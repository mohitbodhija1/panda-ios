-- Optional dev seed. Safe to skip in production.
-- Inserts a baseline FX rate row so cross-currency expenses balance even
-- before fx_refresh has run.

insert into public.fx_rates (base, quote, as_of, rate) values
    ('USD', 'EUR', current_date, 0.92),
    ('USD', 'GBP', current_date, 0.79),
    ('USD', 'INR', current_date, 83.10),
    ('USD', 'JPY', current_date, 156.40),
    ('USD', 'AUD', current_date, 1.51),
    ('USD', 'CAD', current_date, 1.36),
    ('USD', 'SGD', current_date, 1.34),
    ('USD', 'AED', current_date, 3.67),
    ('USD', 'CHF', current_date, 0.91)
on conflict (base, quote, as_of) do nothing;
