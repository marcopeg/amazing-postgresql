BEGIN;

-- Import pgTAP
SELECT plan(2);

-- Insert data for the first test
INSERT INTO tenants (name) VALUES
('Tenant 1'),
('Tenant 2');

-- Users
INSERT INTO users (tenant_id, username, password_hash) VALUES
(1, 'user1', 'hashed_password1'),
(1, 'user2', 'hashed_password2'),
(2, 'user3', 'hashed_password3');


-- First Test: Check if tenant "foobar" exists
SELECT results_eq(
  'SELECT name::text FROM tenants WHERE name = $$Tenant 1$$',
  ARRAY['Tenant 1']::text[],
  'Tenants table should have a tenant with name Tenant 1'
);

-- Second Test: Attempt to delete tenant with tenant_id = 1 should fail
SELECT throws_ok(
  $$
    DELETE FROM tenants WHERE tenant_id = 1
  $$,
  '23503',
  'update or delete on table "tenants" violates foreign key constraint "users_tenant_id_fkey" on table "users"',
  'Should fail to delete a tenant with referenced data'
);
-- SELECT throws_ok(
--   $$ DELETE FROM tenants WHERE tenant_id = 1 $$,
--   'users_tenant_id_fkey',
--   'Deleting tenant with tenant_id 1 should fail due to foreign key constraints'
-- );

-- Finish the tests and clean up
SELECT * FROM finish();

ROLLBACK;
