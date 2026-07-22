# Modularization — Layer-Placement Calculus

Companion of the **modularization** skill (navigation hub: `SKILL.md`). Load when placing a variant axis, capability, or stored requirement at the correct tower layer (Memory ⊏ Storage ⊏ Buffer ⊏ ADT), auditing a placement, or deciding compose-vs-refine. This file reads independently: it collects the cross-layer placement calculus.

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/modularization-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MOD-PLACE], [MOD-PLACE-DECOMPOSE], [MOD-PLACE-FLOOR], [MOD-PLACE-AUDIT], [MOD-PLACE-EXPRESS]

---

## Layer-Placement Calculus

**Scope**: Placing any concern — a variant axis, a capability, a stored requirement — at the correct layer of the `Memory ⊏ Storage ⊏ Buffer ⊏ ADT` tower. This is the cross-layer companion to [MOD-DOMAIN]: [MOD-DOMAIN] factors a law to the right *module*; the `[MOD-PLACE-*]` family factors a law to the right *layer*. **Authority**: `Research/decomposition-layer-placement-calculus.md` (the principles — applied here, not re-derived) and `Research/decomposition-layer-placement-package-map.md` (the exhaustive per-package application). These rules promote §7.1 of the calculus into canon: they are the single source of truth for layer placement, and consulting them **replaces** re-deriving placement from first principles each session (the historical drift this section exists to end).

### The four owners (the orthogonal basis)

The tower is the orthogonal basis of the design-decision space of a stored data structure. Each layer owns exactly one design-decision **secret** (Parnas; Mitchell–Plotkin), existentially bound and unobservable above it. Each `◄has─` edge means *"presupposes, but does not observe, the layer below"* — composition, never refinement.

| Layer | The question it answers | Owns (its secret) | Canonical surface |
|---|---|---|---|
| **Memory** | Where do the bytes live, and who owns their lifetime? | a product of orthogonal sub-axes: byte-**Location** (inline ⊥ out-of-line ⊥ hybrid) ⊥ **Allocation**-discipline (single-buffer ⊥ bump ⊥ free-list) ⊥ liveness/teardown ⊥ growth ⊥ addressing | `Memory.{Inline,Heap,Small}` (Location) · `Memory.Allocator.{Arena,Pool}` (Allocation) · FROZEN 4-op `Store.\`Protocol\`` · `Memory.Allocator.\`Protocol\`` marks the allocation sub-axis (`Inline` does **not** conform — *the tell*) |
| **Storage** | How are live slots arranged across regions? | slot-**Topology** (single-region vs multi-region/SoA) ⊥ init-**Tracking** | `Storage.Contiguous<M>` · `Storage.Split<…>` · `Storage.\`Protocol\`` |
| **Buffer** | What is the logical occupancy/order? | the **Occupancy** discipline (dense `Linear`/`Ring` · sparse `Slab`/`Slots` · node-`Linked` · `Arena` recycling) | `Buffer.{Linear,Ring,Slab,Slots,Linked,Arena}<S>` · `Buffer.\`Protocol\`` (`count`) |
| **ADT** | What abstract contract does the type satisfy? | the **Contract** (membership, key→value, order, priority) + its laws | `Array`/`Stack`/`Queue`/`Tree`/… · the ADT's own `X.\`Protocol\`` |

**Cross-cutting capabilities** — Span (a contiguous view), Iteration (`Iterable`), Algebra — and the **sibling Index axis** (`Index<Element>`, which types *which slot*) compose *over* the basis via `where Self: Core & Capability`. They are **never owned by one layer**; baking one into a core (the `<Element>`+`count`+`span` veneer the now-dissolved `Memory.Contiguous` baked onto the Memory floor — `memory-contiguous-dissolution.md`, 2026-06-23) is the canonical §1.3 smell. Span now rides `Span.Protocol` on the layer that owns it (`Storage.Contiguous`) and bare `Swift.Span` for borrowed views.

### Canonical placements (settled — do NOT relitigate)

The full variant inventory, classified once by axis. This table is **closed**: a concern's layer is looked up here, not re-argued.

| Family | Axis | Canonical layer |
|---|---|---|
| `Inline` / `Heap` / `Small` | Location | **Memory** leaf |
| `Arena` / `Pool` | **Allocation strategy** | **Memory** — `Memory.Allocator.{Arena,Pool}` |
| `Contiguous` / `Split` | Topology | **Storage** |
| `Linear` / `Ring` / `Slab` / `Slots` / `Linked` / `Arena` (occupancy) | Occupancy discipline | **Buffer** |
| `Bounded` / `Fixed` / `Static` | Capacity **bundle** — decompose first | Memory ⊗ Buffer-floor ⊗ Index |
| `Indexed<Tag>` / `Index.Bounded<N>` | Typed-index | **Index** sibling axis |
| `Ordered` / `MinMax` / `Keyed` / `DoubleEnded` / `N` | Contract | **ADT** |

