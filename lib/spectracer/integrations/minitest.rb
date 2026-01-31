# frozen_string_literal: true

module Spectracer
  module Integrations
    module Minitest
      class << self
        attr_accessor :tracer

        def install!
          return unless defined?(::Minitest)
          return unless ENV["WITH_SPECTRACER_TRACING"] == "true"

          logger = Spectracer::Logger.new(
            enabled: ENV["WITH_SPECTRACER_DEBUG"] == "true",
            level: :debug
          )

          self.tracer = Spectracer::Orchestrators::DependencyTracer.new(logger: logger)

          ::Minitest.singleton_class.prepend(RunPatch)
        end
      end

      module RunPatch
        def run(args = [])
          result = super
          Spectracer::Integrations::Minitest.tracer&.write_output!
          result
        end
      end

      module TestCasePlugin
        def before_setup
          super
          tracer = Spectracer::Integrations::Minitest.tracer
          return unless tracer

          file_path = method(name).source_location&.first
          tracer.current_spec_file = file_path if file_path
        end

        def run
          tracer = Spectracer::Integrations::Minitest.tracer
          return super unless tracer

          tracer.with_tracing { super }
        end
      end
    end
  end
end

if defined?(::Minitest::Test) && ENV["WITH_SPECTRACER_TRACING"] == "true"
  ::Minitest::Test.prepend(Spectracer::Integrations::Minitest::TestCasePlugin)
end
