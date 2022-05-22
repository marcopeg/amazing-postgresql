-- -- v5
-- INSERT INTO "public"."v5_commands" VALUES ('a', '{}', '2022-05-22 10:30');
-- INSERT INTO "public"."v5_commands" VALUES ('b', '{}', '2022-05-21 10:30');

-- SELECT * FROM "public"."v5_commands"
-- ORDER BY "created_at" ASC;

-- -- v7
-- INSERT INTO "public"."v6_commands" VALUES ('a', '{}', '2022-05-22 10:30');
-- INSERT INTO "public"."v6_commands" VALUES ('b', '{}', '2022-05-21 10:30');

-- SELECT * FROM "public"."v6_commands"
-- ORDER BY "created_at" ASC;

-- v7
DO $$
BEGIN
  INSERT INTO "public"."v7_commands" VALUES ('a', '{}', '2022-05-22 10:30');
  INSERT INTO "public"."v7_commands" VALUES ('a', '{}', '2022-05-22 10:31');
  INSERT INTO "public"."v7_commands" VALUES ('b', '{}', '2022-05-21 10:30');


END $$;

SELECT * FROM "public"."v7_commands"
ORDER BY "created_at" ASC;