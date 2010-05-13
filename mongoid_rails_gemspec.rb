Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'mongoid_rails_migrations'
  s.version     = '0.0.1'
  s.summary     = 'Data migrations for Mongoid in Active Record style, minus column input.'
  s.description = 'Sometimes you just need to migrate data.'

  # only tested with 1.9.1, but let's go for it
  s.required_ruby_version     = '>= 1.8.6'
  s.required_rubygems_version = ">= 1.3.6"

  s.author            = 'Alan Da Costa'
  s.email             = 'alandacosta@gmail.com.com'
  # s.homepage          = ''
  
  s.files        = Dir['Gemfile', 'Rakefile', 'README.rdoc', 'VERSION', 'lib/**/*', 'test/**/*']
  s.require_path = 'lib'

	rails_version = '3.0.0.beta3'
	
	s.add_dependency('bundler', '>= 0.9.19')
	s.add_dependency('mongoid', '2.0.0.beta4')
  s.add_dependency('rails',  rails_version)
  s.add_dependency('railties',  rails_version)
  s.add_dependency('activesupport',  rails_version)
end