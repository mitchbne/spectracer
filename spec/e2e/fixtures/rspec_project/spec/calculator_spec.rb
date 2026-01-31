# frozen_string_literal: true

require_relative "../lib/calculator"

RSpec.describe Calculator do
  subject(:calculator) { described_class.new }

  describe "#add" do
    it "adds two numbers" do
      expect(calculator.add(2, 3)).to eq(5)
    end
  end

  describe "#subtract" do
    it "subtracts two numbers" do
      expect(calculator.subtract(5, 3)).to eq(2)
    end
  end
end
