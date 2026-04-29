-- Migration: persist group avatar key on group creation.
-- Extends rpc_create_group payload with optional `avatar_url` so each group can
-- keep a stable avatar assignment from creation time.

create or replace function public.rpc_create_group(payload jsonb)
returns public.groups
language plpgsql
volatile
security definer
set search_path = public, pg_temp
as $$
declare
    me           uuid := auth.uid();
    new_group    public.groups;
    member_id    uuid;
    name_in      text := nullif(btrim(coalesce(payload ->> 'name', '')), '');
    desc_in      text := nullif(btrim(coalesce(payload ->> 'description', '')), '');
    currency_in  text := upper(coalesce(nullif(payload ->> 'default_currency', ''), 'USD'));
    avatar_in    text := nullif(btrim(coalesce(payload ->> 'avatar_url', '')), '');
begin
    if me is null then
        raise exception 'auth required' using errcode = '28000';
    end if;
    if name_in is null then
        raise exception 'name is required' using errcode = '22023';
    end if;

    if avatar_in is not null
       and avatar_in not in ('group_avatar_1', 'group_avatar_2', 'group_avatar_3', 'group_avatar_4', 'group_avatar_5')
    then
        avatar_in := null;
    end if;

    insert into public.groups (name, description, avatar_url, default_currency, created_by)
    values (name_in, desc_in, avatar_in, currency_in, me)
    returning * into new_group;

    -- trg_groups_add_owner already inserts (group_id, me, 'owner').
    if jsonb_typeof(payload -> 'member_ids') = 'array' then
        for member_id in
            select (value)::uuid
              from jsonb_array_elements_text(payload -> 'member_ids')
        loop
            if member_id is null or member_id = me then
                continue;
            end if;
            insert into public.group_members (group_id, user_id, role)
            values (new_group.id, member_id, 'member')
            on conflict (group_id, user_id) do nothing;
        end loop;
    end if;

    insert into public.activity_log (actor_id, kind, group_id, payload)
    values (
        me,
        'group_created',
        new_group.id,
        jsonb_build_object('name', new_group.name)
    );

    return new_group;
end;
$$;

revoke all     on function public.rpc_create_group(jsonb) from public;
grant execute on function public.rpc_create_group(jsonb) to authenticated;

notify pgrst, 'reload schema';
