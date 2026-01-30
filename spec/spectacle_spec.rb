# frozen_string_literal: true

RSpec.describe Spectacle do
  it "has a version number" do
    expect(Spectacle::VERSION).not_to be_nil
  end

  describe ".logger" do
    it "returns a Logger instance" do
      expect(Spectacle.logger).to be_a(Spectacle::Logger)
    end

    it "memoizes the logger" do
      expect(Spectacle.logger).to be(Spectacle.logger)
    end
  end

  describe ".paths" do
    it "returns a Paths instance" do
      expect(Spectacle.paths).to be_a(Spectacle::Core::Paths)
    end

    it "memoizes paths" do
      expect(Spectacle.paths).to be(Spectacle.paths)
    end
  end
end
