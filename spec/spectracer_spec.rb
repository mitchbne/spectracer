# frozen_string_literal: true

RSpec.describe Spectracer do
  it "has a version number" do
    expect(Spectracer::VERSION).not_to be_nil
  end

  describe ".logger" do
    it "returns a Logger instance" do
      expect(Spectracer.logger).to be_a(Spectracer::Logger)
    end

    it "memoizes the logger" do
      expect(Spectracer.logger).to be(Spectracer.logger)
    end
  end

  describe ".paths" do
    it "returns a Paths instance" do
      expect(Spectracer.paths).to be_a(Spectracer::Core::Paths)
    end

    it "memoizes paths" do
      expect(Spectracer.paths).to be(Spectracer.paths)
    end
  end
end
