# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

RSpec.describe Spectracer::IO::GitAdapter, "merge-base behavior" do
  let(:tmp_dir) { Dir.mktmpdir("spectracer-git-adapter") }
  let(:adapter) { described_class.new(working_dir: tmp_dir) }

  before do
    Dir.chdir(tmp_dir) do
      system("git init --quiet --initial-branch=main", exception: true)
      system("git config user.email 'test@test.com'", exception: true)
      system("git config user.name 'Test'", exception: true)
    end
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe "#changed_files_against with merge-base" do
    context "when main has commits after branch diverged" do
      before do
        Dir.chdir(tmp_dir) do
          # Initial commit on main
          File.write("file1.rb", "initial content")
          system("git add file1.rb && git commit -m 'Initial commit' --quiet", exception: true)

          # Create feature branch
          system("git checkout -b feature-branch --quiet", exception: true)

          # Make changes on feature branch
          File.write("file2.rb", "feature content")
          system("git add file2.rb && git commit -m 'Add file2 on feature' --quiet", exception: true)

          File.write("file3.rb", "more feature content")
          system("git add file3.rb && git commit -m 'Add file3 on feature' --quiet", exception: true)

          # Go back to main and add commits (simulating other PRs merging)
          system("git checkout main --quiet", exception: true)
          File.write("file4.rb", "main branch addition")
          system("git add file4.rb && git commit -m 'Add file4 on main' --quiet", exception: true)

          File.write("file5.rb", "another main addition")
          system("git add file5.rb && git commit -m 'Add file5 on main' --quiet", exception: true)

          # Back to feature branch for testing
          system("git checkout feature-branch --quiet", exception: true)
        end
      end

      it "returns only files changed on the feature branch (not files changed on main)" do
        files = adapter.changed_files_against("main", include_uncommitted: false)

        expect(files).to contain_exactly("file2.rb", "file3.rb")
        expect(files).not_to include("file4.rb")
        expect(files).not_to include("file5.rb")
      end

      it "matches git diff --name-only main...HEAD output" do
        expected_files = Dir.chdir(tmp_dir) do
          `git diff --name-only main...HEAD`.split("\n")
        end

        files = adapter.changed_files_against("main", include_uncommitted: false)

        expect(files.sort).to eq(expected_files.sort)
      end
    end

    context "when feature branch has uncommitted changes" do
      before do
        Dir.chdir(tmp_dir) do
          File.write("file1.rb", "initial content")
          system("git add file1.rb && git commit -m 'Initial commit' --quiet", exception: true)

          system("git checkout -b feature-branch --quiet", exception: true)

          File.write("file2.rb", "committed on feature")
          system("git add file2.rb && git commit -m 'Add file2' --quiet", exception: true)

          # Uncommitted changes (staged so they're tracked)
          File.write("file3.rb", "uncommitted new file")
          system("git add file3.rb", exception: true)
          File.write("file1.rb", "modified content")
        end
      end

      it "includes both committed and uncommitted changes when include_uncommitted is true" do
        files = adapter.changed_files_against("main", include_uncommitted: true)

        expect(files).to include("file2.rb") # committed
        expect(files).to include("file3.rb") # staged new file
        expect(files).to include("file1.rb") # unstaged modified
      end

      it "excludes uncommitted changes when include_uncommitted is false" do
        files = adapter.changed_files_against("main", include_uncommitted: false)

        expect(files).to contain_exactly("file2.rb")
      end
    end

    context "when branch has file modifications, additions, and deletions" do
      before do
        Dir.chdir(tmp_dir) do
          File.write("existing.rb", "original")
          File.write("to_delete.rb", "will be deleted")
          File.write("to_modify.rb", "will be modified")
          system("git add -A && git commit -m 'Initial' --quiet", exception: true)

          system("git checkout -b feature --quiet", exception: true)

          File.write("new_file.rb", "added on branch")
          FileUtils.rm("to_delete.rb")
          File.write("to_modify.rb", "modified content")
          system("git add -A && git commit -m 'Changes on feature' --quiet", exception: true)
        end
      end

      it "includes all types of changes" do
        files = adapter.changed_files_against("main", include_uncommitted: false)

        expect(files).to include("new_file.rb")    # added
        expect(files).to include("to_delete.rb")   # deleted
        expect(files).to include("to_modify.rb")   # modified
        expect(files).not_to include("existing.rb") # unchanged
      end
    end

    context "when comparing against origin/main" do
      before do
        Dir.chdir(tmp_dir) do
          File.write("file1.rb", "initial")
          system("git add file1.rb && git commit -m 'Initial' --quiet", exception: true)

          # Create a bare remote and push
          remote_dir = File.join(tmp_dir, "remote.git")
          system("git clone --bare . #{remote_dir} --quiet", exception: true)
          system("git remote add origin #{remote_dir}", exception: true)

          system("git checkout -b feature --quiet", exception: true)
          File.write("file2.rb", "feature")
          system("git add file2.rb && git commit -m 'Feature' --quiet", exception: true)

          # Push more commits to origin/main
          system("git checkout main --quiet", exception: true)
          File.write("file3.rb", "main update")
          system("git add file3.rb && git commit -m 'Main update' --quiet", exception: true)
          system("git push origin main --quiet 2>/dev/null", exception: true)

          system("git checkout feature --quiet", exception: true)
          system("git fetch origin --quiet", exception: true)
        end
      end

      it "uses merge-base with origin/main correctly" do
        files = adapter.changed_files_against("main", include_uncommitted: false)

        expect(files).to contain_exactly("file2.rb")
        expect(files).not_to include("file3.rb")
      end
    end
  end
end
