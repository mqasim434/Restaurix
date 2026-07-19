-- Per-order service / delivery charges confirmed on the Live Orders board
-- before the customer receipt prints.

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS service_charge NUMERIC(12, 2) NOT NULL DEFAULT 0;

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS delivery_charge NUMERIC(12, 2) NOT NULL DEFAULT 0;

ALTER TABLE orders
  ADD COLUMN IF NOT EXISTS bill_confirmed_at TIMESTAMPTZ;

COMMENT ON COLUMN orders.service_charge IS
  'Manual service charge entered on desktop Live Orders before receipt print';

COMMENT ON COLUMN orders.delivery_charge IS
  'Manual delivery charge entered on desktop Live Orders before receipt print';

COMMENT ON COLUMN orders.bill_confirmed_at IS
  'When desktop staff confirmed charges and printed the customer receipt';
