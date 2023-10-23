WITH "boundaries" AS (
  SELECT 
    extract(year from current_date) AS "max", 
    extract(year from current_date) - 100 AS "min"
)
SELECT 
  "n",
  floor(random() * ("max" - "min" + 1) + "min")::integer AS "r"
FROM generate_series(1, 10) "n", "boundaries";