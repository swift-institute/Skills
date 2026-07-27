## File Structure

### [API-IMPL-005] One Type Per File

**Statement**: Each `.swift` file MUST contain exactly one type declaration (counting `struct`/`enum`/`class`/`actor`, not `extension` blocks).

```
// CORRECT
File.Directory.Walk.swift     -> contains File.Directory.Walk
File.Directory.Walk.Options.swift -> contains File.Directory.Walk.Options

// INCORRECT
// File: Models.swift
struct User { }      // Multiple types - FORBIDDEN
struct Profile { }   // in one file - FORBIDDEN
```

**Lint enforcement**: `Lint.Rule.Structure.SingleTypePerFile` flags the second-and-subsequent file-scope type declaration (extensions descend without flagging; nested types skipped). Scope-excluded paths per Wave 2b finalization Decision 2: `Tests/`, `Experiments/`, `Examples/` (test fixtures legitimately declare multiple top-level types per [TEST-005]). Scope detail: rationale archive §[API-IMPL-005]. [VERIFICATION: AST Lint.Rule.Structure.SingleTypePerFile]

---

### [API-IMPL-006] File Naming Convention

File names MUST match the type's full nested path with dots — the same `Nest.Name` pattern as [API-NAME-001], expressed at the file system level.

```
// CORRECT
Array.Dynamic.swift
Array.Dynamic.Iterator.swift
Set.Ordered.Element.swift

// INCORRECT
DynamicArray.swift           // Compound name
ArrayDynamicIterator.swift   // No dot separation
```

**Lint enforcement**: Reusable workflow `validate-file-naming.yml` + `.github/scripts/validate-file-naming.py` flag dotless compound-name `.swift` basenames in `Sources/`. Exemptions: `Package.swift`, `exports.swift` / `Exports.swift`; `+`-suffix extension forms and where-clause shape per [API-IMPL-007]; underscore-bearing spec-namespace names (`RFC_4122.swift`) per [API-NAME-003]; test/experiment/example/benchmark trees. Scope detail + fixtures: rationale archive §[API-IMPL-006]. [VERIFICATION: WF validate-file-naming.py]

**Cross-references**: [API-NAME-001] (type-level `Nest.Name` pattern that this rule mirrors at the file-system level), [API-IMPL-005], [TEST-009] (file-naming counterpart for test files)

---

### [API-IMPL-007] Extension Files

**Statement**: Extension files MUST use either the `+` suffix pattern (for adding a conformance) or the where-clause shape (for suppressed-protocol-constraint discrimination), depending on what discriminates the extension.

**`+` suffix — for adding a conformance**:

```
// CORRECT
Array.Dynamic+Sequence.swift
Set.Ordered+Hashable.swift

// File contains:
extension Array.Dynamic: Sequence { ... }
```

**Where-clause shape — for suppressed-protocol-constraint discrimination**:

```
// CORRECT
Carrier where Underlying == Self.swift
Carrier where Underlying == Self, Self ~Copyable.swift

// Each file contains one extension whose where-clause matches the filename.
```

**Lint enforcement**: Reusable workflow `validate-file-naming.yml` + `.github/scripts/validate-file-naming.py` flag pure-extension files (all top-level declarations are `extension` blocks) whose basename lacks BOTH a `+` segment AND a ` where ` discriminator; files with a primary type declaration are out of scope. Scope detail + fixtures: rationale archive §[API-IMPL-007]. [VERIFICATION: WF validate-file-naming.py (API-IMPL-007)]

**Cross-references**: [API-IMPL-005], [API-IMPL-006]

---

### [API-IMPL-008] Minimal Type Body

Type declarations MUST contain only stored properties and the canonical initializer. Everything else MUST be in extensions.

