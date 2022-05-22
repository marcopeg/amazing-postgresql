
CREATE TABLE IF NOT EXISTS "public"."v7_commands" (
  "ref" VARCHAR(50) NOT NULL,
  "payload" JSONB NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now(),
  "cmd_id" BIGSERIAL PRIMARY KEY
);

CREATE OR REPLACE FUNCTION "public"."v7_commands_insert_fn"()
RETURNS trigger AS $$
BEGIN

  -- First attempt
  BEGIN
  EXECUTE format(
    'INSERT INTO v7_commands_%s VALUES ($1.*);',
    to_char(date_trunc('hour', NEW.created_at), 'YYYY_MM_DD_HH')
  ) USING NEW;

  -- First soft error with re-attempt
  EXCEPTION WHEN others THEN
    -- Upsert the table partition
    BEGIN
    EXECUTE format(
      'CREATE TABLE IF NOT EXISTS "public"."v7_commands_%s" () INHERITS ("public"."v7_commands");',
      to_char(date_trunc('hour', NEW.created_at), 'YYYY_MM_DD_HH')
    );
    EXCEPTION WHEN others THEN
      RAISE EXCEPTION 'Could not upsert the table partition: %; SQLSTATE: %', SQLERRM, SQLSTATE;
    END;

    -- Insert into custom partition
    BEGIN
    EXECUTE format(
      'INSERT INTO v7_commands_%s VALUES ($1.*);',
      to_char(date_trunc('hour', NEW.created_at), 'YYYY_MM_DD_HH')
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