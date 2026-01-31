# frozen_string_literal: true

module Spectracer
  module Core
    class SpecSelector
      def call(changed_files:, inverse_deps:, globs:, on_empty:)
        spec_set = Set.new

        changed_files.each do |file|
          spec_set.add(file) if file.end_with?("_spec.rb")

          file_key = file.start_with?("./") ? file : "./#{file}"
          if (specs = inverse_deps[file_key])
            spec_set.merge(specs)
          end

          globs.each do |glob, pattern|
            normalized_glob = glob.sub(%r{\A\./}, "")
            spec_set.add(pattern) if File.fnmatch?(normalized_glob, file)
          end
        end

        files = spec_set.to_a.sort
        files.empty? ? on_empty : files.join(",")
      end
    end
  end
end
