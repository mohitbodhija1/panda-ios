-- Migration: groups + group_members
-- A group has many members; the creator becomes the owner via trigger.

-- ============================================================================
-- groups
-- ============================================================================
create table if not exists public.groups (
    id                  uuid primary key default gen_random_uuid(),
    name                text not null check (length(btrim(name)) between 1 and 80),
    description         text,
    avatar_url          text,
    default_currency    char(3) not null default 'USD' references public.currencies(code),
    created_by          uuid    not null references public.profiles(id) on delete restrict,
    is_archived         boolean not null default false,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now()
);

create index if not exists groups_created_by_idx on public.groups (created_by);
create index if not exists groups_active_idx     on public.groups (is_archived) where is_archived = false;

comment on table public.groups is 'Splitwise-style groups; default_currency is the unit used for in-group balances.';

drop trigger if exists trg_groups_updated_at on public.groups;
create trigger trg_groups_updated_at
    before update on public.groups
    for each row execute function public.tg_set_updated_at();

-- ============================================================================
-- group_members
-- ============================================================================
create table if not exists public.group_members (
    group_id    uuid not null references public.groups(id) on delete cascade,
    user_id     uuid not null references public.profiles(id) on delete cascade,
    role        text not null check (role in ('owner','member')) default 'member',
    joined_at   timestamptz not null default now(),
    primary key (group_id, user_id)
);

create index if not exists group_members_user_idx  on public.group_members (user_id);
create index if not exists group_members_owner_idx on public.group_members (group_id) where role = 'owner';

comment on table public.group_members is 'Group membership with role; owner has elevated privileges in RLS.';

-- ----------------------------------------------------------------------------
-- Auto-add creator as owner on group insert.
-- ----------------------------------------------------------------------------
create or replace function public.tg_groups_add_owner()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    insert into public.group_members (group_id, user_id, role)
    values (new.id, new.created_by, 'owner')
    on conflict (group_id, user_id) do update set role = 'owner';
    return new;
end;
$$;

drop trigger if exists trg_groups_add_owner on public.groups;
create trigger trg_groups_add_owner
    after insert on public.groups
    for each row execute function public.tg_groups_add_owner();

-- ----------------------------------------------------------------------------
-- Prevent the last owner from leaving / being removed.
-- ----------------------------------------------------------------------------
create or replace function public.tg_group_members_protect_last_owner()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    remaining_owners int;
begin
    if old.role <> 'owner' then
        return old;
    end if;

    select count(*) into remaining_owners
      from public.group_members
     where group_id = old.group_id
       and role = 'owner'
       and user_id <> old.user_id;

    if remaining_owners = 0 then
        raise exception 'Cannot remove the last owner of group %', old.group_id
            using errcode = '23514';
    end if;

    return old;
end;
$$;

drop trigger if exists trg_group_members_protect_last_owner on public.group_members;
create trigger trg_group_members_protect_last_owner
    before delete on public.group_members
    for each row execute function public.tg_group_members_protect_last_owner();
