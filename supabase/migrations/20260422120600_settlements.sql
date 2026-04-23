-- Migration: settlements
-- Direct payments to clear debt. Immutable: no UPDATE/DELETE; reverse via a new
-- entry. Affects balance views directly via aggregation.

create table if not exists public.settlements (
    id              uuid primary key default gen_random_uuid(),
    group_id        uuid references public.groups(id) on delete cascade,
    payer_id        uuid not null references public.profiles(id) on delete restrict,
    payee_id        uuid not null references public.profiles(id) on delete restrict,
    amount              numeric(14,2) not null check (amount > 0),
    currency            char(3) not null references public.currencies(code),
    fx_to_group_rate    numeric(18,8) check (fx_to_group_rate is null or fx_to_group_rate > 0),
    method              text not null check (method in ('cash','upi','venmo','paypal','in_app','other')) default 'cash',
    note            text,
    settled_at      timestamptz not null default now(),
    created_by      uuid not null references public.profiles(id) on delete restrict,
    created_at      timestamptz not null default now(),
    check (payer_id <> payee_id)
);

create index if not exists settlements_group_idx
    on public.settlements (group_id, settled_at desc);
create index if not exists settlements_payer_idx
    on public.settlements (payer_id, settled_at desc);
create index if not exists settlements_payee_idx
    on public.settlements (payee_id, settled_at desc);

comment on table public.settlements is 'Immutable record of money transferred between two users; reverse via new entry.';

-- Snapshot FX rate to the group's default currency at settle time so historical
-- group balances stay correct even if rates move.
create or replace function public.tg_settlements_snapshot_fx()
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
       and as_of <= new.settled_at::date
     order by as_of desc
     limit 1;

    new.fx_to_group_rate := coalesce(snapshot, 1);
    return new;
end;
$$;

drop trigger if exists trg_settlements_snapshot_fx on public.settlements;
create trigger trg_settlements_snapshot_fx
    before insert on public.settlements
    for each row execute function public.tg_settlements_snapshot_fx();

-- Make immutability explicit at the DB layer.
create or replace function public.tg_settlements_immutable()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    raise exception 'Settlements are immutable; create a reversing entry instead.'
        using errcode = '0A000';
    return null;
end;
$$;

drop trigger if exists trg_settlements_no_update on public.settlements;
create trigger trg_settlements_no_update
    before update on public.settlements
    for each row execute function public.tg_settlements_immutable();

drop trigger if exists trg_settlements_no_delete on public.settlements;
create trigger trg_settlements_no_delete
    before delete on public.settlements
    for each row execute function public.tg_settlements_immutable();
