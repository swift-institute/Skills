## Namespace Structure

### [API-NAME-001] Nest.Name Pattern

**Statement**: All types MUST use the `Nest.Name` pattern; compound type names are FORBIDDEN. In `Nest.Name`, the Nest is the broader domain and Name is the specific concept within it — apply the test "X is a kind of Y" or "X belongs to Y".

```swift
// CORRECT
File.Directory.Walk
IO.NonBlocking.Selector
RFC_4122.UUID

// INCORRECT
FileDirectoryWalk      // Compound name - FORBIDDEN
DirectoryWalk          // Compound name - FORBIDDEN
NonBlockingSelector    // Compound name - FORBIDDEN
```

**Lint enforcement**: `Lint.Rule.Naming.CompoundType` flags compound type identifiers via word-boundary detection; acronym-only names (`URL`, `UUID`, `IO`), spec-namespace forms with underscores (`RFC_4122`, `ISO_9945`), `package`-scope declarations, and macros are exempt. Compound METHOD identifiers are governed by `Lint.Rule.Naming.Compound` per [API-NAME-002]. Scope detail: rationale archive §[API-NAME-001]. [VERIFICATION: AST Lint.Rule.Naming.CompoundType]
**Exception (L2 Standards, principal ruling 2026-07-07)**: L2 Standards packages optimize for 1:1 spec encodings. An identifier that is a deterministic transliteration of a spec-defined token — per the spec community's own naming convention (e.g. W3C CSSOM camelCase like `animationName`, IEEE 754 operation names like `roundAwayFromZero`, POSIX symbols) — is a spec-mirroring name governed by [API-NAME-003], so this rule's compound-type-name prohibition does NOT mechanically apply at L2. Enforcement mechanism: `Lint.Rule.Bundle.standards` (swift-linter `[LINT-BUNDLE]`) omits `compound type name` from its rule set; L1 (`Bundle.primitives`) and L3 (`Bundle.institute`) are unchanged and keep the rule active. Invented, non-spec identifiers at L2 remain non-conforming as a text convention even though mechanical enforcement opts out layer-wide.
---

### [API-NAME-001a] Single-Type-No-Namespace Rule

**Statement**: A namespace that contains only one type is not a namespace — it is a *variant label* — and MUST nest under its parent type rather than existing as a top-level domain. [API-NAME-001]'s Decision test determines whether X belongs under Y; this rule determines whether Y should exist as a namespace at all.

**Correct** — single-type labels nested under their parent:

| Wrong shape | Correct shape | Why |
|-------------|---------------|-----|
| `Cooperative` (top-level, one type) | `Executor.Cooperative` | `Cooperative` has no siblings outside the `Executor` variants |
| `Kernel.Thread.Polling.Executor` | `Kernel.Thread.Executor.Polling` | `Polling` has no siblings outside `Executor`-variants under `Kernel.Thread` |

**Lint enforcement**: `Lint.Rule.Naming.SingleTypeNamespace` flags caseless-enum namespaces containing exactly one nested type declaration (typealiases permitted as sibling labels). Conservative per-file detection — the flag is a review prompt; real enums, structs, and classes are out of scope. Scope detail: rationale archive §[API-NAME-001a]. [VERIFICATION: AST Lint.Rule.Naming.SingleTypeNamespace]

**Cross-references**: [API-NAME-001], [API-NAME-003]

---

### [API-NAME-001b] LargerDomain.Subdomain — Subject-First When Domain Exceeds Role

**Statement**: When a type sits at the intersection of two namespaces X and Y where one is strictly larger than the other (one is the *subject*, the other is a *role* or *specialization*), the type MUST be nested under the larger domain. `Byte.Parser` (a parser specialized to byte input, owned by the byte domain), NOT `Parser.Byte` (a byte-shaped parser, owned by the parser domain). The decision is structural, not preferential — the larger domain is the one with more co-inhabiting subjects.

**Decision procedure**:

Let `X` be the candidate type. Let `Y` and `S` be the two namespaces under consideration (X sits at their intersection). The two namespaces play different roles: one of them is a **role/operation** (e.g., `Parser`, `Serializer`, `Coder`); the other is a **subject** (e.g., `Byte`, `ASCII`, `JSON`).

