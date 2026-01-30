# frozen_string_literal: true

module Spectacle
  module Integrations
    module Minitest
      class << self
        attr_accessor :tracer

        def install!
          return unless defined?(::Minitest)
          return unless ENV["WITH_SPECTACLE_TRACING"] == "true"

          logger = Spectacle::Logger.new(
            enabled: ENV["WITH_SPECTACLE_DEBUG"] == "true",
            level: :debug
          )

          self.tracer = Spectacle::Orchestrators::DependencyTracer.new(logger: logger)

          ::Minitest.singleton_class.prepend(RunPatch)
        end
      end

      module RunPatch
        def run(args = [])
          result = super
          Spectacle::Integrations::Minitest.tracer&.write_output!
          result
        end
      end

      module TestCasePlugin
        def before_setup
          super
          tracer = Spectacle::Integrations::Minitest.tracer
          return unless tracer

          file_path = method(name).source_location&.first
          tracer.current_spec_file = file_path if file_path
        end

        def run
          tracer = Spectacle::Integrations::Minitest.tracer
          return super unless tracer

          tracer.with_tracing { super }
        end
      end
    end
  end
end

if defined?(::Minitest::Test) && ENV["WITH_SPECTACLE_TRACING"] == "true"
  ::Minitest::Test.prepend(Spectacle::Integrations::Minitest::TestCasePlugin)
end
