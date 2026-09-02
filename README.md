# Idriç CLI

Command-line tools that belong around Idriç but do not belong in the compiler itself.

This repository is the consolidation point for the CLI/API-access programs that were previously scattered across service-specific branches, especially `isomorphisms/az`.

## Current programs

- `bin/az` — Amazon product/price access and append-only price observations.
- `bin/abe` — AbeBooks delivered-price lookup and Impact affiliate links.
- `Ap.idric` — Associated Press API checkpoint.
- `Ballotpedia.idric` — executable Ballotpedia API4 page-one elections-by-state client, entirely in Idriç with ICU as its HTTP boundary.
- `Economist.idric` — Economist API checkpoint.
- `Ft.idric` — Financial Times API checkpoint.
- `Guardian.idric` — Guardian API checkpoint.
- `Nyt.idric` — New York Times API checkpoint.
- `Reddit.idric` — Reddit Data API checkpoint, with a synthetic fixture and manual receipt.
- `Reuters.idric` — Reuters GraphQL checkpoint.
- `Wayback.idric` — Internet Archive Wayback/CDX checkpoint.

The important Idriç sources are exposed at the repository top level so they can be inspected without digging through directories. Most are symbolic links to canonical sources under `checkpoints/`; Ballotpedia's top-level file is currently its canonical source.

Some Idriç clients intentionally contain named holes for compiler/library boundaries that are not implemented yet. Keep those boundaries visible; do not make a client appear green by silently substituting another HTTP implementation. Ballotpedia's former generic environment, header/body, and JSON holes have been replaced by executable boundaries and focused receipts; its remaining limits are recorded in `checkpoints/ballotpedia/README.md`.

## Networking

Where these clients need networking, ICU/Idric-Net remains the intended transport boundary. ICU is deliberately **not** a Git submodule here and is not pinned by this repository.

## Tests

`make test` runs the existing Amazon and AbeBooks smoke tests. Reddit retains a separate manual compiler checkpoint while named Idriç holes remain. Ballotpedia has a separate reproducible receipt:

```text
make ballotpedia-check IDRIC=/opt/Idric/_/build/exec/idris2
```

See `PROVENANCE.md` for the source branches copied into this repository.
