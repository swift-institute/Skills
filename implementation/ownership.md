# Ownership and ~Copyable

Part of the **implementation** skill. Full text of the ownership-posture rules and `~Copyable` constraint patterns. For the foundational axioms ([IMPL-INTENT], [IMPL-000], [IMPL-001], [IMPL-COMPILE]) and the rule index, see `SKILL.md`.

**Rules in this file**: [IMPL-063], [IMPL-064], [IMPL-065], [IMPL-067], [IMPL-070], [IMPL-071], [IMPL-072], [IMPL-078], [IMPL-080], [IMPL-096], [IMPL-106], [IMPL-107], [PATTERN-022], [COPY-FIX-003] – [COPY-FIX-011], [COPY-REM-003].

---

## Ownership Posture

### [IMPL-064] ~Copyable as Default Posture

**Statement**: New types MUST default to `~Copyable`. The question is "does this type need to be Copyable?" — Copyable is the exception requiring justification.

**Copyable justified**: Stored in stdlib collections, value-semantic CoW, lightweight value passed by copy, protocol requirement demands it.
**~Copyable required**: Resource with exactly-once lifecycle, exclusive-access container, unique ownership token, type where duplication is semantic error.

**Cross-references**: [IMPL-COMPILE], [MEM-COPY-001]

---

### [IMPL-065] ~Escapable for Scoped Access

**Statement**: Types representing borrowed access, scoped views, or lifetime-dependent references SHOULD use `~Escapable` when `Lifetimes` is enabled.

**Candidates**: Pointer-based views (`Property.View`), scoped access handles (`Span`), borrowed iterators.
**Does NOT apply**: Types stored in closures, types whose lifetime depends on closure parameters, types stored in collections.

**Cross-references**: [IMPL-COMPILE], [IMPL-021]

---

### [IMPL-067] Explicit Ownership Annotations

**Statement**: Parameters with non-obvious ownership semantics MUST use explicit annotations.

| Annotation | Caller obligation | When required |
|------------|-------------------|---------------|
| `consuming` | Gives up value | ~Copyable params, transfer operations |
| `borrowing` | Retains ownership | View-producing methods |
| `inout` | Grants exclusive mutable access | Mutation through exclusivity |

**When optional**: Simple Copyable value parameters, closures where annotation adds noise.

**Limitation**: Ownership modifiers are NOT an overload axis. `func f(_ x: borrowing T)` and `func f(_ x: consuming T)` are redeclarations, not overloads. This applies to all combinations (borrowing/consuming/inout) and to closure parameter ownership. Use different method names or the static method pattern ([IMPL-023]) for variants with different ownership semantics.

**Validated by**: `swift-institute/Experiments/ownership-overloading-limitation/`

**Cross-references**: [IMPL-COMPILE], [MEM-OWN-001]

---

## Ownership Mechanics

### [IMPL-063] Ownership Subsumes Synchronization

**Statement**: When a type is `~Copyable` with `mutating` methods, the compiler guarantees exclusive access. Adding actors, atomics, or locks to protect stored state introduces synchronization for a concurrency problem that does not exist.

**Detection**: Any `~Copyable` type containing an actor, `Atomic`, `Mutex`, or `OSAllocatedUnfairLock` for internal state is a simplification candidate — if all access paths are `mutating` or `consuming`.

**Cross-references**: [MEM-COPY-001], [IMPL-COMPILE]

---

### [IMPL-070] Ownership Transfer Through Mutex

**Statement**: Transferring `consuming ~Copyable` values through Mutex SHOULD use coroutine-based direct property access for new code.

**End-state pattern** (coroutine Mutex with `@_rawLayout` + `nonmutating _modify`):
```swift
_state.locked.value.buffer.push(consume element, to: .back)
```

**Backward-compat pattern** (closure Mutex): Layer 0 (`var slot: V? = value` + `.take()!`), Layer 1 (`withLock(consuming:body:)`), Layer 2 (`Bridge.push()`, `Channel.send()`). `.take()!` at Layer 2 is a compliance violation per [IMPL-INTENT].

**Validated by**: `swift-institute/Experiments/mutex-coroutine-rawlayout/` (6/6 CONFIRMED, debug + release).

**Cross-references**: [IMPL-INTENT], [IMPL-071], [MEM-OWN-010], [MEM-OWN-011], [MEM-OWN-012]

---

### [IMPL-071] nonmutating _modify for Interior Mutability

**Statement**: When a `~Copyable` view provides mutation through a raw pointer, the `_modify` accessor MUST be `nonmutating`. This enables mutation through `let`-bound containers.

