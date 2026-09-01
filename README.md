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

The top-level `.idric` files are symbolic links to the canonical sources under `checkpoints/`, so the important source is visible without digging through directories.

Some Idriç clients intentionally contain named holes for compiler/library boundaries that are not implemented yet. Keep those boundaries visible; do not make a client appear green by silently substituting another HTTP implementation.

## Networking

Where these clients need networking, ICU/Idric-Net remains the intended transport boundary. ICU is deliberately **not** a Git submodule here and is not pinned by this repository.

## Tests

`make test` runs the existing Amazon and AbeBooks smoke tests. Reddit has a separate manual compiler checkpoint at `checkpoints/reddit/check`; it is not part of `make test` while named Idriç holes remain.

See `PROVENANCE.md` for the source branches copied into this repository.
