# Makefile for mruby-xcframework development

.PHONY: all clean apple-minimal apple-standard linux-minimal linux-standard test-macos

all: apple-minimal apple-standard

# Build for Apple platforms
apple-minimal:
	./scripts/build-apple-platforms.sh minimal

apple-standard:
	./scripts/build-apple-platforms.sh standard

# Build for Linux
linux-minimal:
	./scripts/build-linux.sh minimal

linux-standard:
	./scripts/build-linux.sh standard

# Quick test build on macOS only
test-macos:
	@echo "Building minimal config for macOS..."
	cd mruby && \
		export MRUBY_CONFIG="../build-configs/minimal.rb" && \
		make clean && \
		make -j$$(sysctl -n hw.ncpu)
	@echo "Build successful! Library at: mruby/build/host/lib/libmruby.a"
	@ls -lh mruby/build/host/lib/

# Clean everything
clean:
	rm -rf build/ output/ output-linux/
	@echo "Cleaned"
