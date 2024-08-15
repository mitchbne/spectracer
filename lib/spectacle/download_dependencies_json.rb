require 'zlib'
require 'json'
require 'net/http'

require_relative "./helper_methods"
require_relative "./configuration"

# We expect the OUTPUT_DIRECTORY to contain a file called "dependencies.json.gz" that contains the inverse dependencies of each spec file.
# We use this information to determine which spec files to run based on the files that have changed.
# This class reads the "dependencies.json.gz" file and outputs a list of spec files that need to be run by using git to determine files that have changed.

module Spectacle
  class DownloadDependenciesJson
    include Spectacle::HelperMethods

    def self.download
      new.download
    end

    def download
      unless ENV["BUILDKITE_AGENT_ACCESS_TOKEN"]
        raise "BUILDKITE_AGENT_ACCESS_TOKEN is not set. The `spectacle:download_dependencies` task can only be run on a Buildkite agent."
      end

      unless pipeline_slug = ENV["DEPENDENCIES_ARTIFACT_PIPELINE_SLUG"]
        raise "DEPENDENCIES_ARTIFACT_PIPELINE_SLUG is not set. Please set this to the pipeline slug that generates the dependencies.json.gz artifact."
      end

      unless token = ENV["BUILDKITE_ACCESS_TOKEN"]
        raise "BUILDKITE_ACCESS_TOKEN is not set. Please set this to the Buildkite API access token."
      end

      puts "Downloading dependencies.json.gz..."

      build_id = nil
      organization_slug = ENV["BUILDKITE_ORGANIZATION_SLUG"]

      Net::HTTP.start("api.buildkite.com", use_ssl: true) do |http|
        request = Net::HTTP::Get.new("/v2/organizations/#{organization_slug}/pipelines/#{pipeline_slug}/builds?per_page=1")
        request["Authorization"] = "Bearer #{token}"
        response = http.request(request)

        build_id = JSON.parse(response.body).first["id"]
        puts "Build ID: '#{build_id}'"
      end

      system("buildkite-agent artifact download '#{Spectacle::COLLECTED_DEPENDENCIES_FILE}' . --build '#{build_id}'")
    end
  end
end
