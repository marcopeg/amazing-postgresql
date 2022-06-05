---
--- Public Products View
--- Offers a controlled dataset for public products
---

CREATE MATERIALIZED VIEW "public_products_cached" AS
SELECT
  "p"."id" AS "id",
  "p"."name" AS "name",
  "p"."description" AS "description",
  "p"."price" AS "price",
  "p"."updated_at" AS "updated_at",
  COALESCE("a"."amount", 0) AS "availability_amount",
  COALESCE("a"."updated_at", '1970-01-01') AS "availability_updated_at",
  "t"."id" AS "tenant_id",
  "t"."name" AS "tenant_name"

FROM "public"."products" AS "p"
LEFT JOIN "public"."tenants" AS "t" ON "p"."tenant_id" = "t"."id"
LEFT JOIN "public"."products_availability_cached" AS "a" ON "a"."product_id" = "p"."id"

WHERE "p"."is_visible" IS TRUE;

-- This index allow to refresh this view concurrently
CREATE UNIQUE INDEX "public_products_cached_pk"
ON "public_products_cached" ("id", "tenant_id");




---
--- Single Product View
--- (live data)
---
CREATE VIEW "public_product_view" AS
SELECT
  "t"."id" AS "tenant_id",
  "t"."name" AS "tenant_name",
  "p"."id" AS "id",
  "p"."name" AS "name",
  "p"."description" AS "description",
  "p"."is_visible" AS "is_visible",
  "p"."price" AS "price",
  COALESCE("a"."amount", 0) AS "availability_amount",
  "p"."updated_at" AS "updated_at"
FROM "public"."products" AS "p"
LEFT JOIN "public"."tenants" AS "t" ON "p"."tenant_id" = "t"."id"
LEFT JOIN "public"."products_availability_live" AS "a" ON "a"."product_id" = "p"."id";





---
--- Single Product Function
--- (live data)
---

CREATE TABLE "public"."public_product_type" (
  "tenant_id" TEXT NOT NULL,
  "tenant_name" TEXT NOT NULL,
  "id" TEXT PRIMARY KEY,
  "name" TEXT NOT NULL,
  "description" TEXT,
  "is_visible" BOOLEAN NOT NULL,
  "price" INTEGER NOT NULL,
  "availability" BIGINT NOT NULL,
  "updated_at" TIMESTAMPTZ
);


CREATE OR REPLACE FUNCTION public_product_fn (
  productId TEXT
)
RETURNS SETOF "public"."public_product_type" AS $$
BEGIN
  RETURN QUERY
    -- create a dataset compatible with
    -- "public_product_view"
    SELECT
      "t"."id" AS "tenant_id",
      "t"."name" AS "tenant_name",
      "p"."id" AS "id",
      "p"."name" AS "name",
      "p"."description" AS "description",
      "p"."is_visible" AS "is_visible",
      "p"."price" AS "price",
      COALESCE("a"."amount", 0)::BIGINT AS "availability",
      "p"."updated_at" AS "updated_at"

    -- collect data from live data-sources
    FROM "public"."products" AS "p"
    LEFT JOIN "public"."tenants" AS "t" ON "p"."tenant_id" = "t"."id"
    LEFT JOIN "public"."products_availability_live" AS "a" ON "a"."product_id" = "p"."id"

    -- enforce condition
    WHERE "p"."id" = productId
    LIMIT 1;
END;
$$ LANGUAGE plpgsql STABLE;