-- Add `counterparty_id` to v_recent_activity so the iOS client can navigate
-- directly into FriendHistoryView when a friendship-pair activity row is
-- tapped. NULL for group rows; for friendship rows it is the OTHER side
-- of the pair from `user_id`.

create or replace view public.v_recent_activity as
select
    a.id,
    m.user_id,
    a.actor_id,
    a.kind,
    a.group_id,
    a.expense_id,
    a.settlement_id,
    null::uuid as counterparty_id,
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
    case
        when p.user_id = a.friendship_a then a.friendship_b
        else a.friendship_a
    end as counterparty_id,
    a.payload,
    a.created_at
from public.activity_log a
cross join lateral (values (a.friendship_a), (a.friendship_b)) as p(user_id)
where a.friendship_a is not null;

comment on view public.v_recent_activity is 'Activity feed projected per recipient via group membership or friendship pair, with counterparty for friendship rows.';

notify pgrst, 'reload schema';
