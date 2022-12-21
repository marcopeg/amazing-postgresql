INSERT INTO "v1"."users" VALUES
  ('Luke')
, ('Darth')
, ('Ian')
, ('Leia')
;

INSERT INTO "v1"."orders" VALUES
  ( 'Luke',  100, now() - '2d'::interval,  'This order should be visible')
, ( 'Luke',   90, now() - '20m'::interval, 'This order should be visible')
, ( 'Luke',  190, now() - '5d'::interval,  'This order should be visible')
, ( 'Luke',  230, now() - '3d'::interval,  'This order should be visible')
, ( 'Luke',  200, now() - '10d'::interval, 'This one should not')
, ( 'Darth', 130, now() - '5d'::interval,  'This order should be visible')
, ( 'Darth', 100, now() - '3d'::interval,  'This order should be visible')
, ( 'Darth', 80,  now() - '1d'::interval,  'This order should be visible')
, ( 'Darth', 180, now() - '2d'::interval,  'This order should be visible')
, ( 'Darth', 40,  now() - '4d'::interval,  'This order should be visible')
, ( 'Darth', 20,  now() - '30d'::interval, 'This one should not')
, ( 'Ian',   130, now() - '5d'::interval,  'This one should be visible')
, ( 'Ian',   130, now() - '5y'::interval,  'This one should not')
;