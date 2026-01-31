# Spectracer - Agent Instructions

## Overview

Spectracer is a Ruby gem that traces RSpec/Minitest dependencies and determines which specs to run based on git changes. It integrates with Buildkite CI for parallel test optimization.

## Commands

### Testing
```bash
bundle exec rspec                    # Run all tests
bundle exec rspec spec/core/         # Run specific directory
```

### Linting
```bash
bundle exec standardrb               # Check style
bundle exec standardrb --fix         # Auto-fix issues
```

### Full CI Check
```bash
bundle exec rake                     # Runs spec + standardrb
```

### Build Gem
```bash
bundle exec rake build               # Build .gem file
bundle exec rake install             # Install locally
```

## Architecture

```
lib/spectracer/
├── core/                    # Pure business logic (no I/O)
│   ├── paths.rb             # Path computation from env
│   └── spec_selector.rb     # Spec selection algorithm
├── io/                      # I/O adapters (mockable)
│   ├── command_runner.rb    # Shell command wrapper
│   ├── config_loader.rb     # YAML config loading
│   ├── dependency_store.rb  # Gzip JSON read/write
│   └── git_adapter.rb       # Git gem wrapper
├── providers/               # Data providers
│   ├── git_changed_files.rb # Changed file detection
│   └── repository.rb        # Repo root detection
├── orchestrators/           # Coordinate components
│   ├── dependency_collector.rb
│   ├── dependency_tracer.rb
│   └── spec_run_determiner.rb
├── integrations/            # Test framework hooks
│   ├── minitest.rb
│   ├── railtie.rb
│   └── rspec.rb
├── tasks/
│   └── spectracer.rake
├── logger.rb
└── version.rb
```

## Code Conventions

- All classes use dependency injection for testability
- Core classes are pure functions (no side effects)
- I/O classes wrap external dependencies and are mockable
- Use `frozen_string_literal: true` in all files
- Follow StandardRB style (double quotes, no trailing commas)
- RBS type signatures in `sig/spectracer.rbs`

## Key Design Decisions

1. **No ENV at require-time**: All environment variables read at runtime via injected `env` parameter
2. **Dependency injection**: All collaborators passed via `initialize` with sensible defaults
3. **Pure core logic**: `SpecSelector` has no I/O, fully testable with plain data
4. **Git gem over shelling out**: Uses `ruby-git` gem for git operations

## Testing Patterns

- Unit tests mock collaborators using `instance_double`
- Integration tests use real git operations
- Test files mirror source structure: `lib/spectracer/core/paths.rb` → `spec/core/paths_spec.rb`

## Environment Variables

| Variable | Purpose |
|----------|---------|
| `WITH_SPECTRACER_TRACING` | Enable dependency tracing (`"true"`) |
| `WITH_SPECTRACER_DEBUG` | Enable debug logging (`"true"`) |
| `SPECTRACER_TMP_DIRECTORY` | Override output directory |
| `BUILDKITE_BUILD_ID` | Buildkite build identifier |
| `BUILDKITE_JOB_ID` | Buildkite job identifier |
| `BUILDKITE_BRANCH` | Current branch name |
| `BUILDKITE_PIPELINE_DEFAULT_BRANCH` | Default branch (e.g., `main`) |