```swift
var value: Value {
    _read { yield unsafe pointer.pointee }
    nonmutating _modify { yield &pointer.pointee }  // ✓ works with `let`
}
```

**~Escapable note**: `~Escapable` on the view is desirable but currently blocked by a lifetime checker limitation on class stored properties. Use `~Copyable` alone — `_read` coroutine scope prevents escape, `~Copyable` prevents aliasing. Experiments: `swift-institute/Experiments/nonescapable-closure-storage/`, `pointer-nonescapable-storage/`, `nonescapable-gap-revalidation-624/`.

**Cross-references**: [IMPL-022], [IMPL-070], [IMPL-064]

---

### [IMPL-072] ~Copyable Multi-Value Return

**Statement**: Functions returning multiple `~Copyable` values MUST use a `~Copyable` bundle struct with Optional members and consuming extraction methods. Swift does not yet support `~Copyable` tuples.

```swift
struct Split: ~Copyable {
    private var _reader: Reader?
    private var _writer: Writer?
    consuming func reader() -> Reader { _reader.take()! }
    consuming func writer() -> Writer { _writer.take()! }
}
```

**Cross-references**: [IMPL-064], [MEM-COPY-001], [MEM-OWN-001]

---

## Migration and Selection

### [IMPL-078] Widen, Don't Duplicate

**Statement**: When adding `~Copyable` support to an existing `Copyable` API, the first approach MUST be to widen the existing constraint from `Copyable` to `~Copyable`. Add a parallel extension only where semantics genuinely diverge.

**Decision procedure**: For each method in the `Copyable` extension, ask: "Can this work with `consuming`/`borrowing` conventions?" If yes, widen. If no (e.g., value-returning accessors requiring copy), keep a Copyable-only convenience alongside the widened base.

The two-tier overload pattern ([IMPL-025]) applies when the Copyable tier needs *different preparation logic* (e.g., CoW checks) — not when the logic is identical.

**Cross-references**: [IMPL-025], [IMPL-064], [MEM-COPY-006]

---

### [IMPL-080] Consuming Ternary for ~Copyable Selection

**Statement**: When selecting one of two `~Copyable` values based on a condition (`max`, `min`, ternary return), use `consuming` parameters with a ternary expression. Swift's ownership model handles it naturally — selected branch consumed, other dropped.

```swift
static func max(_ a: consuming Self, _ b: consuming Self) -> Self {
    a < b ? b : a
}
```

**Cross-references**: [IMPL-064], [IMPL-078], [MEM-OWN-001]

---

## File Structure for ~Copyable Types

### [PATTERN-022] ~Copyable Nested Types in Separate Files

**Statement**: Nested types inside `~Copyable`-generic parents MUST be defined in separate files via `extension Parent where Element: ~Copyable { }`, following [API-IMPL-005].

```swift
// File: Namespace.swift
public enum Namespace<Element: ~Copyable> {}

// File: Namespace.NestedData.swift
extension Namespace where Element: ~Copyable {
    public enum NestedData: Sendable, Equatable { ... }
}
```

**Deeply nested types** use extensions on the intermediate parent:
```swift
// File: Namespace.NestedHeap.Cyclic.swift
extension Namespace.NestedHeap where Element: ~Copyable {
    public struct Cyclic<let capacity: Int>: Copyable, Sendable { ... }
}
```

**ManagedBuffer nesting constraint**: `ManagedBuffer` subclasses MUST be nested at the **same level** as the `~Copyable` generic parameter declaration:

```swift
// CORRECT — Storage at same level as Element parameter
public struct Stack<Element: ~Copyable>: ~Copyable {
    final class Storage: ManagedBuffer<Int, Element> { }  // Level 0 — works
    public struct Bounded: ~Copyable {
        var _storage: Stack<Element>.Storage  // References Level 0
    }
}

// INCORRECT — Storage nested deeper
public struct Stack<Element: ~Copyable>: ~Copyable {
    public struct Bounded: ~Copyable {
        final class Storage: ManagedBuffer<Int, Element> { }  // Level 1 — FAILS
    }
}
```

**Cross-references**: [API-IMPL-005], [MEM-COPY-006], [COPY-FIX-003]

