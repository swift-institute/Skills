## Parameter Ordering

### [API-IMPL-012] Closure Parameters Trail the Signature

**Statement**: All closure parameters MUST occupy the final positions of a function or initializer signature; a non-closure parameter MUST NOT appear after a closure parameter. Typed-throws thunks per [IMPL-092] — `() throws(E) -> T` — are closures for the purpose of this rule.

**Correct**:
```swift
public init(
    id: ID,
    interest: Interest,
    flags: Options = [],
    onEvent: @escaping (Event) -> Void
)
```

**Incorrect**:
```swift
public init(
    id: ID,
    onEvent: @escaping (Event) -> Void,
    flags: Options = []                    // ❌ non-closure after closure
)
```

**Lint enforcement**: `Lint.Rule.Closure.ParameterPosition` flags every non-closure parameter following a closure-typed parameter; optional, attributed (`@escaping`/`@Sendable`), and typed-throws closures all count as closures per [IMPL-092]. Scope detail: rationale archive §[API-IMPL-012]. [VERIFICATION: AST Lint.Rule.Closure.ParameterPosition]

**Cross-references**: [API-IMPL-013], [API-IMPL-014], [IMPL-092]

---

### [API-IMPL-013] Multiple Closures Follow Lifecycle Order

**Statement**: For signatures with two or more closure parameters, closures MUST be ordered by lifecycle (setup → body → completion/teardown); the primary body closure MAY be unlabeled but all subsequent closures MUST be labeled per SE-0279, naming the closure's *role* in the operation (not its Swift type) per [API-NAME-002].

**Correct** — validated at `swift-primitives/.../Kernel.Completion.Driver.swift:104`:
```swift
public init(
    submit:        @escaping (Submission, borrowing Descriptor) throws(Error) -> Void,
    flush:         @escaping () throws(Error) -> Submission.Count,
    drain:         @escaping ((Event) -> Void) -> Event.Count,
    close:         @escaping () -> Void,
    overflowCount: @escaping () -> Event.Count = { .zero }
)
```

**Incorrect**:
```swift
// ❌ completion before body — body loses trailing-closure position at call sites
public func perform(
    completion: @escaping (Result) -> Void,
    body: @escaping () -> Void
)
```

**Cross-references**: [API-IMPL-012], [API-NAME-002]

**Lint enforcement**: `Lint.Rule.Closure.MultipleLifecycle` flags signatures with ≥ 2 closure parameters whose 2nd-and-onward closure has a wildcard `_` external label; companion `Lint.Rule.Closure.LifecycleOrder` enforces the ORDER aspect (a completion-tier label appearing before a body-tier closure is flagged). Scope detail: rationale archive §[API-IMPL-013]. [VERIFICATION: AST Lint.Rule.Closure.MultipleLifecycle, AST Lint.Rule.Closure.LifecycleOrder]

---

### [API-IMPL-014] Configuration Parameter Placement

**Statement**: Configuration-bearing parameters (`.Options`, `.Configuration`, `.Context`, or `OptionSet` types) MUST sit **first** (labeled or unlabeled) when the configuration IS the primary input, or **last in the non-closure portion** of the signature (labeled, with a default) when it modifies a primary operation; middle placement and splitting configuration across sibling parameters are both FORBIDDEN.

**Correct — configuration as modifier** (`swift-primitives/.../Kernel.Event.swift:53`):
```swift
public init(id: ID, interest: Interest, flags: Options = [])
```

**Incorrect**:
```swift
public func perform(
    on target: Target,
    options: Options = [],                 // ❌ middle placement
    mode: Mode,
    body: @escaping () -> Void
)
```

**Lint enforcement**: `Lint.Rule.Closure.ConfigurationPlacement` flags configuration-bearing parameters (type-name suffix `Options` / `Configuration` / `Context`) sitting at neither index 0 nor the last non-closure index; splitting-configuration-across-siblings detection is beyond the mechanical rule. Scope detail: rationale archive §[API-IMPL-014]. [VERIFICATION: AST Lint.Rule.Closure.ConfigurationPlacement]

**Cross-references**: [API-IMPL-012]

---

