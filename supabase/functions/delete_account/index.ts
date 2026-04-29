// Edge Function: delete_account
// Verifies the caller JWT, anonymizes DB references, clears avatars storage, then deletes auth user.

import { serviceClient } from "../_shared/supabase.ts";

function json(body: unknown, status = 200): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: { "content-type": "application/json" },
    });
}

Deno.serve(async (req) => {
    if (req.method !== "POST") {
        return new Response("method not allowed", { status: 405 });
    }

    const authHeader = req.headers.get("authorization") ?? "";
    if (!authHeader.toLowerCase().startsWith("bearer ")) {
        return json({ error: "missing bearer token" }, 401);
    }
    const accessToken = authHeader.slice("bearer ".length).trim();

    const sb = serviceClient();
    const { data: userData, error: userErr } = await sb.auth.getUser(accessToken);
    if (userErr || !userData?.user?.id) {
        return json({ error: "invalid token" }, 401);
    }
    const userId = userData.user.id;

    const { error: rpcErr } = await sb.rpc("fn_anonymize_account", { target: userId });
    if (rpcErr) {
        return json({ error: rpcErr.message }, 500);
    }

    // Best-effort: remove objects under avatars/<user_id>/
    try {
        const { data: files, error: listErr } = await sb.storage.from("avatars").list(userId, {
            limit: 100,
            offset: 0,
        });
        if (!listErr && files && files.length > 0) {
            const paths = files.map((f) => `${userId}/${f.name}`);
            await sb.storage.from("avatars").remove(paths);
        }
    } catch {
        /* non-fatal */
    }

    const { error: delErr } = await sb.auth.admin.deleteUser(userId);
    if (delErr) {
        return json({ error: delErr.message }, 500);
    }

    return json({ ok: true });
});
