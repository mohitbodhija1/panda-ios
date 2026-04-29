-- Finish account deletion cleanup before auth.admin.deleteUser runs.
--
-- auth.admin.deleteUser deletes auth.users, which cascades to public.profiles.
-- If that cascade reaches group_members after fn_anonymize_account returns, the
-- account-deletion session GUC is gone and tg_group_members_protect_last_owner
-- can still reject the delete. Delete public.profiles inside the RPC instead,
-- while app.account_deletion_in_progress is set.

create or replace function public.tg_group_members_protect_last_owner()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    remaining_owners int;
begin
    if coalesce(current_setting('app.account_deletion_in_progress', true), '') = 'on' then
        return old;
    end if;

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

    -- Run profile-owned cascades while account-deletion trigger bypasses are active.
    delete from public.profiles where id = target;
end;
$$;

revoke all on function public.fn_anonymize_account(uuid) from public;
grant execute on function public.fn_anonymize_account(uuid) to service_role;
