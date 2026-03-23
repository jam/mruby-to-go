MRuby::Build.new do |conf|
  toolchain :clang

  conf.gembox 'default-no-stdio'

  conf.cc do |cc|
    cc.flags << '-Os'
    cc.defines << 'MRB_USE_FLOAT32'
    cc.defines << 'MRB_GC_TURN_OFF_GENERATIONAL'
  end

  conf.disable_presym
end
