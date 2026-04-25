-- Promote rpc_create_expense to SECURITY DEFINER so the multi-table write
-- (expenses + expense_splits + activity_log + pg_notify) cannot be partially
-- denied by RLS on a single inner table. We re-implement the same business
-- rules the prior INVOKER-mode RLS policies enforced:
--
--   * caller must be authenticated (auth.uid() is not null)
--   * for friend (no group) expenses: paid_by must equal auth.uid()
--   * for group expenses: caller must be a member of the group
--   * created_by is always set to auth.uid()
--
-- Matches the SECURITY DEFINER pattern used by rpc_friend_requests_received,
-- rpc_claim_friend_invites, rpc_create_group, etc.

create or replace function public.rpc_create_expense(payload jsonb)
returns public.expenses
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
    me          uuid := auth.uid();
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
    payload_group_id uuid := nullif(payload ->> 'group_id', '')::uuid;
    payload_paid_by  uuid := (payload ->> 'paid_by')::uuid;
begin
    if me is null then
        raise exception 'auth required' using errcode = '42501';
    end if;
    if amount is null or amount <= 0 then
        raise exception 'amount must be positive';
    end if;
    if n_splits = 0 then
        raise exception 'splits must contain at least one row';
    end if;
    if payload_paid_by is null then
        raise exception 'paid_by is required';
    end if;

    if payload_group_id is null then
        if payload_paid_by <> me then
            raise exception 'For non-group expenses, paid_by must be the current user'
                using errcode = '42501';
        end if;
    else
        if not public.is_group_member(payload_group_id) then
            raise exception 'You are not a member of this group'
                using errcode = '42501';
        end if;
    end if;

    insert into public.expenses (
        group_id, title, notes, emoji, category_id, amount, currency,
        paid_by, expense_date, split_type, created_by
    )
    values (
        payload_group_id,
        payload ->> 'title',
        nullif(payload ->> 'notes', ''),
        nullif(payload ->> 'emoji', ''),
        (payload ->> 'category_id')::smallint,
        amount,
        coalesce(payload ->> 'currency', 'USD'),
        payload_paid_by,
        coalesce((payload ->> 'expense_date')::date, current_date),
        split_type,
        me
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
        me,
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
        json_build_object('expense_id', new_expense.id, 'actor', me)::text
    );

    return new_expense;
end;
$$;

revoke all     on function public.rpc_create_expense(jsonb) from public;
grant  execute on function public.rpc_create_expense(jsonb) to authenticated;

-- Mirror the same hardening for rpc_settle_up which also writes activity_log.
create or replace function public.rpc_settle_up(payload jsonb)
returns public.settlements
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
    me              uuid := auth.uid();
    new_settlement  public.settlements;
    payload_group_id uuid := nullif(payload ->> 'group_id', '')::uuid;
    payload_payer    uuid := (payload ->> 'payer_id')::uuid;
    payload_payee    uuid := (payload ->> 'payee_id')::uuid;
begin
    if me is null then
        raise exception 'auth required' using errcode = '42501';
    end if;
    if payload_payer is null or payload_payee is null then
        raise exception 'payer_id and payee_id are required';
    end if;
    if me <> payload_payer and me <> payload_payee then
        raise exception 'You can only record a settlement involving yourself'
            using errcode = '42501';
    end if;
    if payload_group_id is not null
       and not public.is_group_member(payload_group_id) then
        raise exception 'You are not a member of this group'
            using errcode = '42501';
    end if;

    insert into public.settlements (
        group_id, payer_id, payee_id, amount, currency, method, note, settled_at, created_by
    )
    values (
        payload_group_id,
        payload_payer,
        payload_payee,
        (payload ->> 'amount')::numeric(14,2),
        coalesce(payload ->> 'currency', 'USD'),
        coalesce(payload ->> 'method', 'cash'),
        nullif(payload ->> 'note', ''),
        coalesce((payload ->> 'settled_at')::timestamptz, now()),
        me
    )
    returning * into new_settlement;

    insert into public.activity_log (actor_id, kind, group_id, settlement_id, payload)
    values (
        me,
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
        json_build_object('settlement_id', new_settlement.id, 'actor', me)::text
    );

    return new_settlement;
end;
$$;

revoke all     on function public.rpc_settle_up(jsonb) from public;
grant  execute on function public.rpc_settle_up(jsonb) to authenticated;

-- Refresh PostgREST schema cache so the new function bodies take effect immediately.
notify pgrst, 'reload schema';
