---
name: testing
description: |
  Umbrella (skill-routing sense — distinct from [MOD-005] SwiftPM umbrella and [DOC-080] DocC umbrella):
  routing, test support infrastructure, file naming, suite categories.
  ALWAYS apply when writing or reviewing test code.

layer: implementation

requires:
  - swift-institute
  - code-surface

applies_to:
  - swift
  - swift6
  - primitives
  - standards
  - foundations
  - tests
---

# Testing Conventions

Umbrella skill for test organization across the Swift Institute ecosystem. Routes to specialized skills and defines shared infrastructure: test support modules, file naming, and suite categories.

---

## Skill Routing

| When you are... | Load |
|-----------------|------|
| Writing test suites, naming tests, ~Copyable/async patterns, model tests | **testing-swiftlang** [SWIFT-TEST-*] |
| Adding performance/snapshot tests, #Tests macro, nested package for swift-testing | **testing-institute** [INST-TEST-*] |
| Writing benchmarks, .timed() configuration, comparison benchmarks | **benchmark** [BENCH-*] |
| Setting up test support, file naming, suite categories | **this skill** [TEST-*] |

---

## Test Invocation

Local test runs go through the coordinator and the sole workspace ([PKG-BUILD-023]):

```bash
/Users/coen/Developer/swift-institute/Scripts/swift-build workspace test \
    --scheme "<Test Target>"
```

Clean environment — never set `TOOLCHAINS` locally. Package-level invocations
in the scoped SwiftPM contexts of [PKG-BUILD-024] (e.g. [TEST-036] clean-build
gates, [TEST-037] TSan) also run through the coordinator. Raw SwiftPM
invocations are confined to CI runners where the machine-wide local coordinator
is unavailable.

---

## Rule Index

One-line hooks for every rule in this skill. Numeric IDs are non-sequential due to historical append-only growth — this index is the navigation tool.

| ID | Topic | Hook |
|----|-------|------|
| [TEST-001] | Framework | Framework selection — Swift Testing, not XCTest |
| [TEST-005] | Suite organization | Test category suites (three standard categories) |
| [TEST-009] | File organization | Test file naming convention — `{TypePath} Tests.swift` |
| [TEST-010] | Test Support | Test Support target declaration |
| [TEST-018] | Test Support | Test Support literal conformances |
| [TEST-019] | Test Support | Test Support directory structure |
| [TEST-020] | Test Support | Re-export pattern |
| [TEST-021] | Test Support | Re-export chain architecture |
| [TEST-022] | Test Support | Test Support utility categories |
| [TEST-023] | Test Support | Creating a new Test Support module |
| [TEST-024] | Test Support | Nested Package.swift for circular dependencies |
| [TEST-025] | Test Support | Using Test Support — quick start |
| [TEST-026] | Test Support | Test Support module reference |
| [TEST-027] | Test target | Test target compilation gate |
| [TEST-028] | Mock factory | Null-pointer collision on BitwiseCopyable pointer-wrapping types |
| [TEST-029] | Test witness | Strategy-parameterized test witness factory |
| [TEST-030] | Concurrency-safety | Preserve assertion observation target under remediation |
| [TEST-031] | Cross-reference | Bidirectional link from existing-infrastructure to literal conformances |
| [TEST-035] | Coverage | Non-default-state coverage — wrap/head-offset states for ring-topology suites; move-only elements for ~Copyable-generic suites |

---

## Testing Framework

### [TEST-001] Framework Selection

**Statement**: All tests MUST use Swift Testing framework (not XCTest).

**Correct**:
```swift
import Testing

@Test
func `descriptive name`() { }
```

**Incorrect**:
```swift
import XCTest

class MyTests: XCTestCase {  // ❌ XCTest forbidden
    func testSomething() { }
}
```

**Lint enforcement**: `Lint.Rule.Framework.XCTest` (in `swift-foundations/swift-institute-linter-rules`, target `Linter Rule Framework`) walks `ImportDeclSyntax` and flags any import whose first path component equals `XCTest` (catches `import XCTest`, `import XCTest.XCTestCase`, `public import XCTest`, and any access-level variant). The rule fires on any file — both `Sources/` and `Tests/` — because no institute file has a legitimate reason to import XCTest. Co-defends `[PRIM-FOUND-001]` / `[ARCH-LAYER-007]` since XCTest pulls Foundation transitively. Added pilot 6 of `/promote-rule` 2026-05-14. [VERIFICATION: AST Lint.Rule.Framework.XCTest]

---

## Test Suite Organization

### [TEST-005] Test Category Suites

**Statement**: Test suites MUST include three standard categories. Additional semantic sub-suites MAY be added within categories.

| Suite | Purpose | Trait |
|-------|---------|-------|
| `Unit` | Isolated functionality tests | — |
| `` `Edge Case` `` | Boundary conditions, error paths | — |
| `Integration` | Cross-component behavior | — |

Performance benchmarking is OUT of the test-framework scope — the institute performs performance work in separate benchmark packages per the **benchmark** skill. The `Performance` sub-suite that earlier revisions of this rule required was dropped 2026-05-15; an existing `Performance` sub-suite MAY remain (the lint rule does not fire on extra sub-suites).

**Standard structure**:
```swift
@Suite struct Test {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
}
```

**With semantic sub-suites**:
```swift
extension Pointer.Arithmetic.Test {
    @Suite struct Basics {}
    @Suite struct Advance {}
    @Suite struct Distance {}
}
```

**Lint enforcement**: `Lint.Rule.Framework.SuiteCategories` (in `swift-foundations/swift-institute-linter-rules`, target `Linter Rule Framework`) walks `StructDeclSyntax` at source-file scope; for each top-level `@Suite struct X` declaration, it inspects the body and flags any whose nested members don't declare all three canonical sub-suites (`Unit`, `` `Edge Case` ``, `Integration`) via nested `@Suite struct` decls (matching `@Suite struct` and `@Suite(.serialized) struct` forms; backticked identifier names like `` `Edge Case` `` are normalized). Extension-form files (`extension Foo.Test.Unit`) are NOT flagged — they extend an existing Test namespace declared elsewhere and contribute tests without independently needing the three categories declared again. Per principal direction 2026-05-14, rules are valid in isolation and uniformly applied; ecosystem migrates to comply rather than rule relaxed to practice. Ecosystem state at ship time: **~876 missing-category findings across 268 of 302 repos with `Tests/`** — primarily packages that predate the convention. The validator ships in the institute-tier bundle and gates per-package CI via the existing `lint` job in `swift-ci.yml`. Added pilot 11 of `/promote-rule` 2026-05-14. [VERIFICATION: AST Lint.Rule.Framework.SuiteCategories]

