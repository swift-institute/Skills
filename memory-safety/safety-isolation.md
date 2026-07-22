# Memory Safety — Safety Isolation and Strict Memory Safety

Part of the **memory-safety** skill. See `SKILL.md` for the navigation hub, frontmatter, and rule index.

Full rationale, provenance, extended worked examples, and the dated changelog: `swift-institute/Research/memory-safety-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MEM-SAFE-020], [MEM-SAFE-021], [MEM-SAFE-022], [MEM-SAFE-023], [MEM-SAFE-024], [MEM-SAFE-025] (SUPERSEDED), [MEM-SAFE-025a], [MEM-SAFE-025b], [MEM-SAFE-025c], [MEM-SAFE-026], [MEM-SAFE-027], [MEM-SAFE-028], [MEM-SAFE-029], [MEM-SAFE-030], [MEM-SAFE-031], [MEM-SAFE-001], [MEM-SAFE-002], [MEM-SAFE-003], [MEM-SAFE-004], [MEM-UNSAFE-001], [MEM-UNSAFE-002], [MEM-UNSAFE-003], [MEM-UNSAFE-004], [MEM-SAFE-010], [MEM-SAFE-011], [MEM-SAFE-012], [MEM-SAFE-013], [MEM-SAFE-014], [MEM-SAFE-015].

---

## Safety Isolation

The organizing principle: isolate unsafe code and prevent virality. Place `@safe` boundaries as low as possible. Maximize absorbers, minimize propagators.

### [MEM-SAFE-020] Isolation Principle

**Scope**: All types with unsafe internals.

**Statement**: `@safe` boundaries MUST be placed as low as possible — as close to the raw pointer operations as achievable. The goal is to maximize absorbers (`@safe`) and minimize propagators (`@unsafe`). Every `@unsafe` in the public API is a deliberate escape hatch, not the primary interface.

**The acid test**: Can a caller use this type's complete public API without ever writing the `unsafe` keyword? If yes, the type is properly isolated.

Every declaration plays one of three roles:

| Role | Annotation | Caller Obligation | Purpose |
|------|-----------|-------------------|---------|
| **Absorber** | `@safe` | None | Encapsulates unsafe internals behind a safe API |
| **Propagator** | `@unsafe` | Must use `unsafe` | Escape hatch that pushes safety responsibility to caller |
| **Unspecified** | (none) | Depends on signature | Compiler infers from types in signature |

**Rationale**: Without isolation, unsafety propagates virally through the call graph. One unsafe type at the bottom infects every layer above it. `@safe` is the firewall that stops propagation.

**Cross-references**: [MEM-SAFE-021], [MEM-SAFE-022], [MEM-SAFE-023]

---

### [MEM-SAFE-021] No `@unsafe` on Encapsulating Types

**Scope**: Types that encapsulate unsafe storage behind a safe API.

**Statement**: Types that encapsulate unsafe storage MUST use `@safe`, NOT `@unsafe`. `@unsafe struct` makes `self` an unsafe type, causing cascading warnings on every property access and method call inside the type's own methods — including safe operations like `precondition(index < capacity)`.

```swift
// INCORRECT - self becomes unsafe, infecting every method body
@unsafe struct Slab<Element> {
    var storage: UnsafeMutablePointer<Element>
    let capacity: Int

    func foo() {
        precondition(index < capacity)  // WARNING: self.capacity involves unsafe type
    }
}

// CORRECT - only actual unsafe operations need unsafe.
// `@safe` on the type is admitted by [MEM-SAFE-025b]; the adjacent
// invariant disclosure satisfies [MEM-SAFE-025c].
// WHY: Category D (SP-5) — pointer-backed value type. `capacity` bounds every
// WHY: indexed access; storage lifetime is owned by `Slab`'s init/deinit pair.
@safe struct Slab<Element> {
    var storage: UnsafeMutablePointer<Element>
    let capacity: Int

    func foo() {
        precondition(index < capacity)  // Clean
        unsafe (storage + index).initialize(to: value)  // Only the actual unsafe op
    }

    @unsafe  // Escape hatch
    func withUnsafePointer(_ body: (UnsafePointer<Element>) -> Void) { ... }
}
```

**Exception**: Types that exist solely AS the unsafe escape hatch (e.g., `Loader.Library.Handle` wrapping a raw `dlopen` handle) MAY use `@unsafe struct`.

**Cross-references**: [MEM-SAFE-020], [MEM-UNSAFE-003]

---

### [MEM-SAFE-022] `@unsafe` Only on Escape Hatches

**Scope**: Public API design for types with unsafe internals.

**Statement**: `@unsafe` MUST only appear on escape hatch methods, never on the primary API. If the primary API requires `unsafe` at the call site, isolation has failed.

```swift
// WHY: Category D (SP-5) — pointer-backed Copyable wrapper. Internal
// WHY: `UnsafeMutablePointer` storage is bounded by `capacity` and never
// WHY: escapes the type's safe API surface (`subscript` / `span`); the
// WHY: `@unsafe` escape hatch is the only path to the raw pointer.
@safe public struct Buffer<Element: ~Copyable>: ~Copyable {
    private var storage: UnsafeMutablePointer<Element>

    // PRIMARY: safe, normative interface
    public subscript(index: Int) -> Element {
        precondition(index >= 0 && index < capacity)
        return unsafe storage[index]
    }

    public var span: Span<Element> { ... }

    // ESCAPE HATCH: only when Span/subscript is insufficient
    @unsafe
    public borrowing func withUnsafePointer<R>(
        _ body: (UnsafePointer<Element>) throws -> R
    ) rethrows -> R { ... }
}
```

**Cross-references**: [MEM-SAFE-012], [MEM-SAFE-020]

---

### [MEM-SAFE-023] Private Unsafe Storage

**Scope**: Stored properties of unsafe pointer types.

**Statement**: Stored properties of unsafe pointer types on `@safe` types MUST be `private` or `internal`. Public properties returning unsafe pointer types MUST be annotated `@unsafe` to signal that they are deliberate escape hatches.

```swift
// INCORRECT - public pointer on @safe Escapable type, pointer can dangle.
// (Also missing the invariant disclosure required by [MEM-SAFE-025c].)
@safe public struct Buffer {
    public let storage: UnsafeMutablePointer<UInt8>  // Leaks unsafety
}

