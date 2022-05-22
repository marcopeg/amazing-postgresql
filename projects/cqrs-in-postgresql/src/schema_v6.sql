
CREATE TABLE IF NOT EXISTS "public"."v6_commands" (
  "ref" VARCHAR(50) NOT NULL,
  "payload" JSONB NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now(),
  "cmd_id" BIGSERIAL PRIMARY KEY
);

CREATE OR REPLACE FUNCTION "public"."v6_commands_insert_fn"()
RETURNS trigger AS $$
BEGIN
  -- Upsert the table partition
  EXECUTE format(
    'CREATE TABLE IF NOT EXISTS "public"."v6_commands_%s" () INHERITS ("public"."v6_commands");',
    replace(date_trunc('day', NEW.created_at)::date::text, '-', '_')
  );

  -- Insert into custom partition
  EXECUTE format(
    'INSERT INTO v6_commands_%s VALUES ($1.*);',
    replace(date_trunc('day', NEW.created_at)::date::text, '-', '_')
  ) USING NEW;

  RETURN NULL;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER "v6_commands_insert_trigger" 
BEFORE INSERT 
ON "public"."v6_commands" 
FOR EACH ROW EXECUTE PROCEDURE "public"."v6_commands_insert_fn"();
