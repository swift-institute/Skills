# Expression Style and Component Shape

Part of the **implementation** skill. Full text of the expression-style rules and the architectural-shape rules that apply at the call-site and component level. For the foundational axioms ([IMPL-INTENT], [IMPL-000], [IMPL-001], [IMPL-COMPILE]) and the rule index, see `SKILL.md`.

**Rules in this file**: [IMPL-EXPR-001], [IMPL-033], [IMPL-034], [IMPL-035], [IMPL-036], [IMPL-037], [IMPL-084], [IMPL-086], [IMPL-087], [IMPL-101], [IMPL-102], [IMPL-103], [IMPL-104], [IMPL-105], [IMPL-110], [IMPL-111].

---

## Expression Style

### [IMPL-EXPR-001] Prefer Single Expressions Over Intermediate Bindings

**Statement**: Implementation code MUST prefer single-line expressions over separate `let`/`var` declarations and inline construction over intermediate variables. Subsumes [IMPL-030].

**Boundary conditions** (the only valid reasons for an intermediate binding):

1. **Multi-use**: The sub-expression is consumed more than once.
2. **Explanatory name**: The name communicates domain knowledge not visible in the expression.
3. **Complexity ceiling**: Extract a named function (Fowler's "Replace Temp with Query"), not a local variable.

**Perfect** — single expression reads as intent:
```swift
unsafe destination.pointer(at: offset)
    .initialize(from: base.pointer(at: range.lowerBound), count: range.count)
```

**Imperfect** — separate declarations expose mechanism:
```swift
let srcPointer = unsafe base.pointer(at: range.lowerBound)
let dstPointer = unsafe destination.pointer(at: offset)
let count = range.count
unsafe dstPointer.initialize(from: srcPointer, count: count)
```

**Cross-references**: [IMPL-INTENT]

**Lint enforcement**: `Lint.Rule.Idiom.IntermediateBindingThenReturn` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Idiom`) walks `CodeBlockItemListSyntax` and flags adjacent `let <name> = <expr>` followed by `return <name>` where the binding has no explicit type annotation and a single binding pattern. Explicit type annotations (read as explanatory name), `var` bindings (mutation indicates real use), multi-use cases (binding used before return), and `return <different-expr>` are not flagged. Added Wave 4 mechanization 2026-05-11. [VERIFICATION: AST Lint.Rule.Idiom.IntermediateBindingThenReturn]

---

### [IMPL-033] Iteration: Intent Over Mechanism

**Statement**: Iteration MUST use the highest-level abstraction that expresses intent. Subsumes [IMPL-031] (enum iteration) and [IMPL-032] (bulk operations).

| Level | Style | When |
|-------|-------|------|
| **1. Bulk operation** | `set.range()`, `deinitialize(count:)` | Uniform operation on a range |
| **2. Iteration infra** | `.forEach { }`, `.reduce.into { }`, `.linearize { }` | Per-element logic |
| **3. Typed while loop** | `while slot < end { slot += .one }` | Inside iteration infra only |
| **4. Raw while loop** | Forbidden | Never |

When no iteration infrastructure exists: per [IMPL-000], add `.forEach`, `.reduce`, or the appropriate method, then use it. See [INFRA-107], [INFRA-108], [INFRA-022].

**Lint enforcement**: `Lint.Rule.Idiom.IterationIntent` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Idiom`) flags `for <i> in <a>..<<b>` counter loops with a simple identifier binding — index-counted iteration is mechanism. Direct iteration (`for element in items`), `enumerated()`, `stride(from:to:by:)`, and `forEach { ... }` are not flagged. Tuple-pattern bindings (e.g., zip iteration) are out of scope. Added Wave 3 mechanization 2026-05-11. [VERIFICATION: AST Lint.Rule.Idiom.IterationIntent]

---

### [IMPL-034] unsafe Keyword Placement

**Statement**: `unsafe` MUST wrap the entire expression from the left. It cannot appear to the right of a non-assignment binary operator.

```swift
guard unsafe slot < base.pointee.slotCapacity else { throw .capacityExceeded }  // ✓
guard slot < unsafe base.pointee.slotCapacity else { ... }                       // ✗
```

