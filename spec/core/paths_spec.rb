# frozen_string_literal: true

RSpec.describe Spectacle::Core::Paths do
  subject(:paths) { described_class.new(env: env) }

  let(:env) { {} }

  describe "#build_id" do
    context "when BUILDKITE_BUILD_ID is set" do
      let(:env) { {"BUILDKITE_BUILD_ID" => "abc123"} }

      it "returns the build ID" do
        expect(paths.build_id).to eq("abc123")
      end
    end

    context "when BUILDKITE_BUILD_ID is not set" do
      it "returns 'local'" do
        expect(paths.build_id).to eq("local")
      end
    end
  end

  describe "#job_id" do
    context "when BUILDKITE_JOB_ID is set" do
      let(:env) { {"BUILDKITE_JOB_ID" => "job456"} }

      it "returns the job ID" do
        expect(paths.job_id).to eq("job456")
      end
    end

    context "when BUILDKITE_JOB_ID is not set" do
      it "returns 'local'" do
        expect(paths.job_id).to eq("local")
      end
    end
  end

  describe "#output_directory" do
    context "when SPECTACLE_TMP_DIRECTORY is set" do
      let(:env) { {"SPECTACLE_TMP_DIRECTORY" => "/custom/path"} }

      it "returns the custom path" do
        expect(paths.output_directory).to eq("/custom/path")
      end
    end

    context "when SPECTACLE_TMP_DIRECTORY is not set" do
      it "returns the default path" do
        expect(paths.output_directory).to eq("tmp/spectacle")
      end
    end
  end

  describe "#spec_artifact_output_file" do
    let(:env) { {"BUILDKITE_BUILD_ID" => "build1", "BUILDKITE_JOB_ID" => "job1"} }

    it "returns the correct path" do
      expect(paths.spec_artifact_output_file).to eq("tmp/spectacle/tracing_output/build1/job1.json.gz")
    end
  end

  describe "#normalize" do
    it "converts absolute path to relative with dot prefix" do
      result = paths.normalize("/home/user/project/app/models/user.rb", repo_root: "/home/user/project")
      expect(result).to eq("./app/models/user.rb")
    end

    it "adds dot prefix if not present" do
      result = paths.normalize("app/models/user.rb", repo_root: "/somewhere/else")
      expect(result).to eq("./app/models/user.rb")
    end

    it "preserves dot prefix if already present" do
      result = paths.normalize("./app/models/user.rb", repo_root: "/somewhere/else")
      expect(result).to eq("./app/models/user.rb")
    end
  end

  describe "#strip_dot_prefix" do
    it "removes leading ./" do
      expect(paths.strip_dot_prefix("./app/models/user.rb")).to eq("app/models/user.rb")
    end

    it "leaves paths without prefix unchanged" do
      expect(paths.strip_dot_prefix("app/models/user.rb")).to eq("app/models/user.rb")
    end
  end
end
