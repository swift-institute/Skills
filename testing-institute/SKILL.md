---
name: testing-institute
description: |
  Nested package pattern for snapshot testing and swift-testing dependency isolation.
  ALWAYS apply when adding snapshot tests, #Tests macro scaffolding, or any
  tests requiring swift-testing features to ANY ecosystem package.

layer: process

requires:
  - swift-institute-core
  - testing
  - platform

applies_to:
  - swift
  - swift6
  - swift-primitives
  - swift-standards
  - swift-foundations
---

# Institute Testing via Nested Packages

The Swift Institute ecosystem has two testing layers:

| Layer | Framework | Features | Where |
|-------|-----------|----------|-------|
| Unit + Edge Case | Apple Testing (toolchain) | `@Test`, `@Suite`, `#expect` | Main `Package.swift` test targets |
| Snapshot + #Tests | swift-foundations/swift-testing | `#snapshot`, `#Tests` macro | Nested `Tests/` package |

The nested package pattern keeps the swift-testing dependency isolated from the parent `Package.swift`. This is mandatory for all ecosystem packages — even those that are not transitive dependencies of swift-testing — to maintain a uniform structure and prevent swift-testing from polluting the main dependency graph.

---

## When to Use

### [INST-TEST-001] Nested Package Requirement

**Statement**: ALL ecosystem packages MUST use the nested `Tests/Package.swift` package pattern for performance tests, snapshot tests, and any tests requiring swift-testing features. Direct dependencies on swift-testing in a package's main `Package.swift` are forbidden. The same isolation extends to ALL third-party test-only dependencies (e.g. `pointfreeco/swift-macro-testing`): they enter ONLY via the nested test package, never the main `Package.swift` (principal RULING 2026-07-10).

**Rationale**: Uniformity. Every package follows the same structure regardless of whether it's a transitive dependency of swift-testing. This keeps main `Package.swift` files clean, avoids pulling swift-syntax and the full swift-testing dependency graph into regular builds, and makes the testing approach discoverable and consistent across primitives, standards, and foundations.

**Rationale**: SwiftPM does not allow circular dependencies.

---

## Directory Structure

### [INST-TEST-002] Nested Package Location

**Statement**: The nested testing package MUST be located at `Tests/Package.swift` within the parent package. All test directories — both Apple Testing (unit) and swift-testing (performance, snapshot) — are flat siblings under `Tests/`.

**Statement**: The parent `Package.swift` MUST declare test targets with explicit `path:` parameters, since SwiftPM skips automatic target discovery in directories with their own `Package.swift`.

**Correct**:
```
swift-{package}/
  Package.swift                          # Parent — explicit path: for test targets
  Sources/
    {Module}/
  Tests/
    Package.swift                        # Nested — depends on parent + swift-testing
    {Module} Tests/                      # Apple Testing (unit + edge case)
    {Module} Performance Tests/          # swift-testing performance tests
      {Type} Performance Tests.swift
    {Module} Snapshot Tests/             # swift-testing snapshot tests
      {Type} Snapshot Tests.swift
      __Snapshots__/                     # Committed reference files
```

**Parent Package.swift** test target declaration:
```swift
.testTarget(
    name: "{Module} Tests",
    dependencies: [...],
    path: "Tests/{Module} Tests"         // explicit path required
)
```

**Rationale**: SwiftPM ignores subdirectories with their own `Package.swift` during automatic target discovery, but explicit `path:` overrides this. The flat sibling layout eliminates the `Tests/Testing/Tests/` stutter (validated by experiment `nested-package-source-ownership`). A single nested package avoids duplicating swift-syntax compilation (~40MB) across multiple nested packages.

---

### [INST-TEST-003] `#Tests` Macro Scaffolding (Recommended)

**Statement**: Packages that define their own types SHOULD use the `#Tests` macro for test scaffolding. This generates standardized suites including `.Performance` and `.Snapshot` with correct traits applied.

**Pattern**:
```swift
import Testing
@testable import {Module}

extension {Type} {
    #Tests(snapshots: .init(recording: .missing))
}

extension {Type}.Test.Performance {
    @Test(.timed(threshold: .milliseconds(50)))
    func `operation within budget`() {
        // ...
    }
}

extension {Type}.Test.Snapshot {
    @Test
    func `output format`() {
        #snapshot(instance.render(), as: .lines)
    }
}
```

**When `#Tests` does NOT apply**: Tests on stdlib types or protocols you don't own (e.g., `Sequence` extensions). Use manual `@Suite` instead.

**Rationale**: `#Tests` generates Unit/EdgeCase/Integration/Performance/Snapshot suites with `.serialized` and `.exclusive` traits pre-applied. Consistent scaffolding across the ecosystem.

---

## Package.swift Configuration

### [INST-TEST-004] Nested Package.swift Template

