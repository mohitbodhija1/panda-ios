-- Migration: expenses + expense_splits
-- The two central money tables. Splits must always sum to the expense amount;
-- enforced by a deferrable constraint trigger so an expense + its splits can be
-- inserted within the same transaction (typically via rpc_create_expense).

-- ============================================================================
-- expenses
-- ============================================================================
create table if not exists public.expenses (
    id                  uuid primary key default gen_random_uuid(),
    group_id            uuid references public.groups(id) on delete cascade,
    title               text not null check (length(btrim(title)) between 1 and 140),
    notes               text,
    emoji               text,
    category_id         smallint references public.expense_categories(id),
    amount              numeric(14,2) not null check (amount > 0),
    currency            char(3) not null references public.currencies(code),
    fx_to_group_rate    numeric(18,8) check (fx_to_group_rate is null or fx_to_group_rate > 0),
    paid_by             uuid not null references public.profiles(id) on delete restrict,
    expense_date        date not null default current_date,
    split_type          text not null check (split_type in ('equal','exact','percent','shares')),
    recurring_id        uuid references public.recurring_expenses(id) on delete set null,
    created_by          uuid not null references public.profiles(id) on delete restrict,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    deleted_at          timestamptz
);

create index if not exists expenses_group_date_idx
    on public.expenses (group_id, expense_date desc)
    where deleted_at is null;

create index if not exists expenses_paid_by_idx
    on public.expenses (paid_by, created_at desc)
    where deleted_at is null;

create index if not exists expenses_active_idx
    on public.expenses (created_at desc)
    where deleted_at is null;

comment on table public.expenses is 'A single expense paid by one user; broken out into expense_splits per participant.';

drop trigger if exists trg_expenses_updated_at on public.expenses;
create trigger trg_expenses_updated_at
    before update on public.expenses
    for each row execute function public.tg_set_updated_at();

-- ----------------------------------------------------------------------------
-- FX snapshot: when group_id and currency disagree with the group's default,
-- and the caller did not provide an explicit fx_to_group_rate, snapshot the
-- latest known rate from fx_rates so historical balances stay consistent.
-- ----------------------------------------------------------------------------
create or replace function public.tg_expenses_snapshot_fx()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    group_currency char(3);
    snapshot       numeric(18,8);
begin
    if new.group_id is null or new.fx_to_group_rate is not null then
        return new;
    end if;

    select default_currency into group_currency
      from public.groups
     where id = new.group_id;

    if group_currency is null or group_currency = new.currency then
        new.fx_to_group_rate := 1;
        return new;
    end if;

    select rate into snapshot
      from public.fx_rates
     where base = new.currency
       and quote = group_currency
       and as_of <= new.expense_date
     order by as_of desc
     limit 1;

    new.fx_to_group_rate := coalesce(snapshot, 1);
    return new;
end;
$$;

drop trigger if exists trg_expenses_snapshot_fx on public.expenses;
create trigger trg_expenses_snapshot_fx
    before insert on public.expenses
    for each row execute function public.tg_expenses_snapshot_fx();

-- ============================================================================
-- expense_splits
-- ============================================================================
create table if not exists public.expense_splits (
    id              uuid primary key default gen_random_uuid(),
    expense_id      uuid not null references public.expenses(id) on delete cascade,
    user_id         uuid not null references public.profiles(id) on delete restrict,
    amount_owed     numeric(14,2) not null check (amount_owed >= 0),
    share_percent   numeric(7,4) check (share_percent is null or (share_percent >= 0 and share_percent <= 100)),
    share_count     int          check (share_count   is null or share_count   >= 0),
    is_settled      boolean not null default false,
    created_at      timestamptz not null default now(),
    unique (expense_id, user_id)
);

create index if not exists expense_splits_user_idx     on public.expense_splits (user_id);
create index if not exists expense_splits_expense_idx  on public.expense_splits (expense_id);
create index if not exists expense_splits_open_idx     on public.expense_splits (user_id) where is_settled = false;

