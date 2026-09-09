# Indeed API surface

Snapshot: 2026-09-09.

This is an operation-level map of the current documented Indeed developer surface. The canonical type-level GraphQL schema remains Indeed's downloadable SDL:

https://docs.indeed.com/public_graphql_schema.graphqls

The common GraphQL transport is:

```text
POST https://apis.indeed.com/graphql
```

A single HTTP endpoint therefore does not mean a single API. Product access is permissioned separately.

## 1. Authentication and identity

OAuth / OpenID Connect endpoints:

```text
GET  https://secure.indeed.com/oauth/v2/authorize
POST https://apis.indeed.com/oauth/v2/tokens
GET  https://secure.indeed.com/v2/api/appinfo
GET  https://secure.indeed.com/v2/api/userinfo
GET  https://secure.indeed.com/.well-known/keys
```

Indeed documents both client-credentials (2-legged) and authorization-code (3-legged) OAuth. Access tokens normally expire after 3,600 seconds. Product scopes and whether a token must represent a specific employer vary by operation.

Common GraphQL request headers:

```text
Authorization: Bearer TOKEN
Content-Type: application/json
```

Hiring Lab is the main exception: it uses an Indeed-issued API key in `Indeed-API-Key` and also requires a useful `Referer` header.

## 2. Common GraphQL surface

Common queries:

```text
node(id: ID!)
nodes(ids: [ID!]!)
```

Indeed Resource Identifiers use this conceptual form:

```text
iri://apis.indeed.com/{entityType}/{internalId}
```

Important documented scalar/common types include:

```text
BigDecimal
Boolean
CountryCode
CurrencyCode
Date
DateTime
EmailAddress
Float
ID
IndeedDispositionStatus
Int
Int64
LanguageCode
Long
PhoneNumber
String
URI
WebUrl
```

## 3. Job Sync API

Purpose: create, upsert/reactivate, inspect, and explicitly expire jobs.

Primary operations:

```text
MUTATION jobsIngest.createSourcedJobPostings
MUTATION jobsIngest.expireSourcedJobsBySourcedPostingId
QUERY    node
QUERY    nodes
```

The create/upsert request is based on sourced job postings with body and metadata. The current schema includes job title/description and formatting, salary, location, benefits and other job-body data; source identity; partner job-posting ID; publish date; job URL; contact data; taxonomy/SUID classification; and Indeed Apply configuration/screener-question data where enabled.

`createSourcedJobPostings` returns Indeed identifiers including `sourcedPostingId` and an employer-job IRI/id. Reusing the same source identity and job-posting identity performs an upsert rather than creating an unrelated duplicate. Expiration is explicit; jobs submitted through this API are not assumed to expire themselves.

## 4. Job Update API

Purpose: list existing employer jobs, update selected fields, clear those overrides, verify the resulting job, and manage job seats.

Queries:

```text
findEmployerJobsPartner
node
nodes
```

Mutations:

```text
jobsIngest.updateSourcedJobPostings
jobsIngest.clearSourcedJobPostingUpdates
jobsIngest.addSeats
jobsIngest.updateSeats
jobsIngest.clearSeats
```

`findEmployerJobsPartner` supports employer-scoped listing and pagination. Current documented filters/options include `createdOnIndeed`, sorting, and forward/backward cursor pagination. Indeed currently documents a maximum of 500 jobs per bulk listing response.

Updateable metadata includes at least:

```text
url
campaignCategories
trackingUrl
```

Updateable body data includes job content such as title, description/formatting, and location fields supported by `UpdateSourcedJobPostingBodyInput`.

The current job-status surface exposes whether a job is rejected, requires sponsorship, lacks required sponsorship, and whether Indeed Apply is active. Those values distinguish organic, sponsored-only, and non-searchable states.

Seat mutations are documented separately as the seat-management extension of Job Update.

## 5. Candidate Sync: Employer Registration API

Purpose: associate an ATS employer with Indeed and control Candidate Sync features.

Operations:

```text
MUTATION partnerAtsSyncEmployerRegistration.registerEmployer
MUTATION partnerAtsSyncEmployerRegistration.manageFeaturesForEmployer
QUERY    partnerAtsSyncEmployerRegistration.findRegisteredEmployers
MUTATION partnerAtsSyncEmployerRegistration.deregisterEmployer
```

Registration input includes a partner-provided employer ID and ATS name. Registration returns an `EmployerRegistration` with an Indeed registration ID/IRI, partner employer ID, employer name, feature statuses, and timestamps.

Feature controls currently include:

```text
retrieveSourcedCandidatesClick
retrieveSourcedCandidatesAuto
sendApplications
```

Registering an employer uses employer-linked 3-legged OAuth with `employer.ats_candidate.sync`; management/list/deregister operations use partner credentials as documented by Indeed.

Deregistration is destructive for the registration and candidate/employer data stored through it.

## 6. Candidate Sync: Send Candidates API

Purpose: sync ATS applications into Indeed.

