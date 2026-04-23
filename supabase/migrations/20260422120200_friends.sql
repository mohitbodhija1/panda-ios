-- Migration: friendships + friend_invites
-- Friendship is modelled as a canonical undirected pair (user_a < user_b)
-- so each relationship has exactly one row regardless of who initiated it.

-- ============================================================================
-- friendships
-- ============================================================================
create table if not exists public.friendships (
    user_a          uuid not null references public.profiles(id) on delete cascade,
    user_b          uuid not null references public.profiles(id) on delete cascade,
    requested_by    uuid not null references public.profiles(id) on delete cascade,
    status          text not null check (status in ('pending','accepted','blocked')),
    created_at      timestamptz not null default now(),
    accepted_at     timestamptz,
    primary key (user_a, user_b),
    check (user_a < user_b),
    check (requested_by in (user_a, user_b))
);

create index if not exists friendships_user_b_idx       on public.friendships (user_b);
create index if not exists friendships_pending_idx      on public.friendships (status) where status = 'pending';
create index if not exists friendships_accepted_idx     on public.friendships (status) where status = 'accepted';

comment on table public.friendships is 'Undirected friendship; canonical row stores user_a < user_b.';

-- Helper: normalise a user pair so callers do not need to sort manually.
create or replace function public.friendship_pair(u1 uuid, u2 uuid)
returns table (user_a uuid, user_b uuid)
language sql
immutable
as $$
    select least(u1, u2), greatest(u1, u2);
$$;

-- ============================================================================
-- friend_invites (out-of-band invitations to non-users)
-- ============================================================================
create table if not exists public.friend_invites (
    id                  uuid primary key default gen_random_uuid(),
    inviter_id          uuid not null references public.profiles(id) on delete cascade,
    channel             text not null check (channel in ('email','phone')),
    email               citext,
    phone               text,
    token               text not null unique default encode(extensions.gen_random_bytes(18), 'base64'),
    status              text not null check (status in ('pending','accepted','expired','revoked')) default 'pending',
    expires_at          timestamptz not null default (now() + interval '30 days'),
    accepted_user_id    uuid references public.profiles(id) on delete set null,
    created_at          timestamptz not null default now(),
    check (
        (channel = 'email' and email is not null and phone is null)
        or
        (channel = 'phone' and phone is not null and email is null)
    )
);

-- One pending invite per (inviter, target) so we do not spam.
create unique index if not exists friend_invites_unique_pending_email
    on public.friend_invites (inviter_id, email)
    where status = 'pending' and email is not null;

create unique index if not exists friend_invites_unique_pending_phone
    on public.friend_invites (inviter_id, phone)
    where status = 'pending' and phone is not null;

create index if not exists friend_invites_email_idx on public.friend_invites (email) where email is not null;
create index if not exists friend_invites_phone_idx on public.friend_invites (phone) where phone is not null;

comment on table public.friend_invites is 'Email/phone invitations consumed by friend_invite_link on auth.users insert.';

-- ----------------------------------------------------------------------------
-- link_pending_friend_invites: when a new auth user appears, accept any
-- pending invites that target their email/phone and materialise friendships.
-- ----------------------------------------------------------------------------
create or replace function public.link_pending_friend_invites()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    inv record;
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

        insert into public.friendships (user_a, user_b, requested_by, status, accepted_at)
        values (pair.user_a, pair.user_b, inv.inviter_id, 'accepted', now())
        on conflict (user_a, user_b) do update
            set status = 'accepted',
                accepted_at = excluded.accepted_at;
    end loop;

    return new;
end;
$$;

drop trigger if exists trg_link_friend_invites on auth.users;
create trigger trg_link_friend_invites
    after insert on auth.users
    for each row execute function public.link_pending_friend_invites();
