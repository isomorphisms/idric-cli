# Handshake CLI compiler checkpoint

This directory is a Handshake EDU API command-line client checkpoint in Idriç.

The slice is deliberately narrow: use Handshake's documented read-only EDU API for `jobs` and `job_role_groups`, keep the API-key/header boundary explicit, and expose public job URLs separately. Do not treat Handshake's authenticated student web application as a public API and do not make this checkpoint green by replaying browser cookies or substituting curl/Python.

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

That credential is not assumed to exist. Missing and empty credentials are explicit refusal cases.

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

No network. Validate a nonempty ASCII decimal Handshake job id and print its public job-detail URL.

### `fixture-jobs` / `fixture-roles`

No network. Decode a synthetic EDU-API-shaped JSON response and emit TSV.

Committed fixtures:

```text
fixture/jobs.json
fixture/jobs.expected.tsv
fixture/job_role_groups.json
fixture/job_role_groups.expected.tsv
```

The jobs fixture includes escaped tab/newline characters in a title while its expected TSV contains spaces, so the receipt exercises field cleanup as well as JSON decoding.

### `jobs` / `roles`

Read `HANDSHAKE_EDU_API_KEY`, build `x-api-key` with ICU's caller-declared credential-header surface, perform one ICU GET with file-backed response capture, decode the response, and emit the same TSV shape as the fixtures.

The credential tag does not change the header's wire representation. Its only policy effect is on redirects: same-origin redirects retain `x-api-key`; a change of scheme, host, or port strips it before the redirected request is sent.

This first slice intentionally does not paginate. Handshake documents cursor pagination (`next_cursor` / `page_cursor`); pagination should follow after a single live page is accepted.

`HANDSHAKE_EDU_BASE_URL` exists so deterministic acceptance can direct the live command at a local fixture server. The `url jobs` and `url roles` commands continue to report the documented production URLs.

## Surface audit

The original draft made seven named holes. They are now either implemented through current Idriç surfaces/small client-local logic or covered by the pending ICU stack:

| Original hole | Present surface | Current treatment |
| --- | --- | --- |
| TSV field cleanup | `String`, `pack`, `unpack` | local replacement of tab/newline/carriage-return with spaces |
| fixture input | `System.File.readFile : ... → Either FileError String` | implemented with explicit file-error text |
| jobs JSON decoding | `Language.JSON.parse`, `JSON`, `lookup` | typed `/jobs` decoder over Idriç contrib JSON |
| role-group JSON decoding | same | typed `/job_role_groups` decoder over the same parsed JSON |
| environment access | `System.getEnv : ... → Maybe String` | direct wrapper for fixed valid names |
| decimal job-id validation | ordinary character/list operations | nonempty ASCII decimal check |
| ICU GET with `x-api-key` | ICU #13 header/capture mechanics plus ICU #20 caller-declared credential headers | implemented; pending that ICU stack landing |

`Language.JSON` is already part of current Idriç contrib. It parses a string to `Maybe JSON`, with structural `JNull`, `JBoolean`, `JNumber`, `JString`, `JArray`, and `JObject` values plus object-field lookup. The Handshake checkpoint therefore does not carry its own JSON grammar. Only fields needed for the two raw tables are decoded into Handshake records; unrelated response fields remain parsed JSON and are ignored.

`Language.JSON` represents JSON numbers as `Double`. Required Handshake identifier fields are accepted only when the parsed number converts back to the same integral value. If Handshake ever documents or emits identifiers outside the exactly representable integer range of that JSON surface, that becomes a real decoding-surface limitation rather than something this client should hide.

Idriç PR #67 is separately restoring the stricter project-level `environment_value : String → IO (Maybe String)` wrapper after the source-layout rewrite. Handshake does not need to block on it: this client queries fixed valid names and current `System.getEnv` already returns `Maybe String`.

## Credential redirect boundary

ICU #13 supplies validated caller headers and `fetch_to_files_with_headers`. ICU #20, stacked directly on #13, adds `make_credential_header` and carries only the declared credential header names into native redirect handling.

For Handshake the request is therefore constructed as a normal GET with a credential-tagged `x-api-key`. On same-origin redirects the full request header survives. On cross-origin redirects ICU removes `Authorization`, `Cookie`, and all caller-declared credential headers while preserving unrelated custom headers and rewriting `Host`.

Handshake does not invent a private transport. It does not substitute curl, Python, browser cookies, or a Handshake-specific socket path.

## Checkpoint ladder

1. source parses/checks against current Idriç, contrib, and the current ICU header/capture stack;
2. `url jobs` and `url roles` print the documented endpoints;
3. `public JOB_ID` accepts decimal ids and rejects malformed ids;
4. jobs fixture decodes, flattens embedded TSV-breaking whitespace, and matches its TSV receipt;
5. job-role-group fixture decodes and matches its TSV receipt;
6. process environment distinguishes missing and empty API keys;
7. ICU proves caller-declared credential headers survive same-origin redirects and are stripped cross-origin;
8. the Handshake executable traverses a deterministic same-origin then cross-origin redirect chain with synthetic `x-api-key` and returns the jobs fixture only if both header conditions hold;
9. one actual `/jobs` page can be accepted with an authorized EDU key;
10. one actual `/job_role_groups` page can be accepted through the same boundary;
11. cursor pagination is added without changing the one-page decoder contract;
12. a separate analysis command joins jobs and role groups by `job_id` and reports classification evidence without altering raw observations.

## Public-catalog follow-up

The public `find-jobs` catalog is useful to an individual job seeker even without institutional EDU API credentials. It should be investigated as a separate checkpoint. Only add a machine-readable public-catalog client if there is a stable public interface whose use can be documented; do not infer a private student API from browser internals.
