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
arguments → Idriç validation → Ballotpedia request → ICU → HTTPS
          → ICU response → Idriç decoding → typed candidates → TSV
```

## Current execution boundary

This is an honest compiler/library checkpoint, not a shell-backed client.
The checked ICU path currently accepts only its fixed request headers and
returns transport status while streaming the HTTP response. Therefore the
source retains three named holes:

- environment lookup;
- ICU caller-supplied headers plus captured response body;
- Ballotpedia JSON decoding.

The `url` command and request validation do not need a key and define the
first executable acceptance surface. Do not fill the holes with curl,
Python, JavaScript, or another HTTP implementation. The next real step is
to extend the typed ICU interface, then discharge the decoder against the
synthetic fixture in this directory.
