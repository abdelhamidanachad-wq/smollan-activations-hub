# SMOLLAN Activation Hub

Project-centric operations workspace for SMOLLAN retail activations, field teams, stores, staffing, attendance, production, PLV/POSM, surveys, digital games, quotations, suppliers, purchase orders and project finance.

The production source of truth is the `main` branch of this repository. The React/Vite app is backed by the dedicated SMOLLAN Supabase project below.

## Application workflows

- Project portfolio and project hub with activation setup, locations, dates, client, staffing/payroll assumptions, tasting materials, PLV, BAT, goodies, uniforms, tombola, surveys, digital games, lifecycle triggers and brand assets.
- Project calendar, home readiness and delivery-health panels.
- Promoter, supervisor, store, assignment and attendance workflows.
- Tasting/consumables, gifts, uniforms and PLV/POSM production.
- Survey studio with multilingual templates and promoter-facing survey links.
- Digital game builder and public QR game route; prize allocation is server-side.
- Quotation maker with project requirement import, line items, supplier comparisons and CSV export.
- Purchase orders, invoices, expenses, budgets, dispatch and route/cost registers.
- Floating AI copilot using the signed-in user's Supabase JWT and RLS permissions.

## Supabase production project

- Project: **SMOLLAN**
- Project ref: `nkrxpgshfqkubnovgrhy`
- URL: https://nkrxpgshfqkubnovgrhy.supabase.co
- Region: `eu-west-1`

All database migrations are versioned in `supabase/migrations/`. Apply them in ascending filename order. The activation/commercial, creative/survey, digital-game, quotation, operational RLS, security-hardening, legacy-import and secure-payroll-staging migrations are included in this repository.

### Edge Function

The `digital-game-play` Edge Function is deployed to the SMOLLAN project. It validates public game submissions and performs prize allocation with the Supabase service role on the server. Never expose `SUPABASE_SERVICE_ROLE_KEY` to the browser.

### Data API and RLS

Keep the `public` schema exposed to the Supabase Data API only as required by the app. Table grants and RLS policies do not override the project's API schema exposure setting. Verify the SMOLLAN project's Data API settings after schema changes. All public operational tables have RLS enabled; unauthenticated users cannot read project or promoter records.

### First administrator

The database currently has no Supabase Auth users. The one-time first-admin bootstrap function in the existing migration only accepts the designated, email-verified administrator identity configured in that migration. Sign up and verify that account before expecting project data to appear in the authenticated app. Do not create a user with an unverified or shared mailbox.

## Imported operational data

Source workbooks available in the Project Library have been imported or staged with provenance:

- 43 activation projects across the finance tracker and 6 client accounts, including HALEON from the JPF source.
- 42 client quotation records, imported as **Draft** because signed approval was not verified.
- 10 client purchase-order records imported as **Received**; the source did not contain PO amounts, so imported totals are zero and the original document reference is retained in the notes.
- 68 historical project cost-category totals imported as actuals. The source did not supply approved budgets by category, so the budget amount is deliberately left at zero.
- 20 supplier records, 81 store records, 6 supervisors and 33 store/supervisor links.
- 8 JAMILA goodies records.
- 61 promoter profiles from the JPF FOOD and JPF HALEON sheets. They are marked **Inactive** pending HR validation. CIN/CNSS values are encrypted and stored in the private-details table; a one-time encryption key is held in Supabase Vault, not in source control.
- 61 payroll rows are in the restricted `smollan_payroll_import_staging` table. The source files did not specify the payroll period, so these rows are **Review required** and are not posted payroll runs or payment instructions.
- 63 participants from the activity export, 13 POSM quotation lines, 20 POSM store candidates and 33 PO/invoice follow-up rows are staged for review where identity, project association, currency, or document status was ambiguous.

The raw field-activity export contains location/photo-linked activity rows. Those raw coordinates and image references were not copied into the live database; only store master data and a limited participant review list were extracted. Import those activity rows only after mapping them to verified projects, assignments and survey forms.

## Vercel deployment

Configure the Vercel project to use:

- Repository: `abdelhamidanachad-wq/smollan-activations-hub`
- Production branch: `main`
- Framework: **Vite**
- Root directory: repository root
- Install command: `npm install`
- Build command: `npm run build`
- Output directory: `dist`

Required browser build variables:

- `VITE_SUPABASE_URL=https://nkrxpgshfqkubnovgrhy.supabase.co`
- `VITE_SUPABASE_ANON_KEY` = the Supabase publishable key for SMOLLAN

Optional server-side variables for `/api/assistant`:

- `OPENAI_API_KEY`
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Do not put service-role keys, Vault secrets, employee identifiers, or other private values in `VITE_*` variables.

**Deployment status:** the GitHub source and Supabase database have been updated, but production deployment is still pending. The connected Vercel identity currently receives HTTP 403 when creating a project in the connected team, and no accessible Vercel project is linked to this repository. Grant the connected Vercel identity project-create/deploy permission or link an existing Vercel project to this GitHub repository, then deploy `main`. Do not treat a GitHub build check as a production deployment.

## Security notes

- Do not connect this app to the unrelated MOROTTO project.
- Never commit secrets, private employee identifiers, payroll data, or client financial documents.
- Keep promoter private details and payroll staging restricted to HR/Finance/authorized leadership roles.
- Imported promoter records remain inactive until HR confirms identity, contract and current status.
- Do not mark draft quotations, unverified POs or staged payroll rows as approved or paid without source evidence.
