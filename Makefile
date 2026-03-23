# Makefile for mruby-to-go local development

.PHONY: all apple-minimal apple-standard linux-minimal linux-standard \
        assemble-minimal assemble-standard clean

VERSION ?= $(shell git -C mruby describe --tags --exact-match 2>/dev/null || echo dev)

# ── Build ────────────────────────────────────────────────────────────────────

all: apple-minimal apple-standard linux-minimal linux-standard

apple-minimal:
	ruby scripts/build_apple.rb minimal

apple-standard:
	ruby scripts/build_apple.rb standard

# Uses Docker automatically on non-Linux hosts.
# Override arch with: LINUX_ARCH=arm64 make linux-minimal
linux-minimal:
	ruby scripts/build_linux.rb minimal

linux-standard:
	ruby scripts/build_linux.rb standard

# ── Assemble ─────────────────────────────────────────────────────────────────
# Run after all build targets. VERSION must be set (e.g. make assemble-minimal VERSION=3.3.0).

assemble-minimal:
	ruby scripts/assemble.rb minimal $(VERSION) --write-package-swift

assemble-standard:
	ruby scripts/assemble.rb standard $(VERSION)

# ── Clean ────────────────────────────────────────────────────────────────────

clean:
	rm -rf artifacts/ output/ build/
	@echo "Cleaned."
