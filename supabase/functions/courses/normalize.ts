// courses — numeric normalization for what the provider sends (D370 follow-up,
// review finding 1, 2026-09-19; corrected 2026-09-22).
//
// The course-cache RPC casts strictly, so one malformed field used to fail the
// WHOLE course, permanently. These helpers make every rating, slope, par,
// yardage, hole count and coordinate a finite number or null BEFORE the
// payload reaches SQL — and never anything else:
//   · null and undefined stay null (a missing fact is a missing fact);
//   · booleans, objects, arrays, NaN and ±Infinity become null (never 0 or 1);
//   · a numeric string the provider sends ("113") is a number; an empty or
//     non-numeric string is null;
//   · integers are rounded from finite numbers only.
// A missing course fact must never become an invented zero.

export function num(v: unknown): number | null {
  if (v == null) return null;                       // null and undefined
  if (typeof v === "number") return Number.isFinite(v) ? v : null;
  if (typeof v === "string") {
    const s = v.trim();
    if (s === "") return null;
    const n = Number(s);
    return Number.isFinite(n) ? n : null;
  }
  return null;                                      // boolean, object, array, bigint, symbol
}

export function int(v: unknown): number | null {
  const n = num(v);
  return n == null ? null : Math.round(n);
}

/// The hole count: the provider's number when it is one; else the number of
/// holes actually listed; else null — never 0 for a tee with no hole detail.
export function holeCount(numberOfHoles: unknown, holes: unknown): number | null {
  const said = int(numberOfHoles);
  if (said != null && said > 0) return said;
  const listed = Array.isArray(holes) ? holes.length : 0;
  return listed > 0 ? listed : null;
}
