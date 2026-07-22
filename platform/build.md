# Platform — Swift 6 & Build Infrastructure

Swift 6 language mode, upcoming/experimental feature flags, fine-grained library exposure, the nested test-package pattern, parameter packs for n-ary types, memory-safety warnings as design feedback, and typed-throws-safe catch patterns, plus one non-rule subsection: Import Visibility as Module Contract.

**Rules in this file**: [PATTERN-002], [PATTERN-003], [PATTERN-005], [PATTERN-005a], [PATTERN-005b], [PATTERN-006], [PATTERN-007], [PATTERN-008], [PATTERN-009]

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/platform-skill-rationale.md` (the rationale archive).

---

### [PATTERN-002] Fine-Grained Library Exposure

**Statement**: Complex packages SHOULD expose multiple libraries for fine-grained dependency management.

```swift
// CORRECT
products: [
    .library(name: "Numeric Primitives", targets: ["Numeric Primitives"]),
    .library(name: "Real Primitives", targets: ["Real Primitives"]),
]

// INCORRECT — Single monolithic library
products: [
    .library(name: "Numeric Primitives", targets: [
        "Numeric Primitives", "Real Primitives", "Integer Primitives", "Complex Primitives",
    ]),
]
```

**Cross-references**: [API-LAYER-001], [PATTERN-001]

---

### [PATTERN-003] Nested Test Package Pattern

**Statement**: When packages face potential circular dependencies with swift-testing, the package MUST use nested test packages.

```text
swift-identity-primitives/
├── Package.swift                    # Main package (no test target)
└── Tests/
    └── Package.swift                # Separate package for tests
        └── depends on swift-testing
```

This breaks the cycle: `swift-testing` depends on primitives, but primitives' tests (in a separate package) depend on `swift-testing`.

**Lint enforcement**: Workflow `validate-package-shape.yml` shape-checks `Tests/Package.swift` when present (tools-version first line + at least one `.testTarget`); whether to adopt the pattern remains an authoring judgment. [VERIFICATION: WF validate-package-shape.py (PATTERN-003)]

**Cross-references**: [API-LAYER-001]

---

### [PATTERN-005] Swift 6 Language Mode

**Statement**: All packages MUST require Swift 6.3+ and use Swift 6 language mode.

```swift
// Package.swift
// swift-tools-version: 6.3
platforms: [.macOS(.v26), .iOS(.v26), .tvOS(.v26), .watchOS(.v26), .visionOS(.v26)]
swiftLanguageModes: [.v6]
```

All packages MUST support Darwin, Linux, Windows, POSIX, and Swift Embedded.

**Lint enforcement**: Workflow `validate-package-shape.yml` checks the tools-version first line (6.3+) and `swiftLanguageModes: [.v6]`. [VERIFICATION: WF validate-package-shape.py (PATTERN-005)]

**Cross-references**: [PATTERN-006], [PATTERN-005a]

---

### [PATTERN-005a] Memory Safety Warnings as Design Feedback

**Statement**: `#StrictMemorySafety` warnings MUST be treated as design feedback, not noise. Each warning marks a site requiring eventual `unsafe` annotation.

See **memory-safety** skill [MEM-SAFE-003] for warning classification (Bucket A vs Bucket B).

**Cross-references**: [PATTERN-005], [MEM-SAFE-003]

---

### [PATTERN-005b] Expression Granularity of Unsafe

**Statement**: Swift 6's strict memory safety operates at expression granularity. An `@unsafe` on a function declares *calling* is unsafe; operations *within* still require individual `unsafe` markers.

Key pattern: `unsafe (self.raw = value)` for assignments to unsafe storage.

See **memory-safety** skill [MEM-SAFE-002] for full details.

**Lint enforcement**: `Lint.Rule.Memory.UnsafeAssignmentGranularity` flags assignments whose RHS is a top-level `unsafe` expression — the canonical wrap is `unsafe (<lvalue> = <expr>)`. [VERIFICATION: AST Lint.Rule.Memory.UnsafeAssignmentGranularity]

**Cross-references**: [PATTERN-005], [MEM-SAFE-002]

---

### [PATTERN-006] Upcoming Feature Flags

**Statement**: Packages SHOULD enable upcoming Swift features for forward compatibility.

```swift
swiftSettings: [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
]
```

**Lint enforcement**: Workflow `validate-package-shape.yml` checks each Package.swift for the three required `enableUpcomingFeature(...)` calls. [VERIFICATION: WF validate-package-shape.py (PATTERN-006)]

**Cross-references**: [PATTERN-005], [PATTERN-007]

---

### [PATTERN-007] Experimental Feature Flags

**Statement**: Memory-critical packages MAY enable experimental features for compile-time resource verification.

```swift
swiftSettings: [
    .enableExperimentalFeature("Lifetimes"),
    .enableExperimentalFeature("LifetimeDependence"),
]
```

**Cross-references**: [PATTERN-006]

---

### [PATTERN-008] Parameter Packs for N-Ary Types

**Statement**: Packages requiring n-ary heterogeneous products SHOULD use Swift's parameter packs.

```swift
// CORRECT
struct Product<each Element> {
    var elements: (repeat each Element)
}

// INCORRECT — Type-erased
struct Product {
    var elements: [Any]
}
```

**Cross-references**: [API-IMPL-005]

---

### Import Visibility as Module Contract

Swift 6 enforces that types used in `@inlinable` declarations MUST be visible to clients.

| Import Style | Dependency Visible | Use When |
|--------------|-------------------|----------|
| `import` (internal) | No | Encapsulating implementation details |
| `public import` | Yes | Creating facade modules, re-exporting APIs |

Import visibility MUST be consistent across a module's files. Use `public import` only where `@inlinable` code references the module's types by name.

**Cross-references**: [PATTERN-006], [API-LAYER-001], [PLAT-ARCH-006]

---

### [PATTERN-009] Typed-Throws-Safe Catch Patterns

**Statement**: In catch blocks under typed throws, use the implicit `error` binding with `where` clauses — not `catch let error where`. The explicit `let` binding erases the concrete error type to `any Error`.

**Correct**:
```swift
do throws(IO.Error) {
    try operation()
} catch where error.isInterrupted {
    // `error` is IO.Error — concrete type preserved
}
```

**Incorrect**:
```swift
do throws(IO.Error) {
    try operation()
} catch let error where error.isInterrupted {
    // ❌ `error` is `any Error` — type erased
}
```

**Rationale**: `catch let error` introduces a new binding whose type is inferred as `any Error` regardless of the `do throws(E)` annotation. The implicit `error` binding inherits the typed error.

**Lint enforcement**: SwiftLint custom rule `no_typed_catch_let_error_where` catches `catch let error where`; AST counterpart `Lint.Rule.Throws.DoCatchTyped` flags untyped `do { try … } catch { … }`. [VERIFICATION: SwiftLint no_typed_catch_let_error_where, AST Lint.Rule.Throws.DoCatchTyped]

**Cross-references**: [API-ERR-001], [IMPL-075]

---

