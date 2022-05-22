
CREATE TABLE IF NOT EXISTS "public"."v7_commands" (
  "ref" VARCHAR(50) NOT NULL,
  "payload" JSONB NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now(),
  "cmd_id" BIGSERIAL PRIMARY KEY
);

CREATE OR REPLACE FUNCTION "public"."v7_commands_insert_fn"()
RETURNS trigger AS $$
DECLARE
	VAR_schema VARCHAR;
	VAR_partition VARCHAR;
	VAR_q VARCHAR;
BEGIN
  VAR_schema = concat('v7_commands_', to_char(NEW.created_at, 'IYYY_IW'));
  VAR_partition = to_char(date_trunc('hour', NEW.created_at), 'YYYY_MM_DD_HH24');

  BEGIN
    VAR_q = format(
      'INSERT INTO "%s"."v7_commands_%s" VALUES ($1.*);',
      VAR_schema,
      VAR_partition
    );
    RAISE DEBUG '% - %', VAR_q, NEW.created_at;
    EXECUTE VAR_q USING NEW;

    -- First soft error with re-attempt
    -- the partition table does not exits and must be created automatically
    EXCEPTION WHEN sqlstate '42P01' THEN

      -- Upsert the schema
      BEGIN
        VAR_q = format(
          'CREATE SCHEMA "%s";',
          VAR_schema
        );
        RAISE DEBUG '%', VAR_q;
        EXECUTE VAR_q;
        RAISE INFO 'Created schema "%"', VAR_schema;

        EXCEPTION 
        WHEN sqlstate '42P06' THEN
          -- RAISE NOTICE 'Schema "%" already exists', VAR_schema;
        WHEN others THEN
          RAISE EXCEPTION 'Failed to create schema "%": %; SQLSTATE: %', VAR_schema, SQLERRM, SQLSTATE;
      END;
        
      -- Upsert the table partition
      BEGIN
        VAR_q = format(
          'CREATE TABLE "%s"."v7_commands_%s" () INHERITS ("public"."v7_commands");',
          VAR_schema,
          VAR_partition
        );
        RAISE DEBUG '%', VAR_q;
        EXECUTE VAR_q;
        RAISE DEBUG 'Created partition table "%"."v7_commands_%"', VAR_schema, VAR_partition;


        -- Add the time constraint
        BEGIN
          VAR_q = '';
          VAR_q = VAR_q || 'ALTER TABLE "%s"."v7_commands_%s" ';
          VAR_q = VAR_q || 'ADD CONSTRAINT "v7_commands_%s_created_at" ';
          VAR_q = VAR_q || 'CHECK ("created_at" >= ''%s'' AND "created_at" < ''%s'');';

          VAR_q = format(VAR_q,
            VAR_schema,
            VAR_partition,
            VAR_partition,
            date_trunc('hour', NEW.created_at),
            date_trunc('hour', NEW.created_at + INTERVAL '1h')
          );

          RAISE DEBUG '%', VAR_q;
          EXECUTE VAR_q;
          RAISE DEBUG 'Created constraint "v7_commands_%s_created_at" on "%"."v7_commands_%"', VAR_partition, VAR_schema, VAR_partition;

          EXCEPTION 
          WHEN sqlstate '42710' THEN
            RAISE NOTICE 'Constraint "v7_commands_%s_created_at" on "%"."v7_commands_%" already exists', VAR_partition, VAR_schema, VAR_partition;
          WHEN others THEN
            RAISE EXCEPTION 'Failed to create constraint "v7_commands_%s_created_at" on "%"."v7_commands_%": %; SQLSTATE: %', VAR_partition, VAR_schema, VAR_partition, SQLERRM, SQLSTATE;
        END;

        EXCEPTION 
        WHEN sqlstate '42P07' THEN
          RAISE NOTICE 'Partition table "%"."v7_commands_%" already exists', VAR_schema, VAR_partition;
        WHEN others THEN
          RAISE EXCEPTION 'Failed to create partition table "%"."v7_commands_%": %; SQLSTATE: %', VAR_schema, VAR_partition, SQLERRM, SQLSTATE;
      END;

      -- Insert into custom partition // final attempt
      BEGIN
        EXECUTE format(
          'INSERT INTO "%s"."v7_commands_%s" VALUES ($1.*);',
          VAR_schema,
          VAR_partition
        ) USING NEW;

        -- Final exception when failing the insert
        EXCEPTION WHEN others THEN
          RAISE EXCEPTION 'Could not insert into table partition: %; SQLSTATE: %', SQLERRM, SQLSTATE;
      END;
  END;

  RETURN NULL;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER "v7_commands_insert_trigger" 
BEFORE INSERT 
ON "public"."v7_commands" 
FOR EACH ROW EXECUTE PROCEDURE "public"."v7_commands_insert_fn"();

CREATE TABLE IF NOT EXISTS "public"."stats" (
  "query" TEXT NOT NULL,
  "duration_ms" INTEGER NOT NULL,
  "payload" JSONB NOT NULL DEFAULT '{}',
  "run" BIGSERIAL PRIMARY KEY
);