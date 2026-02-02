# frozen_string_literal: true

module Spectracer
  module Core
    class SpecSelector
      Result = Struct.new(:specs, :file_to_specs_map, keyword_init: true)

      def initialize(factorizer: GlobFactorizer.new)
        @factorizer = factorizer
      end

      def call(changed_files:, inverse_deps:, globs:, on_empty:)
        spec_set = Set.new
        file_to_specs = {}

        changed_files.each do |file|
          matched_specs = []

          if file.end_with?("_spec.rb", "_test.rb")
            spec_set.add(file)
            matched_specs << file
          end

          file_key = file.start_with?("./") ? file : "./#{file}"
          if (specs = inverse_deps[file_key])
            spec_set.merge(specs)
            matched_specs.concat(specs)
          end

          globs.each do |glob, pattern|
            normalized_glob = glob.sub(%r{\A\./}, "")
            if File.fnmatch?(normalized_glob, file)
              spec_set.add(pattern)
              matched_specs << pattern
            end
          end

          file_to_specs[file] = matched_specs.uniq.sort unless matched_specs.empty?
        end

        files = @factorizer.call(spec_set).sort
        specs_result = files.empty? ? on_empty : files.join(",")

        Result.new(specs: specs_result, file_to_specs_map: file_to_specs)
      end
    end
  end
end
