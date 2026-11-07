# SMOLLAN AI Core

## Scope

SMOLLAN AI Core upgrades the existing floating assistant in place. It is a Vercel serverless API route backed by the existing Supabase Auth session and PostgreSQL RLS policies. It does not introduce a second application, database, authentication system, or write path into operational tables.

The first release is deliberately read-only for operational data:
- Read authorized projects, project tasks, attendance summaries, quotations and activation setup.
- Retrieve approved, scope-filtered business memory.
- Save draft recommendations for a human to review.
- Persist conversations, runs and AI audit metadata.

It does not execute project changes, create operational tasks, update budgets, modify promoter assignments, change payroll, approve quotations or change user permissions.

## Existing stack retained

- React 18 / Vite 6 frontend.
- Existing `@supabase/supabase-js` client.
- Existing Supabase project `nkrxpgshfqkubnovgrhy` in `eu-west-2`.
- Existing Vercel `/api` serverless function convention.
- Existing Supabase membership role and RLS authorization.

No new npm dependency is required for this foundation. The API uses the OpenAI-compatible Chat Completions interface exposed by Vercel AI Gateway. The existing OpenAI key remains a compatibility fallback until Gateway credentials are provisioned.

## API

### `POST /api/ai-core`

Headers:
- `Authorization: Bearer <Supabase access token>`
- `Content-Type: application/json`

Body:
```json
{
  "message": "Review this project before launch",
  "conversationId": null,
  "context": {
    "section": "Project workspace",
    "projectId": "optional-project-uuid"
  }
}
```

The endpoint authenticates the user with Supabase Auth, verifies an active `smollan_memberships` record, and uses the caller's JWT for every database query. RLS remains the final data-access boundary.

The available model tools are intentionally constrained:
- `list_projects`: read projects visible to the user.
- `get_project_report`: read a project operational snapshot.
- `save_recommendation`: create a draft recommendation only.

The old `/api/assistant` endpoint remains as a compatibility alias to the new safeguarded handler.

## Model routing

Set server-side Vercel environment variables:
- `AI_GATEWAY_API_KEY`: recommended Gateway credential. Vercel OIDC can be used when enabled for the deployment.
- `AI_CORE_FAST_MODEL`: fast model ID returned by the live AI Gateway model catalog; default is `openai/gpt-4.1-mini`.
- `AI_CORE_REASONING_MODEL`: reasoning model ID returned by the live catalog; default is `openai/gpt-4.1`.
- `AI_CORE_FALLBACK_MODEL`: optional fallback model ID.
- `OPENAI_API_KEY`: optional direct-provider compatibility fallback.
- `SUPABASE_URL` and `SUPABASE_ANON_KEY`: server-side Supabase connection values. The public Vite values can be used as compatibility fallbacks, but service-role credentials must never be sent to the browser.

The router classifies short operational questions versus deeper analysis and selects the configured fast or reasoning model. It retries a configured fallback on model-not-found, rate-limit or transient provider errors. Model IDs must be verified against the live Gateway catalog before production configuration.

## Memory model

`smollan_ai_memory` supports four scopes:
- `company`: approved company-wide operational knowledge.
- `department`: approved knowledge visible only to roles mapped to that department.
- `project`: approved project-specific knowledge visible only where the caller can read the project.
- `user`: private knowledge owned by one user.

Memory retrieval uses PostgreSQL full-text search in this first migration. pgvector/embeddings are intentionally not enabled until the embedding provider, dimensions, retention policy and data classification have been selected. Only approved memory is returned. Do not store secrets, CIN, RIB, private HR records or raw payroll documents in AI memory.

## Data migration

Apply `supabase/migrations/20261107210000_smollan_ai_core_foundation.sql` only after review and successful preview validation. It is additive: it creates AI-specific tables, indexes and RLS policies and does not modify operational tables.

The Supabase project currently reports two applied migrations that were not present in the inspected Git tree:
- `20261107204217_allow_verified_smollan_admin_email`
- `20261107204504_enable_command_center_realtime_tables`.

Reconcile this migration-history drift before applying future migrations from the repository. Do not reset production migration history.

## Deployment and rollout

1. Review the pull request and run the Vite production build.
2. Provision AI Gateway credentials and model IDs in Vercel server-side environment settings. Do not commit secrets or use `VITE_` for server credentials.
3. Apply the additive migration to a Supabase preview/branch first; verify RLS using at least coordinator, finance, HR and leadership test accounts.
4. Deploy the PR as a Vercel Preview and verify authenticated chat, memory filtering, project reads, draft recommendations and legacy route compatibility.
5. Merge only after review and successful checks.
6. Apply the migration to production during the controlled release, then promote the verified deployment.
7. Keep the AI feature disabled or unavailable gracefully if provider credentials are missing. Existing operational modules must continue working.

## Known follow-up work

- Approval inbox and exact-payload approval/execution workflow.
- Durable background workflows and scheduled analysis.
- Event outbox/dispatcher with idempotent consumers.
- Department-specific agents and additional read-only domain tools.
- pgvector semantic retrieval after embedding/provider validation.
- Retention, export and deletion controls for AI conversations.
- Automated tests for authorization, prompt injection, tool arguments, retry and model routing.
