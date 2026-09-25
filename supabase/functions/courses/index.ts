// Cup Season — course lookup proxy.
//
// Holds the GolfCourseAPI key server-side (it must NEVER ship in the single-file
// client, where source is public) and caches picked courses into our own tables
// so play-time reads never depend on the third-party API's rate limits or uptime
// (spec §13.1 seed strategy). Authenticated callers only (verify_jwt default).
//
// POST body:
//   { action: "search", q: "papago" }   -> proxied search, light tee payload
//   { action: "cache",  id: "12345"  }   -> fetch by id + upsert into our cache
//
// Secrets required:  GOLFCOURSE_API_KEY  (SUPABASE_URL / SERVICE_ROLE_KEY auto)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const GCA_BASE = "https://api.golfcourseapi.com";
// .trim() defends against a trailing space/newline in the secret — a common
// cause of a 401 from GolfCourseAPI even when the key itself is correct.
const KEY = (Deno.env.get("GOLFCOURSE_API_KEY") ?? "").trim();
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

async function gca(path: string) {
  const r = await fetch(`${GCA_BASE}${path}`, {
    headers: { Authorization: `Key ${KEY}` },
  });
  if (!r.ok) {
    // A failure here used to be INVISIBLE: the catch turned it into a 502 body
    // and nothing reached the logs, so "search is broken" and "the upstream is
    // rate-limited" looked identical from the dashboard. Log the status and a
    // short body snippet — 429 = their quota (self-heals), 401/403 = the key,
    // 5xx = their outage. NEVER log headers: KEY rides in Authorization.
    const snippet = await r.text().catch(() => "");
    console.error(`[courses] golfcourseapi ${r.status} on ${path} :: ${snippet.slice(0, 200)}`);
    throw new Error(`golfcourseapi ${r.status}`);
  }
  return r.json();
}

// Numeric normalization lives in ./normalize.ts (tested with node --test):
// null stays null, booleans and other non-numbers become null, integers are
// rounded from finite numbers only, and a tee's hole count falls back to the
// holes actually listed — never to an invented zero.
import { holeCount, int, num } from "./normalize.ts";
// C-04 · the per-request upstream cost and the ledger's verdict (./reserve.ts)
import { reservation, SEARCH_DETAIL_FETCHES, unitsFor } from "./reserve.ts";

// GolfCourseAPI groups tees by gender; flatten to one tagged list.
function flattenTees(course: any) {
  const out: any[] = [];
  const t = course?.tees ?? {};
  for (const gender of ["male", "female"]) {
    // 2026-08-28: the upstream SEARCH payload changed — `tees.male` became a COUNT
    // (the number 8), and `?? []` does not guard a number, so this loop threw
    // "number 8 is not iterable" and every search 502'd for 12 days. Iterate
    // only real arrays; a count (or anything else) simply yields no tees here —
    // the search branch below then fills tees from our own cache / a detail fetch.
    const arr = Array.isArray(t[gender]) ? t[gender] : [];
    for (const te of arr) {
      if (!te || typeof te !== "object" || typeof te.tee_name !== "string" || !te.tee_name.trim()) continue;
      const holes = Array.isArray(te.holes) ? te.holes : [];
      out.push({
        gender,
        tee_name: te.tee_name ?? null,
        // ratings are numeric; slope, par, yards and hole count are integers
        course_rating: num(te.course_rating),
        slope_rating: int(te.slope_rating),
        bogey_rating: num(te.bogey_rating),
        par_total: int(te.par_total),
        total_yards: int(te.total_yards),
        number_of_holes: holeCount(te.number_of_holes, holes),
        holes: holes.map((h: any, i: number) => ({
          hole_number: int(h?.hole) ?? i + 1,
          par: int(h?.par),
          yardage: int(h?.yardage),
          handicap: int(h?.handicap),
        })),
      });
    }
  }
  return out;
}

