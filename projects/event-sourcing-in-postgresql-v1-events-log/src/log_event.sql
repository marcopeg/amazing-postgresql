
CREATE OR REPLACE FUNCTION "log_event"(
  PAR_payload JSON
) 
RETURNS SETOF "events_log"
AS $$
BEGIN
  RETURN QUERY
  INSERT INTO "events_log" ("payload")
  VALUES (PAR_payload)
  RETURNING *;
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "log_event"(
  PAR_payload JSON[]
) 
RETURNS SETOF "events_log"
AS $$
BEGIN
  RETURN QUERY
  INSERT INTO "events_log" ("payload")
  SELECT json_array_elements_text('[{"a":1}, {"a": 2}]')::JSON;
  RETURNING *;
END; $$
LANGUAGE plpgsql;