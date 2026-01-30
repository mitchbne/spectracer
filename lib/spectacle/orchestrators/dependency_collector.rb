# frozen_string_literal: true

module Spectacle
  module Orchestrators
    class DependencyCollector
      def initialize(
        paths: Spectacle::Core::Paths.new,
        store: Spectacle::IO::DependencyStore.new,
        logger: nil
      )
        @paths = paths
        @store = store
        @logger = logger
      end

      def self.collect!(...)
        new(...).collect!
      end

      def collect!
        inverse_deps = build_inverse_dependencies

        inverse_deps.each_value(&:sort!)

        @store.write(inverse_deps, @paths.collected_dependencies_file)

        nil
      end

      private

      def build_inverse_dependencies
        inverse = Hash.new { |h, k| h[k] = [] }

        artifact_files.each do |file|
          @logger&.debug("Processing artifact: #{file}")
          data = @store.read(file)

          data.each do |spec_file, dependencies|
            dependencies.each do |dep|
              inverse[dep] << spec_file unless inverse[dep].include?(spec_file)
            end
          end
        end

        inverse
      end

      def artifact_files
        @store.glob(@paths.spec_artifacts_download_glob)
      end
    end
  end
end
