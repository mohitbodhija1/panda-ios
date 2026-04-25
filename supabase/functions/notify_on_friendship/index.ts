// Edge Function: notify_on_friendship
// Trigger: Database Webhooks on public.friendships UPDATE (accepted) and DELETE (pending).
// Notifies the inviter (requested_by): accept / decline inbox row + optional APNs.

import { serviceClient } from "../_shared/supabase.ts";
import { sendApns } from "../_shared/apns.ts";

interface FriendshipRow {
    user_a: string;
    user_b: string;
    requested_by: string;
    status: string;
}

interface WebhookPayload {
    type: string;
    table?: string;
    record?: FriendshipRow | null;
    old_record?: FriendshipRow | null;
}

function counterpart(userA: string, userB: string, known: string): string {
    return known === userA ? userB : userA;
}

async function displayName(sb: ReturnType<typeof serviceClient>, userId: string): Promise<string> {
    const { data } = await sb
        .from("profiles")
        .select("full_name,username,email,phone")
        .eq("id", userId)
        .maybeSingle();
    if (!data) return "Someone";
    const d = data as Record<string, string | null | undefined>;
    const parts = [d.full_name, d.username, d.email, d.phone]
        .map((x) => (typeof x === "string" ? x.trim() : ""))
        .filter((x) => x.length > 0);
    return parts[0] ?? "Someone";
}

async function notifyInviter(
    inviterId: string,
    kind: "friend_accepted" | "friend_declined",
    title: string,
    body: string,
    payload: Record<string, string>,
) {
    const sb = serviceClient();
    await sb.from("notifications").insert({
        user_id: inviterId,
        kind,
        title,
        body,
        payload,
    });

    const { data: tokens } = await sb.from("device_tokens").select("token").eq("user_id", inviterId);
    const tokenList = (tokens ?? []).map((t) => t.token);
    if (tokenList.length === 0) return;

    const results = await sendApns(tokenList, { title, body, extra: payload });
    const failed = results.filter((r) => r.status === 410).map((r) => r.token);
    if (failed.length > 0) await sb.from("device_tokens").delete().in("token", failed);
}

Deno.serve(async (req) => {
    if (req.method !== "POST") return new Response("method not allowed", { status: 405 });

    const event = (await req.json()) as WebhookPayload;
    if (event.table !== "friendships") return new Response("ignored", { status: 200 });

    const sb = serviceClient();

    if (event.type === "UPDATE" && event.record?.status === "accepted") {
        const row = event.record;
        const inviter = row.requested_by;
        const accepter = counterpart(row.user_a, row.user_b, inviter);
        const name = await displayName(sb, accepter);
        const title = "Friend request accepted";
        const body = `${name} accepted your friend request`;
        const payload = { friend_id: accepter };
        await notifyInviter(inviter, "friend_accepted", title, body, payload);
        return new Response(JSON.stringify({ ok: true, kind: "friend_accepted" }), {
            headers: { "content-type": "application/json" },
        });
    }

    if (event.type === "DELETE" && event.old_record?.status === "pending") {
        const row = event.old_record;
        const inviter = row.requested_by;
        const other = counterpart(row.user_a, row.user_b, inviter);
        const name = await displayName(sb, other);
        const title = "Friend request declined";
        const body = `${name} declined your friend request`;
        const payload = { friend_id: other };
        await notifyInviter(inviter, "friend_declined", title, body, payload);
        return new Response(JSON.stringify({ ok: true, kind: "friend_declined" }), {
            headers: { "content-type": "application/json" },
        });
    }

    return new Response("ignored", { status: 200 });
});
