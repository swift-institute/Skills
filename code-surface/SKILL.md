---
name: code-surface
description: |
  API surface conventions: namespace structure, nested accessors, spec-mirroring, typed throws, error naming, one type per file.
  ALWAYS apply when declaring types, methods, properties, errors, or organizing files.

layer: implementation

requires:
  - swift-institute

applies_to:
  - swift
  - swift6
  - primitives
  - standards
  - foundations

absorbs:
  - naming
  - errors
  - code-organization
# Amendment/changelog history: Research/code-surface-skill-rationale.md §Changelog-Provenance (and git history of this file).
---

# Code Surface Conventions

All types, methods, properties, error types, and source files MUST follow these rules.

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/code-surface-skill-rationale.md` (referenced below as the rationale archive).

---

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
**Exception (L2 Standards, principal ruling 2026-07-07)**: L2 Standards packages optimize for 1:1 spec encodings. An identifier that is a deterministic transliteration of a spec-defined token — per the spec community's own naming convention (e.g. W3C CSSOM camelCase like `animationName`, IEEE 754 operation names like `roundAwayFromZero`, POSIX symbols) — is a spec-mirroring name governed by [API-NAME-003], so this rule's compound-type-name prohibition does NOT mechanically apply at L2. Enforcement mechanism: `Lint.Rule.Bundle.standards` (swift-linter `[LINT-BUNDLE-001]`) omits `compound type name` from its rule set; L1 (`Bundle.primitives`) and L3 (`Bundle.institute`) are unchanged and keep the rule active. Invented, non-spec identifiers at L2 remain non-conforming as a text convention even though mechanical enforcement opts out layer-wide.
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
**Exception (L2 Standards, principal ruling 2026-07-07)**: the same spec-token-transliteration rationale as [API-NAME-001]'s L2 exception applies to compound member identifiers — a deterministic transliteration of a spec-defined method/property name (e.g. W3C CSSOM `timingFunction`) is a spec-mirroring name governed by [API-NAME-003], so this rule's compound-identifier prohibition does NOT mechanically apply at L2. Enforcement mechanism: `Lint.Rule.Bundle.standards` (swift-linter `[LINT-BUNDLE-001]`) omits `compound identifier` from its rule set; L1 (`Bundle.primitives`) and L3 (`Bundle.institute`) are unchanged and keep the rule active. Invented, non-spec identifiers at L2 remain non-conforming as a text convention even though mechanical enforcement opts out layer-wide.
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

## Brand-Owner Lint Configuration

### [API-IMPL-024] No Redundant Protocol-Refinement Restatement

**Statement**: A protocol composition or conformance clause MUST NOT restate a protocol that another stated member already refines — the compiler enforces the parent through the refinement.

```swift
func sort<T: Comparable>(_: [T])              // ✓ Equatable comes with Comparable
func sort<T: Comparable & Equatable>(_: [T])  // ❌ redundant: Comparable refines Equatable
```

**Enforcement**: Mechanical — AST `Lint.Rule.Idiom.RedundantRefinement` (`redundant refinement`, universal tier; stdlib refinement table). Rule authored 2026-07-06 as the diagnostic's owning canon (principal ruling). [VERIFICATION: AST]

---

### [API-BRAND-001] Brand-Owner Exclusion Vocabulary

**Statement**: Brand-owner packages (those whose primary export is a wrapper or marker establishing a brand — `Cardinal`, `Ordinal`, `Cyclic.Group.Static<n>.Element`, `Carrier.\`Protocol\`` etc.) MUST declare a per-package `Lint.swift` that excludes the rules targeting their brand-boundary vocabulary, while keeping the rule corpus brand-form-agnostic. The exclusion vocabulary varies by brand-form (protocol-form vs value-form).

**The principle**: The rule corpus is brand-form-agnostic by design — rules target idioms that are anti-patterns FOR EXTERNAL CONSUMERS but are the brand-owner's own protocol-witness or wrapper-boundary surface. The corpus stays uniform; the per-package `excluding(rules:)` declares which rules apply to external consumers but NOT to the brand-owner's own brand-boundary.

**Brand-form distinction**:

- **Protocol-form brand-owner**: the brand is a refinement protocol (e.g., `Carrier.\`Protocol\``). Consumers conform their own types to the protocol. The brand-owner's own surface is the protocol declaration + in-package conformer fixtures.
- **Value-form brand-owner**: the brand is a wrapping value type (e.g., `Cardinal` wraps `UInt`; `Ordinal` wraps `UInt`; `Cyclic.Group.Static<n>.Element` wraps `Ordinal`). The brand-owner's own surface is the wrapper type + its `__unchecked:` constructors + its `.rawValue` accessor + its arithmetic/integration overloads.

**Protocol-form exclusion vocabulary** (1 rule):

| Rule ID | Reason for exclusion at protocol-form brand-owner |
|---|---|
| `int public parameter` | In-package `Carrier.\`Protocol\`` conformers with `Underlying == Int` take `Int` directly because `Int` IS the Underlying being wrapped at the brand boundary. |

**Value-form exclusion vocabulary** (per-brand subset; the rules each value-form brand-owner MAY exclude depending on which boundary vocabulary surfaces in its API):

