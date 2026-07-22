# Memory Safety — Ownership

Part of the **memory-safety** skill. See `SKILL.md` for the navigation hub, frontmatter, and rule index.

Full rationale, provenance, extended worked examples, and the dated changelog: `swift-institute/Research/memory-safety-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MEM-COPY-001], [MEM-COPY-001a], [MEM-COPY-014], [MEM-COPY-015], [MEM-COPY-002], [MEM-COPY-003], [MEM-COPY-004], [MEM-COPY-005], [MEM-COPY-006], [MEM-OWN-001], [MEM-OWN-002], [MEM-OWN-015].

---

## Ownership

### [MEM-COPY-001] Noncopyable Type Declaration

**Statement**: Types that represent resources with exclusive ownership MUST be marked `~Copyable`.

```swift
enum File {
    struct Descriptor: ~Copyable {
        private let fd: CInt
        deinit { close(fd) }
    }
}
```

**Cross-references**: [MEM-COPY-014]

---

### [MEM-COPY-001a] Deinit Immutability for ~Copyable Structs

**Statement**: `deinit` on a `~Copyable` struct grants *immutable* access to `self` and its stored fields — the same access level as `borrowing`. `consuming func` grants *mutable* access. These are different in exactly one way: any operation that requires mutation of a field (notably `Optional.take()`) compiles in `consuming` and fails in `deinit` with "cannot use mutating member on immutable value: 'self' is immutable."

**Access level table**:

| Context | Access to `self` | Access to fields | `Optional.take()` |
|---------|------------------|------------------|-------------------|
| `borrowing` | Immutable | Immutable | Fails |
| `deinit` | Immutable | Immutable | Fails |
| `mutating` | Mutable | Mutable | Works |
| `consuming` | Mutable (ownership) | Mutable | Works |

**Correct** — read-only pattern match in deinit:
```swift
struct Scope: ~Copyable {
    private var _token: Shutdown.Token?

    deinit {
        // deinit has immutable access — check presence, do not extract
        guard case .some = _token else { return }
        // Field is consumed by the compiler when self is destroyed
    }

