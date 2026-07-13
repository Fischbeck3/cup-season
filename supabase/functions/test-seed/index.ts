// Cup Season — test-world seed (pre-pilot QA tool).
//
// Builds a full populated world for the CALLER's real account: 8 bot golfers
// (discoverable='nobody' so they never leak into the real crew's search),
// four leagues in different states, weeks of scored rounds, a friend graph,
// scheduled rounds, and a Ryder event attached to a league (decision B).
//
//   POST { action: "seed" }   → tears down any prior test world, then builds fresh
//   POST { action: "reset" }  → tears the test world down, leaving prod spotless
//
// Bots are auth users under @cupseason.test; teardown deletes them and their
// leagues/events, and the FK cascades wipe everything else. Rounds you posted
// as yourself are never touched. Caller-scoped: only ever seeds the signed-in
// account. Requires SUPABASE_URL / SERVICE_ROLE_KEY / ANON_KEY (auto-injected).

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SB_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ANON = Deno.env.get("SUPABASE_ANON_KEY") ?? "";
const BOT_DOMAIN = "cupseason.test";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...cors, "Content-Type": "application/json" } });

// ---- date helpers (Deno runtime — real Date is fine here) ----
const iso = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}-${String(d.getDate()).padStart(2, "0")}`;
function sundayOffsetWeeks(w: number): Date {          // Sunday, w weeks from this week's Sunday (w<0 = past)
  const d = new Date(); d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() - d.getDay() + w * 7);
  return d;
}
const addDays = (d: Date, n: number) => { const x = new Date(d); x.setDate(x.getDate() + n); return x; };

const BOTS = [
  { n: "Diego Marsh",  city: "Mesa, AZ",     idx: 6.2,  mk: "saguaro",  h: "diego_m" },
  { n: "Priya Anand",  city: "Chandler, AZ", idx: 11.4, mk: "saguaro",  h: "priya_a" },
  { n: "Sam Whitlock", city: "Gilbert, AZ",  idx: 14.9, mk: "saguaro",  h: "sam_w" },
  { n: "Marcus Reyes", city: "Tempe, AZ",    idx: 9.1,  mk: "saguaro",  h: "marcus_r" },
  { n: "Wes Okafor",   city: "Scottsdale, AZ", idx: 18.3, mk: "saguaro", h: "wes_o" },
  { n: "Tara Nguyen",  city: "Phoenix, AZ",  idx: 21.7, mk: "saguaro",  h: "tara_n" },
  { n: "Cole Bennett", city: "Peoria, AZ",   idx: 16.0, mk: "saguaro",  h: "cole_b" },
  { n: "Nia Foster",   city: "Glendale, AZ", idx: 12.8, mk: "saguaro",  h: "nia_f" },
];
const COURSES = ["Papago GC", "Encanto GC", "Aguila GC", "Cave Creek GC", "Grand Canyon University GC"];

async function reset(admin: any, me?: string) {
  const removed: Record<string, number> = { events: 0, leagues: 0, bots: 0 };
  const { data: bots } = await admin.from("profiles").select("id").like("email", `%@${BOT_DOMAIN}`);
  const ids = (bots ?? []).map((b: any) => b.id);
  // the bot-commissioned test leagues
  let leagueIds: string[] = [];
  if (ids.length) {
    const { data: lgs } = await admin.from("leagues").select("id").in("commissioner_id", ids);
    leagueIds = (lgs ?? []).map((l: any) => l.id);
  }
  // events to remove: created by a bot, attached to a test league, or the
  // caller's seeded 'The Grudge' (created_by=you, may be detached/orphaned).
  // Delete events BEFORE their leagues, else league delete null-orphans them.
  const evIds = new Set<string>();
  const collect = (rows: any) => (rows ?? []).forEach((e: any) => evIds.add(e.id));
  if (ids.length)       collect((await admin.from("events").select("id").in("created_by", ids)).data);
  if (leagueIds.length) collect((await admin.from("events").select("id").in("league_id", leagueIds)).data);
  if (me)               collect((await admin.from("events").select("id").eq("created_by", me).eq("name", "The Grudge")).data);
  for (const eid of evIds) { await admin.from("events").delete().eq("id", eid); removed.events++; }
  // leagues (cascade members/squads/seasons/posts/buy_ins)
  for (const lid of leagueIds) { await admin.from("leagues").delete().eq("id", lid); removed.leagues++; }
  // bot auth users → cascade profiles + rounds + event_players + friendships
  for (const id of ids) { try { await admin.auth.admin.deleteUser(id); removed.bots++; } catch (_) {} }
  return removed;
}

// insert a scored round; the score_round trigger fills differential/pvi and
// round_to_board fans a 'round' post to the member's league boards
async function seedRound(admin: any, profileId: string, seasonId: string, idx: number, playedOn: Date, i: number) {
  const rating = 70 + (i % 3);
  const slope = 121 + (i % 8);
  const noise = [-3, 1, 4, -1, 6, 2, -2, 3, 0, 5][i % 10];
  const gross = Math.max(66, Math.round(rating + idx * slope / 113 + noise));
  await admin.from("rounds").insert({
    profile_id: profileId, season_id: seasonId, course_label: COURSES[i % COURSES.length],
    played_on: iso(playedOn), holes_played: 18, gross, rating, slope,
    index_at_post: idx, source: "quick",
  });
}

async function seed(admin: any, me: string) {
  const log: string[] = [];
  await reset(admin, me);

  // ---- 1. bots ----
  const bot: { id: string; idx: number; name: string; mk: string }[] = [];
  for (let i = 0; i < BOTS.length; i++) {
    const b = BOTS[i];
    const { data: created, error } = await admin.auth.admin.createUser({
      email: `seed+bot${i}@${BOT_DOMAIN}`, email_confirm: true,
    });
    if (error || !created?.user) { log.push(`bot ${i} createUser failed: ${error?.message}`); continue; }
    const id = created.user.id;
    await admin.from("profiles").update({
      display_name: b.n, city: b.city, index_current: b.idx, marker: b.mk,
      handle: b.h, discoverable: "nobody",
    }).eq("id", id);
    bot.push({ id, idx: b.idx, name: b.n, mk: b.mk });
  }
  log.push(`bots: ${bot.length}`);
  if (bot.length < 8) return { ok: false, log };

  // helper: build a league with a season, members, optional squads, rounds
  async function buildLeague(cfg: {
    name: string; code: string; structure: string; format: string;
    startWk: number; months: number; status: string; kicked: boolean;
    memberBots: number[]; squads?: { name: string; color: number; bots: number[]; meCaptain?: boolean }[];
    weeksOfRounds: number;
  }) {
    const commish = bot[cfg.memberBots[0]];                 // a bot owns the league (tears down cleanly)
    const { data: lg } = await admin.from("leagues").insert({
      name: cfg.name, code: cfg.code, phase: "season", commissioner_id: commish.id,
    }).select("id").single();
    const leagueId = lg.id;
    await admin.from("league_settings").insert({
      league_id: leagueId, structure: cfg.structure, season_format: cfg.format,
      preset: "standard", locked_at: new Date().toISOString(),
    });
    const starts = sundayOffsetWeeks(cfg.startWk);
    const ends = addDays(starts, cfg.months * 4 * 7 - 1);
    const { data: se } = await admin.from("seasons").insert({
      league_id: leagueId, number: 1, starts_on: iso(starts), ends_on: iso(ends),
      status: cfg.status, kicked_off: cfg.kicked,
    }).select("id").single();
    const seasonId = se.id;

    // members: me (commish is a bot, so I'm a player) + the bots
    const memberId: Record<string, string> = {};
    const meMem = await admin.from("league_members").insert({
      league_id: leagueId, profile_id: me, role: "player", index_current: 12.4,
    }).select("id").single();
    memberId[me] = meMem.data.id;
    for (const bi of cfg.memberBots) {
      const role = bot[bi].id === commish.id ? "commissioner" : "player";
      const m = await admin.from("league_members").insert({
        league_id: leagueId, profile_id: bot[bi].id, role, index_current: bot[bi].idx,
      }).select("id").single();
      memberId[bot[bi].id] = m.data.id;
    }
    // squads
    if (cfg.squads) {
      for (const sq of cfg.squads) {
        const meCap = sq.meCaptain ? memberId[me] : null;
        const { data: sqr } = await admin.from("squads").insert({
          season_id: seasonId, name: sq.name, color: sq.color, captain_member_id: meCap,
        }).select("id").single();
        const seat = async (mid: string) => { await admin.from("squad_members").insert({ squad_id: sqr.id, member_id: mid }); };
        if (sq.meCaptain) await seat(memberId[me]);
        for (const bi of sq.bots) await seat(memberId[bot[bi].id]);
      }
    }
    // rounds across the weeks (pre-kickoff leagues pass weeksOfRounds: 0)
    if (cfg.weeksOfRounds > 0) {
      const roster = [{ pid: me, idx: 12.4 }, ...cfg.memberBots.map((bi) => ({ pid: bot[bi].id, idx: bot[bi].idx }))];
      let ri = 0;
      for (const r of roster) {
        const n = 6 + (ri % 4);                              // 6–9 rounds each
        for (let k = 0; k < n; k++) {
          const day = addDays(starts, Math.min(cfg.weeksOfRounds * 7 - 1, k * 5 + (ri % 4)));
          await seedRound(admin, r.pid, seasonId, r.idx, day, k + ri);
        }
        ri++;
      }
    }
    // a couple of board posts
    await admin.from("posts").insert([
      { league_id: leagueId, season_id: seasonId, kind: "system", body: `${cfg.name} is live — say hello on the board` },
      { league_id: leagueId, season_id: seasonId, kind: "chat", member_id: memberId[commish.id], body: "Floor is 2 rounds this month. No excuses." },
    ]);
    // buy-ins
    for (const bi of cfg.memberBots) {
      await admin.from("buy_ins").insert({
        season_id: seasonId, member_id: memberId[bot[bi].id], amount_cents: 7500,
        paid: bi % 3 !== 0, marked_by: memberId[commish.id], marked_at: new Date().toISOString(),
      });
    }
    await admin.from("buy_ins").insert({ season_id: seasonId, member_id: memberId[me], amount_cents: 7500, paid: true });
    return { leagueId, seasonId, memberId, commish };
  }

  // ---- 2. four leagues, one of each state ----
  const L1 = await buildLeague({ name: "Ridgeline Cup", code: "TSTRDG", structure: "squads2", format: "hybrid",
    startWk: -7, months: 6, status: "active", kicked: true, memberBots: [0, 1, 2, 3, 4, 5, 6],
    squads: [{ name: "Mudsharks", color: 0, bots: [0, 1, 2], meCaptain: true }, { name: "Sandbaggers", color: 1, bots: [3, 4, 5, 6] }],
    weeksOfRounds: 7 });
  log.push("L1 Ridgeline Cup (squads2, mid-season) ✓");

  await buildLeague({ name: "Fairway Society", code: "TSTFWY", structure: "solo", format: "points",
    startWk: -5, months: 6, status: "active", kicked: true, memberBots: [1, 3, 5, 7], weeksOfRounds: 5 });
  log.push("L2 Fairway Society (solo, mid-season) ✓");

  await buildLeague({ name: "Winter Circuit", code: "TSTWIN", structure: "squads4", format: "hybrid",
    startWk: 1, months: 6, status: "active", kicked: false, memberBots: [0, 1, 2, 3, 4, 5, 6, 7],
    squads: [{ name: "Frost", color: 0, bots: [0, 1], meCaptain: true }, { name: "Timber", color: 1, bots: [2, 3] },
             { name: "Granite", color: 2, bots: [4, 5] }, { name: "Ember", color: 3, bots: [6, 7] }],
    weeksOfRounds: 0 });
  log.push("L3 Winter Circuit (squads4, pre-kickoff) ✓");

  const L4 = await buildLeague({ name: "Sunset Match", code: "TSTSUN", structure: "squads2", format: "h2h",
    startWk: -22, months: 6, status: "cup_final", kicked: true, memberBots: [2, 4, 6, 7, 1],
    squads: [{ name: "Coyotes", color: 2, bots: [2, 4], meCaptain: true }, { name: "Scorpions", color: 3, bots: [6, 7, 1] }],
    weeksOfRounds: 20 });
  // lock cup finalists (both squads advance in a 2-squad league)
  const { data: l4sq } = await admin.from("squads").select("id").eq("season_id", L4.seasonId);
  let seed4 = 1;
  for (const s of l4sq ?? []) { await admin.from("cup_finalists").insert({ season_id: L4.seasonId, squad_id: s.id, seed: seed4, head_start: seed4 === 1 ? 10 : 0 }); seed4++; }
  log.push("L4 Sunset Match (squads2, Cup Final) ✓");

  // ---- 3. friend graph: me ↔ several bots, accepted ----
  for (const bi of [0, 3, 5, 7]) {
    await admin.from("friendships").insert({ requester: me, addressee: bot[bi].id, status: "accepted", responded_at: new Date().toISOString() });
  }
  log.push("friends: 4 accepted");

  // ---- 4. scheduled rounds (calendar life; one tags me, one at Pebble) ----
  await admin.from("scheduled_rounds").insert([
    { profile_id: bot[4].id, play_on: iso(addDays(sundayOffsetWeeks(2), 6)), course_label: "Pebble Beach", note: "buddies trip — who's in?" },
    { profile_id: bot[0].id, play_on: iso(addDays(new Date(), 3)), course_label: "Papago GC", note: "early tee", tagged: [me] },
    { profile_id: bot[2].id, play_on: iso(addDays(new Date(), 9)), course_label: "Aguila GC" },
  ]);
  log.push("scheduled rounds: 3");

  // ---- 5. Ryder event "The Grudge", attached to Ridgeline Cup (decision B) ----
  const gStart = sundayOffsetWeeks(-2);
  const { data: ev } = await admin.from("events").insert({
    name: "The Grudge", created_by: L1.commish.id, league_id: L1.leagueId, kind: "ryder",
    status: "live", starts_on: iso(gStart), session_count: 3, session_weeks: 1, draw_rule: "team_pvi", allowance: 100,
  }).select("id").single();
  const eventId = ev.id;
  const { data: tRed } = await admin.from("event_teams").insert({ event_id: eventId, slot: 0, name: "Red", color: 1 }).select("id").single();
  const { data: tBlue } = await admin.from("event_teams").insert({ event_id: eventId, slot: 1, name: "Blue", color: 0 }).select("id").single();
  // 3 v 3: me + 2 bots vs 3 bots
  const redP = [{ pid: me, cap: true }, { pid: bot[0].id }, { pid: bot[1].id }];
  const blueP = [{ pid: bot[3].id, cap: true }, { pid: bot[4].id }, { pid: bot[5].id }];
  const epId: Record<string, string> = {};
  let sd = 0;
  for (const p of redP) { const { data } = await admin.from("event_players").insert({ event_id: eventId, profile_id: p.pid, team_id: tRed.id, role: p.cap ? "captain" : "player", seed: sd++ }).select("id").single(); epId[p.pid] = data.id; }
  sd = 0;
  for (const p of blueP) { const { data } = await admin.from("event_players").insert({ event_id: eventId, profile_id: p.pid, team_id: tBlue.id, role: p.cap ? "captain" : "player", seed: sd++ }).select("id").single(); epId[p.pid] = data.id; }
  if (tRed.captain_player_id === undefined) await admin.from("event_teams").update({ captain_player_id: epId[me] }).eq("id", tRed.id);
  await admin.from("event_teams").update({ captain_player_id: epId[bot[3].id] }).eq("id", tBlue.id);
  // sessions: 1 & 2 resolved, 3 upcoming
  const sess: string[] = [];
  for (let i = 0; i < 3; i++) {
    const o = addDays(gStart, i * 7);
    const { data } = await admin.from("event_sessions").insert({
      event_id: eventId, session_no: i + 1, opens_on: iso(o), closes_on: iso(addDays(o, 6)),
      status: i < 2 ? "closed" : "upcoming",
    }).select("id").single();
    sess.push(data.id);
  }
  // duels for sessions 1 & 2 (resolved), pairing red[i] vs blue[i]
  const results = [
    [{ r: "a", a: 2.1, b: -0.4 }, { r: "b", a: -1.2, b: 0.8 }, { r: "halve", a: 1.0, b: 1.0 }],
    [{ r: "a", a: 1.6, b: 0.2 }, { r: "a", a: 0.9, b: -2.1 }, { r: "b", a: -0.5, b: 1.3 }],
  ];
  for (let s = 0; s < 2; s++) {
    for (let p = 0; p < 3; p++) {
      const res = results[s][p];
      await admin.from("event_duels").insert({
        event_id: eventId, session_id: sess[s], a_player: epId[redP[p].pid], b_player: epId[blueP[p].pid],
        a_pvi: res.a, b_pvi: res.b, result: res.r,
        a_points: res.r === "a" ? 1 : res.r === "halve" ? 0.5 : 0,
        b_points: res.r === "b" ? 1 : res.r === "halve" ? 0.5 : 0,
        resolved_at: new Date().toISOString(),
      });
    }
  }
  // session 3 pending pairings
  for (let p = 0; p < 3; p++) {
    await admin.from("event_duels").insert({ event_id: eventId, session_id: sess[2], a_player: epId[redP[p].pid], b_player: epId[blueP[p].pid], result: "pending" });
  }
  log.push("Ryder event 'The Grudge' (attached to Ridgeline Cup) ✓");

  return { ok: true, log };
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (!SERVICE) return json({ error: "SERVICE_ROLE_KEY missing" }, 500);
  let body: any; try { body = await req.json(); } catch { return json({ error: "bad body" }, 400); }

  // caller identity (only ever act on the signed-in account)
  const authClient = createClient(SB_URL, ANON, { global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } } });
  const { data: { user } } = await authClient.auth.getUser();
  if (!user) return json({ error: "not signed in" }, 401);
  const admin = createClient(SB_URL, SERVICE);

  try {
    if (body.action === "reset") return json({ ok: true, removed: await reset(admin, user.id) });
    if (body.action === "seed") return json(await seed(admin, user.id));
    return json({ error: "unknown action (use seed|reset)" }, 400);
  } catch (e) {
    return json({ error: String((e as Error)?.message ?? e) }, 500);
  }
});
