---
name: workspace
description: Run and interpret every Institute build, test, resolve, lint, and local probe through the Workspace coordinator, and handle failures that come from the toolchain itself — compiler, optimizer and build-system defects, swiftlang/swift pull requests, Swift Evolution pitches, and pre-launch Swift Forums critique. Apply whenever a task builds, tests, resolves, cleans, lints, composes local sources, reports a result as evidence, or when a failure may be the toolchain rather than product logic.
---

# Workspace

Workspace owns local SwiftPM execution. Never invoke `swift build`, `swift test`, `swift package`, or
`xcodebuild` directly, and never wrap them in a repository-local script.

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
workspace sync              # clone and fast-forward; --dry-run plans only
workspace context install|check
workspace navigation install|check

workspace compose --consumer <c> --dependency <d>   # local-source composition
workspace verify  --consumer <c> --dependency <d>
workspace restore --consumer <c> --dependency <d>
```

Add `--fresh` to `build` or `test` whenever the result will be reported. Forward SwiftPM arguments by
repeating `--argument`, using the `=` form whenever the forwarded value begins with `-` or the parser
claims it as a Workspace option:

```sh
workspace package test --argument=--filter --argument "Suite or test"
```

In a fresh clone the bootstrap `swift run --package-path Application workspace …` compiles the whole
dependency graph and is silent for several minutes. It is not hung.

## Evidence

A cached green is not evidence — use `--fresh` for any release, audit, migration, benchmark, or
correctness claim. A zero from the wrong root is not evidence either: record the package root, action,
toolchain, forwarded arguments, exit status, and whether the run was fresh.

Pair every probe with a positive control. A probe that cannot demonstrate it can report something
proves nothing by reporting nothing — and a control proves the instrument RAN, not that the query was
complete. For any claim that something is ABSENT the final check must be an unfiltered enumeration,
never a pattern: a pattern matching zero lines and a wrong pattern look identical. A sweep's shape —
which roots, which file kinds, which spelling — is itself a claim and needs its own control.

Dependencies are branch-based; a green over stale pins `doctor` flagged is not evidence.
`canImport`-gated code does not re-evaluate incrementally, so a clean build is the gate of record when
conditional compilation is in scope. Embedded compatibility is proved by compiling with the declared
SDK and compiler mode, never by searching for imports. Report failures with the first compiler
diagnostic and the complete log; do not infer a source defect from a setup, resolution, capacity, or
toolchain failure; recheck a nightly-only failure on stable, and confirm `swift --version` resolves to
the intended toolchain before interpreting a toolchain-sensitive result.

## Generated and machine-local state

`Package.resolved` is generated. Never commit, hand-edit, copy, stage, or delete it to force
resolution — change `Package.swift` and resolve. Never delete `.build` directly; use `workspace
package clean`, since a manual deletion costs a rebuild on the order of 80 GB of artifacts.

A composed manifest writes a machine-local absolute path deliberately, so it fails loudly off-machine
instead of silently resolving elsewhere. It is uncommittable: `restore` before pushing. `restore`'s
check is structural only — the manifest evaluates, the dependency is declared by URL, no local path
leaked. It resolves nothing and contacts no remote, so report its scope honestly.

The generated Xcode workspace and `Workspace.json` carry relative references only; never emit a machine
path into either. `Workspace.json` is the sole name → org → path authority. `sync` never rewrites work:
it fast-forwards only a clean checkout on `main` tracking `origin/main` with no local commits, and
reports dirty worktrees and feature branches without touching them.

Institute tooling is Full Swift. Do not add Python or shell automation, or revive a `Scripts`
grab-bag; extend the typed Workspace surface and test the extension.

## Local probes

Bare `grep` in this shell is a ugrep wrapper that honours `.gitignore` and silently skips files — use
`/usr/bin/grep` when the result is evidence. Target directories contain spaces, so quote paths and
expect word-splitting bugs in any loop over `find` output. Imports frequently live in umbrella
`exports.swift` files, often as `@_exported public import`, so a grep for `import X` in consumer files
under-reports.

Before any large sweep, census, or absence claim, read [instrument-traps.md](instrument-traps.md) — the
full reference, every entry a failure mode that returns a confident zero.

## swift-linter

A convention graduates from prose to a mechanical rule when it is recognizable from syntax or from a
package graph. swift-linter owns Swift syntax and AST semantics, Workspace validators own checkout and
package-graph facts, repository-policy owns GitHub state, and central CI executes them. Never restate
an executable predicate as prose, and never create package-local severity overrides. Consumers activate
exactly one bundle in a root `Lint.swift` (`Lint.Rule.Bundle.primitives`, `.standards`, `.institute`,
`.universal`); configuration stays in Swift.

Specify the predicate before implementing it: exact syntax matched, the convention it represents, known
false positives and negatives, diagnostic location and message, canonical fix, allowed exemptions. Ship
positive, negative, edge, exemption, and self-firing fixtures — the fixtures are the rule's contract.
Fix the predicate before measuring its zero. Graduate a rule to error only after the fixtures cover the
intended surface, a fresh run scans Sources and Tests across every applicable package root with a
non-zero control, the unsuppressed count is zero, and the same scope is reproducible in central CI.

Suppress a single finding only for a sanctioned pattern, with `// swift-linter:disable:next <rule>`
plus a `// REASON:` line naming the lawful shape. Never evade a detector by respelling the prohibited
code. Exemptions belong in the rule's Swift predicate, not in consumer configuration, and must name the
narrowest stable property distinguishing the lawful shape; add a violation fixture, an exempt fixture,
and a near-miss fixture that must still fire.

