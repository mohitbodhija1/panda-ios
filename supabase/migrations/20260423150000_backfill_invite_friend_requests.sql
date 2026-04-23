-- Migration: backfill friendships that were auto-accepted by the legacy
-- link_pending_friend_invites trigger so the invitee gets a real request.
--
-- The original trigger inserted invite-claim friendships with status =
-- 'accepted', which meant any user who signed up via an emailed invite
-- before 20260423140000 silently became friends with the inviter. This
-- migration re-applies the fixed trigger (idempotent) and then walks the
-- friend_invites claim history to revert those legacy rows to 'pending'.
--
-- Heuristic for "auto-accepted by trigger" (vs. a real human accept):
--   accepted_at - created_at < 1 second
-- The trigger sets both timestamps in the same INSERT statement, so the
-- delta is microseconds. rpc_accept_friend always runs at least a network
-- round-trip after the row was created, so real accepts are safely
-- untouched.

-- ----------------------------------------------------------------------------
-- 1. Re-apply the corrected trigger (idempotent; safe even if 20260423140000
--    already ran).
-- ----------------------------------------------------------------------------
create or replace function public.link_pending_friend_invites()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    inv  record;
    pair record;
begin
    for inv in
        select id, inviter_id
        from public.friend_invites
        where status = 'pending'
          and (
                (channel = 'email' and email = nullif(new.email, ''))
             or (channel = 'phone' and phone = nullif(new.phone, ''))
          )
    loop
        update public.friend_invites
           set status = 'accepted',
               accepted_user_id = new.id
         where id = inv.id;

        select * into pair from public.friendship_pair(inv.inviter_id, new.id);

        insert into public.friendships (user_a, user_b, requested_by, status)
        values (pair.user_a, pair.user_b, inv.inviter_id, 'pending')
        on conflict (user_a, user_b) do nothing;
    end loop;

    return new;
end;
$$;

-- ----------------------------------------------------------------------------
-- 2. Backfill: revert auto-accepted invite-claim friendships to pending.
-- ----------------------------------------------------------------------------
update public.friendships f
   set status      = 'pending',
       accepted_at = null
  from public.friend_invites fi
 where fi.status            = 'accepted'
   and fi.accepted_user_id  is not null
   and fi.inviter_id        = f.requested_by
   and fi.accepted_user_id  in (f.user_a, f.user_b)
   and fi.inviter_id        in (f.user_a, f.user_b)
   and f.status             = 'accepted'
   and f.accepted_at        is not null
   and abs(extract(epoch from (f.accepted_at - f.created_at))) < 1;
