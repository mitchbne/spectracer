# Changelog

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
