# Spectracer Architecture

## Overview

Spectracer follows a clean architecture pattern with clear separation between:

- **Core** - Pure business logic with no I/O
- **I/O** - Adapters for external systems (filesystem, git, config)
- **Providers** - Data providers that combine I/O adapters
- **Orchestrators** - High-level coordinators that combine providers and core logic
- **Integrations** - Framework-specific hooks (RSpec, Minitest, Rails)

## Directory Structure

```
lib/spectracer/
├── core/                    # Pure business logic
│   ├── paths.rb             # Path computation
│   └── spec_selector.rb     # Spec selection algorithm
├── io/                      # I/O adapters
│   ├── command_runner.rb    # Shell commands
│   ├── config_loader.rb     # YAML configuration
│   ├── dependency_store.rb  # Gzip JSON storage
│   └── git_adapter.rb       # Git operations
├── providers/               # Data providers
│   ├── git_changed_files.rb # Changed file detection
│   └── repository.rb        # Repository info
├── orchestrators/           # Coordination
│   ├── dependency_collector.rb
│   ├── dependency_tracer.rb
│   └── spec_run_determiner.rb
├── integrations/            # Framework hooks
│   ├── minitest.rb
│   ├── railtie.rb
│   └── rspec.rb
├── tasks/
│   └── spectracer.rake
├── logger.rb
└── version.rb
```

## Component Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Orchestrators                             │
│  ┌─────────────────┐ ┌──────────────────┐ ┌──────────────────┐  │
│  │DependencyTracer │ │DependencyCollector│ │SpecRunDeterminer│  │
│  └────────┬────────┘ └────────┬─────────┘ └────────┬─────────┘  │
└───────────┼───────────────────┼────────────────────┼────────────┘
            │                   │                    │
            ▼                   ▼                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                         Providers                                │
│  ┌─────────────────────┐         ┌─────────────────────────┐    │
│  │    Repository       │         │   GitChangedFiles       │    │
│  └──────────┬──────────┘         └───────────┬─────────────┘    │
└─────────────┼────────────────────────────────┼──────────────────┘
              │                                │
              ▼                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                         I/O Adapters                             │
│  ┌────────────┐ ┌──────────────┐ ┌────────────┐ ┌────────────┐  │
│  │ GitAdapter │ │DependencyStore│ │ConfigLoader│ │CommandRunner│ │
│  └────────────┘ └──────────────┘ └────────────┘ └────────────┘  │
└─────────────────────────────────────────────────────────────────┘
              │                                │
              ▼                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Core                                    │
│  ┌─────────────────────┐         ┌─────────────────────────┐    │
│  │       Paths         │         │     SpecSelector        │    │
│  └─────────────────────┘         └─────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

## Core Components

### Paths (`core/paths.rb`)

Computes file paths based on environment variables. No I/O operations.

```ruby
paths = Spectracer::Core::Paths.new(env: ENV)
paths.spec_artifact_output_file  # => "tmp/spectracer/tracing_output/build123/job456.json.gz"
paths.collected_dependencies_file # => "tmp/spectracer/dependencies.json.gz"
```

### SpecSelector (`core/spec_selector.rb`)

Pure function that determines which specs to run. Takes data in, returns spec patterns out.

```ruby
selector = Spectracer::Core::SpecSelector.new
result = selector.call(
  changed_files: ["app/models/user.rb"],
  inverse_deps: {"./app/models/user.rb" => ["spec/models/user_spec.rb"]},
  globs: {"config/routes.rb" => "spec/routing/**/*_spec.rb"},
  on_empty: "spec/smoke/**/*_spec.rb"
)
# => "spec/models/user_spec.rb"
```

## I/O Adapters

### GitAdapter (`io/git_adapter.rb`)

Wraps the `ruby-git` gem for all git operations:

```ruby
adapter = Spectracer::IO::GitAdapter.new
adapter.repository_root        # => "/home/user/project"
adapter.current_branch         # => "feature/new-thing"
adapter.commit_sha("HEAD")     # => "abc123..."
adapter.changed_files_in_commit("abc123")
adapter.changed_files_against("main", cached: true)
```

