# frozen_string_literal: true

require "open3"

module Spectracer
  module IO
    class CommandRunner
      def initialize(logger: nil)
        @logger = logger
      end

      def run(command)
        @logger&.debug("Running command: '#{command}'")

        stdout, stderr, status = Open3.capture3(command)

        unless status.success?
          @logger&.warn("Command failed with status #{status.exitstatus}: #{stderr}")
        end

        stdout.chomp
      end
    end
  end
end
