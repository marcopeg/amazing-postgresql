DROP INDEX IF EXISTS user_date_idx;
CREATE INDEX user_date_idx ON invoices (user_id, date desc);

DROP INDEX IF EXISTS user_amount_id_idx;
CREATE INDEX user_amount_id_idx ON invoices (user_id, amount, id);