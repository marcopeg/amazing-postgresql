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
  "created_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  "updated_at" TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  "is_paid" BOOLEAN NOT NULL DEFAULT FALSE,
  "products" JSONB,
  "amount" INTEGER NOT NULL DEFAULT 0
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