# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"
require "bundler"

RSpec.describe "RSpec Integration", :e2e do
  let(:fixture_path) { File.expand_path("fixtures/rspec_project", __dir__) }
  let(:spectracer_root) { File.expand_path("../..", __dir__) }
  let(:tmp_dir) { Dir.mktmpdir("spectracer-e2e-rspec") }

  before do
    FileUtils.cp_r("#{fixture_path}/.", tmp_dir)

    gemfile_content = <<~GEMFILE
      # frozen_string_literal: true

      source "https://rubygems.org"

      gem "rake", "~> 13.0"
      gem "rspec", "~> 3.12"
      gem "spectracer", path: "#{spectracer_root}"
    GEMFILE
    File.write(File.join(tmp_dir, "Gemfile"), gemfile_content)

    Bundler.with_unbundled_env do
      Dir.chdir(tmp_dir) do
        system("git init --quiet --initial-branch=main", exception: true)
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
          output = `WITH_SPECTRACER_TRACING=true SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rspec --format progress 2>&1`

          expect($?.success?).to be(true), "RSpec failed: #{output}"
          dependency_files = Dir.glob("#{tmp_dir}/tracing_output/**/*.json.gz")
          expect(dependency_files).not_to be_empty
        end
      end
    end

    it "does not generate dependency files when tracing is disabled" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          output = `bundle exec rspec --format progress 2>&1`

          expect($?.success?).to be(true), "RSpec failed: #{output}"
          dependency_files = Dir.glob("#{tmp_dir}/tracing_output/**/*.json.gz")
          expect(dependency_files).to be_empty
        end
      end
    end
  end

  describe "spec execution" do
    it "runs all specs successfully" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          output = `bundle exec rspec --format progress 2>&1`
          expect($?.success?).to be true
          expect(output).to include("3 examples, 0 failures")
        end
      end
    end
  end

  describe "gem path filtering" do
    it "excludes gem paths from traced dependencies" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          output = `WITH_SPECTRACER_TRACING=true SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rspec --format progress 2>&1`
          expect($?.success?).to be(true), "RSpec failed: #{output}"

          dependency_files = Dir.glob("#{tmp_dir}/tracing_output/**/*.json.gz")
          expect(dependency_files).not_to be_empty

          require "zlib"
          require "json"

          dependency_files.each do |file|
            content = Zlib::GzipReader.open(file) { |gz| JSON.parse(gz.read) }
            content.each do |_spec_file, deps|
              deps.each do |dep|
                expect(dep).not_to include("/gems/"), "Found gem path in dependencies: #{dep}"
              end
            end
          end
        end
      end
    end
  end

  describe "full tracing flow" do
    it "traces dependencies and collects inverse dependency map" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          trace_output = `WITH_SPECTRACER_TRACING=true SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rspec --format progress 2>&1`
          expect($?.success?).to be(true), "RSpec tracing failed: #{trace_output}"

          collect_output = `SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rake spectracer:collect_dependencies 2>&1`
          expect($?.success?).to be(true), "Collect dependencies failed: #{collect_output}"

          collected_file = File.join(tmp_dir, "dependencies.json.gz")
          expect(File.exist?(collected_file)).to be(true), "Collected dependencies file not found"

          require "zlib"
          require "json"

          inverse_deps = Zlib::GzipReader.open(collected_file) { |gz| JSON.parse(gz.read) }
          expect(inverse_deps).to be_a(Hash)
          expect(inverse_deps.keys).to include("lib/calculator.rb")
        end
      end
    end

    it "determines affected specs from uncommitted changes (local/pre-commit)" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          trace_output = `WITH_SPECTRACER_TRACING=true SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rspec --format progress 2>&1`
          expect($?.success?).to be(true), "RSpec tracing failed: #{trace_output}"

          collect_output = `SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rake spectracer:collect_dependencies 2>&1`
          expect($?.success?).to be(true), "Collect dependencies failed: #{collect_output}"

          system("git add -A && git commit -m 'Initial commit' --quiet", exception: true)

          File.write("lib/calculator.rb", <<~RUBY)
            # frozen_string_literal: true

            class Calculator
              def add(a, b)
                a + b + 0 # Modified but uncommitted!
              end

              def subtract(a, b)
                a - b
              end
            end
          RUBY

          # No BUILDKITE env vars = local mode
          determiner_output = `SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rake spectracer:spec_determiner 2>&1`
          expect($?.success?).to be(true), "Spec determiner failed: #{determiner_output}"

          expect(determiner_output).to include("calculator_spec.rb")
        end
      end
    end

    it "determines affected specs from committed changes on feature branch (local)" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          trace_output = `WITH_SPECTRACER_TRACING=true SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rspec --format progress 2>&1`
          expect($?.success?).to be(true), "RSpec tracing failed: #{trace_output}"

          collect_output = `SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rake spectracer:collect_dependencies 2>&1`
          expect($?.success?).to be(true), "Collect dependencies failed: #{collect_output}"

          system("git add -A && git commit -m 'Initial commit' --quiet", exception: true)
          system("git checkout -b feature-branch --quiet", exception: true)

          File.write("lib/greeter.rb", <<~RUBY)
            # frozen_string_literal: true

            class Greeter
              def greet(name)
                "Hello, \#{name}! Welcome!" # Modified on feature branch
              end
            end
          RUBY
          system("git add -A && git commit -m 'Modify greeter' --quiet", exception: true)

          # No BUILDKITE env vars = local mode, compares against main branch
          determiner_output = `SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rake spectracer:spec_determiner 2>&1`
          expect($?.success?).to be(true), "Spec determiner failed: #{determiner_output}"

          expect(determiner_output).to include("greeter_spec.rb")
          expect(determiner_output).not_to include("calculator_spec.rb")
        end
      end
    end

    it "determines affected specs from both committed and uncommitted changes (local)" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          trace_output = `WITH_SPECTRACER_TRACING=true SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rspec --format progress 2>&1`
          expect($?.success?).to be(true), "RSpec tracing failed: #{trace_output}"

          collect_output = `SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rake spectracer:collect_dependencies 2>&1`
          expect($?.success?).to be(true), "Collect dependencies failed: #{collect_output}"

          system("git add -A && git commit -m 'Initial commit' --quiet", exception: true)
          system("git checkout -b feature-branch --quiet", exception: true)

          File.write("lib/greeter.rb", <<~RUBY)
            # frozen_string_literal: true

            class Greeter
              def greet(name)
                "Hello, \#{name}! Welcome!" # Committed change on branch
              end
            end
          RUBY
          system("git add -A && git commit -m 'Modify greeter' --quiet", exception: true)

          File.write("lib/calculator.rb", <<~RUBY)
            # frozen_string_literal: true

            class Calculator
              def add(a, b)
                a + b + 0 # Uncommitted change
              end

              def subtract(a, b)
                a - b
              end
            end
          RUBY

          # No BUILDKITE env vars = local mode
          determiner_output = `SPECTRACER_TMP_DIRECTORY=#{tmp_dir} bundle exec rake spectracer:spec_determiner 2>&1`
          expect($?.success?).to be(true), "Spec determiner failed: #{determiner_output}"

          expect(determiner_output).to include("greeter_spec.rb")
          expect(determiner_output).to include("calculator_spec.rb")
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

    it "runs specs via rake spec" do
      Bundler.with_unbundled_env do
        Dir.chdir(tmp_dir) do
          output = `bundle exec rake spec 2>&1`
          expect($?.success?).to be true
          expect(output).to include("3 examples, 0 failures")
        end
      end
    end
  end
end