Path-scoped exemptions are the dangerous class. Every AST-based exemption fails toward still firing, so
an author complains; a path exemption fails toward NOT firing, silently suppressing the findings the
rule exists to surface, and the drop reads as progress. Match whole directory segments against a
required suffix that includes its leading separator, drop the trailing filename before matching, never
use `contains` or a prefix test, and gate before the visitor walks. Fixtures are mandatory in both
directions, including a positive control with a bare filename and no directory component — without it
a careless predicate silences the whole fixture suite and the run still reads green.

## Investigating a toolchain failure

Produce a decision, not a pile of diagnostics: a product defect with a verified fix, a toolchain defect
with a minimum reproducer and a safe workaround, a language constraint with an implementation decision,
a stale-state or resolution failure with its source named, or an explicitly bounded inconclusive
result. Eliminate the cheap explanations first: record the exact command and `swift --version`; check
the dependency URL and requirement, the selected toolchain and any unintended `TOOLCHAINS` override,
resolver diagnostics, and a fresh operation. Then retest on the latest development toolchain — the bug
may already be fixed:

```bash
ls /Library/Developer/Toolchains/
TOOLCHAINS=swift xcrun swiftc -O reproducer.swift -o /tmp/test 2>&1
```

Do not call a failure a compiler bug because the diagnostic is confusing. A blocked super-repository
build does not prove the bug persists on another toolchain.

### Reduce, one variable at a time

Reduce until removing any single remaining element would eliminate the behavior. A reproducer is
faithful only if it preserves the compilation phase and optimization mode, the diagnostic or crash
signature or wrong behavior, the generic/ownership/isolation/conformance constraints that trigger it,
and the relevant file and module boundaries. If the trigger cannot itself compile, drive `swiftc` out
of process from a test and assert on the process result.

Every reduction step needs a verified clean build: run `workspace package clean` before building, or
build a standalone `swiftc` reproducer with no SwiftPM cache. Stale caches have produced false
reductions — a "crashing" reduction may be running cached SIL from a previous variant.

