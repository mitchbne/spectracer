# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"
require "bundler"

RSpec.describe "Minitest Integration", :e2e do
  let(:fixture_path) { File.expand_path("fixtures/minitest_project", __dir__) }
  let(:spectracer_root) { File.expand_path("../..", __dir__) }
  let(:tmp_dir) { Dir.mktmpdir("spectracer-e2e-minitest") }

  before do
    FileUtils.cp_r("#{fixture_path}/.", tmp_dir)

    gemfile_content = <<~GEMFILE
      # frozen_string_literal: true

      source "https://rubygems.org"

      gem "minitest", "~> 5.20"
      gem "rake", "~> 13.0"
      gem "spectracer", path: "#{spectracer_root}"
    GEMFILE
    File.write(File.join(tmp_dir, "Gemfile"), gemfile_content)

    Bundler.with_unbundled_env do
      Dir.chdir(tmp_dir) do
        system("git init --quiet", exception: true)
        system("git config user.email 'test@test.com'", exception: true)
        system("git config user.name 'Test'", exception: true)
        system("bundle install --quiet", exception: true)
      end
    end
  end

  after do
    FileUtils.rm_rf(tmp_dir)
  end

  describe "dependency tracing" do
    it "generates dependency files when tracing is enabled" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          output = `WITH_SPECTRACER_TRACING=true SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rake test 2>&1`

          expect($?.success?).to be(true), "Minitest failed: #{output}"
          dependency_files = Dir.glob("#{tmp_dir}/tracing_output/**/*.json.gz")
          expect(dependency_files).not_to be_empty
        end
      end
    end

    it "does not generate dependency files when tracing is disabled" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          output = `bundle exec rake test 2>&1`

          expect($?.success?).to be(true), "Minitest failed: #{output}"
          dependency_files = Dir.glob("#{tmp_dir}/tracing_output/**/*.json.gz")
          expect(dependency_files).to be_empty
        end
      end
    end
  end

  describe "test execution" do
    it "runs all tests successfully" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          output = `bundle exec rake test 2>&1`
          expect($?.success?).to be true
          expect(output).to include("4 runs, 4 assertions, 0 failures")
        end
      end
    end
  end

  describe "rake tasks" do
    it "provides spectracer:install task" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          output = `bundle exec rake -T 2>&1`
          expect(output).to include("spectracer:install")
        end
      end
    end

    it "provides spectracer:collect_dependencies task" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          output = `bundle exec rake -T 2>&1`
          expect(output).to include("spectracer:collect_dependencies")
        end
      end
    end

    it "provides spectracer:spec_determiner task" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          output = `bundle exec rake -T 2>&1`
          expect(output).to include("spectracer:spec_determiner")
        end
      end
    end
  end
end
