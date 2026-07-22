# Memory Safety — Concurrency Safety

Part of the **memory-safety** skill. See `SKILL.md` for the navigation hub, frontmatter, and rule index.

Full rationale, provenance, extended worked examples, and the dated changelog: `swift-institute/Research/memory-safety-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MEM-SEND-001], [MEM-SEND-002], [MEM-SEND-003], [MEM-SEND-004], [MEM-SEND-005], [MEM-SEND-006], [MEM-SEND-007], [MEM-SEND-008], [MEM-SEND-009], [MEM-SEND-010], [MEM-SEND-011], [MEM-SEND-012], [MEM-SEND-013].

---

## Concurrency Safety

### [MEM-SEND-001] Conservative Sendable Defaults

**Statement**: Mutable reference wrappers MUST NOT be unconditionally `@unchecked Sendable` unless they provide synchronization.

```swift
// CORRECT - Conditional
extension Reference.Indirect: @unchecked Sendable where Value: Sendable {}

// INCORRECT - Unconditional
extension Reference.Indirect: @unchecked Sendable {}
```

---

### [MEM-SEND-002] Sendability Tiers

| Tier | When | Example |
|------|------|---------|
| Checked Sendable | Immutable, all fields Sendable | `struct Point: Sendable` |
| Conditional Sendable | Sendable when generic param is | `extension Box: Sendable where T: Sendable` |
| Unchecked Sendable | Synchronized by construction | `Slot`, `Transfer` (atomic state) |
| Not Sendable | Mutable without synchronization | `Indirect` base type |
| Explicit Escape | Caller asserts safety | `Indirect.Unchecked` |

---

### [MEM-SEND-003] Accurate Risk Description

**Statement**: When justifying unsafe escapes, describe the risk accurately — not euphemistically.

| Euphemistic | Accurate |
|-------------|----------|
| "`@unchecked Sendable` means transferable" | "Removing the compiler's data-race prevention" |

---

### [MEM-SEND-004] ~Copyable Structs Can Use Plain Sendable

**Statement**: `~Copyable` structs whose stored properties are all `Sendable` MUST use plain `Sendable`, not `@unchecked Sendable`. The compiler synthesizes and checks `Sendable` conformance for `~Copyable` structs in the same way as `Copyable` structs.

**Correct**:
```swift
public struct Channel.Reader<Element: ~Copyable & Sendable>: ~Copyable, Sendable {
    let descriptor: Kernel.Descriptor  // Sendable
}
```

**Incorrect**:
```swift
public struct Channel.Reader<Element: ~Copyable & Sendable>: ~Copyable, @unchecked Sendable {
    let descriptor: Kernel.Descriptor  // ❌ @unchecked is unnecessary — all fields are Sendable
}
```

**When `@unchecked` IS still needed on `~Copyable` types**: When stored properties include non-Sendable types with internal synchronization (e.g., `UnsafeMutablePointer` to a lock-protected region). In this case, `@unchecked` is about the non-Sendable field, not about `~Copyable`.

**Rationale**: `@unchecked` suppresses the compiler's data-race checking — never use it when the compiler can verify safety directly.

**Cross-references**: [MEM-SEND-001], [MEM-SEND-002], [MEM-SEND-003], [MEM-COPY-001]

**Lint enforcement**: `Lint.Rule.Memory.UnnecessaryUncheckedSendableNoncopyable` flags `struct` declarations whose conformance list contains both `~Copyable` and `@unchecked Sendable`. Scope detail: rationale archive §[MEM-SEND-004]. [VERIFICATION: AST Lint.Rule.Memory.UnnecessaryUncheckedSendableNoncopyable]


---

### [MEM-SEND-005] Non-Mutating Concurrent Access for ~Copyable Wrappers

**Statement**: A `~Copyable` struct whose stored properties are concurrent-primitive wrappers (`Atomic<T>`, `UnsafeMutablePointer<T>`, `Memory.Inline<T>`) MAY be accessed via concurrent borrowing (multiple `borrowing self` accessors at once) when no operation mutates a stored property. The pattern enables lock-free concurrent data structures (Chase-Lev deque, single-producer-multi-consumer queues) within Swift's ownership model — `Atomic.load`, `Atomic.store`, and `UnsafeMutablePointer.pointee` operations are non-mutating with respect to the wrapper struct's stored properties, even though they observably modify shared state.

**Why this works**: The wrapper struct's *stored properties* (e.g., `storage`, `bottom`, `top` in a Chase-Lev deque) are not mutated. The atomic operations modify the atomic's internal storage address; the unsafe-pointer dereferences modify the pointee (the buffer slot). Neither mutation touches `self`'s storage layout. Swift's `borrowing` access mode permits multiple concurrent borrows, so concurrent owner-push + stealer-steal is structurally permitted.

**When `@unchecked Sendable` is the right annotation**: Per [MEM-SEND-006], the data-race safety rests on the atomic protocol (memory orderings, CAS correctness), which the compiler cannot verify. `@unchecked Sendable` is principled here — *not* because `~Copyable` requires it (per [MEM-SEND-004]) but because the unsafe-pointer storage requires manual data-race-safety reasoning.

**Generalization**: Any `~Copyable` wrapper over concurrent primitives inherits this pattern. The structural test: do all operations mutate only through pointer/atomic indirection, never through stored-property assignment? If yes, the wrapper supports concurrent borrowing.


**Cross-references**: [MEM-SEND-001], [MEM-SEND-004], [MEM-SEND-006], [MEM-COPY-001]

---

### [MEM-SEND-006] Compiler-Limitation-Citing `@unchecked Sendable` Requires Revalidation Anchor

**Statement**: An `@unchecked Sendable` annotation whose adjacent justification cites a compiler limitation MUST carry the three institute anchor markers — `WHY:`, `WHEN TO REMOVE:`, `TRACKING:` — so the justification is falsifiable on toolchain bumps.

**Scope**: the compiler-limitation keyword-match is scoped to Category D only — Categories A/B/C are semantic-responsibility cases ([MEM-SAFE-024]'s scheme) and out of scope for this rule. *(Clause hoisted from the 2026-05-15 changelog entry.)*

**Enforcement**: Mechanical — `Lint.Rule.Memory.UncheckedSendableRevalidationAnchor` in `swift-foundations/swift-linter-rules`, target `Linter Rule Memory` (universal tier; pilot 2 of AST-domain pivot of `/promote-rule` 2026-05-15). Discipline: `Audits/PROMOTE-MEM-SEND-006-2026-05-15.md`. [VERIFICATION: AST]

**Cross-references**: [MEM-SEND-001], [MEM-SEND-004], [MEM-SEND-005], [MEM-SAFE-024], [DOC-045]

---

### [MEM-SEND-007] ~Copyable Cannot Capture in `@Sendable` Closures

**Statement**: `~Copyable` types CANNOT be captured in `@Sendable` or `@escaping` closures. This includes `TaskGroup.addTask` closures, `Task.detached` closures, and `withTaskCancellationHandler.onCancel` closures. Designs that require this capture are unimplementable and MUST be refactored.

**Why**: Swift's closure capture semantics require values to be copyable for `@Sendable` capture — a `~Copyable` type cannot be copied into the closure's capture list. This is a fundamental language constraint, not a bug.

**Refactoring options when the design demands this capture**:

| Original intent | Replacement |
|---|---|
| Race a `~Copyable` `receive()` against `Task.sleep` in a TaskGroup | Use structured cancellation from outside the call; manage deadlines at the sender |
| Pass `~Copyable` to `Task.detached` for background work | Use `isolated Actor` parameter pattern per [MEM-OWN-016] |
| Capture in `withTaskCancellationHandler.onCancel` | Move cancellation observation to the sender side (signal a Slot the receiver checks) |

**Disambiguation — `Mutex.withLock` is NOT `@Sendable`**: `Mutex.withLock` closures use `sending` for region transfer (see [MEM-SEND-009]); non-Sendable `~Copyable` values CAN be transferred across lock boundaries using `@unchecked Sendable` intermediaries like `Ownership.Slot`. The constraint above applies specifically to `@Sendable`-annotated closures, not to `sending`-annotated function parameters.

**Cross-references**: [MEM-SEND-001], [MEM-SEND-009], [MEM-OWN-016], [MEM-COPY-001]

---

### [MEM-SEND-008] No `Element: Sendable` Constraint as Region-Merge Workaround

**Statement**: When a `Mutex.withLock` closure fails because it captures non-Sendable values, adding `Element: Sendable` (or any blanket Sendable constraint) is FORBIDDEN as a workaround. The fix is to repair the region transfer using `Ownership.Slot` or to restructure the code.

**Forbidden**:
```swift
public struct Channel<Element: Sendable> {  // ❌ Sendable added to dodge region merge
    public func send(_ element: consuming Element) { ... }
}
```

**Correct** (Slot-based region transfer per `sending-mutex-noncopyable-region` experiment):
```swift
public struct Channel<Element: ~Copyable> {
    private let slot: Ownership.Slot<Element>  // @unchecked Sendable intermediary
    public func send(_ element: consuming Element) {
        slot.put(element)  // region transfer through Slot
    }
}
```

**Rationale**: Adding `Element: Sendable` defeats the purpose of removing the Sendable requirement. It papers over the real issue (region merge in the closure) with a constraint that restricts the API for every consumer, forever, in exchange for closing one diagnostic. The Slot pattern from the experiment is the correct fix.

**Cross-references**: [MEM-SEND-007], [MEM-SEND-009], [MEM-OWN-014]

---

### [MEM-SEND-009] `inout sending Value` for `Mutex.withLock` Wrappers

**Statement**: Any wrapper around `Mutex.withLock` that returns non-Sendable values MUST declare its body parameter as `(inout sending State) throws(E) -> sending T`, not `(inout State) throws(E) -> sending T`. The `sending` on the `inout` parameter is what tells the compiler the value is transferred into the closure and that results derived from it can be transferred OUT.

**Correct**:
```swift
public func withLock<R, E: Swift.Error>(
    _ body: (inout sending State) throws(E) -> sending R
) throws(E) -> sending R {
    try mutex.withLock { state throws(E) -> sending R in
        try body(&state)
    }
}
```

**Incorrect**:
```swift
public func withLock<R, E: Swift.Error>(
    _ body: (inout State) throws(E) -> sending R   // ❌ no `sending` on inout
) throws(E) -> sending R {
    // Diagnostic: "returning task-isolated 'state' as a 'sending' result risks causing data races"
}
```

**Why**: Without `sending` on the `inout` parameter, wrapper methods with identical-looking signatures fail the region check. The compiler has no special knowledge of `Mutex` — it is the `inout sending` parameter annotation (with the `hasSendingResult()` flag) that suppresses the diagnostic (compiler trace: rationale archive §[MEM-SEND-009]).

**Also**: `inout` capture of non-Sendable variables in `withLock` closures merges regions — use `@unchecked Sendable` intermediaries like `Ownership.Slot` per [MEM-SEND-008].

**Hazard — `withLock { $0 }` does NOT prevent escape of non-Sendable `State`**: On the pinned toolchain (Swift 6.3.2, verified 2026-06-01), `mutex.withLock { $0 }` *compiles* even when `State` is **non-Sendable**, handing a region-disconnected (`sending`) alias to the protected value out of the lock. The region checker then loses the aliasing relationship, so the escaped value can be sent into another isolation domain *and* mutated concurrently through `mutex.withLock` on the original thread — a genuine data race the compiler does not diagnose (demonstrated in Point-Free episode #360):

```swift
final class State { var x = 0 }          // NON-Sendable
let m = Mutex(State())
let escaped = m.withLock { $0 }          // ❌ alias escapes the lock, no diagnostic
Task.detached { escaped.x += 1 }         // races with…
m.withLock { $0.x += 1 }                 // …the same State under the lock
```

This is a region-based-isolation soundness gap, not an intended affordance. **Never return the protected `State` itself out of `withLock` when `State` is non-Sendable** — return a Sendable snapshot (`m.withLock { $0.x }`), or move a `~Copyable` value out via the `Ownership.Slot` + `inout sending` transfer above. Returning a **Sendable** value via `withLock { $0 }` (e.g. a `Mutex<[Element]>` array snapshot) is safe and is the common case; the hazard is strictly the non-Sendable-`State` escape. (Reproduction status, ecosystem-site survey, promotion-candidate note: rationale archive §[MEM-SEND-009].)

**Reference experiment**: `swift-institute/Experiments/sending-mutex-noncopyable-region/`.

**Cross-references**: [MEM-SEND-007], [MEM-SEND-008], [MEM-OWN-014]

---

### [MEM-SEND-010] `sending R` Over `R: Sendable` on Actor Returns

**Statement**: Actor methods returning a generic `R` MUST use `-> sending R` rather than constraining `R: Sendable`. `sending R` is strictly more flexible — it allows returning freshly-constructed non-Sendable values when the compiler can prove they are disconnected from the actor's region; `R: Sendable` rejects all non-Sendable returns blanket.

**Correct**:
```swift
extension Actor {
    public func produce<R>() -> sending R { ... }
    public func transform<R>(_ work: @Sendable () -> sending R) -> sending R { ... }
}
```

**Incorrect**:
```swift
extension Actor {
    public func produce<R>() -> R where R: Sendable { ... }  // ❌ blanket constraint
}
```

**Note on Apple's `MainActor.run`**: Apple's stdlib `MainActor.run` still uses `T: Sendable` because it predates `sending` (Swift 6.0). The institute targets Swift 6.3, so `sending` is available and preferred. Sendable types satisfy `sending` trivially — there is no consumer cost to choosing `sending`.

**Cross-references**: [MEM-SEND-001], [MEM-SEND-009]

---

### [MEM-SEND-011] Continuation Dispatch Avoids `T: Sendable`

**Statement**: To dispatch blocking work to a dedicated executor thread without requiring `T: Sendable`, use `withCheckedContinuation` + `Task<Void, Never>(executorPreference:)`. Direct `Task<T, _>(executorPreference:) { operation() }.value` forces `T: Sendable` because `Task<Success, Failure>` requires `Success: Sendable`.

**Correct**:
```swift
public func runOffMain<T>(_ operation: () -> T) async -> sending T {
    nonisolated(unsafe) let op = operation  // region isolation workaround
    return await withCheckedContinuation { continuation in
        Task<Void, Never>(executorPreference: executor) {
            continuation.resume(returning: op())
        }
    }
}
```

**Why this works**: `Task<Void, Never>` has `Void` as `Success` (always Sendable), so the Task itself imposes no constraint on the user's `T`. The value crosses threads via the continuation's `sending` semantics. The `nonisolated(unsafe)` is needed because the region checker does not model continuations — the construction is correct because continuation synchronization guarantees safety.

**Caveat — sync path still requires `T: Sendable`**: `run.sync` wraps an outer Task and inherits the stdlib constraint. Documented as acceptable trade-off in the institute's executor design.

**Cross-references**: [MEM-SEND-001], [MEM-SEND-007], [MEM-SEND-010]

---

### [MEM-SEND-012] Region-Based Isolation Supersedes Sendable Constraint in Protocol-Layer Designs

**Statement**: Region-based isolation (SE-0414) supersedes `Sendable` constraint annotation in protocol-layer designs. New protocol associatedtypes MUST NOT default to `Error & Sendable` (or other Sendable-bearing constraints) when the value's concurrency-safe transport can be secured at the consumer boundary by region isolation. Method parameters and returns that cross actor boundaries MUST prefer `sending T` per [MEM-SEND-009]/[MEM-SEND-010] over `T: Sendable` constraints on generics. Existing `& Sendable` constraints on protocol associatedtypes MAY be relaxed when no conformer relies on the Sendable bound for capture/transport.

**Correct** — Failure as plain `Error`:
```swift
extension Parser {
    public protocol `Protocol`<Input, Output, Failure> {
        associatedtype Failure: Swift.Error           // ✓ no `& Sendable`
        // Cross-actor Failure transport is the consumer's responsibility,
        // resolved at the call site via `sending` parameters or region
        // disconnection — not pre-decided by the protocol.
    }
}
```

**Incorrect** — Failure annotated for hypothetical actor transport:
```swift
extension Parser {
    public protocol `Protocol`<Input, Output, Failure> {
        associatedtype Failure: Swift.Error & Sendable   // ❌ constrains every
                                                          //   conformer for the
                                                          //   protocol's lifetime
    }
}
```

**Why**: A Sendable constraint placed on a protocol associatedtype propagates to every conformer for the protocol's lifetime. The constraint is justified ONLY when the protocol itself requires the value to cross an isolation boundary — which it usually does NOT at the abstract-protocol layer. Region-based isolation, applied at the *consumer* boundary, is strictly more flexible: Sendable types satisfy `sending` trivially; non-Sendable types satisfy `sending` when the compiler proves regional disconnection. The protocol layer should not pre-decide its consumers' isolation discipline.

**How to apply**:

1. **New protocol associatedtypes** (e.g., on capability protocols like `Parser.Protocol`, `Serializer.Protocol`, `Coder.Protocol`, future `Formatter.Protocol`): default to the minimal capability bound (`: Error`, `: ~Copyable & ~Escapable`, etc.) without `& Sendable`.
2. **Boundary-crossing method parameters and returns**: prefer `sending T` over `T: Sendable`. Composes with [MEM-SEND-009] (`inout sending` for `Mutex.withLock` wrappers) and [MEM-SEND-010] (`sending R` over `R: Sendable` on actor returns) at protocol-design scope.
3. **Existing `& Sendable` constraints on protocol associatedtypes**: relaxation is permitted when no conformer depends on the Sendable bound. The check is "would removing `& Sendable` break any conformer's `@Sendable` capture path or `Task` transport?" If no, drop it; consumers needing Sendable can constrain at the consumer site (`P.Failure: Sendable`).
4. **When Sendable IS still required** — this rule does NOT relax:
   - Synchronization-based safety (Category A per [MEM-SAFE-024]).
   - Ownership-transfer types (Category B).
   - Explicit cross-actor API surfaces where the protocol IS the boundary contract.
   - Structural workaround sites (Category D — `@_rawLayout` bridges, pointer-backed wrappers).

**Why "supersedes" not "replaces"**: Sendable remains the right tool for types that are concurrency-safe by construction and where `@Sendable` capture is the intended discipline. The rule narrows the *default* at the protocol-layer — protocol associatedtypes default OFF the Sendable constraint; specific conformers and consumers add Sendable when structural safety or boundary semantics warrant it. This is the same shape as the existing [MEM-SEND-010] (`sending R` over `R: Sendable`) — generalized from actor returns to protocol associatedtype defaults.

**Worked example (the origin incident)**: the 2026-05-13 transformation-domain audit reversal (*"we don't want the & Sendable constraint. we're moving to region based isolation over Sendable."*): rationale archive §[MEM-SEND-012].


**Cross-references**: [MEM-SEND-001] (Conservative Sendable Defaults — narrower complement), [MEM-SEND-008] (No `Element: Sendable` workaround), [MEM-SEND-009] (`inout sending` for `Mutex.withLock`), [MEM-SEND-010] (`sending R` over `R: Sendable` on actor returns — same direction at the return-site scope), [MEM-SEND-011] (Continuation Dispatch Avoids `T: Sendable`), [MEM-SEND-013] (combinator-layer extension of this rule), [MEM-SAFE-024] (Category A/B/C/D taxonomy)

---

### [MEM-SEND-013] Region-Based Isolation Supersedes Sendable Constraint in Combinator-Layer Designs

**Statement**: The principle established in [MEM-SEND-012] extends from the protocol layer to the combinator layer. Combinator types parameterized over protocol-bound generics (e.g. `Parser.Map.Transform<Upstream: Parser.Protocol, …>`, `Serialization.Parsing.Whole<…>`) MUST NOT carry `Sendable` constraints on their protocol-bound generic parameters, MUST NOT carry conditional `Sendable` conformances gated on those parameters being Sendable, MUST NOT mark stored closures `@Sendable`, and extension methods that construct or operate on combinators MUST NOT carry `where Self: Sendable` (or `where T: Sendable`) constraints. Cross-isolation transport of combinator values is the *consumer's* responsibility, resolved at the call site via `sending` parameters or region disconnection.

**Out of scope** — this rule does NOT touch:

| Pattern | Why preserved |
|---|---|
| `enum Error: Swift.Error, Sendable` on concrete error types | `Sendable` is redundant via `Error: Sendable`, not a restriction on callers |
| Conditional `Sendable` on data-only value containers (e.g. `Spanned<T>`, `Located<E>`, `Input.Slice<Base>`, `Parser.Tracked.Checkpoint`) — written as `extension Container: Sendable where T: Sendable {}`, *not* as a struct-level generic constraint `struct Container<T: Sendable>` | Pure value containers follow the stdlib pattern; the conditional form carries no consumer-facing restriction (instantiation with non-Sendable `T` stays valid; only the `Sendable` conformance is gated). The struct-level constraint shape is *forbidden* by this rule — it imposes the bound at instantiation and is indistinguishable from the protocol-bound cascade Pattern A targets. |
| Unconditional `Sendable` on fully-owned concrete types (e.g. `Binary.Bytes.Machine.Build.Parser: Sendable`) | Sendable by construction (when satisfied transitively under whichever Pattern remedy applies); no caller-side constraint |

**Correct** — combinator constructs without Sendable constraints:

```swift
extension Parser.Map {
    public struct Transform<Upstream: Parser.`Protocol`, Output> {     // ✓ no `: Sendable`
        @usableFromInline internal let upstream: Upstream              // ✓ no `where Upstream: Sendable`
        @usableFromInline internal let transform: (Upstream.Output) -> Output  // ✓ no `@Sendable`

