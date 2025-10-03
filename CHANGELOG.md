# Changelog for Viscalyx.Assert

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-10-03

### Added

- Asserts ([issue #11](https://github.com/viscalyx/Viscalyx.Assert/issues/11)):
  - `Assert-ObjectProperty` (alias `Should-HaveProperty`) - Asserts that an
    object contains a specified property and optionally that the property has
    a specified value.
  - `Assert-ObjectMethod` (alias `Should-HaveMethod`) - Asserts that an object
    contains a specified method.

### Changed

- Bump action Stale to v10.
- Bump action Checkout to v5.

## [1.0.0] - 2025-02-04

### Added

- Asserts:
  - `Assert-BlockString` (alias `Should-BeBlockString`)

### Fixed

- Updated README.md
- `Assert-BlockString`
  - Allow it to pass string array and single string to `Expected` parameter.
  - Update to use `Out-Difference`.
  - Update comment-based help.
  - Added localization support.
  - Added parameter `NoHexOutput`.
- Updated module manifest GUID.
