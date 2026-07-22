---
name: primitives
description: |
  Swift Primitives layer conventions. Extends swift-institute conventions with
  Foundation-independence requirements and tier-based layering rules.
  ALWAYS apply when working in the swift-primitives repository.

layer: architecture

requires:
  - swift-institute
  - code-surface
  - memory-safety

applies_to:
  - swift
  - swift6
  - swift-primitives

---

# Swift Primitives Conventions

This skill EXTENDS the **swift-institute** skill. All swift-institute conventions apply here.
Additionally, these primitives-specific rules are MANDATORY.

---

## Foundation Independence

### [PRIM-FOUND-001] No Foundation Imports

Primitives packages MUST NOT import Foundation or use Foundation types in their CORE targets. This is absolute for every target except the single named exception below.

**Exception — `<Name> Foundation Integration` targets (principal ruling 2026-07-13)**: a dedicated, opt-in integration target whose name ends in `Foundation Integration` MAY import Foundation. This mirrors the established `<Name> Standard Library Integration` opt-in pattern (57 primitives packages declare one): the package's core stays Foundation-free; consumers who want Foundation interop opt into the integration product explicitly. Constraints that keep the exception honest:
- **No core target may depend (directly or transitively) on a Foundation Integration target** — otherwise Foundation re-enters the core closure and the exception swallows the rule. The integration target is a LEAF product.
- The exception covers the **target/module class**, not per-file waivers inside core targets — a core file that wants Foundation moves its Foundation-touching surface INTO the integration target.
- Lint: `Lint.Rule.Foundation.Import` requires a matching carve-out (flag imports everywhere EXCEPT in targets matching `* Foundation Integration`); until that amendment ships, expected findings in such targets are shield-documented per the trap-table discipline.
- **Tower-wide (principal ruling 2026-07-14)**: the same-shape exception applies at ALL layers L1/L2/L3 — the standards/foundations analogue is RULED and lives at [ARCH-LAYER-013] (swift-institute skill); this rule remains the L1 carrier.

**Lint enforcement**: `Lint.Rule.Foundation.Import` (in `swift-foundations/swift-institute-linter-rules`, target `Linter Rule Foundation`) walks `ImportDeclSyntax` nodes and flags imports whose first path component is `Foundation` or `FoundationEssentials`. Submodule imports (`Foundation.NSURL`) are also caught. Module names with `Foundation` as a non-leading component (`HTML_Foundation`) are NOT flagged. Placed at institute tier rather than primitives tier so `Bundle.institute` consumers at L2/L3 also receive the rule, enforcing the ecosystem-wide policy in [ARCH-LAYER-007]. Added 2026-05-13 via pilot `/promote-rule` invocation (3rd pilot). [VERIFICATION: AST Lint.Rule.Foundation.Import]

```swift
// CORRECT
import Time_Primitives
import Binary_Primitives

struct Event {
    let timestamp: Instant        // From Time_Primitives
    let payload: Binary.Buffer    // From Binary_Primitives
}

// INCORRECT
import Foundation  // FORBIDDEN

struct Event {
    let timestamp: Date   // Foundation.Date - FORBIDDEN
    let payload: Data     // Foundation.Data - FORBIDDEN
}
```

### [PRIM-FOUND-002] Swift Embedded Compatibility

Primitives MUST be deployable on Swift Embedded targets. Code MUST NOT depend on:
- Reflection
- Objective-C interop
- Foundation
- Runtime features unavailable in embedded contexts

### [PRIM-FOUND-003] Semantic Type Separation

Primitives MUST maintain semantic distinctions that Foundation conflates.

```swift
// CORRECT - Distinct types for distinct concepts
struct CalendarDate { ... }  // A date on a calendar
struct Instant { ... }       // A point in time

// INCORRECT - Foundation conflates these
typealias CalendarDate = Date  // Foundation.Date represents both
typealias Instant = Date
```

### [PRIM-FOUND-004] L1 String/Scalar Conversion Friction Is Intentional

**Statement**: L1 primitives packages MUST NOT add easy String/Scalar escape hatches. Specifically: do NOT add `Path.View.string: Swift.String` to `swift-path-primitives`; do NOT add `ASCII.Case.Conversion.convert(_: Unicode.Scalar, to:)` at L1. String conversion is placed at L3 deliberately to prevent reaching too easily for `Swift.String`. The friction is the point — consumers should stay in the typed primitive system.

