// Cup Season — D391 · posted-round conversation, notifications and the course page,
// exercised against the FULL migration chain in a disposable local PostgreSQL cluster.
// Never accepts a database URL; there is no production option. Uses the same Supabase
// service stubs as tests/release-chain-database.py.
//
//   node tests/social-course-database.mjs
//
// Covers: unrelated users, accepted friends with no league, a blocked (muted) golfer,
// void rounds, a deleted golfer, a reply parent from the wrong round, duplicate retries
// (sequential and concurrent), notification ownership, preference and thread-mute
// filtering, legacy league-board comments staying league-only, moderation, the dark
// push switch, and a course best that sits OUTSIDE the latest 60 rounds.

import { readFileSync, readdirSync, mkdtempSync, mkdirSync, rmSync } from 'node:fs';
import { spawnSync, spawn } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const bin = process.env.PG_BIN || '/opt/homebrew/opt/postgresql@17/bin';
const mig = join(root, 'supabase', 'migrations');
const temp = mkdtempSync(join(tmpdir(), 'cs-social-pg-'));
const data = join(temp, 'data'), sock = join(temp, 's'); mkdirSync(sock);
const PORT = '55447';

const run = (cmd, args, input) => spawnSync(join(bin, cmd), args, { input, encoding: 'utf8', maxBuffer: 64 << 20 });
function must(p, what) { if (p.status) { console.error(what + '\n' + (p.stderr || p.stdout).slice(-4000)); cleanup(); process.exit(1); } return p; }
function cleanup() { run('pg_ctl', ['-D', data, '-m', 'immediate', '-w', 'stop']); rmSync(temp, { recursive: true, force: true }); }

must(run('initdb', ['-D', data, '-U', 'sim', '-A', 'trust', '-E', 'UTF8', '--no-locale']), 'initdb');
must(run('pg_ctl', ['-D', data, '-l', join(temp, 'log'), '-o',
  `-F -k ${sock} -p ${PORT} -c listen_addresses='' -c shared_preload_libraries=pg_stat_statements -c wal_level=logical -c timezone=UTC`, '-w', 'start']), 'start');

const base = ['-h', sock, '-p', PORT, '-X', '-q', '-v', 'ON_ERROR_STOP=1'];
must(run('psql', [...base, '-U', 'sim', '-d', 'postgres', '-c', 'create database cupseason']), 'createdb');
must(run('psql', [...base, '-U', 'sim', '-d', 'cupseason', '-f', join(root, 'tests/fixtures/release-bootstrap.sql')]), 'bootstrap');
const chain = [...base, '-U', 'postgres', '-d', 'cupseason', '--single-transaction'];
for (const f of readdirSync(mig).filter(n => n.endsWith('.sql')).sort()) {
  const text = readFileSync(join(mig, f), 'utf8').replace(
    /^\s*create extension if not exists (?:"supabase_vault"|pg_cron|pg_net).*?;[^\n]*$/gim, '-- local stub');
  must(run('psql', chain, text), 'migration ' + f);
}
must(run('psql', chain, readFileSync(join(root, 'tests/fixtures/release-post-bootstrap.sql'), 'utf8')), 'post-bootstrap');

