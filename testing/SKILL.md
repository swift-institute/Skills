---
name: testing
description: Design, structure, and place Swift Institute tests and benchmarks — suite shape, nested test packages, snapshot tests, Swift Testing framework traps, and executable benchmark mechanics. Apply whenever writing, restructuring, or reviewing tests or performance measurement.
---

# Swift testing

Name the invariant, input space, observable result, and failure signal before choosing a
fixture. Test through the narrowest interface that expresses the behavior, on the
boundary the behavior actually depends on — a same-target test cannot prove a
cross-module claim. Prefer laws and reference models over repeated examples.

## Suite structure

Tests are a subdomain of the source domain, not a parallel vocabulary. Each top-level
suite is declared as an extension of the source type it covers:

```swift
extension <SourceType> {
    @Suite struct <TestSubdomain> {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
    }
}

extension <SourceType>.<TestSubdomain>.Unit {
    @Test func `descriptive scenario name`() { }
}
```

`Unit`, `` `Edge Case` ``, and `Integration` are the canonical sub-suite set. Do not
invent additional categories — fixed names are what make cross-package searching work.

Reference source types directly. No local convenience typealiases, no compound
`FooTests` top-level structs. Test fixtures (phantom-tag enums, sample values) live as
nested members of the test subdomain. Test names state the condition and expected
behavior in readable words; do not repeat the suite or type name to imitate an XCTest
method.

## Host classes that break the extension pattern

Where the extension shape cannot compile or cannot be discovered, use a top-level
single-word backticked suite (`@Suite struct \`Index Tests\``) with the same sub-suites.

- Generic type, unspecialized (`extension Index { @Suite struct Test {} }`) — hard error,
  `@section cannot be used in a generic context`. Test bodies there are also generic, so
  a local `struct Tag {}` inside a test body will not compile.
- Generic type at a concrete specialization (`extension Index<Int> { @Suite struct Test {} }`)
  — compiles and is SILENTLY never discovered. Nothing fails; the tests just do not run.
- Nested-in-generic types inherit the outer generic parameters and fail the same way.
- Protocol extension — `static stored properties not supported in protocol extensions`;
  the suite macro synthesizes static storage a protocol extension cannot host.
- A host type named `Protocol` (e.g. `RFC_791.Protocol`) — the `@Test` macro emits
  expression-position references where Swift's `.Protocol` metatype grammar hijacks the
  name even backticked. Do not attempt the extension pattern there.
- Packages that declare no own type (only constrained extensions).

Scope "this type already carries a `Test` suite" collision checks per test target: a
same-named suite in a sibling test target is not a collision, because extending a type
nested in another module's test target is illegal Swift anyway. When a backticked
top-level name is already claimed, append the new suite's distinguishing tokens rather
than nesting.

Verify any proposed deviation with a `swiftc -typecheck` probe before committing to it.

## Framework traps

- `#expect` copies its operands. Project a `~Copyable` value to a Copyable observation
  first; `#expect(value.property)` also synthesizes a receiver-copying property access,
  so bind the property to a local first.
- `== nil` on a `~Copyable` Optional does not work in `#expect` — binary comparison
  requires Copyable operands. Use `if let` / `guard` pattern matching.
- Two `await`s inside one `#expect` fails type inference. Extract each side to a `let`
  binding, then compare.
- `@Test` generates `@section`-attributed globals whose mangled names scale with nesting
  depth times test count; past about four levels the aggregate exceeds compiler
  thresholds and surfaces as a cryptic `@section` error. One suite per file at that
  depth, and shorten the nesting suffix.
- Use `pthread_main_np() != 0` for main-actor-isolation checks in primitives and
  standards; Foundation's `Thread.isMainThread` is not available there.
- Macro expansion tests validate the expansion, not whether the macro may be attached at
  a given site. Neither harness checks form-vs-site applicability, so macro coverage must
  include at least one real consumer site compiled through the coordinator.
- Prefer the generic macro-test support with a Swift Testing `failureHandler` routing to
  `Issue.record`; do not pull XCTest or Foundation in for fixture convenience.
- A mock produced by `unsafeBitCast` over a pointer-like `BitwiseCopyable` type must
  offset its tag by at least 1. Tag 0 is the all-zeros pattern that `Optional<T>` reads
  as `.none`, so the mock becomes indistinguishable from "no value".
- Do not add copyability to a production API to satisfy a test macro.

## Nested test package

Every ecosystem package puts swift-testing and every other test-only third-party
dependency (macro-testing, snapshot support) in a nested `Tests/Package.swift`, never in
the main manifest. Test directories are flat siblings under `Tests/`.