// CORRECT - pointer is private, Span is the public interface, and the
// adjacent invariant disclosure satisfies [MEM-SAFE-025c].
// WHY: Category D (SP-5) — pointer-backed Copyable wrapper. Storage is
// WHY: private; `Span` is the normative read surface and the `@unsafe`
// WHY: closure is the only path to the raw pointer.
@safe public struct Buffer {
    private let storage: UnsafeMutablePointer<UInt8>
    public var span: Span<UInt8> { ... }

    @unsafe public func withUnsafePointer<R>(...) -> R { ... }
}
```

**`~Escapable` exception**: On `~Escapable` types, public pointer properties are **structurally safe** — the view cannot outlive the source, so the pointer cannot dangle. The type system enforces the lifetime boundary that closures (`withUnsafePointer`) enforce by convention. `@unsafe` is still recommended for documentation clarity, but the severity is LOW, not HIGH. (Worked `~Escapable` example: rationale archive §[MEM-SAFE-023].)

| Containing type | Pointer exposure | Severity |
|----------------|-----------------|----------|
| `Escapable` | Public pointer property | HIGH — pointer can dangle |
| `~Escapable` | Public pointer property | LOW — structurally safe |
| Coroutine-scoped (not `~Escapable`) | Public pointer property | MEDIUM — safe by convention, not type system |

**Cross-references**: [MEM-SAFE-012], [MEM-SAFE-014], [MEM-SAFE-020], [MEM-COPY-013], [IMPL-085] (prefer `sending` + `nonisolated(unsafe)` when a lock provides synchronization — narrower than type-wide `@unchecked Sendable`)

**Lint enforcement**: `Lint.Rule.Memory.PrivateUnsafeStorage` flags public stored properties of `Unsafe*Pointer*` types not annotated `@unsafe`. Scope detail: rationale archive §[MEM-SAFE-023]. [VERIFICATION: AST Lint.Rule.Memory.PrivateUnsafeStorage]

---

### [MEM-SAFE-024] `@unchecked Sendable` Semantic Categories

**Scope**: All `@unchecked Sendable` conformances.

**Statement**: `@unchecked Sendable` conformances MUST be classified into one of four semantic categories AND MUST appear on the conformance clause WITHOUT `@unsafe`. Per SE-0458, `@unsafe` is scoped to the four memory-safety dimensions (lifetime / bounds / type / initialization); thread safety is a separate dimension carried by the `@unchecked Sendable` claim alone. Pairing `@unsafe` with `@unchecked Sendable` on the same conformance clause is a deviation from Swift convention: it does not appear anywhere in the Swift stdlib, swift-collections, swift-nio, swift-async-algorithms, or swift-atomics (zero pairs across several hundred surveyed sites). The Category label is documentation discipline (in a `## Safety Invariant` doc-comment or adjacent `// SAFETY:` / `// WHY:` block), not a trigger for additional `@unsafe` annotation.

| Category | Semantics | Annotation | Safety invariant |
|----------|-----------|------------|-----------------|
| **A: Synchronized** | Internal mutex, atomic, or lock | `@unchecked Sendable` (bare, no `@unsafe` on the conformance) | Document synchronization mechanism |
| **B: Ownership transfer** | `~Copyable` prevents sharing; Sendable enables move | `@unchecked Sendable` (bare, no `@unsafe` on the conformance) | Document `~Copyable` ownership guarantee |
| **C: Thread-confined** | Single-thread access; `@unchecked Sendable` used to cross one boundary | **Should be `~Sendable`** (SE-0518) | DEFER until `~Sendable` stabilizes |
| **D: Structural workaround** | Type is value-like and safe, but compiler inference cannot prove Sendable due to a structural limitation | `@unchecked Sendable` (bare, no `@unsafe` on the conformance) | Document which inference gap the annotation bridges |

**Category A** — synchronized:
```swift
/// ## Safety Invariant
/// Internal `Mutex<State>` serializes all access.
extension Kernel.Thread.Synchronization: @unchecked Sendable {}
```

**Category B** — ownership transfer:
```swift
/// ## Safety Invariant
/// `~Copyable` unique ownership ensures only one thread can access at a time.
/// Transfer via `consuming` parameter relinquishes the sender's access.
@safe public struct Arena: ~Copyable { ... }
extension Arena: @unchecked Sendable {}
```

**Category C** — thread-confined:
```swift
// CURRENT (semantic lie — type is not safe to send arbitrarily)
final class Ring: @unchecked Sendable { ... }

// FUTURE (SE-0518) — express the truth at the type level
final class Ring: ~Sendable { ... }
// Transfer to poll thread uses explicit unsafe at the transfer site
```

Category C types MUST adopt `~Sendable` instead of `@unchecked Sendable`. `@unsafe` does not apply to thread-confined types in current Swift — the real fix is expressing confinement at the type level.

**Orthogonal: `@unsafe` on type or method declarations**: when a type's storage carries unsafe types (raw pointers, etc.) AND consumers should see a warning at every use, apply `@unsafe` on the **type or extension declaration** (a separate syntactic position from the conformance clause). The Sendable conformance still carries bare `@unchecked Sendable`. Example:

```swift
// @unsafe on the TYPE declaration (memory-safety claim);
// @unchecked on the CONFORMANCE clause (thread-safety claim).
// Different syntactic positions; never combined as `@unsafe @unchecked Sendable`.
@unsafe
public struct UnsafePointerWrapper: @unchecked Sendable {
    let pointer: UnsafeMutablePointer<UInt>
}
```

Apply `@unsafe` to individual methods/properties/initializers (e.g., `withUnsafePointer`) per SE-0458; never to the Sendable protocol slot on the conformance clause.

**Category D** — structural workaround (three recognized subpatterns):

Category D covers sites where the type is structurally value-like and concurrency-safe, but Swift's compiler cannot synthesize `Sendable` automatically because of a specific structural limitation. The annotation compensates for the inference gap; the safety invariant is inherent to the type's shape, not to a synchronization mechanism.

