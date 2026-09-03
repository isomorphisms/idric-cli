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

### `jobs` / `roles`

Read `HANDSHAKE_EDU_API_KEY`, perform one ICU/Idric-Net GET with the required `x-api-key` header, decode the response, and emit the same TSV shape as the fixtures.

The live transport call currently fails closed because the merged ICU/Idric-Net surface cannot yet both attach caller-supplied headers and return the response body to the Idriç caller.

This first slice intentionally does not paginate. Handshake documents cursor pagination (`next_cursor` / `page_cursor`); pagination should be the next network-level checkpoint after a single live page works.

## Surface audit

The original draft made seven named holes. Six do not require a new shared dependency and are now implemented locally or through existing Idriç library surfaces:

| Original hole | Present surface | Current treatment |
| --- | --- | --- |
| TSV field cleanup | `String`, `pack`, `unpack` | local replacement of tab/newline/carriage-return with spaces |
| fixture input | `System.File.readFile : ... → Either FileError String` | implemented with explicit file-error text |
| jobs JSON decoding | ordinary Idriç data/recursion | focused structural JSON parser + typed `/jobs` decoder |
| role-group JSON decoding | same | focused structural JSON parser + typed `/job_role_groups` decoder |
| environment access | `System.getEnv : ... → Maybe String` | direct wrapper; fixed `HANDSHAKE_EDU_API_KEY` name |
| decimal job-id validation | ordinary character/list operations | nonempty ASCII decimal check |
| ICU GET with `x-api-key` | incomplete on merged transport path | remains the one genuine dependency/API gap |

The local JSON parser handles strings (including JSON escapes and surrogate pairs), null, booleans, integers, other JSON-number forms, arrays, and objects. Only the fields needed for the two raw tables are decoded into Handshake records; unrelated response fields are parsed and ignored rather than searched textually.

Idriç PR #67 is separately restoring the stricter project-level `environment_value : String → IO (Maybe String)` wrapper after the source-layout rewrite. That wrapper rejects invalid environment-variable names and preserves unset versus empty. Handshake does not need to block on it: this client queries one fixed valid name and current `System.getEnv` already returns `Maybe String`.

## Genuine remaining transport gap

The current merged Idric-Net HTTP model already has typed HTTP header values, but its normal renderer supplies a fixed header set. Current merged ICU's `send_request` consumes that rendered request and returns a transport result; it does not expose the response body to this caller.

Two pending ICU lines demonstrate the missing halves, but neither is the merged shared API Handshake needs:

- ICU #13 adds checked caller-supplied request headers, including `-H` / `--header`, on its pending branch;
- ICU #12 exposes a file-backed raw response capture seam for the OpenAI client on another pending stack.

Handshake therefore does **not** invent a private transport. `edu_icu_get` currently returns an explicit `Left` explaining that caller-header + response-body support is pending. Live `jobs` and `roles` fail closed there. Once ICU/Idric-Net exposes one current shared request API with both capabilities, that small boundary can be replaced directly.

## Checkpoint ladder

1. source parses/checks;
2. `url jobs` and `url roles` print the documented endpoints;
3. `public JOB_ID` accepts decimal ids and rejects malformed ids;
4. jobs fixture decodes and matches its TSV receipt;
5. job-role-group fixture decodes and matches its TSV receipt;
6. process environment distinguishes missing and empty API keys;
7. shared ICU/Idric-Net request API accepts caller headers and returns a response body;
8. one live `/jobs` page travels through that API with `x-api-key`;
9. one live `/job_role_groups` page travels through the same boundary;
10. cursor pagination is added without changing the one-page decoder contract;
11. a separate analysis command joins jobs and role groups by `job_id` and reports classification evidence without altering raw observations.

## Public-catalog follow-up

The public `find-jobs` catalog is useful to an individual job seeker even without institutional EDU API credentials. It should be investigated as a separate checkpoint. Only add a machine-readable public-catalog client if there is a stable public interface whose use can be documented; do not infer a private student API from browser internals.
