// Cup Season — round weather (scheduled-rounds arc, Stage 5).
//
// Given a course's lat/lon + a play date, returns a one-line forecast for the
// round detail sheet. Uses Open-Meteo (FREE, KEYLESS) and caches each answer in
// weather_cache so a busy day's sheet doesn't refetch. Fails SOFT: no lat/lon,
// a date outside the forecast window, or any API hiccup returns
// { unavailable: true } — the client simply hides the weather line (never a
// blank panel). No API key, nothing to leak, nothing to bill.
//
// Deploy: supabase functions deploy weather   (SUPABASE_* auto-provided)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SB_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SB_SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const SB_ANON = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...cors, "Content-Type": "application/json" } });
const soft = (reason: string) => json({ unavailable: true, reason });

// WMO weather codes → a short human summary + a glyph the client can show.
function describe(code: number): { summary: string; icon: string } {
  if (code === 0) return { summary: "Clear", icon: "sun" };
  if (code <= 2) return { summary: "Mostly sunny", icon: "sun" };
  if (code === 3) return { summary: "Overcast", icon: "cloud" };
  if (code <= 48) return { summary: "Fog", icon: "cloud" };
  if (code <= 67) return { summary: "Rain", icon: "rain" };
  if (code <= 77) return { summary: "Snow", icon: "snow" };
  if (code <= 82) return { summary: "Showers", icon: "rain" };
  if (code <= 99) return { summary: "Storms", icon: "storm" };
  return { summary: "—", icon: "cloud" };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  // signed-in users only (not the bare anon key)
  const asUser = createClient(SB_URL, SB_ANON, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: u } = await asUser.auth.getUser();
  if (!u?.user?.id) return json({ error: "not signed in" }, 401);

  let body: any;
  try { body = await req.json(); } catch { return json({ error: "bad body" }, 400); }
  let lat = Number(body?.lat), lon = Number(body?.lon);
  const date = String(body?.date ?? "");
  const courseId = String(body?.course_id ?? "") || "manual";
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return soft("no_date");

  const admin = createClient(SB_URL, SB_SERVICE);

  // Home cards carry only a course_id — resolve its location from the cache.
  if ((!Number.isFinite(lat) || !Number.isFinite(lon)) && courseId !== "manual") {
    const { data: c } = await admin.from("api_courses")
      .select("latitude, longitude").eq("id", courseId).maybeSingle();
    if (c) { lat = Number(c.latitude); lon = Number(c.longitude); }
  }
  if (!Number.isFinite(lat) || !Number.isFinite(lon)) return soft("no_location");

  // forecast window: today .. +16 days (Open-Meteo's free range)
  const day = new Date(date + "T00:00:00Z").getTime();
  const now = Date.now();
  if (day < now - 24 * 3600e3 || day > now + 16 * 24 * 3600e3) return soft("out_of_range");

  // cache hit? (fresh within 6h)
  const { data: cached } = await admin.from("weather_cache")
    .select("payload, fetched_at").eq("course_id", courseId).eq("play_on", date).maybeSingle();
  if (cached?.payload && (now - new Date(cached.fetched_at).getTime()) < 6 * 3600e3) {
    return json({ ok: true, weather: cached.payload });
  }

  // the one (free) fetch
  try {
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}` +
      `&daily=temperature_2m_max,temperature_2m_min,weathercode,windspeed_10m_max` +
      `&temperature_unit=fahrenheit&windspeed_unit=mph&timezone=auto&start_date=${date}&end_date=${date}`;
    const r = await fetch(url);
    if (!r.ok) return soft("api_" + r.status);
    const d = await r.json();
    const dy = d?.daily;
    if (!dy?.temperature_2m_max?.length) return soft("no_data");
    const code = Number(dy.weathercode?.[0] ?? -1);
    const { summary, icon } = describe(code);
    const payload = {
      hi: Math.round(Number(dy.temperature_2m_max[0])),
      lo: Math.round(Number(dy.temperature_2m_min[0])),
      wind: Math.round(Number(dy.windspeed_10m_max?.[0] ?? 0)),
      summary, icon,
    };
    // best-effort cache write
    try {
      await admin.from("weather_cache").upsert({
        course_id: courseId, play_on: date, lat, lon, payload, fetched_at: new Date().toISOString(),
      });
    } catch (_) { /* never fail the response on a cache write */ }
    return json({ ok: true, weather: payload });
  } catch (_) {
    return soft("fetch_failed");
  }
});
