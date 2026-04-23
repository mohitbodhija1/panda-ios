-- Migration: engagement
-- expense_comments, expense_attachments, activity_log, notifications.

-- ============================================================================
-- expense_comments
-- ============================================================================
create table if not exists public.expense_comments (
    id          uuid primary key default gen_random_uuid(),
    expense_id  uuid not null references public.expenses(id) on delete cascade,
    user_id     uuid not null references public.profiles(id) on delete cascade,
    body        text not null check (length(btrim(body)) between 1 and 2000),
    created_at  timestamptz not null default now(),
    edited_at   timestamptz,
    deleted_at  timestamptz
);

create index if not exists expense_comments_expense_idx
    on public.expense_comments (expense_id, created_at)
    where deleted_at is null;

comment on table public.expense_comments is 'Threaded comments on a single expense.';

-- ============================================================================
-- expense_attachments (Supabase Storage references)
-- ============================================================================
create table if not exists public.expense_attachments (
    id              uuid primary key default gen_random_uuid(),
    expense_id      uuid not null references public.expenses(id) on delete cascade,
    storage_path    text not null,
    mime_type       text not null,
    size_bytes      bigint not null check (size_bytes > 0),
    uploaded_by     uuid not null references public.profiles(id) on delete restrict,
    created_at      timestamptz not null default now()
);

create index if not exists expense_attachments_expense_idx
    on public.expense_attachments (expense_id);

comment on table public.expense_attachments is 'Receipt files stored in the expense-attachments bucket; access via signed URLs.';

-- ============================================================================
-- activity_log (server-curated event stream)
-- ============================================================================
create table if not exists public.activity_log (
    id                  uuid primary key default gen_random_uuid(),
    actor_id            uuid not null references public.profiles(id) on delete cascade,
    kind                text not null check (kind in (
        'expense_created','expense_updated','expense_deleted',
        'settlement_created',
        'group_created','member_added','member_removed',
        'friendship_accepted','comment_added'
    )),
    group_id            uuid references public.groups(id) on delete cascade,
    expense_id          uuid references public.expenses(id) on delete set null,
    settlement_id       uuid references public.settlements(id) on delete set null,
    friendship_a        uuid references public.profiles(id) on delete set null,
    friendship_b        uuid references public.profiles(id) on delete set null,
    payload             jsonb not null default '{}'::jsonb,
    created_at          timestamptz not null default now(),
    check (
        (friendship_a is null and friendship_b is null)
        or (friendship_a is not null and friendship_b is not null and friendship_a < friendship_b)
    )
);

create index if not exists activity_log_group_idx
    on public.activity_log (group_id, created_at desc)
    where group_id is not null;

create index if not exists activity_log_actor_idx
    on public.activity_log (actor_id, created_at desc);

create index if not exists activity_log_expense_idx
    on public.activity_log (expense_id) where expense_id is not null;

create index if not exists activity_log_friendship_idx
    on public.activity_log (friendship_a, friendship_b) where friendship_a is not null;

comment on table public.activity_log is 'Append-only event stream powering Recent Activity and the Activity tab.';

-- ============================================================================
-- notifications (in-app inbox; companion to APNs push)
-- ============================================================================
create table if not exists public.notifications (
    id          uuid primary key default gen_random_uuid(),
    user_id     uuid not null references public.profiles(id) on delete cascade,
    kind        text not null check (kind in (
        'expense_created','settlement_created','friend_invite','friend_accepted','comment_added','recurring_run'
    )),
    title       text not null,
    body        text not null,
    payload     jsonb not null default '{}'::jsonb,
    is_read     boolean not null default false,
    created_at  timestamptz not null default now(),
    read_at     timestamptz
);

create index if not exists notifications_inbox_idx
    on public.notifications (user_id, created_at desc);

create index if not exists notifications_unread_idx
    on public.notifications (user_id) where is_read = false;

comment on table public.notifications is 'In-app inbox. Push fan-out is performed by Edge Functions, which also write here.';
