# SMOLLAN Morocco — Operations Hub Foundation

## Product goal
One secure workspace for Brand & Activations, Field Operations, Finance, Production/Procurement and Merchandising. Track continuous weekend promoter programs (VSD: Friday–Sunday; SD: Saturday–Sunday), short activations spanning two or three VSD cycles, pure production engagements, and animation-only engagements.

## Module map
1. Executive overview: live portfolio, risks, blockers, upcoming field activity, overdue tasks, pending approvals and finance milestones.
2. CRM & clients: client contacts, briefs, pitches, opportunities, account owner and history.
3. Projects: project type (permanent promoter / activation / production-only / in-store animation / merchandising), client, scope, cities, stores, VSD/SD pattern, dates, budget, margin estimate, owner, teams, milestones and project files.
4. Workflow & tasks: task templates, assignees, dependencies, due dates, comments, approvals, notifications, daily personal queue and audit trail.
5. Calendar: team/project calendar, activation weekends, creative BAT deadlines, production and procurement milestones, training, dispatches, timesheet closure, invoice due dates.
6. Production: creative versions, BAT (artwork proof) review states, vendors, quantities, cost estimates, production status, quality checks and delivery/dispatch receipts.
7. Materials & inventory: PLV, stands, uniforms, gifts/goodies, digital-game assets; locations, batches, reserved quantities, dispatches, returns, damage and stock reconciliation.
8. People & field execution: promoters/animatrices, supervisors, field managers, merchandisers; onboarding and training; store assignments; attendance/pointage imported from or linked to the existing time-tracking webapp; exceptions, sign-off and payment readiness.
9. Digital activations: mechanics, links/QR codes, prizes, rules, redemptions and reporting.
10. Finance: client estimates/devis with line items and VAT settings, approval and versioning; client PO, BL/delivery notes, invoices, payment status; supplier RFQs/quotes, supplier PO, supplier BL, supplier invoices, due dates, reconciliation and cost-vs-budget.
11. Asset register: laptops, phones, tablets, vehicles, accessories; serial/IMEI/registration, assignee, status, handover forms, maintenance, damage, return, expiry and history.
12. Integrations & repository: Google Drive file links, Google Calendar events, Gmail references, Google Meet links, WhatsApp group links and contact directory. Start with links and metadata; add Google API sync only after OAuth scopes and Workspace admin approval.
13. Reports: execution, attendance, productivity, stock movement, project costs, vendor obligations, billed/recovered amounts and margins.

## Architecture
- Frontend: React + Vite (existing repository) with responsive, installable PWA experience.
- Hosting: Vercel Git deployment with preview/production environments once repository permissions/linking are confirmed.
- Database/Auth/Storage: a **dedicated SMOLLAN Supabase project**, not the connected MOROTTO database (which contains unrelated automotive marketplace data).
- Authentication: Supabase Auth with Google OAuth. Validate verified user email and exact `@smollan.com` domain at the trusted session boundary; reject external accounts. Assign application roles from a protected server-managed membership table, never user-editable metadata.
- Roles: platform admin, leadership, brand/activation coordinator, field operations, finance, procurement/production, merchandising, supervisor, read-only client (optional). Grant least privilege and enforce row-level security on every exposed table.
- Money: use `numeric` for prices, record currency explicitly (default MAD), store tax rate separately, and freeze document number/date/amount snapshots once issued. Configure invoice numbering and VAT with Finance before live issue.
- Audit: maintain created_by, updated_by, timestamps and an append-only business audit trail for approvals, attendance, stock movements and financial documents.
- Privacy: CIN/ID documents, phone numbers, attendance, payments and employee records are sensitive. Collect only needed fields, restrict access, avoid storing IDs in logs/demo fixtures, configure private storage and retention rules.
- Integration credentials must stay server-side; never commit service role keys or OAuth client secrets.
- Seed data must be explicitly marked as demo and must never impersonate real staff or clients.

## Suggested delivery sequence
### Phase 1 — trustworthy core
Dedicated database, Workspace login and role model, clients, projects, tasks, calendar, file references and audit log.
### Phase 2 — field operations
People, store assignments, VSD/SD schedules, attendance import/exception review, training and supervisor views.
### Phase 3 — production & stock
Creative BAT approvals, supplier directory, PLV/uniform/goodies catalog, reservations, dispatches and returns.
### Phase 4 — finance & assets
Estimate/devis builder, PO/BL/invoice workflow, supplier commitments, payment tracking, asset register and maintenance.
### Phase 5 — integrations & analytics
Google Drive/Calendar/Gmail integrations where authorized, WhatsApp links, digital-game integrations, reports and exports.

## Go-live blockers
- Create or select a dedicated Supabase project for SMOLLAN.
- A Workspace/Google Cloud admin must configure the Google OAuth client and authorized redirect URLs.
- Confirm authorized invoice/quote numbering, VAT rules, approval thresholds and MAD accounting policy with Finance.
- Confirm the current attendance webapp supports an API/export, and define source-of-truth and correction ownership.
- Replace all random client, promoter, CIN and project fixtures with approved data imports; preserve data provenance and access controls.
- Confirm which existing Vercel project/repository is intended for this app and ensure the deployment source is the SMOLLAN activations repository, not the unrelated automobile project.
