# frozen_string_literal: true

RSpec.describe Spectacle::IO::ConfigLoader do
  subject(:loader) { described_class.new }

  describe "#load" do
    context "when no config file exists" do
      before do
        allow(File).to receive(:exist?).with(".spectacle.yml").and_return(false)
      end

      it "loads default configuration" do
        config = loader.load

        expect(config).to have_key(:on_empty_spec_set)
        expect(config).to have_key(:globs)
      end
    end

    context "when config file exists" do
      let(:config_content) do
        {
          "defaults" => {"all_specs" => "spec/**/*_spec.rb"},
          "on_empty_spec_set" => "{{all_specs}}",
          "globs_matcher" => {"Gemfile" => "{{all_specs}}"}
        }
      end

      before do
        allow(File).to receive(:exist?).with(".spectacle.yml").and_return(true)
        allow(YAML).to receive(:safe_load_file).with(".spectacle.yml").and_return(config_content)
      end

      it "resolves templates in on_empty_spec_set" do
        config = loader.load
        expect(config[:on_empty_spec_set]).to eq("spec/**/*_spec.rb")
      end

      it "resolves templates in globs" do
        config = loader.load
        expect(config[:globs]["Gemfile"]).to eq("spec/**/*_spec.rb")
      end
    end
  end
end
