CREATE TABLE "public"."accounts" (
  "id" SERIAL,
  "nickname" VARCHAR(50),
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  PRIMARY KEY ("id"),
  CONSTRAINT "un_nickname" UNIQUE ("nickname")
);

CREATE TABLE "public"."profiles" (
  "account_id" INTEGER,
  "name" VARCHAR(50),
  "surname" VARCHAR(50),
  PRIMARY KEY ("account_id"),
  CONSTRAINT "fk_account" FOREIGN KEY("account_id") REFERENCES "accounts"("id")
);

CREATE TABLE "public"."articles" (
  "id" SERIAL,
  "account_id" INTEGER,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  "title" VARCHAR(50),
  "content" TEXT,
  PRIMARY KEY ("id"),
  CONSTRAINT "fk_account" FOREIGN KEY("account_id") REFERENCES "accounts"("id")
);

CREATE TYPE "article_input" AS (
  "title" VARCHAR(50), 
  "content" TEXT
);
