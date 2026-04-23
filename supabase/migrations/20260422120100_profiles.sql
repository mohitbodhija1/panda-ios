-- Migration: profiles + device_tokens
-- One profile row per auth.users; created automatically on signup.
-- Device tokens hold APNs identifiers used by push Edge Functions.

-- ============================================================================
-- profiles
-- ============================================================================
create table if not exists public.profiles (
    id                  uuid primary key references auth.users(id) on delete cascade,
    username            citext unique,
    full_name           text,
    email               citext,
    phone               text unique,
    avatar_url          text,
    default_currency    char(3) not null default 'USD' references public.currencies(code),
    locale              text    not null default 'en_US',
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now()
);

create index if not exists profiles_email_idx on public.profiles (email);
create index if not exists profiles_phone_idx on public.profiles (phone);

comment on table public.profiles is 'Application profile mirroring auth.users; readable by friends and group co-members.';

drop trigger if exists trg_profiles_updated_at on public.profiles;
create trigger trg_profiles_updated_at
    before update on public.profiles
    for each row execute function public.tg_set_updated_at();

-- ----------------------------------------------------------------------------
-- handle_new_user: insert a profile row on auth signup. SECURITY DEFINER so it
-- can write to public.profiles regardless of the caller (an unauthenticated
-- signup transaction).
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
begin
    insert into public.profiles (id, email, phone, full_name, avatar_url)
    values (
        new.id,
        nullif(new.email, ''),
        nullif(new.phone, ''),
        coalesce(meta ->> 'full_name', meta ->> 'name'),
        meta ->> 'avatar_url'
    )
    on conflict (id) do nothing;

    return new;
end;
$$;

drop trigger if exists trg_auth_users_created on auth.users;
create trigger trg_auth_users_created
    after insert on auth.users
    for each row execute function public.handle_new_user();

-- ============================================================================
-- device_tokens (APNs registrations)
-- ============================================================================
create table if not exists public.device_tokens (
    id              uuid primary key default gen_random_uuid(),
    user_id         uuid not null references public.profiles(id) on delete cascade,
    token           text not null unique,
    platform        text not null check (platform in ('ios')),
    last_seen_at    timestamptz not null default now(),
    created_at      timestamptz not null default now()
);

create index if not exists device_tokens_user_idx on public.device_tokens (user_id);

comment on table public.device_tokens is 'APNs device tokens; used by push Edge Functions to fan out notifications.';
