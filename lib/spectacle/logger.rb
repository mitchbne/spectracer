# frozen_string_literal: true

module Spectacle
  class Logger
    LEVELS = {debug: 0, info: 1, warn: 2, error: 3}.freeze

    def initialize(output: $stderr, level: :info, enabled: false)
      @output = output
      @level = LEVELS.fetch(level, 1)
      @enabled = enabled
    end

    def debug(message)
      log(:debug, message)
    end

    def info(message)
      log(:info, message)
    end

    def warn(message)
      log(:warn, message)
    end

    def error(message)
      log(:error, message)
    end

    private

    def log(level, message)
      return unless @enabled
      return if LEVELS[level] < @level

      @output.puts "[Spectacle] #{level.upcase}: #{message}"
    end
  end
end
