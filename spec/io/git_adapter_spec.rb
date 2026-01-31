# frozen_string_literal: true

RSpec.describe Spectracer::IO::GitAdapter do
  subject(:adapter) { described_class.new(working_dir: Dir.pwd) }

  describe "#repository_root" do
    it "returns the repository root path" do
      expect(adapter.repository_root).to be_a(String)
      expect(adapter.repository_root).not_to be_empty
    end
  end

  describe "#current_branch" do
    it "returns the current branch name" do
      expect(adapter.current_branch).to be_a(String)
      expect(adapter.current_branch).not_to be_empty
    end
  end

  describe "#commit_sha" do
    it "returns the SHA for HEAD" do
      sha = adapter.commit_sha("HEAD")
      expect(sha).to match(/\A[0-9a-f]{40}\z/)
    end
  end

  describe "#changed_files_in_commit" do
    it "returns an array of file paths" do
      sha = adapter.commit_sha("HEAD")
      files = adapter.changed_files_in_commit(sha)
      expect(files).to be_an(Array)
    end
  end

  describe "#changed_files_against" do
    context "when target branch exists" do
      it "returns an array of file paths" do
        files = adapter.changed_files_against("HEAD~1", cached: false)
        expect(files).to be_an(Array)
      end
    end

    context "when target branch does not exist" do
      it "returns empty array and logs warning" do
        logger = instance_double(Spectracer::Logger)
        adapter_with_logger = described_class.new(working_dir: Dir.pwd, logger: logger)

        allow(logger).to receive(:warn)

        files = adapter_with_logger.changed_files_against("nonexistent-branch-xyz")
        expect(files).to eq([])
      end
    end
  end
end
