---
name: testing-swiftlang
description: |
  Apple Swift Testing framework: suites, naming, ~Copyable, async, model testing.
  ALWAYS apply when writing or reviewing test code using Apple Swift Testing.

layer: implementation

requires:
  - testing

applies_to:
  - swift
  - swift6
  - swift-primitives
  - swift-standards
  - swift-foundations
---

# Swift Testing Framework Patterns

Patterns and conventions for using the Apple Swift Testing framework. These rules cover suite structure, test naming, ~Copyable type testing, async patterns, and model-based testing.

---

## Suite Structure

### [SWIFT-TEST-001] TestSuites Macro Usage

**Statement**: When available, types SHOULD use `#TestSuites` (current) or `#Tests` (future) macro to generate standard suite structure.

**Current** (swift-testing-extras):
```swift
import Testing_Extras

extension YourType {
    #TestSuites
}
// Generates: YourType.Test.{Unit, `Edge Case`, Integration, Performance}
```

**Future** (swift-foundations/swift-testing):
```swift
import Testing

extension YourType {
    #Tests
}
// Generates: YourType.Test.{Unit, `Edge Case`, Integration, Performance, Snapshot}
```

**When macro unavailable** (manual creation):
```swift
extension YourType {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}
```

**Rationale**: Macros ensure consistent structure; manual fallback maintains compatibility.

**Origin**: TEST-002

---

### [SWIFT-TEST-002] Type Extension Pattern

**Statement**: Non-generic types MUST use the type extension pattern for test suites.

**Correct**:
```swift
extension Memory.Buffer {
    @Suite
    struct Test {
        @Suite struct Unit {}
        @Suite struct `Edge Case` {}
        @Suite struct Integration {}
        @Suite(.serialized) struct Performance {}
    }
}

extension Memory.Buffer.Test.Unit {
    @Test
    func `init creates empty buffer`() { }
}
```

**Incorrect**:
```swift
@Suite struct MemoryBufferTests {  // ❌ Compound name, not nested
    @Test func test() { }
}
```

**Rationale**: Type extension mirrors [API-NAME-001] Nest.Name pattern. Test hierarchy matches type hierarchy.

**Cross-references**: [API-NAME-001], [API-NAME-002]

**Origin**: TEST-003

**Lint enforcement**: `Lint.Rule.Testing.CompoundSuiteName` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Testing`) flags `@Suite struct X` declarations whose name is a compound camelCase identifier (≥ 2 uppercase-led tokens, e.g., `FooTests`, `MemoryBufferChecks`). Single-token suite names (`Test`, `Performance`, `Unit`, `Integration`) are the canonical shape and are not flagged. Generic-type exception per [SWIFT-TEST-003] is left to author judgement (the parallel-namespace pattern uses single-token names anyway). Added 2026-05-10 (Wave 2b finalization Batch 6).

---

### [SWIFT-TEST-003] Generic Type Exception

**Statement**: Generic types — whether extended generically or at a concrete specialization — MUST use the parallel namespace pattern. The [SWIFT-TEST-002] extension pattern is incompatible with generic types, nested-in-generic types, and protocol-hosted suites (a `@Suite` in a protocol extension).

**Context**: The `@Test` macro emits `@section("__DATA_CONST,__swift5_tests")` attributes on generated globals. Swift rejects `@section` in generic contexts with a hard compiler error:

```
error: attribute @section cannot be used in a generic context
```

Additionally, test function bodies declared inside `extension Generic { ... }` are treated as generic functions (they capture the outer type's type parameters), which blocks patterns like declaring a local `struct Tag {}` inside a test body (`type 'Tag' cannot be nested in generic function ...`).

Both failure modes apply to:

- **Extension on generic type unspecialized**: `extension Property { @Suite struct Test { ... } }` — fails with `@section`-in-generic-context because `Test` captures `Property<Tag, Base>`'s generic parameters.
- **Extension on a concrete specialization**: `extension Container<Int> { @Suite struct Test { ... } }` — silently not discovered (see [swiftlang/swift-testing#1508](https://github.com/swiftlang/swift-testing/issues/1508)). This is the original form of the bug that motivated this rule.
- **Nested-in-generic types**: `Property.View`, `Property.View.Read`, etc. — inherit the outer type's generic parameters and fail identically to the first case.

The parallel-namespace pattern escapes the generic context entirely: the `Tests` struct is a top-level non-generic type, so `@section` applies in a non-generic context and discovery works.

**Third failure mode — protocol-hosted suites**: a `@Suite struct` declared in a protocol extension (`extension SomeProtocol { @Suite struct Test { ... } }`) fails with `static stored properties not supported in protocol extensions` — the suite macro synthesizes static storage a protocol extension cannot host. This is a distinct diagnostic and cause from the two generic-context failures above, but it has the same remedy: for a protocol-hosted tested type the top-level backtick-named suite (`@Suite struct `SomeProtocol Tests``) is the ONLY valid shape; the [SWIFT-TEST-002] extension pattern does not apply. Evidence: swift-standards Orientation (commit `2a41a58`).

**Correct** (generic type):
```swift
// Generic type
struct Index<Tag> { }

