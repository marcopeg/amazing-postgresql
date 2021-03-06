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

DROP TABLE IF EXISTS "notify_live_stream_return";
CREATE TABLE "public"."notify_live_stream_return" (
    "user_id" TEXT,
    "event_ids" TEXT[]
);

CREATE INDEX IF NOT EXISTS "notify_live_stream__all_music_events_temp__idx" 
ON "all_music_events_temp" ("event_id" ASC)
WHERE ("country_code" = 'XX');

DROP TABLE IF EXISTS "notify_live_stream_queue";
CREATE TABLE "public"."notify_live_stream_queue" (
    "user_id" TEXT PRIMARY KEY,
    "event_ids" TEXT[],
    "lock_until" TIMESTAMP WITH TIME ZONE DEFAULT now()
);