Vary exactly one dimension per experiment: optimization, file boundary, target boundary, declaration
order, generic constraint, ownership annotation, module resilience, toolchain. Every claimed required
ingredient needs an A/B result: A contains the ingredient and fails; B removes only that ingredient and
passes. State the coverage of a negative experiment — "not reproduced in this shape" is not
"impossible".

### Verify in the production shape

A reduced reproducer establishes a mechanism, not its prevalence. Insert the exact trigger into each
cited production package and confirm the real code behaves the same before recommending a production
change. A minimal reproduction validates that a bug exists; it cannot validate that a workaround works
at scale — test workarounds in the actual codebase, which has structural properties it lacks.

Anything whose confirmation would admit production adoption of a feature, pattern, or workaround must
pass in release mode and across a module boundary (a second target, or a sibling package importing the
first). Debug single-module passes routinely hide SIL-level bugs that fire only once optimization
enables the path (CopyPropagation, CopyToBorrowOptimization, specialization), and hide access-control
and serialization effects that depend on `package` versus `public`. A pattern safe in debug and unsafe
in release is failed evidence dressed as success.

```bash
workspace package build --fresh --argument=-c --argument release
```

### Compiler-level diagnosis

Escalate only as far as needed: source logging, debug-versus-release, file- and module-level
elimination, compiler views, pass bisection, compiler source. Use the same frontend mode and flags as
the reproducer when comparing stages.

```console
swiftc -typecheck Reproducer.swift
swiftc -emit-silgen Reproducer.swift
swiftc -emit-sil -Onone Reproducer.swift
swiftc -emit-sil -O Reproducer.swift
swiftc -emit-ir -O Reproducer.swift
swiftc -S -O Reproducer.swift
swiftc -Xfrontend -debug-constraints Reproducer.swift
swiftc -Xfrontend -debug-generic-signatures Reproducer.swift
swiftc -Xfrontend -sil-verify-all Reproducer.swift
```

Compiler flags change between toolchains; confirm availability with the selected toolchain rather than
treating this list as an interface. Broken `-emit-silgen` points at SIL generation; correct raw SIL
with broken canonical SIL points at a mandatory pass; correct canonical SIL with broken optimized SIL
points at optimization. Compare the smallest differing function, never whole module dumps. For
optimization-only failures, prove `-Onone` passes, capture the pass pipeline for that exact toolchain,
binary-search the executed pass count, then inspect the before/after SIL. Pass numbering is
toolchain-specific evidence, never a portable conclusion.

### Known traps

When a `swift-testing` macro reports an `@section` or lexical-context failure, remove or simplify the
surrounding test macros first. Macro diagnostics can mask an ordinary semantic error in the test body;
investigate the macro only after the underlying source type-checks independently.

A recommendation to conform to a stdlib protocol needs a verification spike — a minimal
external-package target declaring the conformance, built successfully — before adoption. Two mechanisms
strip protocols from the SDK's `.swiftinterface`: `@_spi`-gated declarations disappear from the public
interface, and new stdlib protocols may be `public` in `swiftlang/swift` source but not yet shipping in
a given SDK's compiled interface (driven by SDK-build availability annotations, not source visibility).
Both surface as the same "no such type in module" failure.

Never suppress optimization to hide a miscompile. A proposed fix must change the diagnosed behavior in
the production shape; an explicit conformance or a no-op rewrite is not a fix merely because it looks
related. Searching upstream issues is evidence gathering; it does not authorize filing or modifying an
upstream issue.

## Pull requests to swiftlang/swift

Fork and push to the fork; direct push needs commit access, granted after several accepted non-trivial
PRs.

```bash
gh repo fork swiftlang/swift --clone=false
git remote add myfork https://github.com/{username}/swift.git
```