---

## Test File Organization

### [TEST-009] File Naming Convention

**Statement**: Test files MUST be named `{TypePath} Tests.swift`, mirroring the type hierarchy.

**Correct**:
```
Tests/Memory Primitives Tests/
├── Memory.Buffer Tests.swift
├── Memory.Buffer.Mutable Tests.swift
├── Memory.Arena Tests.swift
└── Memory Arithmetic Tests.swift
```

**Incorrect**:
```
Tests/Memory Primitives Tests/
├── MemoryBufferTests.swift      // ❌ No space before "Tests"
├── BufferTests.swift            // ❌ Missing type hierarchy
└── AllMemoryTests.swift         // ❌ Combined tests
```

**Lint enforcement**: Reusable workflow `validate-file-naming.yml` + companion `.github/scripts/validate-file-naming.py` (the SAME script that enforces `[API-IMPL-006]`/`[API-IMPL-007]` for Sources/, extended pilot 9 to cover Tests/) walk each repo's `Tests/**/*.swift` and flag files whose basename ends with `Tests` but NOT ` Tests` (space before "Tests"). Carve-outs match the Sources/ patterns: skip `Tests/Support/`, `/Fixtures/`, hidden dirs, `Package.swift`/`exports.swift`, basenames with `+` (extension form), basenames containing ` where ` (where-clause shape), files whose basename doesn't end with `Tests` (fixture types in test directories). Ecosystem state at ship time (2026-05-14): **391 candidate violations across 128 repos** — primarily legacy XCTest-style compound names (`OrdinalPositionTests.swift`, `TaggedCardinalTests.swift`, `ChartTests.swift`). The validator gates per-package CI via the new `validate-file-naming` job in `swift-ci.yml`. Added pilot 9 of `/promote-rule` 2026-05-14. [VERIFICATION: WF validate-file-naming.py (TEST-009)]

**Cross-references**: [API-IMPL-005], [API-IMPL-006] (file-naming counterpart for source code)

---

## Test Support Infrastructure

### [TEST-025] Using Test Support — Quick Start

**Statement**: Tests MUST import their package's Test Support module to get literal conformances, factory methods, and transitive access to all upstream utilities. A single import replaces the need for manual type construction.

**The single import**:
```swift
import Memory_Primitives_Test_Support
```

This one import transitively provides: `Memory_Primitives`, `Index_Primitives_Test_Support`, `Vector_Primitives_Test_Support`, `Identity_Primitives_Test_Support`, `Ordinal_Primitives_Test_Support`, `Cardinal_Primitives_Test_Support`, and `Affine_Primitives_Test_Support` — every upstream module and its test utilities.

#### Index, Offset, and Count as Integer Literals

The most important capability Test Support provides is `ExpressibleByIntegerLiteral` for all `Tagged` types. Since `Index<T>`, `Index<T>.Offset`, `Index<T>.Count`, `Ordinal`, and `Cardinal` are all `Tagged`, you can write:

```swift
import Index_Primitives_Test_Support

private enum IntTag {}

@Test
func `advance index by positive offset`() {
    let index: Index<IntTag> = 5
    let offset: Index<IntTag>.Offset = 3
    let result = index.advanced(by: offset)
    #expect(result == 8)
}

@Test
func `count from range`() {
    let start: Index<IntTag> = 2
    let end: Index<IntTag> = 7
    let count: Index<IntTag>.Count = 5
    #expect(end - start == count)
}

@Test
func `negative offset`() {
    let offset: Index<IntTag>.Offset = -3
    #expect(offset == -3)
}

@Test
func `ordinal and cardinal`() {
    let ord: Ordinal = 1
    let card: Cardinal = 42
    #expect(ord.rawValue == 1)
    #expect(card.rawValue == 42)
}
```

**Without Test Support** (never do this in tests):
```swift
// ❌ Manual construction — verbose and obscures intent
let index = Index<IntTag>(position: Tagged(__unchecked: (), 5))
let offset = Index<IntTag>.Offset(Tagged(__unchecked: (), 3))

// ❌ Unwrapping through rawValue chains for comparison
#expect(index.position.rawValue == 5)
```

#### Comparison with Literals

Literal conformances also enable direct comparison with `#expect`:

```swift
let index: Index<IntTag> = 10
#expect(index == 10)        // ✅ Direct comparison
#expect(index != 0)         // ✅
#expect(index > 5)          // ✅ (if Comparable)

// ❌ Do not unwrap for comparison
#expect(index.position.rawValue == 10)  // ❌ Unnecessary
```

#### Bit.Index with Literals

```swift
import Bit_Index_Primitives_Test_Support

@Test
func `Bit.Index from byte index`() {
    let byteIndex: Index<UInt8> = 3
    let bitIndex = Bit.Index(byteIndex)
    #expect(bitIndex == 24)
}
```

#### Buffer Factory Methods

```swift
import Buffer_Primitives_Test_Support

@Test
func `ring buffer append and remove`() {
    var buffer = Buffer<Int>.Ring.with([10, 20, 30])
    #expect(buffer.count == 3)

    buffer.append(40)
    #expect(buffer.count == 4)
}

@Test
func `linear buffer from array`() {
    let buffer = Buffer<Int>.Linear.with([1, 2, 3, 4, 5])
    #expect(buffer.count == 5)
}

@Test
func `inline buffer`() {
    let buffer = Buffer<Int>.Linear.Inline<8>.with([10, 20, 30])
    #expect(buffer.count == 3)
}
```

