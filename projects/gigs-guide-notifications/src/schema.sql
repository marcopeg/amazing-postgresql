CREATE EXTENSION postgis;

DROP TABLE IF EXISTS "all_music_events_temp";
CREATE TABLE "public"."all_music_events_temp" (
    "event_id" text NOT NULL,
    "country_code" text NOT NULL,
    CONSTRAINT "all_music_events_temp_pkey" PRIMARY KEY ("event_id")
) WITH (oids = false);



DROP TABLE IF EXISTS "events_performers_temp";
CREATE TABLE "public"."events_performers_temp" (
    "event_id" text NOT NULL,
    "artist_id" text NOT NULL,
    CONSTRAINT "events_performers_temp_event_id_artist_id" PRIMARY KEY ("event_id", "artist_id")
) WITH (oids = false);


DROP TABLE IF EXISTS "users_performers";
CREATE TABLE "public"."users_performers" (
    "user_id" uuid NOT NULL,
    "artist_id" text NOT NULL,
    CONSTRAINT "users_performers_pkey" PRIMARY KEY ("user_id", "artist_id")
) WITH (oids = false);


DROP TABLE IF EXISTS "users_sent_events";
CREATE TABLE "public"."users_sent_events" (
    "user_id" uuid NOT NULL,
    "event_id" text NOT NULL,
    CONSTRAINT "users_sent_events_pkey" PRIMARY KEY ("user_id", "event_id")
) WITH (oids = false);

