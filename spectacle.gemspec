# frozen_string_literal: true

require_relative "lib/spectacle/version"

Gem::Specification.new do |spec|
  spec.name = "spectacle"
  spec.version = Spectacle::VERSION
  spec.authors = ["Mitch Smith"]
  spec.email = ["mitchpsmith1998@gmail.com"]

  spec.summary = "A Ruby gem that provides a simple way to only run spec files relevant to the changes you've made."
  spec.homepage = "https://github.com/mitchbne/spectacle"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://packages.buildkite.com/spectacle/spectacle"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/mitchbne/spectacle"
  spec.metadata["changelog_uri"] = "https://github.com/mitchbne/spectacle/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
