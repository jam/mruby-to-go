# Shared mruby build settings, used by both the Linux and Apple platform configs.
#
# Defines apply_config(conf, profile) which sets the gembox, compiler flags,
# defines, and other options that are common across all target platforms.
#
# Platform-specific settings (toolchain, CC/AR paths, -target/-isysroot) are
# left to the caller.

MRUBY_PROFILES = {
  'minimal' => { gembox: 'default-no-stdio', opt: '-Os',  defines: %w[MRB_USE_FLOAT32 MRB_GC_TURN_OFF_GENERATIONAL] },
  'standard' => { gembox: 'default',         opt: '-O2',  defines: %w[MRB_USE_FLOAT32] },
}.freeze

def apply_config(conf, profile)
  p = MRUBY_PROFILES.fetch(profile) { raise "Unknown mruby profile: #{profile}" }
  conf.gembox p[:gembox]
  conf.cc do |cc|
    cc.flags << p[:opt]
    p[:defines].each { |d| cc.defines << d }
  end
  conf.disable_presym
end