**Statement**: The nested `Package.swift` MUST declare dependencies on the parent package via `..` and on swift-testing via relative path. Test targets MUST use explicit `path:` parameters since the package root is `Tests/` (SwiftPM would otherwise look for targets in `Tests/Tests/`).

**Template**:
```swift
// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "testing",
    platforms: [
        .macOS(.v26),
    ],
    dependencies: [
        .package(path: ".."),
        .package(path: "{relative-path-to-swift-testing}"),
    ],
    targets: [
        .testTarget(
            name: "{Module} Performance Tests",
            dependencies: [
                .product(name: "{Module}", package: "swift-{package}"),
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "{Module} Performance Tests"
        ),
        .testTarget(
            name: "{Module} Snapshot Tests",
            dependencies: [
                .product(name: "{Module}", package: "swift-{package}"),
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "{Module} Snapshot Tests"
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    ]

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem
}
```

**Rationale**: Relative paths keep everything self-contained. Ecosystem Swift settings match parent conventions. Package name is always `testing`.

---

### [INST-TEST-005] Relative Path Calculation

**Statement**: Relative paths MUST be calculated from `Tests/` as the working directory.

| Parent Repo | Path to parent | Path to swift-testing |
|-------------|---------------|----------------------|
| `swift-primitives/swift-{pkg}/` | `..` | `../../../swift-foundations/swift-testing` |
| `swift-standards/swift-{pkg}/` | `..` | `../../../swift-foundations/swift-testing` |
| `swift-foundations/swift-{pkg}/` | `..` | `../../swift-testing` |

The parent package is always `..`.

**Rationale**: Incorrect relative paths cause "no package found" errors.

---

## Snapshot Tests

### [INST-TEST-008] Snapshot Test Structure

**Statement**: Snapshot tests SHOULD use `#snapshot` for assertions. Snapshot reference files are stored in `__Snapshots__/` relative to the test source and MUST be committed to version control.

**Inline snapshot** (expected value in source):
```swift
@Test
func `output format`() {
    #snapshot(instance.description, as: .lines)
    // First run records; subsequent runs compare
}
```

**Named file-backed snapshot**:
```swift
@Test
func `complex output`() {
    #snapshot(instance.render(), as: .lines, named: "rendered")
}
```

**Inline with explicit expected value** (trailing closure):
```swift
@Test
func `known output`() {
    #snapshot(value.description, as: .lines) {
        """
        expected output
        """
    }
}
```

**Recording modes**:

| Mode | Behavior |
|------|----------|
| `.missing` | Record new, compare existing (default) |
| `.all` | Always record/update (development) |
| `.failed` | Record on failure, still fail |
| `.never` | Compare only, fail if missing (CI) |

---

### [INST-TEST-009] Snapshot Configuration with `#Tests`

**Statement**: When using `#Tests`, snapshot recording mode SHOULD be configured in the macro call.

```swift
extension MyType {
    #Tests(snapshots: .init(recording: .missing))
}
```

**Rationale**: Centralizes snapshot configuration per type rather than scattering it across individual tests.

---

## Build Artifacts

### [INST-TEST-011] .gitignore

**Statement**: The nested `.build/`, `.swiftpm/`, and `.benchmarks/` directories SHOULD be excluded via `.gitignore`. The parent package's gitignore typically covers this already.

---

## Migration from `Tests/Testing/` (Legacy)

### [INST-TEST-012] Migration Procedure

**Statement**: Packages using the legacy `Tests/Testing/` pattern SHOULD migrate to `Tests/Package.swift`.

| Step | Action |
|------|--------|
| 1 | Move `Tests/Testing/Tests/{Module} * Tests/` → `Tests/{Module} * Tests/` |
| 2 | Move `Tests/Testing/Package.swift` → `Tests/Package.swift` |
| 3 | Update nested `Package.swift`: parent `../..` → `..`, swift-testing path loses one `../` |
| 4 | Add explicit `path:` to nested test targets (e.g., `path: "{Module} Snapshot Tests"`) |
| 5 | Add explicit `path:` to parent `Package.swift` test targets (e.g., `path: "Tests/{Module} Tests"`) |
| 6 | Remove old `Tests/Testing/` directory |
| 7 | Verify the structural split through the coordinator: `swift-build package test` from the parent runs unit tests only; the same action from `Tests/` runs performance + snapshot. Routine local runs go through the workspace test scheme ([PKG-BUILD-023]) |

**Rationale**: Eliminates the `Tests/Testing/Tests/` stutter and reduces `__Snapshots__/` path depth from 5 to 3 levels.

---

## Domain-Model Alignment

### [INST-TEST-013] Tests Structurally Mirror Source Domain Model

**Statement**: Test files MUST structurally mirror the source domain model. Each top-level `@Suite` is a SUBDOMAIN of a specific source-domain type, declared as an extension of that type. Test code MUST reference source-domain types directly without inventing local convenience typealiases. The canonical shape:

