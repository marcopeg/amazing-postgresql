
CREATE TABLE IF NOT EXISTS "public"."v8_commands" (
  "ref" VARCHAR(50) NOT NULL,
  "payload" JSONB NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now(),
  "cmd_id" BIGSERIAL PRIMARY KEY
);

CREATE TABLE IF NOT EXISTS "public"."v8_responses" (
  "cmd_id" BIGINT NOT NULL,
  "ref" VARCHAR(50) NOT NULL,
  "payload" JSONB DEFAULT null,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now()
) WITH (fillfactor = 100);

-- Speed up the "query by time" scenario
CREATE INDEX "v8_commands_read_idx"
ON "v8_commands" ( "ref", "created_at" DESC );

CREATE INDEX "v8_responses_read_idx"
ON "v8_responses" ( "ref", "created_at" DESC );

-- Speed up the "query by tenant" scenario
-- CREATE INDEX "v8_commands_read_by_tenant_idx"
-- ON "v8_commands" ( "ref", "created_at" DESC );

-- CREATE INDEX "v8_responses_read_by_tenant_idx"
-- ON "v8_responses" ( "ref", "created_at" DESC );

CREATE OR REPLACE FUNCTION "public"."v8_commands_insert_fn"()
RETURNS trigger AS $$
DECLARE
	VAR_schema VARCHAR;
	VAR_partition VARCHAR;
	VAR_q VARCHAR;
