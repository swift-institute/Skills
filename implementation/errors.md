# Errors

Part of the **implementation** skill. Full text of the error-strategy rules — typed throws, non-throwing specialization, typed catch blocks, and thunk parameters for callback outcomes. For the foundational axioms ([IMPL-INTENT], [IMPL-000], [IMPL-001], [IMPL-COMPILE]) and the rule index, see `SKILL.md`.

**Rules in this file**: [IMPL-040], [IMPL-042], [IMPL-075], [IMPL-092], [IMPL-093], [IMPL-108], [IMPL-109], [IMPL-112].

---

### [IMPL-040] Typed Throws and Error Types

**Statement**: The boundary between typed throws and preconditions is determined by whether the caller can reasonably check the condition. Subsumes [IMPL-041].

| Situation | Mechanism | Example |
|-----------|-----------|---------|
| Caller can check | Typed throw | `guard slot < capacity else { throw .capacityExceeded }` |
| Programming error | Precondition | `subscript(at:)` / `initialize(to:at:)` with invalid slot |

High-level tracked operations (`initialize.next`, `move.last`) throw. Low-level slot primitives (the typed `subscript(at:)`, `initialize(to:at:)`) precondition.

Error types for tracked operations MUST be nested enums per [API-ERR-001]. Cases describe the failure:

```swift
extension Storage where Element: ~Copyable {
    public enum Error: Swift.Error, Hashable, Sendable {
        case capacityExceeded
        case empty
    }
}
```

**Cross-references**: [API-ERR-001], [API-NAME-001], [IMPL-042]

**Lint enforcement**: SwiftLint custom rule `typed_throws_required` and AST rule `Lint.Rule.Throws.Untyped` together flag bare `throws` (without a typed-throws specifier) across `Sources/`; the typed-throws-required boundary is the same surface as [API-ERR-001]. [VERIFICATION: SwiftLint typed_throws_required, AST Lint.Rule.Throws.Untyped]

---

### [IMPL-042] Non-Throwing Specialization for Generic Callback APIs

**Statement**: When a public API propagates a user-supplied typed error through a generic parameter (a closure `throws(E)` or a protocol witness with `associatedtype Failure: Error`) and the callback is invoked in a hot path, the API MUST provide a specialized overload constrained to `Failure == Never`. The specialized overload MUST duplicate the implementation body — it MUST NOT forward to the generic version.

**Why**: a *generic* error parameter (e.g. `Handler.Failure` behind a generic outer type) can hide a `Never` binding from the body's codegen, so the hot path retains error-propagation scaffolding — boxing, spill slots, cleanup edges — it can never use. Duplicating the body under a `where` clause that fixes the error to `Never` compiles it in a context where the error type is *concrete*, and the compiler eliminates the scaffolding entirely — a direct application of [IMPL-COMPILE]. Full analysis: rationale archive §[IMPL-042].

```swift
public struct Parser<Sink: SAX.Handler> {
    // Generic body — propagates Sink.Failure through the per-token loop.
    public mutating func parse(bytes: Span<Byte>) throws(Parse.Error) {
        /* full body */
    }
}

extension Parser where Sink.Failure == Never {
    // Duplicated body — compiled with no error propagation through callbacks.
    public mutating func parse(bytes: Span<Byte>) throws(Parse.Error) {
        /* full body — NOT `try self.parseGeneric(bytes:)` */
    }
}
```

**Why not forward**: A `where Failure == Never` overload whose body is `try self.genericParse(bytes:)` does not specialize. The forwarded call resolves to the generic entry point, which still carries the propagation scaffolding. Specialization requires the body itself to be visible in the specialized context.

**When to apply**:

| Condition | Required |
|-----------|----------|
| Callback is invoked in a tight loop or per-element/per-token | Yes |
| Benchmarks attribute measurable cost to error propagation | Yes |
| Body is stable enough that duplication is maintainable | Yes |

If any condition fails, the duplication is unjustified — see [IMPL-001] (principled absence: no hot path, no specialization).

