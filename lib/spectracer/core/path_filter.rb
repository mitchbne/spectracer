# frozen_string_literal: true

module Spectracer
  module Core
    class PathFilter
      def initialize(
        gem_paths: Gem.path,
        bundler_path: defined?(Bundler) ? Bundler.bundle_path.to_s : nil
      )
        @excluded_prefixes = build_excluded_prefixes(gem_paths, bundler_path)
      end

      def gem_path?(path)
        @excluded_prefixes.any? { |prefix| path.start_with?(prefix) }
      end

      def app_path?(path)
        !gem_path?(path)
      end

      private

      def build_excluded_prefixes(gem_paths, bundler_path)
        prefixes = gem_paths.map { |p| ensure_trailing_slash(p) }
        prefixes << ensure_trailing_slash(bundler_path) if bundler_path
        prefixes.uniq
      end

      def ensure_trailing_slash(path)
        path.end_with?("/") ? path : "#{path}/"
      end
    end
  end
end
