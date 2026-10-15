# SMOLLAN Hub — Morocco Operations

Project-centric operations workspace for retail marketing activations, field teams, stores, attendance, resource requests, gifts/POSM and project finance.

## Rebuilt application
This branch replaces the old promoters-only panel with a broader Smollan Hub workspace based on the supplied product brief:
- Project portfolio and project operational hub with related-module navigation.
- Promoters, supervisors, stores, assignments and attendance.
- Resource requests and approval states.
- Gifts & goodies and PLV/POSM tracking.
- Tasks, clients, project finance, and a mobile-first promoter portal.
- Excel workbook import preview, column mapping, duplicate/key checks and explicit demo confirmation.
- AI Assistant, WhatsApp inbox, Automations Center and Super Admin integration-readiness console.

**Important:** this is a functional UI prototype, not a production launch. Seed records are illustrative, record edits/imports are held in local React state, AI responses are deterministic demo responses, WhatsApp messages are not sent, and automation switches do not execute jobs. No production data is connected to the UI yet.

## Deploy on Vercel
1. Import this repository in Vercel or select the existing project linked to it.
2. Use branch `feat/smollan-hub-rebuild` for this rebuild.
3. Root directory: repository root. Framework: **Vite**. Install: `npm install`. Build: `npm run build`. Output: `dist`.
4. Deploy and check the build logs. The demo needs no environment variables to render.
5. Do not add Supabase service-role keys, Google OAuth secrets, WhatsApp tokens or AI provider secrets to browser environment variables.

## Supabase foundation
Dedicated project: **SMOLLAN**  
Ref: `ddrohraarhdbwamwnmnu` · Region: `eu-west-1`  
URL: https://ddrohraarhdbwamwnmnu.supabase.co

The core schema and operations entities are applied. Tables include clients, projects, tasks, membership/access records, supervisors, stores, promoters, private promoter details, project/store/supervisor links, assignments, attendance, resource requests, gifts and distribution records, PLV/POSM, budgets, quotations, expenses, and import audit/results. Row Level Security is enabled. The SQL history is versioned in `supabase/migrations/`.

Before connecting the UI to live data, implement and test the trusted authentication flow, exact verified `@smollan.com` domain validation, admin-managed active membership, record-level role/scope checks, private Storage policies, and auditable server-side mutations. The browser must never be trusted to assign roles or approve memberships. Identity and bank information must remain encrypted or in private storage.

## Integration status
Google Workspace OAuth, Drive, Calendar, Gmail, WhatsApp Business, external AI provider calls and real workflow execution are **not connected**. Super Admin is a setup checklist only and does not collect or persist credentials.

## Excel import
The workbook importer previews a worksheet and allows explicit column mapping. Current confirmation adds validated sample rows to the local demo session only. Production import still needs authenticated server-side writes, stable-key reconciliation, ambiguous-match review, transaction safety, and row-level result persistence.

## Safety
- Do not connect this app to the MOROTTO project; it contains unrelated marketplace data.
- Never commit secrets or real employee/client records.
- Do not upload CIN images, bank documents or contracts to public storage.
