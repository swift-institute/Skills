---
name: modularization
description: |
  Target decomposition, import precision (umbrella vs variant), cross-package integration (extract vs trait-gate).
  Apply when organizing SwiftPM targets, auditing structure, or choosing which module to import from a multi-product package.

layer: implementation

requires:
  - swift-institute
  - code-surface
  - implementation

applies_to:
  - swift
  - swift6
  - primitives
# Amendment/changelog history: Research/modularization-skill-rationale.md §Changelog-Provenance (and git history of this file).
---

# Modularization

> How modules relate to each other within a package.

The **implementation** skill governs how code reads within a module; the **modularization** skill governs how modules compose within a package.

This skill is organized as a navigation hub. The foundational principle below governs the whole skill and is always in context; the detailed rule bodies live in sibling files, which Claude loads on demand when a topic is active.

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/modularization-skill-rationale.md` (referenced below as the rationale archive).

---

## Foundational Principle

### [MOD-DOMAIN] Factor the Law, Not the Module

**Statement**: A new target MUST represent a coherent semantic domain. Targets MUST NOT be created for shared code, convenience, or "helpers". The question at every decomposition is: "Is this a concept, or just code?"

This is the governing principle. Every MOD-* rule is a corollary.

**Verification boundary**: deterministic validators may prove exact structural
predicates over target graphs, files, imports, or declarations. They do not by
themselves prove that a target is a coherent semantic domain, sits at the right
layer, has sufficient cohesion, or should be split. Those judgments remain
hybrid or human. A partial detector MUST name the structural slice it covers and
MUST NOT report whole-rule conformance.

**Rationale**: Parnas (1972) proved that the information-hiding decomposition — where each module hides one design decision — produces fundamentally better properties than processing-step partitioning. The ecosystem's Primitives Layering.md formalizes this as "Factor the Law, Not the Module."

**Cross-references**: [API-LAYER-001], Primitives Layering.md § "Factor the Law, Not the Module"

---

## Files

| Topic | File | Rules |
|-------|------|-------|
| Layer-Placement Calculus | `layer-placement.md` | [MOD-PLACE], [MOD-PLACE-DECOMPOSE], [MOD-PLACE-FLOOR], [MOD-PLACE-AUDIT], [MOD-PLACE-EXPRESS] |
| Target Structure, Naming, Dependencies & Test Support | `targets.md` | [MOD-001]–[MOD-013], [MOD-017], [MOD-021], [MOD-024], [MOD-031] |
| Consumer Imports & Cross-Module Visibility | `imports.md` | [MOD-015], [MOD-015a], [MOD-023], [MOD-027], [MOD-028], [MOD-036]–[MOD-038], [MOD-040] |
| @_spi Visibility Escape Hatch | `spi.md` | [MOD-016], [MOD-039] |
| Cross-Package Integration, Extraction & Acyclicity | `cross-package.md` | [MOD-014], [MOD-025], [MOD-032]–[MOD-034] |
| Package-Level Decomposition, Rent & Accepted Deviations | `package-decomposition.md` | [MOD-020], [MOD-022], [MOD-026], [MOD-029], [MOD-030], [MOD-035], [MOD-RENT], [MOD-041], [MOD-EXCEPT-001], [MOD-EXCEPT-002] |

The foundational axiom [MOD-DOMAIN] above is inline in this hub; every other rule lives in the companion named in its Rule Index row below.

---

## Rule Index

One-line hooks for every rule. Load the linked file when the topic is active.

### Layer-Placement Calculus (`layer-placement.md`)

| ID | Hook |
|----|------|
| [MOD-PLACE] | Lowest-correct-layer placement axiom — semantic identity + decision procedure over the Memory ⊏ Storage ⊏ Buffer ⊏ ADT basis |
| [MOD-PLACE-DECOMPOSE] | Decompose a multi-axis bundle before placing; no monolithic placement of a ≥2-axis name |
| [MOD-PLACE-FLOOR] | The honest hard floor — never push below the layer that can enforce the invariant; name the floor |
| [MOD-PLACE-AUDIT] | Two-failure-mode lens — check both too-high and too-low; the wart triad |
| [MOD-PLACE-EXPRESS] | Express placement by distinct leaf types + composition + constrained extensions, not an ad-hoc protocol |

### Target Structure, Naming, Dependencies & Test Support (`targets.md`)

| ID | Hook |
|----|------|
| [MOD-001] | Core Layer — REMOVED 2026-05-24 (merged into singular `{Domain} Primitive`); migration trigger preserved |
| [MOD-002] | External dependency centralization — AMENDED (moves to the sub-namespace level under [MOD-031]) |
| [MOD-003] | Variant decomposition along a single axis; variants independent (no inter-variant deps) |
| [MOD-004] | Constraint isolation — no Copyable-imposing conformances in the ~Copyable core |
| [MOD-005] | Umbrella re-export target (`exports.swift` only); dual-role base plural; aggregation discriminator |
| [MOD-021] | Doc-fidelity of the `@_exported` umbrella — docs stripped; `docc convert --merge` mitigation |
| [MOD-017] | Singular `{Domain} Primitive` root target — namespace + foundational types; zero-external-dep invariant |
| [MOD-031] | Per-sub-namespace decomposition default (one target per sub-namespace) |
| [MOD-012] | Target naming convention (per package shape + layer adaptation) |
| [MOD-013] | Semantic group markers (`// MARK: -`) in Package.swift (5+ targets) |
| [MOD-006] | Dependency minimization — declare exactly the dependencies a target uses |
| [MOD-007] | Dependency graph shape — wide, shallow DAG; edge-depth ≤ 3 |
| [MOD-008] | Split decision criteria — when a concern earns its own target |
| [MOD-009] | Inline variant satellite — inline depends on heap; reverse direction forbidden |
| [MOD-010] | Standard library integration module isolation |
| [MOD-011] | Test Support product (`{Domain} Primitives Test Support`) |
| [MOD-024] | Test Support spine discipline — TS deps ⊆ {TS-of-deps, own product} |

