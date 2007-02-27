gem "rspec"
require "spec/rake/spectask"
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
require 'rake/clean'
require 'rake/rdoctask'

PKG_NAME = "bcrypt-ruby"
PKG_VERSION   = "1.0.0"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"
PKG_FILES = FileList[
  '[A-Z]*',
  'lib/**/*.rb', 
  'spec/**/*.rb', 
  'ext/*.c',
  'ext/*.h',
  'ext/*.rb'
]

task :default => [:spec]

desc "Run all specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--color','--backtrace','--diff']
  t.rcov = true
  t.rcov_dir = 'doc/output/coverage'
  t.rcov_opts = ['--exclude', 'spec\/spec,spec\/.*_spec.rb']
end

desc "Run all specs and store html output in doc/output/report.html"
Spec::Rake::SpecTask.new('spec_html') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--diff','--format html','--backtrace','--out doc/output/report.html']
end

desc 'Generate RDoc'
rd = Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/output/rdoc'
  rdoc.options << '--title' << 'bcrypt-ruby' << '--line-numbers' << '--inline-source' << '--main' << 'README'
  rdoc.template = ENV['TEMPLATE'] if ENV['TEMPLATE']
  rdoc.rdoc_files.include('README', 'COPYING', 'lib/**/*.rb')
end

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = "Blah."
  s.description = <<-EOF
    Woot.
  EOF

  s.files = PKG_FILES.to_a
  s.require_path = 'lib'

  s.has_rdoc = true
  s.rdoc_options = rd.options
  s.extra_rdoc_files = rd.rdoc_files.to_a
  
  s.extensions = FileList["ext/extconf.rb"].to_a
  
  s.autorequire = 'bcrypt'
  s.author = ["Coda Hale"]
  s.email = "coda.hale@gmail.com"
  s.homepage = "http://bcrypt-ruby.rubyforge.org"
  s.rubyforge_project = "bcrypt-ruby"
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

task :compile do
  Dir.chdir('./ext')
  system "ruby extconf.rb"
  system "make"
end