-- Insert multiple records into "people_v1"
-- (with independent transactions)
BEGIN;
INSERT INTO "public"."people_v1" ("name", "surname")
VALUES ('Luke', 'Skywalker')
RETURNING *;
COMMIT;

BEGIN;
INSERT INTO "public"."people_v1" ("name", "surname")
VALUES ('Han', 'Solo')
RETURNING *;
COMMIT;






-- Insert multiple records into "people_v2"
-- (multiple records within the same instruction)
INSERT INTO "public"."people_v2" ("name", "surname")
VALUES ('Luke', 'Skywalker'), ('Han', 'Solo')
RETURNING *;

-- Insert multiple records into "people_v2"
-- (multiple instructions within the same trasnaction)
BEGIN;
INSERT INTO "public"."people_v2" ("name", "surname")
VALUES ('Leia', 'Princess')
RETURNING *;
INSERT INTO "public"."people_v2" ("name", "surname")
VALUES ('Obi-Wan', 'Kenobi')
RETURNING *;
INSERT INTO "public"."people_v2" ("name", "surname")
VALUES ('Yoda', 'Master')
RETURNING *;
COMMIT;







-- Insert multiple records into "people_v3"
-- (within independent transactions)

BEGIN;
INSERT INTO "public"."people_v3"
VALUES ((EXTRACT(EPOCH FROM now()) * 100000)::BIGINT, 'Luke', 'Skywalker')
RETURNING *;
COMMIT;

BEGIN;
INSERT INTO "public"."people_v3"
VALUES ((EXTRACT(EPOCH FROM now()) * 100000)::BIGINT, 'Han', 'Solo')
RETURNING *;
COMMIT;


-- Insert multiple records into "people_v3"
-- (within the same transaction)

WITH
-- Generates values to be inserted into the target table:
"insert_values" AS (
	VALUES
	('Leia', 'Princess'), 
	('Obi-Wan', 'Kenobi'),
  ('Yoda', 'Master')
),
-- Allocate a Timestamp based ID with an incremental value
-- that is specific for each record:
"insert_records" AS (
	SELECT 
		CONCAT(
			(EXTRACT(EPOCH FROM now()) * 100000)::BIGINT,
			'-',
			row_number() OVER ()
		) AS "id",
		"a"."column1" as "name",
		"a"."column2" as "surname"
	FROM "insert_values" AS "a"
)
-- Run the insert statement:
INSERT INTO "public"."people_v3" 
SELECT * FROM "insert_records"
RETURNING *;
