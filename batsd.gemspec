$:.unshift File.expand_path("../lib", __FILE__)

require "batsd/version"

Gem::Specification.new do |s|
    s.name          = "batsd"

    s.version       = Batsd::VERSION

    s.homepage      = "https://github.com/hathaway/batsd-client"
    s.authors       = ["Ben Hathaway"]
    s.email         = ["ben@hathaway.cc"]

    s.summary       = "Batsd Client"
    s.description   = "A Batsd client for Ruby. Provides an interface for querying data in a batsd server."

    s.files         = `git ls-files`.split("\n")
end