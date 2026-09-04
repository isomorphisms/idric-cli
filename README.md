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
- `Handshake.idric` — Handshake EDU API checkpoint for jobs and job-role classifications, plus public job URLs.
- `Nyt.idric` — New York Times API checkpoint.
- `Reddit.idric` — Reddit Data API checkpoint, with a synthetic fixture and manual receipt.
- `Reuters.idric` — Reuters GraphQL checkpoint.
- `Wayback.idric` — Internet Archive Wayback/CDX checkpoint.

The top-level `.idric` files are symbolic links to the canonical sources under `checkpoints/`, so the important source is visible without digging through directories.

Some Idriç clients intentionally contain named holes for compiler/library boundaries that are not implemented yet. Keep those boundaries visible; do not make a client appear green by silently substituting another HTTP implementation.

## Networking

Where these clients need networking, ICU/Idric-Net remains the intended transport boundary. ICU is deliberately **not** a Git submodule here. While ICU's caller-header/capture stack is still pending, the Handshake compiler checkpoint checks out that current stack explicitly so its transport dependency is executable rather than replaced by curl or Python.

## Tests

`make test` runs the existing Amazon and AbeBooks smoke tests. Reddit and Handshake have separate compiler checkpoints under `checkpoints/`. Handshake now uses ICU's caller-declared credential-header surface from ICU #20: `x-api-key` is retained across same-origin redirects and stripped before a cross-origin request. The deterministic Handshake checkpoint exercises that redirect chain with a synthetic key and fixture response.

See `PROVENANCE.md` for the source branches copied into this repository.
