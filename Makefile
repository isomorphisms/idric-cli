PREFIX ?= /usr/local
DESTDIR ?=
SHELL ?= /bin/sh

.PHONY: test install

test:
	bash test/az-test.sh
	bash test/abe-test.sh

install:
	install -d "$(DESTDIR)$(PREFIX)/bin"
	install -m 0755 bin/az "$(DESTDIR)$(PREFIX)/bin/az"
	install -m 0755 bin/abe "$(DESTDIR)$(PREFIX)/bin/abe"