**Lint enforcement**: SwiftLint custom rule `no_unsafe_block_form` (`swift-institute/.github/.swiftlint.yml`) flags the `unsafe { … }` block form that conflicts with the expression-wrap discipline. The AST counterpart `Lint.Rule.Unchecked` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Unchecked`) flags the related `__unchecked:` call-site argument label (the call-site sibling concern per the same expression-shape discipline). [VERIFICATION: SwiftLint no_unsafe_block_form, AST Lint.Rule.Unchecked]

---

### [IMPL-035] Uniform Execution Model

**Statement**: When computation is deferred to a work queue or stack, ALL items at the same structural level MUST use the same execution model. Mixing immediate and deferred execution creates ordering violations invisible at the dispatch site.

**Cross-references**: [IMPL-INTENT]

---

### [IMPL-036] Minimal Storage for Deferred Computation

**Statement**: When ownership prevents storing a computed value (`~Copyable` or `~Escapable`), store the minimum necessary to *recompute* it. The storable unit is typically the source (often `Copyable`) rather than the result (often `~Copyable`). Generalized: when you cannot store X, find Y where X = f(Y) and store Y.

**Cross-references**: [MEM-COPY-005], [MEM-COPY-012]

---

### [IMPL-037] String Interpolation as Type Bridge

**Statement**: When a type conforms to `ExpressibleByStringLiteral` and also has `init(_:) throws`, Swift selects the literal conformance unconditionally — even inside `try`. The non-throwing bridge for String variables is interpolation: `"\(stringVar)"`.

---

## Component Shape

### [IMPL-084] Single-Inhabitant Namespaces — See [API-NAME-001a]

**Statement**: A namespace enum containing exactly one type is not a namespace — it is a variant label. This is a naming concern; the canonical rule lives in the **code-surface** skill as [API-NAME-001a] Single-Type-No-Namespace Rule.

**When this comes up in implementation**: The refactor — collapse `Outer.Middle.Only` → `Outer.Middle`, or preserve `Outer.Middle` when it is a variant label under a sibling-having parent (`Executor.Cooperative` alongside `Executor.Stealing`, `Executor.Scheduled`) — is an implementation of the naming rule. See [API-NAME-001a] for the canonical decision procedure and examples.

**Cross-references**: [API-NAME-001a] (canonical), [PATTERN-013], [IMPL-INTENT]

**Lint enforcement**: `Lint.Rule.Naming.SingleTypeNamespace` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Naming`) flags caseless-enum namespaces containing exactly one nested type declaration (with typealiases permitted as sibling labels). Conservative per-file detection — a namespace appearing single-typed here may have siblings in extensions across other files; the flag is a review prompt. Real enums (with cases), structs, and classes are out of scope. Added Wave 3 mechanization 2026-05-11. [VERIFICATION: AST Lint.Rule.Naming.SingleTypeNamespace]

---

### [IMPL-086] Deletion-First Structural Fix

**Statement**: When a bug is in a runtime-checked invariant, the first question MUST be "is the invariant itself load-bearing?" — not "how do I enforce this invariant via the type system?" If the invariant exists because we wrote it (not because it is semantically required), deleting the check, the code that maintains it, and the tests that exercise it is often the right structural fix. Language-level enforcement is the answer only when the invariant is semantically load-bearing.

**Decision procedure**:

1. Identify the runtime check failing (the invariant).
2. Ask: *"What breaks if I delete the check and everything that depends on its correctness?"*
3. If the answer is "a test and a looser contract," deletion is the structural fix.
4. Only if the answer is "memory safety / correctness / user-facing contract," escalate to type-system enforcement (`~Copyable`, `~Escapable`, capability tokens).

**Correct** — delete the invariant when it is not load-bearing:
```swift
// Before: actor tracks state enum + runtime checks on every access
// After: state enum removed, checks removed, tests asserting "throws after shutdown" removed.
// The actor's post-shutdown contract is now "undefined"; no runtime-visible regression.
```

