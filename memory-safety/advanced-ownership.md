# Memory Safety — Advanced Ownership Techniques

Part of the **memory-safety** skill. See `SKILL.md` for the navigation hub, frontmatter, and rule index.

Full rationale, provenance, extended worked examples, and the dated changelog: `swift-institute/Research/memory-safety-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MEM-COPY-010], [MEM-COPY-011], [MEM-COPY-012], [MEM-COPY-013], [MEM-COPY-016], [MEM-COPY-017], [MEM-COPY-018], [MEM-COPY-019], [MEM-LIFE-001], [MEM-OWN-010], [MEM-OWN-011], [MEM-OWN-012], [MEM-OWN-013], [MEM-OWN-014], [MEM-OWN-016], [MEM-OWN-017], [MEM-OWN-018].

---

## Ownership Techniques

### [MEM-COPY-010] Noncopyable Workarounds for Associated Types

**Statement**: When Swift doesn't support `associatedtype T: ~Copyable`, use `Reference.Box<T>` as a workaround.

---

### [MEM-COPY-011] Two-World Separation for Owned and Borrowed Types

**Statement**: When a type has both owned (escapable) and borrowed (`~Escapable`) variants with fundamentally different properties, they MUST be represented as separate types with separate protocol conformances — not unified through abstraction.

**The Constraint Triangle** (Swift 6.x) — three desirable properties cannot all be satisfied:
1. Reuse existing protocol infrastructure
2. Keep borrowed type `~Escapable` (compile-time lifetime safety)
3. Keep zero-copy parsing

| World | Prioritizes | Sacrifices | Use Case |
|-------|-------------|------------|----------|
| **Owned** | (1) + combinator reuse | (2) compile-time safety | Cross-task transfer, recursive structures |
| **Borrowed** | (2) + (3) zero-copy | (1) separate protocol | Maximum performance, scoped parsing |

**Correct** — two separate protocols:
```swift
public protocol Parser<Input, Output, Failure> {
    associatedtype Input  // Must be Escapable (language limitation)
    func parse(_ input: inout Input) throws(Failure) -> Output
}

extension Binary.Bytes {
    public protocol Parser<Output, Failure> {
        mutating func parse(_ input: inout Input.View) throws(Failure) -> Output
    }
}