**Native carve-outs (principal-ratified 2026-07-05)** — these three structures SATISFY the rule as written; they need no exemption: (a) **attribute-defined extension-pattern types** — `@resultBuilder` enums and `@Suite` types whose members the attribute's protocol shape requires in the type body; (b) **`Protocol`-sentinel hosts** — a namespace type whose body carries only the `Protocol` sentinel typealias per [PKG-NAME-002]; (c) **SwiftSyntax visitor subclasses** — `SyntaxVisitor`/`SyntaxRewriter` subclasses, where visitation state and `visit` overrides are structurally body-bound (extraction was measured semantic-zero across ~336 findings). Lint spec: fold these carve-outs natively into `Lint.Rule.Structure.MinimalTypeBody` (queued — see BACKLOG); until that lands, the [RULE-EXEMPT-4/5/7] shapes remain the operational mechanism (rule-exemptions skill).

```swift
// CORRECT
public struct Buffer {
    @usableFromInline
    var storage: Storage

    @usableFromInline
    var count: Int

    @inlinable
    public init() {
        self.storage = Storage()
        self.count = 0
    }
}

extension Buffer {
    public var isEmpty: Bool { count == 0 }

    public mutating func append(_ element: Element) { ... }
}

extension Buffer: Sequence {
    public func makeIterator() -> Iterator { ... }
}

// INCORRECT -- methods in type body
public struct Buffer {
    var storage: Storage
    var count: Int

    public init() { ... }

    public var isEmpty: Bool { count == 0 }  // Should be in extension

    public mutating func append(_ element: Element) { ... }  // Should be in extension
}
```

**What belongs in the type body**:
- Stored instance properties
- Canonical initializer(s)
- `deinit` (for classes and ~Copyable types)

**What belongs in extensions**:
- Computed properties
- Methods
- Protocol conformances
- Static members
- Nested types (with exception below)

**Exception for ~Copyable types**: Per [MEM-COPY-006], types with `~Copyable` generic parameters MAY include in the body:
- Nested storage types (e.g., `ManagedBuffer` subclasses)
- Nested types referencing the `~Copyable` parameter

This avoids constraint poisoning. Conditional conformances MUST still be in the same file.

**Protocol-witness methods on associatedtype-using storage** (companion note): moving witnesses to extensions while keeping conformances on the struct declaration creates an associatedtype inference cycle (`unsupported recursion for reference to type alias`). Working pattern (full-qualify storage types; conformance-on-extension; marker-only conformances stay on the struct decl) + worked Cyclic.Group.Static.Iterator example + provenance: Research/code-surface-skill-rationale.md §[API-IMPL-008].

**Rationale**: Minimal bodies make storage layout immediately visible, separate stable data from evolving behavior, and simplify code review.

**Lint enforcement**: `Lint.Rule.Structure.MinimalTypeBody` flags every `func`, computed `var`, `static let`/`var`, nested type declaration, `subscript`, and `typealias` directly in a type body; stored properties (including `willSet`/`didSet`), canonical initializers, `deinit`, and enum cases are permitted; protocol bodies are out of scope. Scope detail: rationale archive §[API-IMPL-008]. [VERIFICATION: AST Lint.Rule.Structure.MinimalTypeBody]

---

### [API-IMPL-009] Hoisted Protocol with Nested Typealias

**Statement**: When a protocol needs to appear as `Outer.Inner.Protocol` on a generic type, the canonical pattern is:

1. **Hoist** the protocol to module scope (e.g., `_InnerProtocol` or hoisted name)
2. **Nest** a `typealias Protocol = _InnerProtocol` inside the generic type's namespace
3. **Conformance in declaring module** uses the hoisted name directly
4. **Consumers** use the typealias path (`Outer.Inner.Protocol`)

```swift
// CORRECT — Declaring module
public protocol _LocatedErrorProtocol: Swift.Error { ... }

extension Parser.Error {
    public struct Located<E: Swift.Error>: _LocatedErrorProtocol {
        public typealias Protocol = _LocatedErrorProtocol  // Consumers use this path
        ...
    }
}

// Consumer module
extension MyError: Parser.Error.Located.Protocol { ... }  // ✓ Uses typealias
```

```swift
// INCORRECT — Self-referential conformance
extension Parser.Error.Located: Parser.Error.Located.Protocol { ... }
// ❌ Cycle: resolving Located.Protocol requires resolving Located's conformances
```

