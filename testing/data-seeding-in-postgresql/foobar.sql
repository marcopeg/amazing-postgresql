
create table if not exists random_users (
    user_id int,
    user_name text
);



CREATE OR REPLACE FUNCTION "populate"(
  PAR_limit INT
) 
RETURNS SETOF "random_users"
AS $$
BEGIN
  
    return query 
    select
        user_id,
        CONCAT(
            'marco',
            '_',
            floor(random() * ((
                (10 + 1) * 365
            ) - (
                10 * 365
            ) + 1) + (
                10 * 365
            ))::int
        ) AS "user_name"
    from generate_series(1, PAR_limit) user_id;


END; $$
LANGUAGE plpgsql
VOLATILE;


select * from populate(5);