-- Down Migration 2: Remove foreign keys and constraints

-- Invoice Items
ALTER TABLE invoice_items DROP CONSTRAINT IF EXISTS invoice_items_invoice_id_fkey;
ALTER TABLE invoice_items DROP CONSTRAINT IF EXISTS invoice_items_product_id_fkey;

-- Invoices
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_tenant_id_fkey;
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_user_id_fkey;

-- Products
ALTER TABLE products DROP CONSTRAINT IF EXISTS products_tenant_id_fkey;

-- Users
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_tenant_id_fkey;
