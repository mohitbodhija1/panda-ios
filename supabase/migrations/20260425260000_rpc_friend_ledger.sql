-- Friend history (ledger) RPC powering the new "tap a friend tile" screen.
--
-- Returns a date-ordered ledger of every expense + settlement that
-- *involves* the current user AND the supplied counterparty, regardless of
-- whether it lived inside a group or as a 1-to-1 expense.
--
-- For an expense row, my_share is signed from the caller's perspective:
--   +X => the friend owes me X for this expense (I paid, friend was a splittee)
--   -X => I owe the friend X for this expense (friend paid, I was a splittee)
-- For settlements:
--   +X => friend paid me back X
--   -X => I paid friend X
--
-- SECURITY DEFINER so we can read both parties' rows without depending on
-- the (already-conservative) RLS on expenses/expense_splits/settlements.
-- The function still hard-asserts auth.uid() before it does anything.

drop function if exists public.rpc_friend_ledger(uuid, int);

create or replace function public.rpc_friend_ledger(
    p_other uuid,
    p_limit int default 100
)
returns table (
    kind        text,           -- 'expense' | 'settlement'
    entry_id    uuid,
    occurred_on date,
    title       text,
    amount      numeric(14,2),  -- gross (always positive)
    currency    char(3),
    my_share    numeric(14,2),  -- signed from caller's perspective
    i_paid      boolean,
    group_id    uuid,
    group_name  text,
    emoji       text,
    method      text,           -- settlements only
    note        text             -- settlements only
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    with me as (
        select auth.uid() as id
    ),
    -- Expenses where BOTH me and p_other are involved (one paid, the other
    -- has a split) OR vice versa. We aggregate the friend's split per
    -- expense in case of duplicates (defensive).
    expense_rows as (
        select
            e.id,
            e.expense_date,
            e.title,
            e.amount,
            e.currency,
            e.group_id,
            e.emoji,
            e.paid_by,
            sum(case
                    when e.paid_by = (select id from me) and s.user_id = p_other
                        then  s.amount_owed
                    when e.paid_by = p_other and s.user_id = (select id from me)
                        then -s.amount_owed
                    else 0
                end) as signed_share
        from public.expenses e
        join public.expense_splits s on s.expense_id = e.id
        where e.deleted_at is null
          and (
                (e.paid_by = (select id from me) and s.user_id = p_other)
             or (e.paid_by = p_other and s.user_id = (select id from me))
              )
        group by e.id, e.expense_date, e.title, e.amount, e.currency,
                 e.group_id, e.emoji, e.paid_by
    ),
    settlement_rows as (
        select
            s.id,
            s.settled_at::date as occurred_on,
            'Settlement'::text as title,
            s.amount,
            s.currency,
            s.group_id,
            null::text as emoji,
            s.payer_id,
            s.payee_id,
            s.method::text as method,
            s.note,
            case
                when s.payee_id = (select id from me) and s.payer_id = p_other
                    then  s.amount
                when s.payer_id = (select id from me) and s.payee_id = p_other
                    then -s.amount
                else 0
            end as signed_share
        from public.settlements s
        where (s.payer_id = (select id from me) and s.payee_id = p_other)
           or (s.payer_id = p_other and s.payee_id = (select id from me))
    )
    select
        'expense'::text                        as kind,
        er.id                                  as entry_id,
        er.expense_date                        as occurred_on,
        er.title                               as title,
        er.amount                              as amount,
        er.currency                            as currency,
        er.signed_share                        as my_share,
        (er.paid_by = (select id from me))     as i_paid,
        er.group_id                            as group_id,
        g.name                                 as group_name,
        er.emoji                               as emoji,
        null::text                             as method,
        null::text                             as note
    from expense_rows er
    left join public.groups g on g.id = er.group_id
    where (select id from me) is not null

    union all

    select
        'settlement'::text                     as kind,
        sr.id                                  as entry_id,
        sr.occurred_on                         as occurred_on,
        sr.title                               as title,
        sr.amount                              as amount,
        sr.currency                            as currency,
        sr.signed_share                        as my_share,
        (sr.payer_id = (select id from me))    as i_paid,
        sr.group_id                            as group_id,
        g.name                                 as group_name,
        sr.emoji                               as emoji,
        sr.method                              as method,
        sr.note                                as note
    from settlement_rows sr
    left join public.groups g on g.id = sr.group_id
    where (select id from me) is not null

    order by occurred_on desc, entry_id
    limit greatest(p_limit, 1);
$$;

revoke all     on function public.rpc_friend_ledger(uuid, int) from public;
grant  execute on function public.rpc_friend_ledger(uuid, int) to authenticated;

comment on function public.rpc_friend_ledger(uuid, int) is
    'Date-ordered ledger of expenses + settlements between the caller and p_other (groups and 1-1 combined). my_share is signed from the caller perspective.';

notify pgrst, 'reload schema';
