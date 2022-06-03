REFRESH MATERIALIZED VIEW "products_availability_cached";

CREATE MATERIALIZED VIEW "products_public_cached" AS
SELECT
  "t"."id" AS "tenant_id",
  "t"."name" AS "tenant_name",
  "p"."id" AS "product_id",
  "p"."name" AS "name",
  "p"."description" AS "description",
  "p"."price" AS "price",
  COALESCE("a"."amount", 0) AS "availability_amount",
  COALESCE("a"."updated_at", '1970-01-01') AS "availability_updated_at",
  "p"."updated_at" AS "updated_at"

FROM "public"."products" AS "p"
LEFT JOIN "public"."tenants" AS "t" ON "p"."tenant_id" = "t"."id"
LEFT JOIN "public"."products_availability_cached" AS "a" ON "a"."product_id" = "p"."id"

WHERE "p"."is_visible" IS TRUE;

-- This index allow to refresh this view concurrently
CREATE UNIQUE INDEX "products_public_cached_pk"
ON "products_public_cached" ("product_id", "tenant_id");
