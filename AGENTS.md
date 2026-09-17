# Swift ProcessRunner

A one-file, dependency-free runner for external tools: launch, drain both pipes concurrently, return status + stdout + stderr.

- Module `ProcessRunner` in `Sources/ProcessRunner`; tests in `Tests`; `swift test` is the whole check.
- Swift 6 language mode, tools 6.2, macOS 14+, no dependencies unless the README says so.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.

## Module map

- `ProcessRunner.swift` — (flat package)

## Rules

Read `CONTRIBUTING.md` before changing anything: it is the layout and PR rulebook for this package.

- **Auditing? Read `AUDIT.md` first** — what the last full audit checked and fixed, and the known non-issues to skip; extend it, do not redo it.
