-- Migration: balance and feed views
-- All balance math lives here, in the database, so the iOS app cannot drift.
--
-- Sign convention everywhere: positive = user is owed; negative = user owes.

-- ============================================================================
-- v_user_group_balance(group_id, user_id, currency, balance)
-- Per group, per user, in the group's default currency.
-- ============================================================================
create or replace view public.v_user_group_balance as
with
expense_legs as (
    select
        e.group_id,
        m.user_id,
        g.default_currency as currency,
        sum(
            case
                when e.paid_by = m.user_id and s.user_id <> m.user_id
                    then  s.amount_owed * coalesce(e.fx_to_group_rate, 1)
                when s.user_id = m.user_id and e.paid_by <> m.user_id
                    then -s.amount_owed * coalesce(e.fx_to_group_rate, 1)
                else 0
            end
        ) as delta
    from public.group_members m
    join public.groups        g on g.id = m.group_id
    join public.expenses      e on e.group_id = m.group_id and e.deleted_at is null
    join public.expense_splits s on s.expense_id = e.id and (s.user_id = m.user_id or e.paid_by = m.user_id)
    group by e.group_id, m.user_id, g.default_currency
),
settlement_legs as (
    select
        s.group_id,
        m.user_id,
        g.default_currency as currency,
        sum(
            case
                when s.payee_id = m.user_id then  s.amount * coalesce(s.fx_to_group_rate, 1)
                when s.payer_id = m.user_id then -s.amount * coalesce(s.fx_to_group_rate, 1)
                else 0
            end
        ) as delta
    from public.group_members m
    join public.groups        g on g.id = m.group_id
    join public.settlements   s on s.group_id = m.group_id
                               and (s.payer_id = m.user_id or s.payee_id = m.user_id)
    group by s.group_id, m.user_id, g.default_currency
)
select
    coalesce(e.group_id, s.group_id) as group_id,
    coalesce(e.user_id,  s.user_id)  as user_id,
    coalesce(e.currency, s.currency) as currency,
    round(coalesce(e.delta, 0) + coalesce(s.delta, 0), 2) as balance
from expense_legs e
full outer join settlement_legs s
    on  s.group_id = e.group_id
    and s.user_id  = e.user_id;

comment on view public.v_user_group_balance is 'Net balance per (group, user) in group.default_currency. Positive = user is owed.';

-- ============================================================================
-- v_user_friend_balance(user_a, user_b, currency, net_owed)
-- Symmetric pair view in user_a < user_b form. net_owed is signed from user_a:
-- positive = user_b owes user_a; negative = user_a owes user_b.
-- Aggregates BOTH 1-1 and shared-group activity, normalised to USD for v1.
-- ============================================================================
create or replace view public.v_user_friend_balance as
with
expense_pairs as (
    select
        least(e.paid_by, s.user_id)    as user_a,
        greatest(e.paid_by, s.user_id) as user_b,
        case when e.paid_by < s.user_id then  s.amount_owed else -s.amount_owed end
            * coalesce(e.fx_to_group_rate, 1) as delta
    from public.expenses       e
    join public.expense_splits s on s.expense_id = e.id
    where e.deleted_at is null
      and e.paid_by <> s.user_id
),
settlement_pairs as (
    select
        least(s.payer_id, s.payee_id)    as user_a,
        greatest(s.payer_id, s.payee_id) as user_b,
        case when s.payee_id < s.payer_id then  s.amount else -s.amount end
            * coalesce(s.fx_to_group_rate, 1) as delta
    from public.settlements s
)
select
    user_a,
    user_b,
    'USD'::char(3) as currency,
    round(sum(delta), 2) as net_owed
from (
    select user_a, user_b, delta from expense_pairs
    union all
    select user_a, user_b, delta from settlement_pairs
) parts
group by user_a, user_b;

comment on view public.v_user_friend_balance is 'Net debt between two users (canonical pair). Sign is from user_a perspective.';

-- ============================================================================
-- v_home_summary(user_id, you_owe, you_are_owed, net, currency)
-- Powers HomeHeroCard / BalanceSummary for the current user.
-- ============================================================================
create or replace view public.v_home_summary as
with per_group as (
    select user_id, balance from public.v_user_group_balance
)
select
    user_id,
    round(sum(case when balance < 0 then -balance else 0 end), 2) as you_owe,
    round(sum(case when balance > 0 then  balance else 0 end), 2) as you_are_owed,
    round(sum(balance), 2)                                        as net,
    'USD'::char(3) as currency
from per_group
group by user_id;

comment on view public.v_home_summary is 'Aggregated owe / owed totals per user across all groups (display currency only).';

-- ============================================================================
-- v_recent_activity(user_id, ...)
-- Joins activity_log with the requesting user for visibility filtering. The
-- iOS app filters with `where user_id = auth.uid()`.
-- ============================================================================
create or replace view public.v_recent_activity as
select
    a.id,
    m.user_id,
    a.actor_id,
    a.kind,
    a.group_id,
    a.expense_id,
    a.settlement_id,
    a.payload,
    a.created_at
from public.activity_log a
join public.group_members m on m.group_id = a.group_id
where a.group_id is not null
union
select
    a.id,
    p.user_id,
    a.actor_id,
    a.kind,
    a.group_id,
    a.expense_id,
    a.settlement_id,
    a.payload,
    a.created_at
from public.activity_log a
cross join lateral (values (a.friendship_a), (a.friendship_b)) as p(user_id)
where a.friendship_a is not null;

comment on view public.v_recent_activity is 'Activity feed projected per recipient via group membership or friendship pair.';
