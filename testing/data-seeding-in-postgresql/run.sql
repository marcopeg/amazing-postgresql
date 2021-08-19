WITH
  -- Generate a list of random numbers:
  "randomic_data" AS (
    SELECT floor(random() * 10 + 1)AS "rand"
    FROM generate_series(1,10) "id"
  )

  -- Use the row-by-row randomic number to compose
  -- realistic user information:
, "user_data" AS (
    SELECT
      -- randomic username
        (
          CONCAT(
            'user_',
            TO_CHAR(NOW() - INTERVAL '1y' * "rand" ,'YY')
          )
        ) AS "uname"

      -- randomic year of birth
      , DATE_TRUNC(
        'day',
        NOW() - INTERVAL '1d' * (
          floor(random() * ((
            ("rand" + 1) * 365
          ) - (
            "rand" * 365
          ) + 1) + (
            "rand" * 365
          ))::int
        )
      ) AS "bday"

    -- Also provide the simple age:
    , "rand" AS "age"

    -- Source values from the randomic list
    FROM "randomic_data"
  )

-- Eventually, use the generated dataset to populate a table
SELECT * FROM "user_data"
;