### Consumer Imports & Cross-Module Visibility (`imports.md`)

| ID | Hook |
|----|------|
| [MOD-015] | Consumer import precision — primary (import variants) vs supplementary (import umbrella) |
| [MOD-015a] | Narrow-imports exception for shadow disambiguation — import a module that declares the namespace |
| [MOD-023] | `#externalMacro` module-name normalization — spaces → underscores, not collapsed |
| [MOD-027] | `internal import` incompatible with `@inlinable` bodies; use `@_disfavoredOverload` for L2/L3 collisions |
| [MOD-028] | Cross-module nested extension member resolution workaround (module-local namespace enum) |
| [MOD-036] | Cross-package `@inlinable` surface must be genuinely inlinable — `@usableFromInline internal`, not `package` |
| [MOD-037] | Cross-variant `package` symbols must not flip to `internal` during a type/ops consolidation |
| [MOD-038] | Every source import is a declared target dependency — no riding transitive build accidents |
| [MOD-040] | Prefer explicit imports over `@_exported` convenience re-exports — `@_exported` reserved for deliberate umbrella products, never convenience leakage (SHOULD; exceptions analysis pending) |

### @_spi Visibility Escape Hatch (`spi.md`)

| ID | Hook |
|----|------|
| [MOD-016] | `@_spi` per-file opt-in — each file declares its own SPI import; boundary is greppable |
| [MOD-039] | Minimize `@_spi` — last-resort escape hatch; exhaust four alternatives; existing sites are tracked debt |

### Cross-Package Integration, Extraction & Acyclicity (`cross-package.md`)

| ID | Hook |
|----|------|
| [MOD-014] | Cross-package optional integration — extract by default, trait-gate as structural fallback |
| [MOD-025] | Dep-cleanup-pass audit procedure (uniquely-providing test; five required behaviors) |
| [MOD-032] | No package-level cycles, even SwiftPM-tolerated (target-acyclic / package-cyclic forbidden) |
| [MOD-033] | Pre-extraction owner-internal fan-in check (source imports + umbrella re-export) |
| [MOD-034] | Pre-extraction identity-defining-surface check — foundational vs incidental role |

### Package-Level Decomposition, Rent & Accepted Deviations (`package-decomposition.md`)

| ID | Hook |
|----|------|
| [MOD-020] | Dependency-delta check before proposing a new primitive package (prefer target-split) |
| [MOD-022] | Mechanical coupling inventory before scope estimation |
| [MOD-026] | Fine-grained per-type modularization default in multi-type L3 packages |
| [MOD-029] | Split decisions weight the UPSTREAM dep tree, not DOWNSTREAM consumer count |
| [MOD-030] | Combinator/leaf-type micro modules are deliberate; module count is not a quality signal |
| [MOD-035] | Scope statement required for L1 primitives packages |
| [MOD-RENT] | Two-criteria primitive-package rent test (capability + theoretical content) |
| [MOD-041] | Package cohesion — one concern per package; coincidental cohesion (Constantine-Yourdon grab-bag) forbidden; extension-aggregator (stdlib/Foundation-extensions) exception; decompose first-principles, not on demand |
| [MOD-EXCEPT-001] | Platform packages exempt from MOD-001 / MOD-005 / MOD-011 |
| [MOD-EXCEPT-002] | Placeholder/stub packages exempt from MOD-006 / MOD-011 |

---

## Cross-References

- **implementation** skill for [IMPL-*], [API-LAYER-*], [PATTERN-*] — how code reads within a module (this skill governs how modules compose within a package)
- **code-surface** skill for [API-NAME-001], [API-ERR-001] — namespace/naming and typed throws (referenced by [MOD-039]'s public-API-first alternative)
- **ecosystem-data-structures** skill for [DS-001], [DS-004], [DS-025], [DS-028], [DS-029] — the four-layer data-structure model the [MOD-PLACE-*] calculus places onto
- **platform** skill for [PLAT-ARCH-005a], [PLAT-ARCH-019] — the platform-stack application of [MOD-039] (typed-only surfaces, Path-X residual SPI debt)
- **swift-package** skill for [PKG-NAME-016], [PKG-DEP-003], [PKG-DEP-004] — integration-package naming and package-level dependency bounds
- Research: `swift-institute/Research/modularization-skill-rationale.md` (rationale archive — evicted provenance, extended worked examples, dated changelog)
- Research: `swift-institute/Research/decomposition-layer-placement-calculus.md` and `decomposition-layer-placement-package-map.md` (authority for the [MOD-PLACE-*] family)