        @inlinable
        public init(
            upstream: Upstream,
            transform: @escaping (Upstream.Output) -> Output           // ✓ no `@Sendable`
        ) {
            self.upstream = upstream
            self.transform = transform
        }
    }
}

extension Parser.`Protocol` {                                          // ✓ no `where Self: Sendable`
    @inlinable
    public func map<NewOutput>(
        _ transform: @escaping (Output) -> NewOutput                   // ✓ no `@Sendable`
    ) -> Parser.Map.Transform<Self, NewOutput> {
        Parser.Map.Transform(upstream: self, transform: transform)
    }
}
```

**Incorrect** — combinator constructs gated on Sendable:

```swift
extension Parser.Map {
    public struct Transform<Upstream: Parser.`Protocol`, Output>: Sendable   // ❌
    where Upstream: Sendable {                                                // ❌
        let transform: @Sendable (Upstream.Output) -> Output                  // ❌
    }
}

extension Parser.`Protocol` where Self: Sendable {                            // ❌
    public func map<NewOutput>(
        _ transform: @escaping @Sendable (Output) -> NewOutput                // ❌
    ) -> Parser.Map.Transform<Self, NewOutput> { … }
}
```

**Why the combinator layer specifically**: The four restriction patterns above (struct conformance, generic bound, closure annotation, extension constraint) form a **coupled cascade**. The `: Sendable where Upstream: Sendable` conditional conformance on the combinator forces `@Sendable` on stored closures (otherwise the conformance fails), which propagates outward to the constructor parameter, which propagates to the `.map(...)` extension's `where Self: Sendable` constraint (otherwise the call to the constructor doesn't typecheck). Dropping any one of them in isolation leaves dangling constraints; the four must be cleaned together per combinator.

**Cost of dropping**: Combinator values can no longer be stored in `Sendable`-typed locations (long-lived globals declared as `Sendable`, generic captures bound `T: Sendable`). Consumers needing such storage switch to `sending` parameters at the transport boundary or use `nonisolated(unsafe)` at the storage site. For primitive parsers/serializers/coders/formatters, combinators are typically built and consumed locally — the practical impact at the primitives layer is minimal; consumer-side impact is bounded by the deferred ecosystem audit.

**How to apply**:

1. **New combinator types**: do not annotate `: Sendable`, do not add `where T: Sendable` constraints on protocol-bound generics, do not use `@Sendable` on stored closures.
2. **Existing combinators**: drop the four-pattern cascade together in one coordinated pass. Verify the package still builds — typically the dropped constraints reveal no consumers because no internal site depended on them.
3. **Boundary helpers** (rare): if a specific helper truly requires Sendable transport (e.g. a parser cache shared across actors), that helper introduces `sending` at its specific call site — not via a blanket protocol/extension constraint that propagates to all consumers.
4. **Concrete leaves stay Sendable**: error types, owned value containers, and types that are Sendable by construction continue to declare it; only the *constraints* on protocol-bound generics are removed.

---

#### Pattern B — Mode-parameter cascade

The four-pattern cascade above is the *protocol-bound* shape (call it **Pattern A** for disambiguation): combinator structs parameterized over protocol-bound generics whose Sendable bounds form a coupled `: Sendable / @Sendable / where Self: Sendable / <T: Sendable>` cascade that dissolves by dropping all four together.

A second species exists in **Mode-parameterized** combinator layers — those whose `Builder` / `Program` / `Parser` types pass through a phantom `Mode` typealias that gates Sendable bounds at every upstream layer. Here the cascade dissolves differently:

> **Pattern B is TRANSITIONAL** (post-2026-05-13 reframe). The terminal direction for Mode-parameterized combinators is the same as Pattern A's terminal: the assembled `Parser` / `Program` is NOT `Sendable`, and consumers transport across isolation domains via `sending` at the program-transport boundary. The Mode-as-`@unchecked Sendable` promotion is a valid intermediate ONLY when consumers genuinely need the assembled-leaf-is-Sendable property and the cost of `sending` discipline at every transport site outweighs the Cat C disclosure cost upstream.
>
> **Pattern B recipe (terminal direction)**: flip the consumer's `Mode` typealias to a non-Sendable upstream Mode variant (e.g. `Mode.Unchecked` declared as plain `public struct Unchecked`), then cascade-strip the now-redundant `<T: Sendable>` / `@Sendable` annotations across the combinator factories. The assembled `Parser` / `Program` becomes non-Sendable; downstream consumers use `sending` at transport.
>
> **Pattern B recipe (transitional / preserved-Sendable variant)**: promote the upstream Mode variant to `@unchecked Sendable` (one line, with `// SAFETY:` block per [MEM-SAFE-024] Cat C), flip the consumer's typealias to it, then cascade-strip the combinator-factory bounds. The assembled `Parser` retains Sendable by construction (`Frozen<Mode>: Sendable where Mode: Sendable` and `Program: Sendable where Mode: Sendable` automatically apply). This shape introduces a Cat C `@unchecked Sendable` site that future migrations may want to retire in favour of the terminal direction.

