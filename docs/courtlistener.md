# CourtListener CLI boundary

The first command is:

```text
edric courtlistener search "Brown v. Board of Education"
```

The Idriç layer owns the command grammar, the `CourtListener_Query`, the typed
search request, the CourtListener JSON fields, and human-readable output. It
constructs the documented v4 case-law search request with `type=o`.

ICU owns HTTP, TLS, redirects, response capture, and transport outcomes. The
CLI invokes the installed ICU command through an escaped argument list. It
does not contain sockets, TLS, HTTP framing, curl, or a second native adapter.
The required ICU response boundary is the existing API-client work that:

- accepts checked `-H` request headers;
- writes the response body to stdout;
- exits `10` for a non-2xx response;
- uses its other nonzero outcomes for request/network/transport failures.

Set `ICU` to the ICU executable when it is not on `PATH`. If supplied,
`COURTLISTENER_API_TOKEN` becomes `Authorization: Token ...` at the ICU header
boundary. Tokens are never accepted as command arguments or stored here.

The initial query encoder deliberately refuses non-ASCII input until the Idriç
UTF-8 percent-encoding boundary is available. It does not send malformed text
or silently reinterpret it.

The response decoder preserves fields that are present in the v4 opinion-search
response: `caseName`, `court`, `dateFiled`, `citation`, and `absolute_url`.
`court` and `dateFiled` remain optional; `citation` remains plural.

## Next records

`search` is the current resource. The next obvious endpoint is `dockets`,
followed by `docket-entries`. Likely later targets are `recap-documents`,
`parties`, `attorneys`, `clusters`, `opinions`, `opinions-cited`,
`citation-lookup`, `people`, `positions`, and `educations`.

These records can eventually support:

```text
school → person → position → court → case → docket entry → attorney → party
case → cites → case
```

This repository does not build that graph yet.
