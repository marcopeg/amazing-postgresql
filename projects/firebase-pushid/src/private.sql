-- Private function with static timestamp


-- CREATE OR REPLACE FUNCTION "date2text_mu"(
-- 	PAR_now TIMESTAMPTZ,
-- 	OUT VAR_pid VARCHAR(200)
-- )
-- AS $$
-- DECLARE
-- 	VAR_chars VARCHAR(64) = '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
-- 	VAR_ts BIGINT;
-- 	VAR_i INTEGER;
-- 	VAR_timeStampChars VARCHAR(20) DEFAULT '';
-- BEGIN
-- 	VAR_ts = extract(epoch from PAR_now) * 1000000;
-- 	-- RAISE INFO 'VAR_ts: %', VAR_ts;
	
-- 	-- Convert timestamp into a sortable string:
-- 	FOR VAR_i IN 0..9 LOOP
-- 		VAR_timeStampChars = CONCAT(VAR_timeStampChars, SUBSTRING(VAR_chars from ((VAR_ts % 64) + 1)::INT for 1));
-- 		VAR_ts = FLOOR(VAR_ts/64);
-- 	END LOOP;
	
-- 	IF VAR_ts != 0 THEN
-- 		RAISE EXCEPTION 'We should have converted the entire timestamp: %', VAR_ts;
-- 	END IF;
	
-- 	VAR_pid = CONCAT(REVERSE(VAR_timeStampChars));
-- END;
-- $$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION "date2txt_mu"(
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
	VAR_now = date2ts_mu(PAR_now);
	
	-- Convert timestamp into a sortable string:
	FOR VAR_i IN 1..10 LOOP
    VAR_charAt = (VAR_now % 64) + 1;
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
    VAR_charAt = (VAR_now % 64) + 1;
		"value" = CONCAT(SUBSTRING(VAR_chars from VAR_charAt for 1), "value");
		VAR_now = FLOOR(VAR_now / 64);
	END LOOP;
	
	IF VAR_now != 0 THEN
		RAISE EXCEPTION 'We should have converted the entire timestamp: %', VAR_ts;
	END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;

-- DROP FUNCTION "uuid_generate_pushid__";
-- CREATE OR REPLACE FUNCTION "uuid_generate_pushid__"(
-- 	PAR_now TIMESTAMPTZ,
-- 	PAR_lastPushTime TIMESTAMPTZ DEFAULT '1970-01-01',
-- 	PAR_lastRandChars TEXT DEFAULT '',
-- 	OUT VAR_pid VARCHAR(200),
-- 	OUT VAR_lastPushTime TIMESTAMPTZ,
-- 	OUT VAR_lastRandChars TEXT
-- )
-- AS $$
-- DECLARE
-- 	VAR_chars VARCHAR(64) = '-0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz';
-- 	VAR_ts BIGINT;
-- 	VAR_isDuplicateTime BOOLEAN;
-- 	VAR_i INTEGER;
-- 	VAR_timeStampChars VARCHAR(20) DEFAULT '';
-- 	VAR_s TEXT DEFAULT '';
-- 	VAR_randomChars TEXT[];
-- 	VAR_j INTEGER;
-- BEGIN
-- 	VAR_ts = extract(epoch from PAR_now) * 1000000;
-- 	RAISE INFO 'VAR_ts: %', VAR_ts;
-- 	VAR_isDuplicateTime = (PAR_now = PAR_lastPushTime);
	
-- 	-- Convert timestamp into a sortable string:
-- 	FOR VAR_i IN 0..9 LOOP
-- 		VAR_timeStampChars = CONCAT(VAR_timeStampChars, SUBSTRING(VAR_chars from ((VAR_ts % 64) + 1)::INT for 1));
-- 		VAR_ts = FLOOR(VAR_ts/64);
-- 	END LOOP;
	
-- 	IF VAR_ts != 0 THEN
-- 		RAISE EXCEPTION 'We should have converted the entire timestamp: %', VAR_ts;
-- 	END IF;
	
-- 	VAR_pid = CONCAT(REVERSE(VAR_timeStampChars));
	
-- 	RAISE INFO 'VAR_pid (only date): % length of: %', VAR_pid, length(VAR_pid);
	
	
-- 	-- Calculate randomized characters
-- 	IF VAR_isDuplicateTime IS TRUE THEN
-- 		VAR_randomChars = string_to_array(PAR_lastRandChars, ',');
-- 		RAISE INFO 'Last characters: %', VAR_randomChars;
		
-- 		FOR VAR_i IN 1..8 LOOP
-- 			VAR_j = 11 - VAR_i;
-- 			RAISE INFO 'Item % at % is: % - %', VAR_i, VAR_j, VAR_randomChars[VAR_j], VAR_randomChars[VAR_j]::int != 63;
-- 			IF VAR_randomChars[VAR_j]::int != 63 THEN 
-- 				RAISE INFO 'Item is NOT 63!';
-- 				EXIT; 
-- 			END IF;
			
-- 			RAISE INFO 'Replace (%) with 0', VAR_randomChars[(11 - VAR_i)];
-- 			VAR_randomChars[VAR_j] = 0;
-- 		END LOOP;
		
		
-- 		RAISE NOTICE 'Last value of VAR_j: %', VAR_j;
-- --		VAR_randomChars[VAR_j] = (VAR_randomChars[(11 - VAR_i)]::int + 1)::text;
-- 		VAR_randomChars[VAR_j] = VAR_randomChars[VAR_j]::int + 1;
		
-- 		VAR_lastRandChars = array_to_string(VAR_randomChars, ',');
		
-- 		RAISE NOTICE 'New numbers: %', VAR_randomChars;
-- --		RAISE EXCEPTION 'Conflict in time, not yet implemented';
-- 	ELSE
-- 		-- Build randomic list of characters:
-- 		-- (10 items because we use microseconds so the time component length is of 10)
-- 		VAR_lastRandChars = FLOOR(random() * 64);
-- 		FOR VAR_i IN 1..9 LOOP
-- 			VAR_lastRandChars = CONCAT(VAR_lastRandChars, ',', FLOOR(random() * 64));
-- 		END LOOP;
-- 	END IF;
	
-- 	RAISE INFO 'VAR_lastRandChars: %', VAR_lastRandChars;
-- 	VAR_randomChars = string_to_array(VAR_lastRandChars, ',');
-- 	RAISE INFO 'As array: %', VAR_randomChars;
	
	
-- 	-- Add randomized token to ID
-- 	FOR VAR_i IN 1..10 LOOP
-- --		RAISE INFO 'Get: %: % (%) > %', VAR_i, VAR_randomChars[VAR_i], VAR_randomChars[VAR_i]::int, SUBSTRING(VAR_chars from VAR_randomChars[VAR_i]::int for 1);
-- 		VAR_pid = CONCAT(VAR_pid, SUBSTRING(VAR_chars from (VAR_randomChars[VAR_i]::int + 1) for 1));
-- 	END LOOP;
	
-- 	IF length(VAR_pid) != 20 THEN
-- 		RAISE EXCEPTION 'Length should be 20 but got %: %', length(VAR_pid), VAR_pid;
-- 	END IF;
	

-- 	VAR_pid = CONCAT(VAR_pid, ' ', PAR_now, ' - ', VAR_lastRandChars);
-- 	VAR_lastPushTime = PAR_now;
-- END;
-- $$ LANGUAGE plpgsql IMMUTABLE STRICT;