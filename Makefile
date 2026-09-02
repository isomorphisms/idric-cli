PREFIX ?= /usr/local
DESTDIR ?=
SHELL ?= /bin/sh
IDRIC ?= idris2

.PHONY: test ballotpedia ballotpedia-check install

test:
	bash test/az-test.sh
	bash test/abe-test.sh

ballotpedia:
	$(IDRIC) --build ballotpedia.ipkg

ballotpedia-check:
	sh test/ballotpedia/check

install:
	install -d "$(DESTDIR)$(PREFIX)/bin"
	install -m 0755 bin/az "$(DESTDIR)$(PREFIX)/bin/az"
	install -m 0755 bin/abe "$(DESTDIR)$(PREFIX)/bin/abe"
