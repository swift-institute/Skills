# Modularization — Package-Level Decomposition, Rent & Accepted Deviations

Companion of the **modularization** skill (navigation hub: `SKILL.md`). Load when deciding whether new functionality earns a new package or a target-split, whether a micro-module count is a defect, or whether a package earns its rent; and for the accepted platform / stub deviations and audit metrics. This file reads independently: it collects the package-level decomposition and existence-decision rules, deviations, and audit metrics.

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/modularization-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MOD-020], [MOD-022], [MOD-026], [MOD-029], [MOD-030], [MOD-035], [MOD-RENT], [MOD-041], [MOD-EXCEPT-001], [MOD-EXCEPT-002]

---

### [MOD-020] Dependency-Delta Check Before New-Primitive-Package Proposal

**Statement**: When new functionality is proposed as a new primitive package, the first check is the *dependency delta* against the nearest existing primitive in the same family. If the delta is zero (the new target could live in the existing package with no new external dependencies) or within already-allowed deps, prefer a target-split inside the existing package over new-package creation.

**Procedure**:

1. Identify the nearest existing primitive package (same tier, same domain — e.g., `swift-graph-primitives` is nearest to a hypothetical `swift-attribute-graph-primitives`).
2. Compute the dependency delta: what external deps would the new package need that the nearest existing package doesn't already have?
3. If delta is zero or all deltas are already allowed by the existing package's layer budget, propose a new target inside the existing package.
4. Only propose a new package when the delta is non-trivial AND the new dep cannot live at the nearest existing package without changing its layer position.

**Rationale**: Target-splits are cheap and preserve single-package consumer imports; the delta check makes package creation an exception rather than a default. Full text + provenance: rationale archive §[MOD-020].

**Cross-references**: [MOD-001], [MOD-005]

---

### [MOD-022] Mechanical Coupling Inventory Before Scope Estimation

**Statement**: Before declaring cross-file coupling "open-ended" or "dense," run a mechanical inventory. Hitting N errors in a partial build and extrapolating is unreliable; the actual coupling count is the actionable number.

**Inventory commands**:

```bash
# Declared nested types:
grep -nE "extension [A-Za-z._]+ *\{" Sources/**/*.swift | wc -l

# Custom-init patterns:
grep -nE "public init\(.*\)" Sources/**/*.swift | wc -l

# Declared extension methods:
grep -nE "^\s*(public |internal )?func " Sources/**/*.swift | wc -l

# Cross-file references (grep each declared symbol across the file tree):
for sym in <declared-symbols>; do grep -l "$sym" Sources/ | grep -v "$decl_file"; done
```

The mechanical output is the scope estimate; extrapolated estimates are not acceptable substitutes.

**Rationale**: Partial-build error counts are biased in both directions; a mechanical scan produces a bounded, reviewable number where extrapolation produces a range the reviewer cannot verify. Full text + provenance: rationale archive §[MOD-022].

**Cross-references**: [MOD-001], [MOD-020]

---

### [MOD-026] Fine-Grained Per-Type Modularization Default in Multi-Type L3 Packages

**Statement**: When structuring a multi-type L3 package, the default decomposition is **one target per distinct type-family**, matching the swift-io pattern (`IO Core`, `IO Blocking`, `IO Events`, `IO Completions`). Bundling related-but-distinct types into a single coarse target is FORBIDDEN as the default; bundling MAY occur only when types are mechanically inseparable (thin helpers/typealiases that wrap a parent type).

**Correct decomposition** (Kernel Thread package):

```
swift-thread-primitives/
├── Sources/
│   ├── Thread Core/         # Kernel.Thread, common types
│   ├── Thread Barrier/      # Kernel.Thread.Barrier
│   ├── Thread Gate/         # Kernel.Thread.Gate
│   ├── Thread Pool/         # Kernel.Thread.Pool
│   ├── Thread Semaphore/    # Kernel.Thread.Semaphore
│   ├── Thread Synchronization/  # Synchronization<N>, DualSync, SingleSync (mechanically coupled)
│   └── Threads/             # umbrella per [MOD-005]
```

**Forbidden** (coarse "Thread Coordination" bundle):

```
swift-thread-primitives/
└── Sources/
    └── Thread Synchronization/   # ❌ Barrier, Gate, Pool, Semaphore, Worker all stuffed in
```