**Recognition heuristic** (Pattern A vs Pattern B): if dropping `<T: Sendable>` from a single combinator factory makes the upstream call sites (`builder.captures.insert(_:)`, `Value.make(_:)`, `Transform.Erased.init(capture:)`, etc.) fail to typecheck because the consumer's chosen Mode requires Sendable captures upstream — Pattern B applies. If dropping the bound surfaces no upstream call-site failure (the cascade is local to the factory's struct + extension + closure) — Pattern A applies.

**Correct (Pattern B)** — Mode.Unchecked dissolves the cascade:

```swift
extension Binary.Bytes.Machine {
    public typealias Mode = Machine.Capture.Mode.Unchecked        // ✓ @unchecked Sendable upstream
}

extension Binary.Bytes.Machine.Expression {
    @inlinable
    public func map<T>(                                            // ✓ no <T: Sendable>
        _ transform: @escaping (Output) -> T,                      // ✓ no @Sendable
        in builder: inout Binary.Bytes.Machine.Builder
    ) -> Binary.Bytes.Machine.Expression<T> {                      // ✓ no where Output: Sendable
        let captureID = builder.captures.insert(transform)
        // … (Store<Unchecked>.insert<Value> accepts non-Sendable Value)
    }
}
```

**Incorrect (Pattern B)** — Mode.Reference forces the cascade:

