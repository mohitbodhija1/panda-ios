-- Expose inviter email/phone on rpc_friend_requests_received so the client can
-- build the same displayName fallbacks as accepted-friend profile reads.
--
-- Postgres does not allow CREATE OR REPLACE when the RETURNS TABLE shape
-- changes (42P13); drop and recreate, then restore grants.

drop function if exists public.rpc_friend_requests_received();

create function public.rpc_friend_requests_received()
returns table (
    user_id          uuid,
    full_name        text,
    username         text,
    email            text,
    phone            text,
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
        p.email::text     as email,
        p.phone,
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
    'Pending friendships where the caller is the recipient, joined to the inviter profile (incl. email/phone for display fallbacks).';

revoke all on function public.rpc_friend_requests_received() from public;
grant execute on function public.rpc_friend_requests_received() to authenticated;
