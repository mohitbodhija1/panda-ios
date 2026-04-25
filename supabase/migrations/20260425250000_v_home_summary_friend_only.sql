-- Bug fix (round 2): the previous patch UNIONed v_user_group_balance with
-- v_user_friend_balance to surface friend (non-group) expenses on the Home
-- hero. Unfortunately v_user_friend_balance ALREADY aggregates both 1-to-1
-- AND shared-group activity (see migration 20260422120800_views.sql), so the
-- union double-counted every group expense. The hero card displayed roughly
-- "total money you've ever paid into shared expenses" instead of "net money
-- coming back to you".
--
-- Fix: source v_home_summary exclusively from v_user_friend_balance, projected
-- onto each side of the canonical (user_a, user_b) pair. This gives Splitwise
-- semantics: per-counterparty net, then split into receivable / payable.
--
--   you_are_owed = SUM positive per-counterparty net (the money you'll collect)
--   you_owe      = SUM negative per-counterparty net (the money you'll pay)
--   net          = signed total
--
-- Same column shape as before, so HomeSummaryDTO and HomeViewModel are unchanged.

create or replace view public.v_home_summary as
with per_friend as (
    select user_a as user_id,  net_owed as balance from public.v_user_friend_balance
    union all
    select user_b as user_id, -net_owed as balance from public.v_user_friend_balance
)
select
    user_id,
    round(sum(case when balance < 0 then -balance else 0 end), 2) as you_owe,
    round(sum(case when balance > 0 then  balance else 0 end), 2) as you_are_owed,
    round(sum(balance), 2)                                        as net,
    'USD'::char(3) as currency
from per_friend
group by user_id;

comment on view public.v_home_summary is
    'Per-user owe / owed totals derived from v_user_friend_balance (per-counterparty net across all groups, 1-1 and settlements). Splitwise-style: positive net per friend = receivable, negative = payable.';

notify pgrst, 'reload schema';
