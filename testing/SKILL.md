---
name: testing
description: Design, structure, and place Swift Institute tests and benchmarks — suite shape, nested test packages, snapshot tests, Swift Testing framework traps, and executable benchmark mechanics. Apply whenever writing, restructuring, or reviewing tests or performance measurement.
---

# Swift testing

Name the invariant, the input space, the observable result, and the failure signal before
choosing a fixture. Test through the narrowest interface that expresses the behavior, on the
boundary the behavior actually depends on — a same-target test cannot prove a cross-module
claim, however green it is. Prefer laws and reference models over repeated examples.

## Suite structure

Tests are a subdomain of the source domain, not a parallel vocabulary. Each top-level suite is
declared as an extension of the source type it covers:

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

Reference source types directly. No local convenience typealiases, no compound `FooTests`
top-level structs. Test fixtures — phantom-tag enums, sample values — live as nested members of
the test subdomain. Test names state the condition and the expected behavior in readable words;
do not repeat the suite or type name to imitate an XCTest method.

### The sub-suite names, and the split in them

`Unit`, `` `Edge Case` ``, and `Integration` are the hand-written set, and the reason to hold
to a fixed set is that it makes a cross-package search possible at all. Adding a fourth
category of your own defeats that for everyone.

That reason is currently half-defeated, and it is worth knowing before you search. The
Institute's own `#Tests` macro generates five suites — `Unit`, `EdgeCase`, `Integration`,
`Performance`, `Snapshot` — so the corpus carries two spellings of the edge-case suite and two
categories this section does not describe. A search for `` `Edge Case` `` misses every
macro-generated suite, and a search for `EdgeCase` misses the larger hand-written population.
Search for both, and do not "fix" one spelling into the other: the macro emits its own.

### Host types that break the extension pattern

Where the extension shape cannot compile or cannot be discovered, use a top-level single-word
backticked suite (`@Suite struct \`Index Tests\``) with the same sub-suites.

- Generic type, unspecialized (`extension Index { @Suite struct Test {} }`) — hard error,
  `@section cannot be used in a generic context`. Test bodies there are also generic, so a local
  `struct Tag {}` inside a test body will not compile either.
- Generic type at a concrete specialization (`extension Index<Int> { @Suite struct Test {} }`) —
  compiles and is SILENTLY never discovered. Nothing fails; the tests just do not run.
- Nested-in-generic types inherit the outer generic parameters and fail the same way.
- Protocol extension — `static stored properties not supported in protocol extensions`; the
  suite macro synthesizes static storage a protocol extension cannot host.
- A host type named `Protocol` (e.g. `RFC_791.Protocol`) — the `@Test` macro emits
  expression-position references where Swift's `.Protocol` metatype grammar hijacks the name
  even backticked.
- Packages that declare no type of their own, only constrained extensions.

Scope "this type already carries a `Test` suite" collision checks per test target: a same-named
suite in a sibling test target is not a collision, because extending a type nested in another
module's test target is illegal Swift anyway. When a backticked top-level name is already
claimed, append the new suite's distinguishing tokens rather than nesting deeper.

Verify any proposed deviation with a `swiftc -typecheck` probe before committing to it. The
list above is what has been hit, not what can be hit.

## Framework traps

- `#expect` copies its operands. Project a `~Copyable` value to a Copyable observation first;
  `#expect(value.property)` also synthesizes a receiver-copying property access, so bind the
  property to a local first.
- `== nil` on a `~Copyable` Optional does not work in `#expect` — binary comparison requires
  Copyable operands. Use `if let` / `guard` pattern matching.
- Two `await`s inside one `#expect` fails type inference. Extract each side to a `let` binding,
  then compare.
- `@Test` generates `@section`-attributed globals whose mangled names scale with nesting depth
  times test count; deep enough, the aggregate exceeds compiler thresholds and surfaces as a
  cryptic `@section` error. Drop to one suite per file and shorten the nesting suffix.
- Macro expansion tests validate the expansion, not whether the macro may be attached at a
  given site. Neither harness checks form-vs-site applicability, so macro coverage must include
  at least one real consumer site compiled through the coordinator.
- Prefer the generic macro-test support with a Swift Testing `failureHandler` routing to
  `Issue.record`; do not pull XCTest or Foundation in for fixture convenience.
