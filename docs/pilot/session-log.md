# Session and support log

Every time the founder is in the room, on a call, or answering a message about
a round, it is a session. This is how assisted activity is subtracted from the
scorecard; telemetry cannot infer it.

## The record

One row in `pilot_sessions` per session (founder-only table, `20261106090000`):

| field | what to write |
|---|---|
| `cohort` | owner · friends · independent · competition · founding |
| `group_key` | the league id, the booking id, or the group's name as you call it |
| `kind` | `assisted` — you helped them do it · `observed` — you watched and said nothing · `support` — they asked after the fact |
| `started_at` / `ended_at` | the window the help covered |
| `golfers` | the profile ids of the people you helped |
| `notes` | what they were trying to do, where they stalled, what you said — no scores, no money |

Until the migration is applied, keep the same columns in a private note and
enter them afterwards. Do not put names in this repository.

## Entering a session (founder, signed in)

```sql
insert into pilot_sessions (cohort, group_key, kind, started_at, ended_at, golfers, notes)
values ('friends', '<league or booking id>', 'assisted', now() - interval '40 minutes', now(),
        array['<profile id>']::uuid[], 'first tee-off; stalled at the course picker; showed the search');
```

## Adding someone to a cohort

```sql
insert into pilot_cohort_members (profile_id, cohort, group_key, added_by, note)
values ('<profile id>', 'independent', 'thursday-group', founder_id(), 'came via Galen');
```

## Support requests

A message asking for help IS a `support` session, even if it took one reply.
Log it with the question in `notes`. The weekly review counts them.
