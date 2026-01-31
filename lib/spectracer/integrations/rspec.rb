# frozen_string_literal: true

module Spectracer
  module Integrations
    module RSpec
      def self.install!
        return unless defined?(::RSpec) && ::RSpec.respond_to?(:configure)
        return unless ENV["WITH_SPECTRACER_TRACING"] == "true"

        logger = Spectracer::Logger.new(
          enabled: ENV["WITH_SPECTRACER_DEBUG"] == "true",
          level: :debug
        )

        tracer = Spectracer::Orchestrators::DependencyTracer.new(logger: logger)

        ::RSpec.configure do |config|
          config.around(:example) do |example|
            tracer.current_spec_file = example.file_path
            tracer.with_tracing { example.run }
          end

          config.after(:suite) do
            tracer.write_output!
          end
        end
      end
    end
  end
end