- A mock produced by `unsafeBitCast` over a pointer-like `BitwiseCopyable` type must offset its
  tag away from zero. The all-zeros pattern is what `Optional<T>` reads as `.none`, so a
  zero-tagged mock is indistinguishable from "no value".
- Do not add copyability to a production API to satisfy a test macro.

**Main-actor isolation checks.** `pthread_main_np()` is Darwin-only, and on Linux the MainActor
executor does not necessarily run on the thread glibc considers the process's initial thread —
so a `@MainActor` body can report a non-main OS thread while genuinely running isolated. Do not
use it as a MainActor proxy. Capture the thread identity at the top of the `@MainActor` test
body and compare against it: the MainActor executor is a single fixed thread on both platforms,
so the captured identity is stable across suspension points, and no Foundation dependency is
needed either way.

## Test layout and dependencies

Test directories are flat siblings under `Tests/`. Test support is a `.library` product, never
a `.testTarget` — a test target cannot be consumed across packages. Product and target names
use spaces (`"Memory Primitives Test Support"`); imports use underscores (`import
Memory_Primitives_Test_Support`); the path is `Tests/Support`. Test support may depend on
production products; production products never depend on test support. Search for an existing
support product before adding helpers — reusable helpers live with the lowest layer that can
own them, package-specific fixtures stay local.

A package needing **test-only third-party dependencies** — macro-testing, snapshot support, a
driver for an integration test — puts them in a nested test manifest rather than the main one,
so a consumer resolving the package never pulls a test harness:

```
swift-<package>/
  Package.swift            # unit test targets, explicit path:
  Sources/<Module>/
  Tests/
    Package.swift          # depends on ".." — the parent package
    <Module> Tests/
    <Module> Snapshot Tests/
      __Snapshots__/       # committed
```

Most packages need no such manifest, and most do not have one: a `.testTarget` in the main
manifest links the toolchain's testing framework without declaring anything. Reach for the
nested manifest when a third-party test dependency appears, not before. The corpus is not
uniform here — some main manifests do carry macro- and snapshot-testing dependencies, so a
package you copy from may not be an example of this.

SwiftPM skips automatic target discovery in any directory containing its own `Package.swift`,
so both manifests need explicit `path:`. The parent uses `path: "Tests/<Module> Tests"`; the
nested manifest's root is `Tests/`, so its targets use `path: "<Module> Snapshot Tests"` —
without it SwiftPM looks in `Tests/Tests/`. The nested package is named `testing`, reaches its
parent as `.package(path: "..")`, mirrors the parent's upcoming-feature settings, and gitignores
the nested `.build/`, `.swiftpm/`, and `.benchmarks/`. Everything else it depends on is declared
by URL like any other dependency. A relative path to a sibling *package* resolves only on a
machine whose checkout happens to match, which is why the parent is the only one spelled that
way.

Snapshot references live in `__Snapshots__/` beside the test source and are committed.
Recording modes: `.missing` records new and compares existing (the default), `.all` always
records, `.failed` records on failure and still fails, `.never` compares only and fails when
missing — use `.never` in CI, where recording a snapshot means asserting nothing.

## Verification

Filter while iterating, then run the affected package fresh when reporting:

```sh
workspace package test --argument=--filter --argument "Behavior"
workspace package test --fresh
```

A filtered run proves only that filter. For what a run has to satisfy before it counts as
evidence — including why a gate covering `canImport`-conditional suites has to start from a
clean worktree — see the `workspace` skill.

TSan legs on packages whose dependency closure carries `~Copyable & ~Escapable`
lifetime-dependent accessor projections use the carved invocation:

```sh
workspace package test --argument=--sanitize=thread \
  --argument=--scratch-path --argument=.build-tsan \
  --argument=-Xswiftc --argument=-Xllvm \
  --argument=-Xswiftc --argument=-sil-disable-pass=lifetime-dependence-diagnostics
```

`.build-tsan` is used for every sanitized invocation and never without `--sanitize=thread`;
sanitized and unsanitized artifacts never share a scratch. A seeded race positive control rides
every TSan gate with its expected nonzero report count asserted — TSan reports do not fail
swift-testing runs, so pass criteria count `WARNING: ThreadSanitizer` lines, never test counts.

## Elsewhere

- Benchmark shape, mechanics, and when an isolated measurement is not evidence —
  [benchmarks.md](benchmarks.md).
