PREFIX ?= /usr/local
DESTDIR ?=
SHELL ?= /bin/sh
IDRIC ?= idris2

.PHONY: test courtlistener courtlistener-check install

test:
	bash test/az-test.sh
	bash test/abe-test.sh

courtlistener:
	$(IDRIC) --build courtlistener.ipkg

courtlistener-check:
	sh test/courtlistener/check

install:
	install -d "$(DESTDIR)$(PREFIX)/bin"
	install -m 0755 bin/az "$(DESTDIR)$(PREFIX)/bin/az"
	install -m 0755 bin/abe "$(DESTDIR)$(PREFIX)/bin/abe"
	if test -x build/exec/edric; then \
		install -m 0755 build/exec/edric "$(DESTDIR)$(PREFIX)/bin/edric"; \
	fi
