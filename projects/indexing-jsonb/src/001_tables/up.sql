CREATE TABLE movies_json (
    id SERIAL PRIMARY KEY,
    data JSON
);

CREATE TABLE movies_jsonb (
    id SERIAL PRIMARY KEY,
    data JSONB
);