**Three requirements**:
1. Types nested inside `.Error` namespaces MUST use `Swift.Error` (see [PLAT-ARCH-011])
2. **Self-conformance** (a type conforming to its OWN `Protocol` — extended type == the `.Protocol` owner) MUST use the hoisted name: the canonical `X.Protocol` path self-references and the compiler rejects it (`circular reference`). **Sibling** declaring-module conformers (a *different* type conforming to the same protocol) and all constraint sites SHOULD PREFER the canonical `X.Protocol` path — the hoisted `__`-name is an implementation detail whose raw use should be minimized. This matches `Lint.Rule.Structure.HoistedProtocolAlias`, which flags only the self-conformance case. (`[Verified: 2026-06-22]`, swiftc 6.3.2: self-conformance via canonical → `circular reference`; sibling conformance via canonical → compiles. The gerund typealias RHS is a separate forced-hoist site — an unbound generic member is rejected there; see `[PKG-NAME-006]`.)
3. Consumer modules CAN use the typealias path for conformance, constraints, and existentials

**When generic parameters block nesting**: If a nested type needs access to the outer type's generic parameter across a nesting boundary, use a `_Value` typealias on the outer type to capture the generic parameter before the inner type's scope shadows it.

**Lint enforcement**: `Lint.Rule.Structure.HoistedProtocolAlias` flags conformances whose inherited type is `<ExtendedType>.Protocol` (the self-conformance cycle); consumer-module conformance and declaring-module conformance via the hoisted name are not flagged. Scope detail: rationale archive §[API-IMPL-009]. [VERIFICATION: AST Lint.Rule.Structure.HoistedProtocolAlias]

**ADT Tower rider — the struct-carrier hoist (M12, ratified 2026-07-03; transcribed at W4, 2026-07-06).** The [API-IMPL-009]/[PKG-NAME-006] hoist idiom explicitly covers STRUCT carriers (`__X` struct + front-door typealias), not only protocols and agent-nouns. The tower carrier `struct __X<S: ~Copyable>` ([DS-025]) is the canonical struct-hoist instance: the hoisted `__X` is the real declaration and the front-door alias (`typealias X<E> = __X<…>`, [DS-028]) is the consumer spelling. A family author reads the struct-carrier hoist as SANCTIONED, not an exception. Provenance: `Research/adt-tower.md` §4.7.

**Cross-references**: [API-NAME-001], [PLAT-ARCH-011]

---

### [API-IMPL-018] `@retroactive` Is Package-Scoped, Not Module-Scoped

**Statement**: Conformances declared in the SAME PACKAGE as the protocol MUST NOT carry `@retroactive`. Swift's `@retroactive` attribute applies only when the conformance and the protocol live in DIFFERENT packages. Same-package conformances reject the attribute with `error: 'retroactive' attribute does not apply; 'X' is declared in the same package`.

**Correct** (cross-package conformance):
```swift
// In a package that does NOT declare Serializable,
// conforming a stdlib type to Serializable (which IS declared elsewhere):
extension Int: @retroactive Serializable { ... }
```

**Incorrect** (same-package conformance with `@retroactive`):
```swift
// In swift-serializer-primitives, where Serializable is declared:
extension Swift.Optional: @retroactive Serializable where Wrapped: Serializable { ... }
// ❌ error: 'retroactive' attribute does not apply; 'Serializable' is declared in the same package
```

**Why**: `@retroactive` acknowledges a conformance added by a party controlling neither protocol nor type; the diagnostic is scoped to the package boundary, not the module boundary, even across *targets* within one package. Full text: rationale archive §[API-IMPL-018].

**How to apply**: When authoring a stdlib conformance, check whether the protocol lives in the same Swift **package** (Package.swift), not the same module. If same-package, omit `@retroactive`. If cross-package, require it. Module-vs-package confusion is the common failure shape.

