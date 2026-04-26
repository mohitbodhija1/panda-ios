# Push Notifications — End-to-End Setup

This guide walks you through every step required to make push notifications
work for PandaSplit, from Apple Developer to the iOS app to Supabase Edge
Functions. After following it, the **Settings → Notifications → Send Test
Push** button delivers a real APNs alert to your physical device.

> **Heads-up:** the iOS Simulator cannot receive remote APNs alerts. Test
> on a real device. (You can simulate _local_ notifications in the
> simulator, but the device-token round trip needs hardware.)

---

## Architecture overview

```
┌─────────────┐   APNs token    ┌────────────────────┐
│ iOS app     │ ──────────────▶ │ public.device_tokens│
│ (PandaSplit)│                 └────────────────────┘
└─────┬───────┘                          ▲
      │ functions.invoke("send_test_push")│
      ▼                                  │
┌──────────────────────┐  service role   │
│ Edge: send_test_push │ ◀───────────────┘
└──────┬───────────────┘
       │ ES256 JWT
       ▼
   api.push.apple.com  ─────▶ device push banner
```

The same `device_tokens` table is consumed by `notify_on_expense`,
`notify_on_settlement`, and `notify_on_friendship` for the production
event-driven pushes; `send_test_push` is the on-demand variant fired by
the test button in Settings.

---

## 1. Apple Developer prerequisites

You need three values from the Apple Developer portal:

| Variable             | Where to get it                                          |
| -------------------- | -------------------------------------------------------- |
| `APNS_TEAM_ID`       | Apple Developer → Membership Details → Team ID (10 char) |
| `APNS_BUNDLE_ID`     | The Xcode target's bundle identifier                     |
| `APNS_KEY_ID` + `.p8`| Apple Developer → Certificates, Identifiers & Profiles → **Keys** → "+" → enable **Apple Push Notifications service (APNs)**. Download the `.p8` once. |

> ⚠️ The `.p8` file can only be downloaded **once**. Stash it somewhere
> safe (a password manager works well).

Convert the `.p8` contents into a multi-line PEM string when you paste
it into Supabase function secrets — keep the `-----BEGIN PRIVATE KEY-----`
and `-----END PRIVATE KEY-----` lines and the newlines between the body.

### Enable APNs on the App ID

In **Identifiers**, edit the App ID matching `APNS_BUNDLE_ID` and tick
**Push Notifications** under Capabilities. Save.

---

## 2. Xcode project setup

The repo already includes the entitlement and the iOS plumbing. Verify:

1. **Signing & Capabilities** for the
   *PandaSplit - Bill Splitter & Group Expense Tracker* target lists
   **Push Notifications**. If it doesn't, add it via **+ Capability**.
2. `PandaSplit.entitlements` has `aps-environment`:
   - `development` while you're using a Debug build
   - `production` for App Store / TestFlight Release builds
3. The SwiftUI app entry point already wires the delegate:

   ```swift
   @UIApplicationDelegateAdaptor(PushAppDelegate.self) private var pushDelegate
   ```

   See `AppSource/PandaSplit___Bill_Splitter___Group_Expense_TrackerApp.swift`.
4. `RootView` automatically requests authorization once the user is
   signed in:

   ```swift
   .task(id: session.isAuthenticated) {
       guard session.isAuthenticated else { return }
       await PushManager.ensurePermissionAndRegister()
   }
   ```

5. The token handshake is implemented in
   `AppSource/App/PushNotifications.swift`. It forwards the token to
   `DeviceTokensService.register(token:)` which upserts into
   `public.device_tokens` (RLS scoped to the current user).

> If you change bundle id or team, regenerate provisioning profiles in
> Xcode (**Product → Destination → Any iOS Device** then **Try Again**
> in Signing & Capabilities).

---

## 3. Supabase function secrets

Set these once per environment (local + hosted). Either via the
dashboard (**Project Settings → Edge Functions → Secrets**) or the CLI:

```bash
cd supabase
supabase secrets set \
    APNS_TEAM_ID=KFYZTB84NM \
    APNS_KEY_ID=9N642JLTFJ \
    APNS_BUNDLE_ID=bodhija.PandaSplit---Bill-Splitter---Group-Expense-Tracker \
    APNS_USE_SANDBOX=true \
    APNS_PRIVATE_KEY="$(cat AuthKey_9N642JLTFJ.p8)"
```

Notes:

- `APNS_USE_SANDBOX=true` while iOS uses `aps-environment = development`.
  Switch to `false` (or omit) when shipping a Release build with
  `aps-environment = production`. **A mismatch is the #1 cause of
  silent failures.**
