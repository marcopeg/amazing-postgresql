BEGIN;

---
--- Truncate Tables
---

TRUNCATE public.users RESTART IDENTITY CASCADE;
TRUNCATE public.tenants RESTART IDENTITY CASCADE;



---
--- Disable Constraints & Indexes
---

ALTER TABLE ONLY public.orders_lines DROP CONSTRAINT orders_lines_pkey;
ALTER TABLE ONLY public.orders_lines DROP CONSTRAINT orders_lines_user_id_fkey;
ALTER TABLE ONLY public.orders_lines DROP CONSTRAINT orders_lines_tenant_id_fkey;
ALTER TABLE ONLY public.orders_lines DROP CONSTRAINT orders_lines_product_id_fkey;
ALTER TABLE ONLY public.orders_lines DROP CONSTRAINT orders_lines_order_id_fkey;

ALTER TABLE ONLY public.orders DROP CONSTRAINT orders_pkey;
ALTER TABLE ONLY public.orders DROP CONSTRAINT orders_user_id_fkey;

ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;

DROP INDEX movements_product_id_idx;
ALTER TABLE ONLY public.movements DROP CONSTRAINT movements_product_id_fkey;
ALTER TABLE ONLY public.movements DROP CONSTRAINT movements_tenant_id_fkey;
ALTER TABLE ONLY public.movements DROP CONSTRAINT movements_pkey;

DROP INDEX products_is_visible;
ALTER TABLE ONLY public.products DROP CONSTRAINT products_pkey;
ALTER TABLE ONLY public.products DROP CONSTRAINT products_tenant_id_fkey;
DROP TRIGGER set_public_products_updated_at ON public.products;

ALTER TABLE ONLY public.tenants DROP CONSTRAINT tenants_pkey;



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
FROM generate_series(1, 2500) AS "t";

-- Enable Constraints & Indexes
ALTER TABLE ONLY public.tenants ADD CONSTRAINT tenants_pkey PRIMARY KEY (id);



---
--- products
---

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
FROM generate_series(1, 250000) AS "p";

-- Enable Constraints & Indexes
ALTER TABLE ONLY public.products ADD CONSTRAINT products_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.products ADD CONSTRAINT products_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON UPDATE CASCADE ON DELETE CASCADE;
CREATE INDEX products_is_visible ON public.products USING btree (is_visible) WHERE (is_visible = true);
CREATE TRIGGER set_public_products_updated_at BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.set_current_timestamp_updated_at();




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
  FROM generate_series(1, 2500000) AS "m"
) AS "s"
LEFT JOIN "products" AS "p" ON "p"."id" = "s"."product_id";

--- Enable Constraints & Indexes
ALTER TABLE ONLY public.movements ADD CONSTRAINT movements_pkey PRIMARY KEY (id);
ALTER TABLE ONLY public.movements ADD CONSTRAINT movements_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY public.movements ADD CONSTRAINT movements_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES public.tenants(id) ON UPDATE CASCADE ON DELETE CASCADE;
CREATE INDEX movements_product_id_idx ON public.movements USING btree (product_id);

-- COMMIT;



---
--- users
---

--- Enable Constraints & Indexes
ALTER TABLE ONLY "public"."users" ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");

---
--- orders
---

ALTER TABLE ONLY "public"."orders" ADD CONSTRAINT "orders_pkey" PRIMARY KEY ("id");
ALTER TABLE ONLY "public"."orders" ADD CONSTRAINT "orders_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;

---
--- orders_lines
---

--- Enable Constraints & Indexes
ALTER TABLE ONLY "public"."orders_lines" ADD CONSTRAINT "orders_lines_pkey" PRIMARY KEY ("order_id", "product_id");
ALTER TABLE ONLY "public"."orders_lines" ADD CONSTRAINT "orders_lines_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY "public"."orders_lines" ADD CONSTRAINT "orders_lines_tenant_id_fkey" FOREIGN KEY ("tenant_id") REFERENCES "public"."tenants"("id") ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY "public"."orders_lines" ADD CONSTRAINT "orders_lines_product_id_fkey" FOREIGN KEY ("product_id") REFERENCES "public"."products"("id") ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE ONLY "public"."orders_lines" ADD CONSTRAINT "orders_lines_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "public"."orders"("id") ON UPDATE CASCADE ON DELETE CASCADE;






---
--- REFRESH VIEWS
---

REFRESH MATERIALIZED VIEW "products_availability_cached";
REFRESH MATERIALIZED VIEW "public_products_cached";

END;