### DependencyStore (`io/dependency_store.rb`)

Handles reading/writing gzipped JSON files:

```ruby
store = Spectracer::IO::DependencyStore.new
store.write({"spec/user_spec.rb" => ["app/models/user.rb"]}, "deps.json.gz")
data = store.read("deps.json.gz")
```

### ConfigLoader (`io/config_loader.rb`)

Loads and parses `.spectracer.yml` configuration:

```ruby
loader = Spectracer::IO::ConfigLoader.new
config = loader.load
# => {on_empty_spec_set: "spec/**/*_spec.rb", globs: {...}}
```

## Orchestrators

### DependencyTracer

Wraps test execution with TracePoint to record file dependencies:

```ruby
tracer = Spectracer::Orchestrators::DependencyTracer.new
tracer.current_spec_file = "spec/models/user_spec.rb"
tracer.with_tracing { run_test }
tracer.write_output!  # Writes to tmp/spectracer/tracing_output/...
```

### DependencyCollector

Combines individual trace files into inverse dependency map:

```ruby
Spectracer::Orchestrators::DependencyCollector.collect!
# Reads: tmp/spectracer/tracing_output/build123/*.json.gz
# Writes: tmp/spectracer/dependencies.json.gz
```

### SpecRunDeterminer

Coordinates all components to determine specs to run:

```ruby
result = Spectracer::Orchestrators::SpecRunDeterminer.determine!
# => "spec/models/user_spec.rb,spec/controllers/users_controller_spec.rb"
```

## Data Flow

### Tracing Phase

```
RSpec/Minitest Test Run
         │
         ▼
┌─────────────────────┐
│  DependencyTracer   │ ──── TracePoint records file access
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  DependencyStore    │ ──── Writes gzipped JSON
└──────────┬──────────┘
           │
           ▼
   tmp/spectracer/tracing_output/{build_id}/{job_id}.json.gz
```

### Collection Phase

```
   tmp/spectracer/tracing_output/{build_id}/*.json.gz
           │
           ▼
┌─────────────────────┐
│ DependencyCollector │ ──── Combines & inverts dependencies
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  DependencyStore    │ ──── Writes combined file
└──────────┬──────────┘
           │
           ▼
   tmp/spectracer/dependencies.json.gz
```

### Selection Phase

```
   tmp/spectracer/dependencies.json.gz
           │
           ▼
┌─────────────────────┐      ┌─────────────────────┐
│  DependencyStore    │      │   ConfigLoader      │
└──────────┬──────────┘      └──────────┬──────────┘
           │                            │
           ▼                            ▼
┌─────────────────────┐      ┌─────────────────────┐
│ GitChangedFiles     │      │       Config        │
└──────────┬──────────┘      └──────────┬──────────┘
           │                            │
           └──────────┬─────────────────┘
                      │
                      ▼
           ┌─────────────────────┐
           │    SpecSelector     │ ──── Pure logic
           └──────────┬──────────┘
                      │
                      ▼
             "spec/models/user_spec.rb"
```

## Dependency Injection

All classes accept their dependencies via constructor arguments with sensible defaults:

```ruby
class SpecRunDeterminer
  def initialize(
    paths: Spectracer::Core::Paths.new,
    store: Spectracer::IO::DependencyStore.new,
    config_loader: Spectracer::IO::ConfigLoader.new,
    changed_files_provider: Spectracer::Providers::GitChangedFiles.new,
    selector: Spectracer::Core::SpecSelector.new,
    logger: nil
  )
    # ...
  end
end
```

This allows easy testing with mocks:

```ruby
determiner = SpecRunDeterminer.new(
  store: fake_store,
  changed_files_provider: fake_git
)
```

## Testing Strategy

| Layer | Testing Approach |
|-------|------------------|
| Core | Pure unit tests with plain data |
| I/O | Integration tests with real files/git |
| Providers | Unit tests with mocked I/O adapters |
| Orchestrators | Unit tests with mocked providers |
| Integrations | Behavior tests with test framework |
