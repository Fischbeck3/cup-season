/* Cup Season · the ten-capture SYNTHETIC CAST (WX lane, 2026-09-28).
 *
 * Every person, league, course and round a ten capture can show is defined
 * here, once. None of them is a real golfer, a real league or a real course:
 * the surnames are words for "fake" on purpose (Fixture, Sample, Placeholder,
 * Testwell, Mockridge, Stubbs, Dummett, Examplar, Sandbox, Specimen), every
 * email ends in the reserved `.invalid` TLD, and every league and course name
 * carries "(fixture)". Names that exist in tests/fixtures/home-states.json and
 * tests/fixtures/season-book/*.json are NOT reused -- those files name pilot
 * people, and tests/ten-fixtures-build.mjs rewrites them through its
 * HOME_RENAMES and BOOK_RENAMES tables into the synthetic copies under
 * tests/fixtures/ten/ (its FORBIDDEN scan fails the build if one survives)
 * before any capture can show them.
 *
 * Deterministic: no Math.random, no Date.now. The capture clock is fixed at
 * CAPTURE_NOW, and every date here is an ISO literal or an offset from it. */

export const CAPTURE_NOW = '2026-09-28T09:30:00-07:00'   /* Monday, America/Phoenix (no DST) */
export const TODAY = '2026-09-28'
export const TZ = 'America/Phoenix'

const U = (block, n) => `${block}-0000-4000-8000-${String(n).padStart(12, '0')}`
export const uid = (n) => U('f1000000', n)          /* profiles / auth users */
export const lid = (n) => U('f3000000', n)          /* leagues */
export const mid = (l, n) => U('f2000000', l * 100 + n)   /* league_members */
export const sid = (l, n) => U('f4000000', l * 10 + n)    /* seasons */
export const qid = (l, n) => U('f5000000', l * 10 + n)    /* squads */
export const rid = (n) => U('f6000000', n)          /* rounds */
export const pid = (n) => U('f7000000', n)          /* posts */
export const eid = (n) => U('f8000000', n)          /* events */
export const cid = (n) => U('f9000000', n)          /* courses (api_courses ids are ints in prod; ours are ints too, below) */

/* ---- people ---- */
export const PEOPLE = [
  { n: 1,  name: 'Avery Fixture',               handle: 'avery',   marker: 'saguaro',    index: 14.2, city: 'Mesa, AZ',       email: 'avery.fixture@example.invalid' },
  { n: 2,  name: 'Blake Sample',                handle: 'blake',   marker: 'lighthouse', index: 9.8,  city: 'Chandler, AZ',      email: 'blake.sample@example.invalid' },
  { n: 3,  name: 'Casey Placeholder',           handle: 'casey',   marker: 'lonetree',   index: 18.4, city: 'Chandler, AZ',   email: 'casey.placeholder@example.invalid' },
  { n: 4,  name: 'Devon Testwell',              handle: 'devon',   marker: 'island',     index: 6.1,  city: 'Gilbert, AZ',    email: 'devon.testwell@example.invalid' },
  { n: 5,  name: 'Emery Mockridge',             handle: 'emery',   marker: 'dunes',      index: 21.7, city: 'Mesa, AZ',       email: 'emery.mockridge@example.invalid' },
  { n: 6,  name: 'Finley Stubbs',               handle: 'finley',  marker: 'shark',      index: 12.3, city: 'Phoenix, AZ',    email: 'finley.stubbs@example.invalid' },
  { n: 7,  name: 'Gray Dummett',                handle: 'gray',    marker: 'pews',       index: 15.9, city: 'Scottsdale, AZ', email: 'gray.dummett@example.invalid' },
  { n: 8,  name: 'Harper Examplar',             handle: 'harper',  marker: 'jug',        index: 3.4,  city: 'Chandler, AZ',      email: 'harper.examplar@example.invalid' },
  { n: 9,  name: 'Indigo Longname-Fixturington', handle: 'indigo', marker: 'thistle',    index: 27.0, city: 'Apache Junction, AZ', email: 'indigo.fixturington@example.invalid' },
  { n: 10, name: 'Jules Sandbox',               handle: 'jules',   marker: 'beer',       index: 11.1, city: 'Tucson, AZ',     email: 'jules.sandbox@example.invalid' },
  { n: 11, name: 'Kit Specimen',                handle: 'kit',     marker: 'no2',        index: 16.6, city: 'Flagstaff, AZ',  email: 'kit.specimen@example.invalid' },
]
export const person = (n) => PEOPLE.find((p) => p.n === n)

