DROP SCHEMA "public" CASCADE;
CREATE SCHEMA "public";

CREATE TABLE invoice (
  invoice_id INTEGER PRIMARY KEY,
  customer TEXT,
  invoice_date DATE
);

CREATE TABLE lines (
  line_id INTEGER PRIMARY KEY,
  invoice_id INTEGER,
  product TEXT,
  quantity INTEGER
);

INSERT INTO invoice (invoice_id, customer, invoice_date) VALUES
(1, 'Alice', '2022-01-01'),
(2, 'Bob', '2022-01-02'),
(3, 'Charlie', '2022-01-03');

INSERT INTO lines (line_id, invoice_id, product, quantity) VALUES
(1, 1, 'Apple', 1),
(2, 1, 'Banana', 2),
(3, 2, 'Cherry', 1),
(4, 2, 'Date', 3);

SELECT *
FROM invoice
NATURAL JOIN lines;