**Incorrect** — escalate to type-system enforcement without questioning the invariant:
```swift
// Proposed fix cycle: ~Copyable → scope methods → Channel API change → idempotency contract.
// Each proposal adds structure to maintain an invariant that was never load-bearing.
```

**Rationale**: invariants are either load-bearing (deletion breaks memory safety, user contracts, or compositional correctness) or author-imposed; the author-imposed class is surprisingly common in actor-based designs where state machines accumulate. Full rationale: rationale archive §[IMPL-086].

**Diagnostic signal**: If proposals to fix a bug keep iterating on "add more structure" (slip pattern → L1 scope methods → L2 Channel API → idempotency), and each iteration surfaces new latent issues, the structural fix is probably deletion, not addition. Addition-fatigue is evidence.

**Cross-references**: [IMPL-COMPILE], [IMPL-063], [PATTERN-016]

---

### [IMPL-087] Question Whether the Component Needs to Exist

**Statement**: Before designing how a component should work, ask whether it needs to exist at all. This is [IMPL-000] (call-site-first design) applied at the architectural level: the right first question is *"does this need to exist?"*, not *"how should this be implemented?"*. A component that has no data-contract consumer, or whose work is already performed by an existing component, MUST NOT be built on the assumption that the conventional pattern requires it.

**Decision procedure** — for any proposed new component:

1. Identify the specific operation the component must perform.
2. Identify the specific consumer that will invoke that operation.
3. Ask: *"Is there an existing component that already runs at the right time with the right resources?"*
4. If yes, piggyback — add the operation to the existing component.
5. If no, ask: *"Is this component required by the paradigm, or by convention copied from other frameworks?"*
6. Build only what the paradigm requires, not what the convention suggests.

**Correct** — the component is not built because it is not required:
```swift
// io_uring completions discoverable via eventfd + epoll.
// The existing IO.Event.Loop already blocks on epoll.
// → No IO.Completion.Loop with its own poll thread.
// → Completion discovery is a free piggyback on the existing blocking wait.
```

**Incorrect** — the component is built because every framework has one:
```swift
// IO.Completion.Loop with its own OS thread, its own executor, its own shutdown machinery.
// Reasoning: "io_uring is a backend, backends need poll threads."
// Root cause: convention from frameworks that predated eventfd integration.
```

**Rationale**: framework convention ("every backend needs an event loop") creates implicit premises that modern kernel interfaces were designed specifically to invalidate; building on the inherited convention reproduces older paradigms' constraints inside a newer one. Full rationale: rationale archive §[IMPL-087].

**Cross-references**: [IMPL-000], [IMPL-INTENT], [IMPL-060], [IMPL-074]

---

### [IMPL-094] Chained Property Access on `borrowing Self` Parameters (Swift 6.3)

**Statement**: On operator overloads with `borrowing Self` parameters, Swift 6.3 rejects chained property access via short-circuit operators (`&&`, `||`) — the borrow scope becomes incoherent across the short-circuit boundary. Use one of two compiler-accepted alternatives:

1. **Tuple comparison**: `(lhs.a, lhs.b) < (rhs.a, rhs.b)`
2. **Local `let`-bindings**: `let la = lhs.a; let lb = lhs.b; ...; return la < ra || (la == ra && lb < rb)`

Avoid the rejected form:

```swift
// Rejected on Swift 6.3 with "borrowed value escapes its borrow scope":
public static func < (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
    lhs.priority < rhs.priority || (lhs.priority == rhs.priority && lhs.sequence < rhs.sequence)
}
```

**Rationale**: The Swift 6.3 compiler's borrow analysis treats chained property reads across `||` / `&&` as separate borrow scopes that cannot share the initial borrow. Tuple comparison collapses the two reads into one borrow; local bindings materialize the needed values before the short-circuit. The rule is compiler-enforced, not stylistic.

