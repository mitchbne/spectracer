# frozen_string_literal: true

module Spectacle
  module Integrations
    module RSpec
      def self.install!
        return unless defined?(::RSpec) && ::RSpec.respond_to?(:configure)
        return unless ENV["WITH_SPECTACLE_TRACING"] == "true"

        logger = Spectacle::Logger.new(
          enabled: ENV["WITH_SPECTACLE_DEBUG"] == "true",
          level: :debug
        )

        tracer = Spectacle::Orchestrators::DependencyTracer.new(logger: logger)

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
