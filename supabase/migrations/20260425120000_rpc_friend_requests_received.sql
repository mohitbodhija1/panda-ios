-- Migration: RPCs to harden the recipient-side of the friend request flow.
--
-- Problem we are solving
-- ----------------------
-- The recipient of a friend request never saw the request even though the
-- pending friendship row existed, because FriendsService loaded counterparty
-- profiles with a separate select that silently dropped any row whose RLS
-- check failed. Any miss against `profiles_pending_friend_read` (or future
-- RLS regression) emptied the recipient's "Friend Requests" list.
--
-- We now expose two SECURITY DEFINER RPCs:
--   1. rpc_friend_requests_received() — returns pending friendships for which
--      the caller is the recipient, joined to the inviter's profile in a
--      single trip. Bypasses RLS on profiles so the response is guaranteed
--      whenever a friendships row exists.
--   2. rpc_claim_friend_invites() — defensive sweep that materialises any
--      pending public.friend_invites rows targeting the caller's email/phone
--      into pending friendships. Idempotent. Catches cases where the
--      `link_pending_friend_invites` auth trigger did not run (OAuth signups,
--      trigger-disabled environments, late-arriving invites, etc.).
--
-- Both functions are SECURITY DEFINER + locked search_path so they cannot be
-- hijacked by a rogue object on the caller's path. Execute is granted only to
-- authenticated users.

-- ============================================================================
-- rpc_friend_requests_received
-- ============================================================================
create or replace function public.rpc_friend_requests_received()
returns table (
    user_id          uuid,
    full_name        text,
    username         text,
    avatar_url       text,
    default_currency char(3),
    requested_by     uuid,
    created_at       timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select
        p.id              as user_id,
        p.full_name,
        p.username::text  as username,
        p.avatar_url,
        p.default_currency,
        f.requested_by,
        f.created_at
      from public.friendships f
      join public.profiles    p
        on p.id = case when f.user_a = auth.uid() then f.user_b else f.user_a end
     where auth.uid() in (f.user_a, f.user_b)
       and f.status        = 'pending'
       and f.requested_by <> auth.uid()
     order by f.created_at desc;
$$;

comment on function public.rpc_friend_requests_received() is
    'Pending friendships where the caller is the recipient, joined to the inviter profile.';

-- ============================================================================
-- rpc_claim_friend_invites
-- Defensive: sweep friend_invites for any pending rows targeting the caller's
-- email/phone and materialise them as pending friendships. Mirrors the
-- behaviour of the link_pending_friend_invites auth trigger but is safe to
-- run on every Friends-tab load.
-- ============================================================================
create or replace function public.rpc_claim_friend_invites()
returns int
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
    me            uuid := auth.uid();
    my_email      text;
    my_phone      text;
    inv           record;
    pair          record;
    claimed_count int := 0;
begin
    if me is null then
        raise exception 'auth required';
    end if;

    select nullif(email, ''), nullif(phone, '')
      into my_email, my_phone
      from auth.users
     where id = me;

    if my_email is null and my_phone is null then
        return 0;
    end if;

    for inv in
        select id, inviter_id
          from public.friend_invites
         where status = 'pending'
           and inviter_id <> me
           and (
                (channel = 'email' and my_email is not null and email = my_email::citext)
             or (channel = 'phone' and my_phone is not null and phone = my_phone)
           )
    loop
        update public.friend_invites
           set status            = 'accepted',
               accepted_user_id  = me
         where id = inv.id;

        select * into pair from public.friendship_pair(inv.inviter_id, me);

        insert into public.friendships (user_a, user_b, requested_by, status)
        values (pair.user_a, pair.user_b, inv.inviter_id, 'pending')
        on conflict (user_a, user_b) do nothing;

        claimed_count := claimed_count + 1;
    end loop;

    return claimed_count;
end;
$$;

comment on function public.rpc_claim_friend_invites() is
    'Idempotent sweep: materialise pending friend_invites that target the caller into pending friendships.';

-- ============================================================================
-- Grants
-- ============================================================================
revoke all     on function public.rpc_friend_requests_received() from public;
revoke all     on function public.rpc_claim_friend_invites()     from public;

grant  execute on function public.rpc_friend_requests_received() to authenticated;
grant  execute on function public.rpc_claim_friend_invites()     to authenticated;
