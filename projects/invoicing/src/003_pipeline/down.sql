-- Drop the triggers on invoice_items
DROP TRIGGER IF EXISTS trigger_refresh_invoices_read_items ON invoice_items;

-- Drop the triggers on invoices
DROP TRIGGER IF EXISTS trigger_refresh_invoices_read ON invoices;

-- Drop the function to refresh invoices_read
DROP FUNCTION IF EXISTS refresh_invoices_read();

-- Drop the function to calculate invoice details
DROP FUNCTION IF EXISTS get_invoice_details(INT);

-- Drop the invoices_ro table
DROP TABLE IF EXISTS invoices_ro;
