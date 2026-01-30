## [Unreleased]

## [0.3.0] - 2026-01-30

### Changed

- **BREAKING**: Switch TracePoint from `:line` to `:call` events for dramatically improved performance. This reduces tracing overhead by orders of magnitude, making it usable in production CI. Trade-off: slightly less granular tracking (method-level vs line-level).

## [0.1.0] - 2024-04-24

- Initial release