```swift
// In Tests/<TestTarget>/<SourceType>.<TestSubdomain>.swift:
extension <SourceType> {
    @Suite struct <TestSubdomain> {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
    }
}

// Tests live as members of the sub-suite, referencing source-domain types directly:
extension <SourceType>.<TestSubdomain>.Unit {
    @Test
    func `descriptive scenario name`() {
        let value = <SourceType>(...)       // ← direct source-type reference
        let offset = Tagged<...>.Offset(...) // ← direct, no local typealias
    }
}
```

**Forbidden patterns**:

```swift
// ❌ Top-level compound test struct (compound type name + compound suite name fire)
@Suite
struct FooTests {
    @Test func `something`() { ... }
}

// ❌ Local convenience typealias inside test struct (namespace adoption + typealiased namespace bridge fire)
@Suite
struct AffineSLITests {
    enum Element {}
    typealias Offset = Tagged<Element, Ordinal>.Offset  // ← parallel vocabulary, diverges from source

    @Test func `int bit pattern from vector positive`() { ... }
}

// ❌ Performance sub-suite (vestigial post-2026-05-15; performance work lives in
//    separate benchmark packages per the `benchmark` skill, not as a test
//    subdomain — `[TEST-005]` canonical set dropped Performance)
@Suite struct Performance {}
```

**Why**: Test code is a SUBDOMAIN of source code, not a separate vocabulary. Tests that establish parallel vocabulary (local typealiases for namespace adoption, compound names like `FooTests`, custom sub-suite categories) drift from source over time and become friction — source refactors break tests that didn't need to know about the refactor. Tests that mirror source stay aligned automatically: the same `Tagged<Element, Ordinal>.Offset` shape lives at both the source-declaration site and the test-reference site; renames at source propagate naturally.

**The convention's three load-bearing claims**:

1. **Extension-pattern at the file level** ([SWIFT-TEST-002]): the test struct is an extension of `<SourceType>`, named `<TestSubdomain>`. Both `compound type name` and `compound suite name` are satisfied by construction because there's no top-level compound `FooTests` decl.

2. **Three canonical sub-suites** ([TEST-005]): `Unit`, `` `Edge Case` ``, `Integration`. Performance is OUT of test-framework scope. Fixed categories enable cross-package grep-ability.

3. **Direct source-domain reference**: no local convenience typealiases. Test fixtures (phantom-tag enums, sample input values) live as nested members of the test subdomain; non-fixture references go straight to source.

**How to apply**:

| Source type lives at | Test subdomain extension target | Test file name |
|---|---|---|
| `swift-affine-primitives/Sources/Affine Primitives/Affine.Discrete.Vector.swift` | `extension Affine.Discrete.Vector { @Suite struct \`Standard Library Integration\` {} }` | `Tests/Affine Primitives Tests/Affine.Discrete.Vector+\`Standard Library Integration\`.swift` |
| `swift-cardinal-primitives/Sources/Cardinal Primitives/Cardinal.swift` | `extension Cardinal { @Suite struct Tests {} }` | `Tests/Cardinal Primitives Tests/Cardinal Tests.swift` |
| `swift-ordinal-primitives/Sources/Ordinal Primitives/Ordinal.Position.swift` | `extension Ordinal.Position { @Suite struct Tests {} }` | `Tests/Ordinal Primitives Tests/Ordinal.Position Tests.swift` |

**Generic-namespace / no-own-type carve-out**: the canonical `extension <SourceType> { @Suite struct <TestSubdomain> }` shape does not compile when `<SourceType>` is a generic namespace (`List<Element>`, `Memory.Small<let n: Int>`) — the `@Suite` macro emits a static stored property, which is illegal inside a generic type — and has no target when the package declares no own type (only constrained extensions, e.g. `extension Span.Protocol`). In these two cases the conforming shape is a top-level single-word `@Suite("Name") struct Tests` (NOT a compound `FooTests`), or an extension of a non-generic parent / `@_exported` namespace. Verify a proposed deviation with a `swiftc -typecheck` probe before committing to it. (Verified against list / memory-iterator / memory-small; Reflection 2026-06-26 swift-linter-closure-cadence-pivot.)


**Cross-references**: [TEST-005] (canonical sub-suite set), [SWIFT-TEST-002] (extension-pattern naming), [API-NAME-001] (Nest.Name namespace structure for the extension target), `benchmark` skill ([BENCH-*]) for the Performance carve-out.

---

## Cross-References

- **testing** skill — [TEST-*] for umbrella routing and test support infrastructure
- **testing-swiftlang** skill — [SWIFT-TEST-*] for Swift Testing framework patterns
- **benchmark** skill — [BENCH-*] for performance testing (.timed(), .build cleanup, comparison benchmarks)
- **platform** skill — [PLAT-ARCH-*] for Package.swift configuration
- Research: `swift-institute/Research/nested-testing-package-flattening.md`
- Research: `swift-institute/Research/nested-testing-package-structure.md`
- Experiment: `swift-institute/Experiments/nested-package-source-ownership/`