#### Vectors from Swift Ranges

```swift
import Vector_Primitives_Test_Support

@Test
func `vector from Swift range`() {
    let vector = try Vector(0..<10) { $0 }
    #expect(vector.count == 10)
}

@Test
func `vector with transform`() {
    let vector = try Vector(0..<5) { $0 * 2 }
    // Produces: 0, 2, 4, 6, 8
}
```

#### Temporary Files and Directories

```swift
import File_System_Test_Support

@Test
func `write and read file`() throws {
    try File.temporary(extension: "txt") { path in
        try File.write("hello", to: path)
        let content = try File.read(from: path)
        #expect(content == "hello")
    }
    // Path automatically cleaned up
}

@Test
func `scoped temporary directory`() throws {
    try File.Directory.temporary { directory in
        let file = directory.appending("test.txt")
        try File.write("data", to: file)
        #expect(try File.exists(at: file))
    }
    // Directory automatically cleaned up
}
```

#### Thread Coordination Harnesses

```swift
import Kernel_Test_Support

@Test
func `thread coordination`() {
    let harness = Kernel.Thread.Test.Harness(0)
    let gate = Gate()
    let signal = Signal()

    // Thread: wait for gate, update state, signal completion
    Thread.detach {
        gate.wait()
        harness.update { $0 += 1 }
        signal.signal()
    }

    gate.open()
    signal.wait()
    harness.withLocked { #expect($0 == 1) }
}
```

#### Dependency Overrides

```swift
import Dependencies_Test_Support

@Suite(.dependencies)
struct `My Feature Tests` {
    @Test(.dependency(\.clock, .immediate))
    func `timer fires immediately`() {
        // clock dependency overridden to .immediate
    }

    @Test(.dependencies { $0.apiClient = .mock })
    func `uses mock API client`() {
        // apiClient dependency overridden
    }
}
```

---

### [TEST-026] Test Support Module Reference

**Statement**: This is the complete inventory of all Test Support modules and their unique API surface.

#### Primitives Layer — Literal Conformances

| Module | Unique API | What It Enables |
|--------|-----------|-----------------|
| **Identity Primitives TS** | 6 `ExpressibleBy*Literal` on `Tagged` (`@_disfavoredOverload`) | `let index: Index<T> = 5`, `let offset: Index<T>.Offset = -3`, `let count: Index<T>.Count = 10`, `let ord: Ordinal = 1`, `let card: Cardinal = 42` — and all other `Tagged` types |
| **Algebra Modular Primitives TS** | `@retroactive ExpressibleByIntegerLiteral` on `Tagged where Tag: Algebra.Residual` | `let z: Algebra.Z<5> = 3` |
| **Cyclic Primitives TS** | `ExpressibleByIntegerLiteral` on `Cyclic.Group.Static.Element` | `let g: Cyclic.Group.Static<5>.Element = 3` |

#### Primitives Layer — Factory Methods

| Module | Unique API |
|--------|-----------|
| **Buffer Primitives TS** | `Buffer.Ring: ExpressibleByArrayLiteral`. Factory methods: `Buffer.Ring.with(_:minimumCapacity:)`, `.Bounded.with(_:capacity:)`, `Buffer.Linear.with(...)`, `.Bounded.with(...)`, `Buffer.Slab.Bounded.with(...)`, `Buffer.Ring.Inline.with(...)`, `Buffer.Linear.Inline.with(...)`, `Buffer.Slab.Inline.with(...)` — all constrained to `Element == Int` |
| **Vector Primitives TS** | `Vector.init(_: Swift.Range<UInt>, transform:)`, `Vector.init(_: Swift.Range<Int>, transform:)`, `Vector.init(count:transform:)`, `Vector.init(start:end:transform:)` |

#### Primitives Layer — Pure Re-Export Aggregators

These modules provide no unique API — they exist to aggregate upstream re-exports into a single import:

| Module | Re-Exports |
|--------|-----------|
| **Cardinal Primitives TS** | Cardinal Primitives |
| **Ordinal Primitives TS** | Ordinal Primitives, Cardinal TS |
| **Affine Primitives TS** | Affine Primitives, Ordinal TS, Cardinal TS |
| **Index Primitives TS** | Identity TS, Ordinal TS, Cardinal TS, Affine TS |
| **Memory Primitives TS** | Memory Primitives, Index TS, Vector TS |
| **Storage Primitives TS** | Storage Primitives, Memory TS |
| **Bit Primitives TS** | Identity TS |
| **Bit Index Primitives TS** | Bit TS, Index TS |
| **Bit Pack Primitives TS** | Bit Index TS |
| **Bit Vector Primitives TS** | Bit Pack TS |
| **Cyclic Index Primitives TS** | Cyclic Index Primitives, Cyclic TS, Index TS |
| **Collection Primitives TS** | Index TS |
| **Finite Primitives TS** | Finite Primitives, Index TS |
| **Hash Table Primitives TS** | Hash Table Primitives, Index TS |
| **Set Primitives TS** | Bit TS, Index TS |
| **Vector Primitives TS** | Vector Primitives, Index TS |
| **Binary Primitives TS** | Binary Primitives, Memory TS, Bit TS |
| **Binary Parser Primitives TS** | Binary Parser Primitives, Binary TS, Index TS, Serialization Primitives, Parser Primitives |

#### Standards Layer

| Module | Unique API |
|--------|-----------|
| **ISO 9945 Kernel TS** | `Kernel.Thread.Test.Harness<State>` (condvar coordination: `update`, `wait`, `withLocked`). `Locked.Box<T>` (mutex-protected box). `Gate` (condition-based barrier). `Signal` (one-shot handshake). `Kernel.Event.Test` (pipe helpers: `makePipe`, `writeByte`, `readDrain`). `Kernel.Temporary` (temp dir/file paths). `Kernel.IO.Test` (temp file lifecycle: `temporary(...)`, `temporary(content:...)`). Lock Helper executable (multi-process lock contention). |

#### Foundations Layer