Target `main`; release branches need branch-manager approval. Commit subjects carry a component tag —
`[SILOptimizer]`, `[Sema]`, `[SILGen]`, `[IRGen]`, `[AST]`, `[SIL]`, `[stdlib]`, `[test]`,
`[Embedded]`, or the colon form (`IRGen:`) — and `NFC:` for no-functional-change work. New source files
carry the Apache 2.0 + Runtime Library Exception header; test files under `test/` do not. No CLA or DCO
is required. Reference issues by GitHub URL, never `rdar://` (Apple-internal). Never use `Resolves` on
an upstream PR. Disclose AI assistance in the PR body when any part of the change was AI-assisted, and
replace the default HTML comment template.

Every bug fix ships a test at the abstraction level nearest the change: `.sil` tests under
`test/SILOptimizer/` via `sil-opt` + FileCheck, `test/SILGen/` via `-emit-silgen`, `test/Sema/` via
`-typecheck`, `test/IRGen/` via `-emit-ir`, `test/Interpreter/` for end-to-end behavior. Gate with
`// REQUIRES: swift_in_compiler` and `// REQUIRES: swift_feature_X`. Use
`-enable-experimental-feature Lifetimes` for `~Escapable` types, `-disable-availability-checking` when
the test uses features gated on newer deployment targets (without it `llvm-lit` fails against an older
macOS target), and `-sil-print-types` to make types visible to FileCheck. Run tests through llvm-lit
before pushing, since it honors `REQUIRES:`.

```bash
llvm-lit -sv test/SILOptimizer/your_test.sil
llvm-lit -sv test/SILOptimizer/lifetime_dependence/
```

CODEOWNERS auto-assigns reviewers on non-draft PRs. CI runs from a PR comment (`@swift-ci Please smoke
test`, `@swift-ci Please test`, `@swift-ci Please benchmark`); contributors without commit access
cannot trigger it and must ask a reviewer to. Address feedback with follow-up commits — never
force-push. If asked to split a PR, close it with an explanatory comment and open focused replacements
rather than rewriting history.

## Swift Evolution pitches

- https://github.com/swiftlang/swift-evolution/blob/main/process.md
- https://github.com/swiftlang/swift-evolution/blob/main/commonly_proposed.md
- https://forums.swift.org/c/evolution/pitches/18

Check `commonly_proposed.md` before drafting; those ideas have been extensively debated and revisiting
one requires substantial new evidence. A pitch gives the problem and a general solution direction; a
proposal gives a complete specification with detailed design and full compatibility analysis, and a
language change needs an implementation. Do not write proposal-weight content for a pitch.

## Pre-launch Forums review

Before a Forums announcement or public launch, pressure-test the artifact against the recurring
critique patterns in the Forums corpus. Verify each objection's factual premises against source,
manifests, tests, and benchmarks, and turn the verified load-bearing ones into fixes or explicit launch
risks. Keep predicted reception separate from correctness.

Simulated threads are INTERNAL artifacts. The skill MUST NOT suggest posting any simulated content to
forums.swift.org, Bluesky, Discord, or anywhere else. Treat simulated posts as draft-only. Handles in
simulated threads MUST use the format `@reviewer-<cluster-id>` or similar non-identifying tags.

## Exporting a package for an LLM

```sh
PKG=<absolute-package-path>; OUT="/tmp/$(basename "$PKG")-sources.swift"; \
{ echo "# $(basename "$PKG")"; printf '\n## Package Manifest\n\n'; cat "$PKG/Package.swift"; \
  printf '\n## Source Files\n'; \
  /usr/bin/find "$PKG/Sources" -name '*.swift' -type f | sort | while read -r f; do \
    printf '\n### File: %s\n\n' "${f#"$PKG"/}"; cat "$f"; done; } > "$OUT"; wc -c "$OUT"
```

Package name, raw manifest, then each file under a `### File: <relative path>` header with raw
contents. Exclude `.build/`, `.git/`, `Package.resolved`, and anything `.gitignore`d. Export tests to a
sibling `-tests.swift` file only when asked. Report the byte count and let the requester judge fit.
