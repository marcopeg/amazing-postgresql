ALTER TABLE "invoice_items" SET UNLOGGED;
ALTER TABLE "invoices" SET UNLOGGED;
ALTER TABLE "products" SET UNLOGGED;
ALTER TABLE "users" SET UNLOGGED;
ALTER TABLE "tenants" SET UNLOGGED;

-- Generate X Tenants
INSERT INTO "tenants" ("name")
SELECT concat('Tenant-', n)
FROM generate_series(1, 1000) "n";

-- For 80% of Tenants, generate 1-5 Users
DO $$ 
DECLARE 
  tenant_row tenants%ROWTYPE;
  i integer;
BEGIN 
  FOR tenant_row IN (
    SELECT * FROM tenants
    ORDER BY random()
    LIMIT (SELECT floor(0.8 * count(*)) FROM "tenants")
  ) 
  LOOP
    INSERT INTO users (tenant_id, username, password_hash) 
    SELECT
      tenant_row.tenant_id,
      concat('User-', tenant_row.tenant_id, '-', n),
      md5(random()::text)
    FROM generate_series(1, floor(random() * 5 + 1)::int) n;
  END LOOP;
END $$;


-- Generate X Products with a randomic Tenant
WITH
"randomized_tenants_list" AS (
  SELECT array_agg(tenant_id) AS "items"
  FROM (
    SELECT "tenant_id" 
    FROM "tenants"
    ORDER BY random()
    LIMIT (SELECT floor(0.8 * count(*)) FROM "tenants")
  ) sub
),
"randomized_tenant_id" AS (
  SELECT 
    "product_id",
    "items"[1 + floor(random() * array_length("items", 1))::integer] AS tenant_id
  FROM generate_series(1, 250000) product_id, "randomized_tenants_list"
)
INSERT INTO "products" ("tenant_id", "name", "price", "stock_quantity")
SELECT
  "tenant_id",
  concat('Product-', product_id, '-', tenant_id) AS "name",
  cast(floor((random() * 100 + 10) * 100) / 100 as decimal(10,2)) AS "price",
  floor(random() * 100 + 1) AS "stock_quantity"
FROM "randomized_tenant_id";


-- Generate X Invoices associated to a randomic User
-- Invoice created within the last 5 years
WITH
"randomized_users_list" AS (
  SELECT array_agg(user_id) AS "items"
  FROM (
    SELECT "user_id" 
    FROM "users"
    ORDER BY random()
    LIMIT (SELECT floor(0.8 * count(*)) FROM "users")
  ) sub
),
"randomized_user_id" AS (
  SELECT 
    "product_id",
    "items"[1 + floor(random() * array_length("items", 1))::integer] AS user_id
  FROM generate_series(1, 500000) product_id, "randomized_users_list"
)
INSERT INTO "invoices" ("tenant_id", "user_id", "created_at")
SELECT
  (SELECT "tenant_id" FROM "users" WHERE "user_id" = "r"."user_id" ),
  "user_id",
  NOW() - INTERVAL '1 day' * floor(random() * (365 * 5)) AS "created_at"
FROM "randomized_user_id" AS "r";

-- Generate 0-25 InvoiceItems associated with a randomic Product
-- The price should be +/- 25% of the Product's price
INSERT INTO "invoice_items" ("invoice_id", "product_id", "quantity", "price")
SELECT 
  i.invoice_id, 
  p.product_id,
  floor(random() * 10 + 1),
  p.price * (1 + (random() - 0.5) * 0.5)
FROM invoices i
JOIN LATERAL (
  SELECT product_id, price 
  FROM products 
  WHERE tenant_id = i.tenant_id 
  ORDER BY random() 
  LIMIT (floor(random() * (26))::integer)
) AS p ON true;


ALTER TABLE "tenants" SET LOGGED;
ALTER TABLE "users" SET LOGGED;
ALTER TABLE "products" SET LOGGED;
ALTER TABLE "invoices" SET LOGGED;
ALTER TABLE "invoice_items" SET LOGGED;