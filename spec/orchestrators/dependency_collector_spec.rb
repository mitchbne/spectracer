# frozen_string_literal: true

require "spectracer"

RSpec.describe Spectracer::Orchestrators::DependencyCollector do
  let(:paths) { instance_double(Spectracer::Core::Paths, collected_dependencies_file: "deps.json.gz", spec_artifacts_download_glob: "*.json.gz") }
  let(:store) { instance_double(Spectracer::IO::DependencyStore) }
  let(:collector) { described_class.new(paths: paths, store: store) }

  describe "#collect!" do
    before do
      allow(store).to receive(:glob).and_return(["artifact1.json.gz"])
      allow(store).to receive(:write)
    end

    it "excludes gem paths from inverse dependencies" do
      gem_path = File.join(Gem.path.first, "gems/rspec-core-3.13.0/lib/rspec/core.rb")
      allow(store).to receive(:read).with("artifact1.json.gz").and_return({
        "./spec/example_spec.rb" => [
          "./lib/example.rb",
          gem_path
        ]
      })

      collector.collect!

      expect(store).to have_received(:write) do |data, _path|
        expect(data.keys).to eq(["./lib/example.rb"])
      end
    end

    it "includes non-vendor paths" do
      allow(store).to receive(:read).with("artifact1.json.gz").and_return({
        "./spec/example_spec.rb" => ["./lib/example.rb", "./lib/other.rb"]
      })

      collector.collect!

      expect(store).to have_received(:write) do |data, _path|
        expect(data.keys).to contain_exactly("./lib/example.rb", "./lib/other.rb")
      end
    end
  end
end
