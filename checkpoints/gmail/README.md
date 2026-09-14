# Gmail CLI surface

This branch sketches a Gmail command-line client before implementation.

The intended mailbox semantics are server-backed, not local-only. If this client marks a message read or unread, stars it, archives it, or changes a label, the Gmail mailbox should change too.

## Recommended transport split

For an interactive mail client, prefer:

- IMAP for mailbox discovery, message retrieval, read/unread state, stars, labels, search, and mailbox synchronization;
- SMTP for sending mail;
- OAuth 2.0 / XOAUTH2 for authentication;
- the Gmail REST API as an alternate Gmail-native surface and for account settings or facilities that IMAP does not expose cleanly.

Gmail IMAP is at `imap.gmail.com:993` over TLS.

Gmail SMTP is at `smtp.gmail.com:587` with STARTTLS, or `smtp.gmail.com:465` with implicit TLS.

For IMAP/SMTP OAuth, Gmail documents the full-mail scope `https://mail.google.com/`.

## Mailbox-state rules

The client should not treat the local cache as authoritative.

- **open/read**: explicitly add the IMAP `\\Seen` flag;
- **mark unread**: remove `\\Seen`;
- **prefetch/cache**: use `BODY.PEEK[...]` so background retrieval does not accidentally set `\\Seen`;
- **star**: add/remove `\\Flagged`;
- **labels**: reflect the real Gmail labels, not private local folders;
- **archive**: remove Inbox membership while retaining the message in All Mail;
- **trash**: move to Gmail Trash, distinct from archive;
- **delete forever**: keep this separate and visibly destructive.

Gmail is label-based. IMAP presents labels as mailboxes/folders, but one message can carry several labels. Do not model those as independent copies.

## Gmail IMAP surface

IMAP is a command protocol, not a REST endpoint collection. The server endpoint is `imap.gmail.com:993`; the useful command surface is below.

### Session and authentication

- `CAPABILITY` — discover supported extensions.
- `AUTHENTICATE XOAUTH2 ...` — authenticate with an OAuth access token.
- `ID (...)` — identify this client; Google recommends this for Gmail IMAP clients.
- `NOOP` — keepalive / solicit pending updates.
- `LOGOUT` — end the session.

### Mailbox and label discovery

- `LIST` — list mailboxes/labels. Gmail includes Special-Use attributes such as `\\All`, `\\Drafts`, `\\Flagged`, `\\Important`, `\\Junk`, `\\Sent`, and `\\Trash`.
- `XLIST` — old Gmail-specific special-mailbox listing; deprecated. Do not build new code around it.
- `NAMESPACE` — discover namespace layout.
- `STATUS` — mailbox counts/status without selecting it.
- `SELECT` — open a mailbox read/write.
- `EXAMINE` — open a mailbox read-only.
- `CREATE` — create a Gmail user label/mailbox.
- `RENAME` — rename a Gmail user label/mailbox.
- `DELETE` — delete a Gmail user label/mailbox. Do not confuse deleting a label with deleting messages.
- `SUBSCRIBE` / `UNSUBSCRIBE` / `LSUB` — subscription-view management where useful.

### Message lookup and retrieval

Use UID forms once a mailbox is selected; do not confuse transient sequence numbers with stable-in-that-mailbox UIDs.

- `UID SEARCH ...` — search and return UIDs.
- `UID FETCH ...` — fetch flags, headers, bodies, sizes, Gmail IDs, labels, etc.
- `BODY.PEEK[...]` — retrieve content without implicitly marking it read.
- `RFC822.HEADER`, `BODY[HEADER...]`, `BODY[TEXT]`, MIME part fetches — selective retrieval.

### Server-side state changes

