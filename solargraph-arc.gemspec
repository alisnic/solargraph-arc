
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "solargraph/arc/version"

Gem::Specification.new do |spec|
  spec.name          = "solargraph-arc"
  spec.version       = Solargraph::Arc::VERSION
  spec.authors       = ["Andrei Lisnic"]
  spec.email         = ["andrei.lisnic@gmail.com"]

  spec.summary       = %q{Awesome Rails Completions for solargraph}
  spec.description   = %q{Awesome Rails Completions for solargraph}
  spec.homepage      = "https://github.com/alisnic/solargraph-arc"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
    spec.metadata["changelog_uri"] = "https://github.com/alisnic/solargraph-arc/blob/master/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.9.0"
  spec.add_development_dependency "pry", "~> 0.14.1"
  spec.add_dependency "solargraph", "~> 0.44.2"
  spec.add_dependency "activesupport", "~> 6.1.4.1"
end
