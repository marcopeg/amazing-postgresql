CREATE VIEW vw_actors AS
SELECT DISTINCT jsonb_array_elements_text(data->'people'->'cast') AS actors_jsonb
FROM movies_jsonb
ORDER BY actors_jsonb;

CREATE VIEW vw_actors_movies AS
SELECT jsonb_array_elements_text(data->'people'->'cast') AS actor, data->>'title' AS movie FROM movies_jsonb
ORDER BY actor, movie;

CREATE VIEW vw_years AS
SELECT data->>'released' AS released_year, data->>'title' AS movie_title FROM movies_jsonb
ORDER BY released_year, movie_title;