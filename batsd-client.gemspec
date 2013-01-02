Gem::Specification.new do |s|
  s.name        = "batsd-client"
  s.version     = '0.0.1'
  s.authors     = ["Ben Hathaway"]
  s.email       = ["ben@hathaway.cc"]
  s.homepage    = "http://github.com/hathaway/batsd-client"

  s.summary     = %q{A Batsd client for Ruby}
  s.description = %q{A Batsd client for Ruby. Provides an interface for querying data in a batsd server.}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
end