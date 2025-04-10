require 'zlib'
require 'json'

# The .spectacle.yml file should be placed in the root of the repository.
# It looks like this:
# ---
# defaults:
#   all_specs: String
#   no_specs: String

# on_empty_spec_set: String

# globs_matcher:
#   <String>: String

# The defaults are used to define patterns that can be used in the globs_matcher section, and are templated into mustache templates.
# The on_empty_spec_set is a mustache template that is used to determine what to run if no specs are found.
# The globs_matcher section is a list of files or directories that are mapped to a pattern template.

module Spectacle
  class Configuration
    FILE_PATH = File.join(".spectacle.yml").freeze
    DEFAULT_FILE_PATH = File.join(Pathname.new(__dir__).join("..", "spectacle.default.yml")).freeze

    def intialize
      @dependencies = nil
      @configuration = nil
      @spec_files = Set.new
    end

    def self.load!
      new.load!
    end

    def load!
      file = load_configuration_file!

      defaults = file.delete("defaults")
      on_empty_spec_set = file.delete("on_empty_spec_set")
      globs_matcher = file.delete("globs_matcher")

      configuration = {}

      configuration[:on_empty_spec_set] = on_empty_spec_set.gsub(/{{(.*?)}}/) do
        defaults[$1]
      end

      configuration[:globs] = globs_matcher.each_with_object({}) do |(key, value), hash|
        hash[key] = value.gsub(/{{(.*?)}}/) do
          defaults[$1]
        end
      end

      configuration
    end

    private

    def load_configuration_file!
      if File.exist?(FILE_PATH)
        YAML.load_file(FILE_PATH)
      else
        $stderr.puts "No configuration file found at #{FILE_PATH.inspect}. Falling back to defaults" if ENV["WITH_SPECTACLE_DEBUG"] == "true"
        YAML.safe_load(File.read(DEFAULT_FILE_PATH))
      end
    rescue => e
      $stderr.puts "Error loading configuration file: #{e.message}"
    end

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
