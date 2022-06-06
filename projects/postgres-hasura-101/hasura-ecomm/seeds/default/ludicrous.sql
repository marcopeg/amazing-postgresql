---
--- tenants
---

PREPARE "seed_tenants" (
  INT, -- min seed
  INT -- max seed
) AS
INSERT INTO "public"."tenants" 
("id", "name")

-- Describe the dataset:
SELECT
  CONCAT('t', "t") AS "id",
  CONCAT('Tenant', "t") AS "name"

-- Set the size of the dataset:
FROM generate_series($1, $2) AS "t"

-- Manage conflicts with existing values:
ON CONFLICT ON CONSTRAINT "tenants_pkey"
DO UPDATE SET "name" = EXCLUDED."name";



---
--- products
---

PREPARE "seed_products" (
  INT, -- min seed
  INT -- max seed
) AS
INSERT INTO "public"."products" 
("id", "tenant_id", "is_visible", "name", "description", "price")

-- Describe the dataset:
SELECT
  CONCAT('p', "p") AS "id",
  
  -- randomic tenant_id in range:
  CONCAT('t', floor(random() * ((
    SELECT MAX(NULLIF(regexp_replace("id", '\D','','g'), '')::INT)
    FROM "public"."tenants"
  )- 1 + 1) + 1)) AS "tenant_id",
  
  -- 25% of the products are set as hidden
  random() > 0.25 AS "is_visible",
  CONCAT('Product', "p") AS "name",
  CONCAT('Description for product', "p") AS "description",
  -- randomic price (10 .. 100)
  floor(random() * (10 - 1 + 1) + 1) * 10 AS "price"

-- Set the size of the dataset:
FROM generate_series($1, $2) AS "p"

-- Manage conflicts with existing values:
ON CONFLICT ON CONSTRAINT "products_pkey"
DO UPDATE SET 
  "tenant_id" = EXCLUDED."tenant_id",
  "name" = EXCLUDED."name",
  "description" = EXCLUDED."description",
  "price" = EXCLUDED."price",
  "is_visible" = EXCLUDED."is_visible";


---
--- movements
---

PREPARE "seed_movements" (
  INT, -- min seed
  INT -- max seed
) AS
INSERT INTO "public"."movements"
  ("tenant_id", "product_id", "created_at", "amount", "note")
SELECT
  -- randomic tenant_id in range:
  CONCAT('t', floor(random() * ((
    SELECT MAX(NULLIF(regexp_replace("id", '\D','','g'), '')::INT)
    FROM "public"."tenants"
  )- 1 + 1) + 1)) AS "tenant_id",

  -- randomic product_id in range:
  CONCAT('p', floor(random() * ((
    SELECT NULLIF(regexp_replace("id", '\D','','g'), '')::INT
    FROM "public"."products"
    ORDER BY "id" DESC
    LIMIT 1
  ) - 1 + 1) + 1)) AS "product_id",

  -- randomic created_at within the last 30 days
  now() - '30d'::INTERVAL * random() AS "created_at",

  -- randomic amount between -50 and 100 units
  floor(random() * (100 + 50 + 1) - 50)::int AS "amount",

  -- just a dummy note because we set a non null constraint
  '-'
FROM generate_series($1, $2) AS "m";

COMMIT;


---
--- RUN STUFF
---

-- 100K Tenants
EXECUTE "seed_tenants"(1, 50000); COMMIT;
EXECUTE "seed_tenants"(50000, 100000); COMMIT;

-- 5M Products
EXECUTE "seed_products"(1, 1000000); COMMIT;
EXECUTE "seed_products"(1000000, 2000000); COMMIT;
EXECUTE "seed_products"(2000000, 3000000); COMMIT;
EXECUTE "seed_products"(3000000, 4000000); COMMIT;
EXECUTE "seed_products"(4000000, 5000000); COMMIT;

-- 25M Inventory Movements
EXECUTE "seed_movements"(1, 1000000); COMMIT;
EXECUTE "seed_movements"(1000000, 2000000); COMMIT;
EXECUTE "seed_movements"(2000000, 3000000); COMMIT;
EXECUTE "seed_movements"(3000000, 4000000); COMMIT;
EXECUTE "seed_movements"(4000000, 5000000); COMMIT;
EXECUTE "seed_movements"(5000000, 6000000); COMMIT;
EXECUTE "seed_movements"(6000000, 7000000); COMMIT;
EXECUTE "seed_movements"(7000000, 8000000); COMMIT;
EXECUTE "seed_movements"(8000000, 9000000); COMMIT;
EXECUTE "seed_movements"(9000000, 10000000); COMMIT;
EXECUTE "seed_movements"(10000000, 11000000); COMMIT;
EXECUTE "seed_movements"(11000000, 12000000); COMMIT;
EXECUTE "seed_movements"(12000000, 13000000); COMMIT;
EXECUTE "seed_movements"(13000000, 14000000); COMMIT;
EXECUTE "seed_movements"(14000000, 15000000); COMMIT;
EXECUTE "seed_movements"(15000000, 16000000); COMMIT;
EXECUTE "seed_movements"(16000000, 17000000); COMMIT;
EXECUTE "seed_movements"(17000000, 18000000); COMMIT;
EXECUTE "seed_movements"(18000000, 19000000); COMMIT;
EXECUTE "seed_movements"(19000000, 20000000); COMMIT;


---
--- REFRESH VIEWS
---

REFRESH MATERIALIZED VIEW "products_availability_cached";
REFRESH MATERIALIZED VIEW "public_products_cached";

COMMIT;


DEALLOCATE "seed_tenants";
DEALLOCATE "seed_products";
DEALLOCATE "seed_movements";