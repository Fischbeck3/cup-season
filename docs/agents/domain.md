# Domain docs

## Before exploring

1. Read `docs/doc-map.md` and the canonical documents relevant to the work.
2. Read the relevant entries in `spec/decision-log.md`; this remains the
   authoritative mechanic decision log.
3. Read root `CONTEXT.md`, if present, for the domain glossary.
4. Read relevant records in `docs/adr/`, if present, for architectural decisions.

If the glossary or ADR directory does not exist, proceed silently. The
`domain-modeling` skill creates them when terms or decisions are resolved.

## Layout

Use a single shared context across web, iOS, and backend:

- `CONTEXT.md`: glossary at the repository root, created lazily.
- `docs/adr/NNNN-short-title.md`: architectural decisions, created lazily.
- `spec/decision-log.md`: existing mechanic decisions.

Client surfaces and shared packages consume the same product domain. They do
not each need a separate glossary. If an explicitly adopted `CONTEXT-MAP.md`
exists later, follow its pointers to the contexts relevant to the task.

## Vocabulary and authority

Use the glossary's terms for domain concepts. Until a term is defined there,
use the vocabulary in the governing product spec and decisions. When a missing
term needs agreement, resolve it through `domain-modeling` rather than silently
introducing a synonym.

Follow the hierarchy in `AGENTS.md`: vision, principles, information
architecture, mechanics, UI, then implementation. An architectural proposal
must identify conflicts with an existing decision or ADR and explain why it is
worth reopening. Preserve the repo's requirement to record mechanic changes in
`spec/decision-log.md` before implementation; an ADR may link to that entry.

Read the current amendments and relevant decisions before treating older
architecture notes as current guidance.
