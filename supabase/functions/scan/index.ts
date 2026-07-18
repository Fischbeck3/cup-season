// Cup Season — scorecard scan (photos arc ckpt 3, D36).
//
// Reads a photographed scorecard with Claude vision and returns per-hole
// strokes for every player row plus the par row — the client's confirm grid
// does the last mile (the golfer fixes cells, the model never posts anything).
//
// COST DISCIPLINE (fail closed, always before spending):
//   1. kill switch     app_flags.scan.enabled = false  -> refuse
//   2. per-golfer cap  app_flags.scan.daily_per_user   -> refuse
//   3. global cap      app_flags.scan.monthly_global   -> refuse
//   4. API failure / credits exhausted -> { unavailable: true } with HTTP 200,
//      so the client silently falls back to typed entry. The scan is an
//      accelerator; its failure mode is the current app.
// Every attempt writes a scan_usage row (service role) — the cap counter and
// the accuracy dataset in one.
//
// Secrets required: ANTHROPIC_API_KEY  (SUPABASE_* auto-provided).
// Deploy: supabase functions deploy scan
// Prepaid credits, no auto-reload — when the balance is out, path 4 kicks in.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const MODEL = "claude-opus-4-8";
const KEY = (Deno.env.get("ANTHROPIC_API_KEY") ?? "").trim();
const SB_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SB_SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const SB_ANON = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });
// unavailable = a soft no: HTTP 200, client falls back to typed entry
const soft = (reason: string) => json({ unavailable: true, reason });

// Structured-outputs schema — the API guarantees the response parses to this.
// Array lengths are enforced by normalize() below (length constraints aren't
// part of the supported schema subset). 0 = blank/unreadable, by convention.
const SCHEMA = {
  type: "object",
  additionalProperties: false,
  properties: {
    course_name: { type: "string" },
    date: { type: "string" },
    par_row: { type: "array", items: { type: "integer" } },
    players: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          name: { type: "string" },
          holes: { type: "array", items: { type: "integer" } },
          total: { type: "integer" },
        },
        required: ["name", "holes", "total"],
      },
    },
  },
  required: ["course_name", "date", "par_row", "players"],
};

