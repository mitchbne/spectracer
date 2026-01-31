# Configuration Guide

## Configuration File

Spectracer uses a `.spectracer.yml` file in your project root for configuration.

### Generating Default Configuration

```bash
bundle exec rake spectracer:install
```

### Configuration Structure

```yaml
# Define reusable patterns
defaults:
  all_specs: "spec/**/*_spec.rb"
  model_specs: "spec/models/**/*_spec.rb"
  controller_specs: "spec/controllers/**/*_spec.rb"
  feature_specs: "spec/features/**/*_spec.rb"

# What to run when no specs are affected
on_empty_spec_set: "{{all_specs}}"

# Map file patterns to spec patterns
globs_matcher:
  "Gemfile": "{{all_specs}}"
  "Gemfile.lock": "{{all_specs}}"
  "db/schema.rb": "{{model_specs}}"
  "db/migrate/**/*": "{{model_specs}}"
  "config/routes.rb": "spec/routing/**/*_spec.rb"
  "config/locales/**/*": "{{feature_specs}}"
  "app/views/**/*": "spec/views/**/*_spec.rb,{{feature_specs}}"
```

## Configuration Options

### defaults

A hash of named patterns that can be referenced elsewhere using `{{name}}` syntax.

```yaml
defaults:
  all_specs: "spec/**/*_spec.rb"
  api_specs: "spec/requests/**/*_spec.rb"
```

### on_empty_spec_set

Pattern(s) to run when no specs are affected by the current changes. Useful for:

- Running smoke tests as a baseline
- Running the full suite when no specific specs match
- Running a subset of critical specs

```yaml
# Run all specs
on_empty_spec_set: "{{all_specs}}"

# Run only smoke tests
on_empty_spec_set: "spec/smoke/**/*_spec.rb"

# Run nothing (for CI pipelines that should skip when no changes)
on_empty_spec_set: ""
```

### globs_matcher

Maps file glob patterns to spec patterns. When a changed file matches a glob, the corresponding specs are added to the run.

```yaml
globs_matcher:
  # Single file to single pattern
  "Gemfile": "{{all_specs}}"
  
  # Wildcard patterns
  "db/migrate/**/*": "spec/models/**/*_spec.rb"
  
  # Multiple spec patterns (comma-separated)
  "app/views/**/*": "spec/views/**/*_spec.rb,spec/features/**/*_spec.rb"
  
  # Exact file match
  "config/routes.rb": "spec/routing/**/*_spec.rb"
```

## Template Syntax

Use `{{variable_name}}` to reference values from the `defaults` section:

```yaml
defaults:
  all: "spec/**/*_spec.rb"
  models: "spec/models/**/*_spec.rb"

globs_matcher:
  "Gemfile": "{{all}}"           # Expands to "spec/**/*_spec.rb"
  "db/schema.rb": "{{models}}"   # Expands to "spec/models/**/*_spec.rb"
```

## Common Patterns

### Rails Application

```yaml
defaults:
  all_specs: "spec/**/*_spec.rb"
  model_specs: "spec/models/**/*_spec.rb"
  controller_specs: "spec/controllers/**/*_spec.rb"
  request_specs: "spec/requests/**/*_spec.rb"
  feature_specs: "spec/features/**/*_spec.rb"
  view_specs: "spec/views/**/*_spec.rb"
  helper_specs: "spec/helpers/**/*_spec.rb"
  mailer_specs: "spec/mailers/**/*_spec.rb"
  job_specs: "spec/jobs/**/*_spec.rb"

on_empty_spec_set: "{{all_specs}}"

globs_matcher:
  # Dependency changes - run everything
  "Gemfile": "{{all_specs}}"
  "Gemfile.lock": "{{all_specs}}"
  
  # Database changes
  "db/schema.rb": "{{model_specs}}"
  "db/migrate/**/*": "{{model_specs}}"
  
  # Configuration changes
  "config/routes.rb": "spec/routing/**/*_spec.rb,{{request_specs}}"
  "config/locales/**/*": "{{feature_specs}}"
  "config/initializers/**/*": "{{all_specs}}"
  
  # View changes
  "app/views/**/*": "{{view_specs}},{{feature_specs}}"
  
  # Assets
  "app/assets/**/*": "{{feature_specs}}"
  "app/javascript/**/*": "{{feature_specs}}"
  
  # Shared code
  "lib/**/*": "spec/lib/**/*_spec.rb"
  "app/services/**/*": "spec/services/**/*_spec.rb"
```

### API-Only Application

```yaml
defaults:
  all_specs: "spec/**/*_spec.rb"
  request_specs: "spec/requests/**/*_spec.rb"
  model_specs: "spec/models/**/*_spec.rb"

on_empty_spec_set: "{{request_specs}}"

globs_matcher:
  "Gemfile": "{{all_specs}}"
  "Gemfile.lock": "{{all_specs}}"
  "db/schema.rb": "{{model_specs}}"
  "db/migrate/**/*": "{{model_specs}}"
  "config/routes.rb": "{{request_specs}}"
  "app/serializers/**/*": "{{request_specs}}"
```

### Monorepo with Engines

```yaml
defaults:
  all_specs: "spec/**/*_spec.rb"
  engine_specs: "engines/*/spec/**/*_spec.rb"

on_empty_spec_set: "spec/smoke/**/*_spec.rb"

globs_matcher:
  "Gemfile": "{{all_specs}},{{engine_specs}}"
  "engines/authentication/**/*": "engines/authentication/spec/**/*_spec.rb"
  "engines/billing/**/*": "engines/billing/spec/**/*_spec.rb"
  "engines/core/**/*": "{{all_specs}},{{engine_specs}}"
```

## Environment Variables

Configuration can be influenced by environment variables:

| Variable | Purpose |
|----------|---------|
| `SPECTRACER_TMP_DIRECTORY` | Override the output directory (default: `tmp/spectracer`) |
| `WITH_SPECTRACER_DEBUG` | Enable debug logging when set to `"true"` |

## Fallback Behavior

If no `.spectracer.yml` file exists, Spectracer uses a minimal default configuration:

```yaml
defaults:
  all_specs: "spec/**/*_spec.rb"

on_empty_spec_set: "{{all_specs}}"

globs_matcher: {}
```
