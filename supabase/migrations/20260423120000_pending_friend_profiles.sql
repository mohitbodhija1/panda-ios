-- Migration: allow reading the profile of a pending friendship counterparty.
-- Without this, the Friends screen cannot render the name/avatar of someone you
-- have invited until they accept, breaking the "Invited" section and the
-- ability to add an expense with a not-yet-accepted friend.
--
-- We add a separate select policy so that the existing accepted-only
-- `is_friend_with` helper keeps its narrower meaning everywhere else.

create policy profiles_pending_friend_read on public.profiles
    for select using (
        exists (
            select 1
              from public.friendships f
             where f.status = 'pending'
               and (
                    (f.user_a = auth.uid() and f.user_b = profiles.id)
                 or (f.user_b = auth.uid() and f.user_a = profiles.id)
               )
        )
    );
