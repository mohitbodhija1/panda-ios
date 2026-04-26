// Edge Function: send_test_push
//
// Trigger: invoked from the iOS app (Settings → Notifications → "Send
// Test Push"). Uses the caller's JWT to identify the user, looks up
// every device token registered for them and dispatches a sample APNs
// alert via the shared `sendApns` helper.
//
// Security: this function expects `verify_jwt = true` (the default). The
// supabase-js service-role client bypasses RLS so we can read the user's
// device tokens after we've authenticated them via the JWT.

import { serviceClient } from "../_shared/supabase.ts";
import { sendApns } from "../_shared/apns.ts";

interface ResultBody {
    user_id: string;
    devices: number;     // total device tokens stored for this user
    pushed: number;      // count APNs accepted (HTTP 2xx)
    failed: number;      // count APNs rejected (non-2xx)
    statuses: Array<{ status: number; reason?: string }>;
}

function json(body: unknown, status: number = 200): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: { "content-type": "application/json" },
    });
}

Deno.serve(async (req) => {
    if (req.method !== "POST") {
        return new Response("method not allowed", { status: 405 });
    }

    // 1. Resolve caller identity from the bearer token.
    const auth = req.headers.get("authorization") ?? "";
    if (!auth.toLowerCase().startsWith("bearer ")) {
        return json({ error: "missing bearer token" }, 401);
    }
    const accessToken = auth.slice("bearer ".length).trim();

    const sb = serviceClient();
    const { data: userData, error: userErr } = await sb.auth.getUser(accessToken);
    if (userErr || !userData?.user?.id) {
        return json({ error: "invalid token" }, 401);
    }
    const userId = userData.user.id;

    // 2. Optional title/body override from the client. Defaults below
    //    keep the function useful even with no body.
    let title = "🐼 Test push from PandaSplit";
    let body  = "If you can read this, your device is wired up correctly.";
    try {
        const overrides = await req.json() as { title?: unknown; body?: unknown };
        if (overrides && typeof overrides === "object") {
            if (typeof overrides.title === "string") title = overrides.title;
            if (typeof overrides.body  === "string") body  = overrides.body;
        }
    } catch { /* no body or not JSON: keep defaults */ }

    // 3. Look up the caller's device tokens.
    const { data: tokens, error: tokensErr } = await sb
        .from("device_tokens")
        .select("token")
        .eq("user_id", userId);
    if (tokensErr) {
        return json({ error: tokensErr.message }, 500);
    }

    const tokenList = (tokens ?? []).map((t) => t.token);

    if (tokenList.length === 0) {
        const empty: ResultBody = {
            user_id: userId, devices: 0, pushed: 0, failed: 0, statuses: [],
        };
        return json(empty);
    }

    // 4. Fan out to APNs.
    const results = await sendApns(tokenList, {
        title, body,
        extra: { test: true, user_id: userId },
    });

    // 5. Reap permanently-bad tokens (HTTP 410 Gone) so the table doesn't
    //    accumulate dead devices over time.
    const dead = results
        .filter((r) => r.status === 410)
        .map((r) => r.token);
    if (dead.length > 0) {
        await sb.from("device_tokens").delete().in("token", dead);
    }

    const pushed = results.filter((r) => r.status >= 200 && r.status < 300).length;
    const failed = results.length - pushed;

    const out: ResultBody = {
        user_id: userId,
        devices: tokenList.length,
        pushed,
        failed,
        statuses: results.map((r) => ({ status: r.status, reason: r.reason })),
    };
    return json(out);
});
