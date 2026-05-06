// Edge Function: friend_invite_link
// Supports two entrypoints:
//   1. Supabase Database Webhook on `INSERT public.friend_invites`
//   2. Direct app call that sends the email synchronously and returns only
//      after Resend confirms delivery.
//
// The direct path is what the app uses for the success toast. The webhook path
// remains as a safe fallback for existing DB-triggered inserts.

import { serviceClient } from "../_shared/supabase.ts";

interface WebhookPayload {
    type?: "INSERT";
    table?: "friend_invites";
    record?: {
        id: string;
        inviter_id: string;
        channel: "email" | "phone";
        email: string | null;
        phone: string | null;
        token: string;
        email_delivery_status?: "pending" | "sending" | "sent" | "failed";
        email_sent_at?: string | null;
    };
}

interface DirectRequest {
    channel: "email";
    target: string;
}

const APP_URL = Deno.env.get("APP_URL") ?? "https://pandasplit.app";
const APP_STORE_URL = Deno.env.get("APP_STORE_URL") ?? "https://apps.apple.com/in/app/pandasplit-split-bills/id6763338956";

function escapeHtml(value: string): string {
    return value
        .replaceAll("&", "&amp;")
        .replaceAll("<", "&lt;")
        .replaceAll(">", "&gt;")
        .replaceAll("\"", "&quot;")
        .replaceAll("'", "&#39;");
}

function okResponse(body: unknown, status = 200): Response {
    return new Response(JSON.stringify(body), {
        status,
        headers: { "content-type": "application/json" },
    });
}

function failResponse(stage: string, error: string, status = 500, extra: Record<string, unknown> = {}): Response {
    console.error("friend_invite_link failed", JSON.stringify({ stage, error, ...extra }));
    return okResponse({ ok: false, stage, error, ...extra }, status);
}

async function sendEmail(to: string, inviter: string, token: string) {
    const apiKey = Deno.env.get("RESEND_API_KEY");
    if (!apiKey) {
        throw new Error("RESEND_API_KEY not set");
    }

    const link = `${APP_URL}/invite?token=${encodeURIComponent(token)}`;
    const appLink = APP_STORE_URL;
    const safeInviter = escapeHtml(inviter);

    const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
            authorization: `Bearer ${apiKey}`,
            "content-type": "application/json",
        },
        body: JSON.stringify({
            from: Deno.env.get("RESEND_FROM") ?? "PandaSplit <invites@mail.khushlani.store>",
            to,
            subject: `${inviter} invited you to PandaSplit`,
            html: `
                <div style="font-family:Arial,Helvetica,sans-serif;background:#f7f9fc;padding:32px 16px;color:#1f2a37;">
                    <div style="max-width:560px;margin:0 auto;background:#ffffff;border:1px solid #e5e7eb;border-radius:20px;overflow:hidden;">
                        <div style="background:linear-gradient(135deg,#0f172a,#2563eb);padding:28px 32px;color:#fff;">
                            <div style="font-size:13px;letter-spacing:.08em;text-transform:uppercase;opacity:.85;">PandaSplit</div>
                            <h1 style="margin:10px 0 0;font-size:30px;line-height:1.1;">You’re invited</h1>
                        </div>
                        <div style="padding:32px;">
                            <p style="margin:0 0 16px;font-size:16px;line-height:1.6;">${safeInviter} invited you to split expenses on PandaSplit.</p>
                            <p style="margin:0 0 24px;font-size:15px;line-height:1.7;color:#4b5563;">
                                Download the app to get started, then tap the invite link to accept the request and join the shared space.
                            </p>
                            <div style="margin:0 0 18px;">
                                <a href="${appLink}" style="display:inline-block;background:#111827;color:#ffffff;text-decoration:none;padding:12px 18px;border-radius:12px;font-weight:700;margin-right:10px;margin-bottom:10px;">Download the app</a>
                                <a href="${link}" style="display:inline-block;background:#2563eb;color:#ffffff;text-decoration:none;padding:12px 18px;border-radius:12px;font-weight:700;margin-bottom:10px;">Accept invite</a>
                            </div>
                            <p style="margin:0;font-size:13px;line-height:1.6;color:#6b7280;">
                                If the buttons don’t work, paste this link into your browser:<br />
                                <a href="${link}" style="color:#2563eb;word-break:break-all;">${link}</a>
                            </p>
                        </div>
                    </div>
                </div>
            `,
            text: [
                `${inviter} invited you to split expenses on PandaSplit.`,
                "Download the app to get started:",
                appLink,
                "",
                "Accept the invite here:",
                link,
            ].join("\n"),
        }),
    });

    if (!res.ok) {
        throw new Error(`Resend send failed: ${res.status} ${await res.text()}`);
    }
}

