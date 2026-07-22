# Modularization — Target Structure, Naming, Dependencies & Test Support

Companion of the **modularization** skill (navigation hub: `SKILL.md`). Load when structuring SwiftPM targets within a package: the root / umbrella / sub-namespace shape, target naming, the intra-package dependency graph, split decisions, and stdlib-integration or test-support targets. This file reads independently: it collects the intra-package target-structure, naming, dependency, and test-support rules.

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/modularization-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MOD-001], [MOD-002], [MOD-003], [MOD-004], [MOD-005], [MOD-021], [MOD-017], [MOD-031], [MOD-012], [MOD-013], [MOD-006], [MOD-007], [MOD-008], [MOD-009], [MOD-010], [MOD-011], [MOD-024]

---

## Structural Requirements

### [MOD-001] Core Layer — REMOVED 2026-05-24 (merged into singular `{Domain} Primitive` per [MOD-031]/[MOD-017])

**Status**: **REMOVED** as of 2026-05-24. The `{Domain} Primitives Core` target no longer exists in the convention. Core's namespace-enum + foundational-declaration role is merged with the former `{Domain} Namespace` role into a single SINGULAR published library target — `{Domain} Primitive` — per `[MOD-017]` and `[MOD-031]`. Core's dependency-funnel role was already dissolved by `[MOD-031]` (external deps are declared per sub-namespace/variant target per `[MOD-002]` amended). There is no longer a `{Domain} Primitives Core` target and no separate `{Domain} Namespace` target.

**Migration trigger (preserved)**: existing packages still carrying a `{Domain} Primitives Core` (and/or a separate `{Domain} Namespace`) target are NOT immediately non-conformant — they remain valid under the legacy shape until the package next undergoes publication-readiness (`/release-readiness`), at which point Core + Namespace collapse into the singular `{Domain} Primitive` per `[MOD-017]`/`[MOD-031]`. No forced cohort migration (principal policy, sequence-primitives 2026-05-21).

**Original statement** (preserved for migration reference only — NOT a current requirement): Every multi-product package MUST have a `{Domain} Primitives Core` target containing namespace enums, foundational protocols, and minimal type definitions. Core was an **internal-only** target (not published as a product), re-exported external dependencies via `@_exported public import` in `exports.swift`, was depended on by every other target (directly or transitively), held the namespace enum and foundational protocol(s), and acted as the package's single dependency funnel.

**Lint enforcement**: `validate-package-structure.py`'s "Core target presence" check was reconciled 2026-06-04 (`ce82e07`) — it now checks for the singular `{Domain} Primitive` root target, treating a `{Domain} Primitives Core` / `{Domain} Namespace` target as a migration-pending signal, not a requirement; see `[MOD-031]`'s lint-enforcement-candidate note.

**Cross-references**: [MOD-002] (external-dep centralization — amended), [MOD-005] (umbrella), [MOD-017] (the merged `{Domain} Primitive` root target), [MOD-031] (the per-sub-namespace shape that replaced Core)

---

### [MOD-002] External Dependency Centralization — AMENDED 2026-05-21

**Statement (legacy, [MOD-001]-conformant packages)**: Only Core SHOULD depend on external packages. Variant targets SHOULD reach external types through Core's re-exports.

**Statement ([MOD-031]-conformant packages, new L1 default)**: Centralization moves to the sub-namespace level. Each sub-namespace target declares the external dependencies its own source files actually import (per `MemberImportVisibility`). The umbrella re-exports all sub-namespace targets, so downstream consumers see the union via a single import. There is no package-level "funnel" target in the [MOD-031] shape — the funnel becomes per-sub-namespace.

**Rationale for the amendment**: Under [MOD-031] the [MOD-001] centralization property is preserved at the sub-namespace level — an external-package upgrade affects only the sub-namespace targets that actually use it. Full text: rationale archive §[MOD-002].

**Legacy original statement** (unamended, applies to [MOD-001]-conformant packages until migration): Only Core SHOULD depend on external packages. Variant targets SHOULD reach external types through Core's re-exports.

**Exception**: Variant targets MAY directly depend on external packages when they need protocol conformances that cannot be provided transitively (e.g., buffer variants depending on Sequence/Collection Primitives for conformance).

**Correct**:
```swift
// Core re-exports externals
// exports.swift in Parser Primitives Core
@_exported public import Input_Primitives
@_exported public import Array_Primitives

// Variant depends only on Core
.target(name: "Parser Map Primitives",
    dependencies: ["Parser Primitives Core"]),
```

**Incorrect**:
```swift
// ❌ Every variant duplicates external dependency declarations
.target(name: "Parser Map Primitives",
    dependencies: [
        "Parser Primitives Core",
        .product(name: "Input Primitives", package: "swift-input-primitives"),  // ❌
    ]),
```

**Rationale**: Centralizing external dependencies means upgrading an external package affects one `dependencies:` declaration, not N. Full text: rationale archive §[MOD-002].

**Cross-references**: [MOD-001]

---

### [MOD-003] Variant Decomposition

**Statement**: Domain-specific implementations MUST be isolated into separate targets along a single decomposition axis. Variants MUST be independent of each other (no inter-variant dependencies) unless a documented delegation relationship exists.

Decomposition axis names a single conceptual dimension: strategy, operation, behavior, representation.

**Correct** (buffer-primitives along "storage strategy" axis):
```swift
// Each variant depends on Core + only genuine siblings
.target(name: "Buffer Ring Primitives",
    dependencies: ["Buffer Primitives Core"]),
.target(name: "Buffer Linear Primitives",
    dependencies: ["Buffer Primitives Core"]),
.target(name: "Buffer Slab Primitives",
    dependencies: ["Buffer Primitives Core"]),
```

**Incorrect**:
```swift
// ❌ Inter-variant dependency without delegation justification
.target(name: "Buffer Ring Primitives",
    dependencies: ["Buffer Primitives Core", "Buffer Linear Primitives"]),  // ❌ Ring→Linear
```

**Rationale**: Variant independence enables selective import — a consumer needing only `Buffer_Ring_Primitives` pays no compile-time cost for Linear's algorithms. Full text: rationale archive §[MOD-003].

