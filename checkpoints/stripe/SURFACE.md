# Stripe API surface pass

Audit baseline: 2026-09-06.

Pinned API version for this checkpoint: `2026-08-26.dahlia`.

Canonical references:

- API reference: https://docs.stripe.com/api
- authentication: https://docs.stripe.com/api/authentication
- versioning: https://docs.stripe.com/api/versioning
- pagination: https://docs.stripe.com/api/pagination
- idempotent requests: https://docs.stripe.com/api/idempotent_requests
- key handling: https://docs.stripe.com/keys-best-practices
- public GA OpenAPI: https://github.com/stripe/openapi/tree/master/latest

The GA OpenAPI `latest/` directory contains a unified public specification for both v1 and v2. The repository master observed for this pass was commit `58e06a3214ae1574600fba64d40b770e5da6d505`; the public YAML blob was `0eeb1665acf426ce068aac8cac6092db5739d363`.

## Wire contract

Base URL:

```text
https://api.stripe.com
```

v1 requests use resource-oriented paths. Request bodies for the v1 API are form-encoded and responses are JSON. Authentication is by API key. This client uses bearer auth so the key remains a direct header value rather than introducing Basic-auth encoding.

Always send:

```text
Authorization: Bearer $STRIPE_API_KEY
Stripe-Version: 2026-08-26.dahlia
```

The secret belongs in the environment or a secrets store, never in source. Prefer a restricted key with the smallest permissions that cover the command.

## First read-side inventory

These are the useful command-line surfaces to implement before money-moving writes.

| Resource | Read endpoints to cover | CLI priority |
| --- | --- | --- |
| Balance | `GET /v1/balance` | 1 |
| Balance transactions | `GET /v1/balance_transactions`, `GET /v1/balance_transactions/:id` | 2 |
| PaymentIntents | `GET /v1/payment_intents`, `GET /v1/payment_intents/:id`, search | 3 |
| Charges | `GET /v1/charges`, `GET /v1/charges/:id`, search | 3 |
| Refunds | `GET /v1/refunds`, `GET /v1/refunds/:id` | 4 |
| Payouts | `GET /v1/payouts`, `GET /v1/payouts/:id` | 4 |
| Customers | `GET /v1/customers`, `GET /v1/customers/:id`, search | 5 |
| Products | `GET /v1/products`, `GET /v1/products/:id`, search | 6 |
| Prices | `GET /v1/prices`, `GET /v1/prices/:id`, search | 6 |
| Checkout Sessions | `GET /v1/checkout/sessions`, retrieve, line items | 7 |
| Subscriptions | `GET /v1/subscriptions`, retrieve, search | 8 |
| Invoices | `GET /v1/invoices`, retrieve, search | 8 |
| Events | `GET /v1/events`, `GET /v1/events/:id` | 9 |

The first committed checkpoint implements only Balance. It is the smallest authenticated read with no pagination or user-supplied query parameters, so it isolates the transport/header and JSON-decoding boundaries cleanly.

## Pagination

v1 list endpoints share cursor pagination:

```text
limit
starting_after
ending_before
```

`starting_after` and `ending_before` are mutually exclusive. List results contain `data`, `has_more`, and `url`.

Do not hide pagination behind an unbounded fetch-all default. A CLI should expose a bounded page size and explicit continuation. v2 pagination is different and should be modeled separately rather than pretending it is v1.

## Mutation boundary

Important write surfaces include:

- PaymentIntents: create, update, confirm, capture, cancel;
- Customers: create, update, delete;
- Refunds: create, update, cancel where supported;
- Payouts: create, update, cancel, reverse;
- Products and Prices: create/update, plus product delete;
- Checkout Sessions: create/update/expire;
- Subscriptions: create/update/cancel/migrate/resume;
- Invoices: create/update/finalize/pay/send/void/delete draft invoices.

Do not make a generic `post PATH ...` command the primary interface. These operations have materially different consequences and should get named commands with typed inputs.

All Stripe `POST` requests accept idempotency keys. When writes are added, every mutating command should either require or generate an idempotency key and make the chosen key observable without leaking other secrets. GET and DELETE do not need idempotency keys.

## Payment model

PaymentIntents are the primary modern payment workflow. Charges still have list/retrieve/search value, but direct Charge creation is legacy for most new integrations. Sequence the client accordingly: PaymentIntents first, Charges mainly as observable payment-attempt records.

## Event model

Events are read-only through the API and are useful for diagnosis and replay-oriented tooling. Webhook/event-destination configuration is a separate surface. Keep event retrieval independent from any future local webhook listener so the CLI remains useful without a daemon.

## Expansion order

1. Balance fixture + live balance.
2. Shared v1 list envelope and cursor types.
3. Balance transactions.
4. PaymentIntent list/retrieve/search.
5. Charge list/retrieve/search.
6. Refund and payout read side.
7. Customer list/retrieve/search.
8. Product/Price read side.
9. Checkout Session read side.
10. Subscription/Invoice read side.
11. Event list/retrieve.
12. Write request body encoding + idempotency keys.
13. Named write commands, starting in sandbox/test usage.
14. v2 resources as a distinct namespace with its own pagination/response contracts.

Each new resource gets the same receipt pattern: exact URL construction, synthetic fixture, byte-stable output contract, then live transport through ICU/Idric-Net.
