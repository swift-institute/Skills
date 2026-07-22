# Infrastructure and Boundaries

Part of the **implementation** skill. Full text of the rules governing ecosystem dependencies, typed arithmetic, boundary overloads, bounded indexing, cross-layer type references, and the meta-rules about when to invest in a compiler fix or verify a constraint before working around it. For the foundational axioms ([IMPL-INTENT], [IMPL-000], [IMPL-001], [IMPL-COMPILE]) and the rule index, see `SKILL.md`.

**Rules in this file**: [IMPL-002] (+ body sub-labels [IMPL-003], [IMPL-003a], [IMPL-004], [IMPL-005], [IMPL-006]), [IMPL-010], [IMPL-011], [IMPL-012], [IMPL-050] (+ body sub-labels [IMPL-051]–[IMPL-053]), [IMPL-060], [IMPL-061], [IMPL-074], [IMPL-077], [IMPL-089], [IMPL-090], [IMPL-095].

---

## Dependency Strategy

### [IMPL-060] Ecosystem Dependencies Over Ad-Hoc Implementation

**Statement**: When the ecosystem provides a type, operation, or infrastructure at any layer, it MUST be used via dependency rather than reimplemented. "Minimizing dependencies" is NOT a valid reason to reimplement what the ecosystem provides.

| Question | If Yes | If No |
|----------|--------|-------|
| Does the ecosystem provide this type/operation? | Import and use it | Implement it |
| Does importing it violate tier constraints? | Investigate: wrong tier, or need join-point | Import it |
| Is the local version "simpler"? | Still import — simplicity ≠ justification for duplication | — |

**Why**: Ad-hoc reimplementations create type incompatibility, duplicate maintenance, miss upstream improvements, and fragment the ecosystem.

**Cross-references**: [PATTERN-053], [PATTERN-026], [IMPL-000], [API-LAYER-001], [SEM-DEP-009]

---

## Typed Arithmetic

### [IMPL-002] Write the Math, Not the Mechanism

**Statement**: All operations on typed values MUST use typed operators, functors, and comparisons. Raw value extraction (`.rawValue`, `.position`) MUST NOT appear at call sites. This is a direct corollary of [IMPL-INTENT].

| Category | Typed (correct) | Raw (incorrect) |
|----------|-----------------|-----------------|
| **Arithmetic** | `currentCount + .one` | `Cardinal(currentCount.rawValue + 1)` |
| **Functor** [IMPL-003] | `currentCount.map(Ordinal.init)` | `Ordinal(currentCount.rawValue.rawValue)` |
| **Domain crossing** [IMPL-003a] | `offset.retag(Element.self)` then compare | `offset.rawValue < count.rawValue` |
| **Comparison** [IMPL-004] | `slot < base.slotCapacity` | `slot.rawValue < heap.slotCapacity.rawValue` |
| **Min/Max** [IMPL-005] | `Type.min(a, b)` | `Swift.min(a.rawValue, b.rawValue)` |
| **Subtraction** | `count.subtract.saturating(.one)` | `count.rawValue - 1` |

If you find yourself chaining `.rawValue.rawValue`, that's a missing operator. Add it.

**[IMPL-003] Functor Operations**: Cross-domain conversions MUST use `.map()` (transform raw value, preserve tag) or `.retag()` (preserve raw value, change tag). Direct `__unchecked` construction SHOULD be avoided when a functor path exists. See [INFRA-103].

**[IMPL-003a] Domain-Crossing Before Operations**: When an operation requires values from different phantom-typed domains, convert to the target domain first using `.retag()`, then operate. Do NOT extract `.rawValue` as a domain escape hatch. When `Domain` enforcement arrives (via `SuppressedAssociatedTypes`), domain-agnostic operations break.

**[IMPL-006] Typed Stored Properties**: Stored properties holding quantities SHOULD use typed wrappers (`Index<Element>.Count`, `Index<Element>`) rather than raw `UInt`. `Tagged` is zero-cost — same memory layout. Store typed, eliminate N extraction sites.

For canonical constants (`.one`, `.zero`) and their protocol lifting, see [INFRA-101].

**Cross-references**: [CONV-010], [CONV-001], [CONV-003], [IDX-010], [INFRA-101], [INFRA-103]

---

## Boundary Overloads

### [IMPL-010] Push Int to the Edge

