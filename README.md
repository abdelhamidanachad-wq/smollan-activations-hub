# SMOLLAN Morocco — Operations Hub

React/Vite demo for a cross-functional operations workspace spanning Brand & Activations, Field Operations, Production/Procurement, Finance and Merchandising.

## Included
- Responsive dashboard with illustrative project, task and calendar data.
- Super Admin integration-readiness console (UI only).
- AI Assistant, WhatsApp inbox and Automations Center (local demo state only).

**Demo status:** AI replies are deterministic examples, WhatsApp replies are not transmitted, automation toggles do not execute workflows, and no external OAuth/API integrations are active. Do not enter real employee/client data or credentials.

## Deploy on Vercel
1. In Vercel, choose **Add New → Project** and import `abdelhamidanachad-wq/smollan-activations-hub`, or open the existing project linked to this repository.
2. Set the deployment branch to `fix/vite-entrypoint` if you want this full demo. Keep the repository root as the Root Directory.
3. Framework preset: **Vite**; Install Command: `npm install`; Build Command: `npm run build`; Output Directory: `dist`.
4. Deploy from the Vercel dashboard. The local-state demo has no required environment variables.
5. If wiring the frontend to Supabase later, add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` in Project Settings → Environment Variables, then redeploy. A publishable key can appear in browser code. Never place a Supabase service-role/secret key or Google OAuth client secret in a `VITE_*` variable.
6. Confirm deployment status and review build logs before sharing the link.

## Supabase
Dedicated project: **SMOLLAN**  
Project ref: `ddrohraarhdbwamwnmnu`  
URL: https://ddrohraarhdbwamwnmnu.supabase.co  
Region: `eu-west-1`

The initial operations schema is now applied to this dedicated project. Five tables are present: `smollan_memberships`, `smollan_clients`, `smollan_projects`, `smollan_tasks` and `smollan_audit_events`. Row Level Security is enabled on each; they contain no business records at setup time. This is a foundation, not production authorization certification: implement and review server-side Google identity verification, exact verified `smollan.com` domain validation, admin-managed membership activation, table-specific permissions, and append-only audit enforcement before loading real data.

Google Workspace OAuth, WhatsApp Business, AI provider, and workflow execution are not connected. The Super Admin screen does not store secrets or connect services.

## Safety
- Do not connect this app to the MOROTTO project; it contains unrelated marketplace data.
- Do not commit secrets, service-role keys, OAuth client secrets, or real employee/client records.
- Supabase configuration alone does not turn demo-local UI into a live integrated operations system.
