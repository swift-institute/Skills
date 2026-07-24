## State Modeling

### [API-IMPL-003] Enum Over Boolean

Use enums instead of boolean flags when state can expand.

```swift
// CORRECT
enum Connection {
    enum State {
        case disconnected
        case connecting
        case connected(Session)
        case disconnecting
    }
}

// INCORRECT
var isConnected: Bool     // Cannot represent connecting/disconnecting
var isConnecting: Bool    // Requires multiple booleans
```

**Lint enforcement**: `Lint.Rule.Naming.BoolParameter` flags `Bool` (or `Swift.Bool`) parameters in `public` / `open` function or initializer signatures (optional/IUO wrappers detected; closure-typed parameters taking Bool internally exempt; non-public visibility exempt; return-type `Bool` not flagged). Scope detail: rationale archive §[API-IMPL-003]. [VERIFICATION: AST Lint.Rule.Naming.BoolParameter]

---

### [API-IMPL-010] Visibility Change Triggers Naming Audit

**Statement**: Widening a type's or member's access level (e.g., `private` → `internal`, `internal` → `public`) MUST trigger a naming audit against [API-NAME-001] and [API-NAME-002]. Names that were acceptable at narrower visibility may violate conventions when exposed to a wider audience.

**Correct**:
```swift
// Was private — compound name hidden from scrutiny
// private struct ReadResult { ... }

// Widening to internal: audit catches compound name
// Fix: namespace enum + nested Result
enum Read { struct Result { ... } }
```

**Incorrect**:
```swift
// Was private, now widened to internal
internal struct ReadResult { ... }  // ❌ Compound name now visible
```

**Rationale**: Private names accumulate naming debt invisible to convention enforcement; the audit is a one-time cost at the boundary change. Full text: rationale archive §[API-IMPL-010].

**Cross-references**: [API-NAME-001], [API-NAME-002]

---

### [API-IMPL-011] Wrapper Completeness

**Statement**: A wrapper type that owns construction, invariants, and error domain MUST also own the primary operation. A wrapper that encapsulates 90% of an interface is worse than one that encapsulates 100% or 0%, because the escape hatch for the missing 10% dominates the user's experience and makes the wrapper appear useless.

**Correct**:
```swift
// IO.Lane wraps IO.Blocking.Lane
// Owns: factories, error domain, Handle, DI conformance
// Also owns: run() — the primary operation
// → Complete wrapper, _backing never exposed to consumers
```

**Incorrect**:
```swift
// IO.Lane wraps IO.Blocking.Lane
// Owns: factories, error domain, Handle, DI conformance
// Missing: run() — the primary operation
// → Every consumer calls lane._backing.run { }
// ❌ Wrapper looks fake; the 10% escape dominates
```

**Lint enforcement**: `Lint.Rule.Structure.WrapperBackingExposed` flags `_backing` / `_wrapped` / `_underlying` properties wider than `private` / `fileprivate` (the canonical incomplete-wrapper leak); `@usableFromInline` decls exempt; full wrapper-completeness verification is out of mechanical scope. Scope detail: rationale archive §[API-IMPL-011]. [VERIFICATION: AST Lint.Rule.Structure.WrapperBackingExposed]

**Cross-references**: [API-LAYER-001], [IMPL-074]

---

