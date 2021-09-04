
CREATE OR REPLACE FUNCTION "get_event"(
  PAR_lastEtag BIGINT,
  PAR_limit INT
) 
RETURNS SETOF "events_log"
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM "events_log"
  WHERE "etag" > PAR_lastEtag
  LIMIT PAR_limit;
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "get_event"(
  PAR_lastEtag BIGINT
) 
RETURNS SETOF "events_log"
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM get_event(PAR_lastEtag, 1);
END; $$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "get_event"() 
RETURNS SETOF "events_log"
AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM get_event(0, 1);
END; $$
LANGUAGE plpgsql;