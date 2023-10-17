TRUNCATE TABLE movies_json RESTART IDENTITY;
INSERT INTO movies_json (data)
SELECT
    json_build_object(
        'title', 'Movie ' || s.num,
        'rating', trunc(random() * 10 * 10) / 10,
        'genre', (SELECT json_agg(genre) FROM (SELECT genre FROM (VALUES ('Action'), ('Adventure'), ('Comedy'), ('Drama'), ('Fantasy'), ('Horror'), ('Mystery'), ('Romance'), ('Sci-Fi'), ('Thriller')) AS g(genre) ORDER BY random() LIMIT 1) AS subquery),
        'kpis', json_build_object(
            'production_cost', trunc(random() * 100000000),
            'revenue', trunc(random() * 1000000000),
            'cast_size', trunc(random() * 20) + 1,
            'duration', trunc(random() * 200) + 60
        ),
        'people', json_build_object(
            'director', 'Director ' || s.num,
            'director_of_photography', 'DP ' || s.num,
            'sound_director', 'Sound ' || s.num,
            'cast', (SELECT json_agg(actor) FROM (SELECT actor FROM (VALUES ('Tom Hanks'), ('Leonardo DiCaprio'), ('Brad Pitt'), ('Robert Downey Jr.'), ('Scarlett Johansson'), ('Meryl Streep'), ('Denzel Washington'), ('Johnny Depp'), ('Jennifer Lawrence'), ('Will Smith'), ('Christian Bale'), ('Natalie Portman'), ('Harrison Ford'), ('Julia Roberts'), ('Chris Evans'), ('Matt Damon'), ('Emma Stone'), ('Chris Hemsworth'), ('Cate Blanchett'), ('Samuel L. Jackson'), ('Anne Hathaway'), ('Liam Neeson'), ('Charlize Theron'), ('Ryan Gosling'), ('Nicole Kidman'), ('Al Pacino'), ('Morgan Freeman'), ('Kate Winslet'), ('Hugh Jackman'), ('Bradley Cooper'), ('Angelina Jolie'), ('Joaquin Phoenix'), ('Sandra Bullock'), ('Daniel Craig'), ('Amy Adams'), ('Tom Cruise'), ('Viola Davis'), ('Eddie Redmayne'), ('Jessica Chastain'), ('Michael Fassbender'), ('Ethan Hawke'), ('Jake Gyllenhaal'), ('Matthew McConaughey'), ('Keira Knightley'), ('Mark Ruffalo'), ('Emma Watson')) AS a(actor) ORDER BY random() LIMIT trunc(random() * 5) + 1) AS subquery)
        )
    )
FROM generate_series(1, 10000) AS s(num);


TRUNCATE TABLE movies_jsonb RESTART IDENTITY;
INSERT INTO movies_jsonb (data)
SELECT
    json_build_object(
        'title', 'Movie ' || s.num,
        'rating', trunc(random() * 10 * 10) / 10,
        'genre', (SELECT json_agg(genre) FROM (SELECT genre FROM (VALUES ('Action'), ('Adventure'), ('Comedy'), ('Drama'), ('Fantasy'), ('Horror'), ('Mystery'), ('Romance'), ('Sci-Fi'), ('Thriller')) AS g(genre) ORDER BY random() LIMIT 1) AS subquery),
        'kpis', json_build_object(
            'production_cost', trunc(random() * 100000000),
            'revenue', trunc(random() * 1000000000),
            'cast_size', trunc(random() * 20) + 1,
            'duration', trunc(random() * 200) + 60
        ),
        'people', json_build_object(
            'director', 'Director ' || s.num,
            'director_of_photography', 'DP ' || s.num,
            'sound_director', 'Sound ' || s.num,
            'cast', (SELECT json_agg(actor) FROM (SELECT actor FROM (VALUES ('Tom Hanks'), ('Leonardo DiCaprio'), ('Brad Pitt'), ('Robert Downey Jr.'), ('Scarlett Johansson'), ('Meryl Streep'), ('Denzel Washington'), ('Johnny Depp'), ('Jennifer Lawrence'), ('Will Smith'), ('Christian Bale'), ('Natalie Portman'), ('Harrison Ford'), ('Julia Roberts'), ('Chris Evans'), ('Matt Damon'), ('Emma Stone'), ('Chris Hemsworth'), ('Cate Blanchett'), ('Samuel L. Jackson'), ('Anne Hathaway'), ('Liam Neeson'), ('Charlize Theron'), ('Ryan Gosling'), ('Nicole Kidman'), ('Al Pacino'), ('Morgan Freeman'), ('Kate Winslet'), ('Hugh Jackman'), ('Bradley Cooper'), ('Angelina Jolie'), ('Joaquin Phoenix'), ('Sandra Bullock'), ('Daniel Craig'), ('Amy Adams'), ('Tom Cruise'), ('Viola Davis'), ('Eddie Redmayne'), ('Jessica Chastain'), ('Michael Fassbender'), ('Ethan Hawke'), ('Jake Gyllenhaal'), ('Matthew McConaughey'), ('Keira Knightley'), ('Mark Ruffalo'), ('Emma Watson')) AS a(actor) ORDER BY random() LIMIT trunc(random() * 5) + 1) AS subquery)
        )
    )
FROM generate_series(1, 10000) AS s(num);