**Statement**: `Int(bitPattern:)` conversions MUST live inside boundary overloads, never at call sites. If a stdlib API only accepts `Int`, provide a typed overload that converts internally.

**Perfect** — stdlib boundary is invisible:
```swift
unsafe destination.pointer(at: offset)
    .initialize(from: base.pointer(at: range.lowerBound), count: range.count)
```

**The overload pattern**:
```swift
extension UnsafeMutablePointer {
    public func initialize(
        from source: UnsafePointer<Pointee>,
        count: Tagged<Pointee, Ordinal>.Count
    ) {
        self.initialize(from: source, count: Int(bitPattern: count))
    }
}
```

The `Int` conversion lives in one place, once, forever.

**Lint enforcement**: SwiftLint custom rule `no_int_bitpattern_arithmetic` (`swift-institute/.github/.swiftlint.yml`) catches `Int(bitPattern: x.y) + ...` arithmetic at call sites; boundary overloads in `*Standard_Library_Integration` targets are explicitly excluded. Added Wave 2b 2026-05-10. See [CONV-010].

**Lint enforcement (public API surface)**: `Lint.Rule.Naming.IntParameter` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Naming`) flags bare `Int` / `Swift.Int` parameters AND return types in `public` / `open` function and initializer signatures; sized integers, typed wrappers, closure- and tuple-typed parameters, and non-public declarations are not flagged. Scope detail: rationale archive §[IMPL-010]. [VERIFICATION: AST Lint.Rule.Naming.IntParameter]

**Cross-references**: [CONV-014], [CONV-010]

---

### [IMPL-011] Slot / Region Access Primitives

**Statement**: Types that manage memory SHOULD encapsulate offset computation behind a typed surface, so call sites never hand-roll pointer arithmetic. Per the Span-first direction ([MEM-SAFE-012], [MEM-SPAN-003], [INFRA-109]) that surface is: a typed `subscript(at: Index<Element>)` for per-slot access, and the Span family (`span` / `mutableSpan` / `withOutputSpan(addingCapacity:)`) for whole-region access. A raw `pointer(at:)` is NOT the primitive other accessors delegate to — it is a last-resort escape hatch ([MEM-SAFE-015]), present only on conformers that genuinely need it, `@unsafe`-marked, with a no-span-fits comment.

```swift
let element = storage[at: slot]             // ✓ Intent — typed slot access
let region  = storage.mutableSpan           // ✓ Intent — whole-region, in place
// vs.
let ptr = unsafe withUnsafeMutablePointerToElements { base in  // ✗ Mechanism — raw offset arithmetic
    let offset = Index<Element>.Offset(fromZero: slot)
    return unsafe base + offset
}
```

**Lint enforcement**: `Lint.Rule.Memory.PointerArithmetic` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Memory`) flags `<expr>.advanced(by: <expr>)` member-access calls — the canonical raw-pointer-arithmetic shape at consumer call sites — because types managing memory SHOULD provide a typed slot `subscript` and the Span family (`span` / `mutableSpan` / `outputSpan`) instead of exposing raw offset arithmetic; bare `+`/`-` pointer arithmetic requires type information and is out of scope. Scope detail: rationale archive §[IMPL-011]. [VERIFICATION: AST Lint.Rule.Memory.PointerArithmetic]

---

### [IMPL-012] Range Bound Transformation

**Statement**: Transforming both bounds of a range MUST use `range.map.bounds { }`, not manual decomposition.

```swift
_slots.set.range(range.map.bounds { $0.retag(Bit.self) })  // ✓
```

**Cross-references**: [IMPL-003]

---

## Bounded Indexing

### [IMPL-050] Bounded Indices for Static-Capacity Types

**Statement**: Static-capacity types (`let N: Int`) MUST accept `Index<Element>.Bounded<N>` in subscripts and position-tracking APIs. The bounded type encodes capacity at compile time; the collection's API proves occupancy. Subsumes [IMPL-051], [IMPL-052], [IMPL-053].

**Type guarantees**: `index >= 0` (structural — Ordinal is non-negative), `index < N` (structural — Finite<N> is bounded).

**API guarantee**: An index returned by the collection (`index(_:)`, `position(forHash:equals:)`, `forEach.position { }`) is occupied by construction.

