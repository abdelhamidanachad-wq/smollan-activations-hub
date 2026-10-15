# SMOLLAN Morocco Operations Hub — PHP / Hostinger migration

## Decision
The existing React/Vite front end is a prototype and is not the target runtime. This branch introduces a server-rendered PHP 8.2+ application suitable for Hostinger shared hosting. Supabase remains the current source of operational data until the owner explicitly approves a database migration. PHP talks to Supabase REST/Auth/Storage from the server; no service-role secret is sent to the browser.

## Data already held in Supabase
The SMOLLAN project `ddrohraarhdbwamwnmnu` has imported operational data: 7 clients, 51 projects, 84 stores, 21 supervisors, 270 promoters, 121 assignments, 94 project-store links, 16 goodies and 3 PLV material records. Seventy-seven promoter source rows were not silently merged because CIN/name identity was missing or conflicting. Historical attendance and actual CIN/RIB files were not imported; full quotation/PO/invoice/payment reconciliation is incomplete. Do not display these omissions as complete.

## Application modules
- Home dashboard and alerts, global project selector and project operational workspace.
- Clients/CRM and briefs; projects, teams, milestones, tasks, calendar links.
- Stores, supervisors, promoters, assignments and promoter self-service.
- Attendance/check-in/check-out, location/photo evidence and survey forms; require consent and role-scoped access.
- HR onboarding, PEC, payroll readiness, awards/rewards and private CIN/RIB/contract document register.
- PLV/POSM, goodies, uniforms and assets; stock movements, reservation, dispatch, receipt, returns, damage and reconciliation.
- Finance: quote/devis builder with line items and VAT settings; client PO, supplier RFQs and comparisons, supplier PO, delivery notes, invoices, payments, budget-vs-actual and margin reporting.
- Google Workspace connections: Drive resources, Sheets exports/imports, Calendar links/events and Gmail references/search only after OAuth and admin scopes are configured.
- WhatsApp group directory and deep links; WhatsApp Business messaging only after official API credentials/webhooks are configured.
- Import manager with preview, explicit field mapping, duplicate key matching, ambiguous-row review, row outcomes and audit trail.

## Security
- Use PHP sessions, HttpOnly/Secure/SameSite cookies, CSRF tokens, session rotation, rate-limited login and server-side role checks.
- Restrict employee/internal accounts to verified `@smollan.com` addresses; don't assign privileges from client-controlled form fields.
- Never put Supabase secret/service role, Google client secret, WhatsApp token or DB password in source code or `public/`.
- CIN, RIB, payroll and employee photos are private. Only signed-in users with the right HR/Finance scope may request private file links. Never expose raw records as public JSON.
- Every write must validate input server-side and keep an audit record. Money uses decimal/numeric math and explicit MAD/VAT fields.
- No fake integration status: each integration shows Not configured, Connected, Needs authorization, or Error.

## Hostinger deployment
1. Upload the repo `hostinger-php/public/` contents into the domain's `public_html/` (or set document root to `hostinger-php/public` if hosting plan supports it).
2. Keep PHP source/configuration outside the public document root where possible.
3. Set PHP 8.2+, enable cURL, JSON, OpenSSL and mbstring.
4. Copy `.env.example` to a file outside web root and set Supabase URL + publishable key + server-side secret only if available from project owner; never commit secrets.
5. Set HTTPS and trusted redirect URLs. Google OAuth callback origins must match the exact deployment URL.
6. Run `php -l` against all PHP files; test in staging with a non-admin account before production.

## External prerequisites
Google Workspace APIs require a Google Cloud OAuth client, approved scopes, callback URL and possibly Workspace administrator approval. Gmail access scopes should be minimal. Drive/Sheets should use per-user OAuth if access must respect that employee's Workspace permissions. WhatsApp group links can be stored directly; the official WhatsApp Business Platform does not provide general management of arbitrary WhatsApp group membership as a normal public API. Finance must confirm VAT rules, document numbering, and approval thresholds before issuing legal documents.
