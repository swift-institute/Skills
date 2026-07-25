## Error Handling

**Enforcement**: TEXT-ONLY (insufficient grounding — brand-owner membership needs a curated list; /promote-rule 2026-07-06). Re-promotable via a ratified brand-owner list (`.naming-vocabulary` pattern): `Audits/PROMOTE-API-BRAND-001-2026-07-06.md`.

### [API-ERR-001] Typed Throws Required

All throwing functions MUST use typed throws.

```swift
// CORRECT
func read() throws(IO.Error) -> Data
func parse() throws(Parse.Error) -> Document

// INCORRECT
func read() throws -> Data       // Erases error type - FORBIDDEN
func parse() throws(any Error)   // Existential error - FORBIDDEN
```

**Lint enforcement**: SwiftLint custom rule `typed_throws_required` (`swift-institute/.github/.swiftlint.yml`) flags `throws` without a typed-throws specifier in `Sources/`; AST counterpart `Lint.Rule.Throws.Untyped` flags any throws clause whose type is `nil` (covers `func f() throws` and `func g() async throws -> T`). The existential-throws sub-case (`throws(any Error)`) is handled separately per [API-ERR-006]. [VERIFICATION: SwiftLint typed_throws_required, AST Lint.Rule.Throws.Untyped]

**⚠️ Discarding a throw from an UNTYPED callee — no construct satisfies every rule.** `Lint.Rule.Try.Optional` also cites this ID when it flags `try?`, and its remedy (`do { … } catch { }`) is correct ONLY when the callee's error is typed. When the callee throws untyped — cross-module APIs such as `FileManager.removeItem(at:)` or `try await task.value` — every expressible form violates something:

| form | fires |
|---|---|
| `try? x()` | `try optional` — this rule |
| `do { try x() } catch { }` | `do throws for typed catch` [IMPL-075] |
| `do throws(any Error) { try x() } catch { }` | `existential throws` [API-ERR-006] |
| `do throws(E) { … }` | does not compile — there is no `E` |

The escape is **not** a code change: keep the `try?` (or the bare `do`/`catch`) and apply `// swift-linter:disable:next try optional` with a `// REASON:` naming the untyped callee. **No lint rule can decide this for you**: a per-file AST rule can prove a callee *typed* (declared in-file with a typed throws clause) but can never prove it *untyped*, because those callees are cross-module and unresolvable from a parsed source. The author is the only party who can evaluate the condition, which is why this is documented rather than carved out in a predicate — softening [IMPL-075] would license the typed-callee case, where both rules are satisfiable together and behave correctly.

**Applied at**: `swift-institute/Workspace`, target `Application` — 7 of its 11 live `try?` sites are bare `try? FileManager.default.removeItem(…)` in `defer`/statement position (untyped callee, discard intended); the other 4 are value-fallback (`(try? …) == true`, `!= nil`) where `try?` is the intent rather than a discard. Measured 2026-07-25 against `try optional: 11` at `93 rules · 55 files · 117 violations`. Converting a site to an institute-typed callee resolves it outright (−1 `try optional`, +0 elsewhere); converting to a Foundation callee is net-zero (−1 `try optional`, +1 [IMPL-075]).

---

### [API-ERR-002] Nested Error Types

Error types MUST be nested as `Domain.Error` following [API-NAME-001]. The conformance MUST qualify the standard library protocol explicitly as `Swift.Error` per [PLAT-ARCH-011], even though the type's own name is the bare `Error` token.

```swift
// CORRECT
enum IO {
    enum Error: Swift.Error {
        case posix(errno: CInt, operation: Operation, path: FilePath)
        case timeout(duration: Duration, operation: Operation)
    }
}

// INCORRECT
enum IOError: Error {           // Compound name - FORBIDDEN
    case posix(...)
}
```

**Lint enforcement**: The `swift_error_qualification` SwiftLint custom rule (`swift-institute/.github/.swiftlint.yml`) flags bare `Error` references that should be `Swift.Error`; declaration tokens (`enum Error:`, etc.) are exempt. Reference sites inside an extension MUST use the fully-nested type (e.g., `Random.Error`, `Storage.Pool.Error`). `Self.Error` is forbidden in `throws(...)` clauses outside protocol declarations carrying `associatedtype Error`. The AST counterpart `Lint.Rule.Platform.SwiftQualification` (per [PLAT-ARCH-011] / [PLAT-ARCH-022]) subsumes this regex for the `Error` token. [VERIFICATION: SwiftLint swift_error_qualification]

