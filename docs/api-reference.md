# API Reference

## Rake Tasks

### spectacle:install

Creates a default `.spectacle.yml` configuration file.

```bash
bundle exec rake spectacle:install
```

### spectacle:collect_dependencies

Combines individual trace files into a single inverse dependency map.

```bash
bundle exec rake spectacle:collect_dependencies
```

**Input:** `tmp/spectacle/tracing_output/{build_id}/*.json.gz`
**Output:** `tmp/spectacle/dependencies.json.gz`

### spectacle:spec_determiner

Outputs the spec files/patterns to run based on changed files.

```bash
SPECS=$(bundle exec rake spectacle:spec_determiner)
echo $SPECS  # => 'spec/models/user_spec.rb,spec/controllers/users_controller_spec.rb'
```

## Ruby API

### Spectacle Module

```ruby
# Get the shared logger
Spectacle.logger  # => Spectacle::Logger

# Get shared paths instance
Spectacle.paths   # => Spectacle::Core::Paths
```

### Spectacle::Core::Paths

Computes file paths based on environment.

```ruby
paths = Spectacle::Core::Paths.new(env: ENV)

paths.build_id                    # => "abc123" or "local"
paths.job_id                      # => "def456" or "local"
paths.output_directory            # => "tmp/spectacle"
paths.spec_artifact_output_file   # => "tmp/spectacle/tracing_output/abc123/def456.json.gz"
paths.spec_artifacts_download_glob # => "tmp/spectacle/tracing_output/abc123/*.json.gz"
paths.collected_dependencies_file  # => "tmp/spectacle/dependencies.json.gz"

# Path normalization
paths.normalize("/home/user/project/app/models/user.rb", repo_root: "/home/user/project")
# => "./app/models/user.rb"

paths.strip_dot_prefix("./app/models/user.rb")
# => "app/models/user.rb"
```

### Spectacle::Core::SpecSelector

Pure function for spec selection logic.

```ruby
selector = Spectacle::Core::SpecSelector.new

result = selector.call(
  changed_files: ["app/models/user.rb", "spec/models/post_spec.rb"],
  inverse_deps: {
    "./app/models/user.rb" => ["spec/models/user_spec.rb"]
  },
  globs: {
    "config/routes.rb" => "spec/routing/**/*_spec.rb"
  },
  on_empty: "spec/smoke/**/*_spec.rb"
)
# => "spec/models/post_spec.rb,spec/models/user_spec.rb"
```

### Spectacle::IO::GitAdapter

Wrapper for git operations.

```ruby
adapter = Spectacle::IO::GitAdapter.new(working_dir: Dir.pwd, logger: nil)

adapter.repository_root           # => "/home/user/project"
adapter.current_branch            # => "feature/new-thing"
adapter.commit_sha("HEAD")        # => "abc123def456..."
adapter.changed_files_in_commit("abc123")  # => ["app/models/user.rb"]
adapter.changed_files_against("main", cached: true)  # => ["lib/new.rb"]
```

### Spectacle::IO::DependencyStore

Handles gzipped JSON storage.

```ruby
store = Spectacle::IO::DependencyStore.new(logger: nil)

# Write data
store.write(
  {"spec/user_spec.rb" => ["app/models/user.rb"]},
  "deps.json.gz"
)

# Read data
data = store.read("deps.json.gz")
# => {"spec/user_spec.rb" => ["app/models/user.rb"]}

# Find files
files = store.glob("tmp/spectacle/**/*.json.gz")
# => ["tmp/spectacle/tracing_output/build1/job1.json.gz", ...]
```

### Spectacle::IO::ConfigLoader

Loads and parses configuration.

```ruby
loader = Spectacle::IO::ConfigLoader.new(logger: nil)

config = loader.load
# => {
#   on_empty_spec_set: "spec/**/*_spec.rb",
#   globs: {
#     "Gemfile" => "spec/**/*_spec.rb",
#     ...
#   }
# }
```

### Spectacle::Providers::GitChangedFiles

Detects changed files using git.

```ruby
provider = Spectacle::Providers::GitChangedFiles.new(
  git_adapter: Spectacle::IO::GitAdapter.new,
  env: ENV,
  logger: nil
)

files = provider.call
# => ["app/models/user.rb", "spec/models/user_spec.rb"]
```

### Spectacle::Providers::Repository

Provides repository information.

```ruby
repo = Spectacle::Providers::Repository.new(
  git_adapter: Spectacle::IO::GitAdapter.new
)

repo.root  # => "/home/user/project"
```

### Spectacle::Orchestrators::DependencyTracer

Traces spec dependencies during test execution.

```ruby
tracer = Spectacle::Orchestrators::DependencyTracer.new(
  paths: Spectacle::Core::Paths.new,
  store: Spectacle::IO::DependencyStore.new,
  repository: Spectacle::Providers::Repository.new,
  logger: nil
)

tracer.current_spec_file = "spec/models/user_spec.rb"
tracer.with_tracing do
  # Run test code here
end
tracer.write_output!
```

### Spectacle::Orchestrators::DependencyCollector

Collects and combines trace files.

```ruby
Spectacle::Orchestrators::DependencyCollector.collect!(logger: nil)
```

### Spectacle::Orchestrators::SpecRunDeterminer

Determines which specs to run.

```ruby
result = Spectacle::Orchestrators::SpecRunDeterminer.determine!(logger: nil)
# => "spec/models/user_spec.rb,spec/controllers/users_spec.rb"
```

### Spectacle::Logger

Configurable logger for debug output.

```ruby
logger = Spectacle::Logger.new(
  output: $stderr,
  level: :debug,  # :debug, :info, :warn, :error
  enabled: true
)

logger.debug("Debug message")
logger.info("Info message")
logger.warn("Warning message")
logger.error("Error message")
```

## Integrations

### RSpec

Automatically installed when Spectacle is required and `WITH_SPECTACLE_TRACING=true`:

```ruby
require "spectacle"
# RSpec hooks are automatically configured
```

Manual installation:

```ruby
Spectacle::Integrations::RSpec.install!
```

### Minitest

Automatically installed when Spectacle is required and `WITH_SPECTACLE_TRACING=true`:

```ruby
require "spectacle"
# Minitest hooks are automatically configured
```

Manual installation:

```ruby
Spectacle::Integrations::Minitest.install!
```

### Rails

Railtie automatically loads rake tasks when Rails is detected:

```ruby
# Gemfile
gem "spectacle"

# Rake tasks available automatically:
# rake spectacle:install
# rake spectacle:collect_dependencies
# rake spectacle:spec_determiner
```
