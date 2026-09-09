# Indeed API checkpoint

This directory records the current Indeed developer surface as a foundation for an Idriç CLI.

Snapshot date: 2026-09-09.

Status: documentation/research only. No Indeed client is claimed working yet.

## Important access boundary

Indeed does not currently offer an anonymous public replacement for the retired Publisher Job Search API. The current documentation shows a `jobSearch` GraphQL query, but the same official example shows access denied when the app is not provisioned for the `job-retrieval-service`. Treat `jobSearch` as permissioned.

Most current partner APIs require an Indeed partner relationship, provisioned application credentials, product-specific scopes, and sometimes product review/approval. Hiring Lab uses an Indeed-issued API key instead of OAuth.

## Files

- `API.md` — structural inventory of the current API families, operations, protocols, authentication, and important limits.
- `endpoints.txt` — machine-scannable HTTP routes and named GraphQL operations.
- `PROVENANCE.md` — where this inventory came from and what was refreshed.

## Canonical Indeed documentation

- API catalog: https://docs.indeed.com/api-guides/
- Integration basics: https://docs.indeed.com/integration-basics/
- Authentication: https://docs.indeed.com/authentication/
- Full GraphQL schema: https://docs.indeed.com/public_graphql_schema.graphqls
- GraphQL API reference: https://docs.indeed.com/api/graphql_schema
- Release notes: https://docs.indeed.com/release-notes

The downloadable GraphQL SDL is the canonical type-level surface. This checkpoint records the product/operation-level interface and the non-GraphQL protocols without copying Indeed's documentation prose wholesale.