**An allocation strategy lives at exactly one layer — Memory.** `Storage.Arena`/`Storage.Pool` (allocation re-expressed at Storage), and any ADT or Buffer that *names or stores* an allocation concern, are placement smells duplicating one axis across three layers → dissolve to `Storage.Contiguous<Memory.Allocator.Arena|Pool>`. `Buffer.Arena` is retained **only** as an *occupancy* discipline over `Storage.Contiguous<Memory.Allocator.Arena>` — "mirror the mechanism, not the Arena name." A `Storage.* : Buffer.\`Protocol\`` or `Buffer.* : <ADT>.\`Protocol\`` conformance is an **upward (inverted) placement** and is forbidden.

> **Seam taxonomy (RESOLVED — 2026-06-22, supersedes DP3 2026-06-18)**: the allocation-strategy **marker** is `Memory.Allocator.\`Protocol\`` (gerund alias `Memory.Allocating`), homed on the **agent noun** via the [API-IMPL-009] hoist — `__MemoryAllocatorProtocol` re-exposed as a param-free `typealias \`Protocol\`` on the generic `Memory.Allocator<Resource>`; the witness IS `Memory.Allocator<Resource>` itself, and the strategy **types** stay `Memory.Allocator.{Arena,Pool}`. This **converges** the calculus (which always spelled the marker `Memory.Allocator.\`Protocol\``) with live code: DP3 had deferred to `Memory.Allocation.\`Protocol\`` *because* "a protocol cannot nest in the generic `Memory.Allocator<Resource>` on 6.3.2" — that premise is disproven (the hoist exposes `Memory.Allocator.\`Protocol\`` unbound in constraint/conformance position; `[Verified: 2026-06-22]` swiftc 6.3.2 + 6.5-dev), live code moved onto the agent noun (memory-allocation `1153e09`), so DP3's deferral is moot. `Memory.Allocation.\`Protocol\`` is **retired**; the `Memory.Allocation` namespace survives only for `Memory.Allocation.Error` / `.Granularity`. `Memory.Allocatable.Protocol` remains a *separate* create/grow seam (refines `Memory.Tracked`), **not** the strategy marker. The inline `Memory.Allocator.\`Protocol\`` spellings above (the Memory row; [MOD-PLACE-EXPRESS]) are now correct as written. One forced-spelling caveat: the gerund typealias RHS targets the hoisted `__MemoryAllocatorProtocol` directly and self-conformers use the hoisted name (canonical self-references → circular) — see [API-IMPL-009] / [PKG-NAME-006]. Provenance: [API-IMPL-023] (BREAKING 2026-06-22) + operation-domain-naming-and-organization.md v1.1.2 §6.1; [RES-013a] (live code outranks the calculus — here they converge).

---

### [MOD-PLACE] Lowest-Correct-Layer Placement (axiom)

**Statement**: A concern (variant axis, capability, or stored requirement) MUST be placed at the **lowest tower layer that both owns its axis AND can enforce its invariant**. Placement is decided by **semantic identity** — which design-decision-secret the concern *is*, read from its operational behavior, not its name — with the 0-`witness_method` specialization boundary and dep-graph weight as tiebreakers **only among already-correct placements**, never as selectors over a structurally-distinct option. Placement is **correctness-driven, never adoption-driven**: consumer count never enters the decision ([ARCH-LAYER-008]).

**Decision procedure** (calculus §2.2):
1. **Project onto the basis** — which axes in `{Location, Allocation, Topology, Tracking, Occupancy, Contract}` (+ cross-cutting capabilities + Index) does the concern vary? Read behavior, not the name (*the name lies*: `.Bounded` names one thing and is four).
2. **Decompose bundles first** — if it varies ≥ 2 axes it is a mis-bundle; split into single-axis concerns and place each ([MOD-PLACE-DECOMPOSE]).
3. **Find the lowest owner** — `L* = min⊏ { L : owns(L, axis) }`.
4. **Apply the floor** — if `L*` cannot enforce the invariant, lift to the lowest layer that owns the axis AND enforces it, and **name the floor** ([MOD-PLACE-FLOOR]).
5. **Express by decompose/compose** — distinct leaf types + composition + constrained extensions over canonical seams, never an ad-hoc protocol ([MOD-PLACE-EXPRESS]).