// fetch a course from the API and store it whole — the ONE writer for the
// dataset, shared by the foreground miss path and the background refresh.
// api_* tables: the original `courses`/`course_tees`/`course_holes` names
// collided with a legacy uuid schema, so upserts silently failed (text ids
// into uuid columns). See 20260714050000_course_cache_reconcile.
async function fetchAndStore(admin: any, id: string): Promise<string> {
  const data = await gca(`/v1/courses/${encodeURIComponent(id)}`);
  const c = data?.course ?? data;
  if (!c || String(c.id ?? "") !== id) throw new Error("Course provider returned a mismatched card");
  const tees = flattenTees(c);
  if (!tees.length) throw new Error("Course provider returned no tee cards");
  // One transaction preserves the previous card if any replacement row fails.
  // Keep the provider payload, with only SQL-bound coordinates normalized.
  const course = { ...c, location: { ...c.location,
    latitude: num(c.location?.latitude), longitude: num(c.location?.longitude) } };
  const { data: cid, error } = await admin.rpc("cache_course_card", { p_course: course, p_tees: tees });
  if (error || cid !== id) throw new Error("Course card could not be saved; please retry");
  return cid;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (!KEY) return json({ error: "GOLFCOURSE_API_KEY not set" }, 500);

  // -- caller must be a signed-in USER, not just the public anon key. The
  //    platform verify_jwt default accepts the anon key (it's a valid JWT), so
  //    without this any internet caller could drive the paid GolfCourseAPI.
  const asUser = createClient(SB_URL, SB_ANON, {
    global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
  });
  const { data: u } = await asUser.auth.getUser();
  const uid = u?.user?.id;
  if (!uid) return json({ error: "not signed in" }, 401);

  const admin = createClient(SB_URL, SB_SERVICE);

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad request body" }, 400);
  }
  const action = body?.action;

  // -- C-04 · the paid-API caps (per user AND global), booked BEFORE any
  //    upstream call. One service-role RPC counts and inserts under a lock, so
  //    concurrent requests cannot all read the same count (the old read-then-
  //    write let 31 of 60 through a cap of 5), and a ledger it cannot write is a
  //    refusal, never a free pass (the old insert was fire-and-forget). Retune
  //    from the SQL editor: app_flags 'courses' {daily_per_user, daily_global}.
  const units = unitsFor(action, body);
  let booked = "none";
  if (units > 0) {
    const { data: got, error: re } = await admin.rpc("_courses_reserve",
      { p_profile: uid, p_action: String(action ?? ""), p_units: units });
    const v = reservation(got, re);
    booked = re ? `error(${re.message})` : String(got);
    if (!v.ok) {
      console.log(`[courses] action=${String(action ?? "")} units=${units} refused=${booked}`);
      return json({ error: v.error }, v.status);
    }
  }
  // every invocation logs, so "never called" is distinguishable from "called
  // and quietly failed" (the webhook landmine, same shape)
  console.log(`[courses] action=${String(action ?? "")} units=${units} reserve=${booked}`);

  try {
    if (action === "search") {
      const q = String(body.q ?? "").trim();
      if (q.length < 3) return json({ courses: [] });
      const data = await gca(
        `/v1/search?search_query=${encodeURIComponent(q)}`,
      );
      const courses: any[] = [];
      for (const c of data?.courses ?? []) {
        // one malformed course must never 502 the whole search
        try {
          courses.push({
            id: String(c.id),
            club_name: c.club_name ?? null,
            course_name: c.course_name ?? null,
            city: c.location?.city ?? null,
            state: c.location?.state ?? null,
            // omit per-hole detail in the picker payload — keep it light
            tees: flattenTees(c).map(({ holes: _h, ...t }) => t),
          });
        } catch (e) {
          console.error(`[courses] search map skipped ${String(c?.id ?? "?")} :: ${String((e as Error)?.message ?? e)}`);
        }
      }
      // The search payload no longer carries tee arrays (counts since ~2026-08-16),
      // so fill tees from OUR dataset for known courses, then detail-fetch a
      // bounded few unknowns (which also caches them — the dataset builds itself).
      try {
        const bare = courses.filter((c) => c.tees.length === 0);
        if (bare.length) {
          const { data: cachedTees } = await admin
            .from("api_course_tees")
            .select("course_id, gender, tee_name, course_rating, slope_rating, bogey_rating, par_total, total_yards, number_of_holes")
            .in("course_id", bare.map((c) => c.id));
          for (const c of bare) {
            c.tees = (cachedTees ?? []).filter((t) => t.course_id === c.id)
              .map(({ course_id: _cid, ...t }) => t);
          }
          let fetches = 0;
          for (const c of courses) {
            if (c.tees.length || fetches >= SEARCH_DETAIL_FETCHES) continue;
            fetches++;
            try {
              await fetchAndStore(admin, c.id);
              const { data: fresh } = await admin
                .from("api_course_tees")
                .select("gender, tee_name, course_rating, slope_rating, bogey_rating, par_total, total_yards, number_of_holes")
                .eq("course_id", c.id);
              c.tees = fresh ?? [];
            } catch (e) {
              console.error(`[courses] search detail fetch failed for ${c.id} :: ${String((e as Error)?.message ?? e)}`);
            }
          }
        }
      } catch (e) {
        // enrichment is best-effort: bare courses still answer, the client's
        // manual-entry row covers the rest
        console.error(`[courses] search enrichment failed :: ${String((e as Error)?.message ?? e)}`);
      }
      return json({ courses });
    }

    if (action === "cache") {
      const id = String(body.id ?? "").trim();
      if (!id) return json({ error: "id required" }, 400);
      // Serve-always, refresh quietly (owner ruling): a course in our dataset
      // NEVER goes stale from the user's view — the tee pick answers from
      // cache instantly, whatever its age and whatever the API's health. Past
      // the refresh window we ALSO kick a background re-fetch after the
      // response is sent; if that fails (429, outage), nobody notices —
      // freshness is a background concern, never a foreground one. Re-rates
      // move on a multi-year cadence, so 180 days catches them comfortably.
      const REFRESH_MS = 180 * 24 * 3600 * 1000;
      const { data: hit } = await admin
        .from("api_courses").select("id, cached_at").eq("id", id).maybeSingle();
      if (hit) {
        const { data: teeIds } = await admin
          .from("api_course_tees").select("id").eq("course_id", id);
        let holeCount = 0;
        if (teeIds?.length) {
          const { count } = await admin
            .from("api_course_holes").select("*", { count: "exact", head: true })
            .in("tee_id", teeIds.map((t) => t.id));
          holeCount = count ?? 0;
        }
        if (holeCount > 0) {
          const age = Date.now() - new Date(hit.cached_at ?? 0).getTime();
          if (age > REFRESH_MS) {
            console.log(`[courses] cache hit for ${id} — refreshing in background (age ${Math.round(age / 86400000)}d)`);
            const refresh = fetchAndStore(admin, id)
              .then(() => console.log(`[courses] background refresh ok for ${id}`))
              .catch((e) => console.error(`[courses] background refresh failed for ${id} :: ${String((e as Error)?.message ?? e)}`));
            // waitUntil keeps the isolate alive past the response; without it
            // (older runtime) the promise is fire-and-forget — cache still serves
            (globalThis as any).EdgeRuntime?.waitUntil?.(refresh);
          } else {
            console.log(`[courses] cache hit for ${id} — no API call`);
          }
          return json({ ok: true, id, from_cache: true });
        }
      }
      // not in the dataset (or hole rows missing): this is the pull that
      // BUILDS the dataset — fetch, store, answer
      const cid = await fetchAndStore(admin, id);
      return json({ ok: true, id: cid });
    }

    return json({ error: "unknown action" }, 400);
  } catch (e) {
    const msg = String((e as Error)?.message ?? e);
    console.error(`[courses] action=${String(action ?? "")} failed :: ${msg}`);
    return json({ error: msg }, 502);
  }
});