// Bridge for cross-world reuse
struct Bridge<P: Parsing.Parser>: Binary.Bytes.Parser { ... }
```

**Incorrect** — forcing unification:
```swift
public protocol Parser<Input, Output, Failure> {
    associatedtype Input: ~Escapable  // ❌ Cannot do this in Swift 6.x
}
```

| Property | Owned | Borrowed |
|----------|-------|----------|
| Storage | Indefinite | Scoped to borrow lifetime |
| Task transfer | Safe | Cannot cross task boundaries |
| Recursive structures | Yes | No |
| Lifetime safety | Runtime contract | Compile-time enforcement |

**Cross-references**: [MEM-COPY-010], [MEM-LINEAR-001], [IMPL-065]

---

### [MEM-COPY-012] Protocol Property Dispatch for ~Copyable Return Types

**Statement**: Protocol properties with `~Copyable` return types dispatch through `_read` (yielding a borrowed value), while protocol *functions* return owned values.

| Declaration | Dispatch | Ownership of Return |
|-------------|----------|-------------------|
| `var body: Body { get }` | `_read` coroutine | Borrowed (caller cannot store) |
| `func body() -> Body` | Function entry | Owned (caller can store) |

**Workaround**: Store the *container* and compute the `~Copyable` value transiently (see [IMPL-036]).

**Cross-references**: [MEM-COPY-005], [MEM-COPY-006], [IMPL-036]

---

### [MEM-COPY-013] Redundant Annotations on Compiler Optimization Boundaries

**Statement**: When a type annotation (e.g., `~Escapable`) is semantically redundant because the usage context already provides the same guarantee, AND the annotation triggers a known compiler optimization bug, the annotation SHOULD be omitted until the compiler is fixed.

**Canonical example**: `Property.View` omits `~Escapable` because the `_read`/`_modify` coroutine scope already prevents escape. Adding it triggers CopyPropagation crashes.

**Cross-references**: [MEM-COPY-012], [IMPL-061]

---

### [MEM-LIFE-001] ~Escapable Class Stored Property Limitation

**Statement**: `~Escapable` types accessed through class stored properties trigger lifetime checker errors ("lifetime-dependent value escapes its scope"). This is a known limitation of the `Lifetimes` feature in Swift 6.3. Use `~Copyable` alone when the view must be accessed through a class property — the `_read` coroutine scope prevents escape, `~Copyable` prevents aliasing.

**Affected pattern**: Mutex `Locked` view, Property.View-like types stored in classes.

**When resolved**: Add `~Escapable` back to the view type for stronger compile-time safety.

**Cross-references**: [MEM-COPY-013], [IMPL-071], [Research: noncopyable-ergonomics-compiler-state.md]

---

### [MEM-OWN-010] Always-Consume Transfer (Closure Path)

**Statement**: When every code path through a `Mutex.withLock` closure consumes a `~Copyable` value, the value MUST be passed as a `consuming` closure parameter via `withLock(consuming:body:)`. The Optional wrapper mechanism (`.take()!`) is confined to the extension's implementation per [IMPL-070].

**Note**: For new code, prefer the coroutine accessor pattern (`_state.locked.value`) per [IMPL-070]. This closure pattern is backward compatibility for existing `withLock` call sites.

**Call site** (reads as intent):
```swift
_state.withLock(consuming: element) { state, element in
    state.buffer.push(consume element, to: .back)
}
```

**When to use**: The value is always consumed — buffered, delivered, or dropped. No code path retains it.

**Cross-references**: [IMPL-INTENT], [IMPL-067], [IMPL-070], [Research: noncopyable-ownership-transfer-patterns.md]

---

### [MEM-OWN-011] Maybe-Consume Transfer (Closure Path)

**Statement**: When a state machine decides per-path whether to consume a `~Copyable` value, the state machine method MUST take `inout Element?`. It uses `.take()!` on consume paths and leaves the Optional populated on non-consume paths. The caller passes `&slot` through standard `withLock`.

**Call site** (reads as intent):
```swift
let action = storage.withLock { state in
    state.send(&slot)  // state decides whether to take
}
```

**State machine** (mechanism confined here):
```swift
mutating func send(_ element: inout Element?) -> Send.Action {
    guard !_closed else { return .shut }          // leave element
    if hasReceiver { return .give(element.take()!) }  // take element
    buffer.push(element.take()!, to: .back); return .keep  // take element
}
```

**When to use**: Some paths consume (deliver, buffer), others don't (suspend, reject). A state machine determines the outcome.

**Cross-references**: [IMPL-INTENT], [IMPL-067], [IMPL-070], [Research: noncopyable-ownership-transfer-patterns.md]

---

### [MEM-OWN-012] Action Enum Dispatch

**Statement**: When a `Mutex.withLock` closure performs a state transition that requires post-lock side effects, the closure MUST return a `~Copyable` action enum. Side effects (continuation resume, element delivery) happen outside the lock via `switch consume action`. Continuations MUST be resumed post-lock to prevent reentrancy and deadlock.

```swift
// Inside lock: pure state transition
let action: _Take = _state.withLock { state in
    if let element = state.buffer.pop(from: .front) { return .element(element) }
    if state.isFinished { return .finished }
    return .suspend
}

// Outside lock: side effects
switch consume action {
case .element(let element): return element
case .finished: return nil
case .suspend: break
}
```

**Cross-references**: [IMPL-INTENT], [IMPL-070], [Research: noncopyable-ownership-transfer-patterns.md]

---

### [MEM-OWN-013] Consuming Does Not Suppress Deinit

**Statement**: A `consuming func` that extracts a value from a `~Copyable` type does NOT prevent `deinit` from running on the remaining stored properties. When a `consuming func` must signal to `deinit` that a value has already been extracted, the type MUST use a tracking flag (typically `Atomic<Bool>`) checked in `deinit`.

**Correct**:
```swift
struct Handle<Value: ~Copyable>: ~Copyable {
    private let _box: Reference.Box<Value>
    private let _taken = Atomic<Bool>(false)