```
swift-<package>/
  Package.swift            # unit test targets, explicit path:
  Sources/<Module>/
  Tests/
    Package.swift          # depends on ".." and swift-testing by relative path
    <Module> Tests/
    <Module> Snapshot Tests/
      __Snapshots__/       # committed
```

SwiftPM skips automatic target discovery in any directory containing its own
`Package.swift`, so both manifests need explicit `path:`. The parent uses
`path: "Tests/<Module> Tests"`; the nested manifest's root is `Tests/`, so its targets
use `path: "<Module> Snapshot Tests"` — without it SwiftPM looks in `Tests/Tests/`.

The parent package is always `..`. swift-testing is `../../swift-testing` from a
foundations package and `../../../swift-foundations/swift-testing` from primitives and
standards. A wrong relative path surfaces as "no package found". The nested package name
is `testing`; mirror the parent's upcoming-feature settings; gitignore the nested
`.build/`, `.swiftpm/`, and `.benchmarks/`.

Snapshot references live in `__Snapshots__/` beside the test source and are committed.
Recording modes: `.missing` records new and compares existing (default), `.all` always
records, `.failed` records on failure and still fails, `.never` compares only and fails
when missing — use `.never` in CI.

Test support is a `.library` product, never a `.testTarget` — a test target cannot be
consumed across packages. Product and target names use spaces
(`"Memory Primitives Test Support"`); imports use underscores
(`import Memory_Primitives_Test_Support`). Path is always `Tests/Support`. Test support
may depend on production products; production products never depend on test support.
Search for an existing support product before adding helpers: reusable helpers live with
the lowest layer that can own them, package-specific fixtures stay local.

## Verification

Filter while iterating, then run the affected package fresh when reporting:

```sh
workspace package test --argument=--filter --argument "Behavior"
workspace package test --fresh
```

A filtered run proves only that filter. `canImport`-gated suites do not re-evaluate on
incremental builds — a suite rejoined by a dependency change stays silently excluded from
a green incremental run, so any gate covering them runs from a clean worktree after
`workspace package clean`.

TSan legs on packages whose dependency closure carries `~Copyable & ~Escapable`
lifetime-dependent accessor projections use the carved invocation:

```sh
workspace package test --argument=--sanitize=thread \
  --argument=--scratch-path --argument=.build-tsan \
  --argument=-Xswiftc --argument=-Xllvm \
  --argument=-Xswiftc --argument=-sil-disable-pass=lifetime-dependence-diagnostics
```

`.build-tsan` is used for every sanitized invocation and never without
`--sanitize=thread`; sanitized and unsanitized artifacts never share a scratch. A seeded
race positive control rides every TSan gate with its expected nonzero report count
asserted — TSan reports do not fail swift-testing runs, so pass criteria count
`WARNING: ThreadSanitizer` lines, never test counts.

## Benchmarks

Benchmarks are an executable target in a nested `Benchmarks/` package with its own
coordinator-owned clean state, built and run in release:

```sh
workspace package build --argument=-c --argument=release
workspace package run   --argument=-c --argument=release
```

Never delete `.build` directly — `workspace package clean` from the benchmark root.

Required mechanics, none of which are guessable:

- `ContinuousClock` batch timing, with a per-sample floor of roughly 0.5 ms.
- `@inline(never)` opaque sources and sinks, with the sink printed at exit.
- Warmup batches plus at least nine timed samples, emitting the FULL per-sample vector
  (one `BENCH {json}` line per sample). Never hide variance behind a point estimate.
- Every recorded row reports median, worst within-run CV, and max cross-run spread over
  at least three separate process invocations.
- Recording windows are bracketed by process and load checks and gated on cross-run
  agreement: uniform inflation across all subjects is environment, and is excluded.
- A same-binary drift canary rides each recording window.

Store results under `.benchmarks/` relative to the benchmark root, gitignored. Every
recorded baseline that gates a decision states its derivation formula inline next
to the number, and a verifier quotes that formula before comparing numbers —
re-measuring without citing the definition is not verification.

When the consumer's access path layers a Copyable wrapper, enum-case extract, or
subscript indirection over raw storage, an isolated storage micro-benchmark is not
sufficient evidence for an architecture change: pair it with an integrated probe walking
the consumer's real call pattern at the workload's N distribution. Refcount-per-copy cost
is invisible to the isolated mode, and an integrated regression refutes the change
regardless of what the isolated mode shows. A `~Copyable` wrapper has no such term.

Benchmarks may be deferred for a surface that makes no performance claims; an empty
benchmark package is worse than none.
