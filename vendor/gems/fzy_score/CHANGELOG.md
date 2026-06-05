# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-05-28

### Added
- Initial release.
- `FzyScore.score(needle, haystack)` — relevance score (higher is better).
- `FzyScore.match(needle, haystack, positions:)` — score plus matched positions
  for highlighting, returned as a `FzyScore::Match`.
- `FzyScore.match?(needle, haystack)` — O(n) boolean pre-filter.
- `FzyScore.filter(needle, candidates, positions:, key:)` — rank a list,
  best-first, with stable tie-breaking and an optional key extractor.
- Faithful port of fzy's scoring constants from `config.def.h`.

[Unreleased]: https://github.com/tachyurgy/fzy_score/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/tachyurgy/fzy_score/releases/tag/v0.1.0
