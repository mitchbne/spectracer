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

      def changed_files_against(target_branch, include_uncommitted: true)
        target_ref = resolve_target_ref(target_branch)

        committed_files = git.diff(target_ref, "HEAD").stats[:files].keys

        if include_uncommitted
          uncommitted_files = uncommitted_changed_files
          (committed_files + uncommitted_files).uniq
        else
          committed_files
        end
      rescue Git::Error => e
        @logger&.warn("Failed to diff against #{target_branch}: #{e.message}")
        []
      end

      def resolve_target_ref(branch)
        remote_ref = "origin/#{branch}"
        return remote_ref if ref_exists?(remote_ref)

        return branch if ref_exists?(branch)

        @logger&.warn("Neither origin/#{branch} nor #{branch} found, using HEAD~1")
        "HEAD~1"
      end

      def ref_exists?(ref)
        git.object(ref)
        true
      rescue Git::Error
        false
      end

      def uncommitted_changed_files
        staged = git.diff("HEAD").stats[:files].keys
        unstaged = git.status.changed.keys + git.status.added.keys + git.status.deleted.keys
        (staged + unstaged).uniq
      rescue Git::Error => e
        @logger&.warn("Failed to get uncommitted changes: #{e.message}")
        []
      end

      def local_changed_files
        uncommitted = uncommitted_changed_files

        branch_diff = local_branch_diff_files
        (uncommitted + branch_diff).uniq
      end

      def local_branch_diff_files
        current = current_branch
        default_branch = detect_default_branch

        return [] unless default_branch
        return [] if current == default_branch

        git.diff(default_branch, "HEAD").stats[:files].keys
      rescue Git::Error => e
        @logger&.warn("Failed to get branch diff: #{e.message}")
        []
      end

      def detect_default_branch
        remote_head = git.lib.send(:command, "symbolic-ref", "refs/remotes/origin/HEAD", "--short").strip
        remote_head.sub("origin/", "")
      rescue
        %w[main master].find { |b| ref_exists?(b) }
      end

      private

      def git
        @git ||= Git.open(@working_dir, log: nil)
      end
    end
  end
end