**Narrowing and widening** [IMPL-051]:
- Narrowing (unbounded → bounded): returns `Optional` — value may exceed bound.
- Widening (bounded → unbounded): always safe.
- Literal construction: `let pos: Index<Element>.Bounded<16> = 0`.

**API flow** [IMPL-052]: Methods on static-capacity types that accept, return, or pass positions MUST use `Index<Element>.Bounded<N>`. Unbounded variants MUST NOT co-exist alongside bounded variants — bounded is the sole public API. When remediating, the fix is subtractive (remove unbounded) not additive (add bounded alongside).

**Arithmetic** [IMPL-053]: Arithmetic on bounded indices follows [IMPL-000]. All advancement operations (`successor`, `predecessor`, `offset`) return `Optional` — principled per [IMPL-001]. If bounded arithmetic requires `.rawValue` extraction and `__unchecked` reconstruction, that is an infrastructure gap.

For bounded type structure and operations, see [INFRA-105].

**Lint enforcement**: `Lint.Rule.Idiom.BoundedIndex` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Idiom`) walks struct / class / enum / actor declarations whose generic parameter clause contains a `let N: Int` value-generic. Inside the type's own body, subscripts whose index parameter is raw `Int` / `Swift.Int` are flagged. Extensions in separate files are out of per-file scope. Added Wave 3 mechanization 2026-05-11. [VERIFICATION: AST Lint.Rule.Idiom.BoundedIndex]

**Cross-references**: [IMPL-000], [IMPL-001], [IMPL-002], [IMPL-006], [IMPL-010], [INFRA-105]

---

## Compiler Posture

### [IMPL-061] Compiler Fix Over Workaround Accumulation

**Statement**: When a bug is traced to the compiler, investigating a source-level fix SHOULD be attempted before exhaustively exploring workarounds. Workaround cascade signal: when each workaround introduces a new constraint requiring another workaround, the structural fix is at the compiler level.

**Cross-references**: [EXP-011], [EXP-018]

---

### [IMPL-077] Verify Constraints Before Workarounds

**Statement**: When a compiler error or handoff claims a limitation, the constraint MUST be verified via minimal experiment before implementing a workaround. Stale claims and remembered limitations are hypotheses, not facts.

1. Encounter apparent limitation → 2. Minimal experiment → 3. Confirmed? Implement workaround → 4. Refuted? Write the code as it should be.

**Cross-references**: [IMPL-061], [IMPL-COMPILE]

---

## Cross-Layer Type References

### [IMPL-074] Shared-Vocabulary Test for Cross-Layer Type References

**Statement**: When a higher-layer public API references a lower-layer type, the reference MUST pass three conditions: (1) **Stable concept** — not specific to lower layer's mechanics, (2) **No hidden boundary reasoning** — callers need not reason about lower layer internals, (3) **Wrapping adds no value**. If any fails, wrap or re-parameterize.

**Cross-references**: [API-LAYER-001], [IMPL-060]

---

### [IMPL-089] Foundation-Free String Scanning Defaults to UTF-8 Byte View

**Statement**: At L1/L2 (primitives and standards), string scanning operations MUST default to iterating `content.utf8` (UTF-8 code unit view) with O(1) index arithmetic, not `Character` iteration. Grapheme-cluster semantics MUST be reserved for operations that explicitly require them, and the operation's doc comment MUST state the byte-literal semantics when UTF-8 scanning is used.

**Why**: `Character` iteration + `distance(from:to:)` produces O(n²) re-indexing, and grapheme-cluster boundary analysis is 10-1000× slower than byte comparison; for the vast majority of foundation-free scans, byte-literal matching is the correct semantics — and the only semantics requiring no Unicode table dependency. Full analysis: rationale archive §[IMPL-089].

**Correct** — UTF-8 byte scan:
```swift
// Find next newline using byte view — O(n) single pass, no allocation.
extension StringProtocol where UTF8View.Index == Index {
    func nextNewline(from start: Index) -> Index? {
        utf8[start...].firstIndex(of: 0x0A)
    }
}
```

**Incorrect** — Character iteration with per-step re-indexing:
```swift
// O(n²) — distance(from:to:) walks grapheme boundaries on every iteration.
for (i, ch) in content.enumerated() where ch == "\n" {
    let idx = content.index(content.startIndex, offsetBy: i + 1)  // ✗ O(n) per iter
}
```

**Doc-comment requirement**: When converting a Character-semantic API to byte-literal, the doc comment MUST record the semantic change:
```swift
/// Returns the range of the first occurrence of `substring`, matched byte-literal
/// against `self.utf8`. To match by grapheme-cluster equivalence, normalize both
/// sides (e.g., NFC) before calling.
```

**Lint enforcement**: `Lint.Rule.Idiom.StringUTF8Scanning` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Idiom`) flags `.unicodeScalars` member access — the institute default at L1 / L2 is `.utf8` byte-view scanning; `.utf8` and direct `Character` access are not flagged. Scope detail: rationale archive §[IMPL-089]. [VERIFICATION: AST Lint.Rule.Idiom.StringUTF8Scanning]

