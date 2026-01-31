# frozen_string_literal: true

RSpec.describe Spectracer::Logger do
  let(:output) { StringIO.new }

  describe "when disabled" do
    subject(:logger) { described_class.new(output: output, enabled: false) }

    it "does not output anything" do
      logger.debug("test")
      logger.info("test")
      logger.warn("test")
      logger.error("test")

      expect(output.string).to be_empty
    end
  end

  describe "when enabled" do
    subject(:logger) { described_class.new(output: output, enabled: true, level: :debug) }

    it "outputs debug messages" do
      logger.debug("debug message")
      expect(output.string).to include("[Spectracer] DEBUG: debug message")
    end

    it "outputs info messages" do
      logger.info("info message")
      expect(output.string).to include("[Spectracer] INFO: info message")
    end

    it "outputs warn messages" do
      logger.warn("warn message")
      expect(output.string).to include("[Spectracer] WARN: warn message")
    end

    it "outputs error messages" do
      logger.error("error message")
      expect(output.string).to include("[Spectracer] ERROR: error message")
    end
  end

  describe "log level filtering" do
    subject(:logger) { described_class.new(output: output, enabled: true, level: :warn) }

    it "filters messages below the level" do
      logger.debug("debug")
      logger.info("info")

      expect(output.string).to be_empty
    end

    it "outputs messages at or above the level" do
      logger.warn("warn")
      logger.error("error")

      expect(output.string).to include("WARN: warn")
      expect(output.string).to include("ERROR: error")
    end
  end
end
