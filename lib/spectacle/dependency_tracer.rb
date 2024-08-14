require 'zlib'
require 'json'

require_relative "./helper_methods"

# Runs a tracepoint on each line of code in a spec file to determine which other files it depends on.
# Collects the dependencies and writes them to a gzipped JSON file.
# The output file looks like this:
# {
#   "spec/models/user_spec.rb": ["app/models/user.rb", "spec/factories/users.rb" ],
#   "spec/controllers/users_controller_spec.rb": ["app/controllers/users_controller.rb", "spec/factories/users.rb" ],
#   ...
# }

module Spectacle
  class DependencyTracer
    include Spectacle::HelperMethods

    def initialize
      @current_spec_file = nil
      @spec_file_dependencies = Hash.new { |h, k| h[k] = Set.new }
    end

    def with_tracing(&block)
      tracepoint.enable

      block.call

      tracepoint.disable
    end

    def write_output!
      output = output_json

      if output.empty?
        $stderr.puts "No dependencies found." if ENV["WITH_SPECTACLE_DEBUG"] == "true"
        return
      end

      write_object_to_gzipped_json(output_json, SPEC_ARTIFACT_OUTPUT_FILE_PATH)
    end

    def current_spec_file=(file)
      @current_spec_file = relative_file_path(file)
    end

    private

    def tracepoint
      @tracepoint ||= TracePoint.new(:line) do |tp|
        next unless tp.path.start_with?(repository_root) # Only look at files in our repository
        next if @current_spec_file.nil? # Skip if we're not in a spec file

        file_path = relative_file_path(tp.path)
        next if @current_spec_file == file_path # Skip if we're in the current spec file

        @spec_file_dependencies[@current_spec_file].add(file_path)
      end
    end

    def output_json
      @spec_file_dependencies.reduce({}) do |acc, (spec_file, files)|
        next if files.empty?

        acc[spec_file] = files.to_a.sort
        acc
      end
    end
  end
end
