-- Migration: Row-Level Security
-- Helper functions are SECURITY DEFINER so policies that reference them do not
-- recurse through their own RLS. Every table here gets RLS enabled.

-- ============================================================================
-- Helpers
-- ============================================================================
create or replace function public.is_group_member(g uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1 from public.group_members
         where group_id = g and user_id = auth.uid()
    );
$$;

create or replace function public.is_group_owner(g uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1 from public.group_members
         where group_id = g and user_id = auth.uid() and role = 'owner'
    );
$$;

create or replace function public.is_expense_participant(e uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1
          from public.expenses ex
          left join public.expense_splits sp on sp.expense_id = ex.id
         where ex.id = e
           and (
                sp.user_id = auth.uid()
             or ex.paid_by  = auth.uid()
             or (ex.group_id is not null and public.is_group_member(ex.group_id))
           )
    );
$$;

create or replace function public.is_friend_with(other uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1 from public.friendships
         where status = 'accepted'
           and (
                (user_a = auth.uid() and user_b = other)
             or (user_b = auth.uid() and user_a = other)
           )
    );
$$;

create or replace function public.shares_group_with(other uuid)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select exists (
        select 1
          from public.group_members me
          join public.group_members them on them.group_id = me.group_id
         where me.user_id = auth.uid() and them.user_id = other
    );
$$;

-- ============================================================================
-- Enable RLS
-- ============================================================================
alter table public.profiles            enable row level security;
alter table public.device_tokens       enable row level security;
alter table public.friendships         enable row level security;
alter table public.friend_invites      enable row level security;
alter table public.groups              enable row level security;
alter table public.group_members       enable row level security;
alter table public.recurring_expenses  enable row level security;
alter table public.expenses            enable row level security;
alter table public.expense_splits      enable row level security;
alter table public.settlements         enable row level security;
alter table public.expense_comments    enable row level security;
alter table public.expense_attachments enable row level security;
alter table public.activity_log        enable row level security;
alter table public.notifications       enable row level security;

-- Lookup tables stay readable by everyone (no PII).
alter table public.currencies          enable row level security;
alter table public.fx_rates            enable row level security;
alter table public.expense_categories  enable row level security;

create policy currencies_read         on public.currencies         for select to anon, authenticated using (true);
create policy fx_rates_read           on public.fx_rates           for select to anon, authenticated using (true);
create policy expense_categories_read on public.expense_categories for select to anon, authenticated using (true);

-- ============================================================================
-- profiles
-- ============================================================================
create policy profiles_self_read on public.profiles
    for select using (id = auth.uid());

create policy profiles_friends_read on public.profiles
    for select using (public.is_friend_with(id) or public.shares_group_with(id));

create policy profiles_self_update on public.profiles
    for update using (id = auth.uid()) with check (id = auth.uid());

-- Inserts happen via the on-signup trigger (security definer).
-- Deletes cascade from auth.users.

-- ============================================================================
-- device_tokens
-- ============================================================================
create policy device_tokens_self_all on public.device_tokens
    for all using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ============================================================================
-- friendships
-- ============================================================================
create policy friendships_pair_read on public.friendships
    for select using (auth.uid() in (user_a, user_b));

create policy friendships_pair_insert on public.friendships
    for insert with check (
        auth.uid() in (user_a, user_b)
        and requested_by = auth.uid()
    );

create policy friendships_pair_update on public.friendships
    for update using (auth.uid() in (user_a, user_b))
    with check    (auth.uid() in (user_a, user_b));

create policy friendships_pair_delete on public.friendships
    for delete using (auth.uid() in (user_a, user_b));

-- ============================================================================
-- friend_invites
-- ============================================================================
create policy friend_invites_owner_all on public.friend_invites
    for all using (inviter_id = auth.uid()) with check (inviter_id = auth.uid());

-- ============================================================================
-- groups
-- ============================================================================
create policy groups_member_read on public.groups
    for select using (public.is_group_member(id));

create policy groups_authed_insert on public.groups
    for insert with check (auth.uid() is not null and created_by = auth.uid());

create policy groups_owner_update on public.groups
    for update using (public.is_group_owner(id))
    with check    (public.is_group_owner(id));

create policy groups_owner_delete on public.groups
    for delete using (public.is_group_owner(id));

-- ============================================================================
-- group_members
-- ============================================================================
create policy group_members_member_read on public.group_members
    for select using (public.is_group_member(group_id));

create policy group_members_owner_insert on public.group_members
    for insert with check (
        public.is_group_owner(group_id)
        or (auth.uid() = user_id and not exists (
            select 1 from public.group_members gm
             where gm.group_id = group_members.group_id
        ))
    );

create policy group_members_self_or_owner_delete on public.group_members
    for delete using (
        public.is_group_owner(group_id) or user_id = auth.uid()
    );

