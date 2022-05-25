DROP TABLE IF EXISTS "queue_v6" CASCADE;

CREATE TABLE IF NOT EXISTS "public"."queue_v6" (
  "payload" JSONB,
  "partition" SMALLINT,
  "next_iteration" TIMESTAMP NOT NULL DEFAULT now(),
  "task_id" BIGSERIAL PRIMARY KEY
);

CREATE INDEX "queue_v6_pick_idx"
ON "queue_v6" ( "next_iteration" ASC );

CREATE OR REPLACE FUNCTION "queue_v6_insert_fn"()
RETURNS trigger AS $$
DECLARE
	VAR_q VARCHAR;
BEGIN

  BEGIN
    VAR_q = format(
      'INSERT INTO "queue_v6_%s" VALUES ($1.*);',
      NEW."partition"
    );
    RAISE DEBUG '% - %', VAR_q, NEW.partition;
    EXECUTE VAR_q USING NEW;

    -- First soft error with re-attempt
    -- the partition table does not exits and must be created automatically
    EXCEPTION WHEN sqlstate '42P01' THEN
        
      -- Upsert the table partition
      BEGIN
        VAR_q = format(
          'CREATE TABLE "queue_v6_%s" () INHERITS ("public"."queue_v6") WITH (fillfactor = 100);',
          NEW."partition"
        );
        RAISE DEBUG '%', VAR_q;
        EXECUTE VAR_q;
        RAISE DEBUG 'Created partition table "queue_v6_%"', NEW."partition";

        -- Add the read index
        BEGIN
          VAR_q = '';
          VAR_q = VAR_q || 'CREATE INDEX "queue_v6_pick_idx_%s" ';
          VAR_q = VAR_q || 'ON "queue_v6_%s" ( "next_iteration" DESC ); ';

          VAR_q = format(VAR_q,
            NEW."partition",
            NEW."partition"
          );

          RAISE DEBUG '%', VAR_q;
          EXECUTE VAR_q;
          RAISE DEBUG 'Created index "queue_v6_read_idx_%" on"queue_v6_%"', NEW."partition", NEW."partition";
        EXCEPTION 
          WHEN sqlstate '42P07' THEN
            RAISE NOTICE 'Index "queue_v6_read_idx_%" on"queue_v6_%"', NEW."partition", NEW."partition";
          WHEN others THEN
            RAISE EXCEPTION 'Failed to create index ""queue_v6_read_idx_%"" on"queue_v6_%: %; SQLSTATE: %', NEW."partition", NEW."partition", SQLERRM, SQLSTATE;
        END;


        -- Add the partition constraint
        BEGIN
          VAR_q = '';
          VAR_q = VAR_q || 'ALTER TABLE "queue_v6_%s" ';
          VAR_q = VAR_q || 'ADD CONSTRAINT "queue_v6_%s_partition" ';
          VAR_q = VAR_q || 'CHECK ("partition" = %s);';

          VAR_q = format(VAR_q,
            NEW."partition",
            NEW."partition",
            NEW."partition"
          );

          RAISE DEBUG '%', VAR_q;
          EXECUTE VAR_q;
          RAISE DEBUG 'Created constraint "queue_v6_%s_partition" on "queue_v6_%"', NEW."partition", NEW."partition";

        EXCEPTION 
          WHEN sqlstate '42710' THEN
            RAISE NOTICE 'Constraint "queue_v6_%s_partition" on "queue_v6_%" already exists', NEW."partition", NEW."partition";
          WHEN others THEN
            RAISE EXCEPTION 'Failed to create constraint "queue_v6_%_partition" on "queue_v6_%": %; SQLSTATE: %', NEW."partition", NEW."partition", SQLERRM, SQLSTATE;
        END;

      EXCEPTION 
        WHEN sqlstate '42P07' THEN
          RAISE NOTICE 'Partition table "queue_v6_%" already exists', NEW."partition";
        WHEN others THEN
          RAISE EXCEPTION 'Failed to create partition table "queue_v6_%": %; SQLSTATE: %', NEW."partition", SQLERRM, SQLSTATE;
      END;

      -- Insert into custom partition // final attempt
      BEGIN
        EXECUTE format(
          'INSERT INTO "queue_v6_%s" VALUES ($1.*);',
          NEW."partition"
        ) USING NEW;

      -- Final exception when failing the insert
      EXCEPTION WHEN others THEN
        RAISE EXCEPTION 'Could not insert into table partition: %; SQLSTATE: %', SQLERRM, SQLSTATE;
      END;
  END;

  RETURN NULL;
END; $$
LANGUAGE plpgsql;


CREATE TRIGGER "queue_v6_insert_trigger" 
BEFORE INSERT 
ON "public"."queue_v6" 
FOR EACH ROW EXECUTE PROCEDURE "public"."queue_v6_insert_fn"();