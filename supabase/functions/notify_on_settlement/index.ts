// Edge Function: notify_on_settlement
// Trigger: Supabase Database Webhook on `INSERT public.settlements`.
// Notifies the payee that the payer has settled up.

import { serviceClient } from "../_shared/supabase.ts";
import { sendApns } from "../_shared/apns.ts";

interface WebhookPayload {
    type: "INSERT" | "UPDATE" | "DELETE";
    table: string;
    record: {
        id: string;
        group_id: string | null;
        payer_id: string;
        payee_id: string;
        amount: string;
        currency: string;
    };
}

Deno.serve(async (req) => {
    if (req.method !== "POST") return new Response("method not allowed", { status: 405 });

    const event = (await req.json()) as WebhookPayload;
    if (event.type !== "INSERT" || event.table !== "settlements") {
        return new Response("ignored", { status: 200 });
    }

    const s = event.record;
    const sb = serviceClient();

    const { data: payer } = await sb
        .from("profiles").select("full_name").eq("id", s.payer_id).maybeSingle();
    const payerName = payer?.full_name ?? "Someone";

    const title = `${payerName} paid you back`;
    const body  = `${s.currency} ${s.amount}`;

    await sb.from("notifications").insert({
        user_id: s.payee_id,
        kind: "settlement_created",
        title, body,
        payload: { settlement_id: s.id, group_id: s.group_id, amount: s.amount, currency: s.currency },
    });

    const { data: tokens } = await sb
        .from("device_tokens")
        .select("token")
        .eq("user_id", s.payee_id);
    const tokenList = (tokens ?? []).map((t) => t.token);

    if (tokenList.length === 0) return new Response(JSON.stringify({ pushed: 0 }));

    const results = await sendApns(tokenList, {
        title, body,
        extra: { settlement_id: s.id, group_id: s.group_id },
    });

    const failed = results.filter((r) => r.status === 410).map((r) => r.token);
    if (failed.length > 0) await sb.from("device_tokens").delete().in("token", failed);

    return new Response(JSON.stringify({ pushed: results.length, failed: failed.length }));
});
