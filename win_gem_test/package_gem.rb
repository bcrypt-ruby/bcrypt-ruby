# frozen_string_literal: true

require 'rubygems'
require 'rubygems/package'

spec = Gem::Specification.load("./bcrypt.gemspec")

spec.files.concat ['Rakefile_wintest']
spec.files.concat Dir['lib/**/*.so']
spec.test_files = Dir['spec/**/*_spec.rb']

# below lines are required and not gem specific
spec.platform = ARGV[0]
spec.required_ruby_version = [">= #{ARGV[1]}", "< #{ARGV[2]}"]
spec.extensions = []
if spec.respond_to?(:metadata=)
  spec.metadata.delete("msys2_mingw_dependencies")
  spec.metadata['commit'] = ENV['commit_info']
end

Gem::Package.build(spec)
