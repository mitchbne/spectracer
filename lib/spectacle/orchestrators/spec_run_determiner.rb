# frozen_string_literal: true

module Spectacle
  module Orchestrators
    class SpecRunDeterminer
      def initialize(
        paths: Spectacle::Core::Paths.new,
        store: Spectacle::IO::DependencyStore.new,
        config_loader: Spectacle::IO::ConfigLoader.new,
        changed_files_provider: Spectacle::Providers::GitChangedFiles.new,
        selector: Spectacle::Core::SpecSelector.new,
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

        @selector.call(
          changed_files: changed_files,
          inverse_deps: dependencies,
          globs: config[:globs],
          on_empty: config[:on_empty_spec_set]
        )
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
    end
  end
end
