# frozen_string_literal: true

namespace :spectacle do
  desc "Install Spectacle configuration file"
  task :install do
    config_path = Spectacle::IO::ConfigLoader::FILE_PATH

    if File.exist?(config_path)
      warn "Spectacle is already installed."
      exit 0
    end

    warn "Creating '#{config_path}' file."

    default_content = File.read(Spectacle::IO::ConfigLoader::DEFAULT_FILE_PATH)
    File.write(config_path, default_content)
  end

  desc "Collect spec dependencies from tracing artifacts"
  task :collect_dependencies do
    logger = Spectacle::Logger.new(
      enabled: ENV["WITH_SPECTACLE_DEBUG"] == "true",
      level: :debug
    )
    Spectacle::Orchestrators::DependencyCollector.collect!(logger: logger)
  end

  desc "Print the list of specs to run based on changed files"
  task :spec_determiner do
    logger = Spectacle::Logger.new(
      enabled: ENV["WITH_SPECTACLE_DEBUG"] == "true",
      level: :debug
    )
    result = Spectacle::Orchestrators::SpecRunDeterminer.determine!(logger: logger)
    $stdout.puts "'#{result}'"
  end
end