**Cross-references**: [MOD-006], [MOD-008]

---

### [MOD-004] Constraint Isolation

**Statement**: When a package supports `Element: ~Copyable`, Core MUST NOT carry protocol conformances that impose `Copyable` constraints. Conformances to `Swift.Sequence`, `Swift.Collection`, `Collection.Protocol`, `Sequence.Protocol`, or `Sequence.Drain.Protocol` MUST be declared in variant targets, not Core.

What Core retains (with `Element: ~Copyable`):
- Type definitions
- Direct subscript access (index-based, no iteration)
- Span-based access (borrowed, no copy)
- Mutating operations (append, push, enqueue, insert, remove)
- Count, capacity, isEmpty
- Deinit

What Core excludes:
- `Swift.Sequence` / `Swift.Collection` conformances
- Custom `Sequence.Protocol` / `Collection.Protocol` conformances
- `Sequence.Drain.Protocol` conformances
- Any API whose signature requires `Element: Copyable`

**Correct** (Package.swift structure):
```swift
// Core: types with Element: ~Copyable, NO collection conformances
.target(name: "Array Primitives Core",
    dependencies: [/* external deps */]),

// Variant: adds conformances, forces Element: Copyable in scope
.target(name: "Array Dynamic Primitives",
    dependencies: [
        "Array Primitives Core",
        .product(name: "Sequence Primitives", package: "swift-sequence-primitives"),
        .product(name: "Collection Primitives", package: "swift-collection-primitives"),
    ]),
```

**Incorrect**:
```swift
// ❌ Core conforms to Collection → poisons Element: ~Copyable
.target(name: "Array Primitives Core",
    dependencies: [
        .product(name: "Collection Primitives", package: "swift-collection-primitives"),  // ❌
    ]),
// All code using Array<FileHandle> where FileHandle: ~Copyable now fails
```

**Rationale**: **Constraint isolation is type-theoretically necessary, not merely pragmatic** (SE-0427 context) — the constraint is existentially quantified within its module and only propagates when imported; this pattern is the dominant modularization driver for the entire data structure stack (storage → buffer → array/stack/queue/slab/set/dictionary). Full theoretical grounding: rationale archive §[MOD-004].

**Cross-references**: [MEM-COPY-001–006], [MOD-001], SE-0427

---

### [MOD-005] Umbrella Re-export

**Statement**: Every multi-product package MUST have an umbrella target whose sole content is `@_exported public import` statements in `exports.swift` — zero implementation code.

The umbrella product name MUST match `{Domain} Primitives`. The umbrella target MUST depend on ALL sub-targets.

**Correct**:
```swift
// exports.swift — complete file, zero implementation
@_exported public import Parser_Primitives_Core
@_exported public import Parser_Error_Primitives
@_exported public import Parser_Match_Primitives
@_exported public import Parser_Map_Primitives
// ... all remaining targets

// Package.swift
.target(name: "Parser Primitives",
    dependencies: [
        "Parser Primitives Core",
        "Parser Error Primitives",
        "Parser Match Primitives",
        "Parser Map Primitives",
        // ... all targets
    ]),
```

**Incorrect**:
```swift
// ❌ Umbrella contains implementation code
// Parser Primitives/ParserHelpers.swift
func defaultConfiguration() -> Config { ... }  // ❌ Implementation in umbrella
```

**Rationale**: The umbrella enables convenience without sacrificing granularity. The umbrella's role to consumers depends on the decomposition type — see [MOD-015].

**Type/ops-split packages — the base plural doubles as the umbrella (dual-role exception)**: In a type/ops-split discipline package (`[MOD-036]`/`[MOD-004]`: each variant split into a lean `~Copyable` TYPE module `{Domain} {Variant} Primitive` and a conformances OPS module `{Domain} {Variant} Primitives`), there is NO separate pure-umbrella target and no "Base" token. The base plural `{Domain} Primitives` serves BOTH roles at once: it is the base-conformances module AND the umbrella. Its `exports.swift` re-exports the base type singular (`{Domain} Primitive`), every variant ops plural (`{Domain} {Variant} Primitives`), and the external dependency its base conformances surface — so `import {Domain}_Primitives` surfaces the whole package (each variant ops transitively re-exports its own variant type). The "umbrella depends on ALL sub-targets" property holds directly for the variant ops + base type and transitively for the variant types.

Because it carries the base conformances, the base plural is NOT a zero-implementation `exports.swift`-only target — a deliberate exception to the umbrella-sole-content rule above (and to the `validate-package-structure.yml` "umbrella sole source is exports.swift" check, which MUST exempt the type/ops-split base plural).

**Acyclicity requirement (non-negotiable)**: the base plural can re-export the variant ops only if no variant ops module depends back on it. Variant ops MUST depend on the base/variant TYPE singular (`{Domain} Primitive` / `{Domain} {Variant} Primitive`), NEVER on the base ops plural `{Domain} Primitives`. Edge direction is `base plural → variant ops → types`; a variant ops importing the base plural creates a target-level cycle SwiftPM rejects. Naming table: `[MOD-012]`; split mechanics: `[MOD-036]`. (Verified exemplar: rationale archive §[MOD-005].)

**Aggregation discriminator — non-aggregating base plural when variants are mutually exclusive per consumer**: The dual-role aggregation above (base plural re-exports *every* variant ops) is the DEFAULT, correct when a single downstream module may use more than one variant — e.g. an end-user discipline whose callers pick among capacity variants (`Set.Ordered.{Fixed,Static,Small}`, `Buffer.Linear.{Bounded,Inline,Small}`). When the package's variants are **mutually exclusive per consumer** — no single downstream module imports more than one — the aggregating umbrella has NO consumer, and the base plural MUST NOT re-export sibling variant ops. Each variant becomes an **independent entry point**: the per-variant re-export is unchanged (`{Domain} {Variant} Primitives` re-exports its own `{Domain} {Variant} Primitive`), but the base plural `{Domain} Primitives` re-exports only the base type + its own base-variant ops. The Statement's "umbrella MUST depend on ALL sub-targets" is correspondingly relaxed for this case — the non-aggregating base plural depends only on the base type and base-variant ops.

