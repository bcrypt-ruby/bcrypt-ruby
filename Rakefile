require 'rspec/core/rake_task'
require 'rubygems/package_task'
require 'rake/extensiontask'
require 'rake/javaextensiontask'
require 'rake/clean'
require 'rdoc/task'
require 'benchmark'

CLEAN.include(
  "tmp",
  "lib/bcrypt_ext.jar",
  "lib/bcrypt_ext.so"
)
CLOBBER.include(
  "doc",
  "pkg"
)

GEMSPEC = Gem::Specification.load("bcrypt.gemspec")

task :default => [:compile, :spec]

desc "Run all specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.ruby_opts = '-w'
end

desc "Run all specs, with coverage testing"
RSpec::Core::RakeTask.new(:rcov) do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rcov = true
  t.rcov_path = 'doc/coverage'
  t.rcov_opts = ['--exclude', 'rspec,diff-lcs,rcov,_spec,_helper']
end

desc 'Generate RDoc'
RDoc::Task.new do |rdoc|
  rdoc.rdoc_dir = 'doc/rdoc'
  rdoc.options += GEMSPEC.rdoc_options
  rdoc.template = ENV['TEMPLATE'] if ENV['TEMPLATE']
  rdoc.rdoc_files.include(*GEMSPEC.extra_rdoc_files)
end

Gem::PackageTask.new(GEMSPEC) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

if RUBY_PLATFORM =~ /java/
  Rake::JavaExtensionTask.new('bcrypt_ext', GEMSPEC) do |ext|
    ext.ext_dir = 'ext/jruby'
    ext.source_version = "1.8"
    ext.target_version = "1.8"
  end
else
  Rake::ExtensionTask.new("bcrypt_ext", GEMSPEC) do |ext|
    ext.ext_dir = 'ext/mri'
  end
end

desc "Run a set of benchmarks on the compiled extension."
task :benchmark do
  TESTS = 100
  TEST_PWD = "this is a test"
  require File.expand_path(File.join(File.dirname(__FILE__), "lib", "bcrypt"))
  Benchmark.bmbm do |results|
    4.upto(10) do |n|
      results.report("cost #{n}:") { TESTS.times { BCrypt::Password.create(TEST_PWD, :cost => n) } }
    end
  end
end
