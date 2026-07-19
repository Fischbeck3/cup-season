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
  if (!r.ok) throw new Error(`golfcourseapi ${r.status}`);
  return r.json();
}

// GolfCourseAPI groups tees by gender; flatten to one tagged list.
function flattenTees(course: any) {
  const out: any[] = [];
  const t = course?.tees ?? {};
  for (const gender of ["male", "female"]) {
    for (const te of t[gender] ?? []) {
      out.push({
        gender,
        tee_name: te.tee_name ?? null,
        course_rating: te.course_rating ?? null,
        slope_rating: te.slope_rating ?? null,
        bogey_rating: te.bogey_rating ?? null,
        par_total: te.par_total ?? null,
        total_yards: te.total_yards ?? null,
        number_of_holes: te.number_of_holes ?? (te.holes?.length ?? null),
        holes: (te.holes ?? []).map((h: any, i: number) => ({
          hole_number: h.hole ?? i + 1,
          par: h.par ?? null,
          yardage: h.yardage ?? null,
          handicap: h.handicap ?? null,
        })),
      });
    }
  }
  return out;
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

  // -- per-user daily cap (paid API — refuse before spending). Retune from the
  //    SQL editor: update app_flags set value=... where key='courses'.
  const { data: capRow } = await admin
    .from("app_flags").select("value").eq("key", "courses").maybeSingle();
  const dailyCap = Number((capRow?.value as any)?.daily_per_user ?? 150);
  const dayAgo = new Date(Date.now() - 24 * 3600 * 1000).toISOString();
  const { count: used } = await admin.from("courses_usage")
    .select("*", { count: "exact", head: true })
    .eq("profile_id", uid).gte("created_at", dayAgo);
  if ((used ?? 0) >= dailyCap) {
    return json({ error: "daily course-lookup limit reached" }, 429);
  }

  let body: any;
  try {
    body = await req.json();
  } catch {
    return json({ error: "bad request body" }, 400);
  }
  const action = body?.action;
  // ledger = the rate-limit counter; best-effort, never blocks the response
  admin.from("courses_usage").insert({ profile_id: uid, action: String(action ?? "") })
    .then(() => {}, () => {});

  try {
    if (action === "search") {
      const q = String(body.q ?? "").trim();
      if (q.length < 3) return json({ courses: [] });
      const data = await gca(
        `/v1/search?search_query=${encodeURIComponent(q)}`,
      );
      const courses = (data?.courses ?? []).map((c: any) => ({
        id: String(c.id),
        club_name: c.club_name ?? null,
        course_name: c.course_name ?? null,
        city: c.location?.city ?? null,
        state: c.location?.state ?? null,
        // omit per-hole detail in the picker payload — keep it light
        tees: flattenTees(c).map(({ holes: _h, ...t }) => t),
      }));
      return json({ courses });
    }

    if (action === "cache") {
      const id = String(body.id ?? "").trim();
      if (!id) return json({ error: "id required" }, 400);
      const data = await gca(`/v1/courses/${encodeURIComponent(id)}`);
      const c = data?.course ?? data;
      const cid = String(c.id ?? id);
      // admin client created at the top (caller-gated + capped)

      // api_* tables: the original `courses`/`course_tees`/`course_holes`
      // names collided with a legacy uuid schema, so upserts silently failed
      // (text ids into uuid columns). See 20260714050000_course_cache_reconcile.
      await admin.from("api_courses").upsert({
        id: cid,
        club_name: c.club_name ?? null,
        course_name: c.course_name ?? null,
        city: c.location?.city ?? null,
        state: c.location?.state ?? null,
        country: c.location?.country ?? null,
        latitude: c.location?.latitude ?? null,
        longitude: c.location?.longitude ?? null,
        raw: c,
        cached_at: new Date().toISOString(),
      });

      // replace tees + holes so a re-cache is a clean refresh
      await admin.from("api_course_tees").delete().eq("course_id", cid);
      for (const te of flattenTees(c)) {
        const { data: teeRow, error } = await admin
          .from("api_course_tees")
          .insert({
            course_id: cid,
            gender: te.gender,
            tee_name: te.tee_name,
            course_rating: te.course_rating,
            slope_rating: te.slope_rating,
            bogey_rating: te.bogey_rating,
            par_total: te.par_total,
            total_yards: te.total_yards,
            number_of_holes: te.number_of_holes,
          })
          .select("id")
          .single();
        if (error || !teeRow) continue;
        if (te.holes?.length) {
          await admin
            .from("api_course_holes")
            .insert(te.holes.map((h: any) => ({ tee_id: teeRow.id, ...h })));
        }
      }
      return json({ ok: true, id: cid });
    }

    return json({ error: "unknown action" }, 400);
  } catch (e) {
    return json({ error: String((e as Error)?.message ?? e) }, 502);
  }
});
