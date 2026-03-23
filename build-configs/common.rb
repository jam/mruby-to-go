# Shared mruby build settings, used by both the Linux and Apple platform configs.
#
# Call apply_config(conf, profile) from any build config.
# Pass apple: true for MRuby::CrossBuild configs (Apple cross-compilation) to
# use a gembox that omits binary executables, which cannot be linked for
# iOS/tvOS/visionOS targets.

MRUBY_PROFILES = {
  'minimal'  => { opt: '-Os', defines: %w[MRB_USE_FLOAT32 MRB_GC_TURN_OFF_GENERATIONAL] },
  'standard' => { opt: '-O2', defines: %w[MRB_USE_FLOAT32] },
}.freeze

# Gembox paths per profile and platform family.
# Apple uses a custom gembox (full path) that omits binary executables.
GEMBOXES = {
  'minimal'  => { linux: 'default-no-stdio', apple: 'default-no-stdio' },
  'standard' => { linux: 'default',          apple: File.join(__dir__, 'standard-apple') },
}.freeze

def apply_config(conf, profile, apple: false)
  p = MRUBY_PROFILES.fetch(profile) { raise "Unknown mruby profile: #{profile}" }
  platform = apple ? :apple : :linux

  conf.gembox GEMBOXES.fetch(profile).fetch(platform)
  conf.cc do |cc|
    cc.flags << p[:opt]
    p[:defines].each { |d| cc.defines << d }
  end
  conf.disable_presym
end
