DROP SCHEMA "public" CASCADE;
CREATE SCHEMA "public";

CREATE TABLE "users" (
  "user_id" INTEGER PRIMARY KEY,
  "user_name" TEXT NOT NULL
);

CREATE TABLE "colors" (
  "color_id" INTEGER PRIMARY KEY,
  "color_name" TEXT NOT NULL
);

CREATE TABLE "pets" (
  "pet_id" INTEGER PRIMARY KEY,
  "pet_name" TEXT NOT NULL
);

INSERT INTO "users" VALUES
(1, 'Alice'),
(2, 'Bob');

INSERT INTO "colors" VALUES
(1, 'Red'),
(2, 'Green'),
(3, 'Blue');

INSERT INTO "pets" VALUES
(1, 'Dog'),
(2, 'Cat'),
(3, 'Sparrow');

SELECT * FROM "users", "colors", "pets";