**Lint enforcement**: `Lint.Rule.Memory.BorrowingSelfShortCircuit` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Memory`) walks operator `FunctionDeclSyntax` (name kind `.binaryOperator`) whose parameter list contains at least one `borrowing Self`. If the body contains `&&` or `||`, the operator position is flagged. Non-operator functions and operators on non-`borrowing Self` parameters are out of scope. Added Wave 3 mechanization 2026-05-11. [VERIFICATION: AST Lint.Rule.Memory.BorrowingSelfShortCircuit]

**Cross-references**: [IMPL-EXPR-001]

---

### [IMPL-097] Nested-Generic-Dispatch for Overload-Resolution Shadowing

**Statement**: When a more-specific overload's body needs to dispatch through to the base method (and the base is shadowed by the overload), wrap the base call in a locally-defined generic function whose opaque generic parameter forces overload resolution to pick the base. The pattern also surfaces as a SILGen workaround for certain typed-throws + `@Sendable` + generic-substitution interactions.

```swift
// More-specific overload:
public static func perform<T>(_ work: sending () throws(Error) -> T) -> T where T: Sendable {
    // Need to call the base `perform` which is shadowed here.
    func dispatch<U>(_ inner: sending () throws(Error) -> U) -> U {
        inner()  // resolves to base perform — generic param forces base resolution
    }
    return try dispatch(work)
}
```

**Rationale**: Swift's overload resolution prefers the more-specific overload at call sites within the type's scope. A locally-defined generic function introduces a fresh scope with a fresh generic parameter; overload resolution within the generic's body cannot see the outer-specific overload and falls through to the base. Useful whenever a specialized body must delegate to the general body.

**Cross-references**: [IMPL-092]

---

### [IMPL-101] YAGNI at the API Surface, Not Behind the Type Boundary

**Statement**: When applying YAGNI ("you aren't going to need it") to design choices, the load-bearing question is *"is this complexity visible at the API surface?"* — NOT *"is there any complexity?"* Complexity confined behind `@usableFromInline` storage, unsafe-primitive bridges, raw-pointer indirections, or constrained-extension layering MUST NOT dominate the YAGNI calculation when the user-facing API is fully typed and safe. Internal-to-type complexity costs the author once; user-facing complexity costs every consumer indefinitely.

**Decision test**:

| Complexity location | Apply YAGNI pressure? | Why |
|---------------------|----------------------|-----|
| User-facing API surface (parameter types, return types, generic constraints, error types) | **Yes** — every consumer pays the cost | Each new public surface element is a future maintenance + understanding cost across all consumers |
| Internal storage shape (`UnsafeRawPointer` vs `UnsafePointer<T>`, raw bytes vs typed bytes) | **No** — invisible to consumers | The author trades implementation-internal complexity for API-surface simplicity; this is the right trade |
| Constrained extensions (`where Value: ~Copyable`, `where Value: ~Escapable`) used to keep the user-facing API typed | **No** — they preserve the typed surface | Constrained extensions are the mechanism that confines internal complexity; YAGNI-pressuring them defeats their purpose |
| `@usableFromInline let _storage` patterns enabling the typed accessor surface | **No** — invisible to consumers | The `@usableFromInline` mark is exactly the boundary keeping internal machinery internal |

**Anti-pattern signal**: when YAGNI is being weighed and the simpler option is "narrower public surface," verify that the public surface narrowing is what's at stake. If the only thing being "simplified" is internal storage / unsafe machinery / extension count, the YAGNI argument doesn't apply.

**Rationale**: YAGNI is a design discipline against speculative *external* surface; applied to internal-to-type machinery it inverts, because the machinery exists precisely to keep the external surface clean. Full rationale + origin incident: rationale archive §[IMPL-101].

**Cross-references**: [IMPL-086], [IMPL-087]

---

### [IMPL-102] Verify Conformance Expressibility Before Recommending Cross-Type Schemes

**Statement**: When proposing a super-protocol, abstract interface, or cross-type conformance scheme — particularly one designed to unify behavior across two or more existing types — the proposer MUST verify the scheme can be fully expressed in current Swift without requiring overlapping conditional conformances. If overlapping conditional conformances would be required (Swift's type system rejects them), the proposal MUST document the limitation before reaching RECOMMENDATION status.

**The Swift limitation**:

```swift
// FORBIDDEN — overlapping conditional conformances
extension Tagged: SomeProtocol where RawValue: Cardinal { ... }
extension Tagged: SomeProtocol where RawValue: Ordinal { ... }   // ❌ overlap rejected
```

Swift's type system requires conditional conformances to be unambiguous. When two `where` clauses can both apply to the same instantiation (or even when they could in principle overlap), the compiler rejects the second.

**Why this matters at proposal time**: a proposal that requires overlapping conditional conformances is academically clean but Swift-incomplete. Reaching RECOMMENDATION status with an unverified expressibility claim invites a downstream subordinate to discover the limitation mid-implementation, after the proposal has been treated as authoritative for downstream design.

**Procedure**:

1. At proposal authoring time, sketch the conformance schemes the proposal would require.
2. If two or more conditional conformances could overlap, the proposal CANNOT be implemented as drafted.
3. The proposal MUST either (a) restructure to avoid overlap (e.g., introduce a unifying type, factor through an associated type, use a witness pattern), or (b) document the limitation explicitly with the workaround/restructure required.

**Cross-references**: [API-LAYER-001], [IMPL-101]

---

### [IMPL-103] SyntaxVisitor for Descendant Search in SwiftSyntax

**Statement**: When the goal is "find any node of type `T` anywhere inside expression / statement / declaration `E`" using SwiftSyntax, the recursive search MUST use `class Finder: SyntaxVisitor { override func visit(_ n: T) -> SyntaxVisitorContinueKind { found = true; return .skipChildren } } + finder.walk(E)`. Manual recursion via `for child in E.children() { child.as(ExprSyntax.self)?.recurse() }` is forbidden — it silently truncates at non-`ExprSyntax` intermediate nodes (`LabeledExprListSyntax`, `FunctionParameterListSyntax`, `ClosureCaptureClauseSyntax`, `MemberAccessArgumentSyntax`, etc.) that the cast filter discards.

**Why manual children-cast is unsafe**: `children(viewMode:)` is a *shallow* iterator over immediate children, not a deep iterator over descendants; the cast-and-recurse pattern silently truncates at every intermediate node whose syntactic type is not the cast target — exactly where descendant references hide. Full analysis: rationale archive §[IMPL-103].

**Correct**:
```swift
class CountMemberFinder: SyntaxVisitor {
    var found = false
    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if node.declName.baseName.text == "count" {
            found = true
            return .skipChildren
        }
        return .visitChildren
    }
}

