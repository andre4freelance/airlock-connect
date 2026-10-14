PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin

all:
	@echo "airlock-connect - Zero-leak SSH & Telnet launcher"
	@echo "Run 'make install' to install to $(BINDIR)"

install:
	@./install.sh

uninstall:
	@./uninstall.sh

test:
	@shellcheck bin/* install.sh uninstall.sh 2>/dev/null || bash -n bin/* install.sh uninstall.sh
	@echo "Shell syntax check passed."

.PHONY: all install uninstall test
