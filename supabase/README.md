# PandaSplit Supabase Backend

Postgres schema, RLS policies, RPCs, views, and Edge Functions powering the iOS app.

## Layout

```
supabase/
  config.toml                  Local stack config (CLI)
  seed.sql                     Optional dev seed (FX rates)
  migrations/                  Applied in lexicographic order
    20260422120000_lookups.sql
    20260422120100_profiles.sql
    20260422120200_friends.sql
    20260422120300_groups.sql
    20260422120400_recurring_expenses.sql
    20260422120500_expenses.sql
    20260422120600_settlements.sql
    20260422120700_engagement.sql
    20260422120800_views.sql
    20260422120900_rls.sql
    20260422121000_rpcs.sql
    20260422121100_storage.sql
  functions/
    _shared/                   Service-role client + APNs helper
    notify_on_expense/         DB webhook -> APNs
    notify_on_settlement/      DB webhook -> APNs
    notify_on_friendship/      DB webhook -> inbox + APNs (friend accept / decline)
    friend_invite_link/        DB webhook -> Resend / Twilio
    recurring_runner/          Daily cron
    fx_refresh/                Daily cron
```

## Local development

```bash
brew install supabase/tap/supabase   # one-time
cd supabase
supabase start                       # spins up Postgres + Auth + Storage + Studio on 54321..54324
supabase db reset                    # applies all migrations + seed.sql
```

Studio lives at http://localhost:54323.

## Deploying

```bash
# Link your project (one-time)
supabase link --project-ref <ref>

# Push schema
supabase db push

# Deploy functions
supabase functions deploy notify_on_expense
supabase functions deploy notify_on_settlement
supabase functions deploy notify_on_friendship
supabase functions deploy friend_invite_link
supabase functions deploy recurring_runner
supabase functions deploy fx_refresh
```

## Wiring

After `db push` and `functions deploy`, configure in the Supabase dashboard:

1. **Database Webhooks**
   - `public.expenses` INSERT  -> Edge Function `notify_on_expense`
   - `public.settlements` INSERT -> Edge Function `notify_on_settlement`
   - `public.friendships` UPDATE -> Edge Function `notify_on_friendship` (notify inviter when status becomes `accepted`)
   - `public.friendships` DELETE -> Edge Function `notify_on_friendship` (notify inviter when a **pending** row is removed, e.g. recipient declined)
   - `public.friend_invites` INSERT -> Edge Function `friend_invite_link`
2. **Scheduled Functions** (`select cron.schedule(...)` or dashboard)
   - `recurring_runner` daily at 02:00 UTC
   - `fx_refresh` daily at 04:00 UTC
3. **Function secrets**
   - `APNS_TEAM_ID`, `APNS_KEY_ID`, `APNS_PRIVATE_KEY`, `APNS_BUNDLE_ID`, `APNS_USE_SANDBOX`
   - `RESEND_API_KEY`, `RESEND_FROM`
   - `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_FROM`
   - `APP_URL`
   - `FX_PROVIDER_URL` (optional override)

## Schema overview

See `supabase_backend_schema_*.plan.md` in `.cursor/plans/` for the full design.
Highlights:

- All money math lives in views (`v_user_group_balance`, `v_user_friend_balance`,
  `v_home_summary`) so the iOS app cannot drift.
- Expense splits are validated by a deferrable constraint trigger; sums must
  equal the parent expense within a 0.02 tolerance.
- Friendships are stored as a canonical pair (`user_a < user_b`).
- Settlements are immutable - reverse via a new entry.
- FX is snapshotted at expense / settlement creation against the group's
  default currency for stable historical balances.

## Troubleshooting: expense save failures

Three layers often show up as a generic Postgres error in the client:

1. **`rpc_create_expense` runs as `SECURITY DEFINER`** since [`20260425220000_rpc_create_expense_security_definer.sql`](migrations/20260425220000_rpc_create_expense_security_definer.sql). It enforces auth + group-membership / friend rules at the top, then writes `expenses`, `expense_splits`, `activity_log`, and `pg_notify` in one transaction without re-checking RLS for each inner table. If you previously saw `42501` from this RPC, it almost always means you were still on the `SECURITY INVOKER` version with a missing `activity_log` insert policy or stale PostgREST schema cache. Re-run `supabase db push` to apply this migration; it ends with `notify pgrst, 'reload schema'` so PostgREST picks up the new function body immediately.

2. **Row-level security (RLS)** on `expenses`, `expense_splits`, or `activity_log` only matters for direct table writes (i.e. *not* via `rpc_create_expense`). Friend-only expenses still require `paid_by = auth.uid()` when `group_id` is null (`expenses_member_insert` in `20260422120900_rls.sql`); group expenses require `is_group_member(group_id)`. The `activity_log` insert policy lives in [`20260425190000_activity_log_insert_rls.sql`](migrations/20260425190000_activity_log_insert_rls.sql) with an idempotent follow-up at [`20260425210000_activity_log_insert_rls_idempotent.sql`](migrations/20260425210000_activity_log_insert_rls_idempotent.sql).

3. **Deferred constraint trigger** `tg_validate_expense_splits` on `expense_splits` (not RLS): split rows must sum to the expense amount (±0.02), and group-less expenses must have exactly two participants including `paid_by`. Errors here surface as `23514` and are mapped to `AppError.validation` in the client.

If you still see `42501` after `supabase db push`:

```sql
-- run in Supabase SQL editor to confirm the new function is live
select prosecdef as is_security_definer,
       proacl
  from pg_proc
 where proname = 'rpc_create_expense';

-- and to force a PostgREST reload manually
notify pgrst, 'reload schema';
```

## RPC catalogue

| Function                     | Purpose                                         |
| ---------------------------- | ----------------------------------------------- |
| `rpc_create_expense(jsonb)`  | Atomic expense + splits + activity + notify     |
| `rpc_settle_up(jsonb)`       | Insert immutable settlement + activity + notify |
| `rpc_invite_friend(text,text)` | Invite by email or phone                      |
| `rpc_accept_friend(uuid)`    | Accept a pending request                        |
| `rpc_create_recurring(jsonb)`| Create a recurring expense template             |
