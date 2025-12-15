# Changelog for Viscalyx.Assert

The format is based on and uses the types of changes according to [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `Assert-BitwiseFlag`
  - New command to assert that an integer value has does not have a specific
    bitwise flags set. Supports integers, enums, and array processing with
    `-Each` parameter. Alias: `Should-HaveFlag`.
  - Added `-All` parameter to require all array elements have the flag set (default
    behavior when used with `-Each`).
  - Added `-Any` parameter to require at least one array element has the flag set
    when used with `-Each`.
- `Assert-NotBitwiseFlag`
  - New command to assert that an integer value does not have specific bitwise
    flags set. Supports integers, enums, and array processing with `-Each`
    parameter. Alias: `Should-NotHaveFlag`.
  - Added `-All` parameter to require all array elements do not have the flag set
    (default behavior when used with `-Each`).
  - Added `-Any` parameter to require at least one array element does not have
    the flag set when used with `-Each`.
- Added private functions:
  - `Assert-BitwiseType` - Validates that a value is compatible with bitwise
    operations (integer or enum type).
  - `Get-ProcessedPipelineInput` - Processes pipeline input for assertion
    commands, handling single-element array unwrapping.
  - `Test-BitwiseCompatible` - Tests whether a value can be used in bitwise
    operations (integers and enums).
  - `Test-BitwiseFlagSet` - Tests if a value has specific bitwise flags set.

### Changed

- Bump action codeql-action/upload-sarif to v4
- Bump action checkout to v6

## [1.2.0] - 2025-10-04

### Added

- `Assert-ObjectProperty`
  - Added parameter `NoTypeCheck` to opt-in for lenient type checking, allowing
    PowerShell type coercion when comparing values.
- Added private functions:
  - `Get-TypeName` - Gets the full type name of a value as a string, or 'null'
    if the value is null.
  - `New-AssertionError` - Creates a Pester assertion error record with optional
    'because' reasoning to standardize error creation across assertion commands.
  - `Test-ObjectHasMethod` - Tests whether an object has a specified method,
    supporting various object types including PSCustomObjects and .NET objects.
  - `Test-ObjectHasProperty` - Tests whether an object has a specified property,
    supporting hashtables, PSCustomObjects, and .NET objects.
  - `Test-ObjectType` - Tests whether two values have the same type for strict
    type checking in assertion commands.
  - `Test-ValueEquality` - Tests whether two values are equal, supporting both
    scalar values and arrays with structural comparison.

### Changed

- `Assert-ObjectProperty`
  - Added parameter `Each` to opt-in for element-by-element checking when
    passing arrays via pipeline or parameter. Without this parameter, the
    command now checks properties on the array object itself (e.g., `Count`,
    `Length`).
  - Improved error messages to distinguish between type mismatches and value
    mismatches when strict type checking is enabled.
- `Assert-ObjectMethod`
  - Added parameter `Each` to opt-in for element-by-element checking when
    passing arrays via pipeline or parameter. Without this parameter, the
    command now checks methods on the array object itself.
- `Assert-BlockString`
  - Refactored to use the `New-AssertionError` private function for consistent
    error handling across all assertion commands.
- `New-AssertionError`
  - Updated to follow Pester's error message pattern by inserting the `Because`
    clause before `, but` in error messages (e.g., "Expected \<value\>, because
    \<reason\>, but got \<actual\>").
- Localized strings have been reorganized to consolidate common reusable words
  (like "because", "actual", and "expected") into a dedicated "Common localized
  strings" section with a consistent `Common_Word*` naming pattern, reducing
  duplication across command-specific string keys.

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
