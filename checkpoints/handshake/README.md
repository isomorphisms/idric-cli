# Handshake CLI compiler checkpoint

This directory begins a Handshake command-line client in Idriç.

The first slice is deliberately narrow: use Handshake's documented read-only EDU API for `jobs` and `job_role_groups`, keep the API-key/header boundary explicit, and expose public job URLs separately. Do not treat Handshake's authenticated student web application as a public API and do not make this checkpoint green by replaying browser cookies or substituting curl/Python.

## Why these two endpoints first

The immediate analytical use is to compare what a posting actually says with the occupational/job-role classification Handshake attaches to it. The official EDU API documents:

- `/jobs` — job id, title, employer id, employment type, job type, pay rate, remote/on-site/hybrid flags, salary type, external URL, timestamps, and related fields;
- `/job_role_groups` — job id, Handshake job-role-group id, job-role-group name, and timestamps.

Keeping those tables separate preserves Handshake's own data model. A later slice can join them by `job_id` and measure classification disagreements without silently rewriting the source data.

Official documentation, checked 2026-09-02:

- https://support.joinhandshake.com/hc/en-us/articles/31061076506391-Getting-Started-with-EDU-API
- https://support.joinhandshake.com/hc/en-us/articles/35762729693719-EDU-API-Endpoint-Definitions

## Access boundary

Handshake describes the EDU API as read-only and institution-scoped. Access requires an EDU API subscription approved by Handshake Support and requests use an `x-api-key` header.

This checkpoint therefore expects:

```text
HANDSHAKE_EDU_API_KEY=...
```

That credential is not assumed to exist. Missing credentials are a normal refusal case.

The public job catalog is a separate surface. Public job detail pages currently use URLs such as:

```text
https://app.joinhandshake.com/public/jobs/JOB_ID
```

`handshake public JOB_ID` only constructs that public URL. It does not claim that the public catalog has the same API contract as the institution-scoped EDU API.

## Command contract

```text
handshake url jobs
handshake url roles
handshake public JOB_ID
handshake fixture-jobs FILE
handshake fixture-roles FILE
handshake jobs
handshake roles
```

### `url jobs` / `url roles`

No network. Print the documented EDU API endpoint with a page size of 100.

### `public JOB_ID`

No network. Validate a decimal Handshake job id and print its public job-detail URL.

### `fixture-jobs` / `fixture-roles`

No network. Decode a synthetic EDU-API-shaped JSON response and emit TSV.

Committed fixtures:

```text
fixture/jobs.json
fixture/jobs.expected.tsv
fixture/job_role_groups.json
fixture/job_role_groups.expected.tsv
```

### `jobs` / `roles`

Read `HANDSHAKE_EDU_API_KEY`, perform one ICU/Idric-Net GET with the required `x-api-key` header, decode the response, and emit the same TSV shape as the fixtures.

This first slice intentionally does not paginate. Handshake documents cursor pagination (`next_cursor` / `page_cursor`); pagination should be the next network-level checkpoint after a single live page works.

## Named holes

`idric/Handshake.idric` intentionally leaves the following visible:

- TSV field cleanup;
- fixture file input;
- EDU jobs JSON decoding;
- EDU job-role-group JSON decoding;
- environment access;
- decimal job-id validation;
- ICU GET with caller-supplied `x-api-key` header.

The transport hole belongs at the shared ICU/Idric-Net request-header boundary, not in a Handshake-specific HTTP implementation.

## Checkpoint ladder

1. source parses/checks;
2. `url jobs` and `url roles` print the documented endpoints;
3. `public JOB_ID` accepts decimal ids and rejects malformed ids;
4. jobs fixture decodes and matches its TSV receipt;
5. job-role-group fixture decodes and matches its TSV receipt;
6. the process environment distinguishes missing API key from an empty/present value;
7. one live `/jobs` page travels through ICU with `x-api-key`;
8. one live `/job_role_groups` page travels through the same boundary;
9. cursor pagination is added without changing the one-page decoder contract;
10. a separate analysis command joins jobs and role groups by `job_id` and reports classification evidence without altering raw observations.

## Public-catalog follow-up

The public `find-jobs` catalog is useful to an individual job seeker even without institutional EDU API credentials. It should be investigated as a separate checkpoint. Only add a machine-readable public-catalog client if there is a stable public interface whose use can be documented; do not infer a private student API from browser internals.