/* ---- courses (invented; api ids are ints, as the GolfCourseAPI cache's are) ---- */
export const COURSES = [
  { id: 910001, club: 'Saguaro Flats Municipal (fixture)', course: 'Saguaro Flats', city: 'Mesa', state: 'AZ', tees: [
    { tee: 'Blue', gender: 'male', rating: 70.1, slope: 121, holes: 18, yards: 6412 },
    { tee: 'White', gender: 'male', rating: 68.4, slope: 116, holes: 18, yards: 6011 } ] },
  { id: 910002, club: 'Mesquite Wash Golf Club (fixture)', course: 'Mesquite Wash', city: 'Scottsdale', state: 'AZ', tees: [
    { tee: 'Black', gender: 'male', rating: 71.8, slope: 129, holes: 18, yards: 6790 } ] },
  { id: 910003, club: 'Sandbox Fixture Links', course: 'North', city: 'Phoenix', state: 'AZ', tees: [
    { tee: 'Gold', gender: 'male', rating: 68.9, slope: 115, holes: 18, yards: 5902 } ] },
  { id: 910004, club: 'The Championship Course at Whispering Fixture Pines Country Club', course: 'Championship', city: 'Fixture Junction', state: 'AZ', tees: [
    { tee: 'Tournament Tips (Championship Black)', gender: 'male', rating: 73.4, slope: 138, holes: 18, yards: 7244 } ] },
  { id: 910005, club: 'Dry Creek Nine (fixture)', course: 'Dry Creek', city: 'Chandler', state: 'AZ', tees: [
    { tee: 'Forward', gender: 'male', rating: 34.6, slope: 112, holes: 9, yards: null } ] },
]
export const course = (id) => COURSES.find((c) => c.id === id)
export const courseLabel = (c, t) => `${c.club} · ${t.tee}`

/* standard par/SI for the 18-hole cards (a 9-hole card uses the first nine) */
export const PARS18 = [4, 5, 3, 4, 4, 4, 3, 5, 4, 4, 4, 3, 5, 4, 4, 3, 4, 5]
export const SI18 = [7, 1, 15, 11, 3, 9, 17, 5, 13, 8, 2, 16, 6, 12, 4, 18, 10, 14]

/* ---- leagues ---- */
export const LEAGUES = [
  { n: 1, name: 'North Grove (fixture)', code: 'NGFX26', phase: 'season', sandbox: false, pro: 2,
    members: [1, 2, 3, 4, 5, 6, 7, 8],
    season: { number: 1, starts_on: '2026-08-09', ends_on: '2026-11-07', status: 'active', pot_cents: 60000, collected_cents: 52500 },
    squads: [ { n: 1, name: 'Fixture Wrens', color: 0, captain: 3, members: [1, 3, 5, 7] },
              { n: 2, name: 'Fixture Javelinas', color: 1, captain: 2, members: [2, 4, 6, 8] } ],
    settings: { preset: 'standard', handicap_allowance: 95, verification: 'attested', counting_cap: 4, participation_floor: 2,
      floor_penalty: 'deduct', season_format: 'points', buyin_cents: 7500, season_months: 3, sim_rounds_allowed: true,
      nine_hole_allowed: true, locked_at: '2026-08-02T18:00:00Z', structure: 'squads2', draft_type: 'random',
      payout_champ: 60, payout_runnerup: 25, payout_king: 15, finish: 'cup_final' } },
  { n: 2, name: 'South Wash Weekday (fixture)', code: 'SWFX26', phase: 'season', sandbox: false, pro: 1,
    members: [1, 9, 10, 4],
    season: { number: 2, starts_on: '2026-09-06', ends_on: '2026-12-05', status: 'active', pot_cents: 0, collected_cents: 0 },
    squads: [],
    settings: { preset: 'casual', handicap_allowance: 100, verification: 'honor', counting_cap: null, participation_floor: 0,
      floor_penalty: 'none', season_format: 'points', buyin_cents: 0, season_months: 3, sim_rounds_allowed: true,
      nine_hole_allowed: true, locked_at: '2026-09-01T18:00:00Z', structure: 'solo', draft_type: 'random',
      payout_champ: 60, payout_runnerup: 25, payout_king: 15, finish: 'points_table' } },
]

