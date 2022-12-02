-- Private function with static timestamp

CREATE OR REPLACE FUNCTION "date2txt_mu"(
	PAR_now TIMESTAMPTZ,
	OUT "value" VARCHAR(10)
)
AS $$
DECLARE
	VAR_chars VARCHAR(64) = '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
	VAR_now BIGINT;
	VAR_i INTEGER;
  VAR_charAt INTEGER;
BEGIN
  -- Get timestamp to the microseconds:
	VAR_now = date2ts_mu(PAR_now);
	
	-- Convert timestamp into a sortable string:
	FOR VAR_i IN 1..10 LOOP
    VAR_charAt = mod(VAR_now, 64) + 1;
		"value" = CONCAT(SUBSTRING(VAR_chars from VAR_charAt for 1), "value");
		VAR_now = FLOOR(VAR_now / 64);
	END LOOP;
	
	IF VAR_now != 0 THEN
		RAISE EXCEPTION 'We should have converted the entire timestamp: %', VAR_ts;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION "date2txt_ms"(
	PAR_now TIMESTAMPTZ,
	OUT "value" VARCHAR(8)
)
AS $$
DECLARE
	VAR_chars VARCHAR(64) = '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
	VAR_now BIGINT;
	VAR_i INTEGER;
  VAR_charAt INTEGER;
BEGIN
  -- Get timestamp to the millisecond:
	VAR_now = date2ts_ms(PAR_now);
	
	-- Convert timestamp into a sortable string:
	FOR VAR_i IN 1..8 LOOP
    VAR_charAt = mod(VAR_now, 64) + 1;
		"value" = CONCAT(SUBSTRING(VAR_chars from VAR_charAt for 1), "value");
		VAR_now = FLOOR(VAR_now / 64);
	END LOOP;
	
	IF VAR_now != 0 THEN
		RAISE EXCEPTION 'We should have converted the entire timestamp: %', VAR_ts;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;