**Discriminator test**: "Does any downstream module import two or more of this package's variants?" Yes → aggregate (default). No (each consumer selects exactly one variant) → independent entry points (non-aggregating base plural).

**Exemplar (non-aggregating)** — `swift-hash-table-primitives` (2026-05-28): rationale archive §[MOD-005].

**Distinct from `[MOD-015]`**: this discriminator decides whether the aggregating umbrella has any consumer at all (a structural `[MOD-005]` question). It is NOT the `[MOD-015]` consumer-import-precision axis, which governs whether consumers SHOULD import the umbrella vs narrow products *when an aggregating umbrella exists* — e.g. `swift-buffer-primitives` aggregates per `[MOD-005]` yet is primary-decomposition per `[MOD-015]` (callers import specific variants). A package aggregates (the default) unless it fails the discriminator test above.

**Lint enforcement**: Reusable workflow `validate-package-structure.yml` checks that the umbrella target's sole source is `exports.swift` containing only `@_exported public import` lines. Added Wave 2b 2026-05-10. (Exception: the type/ops-split base plural per the dual-role note above — it additionally carries base conformances.)

**Note on "umbrella"**: "Umbrella" in this skill is the SwiftPM product-level sense — a re-export target. Distinct from the DocC catalog umbrella ([DOC-080]) and the testing-routing umbrella skill (`testing`).

**Cross-references**: [MOD-004] (poison isolation behind the type/ops split), [MOD-012] (type/ops-split naming table), [MOD-015], [MOD-036] (split mechanics), [DOC-080]

---

### [MOD-021] Documentation-Fidelity Consequences of Multi-Target + Umbrella Shape

**Statement**: `@_exported public import` re-exports symbols from a target but STRIPS their doc comments; consumers importing only the umbrella see symbols without docs. The ecosystem mitigation is a `docc convert --merge` distribution build that combines per-target symbol graphs into a single umbrella archive. Per-symbol docs live in the declaring module's `.docc` archive; the umbrella archive is the merged consumer-facing reference.

**What this means at authoring time**:

1. Inline `///` comments MUST live in the declaring module — writing them in the umbrella has no effect (the umbrella has no symbols of its own to document).
2. Umbrella `.docc` catalog carries landing articles and cross-module overviews, not per-symbol docs.
3. Distribution builds MUST run the merge step; local preview builds can skip it for a single-module view but produce a degraded umbrella view.

**Rationale**: The doc-comment-strip is a consequence of the symbol-graph emitter treating re-exports as references, not declarations; the rule surfaces a consequence of `@_exported` that authors routinely miss, leading to empty umbrella-archive symbol pages. Full text + provenance: rationale archive §[MOD-021].

**Cross-references**: `swift-institute/Research/docc-multi-target-documentation-aggregation.md`, [DOC-019a]

---

## Root Target and Naming

### [MOD-017] `{Domain} Primitive` — Namespace + Foundational-Types Root Target

**Revision**: REVISED 2026-05-24. The former separate `{Domain} Namespace` target is folded into the singular `{Domain} Primitive` target, which also absorbs the former `{Domain} Primitives Core` namespace + foundational-declaration role (`[MOD-001]`, now REMOVED). One published library target now owns the root namespace AND the package's foundational, zero-external-dependency declarations.

**Statement**: Every multi-product L1 primitives package MUST publish a SINGULAR `{Domain} Primitive` target (note: singular "Primitive", one letter apart from the plural `{Domain} Primitives` umbrella). It owns the root namespace declaration (`public enum {Domain} {}` / `public struct {Domain}`) plus the package's foundational type/protocol declarations, and is published as a library product.

