-- Generate values
VALUES 
  (1, 'Red'),
  (2, 'Green'),
  (3, 'Blue'),
  (4, 'Yellow');

-- Column names
SELECT * FROM (VALUES 
  (1, 'Red'),
  (2, 'Green'),
  (3, 'Blue'),
  (4, 'Yellow')
) AS t(id, color);

-- Typed
SELECT
  "c1"::integer AS "id",
  "c2"::text AS "color"
FROM (VALUES 
  (1, 'Red'),
  (2, 'Green'),
  (3, 'Blue'),
  (4, 'Yellow')
) AS t("c1", "c2");

-- Mix it with static values
SELECT
  "c1"::integer AS "id",
  "c2"::text AS "color",
  123 AS "static_number"
FROM (VALUES 
  (1, 'Red'),
  (2, 'Green'),
  (3, 'Blue'),
  (4, 'Yellow')
) AS t("c1", "c2");