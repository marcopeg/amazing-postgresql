CREATE INDEX user_id_idx ON invoices (user_id);
CREATE INDEX product_id_idx ON invoices (product_id);
CREATE INDEX date_idx ON invoices (date);

CREATE INDEX user_id_id_idx ON invoices (user_id, id asc);
CREATE INDEX user_date_idx ON invoices (user_id, date desc);
CREATE INDEX user_amount_id_idx ON invoices (user_id, amount, id);