namespace :spectacle do
  desc "Install Spectacle"
  task :install do
    puts "Installing Spectacle..."
    # Add your installation logic here
    # We want to create a file called '.spectacle.yml' in the root of the repository.
    # This file will contain the configuration for Spectacle.
    # We want to ask the user for the globs that they want to use to determine which spec files to run
    # to help them create the '.spectacle.yml' file.
    #
    # The file should look like bin/schema.json
    #
    if File.exist?(".spectacle.yml")
      puts "Spectacle is already installed."
      exit 0;
    end

    # Prompt the user for the globs that they want to use to determine which spec files to run
    # and write them to the '.spectacle.yml' file.

    File.open(".spectacle.yml", "w") do |f|
      f.write <<~YAML
        pattern_templates:
          all_specs: "spec/**/*_spec.rb"
          no_specs: "{}"

        on_empty_spec_set: "{{no_specs}}"

        config:
          "Gemfile": "{{all_specs}}"
          "Gemfile.lock": "{{all_specs}}"
          "config/**": "{{all_specs}}"
      YAML
    end
  end

  desc "Collect spec dependencies"
  task :collect_dependencies do
    Spectacle::DependencyCollector.collect!
  end

  desc "Prints the list of specs that will be run to stdout"
  task :spec_determiner do
    puts "'#{Spectacle::SpecRunDeterminer.determine!}'"
  end
end
