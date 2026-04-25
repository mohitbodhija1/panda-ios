-- Allow inbox rows when a pending friend request is declined (webhook fan-out).

alter table public.notifications
    drop constraint if exists notifications_kind_check;

alter table public.notifications add constraint notifications_kind_check check (kind in (
    'expense_created',
    'settlement_created',
    'friend_invite',
    'friend_accepted',
    'friend_declined',
    'comment_added',
    'recurring_run'
));
