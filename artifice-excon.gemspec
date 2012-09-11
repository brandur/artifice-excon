Gem::Specification.new do |gem|
  gem.name        = "artifice-excon"
  gem.version     = "0.1.3"

  gem.author      = "Brandur"
  gem.email       = "brandur@mutelight.org"
  gem.homepage    = "https://github.com/brandur/artifice-excon"
  gem.license     = "MIT"
  gem.summary     = "A version of Wycat's Artifice for use with Excon."

  gem.files       = %w{lib/artifice/excon.rb}

  gem.add_dependency "excon"
  gem.add_dependency "rack-test"
end
