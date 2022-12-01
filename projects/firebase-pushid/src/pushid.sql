
CREATE OR REPLACE FUNCTION "pushid_mu"(
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
	VAR_isDuplicateTime BOOLEAN;
	VAR_i INTEGER;
	VAR_s TEXT DEFAULT '';
	VAR_randomChars TEXT[];
	VAR_j INTEGER;
BEGIN
	VAR_isDuplicateTime = (PAR_now = PAR_lastPushTime);
  "value" = date2txt_mu(PAR_now);
  "last_push_date" = PAR_now;
	
	-- Calculate randomized characters
	IF VAR_isDuplicateTime IS TRUE THEN
		VAR_randomChars = string_to_array(PAR_lastRandChars, ',');
		
		FOR VAR_i IN 1..8 LOOP
			VAR_j = 11 - VAR_i;
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
		FOR VAR_i IN 1..9 LOOP
			"last_rand_chars" = CONCAT("last_rand_chars", ',', FLOOR(random() * 64));
		END LOOP;
	END IF;
	
	VAR_randomChars = string_to_array("last_rand_chars", ',');
	
	
	-- Add randomized token to ID
	FOR VAR_i IN 1..10 LOOP
		"value" = CONCAT("value", SUBSTRING(VAR_chars from (VAR_randomChars[VAR_i]::int + 1) for 1));
	END LOOP;
	
	IF length("value") != 20 THEN
		RAISE EXCEPTION 'Length should be 20 but got %: %', length("value"), "value";
	END IF;
	
	
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION "pushid_ms"(
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
	VAR_isDuplicateTime BOOLEAN;
	VAR_i INTEGER;
	VAR_s TEXT DEFAULT '';
	VAR_randomChars TEXT[];
	VAR_j INTEGER;
BEGIN
	VAR_isDuplicateTime = (PAR_now = PAR_lastPushTime);
  "value" = date2txt_ms(PAR_now);
  "last_push_date" = PAR_now;
	
	-- Calculate randomized characters
	IF VAR_isDuplicateTime IS TRUE THEN
		VAR_randomChars = string_to_array(PAR_lastRandChars, ',');
		
		FOR VAR_i IN 1..10 LOOP
			VAR_j = 13 - VAR_i;
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
		FOR VAR_i IN 1..11 LOOP
			"last_rand_chars" = CONCAT("last_rand_chars", ',', FLOOR(random() * 64));
		END LOOP;
	END IF;
	
	VAR_randomChars = string_to_array("last_rand_chars", ',');
	
	
	-- Add randomized token to ID
	FOR VAR_i IN 1..12 LOOP
		"value" = CONCAT("value", SUBSTRING(VAR_chars from (VAR_randomChars[VAR_i]::int + 1) for 1));
	END LOOP;
	
	IF length("value") != 20 THEN
		RAISE EXCEPTION 'Length should be 20 but got %: %', length("value"), "value";
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


