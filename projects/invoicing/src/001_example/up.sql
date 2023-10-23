-- Migration 1: Create basic tables

-- Tenants
CREATE TABLE tenants (
    tenant_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL
);

-- Users
CREATE TABLE users (
    user_id SERIAL PRIMARY KEY,
    tenant_id INT,
    username VARCHAR(255) NOT NULL,
    password_hash VARCHAR(255) NOT NULL
);

-- Products
CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    tenant_id INT,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT NOT NULL
);

-- Invoices
CREATE TABLE invoices (
    invoice_id SERIAL PRIMARY KEY,
    tenant_id INT,
    user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Invoice Items
CREATE TABLE invoice_items (
    invoice_item_id SERIAL PRIMARY KEY,
    invoice_id INT,
    product_id INT,
    quantity INT NOT NULL,
    price DECIMAL(10, 2) NOT NULL
);