- `UID STORE <uid> +FLAGS.SILENT (\\Seen)` — mark read.
- `UID STORE <uid> -FLAGS.SILENT (\\Seen)` — mark unread.
- `UID STORE <uid> +FLAGS.SILENT (\\Flagged)` — star.
- `UID STORE <uid> -FLAGS.SILENT (\\Flagged)` — unstar.
- `UID STORE ... +X-GM-LABELS (...)` — add Gmail labels.
- corresponding `STORE` removal/replacement forms should be capability-tested against Gmail before relying on them for destructive/system-label changes.
- `APPEND` — append a MIME message to a mailbox, useful for drafts/import-like operations.
- `COPY` / `UID COPY` — copy mailbox membership according to IMAP semantics.
- `STORE ... \\Deleted` + `EXPUNGE` — deletion/expunge path. Gmail's configured expunge behavior can archive, trash, or permanently delete when the message is expunged from its last visible IMAP folder, so this must not be treated as a generic archive primitive without checking the account setting.
- `MOVE` or other newer commands must be used only if advertised by `CAPABILITY`.

### Synchronization

- `IDLE` — wait for mailbox changes instead of polling continuously.
- `NOOP`, `STATUS`, and UID-based re-scan — recovery/resynchronization tools.

For a first client, keep a local cache indexed by Gmail message ID plus mailbox UID mapping, and always be prepared to rebuild the mailbox-local UID mapping.

### Gmail-specific IMAP extensions (`X-GM-EXT-1`)

- `X-GM-RAW` in `SEARCH` / `UID SEARCH` — Gmail search syntax such as `from:`, `has:attachment`, `is:unread`, etc.
- `X-GM-MSGID` in `FETCH` / `SEARCH` — Gmail's stable message ID. The decimal value corresponds to the Gmail API/web message ID represented in hex there.
- `X-GM-THRID` in `FETCH` / `SEARCH` — Gmail thread/conversation ID.
- `X-GM-LABELS` in `FETCH`, `STORE`, and `SEARCH` — inspect and manipulate Gmail labels.

This is the strongest reason to prefer Gmail IMAP over inventing a local folder model: Gmail's own message IDs, conversation IDs, search language, and labels are visible through the protocol.

## SMTP surface

SMTP is separate from IMAP.

Session path:

- connect to `smtp.gmail.com:587`, then `EHLO`, `STARTTLS`, `EHLO`, `AUTH XOAUTH2`, or use implicit TLS on port 465;
- `MAIL FROM`;
- one or more `RCPT TO`;
- `DATA` containing the RFC/MIME message;
- `QUIT`.

Gmail automatically records successfully sent Gmail mail in Sent; do not create a second Sent copy merely because a generic mail client normally would.

## Gmail REST API v1

Base URL:

`https://gmail.googleapis.com/gmail/v1`

`{userId}` is normally the authenticated user's address or the special value `me`.

The list below is the current logical REST method surface. Media-upload variants use the corresponding `/upload/gmail/v1/...` or `/resumable/upload/gmail/v1/...` paths; they are transport variants of the same logical methods, not separate mailbox operations.

### Users

- `GET /users/{userId}/profile` — `users.getProfile`
- `POST /users/{userId}/watch` — `users.watch`
- `POST /users/{userId}/stop` — `users.stop`

### Drafts

- `GET /users/{userId}/drafts` — `drafts.list`
- `GET /users/{userId}/drafts/{id}` — `drafts.get`
- `POST /users/{userId}/drafts` — `drafts.create`
- `PUT /users/{userId}/drafts/{id}` — `drafts.update`
- `DELETE /users/{userId}/drafts/{id}` — `drafts.delete`
- `POST /users/{userId}/drafts/send` — `drafts.send`

### History

- `GET /users/{userId}/history` — `history.list`

History is the incremental Gmail API change feed keyed by history ID.

### Labels

- `GET /users/{userId}/labels` — `labels.list`
- `GET /users/{userId}/labels/{id}` — `labels.get`
- `POST /users/{userId}/labels` — `labels.create`
- `PUT /users/{userId}/labels/{id}` — `labels.update`
- `PATCH /users/{userId}/labels/{id}` — `labels.patch`
- `DELETE /users/{userId}/labels/{id}` — `labels.delete`

### Messages

