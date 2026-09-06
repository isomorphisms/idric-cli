# Stripe CLI compiler checkpoint

This directory is the Idriç Stripe CLI checkpoint. Idriç is the implementation target; ICU/Idric-Net owns HTTP transport.

The first slice is deliberately read-only. Stripe has many operations that create, capture, refund, invoice, or pay out money. Those do not belong in the first transport/compiler checkpoint.

## Command contract

```text
stripe version
stripe url balance
stripe fixture FILE
stripe balance
```

### `version`

Print the API version pinned by this checkpoint:

```text
2026-08-26.dahlia
```

Stripe's API is account-versioned unless a request supplies `Stripe-Version`. Pinning the version makes the response contract reproducible.

### `url balance`

No network. Print:

```text
https://api.stripe.com/v1/balance
```

### `fixture`

No network. Read a Stripe Balance-shaped JSON file and emit TSV.

The committed synthetic fixture is:

```text
fixture/balance.json
```

Expected output is:

```text
fixture/expected.tsv
```

Columns are:

```text
state  currency  amount
```

`amount` is emitted as Stripe's integer value without converting it to a decimal. Keeping the currency code and integer intact avoids silently applying the wrong decimal convention to zero-decimal or other currencies.

### `balance`

Perform one authenticated `GET /v1/balance`, decode the same shape as the fixture, and emit the same TSV.

The process environment supplies:

```text
STRIPE_API_KEY=...
```

Do not accept a secret key as a positional command-line argument and do not commit a key. Restricted keys should be preferred when the eventual command needs only a subset of the account.

The request needs:

```text
Authorization: Bearer KEY
Stripe-Version: 2026-08-26.dahlia
```

Stripe documents both Basic and Bearer authentication. Bearer avoids introducing base64/basic-auth machinery solely for this client.

## Idriç and ICU

`idric/Stripe.idric` is the implementation target.

ICU/Idric-Net remains the networking boundary. The Stripe client currently exposes one narrow request seam: a GET carrying caller-supplied `Authorization` and `Stripe-Version` headers. Do not introduce a Stripe-specific socket/TLS implementation or a curl fallback.

The remaining named holes are intentionally visible:

- file input;
- Stripe Balance JSON decoding;
- environment access;
- authenticated ICU GET with caller-supplied headers.

The Reddit checkpoint already needs the same general caller-supplied-header capability. That should be solved once in Idric-Net/ICU rather than independently in each service client.

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

A focused failure at a named hole is useful evidence. Do not make it green with an unrelated implementation.

## Checkpoint ladder

1. source parses/checks;
2. `version` prints the pinned version;
3. `url balance` prints the exact endpoint;
4. `fixture` reads the synthetic file;
5. `fixture` decodes Balance and matches `expected.tsv` byte-for-byte;
6. `balance` reads `STRIPE_API_KEY` from the environment;
7. ICU sends `Authorization` and `Stripe-Version`;
8. live balance output uses the same TSV contract as the fixture;
9. add read-only list/retrieve resources with common cursor pagination;
10. add mutating operations only with explicit verbs and idempotency-key support.

See `SURFACE.md` for the API pass and sequencing.
