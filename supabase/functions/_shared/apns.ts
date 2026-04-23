// APNs HTTP/2 push helper.
//
// Required env vars:
//   APNS_TEAM_ID            - Apple Developer Team ID
//   APNS_KEY_ID             - APNs Auth Key ID
//   APNS_PRIVATE_KEY        - p8 contents (PEM, with newlines)
//   APNS_BUNDLE_ID          - iOS app bundle id
//   APNS_USE_SANDBOX        - "true" for development (api.sandbox.push.apple.com)
//
// JWT spec: ES256 over { alg: "ES256", kid: KEY_ID } / { iss: TEAM_ID, iat }.

const encoder = new TextEncoder();

let cachedJwt: { token: string; issuedAt: number } | null = null;

function base64Url(input: ArrayBuffer | Uint8Array | string): string {
    const bytes = typeof input === "string" ? encoder.encode(input)
        : input instanceof Uint8Array ? input : new Uint8Array(input);
    let str = "";
    for (const b of bytes) str += String.fromCharCode(b);
    return btoa(str).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToPkcs8(pem: string): ArrayBuffer {
    const body = pem.replace(/-----BEGIN PRIVATE KEY-----/, "")
                    .replace(/-----END PRIVATE KEY-----/, "")
                    .replace(/\s+/g, "");
    const bin = atob(body);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
    return bytes.buffer;
}

async function buildJwt(): Promise<string> {
    const teamId = Deno.env.get("APNS_TEAM_ID");
    const keyId  = Deno.env.get("APNS_KEY_ID");
    const pem    = Deno.env.get("APNS_PRIVATE_KEY");
    if (!teamId || !keyId || !pem) {
        throw new Error("APNS_TEAM_ID, APNS_KEY_ID, APNS_PRIVATE_KEY must be set");
    }

    const now = Math.floor(Date.now() / 1000);
    if (cachedJwt && now - cachedJwt.issuedAt < 50 * 60) {
        return cachedJwt.token;
    }

    const header  = base64Url(JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" }));
    const payload = base64Url(JSON.stringify({ iss: teamId, iat: now }));
    const data    = `${header}.${payload}`;

    const key = await crypto.subtle.importKey(
        "pkcs8",
        pemToPkcs8(pem),
        { name: "ECDSA", namedCurve: "P-256" },
        false,
        ["sign"],
    );
    const sigRaw = await crypto.subtle.sign(
        { name: "ECDSA", hash: "SHA-256" },
        key,
        encoder.encode(data),
    );
    const token = `${data}.${base64Url(sigRaw)}`;
    cachedJwt = { token, issuedAt: now };
    return token;
}

export interface ApnsPayload {
    title: string;
    body: string;
    badge?: number;
    sound?: string;
    extra?: Record<string, unknown>;
}

export interface ApnsSendResult {
    token: string;
    status: number;
    reason?: string;
}

export async function sendApns(deviceTokens: string[], payload: ApnsPayload): Promise<ApnsSendResult[]> {
    if (deviceTokens.length === 0) return [];

    const bundleId = Deno.env.get("APNS_BUNDLE_ID");
    if (!bundleId) throw new Error("APNS_BUNDLE_ID must be set");

    const sandbox = Deno.env.get("APNS_USE_SANDBOX") === "true";
    const host = sandbox ? "https://api.sandbox.push.apple.com" : "https://api.push.apple.com";
    const jwt  = await buildJwt();

    const body = JSON.stringify({
        aps: {
            alert: { title: payload.title, body: payload.body },
            sound: payload.sound ?? "default",
            badge: payload.badge,
            "mutable-content": 1,
        },
        ...(payload.extra ?? {}),
    });

    const sends = deviceTokens.map(async (token): Promise<ApnsSendResult> => {
        const res = await fetch(`${host}/3/device/${token}`, {
            method: "POST",
            headers: {
                authorization: `bearer ${jwt}`,
                "apns-topic": bundleId,
                "apns-push-type": "alert",
                "content-type": "application/json",
            },
            body,
        });
        let reason: string | undefined;
        if (!res.ok) {
            try { reason = (await res.json())?.reason; } catch { /* ignore */ }
        }
        return { token, status: res.status, reason };
    });

    return Promise.all(sends);
}
