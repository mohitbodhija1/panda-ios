-- Fix account deletion failure:
-- new row for relation "activity_log" violates check constraint "activity_log_check"
--
-- Cause:
-- activity_log has:
--   check (
--     (friendship_a is null and friendship_b is null)
--     or (friendship_a is not null and friendship_b is not null and friendship_a < friendship_b)
--   )
--
-- Deleting a profile can set only one side (friendship_a or friendship_b) to NULL via FK
-- ON DELETE SET NULL, violating the check. Normalize these rows first.

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

    -- Keep activity_log_check valid: friendship columns must be both null or both non-null.
    update public.activity_log
       set friendship_a = null,
           friendship_b = null
     where friendship_a = target
        or friendship_b = target;

    -- Run profile-owned cascades while account-deletion trigger bypasses are active.
    delete from public.profiles where id = target;
end;
$$;

revoke all on function public.fn_anonymize_account(uuid) from public;
grant execute on function public.fn_anonymize_account(uuid) to service_role;