    consuming func close() {
        // consuming grants mutation — extract is allowed
        if let token = _token.take() {
            token.fire()
        }
    }
}
```

**Incorrect** — `.take()` in deinit:
```swift
deinit {
    if let token = _token.take() { token.fire() }   // ❌ self is immutable
}
```

**Key insight**: both `consuming` and `deinit` destroy the value, but they grant different access levels. `consuming` is like `mutating` + destruction; `deinit` is like `borrowing` + destruction. The asymmetry matters when extracting values from Optional fields: `.take()` requires mutation and only works in `consuming`. In `deinit`, fields are consumed by the compiler as part of the value's destruction — you only need to *check presence* for any side effects you need to run, not extract.

**Canonical nil-check idiom for `Optional<~Copyable>` in deinit**: `guard case .some = _optionalField else { return }`. This reads the discriminator without touching the payload. The payload itself is destroyed when the struct is destroyed.

**When you need to run a side effect on the payload before destruction**: the side effect MUST be performed via a `consuming func` before the natural destruction path. If a type must always run a side effect on its resource, pair a `consuming func close()` with a `deinit` that traps on a non-closed state (the linear-type pattern per [MEM-LINEAR-001]).

**Rationale**: `self` being immutable in `deinit` matches the semantic model — the value is about to cease to exist, so the compiler forbids observing it in an intermediate mutated state (rationale archive §[MEM-COPY-001a]).


**Cross-references**: [MEM-COPY-001], [MEM-LINEAR-001], [MEM-OWN-001], [MEM-OWN-002]

---

### [MEM-COPY-014] Native Ownership for Resource Types

**Statement**: Types representing resources with lifecycle (file descriptors, handles, allocations) MUST be natively `~Copyable` — ownership is intrinsic to the type, not bolted on via a wrapper. Wrapper patterns (e.g., `Owned<Tag>`) are for cross-module adaptation of types you do not control.

**Correct**:
```swift
// Ownership is native to the type
struct Descriptor: ~Copyable {
    private let fd: CInt
    deinit { close(fd) }
}
```

**Incorrect**:
```swift
// ❌ Ownership bolted on via wrapper
typealias Descriptor = Owned<DescriptorTag>
// The wrapper duplicates what the type should express natively
```

**When to use wrappers**: Only when adapting a type from another module that you cannot modify (e.g., wrapping a C library's handle type). For types you control, make them natively `~Copyable`.

**Rationale**: Analogous to `String` being an owned type (not a wrapper around `UnsafeBufferPointer`). When a type represents a resource with lifecycle, ownership should be expressed at the type level, not through an adapter.

**Cross-references**: [MEM-COPY-001], [IMPL-064]


---

### [MEM-COPY-002] Noncopyable in Error Types

**Statement**: `Swift.Error` requires `Copyable`. Move-only values MUST NOT be embedded in `Error` types. Use non-throwing outcome types instead.

```swift
enum Registration.Outcome {
    case success(Registration.Token)
    case failure(Unregistration.Token, Registration.Error)
}
func register(_ token: consuming Unregistration.Token) -> Registration.Outcome
```

**Lint enforcement**: `Lint.Rule.Memory.ErrorNoncopyable` flags struct / enum / class declarations whose conformance list contains both `Error` (or `Swift.Error`) and `~Copyable`. [VERIFICATION: AST Lint.Rule.Memory.ErrorNoncopyable]

---

### [MEM-COPY-003] Noncopyable in Collections

**Statement**: When `~Copyable` types must be stored in collections, wrap the content in a class.

---

### [MEM-COPY-004] Suppression Restatement — Extensions, Refinements, and Conformances Re-Impose `Copyable` Unless Every Suppressed Parameter Is Restated

**Statement**: Suppression (`~Copyable`, `~Escapable`) does not propagate. Extensions, protocol refinements, and protocol conformances MUST restate the suppression for EVERY suppressed generic parameter; any bare form silently re-imposes `Copyable` on the parameters it omits.

```swift
// CORRECT - Available for ALL elements
extension Container where Element: ~Copyable {
    func operation() { }
}

