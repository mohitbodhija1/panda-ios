// Edge Function: welcome_email
// Trigger: Supabase Database Webhook on `INSERT public.welcome_emails`.
// Sends a one-time transactional welcome email via Resend and marks the queue
// row sent/failed so retries stay idempotent.

import { serviceClient } from "../_shared/supabase.ts";

interface WebhookPayload {
    type: string;
    table?: string;
    record?: {
        user_id: string;
        email: string;
        full_name: string | null;
        status?: string;
    } | null;
}

const APP_URL = Deno.env.get("APP_URL") ?? "https://apps.apple.com/in/app/pandasplit-split-bills/id6763338956 ";

function escapeHtml(value: string): string {
    return value
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll("\"", "&quot;")
        .replaceAll("'", "&#39;");
}

function greetingName(fullName: string | null | undefined): string {
    const trimmed = fullName?.trim() ?? "";
    return trimmed.length > 0 ? trimmed : "there";
}

async function sendEmail(to: string, fullName: string | null | undefined) {
    const apiKey = Deno.env.get("RESEND_API_KEY");
    if (!apiKey) {
        console.warn("RESEND_API_KEY not set; skipping welcome email dispatch");
        return;
    }

    const name = greetingName(fullName);
    const safeName = escapeHtml(name);
    const openAppLink = `${APP_URL}`;

    const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
            authorization: `Bearer ${apiKey}`,
            "content-type": "application/json",
        },
        body: JSON.stringify({
            from: Deno.env.get("RESEND_FROM") ?? "PandaSplit <invites@mail.khushlani.store>",
            to,
            subject: "Welcome to PandaSplit",
            html: `
                <p>Hey ${safeName}, welcome to PandaSplit.</p>
                <p>Your account is ready. You can start splitting bills, tracking balances, and keeping everyone in sync.</p>
                <p><a href="${openAppLink}">Open PandaSplit</a></p>
            `,
            text: [
                `Hey ${name}, welcome to PandaSplit.`,
                "Your account is ready. You can start splitting bills, tracking balances, and keeping everyone in sync.",
                `Open PandaSplit: ${openAppLink}`,
            ].join("\n\n"),
        }),
    });

    if (!res.ok) {
        throw new Error(`Resend send failed: ${res.status} ${await res.text()}`);
    }
}

Deno.serve(async (req) => {
    if (req.method !== "POST") return new Response("method not allowed", { status: 405 });

    const event = (await req.json()) as WebhookPayload;
    if (event.type !== "INSERT" || event.table !== "welcome_emails" || !event.record) {
        return new Response("ignored", { status: 200 });
    }

    const row = event.record;
    const sb = serviceClient();

    const { data: claimed, error: claimError } = await sb
        .from("welcome_emails")
        .update({ status: "sending" })
        .eq("user_id", row.user_id)
        .eq("status", "pending")
        .select("user_id,email,full_name")
        .maybeSingle();

    if (claimError) {
        console.warn("welcome email claim failed", claimError.message);
        return new Response(JSON.stringify({ ok: false, error: claimError.message }), {
            status: 500,
            headers: { "content-type": "application/json" },
        });
    }

    if (!claimed) {
        return new Response(JSON.stringify({ ok: true, skipped: true }), {
            headers: { "content-type": "application/json" },
        });
    }

    try {
        await sendEmail(claimed.email, claimed.full_name);

        await sb
            .from("welcome_emails")
            .update({
                status: "sent",
                sent_at: new Date().toISOString(),
                last_error: null,
            })
            .eq("user_id", claimed.user_id)
            .eq("status", "sending");

        return new Response(JSON.stringify({ ok: true }), {
            headers: { "content-type": "application/json" },
        });
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        console.error("welcome email send failed", message);

        await sb
            .from("welcome_emails")
            .update({
                status: "failed",
                last_error: message,
            })
            .eq("user_id", claimed.user_id)
            .eq("status", "sending");

        return new Response(JSON.stringify({ ok: false, error: message }), {
            status: 500,
            headers: { "content-type": "application/json" },
        });
    }
});