**Bundling exception** (mechanically coupled): `DualSync` and `SingleSync` travel with `Synchronization<N>` because they are wrappers of the parent type — splitting them would require duplicating the parent's storage layout. The exception fires when types share private storage, are mutual `~Copyable` collaborators, or one is a thin typealias of the other.

**How to apply**:

1. When designing a new package with ≥2 distinct type-families, propose one target per family by default.
2. Always provide an umbrella target re-exporting all variants per [MOD-005].
3. Verify [MOD-015] consumer import precision during audit: consumers depend on specific products (`Thread Barrier`), not the umbrella (`Threads`), unless they need the full surface.
4. The fine-grained default is design-time guidance; existing coarse packages are not rewritten on this rule alone — they get split when the next material change touches them, per minimal-revision principle.

**Why default to fine**: consumers who need `Kernel.Thread.Barrier` alone should not be forced to compile `Gate`, `Pool`, `Semaphore`, `Worker` — and the import-precision rules ([MOD-015]) only enforce narrow imports if narrow products *exist*. Full text + provenance: rationale archive §[MOD-026].

**Cross-references**: [MOD-003], [MOD-005], [MOD-006], [MOD-015]

---

### [MOD-029] Split Decisions Weight UPSTREAM Dep Tree, Not DOWNSTREAM Consumer Count

