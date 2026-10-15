# SMOLLAN Morocco — Operations Hub

React/Vite prototype for a cross-functional workspace spanning Brand & Activations, Field Operations, Production/Procurement, Finance and Merchandising.

## Current state
- Responsive desktop/mobile operational dashboard and module navigation.
- Illustrative project/task/calendar views marked as demo data.
- Product blueprint and initial data model in `docs/`.
- A conservative, **proposal-only** Supabase schema in `supabase/migrations/202610150001_smollan_operations_core.sql`.
- No production data connection or real Google Workspace OAuth has been enabled yet.

## Run locally
1. Copy `.env.example` to `.env.local`.
2. Fill in only the Supabase project URL and publishable key for the dedicated SMOLLAN project.
3. Run `npm install`, then `npm run dev`.

## Safety
Do not connect this app to the MOROTTO project; its current schema is unrelated automotive marketplace data. Do not commit service-role keys, Google OAuth client secrets or real employee information. Review the proposal migration and RLS policies with the SMOLLAN system owner before applying it to a dedicated project.

## Google sign-in
Enable Google provider in the dedicated Supabase Auth project and configure the callback URL in Google Cloud. Authorization must validate verified identity and the exact `@smollan.com` domain on a trusted server-side boundary, then require an active record in `smollan_memberships`. A browser-only domain check is insufficient.