| Rule ID | Reason for exclusion at value-form brand-owner |
|---|---|
| `raw value access` | The brand-owner exposes `.rawValue` (or the wrapper's underlying access) at its canonical boundary. |
| `chained rawvalue access` | Same — the brand-owner is the legitimate `.rawValue` chain origin. |
| `bitpattern rawvalue chain` | Stdlib-integration overloads at the brand boundary chain `.rawValue` into `Int.init(bitPattern:)` patterns. |
| `int public parameter` | Stdlib-mirror overloads accept bare `Int` at the brand-boundary integration sites (matches the wrapped type's stdlib API). |
| `pointer advanced by` | Pointer-arithmetic stdlib-mirror overloads at the brand boundary. |
| `unchecked call site` | The brand-owner's `__unchecked:` constructors are the canonical bypass-validation entry. |
| `zero or one literal` | The brand-owner defines `.zero` / `.one` via integer literals at the wrapper's identity-element accessors. |
| `tagged extension public init` | The brand-owner's `Tagged+<Brand>.swift` extension exposes the `Tagged<Tag, Brand>` public init at the brand-domain typed-ID boundary. |

**How to apply**:

1. **Identify the brand**: what type or protocol does this package PRIMARILY export as a wrapper or marker? If it's a refinement protocol consumers conform to, it's protocol-form. If it's a wrapping value type with `__unchecked:` constructors and `.rawValue` access, it's value-form.
2. **Select exclusion subset**: from the appropriate vocabulary table above, exclude only those rules that fire on legitimate-by-construction brand-boundary sites in your package. The exclusion subset is the empirical minimum — don't exclude rules just because the vocabulary lists them; exclude only what fires on your actual surface.
3. **Declare in `Lint.swift`**: use `Lint.Rule.Bundle.primitives.excluding(rules: [ Lint.Rule.\`name\`.id, ... ])` (or the equivalent bundle for non-primitives tiers). Cite each exclusion with a `// reason:` comment naming the specific brand-boundary site that justifies it.
4. **Cross-package consumers**: external consumers using your brand should NOT exclude these rules. The corpus's strict-superset firing on external consumers IS the architectural intent.

**Rationale**: each excluded rule remains in the corpus and fires on every other consumer — brand-owners declare their boundary, not bypass the rule. Full text (per-package cohort empirical exclusion table, provenance): rationale archive §[API-BRAND-001].

**Composes with**:
- `[API-NAME-001c]` (capability-marker protocol) — value-form brand-owners often appear as `Carrier.\`Protocol\`` conformers via the capability-marker recipe.
- Rule corpus design principle: each excluded rule remains in the corpus and fires on every other consumer. The corpus stays uniform; brand-owners declare their boundary, not bypass the rule.

**Lint enforcement**: AST mechanization TBD. The configuration discipline (which exclusions a brand-owner declares, the per-entry justification comment, the protocol-form vs value-form cardinality split) is codified as `[LINT-EXCLUDE-001]` through `[LINT-EXCLUDE-004]` in the **swift-linter** skill — the linter-side application of the brand-owner vocabulary defined in this rule. Future AST candidates: rationale archive §[API-BRAND-001].

**Cross-references**: [API-NAME-001c] (capability-marker protocol); [API-IMPL-008] (minimal type body — companion note covers protocol-witness methods on associatedtype-using storage, the case that arose during the cohort cyclic.Iterator refactor); **swift-linter** skill `[LINT-EXCLUDE-*]` (linter-side application of this vocabulary).

---

## Error Handling

**Enforcement**: TEXT-ONLY (insufficient grounding — brand-owner membership needs a curated list; /promote-rule 2026-07-06). Re-promotable via a ratified brand-owner list (`.naming-vocabulary` pattern): `Audits/PROMOTE-API-BRAND-001-2026-07-06.md`.

### [API-ERR-001] Typed Throws Required

All throwing functions MUST use typed throws.

```swift
// CORRECT
func read() throws(IO.Error) -> Data
func parse() throws(Parse.Error) -> Document

// INCORRECT
func read() throws -> Data       // Erases error type - FORBIDDEN
func parse() throws(any Error)   // Existential error - FORBIDDEN
```

**Lint enforcement**: SwiftLint custom rule `typed_throws_required` (`swift-institute/.github/.swiftlint.yml`) flags `throws` without a typed-throws specifier in `Sources/`; AST counterpart `Lint.Rule.Throws.Untyped` flags any throws clause whose type is `nil` (covers `func f() throws` and `func g() async throws -> T`). The existential-throws sub-case (`throws(any Error)`) is handled separately per [API-ERR-006]. [VERIFICATION: SwiftLint typed_throws_required, AST Lint.Rule.Throws.Untyped]

---

### [API-ERR-002] Nested Error Types

Error types MUST be nested as `Domain.Error` following [API-NAME-001]. The conformance MUST qualify the standard library protocol explicitly as `Swift.Error` per [PLAT-ARCH-011], even though the type's own name is the bare `Error` token.

```swift
// CORRECT
enum IO {
    enum Error: Swift.Error {
        case posix(errno: CInt, operation: Operation, path: FilePath)
        case timeout(duration: Duration, operation: Operation)
    }
}

// INCORRECT
enum IOError: Error {           // Compound name - FORBIDDEN
    case posix(...)
}
```

**Lint enforcement**: The `swift_error_qualification` SwiftLint custom rule (`swift-institute/.github/.swiftlint.yml`) flags bare `Error` references that should be `Swift.Error`; declaration tokens (`enum Error:`, etc.) are exempt. Reference sites inside an extension MUST use the fully-nested type (e.g., `Random.Error`, `Storage.Pool.Error`). `Self.Error` is forbidden in `throws(...)` clauses outside protocol declarations carrying `associatedtype Error`. The AST counterpart `Lint.Rule.Platform.SwiftQualification` (per [PLAT-ARCH-011] / [PLAT-ARCH-022]) subsumes this regex for the `Error` token. [VERIFICATION: SwiftLint swift_error_qualification]

---

### [API-ERR-003] Describe Failure, Not Recovery

Error cases SHOULD describe the failure condition, not the recovery action.

```swift
// CORRECT
case invalidHeader(expected: UInt32, found: UInt32)
case insufficientCapacity(required: Int, available: Int)
// INCORRECT
case retryLater              // Describes recovery, not failure
case useDefaultValue         // Describes recovery, not failure
```

---

### [API-ERR-004] Explicit Closure Annotation for Typed Throws

**Statement**: When calling a stdlib `rethrows` function from a `throws(E)` context, the closure MUST include an explicit `throws(E)` annotation. Without it, Swift 6.2 infers `any Error`, erasing the typed throw.

**Correct**:
```swift
func transform<E: Error>(_ values: [Int], using f: (Int) throws(E) -> String) throws(E) -> [String] {
    try values.map { (value: Int) throws(E) -> String in
        try f(value)
    }
}
```

**Incorrect**:
```swift
func transform<E: Error>(_ values: [Int], using f: (Int) throws(E) -> String) throws(E) -> [String] {
    try values.map { try f($0) }  // Infers `any Error`, not E
}
```

**Lint enforcement**: `Lint.Rule.Throws.ClosureAnnotation` flags closures containing `try` inside typed-throws functions when the closure signature lacks a typed `throws(...)` annotation; closures without `try` and closures inside untyped `throws` outer functions are exempt. Scope detail: rationale archive §[API-ERR-004]. [VERIFICATION: AST Lint.Rule.Throws.ClosureAnnotation]

### [API-ERR-005] stdlib Typed Throws Compatibility (Swift 6.2.4)

**Statement**: Only a subset of stdlib `rethrows` functions preserve typed throws. Do NOT add `@_disfavoredOverload` overloads for functions that already work — they interfere with the stdlib's native support. [VERIFICATION NEEDED 2026-05-10: lists pinned to Swift 6.2.4; revalidate against Swift 6.3.1+. Experiment dispatched separately per [EXP-012].]

**Works with explicit `throws(E)` closure** (Swift 6.2.4):
- `Sequence.map`, `withUnsafeBytes(of:)`, `withUnsafeMutableBytes(of:)`, `Mutex.withLock`

**Does NOT preserve typed throws** (rethrows still erases E):
- `compactMap`, `flatMap`, `filter`, `forEach`, `reduce`, `contains(where:)`, `allSatisfy`, `first(where:)`, `sorted(by:)`, `min(by:)`, `max(by:)`, `drop(while:)`, `prefix(while:)`

**Rationale**: Partial stdlib support is undocumented. Adding same-name overloads causes the rethrows version to be selected, which is strictly worse than no overload.

---

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

**Enforcement**: TEXT-ONLY (cross-module associatedtype knowledge — the [MOD-016] per-file-AST class; /promote-rule 2026-07-06): `Audits/PROMOTE-API-IMPL-019-2026-07-06.md`.

### [API-IMPL-020] Explicit `Body = Never` Typealias on Generic Parser/Serializer Leaf Conformers

**Statement**: Generic types conforming to `Parser.Protocol` / `Serializer.Protocol` / `Coder.Protocol` as leaf conformers (no `body` property delegating to another Parser/Serializer body) MUST declare `public typealias Body = Never` explicitly; without it, witness-table emission for generic conformers fails at link time with `Undefined symbols ... protocol witness for body.getter`.

**Enforcement**: Mechanical — `Lint.Rule.Conformance.LeafBodyTypealias` in `swift-foundations/swift-institute-linter-rules`, target `Linter Rule Conformance` (institute tier; first AST-domain pivot promotion of `/promote-rule` 2026-05-15). Discipline: `Audits/PROMOTE-API-IMPL-020-2026-05-15.md`. [VERIFICATION: AST]

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

**Enforcement**: Mechanical — `Lint.Rule.Tower.FrozenTowerType` (`frozen tower type`, primitives tier, pack `Primitives Linter Rule Tower`; ζ pilot of /promote-rule 2026-06-12). Discipline: `Audits/PROMOTE-API-IMPL-022-2026-06-12.md`. [VERIFICATION: AST Lint.Rule.Tower.FrozenTowerType] **ADT Tower rider (2026-07-02)**: the tower carriers (`__X<S: ~Copyable>`) are stored value types ⇒ `@frozen` from birth ([DS-025]; `Experiments/adt-tower-worked-example` complies); front-door aliases carry no storage of their own (generic-instantiation aliases, [DS-028]) so the `@frozen` obligation lands on the carrier (`Research/adt-tower.md` §4.7).

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

## State Modeling

### [API-IMPL-003] Enum Over Boolean

Use enums instead of boolean flags when state can expand.

```swift
// CORRECT
enum Connection {
    enum State {
        case disconnected
        case connecting
        case connected(Session)
        case disconnecting
    }
}

// INCORRECT
var isConnected: Bool     // Cannot represent connecting/disconnecting
var isConnecting: Bool    // Requires multiple booleans
```

**Lint enforcement**: `Lint.Rule.Naming.BoolParameter` flags `Bool` (or `Swift.Bool`) parameters in `public` / `open` function or initializer signatures (optional/IUO wrappers detected; closure-typed parameters taking Bool internally exempt; non-public visibility exempt; return-type `Bool` not flagged). Scope detail: rationale archive §[API-IMPL-003]. [VERIFICATION: AST Lint.Rule.Naming.BoolParameter]

---

### [API-IMPL-010] Visibility Change Triggers Naming Audit

**Statement**: Widening a type's or member's access level (e.g., `private` → `internal`, `internal` → `public`) MUST trigger a naming audit against [API-NAME-001] and [API-NAME-002]. Names that were acceptable at narrower visibility may violate conventions when exposed to a wider audience.

**Correct**:
```swift
// Was private — compound name hidden from scrutiny
// private struct ReadResult { ... }

// Widening to internal: audit catches compound name
// Fix: namespace enum + nested Result
enum Read { struct Result { ... } }
```

**Incorrect**:
```swift
// Was private, now widened to internal
internal struct ReadResult { ... }  // ❌ Compound name now visible
```

**Rationale**: Private names accumulate naming debt invisible to convention enforcement; the audit is a one-time cost at the boundary change. Full text: rationale archive §[API-IMPL-010].

**Cross-references**: [API-NAME-001], [API-NAME-002]

---

### [API-IMPL-011] Wrapper Completeness

**Statement**: A wrapper type that owns construction, invariants, and error domain MUST also own the primary operation. A wrapper that encapsulates 90% of an interface is worse than one that encapsulates 100% or 0%, because the escape hatch for the missing 10% dominates the user's experience and makes the wrapper appear useless.

**Correct**:
```swift
// IO.Lane wraps IO.Blocking.Lane
// Owns: factories, error domain, Handle, DI conformance
// Also owns: run() — the primary operation
// → Complete wrapper, _backing never exposed to consumers
```

**Incorrect**:
```swift
// IO.Lane wraps IO.Blocking.Lane
// Owns: factories, error domain, Handle, DI conformance
// Missing: run() — the primary operation
// → Every consumer calls lane._backing.run { }
// ❌ Wrapper looks fake; the 10% escape dominates
```

**Lint enforcement**: `Lint.Rule.Structure.WrapperBackingExposed` flags `_backing` / `_wrapped` / `_underlying` properties wider than `private` / `fileprivate` (the canonical incomplete-wrapper leak); `@usableFromInline` decls exempt; full wrapper-completeness verification is out of mechanical scope. Scope detail: rationale archive §[API-IMPL-011]. [VERIFICATION: AST Lint.Rule.Structure.WrapperBackingExposed]

**Cross-references**: [API-LAYER-001], [IMPL-074]

---

## Parameter Ordering

### [API-IMPL-012] Closure Parameters Trail the Signature

**Statement**: All closure parameters MUST occupy the final positions of a function or initializer signature; a non-closure parameter MUST NOT appear after a closure parameter. Typed-throws thunks per [IMPL-092] — `() throws(E) -> T` — are closures for the purpose of this rule.

**Correct**:
```swift
public init(
    id: ID,
    interest: Interest,
    flags: Options = [],
    onEvent: @escaping (Event) -> Void
)
```

**Incorrect**:
```swift
public init(
    id: ID,
    onEvent: @escaping (Event) -> Void,
    flags: Options = []                    // ❌ non-closure after closure
)
```

**Lint enforcement**: `Lint.Rule.Closure.ParameterPosition` flags every non-closure parameter following a closure-typed parameter; optional, attributed (`@escaping`/`@Sendable`), and typed-throws closures all count as closures per [IMPL-092]. Scope detail: rationale archive §[API-IMPL-012]. [VERIFICATION: AST Lint.Rule.Closure.ParameterPosition]

**Cross-references**: [API-IMPL-013], [API-IMPL-014], [IMPL-092]

---

### [API-IMPL-013] Multiple Closures Follow Lifecycle Order

**Statement**: For signatures with two or more closure parameters, closures MUST be ordered by lifecycle (setup → body → completion/teardown); the primary body closure MAY be unlabeled but all subsequent closures MUST be labeled per SE-0279, naming the closure's *role* in the operation (not its Swift type) per [API-NAME-002].

**Correct** — validated at `swift-primitives/.../Kernel.Completion.Driver.swift:104`:
```swift
public init(
    submit:        @escaping (Submission, borrowing Descriptor) throws(Error) -> Void,
    flush:         @escaping () throws(Error) -> Submission.Count,
    drain:         @escaping ((Event) -> Void) -> Event.Count,
    close:         @escaping () -> Void,
    overflowCount: @escaping () -> Event.Count = { .zero }
)
```

**Incorrect**:
```swift
// ❌ completion before body — body loses trailing-closure position at call sites
public func perform(
    completion: @escaping (Result) -> Void,
    body: @escaping () -> Void
)
```

**Cross-references**: [API-IMPL-012], [API-NAME-002]

**Lint enforcement**: `Lint.Rule.Closure.MultipleLifecycle` flags signatures with ≥ 2 closure parameters whose 2nd-and-onward closure has a wildcard `_` external label; companion `Lint.Rule.Closure.LifecycleOrder` enforces the ORDER aspect (a completion-tier label appearing before a body-tier closure is flagged). Scope detail: rationale archive §[API-IMPL-013]. [VERIFICATION: AST Lint.Rule.Closure.MultipleLifecycle, AST Lint.Rule.Closure.LifecycleOrder]

---

### [API-IMPL-014] Configuration Parameter Placement

**Statement**: Configuration-bearing parameters (`.Options`, `.Configuration`, `.Context`, or `OptionSet` types) MUST sit **first** (labeled or unlabeled) when the configuration IS the primary input, or **last in the non-closure portion** of the signature (labeled, with a default) when it modifies a primary operation; middle placement and splitting configuration across sibling parameters are both FORBIDDEN.

**Correct — configuration as modifier** (`swift-primitives/.../Kernel.Event.swift:53`):
```swift
public init(id: ID, interest: Interest, flags: Options = [])
```

**Incorrect**:
```swift
public func perform(
    on target: Target,
    options: Options = [],                 // ❌ middle placement
    mode: Mode,
    body: @escaping () -> Void
)
```

**Lint enforcement**: `Lint.Rule.Closure.ConfigurationPlacement` flags configuration-bearing parameters (type-name suffix `Options` / `Configuration` / `Context`) sitting at neither index 0 nor the last non-closure index; splitting-configuration-across-siblings detection is beyond the mechanical rule. Scope detail: rationale archive §[API-IMPL-014]. [VERIFICATION: AST Lint.Rule.Closure.ConfigurationPlacement]

**Cross-references**: [API-IMPL-012]

---

### [API-NAME-006] New-Code Self-Compliance During Enforcement Sweeps

**Statement**: When a session runs a rule-enforcement sweep (converting N files to comply with [API-NAME-*] or a related convention), any NEW code authored in the same session — for ANY purpose (tests, experiments, fixtures, article examples, handoff artifacts, internal helpers) — MUST be swept for the same rule before commit. The session's enforcement scope includes parallel new code, not just the enumerated enforcement target.

**Procedure**:

1. At enforcement-sweep start, note the rule being enforced and its regex / scan pattern.
2. Before any commit that includes new files (of any kind), re-run the scan pattern against the new files.
3. If the new files violate the rule, fix them in the same commit.

**Rationale**: Enforcement sweeps routinely produce incidental new code; skipping it paradoxically enlarges the non-compliance surface, and the fix is cheap at authoring time and expensive later. Full text (defect example, provenance): rationale archive §[API-NAME-006].

**Cross-references**: [API-NAME-001], [API-NAME-002]

---

### [API-NAME-005] Pre-Rename Mechanical Check for New Type Identifiers

**Statement**: Any new type identifier introduced during refactoring MUST be verified against [API-NAME-001] (Nest.Name pattern) and [API-NAME-002] (no compound identifiers) BEFORE the identifier is applied, not after. The check is a mechanical test the refactor workflow runs against the proposed name.

**Test (applied to each proposed new identifier)**:

1. Does the name contain an embedded capitalized second-word fragment (e.g., `CaseInsensitive`, `NonBlocking`, `BufferLinked`)? If yes, it is a compound — decompose into `Case.Insensitive`, `NonBlocking` (reserved — blocked), `Buffer.Linked`.
2. Does the name start with a verb-like form followed by a noun (`walkFiles`, `openWrite`)? If yes, it is a compound — decompose into `walk.files`, `open.write`.
3. Is the name exactly the same as an existing spec-literal or ecosystem-established term? If the match is intentional, cite the source; if not, rename to avoid accidental collision.

**Rationale**: Catching naming violations at the proposal step is strictly cheaper than at commit or review, and new types rarely appear in isolation (Options, Error, Iterator all inherit the violation). Full text (provenance): rationale archive §[API-NAME-005].

**Cross-references**: [API-NAME-001], [API-NAME-002]

---

### [API-NAME-007] Convention-Known-Convention-Unapplied Heuristic for Method/Property Names

**Statement**: When a proposed method or property name (a) contains an internal capital letter, OR (b) is copied or adapted from the Swift stdlib, an SE proposal, or another language's API, the name MUST be re-verified against [API-NAME-002] (no compound identifiers) BEFORE commit. Both conditions independently trigger the check; either fires it.

**Procedure**:

1. Before committing a new method or property, identify the proposed name.
2. Apply the test: does the name contain an internal capital letter? Is it copied/adapted from stdlib / SE / other-language? If either is yes, proceed to step 3.
3. Re-verify against [API-NAME-002]: is this a compound identifier? If yes, decompose into nested accessor (multi-form) per [API-NAME-008], or labeled method (single-form) per [API-NAME-008].
4. Update the implementation, file name, and commit-message subject to use the corrected name.

**Rationale**: [API-NAME-002] is declarative knowledge that fails procedurally at the moment of naming; codifying the two triggers converts the rule from ambient judgment to a mechanical pre-commit gate. Full text (origin incident — `Array.swapAt` post-ship rename, provenance): rationale archive §[API-NAME-007].

**Cross-references**: [API-NAME-002], [API-NAME-005], [API-NAME-008]

---

### [API-NAME-008] Property.View vs Labeled Method Decision Rule

**Statement**: Both Property.View nested accessors and direct labeled methods are [API-NAME-002]-compliant approaches to avoiding compound identifiers. The choice between them is structural: **multi-form operations (two or more related sub-operations under one root) MUST use Property.View nested accessors; single-form operations (one operation, disambiguated by argument labels) MUST use direct labeled methods.** A Property.View wrapper around a single method adds per-variant types + typealias + property getter for zero call-site expressivity gain.

**Decision test**:

| Operation shape | Convention |
|-----------------|------------|
| `remove.{first, last, all}` — three related sub-operations | Property.View (`remove`) — multi-form |
| `peek.{front, back}` — two related sub-operations | Property.View (`peek`) — multi-form |
| `forEach.{borrowing, consuming, index}` — three related forms | Property.View (`forEach`) — multi-form |
| `swap(at:with:)` — one operation, two indices distinguished by labels | Labeled method (`swap`) — single-form |
| `truncate(to:)` — one operation, target distinguished by label | Labeled method — single-form |
| `clone()` / `clone(capacity:)` — same operation with optional capacity | Labeled method, overloaded — single-form |

**Procedure (decision-test for new APIs)**:

1. Enumerate the related sub-operations the proposed API would expose.
2. Are there 2+ sub-operations naturally under one root noun? → Property.View nested accessor.
3. Is there 1 operation, disambiguated by argument labels? → Direct labeled method.
4. Layer-consistency soft tie-breaker: when a labeled method exists at the layer below (e.g., `Buffer.Linear.swap(at:with:)`), match the name at the higher layer (`Array.swap(at:with:)`) — different names at different layers create friction at every delegation; matching names make the delegation invisible.

**Rationale**: [API-NAME-002] bans compound identifiers but is silent on when nested-accessor ceremony is warranted; codifying multi-form-vs-single-form prevents Property.View ceremony on single-form operations. Full text (origin incident — `swap` Option A/B analysis, provenance): rationale archive §[API-NAME-008].

**ADT Tower rider — the remove-op naming decree (M5, ratified 2026-07-03; transcribed at W4, 2026-07-06).** Tower-wide, a SINGLE-WORD removal op that can fail on empty returns `Optional` — `pop() -> Element?` (extending the SEAT's remove-from-empty ruling, adt-tower §9.3, into a naming decree): `Array.removeLast()` → `pop()`, and every family's single-word remove follows. This supersedes any [API-NAME-008] compound-name pressure for `~Copyable`-carrier remove ops — the `Optional`-consuming return is available for `~Copyable` elements. Carve-out: a `~Copyable` BORROW of `Element?` is structurally unavailable, so borrowing accessors keep crashing preconditions (e.g. `min`) rather than vending `Optional`. Provenance: `Research/adt-tower.md` §4.7, §9.3.

**Cross-references**: [API-NAME-002], [API-NAME-007]

---

### [API-NAME-009] Educational-Diagnostic Message Format

**Statement**: When a diagnostic-emitting rule (linter rule, validation rule, error-reporter) cites an institutional source — a skill rule ID, a feedback-memory file, a research doc — the message text MUST follow the format `"[<rule_id>] <citation>: <description>"` at the message-text layer itself, not just in the rule's source code or the reporter's structured envelope.

**Correct**:
```
[compound_identifier] [API-NAME-002]: method/property `walkFiles` is a compound
identifier; use nested accessor `walk.files()` per the Nest.Name pattern.
```

**Incorrect**:
```
Don't use try?                           // ❌ no rule_id, no citation, no description
[try_optional] Avoid try?                // ❌ no citation, terse description
try? is not allowed here                 // ❌ no rule_id at message layer
```

**Lint enforcement**: Reusable workflow `validate-diagnostic-format.yml` + `.github/scripts/validate-diagnostic-format.py` flag rule-source message strings not beginning with `[<rule_id>] <citation>: `; namespace placeholder files and non-rule sources are out of scope; citation existence is not verified. Scope detail: rationale archive §[API-NAME-009]. [VERIFICATION: WF validate-diagnostic-format.py (API-NAME-009)]

**Cross-references**: [API-NAME-001], [API-NAME-002], [API-ERR-001]

---

### [API-ERR-006] No Existential Throws Ever

**Statement**: Existential throws (`throws`, `throws(any Error)`) are FORBIDDEN — [API-ERR-001] requires typed throws and is non-negotiable; when a stored closure can throw user-domain errors, make the containing type generic over the error type rather than leaving it untyped.

**Correct**:
```swift
public struct Pool<Resource: ~Copyable, CreateError: Swift.Error>: ~Copyable {
    private let create: () throws(CreateError) -> Resource

    public func acquire() throws(CreateError) -> Resource { try create() }
}
```

**Incorrect**:
```swift
public struct Pool<Resource: ~Copyable>: ~Copyable {
    // DESIGN: closure may throw user errors, leaving untyped — ❌ deferred fix, not resolution
    private let create: () throws -> Resource
}
```

**Lint enforcement**: SwiftLint custom rule `no_existential_throws` catches `throws(any Error)`; companion rule `no_any_protocol_existential` extends the discipline to `any <Protocol>` references generally in `Sources/`; AST counterpart `Lint.Rule.Throws.Existential` flags `throws(any Error)` / `throws(any Swift.Error)`. Scope detail: rationale archive §[API-ERR-006]. [VERIFICATION: SwiftLint no_existential_throws, AST Lint.Rule.Throws.Existential]

**Cross-references**: [API-ERR-001], [API-ERR-002]

---

### [API-ERR-007] Public API Path for Error Types, Not Hoisted Internals

**Statement**: When referencing error types in `throws(...)` clauses from extension-declared nested types, use the fully-qualified module path with explicit generic parameters. Never reference the `__` prefixed hoisted type directly.

**Correct**:
```swift
extension Dictionary_Primitives_Core.Dictionary.Ordered.Bounded {
    public func insert(...) throws(Dictionary_Primitives_Core.Dictionary<Key, Value>.Ordered.Bounded.Error) { ... }
}
```

**Incorrect**:
```swift
extension Dictionary_Primitives_Core.Dictionary.Ordered.Bounded {
    public func insert(...) throws(__DictionaryOrderedBoundedError<Key>) { ... }  // ❌ hoisted internal
}
```

**Lint enforcement**: `Lint.Rule.Throws.HoistedError` flags `throws(T)` clauses on `public` / `open` functions and initializers whose leaf identifier starts with `__` (hoisted internal leaking into the public surface); single-underscore prefixes, non-public visibility, and untyped `throws` are exempt. Scope detail: rationale archive §[API-ERR-007]. [VERIFICATION: AST Lint.Rule.Throws.HoistedError]

**Cross-references**: [API-ERR-001], [API-NAME-001]

---

### [API-ERR-008] Lifecycle Typealias Only When ALL Cases Apply

**Statement**: A typealias from a per-primitive error type to a shared lifecycle-error type (`Async.Lifecycle.Error`, `Pool.Lifecycle.Error`, etc.) MUST be adopted only when ALL cases of the lifecycle type are produced by the primitive; if some cases would be unreachable, keep the per-primitive enum with only the cases actually produced.

**Lint enforcement**: `Lint.Rule.Throws.LifecycleTypealiasReview` flags `typealias Error = <…>.Lifecycle.Error` shapes; case coverage cannot be verified mechanically — the flag surfaces the decision as a review prompt. Scope detail: rationale archive §[API-ERR-008]. [VERIFICATION: AST Lint.Rule.Throws.LifecycleTypealiasReview]

**Cross-references**: [API-ERR-001], [API-ERR-002]

---

### [API-NAME-010] No `*Tag` Suffix for Phantom Types

**Statement**: Phantom-type tags used as generic parameters (typically with `Tagged<Tag, RawValue>`) MUST use the bare concept name. The `*Tag` suffix is FORBIDDEN.

**Correct**:
```swift
public typealias Ticket = Tagged<IO.Blocking.Ticket, UInt64>
//                                ^^^^^^^^^^^^^^^^^ bare concept name
```

**Incorrect**:
```swift
public typealias Ticket = Tagged<IO.Blocking.TicketTag, UInt64>  // ❌ Tag suffix
```

**Lint enforcement**: SwiftLint custom rule `no_tag_suffix_phantom` catches `Tagged<\w+Tag,` literals; AST counterpart `Lint.Rule.Naming.Tag` flags `Tag`-suffixed struct/enum declarations with empty bodies (the empty-body heuristic isolates phantom markers from legitimate `*Tag` domain types). Scope detail: rationale archive §[API-NAME-010]. [VERIFICATION: SwiftLint no_tag_suffix_phantom, AST Lint.Rule.Naming.Tag]

**Cross-references**: [API-NAME-001], [API-NAME-002], [API-NAME-010a]

---

### [API-NAME-010a] No Nested `.Tag` Sub-Name for Phantom Types

**Statement**: When a phantom-type parameter is needed for `Property<Tag, Base>`, `Tagged<Tag, Underlying>`, or any similar Tagged-shape API, the surrounding namespace enum MUST play the phantom role directly — introducing an inner `.Tag` sub-type as the phantom is FORBIDDEN. This rule complements [API-NAME-010] (suffix form) by closing the nested-sub-name form: `Order.Tag` is wrong for the same reason `OrderTag` is wrong — the namespace itself is the concept.

**Correct**:
```swift
public enum Order: Sendable {}

extension Property.Inout where Tag == Order, Base: ~Copyable { ... }

extension Order.Orderable where Self: ~Copyable {
    public var order: Property<Order, Self>.Inout { ... }
}
```

**Incorrect**:
```swift
public enum Order: Sendable {}

extension Order {
    public enum Tag {}                                       // ❌ inner .Tag sub-name
}

extension Property.Inout where Tag == Order.Tag, Base: ~Copyable { ... }
//                                    ^^^^^^^^^ — Order alone is the answer
```

**Lint enforcement**: `Lint.Rule.Naming.NestedTag` flags struct/enum declarations literally named `Tag` with empty bodies inside an enclosing type-decl or extension context; domain `.Tag` types with stored properties / cases and top-level `Tag` declarations pass through. Sibling of `Lint.Rule.Naming.Tag` per [API-NAME-010]. Scope detail: rationale archive §[API-NAME-010a]. [VERIFICATION: AST Lint.Rule.Naming.NestedTag]

**Cross-references**: [API-NAME-001] Nest.Name, [API-NAME-001a] Single-Type-No-Namespace (the file-scope phantom-tag pattern that IS endorsed), [API-NAME-010] No `*Tag` Suffix, [IMPL-INTENT]

---

### [API-NAME-010b] Maximal Suppression on Phantom Parameters

**Statement**: A generic type parameter that is *phantom* — never stored as a value and never flowing through any operation; a pure compile-time discriminator — MUST be bound `~Copyable & ~Escapable`, whether it is **bare** today (`<Tag>`, no suppression → both Copyable and Escapable required) or partially suppressed (`<Tag: ~Copyable>`, which still requires Escapable). A non-suppressed marker-protocol requirement on a phantom is forbidden as vacuous over-constraint: by Reynolds parametricity the implementation witnesses no capability of a phantom, so the requirement shrinks the admissible domain while enabling nothing.

**Scope**: Applies uniformly to (a) the `Tagged` / `Index` / `Property` infrastructure (the `Tag` of `Tagged`/`Property`, the `Element` of `Index`) — declarations, `extension Tagged where … Tag: ~Copyable` operation/conformance sites, and free `func`/`init`/`subscript` op-sites that use the param only as a `Tagged`/`Index`/`Property` discriminator — AND (b) **domain-type declarations** whose phantom is a discriminator: `Graph.Sequential<Tag, Payload>` / `Graph.Node<Tag>` (node-identity `Tag`), `Identity.ID<Domain, RawValue>` (`Domain`). A per-domain capability-marker protocol's phantom `associatedtype` (e.g. `Ordinal.Protocol.Domain`) widens the same way when a recursive `Tagged` conformance forces it (composes with [API-NAME-001c]).

**Correct**:
```swift
public typealias Index<Element: ~Copyable & ~Escapable> = Tagged<Element, Ordinal>
public struct Property<Tag: ~Copyable & ~Escapable, Base: ~Copyable>: ~Copyable { var _base: Base }
extension Tagged where Underlying == Ordinal, Tag: ~Copyable & ~Escapable { /* … */ }
public struct Sequential<Tag: ~Copyable & ~Escapable, Payload> { let storage: Tagged<Tag, Array<Payload>> }
```

**Incorrect**:
```swift
public typealias Index<Element: ~Copyable> = Tagged<Element, Ordinal>   // ❌ still requires Escapable
public struct Property<Tag, Base: ~Copyable>: ~Copyable { /* … */ }     // ❌ bare Tag requires both
```

**Stored-value boundary (the rule does NOT apply)**: a *stored* value parameter — `Queue<Element>`, `Array<Element>`, `Graph.Sequential`'s `Payload`, an `Adjacent: Sequence` type, the `Underlying`/`Base`/`RawValue`/`Pointee`/`Word`/`Scalar` of a wrapper — is governed by the container's value-semantics needs, NOT this rule. Relaxing a stored param to `~Escapable` is a *breaking* error. Discriminator: *does any value of the parameter type get stored or flow through an operation (by-value param/return, `[P]`, `Container<P>`, `P?`, `consuming`/`borrowing`/`inout P`)?* No → phantom (this rule); Yes → stored (out of scope).

**Companion edits the relax forces** (surfaced during execution):
- **Conditional conformances** on a relaxed type must restate the suppression: `extension Property: Copyable where Tag: ~Copyable & ~Escapable, Base: Copyable {}` — a bare `extension … where Base: Copyable` no longer infers `Tag`'s bound and errors with *"must explicitly state whether 'Tag' is required to conform to 'Escapable'"*.
- A phantom **associatedtype** carrying the domain (`associatedtype Domain: ~Copyable`) must widen to `~Copyable & ~Escapable` for `Tagged<~EscapableTag, …>` to satisfy the conformance.

**Toolchain caveat — genuinely-Escapable-required sites are NOT phantom**: a `#if swift(<6.4)` backport conformance refining a stdlib protocol that is not yet `~Escapable` on that toolchain — e.g. `extension Tagged: Hash.\`Protocol\` where Tag: ~Copyable, …` where `Hash.\`Protocol\`: Swift.Hashable` (Swift.Hashable requires Escapable pre-SE-0499) — genuinely requires an Escapable tag and MUST stay `~Copyable`. The Escapable requirement is load-bearing, not vacuous; the conformance is excluded on 6.4+ where SE-0499 makes it automatic.

**Non-breaking**: widening `~Copyable` (or bare) → `~Copyable & ~Escapable` strictly enlarges the admissible tag domain; every previously-valid instantiation stays valid (no site keys on a phantom's Copyable/Escapable-ness). Surfacing a missed phantom site later is a *completeness* fix, not a *safety* fix.

**Lint enforcement**: shipped, UNBUNDLED (fires nowhere; Phase 7 deferred — see Audits/PROMOTE-API-NAME-010b-2026-06-01.md) — flags a `typealias`/`struct`/`enum`/`func` generic param used only in `Tagged<P,…>`/`Property<P,…>`/`Index<P>` positions (never in a stored-property/by-value type) whose bound lacks `& ~Escapable`. Will promote to GATING (bundled at `.warning`, then `.error`) after the ecosystem sweep is green.

**Cross-references**: [API-NAME-010] No `*Tag` Suffix, [API-NAME-010a] No Nested `.Tag` Sub-Name, [API-NAME-001c] Per-Domain Capability-Marker Protocol, [IDX-001] Index as Tagged Ordinal, [MEM-LIFE-001], [IMPL-INTENT]

---

### [API-NAME-011] `Options` Not `Flags` for OptionSet Types

**Statement**: OptionSet types and their semantic models MUST use `.Options` suffix, not `.Flags`; types mirroring a specification's exact terminology per [API-NAME-003] MAY retain `.Flags` if that is the spec's literal term.

**Correct**:
```swift
Kernel.File.Rename.Options
Kernel.Socket.Message.Options
Kernel.IO.Uring.Setup.Options
```

**Incorrect**:
```swift
Kernel.File.Rename.Flags         // ❌ C-speak
Kernel.Socket.Message.Flags      // ❌
```

**Lint enforcement**: SwiftLint custom rule `options_not_flags` catches `struct *Flags` / `enum *Flags` declarations (spec-mirroring exception opts out via `// swiftlint:disable:next options_not_flags  // reason: spec literal`); AST counterpart `Lint.Rule.Naming.Options` flags `Flags`-suffixed structs whose inheritance clause names `OptionSet`. Scope detail: rationale archive §[API-NAME-011]. [VERIFICATION: SwiftLint options_not_flags, AST Lint.Rule.Naming.Options]

**Cross-references**: [API-NAME-002], [API-NAME-003]

---

### [API-NAME-012] No `impl` / `obj` / `inst` Local-Binding Abbreviations

**Statement**: Local bindings for concrete types MUST use the type's own name (or a descriptive domain word). The abbreviations `impl`, `obj`, `inst`, `instance` are FORBIDDEN.

**Correct**:
```swift
let actor = IO.Blocking.Actor(executor: executor)
let reader = Channel.Reader(...)
let primary = Pool.acquire()
```

**Incorrect**:
```swift
let impl = IO.Blocking.Actor(executor: executor)   // ❌ implementation-speak
let obj = Pool.acquire()                            // ❌ generic
let instance = Channel.Reader(...)                  // ❌ pure mechanism
```

**Lint enforcement**: SwiftLint custom rule `no_impl_obj_inst_bindings` catches `let|var (impl|obj|inst|instance) =`; AST counterpart `Lint.Rule.Naming.Impl` flags bindings named `impl` or `_impl`. Scope detail: rationale archive §[API-NAME-012]. [VERIFICATION: SwiftLint no_impl_obj_inst_bindings, AST Lint.Rule.Naming.Impl]

**Cross-references**: [API-NAME-001], [API-NAME-002]

---

### [API-NAME-013] Drop Redundant Prefix When Namespace Supplies Context

**Statement**: When a property is named `<noun1><Noun2>` (e.g., `packageRoot`, `packageName`) and lives in a typed namespace where `<noun2>` alone disambiguates within that namespace, the redundant `<noun1>` prefix MUST be dropped. The containing type IS the missing context. This is a strict reading of [API-NAME-002] — the "domain phrase reads naturally" defense is NOT an [API-NAME-002] carve-out (that exception is reserved for spec-mirroring identifiers per [API-NAME-003]).

**Correct**:
```swift
extension Manifest.Configuration {
    var root: Path           // package is implicit — Configuration's domain
    var binding: Identifier  // 'value' carries no domain meaning; binding is the Swift binding name
}

extension Manifest.Dependency {
    var name: String   // a Dependency IS a package
    var path: Path     // siblings: name, product, imports
}
```

**Incorrect**:
```swift
extension Manifest.Configuration {
    var packageRoot: Path     // ❌ "package" redundant inside Configuration
    var valueName: Identifier // ❌ "value" carries no domain meaning
}

extension Manifest.Dependency {
    var packageName: String   // ❌ "package" redundant inside Dependency
}
```

**Lint enforcement**: `Lint.Rule.Naming.RedundantPrefix` flags nested type declarations whose name begins with the enclosing namespace's name followed by an uppercase-led suffix (for extensions on member types, the LAST component is the enclosing name); top-level decls and exact-match nested decls are exempt. The property-naming variant (e.g., `Manifest.Configuration.packageRoot` → `root`) is currently human-enforced — only the type-prefix variant is mechanized. Scope detail: rationale archive §[API-NAME-013]. [VERIFICATION: AST Lint.Rule.Naming.RedundantPrefix]

**Cross-references**: [API-NAME-002], [API-NAME-003], [API-NAME-008]

---

### [API-NAME-014] Module Disambiguation Over Shadow-Avoidance Renames

**Statement**: When a nested type name would shadow a Swift stdlib type (e.g., `Base62.String` shadows `Swift.String`), the domain-correct name MUST be retained and the call site MUST disambiguate via module-qualification (`Base62_Primitives.String`). Renaming the type to dodge the shadow (e.g., `Text` instead of `String`) is FORBIDDEN.

**Correct**:
```swift
// Type definition
extension Base62 {
    public struct String { ... }  // Base62.String — domain-correct
}

// Call site with ambiguity
let encoded: Base62_Primitives.String = ...
let plain: Swift.String = "..."
```

**Incorrect**:
```swift
extension Base62 {
    public struct Text { ... }  // ❌ rename to dodge stdlib String shadow
}
```

**Cross-references**: [API-NAME-001], [API-NAME-003]

---

### [API-IMPL-016] Typealiases Allow Nested Type Extensions

**Statement**: Extensions on typealiased types CAN add nested types. A typealias `Kernel.Time = Kernel.Instant` does NOT block `Kernel.Time.Specification` — `extension Kernel.Time { struct Specification {} }` resolves through the typealias to `extension Kernel.Instant { struct Specification {} }`.

**Correct mental model**:
```swift
public typealias Time = Instant  // in Kernel namespace

extension Kernel.Time {
    public struct Specification { ... }  // ✓ resolves to extension Kernel.Instant
}

let s: Kernel.Time.Specification = ...  // ✓ works
```

**Common false claim** (do not propose alternative naming or defer relocation on this basis):
> "We can't nest under Kernel.Time because it's a typealias."

**How to apply**: Before claiming a namespace is "blocked" by a typealias, write the extension and verify it compiles. Swift's extension mechanism resolves through typealiases — the compiler check is the authoritative answer.

**Cross-references**: [API-NAME-001], [API-NAME-004], [API-NAME-004a]

---

### [API-IMPL-017] Preserve Labeled Call-Site Syntax When Migrating Protocols to Witness Structs

**Statement**: When converting a protocol to a witness struct with stored closures, the call-site syntax regresses (`context.set(attribute: key, value)` becomes `context.setAttribute(key, value)`) because stored closures don't carry argument labels. The migration MUST add `@inlinable` convenience methods on the witness struct that forward to the stored closures with proper labels. Stored closures are kept (for factory/interpret use) but the labeled API is provided on top.

**Correct**:
```swift
extension Rendering.Context {
    @inlinable public func set(attribute name: String, _ value: String?) { setAttribute(name, value) }
    @inlinable public func write(raw bytes: [UInt8]) { writeRaw(bytes) }
    @inlinable public func add(class name: String) { addClass(name) }
}
```

**Why**: Labeled syntax is more readable at call sites and was deliberately chosen during the protocol-era API design; losing labels on a witness migration is a regression even when the functionality is identical. Composes with `[API-NAME-002]` (no compound identifiers) — `setAttribute` is a compound identifier; `set(attribute:)` is the correct shape.

**How to apply**: For every stored closure on a witness struct, add a labeled convenience method. The convenience methods are `@inlinable` so the indirection is optimized away.

**Cross-references**: [API-NAME-002], [API-IMPL-013]

---

## Cross-References

See also:
- **implementation** skill for [IMPL-*] expression style, typed arithmetic, Property.View patterns
- **memory-safety** skill for [MEM-COPY-006] ~Copyable type organization exceptions
