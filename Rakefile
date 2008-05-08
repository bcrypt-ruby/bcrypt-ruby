gem "rspec"
require "spec/rake/spectask"
require 'rake/gempackagetask'
require 'rake/contrib/rubyforgepublisher'
require 'rake/clean'
require 'rake/rdoctask'
require "benchmark"

PKG_NAME = "bcrypt-ruby"
PKG_VERSION   = "2.0.3"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"
PKG_FILES = FileList[
  '[A-Z]*',
  'lib/**/*.rb', 
  'spec/**/*.rb', 
  'ext/*.c',
  'ext/*.h',
  'ext/*.rb'
]
CLEAN.include(
  "ext/*.o",
  "ext/*.bundle",
  "ext/*.so"  
)
CLOBBER.include(
  "doc/coverage"
)

task :default => [:compile, :spec]

desc "Run all specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--color','--backtrace','--diff']
  t.rcov = true
  t.rcov_dir = 'doc/coverage'
  t.rcov_opts = ['--exclude', 'spec\/spec,spec\/.*_spec.rb']
end

namespace :spec do
  desc "Run all specs and store html output in doc/specs.html"
  Spec::Rake::SpecTask.new('html') do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts = ['--diff','--format html','--backtrace','--out doc/specs.html']
  end
end

desc 'Generate RDoc'
rd = Rake::RDocTask.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options << '--title' << 'bcrypt-ruby' << '--line-numbers' << '--inline-source' << '--main' << 'README'
  rdoc.template = ENV['TEMPLATE'] if ENV['TEMPLATE']
  rdoc.rdoc_files.include('README', 'COPYING', 'CHANGELOG', 'lib/**/*.rb')
end

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.summary = "OpenBSD's bcrypt() password hashing algorithm."
  s.description = <<-EOF
    bcrypt() is a sophisticated and secure hash algorithm designed by The OpenBSD project
    for hashing passwords. bcrypt-ruby provides a simple, humane wrapper for safely handling
    passwords.
  EOF

  s.files = PKG_FILES.to_a
  s.require_path = 'lib'

  s.has_rdoc = true
  s.rdoc_options = rd.options
  s.extra_rdoc_files = rd.rdoc_files.to_a
  
  s.extensions = FileList["ext/extconf.rb"].to_a
  
  s.authors = ["Coda Hale"]
  s.email = "coda.hale@gmail.com"
  s.homepage = "http://bcrypt-ruby.rubyforge.org"
  s.rubyforge_project = "bcrypt-ruby"
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

desc "Clean, then compile the extension."
task :compile => [:clean] do
  Dir.chdir('./ext')
  system "ruby extconf.rb"
  system "make"
  Dir.chdir('..')
end

desc "Run a set of benchmarks on the compiled extension."
task :benchmark do
  TESTS = 100
  TEST_PWD = "this is a test"
  require "lib/bcrypt"
  Benchmark.bmbm do |results|
    4.upto(10) do |n|
      results.report("cost #{n}:") { TESTS.times { BCrypt::Password.create(TEST_PWD, :cost => n) } }
    end
  end
end
