-- Seed Data

-- Tenants
INSERT INTO tenants (name) VALUES
('Tenant 1'),
('Tenant 2');

-- Users
INSERT INTO users (tenant_id, username, password_hash) VALUES
(1, 'user1', 'hashed_password1'),
(1, 'user2', 'hashed_password2'),
(2, 'user3', 'hashed_password3');

-- Products
INSERT INTO products (tenant_id, name, price, stock_quantity) VALUES
(1, 'Product A', 10.00, 100),
(1, 'Product B', 20.00, 200),
(2, 'Product C', 30.00, 300),
(2, 'Product D', 40.00, 400);

-- Invoices
INSERT INTO invoices (tenant_id, user_id, created_at) VALUES
(1, 1, '2023-10-23 12:00:00'),
(1, 2, '2023-10-23 13:00:00'),
(2, 3, '2023-10-23 14:00:00');

-- Invoice Items
INSERT INTO invoice_items (invoice_id, product_id, quantity, price) VALUES
(1, 1, 1, 10.00),
(1, 2, 2, 40.00),
(2, 1, 3, 30.00),
(3, 3, 1, 30.00),
(3, 4, 1, 40.00);
