# Swift Foundation Extensions

The small Foundation helpers every package in the Sidewatch family would otherwise copy, and the one way the family runs an external tool.

## Modules

Each module is its own library product: depend on the package, then only on the products you use.

| Module | What it is |
|---|---|
| [`FoundationExtensions`](Docs/Modules/FoundationExtensions.md) | The small Foundation and standard-library helpers every package in the family would otherwise copy, plus `@Preference`. |
| [`ProcessRunner`](Docs/Modules/ProcessRunner.md) | Runs an external tool: launch, drain both pipes concurrently, return status, stdout and stderr. |

## Requirements

- macOS 14+
- Swift 6.2+ (Swift 6 language mode)

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/Sidewatch/swift-foundation-extensions.git", from: "0.1.0")
],
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "FoundationExtensions", package: "swift-foundation-extensions"),
    ]),
]
```

## Usage

### FoundationExtensions

See [Docs/Modules/FoundationExtensions.md](Docs/Modules/FoundationExtensions.md).

### ProcessRunner

```swift
import ProcessRunner

let r = ProcessRunner.run("/usr/bin/git", arguments: ["status", "--porcelain"], currentDirectory: repo)
if r.succeeded { print(r.outputText) } else { print(r.errorText) }
```

Each module's full guide is `Docs/Modules/<Module>.md`.

## Notes

The modules were separate packages until 27 September 2026 (`swift-process-runner`); their commits are kept here, so `git log --follow` traces any file back through them.

## For agents

Read `CONTRIBUTING.md` first: the folder layout and the PR rules. `swift test` is the whole
check, and a new test must fail before the change it covers. `CLAUDE.md` / `AGENTS.md` carry a
module map.

## License

MIT — see [LICENSE](LICENSE).