**Dependency invariant — hard, non-negotiable (preserved from the former Namespace target)**: `{Domain} Primitive` MUST declare zero external-package dependencies — zero primitives, zero standards/foundations packages, zero stdlib-extension modules, zero test-support modules. (It MAY depend on another package's `{Domain} Primitive`-class root in the rare cross-namespace-root case.) The invariant is load-bearing: it is what makes `{Domain} Primitive` universally cheap to import, and what the transitive-weight payoff for downstream extenders depends on. The invariant holds at every layer (L1/L2/L3); the singular `{Domain} Primitive` *naming* is verified at L1 (the L2/L3 root-target name is determined per-package at publication-readiness and is not yet codified by a migrated example).

**Content policy — case-by-case, conservative default**: The root namespace declaration plus any foundational declarations that compile against *only stdlib* are the content of `{Domain} Primitive`. A foundational type or protocol whose signature requires an external dependency MUST NOT live in `{Domain} Primitive` — it lives in a sub-namespace/variant target per `[MOD-031]`, which declares that external dep per `[MOD-002]` (amended). Verified example: `Sequence.Protocol` (referencing `Index`/`Cardinal` types) lives in `Sequence Protocol Primitives`, not in `Sequence Primitive`. Keep `{Domain} Primitive` exactly as light as the zero-dep invariant requires; extracting an external-dep-bearing declaration to a sub-namespace target is cheap and preserves the invariant.

**Target properties**:
- Published as a **library product**.
- Source directory: `Sources/{Domain} Primitive/`.
- Conventionally one `{Domain}.swift` file (the namespace) plus `exports.swift`; additional files are permitted when they satisfy the zero-dep content policy.

**Consumer import rule**:
- Import `{Domain}_Primitive` when the only use is `extension {Domain} { ... }` adding a disjoint sub-namespace or a typealias to another module's namespace.
- Import a specific sub-namespace/variant module (per `[MOD-015]`) when any type declared outside the root is referenced.

**Correct** (Package.swift — verified shape, `swift-buffer-primitives` 2026-05-24):
```swift
products: [
    .library(name: "Buffer Primitive", targets: ["Buffer Primitive"]),      // SINGULAR: namespace + foundational types
    .library(name: "Buffer Growth Primitives", targets: ["Buffer Growth Primitives"]),
    .library(name: "Buffer Primitives", targets: ["Buffer Primitives"]),    // PLURAL: umbrella
],
targets: [
    .target(name: "Buffer Primitive", dependencies: []),                    // zero external deps — the invariant
    .target(name: "Buffer Growth Primitives",
        dependencies: [
            "Buffer Primitive",
            .product(name: "Index Primitives", package: "swift-index-primitives"),
            // ... sub-namespace target declares its own externals per [MOD-002] amended
        ]),
]
```

```swift
// Sources/Buffer Primitive/Buffer.swift — namespace + foundational declaration, zero external deps
public enum Buffer<Element: ~Copyable> {}
```

**Incorrect**:
```swift
// ❌ Invariant violation — {Domain} Primitive declares an external-package dependency
.target(name: "Buffer Primitive",
    dependencies: [.product(name: "Index Primitives", package: "swift-index-primitives")])

// ❌ Invariant violation — a {Domain} Primitive source file imports an external module
// Sources/Buffer Primitive/Buffer.Protocol.swift
public import Index_Primitives                       // ❌ external dep — move this declaration to a sub-namespace target

// ❌ Stale shape — a separate {Domain} Namespace and/or {Domain} Primitives Core target
.library(name: "Buffer Namespace", targets: ["Buffer Namespace"])           // ❌ folded into Buffer Primitive
.target(name: "Buffer Primitives Core", dependencies: [/* ... */])          // ❌ removed per [MOD-001]
```

**Rationale**: Extenders whose sole need is to add a sub-namespace import `{Domain} Primitive` and acquire zero transitive external weight — but only as long as the zero-dep invariant holds; the dependency-free root is the smallest information-hiding partition, separable from the external-dep-bearing type catalog. Full text: rationale archive §[MOD-017].

**Lint enforcement**: `validate-package-structure.py` (reconciled 2026-06-04, `ce82e07`) greps `Sources/` for `^public enum {Domain}` and flags packages lacking a namespace-owning target — checking first for the singular `{Domain} Primitive` root and tolerating a legacy `{Domain} Namespace` / Core target as migration-pending.

**Cross-references**: [MOD-001] (removed — Core declaration-role merged here), [MOD-005], [MOD-012], [MOD-015], [MOD-015a], [MOD-031] (the per-sub-namespace shape that `{Domain} Primitive` roots)

---

### [MOD-031] Per-Sub-Namespace Decomposition Default

**Status**: Statement REVISED 2026-05-24 (root-target merge) and 2026-05-21 (sub-namespace suffix retention). As of 2026-05-24 the root namespace + foundational-types target is the SINGULAR `{Domain} Primitive`, merging the former `{Domain} Namespace` and `{Domain} Primitives Core` roles per `[MOD-017]` (`[MOD-001]` REMOVED). Sub-namespace targets retain the plural `Primitives` layer suffix to ensure unique primitives module names across the ecosystem (2026-05-21 correction). (Verification: rationale archive §[MOD-031].)

**Statement (revised 2026-05-24)**: For multi-product L1 primitives packages, the default decomposition is one target per sub-namespace. The root namespace AND the package's foundational (zero-external-dependency) declarations are owned by a single SINGULAR `{Domain} Primitive` target per `[MOD-017]`; there is no `{Domain} Primitives Core` target (`[MOD-001]` REMOVED) and no separate `{Domain} Namespace` target. Each sub-namespace `{Domain}.{X}` is its own target named `{Domain} {X} Primitives` — the plural `Primitives` layer suffix is RETAINED on sub-namespace targets (2026-05-21 correction; see `[MOD-012]`). Note the one-letter singular/plural distinction: the root is `{Domain} Primitive` (singular), the umbrella is `{Domain} Primitives` (plural).

**Target shape per sub-namespace**:

A `{Domain} {X} Primitives` target owns the entire sub-namespace, including:

- The `extension {Domain} { public enum {X} {} }` declaration (or `{X}.swift`-style namespace declaration)
- Any types nested under `{Domain}.{X}` (e.g., `{Domain}.{X}.Protocol`, `{Domain}.{X}.Iterator`, `{Domain}.{X}.Inout`, etc.)
- Property.Inout extensions if `{Domain}.{X}` is a phantom-tag namespace
- Extensions on `{Domain}.Protocol` that wire the sub-namespace into the protocol surface (e.g., `Sequence.Protocol+Map.swift` extending `Sequence.Protocol` with `var map: ...` lives in `Sequence Map`, the target that owns the `Sequence.Map` sub-namespace)
- The target's own `exports.swift` re-exporting its immediate deps

**Verb-extension placement (non-sub-namespace files)**: Files that extend `{Domain}.Protocol` with a verb that doesn't have a corresponding sub-namespace (e.g., `Sequence.Protocol+count` is a verb extension where `count` is not a sub-namespace) live in the most semantically-coherent existing target. Examples from the pilot:

- `Sequence.Protocol+Count.swift` → `Sequence Protocol Primitives` (count is a Protocol verb, not a sub-namespace)
- `Sequence.Protocol+collect.swift` → `Sequence Hint Primitives` (collect uses `self.hint.count`; co-locating with Hint preserves `[MOD-007]`'s max-depth-3 constraint, since the alternative `Sequence Collect Primitives → Sequence Hint Primitives → ...` chain would exceed depth 3)

**External dep declaration**: Each sub-namespace target declares the external dependencies its source files actually import per `[MOD-002]` (amended). No package-level external-dep "funnel" exists.

**Umbrella unchanged**: Per `[MOD-005]`, the umbrella target re-exports all sub-namespace targets. Consumers importing `{Domain}_Primitives` get the union; consumers needing granularity import specific sub-namespace targets per `[MOD-015]`.

**Worked example — `swift-sequence-primitives`** (the [MOD-031] pilot; shape verified 2026-05-24): full tier table in rationale archive §[MOD-031]. (The external-dep-bearing `Sequence.Protocol` declaration lives in `Sequence Protocol Primitives`, not in the zero-dep `Sequence Primitive` root, per `[MOD-017]`'s content policy.)

**Relationship to existing rules**:

| Rule | Effect under [MOD-031] |
|---|---|
| `[MOD-001]` Core Layer | REMOVED 2026-05-24 — no Core target; its namespace + foundational declaration-role is the singular `{Domain} Primitive` per `[MOD-017]` |
| `[MOD-002]` External Dep Centralization | AMENDED — centralization at sub-namespace level, not package level |
| `[MOD-005]` Umbrella Re-export | UNCHANGED — umbrella re-exports all sub-targets |
| `[MOD-006]` Dependency Minimization | UNCHANGED — each sub-namespace target declares minimal deps |
| `[MOD-007]` Dependency Graph Shape | UNCHANGED — max depth ≤ 3 still applies; achievable with per-sub-namespace decomposition |
| `[MOD-011]` Test Support Product | UNCHANGED — `{Domain} Primitives Test Support` still required |
| `[MOD-012]` Target Naming Convention | AMENDED 2026-05-24: the root is the singular `{Domain} Primitive` (was `{Domain} Namespace`); sub-namespace targets carry the plural `Primitives` suffix — `{Domain} {SubName} Primitives`; umbrella + Test Support keep the plural suffix; the singular `{Domain} Primitive` root + Standard Library Integration are the exceptions to the `{Domain} {SubName} Primitives` pattern |
| `[MOD-015]` Consumer Import Precision | UNCHANGED — primary vs supplementary decomposition test still applies; packages adopting [MOD-031] tend to be primary (consumers import specific sub-namespaces) |
| `[MOD-017]` Root Target | REVISED 2026-05-24 — the singular `{Domain} Primitive` target (merged namespace + foundational types) is the root of [MOD-031]'s decomposition |
| `[MOD-026]` Fine-Grained Per-Type at L3 | COMPLEMENTED — [MOD-031] is the L1 analog of [MOD-026] |
| `[MOD-030]` Combinator Micro Modules | GENERALIZED — [MOD-031] extends the per-type-family principle to all sub-namespaces |

**Migration policy for existing packages**: Existing packages still carrying a `{Domain} Primitives Core` and/or a separate `{Domain} Namespace` target remain valid under the legacy shape until next publication-readiness. At publication-readiness, Core + Namespace collapse into the singular `{Domain} Primitive` per `[MOD-017]`/`[MOD-031]` as part of the release-readiness pass. No forced cohort migration — each package migrates when next touched for release per the principal's stated policy (sequence-primitives 2026-05-21).

**Root-target invariant**: the singular `{Domain} Primitive` per `[MOD-017]` is the special target whose dependency invariant is "zero external packages." All other sub-namespace targets are regular variants per `[MOD-031]`'s general rule; they declare the external deps their sources import per `[MOD-002]` (amended). `{Domain} Primitive` is the structural root; the sub-namespace targets are the layer above.

**Lint enforcement candidate**: a future `validate-package-structure.py` extension could detect [MOD-031]-conformance by checking for singular `{Domain} Primitive` target presence + absence of both `{Domain} Primitives Core` and separate `{Domain} Namespace` targets + per-sub-namespace target presence. (The existing `validate-package-structure.py` Core/Namespace-presence checks were reconciled 2026-06-04 (`ce82e07`) — see the lint notes in `[MOD-001]`/`[MOD-017]`.) Not mechanized in initial landing; conformance verified via inspection.

**Cross-references**: `[MOD-001]` (removed), `[MOD-002]` (amended), `[MOD-005]`, `[MOD-007]`, `[MOD-011]`, `[MOD-012]`, `[MOD-015]`, `[MOD-017]`, `[MOD-026]`, `[MOD-030]`

---

**Enforcement**: Mechanical (existing) — `validate-package-structure.py` [MOD-017]/[MOD-012] checks cover this rule's shape (pre-check collapse, /promote-rule 2026-07-06): `Audits/PROMOTE-MOD-031-2026-07-06.md`. [VERIFICATION: WF]

### [MOD-012] Target Naming Convention

> **Placement note ([MOD-PLACE])**: a `{Variant}` token for a *location/allocation* concern (`Inline`/`Heap`/`Small`/`Arena`/`Pool`) belongs on a **Memory** target; a `Storage.Arena`/`Storage.Pool` (allocation) target name is a placement smell (the *occupancy* `Buffer.Arena` is the one sanctioned exception per the canonical inventory). Name the target for the axis the layer **owns**.

**Statement**: Multi-product target names MUST follow this scheme. The convention depends on the package shape: the current per-sub-namespace substrate shape (`[MOD-031]`, with the singular `{Domain} Primitive` root); the type/ops-split discipline shape (`[MOD-036]`/`[MOD-004]`: a singular type module + a plural ops module per variant, base plural doubling as the umbrella — see the dedicated subsection below); or the legacy Core-based shape (former `[MOD-001]`, REMOVED 2026-05-24 but valid for not-yet-migrated packages).

**[MOD-031]-conformant packages (current L1 default; root merged 2026-05-24)** — sub-namespace targets carry the plural "Primitives" layer suffix (`{Domain} {SubName} Primitives`) to ensure unique primitives module names; the singular `{Domain} Primitive` root and the SLI target are the exceptions to that pattern:

| Role | Pattern | Import Form |
|------|---------|-------------|
| Namespace + foundational types (root) | `{Domain} Primitive` (SINGULAR) | `{Domain}_Primitive` |
| Sub-namespace | `{Domain} {SubName} Primitives` | `{Domain}_{SubName}_Primitives` |
| StdLib integration | `{Domain} Primitives Standard Library Integration` | `{Domain}_Primitives_Standard_Library_Integration` |
| Umbrella | `{Domain} Primitives` | `{Domain}_Primitives` |
| Test support | `{Domain} Primitives Test Support` | `{Domain}_Primitives_Test_Support` |

**[MOD-001]-conformant packages (legacy Core-based)** — retained for packages not yet migrated to `[MOD-031]`:

| Role | Pattern | Import Form |
|------|---------|-------------|
| Core | `{Domain} Primitives Core` | `{Domain}_Primitives_Core` |
| Variant | `{Domain} {Variant} Primitives` | `{Domain}_{Variant}_Primitives` |
| Inline satellite | `{Domain} {Variant} Inline Primitives` | `{Domain}_{Variant}_Inline_Primitives` |
| Composite satellite | `{Domain} {Variant} Small Primitives` | `{Domain}_{Variant}_Small_Primitives` |
| StdLib integration | `{Domain} Primitives Standard Library Integration` | `{Domain}_Primitives_Standard_Library_Integration` |
| Umbrella | `{Domain} Primitives` | `{Domain}_Primitives` |
| Test support | `{Domain} Primitives Test Support` | `{Domain}_Primitives_Test_Support` |

**Layer adaptation**: The table above uses L1 (Primitives) naming. Higher layers drop the layer-identifying word:

| Layer | Core | Variant | Umbrella |
|-------|------|---------|----------|
| L1 Primitives | `{Domain} Primitives Core` | `{Domain} {Variant} Primitives` | `{Domain} Primitives` |
| L2 Standards | `{Domain} Core` | `{Domain} {Variant}` | `{Domain}` |
| L3 Foundations | `{Domain} Core` | `{Domain} {Variant}` | `{Domain}` |

**Example**: L1 `IO Primitives Core` → L3 `IO Core`. L1 `IO Blocking Primitives` → L3 `IO Blocking`.

**Singular-vs-plural caution — the root target**: Per [MOD-017], the namespace + foundational-types root is the SINGULAR `{Domain} Primitive` (e.g., `Buffer Primitive`, `Sequence Primitive`), one letter apart from the PLURAL `{Domain} Primitives` umbrella. The two are distinct products: the singular root carries the zero-external-dependency invariant; the plural umbrella re-exports every sub-target. Do not conflate them. (The former separate `{Domain} Namespace` target is folded into `{Domain} Primitive` as of 2026-05-24; legacy packages still carrying a `{Domain} Namespace` or `{Domain} Primitives Core` target migrate when next touched.) The singular root *naming* is verified at L1; the L2/L3 root-target name is determined per-package at publication-readiness and is not yet codified by a migrated example.

**Type/ops-split discipline packages** (e.g. `swift-buffer-linear-primitives`) — a package implementing a heavy type by splitting each variant into a lean `~Copyable` TYPE module and a conformances OPS module per `[MOD-036]`/`[MOD-004]`. Here `{Domain}` is the discipline name (e.g. "Buffer Linear") and `{Variant}` ranges over the variants (e.g. Bounded, Inline, Small); the base carries no `{Variant}` token. SINGULAR `Primitive` = type module; PLURAL `Primitives` = ops module:

| Role | Pattern | Import Form |
|------|---------|-------------|
| Base type (lean `~Copyable`, no Seq/Coll conformances per [MOD-004]) | `{Domain} Primitive` (SINGULAR) | `{Domain}_Primitive` |
| Variant type (lean `~Copyable`) | `{Domain} {Variant} Primitive` (SINGULAR) | `{Domain}_{Variant}_Primitive` |
| Variant ops (type re-export + isolated conformances) | `{Domain} {Variant} Primitives` (PLURAL) | `{Domain}_{Variant}_Primitives` |
| Base ops **+ umbrella** (base conformances + re-exports the base type and all variant ops) | `{Domain} Primitives` (PLURAL) | `{Domain}_Primitives` |
| Test support | `{Domain} Primitives Test Support` | `{Domain}_Primitives_Test_Support` |

The base plural `{Domain} Primitives` doubles as the `[MOD-005]` umbrella — there is NO separate pure-umbrella target and NO "Base" token. Acyclicity is load-bearing: variant ops MUST depend on the base/variant TYPE singular, NEVER on the base ops plural (which re-exports them); the full mechanism + the dual-role/zero-implementation exception are in `[MOD-005]`. (Verified exemplar: rationale archive §[MOD-012].)

**Distinction from the `[MOD-017]` substrate root**: in a type/ops-split discipline package the singular `{Domain} Primitive` is a *type module* and MAY carry external deps (storage, index, …); it is NOT the `[MOD-017]` zero-dependency namespace root. The `[MOD-017]` zero-dep root is a property of *substrate* packages that own a namespace (`swift-buffer-primitives`' `Buffer Primitive`, `swift-sequence-primitives`' `Sequence Primitive`). A discipline package extends an upstream-owned namespace and depends on that upstream root.

**Rationale**: The "Primitives" suffix is layer-identifying and inappropriate at higher layers where packages compose rather than provide atomic building blocks.

**Lint enforcement**: `validate-package-structure.py`'s name regex (`ROLE_RE`) was reconciled 2026-06-04 (`ce82e07`) — the `Primitives?` role token now matches the singular `{Domain} Primitive` root, and the `Core`/`Namespace` suffixes are tolerated as migration-pending rather than required. (Added Wave 2b 2026-05-10.)

**Cross-references**: [API-NAME-001], [PRIM-NAME-001], [ARCH-LAYER-001]

---

### [MOD-013] Semantic Group Markers

**Statement**: Package.swift files with 5+ targets SHOULD use `// MARK: -` comments to organize targets into semantic groups matching the decomposition axis.

**Correct**:
```swift
// MARK: - Core
.target(name: "Parser Primitives Core", ...),

// MARK: - Error & Match
.target(name: "Parser Error Primitives", ...),
.target(name: "Parser Match Primitives", ...),

// MARK: - Combinators
.target(name: "Parser Map Primitives", ...),
.target(name: "Parser FlatMap Primitives", ...),
// ...

// MARK: - Umbrella
.target(name: "Parser Primitives", ...),

// MARK: - Tests
.testTarget(name: "ParserPrimitivesTests", ...),
```

**Rationale**: Semantic grouping in Package.swift makes the decomposition axis legible to maintainers. The groups correspond to the variant decomposition axis.

**Cross-references**: [MOD-003]

---

## Dependency Requirements

### [MOD-006] Dependency Minimization

**Statement**: Each target MUST declare exactly the dependencies it needs — no convenience imports, no "pull in everything" shortcuts. A target MUST NOT depend on another target unless it uses types or protocols from that target.

**Correct**:
```swift
// Parser Optional depends only on Core (needs nothing else)
.target(name: "Parser Optional Primitives",
    dependencies: ["Parser Primitives Core"]),

// Parser Take depends on Core + 5 siblings it genuinely delegates to
.target(name: "Parser Take Primitives",
    dependencies: [
        "Parser Primitives Core",
        "Parser Error Primitives",
        "Parser Skip Primitives",
        "Parser Conditional Primitives",
        "Parser Optional Primitives",
        "Parser Always Primitives",
    ]),
```

**Incorrect**:
```swift
// ❌ Depends on umbrella instead of specific targets
.target(name: "Parser Optional Primitives",
    dependencies: ["Parser Primitives"]),  // ❌ Pulls in everything
```

**Rationale**: Minimal dependencies keep incremental compile times proportional to the change. Benchmark evidence + full text: rationale archive §[MOD-006].

For cross-package import precision (which product to import from another package), see [MOD-015].

**Cross-references**: [MOD-007], [MOD-003], [MOD-015]

---

### [MOD-007] Dependency Graph Shape

**Statement**: The intra-package dependency graph SHOULD be a wide, shallow DAG rooted at Core. Maximum depth (longest path from Core to a leaf) SHOULD NOT exceed 3.

**Depth metric (clarification)**: depth = longest-path **edges** from the root, ≤ 3 (= ≤ 4 nodes) — NOT node-count. (Root = the legacy Core target, or the singular `{Domain} Primitive` once a package migrates per [MOD-017].)

**Rationale**: Wide shallow DAGs maximize build parallelism — depth 3 with 35 targets yields ~11.7x parallelism vs ~3.5x at depth 10. Measured exemplars: rationale archive §[MOD-007].

**Lint enforcement**: Reusable workflow `validate-package-structure.yml` computes intra-package DAG longest-path edge-depth from the root via `swift package describe --type json` and flags edge-depth > 3 (node-count > 4). Added Wave 2b 2026-05-10; edge-vs-node off-by-one corrected 2026-05-24 (`swift-institute/.github` commit `904867c`).

**Cross-references**: [MOD-001], [MOD-003]

---

## Decision Guides

### [MOD-008] Split Decision Criteria

**Statement**: When deciding whether a concern gets its own target, apply these criteria.

A concern SHOULD be a separate target when any of:
1. **Different dependency set** — It needs fewer (or different) dependencies than its siblings
2. **Independent consumer value** — A downstream package would import this target alone
3. **Depended-on by siblings** — Other targets in the package need it (creating a shared core within the variant layer)
4. **Semantic independence** — It answers one specific question about the domain

A concern SHOULD NOT be a separate target when:
1. It always co-occurs with another target (no independent consumer)
2. It would create a depth > 3 chain without justification
3. The file count is 1 and no other target depends on it specifically

**Tradeoff**: Each additional target boundary requires `@inlinable` annotations for cross-target specialization. Whole Module Optimization (WMO) is bounded by target scope — code in separate targets cannot be jointly optimized without explicit `@inlinable`. Weigh this annotation burden against the modularity benefit.

Evidence table: rationale archive §[MOD-008].

**Cross-references**: [MOD-DOMAIN], Primitives Layering.md § "Semantic Coherence Test"

---

### [MOD-009] Inline Variant Satellite

> **Governed by [MOD-PLACE] (2026-06-18)**: the `Core → Heap → Inline → Small` chain encodes a *location*-axis placement that [MOD-PLACE] reassigns to **Memory** — `Heap`/`Inline`/`Small` are **Memory leaves** (`Memory.{Heap,Inline,Small}`) that Storage/Buffer/ADT **compose** (`Storage.Contiguous<Memory.X>`), not subclass via a cross-layer satellite. The dependency-direction rule below holds **only** for a genuine *intra-Memory* satellite (`Memory.Small` → `Memory.Heap`); the cross-layer location chain is superseded by composition-over-Memory-leaves. See the canonical-placement inventory + `decomposition-layer-placement-package-map.md` §A.1.

**Statement**: When a variant has both heap-allocated and inline (fixed-capacity) forms, the inline variant MUST depend on the heap variant. The reverse dependency is forbidden.

Dependency direction:
```
Core → Heap Variant → Inline Variant → Composite (Small) Variant
```

**Correct**:
```swift
.target(name: "Buffer Ring Primitives",           // heap
    dependencies: ["Buffer Primitives Core"]),
.target(name: "Buffer Ring Inline Primitives",     // inline depends on heap
    dependencies: ["Buffer Primitives Core", "Buffer Ring Primitives"]),
```

**Incorrect**:
```swift
// ❌ Heap depends on inline — reversed
.target(name: "Buffer Ring Primitives",
    dependencies: ["Buffer Primitives Core", "Buffer Ring Inline Primitives"]),  // ❌
```

**Rationale**: The inline variant reuses the heap variant's type definitions and algorithms, adding only fixed-capacity storage specialization. Reversing the direction would force the heap variant (used by most consumers) to compile inline storage code it doesn't need.

**Cross-references**: [MOD-003], [MOD-012]

---

## Integration and Test-Support Modules

### [MOD-010] Standard Library Integration Module

**Statement**: When a package extends Swift standard library types, those extensions SHOULD be isolated in a dedicated `{Domain} Primitives Standard Library Integration` target.

**Correct**:
```swift
.target(name: "Memory Primitives Standard Library Integration",
    dependencies: ["Memory Primitives Core"]),
// Contains: extensions on UnsafePointer, UnsafeBufferPointer, etc.
```

**Incorrect**:
```swift
// ❌ Stdlib extensions mixed into Core
// Memory Primitives Core/UnsafePointer+Memory.swift
extension UnsafePointer { ... }  // ❌ In Core, not isolated
```

**Rationale**: Stdlib extensions can cause implicit member resolution conflicts if imported broadly. Isolating them lets consumers who don't need stdlib interop avoid the extensions. Only present when stdlib extensions exist (not all packages have them).

**Cross-references**: [MOD-001], [MOD-012]

---

### [MOD-011] Test Support Product

**Statement**: Every multi-product package MUST publish a `{Domain} Primitives Test Support` library product containing test fixtures, convenience initializers, and re-exports.

Properties:
- Published as a library product (visible to downstream packages)
- Depends on the umbrella (full API access for test helpers)
- Depends on upstream packages' test support products
- Located at `Tests/Support/` path
- Re-exports upstream test fixtures via `@_exported public import`

**Correct**:
```swift
.library(name: "Parser Primitives Test Support",
    targets: ["Parser Primitives Test Support"]),
// ...
.target(name: "Parser Primitives Test Support",
    dependencies: [
        "Parser Primitives",                    // umbrella
        .product(name: "Input Primitives Test Support",
                 package: "swift-input-primitives"),
    ],
    path: "Tests/Support"),
```

**Rationale**: Downstream packages need test fixtures for types from upstream. Publishing test support as a product creates a parallel dependency graph for testing infrastructure.

**Lint enforcement**: Reusable workflow `validate-package-structure.yml` checks the Test Support product is published (alt-suffix variants accepted; [MOD-EXCEPT] carve-outs respected). Spine/dep validation runs via `lint-test-support-spine.yml` per [MOD-024]. Added Wave 2b 2026-05-10.

**Cross-references**: [TEST-001], [TEST-010] (target declaration counterpart), [CONV-007] (re-export chain and literal conformances), [MOD-024] (spine discipline)

---

### [MOD-024] Test Support Spine Discipline

**Statement**: A `{Domain} Primitives Test Support` target's dependencies MUST be a subset of `{Test Support modules of the package's product deps, the package's own product}`. A Test Support target MUST NOT depend on a non-TS cross-package product. Formally: TS deps ⊆ {TS-of-deps, own product}.

Corollary (strict mode): every package with at least one test target MUST publish a Test Support product. This extends [MOD-011] from "every multi-product package" to "every package with tests" — a strict-uniform variant chosen so contributors get the same answer to "where does test infrastructure go in this package?" everywhere.

**Spine-anchor algorithm**: when picking the upstream Test Support to re-export, pick the LOWEST-level Test Support module that is already in the package's direct product dependencies. The Tagged spine chains one hop deep at each link (Cardinal TS → Tagged TS, Ordinal TS → Cardinal TS, Affine TS → Ordinal TS, …); anchoring on the lowest in-scope dep makes the chain transitive without per-package over-import.

**Empty-shell template** (when the package has no fixtures of its own yet):

```swift
// MARK: - SLI Spine
@_exported public import {Domain}_Primitives
@_exported public import {Anchor}_Primitives_Test_Support
```

When a package's product deps do not reach the Tagged spine (e.g., a pure algebra-family package), drop the second `@_exported` line. The shell still re-exports its own product so the namespace stays uniform.

**Correct**:
```swift
.target(
    name: "Cardinal Primitives Test Support",
    dependencies: [
        "Cardinal Primitives",                                           // own umbrella
        .product(name: "Tagged Primitives Test Support",                 // spine anchor
                 package: "swift-tagged-primitives"),
    ],
    path: "Tests/Support"),
```

**Incorrect**:
```swift
// ❌ TS depends on a non-TS cross-package product
.target(name: "Parser Primitives Test Support", dependencies: [
    "Parser Primitives",
    .product(name: "Array Primitives", package: "swift-array-primitives"),  // ❌ pulls main product
]),

// ❌ Skipping the spine and adding Tagged TS directly when an intermediate
// TS already chains there — introduces redundant package-level deps.
```

**Rationale**: Under MemberImportVisibility (Swift 6.3+), the Tagged ExpressibleBy*Literal conformances (living in `Tagged_Primitives_Standard_Library_Integration`) are visible in test files only when an `@_exported public import` chain reaches the SLI module; anchoring each TS shell on the lowest-level TS in its product deps creates that chain without duplication. Verification history: rationale archive §[MOD-024].

**β→γ transition**: The advisory CI gate (Phase β) flips to gating (Phase γ) when the audit script reports zero violations across all in-scope org-dirs for two consecutive weeks. The soak window catches drift between bulk-rewrite landing and steady state.

**Audit**: `swift-institute/Scripts/preflight-test-support-spine.py --org {primitives|standards|foundations|iso}` reports per-target `OK | VIOLATION | MISSING` and aggregate counts. JSON output is available via `--json`.

**Spine-completion gap (FIX, not DROP)**: When a `{Domain} Primitives Test Support` target declares `.product(name: "{X} Primitives Test Support", package: "swift-{x}-primitives")` in Package.swift but `Tests/Support/exports.swift` is missing the corresponding `@_exported public import {X}_Primitives_Test_Support`, the dep is NOT a UNUSED-cleanup candidate — it's a spine-completion gap. The fix is to ADD the re-export, not drop the dep. The TS target's purpose is to extend the spine; a declared-but-not-re-exported TS dep is a half-built spine link, not a redundant declaration.

Detection heuristic: for each TS target, cross-reference its declared `* Test Support` product deps against the `@_exported public import` lines in its `Tests/Support/exports.swift`. Any declared TS-dep without a matching re-export is a gap.

Disposition rule: spine gaps are FIXED by writing the missing `@_exported public import` line into `exports.swift`. They are NEVER closed by dropping the Package.swift dep — that would silently break the spine for any downstream TS that anchors here per the spine-anchor algorithm above.

**Self-application to the pilot (mandatory verification step)**: When [MOD-024] is added to a skill via any cohort-bundled skill update, the dispatch authoring next-cohort audits MUST verify the rule applies to the pilot package itself BEFORE running it against the next cohort's packages. The pilot is the canonical demonstration; if [MOD-024] is missing on the pilot, the rule is structurally incomplete in the cohort even when satisfied by every sibling.

Worked example (the origin incident, 2026-05-08 swift-linter X1 wave): rationale archive §[MOD-024].

Procedure when [MOD-024] is added or strengthened:

1. Identify the pilot package of the active cohort.
2. Verify the pilot satisfies the rule (Test Support target present + spine `@_exported` chain reaches the lowest in-scope dep).
3. If the pilot does not satisfy, fix the pilot in the same wave OR record the gap as accept-as-known with a named follow-up dispatch and a deadline tied to a specific subsequent-cohort tag.
4. Only after step 2 or 3 is closed, propagate the rule to sibling packages.

**Cross-references**: [MOD-011] (Test Support product baseline), [MOD-025] (Dep-Cleanup-Pass Audit Procedure — exclusion rule for spine deps), [TEST-001], [TEST-010], [CONV-007] (re-export chain and literal conformances), [CI-022] (parallel structural-CI candidate — Foundation-import enforcement)
