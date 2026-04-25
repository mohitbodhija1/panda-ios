-- Allow authenticated users to append activity_log rows where they are the actor
-- and (when scoped to a group) they are a member. rpc_create_expense, rpc_settle_up,
-- rpc_create_group, etc. run as SECURITY INVOKER and INSERT here; without an INSERT
-- policy RLS denied the write and rolled back the whole transaction.

create policy activity_log_authenticated_insert on public.activity_log
    for insert to authenticated
    with check (
        actor_id = auth.uid()
        and (
            group_id is null
            or public.is_group_member(group_id)
        )
        and (
            (friendship_a is null and friendship_b is null)
            or (
                friendship_a is not null
                and friendship_b is not null
                and auth.uid() in (friendship_a, friendship_b)
            )
        )
    );

comment on policy activity_log_authenticated_insert on public.activity_log is
    'Lets RPCs and triggers insert events as the current user; group-scoped rows require membership.';