| Module | Unique API |
|--------|-----------|
| **Kernel TS** | `expectThrows<E,R>(_:_:)` (typed-throws assertion). Same harness/primitives as ISO 9945 TS but targeting foundations `Kernel` module. Re-exports: Kernel Primitives TS. |
| **IO TS** | `Thread.Pool.Testing.idle.wait(...)`. `IO.Benchmark.Fixture` (standardized thread pool for benchmarks). `IO.Blocking.Threads.checkSubmit()`. `IO.Blocking.Lane.runImmediate(...)`. `Barrier` typealias. Re-exports: Kernel TS. |
| **File System TS** | `File.Directory.Temporary.Scope` (scoped temp dir with cleanup). `File.Temporary` (scoped temp file). `Test.Delay.milliseconds(...)`. `Test.Retry.withDelay(...)`. `Glob.Test.create(in:)`. |
| **Parsers TS** | Snapshot testing utilities. Located at `Sources/Parsers Test Support/`. |
| **Dependencies TS** | `Dependency.Test.withOverrides(...)`. `assertMode(...)`, `assertValue(...)`. `__DependencyTestTrait` (suite/test trait for dependency isolation: `.dependencies`, `.dependency(_:_:)`). |

---

### [TEST-010] Test Support Target Declaration

**Statement**: Packages MAY provide a `{Module} Test Support` library for shared test utilities. Test Support MUST be declared as a `.target()` (regular library), NOT a `.testTarget()`. This enables cross-package consumption.

**Package.swift**:
```swift
products: [
    .library(
        name: "Memory Primitives Test Support",
        targets: ["Memory Primitives Test Support"]
    ),
],
targets: [
    .target(
        name: "Memory Primitives Test Support",
        dependencies: [
            "Memory Primitives",
            .product(name: "Index Primitives Test Support", package: "swift-index-primitives"),
            .product(name: "Vector Primitives Test Support", package: "swift-vector-primitives"),
        ],
        path: "Tests/Support"
    ),
    .testTarget(
        name: "Memory Primitives Tests",
        dependencies: [
            "Memory Primitives",
            "Memory Primitives Test Support",
        ]
    ),
]
```

**Key rules**:
- Product name and target name use **spaces**: `"Memory Primitives Test Support"`
- Import statements use **underscores**: `import Memory_Primitives_Test_Support`
- Path is **always** `"Tests/Support"`
- Dependencies include the package's **own main module** AND **upstream Test Support modules**
- Test targets depend on **both** the main module and its Test Support

**Incorrect**:
```swift
.testTarget(                              // ❌ testTarget cannot be consumed cross-package
    name: "Memory Primitives Test Support",
    ...
)
```

**Cross-references**: [MOD-011] (product declaration counterpart), [CONV-007] (re-export chain and literal conformances)

---

### [TEST-019] Test Support Directory Structure

**Statement**: Test Support MUST use the two-file pattern at `Tests/Support/`: an `exports.swift` for re-exports and a `{Name} Test Support.swift` for utilities.

**Standard layout**:
```
Tests/Support/
├── exports.swift                              // @_exported re-imports
└── Memory Primitives Test Support.swift       // Shared utilities
```

**Multiple utility files** (when needed):
```
Tests/Support/
├── exports.swift
├── Buffer Primitives Test Support.swift       // Factory methods
└── Buffer.Ring+ArrayLiteral.swift             // Specific conformance
```

**Incorrect**:
```
Tests/Memory Primitives Tests/Support/         // ❌ Not inside test target dir
Sources/Memory Primitives Test Support/        // ❌ Not at Tests/Support (exceptions exist)
```

---

### [TEST-020] Re-Export Pattern

**Statement**: `exports.swift` MUST use `@_exported public import` to transitively re-export all upstream Test Support modules. MAY also re-export the package's own main module.

**Correct** (`exports.swift`):
```swift
@_exported public import Memory_Primitives
@_exported public import Index_Primitives_Test_Support
@_exported public import Vector_Primitives_Test_Support
```

**Effect**: A test file that imports `Memory_Primitives_Test_Support` transitively receives:
- `Memory_Primitives` (main module)
- `Index_Primitives_Test_Support` (and its chain: Identity, Ordinal, Cardinal, Affine)
- `Vector_Primitives_Test_Support` (and its chain)

**Incorrect**:
```swift
import Index_Primitives_Test_Support           // ❌ Missing @_exported — not transitive
public import Index_Primitives_Test_Support    // ❌ Missing @_exported — not transitive
```

---

### [TEST-021] Re-Export Chain Architecture

**Statement**: Test Support modules form a directed acyclic graph mirroring the package dependency graph. Each module re-exports its upstream Test Supports, creating a single-import experience for test consumers.

**Primitives re-export chain**:
```
Identity Primitives Test Support (root — literal conformances for Tagged)
    ↓
Index Primitives Test Support (hub — re-exports Identity, Ordinal, Cardinal, Affine)
    ↓                    ↓                          ↓
Vector Primitives TS   Cyclic Index Primitives TS   Collection Primitives TS
    ↓                    ↓
Memory Primitives Test Support (re-exports Index TS, Vector TS)
    ↓
Storage Primitives Test Support (re-exports Memory TS)
    ↓
Buffer Primitives Test Support (re-exports Storage TS, Cyclic Index TS, Bit Vector TS)
```

**Cross-layer chain** (Primitives → Standards → Foundations):
```
Kernel Primitives Test Support (primitives)
    ↓
ISO 9945 Kernel Test Support (standards)
    ↓
Darwin Kernel Primitives Test Support (primitives — re-exports both above)
    ↓
Kernel Test Support (foundations — re-exports Kernel Primitives TS)
    ↓
IO Test Support (foundations — re-exports Kernel TS)
```

**Consequence**: A test importing `Buffer_Primitives_Test_Support` transitively receives literal conformances, index utilities, memory helpers, and every upstream Test Support API — from a single import.

---

### [TEST-018] Test Support Literal Conformances

**Statement**: Tests MUST use literal conformances from Test Support for primitives type construction and comparison.

**Source**: `Identity_Primitives_Test_Support` provides `ExpressibleByIntegerLiteral` (and other literal protocols) for `Tagged`. Since `Index<T>`, `Ordinal`, `Cardinal`, etc. are all `Tagged` types, this single conformance enables literal syntax for the entire type hierarchy.

