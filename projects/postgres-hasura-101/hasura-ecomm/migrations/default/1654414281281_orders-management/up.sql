---
--- Users
---

CREATE TABLE IF NOT EXISTS "public"."users" (
  "id" TEXT NOT NULL,
  "name" TEXT NOT NULL
);

-- Primary Key
ALTER TABLE ONLY "public"."users"
ADD CONSTRAINT "users_pkey" PRIMARY KEY ("id");



---
--- Shopping Cart
---

CREATE TABLE IF NOT EXISTS "public"."orders" (
  "id" SERIAL,
  "user_id" TEXT,
  "is_paid" BOOLEAN NOT NULL DEFAULT FALSE,
  "total" INTEGER NOT NULL DEFAULT 0,
  "created_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  "updated_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Primary Key
ALTER TABLE ONLY "public"."orders"
ADD CONSTRAINT "orders_pkey" PRIMARY KEY ("id");

-- Foreign Keys
ALTER TABLE ONLY "public"."orders"
ADD CONSTRAINT "orders_user_id_fkey" 
    FOREIGN KEY ("user_id") 
    REFERENCES "public"."users"("id") 
    ON UPDATE CASCADE 
    ON DELETE CASCADE;



---
--- Shopping Cart Lines
---

CREATE TABLE IF NOT EXISTS "public"."orders_lines" (
  "user_id" TEXT,
  "tenant_id" TEXT,
  "product_id" TEXT,
  "order_id" INT,
  "units" INTEGER NOT NULL DEFAULT 1,
  "price" INTEGER NOT NULL,
  "name" TEXT NOT NULL,
  "created_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  "updated_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Primary Key
ALTER TABLE ONLY "public"."orders_lines"
ADD CONSTRAINT "orders_lines_pkey" 
PRIMARY KEY ("order_id", "product_id");

-- Foreign Keys
ALTER TABLE ONLY "public"."orders_lines"
ADD CONSTRAINT "orders_lines_user_id_fkey" 
    FOREIGN KEY ("user_id") 
    REFERENCES "public"."users"("id") 
    ON UPDATE CASCADE 
    ON DELETE CASCADE;

ALTER TABLE ONLY "public"."orders_lines"
ADD CONSTRAINT "orders_lines_tenant_id_fkey" 
    FOREIGN KEY ("tenant_id") 
    REFERENCES "public"."tenants"("id") 
    ON UPDATE CASCADE 
    ON DELETE CASCADE;

ALTER TABLE ONLY "public"."orders_lines"
ADD CONSTRAINT "orders_lines_product_id_fkey" 
    FOREIGN KEY ("product_id") 
    REFERENCES "public"."products"("id") 
    ON UPDATE CASCADE 
    ON DELETE CASCADE;

ALTER TABLE ONLY "public"."orders_lines"
ADD CONSTRAINT "orders_lines_order_id_fkey" 
    FOREIGN KEY ("order_id") 
    REFERENCES "public"."orders"("id") 
    ON UPDATE CASCADE 
    ON DELETE CASCADE;

