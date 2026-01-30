# frozen_string_literal: true

module Spectacle
  module Providers
    class Repository
      def initialize(git_adapter: Spectacle::IO::GitAdapter.new)
        @git_adapter = git_adapter
      end

      def root
        @root ||= @git_adapter.repository_root
      end
    end
  end
end
