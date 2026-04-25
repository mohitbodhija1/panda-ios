-- Bug fix: HomeHeroCard "You owe / You're owed" reads from v_home_summary,
-- which was previously aggregated only over v_user_group_balance. Friend
-- (1-to-1, group_id = null) expenses live in v_user_friend_balance and were
-- silently excluded, so the landing page rendered 0 even when splits existed.
--
-- Rebuild the view to UNION ALL group balances with per-user friend balances
-- projected from the canonical (user_a, user_b, net_owed) pair. Same DTO shape
-- (HomeSummaryDTO), so no client change required.

create or replace view public.v_home_summary as
with per_group as (
    select user_id, balance
      from public.v_user_group_balance
),
per_friend as (
    -- v_user_friend_balance stores one row per canonical pair (user_a < user_b)
    -- with net_owed signed from user_a's perspective. Project it onto each
    -- party so a single user can sum both sides.
    select user_a as user_id,  net_owed as balance from public.v_user_friend_balance
    union all
    select user_b as user_id, -net_owed as balance from public.v_user_friend_balance
),
all_legs as (
    select user_id, balance from per_group
    union all
    select user_id, balance from per_friend
)
select
    user_id,
    round(sum(case when balance < 0 then -balance else 0 end), 2) as you_owe,
    round(sum(case when balance > 0 then  balance else 0 end), 2) as you_are_owed,
    round(sum(balance), 2)                                        as net,
    'USD'::char(3) as currency
from all_legs
group by user_id;

comment on view public.v_home_summary is
    'Aggregated owe / owed totals per user across all groups AND friend (non-group) expenses (display currency only).';

notify pgrst, 'reload schema';
