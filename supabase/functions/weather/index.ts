// Cup Season — round weather: RETIRED at launch (D407, 2026-10-02).
//
// The forecast on a planned round came from Open-Meteo's free, keyless tier,
// whose terms cover non-commercial use only. The owner retired the feature
// rather than license it ("we don't need it"). Every request now gets the
// function's own soft miss, { unavailable: true }, which both clients already
// read as "hide the weather line" (`ScheduleService.weather` returns nil;
// index.html hides the chip). So the line is gone on every shipped build with
// no app update, and nothing is sent to Open-Meteo. The client code and the
// weather_cache table go in a later cleanup (spec/inbox.md, 2026-10-02).
//
// Deploy: supabase functions deploy weather

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve((req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  // logged, so a client still asking is visible (CLAUDE.md: log every invocation)
  console.log("[weather] retired: answered unavailable");
  return new Response(JSON.stringify({ unavailable: true, reason: "retired" }), {
    status: 200,
    headers: { ...cors, "Content-Type": "application/json" },
  });
});