**Rationale**: [MOD-DOMAIN] applied across layers — factor each law to the layer that owns it; this axiom plus the closed inventory above make placement a **lookup**, not a debate. Full rationale: rationale archive §[MOD-PLACE]. **Seam-taxonomy note (ADT Tower rider, 2026-07-02; audit F5 fix)**: `Memory.Allocatable.\`Protocol\`` refines `Memory.Region` (NOT `Memory.Tracked` — that protocol is deleted by adt-tower §9.6 #1); the create/grow seam is `Memory.Growable`, now ALSO the **fence** for allocation-generic op pins ([DS-029]): `R: Memory.Growable` covers heap AND small in one op extension while excluding `Memory.Inline` (`Research/adt-tower.md` §4.7, §9.6).

**Cross-references**: [MOD-DOMAIN], [MOD-PLACE-DECOMPOSE], [MOD-PLACE-FLOOR], [MOD-PLACE-AUDIT], [MOD-PLACE-EXPRESS], [MOD-009], [MOD-012], [MOD-035], [ARCH-LAYER-008]; **ecosystem-data-structures** [DS-001] (four-layer model), [DS-004] (Buffer owns mutation), [DS-025] (the ADT shape composes onto this placement), [DS-029] (Memory.Growable is the op-pin fence).

---

### [MOD-PLACE-DECOMPOSE] Bundle Decomposition Before Placement

**Statement**: A variant or capability whose name spans ≥ 2 orthogonal axes MUST be decomposed into single-axis concerns and each placed independently. **No monolithic placement of a multi-axis bundle is ever correct.**

**Example**: `.Bounded` = {capacity, growth-policy, overflow-signal, typed-index} — four axes wearing one name. It has no single home; each component places separately: **placement bytes at Memory**; the **overflow contract** (typed `Overflow`, `Header` capacity) and growth policy at **Buffer** (the live-code shape); typed-index at Index. (The earlier "capacity value + growth at Memory" spelling is **deleted** — capacity's overflow contract is a Buffer concern, [DS-029].)

**Rationale**: A multi-axis name is the anti-orthogonality smell; placing the bundle whole necessarily mis-places ≥ 1 of its axes. **ADT Tower rider (2026-07-02)**: capacity SPLITS across Memory (placement bytes) and Buffer (the typed-`Overflow` / `Header`-capacity contract) — the live-code shape; the allocation-generic op pin for bounded columns is the [DS-029] form-2 shape with `throws(Overflow)` (`Research/adt-tower.md` §4.7).

**Cross-references**: [MOD-PLACE], [MOD-PLACE-FLOOR]; **ecosystem-data-structures** [DS-028], [DS-029]

---

### [MOD-PLACE-FLOOR] The Honest Hard Floor

**Statement**: Maximum decomposition is bounded by correctness. A concern MUST NOT be pushed below the lowest layer that can **enforce its invariant**. When the axis-owner cannot enforce it, lift to the lowest enforcing super-layer and **name the floor explicitly** (a source-header note + the governing record) — never silently absorb it.

**Examples**: leak-freedom for ARC-backed `~Copyable` memory floors at the `Memory.Heap` leaf's backing `class` (a conditionally-`Copyable` generic struct cannot carry `deinit` — `bd04f32`); overflow-signaling floors at the lowest layer that can see the caller.

**Rationale**: The too-low failure mode (calculus §3.2) — a policy crushed into a leaf that cannot see the invariant it must enforce. The floor is the honest boundary between maximum decomposition and correctness.

**Cross-references**: [MOD-PLACE], [MOD-PLACE-AUDIT]

---

### [MOD-PLACE-AUDIT] The Two-Failure-Mode Lens

**Statement**: When auditing a placement, check **both** mirror-image failures: **(i) too-high** — does a strictly lower layer own this axis and enforce this invariant? (if yes → push down); **(ii) too-low** — can this layer actually see the invariant it must enforce? (if no → the floor was crossed; lift up). The too-high symptom is the **wart triad**: a runtime override where compile-time type-selection would do; a universal stored requirement where a leaf-private record would do; an awkward non-conformance where an honest absence would do.

**Mechanical checks** (`Scripts/layer-placement-classify.py`): no `Storage.* : Buffer.\`Protocol\`` or `Buffer.* : <ADT>.\`Protocol\`` conformance (upward / inverted placement); no allocation strategy (`Arena`/`Pool`) named or composed at Storage/Buffer/ADT when `Memory.Allocator.*` is its home.

**Rationale**: Mechanizes the post-hoc `.Small`-class discovery into a pre-hoc check; the wart triad is the operational signature of a leaked lower secret.

**Cross-references**: [MOD-PLACE], [MOD-PLACE-FLOOR]; **swift-linter**

---

### [MOD-PLACE-EXPRESS] Express Placement by Decompose/Compose, Not by Protocol

**Statement**: A placement MUST be realized by **distinct leaf types** (compile-time type-selection), **composition/delegation** (`Storage.Contiguous<Memory.X>`), and **constrained extensions over canonical seams** (`where M: Memory.Allocator.\`Protocol\``) — NOT by minting an ad-hoc capability protocol or a protocol refinement to carry the concern.

**Rationale**: Standing principal directive (`mutator-orthogonal-vs-refinement-stance.md`): overlapping concerns get sibling types + dual conformance, never refinement (CLCPM compose-don't-refine). A minted protocol re-introduces the too-high leak the placement was meant to remove.

**Cross-references**: [MOD-PLACE], [MOD-PLACE-AUDIT]; **ecosystem-data-structures** [DS-025]
