# frozen_string_literal: true

require "yaml"

module Spectracer
  module IO
    class ConfigLoader
      FILE_PATH = ".spectracer.yml"
      DEFAULT_RSPEC_FILE_PATH = File.expand_path("../../spectracer.default.yml", __dir__)
      DEFAULT_MINITEST_FILE_PATH = File.expand_path("../../spectracer.default.minitest.yml", __dir__)

      def initialize(logger: nil)
        @logger = logger
      end

      def load
        raw_config = load_raw_config
        return default_config if raw_config.nil?

        parse_config(raw_config)
      rescue => e
        @logger&.error("Error loading configuration: #{e.message}")
        default_config
      end

      private

      def load_raw_config
        if File.exist?(FILE_PATH)
          YAML.safe_load_file(FILE_PATH)
        else
          @logger&.debug("No configuration file found at #{FILE_PATH.inspect}. Using defaults.")
          YAML.safe_load_file(default_file_path)
        end
      end

      def default_file_path
        if defined?(RSpec)
          DEFAULT_RSPEC_FILE_PATH
        elsif defined?(Minitest)
          DEFAULT_MINITEST_FILE_PATH
        else
          DEFAULT_RSPEC_FILE_PATH
        end
      end

      def parse_config(raw)
        defaults = raw.fetch("defaults", {})
        on_empty = raw.fetch("on_empty_spec_set", "")
        globs_matcher = raw.fetch("globs_matcher", {})

        {
          on_empty_spec_set: resolve_templates(on_empty, defaults),
          globs: globs_matcher.transform_values { |v| resolve_templates(v, defaults) }
        }
      end

      def resolve_templates(template, defaults)
        template.gsub(/\{\{(.*?)\}\}/) { defaults[$1] || "" }
      end

      def default_config
        {on_empty_spec_set: "", globs: {}}
      end
    end
  end
end
