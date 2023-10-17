TRUNCATE TABLE movies_json RESTART IDENTITY;
INSERT INTO movies_json (data)
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
    }'),
    -- Movie 3
    ('{
        "title": "The Godfather",
        "rating": 9.2,
        "released": 1972,
        "genre": ["Crime", "Drama"],
        "kpis": {
            "production_cost": 6000000,
            "revenue": 246120974,
            "cast_size": 20,
            "duration": 175
        },
        "people": {
            "director": "Francis Ford Coppola",
            "director_of_photography": "Gordon Willis",
            "sound_director": "Walter Murch",
            "cast": ["Marlon Brando", "Al Pacino", "James Caan"]
        }
    }'),
    -- Movie 4
    ('{
        "title": "Pulp Fiction",
        "rating": 8.9,
        "released": 1994,
        "genre": ["Crime", "Drama"],
        "kpis": {
            "production_cost": 8000000,
            "revenue": 213928762,
            "cast_size": 18,
            "duration": 154
        },
        "people": {
            "director": "Quentin Tarantino",
            "director_of_photography": "Andrzej Sekula",
            "sound_director": "Stephen Hunter Flick",
            "cast": ["John Travolta", "Uma Thurman", "Samuel L. Jackson"]
        }
    }'),
    -- Movie 5
    ('{
        "title": "Fight Club",
        "rating": 8.8,
        "released": 1999,
        "genre": ["Drama"],
        "kpis": {
            "production_cost": 63000000,
            "revenue": 100853753,
            "cast_size": 15,
            "duration": 139
        },
        "people": {
            "director": "David Fincher",
            "director_of_photography": "Jeff Cronenweth",
            "sound_director": "Ren Klyce",
            "cast": ["Brad Pitt", "Edward Norton", "Helena Bonham Carter"]
        }
    }'),
    -- Movie 6
    ('{
        "title": "The Matrix",
        "rating": 8.7,
        "released": 1999,
        "genre": ["Action", "Sci-Fi"],
        "kpis": {
            "production_cost": 63000000,
            "revenue": 463517383,
            "cast_size": 14,
            "duration": 136
        },
        "people": {
            "director": "Lana Wachowski, Lilly Wachowski",
            "director_of_photography": "Bill Pope",
            "sound_director": "Dane A. Davis",
            "cast": ["Keanu Reeves", "Laurence Fishburne", "Carrie-Anne Moss"]
        }
    }'),
    -- Movie 7
    ('{
        "title": "Forrest Gump",
        "rating": 8.8,
        "released": 1994,
        "genre": ["Drama", "Romance"],
        "kpis": {
            "production_cost": 55000000,
            "revenue": 678226133,
            "cast_size": 20,
            "duration": 142
        },
        "people": {
            "director": "Robert Zemeckis",
            "director_of_photography": "Don Burgess",
            "sound_director": "Randy Thom",
            "cast": ["Tom Hanks", "Robin Wright", "Gary Sinise"]
        }
    }'),
    -- Movie 8
    ('{
        "title": "Schindler''s List",
        "rating": 8.9,
        "released": 1993,
        "genre": ["Biography", "Drama", "History"],
        "kpis": {
            "production_cost": 22000000,
            "revenue": 322120058,
            "cast_size": 22,
            "duration": 195
        },
        "people": {
            "director": "Steven Spielberg",
            "director_of_photography": "Janusz Kamiński",
            "sound_director": "Charles L. Campbell",
            "cast": ["Liam Neeson", "Ralph Fiennes", "Ben Kingsley"]
        }
    }')
;