require 'zlib'
require 'json'
require 'open3'

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

        file_key = "./#{file}"
        if ENV["WITH_SPECTACLE_DEBUG"] == "true"
          puts "Checking dependencies for '#{file_key}'..."
          puts "dependencies.json keys: #{@dependencies.keys}"
        end

        if spec_files = @dependencies[file_key]
          @spec_files.merge(spec_files)
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
        $stderr.puts "No spec files to run. Running the 'on_empty_spec_set' pattern defined in the configuration file." if ENV["WITH_SPECTACLE_DEBUG"] == "true"
        @configuration[:on_empty_spec_set]
      else
        files.join(",")
      end
    rescue => e
      puts e.backtrace
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
        default_branch = ENV.fetch("BUILDKITE_PIPELINE_DEFAULT_BRANCH", "main")
        current_branch = ENV.fetch("BUILDKITE_BRANCH", system_command("git rev-parse --abbrev-ref HEAD"))

        if current_branch == default_branch
          # Get the latest commit on the current branch
          latest_commit = system_command("git rev-parse #{current_branch}")
          $stderr.puts "Latest commit SHA: #{latest_commit}" if ENV["WITH_SPECTACLE_DEBUG"] == "true"
          system_command("git diff-tree --no-commit-id --name-only #{latest_commit} -r").split("\n")
        else
          # Get the changed files between the current branch and the default branch
          system_command("git diff --cached origin/#{default_branch} --name-only").split("\n")
        end
      end
    end

    def system_command(command)
      $stderr.puts "Running command: '#{command}'" if ENV["WITH_SPECTACLE_DEBUG"] == "true"

      stdout_str, _, _ = Open3.capture3(command)
      return stdout_str.chomp
    end
  end
end
