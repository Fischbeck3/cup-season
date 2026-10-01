# Reviewed production deployment — pending owner confirmation

Run from /private/tmp/cup-season-compete-identity-plan after the release branch is reviewed.
The preview must list only 20261219090000_a_league_has_its_own_identity.sql.

```sh
supabase db push --dry-run
supabase db push
supabase functions deploy share-cleanup --no-verify-jwt
```

Verify database migration history/readback, then the existing cleanup worker deployment separately. Do not claim the native upload activates shared customization without the database. Existing secrets/schedule are unchanged.