| Subpattern | Structure | Why inference fails |
|-----------|-----------|---------------------|
| **SP-2: `@_rawLayout` bridges** | Type uses `@_rawLayout` attribute to specify explicit memory layout (e.g., atomics storage) | `@_rawLayout` types are not eligible for Sendable synthesis; the annotation bridges the gap for types that are provably safe by layout |
| **SP-4: Non-Sendable generic parameter** | Type is generic over a parameter that cannot be constrained `: Sendable` (e.g., protocols like `AsyncIteratorProtocol`, closure types) but the type's actual use never exposes the parameter in a racy way | The generic parameter is structurally non-Sendable, but the type's API wraps it safely; the annotation is the only way to express the composite type's Sendable contract |
| **SP-5: Pointer-backed Copyable** | Value-like wrapper over a pointer where the pointer's referent is immutable / by-construction uniquely owned | The pointer is a reference type as far as Sendable inference is concerned; the annotation declares the wrapper's value semantics |

**Required doc form for Category D**:

```swift
/// ## Safety Invariant (Category D — structural workaround)
/// SP-N subpattern: {explanation of the inference gap}.
/// Why safe: {the structural property that makes this concurrency-safe}.
extension MyType: @unchecked Sendable {}
```

**What Category D is NOT**:

| Mistaken use | Correct classification |
|--------------|-----------------------|
| "My type has synchronization and I find D's explanation easier" | A |
| "My type is `~Copyable` and owns a resource" | B |
| "My type is thread-confined but I don't want to adopt `~Sendable`" | C (pending SE-0518) |
| "I didn't think through the invariant and D seems permissive" | Stop and classify properly |

Category D is the narrow escape hatch for provable-safe types the compiler cannot verify, not a bucket for unclassified annotations.

**Enablement**: `~Sendable` is available via `.enableExperimentalFeature("TildeSendable")` in Swift 6.3.

**Category C deferral status (2026-06-01)**: `TildeSendable` adoption across canonical packages = **0** (verified). The institute defers `~Sendable` adoption until **SE-0518 leaves experimental / is accepted** (`TildeSendable` is available experimentally in Swift 6.3 but not stabilized). Concrete eliminable Cat C surface = **1 site** — `File.Directory.Contents.IteratorHandle` (`swift-file-system/.../File.Directory.Contents.IteratorHandle.swift`, already anchored `WHEN TO REMOVE: After ~Sendable (SE-0518) stabilizes`). `Ownership.Mutable.Unchecked` (`swift-ownership-primitives/.../Ownership.Mutable.Unchecked.swift`) is a **permanent deliberate Cat C opt-in** that `~Sendable` does NOT supersede. **Revisit trigger**: SE-0518 acceptance / `TildeSendable` leaving experimental → re-run the single-site `IteratorHandle` flip as a PRINCIPAL-CALL per `swift-institute/Audits/sendable-inventory-2026-05-13.md` §13. Do not enable `TildeSendable` ecosystem-wide before then.

**Reference & provenance**: current ecosystem inventories, the superseded tilde-sendable inventory, the Category-D adjudication survey, and the 2026-05-13 BREAKING annotation revision ([SKILL-LIFE-003] Breaking — Cat A/B/D changed from `@unsafe @unchecked Sendable` to bare `@unchecked Sendable`, per the peer-attribute framing already in the Statement): rationale archive §[MEM-SAFE-024].

**Cross-references**: [MEM-SEND-001], [MEM-SEND-002], [MEM-SAFE-020]

**Lint enforcement**: `Lint.Rule.Memory.UncheckedSendableCategorized` flags `@unchecked Sendable` conformances that ALSO carry `@unsafe` on the same conformance clause (inverted 2026-05-13 per the BREAKING annotation revision). Scope detail: rationale archive §[MEM-SAFE-024]. [VERIFICATION: AST Lint.Rule.Memory.UncheckedSendableCategorized]

---

### [MEM-SAFE-025] `nonisolated(unsafe)` Globals Require `@safe` [SUPERSEDED 2026-05-11]

**Statement**: SUPERSEDED 2026-05-11 (Wave 3 Thread 7) by [MEM-SAFE-025a] (invariant-comment requirement) and [MEM-SAFE-025b] (`@safe` attribute forbidden in Sources/). The institute policy converged on forbidding `@safe` in favour of free-form `// SAFETY: ...` / `// WHY: ...` invariant comments. See `swift-institute/Research/mem-safe-025-reconciliation.md` for the decision rationale.

**Historical body**: `nonisolated(unsafe)` globals that are safely encapsulated MUST be annotated with `@safe`. Pattern:

```swift
@safe @usableFromInline
nonisolated(unsafe) let _sentinel: UnsafeMutableRawPointer = .allocate(capacity: 0)
```

The original rule was enforced by `Lint.Rule.Memory.NonisolatedUnsafeSafe`; the supersession replaces it with `Lint.Rule.Memory.NonisolatedUnsafeInvariant` ([MEM-SAFE-025a]) + `Lint.Rule.Memory.SafeForbidden` ([MEM-SAFE-025b]). Migrated sites move from `@safe`-attribute form to adjacent-comment form.

**Cross-references**: [MEM-SAFE-025a], [MEM-SAFE-025b]

---

### [MEM-SAFE-025a] `nonisolated(unsafe)` Requires Invariant Comment

**Scope**: Module-level, static, or property `nonisolated(unsafe)` declarations.

**Statement**: Every `nonisolated(unsafe)` declaration MUST carry an adjacent invariant comment of the form `// SAFETY: ...` or `// WHY: ...` that cites the encapsulation invariant in prose. The comment MUST immediately precede the declaration (no intervening blank line); it MAY be multi-line and MAY cite skill rules (e.g., `[MEM-SAFE-024]`).

```swift
// CORRECT — adjacent invariant comment cites the encapsulation guarantee
// SAFETY: Allocated once at module init; pointee never mutated after init.
// SAFETY: Used as a sentinel for empty-buffer comparison only.
@usableFromInline
nonisolated(unsafe) let _emptyBufferSentinel: UnsafeRawPointer = ...

// INCORRECT — no adjacent invariant comment
@usableFromInline
nonisolated(unsafe) let _sentinel: UnsafeMutableRawPointer = .allocate(capacity: 0)
```

