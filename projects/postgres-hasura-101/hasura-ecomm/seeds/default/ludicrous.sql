BEGIN;

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
FROM generate_series($1, $2) AS "t";



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
FROM generate_series($1, $2) AS "p";


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
  FROM generate_series($1, $2) AS "m"
) AS "s"
LEFT JOIN "products" AS "p" ON "p"."id" = "s"."product_id";

COMMIT;



---
--- Truncate Tables
---

TRUNCATE public.tenants RESTART IDENTITY CASCADE;
TRUNCATE public.users RESTART IDENTITY CASCADE;
TRUNCATE public.orders RESTART IDENTITY CASCADE;





---
--- Disable Constraints & Indexes
---

DROP INDEX movements_product_id_idx;
ALTER TABLE ONLY public.movements DROP CONSTRAINT movements_product_id_fkey;
ALTER TABLE ONLY public.movements DROP CONSTRAINT movements_tenant_id_fkey;
ALTER TABLE ONLY public.movements DROP CONSTRAINT movements_pkey;

ALTER TABLE ONLY public.products DROP CONSTRAINT products_pkey;
ALTER TABLE ONLY public.products DROP CONSTRAINT products_tenant_id_fkey;
DROP INDEX products_is_visible;
DROP TRIGGER set_public_products_updated_at ON public.products;

ALTER TABLE ONLY public.tenants DROP CONSTRAINT tenants_pkey;





---
--- RUN STUFF
---

-- 100K Tenants
EXECUTE "seed_tenants"(1, 50000); COMMIT;
EXECUTE "seed_tenants"(50000, 100000); COMMIT;

-- Enable Constraints & Indexes
ALTER TABLE ONLY public.tenants ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);
COMMIT;

-- 5M Products
EXECUTE "seed_products"(1, 1000000); COMMIT;
EXECUTE "seed_products"(1000000, 2000000); COMMIT;
EXECUTE "seed_products"(2000000, 3000000); COMMIT;
EXECUTE "seed_products"(3000000, 4000000); COMMIT;
EXECUTE "seed_products"(4000000, 5000000); COMMIT;

-- Enable Constraints & Indexes
ALTER TABLE ONLY public.products ADD CONSTRAINT products_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.products ADD CONSTRAINT products_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON UPDATE CASCADE ON DELETE CASCADE;
CREATE INDEX products_is_visible ON public.products USING btree (is_visible) WHERE (is_visible = true);
CREATE TRIGGER set_public_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();
COMMIT;

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

--- Enable Constraints & Indexes
ALTER TABLE ONLY public.movements ADD CONSTRAINT movements_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.movements ADD CONSTRAINT movements_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.movements ADD CONSTRAINT movements_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON UPDATE CASCADE ON DELETE CASCADE;
CREATE INDEX movements_product_id_idx ON public.movements USING btree (product_id);
COMMIT;


---
--- REFRESH VIEWS
---

REFRESH MATERIALIZED VIEW "products_availability_cached";
REFRESH MATERIALIZED VIEW "public_products_cached";

COMMIT;


DEALLOCATE "seed_tenants";
DEALLOCATE "seed_products";
DEALLOCATE "seed_movements";

END;