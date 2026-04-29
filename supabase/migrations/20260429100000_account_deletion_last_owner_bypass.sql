-- Allow dissolving a sole-member group and removing membership rows during
-- fn_anonymize_account while app.account_deletion_in_progress is set (same GUC
-- pattern as tg_settlements_immutable). Without this, DELETE FROM groups CASCADE
-- onto group_members raises "Cannot remove the last owner of group …".

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
