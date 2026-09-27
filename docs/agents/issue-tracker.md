# Issue tracker: GitHub

Engineering tickets and implementation specs produced by Matt Pocock's skills
live in GitHub Issues for `Fischbeck3/cup-season`. Use the `gh` CLI from this
repository, or pass `--repo Fischbeck3/cup-season` when running elsewhere.

## Existing follow-ups and product canon

Read `spec/inbox.md` at session start as required by `CLAUDE.md`. It remains the
capture point for raw notes and findings. Before creating an issue, check the
inbox and existing issues for the same work. When an inbox item becomes a ticket,
link the issue from that item and keep execution status in the issue.

Product rules and durable product specs remain in the canonical files named by
`docs/doc-map.md`. An issue can link to those files; it does not replace them.

## Operations

- Publish to the issue tracker: create a GitHub issue.
- Fetch a ticket: `gh issue view <number> --comments`.
- List work: `gh issue list --state open --json number,title,body,labels`;
  use `--label` to narrow the queue and read each relevant issue's comments.
- Create: `gh issue create --title "..." --body-file <path>`.
- Comment: `gh issue comment <number> --body-file <path>`.
- Edit the description: `gh issue edit <number> --body-file <path>`.
- Apply or remove labels: `gh issue edit <number> --add-label "..."` or
  `gh issue edit <number> --remove-label "..."`.
- Close completed work: `gh issue close <number>`.

Write multiline issue descriptions and comments to a temporary UTF-8 file and
pass it with `--body-file`, preserving actual newlines and literal code.

## Pull requests as a triage surface

**PRs as a request surface: no.**

## Wayfinding

For `/wayfinder`, keep the map in one issue labelled `wayfinder:map`, with child
issues labelled `wayfinder:research`, `wayfinder:prototype`, `wayfinder:grilling`,
or `wayfinder:task`. Use GitHub sub-issues and native dependencies where available;
otherwise link children in the map's task list and put `Part of #<map>` and
`Blocked by: #<number>` references in child descriptions.

Claim the first unassigned child with no open blockers, in map order, using
`gh issue edit <number> --add-assignee @me`. Record the result on the child,
close it when complete, and add the result and link to the map's decisions.
