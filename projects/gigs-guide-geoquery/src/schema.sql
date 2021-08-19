CREATE EXTENSION IF NOT EXISTS "postgis";

--
-- GigsGuide
-- original data structure
--

DROP TABLE IF EXISTS "cities";
CREATE TABLE "public"."cities" (
    "wandercity_id" character varying DEFAULT '100' NOT NULL,
    "location" geography NOT NULL,
    "city_data" jsonb NOT NULL,
    "name" text NOT NULL,
    "country_code" text NOT NULL,
    "state_abbr" text,
    "state" text,
    "country" text,
    "timezone" jsonb,
    "population" integer,
    "city_banner" jsonb,
    "wikivoyage" jsonb,
    "wikipedia" jsonb,
    "wikidata_id" text,
    "geonames_id" text,
    "wikidata" jsonb,
    "guide_book" jsonb,
    CONSTRAINT "cities_pkey" PRIMARY KEY ("wandercity_id")
) WITH (oids = false);

CREATE INDEX "cities_geonames_id" ON "public"."cities" USING btree ("geonames_id");


DROP TABLE IF EXISTS "all_music_events_temp";
CREATE TABLE "public"."all_music_events_temp" (
    "event_id" text NOT NULL,
    "start_date_utc" timestamptz NOT NULL,
    "start_date_local" text NOT NULL,
    "start_time_local" time without time zone NOT NULL,
    "location" geography NOT NULL,
    "wandercity_id" text NOT NULL,
    "venue_id" text NOT NULL,
    "event_status" text NOT NULL,
    "currency" text,
    "min_price" numeric,
    "max_price" numeric,
    "source_label" text NOT NULL,
    "ticket_url" text NOT NULL,
    "venue" jsonb NOT NULL,
    "performer_ids" text[] NOT NULL,
    "event_data" jsonb NOT NULL,
    "city" text NOT NULL,
    "country" text NOT NULL,
    "country_code" text NOT NULL,
    "state_ansi" text,
    "title" text,
    "hero_image" text,
    "event_description" text,
    "ticket_ids" jsonb NOT NULL,
    CONSTRAINT "all_music_events_temp_pkey" PRIMARY KEY ("event_id")
) WITH (oids = false);

CREATE INDEX "notify_live_stream__all_music_events_temp__idx" ON "public"."all_music_events_temp" USING btree ("event_id");



--
-- SUPPORT TABLES
--

CREATE TABLE IF NOT EXISTS "cached_distances" (
  "city_id" TEXT
, "event_id" TEXT
, "city" TEXT
, "distance" INTEGER
, PRIMARY KEY ("city_id", "event_id")
);

CREATE INDEX "cached_distances_idx_distance"
ON "cached_distances" USING btree ("distance" ASC);

CREATE TABLE IF NOT EXISTS "cached_queries" (
 "city" TEXT PRIMARY KEY
);
