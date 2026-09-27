# Audit log

Last full audit: **27 Sep 2026**: the package was created that day from the Sidewatch app's
`Extensions/` and `Support/` folders and the four libraries that each carried their own
`StringProtocol+Trimmed`. Add a dated line under *History* when you audit again, and keep
*Known non-issues* current so the next pass skips them.

## What a full audit checks

1. `swift build` warnings (none allowed except those listed under known non-issues) and `swift test` green.
2. Dead code: every declaration referenced somewhere in the package or the family.
3. Every public declaration documented with `///`.
4. Every test mutation-verified: break the helper, watch its test fail, restore.

## Known non-issues

- `AsyncBridge.wait` blocks its thread by design; calling it on the main thread would deadlock
  any operation that hops to main. The doc comment says so; there is no runtime guard.
- `compactDuration` spells its units in English (`d`, `h`, `m`). Localising it is the host's call.

## History

- 27 Sep 2026 — created; 13 tests, each helper mutation-verified (six mutants, six failures).