```swift
// In Identity Primitives Test Support:
extension Tagged: ExpressibleByIntegerLiteral
where Tag: ~Copyable, RawValue: ExpressibleByIntegerLiteral {
    @_disfavoredOverload
    public init(integerLiteral value: RawValue.IntegerLiteralType) {
        self = .init(__unchecked: (), RawValue(integerLiteral: value))
    }
}
```

**`@_disfavoredOverload`**: Prevents the test-only literal conformance from being preferred over more specific initializers in production code.

**Available when importing any Test Support that re-exports Identity Primitives Test Support**:

| Type | Literal Example |
|------|-----------------|
| `Index<T>` | `let index: Index<Int> = 5` |
| `Index<T>.Offset` | `let offset: Index<Int>.Offset = -3` |
| `Index<T>.Count` | `let count: Index<Int>.Count = 10` |
| `Ordinal` | `let ord: Ordinal = 1` |
| `Cardinal` | `let card: Cardinal = 42` |

**Correct**:
```swift
let index: Index<Int> = 5
#expect(index == 5)
#expect(index.position == 5)

var i = 0
(.zero..<count).forEach { index in
    storage.initialize(to: i * 10, at: index)
    i += 1
}
```

**Incorrect**:
```swift
#expect(index.position.rawValue == 5)  // ❌ Unwrapping when literals available
storage.initialize(to: Int(bitPattern: index.position.rawValue) * 10, at: index)  // ❌
```

**Cross-references**: [PATTERN-017], [CONV-007], [CONV-008]

---

### [TEST-028] Mock Factory — Null-Pointer Collision on `BitwiseCopyable` Pointer-Wrapping Types

**Statement**: When a Test Support module provides a `.mock(_:)` factory that produces values via `unsafeBitCast(Int, to: T.self)` for a `BitwiseCopyable` pointer-wrapping type (e.g., `UnownedJob`, `Unmanaged<X>`, and other pointer-interpretable types), the factory MUST offset input tags by at least 1 — i.e., `unsafeBitCast(tag &+ 1, to: T.self)` — because `Optional<T>` uses the all-zeros bit pattern as `.none` for pointer-like `T`. Producing a mock with tag 0 creates a value that any `Optional<T>` path will read as `.none`, breaking tests that expect the mock to be distinguishable from "no value."

**Correct**:
```swift
extension UnownedJob {
    public static func mock(_ tag: Int = 0) -> UnownedJob {
        // Offset so tag 0 does not collide with Optional<UnownedJob>'s .none representation
        unsafeBitCast(tag &+ 1, to: UnownedJob.self)
    }
}
```

**Incorrect**:
```swift
extension UnownedJob {
    public static func mock(_ tag: Int = 0) -> UnownedJob {
        unsafeBitCast(tag, to: UnownedJob.self)  // ❌ tag 0 → Optional sees .none
    }
}
```

**Scope**: applies to any `BitwiseCopyable` type that Swift treats as pointer-like for layout optimization — the Optional null-pointer optimization is a general stdlib optimization, not specific to `UnownedJob`. Any test that creates values via `unsafeBitCast(Int, to: T.self)` must avoid tag 0 for such types.

**Cross-references**: [TEST-018], [TEST-026]

**Lint enforcement**: `Lint.Rule.Testing.MockFactoryZeroCollision` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Testing`) flags `unsafeBitCast(...)` calls whose first argument is a bare identifier (no `&+ 1` / `+ 1` / `+ N` offset). False positives where the bitcast target is genuinely not pointer-like are suppressed via disable-comment. Added 2026-05-10 (Wave 2b finalization Batch 6).

---

### [TEST-022] Test Support Utility Categories

**Statement**: Test Support utilities fall into four categories. Each category has specific conventions.

#### Category 1: Literal Conformances

Provide `ExpressibleBy*Literal` for types that don't have them in production (to keep production APIs strict).

```swift
// Identity Primitives Test Support — root of all literal conformances
extension Tagged: ExpressibleByIntegerLiteral
where Tag: ~Copyable, RawValue: ExpressibleByIntegerLiteral {
    @_disfavoredOverload
    public init(integerLiteral value: RawValue.IntegerLiteralType) {
        self = .init(__unchecked: (), RawValue(integerLiteral: value))
    }
}
```

#### Category 2: Factory Methods and Convenience Constructors

Provide ergonomic construction for test data.

```swift
// Buffer Primitives Test Support
extension Buffer.Ring: ExpressibleByArrayLiteral { ... }

extension Buffer.Ring where Element == Int {
    public static func with(
        _ elements: [Int],
        minimumCapacity: UInt = 0
    ) -> Self { ... }
}
```

#### Category 3: Test Harnesses

Provide reusable coordination infrastructure for complex test scenarios (e.g., threading, I/O).

```swift
// ISO 9945 Kernel Test Support
extension Kernel.Thread.Test {
    public final class Harness<State: Sendable>: @unchecked Sendable {
        public func update(_ body: (inout State) -> Void) { ... }
        public func wait(until predicate: (State) -> Bool) throws(Timeout) { ... }
    }
}
```

#### Category 4: Temporary Resource Helpers

Provide safe setup/teardown for file system, I/O, and other resource-based tests.

```swift
// Kernel Test Support
extension Kernel.Temporary {
    public static var directory: Swift.String { ... }
    public static func filePath(prefix: Swift.String) -> Swift.String { ... }
}

// File System Test Support
extension File {
    public struct Temporary: Sendable {
        public func callAsFunction<T>(
            _ body: (File.Path) throws -> T
        ) throws -> T { ... }
    }
}
```

---

### [TEST-023] Creating a New Test Support Module

**Statement**: When creating a new Test Support module, follow this checklist.

**Step 1** — Create directory:
```
mkdir Tests/Support
```

**Step 2** — Create `exports.swift` with re-exports of all upstream Test Supports:
```swift
@_exported public import Your_Module
@_exported public import Upstream_Primitives_Test_Support
```

**Step 3** — Create `{Name} Test Support.swift` with package-specific utilities:
```swift
public import Your_Module