// Tests use parallel namespace — top-level, non-generic
@Suite
struct `Index Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
}

extension `Index Tests`.Unit {
    @Test
    func `init with valid position`() { }
}
```

**Incorrect — hard compile error** (generic extension, unspecialized):
```swift
extension Index {
    @Suite struct Test {               // ❌ @section in generic context
        @Test func `something`() { }   // ❌ test body is generic
    }
}
```

**Incorrect — silent discovery failure** (concrete specialization):
```swift
extension Index<Int> {
    @Suite struct Test {               // ❌ Never discovered
        @Test func `something`() { }
    }
}
```

**Rationale**: Two distinct failure modes with one workaround. The parallel namespace sidesteps the generic context entirely — `Tests` is top-level and non-generic, so `@section` is accepted and the test function body is non-generic.

**Additional host classes that force the parallel-namespace form** (fleet-verified 2026-07-11, t002 lane B; each is a hard constraint of the language or the build model, not author preference):

| Host class | Why the [SWIFT-TEST-002] extension pattern fails | Handling |
|---|---|---|
| **Protocol-hosted suite** (tested "type" is a protocol, e.g. `Orientation`) | `@Suite struct` inside a protocol extension is a compile error (`static stored properties not supported in protocol extensions`) | Parallel-namespace (b) form is the only valid shape (evidence: swift-standards `2a41a58`) |
| **Reserved-keyword host** (type named `Protocol`, e.g. `RFC_791.Protocol`) | The `@Test` macro emits expression-position references where Swift's `.Protocol` metatype grammar hijacks the name even backticked (`cannot use 'Protocol' with non-protocol type`) | Keep the compound/parallel form; do NOT attempt the extension pattern (evidence: swift-rfc-791 lane, two suites reverted) |
| **Cross-target collision blindness** | A `Test` suite nested via extension in test target A is invisible to test target B; extending a nested type declared in another module's test target is illegal Swift | Scope "already carries a `Test` suite" collision checks PER TEST TARGET — a same-named suite in a sibling test target is NOT a collision (evidence: swift-rfc-7519 `90ad361`, swift-rfc-791 `5783332`) |
| **(b)-form name collision** (the natural backticked name is already claimed, e.g. `` `Buffer.Ring Tests` `` exists and a second `Buffer.Ring`-hosted suite needs a home) | The (a)-shape collision-nesting fallback does not apply to top-level backticked structs | Append the suite's distinguishing tokens to the backticked name (e.g. `` `Buffer.Ring Teardown Tests` ``), mirroring the established (b) naming that embeds qualifiers (precedent: `` `Graph Sequential Concurrency (W3 rider) Tests` ``, graph-primitives `c08429a`); only merge members into the existing suite when same-target and trivially disjoint |

