WITH "raw_data" AS (
  SELECT 
    ARRAY [
      'Red', 
      'Blue', 
      'Green', 
      'Yellow', 
      'Orange', 
      'Purple', 
      'Brown', 
      'Black', 
      'White', 
      'Gray'
    ] AS "colors"
)
SELECT 
  "colors"[floor(random() * array_length("colors", 1) + 1)::integer] AS "color"
FROM generate_series(1, 10) AS "n", "raw_data";