```swift
extension Binary.Bytes.Machine {
    public typealias Mode = Machine.Capture.Mode.Reference                 // ❌ root cause
}

extension Binary.Bytes.Machine.Expression {
    public func map<T: Sendable>(                                          // ❌ forced by Mode
        _ transform: @Sendable @escaping (Output) -> T,                    // ❌ forced by Mode
        in builder: inout Binary.Bytes.Machine.Builder
    ) -> Binary.Bytes.Machine.Expression<T> where Output: Sendable { … }   // ❌ forced by Mode
}
```

**Why the Mode-parameter cascade is different**: The Sendable annotations on Pattern B combinator factories are not independent design decisions — they are *consequences* of which Mode the consumer's combinator layer parameterizes against. Upstream, the Mode parameter (typically `Mode.Reference` vs `Mode.Unchecked`) drives whether every per-Mode `Store.insert` / `Value.make` / `Transform.Erased.init` / `Combine.Erased.init` extension demands `Value: Sendable` (Reference) or accepts non-Sendable (Unchecked). Flipping the Mode at the consumer's typealias fans out across every downstream annotation; no per-factory edit is the *cause* — they all dissolve together because their forcing function has moved.

**How to apply Pattern B**:

1. **Identify the Mode typealias** at the consumer's Builder/Program (`public typealias Mode = SomeUpstream.Capture.Mode.X` or equivalent).
2. **Choose terminal vs transitional direction**:
   - **Terminal (preferred)**: pick an upstream Mode variant declared as plain `public struct X` (non-Sendable). The assembled `Parser` / `Program` will be non-Sendable by construction; consumers transport via `sending` at the boundary.
   - **Transitional**: pick (or promote) an upstream Mode variant declared as `public struct X: @unchecked Sendable` with a `// SAFETY:` Cat C block. The assembled `Parser` / `Program` retains Sendable. Choose this only when consumers' `sending` discipline at every transport site is genuinely impractical; document the Cat C anchor for later retirement.
