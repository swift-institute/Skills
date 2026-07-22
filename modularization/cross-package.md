# Modularization — Cross-Package Integration, Extraction & Acyclicity

Companion of the **modularization** skill (navigation hub: `SKILL.md`). Load when providing cross-package integration (conformances, adapters, bridges), extracting a sub-target to a sibling package, or auditing package-graph acyclicity and dep-cleanup. This file reads independently: it collects the cross-package integration, extraction pre-flight, and acyclicity rules.

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/modularization-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MOD-014], [MOD-025], [MOD-032], [MOD-033], [MOD-034]

---

### [MOD-014] Cross-Package Optional Integration

**Statement**: When package A needs to provide integration with package B's types (e.g., conformances, witness values, adapters), and B is not a universal dependency of A's consumers, the integration MUST be isolated so consumers of A who don't need it never pull in B. Two forms are sanctioned — **extraction (default)** and **trait-gating (structural fallback)**:

- **Extract** the integration into its own sibling package E that depends on both A and B. This is the DEFAULT. A single-integration-target package is acceptable — it is NOT "unnecessary proliferation."
- **Trait-gate** an integration target kept inside A, behind an SE-0450 package trait. Use ONLY as a fallback when extraction cannot achieve clean layering (see the discriminator).

This is **Problem 2** (cross-package optional integration). It is distinct from Problem 1 (intra-package dependency isolation, solved by Core extraction per [MOD-001]).

**The discriminator — does B stay in A's manifest?** A package trait gates *resolution and compilation* of B, but the `.package(...)` declaration for B REMAINS in A's `Package.swift`; the package-graph edge A → B persists even when the trait is off. Extraction is the only form that removes B from A's manifest entirely: E names both A and B, while A names neither E nor B. Because manifest-graph cleanliness is the goal under maximum decomposition, **extract by default; trait-gate ONLY when** the integration needs A's non-public (`internal`/`package`) symbols an external E cannot reach, OR extraction would complete a package cycle ([MOD-032]) that an umbrella-re-export drop ([MOD-033]) cannot resolve.

**Form 1 — Extraction (default).** Move the integration to a sibling package; A loses its dependency on B. Drop any `@_exported` re-export of the moving target from A's umbrella per [MOD-033] (cursor-pilot pattern) after verifying no owner-internal fan-in.

**Correct** (extracted integration package — illustrative; the Bit ⊗ Algebra-Field bridge, 2026-05-28):
```swift
// swift-bit-algebra-primitives — the recipient⊗provider bridge as its own package
// (integration name is recipient-then-provider per [PKG-NAME-016]: Bit gains Algebra's structure)
let package = Package(
    name: "swift-bit-algebra-primitives",
    products: [.library(name: "Bit Algebra Primitives", targets: ["Bit Algebra Primitives"])],
    dependencies: [
        .package(path: "../swift-bit-primitives"),            // A — recipient (owns the facet)
        .package(path: "../swift-algebra-field-primitives"),  // B — provider (structure conferred)
    ],
    targets: [
        .target(name: "Bit Algebra Primitives", dependencies: [
            .product(name: "Bit Boolean Primitives", package: "swift-bit-primitives"),
            .product(name: "Algebra Field Primitives", package: "swift-algebra-field-primitives"),
        ]),
    ]
)
// swift-bit-primitives' Package.swift then declares swift-algebra-field-primitives nowhere.
```

**Form 2 — Trait-gate (structural fallback).** Keep the integration target in A: declare a `traits:` entry, declare B as a package-level dependency, and gate the integration target's dependency on B with `condition: .when(traits: [...])`. Consumers opt in via `traits: [...]` on their `.package(...)`; SE-0226 ensures consumers who don't opt in never resolve B. (Full provider + consumer manifest example: rationale archive §[MOD-014].)

