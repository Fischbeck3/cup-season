-- Isolated PostgreSQL fixture only. Used by after-golf-postgres.py, never production.
create role authenticated; create role anon;
create schema auth;
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid
$$;
grant usage on schema auth to authenticated, anon;
create table profiles(id uuid primary key,display_name text);
create table friendships(requester uuid,addressee uuid,status text,created_at timestamptz);
create table scheduled_rounds(id uuid primary key,profile_id uuid,play_on date,course_label text,course_id text,tee_time time,created_at timestamptz default now(),tagged uuid[]);
create table round_rsvp(round_id uuid,profile_id uuid,status text);
create table rounds(profile_id uuid,played_on date,voided boolean,api_course_id text);
create function firstname(text) returns text language sql as $$select split_part($1,' ',1)$$;
create function my_schedule(p_from date,p_to date)
returns table(id uuid,play_on date,course_label text,tee_time time,mine boolean,tagged_me boolean,my_rsvp text,rsvp_in integer,display_name text)
language sql stable security definer set search_path=public as $$
 select s.id,s.play_on,s.course_label,s.tee_time,s.profile_id=auth.uid(),auth.uid()=any(s.tagged),
   (select r.status from round_rsvp r where r.round_id=s.id and r.profile_id=auth.uid()),
   (select count(*)::int from round_rsvp r where r.round_id=s.id and r.status='in'),p.display_name
 from scheduled_rounds s join profiles p on p.id=s.profile_id
 where s.play_on between p_from and p_to
$$;
create function native_home() returns jsonb language sql stable security definer set search_path=public as $$
 select jsonb_build_object('profile',jsonb_build_object('rounds_count',1),'memberships','[]'::jsonb,
 'upcoming_rounds',(select coalesce(jsonb_agg(to_jsonb(s)),'[]'::jsonb) from my_schedule(current_date,current_date+14) s))
$$;
insert into profiles values ('a0000000-0000-4000-8000-000000000001','Host'),('a0000000-0000-4000-8000-000000000002','Guest'),('a0000000-0000-4000-8000-000000000003','Outside');
