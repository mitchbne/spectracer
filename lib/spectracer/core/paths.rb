# frozen_string_literal: true

module Spectracer
  module Core
    class Paths
      DEFAULT_OUTPUT_DIR = "tmp/spectracer"

      def initialize(env: ENV)
        @env = env
      end

      def build_id
        @env["BUILDKITE_BUILD_ID"] || "local"
      end

      def job_id
        @env["BUILDKITE_JOB_ID"] || "local"
      end

      def output_directory
        @env["SPECTRACER_TMP_DIRECTORY"] || DEFAULT_OUTPUT_DIR
      end

      def spec_artifact_output_file
        File.join(output_directory, "tracing_output", build_id, "#{job_id}.json.gz")
      end

      def spec_artifacts_download_glob
        File.join(output_directory, "tracing_output", build_id, "*.json.gz")
      end

      def collected_dependencies_file
        File.join(output_directory, "dependencies.json.gz")
      end

      def normalize(file_path, repo_root:)
        relative = file_path.sub(/\A#{Regexp.escape(repo_root)}/, ".")
        relative.start_with?("./") ? relative : "./#{relative}"
      end

      def strip_dot_prefix(path)
        path.sub(%r{\A\./}, "")
      end
    end
  end
end
