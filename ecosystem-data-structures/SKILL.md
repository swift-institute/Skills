---
name: ecosystem-data-structures
description: |
  Catalog of data structures across swift-primitives and swift-foundations with selection guidance.
  ALWAYS apply when selecting or recommending a container, buffer, storage, or memory type.

layer: implementation

requires:
  - swift-institute

applies_to:
  - swift-primitives
  - swift-standards
  - swift-foundations

---

# Ecosystem Data Structures

Catalog and selection guide for all data structure types in the Swift Institute ecosystem.
Types are organized in a four-layer composition architecture: Memory -> Storage -> Buffer -> Collection.

---

## Composition Architecture

### [DS-001] Four-Layer Composition

**Statement**: Data structures in the ecosystem are composed in four layers. Each layer adds exactly one concern. When building new containers, compose from these layers — do not bypass them.

```
ADT         (user-facing API: subscript, iteration, protocol conformances)
    |
Buffer      (mutation logic: grow, insert, remove, rebalance + Header state)
    |
Storage     (element lifecycle: init/deinit tracking, reference-counted backing)
    |
Memory      (raw allocation: malloc, bump, pool, inline)
```

| Layer | Concern | Consumer |
|-------|---------|----------|
| Memory (Tier 13) | Allocation/deallocation | Infrastructure builders only |
| Storage (Tier 14) | Element lifecycle tracking | Buffer/custom container builders |
| Buffer (Tier 15) | Mutation semantics + state | ADT/collection builders |
| ADT (Tiers 16-18) | User ergonomics | Application code |

**Rationale**: Most code should use ADT (Collection) types. Drop to Buffer when you need direct mutation control. Drop to Storage when building a new Buffer discipline. Drop to Memory only for raw allocator work. (The four owners are Memory → Storage → Buffer → ADT; "ADT" is the 4-owner vocabulary for the top layer, [DS-025].)

---

## Variant System

### [DS-002] Variant Selection

**Statement**: A variant is a **point in column space** along three FREE axes — allocation, capacity, ownership — declared as a **front-door alias** on the family carrier, never a hand-written type ([DS-028]). Select by axis:

| Axis | Points (spelling) | Select when |
|------|-------------------|-------------|
| **Allocation** | `X<E>` (heap, default) · `X<E>.Small<n>` (inline ≤ n bytes ⊕ heap spill) · `X<E>.Inline<n>` (fixed inline, n elements) | default heap; `Small` for usually-small-occasionally-large (SmallVec); `Inline` for zero-heap fixed |
| **Capacity** | `X<E>` (growable, default) · `X<E>.Bounded` (fixed capacity, `throws(Overflow)`) | default growable; `Bounded` for a known cap with typed overflow |
| **Ownership** | `X<E>` (unique move-only, default) · `X<E>.Shared` (CoW) | default unique; `Shared` for value-semantics copies |

**Which variants exist per family is consumer-pulled** — pulling one costs one alias file ([DS-028]). Consult the family's front-door files for the built inventory; do not assume a variant exists because a sibling family has it. Units: `Small<n>` = **bytes**, `Inline<n>` = **element count** ([DS-028]).

**`.Indexed<Tag>` is NOT a variant** (2026-06-01): the per-container `*.Indexed<Tag>` phantom-typed-index wrappers are removed. A phantom-typed-index view over any collection is provided generically by `swift-tagged-collection-primitives` — `Tagged<Tag, C>` where `C: Collection.\`Protocol\`` re-exposes the collection through `Index<Tag>` via `Tagged`'s own `retag` (`Index<T>` is itself `Tagged<T, Ordinal>`). It is a **read-only** view (`Tagged.underlying` is `package(set)`). Do NOT add a `.Indexed` nested type to a container.

**Copyability / Sendability flow from the column** (D6, [DS-025]): a carrier is `Copyable` iff its column is (`extension __X: Copyable where S: Copyable`); `Sendable` iff its column is (`Sendable where S: Sendable & ~Copyable`); carriers carry **no `deinit`** (teardown is leaf-owned, [DS-023]). Semantic conformances key on the column's `S:` bounds, never on same-type pins ([MEM-COPY-018]).

