# API Reference

## Rake Tasks

### spectracer:install

Creates a default `.spectracer.yml` configuration file.

```bash
bundle exec rake spectracer:install
```

### spectracer:collect_dependencies

Combines individual trace files into a single inverse dependency map.

```bash
bundle exec rake spectracer:collect_dependencies
```

**Input:** `tmp/spectracer/tracing_output/{build_id}/*.json.gz`
**Output:** `tmp/spectracer/dependencies.json.gz`

### spectracer:spec_determiner

Outputs the spec files/patterns to run based on changed files.

```bash
SPECS=$(bundle exec rake spectracer:spec_determiner)
echo $SPECS  # => 'spec/models/user_spec.rb,spec/controllers/users_controller_spec.rb'
```

## Ruby API

### Spectracer Module

```ruby
# Get the shared logger
Spectracer.logger  # => Spectracer::Logger

# Get shared paths instance
Spectracer.paths   # => Spectracer::Core::Paths
```

### Spectracer::Core::Paths

Computes file paths based on environment.

```ruby
paths = Spectracer::Core::Paths.new(env: ENV)

paths.build_id                    # => "abc123" or "local"
paths.job_id                      # => "def456" or "local"
paths.output_directory            # => "tmp/spectracer"
paths.spec_artifact_output_file   # => "tmp/spectracer/tracing_output/abc123/def456.json.gz"
paths.spec_artifacts_download_glob # => "tmp/spectracer/tracing_output/abc123/*.json.gz"
paths.collected_dependencies_file  # => "tmp/spectracer/dependencies.json.gz"

# Path normalization
paths.normalize("/home/user/project/app/models/user.rb", repo_root: "/home/user/project")
# => "./app/models/user.rb"

paths.strip_dot_prefix("./app/models/user.rb")
# => "app/models/user.rb"
```

### Spectracer::Core::SpecSelector

Pure function for spec selection logic.

```ruby
selector = Spectracer::Core::SpecSelector.new

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

### Spectracer::IO::GitAdapter

Wrapper for git operations.

```ruby
adapter = Spectracer::IO::GitAdapter.new(working_dir: Dir.pwd, logger: nil)

adapter.repository_root           # => "/home/user/project"
adapter.current_branch            # => "feature/new-thing"
adapter.commit_sha("HEAD")        # => "abc123def456..."
adapter.changed_files_in_commit("abc123")  # => ["app/models/user.rb"]
adapter.changed_files_against("main", cached: true)  # => ["lib/new.rb"]
```

### Spectracer::IO::DependencyStore

Handles gzipped JSON storage.

```ruby
store = Spectracer::IO::DependencyStore.new(logger: nil)

# Write data
store.write(
  {"spec/user_spec.rb" => ["app/models/user.rb"]},
  "deps.json.gz"
)

# Read data
data = store.read("deps.json.gz")
# => {"spec/user_spec.rb" => ["app/models/user.rb"]}

# Find files
files = store.glob("tmp/spectracer/**/*.json.gz")
# => ["tmp/spectracer/tracing_output/build1/job1.json.gz", ...]
```

### Spectracer::IO::ConfigLoader

Loads and parses configuration.

```ruby
loader = Spectracer::IO::ConfigLoader.new(logger: nil)

config = loader.load
# => {
#   on_empty_spec_set: "spec/**/*_spec.rb",
#   globs: {
#     "Gemfile" => "spec/**/*_spec.rb",
#     ...
#   }
# }
```

### Spectracer::Providers::GitChangedFiles

Detects changed files using git.

```ruby
provider = Spectracer::Providers::GitChangedFiles.new(
  git_adapter: Spectracer::IO::GitAdapter.new,
  env: ENV,
  logger: nil
)

files = provider.call
# => ["app/models/user.rb", "spec/models/user_spec.rb"]
```

### Spectracer::Providers::Repository

Provides repository information.

```ruby
repo = Spectracer::Providers::Repository.new(
  git_adapter: Spectracer::IO::GitAdapter.new
)

repo.root  # => "/home/user/project"
```

### Spectracer::Orchestrators::DependencyTracer

Traces spec dependencies during test execution.

```ruby
tracer = Spectracer::Orchestrators::DependencyTracer.new(
  paths: Spectracer::Core::Paths.new,
  store: Spectracer::IO::DependencyStore.new,
  repository: Spectracer::Providers::Repository.new,
  logger: nil
)

tracer.current_spec_file = "spec/models/user_spec.rb"
tracer.with_tracing do
  # Run test code here
end
tracer.write_output!
```

### Spectracer::Orchestrators::DependencyCollector

Collects and combines trace files.

```ruby
Spectracer::Orchestrators::DependencyCollector.collect!(logger: nil)
```

### Spectracer::Orchestrators::SpecRunDeterminer

Determines which specs to run.

```ruby
result = Spectracer::Orchestrators::SpecRunDeterminer.determine!(logger: nil)
# => "spec/models/user_spec.rb,spec/controllers/users_spec.rb"
```

### Spectracer::Logger

Configurable logger for debug output.

```ruby
logger = Spectracer::Logger.new(
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

Automatically installed when Spectracer is required and `WITH_SPECTRACER_TRACING=true`:

```ruby
require "spectracer"
# RSpec hooks are automatically configured
```

Manual installation:

```ruby
Spectracer::Integrations::RSpec.install!
```

### Minitest

Automatically installed when Spectracer is required and `WITH_SPECTRACER_TRACING=true`:

```ruby
require "spectracer"
# Minitest hooks are automatically configured
```

Manual installation:

```ruby
Spectracer::Integrations::Minitest.install!
```

### Rails

Railtie automatically loads rake tasks when Rails is detected:

```ruby
# Gemfile
gem "spectracer"

# Rake tasks available automatically:
# rake spectracer:install
# rake spectracer:collect_dependencies
# rake spectracer:spec_determiner
```
