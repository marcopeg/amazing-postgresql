CREATE TABLE IF NOT EXISTS "public"."responses" (
  "cmd_id" BIGINT NOT NULL,
  "ref" VARCHAR(50) NOT NULL,
  "payload" JSONB DEFAULT null,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now()
) WITH (fillfactor = 100);

CREATE INDEX "responses_read_idx"
ON "responses" ( "ref", "created_at" DESC );

CREATE FUNCTION "public"."responses_insert_fn"()
RETURNS trigger AS $$
DECLARE
	VAR_schema VARCHAR;
	VAR_partition VARCHAR;
	VAR_q VARCHAR;
BEGIN
  -- VAR_schema = concat('responses_', to_char(NEW.created_at, 'IYYY_IW'));
  VAR_schema = concat('responses_', to_char(NEW.created_at, 'YYYY_MM_DD'));
  VAR_partition = to_char(date_trunc('hour', NEW.created_at), 'YYYY_MM_DD_HH24');

  BEGIN
    VAR_q = format(
      'INSERT INTO "%s"."responses_%s" VALUES ($1.*);',
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
          'CREATE TABLE "%s"."responses_%s" () INHERITS ("public"."responses") WITH (fillfactor = 100);',
          VAR_schema,
          VAR_partition
        );
        RAISE DEBUG '%', VAR_q;
        EXECUTE VAR_q;
        RAISE DEBUG 'Created partition table "%"."responses_%"', VAR_schema, VAR_partition;


        -- Add the read index
        BEGIN
          VAR_q = '';
          VAR_q = VAR_q || 'CREATE INDEX "responses_read_idx_%s" ';
          VAR_q = VAR_q || 'ON "%s"."responses_%s" ( "ref", "created_at" DESC ); ';

          VAR_q = format(VAR_q,
            VAR_partition,
            VAR_schema,
            VAR_partition
          );

          RAISE DEBUG '%', VAR_q;
          EXECUTE VAR_q;
          RAISE DEBUG 'Created index "responses_read_idx_%" on "%"."responses_%"', VAR_partition, VAR_schema, VAR_partition;
        EXCEPTION 
          WHEN sqlstate '42P07' THEN
            RAISE NOTICE 'Index "responses_read_idx_%" on "%"."responses_%"', VAR_partition, VAR_schema, VAR_partition;
          WHEN others THEN
            RAISE EXCEPTION 'Failed to create index ""responses_read_idx_%"" on "%"."responses_%: %; SQLSTATE: %', VAR_partition, VAR_schema, VAR_partition, SQLERRM, SQLSTATE;
        END;


        -- Add the time constraint
        BEGIN
          VAR_q = '';
          VAR_q = VAR_q || 'ALTER TABLE "%s"."responses_%s" ';
          VAR_q = VAR_q || 'ADD CONSTRAINT "responses_%s_created_at" ';
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
          RAISE DEBUG 'Created constraint "responses_%s_created_at" on "%"."responses_%"', VAR_partition, VAR_schema, VAR_partition;

          EXCEPTION 
          WHEN sqlstate '42710' THEN
            RAISE NOTICE 'Constraint "responses_%s_created_at" on "%"."responses_%" already exists', VAR_partition, VAR_schema, VAR_partition;
          WHEN others THEN
            RAISE EXCEPTION 'Failed to create constraint "responses_%s_created_at" on "%"."responses_%": %; SQLSTATE: %', VAR_partition, VAR_schema, VAR_partition, SQLERRM, SQLSTATE;
        END;

        EXCEPTION 
        WHEN sqlstate '42P07' THEN
          RAISE NOTICE 'Partition table "%"."responses_%" already exists', VAR_schema, VAR_partition;
        WHEN others THEN
          RAISE EXCEPTION 'Failed to create partition table "%"."responses_%": %; SQLSTATE: %', VAR_schema, VAR_partition, SQLERRM, SQLSTATE;
      END;

      -- Insert into custom partition // final attempt
      BEGIN
        EXECUTE format(
          'INSERT INTO "%s"."responses_%s" VALUES ($1.*);',
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

CREATE TRIGGER "responses_insert_trigger" 
BEFORE INSERT 
ON "public"."responses" 
FOR EACH ROW EXECUTE PROCEDURE "public"."responses_insert_fn"();

