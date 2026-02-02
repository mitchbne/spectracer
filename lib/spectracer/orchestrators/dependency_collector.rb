# frozen_string_literal: true

module Spectracer
  module Orchestrators
    class DependencyCollector
      def initialize(
        paths: Spectracer::Core::Paths.new,
        store: Spectracer::IO::DependencyStore.new,
        path_filter: Spectracer::Core::PathFilter.new,
        logger: nil
      )
        @paths = paths
        @store = store
        @path_filter = path_filter
        @logger = logger
      end

      def self.collect!(...)
        new(...).collect!
      end

      def collect!
        inverse_deps = build_inverse_dependencies

        inverse_deps.each_value(&:sort!)

        output_path = @paths.collected_dependencies_file
        @logger&.debug("Writing collected dependencies to: #{output_path}")
        @store.write(inverse_deps, output_path)

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
              next if @path_filter.gem_path?(dep)

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