**Known toolchain walls** (6.3.3): the `deinit ⟹ unconditionally ~Copyable` law (SE-0427, §3 W1 — a by-design type-system law, [MEM-COPY-016], not a passing limitation); the cross-package `@_rawLayout` deinit-skip (#86652, §3 W2 — DEBUG-only on 6.3.3, release specializes past it; the [MEM-SAFE-027] `_deinitWorkaround` stays REQUIRED because debug leaks are real leaks); the dual-storage IRGen crash (§3 W3 — FIXED in reduction; the two-arm enum `_Representation` remains the `Small`-leaf idiom). Full wall table: `Research/adt-tower.md` §3.

**Cross-references**: [DS-001], [DS-023], [DS-025], [DS-028]; **memory-safety** [MEM-COPY-016], [MEM-COPY-018], [MEM-SAFE-027].

---

## Collection Types (Tiers 16-18)

### [DS-003] Container Selection

**Statement**: Select the collection FAMILY that matches the access pattern; do not drop to a Buffer or Storage type when an ADT exists for the use case. Each family's **canonical** front door is below. Variants (allocation / capacity / ownership points) are **consumer-pulled front-door aliases** per [DS-028] — consult the family's front-door files for the *built* inventory rather than assuming a variant exists. Semantic **siblings** (distinct observable laws) get their own package ([DS-027].2), marked *(sibling)*.

| Family (canonical front door) | Import | Access / use when |
|---|---|---|
| `Array<E>` | `Array Primitive` | O(1) random, O(n) insert; general-purpose growable sequence |
| `Fixed<E>` | `Fixed Primitive` | fixed-count sequence |
| `Stack<E>` | `Stack Primitive` | LIFO |
| `Queue<E>` | `Queue Primitive` | FIFO (ring buffer) |
| `Queue<E>.Linked` *(sibling)* | `Queue Linked Primitive` | linked-list FIFO; O(1) middle removal |
| `Queue<E>.DoubleEnded` *(sibling)* | `Queue DoubleEnded Primitive` | deque; push/pop from both ends |
| `List.Linked<E, N>` | `List Linked Primitive` | linked list; N=1 singly, N=2 doubly; O(1) positional insert/remove |
| `Dictionary<K: Hash.\`Protocol\`, V>` | `Dictionary Primitive` | unordered hash map; O(1) lookup/insert/remove |
| `Dictionary<K, V>.Ordered` *(sibling)* | `Dictionary Ordered Primitive` | insertion-ordered; O(n) removal |
| `Set<E: Hash.\`Protocol\`>` | `Set Primitive` | hash set; O(1) membership |
| `Set<E>.Ordered` *(sibling)* | `Set Ordered Primitive` | insertion-ordered hash set |
| `Bitset` | `Bitset Primitives` | integer-domain membership; packed bits (concrete by deliberate exception — [DS-028] N/A, no element axis) |
| `Heap<E: Comparison.\`Protocol\`>` | `Heap Primitive` | binary min-heap; priority queue (`Heap.MinMax` parked as a sibling) |
| `Slab<E>` | `Slab Primitive` | O(1) insert/remove; stable indices across mutations |
| `Tree<S>` | `Tree Primitive` | tree carrier; front doors `Tree<E>.N<n>` etc. are W2 aliases over the tree-n / tree-keyed COLUMN packages ([DS-028]) |
| `Graph` | `Graph Primitive` | algorithm namespace, not a container; operates on external reps via witnesses |
| `String` | `String Primitives` | owned null-terminated platform string; `~Copyable`, `@unchecked Sendable`; support types `.View`, `.Char`, `.Length` |

Selection flowcharts: [DS-010] (they select families, which are stable). Variant/alias inventory per family: the family's front-door files ([DS-028]).

**Cross-references**: [DS-002], [DS-010], [DS-025], [DS-027], [DS-028].

---

## Buffer Types (Tier 15)

### [DS-004] Buffer Selection

**Statement**: When a Collection type does not exist for your use case, or when you need direct mutation control, select from the six Buffer disciplines. Each discipline composes a specific Storage type.

| Discipline | Storage | Pattern | Backs |
|------------|---------|---------|-------|
| `Buffer.Linear<E>` | `Storage<E>.Heap` | Contiguous growable | Array, Stack, Heap, Dictionary.Ordered, Set.Ordered |
| `Buffer.Ring<E>` | `Storage<E>.Heap` | Circular FIFO/LIFO | Queue, Queue.DoubleEnded |
| `Buffer.Slab<E>` | `Storage<E>.Slab` | Sparse index-addressable | Slab, Dictionary |
| `Buffer.Linked<E, N>` | `Storage<Node>.Pool` | Pool-backed linked list | List.Linked, Queue.Linked |
| `Buffer.Slots<E, M>` | `Storage<E>.Split<M>` | Parallel metadata+element | Hash.Table |
| `Buffer.Arena<E>` | `Storage<E>.Arena` | Generation-token arena | Tree types |

**Import**: `Buffer_Primitives`

Each discipline offers the same variant pattern as Collections: `.Bounded`, `.Inline<N>`, `.Small<N>` where applicable.

**Additional byte-level buffers**:
- `Buffer.Aligned` — fixed-size aligned memory block (UInt8 only); ~Copyable
- `Buffer.Unbounded` — resizable byte buffer; configurable `Buffer.Growth.Policy` (struct with closure; factories: `.doubling`, `.factor(scale)`, `.exact`, `.pageAligned(alignment)`)

**Key associated types**:
- `Buffer.Ring.Checkpoint` — save/restore snapshot for ring buffers
- `Buffer.Arena.Position` — 8-byte handle (index:UInt32 + token:UInt32) for safe arena access

---

## Storage Types (Tier 14)

### [DS-005] Storage Selection

**Statement**: When building a new Buffer discipline or custom container, select the Storage type that matches the lifecycle management pattern. Storage handles element init/deinit tracking; you handle mutation logic.

| Type | Semantics | Lifecycle | Select When |
|------|-----------|-----------|-------------|
| `Storage<E>.Heap` | Reference (class) | Range-based auto deinit | Contiguous elements with tracked initialization ranges |
| `Storage<E>.Inline<N>` | Value, ~Copyable | Per-slot bitmap tracking | Stack-allocated; N <= 256; zero heap |
| `Storage<E>.Arena` | Reference (class) | Generation-token deinit | SoA layout; elements with generational tokens |
| `Storage<E>.Arena.Inline<N>` | Value, ~Copyable | Inline arena | Stack-allocated arena |
| `Storage<E>.Slab` | Reference (class) | Bitmap-driven deinit | Sparse elements with O(1) slot-level occupancy |
| `Storage<E>.Pool` | Reference (class) | Bitmap-tracked alloc | Fixed-capacity O(1) alloc/dealloc for uniform elements |
| `Storage<E>.Pool.Inline<N>` | Value, ~Copyable | Bitmap-scanned | Inline pool; no in-band free list |
| `Storage<E>.Split<Lane>` | Reference (class) | NO element deinit | Dual-array SoA; consumer manages element lifecycle |

**Import**: `Storage_Primitives`

`Storage.Initialization` — tracks initialized element ranges: `.empty`, `.one(Range)`, `.two(first:second:)`.

---

## Memory Types (Tier 13)

### [DS-006] Memory Layer Selection

**Statement**: Memory types provide raw allocation with no element lifecycle management. Use these only when building Storage-level or lower infrastructure. Consumer is fully responsible for initialization and deinitialization.

#### Allocators

| Type | Pattern | Select When |
|------|---------|-------------|
| `Memory.Allocator` | System malloc/free | General-purpose heap allocation |
| `Memory.Arena` | Bump allocator; O(1) alloc, bulk reset | Many short-lived allocations; no individual dealloc needed |
| `Memory.Pool` | O(1) alloc/dealloc; in-band free list | Fixed-capacity uniform-size slot allocation |

#### Buffers & Storage

| Type | Select When |
|------|-------------|
| `Memory.Buffer` / `.Mutable` | Raw byte buffer with non-null guarantee |
| `Memory.Inline<E, N>` | Raw fixed inline storage; no tracking; consumer manages lifecycle |

#### Alignment & Addressing

| Type | Purpose |
|------|---------|
| `Memory.Address` | Non-null memory address (Tagged ordinal); typed arithmetic |
| `Memory.Address.Offset` | Signed byte displacement |
| `Memory.Address.Count` | Byte count |
| `Memory.Shift` | Bit shift count (alignment exponent, 0-63) |
| `Memory.Alignment` | Power-of-2 alignment value |

**Import**: `Memory_Primitives`

---

## Bit-Level Types (Tiers 8-12)

### [DS-007] Bit-Level Selection

**Statement**: Select bit-level types based on the abstraction level needed.

| Type | Import | Select When |
|------|--------|-------------|
| `Bitset` | `Bitset_Primitives` | User-facing packed bit set; integer domain membership |
| `Bit.Vector` | `Bit_Vector_Primitives` | Infrastructure bitmap; occupancy tracking for Storage/Buffer |
| `Bit.Pack<Word>` | `Bit_Pack_Primitives` | Layout witness for bit field packing; not a container |

**Bitset vs Bit.Vector**: Bitset is the user-facing set type for integer domains. Bit.Vector is infrastructure used internally by Storage and Buffer types. Use Bitset for application logic; use Bit.Vector only when building containers.

---

## Foundations Types (Layer 3)

### [DS-008] Foundations Selection

**Statement**: Layer 3 types compose Layer 1 primitives with platform capabilities. Use these when the task requires OS integration, concurrency, or serialization.

| Type | Import | Select When |
|------|--------|-------------|
| `Memory.Map` | `Memory` | Memory-mapped file regions; safe mmap wrapper |
| `Pool.Blocking` | `Pool` | Thread-safe blocking resource pool; connection/worker pools |
| `Async.Stream<E>` | `Async` | Composable async sequences with operators |
| `IO.Event.Channel` | `IO` | Non-blocking I/O; socket operations |
| `JSON` | `JSON` | JSON value type (wraps RFC_8259.Value) |
| `XML` | `XML` | XML element representation |
| `Plist` | `Plist` | Property list value type |
| `Path` | `Path` | Filesystem path; Copyable, Sendable, Hashable |

---

## Supporting Infrastructure

### [DS-009] Index and Tagging Types

**Statement**: These types are not containers but are used pervasively by data structures for type-safe access.

| Type | Import | Purpose |
|------|--------|---------|
| `Index<E>` | `Index_Primitives` | Phantom-typed index for type-safe collection access |
| `Index<E>.Offset` | | Typed signed displacement |
| `Index<E>.Count` | | Typed element count |
| `Tagged<Tag, Value>` | `Affine_Primitives` | Phantom-typed value wrapper; base for Index, Memory.Address |
| `Hash.Value` | `Hash_Primitives` | Typed hash value |
| `Hash.Protocol` | `Hash_Primitives` | ~Copyable-compatible hashing protocol |
| `Hash.Table<E>` | `Hash_Table_Primitives` | Open-addressed hash table; backing for Dictionary/Set (not standalone) |
| `Property<Tag, Base>` | `Property_Primitives` | CoW-safe mutation namespace |
| `Property<Tag, Base>.View` | | Pointer-based view for ~Copyable borrowed/consuming access |

---

## Decision Trees

### [DS-010] Container Selection Flowcharts

**Statement**: Use these decision trees to select the appropriate container type. After selecting the type, apply [DS-002] to choose the right variant.

**Sequential container**:
```
Need random access?
  Yes → Array<E>
  No  → Need ordering constraint?
    LIFO → Stack<E>
    FIFO → Need O(1) middle removal?
      Yes → Queue<E>.Linked
      No  → Queue<E>              (ring buffer)
    Both ends → Queue<E>.DoubleEnded
    Positional insert/remove → List.Linked<E, N>
```

**Associative container**:
```
Key-value pairs?
  Yes → Need insertion ordering?
    Yes → Dictionary<K, V>.Ordered  (linear-backed, O(n) remove)
    No  → Dictionary<K, V>          (slab-backed, O(1) remove)
  No (membership only) → Integer domain?
    Yes → Bitset                     (packed bits, no hashing)
    No  → Set.Ordered<E>            (hash set, insertion-ordered)
```

**Stable-index / arena container**:
```
Need use-after-free detection?
  Yes → Buffer.Arena<E>  (generation tokens via Position)
  No  → Slab<E>          (O(1) insert/remove, stable indices)
```

**Common naming confusion**: Code that self-describes as a "slab allocator" often implements a LIFO free-list with generation tokens — this is `Buffer.Arena`, not `Buffer.Slab`. `Buffer.Slab` is bitmap-tracked (`firstVacant()`, O(word) allocation) with no generation tokens. Always match by algorithmic requirements (free-list? generation tokens? O(1) alloc/dealloc?), not by the label in comments.


**Priority container**:
```
Need both min and max?
  Yes → Heap<E>.MinMax
  No  → Heap<E>
```

**Tree container**:
```
Key-indexed?  → Tree.Keyed<K>
Bounded arity? → Tree.N<E, n>  (Tree.Binary = Tree.N<2>)
Variable arity? → Tree.Unbounded<E>
```

**Memory allocator**:
```
Bulk reset, no individual dealloc?  → Memory.Arena
Fixed-capacity O(1) alloc/dealloc? → Memory.Pool
General-purpose?                    → Memory.Allocator
```

**Building a new container**:
1. Pick a Storage discipline → [DS-005]
2. Compose into a Buffer with Header → [DS-004]
3. Build Collection API on top → [DS-003]

---

### [DS-020] Gate Before Proposing a New Ecosystem Primitive

**Statement**: When a recommendation involves ADDING an ecosystem primitive (Memory, Storage, Buffer, or Collection layer), the ecosystem-data-structures skill MUST be consulted first. The catalog plus composition over existing primitives MUST be demonstrated not to cover the use case before a new primitive is proposed.

**Procedure**:

1. Before any proposal for a new primitive is written, consult the full data-structures inventory.
2. Attempt a composition over existing primitives; if composition is feasible, that is the answer.
3. If composition is not feasible, document precisely why — which property the composition lacks, which use case requires the missing property, which existing primitive would need to extend to cover it.
4. Only after steps 1-3 does the proposal for a new primitive proceed; the composition-attempt is part of the proposal's evidence.

**Cross-reference**: The research-process skill's `[RES-018] Cross-Cutting Primitive: Compose-First Justification` is the research-side rule (requiring a demonstration that composition of existing primitives fails before a new cross-cutting primitive is proposed); this gate is the skill-consultation-side rule. Both should fire for data-structure proposals, which are typically case (a) cross-cutting by nature. Neither keys on consumer count — the question is whether composition of the existing catalog covers the use case, decided structurally. Case (b/c/d) carve-outs in `[RES-018]` (domain-owned vocabulary, layer-agnostic pull-down, spec-mirroring) do not bypass this consultation step — even within a carve-out, the inventory check is still cheap and still load-bearing.

**Rationale**: New primitives have long tails (maintenance surface, review cost, decision fork for future designers). The skill-consultation-first discipline catches proposals that composition of the existing catalog already covers, at the moment they're cheapest to redirect — before any research is written and any implementation starts.


**Cross-references**: [RES-018]

---

### [DS-021] Institute Containers Pass `~Copyable` Through; stdlib `Array<Element: Copyable>` Is Not the Operative Constraint

**Statement**: When evaluating whether a container shape is expressible for a `~Copyable` or `~Escapable` element type, the Swift stdlib's constraint set MUST NOT be the framing. The institute container catalog covers `~Copyable` elements out of the box — base variants are `~Copyable`; `Copyable` is gained conditionally when `Element: Copyable`. Falling back to `[Swift.String]` (or any stdlib Array workaround) on the basis of stdlib's `Element: Copyable` constraint while the institute provides `Array_Primitives.Array<E>` etc. is FORBIDDEN. Reasoning like "Array<Path> doesn't work because Path is `~Copyable`, so use [String] and document a typed-system gap" is rooted in stdlib reflex, NOT in any institute ecosystem gap.

**Container catalog (all support ~Copyable elements; base / `.Fixed` / `.Bounded` via the conditional-Copyable pattern, `.Static` / `.Small` as unconditionally `~Copyable`)**:

- `Array_Primitives.Array<E>` (base `~Copyable`; `Copyable when Element: Copyable`)
- `Stack_Primitives.Stack`, `Queue_Primitives.Queue`, `Set_Primitives.Set.Ordered`, `Dictionary_Primitives.Dictionary`, `Heap_Primitives.Heap`, `Slab_Primitives.Slab`, `Tree_Primitives.Tree.*`, `List_Primitives.List.Linked` (same shape)
- Static-capacity variants (`.Static<N>`, `.Small<N>`) are unconditionally `~Copyable` — the by-design `deinit ⟹ ~Copyable` law (SE-0427; [MEM-COPY-016]), not a passing compiler limitation
- `.Bounded` and `.Fixed` heap-backed variants follow the same conditional-Copyable pattern

**Decision axis** — data-shaped vs resource-shaped, NOT "can stdlib Array hold this?":
- Resource-shaped values (FDs, locks, view-borrowed memory) want `~Copyable` → use institute container
- Data-shaped values (config values, pure transforms, JSON-serialized fields) are happy with `Copyable` → stdlib `[CopyableT]` (e.g., `[File.Path]`) is fine

**How to apply**:
1. At every "is X expressible?" check, frame as: "what institute container does this — `<Name>_Primitives.<Container>`?" before reasoning about stdlib constraints.
2. If the right answer is `~Copyable` ownership semantics for the elements, use `Array_Primitives.Array<E>` (or analog). DO NOT fall back to `[Swift.String]`.
3. Reference `[DS-002]` / `[DS-003]` for the full catalog before any "the typed system has a gap here" claim.


**Cross-references**: [DS-002], [DS-003], [MEM-COPY-001]

---

### [DS-022] `stdlib.ManagedBuffer` Is Vestigial; Direct Use Is the Right Interim Choice

**Statement**: `stdlib.ManagedBuffer<Header, Element>` is treated as VESTIGIAL in the Swift Institute primitives ecosystem. The long-term aim is to replace its uses with native ecosystem primitives, but the replacement primitive does NOT yet exist and the migration is a substantial separate effort. Until the replacement lands, direct `ManagedBuffer<H, E>` use is the right interim choice — the SAME pattern stdlib uses internally (`_ContiguousArrayStorage` in `ContiguousArrayBuffer.swift`).

**Why**: The ecosystem aims to be self-contained on native primitives where possible. `ManagedBuffer` is the last load-bearing stdlib primitive in the storage layer; replacement requires a new `swift-memory-primitives`-layer typed-tail-allocated-memory primitive plus migration of all four Storage disciplines (`Storage<E>.Heap`, `.Pool`, `.Split`, `.Arena`) and ad-hoc consumers. The replacement project is unscoped; until it lands, wrapping `ManagedBuffer` in a new Storage primitive that just adds ceremony is the "premature primitive" trap (per `[DS-020]`).

**How to apply**:
- When a consumer needs typed tail-allocated heap memory and no Storage discipline fits (e.g., concurrent collections like Chase-Lev), recommend `ManagedBuffer<H, E>` directly per stdlib precedent. Do NOT propose new Storage primitives that wrap ManagedBuffer with extra ceremony.
- Document any new direct-`ManagedBuffer` use as a known vestigial choice to address when the ecosystem-wide replacement happens.
- If a project arises to define the replacement primitive, it warrants its own research note in `swift-memory-primitives/Research/`.


**Cross-references**: [DS-005], [DS-006], [DS-020]

---

### [DS-023] Occupancy Lives in the Leaf — No Discipline Forces a Carve-Out

**Statement** (CORRECTED 2026-06-07 — `swift-institute/Research/occupancy-lives-in-the-leaf.md`): liveness + teardown live in the **single-allocation leaf**, never in the buffer. This holds for inline (`@_rawLayout`) and heap, dense and sparse alike, so **every** `Buffer.<discipline>` is one pure-generic type with **no element `deinit`**:

- **Dense-occupancy** (`Buffer.Linear` / `Buffer.Ring`): the leaf's range-ledger (`Storage.Initialization`) *is* the occupancy; the leaf `deinit` tears down; the buffer dissolves to `Storage.Contiguous<Memory.Inline>` (cond-`Copyable` when `Element: Copyable`).
- **Sparse-occupancy** (`Buffer.Slab` / `Buffer.Linked` / `Buffer.Arena`): the occupancy oracle (bitmap / generation / free-list) lives in a single-allocation **sparse leaf** — heap: class-backed → cond-`Copyable`; inline: `@_rawLayout` → move-only — so the leaf `deinit` tears down and the buffer is again a thin no-`deinit` generic. `Storage.Arena` already ships this shape. The carve-out **dissolves**; the inline leaf is move-only but the *type* is not separate.

**Selection**: never reach for a concrete `.Inline`/`.Small` *buffer* type — pick the leaf (heap/inline/small × the discipline's occupancy) and compose the one generic buffer. (`.Bounded` is a separate, already-lawful *capacity* axis — retained, not a carve-out.) Cross-package consumers of any inline discipline heed the `swift#86652` / [MEM-SAFE-027] caveat (a codegen issue, orthogonal to this rule).

**Rationale**: occupancy *placement* — not its shape — was the error. The prior text ("sparse occupancy lives at the buffer → a concrete `.Inline` variant is forced") took buffer-held occupancy as a given; the bug was holding occupancy in the buffer (e.g. `Bit.Vector` in `Buffer.Slab`'s header, `Slab.swift:57-58`). Move it to the leaf, where dense already keeps it, and nothing is forced.


**Cross-references**: [DS-002], [MEM-COPY-016] (the Wall-1 law + converged equilibrium), [MEM-SAFE-027] (the Wall-2 cross-package caveat); *(pending — Strata→modularization track)* [MOD-PLACE].

---

### [DS-024] The Seam-Ledger Laws Bind Every ADT Column

**Statement**: A type conforming to BOTH `Store.Protocol` and `Buffer.Protocol` that is consumed as an ADT storage column (`Array<S>` and successors) MUST maintain the seam-ledger contract — `initialize(at:to:)` increments `count` by one; `move(at:)` decrements it by one; the element subscript leaves it unchanged; none of the three changes `capacity` — and MUST prove it by running the laws from its own test suite:

```swift
let violations = Seam.Ledger.violations(
    makeEmpty: { MyColumn(minimumCapacity: Index<Int>.Count(4)) },
    element: { $0 }
)
#expect(violations.isEmpty, "\(violations)")
```

(`Seam.Ledger` lives in `Buffer Primitives Test Support`, swift-buffer-primitives.)

**Why**: the ADT tier's column-GENERIC mutations (the remove-shift dance, `drain`, `removeLast`) are count-driven through the seam — each `move` must self-account so the loops terminate and the end state is a consistent empty/shifted column. The `Array<S>` bound (`Store.Protocol & Buffer.Protocol`) cannot express this; a conformer that satisfies both protocols WITHOUT ledgering corrupts silently. The laws make the untypeable contract mechanically checked.

**How to apply**: when a new column lands (or an existing type gains the second conformance), add the one `violations` test before wiring it into any ADT. Self-gating CoW columns (`Shared`) pass identically — the gate inside the seam ops must not disturb the ledger.


**Cross-references**: [DS-021], [DS-023]; **memory-safety** [MEM-SAFE-028] (the drain-box rule — the box's drain runs over a ledger-honest buffer).

---

## The Decoupling Charter (the canonical ADT shape)

> Single source of truth for how every tower container sits on its storage column.
> RATIFIED 2026-07-02 — `Research/adt-tower.md` is the rationale companion (§2 D1–D8 design,
> §4 rule text, §3 walls table). Supersedes the 2026-06-18 PROVISIONAL V2 revision (the
> ride-the-buffer premise); built on the `cross-layer-capability-protocol-model` backbone
> (minimal orthogonal cores, KEPT). The storage-generic (V1) and ride-`Buffer.\`Protocol\``
> (V2) premises survive in git history and adt-tower.md §8 only.

### [DS-025] The Canonical ADT Shape

**Statement**: Every tower container is a thin **carrier** `struct __X<S: ~Copyable>: ~Copyable`
— hoisted per [API-IMPL-009]/[PKG-NAME-006] — generic over exactly one parameter, its storage
**column** (the composed buffer stack, a storage-direct identity-geometry discipline, or
`Shared<Element, _>` over one), with the parameter bound `~Copyable` **only**: no
capability-protocol bound on the type, direct or inherited.

- Capabilities attach by **conditional extension** keyed on what the column conforms:
  observability and slot ops over `where S: Store.\`Protocol\` & Buffer.\`Protocol\`` (plus
  `S.Count == Index<S.Element>.Count` where the element-domain count is needed); construction
  and growth by allocation-generic pins per [DS-029]; every extension restates `where S: ~Copyable`.
- The public spelling of the family is its **front doors** per [DS-028]; the carrier's hoisted
  name never appears in consumer signatures or `throws` clauses ([API-ERR-007]).
- Every hoisted carrier AND hoisted seam protocol carries `@_documentation(visibility: public)`:
  symbolgraph-extract's underscore filter otherwise drops the entire family API from DocC
  (panel-measured: the worked example's symbol graph = 1 orphan alias, 0 relationships; the
  attribute restores the full graph on the exact carrier shape). DocC curation makes the
  front-door alias page the family landing page. The same hole is LIVE on today's hoisted seam
  protocols (`__StoreProtocol` extracts 0 symbols) — a §9.6 sweep item.
- Conformance chains flow from the column: `extension __X: Copyable where S: Copyable`;
  `extension __X: Sendable where S: Sendable & ~Copyable`; semantic conformances
  (`Equatable`, …) key on `S:` bounds, never on same-type pins ([MEM-COPY-018]).
- `__X<S>` additively conforms its own consumer protocol
  (`extension __X: X.\`Protocol\` where S: …`); the column never conforms `X.\`Protocol\``.
- **Every public seam-generic and column-pinned operation is `@inlinable`** (over the
  `@usableFromInline package` column). This is load-bearing, not style: the tower's topology
  puts generic ops in the library and concreteness in the consumer, so cross-module
  specialization exists only through serialized bodies — the panel measured the §4.1 exemplar
  WITHOUT `@inlinable` at 90.33 vs 0.126 ns/op per element read (714×) from a concrete
  front-door client, with 29 `witness_method` sites in the middle-module SIL.
- Element accessors are `_read`/`_modify` coroutines per [API-IMPL-021]; carriers are `@frozen`
  per [API-IMPL-022]; carriers carry **no `deinit`** (teardown lives in the leaf, [DS-023]).
- Escapability: capability protocols suppress `~Escapable`; carriers stay `Escapable` until the
  recorded trigger (first nonescapable column, or un-flagged `@_lifetime`) — the widening is
  non-breaking.

**Correct**:
```swift
@frozen public struct __Array<S: ~Copyable>: ~Copyable {
    @usableFromInline package var column: S
    @inlinable public init(column: consuming S) { self.column = column }
}
extension __Array: Copyable where S: Copyable {}
extension __Array where S: ~Copyable, S: Store.`Protocol` & Buffer.`Protocol`,
    S.Count == Index<S.Element>.Count {
    @inlinable
    public subscript(_ i: Index<S.Element>) -> S.Element {
        _read { yield column[i] }
        _modify { column.unshare(); yield &column[i] }
    }
}
extension __Array: Array.`Protocol` where S: Store.`Protocol` & Buffer.`Protocol` {}
```

**Incorrect**:
```swift
public struct Array<S: Store.`Protocol` & Buffer.`Protocol` & ~Copyable>  // ❌ bound ON the type
public struct Stack<Element: ~Copyable>                                   // ❌ no column axis (variant = new type)
extension Array where B: Buffer.`Protocol` { subscript … }                // ❌ element ops on the observability seam (the seam has none)
```

**Classification**: **BREAKING** — replaces the 2026-06-18 text (the PROVISIONAL V2 ride-the-buffer premise is superseded). RATIFIED 2026-07-02 per the collaboration protocol (Research/adt-tower.md — the acceptance criterion that no design decision arises mid-flight).

**Status**: RATIFIED 2026-07-02 (`Research/adt-tower.md`; the tree-core real-upstream validation the 2026-06-18 revision parked on is discharged by `Experiments/adt-tower-worked-example` — real columns, cross-module, 0-witness). The storage-generic (V1) and ride-`Buffer.\`Protocol\`` (V2) premises survive in git history and adt-tower.md §8 only.

**Rationale**: One carrier shape at the ADT tier — a reader who learns `__Array` understands every family. Putting the bound on the capability *extensions* (not the type) is composition, not refinement (the **cross-layer-capability-protocol-model** backbone); the single column axis is what makes variants aliases rather than new types ([DS-028]).


**Cross-references**: [DS-001], [DS-004], [DS-023], [DS-026], [DS-027], [DS-028], [DS-029]; **cross-layer-capability-protocol-model**; **memory-safety** [MEM-COPY-016], [MEM-COPY-018]; **code-surface** [API-IMPL-009], [API-IMPL-021], [API-IMPL-022], [API-IMPL-023].

---

### [DS-026] The Conformance Predicate

**Statement**: Whether a family meets [DS-025] MUST be decided mechanically. The predicate:

| Part | Test |
|------|------|
| (a) | the carrier's column parameter is bound `~Copyable` only — no capability-protocol bound, direct or inherited from a parent namespace |
| (b) | capability extensions constrain seams/pins on `S` itself; no extension re-suppresses or reaches through nested associated types |
| (c) | a canonical front-door alias exists, and every variant alias in the family resolves to the same carrier ([DS-028]) |
| (d) | no two op extensions differ only in the Memory leaf of their column pins (the allocation-generic check, [DS-029]) |

Every family is in exactly one state: **at-target** (a–d hold) · **carrier-only** (a–b hold;
front doors or op generalization pending) · **legacy** (a fails: bound-on-type, or no column
axis at all). D8 adds (e) — every public tower op `@inlinable`, every hoisted decl
`@_documentation(visibility: public)` — to the at-target bar. The predicate is encoded in
`Scripts/adt-decoupling-classify.py` (re-pointed at wave W0, §9.1, with a fresh ledger; the
embedded 2026-06-18 V1-axis LEDGER is void). Its (a)-DIRECT slice was AST-promoted at wave W4
(2026-07-06, partial — see **Enforcement**); the remaining parts stay script-enforced by the
classifier.

**Classification**: **BREAKING** — replaces the 2026-06-18 predicate and its three-shape taxonomy (at-target/foundational/concrete). RATIFIED 2026-07-02 per the collaboration protocol.

**Status**: RATIFIED 2026-07-02. The three-shape taxonomy (at-target / foundational / concrete) is superseded by the three states above; the 2026-06-18 census (2/9/10) remains historically correct against the old predicate.

**Rationale**: Eyeballed classification varies between sessions; a mechanical predicate removes the judgment that drift feeds on. The re-pointed classifier's regenerated ledger (2026-07-02) records the pre-reshape tree as 3 carrier-only (`Buffer`, `List.Linked`, `Tree`), 17 legacy, 2 n-a; each W1/W2 package flips its entry to at-target at gate-pass.


**Enforcement**: Partially mechanical (W4 partial promotion, /promote-rule 2026-07-06). Predicate part
**(a)-DIRECT** — a public tower CARRIER (hoisted `__X`, or rooted in an ADT-family namespace) whose
column parameter `S` carries a capability-protocol bound (`Store`/`Buffer`/`Storage.\`Protocol\``) ON
THE TYPE, inline (`<S: …>`) or in the type's own `where` clause — is AST-enforced by
`Lint.Rule.Tower.CarrierColumnBound` (primitives tier, `Primitives Linter Rule Tower` pack;
`Bundle.primitives`; `.warning`). Capability bounds on EXTENSIONS are the lawful
[DS-025] form and are never visited. The remaining predicate surface stays enforced by
`Scripts/adt-decoupling-classify.py` (TEXT/script) — beyond a single-file AST rule: the INHERITED
cross-package half of (a) (parent-namespace bound resolution), (b) associated-type reach-through
(semantic), (c) front-door existence + resolves-to-carrier (whole-package + cross-file), (d) the
pairwise Memory-leaf op-extension comparison ([DS-029], with the lawful Pool/Generational/`Store.Split`
heap-pin carve-outs), and (e) `@inlinable`/`@_documentation(visibility: public)` (adjacent, [API-IMPL-022]/
[API-IMPL-023] track). Discipline: `Audits/PROMOTE-DS-026-2026-07-06.md`. [VERIFICATION: AST (partial) + Script]

**Cross-references**: [DS-002], [DS-004], [DS-025], [DS-027], [DS-028], [DS-029]; **memory-safety** [MEM-COPY-018]; **swift-linter** (the lint encoding).

---

### [DS-027] The Packaging Law

**Statement**:
1. **Canonical-in-main** *(unchanged)*, with a target-placement rider: `swift-X-primitives`
   holds the canonical family — the hoisted carrier, seam-generic ops, the canonical front
   door, and ALL allocation/capacity/ownership **variant aliases** (one file each per
   [API-IMPL-005]/[API-IMPL-006]). A variant alias whose column LEAF is NOT already in the
   canonical target's product closure (`Small` → Memory Small Primitives; `Inline` → Store
   Inline Primitives) lands in **its own variant target + product** within the package
   ([MOD-031]; the array manifest already scaffolds the "Small type/ops/variant" MARKs),
   umbrella-re-exported per [MOD-005] — so heap-only consumers keep a lean dependency graph
   (panel-measured: the in-target shape would push +2 packages onto 7 consumers that never
   spell `Small`).
2. **One-sibling-per-package** *(amends "one-variant-per-package")*: a semantic SIBLING — a
   family member with distinct observable laws (`Set.Ordered`, `Queue.DoubleEnded`,
   `Queue.Linked`, `Dictionary.Ordered`, tree columns) — lives in its own
   `swift-X-Y-primitives`. A **variant** — a column point differing only in the three free
   axes (allocation, capacity, ownership) — is an alias in the canonical package and MUST NOT
   get a package. Discriminator: the ordered D4.1 test (same carrier re-parameterized along
   the free axes, same op layer modulo the [DS-029] decreed forms ⇒ variant; anything else —
   discipline, key/order model, end-surface — ⇒ sibling).
3. **One storage-seam package** *(unchanged)*: `swift-storage-primitives` (seam target minimal,
   index-only deps; `Storage.Contiguous` concrete) + `swift-storage-generational-primitives`
   (the sparse generational discipline). No refinement tiers between seam and concrete
   (`Store.Ledgered` is the capped single exception, Round-C review inherited).

**Classification**: **BREAKING** — clause 2's re-wording (one-variant-per-package → one-sibling-per-package; variants become in-package aliases). RATIFIED 2026-07-02 per the collaboration protocol.

**Status**: RATIFIED 2026-07-02 (clause 2's re-wording is the only change to the principal-ratified 2026-06-18 law; its examples were all siblings already).

**Rationale**: Variants are column points, not new packages — the alias mechanism (inexpressible before 6.3.3) collapses the per-variant package proliferation the old law implied; siblings (distinct observable laws) still get their own package.


**Cross-references**: [DS-002], [DS-005], [DS-025], [DS-028], [DS-029]; **swift-package** [PKG-NAME-*]; **modularization** [MOD-005], [MOD-031].

---

### [DS-028] The Variant Algebra and Front-Door Aliases

**Statement**: A variant is a **point in column space** along the three FREE axes — allocation
placement (Memory leaf / `Store.Inline` leaf), capacity contract (buffer `Bounded`, typed
`Overflow` as the decreed op form), and ownership (`Shared`) — the DISCIPLINE being a frozen
per-family coordinate (a different discipline is a sibling family, [DS-027].2). A variant is
declared as a **typealias**, never a hand-written type:

- The **canonical** family member is a top-level generic-instantiation alias pinning the default
  column: `public typealias X<E: ~Copyable> = __X<Buffer<Storage<Memory.Allocator<Memory.Heap>>.Contiguous<E>>.D>`.
- Every **variant** is a constrained nested alias on the carrier, `Element` inherited from the
  member it is named on — spelled `X<E>.Small<n>`, `X<E>.Inline<n>`, `X<E>.Bounded`,
  `X<E>.Shared` per [API-NAME-001] (variant labels nest) — under the THREE ALIAS LAWS:
  axis-CHANGING aliases (allocation) constrain to the `Direct` marker (cross-axis chains
  error instead of silently resetting an axis); axis-ADDING aliases are column-preserving
  transformers (`Shared` wraps `S`; `Bounded` maps the capacity-twin associated type); every
  alias doc comment states the units rule (`Small<n>` = bytes, `Inline<n>` = element count).
- Which variants exist per family is **consumer-pulled**; pulling one costs one alias file.
  Conformances, inits (including value-generic pins), and `~Copyable` elements flow through the
  alias chain with zero forwarding code and zero runtime cost (0 `witness_method`, verified).
- Semantic siblings are NOT variants and NOT aliases ([DS-027].2).
- `.Indexed<Tag>` remains NOT a variant (the tagged-collection rule stands).

**Classification**: **Additive** — NEW rule; governs future variant declarations. RATIFIED 2026-07-02.

**Status**: RATIFIED 2026-07-02. The mechanism was inexpressible before 6.3.3 (the namespaced/value-generic alias SIGSEGV, §3 W4) — hence the interim dissolution doctrine, whose algebra this rule keeps and whose missing names it restores.

**Rationale**: the alias IS the sanctioned [API-NAME-004] generic-instantiation exception; front-door aliases are the Swift-shaped equivalent of Rust's `A = Global` default type argument (permanently unavailable — no default generic arguments, §3 W10).


**Cross-references**: [DS-025], [DS-026], [DS-027], [DS-029]; **code-surface** [API-NAME-001], [API-NAME-004], [API-IMPL-005], [API-IMPL-006].

---

### [DS-029] Allocation-Generic Operation Pins

**Statement**: Tower operations MUST NOT hardcode a Memory leaf. Three op forms exist, in order
of preference:

1. **Seam-generic** (`where S: Store.\`Protocol\` & Buffer.\`Protocol\``): any op expressible
   over slot transitions + count — removal, in-place mutation, observation. CoW-correct via
   `unshare()` before the first write. Covers every column including `Shared`.
   **Gate discipline (M3, 2026-07-03)**: a public mutating op calls `unshare()` EXACTLY ONCE,
   at entry, before its first write; seam-generic HELPERS (`exchange`, `siftUp`, `siftDown`, …)
   NEVER gate and MUST carry the gating precondition in their doc comment ("caller must have
   gated `unshare()`"). Double-gating and an un-gated helper write are both defects.
   (`unshare()` is the [DS-025] seam requirement renamed from `prepareForMutation()` — the
   rename shipped as one lockstep arc, rule text + this rider + the code sweep, W1.6
   2026-07-05; anything still spelling the old name is a defect. Rationale:
   `Research/adt-tower.md` §4.5/§10.1.)
2. **Allocation-generic pin** (`where S == Buffer<Storage<Memory.Allocator<R>>.Contiguous<E>>.D, R: Memory.Growable & ~Copyable`):
   ops needing the column's own surface (construction, growth). One extension covers heap AND
   small; `Memory.Inline` correctly falls outside (`Memory.Growable` is the fence). Bounded
   columns take the same shape with the bounded discipline + `throws(Overflow)`.
3. **Ownership twin** (`where S == Shared<E, …>`): one thin gate-twin per column-surface op
   (`store.withUnique { … }`) — only for ops form 1 cannot express.

All three forms are `@inlinable` ([DS-025]'s visibility requirement — the specialization
property is body-visibility-conditional, not automatic).

A `Memory.Heap`-hardcoded pin where `R: Memory.Growable` suffices is a defect (the [DS-026](d)
check). Buffer-tier public ops follow the same law (`Buffer.Linear.append` is the shipped
exemplar; ring/slab/linked heap-pinned ops are wave-W3 migration items, §9.1).

**ADT Tower rider — `Overflow` is a stand-in token (M10, ratified 2026-07-03; transcribed at W4, 2026-07-06).**
The bounded op form spelled `throws(Overflow)` in form 2 above (and in [DS-028], [DS-002]) denotes
each family's OWN nested error type — `X<E>.Bounded.Error` with a `.full` case, the LANDED per-family
shape (`Queue+Columns.swift:62,75`, `Queue.Bounded.swift:29`) — NOT a shared tower-wide `Overflow`
type (which never landed). Keep per-family nested `Error`; read `Overflow` throughout as a stand-in
for that per-family error. Provenance: `Research/adt-tower.md` §4.7.

> **Scope note — form 2 is Contiguous-only (seat ruling 2026-07-06, P3; principal-reversible; transcribed at W4).**
> Form 2 (the allocation-generic pin) is DEFINED for the Contiguous storage path only. The
> Pool/Generational path's generalization form is UNDEFINED pending the chartered generational/pool
> design leg. `Storage.Generational`'s create/grow/clone are `Allocation == Memory.Allocator<Memory.Heap>.Pool`
> concrete (`Storage.Generational.swift:274`, `+lifecycle.swift:107,:47`) and the self-allocating pool
> init is `Resource == Memory.Heap` by dependency-inversion design (`Memory.Heap+Memory.Allocator.swift:50`) —
> those concrete heap pins are LAWFUL (the defect clause fires only where `R: Memory.Growable` suffices).
> Same class: ownership-shared's heap-pinned wrapping inits (`Shared+Ring.swift:31/47`). The two-lane
> `Store.Split` (Slots) pin form is likewise undefined pending the leg. Mirrors `Research/adt-tower.md` §4.5.

**Classification**: **Additive** — NEW rule; governs future op pins. RATIFIED 2026-07-02.

**Status**: RATIFIED 2026-07-02. `Buffer.Linear.append` ships the pattern; `swift-json` consumes it over `Memory.Small<24>` in production.

**Rationale**: hardcoding `Memory.Heap` where `Memory.Growable` suffices forces a per-leaf op duplication the column algebra exists to avoid; the growable fence covers heap + small in one extension while correctly excluding inline.


**Cross-references**: [DS-025], [DS-026], [DS-028]; **memory-safety** [MEM-SAFE-028]; **modularization** [MOD-PLACE], [MOD-PLACE-DECOMPOSE].

---

### [DS-030] Iteration Flows From the Column (Borrowing `forEach`)

**Statement**: The ADT tier defines NO iteration of its own. A tower container is iterable exactly
when its column vends borrowing iteration; iteration **flows from the column** — composed over the
buffer-tier surface, never re-implemented per family. The guaranteed common surface is a **borrowing
`forEach`** lending `(borrowing S.Element)` — the one surface every occupancy discipline provides
(0-witness cross-module, spike-verified for both Linear and Ring over a move-only element).

- **Borrow/consume boundary**: a `~Copyable` column is **borrow-iterable only**; the consuming
  `Sequenceable` path is `Element: Copyable`-gated on both Linear and Ring. A move-only element can
  be borrow-iterated but never consume-iterated (consuming iteration would move each element out —
  structurally unavailable). This mirrors the `min`-vs-`pop` boundary ([DS-025]; **code-surface**
  [API-NAME-008] M5): a `~Copyable` borrow of `Element?` is structurally unavailable.
- **Multipass `Iterable` is Linear-only**: Linear ALSO vends the multipass `Iterable` protocol
  (element gate relaxed to `~Copyable`); Ring vends ONLY the single-pass borrowing `forEach` — its
  multipass `Iterable` side was active-pruned (seat-ruled 2026-06-10). A family MUST NOT claim
  multipass `Iterable` unless its column vends it (Linear yes; Ring no, until a borrowing segment
  iterator lands). A family's iteration surface is READ FROM its column, never declared at the ADT tier.

**W1.9 reconciliation (seat-ruled 2026-07-05/06; principal-reversible)**: "the ADT adds no iteration
machinery" binds CONTRACT claims (no `Iterable`/`Sequenceable` the column does not vend) and walk
SEMANTICS (the ADT walk must match the column's documented order) — it does NOT forbid a seam-generic
borrowing `forEach` written once over `Store.\`Protocol\` & Buffer.\`Protocol\``, which is a
[DS-029]-form-1 op covering every conforming column with one method.

**Classification**: **Additive** — NEW rule; governs future tower iteration surfaces. Transcribed at
W4 (2026-07-06) from the ratified D9/M11 rider.

**Cross-references**: [DS-025], [DS-028], [DS-029]; **code-surface** [API-NAME-008] (the `min`/`pop`
borrow/consume boundary).

---

## Cross-References

- **existing-infrastructure** skill for typed operators, boundary overloads, and Standard Library Integration modules
- **memory-safety** skill for ~Copyable ownership, Sendable, and lifecycle rules
- **conversions** skill for Index<T>, Offset, Count arithmetic
- Research: `swift-institute/Research/ecosystem-data-structures-inventory.md` (full inventory with provenance)
- Research: `swift-institute/Research/comparative-*.md` (per-package deep dives against swift-io usage)
- Research: `swift-institute/Research/storage-buffer-abstraction-analysis.md` (Storage/Buffer design rationale)
