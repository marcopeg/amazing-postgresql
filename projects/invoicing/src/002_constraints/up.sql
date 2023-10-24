-- Migration 2: Add foreign keys and constraints

-- Users
ALTER TABLE users
ADD FOREIGN KEY (tenant_id)
REFERENCES tenants(tenant_id);

-- Products
ALTER TABLE products
ADD FOREIGN KEY (tenant_id)
REFERENCES tenants(tenant_id);

-- Invoices
ALTER TABLE invoices
ADD FOREIGN KEY (tenant_id)
REFERENCES tenants(tenant_id);
ALTER TABLE invoices
ADD FOREIGN KEY (user_id)
REFERENCES users(user_id);

-- Invoice Items
ALTER TABLE invoice_items
ADD FOREIGN KEY (invoice_id)
REFERENCES invoices(invoice_id);
ALTER TABLE invoice_items
ADD FOREIGN KEY (product_id)
REFERENCES products(product_id);
