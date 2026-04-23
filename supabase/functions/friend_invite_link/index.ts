// Edge Function: friend_invite_link
// Trigger: Supabase Database Webhook on `INSERT public.friend_invites`.
//
// Responsibilities:
//   - Email channel: send transactional email via Resend (RESEND_API_KEY).
//   - Phone channel: send SMS via Twilio (TWILIO_*).
//   - Always writes a notifications row to the inviter so the inbox shows status.
//
// Note: the actual auto-acceptance on signup is handled by the SQL trigger
// `link_pending_friend_invites` defined in 20260422120200_friends.sql; this
// function is purely the dispatch / inbox side.

import { serviceClient } from "../_shared/supabase.ts";

interface WebhookPayload {
    type: "INSERT";
    table: "friend_invites";
    record: {
        id: string;
        inviter_id: string;
        channel: "email" | "phone";
        email: string | null;
        phone: string | null;
        token: string;
    };
}

const APP_URL = Deno.env.get("APP_URL") ?? "https://pandasplit.app";

async function sendEmail(to: string, inviter: string, token: string) {
    const apiKey = Deno.env.get("RESEND_API_KEY");
    if (!apiKey) {
        console.warn("RESEND_API_KEY not set; skipping email dispatch");
        return;
    }
    const link = `${APP_URL}/invite?token=${encodeURIComponent(token)}`;
    const res = await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
            authorization: `Bearer ${apiKey}`,
            "content-type": "application/json",
        },
        body: JSON.stringify({
            from: Deno.env.get("RESEND_FROM") ?? "PandaSplit <invites@pandasplit.app>",
            to,
            subject: `${inviter} invited you to PandaSplit`,
            html: `<p><strong>${inviter}</strong> wants to split expenses with you on PandaSplit.</p>
                   <p><a href="${link}">Tap here to accept</a>.</p>`,
        }),
    });
    if (!res.ok) console.warn("Resend send failed", res.status, await res.text());
}

async function sendSms(to: string, inviter: string, token: string) {
    const sid   = Deno.env.get("TWILIO_ACCOUNT_SID");
    const auth  = Deno.env.get("TWILIO_AUTH_TOKEN");
    const from  = Deno.env.get("TWILIO_FROM");
    if (!sid || !auth || !from) {
        console.warn("TWILIO_* not set; skipping SMS dispatch");
        return;
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
    if (!res.ok) console.warn("Twilio send failed", res.status, await res.text());
}

Deno.serve(async (req) => {
    if (req.method !== "POST") return new Response("method not allowed", { status: 405 });

    const event = (await req.json()) as WebhookPayload;
    if (event.type !== "INSERT" || event.table !== "friend_invites") {
        return new Response("ignored");
    }

    const inv = event.record;
    const sb = serviceClient();

    const { data: inviter } = await sb
        .from("profiles").select("full_name").eq("id", inv.inviter_id).maybeSingle();
    const inviterName = inviter?.full_name ?? "A friend";

    if (inv.channel === "email" && inv.email) {
        await sendEmail(inv.email, inviterName, inv.token);
    } else if (inv.channel === "phone" && inv.phone) {
        await sendSms(inv.phone, inviterName, inv.token);
    }

    await sb.from("notifications").insert({
        user_id: inv.inviter_id,
        kind: "friend_invite",
        title: "Invite sent",
        body: `Invitation sent to ${inv.email ?? inv.phone}`,
        payload: { invite_id: inv.id, channel: inv.channel },
    });

    return new Response(JSON.stringify({ ok: true }));
});
