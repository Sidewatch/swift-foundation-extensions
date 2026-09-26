# Swift Foundation Extensions

Foundation and standard-library helpers shared across the Sidewatch family, so no package
re-declares `trimmed`, `lines` or a debouncer of its own.

- Module `FoundationExtensions` in `Sources/FoundationExtensions`: `Extensions/` (one file per
  extended type and purpose) and `Support/` (`Debouncer`, `AsyncBridge`).
- Tests in `Tests/FoundationExtensionsTests`; `swift test` is the whole check.
- No dependencies. macOS 14, tools 6.2, Swift 6 language mode.
- A helper belongs here only if it needs nothing but Foundation and two or more packages (or the
  app) would otherwise spell it out. AppKit helpers go to swift-appkit-views.

@CONTRIBUTING.md