**Cross-references**: [IMPL-060], [IMPL-INTENT], [PRIM-FOUND-001]

---

### [IMPL-090] Abstraction-Seam Validity Requires Data-Contract Alignment

**Statement**: Before unifying two runtime patterns behind a shared abstraction (executor, driver, shell), verify that the consumer of each pattern would consume the abstraction's core data contract. If the consumer ignores the shell's core data output, the shared abstraction is at the wrong layer — unify at the primitives layer (shared types), not at the shell layer (shared runtime structure). Surface-shape similarity is NOT evidence of a valid seam.

**Decision procedure**:

1. Identify the candidate abstraction's core data output (what does its `tick` / `run` / `step` emit?).
2. For each prospective consumer, ask: *"Does the consumer's handler consume this data, or discard it?"*
3. If all consumers consume — valid seam; unify.
4. If any consumer discards the core output and consumes a parallel data source — invalid seam; the consumer needs a different shell.

**Correct** — seam at the primitives layer:
```swift
// Reactor (IO.Event.Loop) and Proactor (IO.Completion.Loop) share types:
//   Kernel.Event.Source, Kernel.Completion.Source, Executor.Job.Queue, Shutdown.Flag.
// But NOT run-loop shape — they each own their own 3-phase / 5-phase loop.
// The seam is types (primitives), not shell (Polling executor).
```

**Incorrect** — seam at the shell layer:
```swift
// Proposal: Completion.Loop adapter-wraps its notification eventfd in Kernel.Event.Source
//           so Polling can own both reactor and proactor run loops.
// Problem: Polling's tick emits Kernel.Events. Completion.Loop's handler ignores the
//          event (it already knows an eventfd fired) and runs flush → drain → dispatch.
// The consumer discards the shell's core output. Seam is invalid.
```

**Rationale**: seam validity is measured by data flow, not surface shape — matching method signatures can coexist with non-overlapping data contracts, and forcing the mismatched pair through a shared shell breaks the shell's promise at the seam. Full rationale: rationale archive §[IMPL-090].

**Surface-shape checklist (NOT sufficient evidence for unification)**:
- Both types have a `run()` method.
- Both types block on a primitive and wake via notification.
- Both types produce work for a dispatcher.

**Data-contract checklist (sufficient evidence for unification)**:
- Both consumers read the shell's core output with identical semantics.
- Both consumers handle the shell's core failure modes identically.
- Both consumers respect the shell's phase ordering (e.g., flush-before-wait) identically.

**Cross-references**: [PATTERN-013], [IMPL-074], [API-LAYER-001], [IMPL-060]

---

### [IMPL-095] Platform-Guarded Import Preservation During File Rewrites

**Statement**: When rewriting a file that contains `#if os(X)` blocks, imports inside or supporting those blocks MUST be preserved verbatim and verified against the pre-rewrite version on platform X. Silent drops of `@_spi` or platform-specific imports cause build failures that are invisible to the rewriter's local platform.

**Procedure**:

1. Before the rewrite: `grep -nE "^@?_?spi.*import|^import.*_Primitives" file.swift > pre.imports`.
2. After the rewrite: repeat and compare via `diff pre.imports post.imports`.
3. Non-empty diff MUST be justified (intentional removal) or reverted (silent drop).

**Rationale**: platform-guarded imports are invisible to the builder on the wrong platform, so a silent drop passes local builds and fails the other platform long after commit; the verbatim-preservation-plus-diff discipline closes the window at the commit point. Worked failure mode: rationale archive §[IMPL-095].

**Cross-references**: [IMPL-COMPILE], [PLAT-ARCH-008e]
