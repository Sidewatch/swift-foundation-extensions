# Swift ProcessRunner

A one-file runner for external tools: launch, drain both pipes concurrently, return status + stdout + stderr.

It exists because "launch a tool, read its output" was hand-rolled in four places and only some
got it right: a `Pipe` you never drain deadlocks the moment the child writes more than ~64 KB.
`ProcessRunner.run` drains stdout and stderr on their own threads and waits for both.

## Features

- `ProcessRunner.run(executable, args, directory:, input:, environment:, removing:, augmentPATH:, timeout:, outputLimit:)` → `Result` with `status`, `stdout`, `stderr`, `timedOut`, `truncated`
- `Result.outputText`, `errorText`, `trimmedOutput`, `succeeded`, `launched`
- `removing:` strips inherited variables (a `GIT_DIR` the launching shell exported) before `environment:` is layered on
- `timeout:` sends `SIGTERM` at the deadline and `SIGKILL` to the child's process group after `killGrace` (0.5 s), then abandons the pipes — so the caller is released even when a grandchild that ignores `SIGTERM` keeps stdout open
- `outputLimit:` keeps the first that many bytes of stdout and ends the process the way a timeout does, so a tool printing without end (`yes`, a runaway `jq` query) cannot fill memory; `truncated` says it happened
- `ProcessRunner.which(tool)` → the path `PATH` resolves the tool to, or nil
- Depends only on FoundationExtensions, in the same package; Swift 6 language mode

## Requirements

- macOS 14+
- Swift 6.2+ (Swift 6 language mode)

## Installation

### Swift Package Manager

```swift
.package(url: "https://github.com/Sidewatch/swift-foundation-extensions.git", from: "0.1.0")
```

## Usage

```swift
import ProcessRunner

let r = ProcessRunner.run(
    "/usr/bin/git", ["status", "--porcelain"], directory: repo,
    environment: ["GIT_OPTIONAL_LOCKS": "0"], removing: ["GIT_DIR"], timeout: 60)
if r.timedOut { print("git hung") } else if r.succeeded { print(r.outputText) } else { print(r.errorText) }
```

## For agents

Read `CONTRIBUTING.md` first: the folder layout and the PR rules. `swift test` is the whole
check, and a new test must fail before the change it covers.

## License

MIT — see `LICENSE`.