// INCORRECT - Implicitly adds 'where Element: Copyable'
extension Container {
    func operation() { }  // Only available when Element: Copyable!
}
```

Applies to **all extension content**: methods, computed properties, nested types, and typealiases. Also applies to extensions on nested types within a generic outer type — even when the outer type already constrains `Element: ~Copyable`.

**The suppression-restatement family** — the re-imposition fires at every declaration form, not just member extensions:

| Form | Silent defect when bare | Restated form |
|------|------------------------|---------------|
| Member extension `extension Container { }` | Members exist only for Copyable elements | `extension Container where Element: ~Copyable` |
| Protocol refinement `protocol Mutable: Borrowed` | Conformers forced Copyable | `protocol Mutable: Borrowed, ~Copyable` |
| Conformance `extension X: P {}` | The capability's *existence* is Copyable-pinned for move-only instantiations | `extension X: P where Element: ~Copyable {}` |
| Multi-parameter generic | Restating ONE suppressed param re-imposes Copyable on the OTHERS | Restate EVERY suppressed param: `where Element: ~Copyable, Lanes: ~Copyable, Elements: ~Copyable` |

Three sharp edges:

1. **Conformances gate on EXISTENCE, not witness shape.** A bare conformance to a marker protocol with zero witness requirements still Copyable-pins the capability for move-only elements. "It's a marker protocol — nothing to constrain" is invalid reasoning; the conformance itself is the constraint surface.
2. **Projection asymmetry.** Associated-projection constraints (`where S.Element: Copyable`) are LEGAL on extensions but ILLEGAL on suppressible-protocol conformances: `conditional conformance to suppressible protocol 'Copyable' cannot depend on 'S.Element: Copyable'`. Conditional `Copyable`/`Sendable` conformances must be keyed on the parameter itself (`where S: Copyable`), never a projection.
3. **Copyable-element tests MASK the defect.** Every Copyable instantiation satisfies the wrongly re-imposed constraint, so the suite passes with the defect present; only move-only-element coverage surfaces it. Suites for `~Copyable`-generic APIs MUST include move-only instantiations per [TEST-035].

**Worked examples**: the bare `Storage.Heap: Span.Protocol` conformance, the overturned marker-protocol classification, the multi-param `Storage.Split` miss: rationale archive §[MEM-COPY-004].


**Cross-references**: [MEM-COPY-001], [MEM-COPY-006] (propagation gotchas), [MEM-COPY-016] (conditional-Copyable + deinit triangle), [TEST-035] (move-only coverage)

**Lint enforcement**: `Lint.Rule.Memory.ExtensionNoncopyableConstraint` flags `extension` declarations with `consuming`/`borrowing` members whose `where` clause does not contain `~Copyable`. Scope detail + widening candidate (bare conformances and refinements not yet mechanically covered): rationale archive §[MEM-COPY-004]. [VERIFICATION: AST Lint.Rule.Memory.ExtensionNoncopyableConstraint]

---

### [MEM-COPY-005] Nested Accessor Pattern Incompatibility

**Statement**: Non-consuming nested accessor patterns are incompatible with `~Copyable` containers. The accessor struct must store a reference to the container, which requires copying.

For `~Copyable` containers: keep container Copyable, use direct methods, or wait for language evolution.

**Cross-references**: [API-NAME-002], [MEM-COPY-001]

---

### [MEM-COPY-006] ~Copyable Propagation Gotchas

**Statement**: Swift's `~Copyable` suppression fails across certain boundaries:

| Category | Boundary | Status |
|----------|----------|--------|
| 1 | Extension declaration site (value-generic nested types) | RESOLVED in 6.2.4 |
| 2 | Implicit Copyable in extensions | By design — add explicit `where Element: ~Copyable` |
| 3 | Protocol conformance in separate files | Move conformances to same file |
| 4 | Sequence/Collection protocol requirements | No workaround; use `forEach` with borrowing closures |
| 5 | Module emission phase (compound constraints + separate file + Lifetimes flag) | Consolidate to single file |
| 6 | Non-escaping closure capture consumption | Stage through Copyable reference before closure boundary |

**Category 6 detail**: Non-escaping closures cannot consume a `~Copyable` capture without reinitializing it — even when the capture is consumed exactly once on all paths. The compiler demands reinitialization regardless of the callee's guarantee of total consumption. This affects any `withLock { state in state.method(consuming element) }` pattern where `element: ~Copyable` is captured. The ecosystem solution: pass the element as a closure parameter via `withLock(consuming:body:)` ([MEM-OWN-010]) or stage through `Ownership.Slot` (a Copyable reference wrapper) before the closure boundary.

**Cross-module propagation**: RESOLVED in Swift 6.2.4.

**Workaround hierarchy**: (1) explicit `where Element: ~Copyable`, (2) same-file conformances, (3) single-file consolidation, (6) `Ownership.Slot` or `withLock(consuming:body:)`.

**Tracking**: Category 5 — Swift issue #86669

**Cross-references**: [MEM-COPY-004], [MEM-COPY-005], [MEM-OWN-010], [IMPL-070]

---

### [MEM-OWN-001] Consuming Parameters

**Statement**: Use `consuming` when taking ownership. Caller cannot use the value after passing it.

---

### [MEM-OWN-002] Borrowing Parameters

**Statement**: Use `borrowing` for read-only access without ownership transfer.

---

### Ownership Table

| Keyword | Ownership | Caller After Call | Callee Can |
|---------|-----------|-------------------|------------|
| `consuming` | Transferred to callee | Cannot use value | Store, consume |
| `borrowing` | Retained by caller | Can use value | Read only |
| `inout` | Temporarily loaned | Can use value | Mutate |

---

### Type-Level Ownership Naming

**Statement**: A primitive named after a **reference** (Address, Pointer, Handle) SHOULD be non-owning and `Copyable`. A primitive named after a **resource** (String, Array, Allocation) SHOULD be owning and MAY provide a `.View` borrowing type.

---

### [MEM-COPY-015] Never Degrade ~Copyable to Raw Values

**Statement**: When a `~Copyable` typed value (e.g., `Kernel.Descriptor`) appears as an associated value of an enum, struct field, or generic parameter, the containing type MUST be made `~Copyable`. Replacing the typed value with its raw representation (e.g., `Int32`) to avoid the cascade is FORBIDDEN.

**Correct**:
```swift
public enum Result: ~Copyable {
    case open(Kernel.Descriptor)  // typed, ~Copyable propagates
    case error(Kernel.Errno)
}