func containsCountMemberAccess(_ expr: ExprSyntax) -> Bool {
    let finder = CountMemberFinder(viewMode: .sourceAccurate)
    finder.walk(expr)
    return finder.found
}
```

**Incorrect**:
```swift
func containsCountMemberAccess(_ expr: ExprSyntax) -> Bool {
    if let m = expr.as(MemberAccessExprSyntax.self), m.declName.baseName.text == "count" {
        return true
    }
    for child in expr.children(viewMode: .sourceAccurate) {        // ❌ shallow
        if let childExpr = child.as(ExprSyntax.self),              // ❌ filter at wrong type
           containsCountMemberAccess(childExpr) {                  // ❌ skips LabeledExprListSyntax etc.
            return true
        }
    }
    return false
}
```

**Procedure**:

1. When authoring a SwiftSyntax-based predicate or analysis, identify the target node type `T`.
2. Author a `class Finder: SyntaxVisitor` with an override `visit(_ node: T) -> SyntaxVisitorContinueKind`.
3. Call `finder.walk(rootNode)` and read `finder.found` (or accumulated state).
4. Do NOT manually iterate `node.children()` and cast.

**Cross-references**: [IMPL-INTENT], [PATTERN-026]

---

### [IMPL-104] Leading-Dot Inference at Top-Level Multi-Overload Result-Builder Positions

**Statement**: At the top-level position inside a result-builder body whose `buildExpression` declares ≥2 distinct overloads accepting the same leading-dot identifier (typically `Element` and `[Element]`, or `Element` and `Sequence where S.Element == Element`), Swift's contextual-type inference cannot disambiguate the leading-dot form. The compiler resolves to the first matching overload's parameter type — usually `[Element]` or the protocol-existential — and looks for the leading-dot member there, not on the intended type. The fix is fully-qualified static factories at top-level positions; leading-dot works inside `if` / `for` body scopes where the contextual type narrows to `Element`.

(Origin case — the four-overload `Standard_Library_Extensions/Array.Builder` and the failing `Lint.Configuration(rules:)` call site: rationale archive §[IMPL-104].)

**Correct**:
```swift
Lint.Configuration(rules: {
    Lint.Rule.Configuration.enable(R1.self)
    Lint.Rule.Configuration.enable(R2.self)
    if includeR3 {
        .enable(R3.self)               // OK — inside `if` body, contextual type narrows to Element
    }
})
```

**Incorrect**:
```swift
Lint.Configuration(rules: {
    .enable(R1.self)                   // ❌ ambiguous — picks `[Element]`, fails lookup
    .enable(R2.self)
})
```

**Procedure**:

1. When authoring a result-builder consumer template, identify whether the builder type declares ≥2 `buildExpression` overloads whose parameter types cover both `Element` and `[Element]` / `Sequence where S.Element == Element`.
2. If yes, use fully-qualified static factories at top-level body positions (`Type.Method(...)`).
3. Inside `if` / `for` / `else` body scopes, the contextual type narrows to `Element` and leading-dot works correctly.
4. README / consumer-facing examples MUST be empirically compiled before publication per [README-009] / [RELEASE-007]; theoretical leading-dot examples that would fail under the institute's multi-overload builders are a defect.

**Rationale**: multi-overload `buildExpression` is a deliberate ecosystem-wide design choice in `Array.Builder`; the cost of that ergonomic flexibility is leading-dot ambiguity at unconstrained top-level positions, and the qualification rule is the corresponding documentation discipline. Full rationale: rationale archive §[IMPL-104].

**Cross-references**: [IMPL-094], [IMPL-INTENT], [README-009]

---

### [IMPL-105] Overload Accepting Existing Protocol Over New Wrapper Type

**Statement**: When a proposed new type's value-add is *shape* — a wrapper deferring evaluation, a tagged struct over an existing protocol, a parallel name for an existing concept — and not *novel semantics* (a new operation, a new invariant, a new computed quantity), the proposal MUST first evaluate whether an *overload* accepting the existing protocol can substitute. Adding an overload is shorter, faster (no per-element wrapping cost), introduces no new vocabulary, and preserves the existing concept's primacy.

**The decision test**:

| Question | If yes | If no |
|----------|--------|-------|
| Does the proposed type introduce a new operation, invariant, or computed quantity? | Type is justified — proceed | Continue to next test |
| Could an `overload(_:)` accepting the existing protocol provide the same call-site ergonomics? | Overload subsumes the type — prefer overload | Type may be justified — verify with cost analysis |
| Does the proposed type carry phantom-type or compile-time tagging that the existing protocol lacks? | Type is justified — proceed | Overload is preferred |

**Procedure**:

1. At type-proposal authoring time, run the decision test above.
2. If the value-add is shape rather than semantics, prototype the overload-form alternative.
3. Compare measurements (perf, call-site reads, code shipped) between the type and the overload.
4. The type proceeds only when (a) the decision test surfaces a novel-semantics axis, OR (b) the overload-form prototype demonstrably underperforms or under-expresses.
5. Document the decision test's resolution in the proposing research doc, with the comparison evidence.

**Rationale**: an overload accepting the existing protocol preserves the protocol's primacy and reduces ecosystem learning load; the phantom-type / compile-time-tagging exception is the case where the wrapper IS the novel semantics. Full rationale: rationale archive §[IMPL-105].

**Cross-references**: [IMPL-INTENT], [PATTERN-013], [PATTERN-054]

---

### [IMPL-110] Pair Tagged-Typed Identities With Typed Operations

**Statement**: When introducing a Tagged-based identity over a stdlib-underlying type (`Swift.String`, `Swift.Int`, `Swift.UInt`, `Swift.Double`), the API surface MUST pair the typealias with typed operations on `extension Tagged where Underlying == X` so consumers operate at the typed level. Without typed operations, the rim-typing defect emerges: types at the surface, `.underlying` at every operation site. Audit-target: when a `[skill]/[doc]` review encounters a Tagged-based public API, grep its call sites for `.underlying` — non-zero results indicate missing typed operations.

**Composite:** discipline rule (semantic) + operation-pair pattern (mechanical) + audit-grep (mechanical).

**The pattern**:

```swift
public typealias Path = Tagged<PathTag, Swift.String>

