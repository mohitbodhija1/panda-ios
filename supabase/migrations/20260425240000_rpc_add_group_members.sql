-- Adds an RPC for owners to add additional members to an existing group, in
-- the same SECURITY DEFINER spirit as rpc_create_group: the function asserts
-- ownership server-side from auth.uid() so the client cannot escalate, then
-- inserts each new member and emits a `member_added` activity_log row so the
-- inbox + Recent Activity feed pick the change up.

create or replace function public.rpc_add_group_members(
    p_group_id uuid,
    p_user_ids uuid[]
)
returns int
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
    me    uuid := auth.uid();
    uid   uuid;
    added int  := 0;
begin
    if me is null then
        raise exception 'auth required' using errcode = '42501';
    end if;
    if p_group_id is null then
        raise exception 'group_id is required' using errcode = '22023';
    end if;
    if not public.is_group_owner(p_group_id) then
        raise exception 'Only group owners can add members'
            using errcode = '42501';
    end if;

    if p_user_ids is null then
        return 0;
    end if;

    foreach uid in array p_user_ids loop
        if uid is null or uid = me then
            continue;
        end if;

        insert into public.group_members (group_id, user_id, role)
        values (p_group_id, uid, 'member')
        on conflict (group_id, user_id) do nothing;

        if found then
            added := added + 1;
            insert into public.activity_log (actor_id, kind, group_id, payload)
            values (
                me,
                'member_added',
                p_group_id,
                jsonb_build_object('user_id', uid)
            );
        end if;
    end loop;

    return added;
end;
$$;

comment on function public.rpc_add_group_members(uuid, uuid[]) is
    'Owner-only: add (idempotently) one or more profiles to a group and log the change.';

revoke all     on function public.rpc_add_group_members(uuid, uuid[]) from public;
grant  execute on function public.rpc_add_group_members(uuid, uuid[]) to authenticated;

notify pgrst, 'reload schema';