- `GET /users/{userId}/messages` — `messages.list`
- `GET /users/{userId}/messages/{id}` — `messages.get`
- `POST /users/{userId}/messages` — `messages.insert`
- `POST /users/{userId}/messages/import` — `messages.import`
- `POST /users/{userId}/messages/send` — `messages.send`
- `POST /users/{userId}/messages/{id}/modify` — `messages.modify`
- `POST /users/{userId}/messages/{id}/trash` — `messages.trash`
- `POST /users/{userId}/messages/{id}/untrash` — `messages.untrash`
- `DELETE /users/{userId}/messages/{id}` — `messages.delete` (permanent)
- `POST /users/{userId}/messages/batchModify` — `messages.batchModify`
- `POST /users/{userId}/messages/batchDelete` — `messages.batchDelete` (permanent)
- `GET /users/{userId}/messages/{messageId}/attachments/{id}` — `messages.attachments.get`

For ordinary client state, `messages.modify` is the key operation: read/unread, Inbox/archive, stars, and user labels are represented by label additions/removals.

### Threads

- `GET /users/{userId}/threads` — `threads.list`
- `GET /users/{userId}/threads/{id}` — `threads.get`
- `POST /users/{userId}/threads/{id}/modify` — `threads.modify`
- `POST /users/{userId}/threads/{id}/trash` — `threads.trash`
- `POST /users/{userId}/threads/{id}/untrash` — `threads.untrash`
- `DELETE /users/{userId}/threads/{id}` — `threads.delete` (permanent)

### Settings: account-level

- `GET /users/{userId}/settings/autoForwarding` — `settings.getAutoForwarding`
- `PUT /users/{userId}/settings/autoForwarding` — `settings.updateAutoForwarding`
- `GET /users/{userId}/settings/imap` — `settings.getImap`
- `PUT /users/{userId}/settings/imap` — `settings.updateImap`
- `GET /users/{userId}/settings/language` — `settings.getLanguage`
- `PUT /users/{userId}/settings/language` — `settings.updateLanguage`
- `GET /users/{userId}/settings/pop` — `settings.getPop`
- `PUT /users/{userId}/settings/pop` — `settings.updatePop`
- `GET /users/{userId}/settings/vacation` — `settings.getVacation`
- `PUT /users/{userId}/settings/vacation` — `settings.updateVacation`

The IMAP settings include `autoExpunge`, `expungeBehavior`, and folder-size limits. This matters if the CLI uses standard IMAP delete/expunge operations to implement archive or trash.

### Settings: filters

- `GET /users/{userId}/settings/filters` — `filters.list`
- `GET /users/{userId}/settings/filters/{id}` — `filters.get`
- `POST /users/{userId}/settings/filters` — `filters.create`
- `DELETE /users/{userId}/settings/filters/{id}` — `filters.delete`

### Settings: forwarding addresses

- `GET /users/{userId}/settings/forwardingAddresses` — `forwardingAddresses.list`
- `GET /users/{userId}/settings/forwardingAddresses/{forwardingEmail}` — `forwardingAddresses.get`
- `POST /users/{userId}/settings/forwardingAddresses` — `forwardingAddresses.create`
- `DELETE /users/{userId}/settings/forwardingAddresses/{forwardingEmail}` — `forwardingAddresses.delete`

### Settings: delegates

- `GET /users/{userId}/settings/delegates` — `delegates.list`
- `GET /users/{userId}/settings/delegates/{delegateEmail}` — `delegates.get`
- `POST /users/{userId}/settings/delegates` — `delegates.create`
- `DELETE /users/{userId}/settings/delegates/{delegateEmail}` — `delegates.delete`

### Settings: send-as aliases

