# Swift Foundation Extensions

The small Foundation helpers every package in the Sidewatch family would otherwise copy, and the one way the family runs an external tool.

- Modules `FoundationExtensions`, `ProcessRunner`, each in `Sources/<Module>` with tests in `Tests/<Module>Tests`; `swift test` is the whole check.
- Swift 6 language mode, tools 6.2, macOS 14+.
- Part of the Sidewatch package family; every package follows the same layout and PR rules.
- Each module's user-facing documentation is `Docs/Modules/<Module>.md`; its last audit is `Docs/Audits/<Module>.md` — read it before auditing, and extend it rather than redo it.

## FoundationExtensions — `Sources/FoundationExtensions`

### Module map
- Every helper, one line each, is the table in `Docs/Modules/FoundationExtensions.md`. Recent: `Extensions/String+PathContainment` (path-in-folder by whole components), `Extensions/URL+ContentStamp` (one `stat`, links followed, nanosecond mtime), `Support/StampedCache` (a bounded memo invalidated by the stamp)


## ProcessRunner — `Sources/ProcessRunner`

### Module map
- `ProcessRunner.swift` — (flat package)

## Rules

Read `CONTRIBUTING.md` for the folder layout and the pull-request rules.

@CONTRIBUTING.md
