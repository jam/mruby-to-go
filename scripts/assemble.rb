#!/usr/bin/env ruby
# Assemble built artifacts into release packages:
#   - Per-triple artifact bundle zips  (one per platform/arch)
#   - Artifact bundle index            (.artifactbundleindex — what Package.swift references)
#   - Universal artifact bundle zip    (all variants in one download)
#   - XCFramework zip                  (Apple platforms, requires xcodebuild + lipo)
#   - Package.swift                    (with --write-package-swift flag)
#
# Usage: ruby scripts/assemble.rb <config> <mruby_version> [--write-package-swift]

require 'json'
require 'fileutils'
require 'digest'
require 'tmpdir'
require_relative 'platform'

abort "Usage: assemble.rb <config> <mruby_version> [--write-package-swift]" if ARGV.length < 2

CONFIG           = ARGV[0]
VERSION          = ARGV[1]
WRITE_PKG_SWIFT  = ARGV.include?('--write-package-swift')

ARTIFACTS_DIR = File.join(REPO_ROOT, 'artifacts', CONFIG)
OUTPUT_DIR    = File.join(REPO_ROOT, 'output')
INCLUDE_DIR   = File.join(ARTIFACTS_DIR, 'include')

FileUtils.mkdir_p(OUTPUT_DIR)

def sh(cmd)
  puts "  $ #{cmd}"
  system(cmd) || abort("Failed: #{cmd}")
end

def sha256(path)
  Digest::SHA256.file(path).hexdigest
end

# Build a .artifactbundle directory in tmp, return its path.
# Each variant dir contains: libmruby.a + include/ (SE-0482 staticLibrary layout).
def make_bundle_dir(tmp, platforms)
  bundle = File.join(tmp, 'mruby.artifactbundle')

  variants = platforms.map do |platform|
    src_lib = File.join(ARTIFACTS_DIR, platform[:name], 'lib', 'libmruby.a')
    abort "Missing artifact: #{src_lib}" unless File.exist?(src_lib)

    variant_dir = File.join(bundle, 'mruby', platform[:name])
    FileUtils.mkdir_p(variant_dir)
    FileUtils.cp(src_lib, File.join(variant_dir, 'libmruby.a'))
    FileUtils.cp_r(INCLUDE_DIR, File.join(variant_dir, 'include'))

    { path: "mruby/#{platform[:name]}", supportedTriples: [platform[:triple]] }
  end

  File.write(
    File.join(bundle, 'info.json'),
    JSON.pretty_generate(
      schemaVersion: '1.0',
      artifacts: {
        mruby: { version: VERSION, type: 'staticLibrary', variants: variants }
      }
    )
  )

  bundle
end

puts "Assembling mruby #{VERSION} (#{CONFIG} profile)..."
puts

# ── Per-triple artifact bundles ───────────────────────────────────────────────

archive_entries = []

ALL_PLATFORMS.each do |platform|
  zip_name = "mruby-#{CONFIG}-#{VERSION}-#{platform[:name]}.artifactbundle.zip"
  zip_path = File.join(OUTPUT_DIR, zip_name)

  Dir.mktmpdir do |tmp|
    bundle = make_bundle_dir(tmp, [platform])
    sh "cd #{tmp} && zip -qr #{zip_path} #{File.basename(bundle)}"
  end

  cs = sha256(zip_path)
  puts "  #{zip_name}"
  archive_entries << { fileName: zip_name, checksum: cs, supportedTriples: [platform[:triple]] }
end

puts

# ── Artifact bundle index ─────────────────────────────────────────────────────

index_name = "mruby-#{CONFIG}-#{VERSION}.artifactbundleindex"
index_path = File.join(OUTPUT_DIR, index_name)
File.write(index_path, JSON.pretty_generate(schemaVersion: '1.0', archives: archive_entries))
puts "  #{index_name}"

# ── Universal artifact bundle ─────────────────────────────────────────────────

universal_zip_name = "mruby-#{CONFIG}-#{VERSION}.artifactbundle.zip"
universal_zip_path = File.join(OUTPUT_DIR, universal_zip_name)

Dir.mktmpdir do |tmp|
  bundle = make_bundle_dir(tmp, ALL_PLATFORMS)
  sh "cd #{tmp} && zip -qr #{universal_zip_path} #{File.basename(bundle)}"
end
puts "  #{universal_zip_name}"
puts

# ── XCFramework (Apple only, requires xcodebuild + lipo) ─────────────────────

if system('which xcodebuild > /dev/null 2>&1')
  puts "Creating XCFramework..."

  Dir.mktmpdir do |tmp|
    # macOS needs a lipo-merged universal binary — xcodebuild rejects two libs
    # with the same SDK identifier.
    macos_universal = File.join(tmp, 'libmruby-macos-universal.a')
    sh [
      'lipo -create',
      "#{ARTIFACTS_DIR}/macos-arm64/lib/libmruby.a",
      "#{ARTIFACTS_DIR}/macos-x86_64/lib/libmruby.a",
      "-output #{macos_universal}"
    ].join(' ')

    per_platform_libs = APPLE_PLATFORMS
      .reject { |p| p[:name].start_with?('macos-') }
      .flat_map { |p| ['-library', "#{ARTIFACTS_DIR}/#{p[:name]}/lib/libmruby.a", '-headers', INCLUDE_DIR] }

    xcfw_name = "mruby-#{CONFIG}-#{VERSION}.xcframework"
    xcfw_path = File.join(tmp, xcfw_name)

    sh [
      'xcodebuild -create-xcframework',
      *per_platform_libs,
      '-library', macos_universal, '-headers', INCLUDE_DIR,
      '-output', xcfw_path
    ].join(' ')

    xcfw_zip = File.join(OUTPUT_DIR, "#{xcfw_name}.zip")
    sh "cd #{tmp} && zip -qr #{xcfw_zip} #{xcfw_name}"
    puts "  #{File.basename(xcfw_zip)}"
  end

  puts
else
  puts "Skipping XCFramework (xcodebuild not available)"
end

# ── Package.swift ─────────────────────────────────────────────────────────────

if WRITE_PKG_SWIFT
  puts "Generating Package.swift..."

  index_cs   = sha256(index_path)
  index_url  = "https://github.com/jam/mruby-to-go/releases/download/v#{VERSION}/#{index_name}"

  pkg = <<~SWIFT
    // swift-tools-version: 6.0
    // Generated for mruby #{VERSION} (#{CONFIG} profile) — do not edit by hand.
    // https://github.com/jam/mruby-to-go
    import PackageDescription

    let package = Package(
        name: "mruby",
        products: [
            .library(name: "mruby", targets: ["mruby"]),
        ],
        targets: [
            // Downloads only the slice needed for your build target (SE-0482).
            .binaryTarget(
                name: "mruby",
                url: "#{index_url}",
                checksum: "#{index_cs}"
            ),
        ]
    )
  SWIFT

  File.write(File.join(REPO_ROOT, 'Package.swift'), pkg)
  puts "  Package.swift"
  puts
end

puts "Done. Output in: output/"
