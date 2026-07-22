# Modularization — Consumer Imports and Cross-Module Visibility

Companion of the **modularization** skill (navigation hub: `SKILL.md`). Load when choosing which module a consumer imports, or working at the cross-module symbol-visibility boundary (`@inlinable` bodies, `internal import`, `#externalMacro` module names, declared-dependency completeness). This file reads independently: it collects the consumer-import-precision and cross-module-visibility rules.

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/modularization-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MOD-015], [MOD-015a], [MOD-023], [MOD-027], [MOD-028], [MOD-036], [MOD-037], [MOD-038]

---

### [MOD-015] Consumer Import Precision

**Statement**: Consumer packages MUST import the narrowest module that provides the types they need. The correct import depends on the provider package's decomposition type.

**Primary decomposition** — variants are independently useful modules along a clear axis (strategy, operation, algorithm). Core is scaffolding; the variants are the product.

- Consumers MUST import specific variant modules, never the umbrella
- Package.swift MUST declare dependencies on specific variant products, not the umbrella product

**Supplementary decomposition** — Core contains the main API surface (the protocols, the foundational types). Variants add minor opt-in features (one additional algorithm, stdlib extensions, one alternate representation).

- The umbrella IS the canonical consumer import
- Importing the umbrella is correct even though variants exist

**Distinguishing test**: Could Core stand alone as a complete, useful package? If yes — the variants are supplementary and the umbrella is canonical. If Core is just namespace scaffolding for the variants — the decomposition is primary and consumers must be selective.

**Classification** (L1 primitives):

| Decomposition | Packages | Consumer import |
|---------------|----------|----------------|
| Primary | array, ascii-parser, ascii-serializer, async, binary, binary-parser, bit-vector, buffer, graph, heap, kernel, list, machine, memory, numeric, parser, parser-machine, pool, serializer, slab, storage, test, time, tree | Specific variants |
| Supplementary | sequence, affine, queue, algebra, hash-table, bit, cardinal, ordinal, index, identity, finite, dimension, geometry, set, rendering, cyclic, cyclic-index, input, link, source, text, token, vector, range, sample, lexer, algebra-affine, algebra-cardinal, algebra-modular, bit-index, bit-pack | Umbrella |

**Correct** (primary decomposition — consumer imports specific variant):
```swift
// Consumer needs ring buffer specifically
import Buffer_Ring_Primitives

// Consumer needs DFS traversal specifically
import Graph_DFS_Primitives

// Package.swift
.product(name: "Buffer Ring Primitives", package: "swift-buffer-primitives"),
.product(name: "Graph DFS Primitives", package: "swift-graph-primitives"),
```

**Incorrect** (primary decomposition — umbrella pulls in everything):
```swift
// ❌ Pulls in Ring, Linear, Slab, Linked, Slots, Arena — only needs Ring
import Buffer_Primitives

// ❌ Pulls in all 16 graph algorithms — only needs DFS
import Graph_Primitives
```

**Rationale**: Importing a primary-decomposition umbrella defeats the modularization investment (compile-time cost for every variant, lost signal of which capabilities are used); a supplementary umbrella adds negligible overhead and is the natural consumer interface. Supplementary example pair + full text: rationale archive §[MOD-015].

**Cross-references**: [MOD-005], [MOD-006], [MOD-003]

---

### [MOD-015a] Narrow-Imports Exception for Shadow Disambiguation