async function sendSms(to: string, inviter: string, token: string) {
    const sid = Deno.env.get("TWILIO_ACCOUNT_SID");
    const auth = Deno.env.get("TWILIO_AUTH_TOKEN");
    const from = Deno.env.get("TWILIO_FROM");
    if (!sid || !auth || !from) {
        throw new Error("TWILIO_* not set");
    }

    const link = `${APP_URL}/invite?token=${encodeURIComponent(token)}`;
    const params = new URLSearchParams({
        To: to,
        From: from,
        Body: `${inviter} invited you to PandaSplit. Accept: ${link}`,
    });
    const res = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`, {
        method: "POST",
        headers: {
            authorization: `Basic ${btoa(`${sid}:${auth}`)}`,
            "content-type": "application/x-www-form-urlencoded",
        },
        body: params.toString(),
    });

    if (!res.ok) {
        throw new Error(`Twilio send failed: ${res.status} ${await res.text()}`);
    }
}

async function notifyInviter(inviterId: string, body: string, payload: Record<string, string>) {
    const sb = serviceClient();
    await sb.from("notifications").insert({
        user_id: inviterId,
        kind: "friend_invite",
        title: "Invite sent",
        body,
        payload,
    });
}

async function handleWebhook(inv: NonNullable<WebhookPayload["record"]>) {
    const sb = serviceClient();

    if (inv.channel === "email") {
        if (inv.email_delivery_status && inv.email_delivery_status !== "pending") {
            return okResponse({ ok: true, skipped: true });
        }

        const { data: inviter, error: inviterErr } = await sb
            .from("profiles")
            .select("full_name")
            .eq("id", inv.inviter_id)
            .maybeSingle();
        if (inviterErr) return failResponse("profile_lookup", inviterErr.message);
        const inviterName = inviter?.full_name ?? "A friend";

        try {
            await sendEmail(inv.email ?? "", inviterName, inv.token);
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            return failResponse("resend_send", message, 500, { invite_id: inv.id });
        }

        const { error: updateErr } = await sb.from("friend_invites").update({
            email_delivery_status: "sent",
            email_sent_at: new Date().toISOString(),
            email_delivery_error: null,
        }).eq("id", inv.id);
        if (updateErr) return failResponse("delivery_update", updateErr.message, 500, { invite_id: inv.id });

        try {
            await notifyInviter(inv.inviter_id, `Invitation sent to ${inv.email}`, {
                invite_id: inv.id,
                channel: inv.channel,
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            return failResponse("notify_inviter", message, 500, { invite_id: inv.id });
        }

        return okResponse({ ok: true, delivered: true });
    }

    if (inv.channel === "phone" && inv.phone) {
        const { data: inviter, error: inviterErr } = await sb
            .from("profiles")
            .select("full_name")
            .eq("id", inv.inviter_id)
            .maybeSingle();
        if (inviterErr) return failResponse("profile_lookup", inviterErr.message);
        const inviterName = inviter?.full_name ?? "A friend";

        try {
            await sendSms(inv.phone, inviterName, inv.token);
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            return failResponse("twilio_send", message, 500, { invite_id: inv.id });
        }

        try {
            await notifyInviter(inv.inviter_id, `Invitation sent to ${inv.phone}`, {
                invite_id: inv.id,
                channel: inv.channel,
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            return failResponse("notify_inviter", message, 500, { invite_id: inv.id });
        }
    }

    return okResponse({ ok: true });
}

async function handleDirect(req: Request) {
    const auth = req.headers.get("authorization") ?? "";
    if (!auth.toLowerCase().startsWith("bearer ")) {
        return okResponse({ ok: false, error: "authorization required" }, 401);
    }

    const accessToken = auth.slice("bearer ".length).trim();
    const sb = serviceClient();
    const { data: userData, error: userErr } = await sb.auth.getUser(accessToken);
    if (userErr || !userData.user) {
        const message = userErr?.message ?? "auth required";
        return failResponse("auth", message, 401);
    }

    let body: DirectRequest;
    try {
        body = (await req.json()) as DirectRequest;
    } catch {
        return failResponse("request_parse", "invalid json", 400);
    }
    if (body.channel !== "email" || typeof body.target !== "string" || body.target.trim().length === 0) {
        return failResponse("validate", "invalid request", 400);
    }

    const inviterId = userData.user.id;
    const target = body.target.trim();

    const { data: inviter, error: inviterErr } = await sb
        .from("profiles")
        .select("full_name")
        .eq("id", inviterId)
        .maybeSingle();
    if (inviterErr) return failResponse("profile_lookup", inviterErr.message);
    const inviterName = inviter?.full_name ?? "A friend";

    const { data: invite, error: insertErr } = await sb
        .from("friend_invites")
        .insert({
            inviter_id: inviterId,
            channel: "email",
            email: target,
            status: "pending",
            email_delivery_status: "sending",
        })
        .select("id,token")
        .single();

    if (insertErr || !invite) {
        return failResponse("db_insert", insertErr?.message ?? "could not create invite", 500);
    }

    try {
        await sendEmail(target, inviterName, invite.token);

        const { error: updateErr } = await sb.from("friend_invites").update({
            email_delivery_status: "sent",
            email_sent_at: new Date().toISOString(),
            email_delivery_error: null,
        }).eq("id", invite.id);
        if (updateErr) return failResponse("delivery_update", updateErr.message, 500, { invite_id: invite.id });

        try {
            await notifyInviter(inviterId, `Invitation sent to ${target}`, {
                invite_id: invite.id,
                channel: "email",
            });
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            return failResponse("notify_inviter", message, 500, { invite_id: invite.id });
        }

        return okResponse({ ok: true, delivered: true });
    } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        await sb.from("friend_invites").update({
            status: "failed",
            email_delivery_status: "failed",
            email_delivery_error: message,
        }).eq("id", invite.id);

        return failResponse("resend_send", message, 500, { invite_id: invite.id });
    }
}

Deno.serve(async (req) => {
    if (req.method !== "POST") return new Response("method not allowed", { status: 405 });

    const bodyText = await req.text();
    let parsed: WebhookPayload | DirectRequest | null = null;
    try {
        parsed = JSON.parse(bodyText) as WebhookPayload | DirectRequest;
    } catch {
        return okResponse({ ok: false, error: "invalid json" }, 400);
    }

    if (
        typeof parsed === "object" &&
        parsed !== null &&
        "table" in parsed &&
        (parsed as WebhookPayload).type === "INSERT" &&
        (parsed as WebhookPayload).table === "friend_invites" &&
        (parsed as WebhookPayload).record
    ) {
        return await handleWebhook((parsed as WebhookPayload).record!);
    }

    return await handleDirect(new Request(req.url, {
        method: req.method,
        headers: req.headers,
        body: bodyText,
    }));
});
