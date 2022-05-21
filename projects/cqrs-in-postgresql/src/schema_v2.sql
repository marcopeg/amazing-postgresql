-- FillFactor = 100
-- both tables work in INSERT ONLY mode

CREATE TABLE IF NOT EXISTS "public"."v2_commands" (
  "payload" JSONB NOT NULL,
  "cmd_id" BIGSERIAL PRIMARY KEY,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now()
) WITH (fillfactor = 100);

CREATE TABLE IF NOT EXISTS "public"."v2_responses" (
  "cmd_id" BIGINT,
  "payload" JSONB DEFAULT null,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT now(),
  CONSTRAINT "fk_commands"
    FOREIGN KEY("cmd_id") 
	  REFERENCES v2_commands("cmd_id")
    ON DELETE SET NULL
) WITH (fillfactor = 100);

CREATE OR REPLACE FUNCTION "v2_response_validate_input"()   
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."cmd_id" IS NULL THEN 
    RAISE EXCEPTION '"cmd_id" can not be null';
  END IF;

  RETURN NEW;   
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER "v2_response_validate_input_trigger" 
BEFORE INSERT 
ON "public"."v2_responses" 
FOR EACH ROW 
EXECUTE PROCEDURE "v2_response_validate_input"();