BEGIN
  -- VAR_schema = concat('v8_commands_', to_char(NEW.created_at, 'IYYY_IW'));
  VAR_schema = concat('v8_commands_', to_char(NEW.created_at, 'YYYY_MM_DD'));
  VAR_partition = to_char(date_trunc('hour', NEW.created_at), 'YYYY_MM_DD_HH24');

  BEGIN
    VAR_q = format(
      'INSERT INTO "%s"."v8_commands_%s" VALUES ($1.*);',
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
          'CREATE TABLE "%s"."v8_commands_%s" () INHERITS ("public"."v8_commands") WITH (fillfactor = 100);',
          VAR_schema,
          VAR_partition
        );
        RAISE DEBUG '%', VAR_q;
        EXECUTE VAR_q;
        RAISE DEBUG 'Created partition table "%"."v8_commands_%"', VAR_schema, VAR_partition;

        -- Add the read index
        BEGIN
          VAR_q = '';
          VAR_q = VAR_q || 'CREATE INDEX "v8_commands_read_idx_%s" ';
          VAR_q = VAR_q || 'ON "%s"."v8_commands_%s" ( "ref", "created_at" DESC ); ';

          VAR_q = format(VAR_q,
            VAR_partition,
            VAR_schema,
            VAR_partition
          );

          RAISE DEBUG '%', VAR_q;
          EXECUTE VAR_q;
          RAISE DEBUG 'Created index "v8_commands_read_idx_%" on "%"."v8_commands_%"', VAR_partition, VAR_schema, VAR_partition;
        EXCEPTION 
          WHEN sqlstate '42P07' THEN
            RAISE NOTICE 'Index "v8_commands_read_idx_%" on "%"."v8_commands_%"', VAR_partition, VAR_schema, VAR_partition;
          WHEN others THEN
            RAISE EXCEPTION 'Failed to create index ""v8_commands_read_idx_%"" on "%"."v8_commands_%: %; SQLSTATE: %', VAR_partition, VAR_schema, VAR_partition, SQLERRM, SQLSTATE;
        END;


        -- Add the time constraint
        BEGIN
          VAR_q = '';
          VAR_q = VAR_q || 'ALTER TABLE "%s"."v8_commands_%s" ';
          VAR_q = VAR_q || 'ADD CONSTRAINT "v8_commands_%s_created_at" ';
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
          RAISE DEBUG 'Created constraint "v8_commands_%s_created_at" on "%"."v8_commands_%"', VAR_partition, VAR_schema, VAR_partition;

        EXCEPTION 
          WHEN sqlstate '42710' THEN
            RAISE NOTICE 'Constraint "v8_commands_%s_created_at" on "%"."v8_commands_%" already exists', VAR_partition, VAR_schema, VAR_partition;
          WHEN others THEN
            RAISE EXCEPTION 'Failed to create constraint "v8_commands_%s_created_at" on "%"."v8_commands_%": %; SQLSTATE: %', VAR_partition, VAR_schema, VAR_partition, SQLERRM, SQLSTATE;
        END;

      EXCEPTION 
        WHEN sqlstate '42P07' THEN
          RAISE NOTICE 'Partition table "%"."v8_commands_%" already exists', VAR_schema, VAR_partition;
        WHEN others THEN
          RAISE EXCEPTION 'Failed to create partition table "%"."v8_commands_%": %; SQLSTATE: %', VAR_schema, VAR_partition, SQLERRM, SQLSTATE;
      END;

      -- Insert into custom partition // final attempt
      BEGIN
        EXECUTE format(
          'INSERT INTO "%s"."v8_commands_%s" VALUES ($1.*);',
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

CREATE OR REPLACE FUNCTION "public"."v8_responses_insert_fn"()
RETURNS trigger AS $$
DECLARE
	VAR_schema VARCHAR;
	VAR_partition VARCHAR;
	VAR_q VARCHAR;
BEGIN
  -- VAR_schema = concat('v8_responses_', to_char(NEW.created_at, 'IYYY_IW'));
  VAR_schema = concat('v8_responses_', to_char(NEW.created_at, 'YYYY_MM_DD'));
  VAR_partition = to_char(date_trunc('hour', NEW.created_at), 'YYYY_MM_DD_HH24');

  BEGIN
    VAR_q = format(
      'INSERT INTO "%s"."v8_responses_%s" VALUES ($1.*);',
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
          'CREATE TABLE "%s"."v8_responses_%s" () INHERITS ("public"."v8_responses") WITH (fillfactor = 100);',
          VAR_schema,
          VAR_partition
        );
        RAISE DEBUG '%', VAR_q;
        EXECUTE VAR_q;
        RAISE DEBUG 'Created partition table "%"."v8_responses_%"', VAR_schema, VAR_partition;


        -- Add the read index
        BEGIN
          VAR_q = '';
          VAR_q = VAR_q || 'CREATE INDEX "v8_responses_read_idx_%s" ';
          VAR_q = VAR_q || 'ON "%s"."v8_responses_%s" ( "ref", "created_at" DESC ); ';

          VAR_q = format(VAR_q,
            VAR_partition,
            VAR_schema,
            VAR_partition
          );

          RAISE DEBUG '%', VAR_q;
          EXECUTE VAR_q;
          RAISE DEBUG 'Created index "v8_responses_read_idx_%" on "%"."v8_responses_%"', VAR_partition, VAR_schema, VAR_partition;
        EXCEPTION 
          WHEN sqlstate '42P07' THEN
            RAISE NOTICE 'Index "v8_responses_read_idx_%" on "%"."v8_responses_%"', VAR_partition, VAR_schema, VAR_partition;
          WHEN others THEN
            RAISE EXCEPTION 'Failed to create index ""v8_responses_read_idx_%"" on "%"."v8_responses_%: %; SQLSTATE: %', VAR_partition, VAR_schema, VAR_partition, SQLERRM, SQLSTATE;
        END;


        -- Add the time constraint
        BEGIN
          VAR_q = '';
          VAR_q = VAR_q || 'ALTER TABLE "%s"."v8_responses_%s" ';
          VAR_q = VAR_q || 'ADD CONSTRAINT "v8_responses_%s_created_at" ';
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
          RAISE DEBUG 'Created constraint "v8_responses_%s_created_at" on "%"."v8_responses_%"', VAR_partition, VAR_schema, VAR_partition;

          EXCEPTION 
          WHEN sqlstate '42710' THEN
            RAISE NOTICE 'Constraint "v8_responses_%s_created_at" on "%"."v8_responses_%" already exists', VAR_partition, VAR_schema, VAR_partition;
          WHEN others THEN
            RAISE EXCEPTION 'Failed to create constraint "v8_responses_%s_created_at" on "%"."v8_responses_%": %; SQLSTATE: %', VAR_partition, VAR_schema, VAR_partition, SQLERRM, SQLSTATE;
        END;

        EXCEPTION 
        WHEN sqlstate '42P07' THEN
          RAISE NOTICE 'Partition table "%"."v8_responses_%" already exists', VAR_schema, VAR_partition;
        WHEN others THEN
          RAISE EXCEPTION 'Failed to create partition table "%"."v8_responses_%": %; SQLSTATE: %', VAR_schema, VAR_partition, SQLERRM, SQLSTATE;
      END;

      -- Insert into custom partition // final attempt
      BEGIN
        EXECUTE format(
          'INSERT INTO "%s"."v8_responses_%s" VALUES ($1.*);',
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

CREATE TRIGGER "v8_commands_insert_trigger" 
BEFORE INSERT 
ON "public"."v8_commands" 
FOR EACH ROW EXECUTE PROCEDURE "public"."v8_commands_insert_fn"();

CREATE TRIGGER "v8_responses_insert_trigger" 
BEFORE INSERT 
ON "public"."v8_responses" 
FOR EACH ROW EXECUTE PROCEDURE "public"."v8_responses_insert_fn"();

