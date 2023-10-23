DROP SCHEMA "public" CASCADE;
CREATE SCHEMA "public";

CREATE TABLE languages (
  lang_id TEXT PRIMARY KEY,
  lang_name TEXT NOT NULL
);

INSERT INTO languages (lang_id, lang_name) VALUES
('en', 'English'),
('it', 'Italian'),
('es', 'Spanish');

SELECT a.lang_id AS lang1, b.lang_id AS lang2
FROM languages a, languages b
WHERE a.lang_id != b.lang_id;
