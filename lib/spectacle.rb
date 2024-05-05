# frozen_string_literal: true

require_relative "spectacle/version"
require_relative "spectacle/output_directory"
require_relative "spectacle/dependency_tracer"
require_relative "spectacle/dependency_collector"
require_relative "spectacle/spec_run_determiner"

module Spectacle
  class Error < StandardError; end
end

if defined?(RSpec) && ENV["WITH_SPECTACLE_TRACING"] == "true"
  if RSpec.respond_to?(:configure)
    RSpec.configure do |config|
      dependency_tracer = Spectacle::DependencyTracer.new

      config.around(:example) do |example|
        dependency_tracer.current_spec_file = example.file_path

        dependency_tracer.with_tracing do
          example.run
        end
      end

      config.after(:suite) do
        dependency_tracer.write_output!
      end
    end
  end
end
