# frozen_string_literal: true

RSpec.describe Spectracer::Orchestrators::SpecRunDeterminer do
  subject(:determiner) do
    described_class.new(
      paths: paths,
      store: store,
      config_loader: config_loader,
      changed_files_provider: changed_files_provider,
      selector: selector
    )
  end

  let(:paths) { instance_double(Spectracer::Core::Paths, collected_dependencies_file: "/tmp/deps.json.gz") }
  let(:store) { instance_double(Spectracer::IO::DependencyStore) }
  let(:config_loader) { instance_double(Spectracer::IO::ConfigLoader) }
  let(:changed_files_provider) { instance_double(Spectracer::Providers::GitChangedFiles) }
  let(:selector) { instance_double(Spectracer::Core::SpecSelector) }

  let(:dependencies) { {"./app/models/user.rb" => ["spec/models/user_spec.rb"]} }
  let(:config) { {globs: {}, on_empty_spec_set: "spec/smoke_spec.rb"} }
  let(:changed_files) { ["app/models/user.rb"] }

  before do
    allow(File).to receive(:exist?).with("/tmp/deps.json.gz").and_return(true)
    allow(store).to receive(:read).with("/tmp/deps.json.gz").and_return(dependencies)
    allow(config_loader).to receive(:load).and_return(config)
    allow(changed_files_provider).to receive(:call).and_return(changed_files)
  end

  describe "#determine!" do
    it "passes data to selector and returns result" do
      expect(selector).to receive(:call).with(
        changed_files: changed_files,
        inverse_deps: dependencies,
        globs: config[:globs],
        on_empty: config[:on_empty_spec_set]
      ).and_return("spec/models/user_spec.rb")

      expect(determiner.determine!).to eq("spec/models/user_spec.rb")
    end

    context "when dependencies file does not exist" do
      before do
        allow(File).to receive(:exist?).with("/tmp/deps.json.gz").and_return(false)
      end

      it "uses empty dependencies" do
        expect(selector).to receive(:call).with(
          changed_files: changed_files,
          inverse_deps: {},
          globs: config[:globs],
          on_empty: config[:on_empty_spec_set]
        ).and_return("spec/smoke_spec.rb")

        expect(determiner.determine!).to eq("spec/smoke_spec.rb")
      end
    end
  end
end
