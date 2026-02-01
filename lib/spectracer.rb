# frozen_string_literal: true

require_relative "spectracer/version"
require_relative "spectracer/logger"

require_relative "spectracer/core/paths"
require_relative "spectracer/core/path_filter"
require_relative "spectracer/core/spec_selector"

require_relative "spectracer/io/command_runner"
require_relative "spectracer/io/dependency_store"
require_relative "spectracer/io/config_loader"
require_relative "spectracer/io/git_adapter"

require_relative "spectracer/providers/repository"
require_relative "spectracer/providers/git_changed_files"

require_relative "spectracer/orchestrators/dependency_tracer"
require_relative "spectracer/orchestrators/dependency_collector"
require_relative "spectracer/orchestrators/spec_run_determiner"

require_relative "spectracer/integrations/rspec"
require_relative "spectracer/integrations/minitest"
require_relative "spectracer/integrations/railtie" if defined?(Rails)

module Spectracer
  class Error < StandardError; end

  class << self
    def logger
      @logger ||= Logger.new(
        enabled: ENV["WITH_SPECTRACER_DEBUG"] == "true",
        level: :debug
      )
    end

    def paths
      @paths ||= Core::Paths.new
    end
  end
end

Spectracer::Integrations::RSpec.install!
Spectracer::Integrations::Minitest.install!