    consuming func value() async throws(E) -> Value {
        _taken.store(true, ordering: .releasing)
        return _box.take()
    }

    deinit {
        guard !_taken.load(ordering: .acquiring) else { return }
        // Cleanup only if value was NOT already extracted
        _box.dispose()
    }
}
```

**Incorrect**:
```swift
struct Handle<Value: ~Copyable>: ~Copyable {
    private let _box: Reference.Box<Value>

    consuming func value() async throws(E) -> Value {
        return _box.take()
        // ❌ Assumes deinit won't run — it WILL run on _box
    }
}
```

**Rationale**: In Swift, a `consuming func` that does not `discard self` still runs `deinit` on all remaining stored properties. The mental model "consuming takes ownership, so deinit doesn't run" is incorrect. This is analogous to Rust's pre-drop-flag-removal era where a `moved` flag tracked partial moves.

**Cross-references**: [MEM-LINEAR-001], [MEM-LINEAR-002], [MEM-COPY-001]


---

### [MEM-OWN-014] Batch Slot Staging for Non-Sendable Sequences

**Statement**: When a `Sequence` of non-Sendable elements must enter a `withLock` closure, the elements MUST be staged through `Ownership.Slot(Array(elements))` before the lock. Inside the lock, iterate from the Slot. The `sending` annotation on the parameter alone is not sufficient — captured sequences merge with the `inout sending State` region.

**Correct**:
```swift
func send<S: Sequence>(contentsOf elements: sending S)
    where S.Element == Element
{
    let slot = Ownership.Slot(Array(elements))
    let action = _state.withLock { state in
        let items = slot.take()
        for element in items {
            state.buffer.push(element, to: .back)
        }
        return state.signal()
    }
    action.execute()
}
```

**Incorrect**:
```swift
func send<S: Sequence>(contentsOf elements: sending S) {
    let action = _state.withLock { state in
        for element in elements {  // ❌ Captured `elements` merges with state region
            state.buffer.push(element, to: .back)
        }
        return state.signal()
    }
}
```

**Rationale**: `sending` transfers region ownership at the call boundary, but inside the closure, the captured value merges with the `inout sending State` parameter's region. `Ownership.Slot` is `@unchecked Sendable` — values taken from it are treated as "disconnected" from any region.

**Cross-references**: [MEM-OWN-010], [MEM-COPY-006] Category 6, [IMPL-070]


---

### [MEM-OWN-016] `isolated` Parameter for Borrowing ~Copyable Across Actor Boundaries

**Statement**: When a `borrowing ~Copyable` parameter must reach an actor, the function MUST accept an `isolated Actor` parameter rather than dispatching through `Actor.run` or any closure-based mechanism. Closure-based actor entry is incompatible with `borrowing ~Copyable` parameters; the `isolated` parameter is the only working pattern.

**Correct**:
```swift
extension IO.Event.Selector {
    private func _registerOnExecutor(
        _ event: borrowing IO.Event,
        on actor: isolated Actor
    ) throws(IO.Error) {
        // entire function runs on actor's executor
        // borrow lives in function scope — no closure to escape
        actor.publish(event)
    }

