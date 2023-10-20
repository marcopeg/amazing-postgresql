SELECT data->>'released' AS released_year_json, data->>'title' AS movie_title_json FROM movies_json
ORDER BY released_year_json, movie_title_json;

SELECT data->>'released' AS released_year_jsonb, data->>'title' AS movie_title_jsonb FROM movies_jsonb
ORDER BY released_year_jsonb, movie_title_jsonb;