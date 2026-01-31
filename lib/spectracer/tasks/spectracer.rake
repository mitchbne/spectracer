# frozen_string_literal: true

namespace :spectracer do
  desc "Install Spectracer configuration file"
  task :install do
    config_path = Spectracer::IO::ConfigLoader::FILE_PATH

    if File.exist?(config_path)
      warn "Spectracer is already installed."
      exit 0
    end

    warn "Creating '#{config_path}' file."

    default_content = File.read(Spectracer::IO::ConfigLoader::DEFAULT_FILE_PATH)
    File.write(config_path, default_content)
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