**Why**: Easy String/Scalar escape hatches at L1 would encourage every consumer to bypass the typed infrastructure at every call site, defeating the purpose of the type system. If you're doing byte-level work, stay in byte territory.

**How to apply**: When auditing L3 code that manually bridges L1 types to String, classify as `[IMPL-INTENT]` principled absence (DEFERRED), not as an infrastructure gap (OPEN). The manual mechanism at L3 is the correct cost. Composes with `[PRIM-FOUND-001]` (no Foundation) and `[ARCH-LAYER-001]` (no upward dependencies) — together they keep L1 boundary surfaces narrow.


---

## Tier Architecture

### [PRIM-ARCH-001] Tiered DAG Structure

The primitives layer is organized as a DAG of dependency tiers. Tier assignments are COMPUTED algorithmically from `Package.swift` dependencies — the canonical, always-current listing is `swift-primitives/Documentation.docc/Computed Primitives Tiers.md` (19 tiers / 134 packages as of 2026-07); this skill deliberately carries no static tier table (a hand-maintained mirror of computed data drifts — the previous 13-tier/61-package table here was stale on both axes when retired 2026-07-06).

### [PRIM-ARCH-002] Downward Dependencies Only

Packages MUST depend only on packages at LOWER tiers.

```swift
// CORRECT - Tier 7 depending on Tier 3
// swift-binary-primitives (Tier 7) depends on:
.package(path: "../swift-collection-primitives"),  // Tier 3

// INCORRECT - Tier 3 depending on Tier 7
// swift-collection-primitives (Tier 3) CANNOT depend on:
.package(path: "../swift-binary-primitives"),  // Tier 7 - FORBIDDEN
```

**Enforcement**: Mechanical — covered by `validate-package-graph.py` ([MOD-032] acyclicity; /promote-rule 2026-07-06): tiers are COMPUTED from the dependency graph (`Documentation.docc/Computed Primitives Tiers.md`), so the downward-only ordering exists iff the graph is acyclic; cycle findings inside the primitives org cite both IDs. Discipline: `Audits/PROMOTE-MOD-032-2026-07-06.md`. [VERIFICATION: Script]

Circular dependencies are FORBIDDEN. Lateral (same-tier) dependencies are FORBIDDEN.

---

## Primitives Naming

### [PRIM-NAME-001] Primitives Suffix

All packages MUST use the `-primitives` suffix.

```
// CORRECT
swift-formatting-primitives
swift-dimension-primitives
swift-geometry-primitives

// INCORRECT
swift-formatting-core
swift-dimension-base
swift-geometry
```

**Exceptions** (principal-ruled 2026-07-06): org-scoped infrastructure whose established name is itself a deliberate convention is exempt — the cross-tier `-linter-rules` family (`swift-primitives-linter-rules`) and descriptive substrate with no conforming name that improves on it (`swift-standard-library-extensions`). Exemptions are enumerated in the validator with this ruling cited.

**Enforcement**: Mechanical — `validate-package-naming.py` (+ `validate-package-naming.yml` org sweep; /promote-rule 2026-07-06). Discipline: `Audits/PROMOTE-PRIM-NAME-001-2026-07-06.md`. [VERIFICATION: WF]

### [PRIM-NAME-003] Names Describe Mechanism, Not Origin

Names MUST describe what a primitive DOES, not where it was first needed.

```swift
// CORRECT - Mechanism names
Reference.Transfer    // Exactly-once ownership transfer
Reference.Indirect    // Heap indirection for value types
Cache.Entry          // A cached computation entry

// INCORRECT - Origin names
Kernel.Handoff       // "Handoff" references thread use case
Buffer.Shared        // "Shared" references original context
```

---

## Library Naming Convention

Library names in Package.swift use spaces, not underscores:

```swift
// In Package.swift
.library(name: "Affine Primitives", targets: ["Affine Primitives"])
.library(name: "Stack Primitives", targets: ["Stack Primitives"])
.library(name: "Binary Primitives", targets: ["Binary Primitives"])
```

Import statements use underscores:

```swift
import Affine_Primitives
import Stack_Primitives
import Binary_Primitives
```

---

## Tier 0 Packages (Zero Dependencies)

These packages have NO primitive dependencies (regenerated 2026-05-16 after the ASCII.Code structural-shape arc moved `swift-ascii-primitives` from Tier 0 to Tier 2):

```
swift-algebra-primitives
swift-base62-primitives
swift-carrier-primitives
swift-coder-primitives
swift-comparison-primitives
swift-decimal-primitives
swift-equation-primitives
swift-error-primitives
swift-hash-primitives
swift-io-primitives
swift-optic-primitives
swift-ownership-primitives
swift-position-primitives
swift-property-primitives
swift-random-primitives
swift-reference-primitives
swift-serializer-primitives
swift-slice-primitives
swift-standard-library-extensions
swift-tagged-primitives
```

> **Note (2026-05-16)**: This snapshot reflects the ASCII.Code structural-shape implementation arc — `swift-ascii-primitives` moved Tier 0 → Tier 2 by adopting `Byte.Protocol` from `swift-byte-primitives` (transitive: swift-byte-primitives → swift-carrier-primitives + swift-tagged-primitives). The package's `ASCII.Code` is the first per-domain `Byte.Protocol` conformer; future per-domain conformers (`Latin1.Byte`, `UTF8.Code_Unit`, RFC-specific byte types) will follow the same tier-shift pattern. See `swift-institute/Research/ascii-code-structural-shape.md` v1.0.0 (RECOMMENDATION, Shape (a)).
>
> **Prior note (2026-05-08)**: Witness-chain hygiene wave landed `swift-io-primitives` and `swift-optic-primitives` at Tier 0 by removing the witness-primitives dep + the Witness.Protocol marker conformances. `swift-witness-primitives` itself is Tier 1 (deps standard-library-extensions only). `swift-dependency-primitives` moved Tier 0 → Tier 2 by the inversion `Dependency.Key: Witness.Protocol` (the structural direction; see commit dependency-primitives 5a7edf3 + witness-primitives 7562fb0). `swift-state-primitives` was removed entirely (single-line empty namespace, zero workspace consumers). Earlier 2026-04-30 note about Tagged→Tier 1 has been folded back: with the Carrier dep removed elsewhere, Tagged is back at Tier 0; this list is regenerated each time, not amended.

When creating new primitives, determine the correct tier by computing:
`tier = max(tier[dep] for dep in dependencies) + 1`

---

## ~Copyable Collection Patterns

Collections supporting `~Copyable` elements follow specific patterns:

### Conditional Copyability

```swift
public struct Queue<Element: ~Copyable>: ~Copyable {
    final class Storage: ManagedBuffer<Header, Element> { }

    var _storage: Storage
    var _cachedPtr: UnsafeMutablePointer<Element>
}

extension Queue: Copyable where Element: Copyable {}
```

### Cached Pointer Pattern

Cache pointers for property access (required for ~Copyable spans):

```swift
var span: Span<Element> {
    @_lifetime(borrow self)
    borrowing get {
        Span(_unsafeStart: _cachedPtr, count: count)
    }
}
```

Update cached pointer on EVERY reallocation.

### Module Split for Sequence Conformance

`Sequence.Protocol` requires `Element: Copyable`. Split modules to support both:

```swift
// Stack Primitives Core      -> Core types (supports ~Copyable)
// Stack Primitives Sequence  -> Sequence conformances (Copyable only)
// Stack Primitives           -> Re-exports both
```

---

## Swift 6 Features

All primitives enable these Swift settings:

```swift
swiftLanguageModes: [.v6]

let settings: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableExperimentalFeature("Lifetimes"),
    .strictMemorySafety()
]
```

---

## Cross-References

Parent skill: **swift-institute** (all those rules apply here)

For detailed documentation:
- `/Users/coen/Developer/swift-primitives/Documentation.docc/Primitives Requirements.md`
- `/Users/coen/Developer/swift-primitives/Documentation.docc/Primitives Tiers.md`
- `/Users/coen/Developer/swift-primitives/Documentation.docc/Primitives Layering.md`
- `/Users/coen/Developer/swift-primitives/Documentation.docc/Reference/Collection Primitives Architecture.md`
