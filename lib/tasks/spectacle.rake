namespace :spectacle do
  configuration_file_path = Spectacle::Configuration::FILE_PATH

  desc "Install Spectacle"
  task :install do
    if File.exist?(configuration_file_path)
      $stderr.puts "Spectacle is already installed."
      exit 0;
    end

    $stderr.puts "Creating '#{configuration_file_path}' file."
    # Prompt the user for the globs that they want to use to determine which spec files to run
    # and write them to the configuration file.
    default_file_path = File.join(Pathname.new(__dir__).join("..", "spectacle.default.yml"))
    deafult_spectacle_config = YAML.safe_load(File.read(default_file_path))

    File.open(configuration_file_path, "w") do |f|
      f.write deafult_spectacle_config
    end
  end

  desc "Collect spec dependencies"
  task :collect_dependencies do
    Spectacle::DependencyCollector.collect!
  end

  desc "Prints the list of specs that will be run to stdout"
  task :spec_determiner do
    $stdout.puts "'#{Spectacle::SpecRunDeterminer.determine!}'"
  end
end