**Refinement corollary**: an in-package protocol `X` refining an external protocol `Y`, with a stdlib type conforming via the refinement, requires BOTH clauses — `extension Int: X, @retroactive Y` (in-package `X` without `@retroactive`, inherited external `Y` with it); the single-protocol form emits contradictory diagnostics. Alternative: a sibling-form refactor of `X` (declared not to inherit `Y`) drops the dual clause. Full text + lint-enforcement candidate: rationale archive §[API-IMPL-018].

**Cross-references**: [API-IMPL-009] (related hoisted-protocol patterns for cross-package conformance shape), [API-IMPL-019] (sibling rule from the same W5b incident).

---

### [API-IMPL-019] Qualified Names Inside Conforming Extensions

**Statement**: Inside an `extension T: Protocol` block where `Protocol` declares an `associatedtype X`, the unqualified identifier `X` resolves to the conformer's associatedtype-binding, NOT to any same-named type in the broader namespace. Reference types from outside the conformance via FULL module-qualification when the name could collide with an associatedtype.

**Correct**:
```swift
// Inside an extension conforming Optional to Serializable:
// `Serializable` declares `associatedtype Serializer`.
extension Swift.Optional: Serializable where Wrapped: Serializable {
    public static var serializer: Serializer_Primitives_Core.Serializer.Optionally<Wrapped.Serializer> {
        Serializer_Primitives_Core.Serializer.Optionally(Wrapped.serializer)
    }
}
```

**Incorrect**:
```swift
extension Swift.Optional: Serializable where Wrapped: Serializable {
    public static var serializer: Serializer.Optionally<Wrapped.Serializer> {
        // ❌ error: type 'Optional<Wrapped>.Serializer' has no member 'Optionally'
        // Unqualified `Serializer` here resolves to the associatedtype binding,
        // not the `Serializer` namespace in Serializer_Primitives_Core.
        Serializer.Optionally(Wrapped.serializer)
    }
}
```

**Why**: The associatedtype acts as a name binding in the conformance scope; Swift's name resolution prefers the closer-scoped binding over a top-level namespace of the same name. Full text: rationale archive §[API-IMPL-019].

**How to apply**: When a conformance involves naming a type whose identifier could be confused with an associatedtype name on the conformed-to protocol (e.g., `Serializer`, `Parser`, `Coder`, `Body`, `Output`, `Failure`), use full module qualification: `Serializer_Primitives_Core.Serializer.X`, `Parser_Primitives_Core.Parser.X`, etc. The qualification is load-bearing — leaving it implicit relies on the absence of an associatedtype collision, which holds today but is fragile under future protocol evolution.

**Lint enforcement candidate**: an AST rule could walk `ExtensionDeclSyntax` inheritance clauses, collect the conformed-to protocol's associatedtype names, and flag unqualified references to those names inside the extension body. Not yet implemented.

**Cross-references**: [API-IMPL-009] (hoisted-protocol patterns), [API-IMPL-018] (`@retroactive` package-scoping — sibling rule from the same incident).

---

**Enforcement**: TEXT-ONLY (cross-module associatedtype knowledge and per-file SPI boundaries under [MOD-SPI]): an internal audit record.

### [API-IMPL-020] Explicit `Body = Never` Typealias on Generic Parser/Serializer Leaf Conformers

**Statement**: Generic types conforming to `Parser.Protocol` / `Serializer.Protocol` / `Coder.Protocol` as leaf conformers (no `body` property delegating to another Parser/Serializer body) MUST declare `public typealias Body = Never` explicitly; without it, witness-table emission for generic conformers fails at link time with `Undefined symbols ... protocol witness for body.getter`.

**Enforcement**: Mechanical — `Lint.Rule.Conformance.LeafBodyTypealias` in `swift-foundations/swift-institute-linter-rules`, target `Linter Rule Conformance` (institute tier; first AST-domain pivot promotion of `/promote-rule` 2026-05-15). Discipline: an internal audit record. [VERIFICATION: AST]

**Cross-references**: [API-IMPL-009] (hoisted-protocol patterns); [API-IMPL-018], [API-IMPL-019] (sibling rules from the same W4c/W5b Coder/Serializer modeling arc).

