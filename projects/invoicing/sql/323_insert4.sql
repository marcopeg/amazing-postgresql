WITH "raw_data" AS (
  SELECT 
    ARRAY['Red', 'Green', 'Blue', 'Yellow', 'Purple', 'Orange', 'Pink', 'Brown', 'Grey', 'Black'] AS colors,
    extract(epoch from current_timestamp) AS "max_time",
    extract(epoch from (current_timestamp - interval '100 years')) AS "min_time"
)
INSERT INTO "users_idx_3" ("name", "gender", "date_of_birth", "favourite_color", "favourite_number", "favourite_word")
SELECT
  concat('User-', "n"),
  CASE
    WHEN random() < 0.55 THEN 'M'
    WHEN random() < 0.95 THEN 'F'
    ELSE 'O'
  END,
  to_timestamp("min_time" + (random() * ("max_time" - "min_time")))::date,
  colors[ceil(random() * array_length(colors, 1))::integer],
  floor(random() * 999999999 + 1)::integer,
  concat('word-', floor(random() * 5000 + 1)::integer)
FROM generate_series(1, 1000) "n", "raw_data";