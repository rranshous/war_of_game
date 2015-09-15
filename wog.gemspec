Gem::Specification.new do |s|
  s.name        = 'wog'
  s.version     = '0.1.1'
  s.platform    = Gem::Platform::RUBY
  s.authors     = 'Robby Ranshous'
  s.email       = 'rranshous@gmail.com'
  s.homepage    = 'http://oneinchmile.com'
  s.summary     = 'game/simulation played by bots, prototype DO NOT USE'
  s.description = 'game/simulation played by bots, prototype DO NOT USE'

  s.executables << 'test_player_against'

  s.files        = Dir['**/*','*']
  s.require_path = './'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'pry'
end