---

### [API-ERR-003] Describe Failure, Not Recovery

Error cases SHOULD describe the failure condition, not the recovery action.

```swift
// CORRECT
case invalidHeader(expected: UInt32, found: UInt32)
case insufficientCapacity(required: Int, available: Int)
// INCORRECT
case retryLater              // Describes recovery, not failure
case useDefaultValue         // Describes recovery, not failure
```

---

### [API-ERR-004] Explicit Closure Annotation for Typed Throws

**Statement**: When calling a stdlib `rethrows` function from a `throws(E)` context, the closure MUST include an explicit `throws(E)` annotation. Without it, Swift 6.2 infers `any Error`, erasing the typed throw.

**Correct**:
```swift
func transform<E: Error>(_ values: [Int], using f: (Int) throws(E) -> String) throws(E) -> [String] {
    try values.map { (value: Int) throws(E) -> String in
        try f(value)
    }
}
```

**Incorrect**:
```swift
func transform<E: Error>(_ values: [Int], using f: (Int) throws(E) -> String) throws(E) -> [String] {
    try values.map { try f($0) }  // Infers `any Error`, not E
}
```

**Lint enforcement**: `Lint.Rule.Throws.ClosureAnnotation` flags closures containing `try` inside typed-throws functions when the closure signature lacks a typed `throws(...)` annotation; closures without `try` and closures inside untyped `throws` outer functions are exempt. Scope detail: rationale archive §[API-ERR-004]. [VERIFICATION: AST Lint.Rule.Throws.ClosureAnnotation]

### [API-ERR-005] stdlib Typed Throws Compatibility (Swift 6.2.4)

**Statement**: Only a subset of stdlib `rethrows` functions preserve typed throws. Do NOT add `@_disfavoredOverload` overloads for functions that already work — they interfere with the stdlib's native support. [VERIFICATION NEEDED 2026-05-10: lists pinned to Swift 6.2.4; revalidate against Swift 6.3.1+. Experiment dispatched separately per [EXP-012].]

**Works with explicit `throws(E)` closure** (Swift 6.2.4):
- `Sequence.map`, `withUnsafeBytes(of:)`, `withUnsafeMutableBytes(of:)`, `Mutex.withLock`

**Does NOT preserve typed throws** (rethrows still erases E):
- `compactMap`, `flatMap`, `filter`, `forEach`, `reduce`, `contains(where:)`, `allSatisfy`, `first(where:)`, `sorted(by:)`, `min(by:)`, `max(by:)`, `drop(while:)`, `prefix(while:)`

**Rationale**: Partial stdlib support is undocumented. Adding same-name overloads causes the rethrows version to be selected, which is strictly worse than no overload.

---

### [API-ERR-006] No Existential Throws Ever

**Statement**: Existential throws (`throws`, `throws(any Error)`) are FORBIDDEN — [API-ERR-001] requires typed throws and is non-negotiable; when a stored closure can throw user-domain errors, make the containing type generic over the error type rather than leaving it untyped.

**Correct**:
```swift
public struct Pool<Resource: ~Copyable, CreateError: Swift.Error>: ~Copyable {
    private let create: () throws(CreateError) -> Resource

    public func acquire() throws(CreateError) -> Resource { try create() }
}
```

**Incorrect**:
```swift
public struct Pool<Resource: ~Copyable>: ~Copyable {
    // DESIGN: closure may throw user errors, leaving untyped — ❌ deferred fix, not resolution
    private let create: () throws -> Resource
}
```

**Lint enforcement**: SwiftLint custom rule `no_existential_throws` catches `throws(any Error)`; companion rule `no_any_protocol_existential` extends the discipline to `any <Protocol>` references generally in `Sources/`; AST counterpart `Lint.Rule.Throws.Existential` flags `throws(any Error)` / `throws(any Swift.Error)`. Scope detail: rationale archive §[API-ERR-006]. [VERIFICATION: SwiftLint no_existential_throws, AST Lint.Rule.Throws.Existential]

**Cross-references**: [API-ERR-001], [API-ERR-002]

---

### [API-ERR-007] Public API Path for Error Types, Not Hoisted Internals

**Statement**: When referencing error types in `throws(...)` clauses from extension-declared nested types, use the fully-qualified module path with explicit generic parameters. Never reference the `__` prefixed hoisted type directly.

**Correct**:
```swift
extension Dictionary_Primitives_Core.Dictionary.Ordered.Bounded {
    public func insert(...) throws(Dictionary_Primitives_Core.Dictionary<Key, Value>.Ordered.Bounded.Error) { ... }
}
```

