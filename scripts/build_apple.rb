#!/usr/bin/env ruby
# Build mruby static libraries for all Apple platforms.
# Output: artifacts/<config>/<platform-name>/lib/libmruby.a
#         artifacts/<config>/include/

require 'fileutils'
require 'tempfile'
require_relative 'platform'

CONFIG           = ARGV[0] || 'minimal'
ARTIFACTS_DIR    = File.join(REPO_ROOT, 'artifacts', CONFIG)
MRUBY_DIR        = File.join(REPO_ROOT, 'mruby')
BUILD_CONFIGS_DIR = File.join(REPO_ROOT, 'build-configs')

def sh(cmd)
  puts "  $ #{cmd}"
  system(cmd) || abort("Command failed: #{cmd}")
end

def xcrun(sdk, *args)
  result = `xcrun --sdk #{sdk} #{args.join(' ')} 2>/dev/null`.strip
  abort("xcrun --sdk #{sdk} #{args.join(' ')} failed") if result.empty?
  result
end

def build_platform(platform)
  name   = platform[:name]
  sdk    = platform[:sdk]
  target = platform[:target]

  puts "\n=== #{name} (#{target}) ==="

  sdk_path = xcrun(sdk, '--show-sdk-path')
  cc_path  = xcrun(sdk, '--find clang')
  ar_path  = xcrun(sdk, '--find ar')

  Tempfile.create(['mruby-', '.rb']) do |f|
    f.write(<<~RUBY)
      load "#{BUILD_CONFIGS_DIR}/common.rb"

      MRuby::CrossBuild.new("#{name}") do |conf|
        toolchain :clang
        conf.cc do |cc|
          cc.command = "#{cc_path}"
          cc.flags = ["-target #{target}", "-isysroot #{sdk_path}"]
        end
        conf.archiver { |ar| ar.command = "#{ar_path}" }
        conf.linker   { |l|  l.command  = "#{cc_path}" }
        apply_config(conf, "#{CONFIG}")
      end
    RUBY
    f.flush

    Dir.chdir(MRUBY_DIR) do
      sh "MRUBY_CONFIG=#{f.path} make clean"
      sh "MRUBY_CONFIG=#{f.path} make -j#{`sysctl -n hw.ncpu`.strip}"
    end
  end

  out = File.join(ARTIFACTS_DIR, name)
  FileUtils.mkdir_p("#{out}/lib")
  FileUtils.cp("#{MRUBY_DIR}/build/#{name}/lib/libmruby.a", "#{out}/lib/")

  # Headers are identical across platforms — copy once from any build
  dst_include = File.join(ARTIFACTS_DIR, 'include')
  FileUtils.cp_r("#{MRUBY_DIR}/include", dst_include) unless Dir.exist?(dst_include)
end

puts "Building mruby (#{CONFIG}) for Apple platforms..."

# Clean only Apple platform dirs so Linux artifacts survive a re-run
APPLE_PLATFORMS.each { |p| FileUtils.rm_rf(File.join(ARTIFACTS_DIR, p[:name])) }
FileUtils.rm_rf(File.join(REPO_ROOT, 'build'))
FileUtils.mkdir_p(ARTIFACTS_DIR)

APPLE_PLATFORMS.each { |p| build_platform(p) }

puts "\nDone. Artifacts in: artifacts/#{CONFIG}/"
