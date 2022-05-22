
CREATE TABLE IF NOT EXISTS "public"."v5_commands" (
  "ref" VARCHAR(50) NOT NULL,
  "payload" JSONB NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now(),
  "cmd_id" BIGSERIAL PRIMARY KEY
);

CREATE OR REPLACE FUNCTION "public"."v5_commands_insert_fn"()
RETURNS trigger AS $$
BEGIN
  EXECUTE format(
    'INSERT INTO v5_commands_%s VALUES ($1.*);',
    replace(date_trunc('day', NEW.created_at)::date::text, '-', '_')
  ) USING NEW;

  RETURN NULL;
END; $$
LANGUAGE plpgsql;

CREATE TRIGGER "v5_commands_insert_trigger" 
BEFORE INSERT 
ON "public"."v5_commands" 
FOR EACH ROW EXECUTE PROCEDURE "public"."v5_commands_insert_fn"();

-- Create partitions
CREATE TABLE IF NOT EXISTS "public"."v5_commands_2022_05_22" () INHERITS ("public"."v5_commands");
CREATE TABLE IF NOT EXISTS "public"."v5_commands_2022_05_21" () INHERITS ("public"."v5_commands");
