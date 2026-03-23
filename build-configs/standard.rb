load File.join(__dir__, 'common.rb')

MRuby::Build.new do |conf|
  toolchain :gcc
  apply_config(conf, 'standard')
end
