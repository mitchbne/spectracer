require 'zlib'
require 'json'

require_relative "./helper_methods"

# We expect the OUTPUT_DIRECTORY to contain a file called "dependencies.json.gz" that contains the inverse dependencies of each spec file.
# We use this information to determine which spec files to run based on the files that have changed.
# This class reads the "dependencies.json.gz" file and outputs a list of spec files that need to be run by using git to determine files that have changed.

module Spectacle
  class SpecRunDeterminer
    include Spectacle::HelperMethods

    def self.determine!
      new.determine!
    end

    def determine!
      dependencies = read_file(File.join(OUTPUT_DIRECTORY, "dependencies.json.gz"))

      spec_files = Set.new

      changed_files.each do |file|
        spec_files.add(file) if file.end_with?("_spec.rb") # Also run the spec file itself if it has changed
        if dependencies[file]
          spec_files.merge(dependencies[file])
        end
      end

      $stdout.puts "'#{spec_files.to_a.sort.join(",")}'"
    end

    private

    def changed_files
      @changed_files ||= begin
        # Assume we're on a branch first that should be compared to origin/main
        changed_files = `git diff --cached --merge-base origin/main --name-only`.split("\n")

        # If the list of changed files is empty, and we're on Buildkite, we could probably use the BUILDKITE_COMMIT environment variable
        if changed_files.empty? && ENV["BUILDKITE_COMMIT"]
          changed_files = `git diff --cached $BUILDKITE_COMMIT --name-only`.split("\n")
        end

        # If the list of changed files is empty, we probably should just use the last commit
        if changed_files.empty?
          changed_files = `git diff --cached HEAD~1 --name-only`.split("\n")
        end

        # Git prints the files relative to the repository root, so we need to prepend "./" to each file
        changed_files.map { |file| "./#{file}" }
      end
    end
  end
end
