---
--- tenants
---

CREATE TABLE IF NOT EXISTS "public"."tenants" (
  "id" TEXT,
  "name" TEXT NOT NULL,
  CONSTRAINT "tenants_pkey" PRIMARY KEY ("id")
);



---
--- products
---

CREATE TABLE IF NOT EXISTS "public"."products" (
  "id" TEXT NOT NULL,
  "tenant_id" TEXT NOT NULL,
  "is_visible" BOOLEAN DEFAULT TRUE NOT NULL,
  "name" TEXT NOT NULL,
  "description" TEXT DEFAULT '',
  "price" INTEGER NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  "updated_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  CONSTRAINT "products_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "public"."products" DROP CONSTRAINT IF EXISTS "products_price_check";
ALTER TABLE "public"."products"
ADD CONSTRAINT "products_price_check"
CHECK (price > 0);

ALTER TABLE "public"."products" DROP CONSTRAINT IF EXISTS "products_tenant_id_fkey";
ALTER TABLE ONLY "public"."products"
ADD CONSTRAINT "products_tenant_id_fkey"
FOREIGN KEY (tenant_id) REFERENCES tenants(id)
ON UPDATE CASCADE
ON DELETE CASCADE
NOT DEFERRABLE;

CREATE OR REPLACE FUNCTION "public"."set_current_timestamp_updated_at"()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW."updated_at" = NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS "set_public_products_updated_at" ON "public"."products";
CREATE TRIGGER "set_public_products_updated_at"
BEFORE UPDATE ON "public"."products"
FOR EACH ROW EXECUTE FUNCTION "public"."set_current_timestamp_updated_at"();



---
--- movements
---

CREATE SEQUENCE IF NOT EXISTS "movements_id_seq"
INCREMENT 1 
MINVALUE 1 
MAXVALUE 2147483647 
CACHE 1;

CREATE TABLE IF NOT EXISTS "public"."movements" (
  "id" INTEGER NOT NULL DEFAULT nextval('movements_id_seq'),
  "tenant_id" TEXT NOT NULL,
  "product_id" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  "amount" INTEGER NOT NULL,
  "note" TEXT NOT NULL,
  CONSTRAINT "movements_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "public"."movements" DROP CONSTRAINT IF EXISTS "movements_tenant_id_fkey";
ALTER TABLE ONLY "public"."movements"
ADD CONSTRAINT "movements_tenant_id_fkey"
FOREIGN KEY (tenant_id) REFERENCES tenants(id)
ON UPDATE CASCADE
ON DELETE CASCADE
NOT DEFERRABLE;

ALTER TABLE "public"."movements" DROP CONSTRAINT IF EXISTS "movements_product_id_fkey";
ALTER TABLE ONLY "public"."movements"
ADD CONSTRAINT "movements_product_id_fkey"
FOREIGN KEY (product_id) REFERENCES products(id)
ON UPDATE CASCADE
ON DELETE CASCADE
NOT DEFERRABLE;


---
--- Availability View
---

CREATE VIEW "public"."products_availability_live" AS
SELECT "product_id", sum("amount") AS "amount"
FROM "movements"
GROUP BY "product_id";

CREATE MATERIALIZED VIEW "public"."products_availability_cached" AS
SELECT 
  "product_id", 
  sum("amount") AS "amount",
  now() AS "updated_at"
FROM "movements"
GROUP BY "product_id";

CREATE VIEW "public"."products_display" AS
SELECT
  "p"."id",
  "p"."tenant_id",
  "p"."name",
  "p"."description",
  "p"."price",
  "a"."amount",
  "p"."created_at",
  "p"."updated_at"
FROM "products_availability_live" AS "a"
LEFT JOIN "products" AS "p" ON "p"."id" = "a"."product_id"
WHERE "p"."is_visible" IS TRUE
  AND "a"."amount" > 0;



---
--- Performance Optimization
---

DROP INDEX IF EXISTS "movements_product_id_idx";
CREATE INDEX "movements_product_id_idx"
ON "movements" ("product_id" ASC);
