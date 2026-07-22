# Concurrency and Isolation

Part of the **implementation** skill. Full text of the concurrency, isolation, and `Sendable` rules. For the foundational axioms ([IMPL-INTENT], [IMPL-000], [IMPL-001], [IMPL-COMPILE]) and the rule index, see `SKILL.md`.

**Rules in this file**: [IMPL-062], [IMPL-066], [IMPL-068], [IMPL-069], [IMPL-073], [IMPL-076], [IMPL-083], [IMPL-085], [IMPL-088], [IMPL-091], [IMPL-098], [IMPL-099].

---

## Isolation Selection

### [IMPL-069] Isolation Hierarchy

**Statement**: Concurrency safety mechanisms MUST be selected starting from the highest rank.

| Rank | Mechanism | Compile-time guarantee | Runtime cost |
|------|-----------|----------------------|--------------|
| **1** | Actor + `nonisolated(nonsending)` | Data-race freedom | Async hop |
| **2** | `~Copyable` + `Sendable` | Single-owner transfer | Zero |
| **3** | `sending` annotation | Region-based transfer | Zero |
| **4** | `Mutex` / locking | Mutual exclusion (programmer-verified) | Lock |
| **5** | `@unchecked Sendable` | None (programmer assertion) | Zero |

Start at Rank 1. Move down only when higher rank is impossible due to a specific, documented constraint.

**Cross-references**: [IMPL-062], [IMPL-063], [IMPL-068]

---

### [IMPL-062] Prefer `nonisolated(nonsending)` Over `isolation:` Parameters

**Statement**: Async methods inheriting caller's isolation MUST use `nonisolated(nonsending)`, not `isolation: isolated (any Actor)? = #isolation` (deprecated).

**Exception**: SE-0421 protocol conformances (e.g., `AsyncIteratorProtocol.next(isolation:)`) retain the parameter.

**Scope**: `nonisolated(nonsending)` only applies to async function types. Sync closures (`map`, `filter`) cannot use it.

**Cross-references**: [IMPL-COMPILE], [MEM-SEND-001]

---

## Sendable Discipline

### [IMPL-068] Sendable Minimalism

**Statement**: Types MUST NOT conform to `Sendable` unless they genuinely cross isolation boundaries. Granting it unnecessarily forces thread-safety requirements on the type and all stored properties.

**Anti-pattern — viral Sendability**: Making type A Sendable forces all properties Sendable → forces locks on type B → forces inner State structs → forces `withLock` everywhere → deadlock risk. Root cause: Sendable granted without need.

**Fix**: Keep non-Sendable by default. Use `nonisolated(nonsending)` to pass through function chains.

**Cross-references**: [IMPL-062], [IMPL-063]

---

### [IMPL-076] No @unchecked Sendable on Struct-Wrapping-Class

**Statement**: When a struct's only stored property is a `Sendable` class, the struct MUST use plain `Sendable` — not `@unchecked Sendable`. The `@unchecked` is redundant and misleading.

**Cross-references**: [IMPL-068], [IMPL-069], [MEM-SEND-002]