**Duplication hygiene**: Because the two bodies MUST stay in lockstep, place them in adjacent files or adjacent sections of the same file, mark the duplicate with a `// WHY:` comment per [PATTERN-016] that names the optimization and warns against folding, and verify SIL before merging.

**Cross-references**: [API-ERR-001], [IMPL-001], [IMPL-040], [IMPL-COMPILE], [PATTERN-016], [BENCH-*]

**Lint enforcement**: `Lint.Rule.Throws.GenericNeverSpecialization` (in `swift-foundations/swift-institute-linter-rules`, target `Institute Linter Rule Throws`) flags public generic functions / initializers declared `throws(<G>.<Sub>)` where `<G>` is a visible generic parameter, surfacing the missing specialization as a **review prompt** against the "When to apply" table above. Concrete throw types and untyped throws are not flagged; the recognizer skips `@inlinable` / `@_alwaysEmitIntoClient` declarations and declarations whose extension already contains a same-baseName `where <G>.<Sub> == Never` companion (full recognizer detail: rationale archive §[IMPL-042]). Where neither skip applies and a "When to apply" condition fails, the duplication is unjustified and the firing should be suppressed via `// swift-linter:disable:next generic throws missing never` with a `// REASON:` continuation citing the failing condition — bare suppression is forbidden per the rule corpus discipline. [VERIFICATION: AST Lint.Rule.Throws.GenericNeverSpecialization]

---

### [IMPL-075] `do throws(E)` for Typed Catch Blocks

**Statement**: Inside non-throwing contexts, use `do throws(E) { ... } catch { ... }` to preserve the concrete error type. The `catch let e as E` + `fatalError("Unexpected")` pattern is an anti-pattern.

```swift
do throws(IO.Lane.Error) {
    try lane.run { work() }
} catch {
    logger.log(error)  // error is IO.Lane.Error, not any Error
}
```

**Key distinction**: `catch let error` erases to `any Error`. The implicit `error` binding in a `do throws(E)` catch preserves `E`.

**Cross-references**: [IMPL-040], [API-ERR-001]

**Lint enforcement**: `Lint.Rule.Throws.DoCatchTyped` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Throws`) flags `do { try … } catch { … }` blocks missing the typed-throws specifier on the `do`. Wave 3 companion `Lint.Rule.Throws.DoCatchTypedThrow` covers the additional `do { throw … } catch { … }` pattern whose body has NO `try` (which the original rule misses). Together both AST rules cover the typed-`do`-`catch` discipline; the existing `no_typed_catch_let_error_where` SwiftLint rule (per [PATTERN-009]) catches the `catch let error where` mistake that this rule's "use the implicit binding" guidance prevents. [VERIFICATION: AST Lint.Rule.Throws.DoCatchTyped, Lint.Rule.Throws.DoCatchTypedThrow]

---

### [IMPL-092] `throws(E)` Thunk Parameters Over `Result<T, E>` for Callback Outcomes

**Statement**: For callback APIs that deliver one-of (value, error) to a consumer closure, the outcome MUST be expressed as a `() throws(E) -> T` thunk parameter, not as a `Result<T, E>` value. Internal storage of the outcome (where throws cannot express a not-yet-resolved value — e.g., before the thunk is invoked) MAY use `Optional`, a private enum, or a Result-shaped struct; the consumer-facing interface remains typed throws.

**Correct** — thunk parameter at the interface:
```swift
// Executor supplies the outcome as a thunk; consumer invokes with `try`.
let tick: @Sendable (
    () throws(Kernel.Event.Driver.Error) -> UnsafeBufferPointer<Kernel.Event>
) -> Outcome

// At the consumer:
loop.runInTick { wait in
    do throws(Kernel.Event.Driver.Error) {
        let events = try wait()                      // typed throws — language semantics
        self.dispatch(events)
        return .continue
    } catch {
        return self.handleFailure(error)              // error is Kernel.Event.Driver.Error
    }
}
```

**Incorrect** — Result value at the interface:
```swift
// ✗ Consumer switches on the Result instead of using `try` / `catch`.
let tick: @Sendable (Result<UnsafeBufferPointer<Kernel.Event>, Driver.Error>) -> Outcome

