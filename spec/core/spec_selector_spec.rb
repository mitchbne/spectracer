# frozen_string_literal: true

RSpec.describe Spectracer::Core::SpecSelector do
  subject(:selector) { described_class.new }

  describe "#call" do
    let(:inverse_deps) do
      {
        "./app/models/user.rb" => ["spec/models/user_spec.rb"],
        "./app/controllers/users_controller.rb" => ["spec/controllers/users_controller_spec.rb"],
        "./lib/shared.rb" => ["spec/models/user_spec.rb", "spec/models/post_spec.rb"]
      }
    end

    let(:globs) do
      {
        "db/migrate/**/*" => "spec/models/**/*_spec.rb",
        "config/routes.rb" => "spec/routing/**/*_spec.rb"
      }
    end

    let(:on_empty) { "spec/smoke/**/*_spec.rb" }

    context "when a spec file itself changed" do
      it "includes the spec file" do
        result = selector.call(
          changed_files: ["spec/models/post_spec.rb"],
          inverse_deps: {},
          globs: {},
          on_empty: on_empty
        )

        expect(result.specs).to eq("spec/models/post_spec.rb")
        expect(result.file_to_specs_map).to eq({"spec/models/post_spec.rb" => ["spec/models/post_spec.rb"]})
      end
    end

    context "when a minitest file itself changed" do
      it "includes the test file" do
        result = selector.call(
          changed_files: ["test/models/user_test.rb"],
          inverse_deps: {},
          globs: {},
          on_empty: on_empty
        )

        expect(result.specs).to eq("test/models/user_test.rb")
        expect(result.file_to_specs_map).to eq({"test/models/user_test.rb" => ["test/models/user_test.rb"]})
      end
    end

    context "when a source file with dependencies changed" do
      it "includes specs that depend on it" do
        result = selector.call(
          changed_files: ["app/models/user.rb"],
          inverse_deps: inverse_deps,
          globs: {},
          on_empty: on_empty
        )

        expect(result.specs).to eq("spec/models/user_spec.rb")
        expect(result.file_to_specs_map).to eq({"app/models/user.rb" => ["spec/models/user_spec.rb"]})
      end
    end

    context "when a file matches a glob pattern" do
      it "includes the glob's target pattern" do
        result = selector.call(
          changed_files: ["config/routes.rb"],
          inverse_deps: {},
          globs: globs,
          on_empty: on_empty
        )

        expect(result.specs).to eq("spec/routing/**/*_spec.rb")
        expect(result.file_to_specs_map).to eq({"config/routes.rb" => ["spec/routing/**/*_spec.rb"]})
      end
    end

    context "when multiple files changed" do
      it "aggregates and sorts all matching specs" do
        result = selector.call(
          changed_files: ["app/models/user.rb", "lib/shared.rb"],
          inverse_deps: inverse_deps,
          globs: {},
          on_empty: on_empty
        )

        expect(result.specs).to eq("spec/models/post_spec.rb,spec/models/user_spec.rb")
        expect(result.file_to_specs_map).to eq({
          "app/models/user.rb" => ["spec/models/user_spec.rb"],
          "lib/shared.rb" => ["spec/models/post_spec.rb", "spec/models/user_spec.rb"]
        })
      end
    end

    context "when no specs match" do
      it "returns the on_empty pattern" do
        result = selector.call(
          changed_files: ["README.md"],
          inverse_deps: {},
          globs: {},
          on_empty: on_empty
        )

        expect(result.specs).to eq(on_empty)
        expect(result.file_to_specs_map).to eq({})
      end
    end

    context "with mixed scenarios" do
      it "handles spec files, dependencies, and globs together" do
        result = selector.call(
          changed_files: [
            "spec/models/custom_spec.rb",
            "app/controllers/users_controller.rb",
            "config/routes.rb"
          ],
          inverse_deps: inverse_deps,
          globs: globs,
          on_empty: on_empty
        )

        specs = result.specs.split(",")
        expect(specs).to include("spec/models/custom_spec.rb")
        expect(specs).to include("spec/controllers/users_controller_spec.rb")
        expect(specs).to include("spec/routing/**/*_spec.rb")

        expect(result.file_to_specs_map).to eq({
          "spec/models/custom_spec.rb" => ["spec/models/custom_spec.rb"],
          "app/controllers/users_controller.rb" => ["spec/controllers/users_controller_spec.rb"],
          "config/routes.rb" => ["spec/routing/**/*_spec.rb"]
        })
      end
    end
  end
end