const PSQL = [...base, '-U', 'postgres', '-d', 'cupseason', '-At'];
function sql(text) { return must(run('psql', PSQL, text), text.slice(0, 300)).stdout.trim(); }
function as(user, text, { expectError } = {}) {
  const pre = user === 'anon' ? `set role anon;` :
    `set sim.uid='${U[user]}'; set role authenticated;`;
  const p = run('psql', PSQL, pre + text);
  if (expectError !== undefined) {
    if (!p.status) throw new Error(`expected an error from ${user}: ${text.slice(0, 200)}\n got ${p.stdout}`);
    if (expectError && !p.stderr.includes(expectError)) throw new Error(`wrong error for ${user}: ${p.stderr}`);
    return p.stderr;
  }
  if (p.status) throw new Error(`${user}: ${p.stderr}\n--- ${text.slice(0, 300)}`);
  return p.stdout.trim();
}
const j = (user, call) => JSON.parse(as(user, `select (${call})::text;`));
function asAsync(user, text) {
  return new Promise(resolve => {
    const p = spawn(join(bin, 'psql'), PSQL);
    let out = '', err = '';
    p.stdout.on('data', d => out += d); p.stderr.on('data', d => err += d);
    p.on('close', code => resolve({ code, out: out.trim(), err }));
    p.stdin.end(`set sim.uid='${U[user]}'; set role authenticated;` + text);
  });
}
let passed = 0;
const ok = (cond, msg) => { if (!cond) throw new Error('ASSERT: ' + msg); passed++; console.log('PASS ', msg); };

// fictional fixture golfers (never production data)
const U = {
  a: '00000000-0000-4000-8000-00000000000a',  // owner of the rounds; Pro of Oakfield
  f: '00000000-0000-4000-8000-00000000000f',  // accepted friend of a, in NO league
  l: '00000000-0000-4000-8000-000000000001',  // league mate of a (not a friend)
  u: '00000000-0000-4000-8000-000000000002',  // unrelated (a pending request only)
  b: '00000000-0000-4000-8000-00000000000b',  // accepted friend of a whom a has muted
  d: '00000000-0000-4000-8000-00000000000d',  // friend of a who deletes their account
  z: '00000000-0000-4000-8000-00000000000e',  // the founder (moderation desk)
};
const LG = '10000000-0000-4000-8000-000000000001';
const R = { a1: '20000000-0000-4000-8000-000000000001', void: '20000000-0000-4000-8000-000000000002',
            f1: '20000000-0000-4000-8000-000000000003', u1: '20000000-0000-4000-8000-000000000004',
            b1: '20000000-0000-4000-8000-000000000005', l1: '20000000-0000-4000-8000-000000000006' };
const C = 'C-9001';

