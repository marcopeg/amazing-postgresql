CREATE TYPE "pushid_precision" AS ENUM ('ms', 'mu');

CREATE OR REPLACE FUNCTION "pushid_encode_date"(
  PAR_precision "pushid_precision",
	PAR_now TIMESTAMPTZ DEFAULT clock_timestamp(),
	OUT "value" VARCHAR(10)
)
AS $$
DECLARE
	VAR_chars VARCHAR(64) = '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
	VAR_now BIGINT;
	VAR_i INTEGER;
  VAR_j INTEGER;
  VAR_charAt INTEGER;
BEGIN
  -- MILLISECONDS
  IF PAR_precision = 'ms' THEN
    VAR_now = FLOOR(extract(epoch from PAR_now) * 1000);
    VAR_j = 8;
    
  -- MICROSECONDS
  ELSE
    VAR_now = extract(epoch from PAR_now) * 1000000;
    VAR_j = 10;
  END IF;

  FOR VAR_i IN 1..VAR_j LOOP
    VAR_charAt = mod(VAR_now, 64) + 1;
    "value" = CONCAT(SUBSTRING(VAR_chars from VAR_charAt for 1), "value");
    VAR_now = FLOOR(VAR_now / 64);
  END LOOP;

  IF VAR_now != 0 THEN
    RAISE EXCEPTION 'We should have converted the entire timestamp: %', VAR_ts;
  END IF;

END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;



CREATE OR REPLACE FUNCTION "pushid_generate_v1"(
  PAR_precision "pushid_precision",
	PAR_now TIMESTAMPTZ,
	PAR_lastPushTime TIMESTAMPTZ DEFAULT '1970-01-01',
	PAR_lastRandChars TEXT DEFAULT '',
	OUT "value" VARCHAR(20),
	OUT "last_push_date" TIMESTAMPTZ,
	OUT "last_rand_chars" TEXT
)
AS $$
DECLARE
	VAR_chars VARCHAR(64) = '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
	VAR_ts BIGINT;
	VAR_s TEXT DEFAULT '';
	VAR_randomChars TEXT[];
	-- Loops indexes
	VAR_i INT;
	VAR_j INT;
	-- Params settings defaulted for "ms" precision
  VAR_l1 INT DEFAULT 10;
  VAR_l2 INT DEFAULT 11;
  VAR_l3 INT DEFAULT 12;
  VAR_l4 INT DEFAULT 13;
BEGIN
	-- Different precision has different size :-/
	IF PAR_precision = 'mu' THEN
		VAR_l1 = 8;
		VAR_l2 = 9;
		VAR_l3 = 10;
		VAR_l4 = 11;
	END IF;

	"last_push_date" = PAR_now;
	"value" = pushid_encode_date(PAR_precision, PAR_now);
	
	-- Calculate randomized characters
	IF PAR_now = PAR_lastPushTime THEN
		VAR_randomChars = string_to_array(PAR_lastRandChars, ',');
		
		FOR VAR_i IN 1..VAR_l1 LOOP
			VAR_j = VAR_l4 - VAR_i;
			IF VAR_randomChars[VAR_j]::int != 63 THEN 
				EXIT; 
			END IF;
			
			VAR_randomChars[VAR_j] = 0;
		END LOOP;
		
		VAR_randomChars[VAR_j] = VAR_randomChars[VAR_j]::int + 1;
		"last_rand_chars" = array_to_string(VAR_randomChars, ',');

	-- Build randomic list of characters:
	-- (10 items because we use microseconds so the time component length is of 10)
	ELSE
		"last_rand_chars" = FLOOR(random() * 64);
		FOR VAR_i IN 1..VAR_l2 LOOP
			"last_rand_chars" = CONCAT("last_rand_chars", ',', FLOOR(random() * 64));
		END LOOP;
	END IF;
	
	VAR_randomChars = string_to_array("last_rand_chars", ',');
	
	
	-- Add randomized token to ID
	FOR VAR_i IN 1..VAR_l3 LOOP
		"value" = CONCAT("value", SUBSTRING(VAR_chars from (VAR_randomChars[VAR_i]::int + 1) for 1));
	END LOOP;


	IF length("value") != 20 THEN
		RAISE EXCEPTION 'Length should be 20 but got %: %', length("value"), "value";
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION "pushid_generate_v1"(
  PAR_precision "pushid_precision" DEFAULT 'ms',
	OUT "value" VARCHAR(20)
)
AS $$
DECLARE
	VAR_r RECORD; 
BEGIN
	SELECT * INTO VAR_r FROM pushid_generate_v1(PAR_precision, clock_timestamp());
	"value" = VAR_r."value";
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;