// Literal conformances, factory methods, harnesses, etc.
```

**Step 4** — Add to `Package.swift`:
```swift
// In products:
.library(
    name: "Your Module Test Support",
    targets: ["Your Module Test Support"]
),

// In targets:
.target(
    name: "Your Module Test Support",
    dependencies: [
        "Your Module",
        .product(name: "Upstream Primitives Test Support", package: "swift-upstream-primitives"),
    ],
    path: "Tests/Support"
),
```

**Step 5** — Add Test Support as a dependency of the test target:
```swift
.testTarget(
    name: "Your Module Tests",
    dependencies: [
        "Your Module",
        "Your Module Test Support",
    ]
),
```

**Step 6** — Import from test files:
```swift
import Your_Module_Test_Support
// Transitively provides: Your Module + all upstream Test Support APIs
```

---

### [TEST-024] Nested Package.swift for Circular Dependencies

**Statement**: When a package and `swift-testing` have a circular dependency, tests MUST use a nested `Tests/Package.swift` to break the cycle.

**Layout**:
```
swift-render-primitives/
├── Package.swift              // Main package — no swift-testing dependency
└── Tests/
    ├── Package.swift          // Separate SPM resolution scope
    ├── Support/
    └── Render Primitives Snapshot Tests/
```

**Nested `Tests/Package.swift`**:
```swift
let package = Package(
    name: "testing",
    dependencies: [
        .package(path: ".."),
        .package(url: "https://github.com/swift-foundations/swift-testing.git", branch: "main"),
    ],
    targets: [
        .testTarget(
            name: "Render Primitives Snapshot Tests",
            dependencies: [
                .product(name: "Render Primitives", package: "swift-render-primitives"),
                .product(name: "Render Primitives Test Support", package: "swift-render-primitives"),
                .product(name: "Testing", package: "swift-testing"),
            ],
        ),
    ],
)
```

**Scope**: the nested-package pattern is mandatory for ALL ecosystem packages per [INST-TEST-001] (testing-institute) — the circular-dependency case above is the origin motivation, not the boundary.

---

### [TEST-027] Test Target Compilation Gate

**Statement**: Test target compilation errors MUST be fixed before committing changes to the same package, even if the errors are pre-existing. A non-compiling test target masks new bugs introduced by the current change.

**Cross-references**: [TEST-001]

---

### [TEST-029] Strategy-Parameterized Test Witness Factory

**Statement**: When tests must exercise multiple backends of a strategy-pattern type (e.g., IO.Blocking vs IO.Events vs IO.Completions), the canonical approach is a single backend-opaque factory function on the Test Support target that returns a real-I/O witness conditional on the current platform. Tests call the factory once and exercise the strategy without discovering backend details.

**Factory shape**:

```swift
public func completionsTest() -> some IO.Completions.Witness {
    #if canImport(IOUringPrimitives)
    return IO.Completions.Witness.uring(shared: true)
    #elseif canImport(KqueuePrimitives)
    return IO.Completions.Witness.kqueue(shared: true)
    #else
    return IO.Completions.Witness.fake()
    #endif
}
```

**Non-goals**: The factory MUST NOT expose per-backend configuration. Tests that need backend-specific behavior (e.g., Linux-only IOPS ceilings) belong in backend-specific suites, not in strategy-parameterized tests.

**Cross-references**: [TEST-001], [IMPL-099]

---

### [TEST-030] Preserve Assertion Observation Target Under Concurrency-Safety Remediation

**Statement**: When a strict-concurrency-safety error (`[#MutableGlobalVariable]`, `@Sendable`, region transfer) forces removing observable state from a test fixture, the replacement MUST preserve the assertion's observation target via an alternative mechanism: `weak` reference, `Atomic`, `Mutex`-protected state, or `sending`-parameter stage-in. The replacement MUST NOT degrade the test into a "didn't crash" smoke test.

**Procedure**:

1. Identify what the original test was asserting (not just what it was observing).
2. Identify which value the concurrency-safety error forbids observing.
3. Choose a mechanism that makes the needed value observable without violating concurrency safety.
4. After remediation, count `#expect` calls in the file. If the count decreased, the assertion target is likely lost — investigate before committing.

**Cross-references**: [TEST-001], [MEM-SEND-*]

---

### [TEST-031] Cross-Reference from Existing-Infrastructure to Literal Conformances

**Statement**: The existing-infrastructure catalog entries for `Memory.Address`, `Memory.Address.Count`, `Kernel.File.Offset` and similar typed values MUST cross-reference the test-support literal conformances ([TEST-018]) so that a reader looking up the primitive's tests arrives at the literal-construction shortcut. Absent the cross-reference, tests construct typed values via long-form initializers the ecosystem provides a shortcut for.

**Cross-references**: [TEST-018], [INFRA-*]

---

## Cross-References

See also:
- **testing-swiftlang** skill — [SWIFT-TEST-*] for Swift Testing framework patterns
- **testing-institute** skill — [INST-TEST-*] for nested package pattern and snapshots
- **benchmark** skill — [BENCH-*] for performance testing patterns
- **code-surface** skill — [API-NAME-001] Nest.Name pattern, [API-IMPL-005] one type per file
- **conversions** skill — [CONV-007], [CONV-008] literal conformance usage

---

### [TEST-032] Extension Inits and Static Properties for Test Fixtures

**Statement**: Test fixtures and factory helpers that produce instances of a domain type MUST be authored as `extension Type { init(...) }` overloads (or `static let` / `static var` for singletons) on the type itself, NOT as free functions in the test file.

**Correct**:
```swift
extension Time {
    static let test = Time(seconds: 1234567890)

    init(testHour: Int, testMinute: Int) {
        self.init(seconds: testHour * 3600 + testMinute * 60)
    }
}

@Test func parsesEpochSeconds() {
    let parsed = Time.parse("1234567890")
    #expect(parsed == .test)
}
```

**Incorrect**:
```swift
func makeTestTime(hour: Int, minute: Int) -> Time {  // ❌ free function
    Time(seconds: hour * 3600 + minute * 60)
}
```

**Why**: Factory methods authored as extension inits are discoverable through the type they construct (`Time.` autocomplete shows them) and follow the same API design principles as production code per [API-IMPL-005] / [PATTERN-012]. Free functions in test files lose this discoverability and create per-suite namespaces that drift over time.

**For generic types**: constrain the extension to the test specialization. `extension Pool where Resource == Int { init(testCapacity: Int) { ... } }`.

**For singletons**: `static let test`, `static let testEmpty`, etc. — no need to construct each call site.

**Cross-references**: [API-IMPL-005], [PATTERN-012], [TEST-001]

---

### [TEST-033] Test Target Per Source Target

**Statement**: A package with multiple source targets MUST declare one test target per source target. Bundled test targets that exercise multiple source targets are forbidden.

**Naming**: `Tests/<Source Target> Tests/` — preserve the source target's exact directory name (including spaces and casing) with ` Tests` suffix.

**Correct** (package with source targets `Serializer Namespace`, `Serializer Primitives Core`, `Serializer Map Primitives`):

```
Tests/
  Serializer Namespace Tests/
    Serializer Tests.swift
  Serializer Primitives Core Tests/
    Serializer.Protocol Tests.swift
  Serializer Map Primitives Tests/
    Serializer.Map Tests.swift
```

**Incorrect**:

```
Tests/
  Serializer Primitives Tests/          // ❌ bundles multiple source targets
    Serializer Tests.swift
    Serializer.Protocol Tests.swift
    Serializer.Map Tests.swift
```

**Why**: Bundled test targets can mask link failures specific to sub-target witness paths. When a test imports both `Serializer_Namespace` and `Serializer_Map_Primitives` through a bundled target, the bundle's compilation context resolves cross-target conformance witnesses in ways that may differ from how a downstream consumer would resolve them. Per-source-module targets force each target's witness emission to be exercised independently, catching cross-target regressions before they reach downstream packages.

**Cross-references**: [TEST-001], [TEST-009], [MOD-024]

---

### [TEST-034] Combinator-Family Test Form: Direct Method for Correctness, `var body` for Composition

**Statement**: For types conforming to a combinator-family protocol (`Parser.Protocol`, `Serializer.Protocol`, `Coder.Protocol`), tests MUST use the direct method form (`.parse(_:)`, `.serialize(_:into:)`) for correctness/functionality assertions and SHOULD use the `var body` declarative composition form for representative-usage and integration tests.

**Direct method form** (correctness):

```swift
@Test func parsesDigits() {
    let parser = Parser.Many { Parser.Digit() }
    var input: Substring = "42abc"
    let result = try parser.parse(&input)
    #expect(result == [4, 2])
    #expect(input == "abc")
}

@Test func serializesPrefix() {
    let serializer = Serializer.Literal<[UInt8]>("prefix:")
    var buffer: [UInt8] = []
    try serializer.serialize((), into: &buffer)
    #expect(buffer == Array("prefix:".utf8))
}
```

**`var body` composition form** (representative usage):

```swift
struct GreetingSerializer: Serializer.`Protocol` {
    typealias Output = Void
    typealias Buffer = [UInt8]
    typealias Failure = Never

    var body: some Serializer.`Protocol`<Void, [UInt8], Never> {
        Serializer.Literal<[UInt8]>("hello, ")
        Serializer.Literal<[UInt8]>("world")
    }
}

@Test func declarativeCompositionRoundTrips() {
    var buffer: [UInt8] = []
    try GreetingSerializer().serialize((), into: &buffer)
    #expect(buffer == Array("hello, world".utf8))
}
```

**Why the split**:

1. **Direct method form exercises the witness-table dispatch path.** The protocol's `parse(_:)` / `serialize(_:into:)` requirement is the structural correctness surface — what every conformer must implement and what callers ultimately invoke. Direct-method tests verify the leaf-level behavior is correct AND that the witness-table emission is complete (catches link-time regressions that bundled tests can mask, per [TEST-033]).
2. **`var body` form exercises declarative composition** — the primary user-facing surface for non-trivial parsers/serializers. It verifies the result-builder dispatch, default `parse`/`serialize` delegation to body, and the typealias bindings (`Output`, `Buffer`, `Failure`, `Body`) all compose correctly.
3. **Without both, coverage has gaps.** Tests that only call direct methods miss result-builder regressions. Tests that only exercise `var body` may hide bugs in the leaf-level method dispatch.

**Test target organization** (composes with [TEST-033]): each source target's test target SHOULD include a mix — at minimum one direct-method test (Unit) and one `var body` composition test (Integration) — per combinator type.

**Exemption**: Tests for combinator-family infrastructure (e.g., `Builder.swift` itself, `Protocol+map.swift` extension methods) are inherently structural and need not use the `var body` form. The rule targets tests for concrete combinator TYPES (`Parser.Map`, `Serializer.Filter`, `Coder.Witness`, etc.).

**Cross-references**: [TEST-001], [TEST-005], [TEST-033]

---

### [TEST-035] Non-Default-State Coverage — Exercise the States That Unmask Constraint and Addressing Defects

**Statement**: A suite for a state-dependent or suppression-generic API MUST exercise the non-default states in which known defect classes become observable — not only the default construction path. Two mandatory instances:

| API class | Default state (masks) | Required non-default coverage | Defect class unmasked |
|-----------|----------------------|-------------------------------|----------------------|
| Wrap-capable containers (ring topologies, head-offset layouts) | head == 0, fill-from-empty: physical slots coincide with the logical prefix | Iterate/read in WRAPPED and HEAD-OFFSET states (head > 0, count < capacity) | Count-bounded reads of capacity-domain slots ([MEM-SPAN-004]) |
| `~Copyable`-generic APIs | Copyable elements: a wrongly re-imposed `Copyable` constraint is satisfied | Instantiate with MOVE-ONLY elements (suites + fixtures) | Silent suppression re-imposition on extensions/refinements/conformances ([MEM-COPY-004]) |

In both rows the masking is structural, not statistical: the default state satisfies the wrongly-imposed constraint or the coincident addressing **by construction**, so the suite passes WITH the defect present. This is a state-space requirement, not a coverage-percentage requirement.

**Correct (ring family — wrap-state coverage)**:
```swift
@Test func consumingScalarOverWrappedRing() {
    var ring = Buffer<Storage<Int>.Heap>.Ring(minimumCapacity: 4)
    // Drive into the wrapped state: head > 0, front segment physically ABOVE count
    ring.push(1); ring.push(2); ring.push(3); ring.push(4)
    _ = ring.pop(); _ = ring.pop()
    ring.push(5); ring.push(6)            // wraps: physical slots ∈ [count, capacity)
    #expect(ring.contains(5))             // exercises the consuming-iteration path while wrapped
}
```

**Incorrect (suite shape)**: every test fills from empty and iterates at head == 0 — the wrapped/offset states the structure exists to support are never entered, so any prefix-bounded read inside a witness passes every test.

**Cross-references**: [TEST-005] (category suites — these states live in Unit/Integration categories), [MEM-SPAN-004], [MEM-COPY-004]

---

### [TEST-036] Clean Build Is the Gate of Record for `canImport`-Gated Suites

**Statement**: A gate whose evidence covers `#if canImport(...)`-conditioned test suites MUST run from a clean git worktree after `swift-build package clean`; direct `.build` deletion is forbidden. `canImport` conditions do NOT re-evaluate on incremental builds: a suite rejoined by a dependency change stays silently EXCLUDED from a green incremental run, so the run under-counts without failing.

**Procedure**: clean-build for the gate of record; incremental runs are development convenience only. Where suite counts are the claim, the count comparison MUST come from the clean log.

**Cross-references**: [TEST-035] (suite-reach honesty), the seat verification protocol (HANDOFF-tower-SEAT.md).

---

### [TEST-037] The Carved TSan Gate

**Statement**: TSan legs on packages whose dependency closure carries `~Copyable & ~Escapable` lifetime-dependent accessor projections run under the CARVED invocation — `swift-build package test -- --sanitize=thread --scratch-path .build-tsan -Xswiftc -Xllvm -Xswiftc -sil-disable-pass=lifetime-dependence-diagnostics` — subject to ALL of:

1. The carve appears in INVOCATIONS ONLY — never in manifests or sources.
2. The unsanitized debug+release legs of the same gate sequence remain the gate of record for compiler warnings AND lifetime diagnostics (no source can land that fails them).
3. A seeded-race POSITIVE CONTROL rides every TSan gate (a probe whose expected nonzero report count is asserted) — a quiet gate is otherwise meaningless, because TSan reports do NOT fail swift-testing runs; pass criteria grep `WARNING: ThreadSanitizer` counts, never test counts alone.
4. `.build-tsan` is used for every sanitized invocation and never without `--sanitize=thread`; sanitized and unsanitized artifacts never share a scratch.

**Why the carve is sound**: the disabled pass is the lifetime-dependence DIAGNOSTIC pass (catalog B8 — `-sanitize=thread` falsely rejects mutating calls through `nonmutating _modify`/address-accessor projections on lifetime-dependent self); race-signal preservation is positive-control-proven (6/6 seeded warnings survive the carve). Re-probe the wall at every toolchain canon bump — the carve retires when B8 does.

**Cross-references**: catalog B8 (`Research/swift-compiler-bug-catalog.md`), [TEST-036] (clean-build discipline applies to the unsanitized legs).

---

### [TEST-038] No Monolithic Move-Dense Test Bodies (`-Onone` Compile-Time Pathology)

**Statement**: Test code generating dense move-only traffic (op-stream loops, large switches over `~Copyable` payloads, nested functions borrow-capturing `~Copyable` locals) MUST be structured as small per-op `mutating` methods on dedicated stream types — never as one monolithic function body.

**Why**: 6.3.2's `-Onone` mandatory SIL pass `MovedAsyncVarDebugInfoPropagator` is superlinear-to-non-terminating on large move-dense bodies (catalog B10: a 1h19m+ frontend hang; the per-op-method respell of identical semantics compiles in ~6s).

**Cross-references**: catalog B10, [TEST-035] (the same suites carry the state-space duty).

---

### [TEST-039] Structural Law vs Fixture — Test What the Type System Cannot Prove

**Statement**: Suites MUST NOT contain runtime checks for type-system theorems — properties the compiler already proves (exactly-once-on-drop for `~Copyable`, `~Escapable` scope confinement, vacuous identities like `base == base`). What genuinely needs tests: (a) workaround seams where a toolchain wall turned a theorem back into an implementation invariant (e.g. the `discard self` wall forcing the [MEM-OWN-018] guarded-deinit shape); (b) the caller's half of `@unsafe` contracts, which no type system checks. Lifecycle-counting fixtures are named `Census` (the Model.Census precedent) — never `Witness`, which [PKG-NAME-015] reserves.

**Correct**: a `Census` fixture counting init/deinit pairs across a guarded-deinit seam.
**Incorrect**: a `Law` namespace asserting `~Copyable` exactly-once at runtime — ceremony the compiler already proves.

**Cross-references**: [TEST-035] (suite-reach honesty), [MEM-OWN-018], [PKG-NAME-015]

---

### [TEST-040] Live-Mutating Suites Are OUT of Unattended Gates by Default

**Statement**: Test suites that mutate live external state (network calls with account-scoped side effects: sends, key/subaccount/user/IP writes, billing objects) are EXCLUDED from unattended gates BY DEFAULT — default-out, explicit per-run opt-in only. A sandbox DOMAIN does not sandbox ACCOUNT-scoped endpoints (keys, subaccounts, users, IPs are account-level even when the data domain is sandboxed). Any unattended run that DID mutate live state produces a MUTATION CENSUS before close: enumerate which live calls succeeded (what landed where), so the principal can inspect and clean up — "N rejected" covers failures; the census covers what got through.

**Cross-references**: [TEST-005] (test category suites), **testing-institute** [INST-TEST-*] (suite isolation patterns)

---
