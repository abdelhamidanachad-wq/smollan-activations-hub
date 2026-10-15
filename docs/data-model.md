# Initial relational data model (proposal)

- `organizations`: legal entity / workspace boundary.
- `profiles`: auth user display profile; no authorization fields sourced from user metadata.
- `memberships`: organization_id, user_id, role, status, approved_by, approved_at.
- `clients`, `client_contacts`, `stores`, `suppliers`.
- `projects`: client_id, code, name, service_type, cadence (VSD/SD/none), dates, owner, status, budget and currency.
- `project_members`, `project_stores`, `project_milestones`.
- `tasks`, `task_dependencies`, `task_comments`, `approvals`, `audit_events`.
- `briefs`, `creative_assets`, `creative_versions`, `bat_reviews`.
- `catalog_items`, `inventory_locations`, `inventory_batches`, `stock_movements`, `dispatches`, `dispatch_items`, `returns`.
- `people`, `assignments`, `training_records`, `attendance_imports`, `attendance_entries`, `attendance_exceptions`, `payment_batches`.
- `digital_activations`, `game_mechanics`, `prize_inventory`, `redemptions`.
- `quote_headers`, `quote_lines`, `client_purchase_orders`, `delivery_notes`, `client_invoices`, `client_payments`.
- `supplier_quotes`, `supplier_purchase_orders`, `supplier_delivery_notes`, `supplier_invoices`, `supplier_payments`.
- `assets`, `asset_assignments`, `asset_maintenance`, `asset_handover_events`.
- `external_links`: type, URL, project/client association, owner and visibility (Drive/Calendar/Gmail/Meet/WhatsApp references).
- `attachments`: private Storage object references and metadata (no public ID-document URLs).

Use UUID primary keys, foreign keys, check constraints for enums/statuses, indexes for foreign keys and frequent organization/project/date lookups, and RLS policies on every exposed table. Use numeric decimal types for monetary line items. Model inventory via immutable stock movement records rather than relying only on a manually editable quantity field. Add optimistic locking/versioning to financial documents and creative approval revisions.
