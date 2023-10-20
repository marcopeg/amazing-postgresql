SELECT json_array_elements_text(data->'people'->'cast') AS actor, data->>'title' AS movie FROM movies_json
ORDER BY actor, movie;

SELECT jsonb_array_elements_text(data->'people'->'cast') AS actor, data->>'title' AS movie FROM movies_jsonb
ORDER BY actor, movie;