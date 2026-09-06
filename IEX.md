# IEX

IEX is useful here in two distinct historical/current forms.

## Historical: IEX Cloud

IEX Cloud was the unusually clean developer REST/JSON API. It is useful as an API-design reference, but it is no longer a live target: IEX Cloud products were retired on 2024-08-31.

Representative request shapes from the former API:

- `GET https://cloud.iexapis.com/stable/stock/{symbol}/quote?token=...`
- `GET https://cloud.iexapis.com/stable/stock/{symbol}/chart/{range}?token=...`
- `GET https://cloud.iexapis.com/stable/stock/market/batch?symbols=...&types=quote,chart&range=...&token=...`
- `GET https://cloud.iexapis.com/stable/ref-data/symbols?token=...`

These are historical interface notes, not endpoints that a new command-line program should depend on.

The still older IEX Exchange API, TOPS Viewer, and Stocks App were retired on 2021-11-18.

## Current: IEX Exchange market-data feeds

The current exchange-facing parser target is binary market data transported over IEX-TP v1:

- **TOPS v1.66** — top-of-book quotations plus last sale.
- **DEEP v1.08** — price-aggregated displayed depth plus last sale.
- **DEEP+ v1.02** — order-by-order displayed depth plus last sale.
- **HIST** — free T+1 historical market-data downloads, with the most recent twelve months available. The binary feeds are distributed as packet captures containing IEX-TP traffic.

Real-time direct feed access has subscriber/agreement requirements. HIST is the better parser-development source because it gives frozen public packet captures.

## Command-line parser progression

A useful program should grow from data inspection rather than a toy protocol:

1. inspect a HIST filename/catalog row and identify date, feed, feed version, and transport version;
2. read PCAP framing;
3. decode IEX-TP framing and sequencing;
4. decode TOPS message types;
5. decode DEEP price-level messages and maintain an aggregated book;
6. decode DEEP+ order-level messages and maintain order-by-order state;
7. emit normalized text/JSON/CSV to stdout for composition with other shell tools.

Possible command surface:

```text
iex hist
iex pcap FILE
iex tops FILE
iex deep FILE
iex deep-plus FILE
```

Do not assume that the latest specification revision describes every historical file. The HIST filenames/catalog identify the protocol/feed version used for a capture; decoding should select the matching layout.

## Official sources

- Market-data products: https://www.iex.io/products/equities/market-data-connectivity
- Current specifications and sample PCAPs: https://www.iex.io/resources/trading/market-data
- Historical downloads: https://iextrading.com/trading/market-data/
- IEX Cloud closure reference: https://iexcloud.org/

Snapshot checked: 2026-09-06.
