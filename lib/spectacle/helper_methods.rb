require 'fileutils'
require 'json'
require 'zlib'

module Spectacle
  module HelperMethods
    # @return [String] The root directory of the git repository that the gem is being run in.
    def repository_root
      # We could use Rails.root, but to remove the dependency on Rails, we'll use this method instead.
      @repository_root ||= `git rev-parse --show-toplevel`.chomp
    end

    def relative_file_path(file_path)
      file_path.gsub(repository_root, '.')
    end

    def write_object_to_gzipped_json(object, file_path)
      FileUtils.mkdir_p(File.dirname(file_path))

      if ENV["WITH_SPECTACLE_DEBUG"] == "true"
        $stderr.puts "Writing to #{file_path}"
        $stderr.puts JSON.pretty_generate(object)
      end

      File.open(file_path, "wb") do |f|
        Zlib::GzipWriter.wrap(f) do |gz|
          gz.write(object.to_json)
        end
      end
    end

    def read_file(file_path)
      if file_path.end_with?(".json.gz")
        Zlib::GzipReader.open(file_path) do |gz|
          JSON.parse(gz.read)
        end
      elsif file_path.end_with?(".json")
        JSON.parse(File.read(file_path))
      else
        {}
      end
    rescue JSON::ParserError
      $stderr.puts "Failed to parse JSON file: '#{file_path}'"
      {}
    end
  end
end
