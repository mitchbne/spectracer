# frozen_string_literal: true

RSpec.describe Spectracer::Providers::GitChangedFiles do
  subject(:provider) { described_class.new(git_adapter: git_adapter, env: env) }

  let(:git_adapter) { instance_double(Spectracer::IO::GitAdapter) }
  let(:env) { {} }

  describe "#call" do
    context "in CI on default branch" do
      let(:env) do
        {
          "BUILDKITE_BUILD_ID" => "12345",
          "BUILDKITE_PIPELINE_DEFAULT_BRANCH" => "main",
          "BUILDKITE_BRANCH" => "main"
        }
      end

      before do
        allow(git_adapter).to receive(:commit_sha)
          .with("main")
          .and_return("abc123def456")

        allow(git_adapter).to receive(:changed_files_in_commit)
          .with("abc123def456")
          .and_return(["app/models/user.rb", "spec/models/user_spec.rb"])
      end

      it "returns changed files from latest commit" do
        expect(provider.call).to eq(["app/models/user.rb", "spec/models/user_spec.rb"])
      end
    end

    context "in CI on feature branch" do
      let(:env) do
        {
          "BUILDKITE_BUILD_ID" => "12345",
          "BUILDKITE_PIPELINE_DEFAULT_BRANCH" => "main",
          "BUILDKITE_BRANCH" => "feature/new-thing"
        }
      end

      before do
        allow(git_adapter).to receive(:changed_files_against)
          .with("main", include_uncommitted: true)
          .and_return(["lib/new_feature.rb"])
      end

      it "returns changed files compared to default branch" do
        expect(provider.call).to eq(["lib/new_feature.rb"])
      end
    end

    context "running locally (no BUILDKITE_BUILD_ID)" do
      let(:env) { {} }

      before do
        allow(git_adapter).to receive(:current_branch)
          .and_return("feature/local")

        allow(git_adapter).to receive(:local_changed_files)
          .and_return(["local_change.rb", "uncommitted.rb"])
      end

      it "returns local changed files (uncommitted + branch diff)" do
        expect(provider.call).to eq(["local_change.rb", "uncommitted.rb"])
      end
    end

    context "running locally on main branch" do
      let(:env) { {} }

      before do
        allow(git_adapter).to receive(:current_branch)
          .and_return("main")

        allow(git_adapter).to receive(:local_changed_files)
          .and_return(["uncommitted_only.rb"])
      end

      it "returns uncommitted changes only" do
        expect(provider.call).to eq(["uncommitted_only.rb"])
      end
    end
  end
end
