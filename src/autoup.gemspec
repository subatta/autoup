Gem::Specification.new do |s|
  s.name        = 'autoup'
  s.version     = '1.0.0'
  s.date        = '2016-09-13'
  s.summary     = 'Given a project dependency chain, updates versions, builds, tests and creates nuget packages that are applied downstream'
  s.description = 'Automated Upgrade/Update Gem. Provides nuget version upgrades'
  s.authors     = ['Suresh Batta']
  s.email       = 'subatta@hotmail.com'
  s.files       = Dir['{test,lib,rakefile.rb}/**/*'] + ['autoup.gemspec']
  s.homepage    = 'http://rubygems.org/gems/autoup'
  s.license     = 'MIT'
end