-- Migration: rpc_update_expense (SECURITY DEFINER)
--
-- Adds an RPC that lets the expense creator (or the group owner) edit the
-- title / emoji / notes / amount / currency / expense_date / splits of an
-- existing expense in a single transaction. Mirrors the SECURITY DEFINER
-- pattern of rpc_create_expense so the multi-table write (expenses +
-- expense_splits + activity_log) cannot be partially blocked by RLS on an
-- inner table.
--
-- Authorization mirrors the existing `expenses_creator_or_owner_update`
-- RLS policy: the caller must be the expense's `created_by` OR the owner
-- of the parent group (when the expense lives inside a group).
--
-- Splits are fully replaced from the payload. The deferrable constraint
-- trigger `trg_validate_expense_splits_iud` enforces that the new sum
-- matches the new amount within ±0.02 tolerance at commit time.
--
-- An `expense_updated` activity_log row is appended so Recent Activity /
-- Activity tab reflects the change for every visible participant.

create or replace function public.rpc_update_expense(payload jsonb)
returns public.expenses
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
    me               uuid := auth.uid();
    p_expense_id     uuid := nullif(payload ->> 'expense_id', '')::uuid;
    existing         public.expenses;
    updated_expense  public.expenses;
    p_split_type     text;
    p_amount         numeric(14,2) := (payload ->> 'amount')::numeric(14,2);
    splits           jsonb := payload -> 'splits';
    n_splits         int   := jsonb_array_length(coalesce(splits, '[]'::jsonb));
    even_share       numeric(14,2);
    remainder        numeric(14,2);
    s                jsonb;
    idx              int := 0;
    owed             numeric(14,2);
    friend_uid       uuid;
begin
    if me is null then
        raise exception 'auth required' using errcode = '42501';
    end if;
    if p_expense_id is null then
        raise exception 'expense_id is required';
    end if;
    if p_amount is null or p_amount <= 0 then
        raise exception 'amount must be positive';
    end if;
    if n_splits = 0 then
        raise exception 'splits must contain at least one row';
    end if;

    select * into existing
      from public.expenses
     where id = p_expense_id
       and deleted_at is null;
    if not found then
        raise exception 'Expense % not found', p_expense_id;
    end if;

    -- Authorization parity with `expenses_creator_or_owner_update` RLS.
    if existing.created_by <> me
       and not (existing.group_id is not null and public.is_group_owner(existing.group_id))
    then
        raise exception 'Not authorized to edit this expense'
            using errcode = '42501';
    end if;

    p_split_type := coalesce(payload ->> 'split_type', existing.split_type);

    update public.expenses
       set title        = coalesce(nullif(payload ->> 'title', ''), title),
           notes        = case
                              when payload ? 'notes' then nullif(payload ->> 'notes', '')
                              else notes
                          end,
           emoji        = case
                              when payload ? 'emoji' then nullif(payload ->> 'emoji', '')
                              else emoji
                          end,
           amount       = p_amount,
           currency     = coalesce(payload ->> 'currency', currency),
           split_type   = p_split_type,
           expense_date = coalesce((payload ->> 'expense_date')::date, expense_date),
           updated_at   = now()
     where id = p_expense_id
     returning * into updated_expense;

    -- Replace the full splits set. The constraint trigger is deferrable so
    -- the validation only fires at commit time, after we've inserted the
    -- new rows.
    delete from public.expense_splits where expense_id = p_expense_id;

    if p_split_type = 'equal' then
        even_share := round(p_amount / n_splits, 2);
        remainder  := p_amount - even_share * n_splits;
    end if;

    for s in select * from jsonb_array_elements(splits) loop
        idx := idx + 1;

        if p_split_type = 'equal' then
            owed := even_share + (case when idx = 1 then remainder else 0 end);
        elsif p_split_type = 'exact' then
            owed := (s ->> 'amount_owed')::numeric(14,2);
        elsif p_split_type = 'percent' then
            owed := round(p_amount * (s ->> 'share_percent')::numeric / 100, 2);
        elsif p_split_type = 'shares' then
            owed := round(p_amount * (s ->> 'share_count')::numeric
                           / nullif((select sum((x ->> 'share_count')::numeric)
                                       from jsonb_array_elements(splits) x), 0), 2);
        else
            raise exception 'unknown split_type %', p_split_type;
        end if;

        insert into public.expense_splits (
            expense_id, user_id, amount_owed, share_percent, share_count
        )
        values (
            p_expense_id,
            (s ->> 'user_id')::uuid,
            owed,
            (s ->> 'share_percent')::numeric(7,4),
            (s ->> 'share_count')::int
        );
    end loop;

    -- Friend (no-group) expenses: stamp the canonical (a,b) friendship
    -- pair so the activity row is visible to both sides via
    -- v_recent_activity. Mirrors rpc_create_expense.
    if updated_expense.group_id is null then
        select (e ->> 'user_id')::uuid
          into friend_uid
          from jsonb_array_elements(splits) e
         where (e ->> 'user_id')::uuid <> updated_expense.paid_by
         limit 1;
    end if;

    insert into public.activity_log (
        actor_id, kind, group_id, expense_id,
        friendship_a, friendship_b, payload
    )
    values (
        me,
        'expense_updated',
        updated_expense.group_id,
        updated_expense.id,
        case when friend_uid is not null then least(updated_expense.paid_by, friend_uid) end,
        case when friend_uid is not null then greatest(updated_expense.paid_by, friend_uid) end,
        jsonb_build_object(
            'title',    updated_expense.title,
            'amount',   updated_expense.amount,
            'currency', updated_expense.currency
        )
    );

    perform pg_notify(
        'pandasplit.expense_updated',
        json_build_object('expense_id', updated_expense.id, 'actor', me)::text
    );

    return updated_expense;
end;
$$;

revoke all     on function public.rpc_update_expense(jsonb) from public;
grant  execute on function public.rpc_update_expense(jsonb) to authenticated;

notify pgrst, 'reload schema';
