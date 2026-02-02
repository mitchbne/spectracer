# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"
require "bundler"

RSpec.describe "Install Test Framework Detection", :e2e do
  let(:spectracer_root) { File.expand_path("../..", __dir__) }
  let(:tmp_dir) { Dir.mktmpdir("spectracer-e2e-install") }

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  def setup_project(gemfile_content:, has_test_dir: false)
    File.write(File.join(tmp_dir, "Gemfile"), gemfile_content)
    File.write(File.join(tmp_dir, "Rakefile"), <<~RUBY)
      # frozen_string_literal: true

      require "bundler/setup"
      require "spectracer"

      load "spectracer/tasks/spectracer.rake"
    RUBY

    FileUtils.mkdir_p(File.join(tmp_dir, "test")) if has_test_dir

    Bundler.with_unbundled_env do
      Dir.chdir(tmp_dir) do
        system("bundle install --quiet", exception: true)
      end
    end
  end

  describe "spectracer:install" do
    context "when project uses RSpec" do
      before do
        setup_project(gemfile_content: <<~GEMFILE)
          # frozen_string_literal: true

          source "https://rubygems.org"

          gem "rake", "~> 13.0"
          gem "rspec", "~> 3.12"
          gem "spectracer", path: "#{spectracer_root}"
        GEMFILE
      end

      it "detects RSpec and creates RSpec config" do
        Bundler.with_unbundled_env do
          Dir.chdir(tmp_dir) do
            output = `bundle exec rake spectracer:install 2>&1`

            expect($?.success?).to be(true), "Install failed: #{output}"
            expect(output).to include("Detected test framework: rspec")

            config_content = File.read(".spectracer.yml")
            expect(config_content).to include("spec/**/*_spec.rb")
            expect(config_content).to include("Test framework: RSpec")
          end
        end
      end
    end

    context "when project uses rspec-rails" do
      before do
        setup_project(gemfile_content: <<~GEMFILE)
          # frozen_string_literal: true

          source "https://rubygems.org"

          gem "rake", "~> 13.0"
          gem "rspec-rails", "~> 6.0"
          gem "spectracer", path: "#{spectracer_root}"
        GEMFILE
      end

      it "detects RSpec and creates RSpec config" do
        Bundler.with_unbundled_env do
          Dir.chdir(tmp_dir) do
            output = `bundle exec rake spectracer:install 2>&1`

            expect($?.success?).to be(true), "Install failed: #{output}"
            expect(output).to include("Detected test framework: rspec")

            config_content = File.read(".spectracer.yml")
            expect(config_content).to include("spec/**/*_spec.rb")
          end
        end
      end
    end

    context "when project uses Minitest" do
      before do
        setup_project(gemfile_content: <<~GEMFILE)
          # frozen_string_literal: true

          source "https://rubygems.org"

          gem "rake", "~> 13.0"
          gem "minitest", "~> 5.0"
          gem "spectracer", path: "#{spectracer_root}"
        GEMFILE
      end

      it "detects Minitest and creates Minitest config" do
        Bundler.with_unbundled_env do
          Dir.chdir(tmp_dir) do
            output = `bundle exec rake spectracer:install 2>&1`

            expect($?.success?).to be(true), "Install failed: #{output}"
            expect(output).to include("Detected test framework: minitest")

            config_content = File.read(".spectracer.yml")
            expect(config_content).to include("test/**/*_test.rb")
            expect(config_content).to include("Test framework: Minitest")
          end
        end
      end
    end

    context "when project has test/ directory but no minitest gem" do
      before do
        setup_project(
          gemfile_content: <<~GEMFILE,
            # frozen_string_literal: true

            source "https://rubygems.org"

            gem "rake", "~> 13.0"
            gem "spectracer", path: "#{spectracer_root}"
          GEMFILE
          has_test_dir: true
        )
      end

      it "detects Minitest from test/ directory" do
        Bundler.with_unbundled_env do
          Dir.chdir(tmp_dir) do
            output = `bundle exec rake spectracer:install 2>&1`

            expect($?.success?).to be(true), "Install failed: #{output}"
            expect(output).to include("Detected test framework: minitest")

            config_content = File.read(".spectracer.yml")
            expect(config_content).to include("test/**/*_test.rb")
          end
        end
      end
    end

    context "when project has both RSpec and Minitest" do
      before do
        setup_project(
          gemfile_content: <<~GEMFILE,
            # frozen_string_literal: true

            source "https://rubygems.org"

            gem "rake", "~> 13.0"
            gem "rspec", "~> 3.12"
            gem "minitest", "~> 5.0"
            gem "spectracer", path: "#{spectracer_root}"
          GEMFILE
          has_test_dir: true
        )
      end

      it "prefers RSpec when both are present" do
        Bundler.with_unbundled_env do
          Dir.chdir(tmp_dir) do
            output = `bundle exec rake spectracer:install 2>&1`

            expect($?.success?).to be(true), "Install failed: #{output}"
            expect(output).to include("Detected test framework: rspec")

            config_content = File.read(".spectracer.yml")
            expect(config_content).to include("spec/**/*_spec.rb")
          end
        end
      end
    end

    context "when project has no test framework" do
      before do
        setup_project(gemfile_content: <<~GEMFILE)
          # frozen_string_literal: true

          source "https://rubygems.org"

          gem "rake", "~> 13.0"
          gem "spectracer", path: "#{spectracer_root}"
        GEMFILE
      end

      it "defaults to RSpec" do
        Bundler.with_unbundled_env do
          Dir.chdir(tmp_dir) do
            output = `bundle exec rake spectracer:install 2>&1`

            expect($?.success?).to be(true), "Install failed: #{output}"
            expect(output).to include("Detected test framework: rspec")

            config_content = File.read(".spectracer.yml")
            expect(config_content).to include("spec/**/*_spec.rb")
          end
        end
      end
    end

    context "when .spectracer.yml already exists" do
      before do
        setup_project(gemfile_content: <<~GEMFILE)
          # frozen_string_literal: true

          source "https://rubygems.org"

          gem "rake", "~> 13.0"
          gem "rspec", "~> 3.12"
          gem "spectracer", path: "#{spectracer_root}"
        GEMFILE

        File.write(File.join(tmp_dir, ".spectracer.yml"), "existing: config")
      end

      it "does not overwrite existing config" do
        Bundler.with_unbundled_env do
          Dir.chdir(tmp_dir) do
            output = `bundle exec rake spectracer:install 2>&1`

            expect(output).to include("Spectracer is already installed")
            expect(File.read(".spectracer.yml")).to eq("existing: config")
          end
        end
      end
    end
  end
end
