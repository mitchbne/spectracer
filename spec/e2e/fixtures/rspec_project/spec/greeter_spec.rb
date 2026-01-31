# frozen_string_literal: true

require_relative "../lib/greeter"

RSpec.describe Greeter do
  subject(:greeter) { described_class.new("World") }

  describe "#greet" do
    it "returns a greeting message" do
      expect(greeter.greet).to eq("Hello, World!")
    end
  end
end
