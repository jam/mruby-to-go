#!/usr/bin/env ruby
# Build mruby static library for the current Linux architecture.
# On non-Linux hosts, re-runs itself inside Docker.
# Output: artifacts/<config>/linux-<arch>/lib/libmruby.a
#         artifacts/<config>/include/
#
# Override the Docker target architecture with LINUX_ARCH=arm64 (default: amd64).

require 'fileutils'
require_relative 'platform'

CONFIG = ARGV[0] || 'minimal'

# On non-Linux, re-exec inside Docker for the target architecture.
unless RUBY_PLATFORM.include?('linux')
  docker_arch = ENV.fetch('LINUX_ARCH', 'amd64')
  puts "Non-Linux host — building inside Docker (linux/#{docker_arch})..."
  exec(
    'docker', 'run', '--rm',
    '--platform', "linux/#{docker_arch}",
    '-v', "#{REPO_ROOT}:/work",
    '-w', '/work',
    'debian:bookworm-slim',
    'bash', '-c',
    "set -e && apt-get update -qq && apt-get install -y -qq gcc make ruby bison && ruby scripts/build_linux.rb #{CONFIG}"
  )
end

RAW_ARCH     = `uname -m`.strip                          # x86_64 or aarch64
PLATFORM_NAME = "linux-#{RAW_ARCH == 'aarch64' ? 'arm64' : RAW_ARCH}"
ARTIFACTS_DIR = File.join(REPO_ROOT, 'artifacts', CONFIG)
MRUBY_DIR     = File.join(REPO_ROOT, 'mruby')

def sh(cmd)
  puts "  $ #{cmd}"
  system(cmd) || abort("Command failed: #{cmd}")
end

puts "Building mruby (#{CONFIG}) for #{PLATFORM_NAME}..."

Dir.chdir(MRUBY_DIR) do
  ENV['MRUBY_CONFIG'] = File.join(REPO_ROOT, 'build-configs', "#{CONFIG}.rb")
  ENV['CC']  = 'gcc'
  ENV['AR']  = 'ar'
  ENV['LD']  = 'gcc'
  sh 'make clean'
  sh "make -j#{`nproc`.strip}"
end

out = File.join(ARTIFACTS_DIR, PLATFORM_NAME)
FileUtils.mkdir_p("#{out}/lib")
FileUtils.cp("#{MRUBY_DIR}/build/host/lib/libmruby.a", "#{out}/lib/")

dst_include = File.join(ARTIFACTS_DIR, 'include')
FileUtils.cp_r("#{MRUBY_DIR}/include", dst_include) unless Dir.exist?(dst_include)

puts "Done. Artifact in: artifacts/#{CONFIG}/#{PLATFORM_NAME}/"
