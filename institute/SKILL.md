---
name: institute
description: Develop locally in an app-owned Xcode workspace through the selected Xcode's connector; interpret build and test evidence and investigate toolchain defects. Also covers Institute CI, repository policy and lint when those systems are explicitly in scope. Local resolution, builds and tests use Xcode.
---

# Institute

## Local development

The app's `.xcworkspace` owns local development and dependency resolution. For Laurie, use
`Laurie.xcworkspace` (formerly `Harvest.xcworkspace`). Include the app, its hosts, and the local
package checkouts needed for the change in that workspace, using relative references. Xcode
must resolve and build the intended local sources, including unpushed cross-package edits.
Keep published package requirements portable; do not rewrite manifests to machine-local
absolute paths for local iteration.

Discover the available tool capabilities rather than assuming an older tool interface.

- Open the workspace through the connector and identify its workspace identifier.
- Inspect and select the scheme, test plan and destination through Xcode.
- Let Xcode own package resolution. Verify the resolved dependency identity, revision and local
  checkout from Xcode's package graph and diagnostics before interpreting a result.
- Build, run tests, read compiler diagnostics and full logs, and interact with devices through
  the connector. Use a focused test selection during iteration and the affected test plan for
  final local verification.
- If a required workspace, package-resolution or clean-build operation is unavailable through
  the connected tools, report the specific missing capability. Do not silently substitute an
  Institute command, raw SwiftPM command, `xcodebuild`, or a repository-local wrapper.

### Using the connector

- Keep the app workspace open across tasks; closing it discards Xcode's build state, so the
  next build re-plans from scratch. Do not call `XcodeCloseWorkspace` between tasks.
- Build packages through the app workspace. When a package must be opened on its own, pass its
  directory, never `Package.swift`, which Xcode opens as a lone source file.
- Workspace and window identifiers do not survive a close. After any close or error naming the
  identifier, list workspaces again rather than reusing the old one.
- A run with failing tests returns as a successful call; read `counts.failed`. An incomplete
  result bundle is not a test failure until the bundle has been read.
- A timed-out call leaves Xcode building. Wait for that build to finish before starting another;
  a retry stacks a second build on the first. Run one build or test at a time.
- Follow Apple's `xcode-integration:device-interaction` skill for device sessions: one
  workspace-bound session per workspace, handed exclusively to one agent, ended when done.

The `institute` command is not a prerequisite for local app work: it operates CI and the
GitHub organizations, and has no build, composition or checkout commands.

## Institute CI and administration

Use Institute machinery when the task explicitly concerns its CI, repository policy, lint or
administration. This does not change the local Xcode workflow above.

Institute lint's entry point is `institute ci -- source --repository <owner/name> --revision
<commit> --root <path> --bundle <bundle> --xcode-application <Xcode.app>`. A local lint run is
guidance; CI's `Quality · source` job is the evidence. Running `swift-format` or `swiftlint`
with a stray repository configuration is not Institute lint.

CI full-tier `workflow_dispatch` is the evidence of record for issue closure. A local green is
iteration evidence, not CI closure evidence. `gh run rerun` re-executes an old snapshot; dispatch
a fresh run when fresh CI evidence is required.

## Evidence

A cached green is not newly originated evidence. For a new local correctness, migration or
performance claim, verify that Xcode compiled the relevant changed sources and ran the intended
tests. When a claim requires a clean build, use an available Xcode clean-build operation and
record it; if unavailable, state that limitation rather than claiming freshness.
Exact-head evidence from another task remains
usable when its command, root, toolchain, revision, exit status, and provenance are reported as
task-attributed rather than re-labelled as independently checked.

Choose the smallest Xcode operation that can change the decision. A test normally compiles the
tested target, so do not add a separate fresh build unless it answers a different material
question. Once a decisive blocker fixes the next action, stop unrelated verification rather
than filling out an evidence inventory.

A zero from the wrong root is not evidence either, so record what the run was: the workspace
and package roots,
full Git SHAs and relevant uncommitted changes, scheme, test plan or test selection, destination,
SDK and toolchain, action, result, and whether a clean build was performed.
That record is what lets someone else disagree with your conclusion rather than only with your
confidence.

Pair every probe with a positive control. A probe that cannot demonstrate it can report
something proves nothing by reporting nothing — and a control proves the instrument RAN, not
that the query was complete. For any claim that something is ABSENT, the final check is an
unfiltered enumeration, never a pattern: a pattern matching zero lines and a wrong pattern look
identical. A sweep's shape — which roots, which file kinds, which spelling — is itself a claim
and needs its own control.

`canImport`-gated code does not re-evaluate on an incremental build: a suite rejoined by a
dependency change stays silently excluded from a green incremental run, so a clean build is the
gate of record whenever conditional compilation is in scope. Embedded compatibility is proved by
compiling with the declared SDK and compiler mode, never by searching for imports.

Report failures with the first compiler diagnostic and the complete log. Do not infer a source
defect from a setup, resolution, capacity, or toolchain failure; recheck a nightly-only failure
on stable; and confirm the toolchain and SDK used by Xcode before interpreting
a toolchain-sensitive result. The shell's `swift --version` alone does not identify Xcode's compiler.

## Generated and machine-local state

`Package.resolved` is generated. Never commit, hand-edit, copy, stage, or delete it to force
resolution — change `Package.swift` and resolve.

Never delete `.build` or DerivedData directly as a reset. Use Xcode's supported clean-build
operation when needed; avoid discarding unrelated build caches.

`sync` never rewrites work: it fast-forwards only a clean checkout on `main` tracking
`origin/main` with no local commits, and reports dirty worktrees and feature branches without
touching them.

Institute tooling is Full Swift. Do not add Python or shell automation, or revive a `Scripts`
grab-bag; extend the typed Institute surface and test the extension.

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
swift-linter owns Swift syntax and AST semantics, Institute validators own checkout and
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

- Compiler, optimizer, and build-system defects: reduction, production-shape verification,
  SIL-level diagnosis — [toolchain-defects.md](toolchain-defects.md).
- Pull requests to swiftlang/swift, Evolution pitches, pre-launch Forums review —
  [upstream.md](upstream.md).
- Reporting a toolchain bug upstream: record it with swift-institute/Issues' "Toolchain bug"
  form; nothing is filed until `issue-check` admits `upstream-ready` and Coen says yes —
  [UPSTREAM-PROCEDURE.md](https://github.com/swift-institute/Issues/blob/main/UPSTREAM-PROCEDURE.md).
