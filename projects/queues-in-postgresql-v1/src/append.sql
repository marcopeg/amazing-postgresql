CREATE OR REPLACE FUNCTION "append_v1"(
  PAR_payload JSON
) 
RETURNS SETOF "queue_v1"
AS $$
BEGIN
  -- Insert multiple rows from JSON
  IF json_typeof(PAR_payload) = 'array' THEN
    RETURN QUERY
    INSERT INTO "queue_v1" ("payload")
    SELECT json_array_elements_text(PAR_payload)::JSON
    RETURNING *;
  -- Insert single row from JSON
  ELSE
    RETURN QUERY
    INSERT INTO "queue_v1" ("payload")
    VALUES (PAR_payload)
    RETURNING *;
  END IF;
END; $$
LANGUAGE plpgsql;

