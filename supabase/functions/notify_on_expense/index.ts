// Edge Function: notify_on_expense
// Trigger: Supabase Database Webhook on `INSERT public.expenses`.
// Behaviour:
//   1. Resolve all participants (splits + group members) excluding the payer.
//   2. Insert a `notifications` row per participant.
//   3. Look up their device tokens and dispatch APNs alerts.

import { serviceClient } from "../_shared/supabase.ts";
import { sendApns } from "../_shared/apns.ts";

interface WebhookPayload {
    type: "INSERT" | "UPDATE" | "DELETE";
    table: string;
    record: { id: string; group_id: string | null; paid_by: string; title: string; amount: string; currency: string };
}

Deno.serve(async (req) => {
    if (req.method !== "POST") return new Response("method not allowed", { status: 405 });

    const event = (await req.json()) as WebhookPayload;
    if (event.type !== "INSERT" || event.table !== "expenses") {
        return new Response("ignored", { status: 200 });
    }

    const expense = event.record;
    const sb = serviceClient();

    const { data: splits, error: splitsErr } = await sb
        .from("expense_splits")
        .select("user_id")
        .eq("expense_id", expense.id);
    if (splitsErr) return new Response(splitsErr.message, { status: 500 });

    const recipientSet = new Set<string>(splits?.map((r) => r.user_id) ?? []);
    if (expense.group_id) {
        const { data: members } = await sb
            .from("group_members")
            .select("user_id")
            .eq("group_id", expense.group_id);
        members?.forEach((m) => recipientSet.add(m.user_id));
    }
    recipientSet.delete(expense.paid_by);

    if (recipientSet.size === 0) return new Response("no recipients", { status: 200 });

    const { data: payer } = await sb
        .from("profiles").select("full_name").eq("id", expense.paid_by).maybeSingle();
    const payerName = payer?.full_name ?? "Someone";

    const title = `${payerName} added an expense`;
    const body  = `${expense.title} · ${expense.currency} ${expense.amount}`;

    const recipients = [...recipientSet];

    const notifRows = recipients.map((userId) => ({
        user_id: userId,
        kind: "expense_created",
        title, body,
        payload: {
            expense_id: expense.id,
            group_id: expense.group_id,
            amount: expense.amount,
            currency: expense.currency,
        },
    }));
    await sb.from("notifications").insert(notifRows);

    const { data: tokens } = await sb
        .from("device_tokens")
        .select("token")
        .in("user_id", recipients);

    const tokenList = (tokens ?? []).map((t) => t.token);
    if (tokenList.length === 0) return new Response(JSON.stringify({ recipients: recipients.length, pushed: 0 }), { status: 200 });

    const results = await sendApns(tokenList, {
        title, body,
        extra: { expense_id: expense.id, group_id: expense.group_id },
    });

    const failed = results.filter((r) => r.status === 410).map((r) => r.token);
    if (failed.length > 0) await sb.from("device_tokens").delete().in("token", failed);

    return new Response(
        JSON.stringify({ recipients: recipients.length, pushed: results.length, failed: failed.length }),
        { headers: { "content-type": "application/json" } },
    );
});
