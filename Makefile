# Makefile for mruby-xcframework development

.PHONY: all clean apple-minimal apple-standard linux-minimal linux-standard test-macos

VERSION ?= 3.3.0

all: apple-minimal apple-standard

# Download mruby source
mruby-$(VERSION):
	@echo "Downloading mruby $(VERSION)..."
	curl -L https://github.com/mruby/mruby/archive/refs/tags/$(VERSION).tar.gz -o mruby.tar.gz
	tar -xzf mruby.tar.gz
	rm mruby.tar.gz

# Build for Apple platforms
apple-minimal: mruby-$(VERSION)
	./scripts/build-apple-platforms.sh minimal $(VERSION)

apple-standard: mruby-$(VERSION)
	./scripts/build-apple-platforms.sh standard $(VERSION)

# Build for Linux
linux-minimal: mruby-$(VERSION)
	./scripts/build-linux.sh minimal $(VERSION)

linux-standard: mruby-$(VERSION)
	./scripts/build-linux.sh standard $(VERSION)

# Quick test build on macOS only
test-macos: mruby-$(VERSION)
	@echo "Building minimal config for macOS..."
	cd mruby-$(VERSION) && \
		export MRUBY_CONFIG="../build-configs/minimal.rb" && \
		make clean && \
		make -j$$(sysctl -n hw.ncpu)
	@echo "Build successful! Library at: mruby-$(VERSION)/build/host/lib/libmruby.a"
	@ls -lh mruby-$(VERSION)/build/host/lib/

# Clean everything
clean:
	rm -rf build/ build-*/ output/ output-*/
	rm -rf mruby-*/ *.tar.gz *.zip
	@echo "Cleaned"
