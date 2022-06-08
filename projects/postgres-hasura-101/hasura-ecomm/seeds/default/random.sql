---
--- tenants
---

INSERT INTO "public"."tenants" 
("id", "name")

-- Describe the dataset:
SELECT
  CONCAT('t', "t") AS "id",
  CONCAT('Tenant', "t") AS "name"

-- Set the size of the dataset:
FROM generate_series(1, 10) AS "t"

-- Manage conflicts with existing values:
ON CONFLICT ON CONSTRAINT "tenants_pkey"
DO UPDATE SET "name" = EXCLUDED."name";

COMMIT;



---
--- products
---

INSERT INTO "public"."products" 
("id", "tenant_id", "is_visible", "name", "description", "price")

-- Describe the dataset:
SELECT
  CONCAT('p', "p") AS "id",
  -- randomic tenant_id (t1 .. t10)
  CONCAT('t', floor(random() * (10 - 1 + 1) + 1)) AS "tenant_id",
  -- 25% of the products are set as hidden
  random() > 0.25 AS "is_visible",
  CONCAT('Product', "p") AS "name",
  CONCAT('Description for product', "p") AS "description",
  -- randomic price (10 .. 100)
  floor(random() * (10 - 1 + 1) + 1) * 10 AS "price"

-- Set the size of the dataset:
FROM generate_series(1, 100) AS "p"

-- Manage conflicts with existing values:
ON CONFLICT ON CONSTRAINT "products_pkey"
DO UPDATE SET 
  "tenant_id" = EXCLUDED."tenant_id",
  "name" = EXCLUDED."name",
  "description" = EXCLUDED."description",
  "price" = EXCLUDED."price",
  "is_visible" = EXCLUDED."is_visible";

COMMIT;


---
--- movements
---

INSERT INTO "public"."movements"
  ("tenant_id", "product_id", "created_at", "amount", "note")

SELECT
  "p"."tenant_id",
  "p"."id" AS "product_id",
  -- randomic created_at within the last 30 days
  now() - '30d'::INTERVAL * random() AS "created_at",
  
  -- randomic amount between -50 and 100 units
  floor(random() * (100 + 50 + 1) - 50)::int AS "amount",
  
  '-' AS "description"

FROM (
  SELECT
    -- randomic product_id in range:
    CONCAT('p', floor(random() * ((
      SELECT NULLIF(regexp_replace("id", '\D','','g'), '')::INT
      FROM "public"."products"
      ORDER BY "id" DESC
      LIMIT 1
    ) - 1 + 1) + 1)) AS "product_id"
  FROM generate_series(1, 100) AS "m"
) AS "s"
LEFT JOIN "products" AS "p" ON "p"."id" = "s"."product_id";

COMMIT;


---
--- REFRESH VIEWS
---

REFRESH MATERIALIZED VIEW "products_availability_cached";
REFRESH MATERIALIZED VIEW "public_products_cached";

COMMIT;