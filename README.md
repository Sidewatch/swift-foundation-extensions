# Swift Foundation Extensions

The small Foundation and standard-library helpers every package in the Sidewatch family would
otherwise re-declare: one home, tested once.

| Helper | What it answers |
|---|---|
| `collection[safe: i]` | the element, or nil out of bounds |
| `x.clamped(to:)` / `clamped(low:high:)` | a value held in bounds (the second tolerates inverted bounds) |
| `text.lines` | lines split on `\n` — safe on CRLF text, unlike `split(separator: "\n")` |
| `text.shellQuoted` | one POSIX shell argument |
| `text.trimmed` / `trimmedSpaces` | surrounding whitespace (and newlines) removed |
| `interval.compactDuration` | `5d 8h 13m`, `12m`, `<1m` |
| `url.exists`, `url.lowercasedExtension` | file existence, a case-folded extension |
| `nsString.fullRange` | `NSRange` over the whole string |
| `defaults.bool(forKey:default:)` (and Int, Double, String) | a stored value, or the default when never written |
| `Debouncer` | the last of a burst of actions, once, after a quiet delay |
| `AsyncBridge.wait` | an async result from synchronous code on a worker thread |

```swift
import FoundationExtensions

let firstLine = text.lines[safe: 0]?.trimmed
let width = proposed.clamped(to: 130...460)
```

- Module `FoundationExtensions`; `swift test` is the whole check.
- No dependencies. macOS 14, tools 6.2, Swift 6 language mode.
- MIT licence. Copyright © 2026 ArrayPress Limited.
