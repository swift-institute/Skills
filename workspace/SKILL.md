---
name: workspace
description: Run and interpret every Institute build, test, resolve, lint, and local probe through the Workspace coordinator, and handle failures that come from the toolchain itself — compiler, optimizer and build-system defects, swiftlang/swift pull requests, Swift Evolution pitches, and pre-launch Swift Forums critique. Apply whenever a task builds, tests, resolves, cleans, lints, composes local sources, reports a result as evidence, or when a failure may be the toolchain rather than product logic.
---

# Workspace

Workspace owns local SwiftPM execution. Never invoke `swift build`, `swift test`, `swift
package`, or `xcodebuild` directly, and never wrap them in a repository-local script — a
repository-local wrapper is how a machine-specific assumption becomes everyone's.

## Commands

```sh
workspace package build   --package-path <path>
workspace package test    --package-path <path>
workspace package resolve --package-path <path>
workspace package update  --package-path <path>
workspace package clean   --package-path <path>
workspace package run     --package-path <path>
workspace package dump-package --package-path <path>

workspace doctor            # machine-checked checkout facts
workspace inventory         # the name → org → path register
workspace sync              # clone and fast-forward; --dry-run plans only
workspace context install|check
workspace navigation install|check

workspace compose --consumer <c> --dependency <d>   # local-source composition
workspace verify  --consumer <c> --dependency <d>
workspace restore --consumer <c> --dependency <d>
```

Add `--fresh` to `build` or `test` whenever the result will be reported. Forward SwiftPM
arguments by repeating `--argument`, using the `=` form whenever the forwarded value begins with
`-` or the parser claims it as a Workspace option:

```sh
workspace package test --argument=--filter --argument "Suite or test"
```

In a fresh clone the bootstrap `swift run --package-path Application workspace …` compiles the
whole dependency graph and is silent for several minutes. It is not hung.

## Evidence

A cached green is not evidence. Use `--fresh` for any release, audit, migration, benchmark, or
correctness claim.

A zero from the wrong root is not evidence either, so record what the run was: the package root,
the action, the toolchain, the forwarded arguments, the exit status, and whether it was fresh.
That record is what lets someone else disagree with your conclusion rather than only with your
confidence.

Pair every probe with a positive control. A probe that cannot demonstrate it can report
something proves nothing by reporting nothing — and a control proves the instrument RAN, not
that the query was complete. For any claim that something is ABSENT, the final check is an
unfiltered enumeration, never a pattern: a pattern matching zero lines and a wrong pattern look
identical. A sweep's shape — which roots, which file kinds, which spelling — is itself a claim
and needs its own control.

Dependencies are branch-based, so a green over stale pins `doctor` flagged is not evidence.
`canImport`-gated code does not re-evaluate on an incremental build: a suite rejoined by a
dependency change stays silently excluded from a green incremental run, so a clean build is the
gate of record whenever conditional compilation is in scope. Embedded compatibility is proved by
compiling with the declared SDK and compiler mode, never by searching for imports.

Report failures with the first compiler diagnostic and the complete log. Do not infer a source
defect from a setup, resolution, capacity, or toolchain failure; recheck a nightly-only failure
on stable; and confirm `swift --version` resolves to the intended toolchain before interpreting
a toolchain-sensitive result.

## Generated and machine-local state

`Package.resolved` is generated. Never commit, hand-edit, copy, stage, or delete it to force
resolution — change `Package.swift` and resolve.

Never delete `.build` directly; use `workspace package clean`. A manual deletion costs a full
rebuild of an artifact tree large enough that the mistake is measured in hours, not seconds.

A composed manifest writes a machine-local absolute path deliberately, so that it fails loudly
off-machine instead of silently resolving elsewhere. It is uncommittable: `restore` before
pushing. `restore`'s check is structural only — the manifest evaluates, the dependency is
declared by URL, no local path leaked. It resolves nothing and contacts no remote, so report its
scope honestly rather than as a resolution check.

The generated Xcode workspace and `Workspace.json` carry relative references only; never emit a
machine path into either. `Workspace.json` is the sole name → org → path authority.

`sync` never rewrites work: it fast-forwards only a clean checkout on `main` tracking
`origin/main` with no local commits, and reports dirty worktrees and feature branches without
touching them.

