# frozen_string_literal: true

require_relative "spectacle/version"
require_relative "spectacle/logger"

require_relative "spectacle/core/paths"
require_relative "spectacle/core/spec_selector"

require_relative "spectacle/io/command_runner"
require_relative "spectacle/io/dependency_store"
require_relative "spectacle/io/config_loader"
require_relative "spectacle/io/git_adapter"

require_relative "spectacle/providers/repository"
require_relative "spectacle/providers/git_changed_files"

require_relative "spectacle/orchestrators/dependency_tracer"
require_relative "spectacle/orchestrators/dependency_collector"
require_relative "spectacle/orchestrators/spec_run_determiner"

require_relative "spectacle/integrations/rspec"
require_relative "spectacle/integrations/minitest"
require_relative "spectacle/integrations/railtie" if defined?(Rails)

module Spectacle
  class Error < StandardError; end

  class << self
    def logger
      @logger ||= Logger.new(
        enabled: ENV["WITH_SPECTACLE_DEBUG"] == "true",
        level: :debug
      )
    end

    def paths
      @paths ||= Core::Paths.new
    end
  end
end

Spectacle::Integrations::RSpec.install!
Spectacle::Integrations::Minitest.install!