    public func register(_ event: borrowing IO.Event, on actor: Actor) async throws(IO.Error) {
        try await _registerOnExecutor(event, on: actor)
    }
}
```

**Incorrect**:
```swift
public func register(_ event: borrowing IO.Event, on actor: Actor) async throws(IO.Error) {
    try await actor.run { actor in   // ❌ @Sendable closure cannot capture borrowing
        actor.publish(event)         // ❌ event borrow expired
    }
}
```

**Rationale**: `@Sendable` closures are escaping — they cannot capture `borrowing` parameters because the borrow's lifetime is function-scoped, while escaping closures outlive that scope. The `isolated` parameter avoids closures entirely: the entire function body runs on the actor's executor, and the borrow lives in the function scope from start to finish. (Experiment history: rationale archive §[MEM-OWN-016].)

**How to apply**: Extract the actor-interacting code into a private helper with an `isolated ActorType` parameter. The public method delegates with `try await _helper(args, on: actor)`. Result: one hop, both register and publish synchronous, borrow intact.


**Cross-references**: [MEM-OWN-010], [MEM-OWN-011], [MEM-SEND-007]

---

### [MEM-COPY-016] Conditional-Copyable Cleanup Triangle — Lifecycle Oracles Live at a Class Boundary

**Statement**: A generic struct with a conditional `Copyable` conformance (`: Copyable where S: Copyable`) CANNOT declare `deinit` — the compiler rejects it (`deinitializer cannot be declared in generic struct that conforms to Copyable`): the unconstrained instantiation must satisfy Copyable layout, and Copyable structs cannot carry deinits. Consequently, a discipline that wants all three of (a) a generic substrate field, (b) conditional Copyability, and (c) automatic cleanup of its contents on drop can have any TWO directly. When all three are required, the cleanup oracle MUST move to a class boundary (Box-relocation), and the discipline MUST preserve exactly ONE cleanup-truth-holder.

**The triangle** — Swift admits any two of the three:

| Keep | Give up | Resulting form |
|------|---------|----------------|
| (a) generic substrate + (b) conditional Copyable | (c) auto-cleanup | No `deinit`; cleanup is manual, or delegated to a self-cleaning substrate |
| (a) generic substrate + (c) auto-cleanup | (b) conditional Copyable | Unconditionally `~Copyable` struct carrying `deinit`; Copyable consumers excluded |
| (b) conditional Copyable + (c) auto-cleanup | (a) generic substrate | Field pinned to a concrete type whose own `deinit` cleans up |

**Box-relocation (the escape)**: move the (a)+(c) pair into a private `final class Box` — classes carry deinits freely, and a class-reference field is Copyable-layout-compatible (a pointer) — leaving the struct with (b) trivially:

```swift
extension Buffer where S: Storage.`Protocol`, S: ~Copyable {
    public struct Slab: ~Copyable {
        private var box: Box                       // class reference — Copyable layout
        private final class Box {
            var storage: S                         // (a) the generic substrate
            var occupancy: Bitmap
            deinit { /* (c) walk occupancy; deinitialize occupied slots */ }
        }
    }
}
extension Buffer.Slab: Copyable where S: Copyable {}   // (b) conditional Copyable
// CoW: mutating paths probe isKnownUniquelyReferenced(&box) and deep-copy occupied slots.
```

When the Box's witnesses must reach off-protocol members of the substrate (generation tokens, node links), the Box holds the CONCRETE substrate (the generic parameter stays as a phantom or truthful spelling at the surface) — the class-reference field makes the conditional `Copyable` demand-free either way.

**Exactly one cleanup-truth-holder per discipline**: the `deinit` lives EITHER on the Box OR on a held concrete substrate that self-cleans — never both. Two deinits walking the same occupancy state is a double-free waiting to happen. Which holder is correct is a per-discipline judgment: a Box holding a self-cleaning store carries NO deinit (the held store IS the oracle); a Box that absorbed a deleted oracle's responsibility DOES.

**Worked example (the origin incident)**: the MSB W3 `Buffer.Slab<S>` reparam wall and the Box-relocation pilot — three sightings, one constraint: rationale archive §[MEM-COPY-016].

**Rationale**: when a generic value-type discipline needs lifecycle management, the lifecycle lives at a class boundary — the type system forces you to find where. Naming the triangle converts a recurring compiler wall into a design decision made up front: pick which leg to give up, or relocate to a Box and pick the truth-holder.

---

### [MEM-COPY-017] Construction Captures Copyability Evidence — Split the Constructors, Split the Helpers

**Statement**: A CoW-capable wrapper whose copy machinery (clone strategy, drain, …) depends on `Element: Copyable` MUST capture that machinery at CONSTRUCTION, via constructor overloads split on element copyability (`init` `where Element: Copyable` capturing the strategy; `init` `where Element: ~Copyable` capturing none). Every GENERIC construction helper in tests or consumers MUST split the same way — a single `~Copyable`-generic helper statically selects the strategy-less overload even when the caller's element is `Copyable`, producing a column that traps (or worse, aliases) on its first shared mutation.

**Why**: copyability evidence exists only where `Element: Copyable` is statically visible; overload resolution is decided at the CONSTRUCTION site, not the use site. There is no type-level repair downstream — the `sending`/region spike (2026-06-10) confirmed region disconnection proves race-safety, never refcount uniqueness, so the strategy cannot be recovered later. The runtime backstop (`unshare()` — the [DS-025] gate, renamed from `prepareForMutation()` at W1.6 — trapping on a shared box with no strategy) converts silent aliasing into a trap; this rule prevents reaching it.

**How to apply**: when adding a constructor or helper to a `Shared`-like type (or any S5 column combinator), write the pair; never a single `~Copyable`-generic form. (Fired-trap incident: rationale archive §[MEM-COPY-017].)


**Cross-references**: [MEM-COPY-016] (the cleanup triangle — the drain side of the same captured machinery), [MEM-SAFE-028] (the drain-box rule).

**The law is fundamental, not a passing compiler gap.** A value type with a user `deinit` cannot conform to `Copyable` — *even conditionally* (SE-0427, § "Conformance to `Copyable`": *"A conditional `Copyable` conformance is not permitted if the struct or enum declares a `deinit`. Deterministic destruction requires the type to be unconditionally noncopyable."*; diagnostic `copyable_illegal_deinit`). A **conditional `deinit`** — one that runs only for the `~Copyable` instantiations — is **not expressible today** (8 empirical spikes fail on Swift 6.3.2 and 6.4-dev; no experimental flag unlocks it) and has **no near-term horizon**; the restriction is mirrored by Rust (`Drop ⟹ !Copy`, E0184; no conditional `Drop`, E0367). This is the canonical, promoted form of the vector-primitives DECISION: *needs `~Copyable` cleanup ⟹ MUST have `deinit` ⟹ CANNOT be conditionally `Copyable` ⟹ MUST be unconditionally `~Copyable`.*

**The inline third corner — the leaf carries the deinit, not a carve-out (CORRECTED 2026-06-07).** When the substrate is `@_rawLayout` (inline), a *class* Box is indeed wrong (it reintroduces the heap the inline storage avoids). But the conclusion is **not** a forced separate `.Inline` *buffer type*. The escape is the **same one the dense side already uses**: put the occupancy oracle + `deinit` in the **leaf**. A move-only `@_rawLayout` leaf carries its `deinit` freely (it is unconditionally `~Copyable` — fine for a leaf), exactly as `Memory.Inline` carries its range-ledger deinit. The `Buffer<S>` over it carries **no** `deinit` and stays one generic — the S5 pattern (conditional-`Copyable` over a generic field), *not* S8 (which only fails a wrapper claiming `Copyable` while holding a *concrete* `~Copyable` field). Copyability flows from the leaf: move-only for the inline leaf, that is all. So the `.Inline`/`.Small` *buffer types dissolve*; the only residual is that bit-dense + value-semantics + inline cannot coexist (a tombstone `Element?` leaf trades density for copyability). See `swift-institute/Research/occupancy-lives-in-the-leaf.md`. *(The triangle, the one-truth-holder invariant, and the heap class-boundary mechanism above are unchanged and correct — `Storage.Arena` is the shipping sparse-leaf proof.)*

**Wall 1 vs Wall 2.** This rule is the **type-system** wall (Wall 1). It is distinct from the **codegen** bug `swiftlang/swift#86652` (Wall 2 — cross-package deinit-skip), governed by [MEM-SAFE-027]. Do not conflate them.


