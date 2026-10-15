# SMOLLAN Morocco — Operations Hub

React/Vite demo for a cross-functional operations workspace spanning Brand & Activations, Field Operations, Production/Procurement, Finance and Merchandising.

## What is included
- Responsive operations dashboard with illustrative projects, tasks, calendar, and supporting module views.
- Super Admin integration-readiness console (UI only).
- AI Assistant, WhatsApp inbox, and Automations Center (local demo state only).

**Demo status:** The AI replies are deterministic examples, WhatsApp replies are not transmitted, automation toggles do not execute workflows, and no external OAuth/API integrations are active. Do not enter real employee/client data or credentials into the demo.

## GitHub
Repository: https://github.com/abdelhamidanachad-wq/smollan-activations-hub
Deployment branch with the demo: `fix/vite-entrypoint` (feature PRs #3 and #4 have been merged there).

## Deploy on Vercel
1. In Vercel, choose **Add New → Project** and import this repository (or select the existing Vercel project already linked to it).
2. Select `fix/vite-entrypoint` as the deployment branch if you want this demo branch. The production deployment branch can be changed later in Project Settings → Git.
3. Framework preset: **Vite**. Root directory: repository root. Build command: `npm run build`. Output directory: `dist`. Install command: `npm install`.
4. Deploy. This repository has no required environment variables for the local-state demo.
5. To configure the Supabase URL and publishable key, add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` in Vercel Project Settings → Environment Variables, then redeploy. These values may be exposed in the browser; never put a Supabase service-role/secret key or Google OAuth client secret into a `VITE_*` variable.
6. Verify the deployment and its build logs before using it.

## Supabase project
Dedicated SMOLLAN project ref: `ddrohraarhdbwamwnmnu` (region `eu-west-1`).
Public project URL: `https://ddrohraarhdbwamwnmnu.supabase.co`

The SQL file at `supabase/migrations/202610150001_smollan_operations_core.sql` is a **proposal only**. It has not been applied. Have the SMOLLAN system owner/security reviewer approve and harden role-specific RLS, membership approval, audit immutability, and server-side OAuth checks before applying it or handling real data. Authentication must validate `email_verified`, the exact `smollan.com` domain, and active membership on a trusted server-side boundary. A frontend-only domain check is not authorization.

## Safety
- Do not connect this app to the MOROTTO project; it has unrelated marketplace data.
- Do not commit secrets, service-role keys, OAuth client secrets, or real employee/client data.
- A configured Supabase URL and publishable key do not make the demo production-ready.