const PROMPT = `Read this golf scorecard photo.

Extract:
- course_name: the printed course/club name ("" if not visible)
- date: the written or printed date as YYYY-MM-DD ("" if not legible)
- par_row: the printed PAR for each of the 18 holes, in order (exactly 18
  integers; use 0 for any hole whose par isn't visible; for a 9-hole card use
  0 for holes 10-18)
- players: one entry per handwritten player row that has any scores. For each:
  - name: the name written on the row ("" if blank)
  - holes: exactly 18 integers, the gross strokes per hole in order (0 for
    blank/unreadable holes; holes 10-18 are 0 on a 9-hole card)
  - total: the written total for the row, or the sum of the holes if no total
    is written (0 if neither)

Rules: read the handwriting carefully — a slash or dot often marks par.
Ignore +/- match-play notation rows, putt counts, and junk rows. Never invent
scores: an unreadable cell is 0. OUT/IN/total columns are not holes.`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (!KEY) return soft("no_api_key");

  // -- who's asking (verify_jwt gates the function; this resolves the uid) --
  const auth = req.headers.get("Authorization") ?? "";
  const asUser = createClient(SB_URL, SB_ANON, {
    global: { headers: { Authorization: auth } },
  });
  const { data: userData } = await asUser.auth.getUser();
  const uid = userData?.user?.id;
  if (!uid) return json({ error: "not signed in" }, 401);

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad request body" }, 400);
  }
  const b64 = String(body?.image ?? "").replace(/^data:[^,]+,/, "");
  const mediaType = String(body?.media_type ?? "image/jpeg");
  if (b64.length < 1000) return json({ error: "image required" }, 400);
  if (b64.length > 8_000_000) return json({ error: "image too large" }, 413);

  const admin = createClient(SB_URL, SB_SERVICE);

  // -- caps: refuse BEFORE spending ----------------------------------------
  const { data: flagRow } = await admin
    .from("app_flags").select("value").eq("key", "scan").maybeSingle();
  const flag = flagRow?.value ?? {};
  if (flag.enabled === false) return soft("disabled");
  const dailyCap = Number(flag.daily_per_user ?? 5);
  const monthlyCap = Number(flag.monthly_global ?? 400);

  const dayAgo = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const monthStart = new Date();
  monthStart.setUTCDate(1); monthStart.setUTCHours(0, 0, 0, 0);

  const [{ count: mine }, { count: all }] = await Promise.all([
    admin.from("scan_usage").select("*", { count: "exact", head: true })
      .eq("profile_id", uid).gte("created_at", dayAgo),
    admin.from("scan_usage").select("*", { count: "exact", head: true })
      .gte("created_at", monthStart.toISOString()),
  ]);
  if ((mine ?? 0) >= dailyCap) return soft("daily_cap");
  if ((all ?? 0) >= monthlyCap) return soft("monthly_cap");

  // -- the one paid call ----------------------------------------------------
  let scan: any = null;
  let ok = false;
  try {
    const r = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "x-api-key": KEY,
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 3000,
        output_config: { format: { type: "json_schema", schema: SCHEMA } },
        messages: [{
          role: "user",
          content: [
            { type: "image", source: { type: "base64", media_type: mediaType, data: b64 } },
            { type: "text", text: PROMPT },
          ],
        }],
      }),
    });
    if (r.ok) {
      const msg = await r.json();
      // refusal / truncation are content outcomes, not exceptions — check first
      if (msg?.stop_reason === "end_turn") {
        const text = (msg.content ?? []).find((b: any) => b.type === "text")?.text;
        if (text) { scan = normalize(JSON.parse(text)); ok = true; }
      } else {
        console.error("[scan] stop_reason", msg?.stop_reason, msg?.stop_details ?? "");
      }
    } else {
      // 400 bad image, 401 key, 402/credits, 429, 5xx — all the same to the
      // client: scan unavailable, type it in. Detail stays in the logs.
      console.error("[scan] api", r.status, (await r.text()).slice(0, 400));
    }
  } catch (e) {
    console.error("[scan] fetch", String(e));
  }

  // -- ledger (cap counter + accuracy dataset), best-effort -----------------
  try {
    await admin.from("scan_usage").insert({ profile_id: uid, model: MODEL, ok });
  } catch (_) { /* never fail the response on ledger issues */ }

  if (!ok || !scan) return soft("scan_failed");
  return json({ ok: true, scan });
});

// Coerce model output into the exact shape the client trusts: 18-slot integer
// arrays, sane bounds, junk rows dropped.
function normalize(raw: any) {
  const arr18 = (a: any) => {
    const out = Array.from({ length: 18 }, (_, i) => {
      const v = Math.round(Number((a ?? [])[i] ?? 0));
      return Number.isFinite(v) && v >= 0 && v <= 20 ? v : 0;
    });
    return out;
  };
  const players = (Array.isArray(raw?.players) ? raw.players : [])
    .slice(0, 6)
    .map((p: any) => {
      const holes = arr18(p?.holes);
      const sum = holes.reduce((t: number, v: number) => t + v, 0);
      const total = Math.round(Number(p?.total ?? 0)) || sum;
      return {
        name: String(p?.name ?? "").slice(0, 40),
        holes,
        total: total >= 18 && total <= 200 ? total : sum,
        holes_sum: sum,
        holes_read: holes.filter((v: number) => v > 0).length,
      };
    })
    .filter((p: any) => p.holes_read > 0 || p.total > 0);
  const par = arr18(raw?.par_row).map((v) => (v >= 3 && v <= 6 ? v : 0));
  const date = /^\d{4}-\d{2}-\d{2}$/.test(String(raw?.date ?? "")) ? raw.date : "";
  return {
    course_name: String(raw?.course_name ?? "").slice(0, 80),
    date,
    par_row: par,
    players,
  };
}