try {
  // ---- the fixture world ----------------------------------------------------
  sql(`insert into auth.users(id, email) values ${Object.entries(U).map(([k, id]) => `('${id}','${k}@example.test')`).join(',')};
    update profiles set display_name = upper(left(split_part(email,'@',1),1)) || ' Fixture', marker = 'saguaro',
                        handle = split_part(email,'@',1) || '_fx';
    update profiles set is_founder = true where id = '${U.z}';
    insert into leagues(id, name, code, commissioner_id) values ('${LG}','Oakfield','OAKF01','${U.a}');
    insert into league_members(league_id, profile_id, role)
      select '${LG}', x, r from (values ('${U.a}'::uuid,'commissioner'),('${U.l}'::uuid,'player')) v(x,r)
      on conflict (league_id, profile_id) do nothing;
    insert into friendships(requester, addressee, status) values
      ('${U.a}','${U.f}','accepted'),('${U.b}','${U.a}','accepted'),('${U.d}','${U.a}','accepted'),
      ('${U.u}','${U.a}','pending');
    insert into mutes(muter, muted) values ('${U.a}','${U.b}');
    insert into api_courses(id, club_name, course_name, city, state, country)
      values ('${C}','Fixture Oaks','Fixture Oaks','Testville','CA','USA');
    insert into api_course_tees(course_id, gender, tee_name, course_rating, slope_rating, number_of_holes) values
      ('${C}','male','White',70.1,124,18),('${C}','male','Blue',72.3,131,18),('${C}','female','Red',70.1,124,18);
    insert into rounds(id, profile_id, gross, rating, slope, holes_played, course_label, api_course_id, played_on, index_at_post, voided) values
      ('${R.a1}','${U.a}',84,70.1,124,18,'Fixture Oaks · White','${C}',current_date-5,12.0,false),
      ('${R.void}','${U.a}',50,70.1,124,18,'Fixture Oaks · White','${C}',current_date-4,12.0,true),
      ('${R.f1}','${U.f}',70,70.1,124,18,'Fixture Oaks · White','${C}',current_date-300,9.0,false),
      ('${R.u1}','${U.u}',60,70.1,124,18,'Fixture Oaks · White','${C}',current_date-6,4.0,false),
      ('${R.b1}','${U.b}',61,70.1,124,18,'Fixture Oaks · White','${C}',current_date-6,4.0,false),
      ('${R.l1}','${U.l}',68,72.3,131,18,'Fixture Oaks · Blue','${C}',current_date-7,6.0,false);`);

  // ---- 1 · who may read a posted round's conversation ------------------------
  ok(j('f', `posted_round_thread('${R.a1}')`).ok === true, 'accepted friend with no league reads the thread');
  ok(j('l', `posted_round_thread('${R.a1}')`).ok === true, 'league mate reads the thread');
  ok(j('u', `posted_round_thread('${R.a1}')`).reason === 'not_visible', 'unrelated golfer: not_visible');
  ok(j('b', `posted_round_thread('${R.a1}')`).reason === 'not_visible', 'muted golfer: not_visible (mute cuts both ways)');
  ok(j('f', `posted_round_thread('${R.void}')`).reason === 'not_visible', 'void round: not_visible');
  ok(j('f', `posted_round_thread('20000000-0000-4000-8000-0000000000ff')`).reason === 'not_visible', 'unknown round answers exactly like an invisible one');
  as('anon', `select posted_round_thread('${R.a1}');`, { expectError: 'permission denied' }); ok(true, 'anon cannot execute the thread read');
  const th0 = j('f', `posted_round_thread('${R.a1}')`);
  ok(th0.round.course.tee_name === 'White' && th0.round.course.tee_key === 'white@70.1/124', 'thread round carries its proven tee');

  // ---- 2 · commenting, idempotency, notifications ----------------------------
  const k1 = '30000000-0000-4000-8000-000000000001';
  const c1 = j('f', `add_posted_round_comment('${R.a1}', '  Same ball? <b>witness</b>  ', null, '${k1}')`);
  ok(c1.ok && !c1.replayed && c1.comment.body === 'Same ball? <b>witness</b>' && c1.comment.author.id === U.f, 'friend comments; body trimmed and stored verbatim (clients escape)');
  const c1r = j('f', `add_posted_round_comment('${R.a1}', 'Same ball? <b>witness</b>', null, '${k1}')`);
  ok(c1r.replayed === true && c1r.comment.id === c1.comment.id, 'a retry with the same client id replays the same comment');
  as('f', `select add_posted_round_comment('${R.a1}', 'different', null, '${k1}');`, { expectError: 'already sent differently' });
  ok(true, 'the same client id with a different body is refused');
  const k2 = '30000000-0000-4000-8000-000000000002';
  const race = await Promise.all([1, 2, 3].map(() => asAsync('f', `select (add_posted_round_comment('${R.a1}', 'Race', null, '${k2}'))::text;`)));
  ok(race.every(r => r.code === 0) && new Set(race.map(r => JSON.parse(r.out).comment.id)).size === 1, 'three concurrent retries make ONE comment');
  ok(sql(`select count(*) from post_comments where client_id = '${k2}'`) === '1', 'exactly one row for the raced client id');
  ok(sql(`select count(*) from social_notifications where recipient = '${U.a}'`) === '2', 'owner notified once per comment (no duplicate from retries)');
  ok(sql(`select count(*) from social_notifications where recipient = '${U.f}'`) === '0', 'no self-notification');

  as('u', `select add_posted_round_comment('${R.a1}', 'hi');`, { expectError: 'rounds you can see' }); ok(true, 'unrelated golfer cannot comment');
  as('b', `select add_posted_round_comment('${R.a1}', 'hi');`, { expectError: 'rounds you can see' }); ok(true, 'muted golfer cannot comment');
  as('f', `select add_posted_round_comment('${R.a1}', '   ');`, { expectError: 'Say something first' }); ok(true, 'empty body refused');
  as('f', `select add_posted_round_comment('${R.a1}', repeat('x', 501));`, { expectError: 'under 500' }); ok(true, 'over-long body refused');
  as('f', `select add_posted_round_comment('${R.void}', 'hi');`, { expectError: 'rounds you can see' }); ok(true, 'void round refuses comments');

  // replies and the wrong-round parent
  const rep = j('l', `add_posted_round_comment('${R.a1}', 'Caught the left edge.', '${c1.comment.id}')`);
  ok(rep.comment.parent_id === c1.comment.id && rep.comment.root_id === c1.comment.id && rep.comment.reply_to.id === c1.comment.id, 'a reply names its parent and root');
  ok(sql(`select kind from social_notifications where recipient = '${U.f}' and comment_id = '${rep.comment.id}'`) === 'reply', 'the parent author gets a reply notification');
  ok(sql(`select kind from social_notifications where recipient = '${U.a}' and comment_id = '${rep.comment.id}'`) === 'own_round', 'the owner gets own_round');
  const rep2 = j('a', `add_posted_round_comment('${R.a1}', 'Nested', '${rep.comment.id}')`);
  ok(rep2.comment.root_id === c1.comment.id && rep2.comment.parent_id === rep.comment.id, 'a reply to a reply stays under the root');
  ok(sql(`select count(*) from social_notifications where comment_id = '${rep2.comment.id}' and recipient = '${U.a}'`) === '0', 'owner commenting on their own round: no self-notification');
  const onF = j('f', `add_posted_round_comment('${R.f1}', 'My own round note')`);
  as('f', `select add_posted_round_comment('${R.f1}', 'wrong parent', '${c1.comment.id}');`, { expectError: 'lost its comment' });
  ok(onF.ok, 'a reply parent from a DIFFERENT round is refused');

  // follow, thread mute, preferences
  ok(j('f', `set_round_thread_state('${R.a1}', 'following')`).state === 'following', 'follow a thread');
  as('u', `select set_round_thread_state('${R.a1}', 'following');`, { expectError: 'rounds you can see' }); ok(true, 'cannot follow an invisible round');
  const t3 = j('l', `add_posted_round_comment('${R.a1}', 'Saturday again?')`);
  ok(sql(`select kind from social_notifications where recipient = '${U.f}' and comment_id = '${t3.comment.id}'`) === 'followed', 'follower gets followed');
  j('f', `set_round_thread_state('${R.a1}', 'muted')`);
  j('a', `set_social_notify_prefs(p_own_round => false)`);
  ok(j('a', `social_notify_prefs()`).own_round === false && j('a', `social_notify_prefs()`).replies === true, 'prefs persist and default the rest');
  const t4 = j('l', `add_posted_round_comment('${R.a1}', 'Quiet one')`);
  ok(sql(`select count(*) from social_notifications where comment_id = '${t4.comment.id}'`) === '0', 'muted thread + own_round off: nobody notified');
  j('a', `set_social_notify_prefs(p_own_round => true)`);
  j('f', `set_round_thread_state('${R.a1}', 'none')`);

  // ---- 3 · legacy league-board comments stay league-only ----------------------
  sql(`insert into posts(id, league_id, kind, member_id, round_id, body) values
        ('40000000-0000-4000-8000-000000000001','${LG}','round',
         (select id from league_members where league_id='${LG}' and profile_id='${U.a}'),'${R.a1}','A posted 84');
       insert into post_comments(id, post_id, member_id, body) values
        ('40000000-0000-4000-8000-000000000002','40000000-0000-4000-8000-000000000001',
         (select id from league_members where league_id='${LG}' and profile_id='${U.l}'),'League-only chatter');`);
  const lThread = j('l', `posted_round_thread('${R.a1}')`);
  const legacy = lThread.comments.find(c => c.origin === 'board');
  ok(legacy && legacy.body === 'League-only chatter' && legacy.can_reply === false, 'league mate sees the legacy board comment, not repliable');
  ok(!j('f', `posted_round_thread('${R.a1}')`).comments.some(c => c.origin === 'board'), 'friend outside the league never sees it');
  as('l', `select add_posted_round_comment('${R.a1}', 'reply', '40000000-0000-4000-8000-000000000002');`, { expectError: 'lost its comment' });
  ok(true, 'a legacy board comment cannot be a reply parent');
  ok(as('f', `select count(*) from post_comments where round_id is not null;`) === '0', 'round-thread rows are invisible to direct selects');
  as('f', `insert into post_comments(round_id, profile_id, body) values ('${R.a1}','${U.f}','sneak');`, { expectError: '' });
  ok(true, 'a direct insert of a round row is refused (RLS)');

  // ---- 4 · the inbox ----------------------------------------------------------
  const inbox = j('a', `my_notifications()`);
  ok(inbox.ok && inbox.unread === inbox.items.filter(i => !i.read).length && inbox.unread >= 3, 'owner inbox counts only live unread');
  const top = inbox.items[0];
  ok(top.link.kind === 'round_comment' && top.link.web === `/?round=${top.round_id}&comment=${top.comment_id}` && top.actor.name, 'a notification carries the exact comment link and actor');
  ok(j('f', `my_notifications()`).items.every(i => true) && !j('f', `my_notifications()`).items.some(i => inbox.items.some(x => x.id === i.id)), 'a golfer never reads another golfer’s notifications');
  const before = j('a', `notification_badge()`).unread;
  j('f', `mark_notifications_read(array['${top.id}']::uuid[])`);
  ok(j('a', `notification_badge()`).unread === before, 'marking someone else’s notification does nothing');
  ok(j('a', `mark_notifications_read(array['${top.id}']::uuid[])`).unread === before - 1, 'marking your own reads it');
  as('a', `select * from social_notifications;`, { expectError: 'permission denied' }); ok(true, 'no direct read of notifications');
  const pg1 = j('a', `my_notifications(null, 1)`);
  ok(pg1.items.length === 1 && pg1.next_before, 'paging returns a cursor');

  // hidden (moderated) and removed comments drop out
  as('l', `select hide_content('comment', '${c1.comment.id}', 'test');`, { expectError: 'founder' }); ok(true, 'a non-Pro cannot hide a round-thread comment');
  as('a', `select hide_content('comment', '${c1.comment.id}', 'Pro takedown');`);
  ok(!j('f', `posted_round_thread('${R.a1}')`).comments.some(c => c.id === c1.comment.id), 'a hidden comment leaves the thread');
  ok(!j('a', `my_notifications()`).items.some(i => i.comment_id === c1.comment.id), 'and leaves the inbox');
  ok(j('l', `posted_round_thread('${R.a1}')`).comments.find(c => c.id === rep.comment.id).reply_to === null, 'a reply to a hidden comment loses its reply_to');
  as('a', `select unhide_content('comment', '${c1.comment.id}');`, { expectError: 'not yours' }); ok(true, 'only the founder restores a round-thread comment');
  as('z', `select unhide_content('comment', '${c1.comment.id}');`);
  ok(j('f', `posted_round_thread('${R.a1}')`).comments.some(c => c.id === c1.comment.id), 'the founder restores it');
  j('l', `remove_posted_round_comment('${t4.comment.id}')`);
  as('f', `select remove_posted_round_comment('${t3.comment.id}');`, { expectError: 'Only your own' }); ok(true, 'cannot remove someone else’s comment');
  ok(!j('f', `posted_round_thread('${R.a1}')`).comments.some(c => c.id === t4.comment.id), 'the author removes their own');

  // reports
  as('u', `select report_content(p_kind => 'comment', p_comment => '${rep.comment.id}', p_reason => 'x');`, { expectError: 'you can see' });
  ok(true, 'an unrelated golfer cannot report a comment they cannot see');
  as('f', `select report_content(p_kind => 'comment', p_comment => '${rep.comment.id}', p_reason => 'rude');`);
  const q = j('z', `moderation_queue()`);
  ok(q.some(x => x.comment_id === rep.comment.id && x.comment_body === 'Caught the left edge.' && x.comment_round_id === R.a1), 'the founder desk reads the reported comment');

  // a deleted golfer's words and notifications go with them
  const dc = j('d', `add_posted_round_comment('${R.a1}', 'From d')`);
  ok(j('a', `my_notifications()`).items.some(i => i.comment_id === dc.comment.id), 'd’s comment notified a');
  sql(`update profiles set deleted_at = now(), display_name = 'Former member' where id = '${U.d}'`);
  ok(!j('a', `posted_round_thread('${R.a1}')`).comments.some(c => c.id === dc.comment.id), 'a deleted golfer’s comment leaves the thread');
  ok(!j('a', `my_notifications()`).items.some(i => i.comment_id === dc.comment.id), 'and their notification leaves the inbox');

  // blocking after the fact: a mutes l → l's comments vanish from a's view, and back
  sql(`insert into mutes(muter, muted) values ('${U.l}','${U.a}')`);
  ok(!j('a', `posted_round_thread('${R.a1}')`).comments.some(c => c.author.id === U.l), 'a golfer who muted you disappears from your thread');
  ok(!j('a', `my_notifications()`).items.some(i => i.actor.id === U.l), 'and from your inbox');
  const quiet = j('f', `add_posted_round_comment('${R.a1}', 'no ring for l', '${rep.comment.id}')`);
  ok(sql(`select count(*) from social_notifications where comment_id = '${quiet.comment.id}' and recipient = '${U.l}'`) === '0', 'no notification crosses a mute (l cannot see a’s round now)');
  sql(`delete from mutes where muter = '${U.l}'`);

  // the dark push switch
  ok(sql(`select count(*) from push_nudges where kind = 'comment'`) === '0', 'push stays dark by default');
  sql(`update app_flags set value = jsonb_set(value, '{enabled}', 'true') where key = 'social_comment_push'`);
  const lit = j('l', `add_posted_round_comment('${R.a1}', 'Lit')`);
  const pn = JSON.parse(sql(`select payload::text from push_nudges where kind='comment' and profile_id='${U.a}'`));
  ok(pn.comment_id === lit.comment.id && pn.round_id === R.a1 && pn.profile_id === U.l && pn.notification_id, 'with the switch on, the push carries round, comment, notification and actor');

  // ---- 5 · the course page ------------------------------------------------------
  // 64 recent rounds for a at White (all worse than the old 70 below), one OLD 70 far
  // outside any 60-row page, a 9-hole 38, an unprovable tee, and an ambiguous label.
  sql(`insert into rounds(profile_id, gross, rating, slope, holes_played, course_label, api_course_id, played_on, index_at_post)
         select '${U.a}', 90 + (g % 9), 70.1, 124, 18, 'Fixture Oaks · White', '${C}', current_date - g, 12.0
           from generate_series(1, 64) g;
       insert into rounds(id, profile_id, gross, rating, slope, holes_played, course_label, api_course_id, played_on, index_at_post) values
         ('20000000-0000-4000-8000-0000000000a0','${U.a}',70,70.1,124,18,'Fixture Oaks · White','${C}',current_date-400,12.0),
         ('20000000-0000-4000-8000-0000000000a1','${U.a}',38,70.1,124,9,'Fixture Oaks · White','${C}',current_date-2,12.0),
         ('20000000-0000-4000-8000-0000000000a2','${U.a}',66,69.0,120,18,'Fixture Oaks · Gold','${C}',current_date-3,12.0),
         ('20000000-0000-4000-8000-0000000000a3','${U.a}',65,70.1,124,18,'Fixture Oaks','${C}',current_date-3,12.0);`);
  const cp = j('a', `course_page('${C}')`);
  ok(cp.ok && cp.scope.best_label === 'Your circle best' && /Not an official course record/.test(cp.scope.note), 'the scope is labelled as the circle, never a record');
  ok(cp.selection.tee_key === 'white@70.1/124' && cp.selection.holes === 18, 'default selection: White, 18 holes');
  ok(cp.best.gross === 70 && cp.best.tied === true && cp.best.holders.length === 2, 'the best (70) sits OUTSIDE the latest 60 and is a shared tie');
  ok(cp.best.holders[0].round_id === '20000000-0000-4000-8000-0000000000a0' && cp.best.holders[1].round_id === R.f1, 'tie holders ordered first-posted first, each with its source round');
  ok(!cp.people.some(p => p.person.id === U.u || p.person.id === U.b), 'unrelated and muted golfers are absent');
  ok(cp.best.eligible_rounds === 67, 'eligible = 64 + old 70 + a1 84 + f 70 (void, nine, unknown and ambiguous excluded)');
  ok(cp.unknown_tee_rounds === 2, 'an unprovable tee and an ambiguous label are counted unknown, never guessed');
  const aRow = cp.people.find(p => p.person.id === U.a);
  ok(aRow.relation === 'me' && aRow.rounds_total === 69 && aRow.rounds.length === 30, 'my history: true total, 30 newest listed');
  ok(aRow.rounds.some(r => r.round_id === '20000000-0000-4000-8000-0000000000a3' && r.tee_key === null && r.tee_name === null), 'ambiguous round shows with no tee');
  ok(cp.my_best.gross === 70 && cp.my_best.rounds === 66, 'my best is the old 70 with the true count');
  ok(cp.people.find(p => p.person.id === U.l).best_in_selection === null, 'a Blue round is not in the White best');
  ok(cp.tees.some(t => t.key === 'blue@72.3/131' && t.rounds === 1), 'Blue is offered as a filter');
  const blue = j('a', `course_page('${C}', 'blue@72.3/131', 18)`);
  ok(blue.best.gross === 68 && blue.best.holders[0].person.id === U.l, 'the Blue filter gives the league mate’s 68');
  const nine = j('a', `course_page('${C}', 'white@70.1/124', 9)`);
  ok(nine.best.gross === 38 && nine.selection.holes === 9, 'nines compare only with nines');
  const bogus = j('a', `course_page('${C}', 'made-up', 7)`);
  ok(bogus.selection.tee_key === 'white@70.1/124' && bogus.selection.holes === 18, 'an invalid selection falls back to the default');
  const fp = j('f', `course_page('${C}')`);
  ok(fp.people.some(p => p.person.id === U.a && p.relation === 'friend') && !fp.people.some(p => p.person.id === U.l), 'a friend with no league sees a (friend) but not a’s league mate');
  ok(j('u', `course_page('${C}')`).people.every(p => p.person.id === U.u), 'an unrelated golfer sees only themself');
  as('anon', `select course_page('${C}');`, { expectError: 'permission denied' }); ok(true, 'anon cannot read a course page');

  // ---- 6 · the feed doors ---------------------------------------------------------
  const soc = j('f', `posted_rounds_social(array['${R.a1}','${R.u1}','${R.void}','20000000-0000-4000-8000-0000000000ff']::uuid[])`);
  ok(soc.items.length === 1 && soc.items[0].round_id === R.a1, 'only visible rounds come back');
  ok(soc.items[0].comment_count === j('f', `posted_round_thread('${R.a1}')`).count, 'the door’s count equals the thread’s');
  ok(soc.items[0].course.api_course_id === C && soc.items[0].course.faces.every(x => x.id !== U.f) && soc.items[0].course.faces.some(x => x.id === U.a), 'the course door names circle faces, never the viewer');

  console.log(`\nALL PASS (${passed})`);
} catch (e) {
  console.error(e.stack || e.message);
  cleanup();
  process.exit(1);
}
cleanup();
