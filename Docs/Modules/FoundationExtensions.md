# Swift Foundation Extensions

The small Foundation and standard-library helpers every package in the Sidewatch family would
otherwise re-declare: one home, tested once.

| Helper | What it answers |
|---|---|
| `collection[safe: i]` | the element, or nil out of bounds |
| `x.clamped(to:)` / `clamped(low:high:)` | a value held in bounds (the second tolerates inverted bounds) |
| `seq.groupedInOrder(by:)` | groups in the order each key first appears, elements in their order |
| `text.lines` | lines split on `\n` — safe on CRLF text, unlike `split(separator: "\n")` |
| `text.firstLine`, `text.clipped(to:)` | the first line holding anything, trimmed (every break kind); at most n characters, the ellipsis included |
| `text.shellQuoted` | one POSIX shell argument |
| `text.trimmed` / `trimmedSpaces` | surrounding whitespace (and newlines) removed |
| `interval.compactDuration` | `5d 8h 13m`, `12m`, `<1m` |
| `url.exists`, `url.lowercasedExtension` | file existence, a case-folded extension |
| `url.realPath` | the path with every link resolved as `realpath(3)` names it (`/private/var/…`, what FSEvents reports); nil when nothing exists there — `resolvingSymlinksInPath` strips `/private` and is not a substitute |
| `url.isSameFile(as:)` | whether two URLs name one file however each is spelled: the same standardized path, or the same real path (`/tmp` and `/private/tmp`, a folder opened through a link) |
| `FileManager.walk(_:includingPropertiesForKeys:options:visit:)` | every item under a folder, depth first, even when the folder ITSELF is a symbolic link (`enumerator(at:)` lists nothing then), spelled under the root as given; `DirectoryWalkStep` = next / skipDescendants / stop |
| `SingleFlight<Request>` | one run of a slow refresh at a time: `begin(_:)` false while one runs (keeping the LATEST request), `end()` hands it back for exactly one rerun; `begin()` / `endWantsRerun()` when there is nothing to remember |
| `path.isInside(folder, includingSelf:)`, `path.relativePath(under:)`, `url.isInside`, `url.path(relativeTo:)`, `roots.firstContaining(url)`, `roots.relativePath(of:)` | "is this path in that folder" by whole components (`/a/bc` is not inside `/a/b`), the folder itself only when asked; `directoryPrefix` is the folder with one trailing `/` |
| `url.contentStamp` | a file's size and nanosecond modification time from one `stat` (links followed), nil when nothing is there — the "did it change" key |
| `StampedCache` | a bounded memo keyed by path whose entries are dropped when the file's `contentStamp` moves |
| `nsString.fullRange` | `NSRange` over the whole string |
| `defaults.bool(forKey:default:)` (and Int, Double, String) | a stored value, or the default when never written |
| `Debouncer` | the last of a burst of actions, once, after a quiet delay |
| `RecencyFormatter` | a moment for a list of recent things, in the locale's words: "now", "12 min ago", "Yesterday at 14:05", "Mon 09:00", "22 Oct", "31 Dec 2025"; never "in 5 min" for a moment ahead of now; `full(_:)` with seconds and zone. Make one per list |
| `AsyncBridge.wait` | an async result from synchronous code on a worker thread |

```swift
import FoundationExtensions

let firstLine = text.lines[safe: 0]?.trimmed
let width = proposed.clamped(to: 130...460)
```

- Module `FoundationExtensions`; `swift test` is the whole check.
- No dependencies. macOS 14, tools 6.2, Swift 6 language mode.
- MIT licence. Copyright © 2026 ArrayPress Limited.