3. **Flip the consumer's typealias** to the chosen Mode. Upstream's per-Mode parallel extensions (`Store.insert<Value>` / `Value.make<T>` / per-Erased `init<In, Out>(capture:)` without Sendable bounds) must already exist; if absent, propose their addition first.
4. **Cascade-strip the now-redundant annotations** from the consumer's combinator factories: every `<T: Sendable>` becomes `<T>`, every `@Sendable @escaping (...) -> T` becomes `@escaping (...) -> T`, every `where Output: Sendable` is dropped. The compiler will guide each strip — each removal flips a previously-required bound into a now-redundant one.
5. **Closed-world IR enums storing user-provided non-Sendable closures** (e.g. `Binary.Bytes.Machine.Instruction` with `case satisfy((UInt8) -> Bool)` cases) STAY non-Sendable under the terminal direction; under the transitional direction they MAY downgrade to `@unchecked Sendable` with a `// SAFETY:` block — but the terminal direction is preferred and matches the assembled `Parser` non-Sendable endpoint.
6. **Upstream `Builder` / `Program` over-constraints**: if upstream's `Builder` / `Program` carry struct-level `Leaf: Sendable` / `Mode: Sendable` constraints (intended only as a guard against non-Sendable Leaf instantiations under the Reference Mode), those constraints block the terminal direction. Relax them to conditional Sendable extensions (`extension Builder { } / extension Program: Sendable where Leaf: Sendable, Mode: Sendable {}`); existing Sendable-Leaf-and-Mode instantiations remain Sendable, non-Sendable instantiations become non-Sendable by construction.

**Worked example (Pattern B origin incident → terminal-direction landing)**: the `Binary.Bytes.Machine` arc — transitional landing (morning) → terminal landing (afternoon, both Cat C sites eliminated), including the prerequisite `swift-graph-primitives` conditional-Sendable relaxation and full downstream build/test verification: rationale archive §[MEM-SEND-013].

**Landed**: the `swift-parser-machine-primitives` cascade and the `Binary.Bytes.Machine` precedent landed via the terminal direction (detail: rationale archive §[MEM-SEND-013]). **Next candidates**: Any package whose Builder/Program/Parser passes through a `Machine.Capture.Mode.Reference` typealias is a candidate; choose the **terminal** direction by default (non-Sendable Mode variant + `sending` at transport) unless a consumer's `sending` discipline is genuinely impractical.

---


**Cross-references**: [MEM-SEND-001] (Conservative Sendable Defaults), [MEM-SEND-008] (No `Element: Sendable` workaround), [MEM-SEND-009] (`inout sending` for `Mutex.withLock`), [MEM-SEND-010] (`sending R` over `R: Sendable` on actor returns), [MEM-SEND-012] (protocol-layer rule this extends), [MEM-SAFE-024] (Category A/B/C/D taxonomy)

---

