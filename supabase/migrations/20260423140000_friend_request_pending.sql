-- Migration: link_pending_friend_invites should leave friendships PENDING.
--
-- The original implementation auto-accepted the friendship the moment the
-- invited user signed up, which meant the recipient never saw an actionable
-- friend request. We now materialise the friendship as `pending` with
-- `requested_by = inviter_id` so the new user gets a normal Accept / Decline
-- prompt in the Friends tab, just like an in-app invite to an existing user.

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