Workflow operations:

```text
MUTATION atsSyncCandidateSync.application.initialize
MUTATION atsSyncCandidateSync.application.submit
QUERY    atsSyncCandidateSync.application.findStatuses
MUTATION atsSyncCandidateSync.application.delete
```

`initialize` stages a complete application version and returns an `applicationVersionId` plus presigned upload URLs for attachments. The current workflow gives five minutes to upload attachments and submit that version.

The application input includes the application identity, applicant data, screener questions/answers, disposition, links back to ATS application/candidate records, timestamps, attachments, and supported applicant profile/resume fields. Updates are versions: a new sync represents the complete current application, not a patch against an old application.

`findStatuses` supports filters by registration IDs, application identifiers, application-version IDs and status types with cursor pagination.

`delete` permanently removes the application and its versions from Indeed.

## 7. Candidate Sync: Retrieve Candidates API

Purpose: retrieve candidate assets from Indeed and acknowledge their delivery.

Operations:

```text
MUTATION atsSyncCandidateSync.fetchAssets
QUERY    atsSyncCandidateSync.assetsByTimeRange
MUTATION atsSyncCandidateSync.stageAssets
```

`fetchAssets` returns the next unacknowledged asset batch plus a token. Passing the previous token acknowledges that batch. `assetsByTimeRange` retrieves already-acknowledged assets. `stageAssets` creates test assets; current docs say staged mock data expires after 14 days.

The asset interface currently includes at least Smart Sourcing interested-candidate assets and Smart Screening update assets. Common metadata includes asset ID, staged timestamp, employer identifier, test-data flag, and complete source attribution. Candidate-specific implementations can include contact data, job linkage, tracking data, and resume information.

## 8. Disposition Sync API

Purpose: send application state changes from an ATS to Indeed.

Operation:

```text
MUTATION partnerDisposition.send
```

A request contains up to 25 dispositions in one call in the current integration guidance. Each `PartnerDispositionInput` includes:

```text
identifiedBy
dispositionStatus
rawDispositionStatus
rawDispositionDetails
atsName
statusChangeDateTime
applicationSourceName
```

Supported identifier paths include Indeed Apply ID, ITTK, Universal Apply ID, or alternate job + job-seeker identifiers.

Current `IndeedDispositionStatus` values:

```text
NEW
REVIEW
LIKED
CONTACTED
INTERVIEW
BACKGROUND_CHECK
WITHDRAWN
HIRED
INCOMPLETE
UNABLE_TO_MAP
SCREEN
VERIFY_ELIGIBILITY
NOT_SELECTED
OFFER_DECLINED
ASSESS_QUALIFICATIONS
OFFER_MADE
ONBOARDED
POSITIVELY_SCREENED
JOB_INACTIVE
JOB_CLOSED
DROPPED_DUPLICATE
DROPPED_JOB_EXPIRED
DROPPED_FRAUD_SPAM
DROPPED_OTHER
```

The `DROPPED_*` values are delivery-failure states and are not valid as ordinary persisted Candidate Sync dispositions.

The response reports the number of good dispositions and failed dispositions with identifiers and rationale.

## 9. Hiring Lab API

Purpose: labor-market datasets, not ordinary job-search results.

Transport:

```text
POST https://apis.indeed.com/graphql
Indeed-API-Key: KEY
Referer: ...
```

Core data queries:

```text
findHiringLabPostingsPublic
findHiringLabRemotePublic
findHiringLabWagesPublic
findHiringLabAiPublic
```

Metadata/coverage queries:

```text
findHiringLabCountriesPublic
findHiringLabSectorsPublic
findHiringLabGeographiesPublic
findHiringLabRegionsPublic
allHiringLabDatasetsPublic
```

Current datasets cover job-posting indices, remote-work measures, wage growth, and AI-job measures. Job-posting data has national, regional and sectoral variants. Pagination is cursor based and currently capped at 50 results per page.

## 10. Permissioned job retrieval

Indeed's current OAuth/getting-started documentation demonstrates:

```text
QUERY jobSearch
```

The same official example demonstrates a client receiving an error because it lacks access to `job-retrieval-service`. Record this operation, but do not treat it as an open anonymous search API.

## 11. Indeed PLUS / Employer Data API

Indeed PLUS documentation exposes employer-entity operations for the Japan integration surface.

Known current mutation:

```text
patchEmployer
```

It creates/updates employer identity and attributes using Indeed-provisioned employer identifier types. The GraphQL schema also includes employer/taxonomy-related input and payload types used by this surface.

This is market/integration specific rather than a general anonymous employer directory API.

## 12. Indeed Apply

Indeed Apply is an application-delivery integration rather than a simple client-initiated query API.

Two current publication paths exist:

```text
Job Sync API + Indeed Apply configuration
Job Sync XML feed + Indeed Apply metadata
```

The partner supplies a `postUrl`; Indeed POSTs application JSON to that URL. The receiving system validates `X-Indeed-Signature`, calculated from the unmodified JSON payload using the shared secret and HMAC-SHA1. Current partner integrations must support documented application/resume data and delivery status handling.

