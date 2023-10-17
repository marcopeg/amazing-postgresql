TRUNCATE TABLE movies_json RESTART IDENTITY;
TRUNCATE TABLE movies_jsonb RESTART IDENTITY;

WITH
  --
  -- Provides seeding configuration as a JSON document for
  -- convenience in affecting the seeding logic.
  --
  "config"("doc") AS (VALUES ('{
    "rows": 1000,
    "release": {
      "min": 1980,
      "max": 2022
    },
    "rating": {
      "min": 1,
      "max": 5
    },
    "production_cost": {
      "min": 50000,
      "max": 200000000
    },
    "revenue": {
      "min": 50000,
      "max": 280000000
    },
    "cast_size": {
      "min": 3,
      "max": 10
    },
    "genre_size": {
      "min": 1,
      "max": 5
    },
    "duration": [
      22,
      30,
      42,
      45,
      60,
      90,
      120,
      180,
      240
    ],
    "tokens": {
      "t1": [
        "atomic",
        "power",
        "frivolous",
        "ephemeral",
        "meticulous",
        "surreal",
        "exuberant",
        "whimsical",
        "stoic",
        "ominous",
        "turbulent",
        "vibrant",
        "luminous",
        "ethereal",
        "opaque",
        "tenacious",
        "audacious",
        "eclectic",
        "sporadic",
        "voracious",
        "capricious",
        "gregarious",
        "inert",
        "taciturn",
        "voluble",
        "sonorous",
        "obtuse",
        "loquacious",
        "ebullient",
        "nebulous",
        "cogent",
        "munificent",
        "facetious",
        "perfunctory",
        "sagacious",
        "indolent",
        "sublime",
        "dubious",
        "amorphous",
        "morose",
        "mellifluous",
        "quixotic",
        "serene",
        "jovial",
        "erudite",
        "arduous",
        "ephemeral",
        "pellucid",
        "laconic",
        "effervescent",
        "verdant"
      ],
      "t2": [
        "warriors",
        "childs",
        "dogs",
        "sailors",
        "kings",
        "queens",
        "knights",
        "soldiers",
        "hunters",
        "wizards",
        "merchants",
        "craftsmen",
        "peasants",
        "rebels",
        "elves",
        "dwarves",
        "heroes",
        "goddesses",
        "villagers",
        "miners",
        "smiths",
        "farmers",
        "pirates",
        "guards",
        "archers",
        "clerics",
        "priests",
        "wanderers",
        "travelers",
        "adventurers",
        "survivors",
        "nomads",
        "vagabonds",
        "ghosts",
        "spirits",
        "poets",
        "thieves",
        "mermaids",
        "huntresses",
        "vampires",
        "barons",
        "wolves",
        "panthers",
        "griffins",
        "dragons",
        "chimeras",
        "phoenixes",
        "titans",
        "goblins",
        "ogres",
        "trolls"
      ],
      "t3": [
        "bewitching",
        "concocting",
        "deciphering",
        "divining",
        "ensnaring",
        "foreboding",
        "gargling",
        "hexing",
        "imbuing",
        "jousting",
        "kindling",
        "lamenting",
        "murmuring",
        "navigating",
        "oscillating",
        "parlaying",
        "quaffing",
        "rummaging",
        "sundering",
        "trespassing",
        "unearthing",
        "vexing",
        "waltzing",
        "yawning",
        "zealoting",
        "anointing",
        "befuddling",
        "conjuring",
        "dissolving",
        "elapsing",
        "festering",
        "gloating",
        "howling",
        "incanting",
        "jumbling",
        "keening",
        "loitering",
        "muttering",
        "nefarating",
        "obfuscating",
        "permeating",
        "quivering",
        "resurrecting",
        "scavenging",
        "tormenting",
        "undulating",
        "vitiating",
        "withering",
        "yearning",
        "zigzagging"
      ],
      "t4": [
        "elixir",
        "grimoire",
        "oblivion",
        "chalice",
        "nether",
        "wraith",
        "phosphor",
        "quasar",
        "vortex",
        "wyrm",
        "sulfur",
        "hemlock",
        "manuscript",
        "talisman",
        "specter",
        "mercury",
        "labyrinth",
        "serpent",
        "cipher",
        "void",
        "zephyr",
        "ether",
        "beacon",
        "dread",
        "relic",
        "plague",
        "bane",
        "myst",
        "cadaver",
        "osmosis",
        "quicksilver",
        "voidance",
        "mire",
        "ichor",
        "cauldron",
        "coven",
        "nexus",
        "doppelganger",
        "chimera",
        "sanguine",
        "phylactery",
        "thunderbolt",
        "stigma",
        "amulet",
        "dystopia",
        "ecliptic",
        "fiend",
        "ghoul",
        "hollow",
        "ignis",
        "jade"
      ]
    },
    "genres": [
      "Action",
      "Adventure",
      "Animation",
      "Biography",
      "Comedy",
      "Crime",
      "Documentary",
      "Drama",
      "Family",
      "Fantasy",
      "Film-Noir",
      "History",
      "Horror",
      "Musical",
      "Mystery",
      "Romance",
      "Sci-Fi",
      "Sport",
      "Thriller",
      "War",
      "Western"
    ],
    "actors": [
      "Tom Hanks",
      "Leonardo DiCaprio",
      "Brad Pitt",
      "Robert Downey Jr.",
      "Scarlett Johansson",
      "Meryl Streep",
      "Denzel Washington",
      "Johnny Depp",
      "Jennifer Lawrence",
      "Will Smith",
      "Christian Bale",
      "Natalie Portman",
      "Harrison Ford",
      "Julia Roberts",
      "Chris Evans",
      "Matt Damon",
      "Emma Stone",
      "Chris Hemsworth",
      "Cate Blanchett",
      "Samuel L. Jackson",
      "Anne Hathaway",
      "Liam Neeson",
      "Charlize Theron",
      "Ryan Gosling",
      "Nicole Kidman",
      "Al Pacino",
      "Morgan Freeman",
      "Kate Winslet",
      "Hugh Jackman",
      "Bradley Cooper",
      "Angelina Jolie",
      "Joaquin Phoenix",
      "Sandra Bullock",
      "Daniel Craig",
      "Amy Adams",
      "Tom Cruise",
      "Viola Davis",
      "Eddie Redmayne",
      "Jessica Chastain",
      "Michael Fassbender",
      "Ethan Hawke",
      "Jake Gyllenhaal",
      "Matthew McConaughey",
      "Keira Knightley",
      "Mark Ruffalo",
      "Emma Watson",
      "Robert De Niro",
      "George Clooney",
      "Reese Witherspoon",
      "Halle Berry"
    ],
    "directors": [
      "Steven Spielberg",
      "Christopher Nolan",
      "Martin Scorsese",
      "Quentin Tarantino",
      "Alfred Hitchcock",
      "Stanley Kubrick",
      "James Cameron",
      "Francis Ford Coppola",
      "Clint Eastwood",
      "Peter Jackson",
      "Ridley Scott",
      "David Fincher",
      "Spike Lee",
      "Wes Anderson",
      "J.J. Abrams"
    ],
    "soundDirectors": [
      "Ben Burtt",
      "Walter Murch",
      "Randy Thom",
      "Gary Rydstrom",
      "Skip Lievsay",
      "Alan Splet",
      "Chris Jenkins",
      "Mark Mangini",
      "Tom Johnson",
      "Christopher Boyes",
      "Andy Nelson",
      "Gregg Landaker",
      "Lora Hirschberg",
      "Paul N.J. Ottosson",
      "Scott Millan"
    ],
    "photographyDirectors": [
      "Roger Deakins",
      "Emmanuel Lubezki",
      "Robert Richardson",
      "Janusz Kamiński",
      "Vittorio Storaro",
      "Hoyte van Hoytema",
      "Robert Elswit",
      "John Toll",
      "Caleb Deschanel",
      "Darius Khondji",
      "Matthew Libatique",
      "Wally Pfister",
      "Dante Spinotti",
      "John Schwartzman",
      "Phedon Papamichael"
    ]
  }'::json))

  --
  -- Explode the configuration object into tabular data that
  -- are convenient to use in further data manipulations.
  --
, "config_params" AS (
  SELECT
    "n"

  -- Rating min/max
  , (SELECT ("doc"->'rating'->>'min')::INT FROM "config") AS "ratingMin"
  , (SELECT ("doc"->'rating'->>'max')::INT FROM "config") AS "ratingMax"

  -- Release min/max
  , (SELECT ("doc"->'release'->>'min')::INT FROM "config") AS "releaseMin"
  , (SELECT ("doc"->'release'->>'max')::INT FROM "config") AS "releaseMax"

  -- Revenue min/max
  , (SELECT ("doc"->'revenue'->>'min')::INT FROM "config") AS "revenueMin"
  , (SELECT ("doc"->'revenue'->>'max')::INT FROM "config") AS "revenueMax"

  -- Production Costs min/max
  , (SELECT ("doc"->'production_cost'->>'min')::INT FROM "config") AS "productionCostMin"
  , (SELECT ("doc"->'production_cost'->>'max')::INT FROM "config") AS "productionCostMax"
  
  -- Genre Size min/max
  , (SELECT ("doc"->'genre_size'->>'min')::INT FROM "config") AS "genreSizeMin"
  , (SELECT ("doc"->'genre_size'->>'max')::INT FROM "config") AS "genreSizeMax"
  
  -- Cast Size min/max
  , (SELECT ("doc"->'cast_size'->>'min')::INT FROM "config") AS "castSizeMin"
  , (SELECT ("doc"->'cast_size'->>'max')::INT FROM "config") AS "castSizeMax"

  -- Title Tokens
  , (SELECT ARRAY(SELECT json_array_elements_text("doc"->'tokens'->'t1')) FROM "config") AS "t1Values"
  , (SELECT ARRAY(SELECT json_array_elements_text("doc"->'tokens'->'t2')) FROM "config") AS "t2Values"
  , (SELECT ARRAY(SELECT json_array_elements_text("doc"->'tokens'->'t3')) FROM "config") AS "t3Values"
  , (SELECT ARRAY(SELECT json_array_elements_text("doc"->'tokens'->'t4')) FROM "config") AS "t4Values"

  -- Other tokens
  , (SELECT ARRAY(SELECT json_array_elements_text("doc"->'duration')) FROM "config") AS "durationValues"
  , (SELECT ARRAY(SELECT json_array_elements_text("doc"->'genres')) FROM "config") AS "genreValues"
  , (SELECT ARRAY(SELECT json_array_elements_text("doc"->'actors')) FROM "config") AS "actorsValues"
  , (SELECT ARRAY(SELECT json_array_elements_text("doc"->'directors')) FROM "config") AS "directorsValues"
  , (SELECT ARRAY(SELECT json_array_elements_text("doc"->'photographyDirectors')) FROM "config") AS "photographyDirectorsValues"
  , (SELECT ARRAY(SELECT json_array_elements_text("doc"->'soundDirectors')) FROM "config") AS "soundDirectorsValues"

  -- Generate a serie of rows as the configuration requires:
  FROM generate_series(1, (SELECT ("doc"->>'rows')::int FROM "config")) "n"
)




  --
  -- Shuffle input arrays 
  -- useful to pick a random number of items
  --
, "randomized_actors" AS (
  SELECT "n", array_agg(elem ORDER BY random()) AS "value"
  FROM "config_params", unnest("actorsValues") AS elem
  GROUP BY "n"
)
, "randomized_genres" AS (
  SELECT "n", array_agg(elem ORDER BY random()) AS "value"
  FROM "config_params", unnest("genreValues") AS elem
  GROUP BY "n"
)


  --
  -- Generate variables
  --
, "variables" AS (
  SELECT *
    -- Genre size
  , floor(random() * ("genreSizeMax" - "genreSizeMin" + 1) + "genreSizeMin")::int AS "genreSize"

    -- Cast size
  , floor(random() * ("castSizeMax" - "castSizeMin" + 1) + "castSizeMin")::int AS "castSize"

  FROM "config_params"
)


  --
  -- Generate tabular data with the proper randomized values
  -- (tabular data is often easier to debug at build time)
  --
, "values" AS (
  SELECT "t1".*

    -- Title
  , CONCAT(
    ("t1Values")[floor(random() * array_length("t1Values", 1) + 1)], ' ',
    ("t2Values")[floor(random() * array_length("t2Values", 1) + 1)], ' ',
    ("t3Values")[floor(random() * array_length("t3Values", 1) + 1)], ' ',
    ("t4Values")[floor(random() * array_length("t4Values", 1) + 1)]
  ) AS "title"

    -- Rating
  , (
      round(
        (random() * ("ratingMax" - "ratingMin" + 1) + "ratingMin") 
        * 100 
      ) / 100
    )::FLOAT AS "rating"

    -- Release
  , (
      round(
        (random() * ("releaseMax" - "releaseMin" + 1) + "releaseMin") 
      )
    )::FLOAT AS "release"

    -- ProductionCost
  , (
      round(
        (random() * ("productionCostMax" - "productionCostMin" + 1) + "productionCostMin") 
        * 100 
      ) / 100
    )::FLOAT AS "productionCost"

    -- Revenue
  , (
      round(
        (random() * ("revenueMax" - "revenueMin" + 1) + "revenueMin") 
        * 100 
      ) / 100
    )::FLOAT AS "revenue"

    -- Duration
  , ("durationValues")[floor(random() * array_length("durationValues", 1) + 1)]::int AS "duration"

    -- Genre items array
  , "t3"."value"[1:"genreSize"] AS "genre"

    -- Cast items array
  , "t2"."value"[1:"castSize"] AS "cast"

    -- Director
  , ("directorsValues")[floor(random() * array_length("directorsValues", 1) + 1)] AS "director"

    -- Director of Photography
  , ("photographyDirectorsValues")[floor(random() * array_length("photographyDirectorsValues", 1) + 1)] AS "photographyDirector"

    -- Director of Sound
  , ("soundDirectorsValues")[floor(random() * array_length("soundDirectorsValues", 1) + 1)] AS "soundDirector"

  FROM "variables" AS "t1"
  JOIN "randomized_actors" AS "t2" ON "t1"."n" = "t2"."n"
  JOIN "randomized_genres" AS "t3" ON "t1"."n" = "t3"."n"
)


  --
  -- Format the generated data into the JSON object
  -- that we want to use in our data model
  --
, "documents" AS (
SELECT 
  json_build_object(
      'title', "title"
    , 'rating', "rating"
    , 'release_date', "release"
    , 'genre', "genre"
    , 'kpis', json_build_object(
        'production_cost', "productionCost"
      , 'revenue', "revenue"
      , 'cast_size', "castSize"
      , 'duration', "duration"
    )
    , 'people', json_build_object(
        'director', "director"
      , 'director_of_photography', "photographyDirector"
      , 'sound_director', "soundDirector"
      , 'cast', "cast"

    )
  ) AS "doc"
  FROM "values"
)


  --
  -- Insert the generated dataset into the target table(s)
  --
, "insert_json" AS (
    INSERT INTO "public"."movies_json" ("data")
    SELECT "doc" FROM "documents"
    ON CONFLICT ON CONSTRAINT "movies_json_pkey" DO NOTHING
    RETURNING *
)

, "insert_jsonb" AS (
    INSERT INTO "public"."movies_jsonb" ("data")
    SELECT "doc" FROM "documents"
    ON CONFLICT ON CONSTRAINT "movies_jsonb_pkey" DO NOTHING
)

--
-- Return a sample:
--
SELECT * FROM "insert_json" LIMIT 1;