**Incorrect**:
```swift
extension Dictionary_Primitives_Core.Dictionary.Ordered.Bounded {
    public func insert(...) throws(__DictionaryOrderedBoundedError<Key>) { ... }  // ❌ hoisted internal
}
```

**Lint enforcement**: `Lint.Rule.Throws.HoistedError` flags `throws(T)` clauses on `public` / `open` functions and initializers whose leaf identifier starts with `__` (hoisted internal leaking into the public surface); single-underscore prefixes, non-public visibility, and untyped `throws` are exempt. Scope detail: rationale archive §[API-ERR-007]. [VERIFICATION: AST Lint.Rule.Throws.HoistedError]

**Cross-references**: [API-ERR-001], [API-NAME-001]

---

### [API-ERR-008] Lifecycle Typealias Only When ALL Cases Apply

**Statement**: A typealias from a per-primitive error type to a shared lifecycle-error type (`Async.Lifecycle.Error`, `Pool.Lifecycle.Error`, etc.) MUST be adopted only when ALL cases of the lifecycle type are produced by the primitive; if some cases would be unreachable, keep the per-primitive enum with only the cases actually produced.

**Lint enforcement**: `Lint.Rule.Throws.LifecycleTypealiasReview` flags `typealias Error = <…>.Lifecycle.Error` shapes; case coverage cannot be verified mechanically — the flag surfaces the decision as a review prompt. Scope detail: rationale archive §[API-ERR-008]. [VERIFICATION: AST Lint.Rule.Throws.LifecycleTypealiasReview]

**Cross-references**: [API-ERR-001], [API-ERR-002]

---

### [API-ERR-009] No Phantom-Generic Error Types in Typed Throws

**Statement**: An error type used in typed throws MUST NOT be nested in a generic type whose parameter it never uses. A non-payload `enum Error` nested in `Parse<Input>` is *accidentally* generic: the `@error` SIL result carries a type parameter, which trips `FunctionSignatureOpts` (`SILArgument.cpp:40 !type.hasTypeParameter()`) under stock `-O -enable-default-cmo`, aborting the release build of the package AND of every consumer (swiftlang/swift#89617; a build-blocker on 6.2 through 6.5-dev, not nightly-only). Hoist the enum to non-generic module scope and keep a `public typealias Error` on the generic type so the nested spelling still resolves — behaviour-preserving, because the cases never used the parameter.

**Incorrect**:
```swift
public struct Parse<Input> {
    public enum Error: Swift.Error { case expectedPeriod }   // ❌ phantom <Input>
}
extension Parse: Parser.`Protocol` {
    public typealias Failure = Parse<Input>.Error
}
```

**Correct**:
```swift
public enum __JWTParserError: Swift.Error { case expectedPeriod }
extension Parse { public typealias Error = __JWTParserError }   // nested spelling preserved
extension Parse: Parser.`Protocol` {
    public typealias Failure = __JWTParserError                 // signature no longer parameterised
}
```

**Shape is necessary but not sufficient**: the crash additionally requires an eliminable argument for the optimizer to build a signature-optimized thunk, which is a SIL-level property no syntactic check can see. `swift-rfc-2045` carries the byte-identical shape and builds clean; `swift-rfc-9110` crashed. Treat a finding as a candidate and confirm with a release build — never as proof of breakage, and never as proof of safety.

**Lint enforcement**: `Lint.Rule.Throws.PhantomGenericError` uses two detectors whose union is required: a *declaration-site* detector (non-generic `Error`/`Failure` enum with cases, nested in a generic type visible in the same file, cases never using the parameter outside a generic-argument list) and a *use-site* detector (typed-throws position naming a member type whose base carries generic arguments). Neither suffices alone — `swift-w3c-xml` spells its clauses bare (`throws(Error)`), and `swift-iso-8601` / `swift-rfc-9110` declare the enum in a separate file, which a per-file rule cannot resolve. Reachability is deliberately NOT gated: the enum and its `typealias Failure` routinely live in different files, so a same-file gate would have certified `swift-rfc-9110` clean while it was crashing. Fires at `.warning`; a use-site finding on an already-hoisted type means only the spelling is stale. Scope detail: rationale archive §[API-ERR-009]. [VERIFICATION: AST Lint.Rule.Throws.PhantomGenericError]

**Cross-references**: [API-ERR-001], [API-ERR-007]

---
