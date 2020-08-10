require_relative 'lib/chainpoint/ruby/version'

Gem::Specification.new do |spec|
  spec.name          = "chainpoint-ruby"
  spec.version       = Chainpoint::Ruby::VERSION
  spec.authors       = ["Rifatul Islam Chayon", "A.T.M. Hassan Uzzaman Sajib"]
  spec.email         = ["rifatulchayon@gmail.com", "sajib.hassan@gmail.com"]

  spec.summary       = "Ruby Client for Chainpoint API v4"
  spec.description   = "Ruby Client for Chainpoint API v4"
  spec.homepage      = "https://github.com/nigh7m4r3/chainpoint-ruby"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  spec.metadata["allowed_push_host"] = "TODO Set to 'http://mygemserver.com'"

  spec.metadata["homepage_uri"] = "https://github.com/nigh7m4r3/chainpoint-ruby"
  spec.metadata["source_code_uri"] = "https://github.com/nigh7m4r3/chainpoint-ruby"
  spec.metadata["changelog_uri"] = "TODO Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
