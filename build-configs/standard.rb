MRuby::Build.new do |conf|
  toolchain :clang

  conf.gembox 'default'

  conf.cc do |cc|
    cc.flags << '-O2'
    cc.defines << 'MRB_USE_FLOAT32'
  end

  conf.disable_presym
end