extension Tagged where Underlying == Swift.String {
    public func hasPrefix(_ prefix: Tagged<PathTag, Swift.String>) -> Bool {
        underlying.hasPrefix(prefix.underlying)
    }
}

let p: Path = "/Sources/A"
let prefix: Path = "/Sources"
if p.hasPrefix(prefix) { ... }   // No .underlying on either side
```

**Without this pattern (rim-typing defect)**:

```swift
public typealias Path = Tagged<PathTag, Swift.String>
if p.underlying.hasPrefix(prefix.underlying) { ... }   // Defect
```

**Audit procedure** (post-design):

```bash
grep -rn "\.underlying\." <package>/Sources | head
# Each result is a candidate site where a typed operation is missing.
```

**Rationale**: Tagged types exist to make the type system carry domain identity; if the consumer drops to `.underlying` at every operation, the identity collapses to a label that doesn't propagate through computation. Pairing typealias with typed operations enforces the identity end-to-end at the cost of one operation declaration per use case. The cost is small; the benefit is preserving the type system's load-bearing function.

**Cross-references**: [IMPL-INTENT], [API-NAME-001], [PATTERN-013]

---

### [IMPL-111] Ecosystem-Type Adoption Check Before New Per-Platform Shapes

**Statement**: Before introducing a type shape that encodes a per-platform distinction — an enum with cases per platform, a field with `#if os(...)` conditional on type, or a parallel typed value — the writer MUST grep `swift-institute/Research/string-type-ecosystem-model.md` and the relevant L1 primitives to check whether the distinction is already carried by an existing platform-conditional typealias (`Path.Char`, `String.Char`). New shapes are warranted only when no existing ecosystem typealias carries the semantics.