**Lint enforcement**: Reusable workflow `validate-package-shape.yml` + companion `.github/scripts/validate-package-shape.py` flag files whose top-level declaration is a `~Copyable`-generic type with nested `struct`/`class`/`enum`/`actor` declarations in-body — the nested type SHOULD be hoisted to a sibling file via `extension Parent where Element: ~Copyable { … }` per the rule. ManagedBuffer nesting-level constraints are out of scope (whole-module concern). Scope detail: rationale archive §[PATTERN-022]. [VERIFICATION: WF validate-package-shape.py (PATTERN-022)]

---

## ~Copyable Constraint Patterns

Rules for correctly structuring code with `~Copyable` generic parameters. Absorbed from the former copyable-remediation skill.

**Quick reference**:

| Error / Symptom | Fix |
|-----------------|-----|
| `type 'Element' does not conform to protocol 'Copyable'` | [COPY-FIX-003] or [COPY-FIX-004] |
| Error after adding `Sequence` conformance | [COPY-FIX-005] |
| Extension methods unavailable for ~Copyable elements | [COPY-FIX-003] |
| Error only during `swift build`, not in IDE | [COPY-FIX-006] |
| ~Copyable element deinit NOT called (memory leak) | [COPY-FIX-009] |

---

### [COPY-FIX-003] Extension Constraint Requirement

**Statement**: Every extension on a type with `~Copyable` parameters MUST include explicit `where Element: ~Copyable`, unless intentionally restricted to `Copyable` elements. This applies to methods, properties, typealiases, nested types, and extensions on nested types.

```swift
extension Container where Element: ~Copyable { func baseOperation() { } }     // ✓
extension Container { func operation() { } }                                     // ✗ implicitly Copyable-only
```

The constraint appears redundant on nested types but is required:
```swift
extension Storage.Heap where Element: ~Copyable { public struct Header { } }   // ✓
extension Storage.Heap { public struct Header { } }                              // ✗
```

**Cross-references**: [MEM-COPY-004], [MEM-COPY-006], [PATTERN-022]

---

### [COPY-FIX-004] Conditional Conformance Placement

**Statement**: Conditional conformances MUST be in the **same file** as the type definition to avoid constraint poisoning. Module boundary alternative: [COPY-FIX-010].

**Cross-references**: [MEM-COPY-006], [COPY-FIX-010]

---

### [COPY-FIX-005] Protocol Conformance Strategy

**Statement**: `Sequence`/`Collection` conformances MUST be conditional on `Element: Copyable`. For ~Copyable iteration, use custom protocols or `forEach` with borrowing closures.

---

### [COPY-FIX-006] Multi-File Emit-Module Bug

**Status**: OPEN. Tracking: swiftlang/swift #86669. Experiment: `swift-institute/Experiments/noncopyable-sequence-emit-module-bug/`

**Statement**: When errors appear during `-emit-module` but not type-checking, and all six conditions are present (compound `~Copyable & Protocol` constraint, `UnsafeMutablePointer<Element>` in nested type, conditional Sequence conformance, `borrowing Element` closure in separate file, library target, `-enable-experimental-feature Lifetimes`), consolidate all source into a single file.

---

### [COPY-FIX-007] Copy-on-Write for Conditional Copyable

**Statement**: Types with conditional `Copyable` conformance MUST implement CoW in all mutating operations when `Element: Copyable`. The `~Copyable` tier mutates directly; the `Copyable` tier adds uniqueness checks. Critical: always update cached pointers after CoW copy.

**Cross-references**: [IMPL-023], [IMPL-025]

---

### [COPY-FIX-008] Sendable Conformance Independence

**Statement**: `Sendable` conformance MUST be conditional on `Element: Sendable`, independent of `Copyable`.

**Silent failure**: `@unchecked Sendable where Element: ~Copyable` compiles without warning but grants Sendable to ALL element types — including non-Sendable ones.

**Cross-references**: [IMPL-068], [MEM-SEND-001]

---

### [COPY-FIX-009] @_rawLayout Deinit Bug

**Status**: OPEN. Tracking: swiftlang/swift #86652. Experiments: `swift-buffer-primitives/Experiments/rawlayout-*/` (6 variants).

**Statement**: The compiler does not synthesize member destruction for `~Copyable` structs whose stored property chain includes `@_rawLayout`-backed types across package boundaries. Element deinitializers silently fail — **memory leak**, not compile error.

**Conditions** (all three): (1) `@_rawLayout` stored property (directly or transitively), (2) cross-package boundary, (3) container is `~Copyable`.

