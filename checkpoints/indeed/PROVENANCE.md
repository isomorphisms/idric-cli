# Indeed API research provenance

The first Indeed API inventory was written on `isomorphisms/az` branch `indeed-api` at commit:

```text
84d2737b819d885eeba296870099d30908c8094e
```

That branch documented OAuth endpoints, the shared GraphQL transport, Job Sync/Update, Candidate Sync, Disposition Sync, Hiring Lab, SCIM, SSE, XML/callback surfaces, and the permission boundary around `jobSearch`.

During CLI consolidation on 2026-09-01, the Indeed branch was deliberately recorded as documentation/research only and was not copied as a CLI program.

This `idric-cli` checkpoint was recreated and refreshed on 2026-09-09 from the current Indeed Partner Docs. In particular it adds/refreshes:

- the current API catalog classification;
- the September 4, 2026 Job Update documentation state;
- Candidate Sync operation namespaces and current Retrieve/Send behavior;
- the full current `IndeedDispositionStatus` inventory;
- the expanded Hiring Lab query inventory;
- Job Update seat-management mutations;
- the separately documented Sponsored Jobs, Disposition Data CSV, JavaScript, webhook, and deprecated surfaces;
- the canonical downloadable GraphQL schema URL.

Primary official sources are listed in `API.md`.

No credentials, API keys, access tokens, copied customer data, or live Indeed responses are committed here.