**Why**: the ecosystem has *three* owning string types (`String_Primitives.String`, `Kernel.String`, `ISO_9899.String`); D1 of `string-type-ecosystem-model.md` bans a fourth. The platform-varying element type is already solved by `String_Primitives.String.Char` (= `UInt8` POSIX / `UInt16` Windows), chained through `Path.Char` via `swift-path-primitives/Path.swift:59`. Origin incident (`File.Name.RawEncoding` → `[Path.Char]`, three wasted iterations): rationale archive §[IMPL-111].

**Trigger signals**: when any of the following appears during design or review, run the grep BEFORE accepting the shape:

| Signal | Action |
|---|---|
| Proposing an enum where each case has a platform-specific element type | Check `Path.Char` / `String.Char`; consider `[Path.Char]` storage + `Encoding` typealias |
| Adding a field with `#if os(Windows) let x: [UInt16] #else let x: [UInt8]` | Same — the platform conditional lives in the typealias already |
| Writing a second type that mirrors `Kernel.String` / `String_Primitives.String` with a new domain tag | D1 bans the fourth — pick one of the existing three or use phantom tagging |
| Wrapping view bytes into `Array<UInt8>` on POSIX and `Array<UInt16>` on Windows via `#if` | Use `[Path.Char]` — the array element type automatically varies |

**Procedural step (writer-side prior-research grep)**: Before proposing ANY new typed-value type at L1 (especially in the string / name / identifier / byte-view family), grep BOTH the target repo's `Research/` AND ecosystem-wide `swift-institute/Research/` for existing type catalogs, unification policies, and rejected-design records. Then either: (a) use an existing type that already carries the semantics, (b) extend an existing type with a new accessor, or (c) cite the existing research and explicitly explain why the new type is warranted. The canonical catalog for string/name/byte-view types is `swift-institute/Research/string-type-ecosystem-model.md`.

**Cross-references**: [IMPL-INTENT], [API-NAME-001], [PRIM-FOUND-004]
