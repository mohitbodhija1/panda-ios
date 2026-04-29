-- Migration: account deletion sentinel + anonymization RPC + settlements bypass during deletion.
-- Enables Edge Function delete_account → fn_anonymize_account → auth.admin.deleteUser.

create extension if not exists pgcrypto with schema extensions;

-- ----------------------------------------------------------------------------
-- Immutable settlements: allow UPDATE/DELETE only while anonymizing an account.
-- ----------------------------------------------------------------------------
create or replace function public.tg_settlements_immutable()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if coalesce(current_setting('app.account_deletion_in_progress', true), '') = 'on' then
        return coalesce(new, old);
    end if;
    raise exception 'Settlements are immutable; create a reversing entry instead.'
        using errcode = '0A000';
    return null;
end;
$$;

-- ----------------------------------------------------------------------------
-- Sentinel auth user + profile for "Deleted user" (never log-in capable).
-- ----------------------------------------------------------------------------
do $$
begin
    if exists (select 1 from auth.users where id = '00000000-0000-0000-0000-000000000000') then
        return;
    end if;

    insert into auth.users (
        instance_id,
        id,
        aud,
        role,
        email,
        encrypted_password,
        email_confirmed_at,
        raw_app_meta_data,
        raw_user_meta_data,
        created_at,
        updated_at,
        confirmation_token,
        email_change,
        email_change_token_new,
        recovery_token
    ) values (
        '00000000-0000-0000-0000-000000000000',
        '00000000-0000-0000-0000-000000000000',
        'authenticated',
        'authenticated',
        'deleted-user-sentinel@pandasplit.internal',
        extensions.crypt(
            encode(extensions.gen_random_bytes(32), 'hex'),
            extensions.gen_salt('bf')
        ),
        null,
        '{}',
        jsonb_build_object('full_name', 'Deleted user'),
        now(),
        now(),
        '',
        '',
        '',
        ''
    );

    update public.profiles
       set full_name = 'Deleted user',
           email = null,
           phone = null,
           avatar_url = null
     where id = '00000000-0000-0000-0000-000000000000';
end;
$$;

-- ----------------------------------------------------------------------------
-- Anonymize every restrictive FK to the sentinel, transfer sole-owner groups,
-- then auth deletion can cascade profiles/device_tokens/friendships/etc.
-- ----------------------------------------------------------------------------
create or replace function public.fn_anonymize_account(target uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    sentinel constant uuid := '00000000-0000-0000-0000-000000000000';
    r record;
    promoted uuid;
begin
    if target is null or target = sentinel then
        raise exception 'invalid anonymization target';
    end if;

    perform set_config('app.account_deletion_in_progress', 'on', true);

    -- Groups where target is an owner: promote oldest other member, or delete empty group.
    for r in
        select distinct gm.group_id
          from public.group_members gm
         where gm.user_id = target
           and gm.role = 'owner'
    loop
        select gm2.user_id
          into promoted
          from public.group_members gm2
         where gm2.group_id = r.group_id
           and gm2.user_id <> target
         order by gm2.joined_at asc
         limit 1;

        if promoted is null then
            delete from public.groups where id = r.group_id;
        else
            update public.group_members
               set role = 'owner'
             where group_id = r.group_id
               and user_id = promoted;

            update public.groups
               set created_by = promoted
             where id = r.group_id;
        end if;
    end loop;

    -- Friend-only (non-group) expenses: remove entirely for this user.
    delete from public.expenses e
     where e.group_id is null
       and (e.paid_by = target or e.created_by = target);

    update public.expenses set paid_by = sentinel where paid_by = target;
    update public.expenses set created_by = sentinel where created_by = target;

    update public.expense_splits set user_id = sentinel where user_id = target;

    update public.settlements set payer_id = sentinel where payer_id = target;
    update public.settlements set payee_id = sentinel where payee_id = target;
    update public.settlements set created_by = sentinel where created_by = target;

    update public.expense_attachments set uploaded_by = sentinel where uploaded_by = target;

    update public.recurring_expenses
       set paid_by = sentinel,
           is_active = false
     where paid_by = target;

    update public.recurring_expenses
       set created_by = sentinel
     where created_by = target;

    update public.groups set created_by = sentinel where created_by = target;
end;
$$;

comment on function public.fn_anonymize_account(uuid) is
    'Service-role only: reassigns FK references from the deleting user to the Deleted-user sentinel before auth.users deletion.';

revoke all on function public.fn_anonymize_account(uuid) from public;
grant execute on function public.fn_anonymize_account(uuid) to service_role;
