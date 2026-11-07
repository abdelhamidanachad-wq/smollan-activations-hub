-- Add the import idempotency index after the quotation lifecycle migration creates the table.
create unique index if not exists smollan_quotations_number_uidx
  on public.smollan_quotations(quotation_number) where quotation_number is not null;
