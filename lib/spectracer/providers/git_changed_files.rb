# frozen_string_literal: true

module Spectracer
  module Providers
    class GitChangedFiles
      def initialize(git_adapter: Spectracer::IO::GitAdapter.new, env: ENV, logger: nil)
        @git_adapter = git_adapter
        @env = env
        @logger = logger
      end

      def call
        default_branch = @env.fetch("BUILDKITE_PIPELINE_DEFAULT_BRANCH", "main")
        current_branch = @env.fetch("BUILDKITE_BRANCH") { @git_adapter.current_branch }

        files = if current_branch == default_branch
          changed_files_for_latest_commit(current_branch)
        else
          changed_files_against_default_branch(default_branch)
        end

        @logger&.debug("Changed files: #{files.inspect}")
        files
      end

      private

      def changed_files_for_latest_commit(branch)
        sha = @git_adapter.commit_sha(branch)
        @logger&.debug("Latest commit SHA: #{sha}")

        @git_adapter.changed_files_in_commit(sha)
      end

      def changed_files_against_default_branch(default_branch)
        @git_adapter.changed_files_against(default_branch, cached: true)
      end
    end
  end
end
