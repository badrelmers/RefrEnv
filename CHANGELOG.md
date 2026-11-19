# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.4] - 2026-11-19

### Fixed

- **Powershell: `PSModulePath` refresh losing engine default module paths**
  ([#9](https://github.com/badrelmers/RefrEnv/issues/9)),
  fixed by [@soredake](https://github.com/soredake)
  ([#11](https://github.com/badrelmers/RefrEnv/pull/11)).
  Powershell builds the process `PSModulePath` at startup by appending its
  default module paths (which are not stored in the registry) to the inherited
  value. The refresh loop overwrote it with the raw registry value, losing all
  engine-added paths and breaking module autoloading. `PSModulePath` is now
  excluded from the refresh loop and merged instead: the process value is kept
  and registry (machine/user) entries that are not already present are
  appended, so newly installed module paths still propagate.

### Changed

- Standardized the usage documentation of all four scripts (`refrenv.bat`,
  `refrenv.ps1`, `refrenv.sh`, `refrenvz.sh`) into a common
  NAME / SYNOPSIS / DESCRIPTION layout describing the
  `RefrEnv_ResetPath`, `RefrEnv_debug`, `RefrEnv_StrictRefresh` and
  `PSModulePath` behaviours (PR [#7](https://github.com/badrelmers/RefrEnv/pull/7)).
- Renamed the CMD debug flag from `debugme` to `RefrEnv_debug` for
  consistency with the other scripts.
- Expanded the README with detailed CMD/Bash/Zsh/Powershell usage sections and
  examples.
- Normalized the line endings of `refrenv.bat` and `refrenv.ps1` in the
  repository (b5191d7), by [@badrelmers](https://github.com/badrelmers).

### Project

- Version bumped to 1.4 across all scripts; added this CHANGELOG.
- Script headers updated: `# author: Badr Elmers 2021-2026`.

## [1.3] - 2023-06-02

### Changed

- Global revision of all the scripts.
- Bash version refreshes only standard bash variable keys (a safe list of
  bash/zsh special and shell-local variables is excluded from refreshing).

## [1.2] - 2023-05-31

### Added

- `refrenvz.sh`: RefrEnv for the Z shell (`zsh` of Cygwin/Msys2/GitBash).

## [1.0] - 2022-02-19

### Added

- Initial public release: `refrenv.bat` (CMD), `refrenv.sh` (Bash of
  Cygwin/Msys2/GitBash), `refrenv.ps1` (Powershell/Pwsh) plus
  `refrenv_test.sh`.
- `RefrEnv_ResetPath=yes` option to reset the actual PATH before refreshing it.
