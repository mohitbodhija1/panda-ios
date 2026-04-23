-- Migration: recurring_expenses
-- Templates that the recurring_runner Edge Function expands into expenses on schedule.

create table if not exists public.recurring_expenses (
    id              uuid primary key default gen_random_uuid(),
    group_id        uuid references public.groups(id) on delete cascade,
    title           text not null check (length(btrim(title)) between 1 and 120),
    notes           text,
    emoji           text,
    category_id     smallint references public.expense_categories(id),
    amount          numeric(14,2) not null check (amount > 0),
    currency        char(3) not null references public.currencies(code),
    paid_by         uuid not null references public.profiles(id) on delete restrict,
    split_type      text not null check (split_type in ('equal','exact','percent','shares')),
    -- Each item: { user_id, amount_owed?, share_percent?, share_count? }
    split_payload   jsonb not null,
    frequency       text not null check (frequency in ('daily','weekly','monthly','yearly')),
    interval_count  int  not null default 1 check (interval_count between 1 and 365),
    next_run_on     date not null,
    last_run_on     date,
    is_active       boolean not null default true,
    created_by      uuid not null references public.profiles(id) on delete restrict,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now()
);

create index if not exists recurring_expenses_due_idx
    on public.recurring_expenses (next_run_on)
    where is_active;

create index if not exists recurring_expenses_group_idx
    on public.recurring_expenses (group_id);

comment on table public.recurring_expenses is 'Templates expanded into concrete expenses by the recurring_runner cron Edge Function.';

drop trigger if exists trg_recurring_expenses_updated_at on public.recurring_expenses;
create trigger trg_recurring_expenses_updated_at
    before update on public.recurring_expenses
    for each row execute function public.tg_set_updated_at();
