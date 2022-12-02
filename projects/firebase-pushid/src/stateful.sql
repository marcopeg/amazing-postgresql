-- !!! EXPERIMENTAL !!!
-- Handles conflicts using a support table:

CREATE TABLE IF NOT EXISTS "pushid" (
  "scope" TEXT NOT NULL,
  "precision" TEXT NOT NULL,
  "last_push_date" TIMESTAMPTZ NOT NULL,
  "last_rand_chars" TEXT NOT NULL,
  PRIMARY KEY ("scope", "precision")
);

CREATE OR REPLACE FUNCTION "pushid_ms_stateful"(
  PAR_scope TEXT,
	OUT "value" VARCHAR(20)
)
AS $$
DECLARE
	VAR_a RECORD; 
	VAR_r RECORD; 
BEGIN
  SELECT * INTO VAR_a FROM "pushid" 
  WHERE "scope" = PAR_scope
    AND "precision" = 'ms';

  IF VAR_a IS NULL THEN
    SELECT * INTO VAR_r FROM pushid_ms(clock_timestamp());
    INSERT INTO "pushid" VALUES (PAR_scope, 'ms', VAR_r.last_push_date, VAR_r.last_rand_chars);
  ELSE
    SELECT * INTO VAR_r FROM pushid_ms(clock_timestamp(), VAR_a.last_push_date, VAR_a.last_rand_chars);
    UPDATE "pushid" SET
      "last_push_date" = VAR_r.last_push_date,
      "last_rand_chars" = VAR_r.last_rand_chars
    WHERE "scope" = PAR_scope AND "precision" = 'ms';
  END IF;

	"value" = VAR_r."value";
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION "pushid_mu_stateful"(
  PAR_scope TEXT,
	OUT "value" VARCHAR(20)
)
AS $$
DECLARE
	VAR_a RECORD; 
	VAR_r RECORD; 
BEGIN
  SELECT * INTO VAR_a FROM "pushid" 
  WHERE "scope" = PAR_scope
    AND "precision" = 'mu';

  IF VAR_a IS NULL THEN
    SELECT * INTO VAR_r FROM pushid_mu(clock_timestamp());
    INSERT INTO "pushid" VALUES (PAR_scope, 'mu', VAR_r.last_push_date, VAR_r.last_rand_chars);
  ELSE
    SELECT * INTO VAR_r FROM pushid_mu(clock_timestamp(), VAR_a.last_push_date, VAR_a.last_rand_chars);
    UPDATE "pushid" SET
      "last_push_date" = VAR_r.last_push_date,
      "last_rand_chars" = VAR_r.last_rand_chars
    WHERE "scope" = PAR_scope AND "precision" = 'mu';
  END IF;

	"value" = VAR_r."value";
END;
$$ LANGUAGE plpgsql;