(Further variants — the multi-line `// WHY:` form, the non-adjacent blank-line defect: rationale archive §[MEM-SAFE-025a].)

**Rationale**: `nonisolated(unsafe)` encodes a temporal invariant ("set once before any concurrent read", "pointee never mutated") that the type system cannot express; the invariant is stated in prose at the declaration site so reviewers can verify it there (rationale archive §[MEM-SAFE-025a]).

`nonisolated(unsafe)` mutable statics that ARE accessed concurrently MUST use synchronization (`Mutex`, `Atomic`) instead of relying on temporal invariants — the comment requirement does not authorize concurrent mutation, only documents the encapsulation that makes the temporal invariant sound.

**Cross-references**: [MEM-SAFE-020], [MEM-SAFE-024], [MEM-SAFE-025b], [MEM-SEND-001]

**Lint enforcement**: `Lint.Rule.Memory.NonisolatedUnsafeInvariant` flags `nonisolated(unsafe)` declarations whose leading trivia does not contain an adjacent `// SAFETY:` or `// WHY:` line (adjacency requirement per the Statement). Scope detail: rationale archive §[MEM-SAFE-025a]. [VERIFICATION: AST Lint.Rule.Memory.NonisolatedUnsafeInvariant]

---

### [MEM-SAFE-025b] `@safe` Attribute Admitted with Invariant Disclosure

**Scope**: All declarations in `Sources/` of any ecosystem package.

**Statement**: The `@safe` attribute MAY appear on any declaration in `Sources/`. When it does, it MUST carry an adjacent invariant disclosure per [MEM-SAFE-025c]. `@safe` is admitted wherever SE-0458 permits it — type declarations (struct, class, enum, actor, extension), methods, properties (let/var), initializers, subscripts, typealiases, associated types.

```swift
// CORRECT — `@safe` accompanied by an adjacent `// WHY:` disclosure
// WHY: Category D (SP-5) — UnsafeRawPointer storage blocks structural
// WHY: Sendable inference. COW discipline ensures each isolation domain
// WHY: owns its unique _Storage after first write.
@safe @usableFromInline
final class _Storage: @unchecked Sendable { ... }

// INCORRECT — `@safe` without any adjacent invariant disclosure
@safe @usableFromInline
final class _Storage: @unchecked Sendable { ... }
```

**Rationale**: per SE-0458, `@safe` is the machine-checkable absorber claim that materializes [MEM-SAFE-020]'s absorber role; per cross-language convention the human-auditable disclosure accompanies it — comments and attributes are complementary, both required where `@safe` is used. Full rationale, the Wave 3 Thread 7 inversion history, and further example variants: rationale archive §[MEM-SAFE-025b].

**Author judgment on cluster C (pure-documentation `@safe`)**: Some `@safe` sites have no mechanical effect (the declaration's signature does not contain unsafe types that would otherwise be diagnosed). The attribute on such sites serves as a documentation marker rather than a diagnostic-suppression mechanism. Both retaining `@safe` (with disclosure) and dropping it are internally consistent under this rule; per-site removal is an author-judgment decision, not a lint requirement.

**Cross-references**: [MEM-SAFE-020], [MEM-SAFE-021], [MEM-SAFE-022], [MEM-SAFE-023], [MEM-SAFE-024], [MEM-SAFE-025a], [MEM-SAFE-025c]

**Lint enforcement**: `Lint.Rule.Memory.SafeAttributeUndocumented` flags any `@safe`-attributed declaration whose leading trivia does not contain an adjacent `// SAFETY:` / `// WHY:` comment OR a `## Safety Invariant` doc-comment section (inverted from `Lint.Rule.Memory.SafeForbidden`, Option B DECISION 2026-05-12). [VERIFICATION: AST Lint.Rule.Memory.SafeAttributeUndocumented]


---

### [MEM-SAFE-025c] `@safe` Declarations Require Invariant Disclosure

**Scope**: All `@safe`-attributed declarations in `Sources/`.

**Statement**: Every `@safe` declaration MUST carry an adjacent invariant disclosure: either (a) one or more `// SAFETY: ...` / `// WHY: ...` line comments in the declaration's leading trivia, OR (b) a `## Safety Invariant` section within the declaration's `///` doc-comment. The disclosure SHOULD cite a [MEM-SAFE-024] Category (A/B/C/D) when the site is categorizable; multi-line free-form prose is acceptable when not. Disclosure is mandatory for documentation purposes even when the `@safe` attribute does not mechanically suppress any compiler diagnostic on the declaration's specific shape.

```swift
// CORRECT — adjacent `// WHY:` block citing a [MEM-SAFE-024] Category
// WHY: Category A — synchronized via internal `Mutex<State>`; the
// WHY: pointer is only handed out within the mutex's critical section.
@safe
public struct LockedState {
    private let lock = Mutex<State>(.initial)
}

// CORRECT — `## Safety Invariant` doc-comment section
/// A pinned wrapper around raw bytes.
///
/// ## Safety Invariant
/// Storage allocated once at init and never reassigned; `capacity` bounds
/// every indexed access; storage lifetime is owned by `Pinned`'s init/deinit
/// pair. See [MEM-SAFE-024] Category D (SP-5).
@safe
public struct Pinned {
    nonisolated(unsafe) let storage: UnsafeMutableRawPointer
    let capacity: Int
}

// INCORRECT — `@safe` with no adjacent disclosure
@safe
public struct Pinned {
    private let storage: UnsafeMutableRawPointer
}
```

(Further variants — free-form `// SAFETY:` prose, `@safe` on a method, the non-adjacent blank-line defect: rationale archive §[MEM-SAFE-025c].)

**Rationale**: the corpus carries both halves of a safety claim — the machine-checked `@safe` attribute (SE-0458) and the human-auditable prose disclosure (rationale archive §[MEM-SAFE-025c]).

**Cross-references**: [MEM-SAFE-020] (Isolation Principle — `@safe` is the absorber mechanism), [MEM-SAFE-024] (Category taxonomy), [MEM-SAFE-025b] (inverted to admit `@safe`).