func consume(_ result: consuming Result) { ... }
```

**Incorrect**:
```swift
public enum Result {
    case open(Int32)  // ❌ degraded to raw — ownership invariant lost
    case error(Int32)
}
```

**Rationale**: The `~Copyable` constraint is a compiler-enforced ownership invariant. Replacing the typed value with `Int32` discards the close-on-drop guarantee, makes double-close possible, and re-introduces the raw-at-API-surface anti-pattern that typed-everywhere refactors exist to eliminate. The cascade (adding `~Copyable` to the container, adding `borrowing`/`consuming` to call sites) is the cost of correctness, not a problem to dodge.

**How to apply**: When the compiler reports `Result is not Copyable` errors, the fix is to add `~Copyable` to the container, not to downgrade the associated value. Add explicit `borrowing` annotations to all parameters that take the container.

**Cross-references**: [MEM-COPY-001], [MEM-COPY-002], [MEM-OWN-015]

---

### [MEM-OWN-015] No Raw Extraction or Reconstruction Across Boundaries

**Statement**: Extracting `_raw` / `_rawValue` from a `~Copyable` typed wrapper and reconstructing the wrapper on the other side of a call, layer, or closure boundary is FORBIDDEN. Use `borrowing`, `consuming`, and `~Copyable` language semantics to transfer ownership; raw round-tripping defeats the typed wrapper's entire purpose.

**Three forbidden guises**:

| Situation | Forbidden Pattern | Use Instead |
|---|---|---|
| L3-policy → L2-typed crossing | `let raw = descriptor._raw; ... ; let l2 = Windows.Kernel.Descriptor(_rawValue: raw)` | `consuming` init on L2 type taking `consuming L3.Descriptor`, OR shared underlying type so no conversion is needed |
| `~Copyable` through `Mutex.withLock` | reconstruct from `rawValue` inside the closure | `var Optional<~Copyable>` + `.take()!` (one-shot consume) |
| New typed-wrapper API | function takes raw, returns typed | function takes/returns typed throughout; raw exists only inside the function body via internal accessor |
| "Pass without consuming" | extract raw, pass raw, reconstruct | `borrowing` parameter |
| Move ownership across call | extract + reconstruct | `consuming` parameter |

**Rationale**: The point of `Kernel.Descriptor: ~Copyable` is to enforce ownership and make the typed surface load-bearing. Round-trip through raw values bypasses ownership, voids `deinit` close-on-drop guarantees, and re-introduces raw-at-API-surface — the exact anti-pattern typed-everywhere refactors (Wave 4c) are eliminating. The L3-policy → L2-typed boundary is the most tempting place to round-trip; doing it there bakes the anti-pattern into the canonical layer-crossing example.

**Detection in code review**: any diff line containing `_raw`, `_rawValue`, or `init(_rawValue:)` outside the wrapper type's own implementation file is suspect. Grep for these patterns when reviewing typed-everywhere refactor output.

**Cross-references**: [MEM-COPY-015], [MEM-OWN-001], [MEM-OWN-002]

---