**Workaround** (two parts, both required):
```swift
struct Container<Element: ~Copyable, let capacity: Int>: ~Copyable {
    var _buffer: Buffer<Element>.Ring.Inline<capacity>
    var _deinitWorkaround: AnyObject? = nil  // Part 1: forces deinit body to execute

    deinit {
        // Part 2: manually clean up via mutating path
        unsafe withUnsafePointer(to: _buffer) { ptr in
            unsafe UnsafeMutablePointer(mutating: ptr).pointee.remove.all()
        }
    }
}
```

**Cross-references**: [MEM-COPY-001], [PATTERN-016]

---

### [COPY-FIX-010] Module Boundary Solution

**Statement**: When same-file conformance placement [COPY-FIX-004] isn't viable, split into separate SPM modules. Module boundaries prevent constraint propagation.

---

### [COPY-FIX-011] Prefer the Non-Restricting Fix Over a `Copyable` Constraint

**Statement**: When a nightly / language change (e.g. Equatable no longer implying Copyable) breaks `~Copyable`-generic code, PREFER the non-restricting fix — a borrow-based body, an open-coded loop, no added `Element: Copyable` — over constraining the API to `Copyable`. An explicit `Copyable` constraint is acceptable only as an **expedient** where `Copyable` is structural today (e.g. the element is held in `Array` storage), and MUST then be tracked as follow-up debt (`// WORKAROUND:` per [PATTERN-016]) to revisit when the baseline supports the noncopyable-compatible representation.

**Correct** (non-restricting): open-coded borrow loop, constraint-free — `swift-storage-primitives` `contains(_:)` (`d32254c`).
**Expedient debt** (tracked): `swift-parser-primitives` `Parser.Prefix.Through` / `UpTo` (`fa12693`) added `Input.Element: Copyable` because the delimiter is stored as `[Input.Element]`; lifting it needs a noncopyable-compatible delimiter representation.

**Rationale**: evergreen, structurally-correct ownership shapes over expedient narrowing — consistent with [ARCH-LAYER-008] (correctness / evergreen) and the suppression-restatement discipline ([COPY-FIX-003], [MEM-COPY-004]).


**Cross-references**: [COPY-FIX-003], [COPY-REM-003], [MEM-COPY-004], [PATTERN-016], [ARCH-LAYER-008].

---

### [COPY-REM-003] Constraint Cascade Planning

**Statement**: Before implementing a `~Copyable` or `~Escapable` change, trace every associated type through every conformer and extension to predict where constraints will be needed.

**Cascade categories**: ~Copyable on Element (subscript access breaks), ~Copyable on output types (protocol requirements break), ~Escapable on parameters (implicit Escapable breaks).

**Cross-references**: [COPY-FIX-003], [COPY-FIX-004], [MEM-COPY-006], [IMPL-064], [IMPL-065]

---

### [IMPL-096] Layout-Soundness Pre-Check for Typed-Pointer Wrappers

**Statement**: When declaring `UnsafeMutablePointer<Wrapper>?` over C-allocated memory, verify `MemoryLayout<Wrapper>.stride ≤ minimum allocation size` — not just equality with one specific case. Kernel-always-full-allocates types (e.g., `siginfo_t`) pass this check; family-dispatched types (e.g., `sockaddr_storage` re-cast over `sockaddr_in`) fail it.

**Procedure**:

1. Identify the minimum allocation size the C caller may produce (smallest family member for variant types, fixed size for always-full types).
2. Compare `MemoryLayout<Wrapper>.stride` against that minimum.
3. If stride exceeds minimum, the wrapper is unsound — typed pointer reads may cross allocation boundaries. Use `OpaquePointer?` or `UnsafeMutableRawPointer?` instead and bind at the access site.

**Rationale**: Layout-compatibility at the maximal case does not imply layout-compatibility at the family-dispatched minimum. The typed pointer wrapper, if allowed on the variant case, produces undefined behavior when the minimum-allocation-sized buffer is accessed via the larger stride. The check is cheap at declaration time and impossible to retrofit once the wrapper is in use.

**Cross-references**: [PLAT-ARCH-005a]

---

### [IMPL-106] Language Features Over Custom Ownership Types

**Statement**: When fixing aliasing, double-close, or borrow-lifetime bugs in `~Copyable` types, the correct fix MUST use Swift's existing language features (`borrowing`, `consuming`, `~Copyable`, `~Escapable`, `inout`). Inventing custom non-owning wrapper types (`Raw`, `Borrow` shadows) or raw-`Int` boundary overloads is FORBIDDEN — these bypass the type system's ownership story instead of expressing it.

**Forbidden patterns**:

- `Kernel.Descriptor.Raw` / `.Borrow` shadow types declared to "represent a non-owning view"
- `func ctl(..., rawFD: Int32, ...)` raw-Int overloads alongside the typed signature
- `Borrowed(_rawValue:)` constructors
- "Borrowing-only constructor that doesn't deinit-close"
- `consuming func _take() -> RawValue` SPI that extracts raw and suppresses deinit
- Any pattern that requires the caller to work with raw values (`UInt`/`Int32`) directly at the call site

**Correct alternatives**:

| Symptom | Fix |
|---|---|
| Stored raw `Int32` + borrowing API call | Refactor storage to hold the owning Descriptor (or borrow from the owner). Never reconstruct from raw. |
| Lock-protected owned Descriptor needs to call a borrowing API | Call the borrowing API from inside the lock scope, borrowing the stored Descriptor in place. Don't extract `_rawValue` then reconstruct outside the lock. |
| `dup2`-style atomic "replace" semantics | `inout Kernel.Descriptor` parameter — exclusive mutable borrow for the syscall duration; the wrapper's `_raw` slot stays the same number, the kernel resource it points to has been replaced. No `consuming` extraction, no reconstruction. |
| Computed property accessor returning owned `~Copyable` from borrowed state | Remove the accessor — it is a fundamental ownership lie. Expose the underlying state through methods that take ownership properly, or not at all. |
| Process-owned standard streams (stdin/stdout/stderr) | A process-scoped owning Descriptor that other types borrow from, OR typed syscall overloads that take the typed wrapper (`read(_ stream: Terminal.Stream, ...)`). The Int conversion happens once at the syscall boundary per [IMPL-010]. |

**Rationale**: custom shadow types and raw-Int overloads are mechanism leaks — they bypass the type system's ownership story instead of expressing it, contra the foundational axioms ([IMPL-INTENT], [IMPL-COMPILE], [IMPL-002], [IMPL-010], [PATTERN-017]). Origin formulation: rationale archive §[IMPL-106].

**Cross-references**: [IMPL-INTENT], [IMPL-010], [IMPL-064], [IMPL-067], [PATTERN-017], [MEM-OWN-015]

---

### [IMPL-107] Reference<T> / Owned<T> for Recursive Value-Type Indirection

**Statement**: When a struct or enum needs to store a value of its own type recursively (the classic `struct Foo { let parent: Foo? }` pattern that requires heap indirection), the storage MUST use `Reference<T>` (shared-ownership, swift-reference-primitives) or `Owned<T>` (unique-ownership, swift-ownership-primitives). Authoring an ad-hoc `internal final class _Box { let value: T }` per occurrence is FORBIDDEN.

**Decision rule** for which primitive:

| Access pattern | Primitive |
|---|---|
| Multiple call paths read the same value (parent-chain walked repeatedly) | `Reference<T>` — shared-ownership |
| Ownership transfers cleanly between scopes (builder consumes inputs) | `Owned<T>` — unique-ownership |

**Forbidden** (one-off pattern):
```swift
public struct Configuration {
    private final class _ParentBox {  // ❌ ad-hoc box
        let value: Configuration
        init(_ v: Configuration) { value = v }
    }
    private let _parent: _ParentBox?
}
```

**Correct**:
```swift
public struct Configuration {
    private let _parent: Reference<Configuration>?  // ✓ institute primitive
}
```

**Apparent contradiction with the "ownership/reference primitives are last-resort" guidance, resolved**: the last-resort framing applies to **marketing / external positioning** (don't lead with these primitives when introducing the institute publicly). It does **not** apply to code authoring when the use case is genuinely recursive-value-type indirection — at that moment, the primitives ARE the right tool. The two compose: rare-but-correct in code; muted in the public narrative.

**Counter-pattern (NOT this rule's target)**: classes that wrap resources, manage non-trivial lifecycles, or coordinate multi-step construction are legitimate class designs. The pattern this rule bans is specifically "single-property class for the sole purpose of breaking value-type recursion."

**Existing `_Box`-style ad-hoc classes are debt**; convert to typed references in cleanup passes (NOT mid-feature work — the conversion is its own commit, scope-disciplined).

**Lint enforcement**: `Lint.Rule.Naming.BoxClass` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Naming`) flags free-standing `class` declarations whose name (after stripping a leading underscore) is in `{Box, Storage, Wrap, Wrapper, Cell}` AND which carries no inheritance clause. Scope detail: rationale archive §[IMPL-107]. [VERIFICATION: AST Lint.Rule.Naming.BoxClass]

**Cross-references**: [IMPL-106], [IMPL-INTENT]

---
