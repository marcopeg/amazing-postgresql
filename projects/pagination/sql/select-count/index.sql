DROP INDEX IF EXISTS user_id_idx;
CREATE INDEX user_id_idx ON invoices (user_id);