comment on table public.expense_splits is 'Per-participant share of an expense (in expense.currency).';

-- ----------------------------------------------------------------------------
-- Validate per-expense invariants at end of transaction:
--  - sum(amount_owed)   = expenses.amount     (within rounding tolerance)
--  - split_type=percent => share_percent set on every row, sum=100
--  - split_type=shares  => share_count   set on every row, sum>0
--  - split_type=exact   => amount_owed set on every row
--  - paid_by must be a participant when group_id is null (1-1 expense between 2 users)
-- ----------------------------------------------------------------------------
create or replace function public.tg_validate_expense_splits()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    exp           public.expenses%rowtype;
    target_id     uuid;
    split_count   int;
    sum_amount    numeric(14,2);
    sum_percent   numeric(10,4);
    sum_shares    int;
    bad_rows      int;
begin
    target_id := coalesce(new.expense_id, old.expense_id);

    select * into exp from public.expenses where id = target_id;
    if not found then
        return coalesce(new, old);
    end if;

    select count(*),
           coalesce(sum(amount_owed), 0),
           coalesce(sum(share_percent), 0),
           coalesce(sum(share_count), 0)
      into split_count, sum_amount, sum_percent, sum_shares
      from public.expense_splits
     where expense_id = target_id;

    if split_count = 0 then
        raise exception 'Expense % has no splits', target_id using errcode = '23514';
    end if;

    -- Sum of owed amounts must equal expense amount within ±0.02 tolerance.
    if abs(sum_amount - exp.amount) > 0.02 then
        raise exception
            'Expense % splits sum (%) does not match amount (%)',
            target_id, sum_amount, exp.amount
            using errcode = '23514';
    end if;

    if exp.split_type = 'percent' then
        select count(*) into bad_rows
          from public.expense_splits
         where expense_id = target_id and share_percent is null;

        if bad_rows > 0 then
            raise exception 'Expense % uses percent split but % rows are missing share_percent', target_id, bad_rows
                using errcode = '23514';
        end if;

        if abs(sum_percent - 100) > 0.01 then
            raise exception 'Expense % percent split must total 100, got %', target_id, sum_percent
                using errcode = '23514';
        end if;
    end if;

    if exp.split_type = 'shares' then
        select count(*) into bad_rows
          from public.expense_splits
         where expense_id = target_id and share_count is null;

        if bad_rows > 0 then
            raise exception 'Expense % uses shares split but % rows are missing share_count', target_id, bad_rows
                using errcode = '23514';
        end if;

        if sum_shares <= 0 then
            raise exception 'Expense % shares split must total > 0', target_id
                using errcode = '23514';
        end if;
    end if;

    if exp.split_type = 'exact' then
        select count(*) into bad_rows
          from public.expense_splits
         where expense_id = target_id and amount_owed is null;

        if bad_rows > 0 then
            raise exception 'Expense % uses exact split but % rows are missing amount_owed', target_id, bad_rows
                using errcode = '23514';
        end if;
    end if;

    -- 1-1 expenses (no group) must be between exactly two friends including the payer.
    if exp.group_id is null then
        if split_count <> 2 then
            raise exception 'Expense % without a group must have exactly 2 participants, got %', target_id, split_count
                using errcode = '23514';
        end if;

        if not exists (
            select 1 from public.expense_splits
             where expense_id = target_id and user_id = exp.paid_by
        ) then
            raise exception 'Expense % paid_by user must also be a participant', target_id
                using errcode = '23514';
        end if;
    end if;

    return coalesce(new, old);
end;
$$;

-- Constraint trigger lets us insert expense + splits in one transaction.
drop trigger if exists trg_validate_expense_splits_iud on public.expense_splits;
create constraint trigger trg_validate_expense_splits_iud
    after insert or update or delete on public.expense_splits
    deferrable initially deferred
    for each row execute function public.tg_validate_expense_splits();
