# J.P. Morgan Online Payments API surface pass

Audit baseline: 2026-09-06.

Online Payments API specification release observed in the official changelog: `2.19.0` (2026-08-04).

This inventory is for the **Online Payments API only**. Checkout, Disputes, Wallet Decryption, Merchant Configuration, Treasury, Embedded Payments, and the other J.P. Morgan Payments APIs are separate surfaces and are not silently mixed into this client.

Canonical references:

- API reference: https://developer.payments.jpmorgan.com/api/home
- Online Payments overview: https://developer.payments.jpmorgan.com/api/commerce/online-payments/overview
- Online Payments changelog: https://developer.payments.jpmorgan.com/api/commerce/online-payments/online-payments/changelog
- Online Payments response codes: https://developer.payments.jpmorgan.com/api/commerce/online-payments/online-payments/error-codes
- OAuth authentication: https://developer.payments.jpmorgan.com/api/commerce/online-payments/oauth-authentication
- Quick start: https://developer.payments.jpmorgan.com/docs/quick-start
- authorize/capture guide: https://developer.payments.jpmorgan.com/docs/commerce/online-payments/capabilities/online-payments/how-to/auth-and-capture-payment
- refund guide: https://developer.payments.jpmorgan.com/docs/commerce/online-payments/capabilities/online-payments/how-to/refund-payment
- verification guide: https://developer.payments.jpmorgan.com/docs/commerce/online-payments/capabilities/online-payments/how-to/verify-payment
- fraud-score guide: https://developer.payments.jpmorgan.com/docs/commerce/online-payments/capabilities/online-payments/how-to/fraud-scores

## Wire contract

The documented mock major-version base is:

```text
https://api-mock.payments.jpmorgan.com/api/v2
```

J.P. Morgan documents Online Payments versioning in the URL prefix (`v2`). The product's specification has its own release number; the latest changelog entry in this pass is `2.19.0`.

The Quick Start request carries JSON and uses OAuth bearer authentication plus merchant and request identifiers:

```text
Accept: application/json
Content-Type: application/json
Authorization: Bearer ACCESS_TOKEN
merchant-id: MERCHANT_ID
request-id: REQUEST_ID
minorVersion: ...
```

The first read-only checkpoint does not acquire OAuth tokens itself. Keep client credentials/private keys outside source. `JPMORGAN_ACCESS_TOKEN` supplies an already-issued bearer token and `JPMORGAN_MERCHANT_ID` supplies the processing merchant identifier.

## Complete Online Payments endpoint inventory

The current surface pass yields 16 HTTP operations across payments, captures, refunds, verifications, and fraud checks.

| Method | Path | Meaning | First CLI phase |
| --- | --- | --- | --- |
| `POST` | `/payments` | Create/authorize a payment; capture can be immediate depending on request | later write |
| `GET` | `/payments` | Retrieve a payment by `requestId` query parameter | read |
| `GET` | `/payments/{id}` | Retrieve a payment by transaction ID | first live read |
| `PATCH` | `/payments/{id}` | Update a payment; documented uses include incremental authorization, reversal/void, and reauthorization | later write |
| `POST` | `/payments/{id}/captures` | Capture a previously authorized payment; supports split/multiple capture cases | later write |
| `GET` | `/captures` | Retrieve capture/payment details by `requestId` | read |
| `GET` | `/captures/{id}` | Retrieve capture/payment details by transaction ID | read |
| `POST` | `/refunds` | Create full, partial, standalone, or capture-related refund | later write |
| `GET` | `/refunds` | Retrieve a refund by `requestId` | read |
| `GET` | `/refunds/{id}` | Retrieve a refund by transaction ID | read |
| `POST` | `/verifications` | Verify a payment instrument | later write-like request, no money movement |
| `GET` | `/verifications` | Retrieve verification details by `requestId` | read |
| `GET` | `/verifications/{id}` | Retrieve verification details by transaction ID | read |
| `POST` | `/fraudcheck` | Request a fraud score/check | later request |
| `GET` | `/fraudcheck` | Retrieve fraud-check details by `requestId` | read |
| `GET` | `/fraudcheck/{id}` | Retrieve fraud-check details by transaction ID | read |

