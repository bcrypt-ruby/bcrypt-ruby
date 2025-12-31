Gem::Specification.new do |s|
  s.name = 'bcrypt'
  s.version = '3.1.21'

  s.summary = "OpenBSD's bcrypt() password hashing algorithm."
  s.description = <<-EOF
    bcrypt() is a sophisticated and secure hash algorithm designed by The OpenBSD project
    for hashing passwords. The bcrypt Ruby gem provides a simple wrapper for safely handling
    passwords.
  EOF

  s.files = Dir['CHANGELOG', 'COPYING', 'README.md', 'lib/**/*.rb', 'ext/**/*.*']
  s.require_path = 'lib'

  s.add_development_dependency 'rake-compiler', '~> 1.2.0'
  s.add_development_dependency 'rspec', '>= 3'
  s.add_development_dependency 'rdoc', '>= 7.0.3'
  s.add_development_dependency 'benchmark', '>= 0.5.0'

  s.rdoc_options += ['--title', 'bcrypt-ruby', '--line-numbers', '--inline-source', '--main', 'README.md']
  s.extra_rdoc_files += ['README.md', 'COPYING', 'CHANGELOG', *Dir['lib/**/*.rb']]

  s.extensions = 'ext/mri/extconf.rb'

  s.authors = ["Coda Hale"]
  s.email = "coda.hale@gmail.com"
  s.homepage = "https://github.com/bcrypt-ruby/bcrypt-ruby"
  s.license = "MIT"

  s.metadata["changelog_uri"] = s.homepage + "/blob/master/CHANGELOG"
end
