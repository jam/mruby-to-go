# Quick Start Guide

## Directory Structure

```
mruby-xcframework/
├── NOTES.md              ← Read this first! Comprehensive notes
├── TODO.md               ← Checklist of what needs to be done
├── README.md             ← User-facing documentation
├── Makefile              ← Helper commands
├── .gitignore            ← Git ignore rules
├── build-configs/        ← mruby build configurations
│   ├── minimal.rb        ← Needs fixing! Core language only
│   └── standard.rb       ← Needs fixing! Core + gems
├── scripts/              ← Build scripts
│   ├── build-apple-platforms.sh  ← Builds XCFramework
│   └── build-linux.sh            ← Builds Linux binaries
└── .github/workflows/    ← GitHub Actions (TODO)
```

## Quick Commands

```bash
# Test if basic setup works (macOS only)
make test-macos

# Build full XCFramework for Apple platforms
make apple-minimal    # Core language only
make apple-standard   # Core + useful gems

# Build for Linux
make linux-minimal
make linux-standard

# Clean everything
make clean
```

## First Steps

1. **Read NOTES.md** - It has all the context and known issues

2. **Fix the build configs:**
   - Open `build-configs/minimal.rb`
   - Look at `mruby-3.3.0/build_config/minimal.rb` for reference
   - Copy and adapt

3. **Test locally:**
   ```bash
   make test-macos
   ```

4. **If it works, try the full build:**
   ```bash
   make apple-minimal
   ```

## Key Files to Understand

- **build-configs/*.rb** - Ruby files that configure what to include in mruby
- **scripts/build-apple-platforms.sh** - Bash script that orchestrates cross-compilation
- **Makefile** - Convenience commands for development

## Expected Output

After successful build, you should have:

```
output/
└── mruby-minimal-apple.xcframework.zip  ← This is what we want!
```

## Integration with RubyTest

Once the XCFramework is built, update `RubyTest/RubyTestCore/Package.swift`:

```swift
.binaryTarget(
    name: "mruby",
    url: "https://github.com/YOU/mruby-xcframework/releases/download/v3.3.0/mruby-minimal-apple.xcframework.zip",
    checksum: "..."  // Calculate with: swift package compute-checksum file.zip
)
```

## Getting Help

- mruby build guide: https://github.com/mruby/mruby/blob/master/doc/guides/compile.md
- XCFramework guide: https://developer.apple.com/videos/play/wwdc2019/416/
- Look at existing cross-compile configs in `mruby-3.3.0/build_config/`

## Status

✅ Repository structure created
✅ Initial scripts and configs created
⚠️ Build configs need fixing (they won't work as-is)
⚠️ Scripts untested
❌ GitHub Actions not created yet

**Next:** Fix `build-configs/minimal.rb` and test with `make test-macos`