The no-network `jpmorgan endpoints` command emits exactly this operation set in machine-friendly TSV form.

## Identifier model

Do not collapse J.P. Morgan's identifiers into one generic `id` in the normalized model. Important values include:

- `transactionId` — identifies a payment/refund/verification/fraud transaction and is used by path retrieval forms;
- `requestId` — caller/request identifier, also usable to retrieve several resource types through query forms;
- `paymentRequestId` — groups payment request state;
- `authorizationId` — identifies an authorization;
- `captureId` — identifies a capture;
- `refundId` — identifies a refund where present;
- `networkTransactionId` — network-side identifier, not interchangeable with J.P. Morgan's transaction ID;
- `merchantOrderNumber` — merchant business/order reference.

The first fixture keeps `transactionId` and `requestId` separate. Later capture/refund fixtures should preserve their nested identifiers rather than flattening them into one opaque string.

## Response model

The Quick Start payment response exposes a useful stable diagnostic spine:

```text
transactionId
requestId
transactionState
responseStatus
responseCode
responseMessage
amount
currency
```

The first TSV contract uses all except the human-readable response message. Keep the integer amount intact; currency-specific decimal presentation belongs above the wire model.

`transactionState` and `responseStatus` answer different questions. The former describes transaction lifecycle state; the latter reports the request/business result (`SUCCESS`, `DENIED`, or `ERROR`). Do not merge them into one status field.

## Read side first

The first implementation slice is deliberately narrow:

1. print the specification release;
2. print every endpoint/method pair;
3. construct a transaction-ID payment retrieval URL;
4. decode a synthetic payment response;
5. retrieve one payment from the mock environment using an already-issued token.

Then add the other GET forms before implementing payment mutations. This exercises URL construction, OAuth headers, request IDs, JSON decoding, and stable CLI output without accidentally creating or moving money.

## Mutation boundary

The write/request surfaces are not interchangeable generic POSTs:

- `POST /payments` may authorize and/or capture money;
- `PATCH /payments/{id}` can alter an existing authorization, including reauthorization and reversal/void cases;
- `POST /payments/{id}/captures` completes all or part of a manual authorization and can participate in multiple-capture shipment flows;
- `POST /refunds` can return captured funds and has full, partial, standalone, and multi-capture cases;
- `POST /verifications` checks a payment instrument without being a payment;
- `POST /fraudcheck` asks for a fraud decision/score rather than processing the payment itself.

Give each one a named CLI verb and typed request model. Do not expose a primary `post PATH JSON` interface that erases the consequence differences.

`request-id` is also part of duplicate-request handling, so mutation support needs explicit tests for retry/duplicate behavior before it is treated as safe.

## Expansion order

1. Endpoint inventory and exact URL construction.
2. Synthetic payment retrieval fixture.
3. Live mock `GET /payments/{id}` through ICU/Idric-Net.
4. `GET /payments?requestId=...`.
5. Capture GET forms and capture-specific fixture.
6. Refund GET forms and refund-specific fixture.
7. Verification GET forms and fixture.
8. Fraud-check GET forms and fixture.
9. Shared OAuth/merchant/request-id header construction.
10. Typed request bodies for `POST /verifications` and `POST /fraudcheck`.
11. `POST /payments` only in mock/test usage with duplicate-request receipts.
12. `POST /payments/{id}/captures` with full/partial/multiple-capture fixtures.
13. `PATCH /payments/{id}` with separate fixtures for each supported update intent.
14. `POST /refunds` with full/partial/standalone/multi-capture fixtures.
15. Production base/configuration only after the client-specific environment contract is known; do not guess production endpoints from the mock hostname.

Each resource follows the same receipt pattern: exact URL and headers, synthetic fixture, byte-stable output, mock/live transport, then consequence-specific write tests.