**Cross-references**: [SWIFT-TEST-002], [swiftlang/swift-testing#1508](https://github.com/swiftlang/swift-testing/issues/1508)


**Origin**: TEST-004

---

### [SWIFT-TEST-004] Performance Suite Serialization

**Statement**: Performance test suites MUST use `.serialized` trait to prevent parallel execution interference.

**Correct**:
```swift
@Suite(.serialized) struct Performance {}
```

**Incorrect**:
```swift
@Suite struct Performance {}  // ❌ Missing .serialized
```

**Rationale**: Parallel test execution causes timing measurement variance.

**Origin**: TEST-006

**Lint enforcement**: `Lint.Rule.Testing.PerformanceSuiteSerialized` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Testing`) flags `@Suite struct Performance {}` declarations whose `Suite` argument list does NOT mention `.serialized`. Other suite names (`Unit`, `Integration`, `Edge Case`, etc.) are out of scope; only `Performance`-named suites carry the serialisation requirement. Added 2026-05-10 (Wave 2b finalization Batch 6).

---

## Test Function Conventions

### [SWIFT-TEST-005] Test Naming Pattern

**Statement**: Test functions MUST use `@Test` without string parameter. Function names MUST use backticks with descriptive sentences.

**Correct**:
```swift
@Test
func `Memory.Address from UnsafeRawPointer preserves identity`() { }

@Test
func `Advance address by positive offset`() { }

@Test
func `Distance is antisymmetric: a→b == -(b→a)`() { }

@Test
func `Round-trip: address + distance(to: other) == other`() { }
```

**Incorrect**:
```swift
@Test("init creates empty buffer")  // ❌ String parameter
func initEmpty() { }

@Test
func initEmpty() { }  // ❌ No backticks, not descriptive

@Test
func testThatInitCreatesEmptyBuffer() { }  // ❌ No backticks
```

**Rationale**: Backtick names provide single source of truth — the function name IS the description. No duplication, fully searchable, readable in test output.

**Origin**: TEST-007

**Lint enforcement**: `Lint.Rule.Testing.FunctionNaming` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Testing`) flags `@Test`-attributed function decls whose name does NOT contain a space. Backtick-with-sentence syntax produces names with spaces; camelCase names cannot. The string-argument variant of `@Test("…")` is not flagged here (a separate concern); the rule's signal is identifier shape, not attribute argument shape. Added 2026-05-10 (Wave 2b finalization Batch 6).

---

### [SWIFT-TEST-006] Test Implementation Pattern

**Statement**: Tests MUST follow arrange-act-assert pattern. Setup MAY use `defer` for cleanup.

**Correct**:
```swift
@Test
func `allocate creates buffer with specified size`() {
    // Arrange
    let count: Memory.Address.Count = 100

    // Act
    let buffer = Memory.Buffer.Mutable.allocate(count: count, alignment: 8)
    defer { buffer.deallocate() }

    // Assert
    #expect(!buffer.isEmpty)
    #expect(buffer.count == 100)
}
```

**Rationale**: Clear structure aids readability and maintenance.

**Origin**: TEST-008

---

## Testing ~Copyable Types

### [SWIFT-TEST-007] Observable Property Testing

**Statement**: ~Copyable types MUST be tested via observable properties rather than copying values.

**Correct**:
```swift
@Test
func `init with capacity`() {
    let arena = Memory.Arena(capacity: 1024)

    // Test via properties (non-consuming)
    #expect(arena.capacity.rawValue == 1024)
    #expect(arena.allocated.rawValue == 0)
    #expect(arena.remaining.rawValue == 1024)
}
```

**Incorrect**:
```swift
@Test("arena equality")
func arenaEquality() {
    let arena1 = Memory.Arena(capacity: 1024)
    let arena2 = arena1  // ❌ Cannot copy ~Copyable
    #expect(arena1 == arena2)
}
```

**Rationale**: ~Copyable types cannot be copied; test through properties that borrow self.

**Origin**: TEST-011

---

### [SWIFT-TEST-008] Mutation Testing Pattern

**Statement**: ~Copyable mutation tests MUST use `var` bindings and test state changes in place.

**Correct**:
```swift
@Test
func `reset restores full capacity`() {
    var arena = Memory.Arena(capacity: 1024)

    _ = arena.allocate(count: 500, alignment: 8)
    #expect(arena.remaining.rawValue < 1024)

    arena.reset()  // Mutates in place
    #expect(arena.allocated.rawValue == 0)
    #expect(arena.remaining.rawValue == 1024)
}
```

**Rationale**: Mutation via inout avoids copying.

**Origin**: TEST-012

---

### [SWIFT-TEST-009] Consuming Operation Testing

**Statement**: Consuming operations MUST be tested at the end of a test, after all other assertions.

**Correct**:
```swift
@Test
func `move transfers value`() {
    let ptr = Pointer<Int>.Mutable.allocate(capacity: 1)
    defer { ptr.deallocate() }

    ptr.initialize(to: 42)

    // Consuming operation at end
    let moved = ptr.move()
    #expect(moved == 42)
}
```

**Incorrect**:
```swift
@Test
func `move and continue`() {
    let ptr = Pointer<Int>.Mutable.allocate(capacity: 1)
    ptr.initialize(to: 42)
    let moved = ptr.move()
    #expect(ptr.pointee == 42)  // ❌ Undefined after move
}
```

**Rationale**: Consuming destroys the value; no further operations are valid.

