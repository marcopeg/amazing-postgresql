-- JSON
SELECT DISTINCT json_array_elements_text(data->'people'->'cast') AS actors_json 
FROM movies_json
ORDER BY actors_json;

-- JSONB
SELECT DISTINCT jsonb_array_elements_text(data->'people'->'cast') AS actors_jsonb
FROM movies_jsonb
ORDER BY actors_jsonb;