**Lint enforcement**: `Lint.Rule.Memory.SafeAttributeUndocumented` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Memory`).

---

## Strict Memory Safety (SE-0458)

### [MEM-SAFE-001] Enable Strict Memory Safety

**Scope**: All ecosystem packages.

**Statement**: All packages MUST enable strict memory safety via `.strictMemorySafety()`.

```swift
// Package.swift
.target(
    name: "Buffer Primitives",
    swiftSettings: [.strictMemorySafety()]
)
```

---

### [MEM-SAFE-002] Unsafe Expression Marking

**Statement**: Each unsafe operation requires its own `unsafe` acknowledgment. Expression granularity.

```swift
// For assignments to unsafe storage, wrap the entire expression
unsafe (self.raw = Unmanaged.passRetained(instance).toOpaque())

// INCORRECT - destination uncovered
self.raw = unsafe Unmanaged.passRetained(instance).toOpaque()
```

- `@unsafe` on a function declares that *calling* is unsafe
- Operations *within* still require individual `unsafe` markers
- `unsafe` does NOT propagate into closures — mark both outer call and inner operations

---

### [MEM-SAFE-003] Warning Classification

**Statement**: Two buckets:

| Category | Description | Action |
|----------|-------------|--------|
| **Bucket A** | Operations requiring `unsafe` acknowledgment | Mark with `unsafe` |
| **Bucket B** | "Struct has storage involving unsafe types" | Decide `@safe` or `@unsafe` per [MEM-SAFE-021] |

---

### [MEM-SAFE-004] Five Dimensions of Memory Safety

| Dimension | Guarantee | Mechanism |
|-----------|-----------|-----------|
| Lifetime Safety | Values accessed within their lifetime | ARC, `~Copyable`, `@_lifetime` |
| Bounds Safety | Accesses within allocation bounds | Array bounds checking |
| Type Safety | Values accessed using compatible types | Strong typing |
| Initialization Safety | Values initialized before use | Definite initialization |
| Thread Safety | Invariants maintained under concurrency | `Sendable`, actors, Swift 6 |

---

### [MEM-UNSAFE-001] Unsafe Operation Tracking

**Statement**: Unsafe operations MUST be tracked and marked with `unsafe`. Warnings serve as a TODO list.

---

### [MEM-UNSAFE-002] Lifetime Annotations

**Statement**: APIs exposing pointers with limited lifetime MUST use `@_lifetime` annotations.

```swift
// CORRECT
extension Buffer.Aligned {
    @_lifetime(borrow self)
    func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) -> R) -> R {
        body(UnsafeRawBufferPointer(start: pointer, count: size))
    }
}

// INCORRECT - Pointer can escape scope
func getPointer() -> UnsafeRawPointer { return pointer }
```

---

### [MEM-UNSAFE-003] Safe Attribute

**Statement**: Use `@safe` to assert that a declaration containing unsafe operations maintains safety through careful design. The `@safe` attribute is admitted by `[MEM-SAFE-025b]` on any declaration in `Sources/` provided it carries an adjacent invariant disclosure per `[MEM-SAFE-025c]` (a `// SAFETY:` / `// WHY:` comment block, or a `## Safety Invariant` doc section).

```swift
// `@safe` admitted by [MEM-SAFE-025b]; the adjacent disclosure satisfies
// [MEM-SAFE-025c]. The disclosure cites a [MEM-SAFE-024] Category.
// WHY: Category B — ownership transfer. `Value: Sendable` is immutable;
// WHY: `Box`'s only mutation path is class identity (refcount), already
// WHY: synchronized by the runtime.
@safe
public final class Box<Value: ~Copyable & Sendable>: @unchecked Sendable {
    // Safe despite @unchecked - immutable value with Sendable constraint
}
```

---

### [MEM-SAFE-010] No Dual Public Overloads

**Statement**: Public APIs MUST NOT provide both safe and unsafe overloads. Unsafe implementation SHOULD be `internal` or `@usableFromInline internal`.

---

### [MEM-SAFE-011] Inline Clarity Over Helper Consolidation

**Statement**: Unsafe operations SHOULD be inline and explicit, not hidden behind convenience helpers.

---

### [MEM-SAFE-012] Span Family as Normative Interface

**Statement**: APIs providing contiguous memory access MUST use the `Span` family as the primary interface, matched to the access mode: `Span<T>` for read, `MutableSpan<T>` for in-place mutation of the initialised region, `OutputSpan<T>` for appending into uninitialised capacity (per [MEM-SPAN-003]). Raw `Unsafe*Pointer` access is a last-resort escape hatch ([MEM-SAFE-015]), never the primary API. There is no access mode for which a raw pointer is "the primitive" and a span is the wrapper — the span family is the surface; the pointer is the implementation detail beneath it.

```swift
// CORRECT — span family, mode-matched
public struct Buffer {
    public var span: Span<UInt8> { ... }                 // read
    public var mutableSpan: MutableSpan<UInt8> { ... }   // in-place, initialised region
    // append into uninit tail — OutputSpan tracks initializedCount, no UB
    public mutating func withOutputSpan<R>(
        addingCapacity n: Int, _ body: (inout OutputSpan<UInt8>) -> R
    ) -> R { ... }
    @unsafe public func withUnsafeBufferPointer<R>(...) rethrows -> R  // [MEM-SAFE-015] last resort
}

// INCORRECT - Pointer-first
public struct Buffer {
    public var baseAddress: UnsafePointer<UInt8>? { ... }
}
```

(Further incorrect variant — vending a raw pointer for the uninitialised tail: rationale archive §[MEM-SAFE-012].)

**Cross-references**: [MEM-SAFE-013], [MEM-SAFE-014], [MEM-SAFE-015], [MEM-SPAN-001], [MEM-SPAN-003]

---

### [MEM-SAFE-013] API Surface Reduction as Safety

**Statement**: Removing public unsafe overloads in favor of scoped accessors reduces API surface without reducing capability.

---

### [MEM-SAFE-014] Closure Scope Over Property Access

**Statement**: When NO member of the Span family fits (see [MEM-SPAN-003] and the gate in [MEM-SAFE-015]) and a genuine `Unsafe*` operation is unavoidable, that unsafe operation MUST use closure-scoped access (`withUnsafe*`) rather than a pointer property. Properties make unsafe operations look safe. This rule governs the *shape* of the last-resort hatch; it does NOT license reaching for a pointer when a span exists.