loop.runInTick { result in
    switch result {
    case .success(let events): self.dispatch(events); return .continue
    case .failure(let error):  return self.handleFailure(error)
    }
}
```

**Internal storage is unaffected**: executor materialises the outcome into `let count: Int` and `let error: Error?` before constructing the thunk closure. That internal representation is private; the consumer interface is `throws(E)`.

**Rationale**: `[API-ERR-001]` prescribes typed throws for functions that throw. The analogous rule for a callback *parameter* that delivers an outcome is the thunk form — it uses the language's primitive error-propagation mechanism (`try` / `catch`) instead of adding a type-level ADT. Consumer code reads as intent ([IMPL-INTENT]): "try wait; handle error." A `Result` value forces the consumer to switch on cases explicitly, which is mechanism.

**When to use `Result` instead**: when the outcome must be stored, inspected multiple times, passed across a non-throwing API boundary (e.g., into `AsyncStream.yield`), or pattern-matched in a switch that tests additional conditions besides success/failure. Storage-shape needs are legitimate — interface-shape should still be throws.

**Two-callback storage fallback for toolchain-blocked thunk composition**: when the thunk form is blocked by a compiler bug involving composed `~Copyable` + `sending` + `@Sendable` capture, internal storage MAY fall back to *two-callback storage* — separate `_onValue` and `_onError` closures — while keeping the consumer-facing interface on `throws(E)`. Two-callback storage is denotationally equivalent to a tagged union. (Failure signatures: rationale archive §[IMPL-092].)

**Requirements when applying the fallback**:

| Requirement | Why |
|-------------|-----|
| Compile-time reproducer experiment in the package's `Experiments/` | The path back when toolchains improve — without a reproducer, there is no test for "is this still needed?" |
| Revisit-trigger doc comment on the storage type citing the reproducer | Names the upstream bug inline so a future session sees it |
| Public API unchanged — factories still accept `() throws(E) -> T` or equivalent | Fallback is internal only; consumers never see the two-callback shape |

**Heuristic**: when three or more ownership/concurrency primitives layer at a single syntactic site (`~Copyable` + `sending` + `@Sendable` capture + typed-throws + `consuming`), expect a compiler bug before assuming the code shape is wrong — the failing configuration is the composition, not any single part. Detail: rationale archive §[IMPL-092].

**Cross-references**: [API-ERR-001], [IMPL-040], [IMPL-075], [IMPL-INTENT]

**Lint enforcement**: `Lint.Rule.Throws.ResultCallback` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Throws`) flags closure-typed parameters (in function/init parameters and stored properties) whose parameter type is `Result<T, E>`; function-return `Result` and top-level non-closure `Result` parameters are not flagged — those could be storage-shape uses of Result. Scope detail: rationale archive §[IMPL-092]. [VERIFICATION: AST Lint.Rule.Throws.ResultCallback]

---

### [IMPL-093] Optional-Capture Reinitialization for `~Copyable` Async Closure Boundaries

**Statement**: When moving a `~Copyable` value across an async closure boundary where the closure captures a consuming parameter (e.g., `withTaskCancellationHandler`, async Task spawns, `withCheckedContinuation` bodies), the canonical pattern is to (a) declare the parameter as a local `Optional<T>`, (b) consume the value into its destination (e.g., store in an `Entry` dictionary), then (c) reinitialize the Optional to `nil` in the outer scope after the consuming move. The compiler's ownership checker sees a valid capture-slot state for the closure's remaining lifetime.

**Correct**:
```swift
func submit(descriptor: consuming Kernel.Descriptor?) async {
    guard var descriptor else { return }
    let id = entries.insert(Entry(descriptor: consume descriptor))
    descriptor = nil  // ← reinitialize after consuming move
    return try await withTaskCancellationHandler { ... } onCancel: { ... }
}
```

