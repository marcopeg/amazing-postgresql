CREATE TABLE IF NOT EXISTS "public"."books" (
  "id" UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  "title" TEXT NOT NULL,
  "created_at" TIMESTAMP WITH TIME ZONE DEFAULT clock_timestamp()
);