**Incorrect**:
```swift
// ❌ Nested package for integration — fails GitHub publication (SPM limitation)
.package(path: "../swift-dependencies/integration/swift-clocks-dependency"),

// ❌ Trait-gating when A's manifest must be free of B — the .package(...) edge to B
//    still sits in A's Package.swift with the trait off; only extraction removes it.

// ❌ Integration dependency unconditional in-package — all consumers of A pay B's cost
.target(name: "Clocks Dependency", dependencies: [
    "Dependencies",
    .product(name: "Clock Primitives", package: "swift-clock-primitives"),  // ❌ no gate, no extraction
]),
```

(A separate repository for a single integration target is NOT incorrect — it is Form 1, the default. The earlier "unnecessary proliferation" prohibition is retracted; see Provenance.)

**Choosing the form**:

| Condition | Form |
|---|---|
| Default — A's manifest / package-graph must carry zero knowledge of B | **Extract** (Form 1) |
| Extraction needs A's non-public (`internal`/`package`) symbols, OR would complete a package cycle ([MOD-032]) that an umbrella-re-export drop ([MOD-033]) cannot resolve | Trait-gate (Form 2, fallback) |
| Integration is intra-package (A's own targets) | Neither — use [MOD-001]/[MOD-004] |
| B is needed by all consumers of A | Neither — declare B normally |

**Rent of an extracted integration package**: an extracted bridge E satisfies [MOD-RENT]'s consumer criterion by BEING the integration point — it is the only place the A⊗B integration can live without a manifest edge (trait form) or a layer cycle (B cannot depend up into A). The "no consumer today" reading of [MOD-RENT] does NOT disqualify an integration package whose role is to be the bridge, and [MOD-020]'s prefer-target-split default is overridden for the manifest-decoupling case.

**Strict decomposition (principal tightening 2026-07-12).** The extract-by-default mandate generalizes: EVERY cross-package integration concern (conformance, adapter, bridge, witness value) is vended from its own dedicated integration package — not only the optional (B-not-a-universal-dependency) case, and not only when the integration ADDS a dependency. A package "must not do too much": a general integration is never vended from a package whose primary concern is something else. The SOLE exception is Layer-5 applications, which by nature consume many packages — an application composing its dependencies is not vending an integration. Integration-package names follow [PKG-NAME-016] recipient-then-provider (`swift-html-vapor`; `swift-url-routing-authentication`). This narrows the choosing-the-form table's "B is needed by all consumers of A → declare B normally" row: that row still governs a plain shared *dependency*, but a distinct integration *concern* layered over that dependency is still extracted. Known in-package violators to migrate under this tightening are Pass-2 targets (an authentication×url-routing coupling; an HTML×Vapor conformance), reviewed per-package during the end-state pass — NOT a retroactive standalone sweep. This is a scope-broadening of the extraction mandate; the drain entry is the principal directive authorizing it.

**Rationale**: SE-0450 traits remove the *resolution and compile cost* of an optional integration but NOT the *manifest coupling* — extraction removes the coupling outright, and under maximum decomposition that extra package is worth it. Validated forms + weakening provenance: rationale archive §[MOD-014].

**First-principles, not demand-triggered (clarification 2026-07-13).** The mandate to vend a distinct integration concern from its own package is justified *first-principles* — by the existence of a distinct integration concern — and NEVER by consumer demand. Demand neither justifies an extraction nor defers one: the only per-case question is "is this a distinct integration concern?" A bug that surfaces the need (a consumer that trips over the missing bridge) is an *illustration the rule already predicted*, not the evidence that created the requirement; do not frame such a bug as "demand evidence" for the extraction. This mirrors the package-level [MOD-041] statement (a second concern makes a package a decomposition target regardless of demand) and [MOD-029] (splits weight the upstream tree, not downstream consumer count). Provenance: Internal/inbox.md drain 2026-07-13, first-principles-decomposition correction.

**Cross-references**: [MOD-001], [MOD-002], [MOD-020] (prefer-target-split — overridden for manifest-decoupling extraction), [MOD-032] (package-graph acyclicity), [MOD-033] (pre-extraction owner-internal fan-in check), [MOD-RENT] (integration-package rent carve-out), [MOD-041] (package-cohesion / one-concern — same first-principles-not-demand basis), [MOD-029] (upstream-weighted split), [PKG-NAME-016] (integration package naming — recipient-then-provider), SE-0450, SE-0226, `cross-package-integration-strategies.md`

---

### [MOD-025] Dep-Cleanup-Pass Audit Procedure

**Statement**: A dep-cleanup pass — the periodic ecosystem-wide sweep that flags `.product(...)` declarations no longer referenced from source — MUST follow this procedure. The audit's classification logic, source-coverage heuristics, exclusion rules, and per-edit verification gate are normative; informal greps for `import X` against declared deps produce false positives and false negatives at scale.

**Classification — uniquely-providing dep, not literal-name match**:

A declared dep `i` is REQUIRED iff there exists at least one imported module `m` (in any source file of any target in the package) whose **coverage set** is exactly `{i}`. The coverage set of `m` is the set of declared deps that re-export (transitively, through `@_exported public import` chains) the module owning `m`. A dep is UNUSED iff every imported module it covers is also covered by at least one other declared dep (i.e., its coverage is fully redundant).

Naïve "no `import X` in source ⇒ drop X" misclassifies the kitchen-sink → strict-import transition: a dep may legitimately be retained because consumers transit through it via `@_exported` re-export chains. The uniquely-providing test catches this.

**Required audit-script behaviors** (any cleanup-pass tooling MUST implement all five):

| # | Behavior | Failure mode if absent |
|---|---------|----------------------|
| (a) | Skip commented `// .product(...)` lines in Package.swift dep parsing | Phantom UNUSED findings on commented-out deps |
| (b) | Resolve `.package(url: "https://github.com/{org}/{repo}", ...)` deps by repo-basename → workspace package map lookup | URL-form deps treated as unknown packages, mis-classified |
| (c) | Follow `@_exported public import` chains transitively when computing each module's provider set | Re-exported modules attributed to the wrong dep |
| (d) | Scan both `Tests/<TargetName>/` AND `Tests/Support/` recursively for imports | Test-only deps falsely flagged as UNUSED |
| (e) | Exclude `* Test Support` deps declared on `* Test Support` targets from UNUSED candidacy per [MOD-024] | Spine deps falsely flagged; cleanup would silently break TS spine |

**Per-edit verification gate**: Every cleanup edit MUST be gated by `rm -rf .build && swift build && swift test` from the package's own directory. The clean-build precondition catches stale-cache false positives; the test run catches missing transitive providers that compile-only checks miss. A cleanup pass that batches multiple package edits without per-package verification is non-conforming.

**Stub-package exemption**: Packages tagged per [MOD-EXCEPT-002] (placeholders with design-intent deps) are excluded from the UNUSED sweep — their unused declarations are intentional.

**Spine-completion gap**: Findings on `* Test Support` declared deps where the corresponding `@_exported public import` is missing from `exports.swift` MUST be reclassified as spine-completion gaps and dispositioned per [MOD-024] (FIX by adding the re-export, not DROP).

**Procedure**:

1. Build the dep graph: parse all `Package.swift` files, resolve url-form deps via workspace map, skip commented lines.
2. Compute per-module provider sets by following `@_exported public import` chains in each target's source.
3. For each declared dep `i` in each package, compute coverage and classify (REQUIRED / UNUSED / TS-SPINE).
4. For each UNUSED finding, cross-check against [MOD-024] — if it's a TS-spine dep with a missing re-export, reclassify as spine-completion gap.
5. For each true UNUSED finding, propose the edit, then run `rm -rf .build && swift build && swift test` after applying. Only commit on green.
6. Audit-completion check: re-run the audit post-cleanup; remaining UNUSED findings MUST all be either stub packages or TS-spine candidates already routed to [MOD-024].

**Rationale**: Dep cleanup is high-leverage but its failure modes are silent (a dropped uniquely-providing dep breaks downstream consumers weeks later); the procedure's safety properties collectively eliminate the class of failure where a dep looks unused at source level but is load-bearing for re-export chains. Sweep evidence + provenance: rationale archive §[MOD-025].

**Cross-references**: [MOD-002] (centralization invariant the cleanup respects), [MOD-006] (dependency minimization the cleanup enforces), [MOD-024] (TS spine exclusion + spine-completion gap routing), [MOD-EXCEPT-002] (stub-package exemption)

---

### [MOD-032] No Package-Level Cycles, Even SwiftPM-Tolerated

**Statement**: Package dependencies MUST be acyclic at the *package-graph* level, not merely the *target-graph* level. SwiftPM target-acyclic / package-cyclic configurations — where package A declares `.package(path: "../B")` and package B declares `.package(path: "../A")` but the target dependencies remain acyclic — are forbidden even when SwiftPM tolerates them.

**Why**: SwiftPM's cycle detection operates at the target-graph level, so a package-cyclic configuration compiles and tests cleanly today but is fragile to tightened SwiftPM cycle detection, alternate build systems, URL-form switchover, and other PackageDescription consumers — pre-1.0 "timeless infrastructure" quality demands true acyclicity, not "works today by accident." Full fragility list: rationale archive §[MOD-032].

**How to apply**:

1. Before authoring any new `.package(path: "../X")` declaration in `Package.swift`, grep the target package's `Package.swift` for a back-dependency on the proposed dependent. If present, the new declaration completes a package-level cycle and MUST NOT land.
2. After any cohort extraction that adds new deps, run the graph validator over the org roots and resolve any non-baselined finding before the next push.

**Enforcement**: Mechanical — `validate-package-graph.py` (swift-institute/.github scripts; /promote-rule 2026-07-06): full Tarjan-SCC cycle detection over all org manifests (the earlier in-rule 2-cycle audit under-detected longer cycles), multi-root union for cross-org edges, prune-only `.package-graph-baseline`. Landing sweep 2026-07-06: ZERO live cycles across all five org roots. Discipline: `Audits/PROMOTE-MOD-032-2026-07-06.md`. [VERIFICATION: Script]

**Worked example (the origin incident, 2026-05-22 Cohort I — six reverts)**: rationale archive §[MOD-032].

**Relationship to other rules**: [MOD-033] is the pre-flight mechanism that catches this at extraction-write-time (cheaper than discovery). [MOD-034] is the parallel rule on the foundational-conformance axis. [MOD-035] requires a written scope statement that pre-decides which sub-targets are extraction candidates at all.

**Cross-references**: [MOD-033] (pre-extraction fan-in pre-flight — catches the cycle vector), [MOD-034] (pre-extraction identity-defining check — catches the foundational-conformance axis), [ARCH-LAYER-001] (layer dep direction discipline)

---

### [MOD-033] Pre-Extraction Owner-Internal Fan-In Check

**Statement**: Before extracting a sub-target `{Domain} {X} Primitives` from its owner package to a new sibling, the proposer MUST grep the owner's `Sources/` for `import {Domain}_{X}_Primitives` AND inspect the owner's umbrella `exports.swift` for `@_exported public import {Domain}_{X}_Primitives`. ANY hit constitutes *owner-internal fan-in* — extracting would require the owner to declare a path-dependency on the new sibling for its own continued behavior, completing the package-level cycle forbidden by [MOD-032].

**Mechanism**:

```bash
# 1. Source-file imports across owner's sub-targets:
grep -rn "^[[:space:]]*\(@_exported[[:space:]]\+\)\?\(public\|internal\|private\|fileprivate\|package\)\?[[:space:]]*import[[:space:]]\+{Domain}_{X}_Primitives" \
  {owner}/Sources/ \
  | grep -v "/{Domain} {X} Primitives/"

# 2. Umbrella re-export:
grep "{Domain}_{X}_Primitives" "{owner}/Sources/{Domain} Primitives/exports.swift"
```

**Decision table**:

| Grep result | Disposition |
|---|---|
| Both empty | Pre-flight passes for [MOD-033]; proceed to [MOD-034] check |
| Source-file hits only | Cycle hazard — owner-stayer sources reach into the moving target's surface; reject extraction or refactor stayer to avoid the import |
| Umbrella hit only | Cycle hazard via umbrella re-export — either drop the re-export (deliberate API narrowing; cursor-pilot pattern) or reject extraction |
| Both hit | Cycle hazard; reject by default OR address both vectors before extraction |

**Cursor-pilot pattern exception (umbrella drop)**: When the only fan-in is the umbrella `@_exported public import`, the extraction MAY proceed if the umbrella line is removed AS PART OF the extraction. The deliberate API narrowing — downstream consumers gain a one-line explicit-import requirement for the extracted module — is acceptable when the sub-target is genuinely *incidental* to owner's identity per [MOD-034]. If the sub-target is *foundational* per [MOD-034], even the umbrella-drop path is forbidden (the conformance has to stay with the type).

**Worked examples** (Memory Cursor pilot clean; Affine Ordinal rejected; Cardinal Subtract rejected) + provenance: rationale archive §[MOD-033].

**Cross-references**: [MOD-032] (the cycle rule this enforces), [MOD-034] (the parallel pre-flight on the foundational axis), `Scripts/integration-extraction-inventory.py` (v3.5 discriminator, Step 4 mechanizes this check)

---

### [MOD-034] Pre-Extraction Identity-Defining-Surface Check

**Statement**: Before extracting a sub-target `{Domain} {X} Primitives` from its owner, the proposer MUST classify `{X}` as either *foundational* or *incidental* to `{Domain}`'s identity. Sub-targets whose `{X}` is foundational MUST NOT extract, regardless of cycle-cleanness or dep-minimization benefit. The conformance defines owner identity; extraction inverts the dep direction.

**FOUNDATIONAL_ROLES** (extraction forbidden):

| Role | Why foundational |
|---|---|
| `carrier` | Domain.Type IS a Carrier of an underlying type; conformance defines algebraic identity (e.g., Cardinal IS a Carrier of Int with `.zero`/`.one`) |
| `tagged` | Domain.Type IS a Tagged<Tag, Underlying> phantom-typed wrapper; conformance defines the Domain discrimination |
| `property` | Domain provides Property.Protocol semantics to consumers; conformance defines identity-preserving inout/borrow |
| `equation` | Domain conforms to Equation.Protocol; equality is identity |
| `hash` | Domain conforms to Hash.Protocol; hashability is identity for hash-based collections |
| `comparison` | Domain conforms to Comparison.Protocol; ordering is identity |

**INCIDENTAL_ROLES** (extraction permitted on [MOD-033]/[MOD-032] axes):

Parsing/serializing (`parser`, `serializer`, `coder`, `lexer`), position/iteration (`cursor`, `iterator`), formatting/output (`format`, `formatter`, `render`), execution context (`async`), ownership idioms (`inout`, `borrow`, `consume`). These are capability layers OVER the owner's core; the owner's identity doesn't depend on them.

**Procedure**:

1. Identify the `{X}` token of the sub-target name (the words between `{Domain}` and `Primitives`).
2. Lowercase and kebab-case it (e.g., "Carrier" → `carrier`).
3. If the result is in FOUNDATIONAL_ROLES, reject extraction.
4. If the result is in INCIDENTAL_ROLES (or is a non-role subject like `Pool`, `Buffer`, `Map`), proceed to [MOD-033] cycle pre-flight.

**Why the asymmetry**: Foundational conformances are how `{Domain}` defines its own behavior — extraction inverts the dependency (the owner would depend on the sibling for its own identity surface); [MOD-033] catches the mechanical symptom, [MOD-034] the architectural root cause, and it applies even when the cycle test would technically pass (e.g., via umbrella-drop workaround).

**Worked examples** (Cardinal Carrier / Affine Tagged / Comparison Property rejected; Memory Cursor / Binary Format accepted) + provenance: rationale archive §[MOD-034].

**Cross-references**: [MOD-032] (the cycle rule this rule sometimes preempts via architectural correctness), [MOD-033] (the parallel pre-flight on the cycle axis), [MOD-035] (scope-statement discipline — the package-level analog of this sub-target check)
