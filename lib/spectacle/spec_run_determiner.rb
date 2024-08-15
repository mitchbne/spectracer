require 'zlib'
require 'json'

require_relative "./helper_methods"
require_relative "./configuration"

# We expect the OUTPUT_DIRECTORY to contain a file called "dependencies.json.gz" that contains the inverse dependencies of each spec file.
# We use this information to determine which spec files to run based on the files that have changed.
# This class reads the "dependencies.json.gz" file and outputs a list of spec files that need to be run by using git to determine files that have changed.

module Spectacle
  class SpecRunDeterminer
    include Spectacle::HelperMethods

    def initialize
      @dependencies = nil
      @configuration = nil
      @spec_files = Set.new
    end

    def self.determine!
      new.determine!
    end

    def determine!
      load_dependencies_file!
      load_configuration_file!
      load_changed_files!

      if ENV["WITH_SPECTACLE_DEBUG"] == "true"
        $stderr.puts "Configuration:"
        $stderr.puts JSON.pretty_generate(@configuration)

        $stderr.puts "Changed files:"
        @changed_files.each do |file|
          $stderr.puts "  - #{file}"
        end

        $stderr.puts ""
      end

      @changed_files.each do |file|
        @spec_files.add(file) if file.end_with?("_spec.rb") # Also run the spec file itself if it has changed

        if @dependencies[file]
          @spec_files.merge(@dependencies[file])
        end

        @configuration[:globs].each do |glob, pattern|
          glob = glob.gsub("./", "") if glob.start_with?("./")

          if File.fnmatch?(glob, file)
            $stderr.puts "Detected #{file} in changed files. Adding '#{pattern}' to the spec pattern." if ENV["WITH_SPECTACLE_DEBUG"] == "true"
            @spec_files.add(pattern)
          end
        end
      end

      files = @spec_files.to_a.sort

      if files.empty?
        $stderr.puts "No spec files to run. Running the pattern defined in the configuration file." if ENV["WITH_SPECTACLE_DEBUG"] == "true"
        @configuration[:on_empty_spec_set]
      else
        files.join(",")
      end
    end

    private

    def load_dependencies_file!
      unless File.exist?(COLLECTED_DEPENDENCIES_FILE)
        $stderr.puts "No dependencies file found at #{Spectacle::COLLECTED_DEPENDENCIES_FILE.inspect}." if ENV["WITH_SPECTACLE_DEBUG"] == "true"
        return
      end

      @dependencies = read_file(Spectacle::COLLECTED_DEPENDENCIES_FILE)
    end

    def load_configuration_file!
      @configuration = Spectacle::Configuration.load!
    end

    def load_changed_files!
      @changed_files = begin
        # Assume we're on a branch first that should be compared to origin/main
        changed_files = `git diff --cached --merge-base origin/main --name-only`.split("\n")

        # If the list of changed files is empty, and we're on Buildkite, we could probably use the BUILDKITE_COMMIT environment variable
        if changed_files.empty? && ENV["BUILDKITE_COMMIT"]
          changed_files = "git diff --cached $BUILDKITE_COMMIT --name-only".split("\n")
        end

        # If the list of changed files is empty, we probably should just use the last commit
        if changed_files.empty?
          changed_files = "git diff --cached HEAD~1 --name-only".split("\n")
        end

        changed_files
      end
    end
  end
end
