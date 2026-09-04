# Swift Subprocess

A one-file, dependency-free runner for external tools: launch, drain both pipes concurrently, return status + stdout + stderr.

It exists because "launch a tool, read its output" was hand-rolled in four places and only some
got it right: a `Pipe` you never drain deadlocks the moment the child writes more than ~64 KB.
`Subprocess.run` drains stdout and stderr on their own threads and waits for both.

## Features

- `Subprocess.run(executable, arguments:, currentDirectory:, environment:)` → `Result` with `status`, `stdout`, `stderr`
- `Result.outputText`, `errorText`, `trimmedOutput`, `succeeded`, `launched`
- `Subprocess.which(tool)` → the path `PATH` resolves the tool to, or nil
- No dependencies; Swift 6 language mode

## Requirements

- macOS 14+
- Swift 6.2+ (Swift 6 language mode)

## Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/Sidewatch/swift-subprocess.git", from: "0.1.0")
```

## Usage

```swift
import Subprocess

let r = Subprocess.run("/usr/bin/git", arguments: ["status", "--porcelain"], currentDirectory: repo)
if r.succeeded { print(r.outputText) } else { print(r.errorText) }
```

## For agents

Read `CONTRIBUTING.md` first: the folder layout and the PR rules. `swift test` is the whole
check, and a new test must fail before the change it covers.

## License

MIT — see `LICENSE`.
