// Shared service-role client for Edge Functions.
// All Edge Functions need to bypass RLS while still acting as the platform.

import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

let cached: SupabaseClient | null = null;

export function serviceClient(): SupabaseClient {
    if (cached) return cached;

    const url = Deno.env.get("SUPABASE_URL");
    const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

    if (!url || !key) {
        throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set");
    }

    cached = createClient(url, key, {
        auth: { persistSession: false, autoRefreshToken: false },
    });
    return cached;
}
