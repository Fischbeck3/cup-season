/* Cup Season · ten-capture, WX-D ids (links · setup · schedule · courses · settings).
 *
 * The one place the tokens and plan ids of this module live, so the RPC module
 * (tests/fixtures/ten/rpc/40-links-setup.mjs) and the state catalogue
 * (tests/ten-states.d/40-links-setup.mjs) can never disagree about which link
 * is which. Every id is a uuid in the cast's style, in two blocks of its own:
 * `fd40…` for link tokens and invitations, `fe40…` for plans (scheduled
 * rounds). Nothing here names a person: the payloads are built from the cast. */
const U = (block, n) => `${block}-0000-4000-8000-${String(n).padStart(12, '0')}`
export const tok = (n) => U('fd400000', n)
export const planId = (n) => U('fe400000', n)

/* /?share= (share_info) */
export const SHARE = {
  round: tok(1),          /* a round card, no photo */
  roundPhoto: tok(2),     /* the golfer shared the photo too */
  roundLong: tok(3),      /* the longest name and course in the cast, a nine */
  roundEscaped: tok(4),   /* markup in the name and the course: must render as text */
  roundNoBand: tok(5),    /* a round outside any season: no band line */
  roundBroken: tok(6),    /* photo:true, but the shared copy is gone (storage 404) */
  settlement: tok(10),    /* a settled match, with its hole strip */
  recap: tok(11),         /* a season recap */
  person: tok(20),        /* /?p= a golfer's card */
  personNew: tok(21),     /* /?p= a golfer with no rounds yet */
  plan: tok(30),          /* /?plan= a weekend round with a seat */
  planPast: tok(31),      /* /?plan= a day already played */
  dead: tok(255),         /* no row: every dead path answers null (D57) */
}

/* /?claim= (guest_live_state · claim_round_info · scan_claim_info) */
export const CLAIM = {
  valid: tok(101),        /* a tee-sheet guest seat, round final, unclaimed */
  used: tok(102),         /* the same kind of seat, already claimed */
  abandoned: tok(103),    /* the round was never finished */
  setup: tok(104),        /* the round has not teed off */
  scan: tok(105),         /* a scanned-scorecard partner row, unclaimed */
  dead: tok(199),         /* nothing answers it */
}

/* /?join= (league_by_code · join_covenant_info) */
export const JOIN = {
  season: 'NGFX26',       /* North Grove (fixture): in season, $75, two squads */
  free: 'SWFX26',         /* South Wash Weekday (fixture): in season, $0, solo, points table */
  setup: 'DSFX26',        /* Desert Setup League (fixture): still in setup, no season */
  dead: 'QQFX00',         /* resolves to no league */
}

/* in-app invitations (my_invites · join_covenant_for_invite) */
export const INVITE = {
  league: tok(301),       /* Blake invites Avery to North Grove (fixture) */
}

/* plans (my_schedule · round_detail) */
export const PLAN = {
  mine: planId(1),        /* Avery hosts, Wed Sep 30, two tagged */
  taggedMe: planId(2),    /* Blake hosts, Sat Oct 3, Avery tagged */
  leagueMate: planId(3),  /* Devon hosts, Sun Oct 4, nobody tagged */
  today: planId(4),       /* Casey hosts, today, the long course */
  nine: planId(5),        /* Avery hosts, Sat Oct 10, the nine with no yardage */
  past: planId(6),        /* Blake hosted, Sat Sep 26, Avery played */
}

/* the course ids (api_courses) this module leans on */
export const COURSE = { flats: 910001, wash: 910002, sandbox: 910003, long: 910004, nine: 910005 }
