# J.P. Morgan Online Payments CLI compiler checkpoint

This directory is the Idriç checkpoint for J.P. Morgan's Online Payments API. It is intentionally scoped to Online Payments rather than every API on the J.P. Morgan Payments portal.

The first slice is read-only. The API has operations that create, update, capture, refund, verify, and fraud-score payment activity; money-moving writes do not belong in the first transport/compiler checkpoint.

## Command contract

```text
jpmorgan version
jpmorgan endpoints
jpmorgan url payment TRANSACTION_ID
jpmorgan fixture FILE
jpmorgan payment TRANSACTION_ID
```

### `version`

Print the Online Payments API specification version used for this pass:

```text
2.19.0
```

The URL major version remains `v2`; the specification release is tracked separately because J.P. Morgan updates fields and enums within that major-version surface.

### `endpoints`

No network. Print the complete Online Payments endpoint inventory captured in `SURFACE.md` as TSV:

```text
method  path  action
```

This includes all 16 method/path operations in the current surface pass: payments, captures, refunds, verifications, and fraud checks.

### `url payment`

No network. Build the mock-environment URL for transaction-id retrieval:

```text
https://api-mock.payments.jpmorgan.com/api/v2/payments/TRANSACTION_ID
```

### `fixture`

No network. Read an Online Payments payment-response-shaped JSON file and emit TSV.

The committed synthetic fixture is:

```text
fixture/payment.json
```

Expected output is:

```text
fixture/expected.tsv
```

Columns are:

```text
transaction_id  request_id  state  status  code  amount  currency
```

`amount` remains the integer value returned by the API; the checkpoint does not guess a decimal convention from the currency.

### `payment`

Retrieve one payment by transaction ID from the mock Online Payments v2 base, decode the same shape as the fixture, and emit the same TSV.

The process environment supplies:

```text
JPMORGAN_ACCESS_TOKEN=...
JPMORGAN_MERCHANT_ID=...
```

The request seam carries:

```text
Authorization: Bearer ACCESS_TOKEN
merchant-id: MERCHANT_ID
request-id: freshly generated UUID
Accept: application/json
```

Token acquisition is deliberately outside this first slice. J.P. Morgan uses OAuth 2.0 client credentials; a separately acquired bearer token is enough to exercise the client without putting client secrets into this repository or command-line arguments.

## Idriç and ICU

`idric/JPMorgan.idric` is the implementation target.

ICU/Idric-Net remains the networking boundary. The J.P. Morgan checkpoint adds no private socket/TLS implementation and no curl fallback. The generic transport needs to support caller-supplied headers; this is the same underlying seam already exposed by the Reddit and Stripe checkpoints.

The remaining named holes are intentionally visible:

- file input;
- Online Payments JSON decoding;
- environment access;
- UUID request-id generation;
- authenticated ICU GET with caller-supplied headers.

Do not replace these with a hidden untyped implementation merely to make the checkpoint green.

## Manual receipt

Run:

```text
ysh check
```

or:

```text
IDRIC=/opt/Idric/build/exec/idris2 ysh check
```

The runner emits only:

```text
PASS    checkpoint
FAIL    checkpoint
SKIP    checkpoint
```

A focused failure at a named hole is useful evidence of the remaining compiler/library boundary.

## Checkpoint ladder

1. source parses/checks;
2. `version` prints `2.19.0`;
3. `endpoints` prints the byte-stable 16-operation inventory;
4. `url payment ID` prints the exact mock v2 URL;
5. `fixture` reads the synthetic file;
6. `fixture` decodes a payment response and matches `expected.tsv` byte-for-byte;
7. `payment` reads the bearer token and merchant ID from the environment;
8. request-id generation produces a fresh value;
9. ICU sends Authorization, merchant-id, request-id, and Accept headers;
10. live mock payment retrieval uses the same TSV contract as the fixture;
11. add request-id lookup forms for payments/captures/refunds/verifications/fraud checks;
12. add mutating commands only after request bodies, consequence-specific verbs, and duplicate-request behavior have fixtures and tests.

See `SURFACE.md` for the audited endpoint list and sequencing.