**Origin**: TEST-013

---

### [SWIFT-TEST-010] Helper Functions for ~Copyable

**Statement**: Helper functions operating on ~Copyable types MUST use `borrowing` parameter.

**Correct**:
```swift
func toArray<Element: Hashable>(
    _ set: borrowing Set<Element>.Ordered
) -> [Element] {
    var result: [Element] = []
    for i in 0..<set.count {
        result.append(set[i])
    }
    return result
}
```

**Incorrect**:
```swift
func toArray<Element: Hashable>(
    _ set: Set<Element>.Ordered  // ❌ Would consume
) -> [Element] { }
```

**Rationale**: `borrowing` enables read-only access without consuming.

**Origin**: TEST-014

---

### [SWIFT-TEST-014] ~Copyable Values in #expect

**Statement**: `#expect` macro expansion copies its operands during evaluation. ~Copyable values MUST be projected to a Copyable value before passing to `#expect`.

**Correct**:
```swift
@Test
func `handle is fulfilled`() {
    let handle = IO.Blocking.Lane.Handle<Int>(...)
    let fulfilled = handle.isFulfilled  // Extract Copyable projection
    #expect(fulfilled)
}
```

**Incorrect**:
```swift
@Test
func `handle is fulfilled`() {
    let handle = IO.Blocking.Lane.Handle<Int>(...)
    #expect(handle.isFulfilled)  // ❌ Macro tries to copy ~Copyable handle
}
```

**Statement**: ~Copyable values MUST NOT be stored in `Array` or other `Copyable`-constrained collections for bulk assertion. Use sequential assertions or a loop with `borrowing` access.

**Statement**: ~Copyable `Optional` values MUST NOT use `== nil` in `#expect` — binary comparison requires Copyable operands. Use `if let` / guard pattern matching instead.

**Correct**:
```swift
@Test
func `front is nil after drain`() {
    var deque = Deque<NoCopy>()
    let isEmpty = deque.front.peek { _ in false } == nil
    #expect(isEmpty)
    // Or:
    if let _ = deque.front.peek({ $0.value }) {
        Issue.record("Expected nil")
    }
}
```

**Incorrect**:
```swift
@Test
func `front is nil after drain`() {
    var deque = Deque<NoCopy>()
    #expect(deque.front.take == nil)  // ❌ Binary comparison copies ~Copyable Optional
}
```

**Property-access expansion in #expect**: Swift Testing's `__checkPropertyAccess` instrumentation requires `Copyable`. When `#expect(deque.isEmpty)` expands, the macro synthesizes a property access that copies the receiver. For `~Copyable` types, extract the property to a local `Bool` / `Copyable` binding first:

```swift
@Test
func `deque is empty`() {
    let deque = Executor.Job.Deque(capacity: 16)
    let isEmpty = deque.isEmpty        // local Copyable projection
    #expect(isEmpty)                    // expansion copies Bool, not deque
}
```

