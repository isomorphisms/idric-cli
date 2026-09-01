# Idriç CLI

Command-line tools that belong around Idriç but do not belong in the compiler itself.

This repository is the consolidation point for the CLI/API-access programs that were previously scattered across service-specific branches, especially `isomorphisms/az`.

## Current programs

- `bin/az` — Amazon product/price access and append-only price observations.
- `bin/abe` — AbeBooks delivered-price lookup and Impact affiliate links.
- `Ap.idric` — Associated Press API checkpoint.
- `Economist.idric` — Economist API checkpoint.
- `Ft.idric` — Financial Times API checkpoint.
- `Guardian.idric` — Guardian API checkpoint.
- `Nyt.idric` — New York Times API checkpoint.
- `Reddit.idric` — Reddit Data API checkpoint, with a synthetic fixture and manual receipt.
- `Reuters.idric` — Reuters GraphQL checkpoint.
- `Wayback.idric` — Internet Archive Wayback/CDX checkpoint.
- `CourtListener.idric` — executable CourtListener v4 case-law search through ICU.

The top-level `.idric` files are symbolic links to their canonical sources, so the important source is visible without digging through directories.

Some Idriç clients intentionally contain named holes for compiler/library boundaries that are not implemented yet. Keep those boundaries visible; do not make a client appear green by silently substituting another HTTP implementation.

## CourtListener

Build and run the first legal-search command with:

```text
make courtlistener IDRIC=/opt/Idric/build/exec/idris2
edric courtlistener search "Brown v. Board of Education"
```

The installed ICU command owns HTTP and TLS. `ICU=/path/to/icu` selects it when
it is not on `PATH`; `COURTLISTENER_API_TOKEN` supplies optional token
authentication through ICU's checked header boundary. See
[`docs/courtlistener.md`](docs/courtlistener.md) for the exact ownership and
response contracts.

## Networking

Where these clients need networking, ICU/Idric-Net remains the intended transport boundary. ICU is deliberately **not** a Git submodule or pinned runtime dependency here. The CourtListener acceptance workflow pins a reviewed ICU revision only so its receipt is reproducible.

## Tests

`make test` runs the existing Amazon and AbeBooks smoke tests. Reddit has a separate manual compiler checkpoint at `checkpoints/reddit/check`; it is not part of `make test` while named Idriç holes remain.

See `PROVENANCE.md` for the source branches copied into this repository.

The CourtListener receipt is separate because it requires the Idriç compiler,
Idric-Net, contrib, and ICU:

```text
make courtlistener-check IDRIC=/opt/Idric/build/exec/idris2
```
