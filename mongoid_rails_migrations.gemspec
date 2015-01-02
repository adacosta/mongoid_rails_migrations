require File.join(File.dirname(__FILE__), 'lib', 'mongoid_rails_migrations', 'version')

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'mongoid_rails_migrations'
  s.version     = MongoidRailsMigrations::VERSION
  s.summary     = 'Data migrations for Mongoid in Active Record style, minus column input.'
  s.license     = 'MIT'
  s.description = 'Migrations for the migrator.'

  s.required_ruby_version     = '>= 1.8.6'
  s.required_rubygems_version = '>= 1.3.6'

  s.author            = 'Alan Da Costa'
  s.email             = 'alandacosta@gmail.com'
  s.date              = %q{2015-01-01}
  s.homepage          = 'http://github.com/adacosta/mongoid_rails_migrations'

  s.require_paths = ['lib']
  s.files         = Dir['.gitignore', 'Gemfile', 'Gemfile.lock', 'Rakefile', 'README.rdoc', 'mongoid_rails_migrations.gemspec', 'lib/**/*']
  s.test_files    = Dir['test/**/*']
  s.has_rdoc      = false

  rails_version = '>= 4.2.0'

  s.add_runtime_dependency('bundler', '>= 1.0.0')
  s.add_runtime_dependency('mongoid', '>= 4.0.0')
  s.add_runtime_dependency('rails',  rails_version)
  s.add_runtime_dependency('railties',  rails_version)
  s.add_runtime_dependency('activesupport',  rails_version)
end