/* ---- rounds: deterministic, dated, real arithmetic ---- */
/* A small seeded generator (mulberry32) keeps every run byte-identical. */
function mulberry32(a) { return function () { a |= 0; a = (a + 0x6D2B79F5) | 0; let t = Math.imul(a ^ (a >>> 15), 1 | a); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return ((t ^ (t >>> 14)) >>> 0) / 4294967296 } }
const iso = (y, m, d) => `${y}-${String(m).padStart(2, '0')}-${String(d).padStart(2, '0')}`
export function addDays(isoDate, n) {
  const [y, m, d] = isoDate.split('-').map(Number)
  const t = new Date(Date.UTC(y, m - 1, d + n))
  return iso(t.getUTCFullYear(), t.getUTCMonth() + 1, t.getUTCDate())
}
export const r1 = (x) => Math.round(x * 10) / 10

/* played dates per person: offsets (days before TODAY) */
const PLAYED = {
  1: [1, 6, 13, 20, 27, 34, 41, 48],
  2: [2, 9, 16, 23, 30, 37, 44],
  3: [3, 17, 31, 45],
  4: [1, 8, 15, 22, 29, 36, 43],
  5: [5, 26, 40],
  6: [4, 11, 25, 39, 46],
  7: [2, 16, 30, 44],
  8: [6, 13, 20, 27, 34, 41],
  9: [7, 21],
  10: [3, 10],
  11: [],
}
export function buildRounds() {
  const out = []
  let n = 1
  for (const p of PEOPLE) {
    const rng = mulberry32(1000 + p.n)
    const offs = PLAYED[p.n] || []
    offs.forEach((off, k) => {
      const c = COURSES[(p.n + k) % 4]                           /* the 18-hole courses */
      const t = c.tees[0]
      const nine = p.n === 1 && k === 3                         /* one nine-hole round in Avery's record */
      const cc = nine ? COURSES[4] : c, tt = nine ? COURSES[4].tees[0] : t
      const par = nine ? 36 : 72
      const idx = r1(p.index + (k - offs.length / 2) * 0.1)
      const swing = Math.round((rng() - 0.45) * 8)
      const gross = nine ? Math.round(par + idx / 2 + swing / 2) : Math.round(par + idx + swing)
      const diff = nine ? r1(((gross - tt.rating) * 113 / tt.slope) * 2) : r1((gross - tt.rating) * 113 / tt.slope)
      const played_on = addDays(TODAY, -off)
      out.push({
        n, id: rid(n), profile_id: uid(p.n), person: p.n, gross, rating: tt.rating, slope: tt.slope,
        differential: diff, index_at_post: idx, played_on, course_label: courseLabel(cc, tt), api_course_id: cc.id,
        holes_played: nine ? 9 : 18, tee_name: tt.tee, par,
        photo_path: (p.n === 1 && k === 0) ? `rounds/${uid(1)}/${rid(n)}.jpg` : (p.n === 2 && k === 0 ? `rounds/${uid(2)}/${rid(n)}.jpg` : null),
        created_at: `${played_on}T20:${String(10 + (n % 40)).padStart(2, '0')}:00-07:00`,
      })
      n++
    })
  }
  return out
}

/* PvI and points, the band table of tests/fixtures/bands.json */
export function pviOf(r, allowance = 95) { return r1(r.index_at_post * allowance / 100 - r.differential) }
export function pointsOf(pvi) { return pvi >= 3 ? 12 : pvi >= 1 ? 9 : pvi > -1 ? 7 : pvi >= -3 ? 6 : 5 }
export function bandOf(pvi) { return pvi >= 3 ? 'Torched it' : pvi >= 1 ? 'Beat your number' : pvi > -1 ? 'Played to it' : pvi >= -3 ? 'A little loose' : 'Posted anyway' }

/* ---- the rename table for legacy fixtures that name pilot people ----
   Applied to tests/fixtures/home-states.json and tests/fixtures/season-book/*
   before any capture sees them (see tests/ten-fixtures-build.mjs). The keys
   are matched as whole words, longest first. `TEN_NAME_POOL` supplies a fresh
   synthetic name for any person-name the scan finds that is not listed. */
export const TEN_NAME_POOL = [
  'Lane Mockup', 'Morgan Stand-In', 'Noel Dryrun', 'Oakley Proxy', 'Parker Sampleton', 'Quinn Draftly',
  'Reese Simulant', 'Sage Pretendo', 'Tatum Rehearsal', 'Umber Testcase', 'Vale Mannequin', 'Wren Understudy',
  'Xan Prototype', 'Yael Scaffold', 'Zion Fauxley', 'Arden Dummyworth', 'Bellamy Figment', 'Cruz Hypothetica',
  'Dale Examplewood', 'Ellis Notreal', 'Frankie Fictive', 'Gale Madeup', 'Hollis Imaginary', 'Ira Inventa',
]
