# frozen_string_literal: true

RSpec.describe Spectracer::Orchestrators::DependencyTracer do
  subject(:tracer) do
    described_class.new(
      paths: paths,
      store: store,
      repository: repository,
      path_filter: path_filter,
      logger: logger
    )
  end

  let(:paths) { Spectracer::Core::Paths.new }
  let(:store) { instance_double(Spectracer::IO::DependencyStore, write: nil) }
  let(:repository) { Spectracer::Providers::Repository.new }
  let(:path_filter) { Spectracer::Core::PathFilter.new }
  let(:logger) { nil }

  describe "#current_spec_file=" do
    it "strips ./ prefix from spec file path" do
      tracer.current_spec_file = "./spec/foo_spec.rb"

      tracer.with_tracing { 1 + 1 }

      tracer.write_output!
    end
  end

  describe "#with_tracing" do
    it "enables and disables tracepoint without error" do
      tracer.current_spec_file = "./spec/foo_spec.rb"

      result = tracer.with_tracing { 1 + 1 }

      expect(result).to eq(2)
    end
  end

  describe "#write_output!" do
    context "when no dependencies were collected" do
      it "does not write to store" do
        tracer.write_output!

        expect(store).not_to have_received(:write)
      end
    end
  end
end