**`~Copyable` across `group.addTask` closure boundaries**: task-group closures cannot capture `~Copyable` values directly (the closure body is `@Sendable` and `Copyable`-implicit). Wrap the `~Copyable` value in a generic `@unchecked Sendable` reference-typed harness (e.g., `Test.Harness<T>` or the ecosystem's shared `Harness<State>` from Test Support, per `[TEST-023]`) whose lifetime spans the test. Nested or generic names per `[API-NAME-001]`; compound type names like `DequeHarness` are forbidden.

```swift
// Generic harness — compound names forbidden per [API-NAME-001].
// One reusable type at test-support scope; bind State per call site.
final class Harness<State>: @unchecked Sendable {
    var state: State
    init(_ state: State) { self.state = state }
}

@Test
func `100k contended reconciliation`() async throws {
    let harness = Harness(Executor.Job.Deque(capacity: 131_072))
    await withTaskGroup(of: Int.self) { group in
        for workerId in 0..<16 {
            group.addTask { /* access harness.state here */ return 0 }
        }
        // ...
    }
}
```

**Rationale**: `#expect`, `Array`, `group.addTask`, and other generic stdlib infrastructure assume `Copyable`. This is the current state of generics adoption, not a bug. As stdlib adopts `~Copyable` generics, this friction will decrease. The class-harness wrapping is a mechanical workaround that preserves test semantics; the `@unchecked` is safe because the test is single-consumer-at-a-time of the `~Copyable` value under the group's scheduling.

**Cross-references**: [SWIFT-TEST-009], [SWIFT-TEST-010], [MEM-COPY-004], [TEST-028]


---

## Async Testing Patterns

### [SWIFT-TEST-011] Async Expect Bindings

**Statement**: When comparing two `async` values in `#expect`, both sides MUST be extracted to `let` bindings first. Direct `await` inside `#expect` causes compiler inference failures.

**Correct**:
```swift
@Test
func `stream produces expected value`() async {
    let actual = await stream.next()
    let expected = await reference.value()
    #expect(actual == expected)
}
```

**Incorrect**:
```swift
@Test
func `stream produces expected value`() async {
    #expect(await stream.next() == await reference.value())  // ❌ Inference failure
}
```

**Rationale**: Swift Testing's `#expect` macro expansion interacts poorly with multiple `await` expressions in a single macro invocation.

**Origin**: TEST-027

---

### [SWIFT-TEST-012] Foundation-Free Isolation Verification

**Statement**: Primitives-layer tests that need to verify main-actor isolation MUST use `pthread_main_np()` instead of Foundation's `Thread.isMainThread`.

**Correct**:
```swift
#if canImport(Darwin)
import Darwin

@Test
func `callback runs on main thread`() async {
    let isMain = pthread_main_np() != 0
    #expect(isMain)
}
#endif
```

**Incorrect**:
```swift
import Foundation  // ❌ Forbidden in primitives [PRIM-FOUND-001]
#expect(Thread.isMainThread)
```

**Rationale**: Foundation is forbidden in primitives and standards layers. `pthread_main_np()` is available directly from Darwin.

**Lint enforcement**: SwiftLint custom rule `no_thread_ismainthread_in_primitives` (`swift-institute/.github/.swiftlint.yml`) catches `Thread.isMainThread` in `Sources/`. Severity error. Added Wave 2b 2026-05-10.

**Cross-references**: [PRIM-FOUND-001]

**Origin**: TEST-028

---

## Model-Based Testing

### [SWIFT-TEST-013] Model-Based Testing

**Statement**: Complex data structures SHOULD include model tests that compare behavior against a reference implementation.

**Pattern**:
```swift
@Suite
struct `Set.Ordered - Model Tests` {

    struct ReferenceModel<Element: Hashable> {
        var elements: [Element] = []
        var set: Swift.Set<Element> = []

        mutating func insert(_ element: Element) -> Bool {
            guard !set.contains(element) else { return false }
            set.insert(element)
            elements.append(element)
            return true
        }
    }

    @Test
    func `random operations match model`() {
        var sut = Set<Int>.Ordered()
        var model = ReferenceModel<Int>()

        for i in 0..<100 {
            let sutResult = sut.insert(i).inserted
            let modelResult = model.insert(i)
            #expect(sutResult == modelResult)
        }

        #expect(sut.count == model.elements.count)
    }
}
```

**Rationale**: Model tests verify invariants across many operations, catching subtle bugs.

**Origin**: TEST-017

---

### [SWIFT-TEST-015] @Test Symbol Length at Deep Nesting

**Statement**: The `@Test` macro generates `@section`-attributed global variables with mangled names proportional to the full type nesting path. At deep nesting (e.g., `IO.Event.Channel.Test.FullDuplex`) with many tests in one file, the aggregate symbol names may exceed compiler thresholds, causing cryptic `@section` attribute errors.

**Workaround**: Limit one test suite per file when the nesting path exceeds 4 levels. If a `@section` error appears, split the file and use a shorter nesting suffix.

**Correct**:
```
// Separate files with shorter nesting
IO.Event.Channel.Split.Tests.swift  → @Suite struct Test { @Suite struct Split { ... } }
IO.Event.Channel.Lifecycle.Tests.swift → @Suite struct Test { @Suite struct Lifecycle { ... } }
```

**Incorrect**:
```
// Single file with deep nesting and many tests
IO.Event.Channel.Tests.swift
  → @Suite struct Test {
       @Suite struct FullDuplex { /* 20+ tests */ }  // ❌ Symbol names too long
     }
```

**Rationale**: The symbol length scales with nesting depth × test count. The mangled name for a test at 5 levels of nesting is ~180 characters. The principled fix at the compiler level would be symbol hashing for `@section`-attributed globals; at the codebase level, the fix is one suite per file.

**Cross-references**: [TEST-009]


---

### [SWIFT-TEST-016] Macro Test Framework — Generic Helper, No XCTest, No Foundation

**Statement**: Tests for Swift Testing macro implementations MUST use `SwiftSyntaxMacrosGenericTestSupport`'s framework-agnostic `assertMacroExpansion(...)` overload, paired with a Swift Testing `failureHandler` adapter routing failures to `Issue.record(...)`. Tests MUST NOT use `SwiftSyntaxMacrosTestSupport` — it is XCTest-based and pulls Foundation transitively, in violation of [TEST-001] (no XCTest) and the ecosystem's absolute Foundation ban.

**Correct**:

```swift
import Testing
import SwiftSyntaxMacrosGenericTestSupport
@testable import Observations_Macros

extension ObservableMacro.Test.Unit {
    @Test
    func `simple struct expansion`() {
        assertMacroExpansion(
            "@Observable struct Counter { var x: Int = 0 }",
            expandedSource: "...",
            macros: ["Observable": ObservableMacro.self],
            failureHandler: { specifier in
                Issue.record(
                    Comment(rawValue: specifier.message),
                    sourceLocation: SourceLocation(/* fileID, line, column */)
                )
            }
        )
    }
}
```

**Incorrect**:

```swift
import XCTest                                    // ❌ XCTest forbidden per [TEST-001]
import SwiftSyntaxMacrosTestSupport              // ❌ XCTest-based; pulls Foundation transitively
@testable import Observations_Macros

class ObservableMacroTests: XCTestCase {         // ❌ Compound name; XCTest base class
    func testSimpleStruct() {                    // ❌ Not Swift Testing
        assertMacroExpansion(/* ... */)          // ❌ XCTest-routed failureHandler
    }
}
```

**Limitation — `@attached(...)` form-vs-site validation gap**:

The generic helper does NOT validate `@attached(...)` applicability against the actual attachment context any more than the XCTest variant does — both run textual expansion only. A macro can pass all `assertMacroExpansion` tests yet fail at compile time because:

| Mismatch | Compile-time outcome | Test-harness outcome |
|----------|---------------------|----------------------|
| `@attached(member)` on a property-attachment site | Rejected | Accepted |
| `@attached(accessor)` on a type-attachment site | Rejected | Accepted |
| Single macro combining `@attached(member)` + `@attached(accessor)` + `@attached(extension)` | Invalid at every site (Swift checks each `@attached(...)` against the actual attachment context) | Accepted at every site (test harness skips per-site validation) |

Macro test coverage that omits a real coordinator-owned package-build integration test is fragile. Macro test coverage MUST include at least one consumer site that invokes the macro under a real compile, exercising the form-vs-site applicability that the test harnesses don't check. For type-level + property-level co-design (e.g., type-level synthesis paired with property-level accessor injection), the integration test surfaces the twin-macro requirement directly: a single macro with multi-attached-forms is structurally invalid for the same reason — the integration test is the only check.

**Rationale**: The XCTest-based `SwiftSyntaxMacrosTestSupport` predates Swift Testing and assumes XCTest's `XCTFail`-routed failure mechanism. The generic `SwiftSyntaxMacrosGenericTestSupport` exposes the failure mechanism as a `failureHandler` closure, allowing the test harness to choose. Swift Testing routes failures via `Issue.record(...)`; the adapter is a single closure, not a separate framework. This eliminates the XCTest dependency and the transitive Foundation pull. The form-vs-site validation gap is documented separately because it applies to BOTH test harnesses; the rule's coverage requirement (real-compile integration test) closes the gap regardless of which expansion-test harness is chosen.

**Lint enforcement**: SwiftLint custom rule `no_macros_test_support_legacy` (`swift-institute/.github/.swiftlint.yml`) catches `import SwiftSyntaxMacrosTestSupport`. Severity error. Added Wave 2b 2026-05-10.


**Cross-references**: [TEST-001], [PRIM-FOUND-001], [SWIFT-TEST-005], [SWIFT-TEST-013]

---

## Cross-References

See also:
- **testing** skill — [TEST-*] for umbrella routing, test support infrastructure, file naming
- **benchmark** skill — [BENCH-*] for performance measurement patterns
- **testing-institute** skill — [INST-TEST-*] for nested package pattern and snapshots
- **code-surface** skill — [API-NAME-001] Nest.Name pattern, [API-IMPL-005] one type per file
- **memory-safety** skill — [MEM-COPY-*] for ~Copyable ownership rules
- [swiftlang/swift-testing#1508](https://github.com/swiftlang/swift-testing/issues/1508) for generic type limitation