Screener questions can be supplied as documented JSON. The XML path has its own Indeed Apply configuration fields.

## 13. Job Sync XML

Purpose: feed-based job ingestion.

This is an XML document/feed protocol, not one universal request endpoint. The feed defines jobs and, where enabled, Indeed Apply configuration. Feed hosting/crawling/SFTP details depend on the integration arrangement.

Job Sync API is the preferred programmatic GraphQL path for new supported partner integrations, but XML remains documented.

## 14. Real-time API

Purpose: stream server-sent events.

Endpoint:

```text
GET https://apis.indeed.com/sse/notifications/message-update
```

Authentication uses a bearer token. Optional query parameter:

```text
eventTypes=TYPE1,TYPE2,...
```

Event data currently includes:

```text
uuid
eventType
payload
eventTime
```

## 15. SCIM 2.0 API

Purpose: user-directory synchronization, especially Indeed PLUS integrations.

Base resource:

```text
https://api.indeed.com/scim/v2/Users
```

Operations:

```text
GET    /scim/v2/Users
POST   /scim/v2/Users
GET    /scim/v2/Users/{id}
PUT    /scim/v2/Users/{id}
DELETE /scim/v2/Users/{id}
```

SCIM uses OAuth 2.0 client credentials and `application/scim+json`; errors follow SCIM 2.0 response conventions.

## 16. Sponsored Jobs API

Indeed maintains a separately permissioned Sponsored Jobs API and documents v8-or-later behavior for current integrations. It manages sponsorship/campaign operations and campaign reporting around Indeed jobs. It requires partner approval and product-specific OAuth/API access; no sandbox is generally provided, and Indeed recommends paused campaigns for non-spending create/update tests.

The current docs tie Sponsored Jobs to employer job IDs and `campaignCategories` used by Job Update. The exact Sponsored Jobs REST surface is maintained in Indeed's separate Developer Portal reference:

https://docs.indeed.com/api/sponsored-jobs-api/direct-integrations-for-sponsored-jobs-api-reference

Do not invent endpoints when access to that separate reference is unavailable. Keep that reference as the source of truth for campaign endpoint/version details.

## 17. Disposition Data CSV integration

Indeed still documents an older file-oriented disposition integration in addition to GraphQL Disposition Sync.

Protocol:

1. request a signed upload URL with the assigned API key;
2. upload CSV (legacy integrations may use XML) to the signed object-storage URL;
3. required CSV data includes Apply ID, status-change timestamp and normalized status;
4. current documented upload size is up to 1 GB, with uploads up to hourly.

This should be treated as a separate/legacy integration path, not confused with `partnerDisposition.send`.

## 18. Webhooks and lifecycle callbacks

Indeed documents jobs lifecycle event webhooks and application-delivery callbacks. These target partner-provided callback endpoints rather than one fixed Indeed URL, so they do not belong in a list of universal Indeed request routes.

Job Update documentation includes lifecycle status events. Indeed Apply uses partner `postUrl` callbacks for applications.

## 19. JavaScript integration surfaces

Indeed also documents browser-side integration products that are not command-line APIs:

```text
Publisher JavaScript Plugin
ATS JavaScript Plugin
Apply with Indeed
```

The ATS plugin can expose job visibility/sponsored-job controls in an ATS UI. Publisher JS is the current documented publisher/job-board integration path; it is distinct from the retired anonymous Publisher Job Search API.

## 20. Deprecated / historical surfaces

### Publisher Job Search API

The old public Publisher Job Search API is retired. Do not build a new CLI around its historical endpoint/key model.

### Indeed Interview API

Indeed's legal documentation explicitly marks the Indeed Interview API deprecated.

### Simulated GraphQL environment

Indeed announced removal of the simulated GraphQL environment effective 2026-06-30. Do not make it a dependency of a new client.

## 21. Sources

Current primary sources:

```text
https://docs.indeed.com/api-guides/
https://docs.indeed.com/integration-basics/
https://docs.indeed.com/api/graphql_schema
https://docs.indeed.com/public_graphql_schema.graphqls
https://docs.indeed.com/job-sync-api/
https://docs.indeed.com/job-update-api/
https://docs.indeed.com/employer-registration-api/
https://docs.indeed.com/send-candidates-api/
https://docs.indeed.com/retrieve-candidates-api/
https://docs.indeed.com/disposition-sync-api/
https://docs.indeed.com/hiring-lab-api/
https://docs.indeed.com/indeed-apply
https://docs.indeed.com/scim-api/scim-api-guide
https://docs.indeed.com/real-time-api/get-started
https://docs.indeed.com/disposition-data-api/
https://docs.indeed.com/release-notes
```

This file is intentionally an interface map rather than a copied mirror of Indeed's prose. For exact nested GraphQL fields and nullability, use the pinned snapshot date plus the downloadable SDL/reference above.