**Span family covers more than "read a contiguous region"** — do NOT fall through to a `withUnsafe*` closure for a case a span handles:

| Need | Surface (NOT a raw pointer) |
|------|-----------------------------|
| Read initialised region | `span` → `Span<T>` |
| Mutate initialised region in place | `mutableSpan` → `MutableSpan<T>` |
| Append into the *uninitialised* tail | `OutputSpan<T>` via `withOutputSpan(addingCapacity:)` — tracks `initializedCount`, safe over uninit memory |

The historical justification "`MutableSpan` is UB over uninitialised memory, therefore vend a raw `UnsafeMutableBufferPointer` / `withUnsafe*` closure" is **superseded**: `OutputSpan` is the safe surface for the uninitialised-tail case. Reach for `withUnsafe*` only for true non-span scenarios (C string/`CChar` interop, foreign FFI buffers, opaque-handle bridging).

```swift
// CORRECT - genuine non-span case (C interop), closure enforces lifetime
path.withUnsafeCString { ptr in usePointer(ptr) }

// INCORRECT - Property makes danger invisible
public var unsafeCString: UnsafePointer<CChar> {
    _storage.baseAddress  // Can escape and dangle
}
```

(Further incorrect variant — `withUnsafe*` over an uninitialised tail when `OutputSpan` fits: rationale archive §[MEM-SAFE-014].)

**Cross-references**: [MEM-SAFE-012], [MEM-SAFE-015], [MEM-SPAN-003]

---

### [MEM-SAFE-015] Raw Pointer Is the Last Resort, Deeply Encapsulated

**Statement**: `Unsafe*Pointer` / `Unsafe*BufferPointer` MUST NOT appear on a public or `package` API surface as the primary way to read, mutate, or fill memory. The Span family ([MEM-SPAN-003]) is the default surface: `Span` (read), `MutableSpan` (in-place over the initialised region), `OutputSpan` (append into uninitialised capacity). A raw pointer is admitted ONLY when ALL hold:

1. **No Span fits** — the scenario is genuinely outside the span model (C-string/`CChar` interop, FFI buffers passed by raw address, opaque-handle bridging, an allocator/`@_rawLayout` substrate below the span layer). "Uninitialised tail" is NOT such a scenario — `OutputSpan` covers it.
2. **Lowest level** — the pointer lives at the deepest implementation layer (the conformer/substrate), never re-exported upward. Per [MEM-SAFE-020]/[MEM-SAFE-022] the `@unsafe` boundary is pushed as low as possible; per [MEM-SAFE-010] there is no public safe+unsafe overload pair.
3. **`@unsafe`-marked** per [MEM-SAFE-002], and closure-scoped per [MEM-SAFE-014] when it is an escape-hatch accessor (not a `~Escapable` view).
4. **Justified in a comment** — an adjacent `// WHY:` / `// SAFETY:` line states *why no Span fits* (which interop boundary or substrate constraint forces the raw pointer). A raw pointer with no such comment is a defect, not an escape hatch.

```swift
// CORRECT — substrate hatch, justified, not on the public surface
extension Storage.Heap {
    // WHY: no Span fits — this is the allocator substrate beneath `span`/`mutableSpan`/`outputSpan`;
    // WHY: ManagedBuffer's tail is reached by raw pointer once, here, and never re-exported.
    @unsafe func withUnsafeElements<R>(_ body: (UnsafeMutableBufferPointer<Element>) -> R) -> R { ... }
}

// INCORRECT — raw pointer as the per-slot / whole-region primitive
public func pointer(at slot: Index) -> UnsafeMutablePointer<Element>   // ❌ use subscript / span family
```

**Retention discipline**: when a typed surface replaces a raw accessor, any RETAINED `@unsafe` accessor on a conformer MUST cite the *specific* language/compiler limitation that necessitates it AND a `REMOVE-WHEN:` condition under which it dissolves; absent both, the retained accessor is migration debt to delete, not a sanctioned hatch. (Origin: the Storage.Protocol de-pointering — Heap/Inline retained `pointer(at:)` with cited limitations, Pool/Slab had none and were deleted; Reflection 2026-06-02 storage-protocol-depointer-merge.)

**Why**: the ecosystem direction is Span-first — this rule inverts the default: span first, pointer only when the four gates above are all satisfied and documented (rationale archive §[MEM-SAFE-015]).


**Cross-references**: [MEM-SAFE-002], [MEM-SAFE-010], [MEM-SAFE-012], [MEM-SAFE-014], [MEM-SAFE-020], [MEM-SAFE-022], [MEM-SPAN-003], [INFRA-109]

---

### [MEM-SAFE-026] No Optional-Based Replacement for `@_rawLayout`

**Statement**: Replacing `@_rawLayout` storage with `InlineArray<capacity, Optional<Element>>` or any approach that requires `Element: Copyable` or that wastes space for Optional tags is FORBIDDEN. When exploring workarounds for `@_rawLayout` compiler bugs, the `@_rawLayout` infrastructure MUST be preserved.

**Why**: `@_rawLayout` is a fundamental design choice for zero-overhead dense packing with `~Copyable` element support. Replacing it with Optional-based storage destroys two load-bearing properties:

1. **Type theory**: `Optional<Element>` requires `Element: Copyable`, defeating the entire reason `@_rawLayout` was chosen.
2. **Memory layout**: Optional adds a discriminant tag per element, wasting space and breaking dense-packing guarantees.

**Acceptable workaround directions** (none of which remove `@_rawLayout`):
- Targeted `@inlinable` removal at the bug site
- Compiler flag suppression with citation
- SIL analysis to characterize the miscompile
- Filing a compiler bug report against swiftlang/swift
- Restructuring the surrounding API to avoid the trigger

**Cross-references**: [MEM-SAFE-001], [MEM-COPY-001], [MEM-COPY-014]

---

### [MEM-SAFE-027] `_deinitWorkaround` Placement for the Cross-Package `@_rawLayout` Deinit-Skip (`swift#86652`)

**Statement**: `swiftlang/swift#86652` (**Wall 2** — a *codegen* bug, distinct from the Wall-1 type-system law in [MEM-COPY-016]) misclassifies a `~Copyable` value's witness as *trivial* cross-package when its `@_rawLayout` storage is reached through cross-module composition, so the `deinit` is **silently skipped** and elements leak. The `_deinitWorkaround: AnyObject?` non-triviality marker MUST be placed by composition shape:

