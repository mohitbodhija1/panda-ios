-- Migration: lookups
-- Currencies, FX rates, and expense categories.
-- These tables are reference data; consumed by FK constraints throughout the schema.

-- Supabase pre-installs pgcrypto and citext in the `extensions` schema.
-- These no-op locally and on remote, but make the dependency explicit.
create extension if not exists "pgcrypto";
create extension if not exists "citext";

-- ============================================================================
-- currencies (ISO 4217 subset; expand as needed)
-- ============================================================================
create table if not exists public.currencies (
    code        char(3) primary key,
    name        text    not null,
    symbol      text    not null,
    decimals    smallint not null default 2 check (decimals between 0 and 4)
);

comment on table public.currencies is 'ISO 4217 currency codes used by expenses and settlements.';

insert into public.currencies (code, name, symbol, decimals) values
    ('USD', 'US Dollar',         '$',   2),
    ('EUR', 'Euro',              '€',   2),
    ('GBP', 'British Pound',     '£',   2),
    ('INR', 'Indian Rupee',      '₹',   2),
    ('JPY', 'Japanese Yen',      '¥',   0),
    ('AUD', 'Australian Dollar', 'A$',  2),
    ('CAD', 'Canadian Dollar',   'C$',  2),
    ('SGD', 'Singapore Dollar',  'S$',  2),
    ('AED', 'UAE Dirham',        'د.إ', 2),
    ('CHF', 'Swiss Franc',       'CHF', 2)
on conflict (code) do nothing;

-- ============================================================================
-- fx_rates (cache of base->quote rates as of a given date)
-- ============================================================================
create table if not exists public.fx_rates (
    base    char(3) not null references public.currencies(code) on update cascade,
    quote   char(3) not null references public.currencies(code) on update cascade,
    as_of   date    not null,
    rate    numeric(18,8) not null check (rate > 0),
    primary key (base, quote, as_of)
);

create index if not exists fx_rates_quote_idx on public.fx_rates (quote, as_of desc);

comment on table public.fx_rates is 'Daily FX rates refreshed by the fx_refresh Edge Function.';

-- ============================================================================
-- expense_categories (system-curated taxonomy)
-- ============================================================================
create table if not exists public.expense_categories (
    id          smallint generated always as identity primary key,
    key         text   not null unique,
    label       text   not null,
    emoji       text   not null,
    icon        text   not null,
    is_system   boolean not null default true
);

comment on table public.expense_categories is 'Static category taxonomy surfaced in Add Expense pickers.';

insert into public.expense_categories (key, label, emoji, icon) values
    ('food',          'Food & Drink',     '🍽️', 'fork.knife'),
    ('groceries',     'Groceries',        '🛒', 'cart.fill'),
    ('travel',        'Travel',           '✈️', 'airplane'),
    ('lodging',       'Lodging',          '🏨', 'bed.double.fill'),
    ('transport',     'Transport',        '🚕', 'car.fill'),
    ('rent',          'Rent',             '🏠', 'house.fill'),
    ('utilities',     'Utilities',        '💡', 'bolt.fill'),
    ('entertainment', 'Entertainment',    '🎬', 'film.fill'),
    ('shopping',      'Shopping',         '🛍️', 'bag.fill'),
    ('gifts',         'Gifts',            '🎁', 'gift.fill'),
    ('health',        'Health',           '🏥', 'heart.fill'),
    ('other',         'Other',            '🔖', 'tag.fill')
on conflict (key) do nothing;

-- ============================================================================
-- updated_at touch trigger (reused throughout the schema)
-- ============================================================================
create or replace function public.tg_set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

comment on function public.tg_set_updated_at is 'Generic BEFORE UPDATE trigger that bumps updated_at.';
