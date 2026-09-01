# Reddit CLI compiler checkpoint

This directory is the Idriç Reddit CLI checkpoint. Idriç is the only implementation target here.

The earlier Ithon and Fieldmouse drafts were removed deliberately. Do not maintain parallel Reddit clients merely to keep a language comparison alive; this is now a real Idriç dogfood case.

## Command contract

```text
reddit url QUERY
reddit fixture FILE
reddit search QUERY
```

`QUERY` is one command-line argument. Quote a multiword query in the shell. Reddit search operators such as `subreddit:`, `author:`, and `site:` remain part of the query string; this checkpoint does not invent a second search language.

### `url`

No network. Print the authenticated Data API search URL for `QUERY`:

```text
https://oauth.reddit.com/search?raw_json=1&limit=25&sort=relevance&t=all&q=...
```

For the common fixture query `industrial maintenance`, the expected encoding is `industrial%20maintenance`.

### `fixture`

No network. Read a Reddit Listing-shaped JSON file and emit TSV.

The committed synthetic fixture is:

```text
fixture/search.json
```

The required output is:

```text
fixture/expected.tsv
```

Columns are:

```text
created_utc  score  subreddit  author  title  permalink
```

Tabs and newlines inside text fields are flattened to spaces. `permalink` is expanded to a full `https://www.reddit.com/...` URL.

### `search`

Build the same URL, perform one authenticated `GET`, decode the Listing, and emit the same TSV shape as `fixture`.

The process environment supplies:

```text
REDDIT_ACCESS_TOKEN=...
REDDIT_USER_AGENT=...
```

The request needs both:

```text
Authorization: Bearer TOKEN
User-Agent: USER_AGENT
```

The checkpoint deliberately does not implement Reddit OAuth token acquisition. A separately acquired access token is enough for the first live client.

## Idriç and ICU

`idric/Reddit.idric` is the implementation target.

ICU now consumes Idric-Net for typed URL, destination-port, HTTP request, byte-count, and transport values. That removes the earlier duplicated-network-model problem. Reddit still exposes one narrow transport gap: the current Idric-Net/ICU request path renders fixed headers rather than accepting caller-supplied `Authorization` and `User-Agent` headers.

Idric-Net already has typed `HttpHeader`, `HeaderName`, and `HeaderValue` values. The next networking change belongs there and in ICU's send surface, not in a second Reddit-specific HTTP implementation.

The remaining named holes in `Reddit.idric` are intentionally visible:

- percent encoding;
- TSV field cleanup and absolute Reddit permalinks;
- file input;
- Reddit Listing JSON decoding;
- environment access;
- authenticated ICU GET with caller-supplied headers.

Do not replace any of these with an untyped shell, Python, curl, or another hidden HTTP fallback merely to make the checkpoint green.

## Manual receipt

`check` checks the Idriç source only.

```text
ysh check
```

or:

```text
IDRIC=/opt/Idric/build/exec/idris2 ysh check
```

It emits only:

```text
PASS    checkpoint
FAIL    checkpoint
SKIP    checkpoint
```

The source currently contains named holes, so a focused `FAIL` is useful evidence of the exact remaining compiler/library boundary.

## Checkpoint ladder

The Idriç implementation advances through these checkpoints:

1. source parses/checks;
2. `url` receives a command argument;
3. `url` percent-encodes it correctly;
4. `fixture` reads the synthetic file;
5. `fixture` decodes the Listing and matches `expected.tsv` byte-for-byte;
6. `search` reads token and user-agent from the environment;
7. `search` performs the authenticated ICU request;
8. live Listing output uses the same TSV contract as the fixture.

A regression should fail at a named boundary instead of merely producing "Reddit tool broken".