**Lint enforcement**: `Lint.Rule.Memory.StructSendableClassMember` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Memory`) flags `struct: @unchecked Sendable` declarations whose member block contains a class-typed stored property (narrow class-name heuristic). Scope detail: rationale archive §[IMPL-076]. [VERIFICATION: AST Lint.Rule.Memory.StructSendableClassMember]

---

## Boundary Transfers

### [IMPL-066] `sending` at Isolation Boundaries

**Statement**: Parameters and return values crossing isolation boundaries MUST use `sending`.

| Boundary | Annotation |
|----------|------------|
| Value enters actor | `sending` on parameter |
| Value exits actor | `sending` on return |
| Value enters `Mutex.withLock` | `sending` on closure parameter |
| Channel send / fulfill | `sending` on payload |

**Cross-references**: [IMPL-COMPILE], [IMPL-062]

---

### [IMPL-085] Prefer `sending` + `nonisolated(unsafe)` Over `@unchecked Sendable` for Locked Transfer

**Statement**: When transferring a value across region boundaries and a lock provides the synchronization, the value MUST be passed with `sending` (at the API boundary) and stored behind `nonisolated(unsafe)` (inside the synchronized container). `@unchecked Sendable` on the transferred type MUST NOT be used as a substitute.

**Correct** — scoped unsafe promise, lock-enforced:
```swift
final class Slot<Value: ~Copyable> {
    private let mutex: Mutex<()>
    nonisolated(unsafe) private var _value: Value?     // ✓ unsafe scope bounded by mutex
    func fulfill(_ value: sending Value) {             // ✓ sending at the boundary
        mutex.withLock { self._value = value }
    }
}
```

**Incorrect** — type-wide unsafe promise:
```swift
struct Handle: @unchecked Sendable {                   // ✗ asserts safety everywhere
    let value: Value                                    //   even where no lock exists
}
```

**Rationale**: `@unchecked Sendable` is rank 5 in the isolation hierarchy ([IMPL-069]) — strictly the last resort. `sending` + `nonisolated(unsafe)` is the region-based transfer (rank 3) with a narrowly scoped unsafe assertion. When a lock already provides synchronization, the region transfer can be honestly expressed without elevating the type's shareability.

**Cross-references**: [IMPL-066], [IMPL-068], [IMPL-069], [IMPL-076], [MEM-SAFE-024] (Category D: `@unchecked Sendable` as structural workaround — when sending+nonisolated(unsafe) is not applicable)

---

## Closure Inference

### [IMPL-073] SE-0461 @concurrent Inference Is Body-Sensitive

**Statement**: Under SE-0461, `@concurrent` default for `@Sendable async` closures only triggers when the closure body contains `await`. A sync closure promoted to async does NOT trigger `@concurrent`.

| Closure Body | Parameter Type | Inference |
|-------------|---------------|-----------|
| Contains `await` | `@Sendable async` | `@concurrent` |
| No `await` | `@Sendable async` | Sync→async promotion, no `@concurrent` |
| Any | `nonisolated(nonsending)` | Explicitly non-concurrent |

**Validated by**: `swift-institute/Experiments/se0461-concurrent-body-sensitivity/`

**Cross-references**: [IMPL-062]

---

## Lock Composition

### [IMPL-088] Lock-Ordering Analysis for Multi-Lock Compositions

**Statement**: Any composition that may hold two locks simultaneously MUST document a total ordering — lock A is always acquired before lock B — or MUST NOT hold both at once. The default posture is separate lock scopes. Acquiring lock B while holding lock A without a documented global ordering is an ABBA-deadlock candidate.

**Decision procedure**:

1. For each method, enumerate the locks held at each point in its body.
2. For each type that holds a lock and calls a method on another lock-holding type, check whether the callee may acquire its own lock.
3. If the call sequence produces "A then B" in one method and "B then A" in another (same types or across types), that is an ABBA deadlock.
4. Prefer separating lock scopes: acquire A, release A, then acquire B. Store the value extracted under A as a local; use it under B.

**Correct** — separated lock scopes:
```swift
func dispatch(_ job: Job) {
    let worker = cursor.advance(within: count)       // no lock held
    workers[worker].enqueue(job)                     // worker's lock acquired in isolation
}
```

**Incorrect** — ABBA via nested locks:
```swift
func trySteal(from other: Worker) {
    self.lock.withLock {                             // A acquired
        other.lock.withLock {                        // B acquired while holding A
            // if another thread simultaneously does other.trySteal(from: self)
            // with B first then A, both deadlock.
        }
    }
}
```

**Rationale**: ABBA deadlocks are invisible at the dispatch site and surface only when two threads hit the cross-lock interaction simultaneously; separated scopes are the default because they require no global ordering invariant. Full rationale: rationale archive §[IMPL-088].

**Cross-references**: [IMPL-063], [IMPL-069], [IMPL-COMPILE]

---

## Executor and Actor Bridging

### [IMPL-083] Custom-Executor-to-Actor Bridge Pattern

**Statement**: When a custom `SerialExecutor` owns an OS thread running a synchronous event loop and the tick callback must reach actor-isolated state, the bridge MUST use the SE-0424 mechanism — `isIsolatingCurrentContext()` override on the executor + `assumeIsolated` in the tick body — combined with a local weak-box class captured by the tick to break the definite-init trap. The SE-0424 pieces are designed bridges, NOT workarounds; the weak-box is the minimum-viable workaround for Swift 6.3's DI rule.

**The triad**:

| Piece | Classification |
|-------|---------------|
| `isIsolatingCurrentContext() -> Bool?` returning "is current thread the executor's thread" on the executor class | Designed bridge (SE-0424) |
| `assumeIsolated { isolated in … }` inside the tick body | Designed bridge (SE-0424) |
| Local `Handle` class with `weak var actor: MyActor?`, captured by tick, tail-assigned `handle.actor = self` after the executor is initialized | Minimum-viable workaround |

**Why Handle is required**: self-capture in the tick closure (the RHS of a stored-property assignment in the actor's init) is rejected by Swift 6.3's DI rule because `self.executor` is not yet initialized; a local `let handle = Handle()` captured by the tick sidesteps DI, and the tail `handle.actor = self` runs after all stored properties are assigned. Full walkthrough: rationale archive §[IMPL-083].

**Closed avenues on Swift 6.3**: nine alternative shapes probed and rejected — survey: rationale archive §[IMPL-083].

**Only known elimination path on Swift 6.3**: two-phase executor API — `init(source:)` + `public func start(tick:)`. Adds one public method to the executor. Requires explicit owner approval given the API surface growth. See `swift-institute/Experiments/polling-two-phase-api/` (CONFIRMED).

**Reference implementation**: `swift-executors/Sources/Executors/Kernel.Thread.Executor.Polling.swift` (executor with SE-0424 hooks + `sending @escaping` tick + `@safe` class); `swift-io/Sources/IO Events/IO.Events.Actor.swift` (actor using the bridge); `swift-io/Sources/IO Events/IO.Events.Actor.Handle.swift` (weak-box).

**Cross-references**: [IMPL-066], [IMPL-069], [IMPL-COMPILE], [PATTERN-016], SE-0424

---

### [IMPL-091] Materialise Before Crossing Region Boundaries

**Statement**: When a task-isolated closure parameter must produce a value consumed inside an actor-isolated `assumeIsolated` region, the closure MUST be invoked OUTSIDE the actor-isolated region, its result bound to `Sendable` local variables, and those locals consumed INSIDE the region. Invoking the closure inside the region triggers region-analysis errors that are compile-time artifacts, not runtime safety violations.

**The pattern**:
```swift
// Task-isolated tick parameter, actor-isolated handler.
executor.run { [weak self] wait in                    // wait: task-isolated
    guard let self else { return .halt }

    // Materialise: call the closure OUTSIDE assumeIsolated.
    let events: UnsafeBufferPointer<Kernel.Event>
    let waitError: Driver.Error?
    do throws(Driver.Error) {
        events = try wait()                           // ✓ called at tick scope
        waitError = nil
    } catch {
        events = UnsafeBufferPointer(start: nil, count: 0)
        waitError = error
    }

    // Cross: consume Sendable locals INSIDE assumeIsolated.
    self.assumeIsolated { isolated in
        if let waitError { isolated.handleFailure(waitError) }
        else              { isolated.dispatchEvents(events) }
    }
}
```

**Why the naive form fails**:
```swift
// ✗ sending 'wait' risks causing data races — region analysis rejects this.
self.assumeIsolated { isolated in
    let events = try wait()                            // closure crosses actor boundary
    isolated.dispatchEvents(events)
}
```

**Rationale**: compile-time region analysis and the runtime `isIsolatingCurrentContext` verification ([IMPL-083]) operate at different abstraction levels and both must be satisfied; materialising the result into `Sendable` locals is the generic bridge — the locals cross the region boundary freely and the closure body only reads them. Full rationale: rationale archive §[IMPL-091].

**Constraints on the locals**: they MUST be `Sendable`. `UnsafeBufferPointer<T> where T: Sendable` qualifies. For ~Copyable intermediates, the closure body must do the entire work inside the outer scope; only Sendable primitives / pointers may cross the boundary.

**Cross-references**: [IMPL-066], [IMPL-069], [IMPL-083], [IMPL-COMPILE]

---

### [IMPL-098] Unmanaged Self-Retention as Code Smell

**Statement**: When a class uses `Unmanaged.passRetained(self)` / `takeRetainedValue()` to bridge `self` through a C callback, the pattern SHOULD be treated as a code smell suggesting the ownership boundary is in the wrong place. Investigate whether the state could live in an actor (removing the `self` bridge entirely) or whether the C callback could be replaced with a Swift-native mechanism (`for await`, continuations, `@Sendable` closures).

**When the pattern is actually correct**: when `self` must survive an unbounded-duration C callback that the runtime itself manages (e.g., `dispatch_source_create`-style APIs where the cancellation handler is the only release path). Flag the unmanaged retain with a comment explaining why it's necessary.

**Rationale**: Unmanaged retention puts the burden of retain/release balance on code the Swift compiler cannot check. If the ownership boundary is moveable (actor state, `AsyncSequence` bridge), that's strictly safer than hand-balanced unmanaged references. Teams adopting the pattern by default accumulate a "known but not reviewed" class of lifetime bug; flagging it as a smell forces a justification at introduction time.

**Cross-references**: [IMPL-067], [MEM-SAFE-*]

---

### [IMPL-099] Fake Startup-Gate Pattern in Test Doubles

**Statement**: When a Fake replaces a blocking kernel wait (e.g., a Fake for `kqueue.wait`, `epoll.wait`, `IO_uring.submit_and_wait`), the Fake's drain MUST gate on a condvar or similar synchronization primitive until the actor's init has completed. Returning from the Fake's `wait` before the actor is fully initialized produces tests that pass under one scheduler and fail under another.

**Reason**: The real kernel wait synchronizes producer and consumer threads implicitly (the wait returns only when events are queued, by which time the actor is running). The Fake has no such implicit synchronization; without an explicit startup gate, the Fake can return to the caller before the actor init has completed, and subsequent assertions observe partial initialization state.

**Cross-references**: [IMPL-083]
