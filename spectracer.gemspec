# frozen_string_literal: true

require_relative "lib/spectracer/version"

Gem::Specification.new do |spec|
  spec.name = "spectracer"
  spec.version = Spectracer::VERSION
  spec.authors = ["Mitch Smith"]
  spec.email = ["mitchpsmith1998@gmail.com"]

  spec.summary = "Intelligent test selection based on code changes"
  spec.description = <<~DESC
    Spectracer traces RSpec and Minitest dependencies to determine which specs 
    to run based on git changes. It builds a dependency map during test execution,
    then uses this data to run only the tests affected by your changes.
  DESC
  spec.homepage = "https://github.com/mitchbne/spectracer"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.metadata = {
    "allowed_push_host" => "https://rubygems.org",
    "homepage_uri" => spec.homepage,
    "source_code_uri" => "https://github.com/mitchbne/spectracer",
    "changelog_uri" => "https://github.com/mitchbne/spectracer/blob/main/CHANGELOG.md",
    "documentation_uri" => "https://github.com/mitchbne/spectracer#readme",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.glob(%w[
    lib/**/*.rb
    lib/**/*.yml
    lib/**/*.rake
    sig/**/*.rbs
    AGENTS.md
    CHANGELOG.md
    LICENSE.txt
    README.md
  ])
  spec.require_paths = ["lib"]

  spec.add_dependency "git", "~> 2.0"
end