Institute tooling is Full Swift. Do not add Python or shell automation, or revive a `Scripts`
grab-bag; extend the typed Workspace surface and test the extension.

## Local probes

Bare `grep` in this shell is a function wrapping ugrep with `--ignore-files`, so it honours
`.gitignore` and silently skips files — use `/usr/bin/grep` when the result is evidence. Target
directories contain spaces, so quote paths and expect word-splitting bugs in any loop over
`find` output. Imports frequently live in umbrella `exports.swift` files, often as `@_exported
public import`, so a grep for `import X` in consumer files under-reports.

Before any large sweep, census, or absence claim, read
[instrument-traps.md](instrument-traps.md) — every entry there is a way to obtain a confident
zero from a broken instrument.

## swift-linter

A convention graduates from prose to a mechanical rule when it is recognizable from syntax or
from a package graph. That is the dividing line worth keeping in mind while writing either one:
swift-linter owns Swift syntax and AST semantics, Workspace validators own checkout and
package-graph facts, repository-policy owns GitHub state, and central CI executes them. Never
restate an executable predicate as prose, and never create package-local severity overrides.

Consumers activate exactly one bundle in a root `Lint.swift` (`Lint.Rule.Bundle.primitives`,
`.standards`, `.institute`, `.universal`); configuration stays in Swift.

Specify the predicate before implementing it: the exact syntax matched, the convention it
represents, known false positives and negatives, diagnostic location and message, canonical fix,
allowed exemptions. Ship positive, negative, edge, exemption, and self-firing fixtures — the
fixtures are the rule's contract, and a rule with no failing fixture is not known to work.

Fix the predicate before measuring its zero. Graduate a rule to error only after the fixtures
cover the intended surface, a fresh run scans Sources and Tests across every applicable package
root with a non-zero control, the unsuppressed count is zero, and the same scope is reproducible
in central CI.

Be honest in the rule's own message about which half it checks. A rule that requires a
justification comment checks that the comment is *there*; it does not check that the
justification is sound, and the reader deciding whether to trust a clean run needs to know
which.

Suppress a single finding only for a sanctioned pattern, with `// swift-linter:disable:next
<rule>` plus a `// REASON:` line naming the lawful shape. Never evade a detector by respelling
the prohibited code. Exemptions belong in the rule's Swift predicate, not in consumer
configuration, and must name the narrowest stable property distinguishing the lawful shape; add
a violation fixture, an exempt fixture, and a near-miss fixture that must still fire.

**Path-scoped exemptions are the dangerous class.** Every AST-based exemption fails toward still
firing, so an author complains and you find out. A path exemption fails toward NOT firing,
silently suppressing the findings the rule exists to surface — and the drop reads as progress.
Match whole directory segments against a required suffix that includes its leading separator,
drop the trailing filename before matching, never use `contains` or a prefix test, and gate
before the visitor walks. Fixtures are mandatory in both directions, including a positive
control with a bare filename and no directory component — without it, a careless predicate
silences the whole fixture suite and the run still reads green.

## Exporting a package for an LLM

```sh
PKG=<absolute-package-path>; OUT="/tmp/$(basename "$PKG")-sources.swift"; \
{ echo "# $(basename "$PKG")"; printf '\n## Package Manifest\n\n'; cat "$PKG/Package.swift"; \
  printf '\n## Source Files\n'; \
  /usr/bin/find "$PKG/Sources" -name '*.swift' -type f | sort | while read -r f; do \
    printf '\n### File: %s\n\n' "${f#"$PKG"/}"; cat "$f"; done; } > "$OUT"; wc -c "$OUT"
```

Package name, raw manifest, then each file under a `### File: <relative path>` header with raw
contents. Exclude `.build/`, `.git/`, `Package.resolved`, and anything `.gitignore`d. Export
tests to a sibling `-tests.swift` file only when asked. Report the byte count and let the
requester judge fit.

## Elsewhere

- Probes that return a confident zero — [instrument-traps.md](instrument-traps.md).
- Compiler, optimizer, and build-system defects: reduction, production-shape verification,
  SIL-level diagnosis — [toolchain-defects.md](toolchain-defects.md).
- Pull requests to swiftlang/swift, Evolution pitches, pre-launch Forums review —
  [upstream.md](upstream.md).
