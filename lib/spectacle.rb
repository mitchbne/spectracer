# frozen_string_literal: true

require_relative "spectacle/version"
require_relative "spectacle/dependency_tracer"
require_relative "spectacle/dependency_collector"
require_relative "spectacle/spec_run_determiner"
require_relative "spectacle/railtie" if defined?(Rails)

module Spectacle
  class Error < StandardError; end

  # These variables are pulled in from Buildkite's environment variables, but default to "local" if not found.
  BUILD_ID = ENV["BUILDKITE_BUILD_ID"] || "local"
  JOB_ID = ENV["BUILDKITE_JOB_ID"] || "local"

  # The path to the output directory where all the Spectacle artifacts are stored before being uploaded to Buildkite.
  # Artifacts downloaded from Buildkite are also stored here.
  OUTPUT_DIRECTORY = ENV["SPECTACLE_TMP_DIRECTORY"] || "tmp/spectacle"

  # When rspec files are run (with the `WITH_SPECTACLE_TRACING` environment variable set to "true"),
  # we generate a gzipped JSON file for all rspect files that were run called: "#{JOB_ID}.json.gz"
  SPEC_ARTIFACT_OUTPUT_FILE_PATH = File.join(OUTPUT_DIRECTORY, "tracing_output", BUILD_ID, "#{JOB_ID}.json.gz")

  # Spectacle expects spec artifacts to be uploaded to Buildkite, and then downloaded in a subsequent job.
  # The downloaded artifacts path is stored in the `SPECTACLE_ARTIFACTS_DOWNLOAD_PATH` constant.
  SPEC_ARTIFACTS_DOWNLOAD_PATH = File.join(OUTPUT_DIRECTORY, "tracing_output", BUILD_ID, "*.json.gz")

  # Once all the spec artifacts are downloaded, we combine them into a single gzipped JSON file called "dependencies.json.gz".
  # We expect this file to be then uploaded to Buildkite, and used in a seperate Buildkite job to determine which specs to run.
  COLLECTED_DEPENDENCIES_FILE = File.join(OUTPUT_DIRECTORY, "dependencies.json.gz")
end

if defined?(RSpec) && ENV["WITH_SPECTACLE_TRACING"] == "true"
  if RSpec.respond_to?(:configure)
    RSpec.configure do |config|
      dependency_tracer = Spectacle::DependencyTracer.new

      config.around(:example) do |example|
        dependency_tracer.current_spec_file = example.file_path
        dependency_tracer.with_tracing { example.run }
      end

      config.after(:suite) do
        dependency_tracer.write_output!
      end
    end
  end
end
