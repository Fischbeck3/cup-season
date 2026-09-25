-- Operator-only deployment step. Not a migration; never run by preflight.
-- Prerequisites: deployed share-cleanup Edge Function, pg_cron + pg_net,
-- and two Supabase Vault secrets created privately in the target project:
--   share_cleanup_url: full https://<project>/functions/v1/share-cleanup URL
--   share_cleanup_secret: same value as Edge SHARE_CLEANUP_SECRET
-- No secret value is printed or embedded in cron.job.command.
do $$
begin
  if not exists (select 1 from vault.decrypted_secrets
                  where name='share_cleanup_url' and decrypted_secret like 'https://%/functions/v1/share-cleanup')
     or not exists (select 1 from vault.decrypted_secrets
                     where name='share_cleanup_secret' and length(decrypted_secret)>0) then
    raise exception 'Configure share_cleanup_url and share_cleanup_secret in Vault first';
  end if;
end $$;

-- A webhook alone cannot wake up when a lease expires or a retry becomes due.
-- Named scheduling updates the same job when this file is run again.
select cron.schedule('cs-share-cleanup', '* * * * *', $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name='share_cleanup_url'),
    headers := jsonb_build_object('Content-Type','application/json','x-cleanup-secret',
      (select decrypted_secret from vault.decrypted_secrets where name='share_cleanup_secret')),
    body := '{}'::jsonb,
    timeout_milliseconds := 10000
  );
$job$);

select jobname, schedule, active from cron.job where jobname='cs-share-cleanup';
