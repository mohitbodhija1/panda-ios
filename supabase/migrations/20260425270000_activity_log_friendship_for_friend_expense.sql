-- Bug fix: the Activity tab is empty for users whose only expenses are
-- friend (no-group) ones. v_recent_activity only projects rows where
-- group_id is not null OR friendship_a/_b are not null (see migration
-- 20260422120800_views.sql). rpc_create_expense currently writes the
-- activity_log entry without populating friendship_a/_b for friendless
-- expenses, so they're invisible in the feed for both parties.
--
-- Fix: re-create rpc_create_expense (still SECURITY DEFINER) so that for
-- friend (group_id IS NULL) expenses it computes the other participant
-- once from the splits payload and stores the canonical pair (least,
-- greatest) on activity_log.friendship_a/_b. v_recent_activity then
-- naturally projects the row to both sides of the pair.
--
-- Side benefit: the iOS client now has the counterparty available for
-- tap-to-history navigation directly from the Recent Activity feed.

create or replace function public.rpc_create_expense(payload jsonb)
returns public.expenses
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
    me               uuid := auth.uid();
    new_expense      public.expenses;
    split_type       text := payload ->> 'split_type';
    amount           numeric(14,2) := (payload ->> 'amount')::numeric(14,2);
    splits           jsonb := payload -> 'splits';
    n_splits         int   := jsonb_array_length(coalesce(splits, '[]'::jsonb));
    even_share       numeric(14,2);
    remainder        numeric(14,2);
    s                jsonb;
    idx              int := 0;
    owed             numeric(14,2);
    payload_group_id uuid := nullif(payload ->> 'group_id', '')::uuid;
    payload_paid_by  uuid := (payload ->> 'paid_by')::uuid;
    friend_uid       uuid;
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

    -- Friend (no-group) expenses: identify the other participant from the
    -- splits and stamp the canonical (a,b) pair onto activity_log so the
    -- entry is visible to both sides via v_recent_activity. The constraint
    -- trigger already guarantees exactly one other splittee for friend
    -- expenses, but we use `limit 1` defensively.
    if payload_group_id is null then
        select (e ->> 'user_id')::uuid
          into friend_uid
          from jsonb_array_elements(splits) e
         where (e ->> 'user_id')::uuid <> payload_paid_by
         limit 1;
    end if;

    insert into public.activity_log (
        actor_id, kind, group_id, expense_id,
        friendship_a, friendship_b, payload
    )
    values (
        me,
        'expense_created',
        new_expense.group_id,
        new_expense.id,
        case when friend_uid is not null then least(payload_paid_by, friend_uid) end,
        case when friend_uid is not null then greatest(payload_paid_by, friend_uid) end,
        jsonb_build_object(
            'title',    new_expense.title,
            'amount',   new_expense.amount,
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

notify pgrst, 'reload schema';
