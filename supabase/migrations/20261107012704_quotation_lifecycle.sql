-- Expand quotation status lifecycle used by the quotation maker.
alter table public.smollan_quotations drop constraint if exists smollan_quotations_status_check;
alter table public.smollan_quotations add constraint smollan_quotations_status_check
 check (status in ('Draft','Requested','Received','Under comparison','Submitted','Sent to client','Approved','Rejected','Expired'));
