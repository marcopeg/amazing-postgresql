
CREATE OR REPLACE FUNCTION "date2ts_mu"(
	PAR_now TIMESTAMPTZ,
	OUT ts BIGINT
)
AS $$
BEGIN
	ts = extract(epoch from PAR_now) * 1000000;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION "date2ts_ms"(
	PAR_now TIMESTAMPTZ,
	OUT ts BIGINT
)
AS $$
BEGIN
	ts = FLOOR(extract(epoch from PAR_now) * 1000);
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;
