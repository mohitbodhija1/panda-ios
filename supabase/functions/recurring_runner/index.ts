// Edge Function: recurring_runner
// Trigger: cron (configured via supabase/functions/recurring_runner/cron.json
// or via pg_cron / Supabase Scheduled Functions UI). Runs once per day.

import { serviceClient } from "../_shared/supabase.ts";

interface SplitItem {
    user_id: string;
    amount_owed?: number;
    share_percent?: number;
    share_count?: number;
}

interface RecurringRow {
    id: string;
    group_id: string | null;
    title: string;
    notes: string | null;
    emoji: string | null;
    category_id: number | null;
    amount: string;
    currency: string;
    paid_by: string;
    split_type: "equal" | "exact" | "percent" | "shares";
    split_payload: SplitItem[];
    frequency: "daily" | "weekly" | "monthly" | "yearly";
    interval_count: number;
    next_run_on: string;
}

function advance(date: string, frequency: RecurringRow["frequency"], n: number): string {
    const d = new Date(date + "T00:00:00Z");
    switch (frequency) {
        case "daily":   d.setUTCDate(d.getUTCDate() + n); break;
        case "weekly":  d.setUTCDate(d.getUTCDate() + 7 * n); break;
        case "monthly": d.setUTCMonth(d.getUTCMonth() + n); break;
        case "yearly":  d.setUTCFullYear(d.getUTCFullYear() + n); break;
    }
    return d.toISOString().slice(0, 10);
}

Deno.serve(async () => {
    const sb = serviceClient();
    const today = new Date().toISOString().slice(0, 10);

    const { data: due, error } = await sb
        .from("recurring_expenses")
        .select("*")
        .eq("is_active", true)
        .lte("next_run_on", today)
        .returns<RecurringRow[]>();

    if (error) return new Response(error.message, { status: 500 });
    if (!due || due.length === 0) return new Response(JSON.stringify({ ran: 0 }));

    let ran = 0;
    for (const r of due) {
        const payload = {
            group_id: r.group_id,
            title: r.title,
            notes: r.notes,
            emoji: r.emoji,
            category_id: r.category_id,
            amount: r.amount,
            currency: r.currency,
            paid_by: r.paid_by,
            split_type: r.split_type,
            splits: r.split_payload,
        };
        const { error: rpcErr } = await sb.rpc("rpc_create_expense", { payload });
        if (rpcErr) { console.warn("rpc_create_expense failed", r.id, rpcErr.message); continue; }

        await sb
            .from("recurring_expenses")
            .update({
                last_run_on: today,
                next_run_on: advance(r.next_run_on, r.frequency, r.interval_count),
            })
            .eq("id", r.id);

        ran += 1;
    }

    return new Response(JSON.stringify({ ran }), { headers: { "content-type": "application/json" } });
});
