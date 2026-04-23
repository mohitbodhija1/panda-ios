-- Migration: RPCs (typed contracts called from the iOS client)
--
-- These functions wrap multi-table writes in a single transaction so the client
-- never has to coordinate. Each is SECURITY INVOKER (default): RLS still
-- applies to every underlying statement.

-- ============================================================================
-- rpc_create_expense
-- payload schema:
-- {
--   "group_id":     uuid | null,
--   "title":        text,
--   "notes":        text | null,
--   "emoji":        text | null,
--   "category_id":  smallint | null,
--   "amount":       numeric,
--   "currency":     "USD",
--   "paid_by":      uuid,
--   "expense_date": "YYYY-MM-DD",
--   "split_type":   "equal" | "exact" | "percent" | "shares",
--   "splits":       [ { "user_id": uuid, "amount_owed"?, "share_percent"?, "share_count"? } ]
-- }
-- For split_type='equal' the server divides amount evenly across splits and
-- distributes the rounding remainder onto the first row.
-- ============================================================================
create or replace function public.rpc_create_expense(payload jsonb)
returns public.expenses
language plpgsql
volatile
as $$
declare
    new_expense public.expenses;
    split_type  text := payload ->> 'split_type';
    amount      numeric(14,2) := (payload ->> 'amount')::numeric(14,2);
    splits      jsonb := payload -> 'splits';
    n_splits    int   := jsonb_array_length(coalesce(splits, '[]'::jsonb));
    even_share  numeric(14,2);
    remainder   numeric(14,2);
    s           jsonb;
    idx         int := 0;
    owed        numeric(14,2);
begin
    if amount is null or amount <= 0 then
        raise exception 'amount must be positive';
    end if;
    if n_splits = 0 then
        raise exception 'splits must contain at least one row';
    end if;

    insert into public.expenses (
        group_id, title, notes, emoji, category_id, amount, currency,
        paid_by, expense_date, split_type, created_by
    )
    values (
        nullif(payload ->> 'group_id', '')::uuid,
        payload ->> 'title',
        nullif(payload ->> 'notes', ''),
        nullif(payload ->> 'emoji', ''),
        (payload ->> 'category_id')::smallint,
        amount,
        coalesce(payload ->> 'currency', 'USD'),
        (payload ->> 'paid_by')::uuid,
        coalesce((payload ->> 'expense_date')::date, current_date),
        split_type,
        auth.uid()
    )
    returning * into new_expense;

    if split_type = 'equal' then
        even_share := round(amount / n_splits, 2);
        remainder  := amount - even_share * n_splits;
    end if;

    for s in select * from jsonb_array_elements(splits) loop
        idx := idx + 1;

        if split_type = 'equal' then
            owed := even_share + (case when idx = 1 then remainder else 0 end);
        elsif split_type = 'exact' then
            owed := (s ->> 'amount_owed')::numeric(14,2);
        elsif split_type = 'percent' then
            owed := round(amount * (s ->> 'share_percent')::numeric / 100, 2);
        elsif split_type = 'shares' then
            owed := round(amount * (s ->> 'share_count')::numeric
                           / nullif((select sum((x ->> 'share_count')::numeric)
                                       from jsonb_array_elements(splits) x), 0), 2);
        else
            raise exception 'unknown split_type %', split_type;
        end if;

        insert into public.expense_splits (
            expense_id, user_id, amount_owed, share_percent, share_count
        )
        values (
            new_expense.id,
            (s ->> 'user_id')::uuid,
            owed,
            (s ->> 'share_percent')::numeric(7,4),
            (s ->> 'share_count')::int
        );
    end loop;

    insert into public.activity_log (actor_id, kind, group_id, expense_id, payload)
    values (
        auth.uid(),
        'expense_created',
        new_expense.group_id,
        new_expense.id,
        jsonb_build_object(
            'title',  new_expense.title,
            'amount', new_expense.amount,
            'currency', new_expense.currency
        )
    );

    perform pg_notify(
        'pandasplit.expense_created',
        json_build_object('expense_id', new_expense.id, 'actor', auth.uid())::text
    );

    return new_expense;
end;
$$;

-- ============================================================================
-- rpc_settle_up
-- payload: { group_id?, payer_id, payee_id, amount, currency, method?, note?, settled_at? }
-- ============================================================================
create or replace function public.rpc_settle_up(payload jsonb)
returns public.settlements
language plpgsql
volatile
as $$
declare
    new_settlement public.settlements;
begin
    insert into public.settlements (
        group_id, payer_id, payee_id, amount, currency, method, note, settled_at, created_by
    )
    values (
        nullif(payload ->> 'group_id', '')::uuid,
        (payload ->> 'payer_id')::uuid,
        (payload ->> 'payee_id')::uuid,
        (payload ->> 'amount')::numeric(14,2),
        coalesce(payload ->> 'currency', 'USD'),
        coalesce(payload ->> 'method', 'cash'),
        nullif(payload ->> 'note', ''),
        coalesce((payload ->> 'settled_at')::timestamptz, now()),
        auth.uid()
    )
    returning * into new_settlement;

    insert into public.activity_log (actor_id, kind, group_id, settlement_id, payload)
    values (
        auth.uid(),
        'settlement_created',
        new_settlement.group_id,
        new_settlement.id,
        jsonb_build_object(
            'amount', new_settlement.amount,
            'currency', new_settlement.currency,
            'payer', new_settlement.payer_id,
            'payee', new_settlement.payee_id
        )
    );

    perform pg_notify(
        'pandasplit.settlement_created',
        json_build_object('settlement_id', new_settlement.id, 'actor', auth.uid())::text
    );

    return new_settlement;