---

### [API-IMPL-021] Coroutine Accessors and `borrowing get` Over `get`/`set`

**Statement**: Element-vending and forwarding property/subscript surfaces use the coroutine pair `_read` / `_modify` (never plain `get`/`set`) wherever the vended value may be `~Copyable` OR a copy is avoidable; properties returning `~Escapable` values (`Span`, `MutableSpan`) use `borrowing get` (+ `@_lifetime`, per the 6.3.2 spelling pin) or `mutating get`. Plain `get`/`set` remains correct only where copy semantics are the point (e.g. `element(at:) -> E?` conveniences for `Copyable` elements).

**6.3.2 constraints** (probed 2026-06-10, `/tmp/accessor-probe`): protocol REQUIREMENTS cannot be spelled with coroutines — `modify` is rejected in requirement position even under `-enable-experimental-feature CoroutineAccessors` — so requirements stay `{ get set }` and conformers witness them with `_read`/`_modify` (the established `Store.Protocol` subscript pattern). SE-0474's accepted spelling `yielding borrow` / `yielding mutate` does not parse on 6.3.2 at all. Do NOT adopt the experimental unprefixed `read`/`modify` member spelling now: it is a guaranteed rename at the gate bump.

**Why**: `get` on a `~Copyable` element does not compile; on `Copyable` class-typed elements it costs retain/copy traffic the coroutine avoids. Uniform coroutine surfaces also keep the gate idiom available (`_modify { gate(); yield &… }`). **ADT Tower rider (2026-07-02)**: on 6.3.3 the `CoroutineAccessors` flag IS accepted — struct `read`/`modify` parse; protocol requirements accept `{ read }`/`{ read set }` but NOT `modify` (probes p6/p6b); SE-0507 is Implemented (Swift 6.4, default-on there) so the SE-0507/SE-0474 rename is a mechanical 6.4-gate item; adoption stays deferred because SE-0507 rejects pointer projection, so heap-backed element vends keep `_read`/`_modify` coroutines even post-6.4 (`Research/adt-tower.md` §3 W6, §4.7).

**Cross-references**: [API-IMPL-020]; **memory-safety** [MEM-SAFE-025c] (disclosure idiom for the unsafe-marked construction behind some `borrowing get` spans), [MEM-SAFE-028]; **ecosystem-data-structures** [DS-025] (carriers vend elements via these coroutines).

---

### [API-IMPL-022] Tower Value Types Are `@frozen`

**Statement**: Public STORED value types in the storage tower ship `@frozen` from birth; views/iterators/snapshots (`~Escapable` types and the curated `Checkpoint`/`Scalar`/`Segments`/`Walk` class) stay unfrozen until cross-module partial consumption is demonstrated.

**Enforcement**: Mechanical — `Lint.Rule.Tower.FrozenTowerType` (`frozen tower type`, primitives tier, pack `Primitives Linter Rule Tower`; ζ pilot of /promote-rule 2026-06-12). Discipline: an internal audit record. [VERIFICATION: AST Lint.Rule.Tower.FrozenTowerType] **ADT Tower rider (2026-07-02)**: the tower carriers (`__X<S: ~Copyable>`) are stored value types ⇒ `@frozen` from birth ([DS-025]; `Experiments/adt-tower-worked-example` complies); front-door aliases carry no storage of their own (generic-instantiation aliases, [DS-028]) so the `@frozen` obligation lands on the carrier (`Research/adt-tower.md` §4.7).

**Cross-references**: [API-IMPL-021]; **memory-safety** [MEM-COPY-016]; **rule-exemptions** (exemption shapes); **ecosystem-data-structures** [DS-025] (frozen carriers), [DS-028] (aliases hold no storage).

---

### [API-IMPL-023] Capability Seams Are Deletable Conveniences — Canonical Spellings Stay Concrete

