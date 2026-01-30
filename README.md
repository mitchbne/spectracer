# Spectacle

> spectacle (noun): something exhibited to view as unusual, notable, or entertaining

Spectacle is a Ruby gem that intelligently determines which specs to run based on the files you've changed. By tracing dependencies during test execution, Spectacle builds a map of which source files are used by which specs, then uses this data to run only the relevant tests.

## Features

- **Dependency tracing** - Automatically tracks which files each spec depends on
- **Smart test selection** - Only runs specs affected by your changes
- **CI integration** - Built for Buildkite with parallel job support
- **Framework support** - Works with both RSpec and Minitest
- **Rails compatible** - Includes Railtie for automatic setup

## Installation

Add Spectacle to your Gemfile:

```ruby
group :development, :test do
  gem "spectacle", github: "mitchbne/spectacle", branch: "main"
end
```

Then run:

```bash
bundle install
bundle exec rake spectacle:install
```

This creates a `.spectacle.yml` configuration file in your project root.

## How It Works

Spectacle operates in three phases:

### 1. Tracing Phase

Run your full test suite with tracing enabled:

```bash
WITH_SPECTACLE_TRACING=true bundle exec rspec
```

This uses Ruby's TracePoint to record which files each spec touches, outputting a gzipped JSON file mapping specs to their dependencies.

### 2. Collection Phase

After running specs across parallel jobs, collect all tracing artifacts:

```bash
bundle exec rake spectacle:collect_dependencies
```

This combines individual trace files into a single inverse dependency map: for each source file, which specs depend on it.

### 3. Selection Phase

When running tests on a branch, determine which specs to run:

```bash
SPECS=$(bundle exec rake spectacle:spec_determiner)
bundle exec rspec $SPECS
```

## Configuration

Create a `.spectacle.yml` file in your project root:

```yaml
defaults:
  all_specs: "spec/**/*_spec.rb"
  no_specs: ""

on_empty_spec_set: "{{all_specs}}"

globs_matcher:
  "Gemfile": "{{all_specs}}"
  "Gemfile.lock": "{{all_specs}}"
  "db/schema.rb": "spec/models/**/*_spec.rb"
  "config/routes.rb": "spec/routing/**/*_spec.rb"
  "app/views/**/*": "spec/views/**/*_spec.rb,spec/features/**/*_spec.rb"
```

### Configuration Options

| Option | Description |
|--------|-------------|
| `defaults` | Named patterns that can be referenced in other options |
| `on_empty_spec_set` | Pattern to run when no specs are affected by changes |
| `globs_matcher` | Map of file globs to spec patterns to run when matched |

## Buildkite Integration

Example `pipeline.yml`:

```yaml
steps:
  # Step 1: Run full suite with tracing (weekly/nightly)
  - label: ":rspec: Full Suite with Tracing"
    command: |
      WITH_SPECTACLE_TRACING=true bundle exec rspec --format progress
    artifact_paths:
      - "tmp/spectacle/**/*"
    branches: main

  # Step 2: Collect dependencies
  - label: ":package: Collect Dependencies"
    command: |
      buildkite-agent artifact download "tmp/spectacle/**/*" .
      bundle exec rake spectacle:collect_dependencies
    artifact_paths:
      - "tmp/spectacle/dependencies.json.gz"
    depends_on: "full-suite"

  # Step 3: Run affected specs on feature branches
  - label: ":rspec: Affected Specs"
    command: |
      buildkite-agent artifact download "tmp/spectacle/dependencies.json.gz" .
      SPECS=$(bundle exec rake spectacle:spec_determiner)
      bundle exec rspec $SPECS
    branches: "!main"
```

## RSpec Integration

Spectacle automatically configures RSpec when required. No additional setup needed:

```ruby
# Gemfile
gem "spectacle"

# That's it! Tracing is enabled via WITH_SPECTACLE_TRACING=true
```

## Minitest Integration

Spectacle also supports Minitest:

```ruby
# test/test_helper.rb
require "spectacle"

# Tracing is automatically enabled when WITH_SPECTACLE_TRACING=true
```

## Debug Mode

Enable debug logging to see what Spectacle is doing:

```bash
WITH_SPECTACLE_DEBUG=true bundle exec rake spectacle:spec_determiner
```

## Development

After checking out the repo:

```bash
bin/setup                    # Install dependencies
bundle exec rake             # Run tests + linting
bundle exec rspec            # Run tests only
bundle exec standardrb       # Run linting only
```

## Architecture

See [docs/architecture.md](docs/architecture.md) for detailed architecture documentation.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mitchbne/spectacle.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
