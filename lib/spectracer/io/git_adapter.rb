# frozen_string_literal: true

require "git"

module Spectracer
  module IO
    class GitAdapter
      def initialize(working_dir: Dir.pwd, logger: nil)
        @working_dir = working_dir
        @logger = logger
        @git = nil
      end

      def repository_root
        git.dir.path
      end

      def current_branch
        git.current_branch
      end

      def commit_sha(ref)
        git.object(ref).sha
      end

      def changed_files_in_commit(sha)
        commit = git.object(sha)
        return [] unless commit.respond_to?(:diff_parent)

        commit.diff_parent.stats[:files].keys
      rescue Git::Error => e
        @logger&.warn("Failed to get changed files for commit #{sha}: #{e.message}")
        []
      end

      def changed_files_against(target_branch, cached: false)
        target_ref = "origin/#{target_branch}"

        diff = if cached
          git.diff(target_ref, "HEAD")
        else
          git.diff(target_ref)
        end

        diff.stats[:files].keys
      rescue Git::Error => e
        @logger&.warn("Failed to diff against #{target_branch}: #{e.message}")
        []
      end

      private

      def git
        @git ||= Git.open(@working_dir, log: nil)
      end
    end
  end
end
