# frozen_string_literal: true

module Spectracer
  module Orchestrators
    class DependencyTracer
      def initialize(
        paths: Spectracer::Core::Paths.new,
        store: Spectracer::IO::DependencyStore.new,
        repository: Spectracer::Providers::Repository.new,
        logger: nil
      )
        @paths = paths
        @store = store
        @repository = repository
        @logger = logger
        @current_spec_file = nil
        @spec_file_dependencies = Hash.new { |h, k| h[k] = Set.new }
      end

      attr_writer :current_spec_file

      def with_tracing(&block)
        tracepoint.enable
        block.call
      ensure
        tracepoint.disable
      end

      def write_output!
        output = build_output

        if output.empty?
          @logger&.debug("No dependencies found.")
          return
        end

        @store.write(output, @paths.spec_artifact_output_file)
      end

      private

      def tracepoint
        @tracepoint ||= TracePoint.new(:call) do |tp|
          path = tp.path
          next unless path.start_with?(repository_root)
          next if @current_spec_file.nil?

          file_path = normalize_path(path)
          next if @current_spec_file == file_path

          @spec_file_dependencies[@current_spec_file].add(file_path)
        end
      end

      def repository_root
        @repository_root ||= @repository.root
      end

      def normalize_path(path)
        @paths.normalize(path, repo_root: repository_root)
      end

      def build_output
        @spec_file_dependencies.each_with_object({}) do |(spec_file, files), acc|
          next if files.empty?
          acc[spec_file] = files.to_a.sort
        end
      end
    end
  end
end
