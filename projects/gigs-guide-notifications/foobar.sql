

-- with
--   "artists_followed_by_users" as (
--     select distinct artist_id
--     from users_performers 
--     group by artist_id
--     -- limit 2
--   )
-- , "events_followed_by_users" as (
--     select e.event_id, a.artist_id
--     from "artists_followed_by_users" as a
--     join "events_performers_temp" as e on a.artist_id = e.artist_id
--     order by a.artist_id
--   )
-- , "events_filtered_by_country_code" as (
--     select
--       t1.artist_id,
--       t2.event_id,
--       t2.country_code
--     from "events_followed_by_users" as t1
--     join "all_music_events_temp" as t2 on t1.event_id = t2.event_id
--     where t2.country_code = 'XX'
-- )
-- select * from events_filtered_by_country_code;


-- with
--   events_followed_by_users as (
--     select
--       t1.user_id,
--       t1.artist_id,
--       t2.event_id
--     from users_performers as t1
--     join events_performers_temp as t2 on t1.artist_id = t2.artist_id
--     order by t1.user_id, t1.artist_id
--   )
-- ,  events_by_country_code as (
--     select 
--       t1.*, 
--       t2.country_code 
--     from events_followed_by_users as t1
--     join all_music_events_temp as t2 on t1.event_id = t2.event_id
--     where t2.country_code = 'XX'
--   )
-- , users_events_notifications as (
--     select
--       t1.user_id,
--       t1.event_id,
--       t1.country_code
--     from events_by_country_code as t1
--     where not exists (
--       select 
--       from users_sent_events
--       where event_id = t1.event_id and user_id = t1.user_id
--   )
-- )
-- select 
--   user_id::text, 
--   json_agg(event_id) as event_ids
-- from users_events_notifications
-- group by user_id;



select * from notify_live_stream();


