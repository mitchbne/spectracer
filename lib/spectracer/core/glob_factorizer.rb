# frozen_string_literal: true

module Spectracer
  module Core
    class GlobFactorizer
      def call(patterns)
        return patterns.to_a if patterns.size <= 1

        patterns_array = patterns.to_a.uniq
        globs, files = patterns_array.partition { |p| glob_pattern?(p) }

        # Remove files that are matched by any glob
        remaining_files = files.reject do |file|
          globs.any? { |glob| File.fnmatch?(glob, file, File::FNM_PATHNAME) }
        end

        # Remove globs subsumed by other globs (broader patterns win)
        remaining_globs = globs.reject do |glob|
          globs.any? { |other| other != glob && subsumes?(other, glob) }
        end

        remaining_globs + remaining_files
      end

      private

      def glob_pattern?(pattern)
        pattern.include?("*") || pattern.include?("?") || pattern.include?("[")
      end

      def subsumes?(broader, narrower)
        return false if broader == narrower

        # Convert the narrower glob to a concrete-ish path by replacing wildcards
        # then check if the broader glob would match it
        test_path = narrower
          .gsub("**", "any/nested/path")
          .gsub("*", "placeholder")

        File.fnmatch?(broader, test_path, File::FNM_PATHNAME)
      end
    end
  end
end
