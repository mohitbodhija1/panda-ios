-- Migration: welcome email queue
-- Enqueues exactly one transactional welcome email per new auth user.

-- ============================================================================
-- welcome_emails
-- ============================================================================
create table if not exists public.welcome_emails (
    user_id      uuid primary key references public.profiles(id) on delete cascade,
    email        citext not null,
    full_name    text,
    status       text not null default 'pending' check (status in ('pending', 'sending', 'sent', 'failed')),
    sent_at      timestamptz,
    last_error   text,
    created_at   timestamptz not null default now()
);

comment on table public.welcome_emails is 'Transactional welcome emails queued from auth.users inserts and delivered by the welcome_email Edge Function.';

-- ----------------------------------------------------------------------------
-- handle_new_user: insert a profile row and queue a welcome email on auth signup.
-- The welcome email enqueue is intentionally non-fatal so signup still succeeds
-- if the queue insert hits a transient issue.
-- ----------------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    meta jsonb := coalesce(new.raw_user_meta_data, '{}'::jsonb);
    welcome_email citext := nullif(new.email, '')::citext;
    welcome_name text := coalesce(meta ->> 'full_name', meta ->> 'name');
begin
    insert into public.profiles (id, email, phone, full_name, avatar_url)
    values (
        new.id,
        nullif(new.email, ''),
        nullif(new.phone, ''),
        welcome_name,
        meta ->> 'avatar_url'
    )
    on conflict (id) do nothing;

    if welcome_email is not null then
        begin
            insert into public.welcome_emails (user_id, email, full_name)
            values (new.id, welcome_email, welcome_name)
            on conflict (user_id) do nothing;
        exception when others then
            raise warning 'welcome email enqueue failed for %: %', new.id, SQLERRM;
        end;
    end if;

    return new;
end;
$$;

drop trigger if exists trg_auth_users_created on auth.users;
create trigger trg_auth_users_created
    after insert on auth.users
    for each row execute function public.handle_new_user();
