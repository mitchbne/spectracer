# frozen_string_literal: true

RSpec.describe Spectracer::Integrations::Minitest do
  describe ".install!" do
    before do
      described_class.tracer = nil
    end

    context "when Minitest is not defined" do
      before do
        hide_const("Minitest")
      end

      it "does not install" do
        expect { described_class.install! }.not_to raise_error
        expect(described_class.tracer).to be_nil
      end
    end

    context "when WITH_SPECTRACER_TRACING is not set" do
      before do
        stub_const("Minitest", Class.new)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("WITH_SPECTRACER_TRACING").and_return(nil)
      end

      it "does not install" do
        described_class.install!
        expect(described_class.tracer).to be_nil
      end
    end

    context "when Minitest is defined and tracing is enabled" do
      let(:minitest_mock) { Class.new }

      before do
        stub_const("Minitest", minitest_mock)
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("WITH_SPECTRACER_TRACING").and_return("true")
        allow(ENV).to receive(:[]).with("WITH_SPECTRACER_DEBUG").and_return("false")
      end

      it "creates a tracer" do
        described_class.install!
        expect(described_class.tracer).to be_a(Spectracer::Orchestrators::DependencyTracer)
      end
    end
  end

  describe Spectracer::Integrations::Minitest::TestCasePlugin do
    let(:tracer) { instance_double(Spectracer::Orchestrators::DependencyTracer) }

    let(:base_class) do
      Class.new do
        attr_accessor :name

        def initialize(name)
          @name = name
        end

        def method(name)
          Object.instance_method(:to_s)
        end

        def run
          :test_result
        end

        def before_setup
        end
      end
    end

    let(:test_class) do
      klass = Class.new(base_class)
      klass.prepend(Spectracer::Integrations::Minitest::TestCasePlugin)
      klass
    end

    before do
      Spectracer::Integrations::Minitest.tracer = tracer
    end

    after do
      Spectracer::Integrations::Minitest.tracer = nil
    end

    describe "#run" do
      it "wraps test execution with tracing" do
        test_instance = test_class.new("test_example")

        expect(tracer).to receive(:with_tracing).and_yield

        result = test_instance.run
        expect(result).to eq(:test_result)
      end
    end
  end
end
