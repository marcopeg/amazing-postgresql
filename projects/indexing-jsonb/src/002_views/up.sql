CREATE VIEW actors AS
SELECT DISTINCT actor
FROM movies_jsonb,
     LATERAL jsonb_array_elements_text(data -> 'people' -> 'cast') AS actor
ORDER BY actor ASC;