end;
$$;

-- ============================================================================
-- rpc_invite_friend
--   channel = 'email' | 'phone'
--   target  = the email or phone string
-- If a profile already exists with that email/phone, immediately create a
-- pending friendship with auth.uid() as the requester. Otherwise create a
-- friend_invites row that the friend_invite_link trigger will consume on signup.
-- ============================================================================
create or replace function public.rpc_invite_friend(channel text, target text)
returns jsonb
language plpgsql
volatile
as $$
declare
    me uuid := auth.uid();
    other_id uuid;
    pair record;
    invite public.friend_invites;
begin
    if me is null then
        raise exception 'auth required';
    end if;
    if channel not in ('email','phone') then
        raise exception 'invalid channel %', channel;
    end if;

    if channel = 'email' then
        select id into other_id from public.profiles where email = target::citext;
    else
        select id into other_id from public.profiles where phone = target;
    end if;

    if other_id is not null and other_id <> me then
        select * into pair from public.friendship_pair(me, other_id);

        insert into public.friendships (user_a, user_b, requested_by, status)
        values (pair.user_a, pair.user_b, me, 'pending')
        on conflict (user_a, user_b) do nothing;

        return jsonb_build_object('kind', 'friendship_request', 'user_id', other_id);
    end if;

    insert into public.friend_invites (inviter_id, channel, email, phone)
    values (
        me,
        channel,
        case when channel = 'email' then target::citext else null end,
        case when channel = 'phone' then target else null end
    )
    on conflict do nothing
    returning * into invite;

    return jsonb_build_object('kind', 'pending_invite', 'invite_id', invite.id, 'token', invite.token);
end;
$$;

-- ============================================================================
-- rpc_accept_friend
-- ============================================================================
create or replace function public.rpc_accept_friend(other uuid)
returns public.friendships
language plpgsql
volatile
as $$
declare
    me uuid := auth.uid();
    pair record;
    row  public.friendships;
begin
    if me is null then
        raise exception 'auth required';
    end if;
    if other = me then
        raise exception 'cannot friend self';
    end if;

    select * into pair from public.friendship_pair(me, other);

    update public.friendships
       set status = 'accepted',
           accepted_at = now()
     where user_a = pair.user_a
       and user_b = pair.user_b
       and status = 'pending'
       and requested_by <> me
    returning * into row;

    if row.user_a is null then
        raise exception 'no pending friendship to accept';
    end if;

    insert into public.activity_log (actor_id, kind, friendship_a, friendship_b, payload)
    values (me, 'friendship_accepted', pair.user_a, pair.user_b, '{}'::jsonb);

    return row;
end;
$$;

-- ============================================================================
-- rpc_create_recurring
-- payload mirrors recurring_expenses columns plus splits embedded in split_payload.
-- ============================================================================
create or replace function public.rpc_create_recurring(payload jsonb)
returns public.recurring_expenses
language plpgsql
volatile
as $$
declare
    row public.recurring_expenses;
begin
    insert into public.recurring_expenses (
        group_id, title, notes, emoji, category_id, amount, currency,
        paid_by, split_type, split_payload, frequency, interval_count,
        next_run_on, is_active, created_by
    )
    values (
        nullif(payload ->> 'group_id', '')::uuid,
        payload ->> 'title',
        nullif(payload ->> 'notes', ''),
        nullif(payload ->> 'emoji', ''),
        (payload ->> 'category_id')::smallint,
        (payload ->> 'amount')::numeric(14,2),
        coalesce(payload ->> 'currency', 'USD'),
        (payload ->> 'paid_by')::uuid,
        payload ->> 'split_type',
        coalesce(payload -> 'split_payload', '[]'::jsonb),
        payload ->> 'frequency',
        coalesce((payload ->> 'interval_count')::int, 1),
        coalesce((payload ->> 'next_run_on')::date, current_date),
        coalesce((payload ->> 'is_active')::boolean, true),
        auth.uid()
    )
    returning * into row;
    return row;
end;
$$;

-- ============================================================================
-- Grant execute to authenticated users only.
-- ============================================================================
revoke all on function public.rpc_create_expense(jsonb)         from public;
revoke all on function public.rpc_settle_up(jsonb)              from public;
revoke all on function public.rpc_invite_friend(text, text)     from public;
revoke all on function public.rpc_accept_friend(uuid)           from public;
revoke all on function public.rpc_create_recurring(jsonb)       from public;

grant execute on function public.rpc_create_expense(jsonb)      to authenticated;
grant execute on function public.rpc_settle_up(jsonb)           to authenticated;
grant execute on function public.rpc_invite_friend(text, text)  to authenticated;
grant execute on function public.rpc_accept_friend(uuid)        to authenticated;
grant execute on function public.rpc_create_recurring(jsonb)    to authenticated;
