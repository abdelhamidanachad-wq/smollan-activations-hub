# SMOLLAN Morocco Operations Hub — PHP edition

PHP-first application path under development. Uses PHP 8.2+ and PDO PostgreSQL against the existing Supabase database; it does not duplicate or migrate imported data.

## Run locally
1. Install Docker/Compose or PHP 8.2+, Composer, and the pdo_pgsql extension.
2. Copy .env.example to .env.
3. In Supabase Dashboard → Connect choose Session pooler; configure host/user/password. Obtain the database CA certificate and use DB_SSLMODE=verify-full.
4. Run composer install. With Docker, run docker compose up --build.
5. Visit http://localhost:8080/health and http://localhost:8080/login.

Never commit .env, database credentials, Google secrets, WhatsApp tokens or private HR files.

## Architecture
- Support/Database.php: SSL PostgreSQL PDO connection.
- Support/Auth.php: session identity and active membership gate.
- Support/Policy.php: role-to-module authorization.
- Support/Csrf.php: CSRF tokens.
- Repositories/OperationsRepository.php: live queries against existing smollan_* tables.
- Services/AttendanceService.php: assignment-bounded check-in/out with audit.
- Services/WorkflowService.php: transactional quotations, expense intake and role-gated decisions.
- Services/GoogleWorkspace.php, WhatsAppBusiness.php: setup gates until provider OAuth/API flows are configured.

## Implementation status
Foundation committed: login/session structure, membership authorization, module navigation, live read directories, database-driven overview counters, quotation header and line items, expense submission, role-gated decision services, audit writes, assignment-bound check-in/out service.

Not release-ready: Supabase Auth password verification must be tested against the active Auth mechanism; most modules still need dedicated create/update workflows; supplier registry, quotation comparisons, PO issuance and goods receipt need schema; payment ledger/reconciliation and Moroccan payroll rules are not implemented; surveys/project forms are incomplete; private Storage uploads and signed evidence access need end-to-end tests; Google per-user OAuth/callback/token encryption/sync and WhatsApp Cloud API/webhooks/templates require real credentials; safe Excel staging/reconciliation UI is unfinished. Navigation is not a claim those workflows are live.

## Hosting
Vercel is not a conventional PHP/Apache host. Run this container on a PHP-capable host or VM; keep Vercel for an optional frontend unless a verified container path is selected. Existing Vercel project enumeration under the connected team returned no projects, so this branch does not alter Vercel settings.
