# frozen_string_literal: true

require "json"

module Spectracer
  module Orchestrators
    class SpecRunDeterminer
      def initialize(
        paths: Spectracer::Core::Paths.new,
        store: Spectracer::IO::DependencyStore.new,
        config_loader: Spectracer::IO::ConfigLoader.new,
        changed_files_provider: Spectracer::Providers::GitChangedFiles.new,
        selector: Spectracer::Core::SpecSelector.new,
        logger: nil
      )
        @paths = paths
        @store = store
        @config_loader = config_loader
        @changed_files_provider = changed_files_provider
        @selector = selector
        @logger = logger
      end

      def self.determine!(...)
        new(...).determine!
      end

      def determine!
        dependencies = load_dependencies
        config = @config_loader.load
        changed_files = @changed_files_provider.call

        log_debug_info(config, changed_files)

        result = @selector.call(
          changed_files: changed_files,
          inverse_deps: dependencies,
          globs: config[:globs],
          on_empty: config[:on_empty_spec_set]
        )

        log_file_to_specs_map(result.file_to_specs_map)

        result.specs
      rescue => e
        @logger&.error("Error determining specs: #{e.message}")
        @logger&.error(e.backtrace&.join("\n"))
        nil
      end

      private

      def load_dependencies
        deps_file = @paths.collected_dependencies_file

        unless File.exist?(deps_file)
          @logger&.debug("No dependencies file found at #{deps_file.inspect}")
          return {}
        end

        @store.read(deps_file)
      end

      def log_debug_info(config, changed_files)
        @logger&.debug("Configuration: #{config.inspect}")
        @logger&.debug("Changed files: #{changed_files.inspect}")
      end

      def log_file_to_specs_map(file_to_specs_map)
        return if file_to_specs_map.empty?

        @logger&.debug("Changed files to specs mapping:")
        @logger&.debug(JSON.pretty_generate(file_to_specs_map))
      end
    end
  end
end
