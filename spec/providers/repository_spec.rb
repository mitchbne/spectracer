# frozen_string_literal: true

RSpec.describe Spectacle::Providers::Repository do
  subject(:repository) { described_class.new(git_adapter: git_adapter) }

  let(:git_adapter) { instance_double(Spectacle::IO::GitAdapter) }

  describe "#root" do
    before do
      allow(git_adapter).to receive(:repository_root).and_return("/home/user/project")
    end

    it "returns the repository root from git adapter" do
      expect(repository.root).to eq("/home/user/project")
    end

    it "memoizes the result" do
      expect(git_adapter).to receive(:repository_root).once.and_return("/home/user/project")

      2.times { repository.root }
    end
  end
end
