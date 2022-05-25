DROP TABLE IF EXISTS "queue_v5" CASCADE;

CREATE TABLE "queue_v5" (
  "payload" JSONB,
  "partition" SMALLINT,
  "next_iteration" TIMESTAMP NOT NULL DEFAULT now(),
  "task_id" BIGSERIAL PRIMARY KEY
);

CREATE INDEX "queue_v5_pick_idx"
ON "queue_v5" ( "next_iteration" ASC );

CREATE TABLE "queue_v5_1" () INHERITS ("queue_v5") WITH (fillfactor = 100);
ALTER TABLE "queue_v5_1" ADD CONSTRAINT "queue_v5_1_partition" CHECK ("partition" = 1);
CREATE INDEX "queue_v5_pick_idx_1" ON "queue_v5_1" ( "next_iteration" ASC ); 

CREATE TABLE "queue_v5_2" () INHERITS ("queue_v5") WITH (fillfactor = 100);
ALTER TABLE "queue_v5_2" ADD CONSTRAINT "queue_v5_2_partition" CHECK ("partition" = 2);
CREATE INDEX "queue_v5_pick_idx_2" ON "queue_v5_2" ( "next_iteration" ASC ); 

CREATE TABLE "queue_v5_3" () INHERITS ("queue_v5") WITH (fillfactor = 100);
ALTER TABLE "queue_v5_3" ADD CONSTRAINT "queue_v5_3_partition" CHECK ("partition" = 3);
CREATE INDEX "queue_v5_pick_idx_3" ON "queue_v5_3" ( "next_iteration" ASC ); 

CREATE TABLE "queue_v5_4" () INHERITS ("queue_v5") WITH (fillfactor = 100);
ALTER TABLE "queue_v5_4" ADD CONSTRAINT "queue_v5_4_partition" CHECK ("partition" = 4);
CREATE INDEX "queue_v5_pick_idx_4" ON "queue_v5_4" ( "next_iteration" ASC ); 

CREATE TABLE "queue_v5_5" () INHERITS ("queue_v5") WITH (fillfactor = 100);
ALTER TABLE "queue_v5_5" ADD CONSTRAINT "queue_v5_5_partition" CHECK ("partition" = 5);
CREATE INDEX "queue_v5_pick_idx_5" ON "queue_v5_5" ( "next_iteration" ASC ); 

CREATE TABLE "queue_v5_6" () INHERITS ("queue_v5") WITH (fillfactor = 100);
ALTER TABLE "queue_v5_6" ADD CONSTRAINT "queue_v5_6_partition" CHECK ("partition" = 6);
CREATE INDEX "queue_v5_pick_idx_6" ON "queue_v5_6" ( "next_iteration" ASC ); 

CREATE TABLE "queue_v5_7" () INHERITS ("queue_v5") WITH (fillfactor = 100);
ALTER TABLE "queue_v5_7" ADD CONSTRAINT "queue_v5_7_partition" CHECK ("partition" = 7);
CREATE INDEX "queue_v5_pick_idx_7" ON "queue_v5_7" ( "next_iteration" ASC ); 

CREATE TABLE "queue_v5_8" () INHERITS ("queue_v5") WITH (fillfactor = 100);
ALTER TABLE "queue_v5_8" ADD CONSTRAINT "queue_v5_8_partition" CHECK ("partition" = 8);
CREATE INDEX "queue_v5_pick_idx_8" ON "queue_v5_8" ( "next_iteration" ASC ); 

CREATE TABLE "queue_v5_9" () INHERITS ("queue_v5") WITH (fillfactor = 100);
ALTER TABLE "queue_v5_9" ADD CONSTRAINT "queue_v5_9_partition" CHECK ("partition" = 9);
CREATE INDEX "queue_v5_pick_idx_9" ON "queue_v5_9" ( "next_iteration" ASC ); 

CREATE TABLE "queue_v5_10" () INHERITS ("queue_v5") WITH (fillfactor = 100);
ALTER TABLE "queue_v5_10" ADD CONSTRAINT "queue_v5_10_partition" CHECK ("partition" = 10);
CREATE INDEX "queue_v5_pick_idx_19" ON "queue_v5_10" ( "next_iteration" ASC ); 

CREATE OR REPLACE FUNCTION "queue_v5_insert_fn"()
RETURNS trigger AS $$
DECLARE
	VAR_q VARCHAR;
BEGIN
  EXECUTE format(
    'INSERT INTO "queue_v5_%s" VALUES ($1.*);',
    NEW."partition"
  ) USING NEW;

  RETURN NULL;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER "queue_v5_insert_trigger" 
BEFORE INSERT 
ON "public"."queue_v5" 
FOR EACH ROW EXECUTE PROCEDURE "public"."queue_v5_insert_fn"();

INSERT INTO "queue_v5" ("payload", "partition", "next_iteration")
SELECT
  json_build_object('name', CONCAT('Task', "t")),
  floor(random()* (10 - 1 + 1) + 1),
  CASE
  	WHEN random() > 0.5 THEN now() - '10m'::INTERVAL * random()
  	ELSE now() + '10s'::INTERVAL * random()
  END
FROM generate_series(1, 100) AS "t";