- `GET /users/{userId}/settings/sendAs` — `sendAs.list`
- `GET /users/{userId}/settings/sendAs/{sendAsEmail}` — `sendAs.get`
- `POST /users/{userId}/settings/sendAs` — `sendAs.create`
- `PUT /users/{userId}/settings/sendAs/{sendAsEmail}` — `sendAs.update`
- `PATCH /users/{userId}/settings/sendAs/{sendAsEmail}` — `sendAs.patch`
- `POST /users/{userId}/settings/sendAs/{sendAsEmail}/verify` — `sendAs.verify`
- `DELETE /users/{userId}/settings/sendAs/{sendAsEmail}` — `sendAs.delete`

### Settings: S/MIME on send-as aliases

- `GET /users/{userId}/settings/sendAs/{sendAsEmail}/smimeInfo` — `smimeInfo.list`
- `GET /users/{userId}/settings/sendAs/{sendAsEmail}/smimeInfo/{id}` — `smimeInfo.get`
- `POST /users/{userId}/settings/sendAs/{sendAsEmail}/smimeInfo` — `smimeInfo.insert`
- `POST /users/{userId}/settings/sendAs/{sendAsEmail}/smimeInfo/{id}/setDefault` — `smimeInfo.setDefault`
- `DELETE /users/{userId}/settings/sendAs/{sendAsEmail}/smimeInfo/{id}` — `smimeInfo.delete`

### Settings: client-side encryption identities

These are mostly Google Workspace / hardware-key facilities, not first-slice personal-mail client work.

- `GET /users/{userId}/settings/cse/identities` — `cse.identities.list`
- `GET /users/{userId}/settings/cse/identities/{emailAddress}` — `cse.identities.get`
- `POST /users/{userId}/settings/cse/identities` — `cse.identities.create`
- `PATCH /users/{userId}/settings/cse/identities/{emailAddress}` — `cse.identities.patch`
- `DELETE /users/{userId}/settings/cse/identities/{emailAddress}` — `cse.identities.delete`

### Settings: client-side encryption key pairs

- `GET /users/{userId}/settings/cse/keypairs` — `cse.keypairs.list`
- `GET /users/{userId}/settings/cse/keypairs/{keyPairId}` — `cse.keypairs.get`
- `POST /users/{userId}/settings/cse/keypairs` — `cse.keypairs.create`
- `POST /users/{userId}/settings/cse/keypairs/{keyPairId}:enable` — `cse.keypairs.enable`
- `POST /users/{userId}/settings/cse/keypairs/{keyPairId}:disable` — `cse.keypairs.disable`
- `POST /users/{userId}/settings/cse/keypairs/{keyPairId}:obliterate` — `cse.keypairs.obliterate`

## What belongs in the first CLI slice

Do not implement all of the REST API just because it exists.

The useful first Gmail client slice is:

1. OAuth token acquisition/refresh outside the mailbox data model.
2. IMAP XOAUTH2 login.
3. `LIST` / Special-Use discovery.
4. `SELECT INBOX`.
5. `UID SEARCH` and `UID FETCH` headers/flags/Gmail IDs/thread IDs/labels.
6. `BODY.PEEK[]` for explicit fetch without accidental read state.
7. explicit read/unread and star/unstar via `UID STORE`.
8. Gmail label add/remove with a regression fixture proving the exact `X-GM-LABELS` behavior used.
9. archive with a regression fixture proving that the message leaves Inbox but remains in All Mail.
10. trash with a separate fixture proving it enters Trash rather than being archived or permanently deleted.
11. SMTP XOAUTH2 send.
12. `IDLE` or a mechanically simple resync path.

Keep permanent deletion out of the initial interactive path.

## Acceptance boundary

A useful receipt should prove against a disposable Gmail test message that:

- fetching it for preview does not mark it read;
- opening it does mark it read in Gmail itself;
- marking unread reverses that state in Gmail itself;
- applying a user label is visible in Gmail itself;
- removing that label is visible in Gmail itself;
- archive removes Inbox membership but preserves the message in All Mail;
- trash moves it to Trash;
- a sent message appears exactly once in Gmail Sent;
- a reconnect/re-sync reconstructs the same state from the server rather than trusting stale local state.

Do not claim generic IMAP behavior as Gmail behavior until the Gmail-specific fixture establishes it.
