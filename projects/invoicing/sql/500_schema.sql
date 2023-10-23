DROP SCHEMA "public" CASCADE;
CREATE SCHEMA "public";

-- Super duper simple tasks management
CREATE TABLE tasks (
  "id" SERIAL PRIMARY KEY
);

-- Insert 3 tasks
INSERT INTO tasks DEFAULT VALUES;
INSERT INTO tasks DEFAULT VALUES;
INSERT INTO tasks DEFAULT VALUES;

-- Logs table
CREATE TABLE logs (
  "value" INTEGER
);