- The PEM newlines must survive the shell quoting. The `"$(cat …)"`
  pattern above preserves them. Pasting into the dashboard works too —
  paste the full multi-line text, no escaping needed.
- `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are auto-injected on
  the hosted runtime; set them manually only for `supabase functions
  serve` against a local-but-non-supabase backend.

---

## 4. Deploy the Edge Functions

```bash
cd supabase
supabase functions deploy send_test_push          # NEW: powers the test button
supabase functions deploy notify_on_expense
supabase functions deploy notify_on_settlement
supabase functions deploy notify_on_friendship
```

`send_test_push` requires `verify_jwt = true` (the default) so the
function can identify the caller from the iOS bearer token. Do **not**
add an entry for it in `supabase/config.toml`'s `[functions.*]` blocks
— those exist only to flip JWT verification _off_ for the webhook /
cron-driven functions.

---

## 5. Database webhooks (production push events)

Configure these in the dashboard at **Database → Webhooks** so writes
fan out to APNs automatically.

| Source table          | Event(s)         | Function URL                                     |
| --------------------- | ---------------- | ------------------------------------------------ |
| `public.expenses`     | INSERT           | `…/functions/v1/notify_on_expense`               |
| `public.settlements`  | INSERT           | `…/functions/v1/notify_on_settlement`            |
| `public.friendships`  | UPDATE, DELETE   | `…/functions/v1/notify_on_friendship`            |
| `public.friend_invites` | INSERT         | `…/functions/v1/friend_invite_link`              |

Each webhook should send the default Supabase payload format
(`type`, `table`, `record`, `old_record`). Headers can be left blank —
the receiving functions are JWT-disabled (`verify_jwt = false` in
`supabase/config.toml`) precisely so webhook traffic doesn't need a
bearer token.

---

## 6. Smoke-test the pipeline

1. Build & run on a **real device** (Cmd-R in Xcode against a connected
   iPhone). The simulator will silently fail because it has no APNs
   stack.
2. Sign in. iOS shows the system permission prompt → tap **Allow**.
   `RootView` calls `PushManager.ensurePermissionAndRegister()`, which
   triggers `PushAppDelegate.didRegisterForRemote…`, which upserts a
   row into `public.device_tokens`.
   - Verify with `select user_id, token, last_seen_at from device_tokens
     where user_id = auth.uid();` in the SQL editor.
3. Open **Settings → Notifications**. The first row should read
   *Notifications Enabled*.
4. Tap **Send Test Push**. Within ~1 second you should see:
   - A banner on your device titled *🐼 Test push from PandaSplit*.
   - In Settings, the status text below the card: *Sent to 1 device(s)
     — delivered: 1, failed: 0.*
5. To exercise production paths, add an expense in a group with a
   second user. Their device should receive the *<You> added an
   expense* notification driven by `notify_on_expense`.

---

## 7. Troubleshooting

| Symptom                                  | Likely cause                                                                  |
| ---------------------------------------- | ----------------------------------------------------------------------------- |
| `No registered device tokens`            | Running on simulator, or you tapped "Don't Allow" on the iOS prompt.          |
| `failed: 1` with `BadDeviceToken`        | `APNS_USE_SANDBOX` doesn't match `aps-environment` (Debug ↔ sandbox=true).    |
| `failed: 1` with `InvalidProviderToken`  | Wrong `APNS_TEAM_ID` / `APNS_KEY_ID`, or PEM body lost newlines on paste.     |
| `failed: 1` with `Unregistered`          | Token was revoked (e.g. user deleted the app). The function auto-cleans 410s. |
| `401 invalid token`                      | The Supabase session expired. Sign out and back in.                           |
| Nothing happens at all on tap            | Check Xcode console for `[Push] registration failed:` — usually missing       |
|                                          | provisioning profile or APNs capability disabled on the App ID.               |

For deeper debugging, run the function locally:

```bash
cd supabase
supabase functions serve send_test_push --env-file ./.env.local --no-verify-jwt
```

Then `curl` it with a real bearer token from the app's keychain (DM the
session JWT to yourself with `print(SupabaseProvider.auth.session)` for
testing only — never commit real tokens).

---

## 8. Removing the test button

The button lives in `AppSource/Features/Settings/SettingsView.swift` under
the *Notifications* section. Delete the `notificationsCard` view (or just
the `paperplane.fill` Button) once you no longer need it. The matching
`NotificationsService.sendTestPush()` and the `send_test_push` Edge
Function can stay — they're cheap and useful for ongoing verification.
