CREATE TABLE "public"."people_v2" (
  "id" TIMESTAMP DEFAULT clock_timestamp(),
  "name" TEXT,
  "surname" TEXT,
  PRIMARY KEY ("id")
);