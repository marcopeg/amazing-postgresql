SELECT 
  invoices.invoice_id, 
  invoices.created_at,
  invoice_items.invoice_item_id,
  invoice_items.product_id,
  invoice_items.quantity,
  invoice_items.price
FROM invoices
JOIN invoice_items ON invoices.invoice_id = invoice_items.invoice_id
ORDER BY invoices.invoice_id;


SELECT 
  invoices.invoice_id,
  invoices.created_at,
  jsonb_agg(json_build_object(
    'invoice_item_id', invoice_items.invoice_item_id,
    'product_id', invoice_items.product_id,
    'quantity', invoice_items.quantity,
    'price', invoice_items.price
  )) AS invoice_items
FROM invoices
JOIN invoice_items ON invoices.invoice_id = invoice_items.invoice_id
GROUP BY invoices.invoice_id, invoices.created_at
ORDER BY invoices.invoice_id;


SELECT 
  invoices.invoice_id,
  invoices.created_at,
  jsonb_build_object(
    'user_id', users.user_id,
    'username', users.username
  ) AS user_data,
  jsonb_agg(jsonb_build_object(
    'invoice_item_id', invoice_items.invoice_item_id,
    'product_id', invoice_items.product_id,
    'quantity', invoice_items.quantity,
    'price', invoice_items.price
  )) AS invoice_items,
  jsonb_agg(jsonb_build_object(
    'product_id', products.product_id,
    'name', products.name,
    'price', products.price,
    'stock_quantity', products.stock_quantity
  )) AS related_products
FROM invoices
JOIN invoice_items ON invoices.invoice_id = invoice_items.invoice_id
JOIN products ON invoice_items.product_id = products.product_id
JOIN users ON invoices.user_id = users.user_id
GROUP BY invoices.invoice_id, invoices.created_at, users.user_id, users.username
ORDER BY invoices.invoice_id;



SELECT 
  invoices.invoice_id,
  invoices.created_at,
  jsonb_build_object(
    'user_id', users.user_id,
    'username', users.username
  ) AS user_data,
  jsonb_agg(jsonb_build_object(
    'id', invoice_items.invoice_item_id,
    'product', jsonb_build_object(
      'id', products.product_id,
      'name', products.name,
      'price', products.price,
      'stock_quantity', products.stock_quantity
    ),
    'quantity', invoice_items.quantity,
    'price', invoice_items.price
  )) AS invoice_items
FROM invoices
JOIN invoice_items ON invoices.invoice_id = invoice_items.invoice_id
JOIN products ON invoice_items.product_id = products.product_id
JOIN users ON invoices.user_id = users.user_id
GROUP BY invoices.invoice_id, invoices.created_at, users.user_id, users.username
ORDER BY invoices.invoice_id;


CREATE MATERIALIZED VIEW invoices_read AS
SELECT 
  invoices.invoice_id,
  invoices.created_at,
  jsonb_build_object(
    'user_id', users.user_id,
    'username', users.username
  ) AS user_data,
  jsonb_agg(jsonb_build_object(
    'id', invoice_items.invoice_item_id,
    'product', jsonb_build_object(
      'id', products.product_id,
      'name', products.name,
      'price', products.price,
      'stock_quantity', products.stock_quantity
    ),
    'quantity', invoice_items.quantity,
    'price', invoice_items.price,
    'total', invoice_items.quantity::numeric * invoice_items.price::numeric
  )) AS invoice_items,
  SUM(invoice_items.quantity * invoice_items.price) AS invoice_total
FROM invoices
JOIN invoice_items ON invoices.invoice_id = invoice_items.invoice_id
JOIN products ON invoice_items.product_id = products.product_id
JOIN users ON invoices.user_id = users.user_id
GROUP BY invoices.invoice_id, invoices.created_at, users.user_id, users.username
ORDER BY invoices.invoice_id;



CREATE UNIQUE INDEX idx_invoices_read_invoice_id ON invoices_read (invoice_id);
REFRESH MATERIALIZED VIEW CONCURRENTLY invoices_read;






CREATE VIEW invoices_to_json AS
SELECT 
  invoices.invoice_id,
  invoices.created_at,
  jsonb_build_object(
    'user_id', users.user_id,
    'username', users.username
  ) AS user_data,
  jsonb_agg(jsonb_build_object(
    'id', invoice_items.invoice_item_id,
    'product', jsonb_build_object(
      'id', products.product_id,
      'name', products.name,
      'price', products.price,
      'stock_quantity', products.stock_quantity
    ),
    'quantity', invoice_items.quantity,
    'price', invoice_items.price,
    'total', invoice_items.quantity::numeric * invoice_items.price::numeric
  )) AS invoice_items,
  SUM(invoice_items.quantity * invoice_items.price) AS invoice_total
