# frozen_string_literal: true

namespace :spectracer do
  desc "Install Spectracer configuration file"
  task :install do
    config_path = Spectracer::IO::ConfigLoader::FILE_PATH

    if File.exist?(config_path)
      warn "Spectracer is already installed."
      exit 0
    end

    framework = detect_test_framework
    default_file_path = case framework
    when :minitest
      Spectracer::IO::ConfigLoader::DEFAULT_MINITEST_FILE_PATH
    else
      Spectracer::IO::ConfigLoader::DEFAULT_RSPEC_FILE_PATH
    end

    warn "Detected test framework: #{framework}"
    warn "Creating '#{config_path}' file."

    default_content = File.read(default_file_path)
    File.write(config_path, default_content)
  end

  def detect_test_framework
    gemfile_path = File.join(Dir.pwd, "Gemfile")
    return :rspec unless File.exist?(gemfile_path)

    gemfile_content = File.read(gemfile_path)

    has_rspec = gemfile_content.match?(/['"]rspec['"]|['"]rspec-rails['"]/)
    has_minitest = gemfile_content.match?(/['"]minitest['"]/) || Dir.exist?("test")

    if has_rspec
      :rspec
    elsif has_minitest
      :minitest
    else
      :rspec
    end
  end

  desc "Collect spec dependencies from tracing artifacts"
  task :collect_dependencies do
    logger = Spectracer::Logger.new(
      enabled: ENV["WITH_SPECTRACER_DEBUG"] == "true",
      level: :debug
    )
    Spectracer::Orchestrators::DependencyCollector.collect!(logger: logger)
  end

  desc "Print the list of specs to run based on changed files"
  task :spec_determiner do
    logger = Spectracer::Logger.new(
      enabled: ENV["WITH_SPECTRACER_DEBUG"] == "true",
      level: :debug
    )
    result = Spectracer::Orchestrators::SpecRunDeterminer.determine!(logger: logger)
    $stdout.puts "'#{result}'"
  end
end
