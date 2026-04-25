-- Ensure activity_log INSERT policy exists (idempotent). Fixes environments
-- where 20260425190000 was skipped or the policy was dropped.

drop policy if exists activity_log_authenticated_insert on public.activity_log;

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
