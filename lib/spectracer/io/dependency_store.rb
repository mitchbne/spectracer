# frozen_string_literal: true

require "fileutils"
require "json"
require "zlib"

module Spectracer
  module IO
    class DependencyStore
      def initialize(logger: nil)
        @logger = logger
      end

      def read(file_path)
        return {} unless File.exist?(file_path)

        case File.extname(file_path)
        when ".gz"
          read_gzipped_json(file_path)
        when ".json"
          read_json(file_path)
        else
          @logger&.warn("Unknown file format: #{file_path}")
          {}
        end
      rescue JSON::ParserError => e
        @logger&.error("Failed to parse JSON file '#{file_path}': #{e.message}")
        {}
      end

      def write(data, file_path)
        FileUtils.mkdir_p(File.dirname(file_path))

        @logger&.debug("Writing to #{file_path}")
        @logger&.debug(JSON.pretty_generate(data))

        File.open(file_path, "wb") do |f|
          Zlib::GzipWriter.wrap(f) do |gz|
            gz.write(data.to_json)
          end
        end
      end

      def glob(pattern)
        Dir.glob(pattern)
      end

      private

      def read_gzipped_json(file_path)
        Zlib::GzipReader.open(file_path) do |gz|
          JSON.parse(gz.read)
        end
      end

      def read_json(file_path)
        JSON.parse(File.read(file_path))
      end
    end
  end
end