**Incorrect** (rejected by compiler):
```swift
func submit(descriptor: consuming Kernel.Descriptor?) async {
    let id = entries.insert(Entry(descriptor: consume descriptor))
    // Compiler error: "missing reinitialization of closure capture after consume"
    return try await withTaskCancellationHandler { ... } onCancel: { ... }
}
```

**When the compiler error fires**: *"missing reinitialization of closure capture after consume"*. The error message literally prescribes the fix — reinitialize the Optional to `nil` after the consuming move. No new types, no ownership-primitives dependency, no `DescriptorBox` wrapper class. Pure language semantics.

**Rationale**: the consuming move transfers ownership to the destination (Entry); the nil reinitialization satisfies the ownership checker that the capture slot is valid for the closure's remaining lifetime. This is a language-level pattern, not an ecosystem-level abstraction. Origin incident: rationale archive §[IMPL-093].

**When to NOT apply**: when the closure is synchronous and the value does not cross a Task boundary, simpler consuming patterns apply. [IMPL-072] covers synchronous `~Copyable` multi-value return via Optional bundle + consuming extraction; this rule extends the pattern specifically for async-closure-boundary captures.

**Cross-references**: [IMPL-064], [IMPL-067], [IMPL-070], [IMPL-072], [IMPL-092]

---

### [IMPL-108] No `try?` — Prefer Typed Throws

**Statement**: `try?` silently discards errors. New code MUST NOT use `try?`. Existing `try?` sites SHOULD be converted to `do throws(E) { try ... } catch { ... }` with explicit typed-error handling whenever a meaningful error mode exists.

**Why**: `try?` swallows the error and produces an Optional, hiding the failure mode from the type system. Typed throws forces explicit error-case handling at the call site.

**Correct**:
```swift
do throws(IO.Error) {
    try notification.wait()
} catch let error {
    switch error {
    case .wouldBlock: continue
    case .interrupted: continue
    case .closed: return .closed
    }
}
```

**Incorrect**:
```swift
let result = try? notification.wait()  // ❌ EAGAIN/EINTR/closed all collapse to nil
```

**Legitimate `try?` exception**: best-effort cleanup paths where there is genuinely no meaningful error mode (e.g., closing a descriptor in `deinit` after the resource is already being torn down). Even then, document the WHY:

```swift
deinit {
    try? close()  // WHY: deinit cleanup; descriptor already lost on resource teardown
}
```

**Audit guidance**: when reviewing or modifying nearby code, audit `try?` sites in scope. Convertible sites → convert. Non-convertible sites → add `// WHY:` comment. Out-of-scope `try?` audits are filed separately, not folded into unrelated commits.