- **Composed** substrate (`Storage.Contiguous<Memory.Inline>` — the `@_rawLayout` leaf lives in another module) → the workaround lives at the **substrate leaf** (`Memory.Inline`), so non-triviality propagates *once* up through the composition and the buffer `deinit` fires cross-package.
- **Direct** `@_rawLayout` (same-module nested storage, e.g. `Buffer.Arena.Inline`'s `_Elements`) → the workaround lives **on the type itself**.
- **NEVER** add a buffer-level `_deinitWorkaround` over a **nested** `@_rawLayout` substrate — it **SIGSEGV-miscompiles** (empirically: composed + double-WA → SIGSEGV; bug-catalog §A14 matrix).

**Removal gate**: the workaround is removable when `swift#86652` lands upstream.

**Rationale**: keeps the **codegen** workaround (Wall 2) in a different rule family from the **type-system** law (Wall 1, [MEM-COPY-016]) so the two are not conflated. Sits beside [MEM-SAFE-026] as `@_rawLayout`-compiler-bug-workaround discipline.


**ADT Tower rider (2026-07-02)**: re-affirmed on 6.3.3 with a sharper shape — the NAKED cross-package skip is DEBUG-only (release specializes past it: naked store 0/2 deinits DEBUG, 2/2 release; with `_deinitWorkaround` 2/2 both). The workaround stays REQUIRED because debug leaks are real leaks. Probe pointer: `Experiments/adt-tower-walls` (W-B/W-C). Provenance: `Research/adt-tower.md` §3 W2, §4.7.

**Cross-references**: [MEM-SAFE-026] (preserve `@_rawLayout`; sibling workaround discipline), [MEM-COPY-016] (the distinct Wall-1 law), [DS-002], [DS-023], [DS-025], [MEM-SAFE-028] (the sibling devirtualized-destroy rule).

---

### [MEM-SAFE-028] The Drain-Box Rule — a Refcounted Box Over Move-Only Storage OWNS Element Teardown

**Statement**: A refcounted `final class` box wrapping a `~Copyable` storage/buffer value (the CoW column shape — `Shared<Element, B>`'s `Box`) MUST perform element teardown in its OWN class `deinit`, by draining the wrapped value through public mutating API, and close the drain with `_fixLifetime(self)` (the stdlib `_ContiguousArrayStorage` idiom). It MUST NOT rely on the wrapped struct's deinit oracle running during automatic field destruction.

**Why (the miscompile)**: on Swift 6.3.2 under `-O`, once `isKnownUniquelyReferenced` has been applied to the box, the optimizer devirtualizes the final release, and the synthesized destroy of a **generic-namespace-NESTED** `~Copyable` struct (the `Storage<Allocation>.Contiguous<Element>` shape) **omits the user deinit while still destroying its stored fields** — elements leak while their bytes are freed. An empty box `deinit {}` does NOT restore it; the [MEM-SAFE-027] `AnyObject?` field does NOT (different bug than the triviality misclassification); flat top-level generics and no-uniqueness-call paths are unaffected. An effectful drain in the class deinit body DOES restore correct teardown.

**Why the rule is design, not just workaround**: with the drain, correctness no longer depends on whether the compiler runs the struct's oracle — count-driven teardown converges with the stdlib `_ContiguousArrayStorage` factoring (rationale archive §[MEM-SAFE-028]).

**How to apply**: the drain strategy is column-specific (linear prefix → `removeAll(keepingCapacity: true)`; wrapped/sparse disciplines supply their own) — store it on the box as a `@Sendable` closure captured at the pinned construction site, keeping the box column-agnostic.

**Removal gate**: an upstream fix to the devirtualized-destroy user-deinit omission (filing DEFERRED per R-6 — the durable repro is `swift-institute/Experiments/cow-box-deinit-omission-miscompile`). The drain remains correct (and stdlib-convergent) even after a fix.


**ADT Tower rider (2026-07-02)**: re-probe on each toolchain bump is a STANDING wave gate (adt-tower §9.5) — re-confirmed on 6.3.3 (5 shapes skip the user deinit at -O; only the DRAIN-box shape is safe). `Shared` is the only CoW column. The reproducer package `Experiments/cow-box-deinit-omission-miscompile` is the witness. Provenance: `Research/adt-tower.md` §3 W5, §4.7.

**Cross-references**: [MEM-SAFE-027] (the sibling cross-package deinit-skip; different mechanism, same family), [MEM-COPY-016] (the Box-relocation triangle this rule completes), [DS-025], [DS-029].

---

### [MEM-SAFE-029] No Generic Address Caching — Derive Per Access Through the Seam

**Statement**: Generic code over a storage/pooling capability seam MUST derive addresses PER
ACCESS through the seam's observation (`pointer(at:)`-class requirements) and MUST NOT cache
them (no stored base pointers, no stride caches) across moves of the owning value. A cached
base is lawful ONLY behind a concrete heap-pinned path (`where Resource == Memory.Heap`-class
pins), never in generic code.

**Why**: the capability's quantifier is real — an inline-backed resource (`Memory.Inline<n>`)
moves its BYTES with the value, so any address cached before a move dangles after it. Only the
heap-conformer refinement strengthens borrow-scoped address stability to whole-lifetime
stability (`Memory.Pooling` law L3). (Origin incident — the pre-W5 `Storage.Generational` caches: rationale archive §[MEM-SAFE-029].)

**Correct** (generic — derive per access, including in `deinit`):
```swift
internal func _ptr(at i: Int) -> UnsafeMutablePointer<Element> {
    unsafe allocation.pointer(at: Index<Memory.Pool.Slot>(Ordinal(UInt(i))))
        .assumingMemoryBound(to: Element.self)
}
```

**Incorrect** (generic cache):
```swift
internal var _baseRaw: UnsafeMutableRawPointer  // ❌ dangles when an inline resource moves
internal let _slotStride: Int                   // ❌ second-guesses the pool's layout
```

**Rationale**: addresses are DERIVED observations of slot identity, not state (the pooling
ontology: primitive = slot identity; derived = address/arithmetic; refinement =
lifetime-stable region). Caching them in generic code silently assumes the heap refinement.


**Cross-references**: [MEM-SAFE-027], [PATTERN-059] (construction pins, operations generic),
[API-IMPL-023] (the deletable-seam discipline).

---

### [MEM-SAFE-030] The Read-Only Fence — Read-Only Regimes Never Conform `Memory.Region`

**Statement**: A read-only memory regime — a mapped read-only window (`Memory.Map` with `access: .read`), an immutable foreign buffer (the `Memory.Foreign.Immutable` sketch), any provenance whose bytes MUST NOT be written — MUST NOT conform to `Memory.Region`. Reads ride `Swift.Span` via `Span.Protocol`; `Memory.Region` is reserved for write-capable regions.

**Why**: `Memory.Region`'s only production consumer is storage construction: `Storage.Contiguous` resolves the region's base with `assumingMemoryBound(to:)` and hands out an unconditional `_modify` (`Storage.Contiguous.swift:100–111`; the seam witness `Storage.Contiguous+Store.Protocol.swift:25–34`). The conformance buys exactly one thing — entry into the storage tier — and that entry is UB (faulting writes) for read-only memory: a conforming read-only region is one convenience init away from a faulting write. Non-conformance makes the misuse unrepresentable ([MEM-SAFE-013]). Structurally, a read-only view also has nothing for the storage tier to manage — the initialization ledger and deinit oracle exist for element *lifecycle*, and immutable bytes arrive initialized and die with their envelope; reading is Span's tier ([MEM-SAFE-012]).

**How to apply**:
- Read-only envelopes expose a borrowing `span: Span<Byte>` (+ `Span.Protocol`) per [MEM-SPAN-001] — the shipped pattern is `Memory.Map.Region.span` / `Storage.Contiguous: Span.Protocol` (the owned typed read-Span exemplar; a borrowed contiguous view is a bare `Swift.Span`). The former `Memory.Contiguous: Span.Protocol` exemplar was dissolved 2026-06-23 (`memory-contiguous-dissolution.md`).
- A mutable counterpart, if ever wanted, gates on the regime's own access witness (`access.allows.write`-class) — a separate decision; never `Memory.Region` entry.
- No read/write constraint split of `Store.Protocol` either: the 4+1-op seam is mutation by design; serving readers is not its job.


**Cross-references**: [MEM-SAFE-012] (Span as normative interface), [MEM-SAFE-013] (API-surface reduction as safety), [MEM-SPAN-001], [MEM-SPAN-003]

---

### [MEM-SAFE-031] Two Unsafe Surfaces of an Owned Region — Permanent Floor vs SE-0465-Gated Span

**Statement**: An owned raw region's `unsafe` is **two distinct surfaces**, reasoned about and budgeted separately:

- **(a) The allocation floor** — `allocate`/`deallocate` plus the cached base pointer the region holds for its lifetime. **Permanent and irreducible**: Swift has no safe stable-base *runtime* raw allocator (an inline region escapes `unsafe` only via compile-time `@_rawLayout`; a heap region cannot). The cached base is lawful ONLY behind a concrete heap-pinned path per [MEM-SAFE-029], confined and `// SAFETY:`-marked per [MEM-SAFE-025a]/[MEM-SAFE-015]. **SE-0465 does not remove this surface** — alloc/free are intrinsically pointer operations.
- **(b) The span surface** — read-`Span` vending over the region; rides `Span.Protocol` per [MEM-SAFE-030] (write spans confined to Storage; reads ride `Swift.Span`) and [MEM-SAFE-012]. **This is the SE-0465-gated surface** — the one a safe-owning-span language feature retires.

A "zero-`unsafe` leaf" goal targets surface **(b) only**. Claiming a leaf can become fully `unsafe`-free conflates the two and over-promises (SE-0465 never cleans the floor); conversely, pushing the floor's cached base into generic code to "avoid the pointer" violates [MEM-SAFE-029]. Keep them separate so the upgrade path stays legible: (b) improves with the toolchain; (a) is the standing floor.

**Why**: the two surfaces have different truth conditions *over time*. The floor's `unsafe` is a fact about the machine (you cannot obtain raw bytes without a pointer op); the span's `unsafe` is a fact about the *current* language (no safe owning span yet). A design that does not separate them cannot state which of its `unsafe` sites are temporary and which are permanent — exactly the question every leaf-`unsafe` review must answer.

**How to apply**:
- When auditing or marking a leaf's `unsafe`, classify each site as (a) floor or (b) span; tag (b) sites with the gating feature (SE-0465) so the upgrade is mechanical when it lands.
- Set a "zero-`unsafe`" target on (b), never on (a).
- Keep the floor's cached base behind the concrete heap-pinned path ([MEM-SAFE-029]); never lift it into generic code to chase a zero-`unsafe` number.


**Cross-references**: [MEM-SAFE-029] (the floor's cached-base placement rule), [MEM-SAFE-030] (the span surface — read-only fence), [MEM-SAFE-012] (Span as normative interface), [MEM-SAFE-025a] (invariant comment), [MEM-SAFE-015] (raw pointer last resort), [MEM-SPAN-005] (distinct concern — span *derivation cost*, not surface taxonomy).

---

### [MEM-UNSAFE-004] `unsafe` Is Expression Keyword, Not Block

**Statement**: Swift's `unsafe` is an expression-level keyword (similar to `try` and `await`), NOT a block construct. There is no `unsafe { ... }` form.

**Correct**:
```swift
let x = unsafe someUnsafeCall()
let y = unsafe pointer.load(as: Int.self)
unsafe pointer.deallocate()
```

**Incorrect**:
```swift
unsafe {                              // ❌ does not compile
    let x = someUnsafeCall()
    let y = pointer.load(as: Int.self)
    pointer.deallocate()
}
```

**Lint enforcement**: SwiftLint custom rule `no_unsafe_block_form` (`swift-institute/.github/.swiftlint.yml`) catches `unsafe {`. Severity error. Added Wave 2b 2026-05-10.

**Cross-references**: [MEM-SAFE-001], [MEM-SAFE-002], [MEM-UNSAFE-001]

---

