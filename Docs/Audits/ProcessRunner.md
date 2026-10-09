# Audit log

Last full audit: **17 Sep 2026** — every source file covered by the MECHANICAL checks below (build warnings, tests,
dead-code and risk-pattern scans, docs drift); line-by-line logic review was targeted at the areas changed since
5 Sep 2026, not the whole tree. Nothing needs re-scanning unless it changed after that date. Add a dated line under *History* when you audit again, and keep the
*Known non-issues* list current so the next pass skips them.

## What a full audit checks

1. `swift build` warnings (none allowed except those listed under known non-issues) and `swift test` green.
2. Dead code: every `func`/type/property declared once and referenced nowhere in the app or the family
   (`grep -w` across `*.swift` AND non-Swift files — selectors and MCP names live in strings). Protocol
   requirements, `override`s, `@objc` actions and public API are NOT dead because Sidewatch does not call them.
3. Risky patterns: `Timer` without `invalidate`, `addObserver(forName:)` without `removeObserver`, `as!`, `try!`
   outside literal regexes, `fatalError` outside `init?(coder:)`, `print(` outside harnesses, TODO/FIXME left behind.
4. Docs drift: every name in CLAUDE.md's module map exists; AGENTS.md mirrors CLAUDE.md; README Usage matches the API.

## Result on 17 Sep 2026

- Build: clean. Tests: green.
- Nothing to fix in this package.

## Logic review — 18 Sep 2026 (the whole package, line by line)

Nothing to fix. Checked: stdout and stderr are drained on their own queues and joined through a
`DispatchGroup` before `waitUntilExit`, so a child that fills one pipe cannot deadlock the parent;
the locked result sink; the optional stdin pipe; the launch-failure path.

## Timeout and environment — 9 Oct 2026

Probed, with the outcomes, so nobody re-tests them:

- `Process` launches the child as the leader of its own process group and `terminate()` signals
  that group, so `sh -c 'sleep 30 & sleep 30'` with a 1 s timeout already returned in ~1 s under
  the old read-to-EOF drain: both sleeps died with the shell. The case that blocked was a
  grandchild that ignores `SIGTERM` (`trap "" TERM`, inherited through `exec`) or has left the
  group: the old drain waited the full 10 s for EOF and reported `succeeded == true`. Now:
  `SIGTERM` at the deadline, `SIGKILL` to the group after `killGrace` (0.5 s), then the drains
  stop polling and the pipes are abandoned. Measured: 1.67 s for the `trap` fixture. Test
  `testATimeoutReturnsEvenWhenAGrandchildKeepsThePipesOpen`; mutant: the previous
  `ProcessRunner.swift` (10.08 s, `succeeded` true).
- `removing:` strips inherited variables before `environment:` is layered; a name in both takes
  the `environment:` value. Tests `testRemovingStripsAnInheritedVariable` (mutant: the
  `removeValue` loop deleted — the child still saw the variable) and
  `testEnvironmentWinsOverRemoving`.
- Output written before the deadline is kept (`testOutputBeforeTheTimeoutIsKept`).

## Known non-issues (do not "fix" these again)

- The drains poll in 200 ms ticks only while a timeout is set and no data is ready; a stream at
  EOF returns at once, so the normal path costs nothing extra.

## History

- 17 Sep 2026 — full audit (app + all 20 libraries), Claude with David.
- 18 Sep 2026 — logic review (every source and test file, line by line), Claude with David.
- 9 Oct 2026 — timeout against a pipe-holding grandchild, `removing:` for inherited variables (see above).