**Lint enforcement**: SwiftLint custom rule `no_try_optional` (`swift-institute/.github/.swiftlint.yml`) catches `try?` outside `Tests/`. Deinit-cleanup exception is opt-out via `// swiftlint:disable:next no_try_optional  // reason: <citation>`. The AST counterpart `Lint.Rule.Try` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Try`) flags `TryExprSyntax` whose `questionOrExclamationMark.tokenKind` is `.postfixQuestionMark`. Added Wave 2b 2026-05-10. [VERIFICATION: SwiftLint no_try_optional, AST Lint.Rule.Try]

**Cross-references**: [IMPL-040], [IMPL-075], [IMPL-092], [API-ERR-001]

---

### [IMPL-109] Result-Wrapper Pattern for Typed-Throws Shims Around Stdlib `rethrows`

**Statement**: When wrapping a stdlib `rethrows` API (e.g., `_Concurrency.withTaskCancellationHandler`, `Array.withUnsafeBufferPointer`, `withUnsafeTemporaryAllocation`) from a `throws(E)` outer function — adding typed-throws semantics around the stdlib's untyped propagation — the canonical shim is the **Result-wrapper pattern**: materialise the operation into `Result<T, E>` inside the closure, return it, then `try result.get()` outside the stdlib call. The `do throws(E) { return .success(try ...) } catch { return .failure(error) }` body locally types the implicit `error` as `E` per [IMPL-075], avoiding both the force-cast (`error as! E`) and the typed-catch + `preconditionFailure` patterns.

**Canonical shape**:

```swift
public func withTaskCancellationHandler<T, E: Swift.Error>(
    operation: () async throws(E) -> T,
    onCancel handler: @Sendable () -> Void
) async throws(E) -> T {
    let result: Result<T, E> = await _Concurrency.withTaskCancellationHandler {
        do throws(E) {
            return .success(try await operation())
        } catch {
            return .failure(error)
        }
    } onCancel: { handler() }
    return try result.get()
}
```

**Why this beats the alternatives**:

| Alternative | Drawback |
|-------------|----------|
| `error as! E` force-cast | SwiftLint's `NeverForceUnwrap` flags it; structurally fragile — only safe because of the `rethrows` invariant the compiler can't express |
| `catch let e as E { throw e } catch { preconditionFailure("…") }` | Two catch arms for one logical case; the `preconditionFailure` arm is unreachable scaffolding |
| Bare `try await stdlibFunction(...)` from a `throws(E)` outer | Does NOT compile — stdlib `rethrows` does not propagate typed throws (verified Swift 6.3.1: `error: thrown expression type 'any Error' cannot be converted to error type 'E'`) |
| Result-wrapper (this rule) | The `do throws(E)` annotation locally types `error` as `E` per [IMPL-075]; the closure passed to stdlib is non-throwing (returns `Result<T, E>`); `try result.get()` propagates `E` cleanly |

**Already-canonical sites in the ecosystem**: `Array.withUnsafeBufferPointer` (typed-throws overload), `withUnsafeTemporaryAllocation`, and `withTaskCancellationHandler` use this shape. The less-clean parallel pattern (typed-catch + `preconditionFailure` for the unreachable arm) SHOULD be rewritten when encountered.

**When the rule does NOT apply**: when the stdlib function ITSELF has been updated to typed throws (`throws(E)`), bare `try await stdlibFunction(...)` propagates `E` cleanly and no shim is needed. Verify via `swiftc -typecheck` if uncertain. For Swift 6.3 stdlib, this rule applies broadly (most `with*` closure-based APIs are still `rethrows`).

**Cross-references**: [IMPL-075] (`do throws(E)` for typed catch — provides the local-typing mechanism), [IMPL-092] (`throws(E)` thunk parameters — sister rule for a different API shape), [API-ERR-001] (typed throws as ecosystem-mandatory).

---

### [IMPL-112] `Either` for Cross-Cutting Error Composition, Not Domain-Polluting Cases or Custom Result Wrappers

**Statement**: Error enums MUST contain only domain cases. Cross-cutting execution conditions (interruption / EINTR, cancellation, timeout) MUST NOT be added as cases on a domain error enum. Compose them via `Either<DomainError, CrossCuttingError>` and typed throws — `Either: Error where Left: Error, Right: Error` works directly with typed throws. Custom `Kernel.Outcome`-style result wrappers MUST NOT be introduced.

**Why**: Domain error purity. `Kernel.File.Handle.Error` should have only file handle domain cases. Interruption is a cross-cutting execution condition, not a domain failure. `Either` from `swift-algebra-primitives` composes errors at the type level without polluting domain enums; it composes with typed throws via the `Error: Either where Left: Error, Right: Error` conformance. Custom result-wrapper types (`Kernel.Outcome`) reinvent what `Either` + typed throws already do.

**How to apply**: When an error type has a case that doesn't belong to its domain (like `.interrupted` on a file handle error), model the function as `throws(Either<DomainError, CrossCuttingError>)` instead. At L3, the EINTR retry wrapper catches `.right(.occurred)` and retries, re-throwing only `.left(domainError)`.

**Cross-references**: [IMPL-040], [API-ERR-001], [API-ERR-002]
