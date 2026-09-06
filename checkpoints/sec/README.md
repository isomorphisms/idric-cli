# SEC EDGAR checkpoint

Read-only command-line access to the SEC's documented public EDGAR data surfaces.

## Endpoints

The first slice exposes:

- `submissions CIK10` — current filing history and filer metadata.
- `companyfacts CIK10` — all standard-taxonomy XBRL facts for one filer.
- `companyconcept CIK10 TAXONOMY TAG` — one standard XBRL concept for one filer.
- `frame TAXONOMY TAG UNIT PERIOD` — one XBRL fact across reporting entities for a calendar frame.
- `tickers` — company ticker / CIK / name associations.
- `ticker-exchanges` — company / CIK / ticker / exchange associations.
- `mutual-fund-tickers` — fund CIK / series / class / ticker associations.
- `bulk-submissions` — nightly submissions archive.
- `bulk-companyfacts` — nightly XBRL company-facts archive.

CIKs passed to the `data.sec.gov` endpoints are the SEC's 10-digit zero-padded form, without the `CIK` prefix. For Apple, for example, use `0000320193`.

## URL-only use

`url` prints the endpoint without performing a request:

```text
sec url submissions 0000320193
sec url companyfacts 0000320193
sec url companyconcept 0000320193 us-gaap AssetsCurrent
sec url frame us-gaap AccountsPayableCurrent USD CY2025Q4I
sec url tickers
sec url bulk-submissions
```

## Network use

The public data APIs require no API key. SEC automated-access policy does require a declared User-Agent identifying the requester and a contact address. The checkpoint therefore requires `SEC_USER_AGENT` before any network request, for example:

```text
SEC_USER_AGENT='Example Research example@example.org' sec submissions 0000320193
```

The actual HTTP operation remains a named ICU/Idric-Net hole: `?icu_get_with_user_agent_and_forward_stdout`. Do not replace it with curl or another transport merely to make the checkpoint look complete.

## Scope

This checkpoint intentionally does **not** implement EDGAR Next filer-management or filing-submission APIs. Those are authenticated write-capable interfaces with filer/user tokens and should be added as a separate authenticated slice rather than conflated with public EDGAR data access.

## Sources

- SEC, EDGAR Application Programming Interfaces (APIs): https://www.sec.gov/search-filings/edgar-application-programming-interfaces
- SEC, Accessing EDGAR Data: https://www.sec.gov/search-filings/edgar-search-assistance/accessing-edgar-data
- SEC, Developer Resources: https://www.sec.gov/about/developer-resources