FROM invoices
JOIN invoice_items ON invoices.invoice_id = invoice_items.invoice_id
JOIN products ON invoice_items.product_id = products.product_id
JOIN users ON invoices.user_id = users.user_id
GROUP BY invoices.invoice_id, invoices.created_at, users.user_id, users.username
ORDER BY invoices.invoice_id;



-- Create a table to store invoice details
CREATE TABLE invoices_ro (
  invoice_id INT PRIMARY KEY,
  created_at TIMESTAMP,
  user_data JSONB,
  invoice_items JSONB,
  invoice_total NUMERIC
);


DROP FUNCTION IF EXISTS get_invoice_details(INT);

-- Create a function that calculates invoice details for a specific invoice ID
CREATE OR REPLACE FUNCTION get_invoice_details(invoice_id_param INT) 
RETURNS SETOF invoices_ro  
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    invoices.invoice_id,
    invoices.created_at,
    jsonb_build_object(
      'user_id', users.user_id,
      'username', users.username
    ) AS user_data,
    jsonb_agg(jsonb_build_object(
      'id', invoice_items.invoice_item_id,
      'product', jsonb_build_object(
        'id', products.product_id,
        'name', products.name,
        'price', products.price,
        'stock_quantity', products.stock_quantity
      ),
      'quantity', invoice_items.quantity,
      'price', invoice_items.price,
      'total', invoice_items.quantity::numeric * invoice_items.price::numeric
    )) AS invoice_items,
    SUM(invoice_items.quantity * invoice_items.price) AS invoice_total
  FROM invoices
  JOIN invoice_items ON invoices.invoice_id = invoice_items.invoice_id
  JOIN products ON invoice_items.product_id = products.product_id
  JOIN users ON invoices.user_id = users.user_id
  WHERE invoices.invoice_id = invoice_id_param
  GROUP BY invoices.invoice_id, invoices.created_at, users.user_id, users.username;
END;
$$ LANGUAGE plpgsql;






-- Create a trigger function to refresh the materialized view
CREATE OR REPLACE FUNCTION refresh_invoices_read() 
RETURNS TRIGGER AS $$
BEGIN
  -- REFRESH MATERIALIZED VIEW CONCURRENTLY invoices_read;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- Create a trigger on the invoices table
DROP TRIGGER IF EXISTS trigger_refresh_invoices_read ON invoices;
CREATE TRIGGER trigger_refresh_invoices_read
AFTER INSERT OR UPDATE OR DELETE
ON invoices
FOR EACH ROW
EXECUTE FUNCTION refresh_invoices_read();

-- Create a trigger on the invoice_items table
DROP TRIGGER IF EXISTS trigger_refresh_invoices_read_items ON invoice_items;
CREATE TRIGGER trigger_refresh_invoices_read_items
AFTER INSERT OR UPDATE OR DELETE
ON invoice_items
FOR EACH ROW
EXECUTE FUNCTION refresh_invoices_read();





ALTER TABLE invoice_items
DROP CONSTRAINT IF EXISTS invoice_items_invoice_id_fkey;

ALTER TABLE invoice_items
ADD CONSTRAINT invoice_items_invoice_id_fkey
FOREIGN KEY (invoice_id)
REFERENCES invoices (invoice_id)
ON DELETE CASCADE;


-- Revert the foreign key constraint on invoice_items
ALTER TABLE invoice_items
DROP CONSTRAINT IF EXISTS invoice_items_invoice_id_fkey;

ALTER TABLE invoice_items
ADD CONSTRAINT invoice_items_invoice_id_fkey
FOREIGN KEY (invoice_id)
REFERENCES invoices (invoice_id);





CREATE OR REPLACE FUNCTION refresh_invoices_read() 
RETURNS TRIGGER AS $$
BEGIN

  IF TG_TABLE_NAME = 'invoices' AND TG_OP = 'DELETE' THEN
    -- Elimina dalla tabella invoices_ro l'entry corrispondente all'invoice_id eliminato
    DELETE FROM invoices_ro WHERE invoice_id = OLD.invoice_id;
  ELSE
    -- Esegui un upsert utilizzando il risultato di get_invoice_details con l'invoice_id
    --RAISE EXCEPTION 'Messaggio di errore personalizzato %', OLD.created_at;
    INSERT INTO invoices_ro
    SELECT * FROM get_invoice_details(NEW.invoice_id)
    ON CONFLICT (invoice_id) DO UPDATE SET
      created_at = EXCLUDED.created_at,
      user_data = EXCLUDED.user_data,
      invoice_items = EXCLUDED.invoice_items,
      invoice_total = EXCLUDED.invoice_total;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

