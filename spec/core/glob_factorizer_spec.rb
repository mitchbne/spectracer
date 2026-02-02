# frozen_string_literal: true

require "spec_helper"

RSpec.describe Spectracer::Core::GlobFactorizer do
  subject(:factorizer) { described_class.new }

  describe "#call" do
    context "with empty or single patterns" do
      it "returns empty array for empty input" do
        expect(factorizer.call([])).to eq([])
      end

      it "returns single pattern unchanged" do
        expect(factorizer.call(["spec/user_spec.rb"])).to eq(["spec/user_spec.rb"])
      end
    end

    context "when concrete files are covered by globs" do
      it "removes files matched by a glob" do
        patterns = [
          "spec/**/*_spec.rb",
          "spec/models/user_spec.rb",
          "spec/models/post_spec.rb"
        ]

        result = factorizer.call(patterns)

        expect(result).to eq(["spec/**/*_spec.rb"])
      end

      it "keeps files not matched by any glob" do
        patterns = [
          "spec/models/*_spec.rb",
          "spec/controllers/users_controller_spec.rb"
        ]

        result = factorizer.call(patterns)

        expect(result).to contain_exactly(
          "spec/models/*_spec.rb",
          "spec/controllers/users_controller_spec.rb"
        )
      end
    end

    context "when globs subsume other globs" do
      it "removes narrower globs covered by broader ones" do
        patterns = [
          "spec/user/**/*_spec.rb",
          "spec/user/**/one_spec.rb",
          "spec/user/**/two_spec.rb"
        ]

        result = factorizer.call(patterns)

        expect(result).to eq(["spec/user/**/*_spec.rb"])
      end

      it "removes directory-specific globs covered by recursive globs" do
        patterns = [
          "spec/**/*_spec.rb",
          "spec/models/*_spec.rb",
          "spec/controllers/*_spec.rb"
        ]

        result = factorizer.call(patterns)

        expect(result).to eq(["spec/**/*_spec.rb"])
      end

      it "keeps independent globs that don't overlap" do
        patterns = [
          "spec/models/*_spec.rb",
          "spec/controllers/*_spec.rb"
        ]

        result = factorizer.call(patterns)

        expect(result).to contain_exactly(
          "spec/models/*_spec.rb",
          "spec/controllers/*_spec.rb"
        )
      end
    end

    context "with mixed patterns" do
      it "factorizes both globs and files" do
        patterns = [
          "spec/**/*_spec.rb",
          "spec/models/*_spec.rb",
          "spec/models/user_spec.rb",
          "lib/spectracer.rb"
        ]

        result = factorizer.call(patterns)

        expect(result).to contain_exactly(
          "spec/**/*_spec.rb",
          "lib/spectracer.rb"
        )
      end
    end

    context "with Set input" do
      it "accepts a Set and returns an Array" do
        patterns = Set.new(["spec/**/*_spec.rb", "spec/models/user_spec.rb"])

        result = factorizer.call(patterns)

        expect(result).to be_an(Array)
        expect(result).to eq(["spec/**/*_spec.rb"])
      end
    end
  end
end