**Statement**: `public import X` in a narrow product `Y` makes X's *types* visible to Y's consumers but does NOT promote Y to "declares X" status for the purpose of module-qualification. When a consumer needs `Module.Namespace` syntax to disambiguate a shadowed name (e.g., the primitives `Executor` namespace shadowed by stdlib's `_Concurrency.Executor` in a type that conforms to `SerialExecutor`), the consumer MUST import a module that *declares* the namespace — typically the umbrella product — not a narrow product that merely re-exports it.

**Structural reason**: Swift module qualification is about declaration, not visibility. `Module.TypeName` resolves only when `Module` is the module that actually declares `TypeName`. `public import X` in module Y makes X's types visible through Y but Y is a conduit, not a declaring owner. Consumers writing `Y.TypeName` will fail to resolve; they must write `X.TypeName`.

**Correct** (umbrella for shadow disambiguation):
```swift
// In a type that conforms to SerialExecutor (brings _Concurrency.Executor in scope):
import Executor_Primitives           // umbrella — declares Executor namespace via Core

let queue: Executor_Primitives.Executor.Job.Queue = ...   // disambiguates from _Concurrency.Executor
```

**Incorrect** (narrow product cannot be qualified):
```swift
import Executor_Job_Queue_Primitives    // narrow — re-exports Executor via public import of Core

let queue: Executor_Job_Queue_Primitives.Executor.Job.Queue = ...
// ❌ Does not resolve: Executor is declared in Executor Primitives Core, not in this module
```

**Decision procedure for consumers**:

| Situation | Import |
|-----------|--------|
| No name shadow, no need for module-qualified syntax | Narrow variant product per [MOD-015] |
| Name shadow exists AND disambiguation needs `Module.Namespace` prefix | Umbrella product (or whichever product's module declares the namespace) |
| Types live in a shared Core target that is NOT itself a product | Umbrella product (Core is not importable; umbrella re-exports Core and can be qualified as a proxy because its target has `@_exported public import` of Core) |

**Why this is not a [MOD-015] violation**: [MOD-015] prohibits umbrella imports to avoid paying compile-time cost for unused variants. Shadow disambiguation is a distinct need — the consumer needs a module *identity* for qualification, not broader visibility. When the shadow is real and narrow-import qualification fails structurally, the umbrella is the smallest import that resolves the disambiguation; this is the case the narrow-imports rule does not cover.

**Rationale**: The shadow-disambiguation case is an exception, not a violation — the narrow-imports reasoning does not account for the structural difference between visibility and declaration in Swift's module system. Rejected alternative + full text: rationale archive §[MOD-015a].

**Cross-references**: [MOD-001], [MOD-005], [MOD-006], [MOD-015]

---

### [MOD-023] `#externalMacro` Module Name Normalization

**Statement**: `#externalMacro(module: ..., type: ...)` MUST cite the SwiftPM-normalized module name, not the SwiftPM target name as written in `Package.swift`. SwiftPM target names with spaces (e.g., `"Observations Macros"`) produce module identity with underscores (`"Observations_Macros"`), not collapsed-space names (`"ObservationsMacros"`). The string literal in `#externalMacro` MUST match the actual import identifier.

**Correct**:

```swift
// SwiftPM target: "Observations Macros"
// Module identifier: Observations_Macros (spaces → underscores per [PATTERN-004b])

@attached(member, names: named(_$registrar))
@attached(extension, conformances: Observable)
public macro Observable() = #externalMacro(
    module: "Observations_Macros",   // ✓ Underscore form matches import identifier
    type: "ObservableMacro"
)
```

**Incorrect**:

```swift
public macro Observable() = #externalMacro(
    module: "ObservationsMacros",    // ❌ collapsed spaces — module not found at compile time
    type: "ObservableMacro"
)
```

**Enforcement**: Mechanical — `validate-package-naming.py` [MOD-023] check (/promote-rule 2026-07-06): source `#externalMacro(module:)` cites vs dump-package macro-target names normalized spaces→underscores (dump-package resolves constant-named targets); near-misses of the package's OWN macro targets fire, external-package cites pass. Rationale + displaced detail: rationale archive §[MOD-023] + `Audits/PROMOTE-MOD-023-2026-07-06.md`. [VERIFICATION: WF]

**Cross-references**: [PATTERN-004b], [MOD-012]

---

### [MOD-027] `internal import` Is Incompatible With `@inlinable` Bodies Referencing the Module's Public API

**Statement**: `internal import X` and `@inlinable public func f() { X.SomeType.member(...) }` MUST NOT coexist in the same module. The compiler rejects any `@inlinable` body referencing a symbol imported with internal visibility:

```
property/method 'X' is internal and cannot be referenced from an '@inlinable' function
note: 'X' imported as 'internal' from 'SomeModule' here
```

This blocks the "demote imports + rely on `MemberImportVisibility` to hide L2 from re-export chain" route for resolving L2/L3 overload-resolution ambiguity when either (a) the L3 policy wrapper is `@inlinable` and references the L2 type, or (b) downstream modules rely on the re-exported L2 visibility for their own `@inlinable` bodies.

**Correct fallback for L2/L3 same-signature collisions**: apply `@_disfavoredOverload` to the colliding L2 `public static func` declarations. The attribute is a pure overload-resolution priority flag — does NOT perturb the body, signature, re-export chain, or `@inlinable`. The L3 unifier wins resolution cleanly; L2 access remains reachable via the qualified namespace path (`ISO_9945.Kernel.X.*`).

**Don't retry import-demotion under different framings** — these all fail in practice:
- Stripping the `@_exported` re-export but keeping `public import` per-file — the `@inlinable` rule still applies; the public/internal distinction is what matters, not re-export visibility.
- Switching the L3 methods from `@inlinable` to non-inlinable — changes public ABI, removes the inlining the methods were marked `@inlinable` for. Out of scope for a disambiguation fix.
- Hoisting L2 type references behind `@usableFromInline internal` wrappers — works in principle but requires one helper per referenced method, scales poorly vs. the one-line `@_disfavoredOverload` change, and obscures intent.

**Procedure when auditing an L2/L3 same-signature collision**:
1. Inspect the L3 tier's method attributes BEFORE considering import-demotion. Any `@inlinable` / `@_alwaysEmitIntoClient` / back-deployable method structurally blocks demotion.
2. Apply `@_disfavoredOverload` on L2; verify L3 unifier wins resolution; verify `ISO_9945.Kernel.X.*` qualified path still reaches L2.
3. When the L3 tier is NOT `@inlinable`, demotion becomes viable — but weigh against downstream re-export chain.

**Prior art + provenance**: rationale archive §[MOD-027] (canonical pattern: `@_disfavoredOverload` on 10 iso-9945 Read/Write declarations, `9aa06e6`).

**Cross-references**: [MOD-015], [MOD-016], [PLAT-ARCH-028]

---

### [MOD-028] Cross-Module Nested Extension Member Resolution Workaround

**Statement**: Under Swift 6.2+ with `InternalImportsByDefault` + `MemberImportVisibility`, the compiler cannot resolve extension members nested across module boundaries. A typealias-resolved type's extension members defined in a different module from the canonical type are invisible to consumers, even with explicit imports. When this affects a consumer-facing namespace (e.g., per-article typealiases on `Burgerlijk Wetboek.2.Artikel 194`), the workaround is a module-local namespace enum (e.g., `Boek_2`) with per-member typealiases that resolve within the same module.

**Why**: The compiler resolves typealiases to the canonical type's defining module, then looks for extension members there — not in the extending module. `Burgerlijk Wetboek.2.Artikel 194` is invisible to consumers because `Burgerlijk Wetboek` is from Core and `.2` + `.Artikel 194` are extensions from Boek 2.

**How to apply**:
1. When a module defines extensions on types from another module that consumers must access, check whether those extension members resolve at consumer call sites.
2. If invisibility surfaces: provide a module-local enum (`Boek_2`) with per-member typealiases that resolve within the same module.
3. Do NOT use `@_exported public import` to work around this — it prevents downstream composition layers from substituting custom types for the typealiases.


**Cross-references**: [MOD-015], [LEG-ENC-043]

---

### [MOD-036] Cross-Package Inlinable Surface Must Be Genuinely Inlinable

**Statement**: A `public @inlinable` declaration MUST NOT reference `package` / `@usableFromInline package` symbols in its body. A cross-package `@inlinable` consumer cannot see `package`-scoped symbols, so it cannot inline through such a body: the `@inlinable` silently fails to deliver the cross-package zero-witness-dispatch it promises, and consumer `@inlinable` code that references the op gets a hard compile error (`'X' is internal/package and cannot be referenced from an '@inlinable' function`). The internal-touching ops MUST be co-located with their storage in the SAME module as `@usableFromInline internal` — same-module-visible (ops reach the internals) AND ABI-visible (cross-package consumers inline) AND no public exposure.

**ADT Tower rider — scope correction (M12, ratified 2026-07-03; transcribed at W4, 2026-07-06).** The Statement reads as WHOLESALE (any `@usableFromInline package` storage under `@inlinable` accessors collides cross-package); the ADT-tower carriers REFUTE that wholesale reading — the landed `struct __X<S: ~Copyable>` carriers hold `@usableFromInline package var column` under `@inlinable` accessors and compile + specialize 0-witness cross-module (**ecosystem-data-structures** [DS-025]). The real constraint is NARROWER: the collision manifests ONLY at a RESILIENT (library-evolution, `-enable-library-evolution`) module boundary. **Non-resilient-builds invariant**: tower packages — and the [DS-025] carrier shape generally — assume NON-RESILIENT builds, where the shape is sound; scope this rule to the resilient-boundary case. Provenance: `Research/adt-tower.md` §4.7.

**Why `package` is the trap**: the type/ops module split (`[MOD-004]` constraint isolation) declares storage internals `@usableFromInline package` so the ops module (a different module of the same package) can reach them. That works intra-package but defeats cross-package inlining — `package` does not cross the package boundary, and no annotation makes a `package` symbol cross-package-inlinable. The only access level satisfying both same-module ops access AND cross-package inlining is `@usableFromInline internal`, which forces the internal-touching ops co-located with the storage.

**Decision procedure when consolidating a type/ops split** (partition on the conformance/import axis, NOT on `Copyable`-ness or filenames):
1. **Co-locate with storage** (`@usableFromInline internal`, one module): the entire internal-touching `~Copyable` surface AND conditional `where Element: Copyable` *instance methods* that import no sequence/collection-primitives and add no conformance.
2. **Isolate** (separate module per `[MOD-004]`, with minimal `package` windows where unavoidable): `Sequence`/`Collection`/`Sequence.Drain`/`Span.Protocol` *conformances* + their imports — they need module isolation for their imports + constraint, and consumers rarely inline through them. (`Span.Protocol` is the post-2026-06-23 spelling of the former `Memory.Contiguous.Protocol`, renamed/relocated out of the dissolved `Memory.Contiguous`.)
3. Satellite caveat: a `package` symbol a sibling-variant module references stays `package` per `[MOD-037]`.

This clarifies `[MOD-004]`'s "What Core excludes: any API whose signature requires `Element: Copyable`": the load-bearing exclusion is Copyable-*imposing conformances + their imports*, NOT conditional `where Element: Copyable` instance methods, which may co-locate with the `~Copyable` type.

**Naming + umbrella shape of the split**: the lean type module is named `{Domain} {Variant} Primitive` (SINGULAR); the conformances ops module is `{Domain} {Variant} Primitives` (PLURAL). The base plural `{Domain} Primitives` doubles as the `[MOD-005]` umbrella (re-exports the base type + all variant ops) — no separate pure-umbrella target, no "Base" token. Acyclicity: variant ops depend on the base/variant TYPE singular, never on the base ops plural. Full naming table in `[MOD-012]`; umbrella + acyclicity + dual-role exception in `[MOD-005]`.

**Lint enforcement (TEXT-ONLY — synthetic build-probe attempted + retracted 2026-05-24)**: the violation triggers only in a real consumer's **whole-module** context — synthetic build-probes all build clean and AST detection is out (cross-module access-level resolution, `[MOD-016]`) — so enforcement is **incidental consumer CI** (optionally made deterministic by a producer-side "canary consumer build"); re-promotable only with a representative real-consumer fixture. Outcome record: `Audits/PROMOTE-MOD-036-2026-05-24.md`; detail: rationale archive §[MOD-036].

**Cross-references**: [MOD-004] (the conformance isolation that motivates the split; this rule clarifies its Copyable-exclusion scope), [MOD-008] (cross-target `@inlinable` tradeoff), [MOD-009] (satellite→heap delegation), [MOD-016] (AST-can't-resolve-cross-module — and why a synthetic build-probe can't detect it either; enforcement is incidental consumer CI), [MOD-027] (`internal import` + `@inlinable` incompatibility — sibling access-level rule), [MOD-037] (cross-variant flip), [MOD-005] (base-plural-as-umbrella shape), [MOD-012] (type/ops-split naming table)

---

### [MOD-037] Cross-Variant `package` Symbols Must Not Flip to `internal`

**Statement**: When consolidating a type/ops split per `[MOD-036]`, the `package → @usableFromInline internal` flip MUST skip any `package` symbol a sibling-variant module references. Inline/Small satellites delegate into the heap variant cross-module (`[MOD-009]`); `internal` is single-module, so flipping a symbol a satellite calls breaks the satellite's build (and a per-target build will not catch it — the satellite is not in that target's closure). Classify each pinned-`package` symbol: **cold path** (spill transition, arbitrary-index remove/replace, raw `_remove*`) → keep `package`, accept it is not cross-package-inlinable; **hot path** (a consumer-inlined op pinned to a satellite-shared primitive) → refactor the satellite to call base's `@inlinable public` API so the primitive can be `@usableFromInline internal`. Never widen to `public`.

**Lint enforcement (DEFERRED — semantic-info gap)**: detection needs cross-module symbol-reference analysis (does another module in the package reference this `package` symbol?), which SwiftSyntax does not surface — the same limit that deferred `[MOD-016]`. Future path: a `swift package describe` / build-graph workflow validator. Until then, text-only; the `[MOD-036]` build-probe catches the consumer-visible symptom.


**Cross-references**: [MOD-036], [MOD-009] (satellite→heap delegation), [MOD-016] (analogous AST-can't-see-cross-module deferral)

---

### [MOD-038] Every Source Import Is a Declared Target Dependency — No Riding Transitive Build Accidents

**Statement**: Every module a target's sources `import` (any form — `public`, `internal`, `@_exported`, scoped) MUST appear in that target's `dependencies:` in `Package.swift`, as a same-package target dependency or a cross-package product dependency. Excepted: the target's own module, and modules supplied by the toolchain/SDK rather than by the package graph (the stdlib, `Testing`, platform modules). An import satisfied only transitively — the module happens to be built because some OTHER target's build job produced it first — is an undeclared build edge, and whether the target compiles becomes a build-plan scheduling race.

**The failure shape (W3-F2)**: an undeclared Barrier→Waiter import edge compiled iff another target's build job produced Waiter first — the first tsan-release plan lost that race, surfacing `no such module` in a DOWNSTREAM consumer's gate; fix was the one-line dependency declaration. Full incident: rationale archive §[MOD-038].

**Why scheduling-dependent is worse than plainly broken**: the missing edge does not fail deterministically — it fails on build plans with different parallelism and implicates the wrong package (the symptom surfaces in whichever consumer's gate ran the losing plan, not in the package carrying the defect).

**Relationship to the neighbor rules**: [MOD-006] is the upper bound (declare nothing a target doesn't use); this rule is the lower bound (declare everything its sources import). Together: `dependencies:` ≡ the import set, modulo the toolchain carve above and the [PKG-DEP-004] test-support-spine carve on the [MOD-006] side. [MOD-015] picks WHICH module to import; this rule says whichever module is imported, declare the edge. [PKG-DEP-003] is the package-level analog of the upper bound.

**Enforcement**: Mechanical — `validate-target-imports.py` (/promote-rule 2026-07-06): per-target import census (dump-package target/product/byName edges; dep manifests resolved via org mirrors, soft-skip when unresolvable; documented toolchain-module carve). Ladder found 2 live undeclared edges (tagged, ordinal) — fixed same-day. Symptom reminder stands: nondeterministic `no such module` on fresh/sanitizer plans = candidate undeclared edge before suspecting the toolchain. Discipline: `Audits/PROMOTE-MOD-038-2026-07-06.md`. [VERIFICATION: WF]

**Cross-references**: [MOD-006] (the complement bound — no unused deps), [MOD-015] (import precision — which module; this rule — declare it), [PKG-DEP-003] (package-level used-only declarations), [PKG-DEP-004] (test-support spine carve)

---

### [MOD-040] Prefer Explicit Imports Over `@_exported` Convenience Re-Exports

**Statement**: The institute moves AWAY from `@_exported` re-exports in general. A package SHOULD NOT `@_exported import` another module purely to spare consumers an `import` line. Consumers declare the imports they use ([MOD-015], [MOD-038]); a convenience re-export leaks the re-exported module's entire surface into every consumer's namespace, where it silently shadows or collides with local and stdlib names. `@_exported` is reserved for DELIBERATE umbrella products whose stated contract is to re-vend a curated surface (an umbrella target that exists to be the single import for a decomposed family) — never for convenience leakage.

**Evidence base (the failure shape this direction retires)**:
- Ambient-leak collision — an `@_exported` re-export of `Product_Primitives` from a parser-primitives umbrella made app-graph `Product`/`Coproduct` names collide (app collision, 2026-07-13).
- Stdlib shadow — an `@_exported import` leaking a `~Copyable` public `String` (and a UUIDs String-shadow at an integration cutover) collided with the stdlib name.
- Wrong-member-set — a fully commented-out local type silently re-bound its call sites to an `@_exported` element type (`Link` → `HTML_Standard.Link`; CLAUDE.md Gotchas).

**Exceptions analysis (pending)**: the exact boundary between a deliberate umbrella product and convenience leakage — and the mechanical distinction a linter can check — is UNRESOLVED as of this rule's authoring; the full exceptions analysis is a pending design task (BACKLOG). Until it lands this rule is SHOULD-level, and execution rides the end-state bottom-to-top per-package review, NOT a standalone ecosystem sweep. Direction aligns with `MemberImportVisibility` adoption (explicit imports become mandatory regardless).


**Cross-references**: [MOD-033] (drop the `@_exported` umbrella re-export on extraction — the operational case), [MOD-014] (extraction), [MOD-015] (consumer import precision), [MOD-038] (declare every imported module), [PKG-DEP-004] (test-support spine — a sanctioned re-export carve)
