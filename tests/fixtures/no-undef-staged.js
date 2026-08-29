/* Fixture for preflight check 18 (free identifiers).
   This is the exact shape of the bug that shipped on 2026-08-04 and told every
   Pro "Lock failed" for 25 days: D97 deleted the `staged` array and left the
   reference in the return statement, where `node --check` cannot see it
   because the file parses perfectly. The check must find `staged` here.
   Do not "fix" this file — it is the assertion. */
async function lockBylaws() {
  const emails = ['a@b.com'];
  const nextPhase = 'draft';
  return { emails: emails.length, invited: staged.length, nextPhase };
}

/* And these must NOT be reported: a browser global, a typeof guard, and a
   name another classic block owns (the checker unions the blocks first). */
function alsoFine() {
  if (typeof STRUCT_MIN !== 'undefined') return document.title;
  return window.CS && localStorage.getItem('cs_theme');
}