-- ============================================================================
-- recurring_expenses
-- ============================================================================
create policy recurring_member_read on public.recurring_expenses
    for select using (
        group_id is null and created_by = auth.uid()
        or group_id is not null and public.is_group_member(group_id)
    );

create policy recurring_member_write on public.recurring_expenses
    for insert with check (
        created_by = auth.uid()
        and (group_id is null or public.is_group_member(group_id))
    );

create policy recurring_owner_update on public.recurring_expenses
    for update using (created_by = auth.uid()) with check (created_by = auth.uid());

create policy recurring_owner_delete on public.recurring_expenses
    for delete using (created_by = auth.uid());

-- ============================================================================
-- expenses
-- ============================================================================
create policy expenses_participant_read on public.expenses
    for select using (public.is_expense_participant(id));

create policy expenses_member_insert on public.expenses
    for insert with check (
        created_by = auth.uid()
        and (
            (group_id is null and paid_by = auth.uid())
            or (group_id is not null and public.is_group_member(group_id))
        )
    );

create policy expenses_creator_or_owner_update on public.expenses
    for update using (
        created_by = auth.uid()
        or (group_id is not null and public.is_group_owner(group_id))
    )
    with check (
        created_by = auth.uid()
        or (group_id is not null and public.is_group_owner(group_id))
    );

-- Soft delete by setting deleted_at; hard delete reserved for owner / RPC.
create policy expenses_creator_or_owner_delete on public.expenses
    for delete using (
        created_by = auth.uid()
        or (group_id is not null and public.is_group_owner(group_id))
    );

-- ============================================================================
-- expense_splits (visibility follows parent expense; writes via RPC only)
-- ============================================================================
create policy expense_splits_participant_read on public.expense_splits
    for select using (public.is_expense_participant(expense_id));

create policy expense_splits_creator_write on public.expense_splits
    for insert with check (
        exists (
            select 1 from public.expenses e
             where e.id = expense_splits.expense_id
               and (e.created_by = auth.uid() or e.paid_by = auth.uid())
        )
    );

create policy expense_splits_creator_update on public.expense_splits
    for update using (
        exists (
            select 1 from public.expenses e
             where e.id = expense_splits.expense_id
               and (e.created_by = auth.uid() or e.paid_by = auth.uid())
        )
    )
    with check (
        exists (
            select 1 from public.expenses e
             where e.id = expense_splits.expense_id
               and (e.created_by = auth.uid() or e.paid_by = auth.uid())
        )
    );

create policy expense_splits_creator_delete on public.expense_splits
    for delete using (
        exists (
            select 1 from public.expenses e
             where e.id = expense_splits.expense_id
               and (e.created_by = auth.uid() or e.paid_by = auth.uid())
        )
    );

-- ============================================================================
-- settlements
-- ============================================================================
create policy settlements_participant_read on public.settlements
    for select using (
        payer_id = auth.uid()
        or payee_id = auth.uid()
        or (group_id is not null and public.is_group_member(group_id))
    );

create policy settlements_party_insert on public.settlements
    for insert with check (
        created_by = auth.uid()
        and (payer_id = auth.uid() or payee_id = auth.uid())
        and (group_id is null or public.is_group_member(group_id))
    );

-- No update / delete policies: triggers raise errors anyway.

-- ============================================================================
-- expense_comments / expense_attachments
-- ============================================================================
create policy comments_participant_read on public.expense_comments
    for select using (public.is_expense_participant(expense_id));

create policy comments_participant_insert on public.expense_comments
    for insert with check (
        user_id = auth.uid() and public.is_expense_participant(expense_id)
    );

create policy comments_author_update on public.expense_comments
    for update using (user_id = auth.uid()) with check (user_id = auth.uid());

create policy comments_author_delete on public.expense_comments
    for delete using (user_id = auth.uid());

create policy attachments_participant_read on public.expense_attachments
    for select using (public.is_expense_participant(expense_id));

create policy attachments_participant_insert on public.expense_attachments
    for insert with check (
        uploaded_by = auth.uid() and public.is_expense_participant(expense_id)
    );

create policy attachments_uploader_delete on public.expense_attachments
    for delete using (uploaded_by = auth.uid());

-- ============================================================================
-- activity_log (read-only to clients; triggers and RPCs INSERT directly)
-- ============================================================================
create policy activity_visible_read on public.activity_log
    for select using (
        (group_id is not null and public.is_group_member(group_id))
        or (friendship_a is not null and auth.uid() in (friendship_a, friendship_b))
        or actor_id = auth.uid()
    );

-- ============================================================================
-- notifications
-- ============================================================================
create policy notifications_self_read on public.notifications
    for select using (user_id = auth.uid());

create policy notifications_self_update on public.notifications
    for update using (user_id = auth.uid()) with check (user_id = auth.uid());
