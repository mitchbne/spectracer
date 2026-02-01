# Changelog

## [1.1.0] - 2026-02-01

### Added

- PathFilter class to exclude gem paths from dependency tracing
- Local pre-commit hook support: detect affected specs from uncommitted changes
- Automatic default branch detection from `origin/HEAD` with fallback to `main`/`master`
- E2E tests for full tracing flow, gem path filtering, and local usage scenarios
- CI pipeline annotation step to display collected dependency tree as pretty JSON

### Changed

- GitAdapter now supports both CI and local modes for changed file detection
- Changed files detection includes uncommitted changes (staged + unstaged) plus branch diff
- Improved gem path filtering using both `Gem.path` and `Bundler.bundle_path`

## [1.0.1] - 2026-01-31

### Fixed

- Renamed `spectacle.rake` to `spectracer.rake`
- Renamed `spectacle.default.yml` to `spectracer.default.yml`
- Fixed `WITH_SPECTACLE_DEBUG` references to `WITH_SPECTRACER_DEBUG`
- Fixed `bin/console` require statement
- Fixed `Gemfile` comment

## [1.0.0] - 2026-01-31

### Added

- Intelligent test selection based on git changes
- RSpec and Minitest integration via TracePoint
- Dependency tracing with gzip-compressed JSON storage
- Buildkite CI integration for parallel test optimization
- Git adapter for changed file detection
- Configurable via `.spectracer.yml`

### Changed

- Switch TracePoint from `:line` to `:call` events for dramatically improved performance
- Renamed gem from `spectacle` to `spectracer`