**Statement**: For package-split decisions, the UPSTREAM dep tree of the candidate (would the candidate's tree prune to a much smaller graph if extracted?) is the load-bearing signal for domain-distinctness. DOWNSTREAM consumer count (how many things import this?) does NOT signal domain-split. Single-module-use is mechanical and mostly surfaces `[MOD-004]` constraint-isolation and capability-internal variants — NOT genuine domain-split candidates.

**Why**: Domain-split exists to keep dependency graphs minimal and reasoning local; "would the graph prune?" is determined by upstream coupling, not downstream popularity, which measures adoption — orthogonal to architecture. Full text: rationale archive §[MOD-029].

**How to apply**:
- When evaluating a split candidate, trace upstream: how many packages does the candidate currently depend on? How many would it depend on after extraction? Large prune → split makes architectural sense.
- Do NOT cite "only one consumer imports this" as a reason to split (that's a `[MOD-004]` constraint-isolation flag, not a split signal).
- Composes with `[ARCH-LAYER-008]` correctness-driver: split decisions are correctness-driven (does the dep tree improve?), not adoption-driven.

**Cross-references**: [MOD-004], [MOD-008], [MOD-026], [ARCH-LAYER-008]

---

### [MOD-030] Combinator/Leaf-Type Micro Modules Are Deliberate; Module Count Is Not a Quality Signal

**Statement**: Combinator-style and leaf-type micro modules — one module per type-family at any layer — are deliberate. Module count MUST NOT be cited as a defect on its own or proposed for consolidation. Consolidation proposals targeting "fewer modules for readability or count reduction" without a load-bearing technical reason ([MOD-026] mechanical-inseparability, [MOD-001] broken layering, [MOD-RENT] rent failure) are forbidden.

**Why**: Micro modules carry three independent properties that bulk modules cannot replicate at once — optional adoption, parallel compilation, and conformance modularity (detail: rationale archive §[MOD-030]).

Generalizes [MOD-026]'s "fine-grained per-type modularization default" from multi-type L3 packages to L1 combinator-style packages. The underlying principle is the same; this rule names the L1 case so audits do not propose L1 module-count "tidying" by analogy from outside the institute's conventions.

**How to apply**:

1. When auditing a primitives package, count modules ONLY as input to other signals — never as a standalone defect line item.
2. When proposing structural changes to combinator-heavy packages (swift-parser-primitives, swift-serializer-primitives, future swift-formatter-primitives), do NOT propose collapsing N combinator modules into fewer "category" groupings (algebra / leaf / modifier). The N-count is the institute's intended granularity at L1 combinator packages.
3. A genuine consolidation case requires a load-bearing reason: mechanical inseparability per [MOD-026]'s bundling exception (types share private storage, mutual `~Copyable` collaborators, thin typealias of parent), broken layering per [MOD-001], or [MOD-RENT] rent failure on the family. Reader convenience and count aesthetics do not qualify.
4. The rule applies symmetrically across layers: [MOD-026] gives the L3 case; [MOD-030] gives the L1 case; the underlying principle is shared.

**Worked example (the origin incident, 2026-05-13 transformation-domain audit)** + provenance: rationale archive §[MOD-030]. The institute's intended granularity IS one module per combinator family, not a workaround for the absent variadic shape.

**Cross-references**: [MOD-026] (L3 fine-grained-per-type default — sibling rule), [MOD-RENT] (rent test for primitive packages), [MOD-001] (Core layer principle), [MOD-DOMAIN] (factor the law, not the module), [MOD-015] (consumer import precision — depends on narrow products existing)

---

### [MOD-035] Scope Statement Required for L1 Primitives Packages

> **Placement note ([MOD-PLACE])**: a package's scope statement IS its **owned axis**; the "Out of scope" list is exactly the axes [MOD-PLACE] assigns to *other* layers (e.g. `swift-memory-primitives` = addressing + allocation, **NOT** occupancy/topology/contract). Cite the owned axis explicitly.

**Statement**: Every L1 primitives package SHOULD carry a written scope statement bounding its identity surface. The scope statement names what the package IS (its identity-defining core) and what it explicitly is NOT (capability layers, allocation strategies, OS facilities, synchronization primitives, etc. that compose the core but lie outside it). The scope statement MUST be the reference for evaluating whether a proposed sub-target addition or extraction is in-scope or out-of-scope.

**Where it lives**:

| Option | When to use |
|---|---|
| `Documentation.docc/{Package} Scope.md` (preferred) | Package has a DocC catalog; scope statement is a top-level DocC article |
| Top-level `README.md` § Scope | Package has no DocC catalog or DocC is reserved for API docs |
| Top-level `SCOPE.md` | Both above are inappropriate or already used for other purposes |

**Required structure**:

1. **Identity statement** — one paragraph naming what the package IS. The package's *Domain.Namespace* concept defined in plain prose.
2. **Core targets** — enumerated list of the sub-targets that make up the identity surface.
3. **Out of scope** — enumerated list of capabilities, strategies, or facilities that compose this package but lie OUTSIDE its identity. Each entry names where the capability belongs instead (sibling package name, future extraction, or "lives in consumer code").
4. **Evaluation rule** — one sentence stating "Sub-target additions are evaluated against this scope. If a proposed addition is OUT of scope, it extracts to a sibling package, not into this one."

**Worked example** (memory-primitives scope statement): Research/modularization-skill-rationale.md §[MOD-035].

**Why**: Without a written scope, every contribution is judged against the contributor's intuition of "what fits" and sub-targets accrete over time (each justifiable in isolation, none individually triggering a reject); a written scope statement fixes the boundary at the package-design level, before the per-sub-target judgment is needed. Full text: rationale archive §[MOD-035].

**Composes with [MOD-034]**: [MOD-034] is the per-sub-target identity check (is this *role* foundational to this *Domain*?). [MOD-035] is the per-package identity check (what IS this Domain's identity surface, written down once for all sub-targets?). [MOD-034] catches role-based extractions that invert the dep direction; [MOD-035] prevents sub-target accretion that expands the Domain's identity surface inappropriately.

**Worked example (the origin incident, 2026-05-22 memory-primitives Cohort II semantic analysis)**: rationale archive §[MOD-035].

**Migration policy for existing packages**: Existing L1 primitives packages without a scope statement SHOULD add one at next publication-readiness pass. No forced cohort migration. The scope statement is part of release-readiness, not a precondition for routine work.

**Cross-references**: [MOD-DOMAIN] (factor the law, not the module — scope statement IS the law factoring at the package level), [MOD-034] (sub-target identity check — composes with [MOD-035] package identity check), [MOD-RENT] (two-criteria rent test — scope statement is the framing under which the rent test evaluates membership)

---

### [MOD-RENT] Two-Criteria Primitive-Package Rent Test

**Statement**: A primitive package's existence in the ecosystem MUST satisfy two criteria simultaneously: (1) **capability** — enables something the language and existing primitives don't already express; (2) **theoretical content** per [MOD-DOMAIN] — represents a coherent semantic domain with definition, law, spec, or structural invariant, not just code (convenience wrapper, naming sugar, helper). A package failing either criterion SHOULD be a candidate for absorption, deprecation, or deletion. Existence is judged on capability + theoretical merit, never on consumer or adoption count (per [ARCH-LAYER-008]).

**When the test fires**:

| Trigger | Action |
|---------|--------|
| New primitive package proposal | Gate before SPM scaffolding — both criteria MUST be checked and satisfied before scaffolding lands. |
| Existing primitive package review | Periodic audit against both criteria. |

**Procedure**:

1. **Identify** the primitive package and its claimed scope.
2. **Check capability**: enumerate what the package's types and functions enable that is NOT already expressible via language features (`consuming`, `~Copyable`, `deinit`, typed throws) plus existing primitives (Ownership, Memory, Reference, Tagged, Index, etc.). If the listed capability is fully expressible without the package, criterion fails.
3. **Check theoretical content** per [MOD-DOMAIN]: is the domain a *concept* with definitions, laws, or structural invariants that warrant a module boundary, or is it a code-collection? If the package's contents are characterized by "shared code, convenience, or helpers," criterion fails.
4. **Disposition** — when either criterion fails:
   - **Absorption**: move the failing package's types into the nearest related primitive package.
   - **Deprecation**: mark superseded with a replacement path; schedule deletion per [SKILL-LIFE-020] timing.
   - **Deletion**: remove from the workspace when the capability is fully expressible elsewhere and no replacement path is needed.

**Anti-pattern — the conceptual-purity defense**:

A common failure mode is defending an existing package on conceptual-cleanliness grounds (e.g., "lifetime ≠ ownership," "encoding ≠ format," "transport ≠ protocol") rather than on capability + theoretical content. Whether two concepts are distinct is upstream of whether each gets its own primitive package; the primary question is whether the package earns rent. Apply the rent test first; conceptual analysis is the tiebreaker when both criteria pass for both candidate scopes.

**Worked example (the origin incident)**: the 2026-04-26 ecosystem audit failed `swift-lifetime-primitives` on both criteria for all three of its types; the package was deleted. Full criterion table: rationale archive §[MOD-RENT].

**Rationale**: Primitive packages bear ecosystem weight (target, maintenance surface, review cost, "absorb or add?" decision fork), so the hurdle rate is higher than for an internal type; the two-criteria test is a default-explicit gate against the conceptual-purity defense pattern. Full text + provenance (incl. the 2026-06-09 consumer-criterion removal): rationale archive §[MOD-RENT].

**Cross-references**: [MOD-DOMAIN], [MOD-020], [RES-018], [ARCH-LAYER-001]

---

### [MOD-041] Package Cohesion — One Concern per Package (the coincidental-cohesion anti-pattern)

**Statement**: Every package MUST exhibit **functional cohesion** — every element it vends serves one well-defined concern. A package that accumulates unrelated functionality because it was convenient to put it there exhibits **coincidental cohesion**, the worst grade on Constantine & Yourdon's cohesion scale, and is FORBIDDEN. A package carrying more than one concern is a decomposition target **regardless of its size, age, or whether any consumer currently demands the split** — the split is justified first-principles by the presence of a second concern, never by demand (per [MOD-029], [ARCH-LAYER-008]).

**Vocabulary** (use the citable term in rules; the colloquial term as shorthand):

| Term | Meaning |
|------|---------|
| **Coincidental cohesion** | Worst grade — elements grouped for convenience, no shared purpose. The anti-pattern this rule forbids. |
| **Functional cohesion** | Best grade — every element contributes to one well-defined task. The target. |
| **Grab-bag** / kitchen-sink / junk-drawer | Working shorthand for a coincidentally-cohesive package. The classic instance is a `Utils` module. |

**Exception — extension-aggregator packages.** A package whose one concern is "extensions to a single well-defined external surface" is functionally cohesive *by that surface* and is NOT a grab-bag. `swift-standard-library-extensions` (extends the Swift standard library) and `swift-foundation-extensions` (extends Foundation) are blessed under this exception: their heterogeneous contents share the single purpose "extend surface X," so they satisfy [MOD-041] and MUST NOT be flagged as decomposition targets. The discriminator: does the package extend ONE named external surface (cohesive), or aggregate UNRELATED domains that merely share a repo (coincidental)?

**Correct** (functionally cohesive — one concern each):
```
swift-rfc-4122/                      # one concern: RFC 4122 (UUID)
swift-bit-primitives/                # one concern: the Bit domain
swift-standard-library-extensions/   # one concern: extensions to the stdlib (exception clause)
```

**Incorrect** (coincidental cohesion — the worked casualty):
```
swift-standards/swift-standards   // ❌ a bare @_exported umbrella over 14+ unrelated
                                  //    specification domains; implemented no specification
                                  //    itself (failed the L2 bar too). ARCHIVED 2026-07-13
                                  //    as the ecosystem's worst grab-bag.
swift-server-foundation           // ❌ where server-side odds-and-ends landed; a grab-bag by
                                  //    construction — each constituent concern extracts to its own package.
```

**How to apply**:

1. State each package's single concern in one sentence ([MOD-035] scope statement is the written form). If the sentence needs "and" between unrelated nouns, the package has ≥2 concerns.
2. A second concern makes the package a decomposition target — enumerate its concerns, extract each to its own package. Do NOT wait for a consumer to demand it.
3. Before flagging, apply the extension-aggregator exception: a package that uniformly extends ONE external surface is cohesive.

**Rationale**: Constantine & Yourdon's cohesion scale (Structured Design, 1979) gives a *scale*, not a binary, for "do these elements belong together." Coincidental cohesion — the bottom of the scale — is the failure mode a growing ecosystem drifts into as convenience placement compounds. Naming it with the citable term, and stating the one-concern rule at the package level, makes the anti-pattern reviewable and gives decomposition its first-principles justification: extract because a distinct concern exists, never because demand appeared. This is also the mechanism behind product leanness — every reusable concern lives in exactly one functionally-cohesive package that many products share.


**Cross-references**: [MOD-DOMAIN] (factor the law, not the module — [MOD-041] is its package-level corollary with the cohesion vocabulary), [MOD-RENT] (theoretical-content criterion — coincidental cohesion fails it), [MOD-029] (split weights upstream tree, not downstream demand — the first-principles basis), [MOD-014] (cross-package integration extraction — same first-principles/not-demand rationale), [MOD-035] (scope statement is the written one-concern test), [ARCH-LAYER-008] (correctness-driven, not adoption-driven).

---

## Accepted Deviations

### [MOD-EXCEPT-001] Platform Packages

**Statement**: Platform-abstraction packages at Layer 1 and Layer 3 are exempt from MOD-001 (Core), MOD-005 (Umbrella), and MOD-011 (Test Support). These packages use a peer-products pattern where each target independently wraps a platform subsystem (kernel, loader, system/memory).

**Affected packages**:
- L1: `swift-darwin-primitives`, `swift-linux-primitives`, `swift-windows-primitives`
- L3: `swift-darwin`, `swift-linux`, `swift-windows`

**Rationale**: These packages have 1-8 files per target; each target wraps a different OS subsystem with no shared types between them — a Core would be empty or contain only re-exports with no added semantic value. (Established 2026-03-20: rationale archive §[MOD-EXCEPT-001].)

---

### [MOD-EXCEPT-002] Placeholder/Stub Packages

**Statement**: Packages with zero-byte source files that serve as architectural placeholders are exempt from MOD-006 (Dependency Minimization) and MOD-011 (Test Support). Their declared dependencies serve as a design intent record.

**Affected packages** (L3 compiler toolchain family): `swift-abstract-syntax-tree`, `swift-backend`, `swift-compiler`, `swift-diagnostic`, `swift-driver`, `swift-intermediate-representation`, `swift-lexer`, `swift-module`, `swift-symbol`, `swift-syntax`, `swift-type`

**Rationale**: These packages exist to reserve namespace and document intended dependency structure for a future compiler toolchain — removing their dependencies would destroy design intent, and Test Support for empty packages is meaningless. (Established 2026-03-20: rationale archive §[MOD-EXCEPT-002].)

---

## Audit Metrics

| Metric | Source | Threshold | What It Reveals |
|--------|--------|-----------|-----------------|
| Product tier spread | `compute-tiers.sh` | >= 3 is a concern | Bundled concerns at different abstraction levels — extraction candidates |
| Mean sibling dependencies | Package.swift analysis | <= 2.0 | Lower is better; parser-primitives achieves 1.2 |
| Max dependency depth | Package.swift analysis | <= 3 | Deeper chains reduce build parallelism |
| Semantic domain count | Manual analysis per Primitives Layering.md | 1 per package | Multiple domains → split needed |

**Audit invocation**: "Audit {package} against /modularization" checks each MOD-* requirement against the package's Package.swift and source layout, producing a compliance table per [RES-015].
