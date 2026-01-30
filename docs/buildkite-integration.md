# Buildkite Integration Guide

Spectacle is designed to work seamlessly with Buildkite CI for parallel test optimization.

## Overview

The typical workflow involves three phases:

1. **Tracing** - Run full test suite with tracing enabled (periodic)
2. **Collection** - Combine trace artifacts into dependency map
3. **Selection** - Run only affected specs on feature branches

## Environment Variables

Spectacle automatically reads these Buildkite environment variables:

| Variable | Purpose |
|----------|---------|
| `BUILDKITE_BUILD_ID` | Unique identifier for the build (used in artifact paths) |
| `BUILDKITE_JOB_ID` | Unique identifier for the job (used in artifact paths) |
| `BUILDKITE_BRANCH` | Current branch name |
| `BUILDKITE_PIPELINE_DEFAULT_BRANCH` | Default branch (e.g., `main`) |

## Basic Pipeline

```yaml
steps:
  # Run on main branch with tracing
  - label: ":rspec: Full Suite"
    command: |
      bundle install
      WITH_SPECTACLE_TRACING=true bundle exec rspec
    branches: main
    artifact_paths:
      - "tmp/spectacle/**/*"
    key: "full-suite"

  # Collect dependencies after full suite
  - label: ":package: Collect Dependencies"
    command: |
      bundle install
      buildkite-agent artifact download "tmp/spectacle/**/*" .
      bundle exec rake spectacle:collect_dependencies
    branches: main
    depends_on: "full-suite"
    artifact_paths:
      - "tmp/spectacle/dependencies.json.gz"
    key: "collect-deps"

  # Run affected specs on feature branches
  - label: ":rspec: Affected Specs"
    command: |
      bundle install
      # Download latest dependencies from main
      buildkite-agent artifact download "tmp/spectacle/dependencies.json.gz" . --build "latest" --branch main || true
      SPECS=$(bundle exec rake spectacle:spec_determiner 2>/dev/null | tr -d "'")
      if [ -n "$SPECS" ]; then
        bundle exec rspec $SPECS
      else
        echo "No specs to run"
      fi
    branches: "!main"
```

## Parallel Testing Pipeline

For larger test suites, run tracing across parallel jobs:

```yaml
steps:
  # Parallel tracing jobs
  - label: ":rspec: Suite %n"
    command: |
      bundle install
      WITH_SPECTACLE_TRACING=true bundle exec rspec --format progress
    branches: main
    parallelism: 4
    artifact_paths:
      - "tmp/spectacle/**/*"
    key: "parallel-suite"

  # Collect from all parallel jobs
  - label: ":package: Collect Dependencies"
    command: |
      bundle install
      buildkite-agent artifact download "tmp/spectacle/**/*" .
      bundle exec rake spectacle:collect_dependencies
    branches: main
    depends_on: "parallel-suite"
    artifact_paths:
      - "tmp/spectacle/dependencies.json.gz"
```

## Scheduled Tracing

Run tracing periodically rather than on every main branch push:

```yaml
# Separate pipeline for nightly tracing
steps:
  - label: ":rspec: Nightly Trace"
    command: |
      bundle install
      WITH_SPECTACLE_TRACING=true bundle exec rspec
    artifact_paths:
      - "tmp/spectacle/**/*"
    key: "nightly-trace"

  - label: ":package: Update Dependencies"
    command: |
      bundle install
      buildkite-agent artifact download "tmp/spectacle/**/*" .
      bundle exec rake spectacle:collect_dependencies
      # Upload to a persistent location (S3, artifact storage, etc.)
      aws s3 cp tmp/spectacle/dependencies.json.gz s3://my-bucket/spectacle/
    depends_on: "nightly-trace"
```

Then in your main pipeline:

```yaml
steps:
  - label: ":rspec: Affected Specs"
    command: |
      bundle install
      # Download from persistent storage
      aws s3 cp s3://my-bucket/spectacle/dependencies.json.gz tmp/spectacle/ || true
      SPECS=$(bundle exec rake spectacle:spec_determiner 2>/dev/null | tr -d "'")
      bundle exec rspec $SPECS
```

## Artifact Paths

Spectacle uses these artifact paths by default:

| Path | Contents |
|------|----------|
| `tmp/spectacle/tracing_output/{build_id}/{job_id}.json.gz` | Per-job trace output |
| `tmp/spectacle/dependencies.json.gz` | Combined inverse dependencies |

Override with `SPECTACLE_TMP_DIRECTORY`:

```yaml
- command: |
    export SPECTACLE_TMP_DIRECTORY=".spectacle-output"
    WITH_SPECTACLE_TRACING=true bundle exec rspec
  artifact_paths:
    - ".spectacle-output/**/*"
```

## Debugging

Enable debug output to troubleshoot issues:

```yaml
- command: |
    WITH_SPECTACLE_DEBUG=true bundle exec rake spectacle:spec_determiner
```

This will output:

- Configuration being used
- Changed files detected
- Dependency lookups
- Glob pattern matching

## Error Handling

### No Dependencies File

If the dependencies file doesn't exist, Spectacle falls back to `on_empty_spec_set`:

```yaml
- command: |
    buildkite-agent artifact download "tmp/spectacle/dependencies.json.gz" . || echo "No deps file, running fallback"
    SPECS=$(bundle exec rake spectacle:spec_determiner 2>/dev/null | tr -d "'")
    bundle exec rspec ${SPECS:-spec/smoke/**/*_spec.rb}
```

### Empty Spec Set

Handle cases where no specs need to run:

```yaml
- command: |
    SPECS=$(bundle exec rake spectacle:spec_determiner 2>/dev/null | tr -d "'")
    if [ -z "$SPECS" ] || [ "$SPECS" = "''" ]; then
      echo "No specs affected by changes"
      exit 0
    fi
    bundle exec rspec $SPECS
```

## Performance Tips

1. **Cache dependencies** - Store `dependencies.json.gz` in persistent storage
2. **Run tracing nightly** - Don't trace on every push to main
3. **Use parallelism** - Tracing works across parallel jobs
4. **Prune old artifacts** - Clean up old trace files periodically
