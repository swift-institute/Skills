# Memory Safety — Lifetime Primitives

Part of the **memory-safety** skill. See `SKILL.md` for the navigation hub, frontmatter, and rule index.

Full rationale, provenance, extended worked examples, and the dated changelog: `swift-institute/Research/memory-safety-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MEM-LIFE-007], [MEM-LIFE-002], [MEM-LIFE-003], [MEM-LIFE-004], [MEM-LIFE-005], [MEM-LIFE-006], [MEM-LIFE-008].

---

## Lifetime Primitives

### [MEM-LIFE-007] Lifetime.Scoped

**Statement**: Use `Lifetime.Scoped` for RAII-style deterministic cleanup when scope exits.

---

### [MEM-LIFE-002] Lifetime.Lease

**Statement**: Use `Lifetime.Lease` for temporary access with guaranteed return.

---

### [MEM-LIFE-003] Lifetime.Disposable

**Statement**: Conform to `Lifetime.Disposable` for types requiring explicit cleanup. Implementations MUST be idempotent.

---

### [MEM-LIFE-004] Experimental Lifetime Annotation Version Skew

**Statement**: The `@_lifetime` experimental annotation has incompatible semantics between Swift compiler versions:

| Compiler | Constraint |
|----------|-----------|
| 6.2.x | Requires `@_lifetime(self: ...)` on mutating methods where `self` is `~Escapable` |
| 6.4-dev | Rejects `@_lifetime` when the return type is `Escapable`, regardless of `self`'s escapability |

These constraints are **contradictory** for `~Escapable self` methods returning `Escapable` types. No source-level annotation satisfies both compilers simultaneously.

**Cross-references**: [MEM-LIFE-001], [MEM-COPY-013]

---

### [MEM-LIFE-005] Nested Coroutine ~Escapable Scope Limitation

**Statement**: A `~Escapable` value produced inside an inner `_read` coroutine MUST NOT be yielded from an outer `_read` coroutine. The inner value's lifetime is tied to the inner scope, which ends before the outer yield can deliver the value to the caller.

```swift
// FAILS — inner ~Escapable cannot escape to outer scope
var outer: Ownership.Borrow<Element> {
    _read {
        var inner_view = unsafe Property<Peek, Buffer>.View(&self.buffer)
        yield inner_view.first  // ❌ Borrow<Element> lifetime tied to inner_view's scope
    }
}
```

**This applies to any nested coroutine composition**: not just `_read` + `_read`, but any pattern where an outer coroutine attempts to yield a lifetime-dependent value from an inner scope. The limitation is fundamental to Swift's coroutine scoping model — the inner scope's stack frame is deallocated before the outer yield suspends.

**Workarounds**: Return Copyable projections (extract scalar values) or use closure-based access (`func peek<R>(_ body: (borrowing Element) -> R) -> R?`).

**Cross-references**: [IMPL-079], [IMPL-065], [MEM-COPY-013], [MEM-LIFE-001]


---

### [MEM-LIFE-006] ~Escapable Parameters in Async Methods

**Scope**: Async functions accepting `Span<T>` or `MutableSpan<T>` parameters.

**Statement**: `~Escapable` function parameters (`Span<T>`, `inout MutableSpan<T>`) CAN be used in `async` methods and survive across suspension points (`await`). The compiler ties their lifetime to the function scope — not to the synchronous interval between suspensions.

| Path | Parameter type | Why it works |
|------|---------------|--------------|
| Read | `inout MutableSpan<T>` | Coroutine stores a reference to caller's buffer; the `inout` binding is alive for the full function scope |
| Write | `Span<T>` | Value parameter; alive for the full function scope |
| Partial-write retry | `Span<T>` + `extracting(droppingFirst:)` | Sub-span derived from parameter; same lifetime |

**Correct** — Span across await in retry loop:
```swift
public mutating func write(
    _ buffer: Span<UInt8>
) async throws(IO.Event.Failure) -> Int {
    while true {
        // ... attempt syscall with buffer ...
        case .wouldBlock:
            try await arm()  // Span survives this suspension
        // ...
    }
}
```

(Companion examples — `inout MutableSpan` across await, `extracting(droppingFirst:)` partial-write retry: rationale archive §[MEM-LIFE-006].)

**The limitation remains**: `~Escapable` values cannot be *stored* in class fields or captured in `@escaping` closures ([MEM-LIFE-001]). Async function parameters are fine because the parameter lifetime is scoped to the function call — the caller's buffer is guaranteed alive until the function returns.

**Empirical proof**: rationale archive §[MEM-LIFE-006] (swift-io Channel migration).

**Cross-references**: [MEM-SPAN-001], [MEM-LIFE-001], [MEM-SAFE-012]


---

### [MEM-LIFE-008] ~Escapable Over `with*` Closure APIs for Borrowed Access

**Statement**: New `with*` closure APIs MUST NOT be added for borrowed access to `~Copyable` resources. ~Escapable views are current ecosystem infrastructure (Lifetimes enabled across all packages) and supersede the `with*` closure pattern. When a class needs to expose a `~Copyable` resource, ~Escapable accessor patterns MUST be investigated first; `with*` is acceptable only as a verified compiler-limitation fallback for a specific case, with a TRACKING comment naming the limitation.

**Why**: Each `with*` overload (non-throwing, throwing, generic-error) adds API surface that ~Escapable eliminates. The ecosystem already standardizes on ~Escapable views (Span, MutableSpan, Property.View, Lifetime.Lease, Lifetime.Scoped, Lifetime.Disposable). Adding more `with*` APIs goes against the grain. The narrow `[MEM-LIFE-001]` limitation (~Escapable values cannot be stored in class fields or captured in `@escaping` closures) does NOT justify expanding the `with*` pattern — most use cases have a viable ~Escapable shape.

**How to apply**:
1. Don't add new `with*` methods.
2. When a class needs to expose a `~Copyable` resource, investigate ~Escapable accessor patterns first (property-based span access per `[MEM-SPAN-001]`, Lifetime.Lease per `[MEM-LIFE-002]`, etc.).
3. Only fall back to `with*` if a verified compiler limitation blocks the ~Escapable path for that specific case — and document the limitation with a TRACKING comment.


**Cross-references**: [MEM-LIFE-001], [MEM-LIFE-002], [MEM-SPAN-001], [IMPL-100]

---