| Ask | If yes → | If no → |
|-----|---------|---------|
| Is X a *kind of* Y (X is a Y-variant — same domain as Y)? | `Y.X` — variant nested under parent (this is [API-NAME-001]'s Nest.Name) | Continue. |
| Is one of {Y, S} the role/operation and the other the subject — and X is "the role specialized to the subject"? | `S.R` where S is the subject and R is the role — specialization nested under subject | Continue. |
| Are Y and S peer subjects (neither is a role of the other)? | The ordering is a judgment call; document the rationale and check for spec-mirroring per [API-NAME-003] | — |

**Correct** — subject owns the namespace; role is the leaf:

| Wrong shape | Correct shape | Why |
|-------------|---------------|-----|
| `Parser.Byte` | `Byte.Parser` | A byte parser is byte-domain; parsing is the role. Byte is the subject. |
| `Coder.JSON` | `JSON.Coder` | JSON is the subject (spec-defined domain); coder is the role. |

**Correct** — variant nested under parent (this is [API-NAME-001]'s case, not [API-NAME-001b]'s):

| Shape | Why |
|-------|-----|
| `Parser.Many` | `Many` is a kind of `Parser` — a parser variant. Parser owns the namespace because Many is a parser-domain concept. |
| `Executor.Cooperative` | `Cooperative` is a kind of `Executor` — an executor variant. |

**The distinction**: [API-NAME-001b] applies when the two namespaces are *both* domains in their own right and one is strictly larger. Y is a *role* (parse, serialize, code, encode) — it applies to many subjects. X is a *subject* (byte, ASCII, JSON, binary) — it has many roles. The role is the leaf; the subject owns the namespace.

[API-NAME-001]'s Nest.Name applies when one namespace is *not* a domain in its own right — it is a variant label that exists only as a member of a larger type. `Many` is not a domain; it is a parser-variant label. `Cooperative` is not a domain; it is an executor-variant label.

**What the rule does NOT mean**: it does not mean "always put the noun before the verb." `Parser.Builder` is correct — Builder is a parser-variant (a sub-shape of parser), not a builder specialized to parsing. `Buffer.Allocator` is correct — Allocator is a buffer-variant in the buffer domain. The rule fires only when both X and Y are domains in their own right and one is a role specialization on the other.

**The subject-vs-manner discriminator (added 2026-05-26).** The decision turns on one question: is the leading token the **data the operation processes** (a *subject*) or **a way the operation behaves** (a *manner*)?

| Leading token is… | Linguistic test | Ordering |
|-------------------|-----------------|----------|
| **Subject** — the data/value/format processed | "operate *on the* ___" → *parse the bytes*, *iterate the memory* | subject-first `Subject.Op` (`Byte.Parser`, `Memory.Cursor`) — subject owns the package |
| **Manner** — how the operation behaves (a mode/shape/adverb) | "operate ___*-ly* / in a ___ way" → *iterate borrowingly*, *iterate in bulk* | role-owns `Op.Manner` (`Iterator.Borrow`, `Iterator.Chunk`, `Parser.Many`) — operation owns |

**Concept before word — and never reuse a *subject's* word as a *manner*.** Decide by *concept*, not spelling. The cautionary worked example is the bulk iterator: it yields contiguous spans, yet it is named `Iterator.Chunk` (manner = *chunked* — successive sub-spans), **not** `Iterator.Contiguous` — because `Contiguous` is already a memory *subject's* word (`Storage.Contiguous`; formerly also `Memory.Contiguous`, dissolved 2026-06-23), and reusing a subject's word for a manner re-creates the very cross-domain collision this rule exists to prevent (the same reason `Borrow` stays reserved for the ownership tier). Pick a manner word that no subject owns (`Chunk`, `Borrow`); when a token *could* name a subject (`Memory`, `Storage`, `Span`, `Contiguous`), that pull is the signal to choose a different manner word, not to flip to subject-first. The ownership tell confirms which you have: role-owns has the operation package depend *down* onto the mode (iterator → ownership); subject-first has the subject depend *up* onto the operation (byte → parser). Manner-variants take the **noun** form (`Iterator.Borrow`, not `Iterator.Borrowing`). See `operation-domain-naming-and-organization.md` §7.

**Rationale**: `Role.Subject` ordering misrepresents ownership (the role is applied to the subject, not the reverse) and welds every subject's specialization into the role package; `Subject.Role` reads naturally and lets the subject's package own its specializations. Full text (formalization history, byte worked example with package split, provenance): rationale archive §[API-NAME-001b].

**Cross-references**: [API-NAME-001] Nest.Name, [API-NAME-001a] Single-Type-No-Namespace, [API-NAME-003] Specification-Mirroring Names.

---

### [API-NAME-001c] Per-Domain Capability-Marker Protocol

**Statement**: Group A capability-marker types (domain-identity value types that are the institute twin of a stdlib carrier — `Cardinal`/UInt, `Ordinal`/UInt, `Affine.Discrete.Vector`/Int, `Byte`/UInt8, future `Char`/`Codepoint`/`Word`/`Line`) MUST define a per-domain `X.Protocol` following the canonical recipe: a SIBLING to `Carrier.Protocol` (NOT a refinement) with `var x: X { get }` + `init(_ x: X)` self-accessor, `associatedtype Domain: ~Copyable = Never` for tag-enforcement, recursive Tagged conformance via `extension Tagged: X.Protocol where Underlying: X.Protocol, Tag: ~Copyable`, stdlib-protocol conformances declared separately on each conformer (NOT as protocol parents), and default impls on `extension X.Protocol` that provide witnesses for those stdlib protocols. The stdlib raw type that X carries (UInt8 for Byte, UInt for Cardinal, Int for Vector, …) MUST NOT conform to `X.Protocol` — its institute twin is the conformer; the stdlib raw type carries the arithmetic-algebras identity, the institute twin carries the domain identity.

**Recipe** — instantiated for byte (the canonical example):

```swift
// Step 1: protocol declaration — sibling, no Carrier refinement, no stdlib parents.
extension Byte {
    public protocol `Protocol` {
        associatedtype Domain: ~Copyable = Never
        var byte: Byte { get }
        init(_ byte: Byte)
    }
}

// Step 2: self-conformance — trivial identity.
extension Byte: Byte.`Protocol` {
    public typealias Domain = Never
    @inlinable public var byte: Byte { self }
    @inlinable public init(_ byte: Byte) { self = byte }
}

// Step 3: recursive Tagged conformance — `Tagged<Tag, Byte>` is itself a Byte.
extension Tagged: Byte.`Protocol`
where Underlying: Byte.`Protocol`, Tag: ~Copyable {
    public typealias Domain = Tag
    @inlinable public var byte: Byte { underlying.byte }
    @_disfavoredOverload
    @inlinable public init(_ byte: Byte) {
        self.init(_unchecked: Underlying(byte))
    }
}

// Step 4: stdlib conformances declared directly on each conformer, NOT inherited
// via X.Protocol parents. Default impls below provide the witnesses.
extension Byte: Equatable {}
extension Byte: Hashable {}
extension Byte: Comparable {}
extension Byte: ExpressibleByIntegerLiteral {}

// Step 5: default impls on the protocol's extension — witnesses for stdlib
// conformances + domain-specific operators (bitwise / arithmetic / etc.).
extension Byte.`Protocol` {
    @inlinable public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.byte.underlying == rhs.byte.underlying
    }
    @inlinable public func hash(into hasher: inout Hasher) {
        hasher.combine(byte.underlying)
    }
    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.byte.underlying < rhs.byte.underlying
    }
    @inlinable public init(integerLiteral value: UInt8.IntegerLiteralType) {
        self.init(Byte(UInt8(integerLiteral: value)))
    }
    @inlinable public static var zero: Self { Self(Byte(0)) }
    @inlinable public static var max: Self { Self(Byte(0xFF)) }
}
```

The recipe is uniform across Group A capability markers; only the names change (`byte`/`Byte`, `cardinal`/`Cardinal`, `ordinal`/`Ordinal`, `vector`/`Vector`, …). Cardinal uses the trivial-self-carrier variant where the accessor lives on `extension Carrier.Protocol where Underlying == Cardinal` instead of a separate `Cardinal.Protocol` — that variant is structurally equivalent (the Cardinal package's storage shape makes it cleaner) and falls within the same recipe family.

**Sibling-vs-refinement decision criterion — the recursion-vs-refinement constraint principle**:

> A refinement-of-Carrier form (`X.Protocol: Carrier.Protocol where Underlying == U`) BLOCKS recursive Tagged conformance because `Tagged<Tag, X>.Underlying == X` (per Tagged's universal `Tagged: Carrier.Protocol` conformance with `typealias Underlying = Underlying` — the immediate generic param), not `U`. Use the SIBLING form when recursive Tagged conformance is needed or anticipated.

For every Group A capability marker, recursive Tagged conformance IS anticipated — phantom-tagged value types (`Tagged<DeviceID, Byte>`, `Tagged<UserBalance, Cardinal>`, …) are the natural composition shape. Therefore every Group A capability marker MUST use the sibling form; the refinement form is only viable for the (essentially-empty) case where X.Protocol explicitly cannot participate in `Tagged<Tag, X>` composition.

| Form | Conformer set | When viable |
|------|---------------|-------------|
| Sibling (`X.Protocol { var x: X { get }; init(_:) }`) | `X`, `Tagged<Tag, T: X.Protocol>`, future newtype conformers | Always — supports recursive Tagged conformance |
| Refinement (`X.Protocol: Carrier.Protocol where Underlying == U`) | `X`, `Tagged<Tag, U>`, future U-storing newtype conformers | Only when Tagged-recursive participation is explicitly excluded — RARE in Group A |

**Negative rules**:

| Forbidden | Why |
|-----------|-----|
| `extension UInt8: Byte.Protocol {}` (stdlib raw type conforming to institute X.Protocol) | UInt8 is the arithmetic-algebras carrier; Byte is the byte-domain twin. Conformance dissolves the separation that motivates the institute twin. Operator shadow (`<`/`==`/`hash`), API-surface broadening, Carrier-composition pollution of `Tagged<_, UInt8>` all follow. |
| Refinement-of-Carrier `X.Protocol` for a Group A type that wants `Tagged<Tag, X>` recursive conformance | Structurally impossible — see constraint principle. |
| Including stdlib protocols as parents of `X.Protocol` (`X.Protocol: Sendable, Equatable, ...`) | Forces every conformer to imply each parent under the same where-clause, which conflicts with Tagged's existing conditional conformances (different where-clauses) and with cross-target conformance lookup (SLI conformances aren't visible from core). Declare stdlib conformances on each conformer separately; default impls on `X.Protocol` provide the witnesses. |
| Generator macro that emits the recipe | Hides the sibling-vs-refinement constraint principle (a structural decision) behind macro expansion. The recipe is ~20 lines; the explicit code surfaces the choice. |
| Meta-protocol unifying the recipe across domains (`Capability.Marker<U>` or similar) | Blocked by [IMPL-102] — Swift's overlapping-conformance rules force the implementation to be incomplete. Same verdict as the capability-lift-pattern family. |

**Future cohorts**: `Char.Protocol` (Unicode code units), `Codepoint.Protocol` (Unicode scalars), `Word.Protocol` (machine words), `Line.Protocol` (lines of text), and any further byte-shape value type follow the same recipe.

**Rationale**: the recipe was rediscovered independently across four adoptions (Cardinal, Ordinal, Vector, Byte); codifying it — with the recursion-vs-refinement constraint principle as the structural anchor — eliminates the rediscovery cost and makes the sibling-vs-refinement decision mechanical. Full text (in-production cohort table, adoption history, provenance): rationale archive §[API-NAME-001c].

**Composes with**: `Group A capability-marker` is the per-`property-tagged-semantic-roles.md` taxonomy; the recipe applies to Group A members. Group B verb-namespace types (`Property` family) do NOT use this recipe — their fibers are sealed by construction and recursive Tagged conformance is not the right composition. [IMPL-102] from the carrier-walkback reflection blocks the meta-protocol alternative.

**Cross-references**: [API-NAME-001] Nest.Name (parent rule for the X/X.Protocol structure), [API-NAME-001b] LargerDomain.Subdomain (sibling rule from the byte-extraction arc), [API-NAME-003] Specification-Mirroring Names (for X.Protocol naming when X is spec-mirrored). Composes with `[IMPL-102]` (Swift overlapping-conformance constraint).

---

### [API-NAME-002] No Compound Identifiers

**Statement**: Methods and properties MUST NOT use compound names — use nested accessors instead. The rule applies to any file-boundary-visible declaration (`internal`/`package`/`public`/`open`; `fileprivate`/`private` exempt), with narrow exemptions for `is`-prefixed booleans, spec-mirroring identifiers, and namespace-redundant prefixes, and an absolute prohibition on repurposing Swift's ownership/effect/isolation keywords (`throwing`, `async`, `borrowing`, etc.) as identifiers.

```swift
// CORRECT
instance.open.write { }
dir.walk.files()

// INCORRECT
instance.openWrite { }  // Compound method - FORBIDDEN
dir.walkFiles()         // Compound method - FORBIDDEN
```

**Lint enforcement**: `Lint.Rule.Naming.Compound` flags compound method, property, and enum-case identifiers via word-boundary detection; the visibility-scope amendment is enforced via the shared effective-visibility helper (walks the parent chain for enclosing fileprivate / private types). Compound TYPE identifiers are covered by `Lint.Rule.Naming.CompoundType` per [API-NAME-001]. Scope detail: rationale archive §[API-NAME-002]. [VERIFICATION: AST Lint.Rule.Naming.Compound]
**Exception (L2 Standards, principal ruling 2026-07-07)**: the same spec-token-transliteration rationale as [API-NAME-001]'s L2 exception applies to compound member identifiers — a deterministic transliteration of a spec-defined method/property name (e.g. W3C CSSOM `timingFunction`) is a spec-mirroring name governed by [API-NAME-003], so this rule's compound-identifier prohibition does NOT mechanically apply at L2. Enforcement mechanism: `Lint.Rule.Bundle.standards` (swift-linter `[LINT-BUNDLE]`) omits `compound identifier` from its rule set; L1 (`Bundle.primitives`) and L3 (`Bundle.institute`) are unchanged and keep the rule active. Invented, non-spec identifiers at L2 remain non-conforming as a text convention even though mechanical enforcement opts out layer-wide.
---

### [API-NAME-003] Specification-Mirroring Names

Types implementing specifications MUST mirror the specification terminology.

```swift
// CORRECT
RFC_4122.UUID
ISO_32000.Page
RFC_3986.URI

// INCORRECT
UUID        // No specification context
PDFPage     // Compound, no spec namespace
URL         // No specification context
```

**Lint enforcement (DEFERRED — insufficient empirical grounding)**: a pilot promotion attempt under `/promote-rule` (5th pilot, 2026-05-13) classified this rule as TEXT-ONLY rather than mechanizable — zero ground-truth declarations exist in either direction to calibrate against. Re-evaluate when the first spec package lands a type at `RFC_NNNN.X` shape. Full reasoning + outcome record pointer: rationale archive §[API-NAME-003].

---

### [API-NAME-004] No Typealiases for Type Unification

**Statement**: When unifying duplicate types across packages, the canonical type MUST be used directly at all call sites. Typealiases MUST NOT be introduced as a unification bridge — they create a false sense of equivalence while adding an indirection layer that complicates navigation and diagnostics.

**Correct**:
```swift
// After unification: all packages use the canonical type directly
import Text_Primitives

func report(at location: Text.Location) { }  // Direct usage
```

**Incorrect**:
```swift
// Typealias bridge — adds indirection without benefit
typealias SourceLocation = Text.Location

func report(at location: SourceLocation) { }  // Obscures actual type
```

**Exception**: Typealiases for generic instantiations remain valid — those localize a *specialization decision*, not a *unification bridge*.

**Lint enforcement**: `Lint.Rule.Naming.UnificationTypealias` flags top-level typealiases to member types whose local name differs from the RHS leaf and that carry no generic argument clause (generic-instantiation typealiases exempt); same-leaf namespace-adoption shapes are flagged separately per [API-NAME-004a]. Scope detail: rationale archive §[API-NAME-004]. [VERIFICATION: AST Lint.Rule.Naming.UnificationTypealias]

**ADT Tower rider — the `Store.Direct` seam alias (M4, ratified 2026-07-03; transcribed at W4, 2026-07-06).** A seam-tier public typealias `Store.Direct` (= the hoisted `__ColumnDirect` marker) lives in Store Protocol Primitives, alongside the hoisted marker per the [API-IMPL-009] hoist idiom (a hoist-alias, not a unification bridge). In-tower conformances and `where`-clauses bind `Store.Direct` — NEVER the dunder `__ColumnDirect`, and NEVER the column-vocabulary spelling `Column.Direct` (which stays the CONSUMER-facing spelling). No dunder token ever appears in a public conformance clause. The `Direct` marker is load-bearing per [API-IMPL-023]'s M4 carve-out (it is the [DS-028] axis-drop fence). Provenance: `Research/adt-tower.md` §4.7, §2 D4.1.

---

### [API-NAME-004a] Namespace Adoption Typealiases

**Statement**: A typealias that adopts a lower-layer type into a higher-layer namespace for domain extension is PERMITTED when the higher layer builds substantial domain behavior on the type (5+ sibling types/extensions/methods). A typealias that merely saves keystrokes (rename bridge) is FORBIDDEN per [API-NAME-004].

**Permitted** — namespace adoption (extends the concept):
```swift
// IO.Event = Kernel.Event — IO builds 52 types on this kernel concept
public typealias Event = Kernel.Event  // Adoption: domain behavior built on top
```

**Forbidden** — rename bridge (saves keystrokes):
```swift
// IO.Deadline = Clock.Suspending.Instant — just a shorter name
public typealias Deadline = Clock.Suspending.Instant  // ❌ No domain behavior added
```

**Lint enforcement**: `Lint.Rule.Naming.NamespaceAdoption` flags typealiases whose name equals the RHS leaf component. The flag is a REVIEW PROMPT: the writer SHOULD confirm the higher-layer namespace declares ≥ 5 sibling types / extensions / methods that justify adoption — without those companions, the same shape is the rename-bridge anti-pattern caught by [API-NAME-004]. The "5+ companions" criterion is out of mechanical scope (cross-file). Scope detail: rationale archive §[API-NAME-004a]. [VERIFICATION: AST Lint.Rule.Naming.NamespaceAdoption]

**Cross-references**: [API-NAME-004], [API-NAME-001], [PKG-NAME-015]

---

### [API-NAME-015] Namespace Depth Is Not a Design Constraint

**Statement**: Nesting depth is NOT a design constraint. A `Nest.Name` chain MAY be as deep as the domain's semantic structure requires — there is no maximum depth to stay under and no minimum to reach for. The ONLY criterion is the one [API-NAME-001] already sets: every level must carry real semantic weight, so that `A.B.C.D` reads as "D within C within B within A" with each step naming a genuine narrower sub-domain.

```swift
// CORRECT — every level narrows the scope to a real sub-domain
POSIX.Kernel.IO.Read          // a read, in kernel I/O, in the POSIX domain
RFC_4122.UUID.Version         // a version, of a UUID, in the RFC 4122 domain

// INCORRECT — flattening a semantically correct nest to shorten the path
POSIX.KernelIORead            // compound name - FORBIDDEN by [API-NAME-002]
KernelIORead                  // compound name, domain lost - FORBIDDEN by [API-NAME-001]

// INCORRECT — a filler level carrying no semantic content
POSIX.Kernel.Types.IO.Read    // "Types" names no sub-domain - remove it
```

**Corollaries**:

- **(a) Never flatten a semantically correct nest for brevity, ergonomics, or discoverability.** Collapsing a real chain into a shorter compound identifier to reduce path length produces exactly the compound name forbidden by [API-NAME-001] (types) and [API-NAME-002] (methods/properties). Path length is never a reason to flatten; if every level is semantic, the depth is correct however deep it runs.
- **(b) Depth is not a virtue either.** Adding filler levels that carry no semantic content — a level that does not narrow the scope, or one that only groups unrelated siblings — is wrong for the same reason a compound name is wrong: the path stops mirroring the domain. A level that fails [API-NAME-001a]'s single-type-no-namespace test, or that a reader cannot phrase as "X within Y", is filler and MUST be removed.

**Decision test**: apply [API-NAME-001]'s "X is a kind of Y" / "X belongs to Y" test to each *adjacent pair* in the chain. If every adjacent pair passes, the depth is correct no matter how deep. If any pair fails, that level is either filler (remove it) or misplaced (re-nest it) — the fix is local to the failing level and independent of the total depth.


**Cross-references**: [API-NAME-001] Nest.Name (the semantic-weight criterion this rule elaborates), [API-NAME-001a] Single-Type-No-Namespace (the filler-level test), [API-NAME-002] No Compound Identifiers (what flattening produces).

---
