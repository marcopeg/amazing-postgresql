-- Define a simple data structure:
DROP TABLE IF EXISTS "users";
CREATE TABLE "users" (
  "id" SERIAL PRIMARY KEY,
  "name" TEXT NOT NULL UNIQUE, -- extremely high cardinality
  "gender" TEXT NOT NULL, -- extremely low cardinality
  "date_of_birth" DATE NOT NULL, -- extremely high cardinality
  "favourite_color" TEXT, -- high(er) cardinality
  "favourite_number" INTEGER -- extremely high cardinality
);
