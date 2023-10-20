-- Here is my schema:

CREATE TABLE movies_json (
    id SERIAL PRIMARY KEY,
    data JSON
);

CREATE TABLE movies_jsonb (
    id SERIAL PRIMARY KEY,
    data JSONB
);

-- Here is some seeding data as example:

VALUES
    -- Movie 1
    ('{
        "title": "Inception",
        "rating": 8.8,
        "released": 2010,
        "genre": ["Action", "Adventure", "Sci-Fi"],
        "kpis": {
            "production_cost": 160000000,
            "revenue": 825532764,
            "cast_size": 10,
            "duration": 148
        },
        "people": {
            "director": "Christopher Nolan",
            "director_of_photography": "Wally Pfister",
            "sound_director": "Richard King",
            "cast": ["Leonardo DiCaprio", "Joseph Gordon-Levitt", "Ellen Page"]
        }
    }'),
    -- Movie 2
    ('{
        "title": "The Shawshank Redemption",
        "rating": 9.3,
        "released": 1994,
        "genre": ["Drama"],
        "kpis": {
            "production_cost": 25000000,
            "revenue": 58300000,
            "cast_size": 12,
            "duration": 142
        },
        "people": {
            "director": "Frank Darabont",
            "director_of_photography": "Roger Deakins",
            "sound_director": "Frank E. Eulner",
            "cast": ["Tim Robbins", "Morgan Freeman"]
        }
    }')

-- do not explain me anything
-- just learn this and be ready to build queries together