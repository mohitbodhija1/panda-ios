# Supabase wiring for PandaSplit (iOS)

This guide covers the one-time Xcode setup required after pulling in the
new `Core/Supabase`, `Models/DTO`, and `Services` folders.

## 1. Add the SPM dependency

In Xcode:

1. **File → Add Package Dependencies…**
2. Paste `https://github.com/supabase/supabase-swift`
3. Choose **Up to Next Major Version → 2.20.0** (or newer)
4. Add the **Supabase** product to the
   *PandaSplit - Bill Splitter & Group Expense Tracker* target

The new files under `Core/Supabase/`, `Models/DTO/`, and `Services/` are picked
up automatically because the target uses the synced filesystem group.

## 2. Configure your project URL + anon key

Either add user-defined keys to `Info.plist`:

```xml
<key>SUPABASE_URL</key>
<string>https://<project-ref>.supabase.co</string>
<key>SUPABASE_ANON_KEY</key>
<string>eyJhbGciOi...</string>
```

…or expose them as scheme environment variables (Edit Scheme → Run → Arguments
→ Environment Variables).

`SupabaseEnvironment.swift` falls back to `http://127.0.0.1:54321` so a freshly
cloned checkout points at a `supabase start` instance by default.

## 3. Migration map (DTO → existing presentation types)

| Existing UI type | New DTO source                                              |
| ---------------- | ----------------------------------------------------------- |
| `MockFriend`     | `FriendsService.shared.friendsWithBalances()`               |
| `MockGroup`      | `GroupsService.shared.myGroups()` + `myBalanceAcrossGroups` |
| `MockExpense`    | `ExpensesService.shared.list(groupId:)`                     |
| `MockActivity`   | `ActivityService.shared.recent()`                           |
| Home hero card   | `HomeService.shared.summary()`                              |

The DTOs live under `Models/DTO/`. Map them onto the existing presentational
structs (`MockGroup`, etc.) inside small per-screen view models so the
pixel-perfect UI stays untouched while the data source swaps. Example:

```swift
@Observable @MainActor
final class GroupsListViewModel {
    private(set) var rows: [MockGroup] = []
    private(set) var isLoading = false
    private(set) var error: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let groups   = try await GroupsService.shared.myGroups()
            let balances = try await GroupsService.shared.myBalanceAcrossGroups()
            let netByGroup = Dictionary(uniqueKeysWithValues: balances.map { ($0.groupId, $0.balance) })
            rows = groups.map { g in
                MockGroup(
                    name: g.name,
                    emoji: "👥",
                    membersCount: 0, // TODO: GroupsService.shared.members(of:)
                    yourBalance: netByGroup[g.id] ?? 0,
                    accent: AppColor.pandaBlue
                )
            }
        } catch {
            self.error = AppError.wrap(error).errorDescription
        }
    }
}
```

Then in `GroupsListView`:

```swift
@State private var viewModel = GroupsListViewModel()

var body: some View {
    /* ...existing layout... */
    .task { await viewModel.load() }
}
```

## 4. Push notifications

After signing in, register the device token with Supabase:

```swift
// in your AppDelegate
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Task { await DeviceTokensService.shared.register(token: deviceToken) }
}
```

The `notify_on_expense` / `notify_on_settlement` Edge Functions look these up.

## 5. Sign in with Apple (native iOS)

The app exchanges Apple's ID token for a Supabase session via
`AuthSession.signInWithApple` ([AuthSession.swift](AppSource/Core/Supabase/AuthSession.swift)).
Configure the provider once per hosted project:

1. In the [Supabase Dashboard](https://supabase.com/dashboard) open **Authentication → Sign In / Providers → Apple** and enable the provider.
2. For a **native-only** iOS app, add your Xcode **Bundle Identifier** (e.g.
   `bodhija.PandaSplit---Bill-Splitter---Group-Expense-Tracker`) to **Client IDs**
   so GoTrue accepts tokens issued to that app. You do **not** need the OAuth
   Services ID, website URLs, or rotating `.p8` client secret unless you also
   offer Sign in with Apple on the web.
3. In [Apple Developer → Identifiers](https://developer.apple.com/account/resources/identifiers/list/bundleId),
   edit the same App ID and turn on the **Sign In with Apple** capability so the
   entitlement in [PandaSplit.entitlements](PandaSplit.entitlements) is valid in
   production.

Official reference: [Login with Apple (Swift)](https://supabase.com/docs/guides/auth/social-login/auth-apple?platform=swift).

## 6. Disable email confirmation on the hosted project

`supabase db push` only deploys SQL migrations, **not** the `[auth]` block in
`supabase/config.toml`. The local stack already runs with
`enable_confirmations = false`, but the hosted project keeps its own copy of
that flag. After provisioning a new project, go to
**Authentication → Sign In / Providers → Email** in the Supabase dashboard
and turn **Confirm email** OFF (and, if you want passwordless flows
disabled, untick the magic-link option). Without this flip, `signUp` returns
a `User` with no `Session` and the app's `signIn` fallback in
`[AppSource/Core/Supabase/AuthSession.swift](AppSource/Core/Supabase/AuthSession.swift)`
will surface an "Email not confirmed" error.

## 7. Local development

```bash
cd ../supabase
supabase start
supabase db reset    # applies all migrations + seed.sql
```

Then run the Xcode target with `SUPABASE_URL=http://127.0.0.1:54321` and the
local anon key printed by `supabase status`.
