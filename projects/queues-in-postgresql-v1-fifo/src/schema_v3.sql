
CREATE TABLE IF NOT EXISTS "public"."queue_v3" (
  "payload" JSONB,
  "is_available" BOOLEAN DEFAULT true,
  "task_id" BIGSERIAL PRIMARY KEY,
  "picked_at" TIMESTAMP
);

CREATE INDEX "queue_v3_pick_idx" 
ON "queue_v3" ( "task_id" ASC ) 
WHERE ( "is_available" = true );

CREATE INDEX "queue_v3_recover_idx"
ON "queue_v3" ( "picked_at" ASC ) 
WHERE ( "is_available" = false );

CREATE OR REPLACE FUNCTION "queue_v3_picked_at"()   
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."is_available" = false AND 
     OLD."is_available" = true 
  THEN
    NEW.picked_at = NOW();
  END IF;
  RETURN NEW;   
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER "queue_v3_picked_at" 
BEFORE UPDATE 
ON "queue_v3" 
FOR EACH ROW 
EXECUTE PROCEDURE "queue_v3_picked_at"();