**Statement**: A capability seam (a protocol minted so generic algorithms can range over a
family — `Memory.Pooling`, `Memory.Allocating`, `Store.\`Protocol\``-class) is a DELETABLE
CONVENIENCE. Canonical spellings stay CONCRETE
(`Storage<Memory.Allocator<Memory.Heap>.Pool>.Generational<Element>` — never
`Storage<any Memory.Pooling>…`); existentials of the seam (`any X`) are forbidden; the seam
MUST NOT refine into identity tiers nor become the public spelling of products. When a seam is
minted and a NON-GENERIC noun nest is available or mintable, mint the CANONICAL TRIPLE — noun
namespace + nested `\`Protocol\`` + gerund typealias (`Memory.Pool` / `Memory.Pool.\`Protocol\`` /
`Memory.Pooling`; the `Iterator.Protocol`/`Iterating` precedent, [API-NAME-001a]/[PKG-NAME-002]).
When the agent-noun nest is itself **generic** (a tower struct such as `Memory.Allocator<Resource>`
under a non-generic root namespace), the canonical triple is STILL REQUIRED and STILL homed on the
agent noun: hoist the protocol to module scope and re-expose it via a param-free `typealias \`Protocol\``
per [API-IMPL-009], so `Namespace.\`Protocol\`` resolves UNBOUND (the depth-2 resolution holds because the
*root* — e.g. `Memory` — is non-generic; `[Verified: 2026-06-22]`, swiftc 6.3.2). The witness is then the
generic agent-noun struct itself, conforming to its own protocol via the **hoisted name** (never the
`.\`Protocol\`` alias — that self-reference is the [API-IMPL-009] cycle). Homing the active protocol on the
**deverbal noun** instead (`Memory.Allocation.\`Protocol\`` + `Memory.Allocating`) is DISALLOWED: it rested
on a "generic types cannot host the protocol" premise the hoist disproves, and it spends the result-noun
that [PKG-NAME-015] reserves for the witness. Existing seams in that shape (`Memory.Allocating`, any
`Store.\`Protocol\``-class seam homed off its agent noun) MUST be flagged for triple-retrofit onto the agent
noun at their package's release-readiness.

**Rationale**: seams exist for generic algorithms, not identity — concrete canonical spellings preserve zero-cost dispatch and keep the seam deletable, while the triple keeps the algebra's vocabulary at a non-generic noun home. Full text: rationale archive §[API-IMPL-023].

**Backward compatibility**: BREAKING (2026-06-22) — generic agent-noun nests carry the canonical triple ON the agent noun via the [API-IMPL-009] hoist; deverbal-noun homing disallowed; existing `Memory.Allocating`-class seams flagged for triple-retrofit at release-readiness. Principal-ratified. Reversal narrative (reopened seat ruling R-1), provenance, and ADT Tower rider: Research/code-surface-skill-rationale.md §[API-IMPL-023].

**ADT Tower rider — the `Direct`-marker carve-out (M4, ratified 2026-07-03; transcribed at W4, 2026-07-06).** [DS-028] front doors are generic-instantiation aliases, expressly OUTSIDE this rule's forbidden rename-bridge class. Discipline seams stay deletable conveniences WITH ONE CARVE-OUT: the `Direct` marker — the hoisted `__ColumnDirect` protocol AND its seam-tier public typealias `Store.Direct` (see [API-NAME-004]) — is **load-bearing**, NOT a deletable convenience. It is the axis-drop FENCE the [DS-028] alias laws depend on ([DS-028] alias-law 1: deleting it lets a cross-axis chain silently reset an axis — e.g. `Vector<Int>.Shared.Small<8>` dropping the `Shared` axis with no diagnostic). It is thus reclassified from "deletable convenience" to a REQUIRED seam type; this supersedes the prior "in-tower plumbing binds `__ColumnDirect` directly" ruling (§10 ledger). Provenance: `Research/adt-tower.md` §4.7, §2 D4.1.

**Cross-references**: [API-NAME-001a], [API-NAME-004], [PKG-NAME-002]; **implementation** [PATTERN-059];
**memory-safety** [MEM-SAFE-029]; **ecosystem-data-structures** [DS-028] (front-door aliases), [DS-025].

---