**ADT Tower rider (2026-07-02)**: this law is now a LOAD-BEARING citation of [DS-025] (the D2 rationale — the triangle is why carriers carry no `deinit` and copyability flows from the column). Wall 1 in `Research/adt-tower.md` §3. Provenance: `Research/adt-tower.md` §4.7.

**Cross-references**: [MEM-COPY-001a] (deinit immutability on ~Copyable structs), [MEM-COPY-003] (class wrapping for collections), [MEM-COPY-004] (suppression restatement on the conditional conformance), [MEM-COPY-010], [MEM-REF-002], [MEM-SAFE-027] (the distinct Wall-2 codegen workaround), [DS-002] / [DS-023] / [DS-025] (data-structure variant disposition + the canonical ADT shape); *(pending — Strata→modularization track)* [MOD-PLACE] (placement-calculus hard-floor exception). Research: `conditional-deinit-conditionally-copyable-generics.md`.

---

### [MEM-COPY-018] Same-Type Method Pins Derive Suppression Conditions, Not Conformance Conditions

**Statement**: A `where S == Wrapper<E, Concrete<E>>` same-type pin on a METHOD (the column-pin idiom, mechanic #2) succeeds only when every conditional conformance it must derive for the pinned type's parts is conditional ONLY on suppressions (`where T: ~Copyable`). A conformance conditional on a PROTOCOL bound (`extension Wrapper: P where B: P`) does NOT derive through such a pin — the requirement machine reifies `Concrete<E>: P` as a stated requirement, whose subject is concrete, which is ill-formed ("type … in conformance requirement does not refer to a generic parameter or associated type"). Therefore: a column combinator consumed through method pins MUST carry its protocol obligations in the DECLARATION bound, never as conditional conformances; threading the concrete part through an extra method-level generic (`Column == Concrete<E>`) does not help ("same-type requirement makes generic parameter 'Column' non-generic").

**Why**: the Array-playbook ADT surface pins growth/construction per column with method-level `where S == Shared<E, Column>` clauses; `Shared`'s seam obligations must be derivable at every such pin. This is why `Shared`'s declaration bound (`B: Store.`Protocol`` & Buffer.`Protocol`` & ~Copyable`) is load-bearing and must not be relaxed to a smaller bound + conditional conformance — the relaxation type-checks in isolation and breaks every consumer pin (one-variable proof, ADT-families spike F-4, 2026-06-10).

**How to apply**: when designing an S5 column combinator or any generic type consumed via `where ==` method pins, put every protocol obligation pins must see into the declaration's generic-parameter bounds. Reserve conditional conformances on such types for capabilities pins never derive (carriers like `Equatable`/`Hashable`/`Copyable`, which consumers use through values, not pins).


**ADT Tower rider (2026-07-02)**: now a LOAD-BEARING citation of [DS-025]/[DS-029] — `Shared`'s declaration bound is load-bearing precisely because the [DS-029] allocation-generic op pins consume it through `where S == Shared<E, …>` method pins (form 3). Semantic conformances on carriers key on `S:` bounds, never on same-type pins, for this reason ([DS-025]). Provenance: `Research/adt-tower.md` §4.7, §2 D2.

**Cross-references**: [MEM-COPY-004] (suppression restatement — the suppression side of the same derivation behavior), [MEM-COPY-017] (the construction half of the column-combinator discipline); **ecosystem-data-structures** [DS-025], [DS-029].

---

### [MEM-OWN-017] A Closure Capture Cannot Be Consumed — Thread Consuming Payloads as Closure Parameters

**Statement**: A `~Copyable` value (including a `consuming` function parameter) MUST NOT be consumed inside a closure body that captures it — Swift 6.3.2 rejects it with "missing reinitialization of closure capture after consume", for NON-escaping closures as well as escaping ones. An API whose closure must move a value INTO the scoped context (e.g. `Shared.withUnique`) MUST thread the payload as a `consuming` closure PARAMETER instead: `withUnique(consuming: payload) { column, payload in column.insert(payload) }`.

**Why**: closure captures are semantically re-entrant storage to the checker; consumption would leave the capture deinitialized for a hypothetical next call. Closure PARAMETERS carry per-call ownership, so `consuming` parameters compose freely. (`Copyable` values mask the wall — the "consume" silently copies — so a generic API that only ever saw `Copyable` payloads in tests will break on its first move-only client.)

**How to apply**: scoped-access APIs that accept work closures get a payload-threading overload from birth (`(inout B, consuming T) -> R` beside `(inout B) -> R`); call sites move values through the parameter, never the capture. This is the structured-transfer sibling of the recorded `Task {}` wall (REPORT-W4 §ADDENDUM probe ii-b: move-only values cannot be consumed into escaping closures either — design handoffs as structured calls).


**Cross-references**: [MEM-OWN-001] (ownership annotations), [MEM-COPY-017] (the construction-evidence discipline the payload often feeds), REPORT-W4 §ADDENDUM (the escaping-closure/`Task {}` wall).

---

### [MEM-COPY-019] Box-Replacing Overloads MUST Split Per the [MEM-COPY-017] Pinned Pair

**Statement**: Any family overload that REPLACES a `Shared` box (`self.store = Shared(freshColumn)` or equivalent) MUST be split per the [MEM-COPY-017] pinned pair: the Copyable-element overload rebuilds through the strategy-CARRYING init; the `~Copyable`-bounded overload may keep the strategy-less init (lawful — a move-only-element family is itself move-only and can never fork). A single overload written under `~Copyable` bounds is FORBIDDEN for box replacement: under suppression, overload resolution statically selects the strategy-less init, so the replacement box carries NO clone strategy even when the element is concretely Copyable — the box works while unique and TRAPS on the first post-fork mutation (`Shared+Unique.swift:77` "Shared box is not unique but carries no clone strategy").

**The defect class (two confirmed occurrences)**: the stack Builder constructing-grammar twins and both dictionary families' Shared `removeAll` — masked by example tests that never forked after the wipe (the [TEST-035] class); fixes landed and regression-locked. Incident detail: rationale archive §[MEM-COPY-019].

**Enforcement**: Mechanical — `Lint.Rule.Tower.CloneLessBox` (`clone-less box`, primitives tier, pack `Primitives Linter Rule Tower`; ζ pilot of /promote-rule 2026-06-12; historically calibrated — fires at the pre-fix `Dictionary+Columns.swift:239` exactly). Discipline: `Audits/PROMOTE-MEM-COPY-019-2026-06-12.md`. [VERIFICATION: AST Lint.Rule.Tower.CloneLessBox]


**Cross-references**: [MEM-COPY-017] (the pinned pair this rule applies), [TEST-035] (the masking class the finding unmasked).

---

### [MEM-OWN-018] Guarded Deinit for Closure-Bearing ~Copyable Types

**Statement**: While the `discard self` wall stands (`discard` requires trivially-destroyed stored properties — Swift 6.3 diagnostic: "can only 'discard' type … trivially-destroyed stored properties"), a `~Copyable` type carrying a closure or other non-trivially-destroyed stored property MUST use the guarded-deinit shape: store the payload in an Optional field, `take()`/nil it in the consuming operation, and guard `deinit` on the field still being populated. The boundary spelling for `~Copyable` parameters crossing isolation seams is `consuming sending` — `sending` alone does not specify ownership for a `~Copyable` parameter. When a seam's declaration cannot yet carry `sending`, a wrapper vending the `sending` result is a provably additive retrofit (proof step before the canonical annotation).

```swift
public struct Foreign: ~Copyable {
    private var finalizer: (() -> Void)?          // Optional field

    public consuming func release() {
        finalizer.take()!()                       // nil-in-consuming-op
    }

    deinit {
        guard let finalizer else { return }       // guarded deinit
        finalizer()
    }
}
```

**Rationale**: three shipped types converged on this shape independently — `Completion.Entry` (`Completion.Entry.swift:102–131`), `Memory.Foreign` (`Memory.Foreign.swift`), `Memory.Map` (`Memory.Map.swift:94–97`) — making it the canonical ecosystem pattern, not a per-package workaround (Reflections 2026-06-12, memory-foreign pair).

**Removal gate**: re-derive when `discard self` accepts non-trivially-destroyed stored properties.

**Cross-references**: [MEM-OWN-013] (consuming does not suppress deinit — the tracking-flag sibling), [MEM-COPY-016] (the class-boundary escape for the conditional-Copyable case), [MEM-SEND-010] (`sending` results)

---
