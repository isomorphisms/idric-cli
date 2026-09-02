# Ballotpedia CLI checkpoint

The Idriç command is:

```text
ballotpedia url MI 2026-11-03
ballotpedia elections MI 2026-11-03
```

It constructs an API4 `/data/elections_by_state` request and reads the API
key from `BALLOTPEDIA_API_KEY`. The key is sent only as the `x-api-key`
header.

Ownership stays explicit:

```text
arguments → Idriç validation → ICU command → HTTPS
          → captured response body → Idriç JSON decoding → typed candidates → TSV
```

The request uses Ballotpedia's `election_date` parameter and explicitly asks
for page 1. The response decoder follows the available nested shape:

```text
data → districts → races → candidates → person / party_affiliation
```

The earlier checkpoint's `date` parameter and flat `data.candidates` fixture
were not supported by the available client implementations and have been
removed.

## Re-evaluated boundaries

The three original named holes are no longer one undifferentiated block:

- Idriç #64 supplies `environment_value`; the later source-layout change
  accidentally dropped it from the buildable library tree, so the acceptance
  workflow pins the narrow restoration until that regression is merged.
- ICU #13 accepts checked repeatable `-H` values, writes the response body to
  stdout, and assigns distinct nonzero outcomes to HTTP and transport failure.
  Ballotpedia invokes that command through `System.run`; there is no second
  HTTP implementation here.
- `Language.JSON` performs the parse, and the Ballotpedia module projects the
  nested fixture into a typed candidate record before rendering TSV.

The remaining boundaries are specific rather than generic library holes:

- page 1 is implemented; following every Ballotpedia page is not;
- the nested synthetic fixture covers person name/id, party affiliation, and
  optional district/race names, but a captured live response fixture is still
  needed before claiming the rest of Ballotpedia's paid response contract;
- no live receipt runs without an explicitly supplied Ballotpedia API key.

`BALLOTPEDIA_API_BASE` exists for deterministic local receipts. Normal use
leaves it unset and uses `https://api4.ballotpedia.org/data/elections_by_state`.

The request parameter, pagination, and `data.districts` envelope are also
consistent with the available Ballotpedia Python client implementation. A
separate public adapter corroborates the nested races, candidates, person, and
party-affiliation path. Neither source substitutes for a retained live fixture.

The `url` command and deterministic fixture receipt do not need a key. The
production path remains Idriç plus ICU; curl, Python, JavaScript, and SDKs are
not fallback transports.

Sources used to correct the checkpoint:

- <https://github.com/Mwithalii/mobile/blob/46feafb8b14b470d190584ca14cb03d196ee6406/mobile/Lib/site-packages/ballotpedia/api.py>
- <https://github.com/cliffpyles/Hops/blob/606a799d0404f362bc2e560048203baedd9db7e4/pipelines/sources/ballotpedia/politicians.py>
