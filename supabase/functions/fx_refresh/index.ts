// Edge Function: fx_refresh
// Trigger: cron (daily). Refreshes fx_rates against an external provider.
//
// Default provider: open.er-api.com (free, no key). Override with FX_PROVIDER_URL.
// Expected response shape: { base: "USD", rates: { EUR: 0.92, ... } }.

import { serviceClient } from "../_shared/supabase.ts";

const PROVIDER = Deno.env.get("FX_PROVIDER_URL") ?? "https://open.er-api.com/v6/latest/USD";

Deno.serve(async () => {
    const sb = serviceClient();

    const res = await fetch(PROVIDER);
    if (!res.ok) return new Response(`provider error ${res.status}`, { status: 502 });

    const body = await res.json() as { base_code?: string; base?: string; rates: Record<string, number> };
    const base = (body.base_code ?? body.base ?? "USD").toUpperCase();
    const today = new Date().toISOString().slice(0, 10);

    const { data: codes } = await sb.from("currencies").select("code");
    const known = new Set((codes ?? []).map((c) => c.code));

    const rows = Object.entries(body.rates)
        .filter(([quote]) => known.has(quote) && quote !== base)
        .map(([quote, rate]) => ({
            base,
            quote,
            as_of: today,
            rate,
        }));

    if (rows.length === 0) return new Response(JSON.stringify({ inserted: 0 }));

    const { error } = await sb.from("fx_rates").upsert(rows, { onConflict: "base,quote,as_of" });
    if (error) return new Response(error.message, { status: 500 });

    return new Response(JSON.stringify({ inserted: rows.length, base, as_of: today }));
});
