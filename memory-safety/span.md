# Memory Safety — Span Access

Part of the **memory-safety** skill. See `SKILL.md` for the navigation hub, frontmatter, and rule index.

Full rationale, provenance, extended worked examples, and the dated changelog: `swift-institute/Research/memory-safety-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MEM-SPAN-001], [MEM-SPAN-002], [MEM-SPAN-003], [MEM-SPAN-004], [MEM-SPAN-005].

---

## Span Access

### [MEM-SPAN-001] Property-Based Span Access

**Statement**: Types that expose `Span` or `MutableSpan` MUST use property-based access, not closure-based `withSpan(_:)`.

```swift
var span: Span<Element> {
    @_lifetime(borrow self)
    borrowing get { /* ... */ }
}
```

`Span` is `~Escapable` — the type system enforces scoping, making closures unnecessary.

**Cross-references**: [MEM-COPY-001], SE-0456

---

### [MEM-SPAN-002] Span-Indexed Iteration Over `withUnsafePointer` at L3 Consumer Sites

**Statement**: When copying a `Span<T>` (or any `~Escapable` view's contents) into an owned `Array<T>` at an L3 consumer site, indexed iteration MUST be preferred over `withUnsafePointer + UnsafeBufferPointer + Array(buffer)`. Same compiled behavior, no `unsafe` keyword, no raw-pointer surface.

**Correct (L3 consumer copy)**:
```swift
let span = entry.nameView.span
var bytes: [Path.Char] = []
bytes.reserveCapacity(span.count)
for i in 0..<span.count {
    bytes.append(span[i])
}
```

**Incorrect at L3 (works but leaks `unsafe` into consumer code)**:
```swift
let count = entry.nameView.count
let bytes = unsafe entry.nameView.withUnsafePointer { ptr in
    unsafe Array(UnsafeBufferPointer(start: ptr, count: count))
}
```

**Why**: `[MEM-UNSAFE-001]` says L3 consumer sites keep `unsafe` inside implementation bodies, not in the shape of consumer code. `Span<T>` has a public, safe indexed subscript (Swift 6.3+). The indexed form carries no `unsafe` keyword, no `UnsafeBufferPointer`, and reads as intent ("append each element") rather than mechanism. (Origin incident: rationale archive §[MEM-SPAN-002].)

**Counter-indication**: at L1/L2 implementation sites that interface with C directly, `withUnsafePointer` is correct — Span-indexed iteration is the L3 *consumer-site* preference, not an absolute rule. When the Span's element type is `~Copyable` and indexed subscript is unavailable, the unsafe form is the fallback.


**Cross-references**: [MEM-UNSAFE-001], [MEM-UNSAFE-004], [MEM-SPAN-001], [IMPL-INTENT]

---

### [MEM-SPAN-003] Span Family Selection — Match the Access Mode

**Statement**: When choosing the surface for contiguous-memory access, pick the member of the Span family that matches the access mode. The family is the default; a raw `Unsafe*Pointer` is the last resort ([MEM-SAFE-015]), never the first reach.

| Access mode | Surface | Notes |
|-------------|---------|-------|
| Read the initialised region | `Span<T>` (`.span`) | `~Escapable`; property-based per [MEM-SPAN-001] |
| Mutate the initialised region in place | `MutableSpan<T>` (`.mutableSpan`) | Covers `0..<count`; does NOT extend over uninitialised memory |
| Append into the *uninitialised* tail (grow) | `OutputSpan<T>` via `withOutputSpan(addingCapacity:)` | Tracks `initializedCount`; the safe surface for initialising fresh capacity |
| None of the above (C/FFI/substrate) | `@unsafe` `withUnsafe*` hatch | Last resort, gated + justified per [MEM-SAFE-015] |

**`OutputSpan` is the answer to "I need to fill an uninitialised buffer."** `MutableSpan` is well-defined only over already-initialised memory; the historical workaround was to drop to a raw `UnsafeMutableBufferPointer` for the uninitialised-tail case. That workaround is **superseded** — `OutputSpan` initialises into uninitialised capacity safely and reports how many elements were written via `initializedCount`. Do not vend a raw pointer (or a `withUnsafe*` closure) for tail-append when `OutputSpan` fits.

**Correct — append into uninitialised capacity**:
```swift
storage.withOutputSpan(addingCapacity: items.count) { out in
    for item in items { out.append(item) }   // out.initializedCount tracks progress
}
```

**Incorrect — raw pointer over the uninitialised tail**:
```swift
let tail = unsafe storage.uninitializedTailPointer(count: items.count)   // ❌ pre-OutputSpan
var i = 0
for item in items { unsafe (tail + i).initialize(to: item); i += 1 }
```

**Why**: `OutputSpan` (SE-0527) closed the one gap that previously justified raw pointers in safe-by-default storage APIs — the uninitialised tail. With `Span` / `MutableSpan` / `OutputSpan` covering read / in-place / append, the Span family spans every access mode an element-storage API needs, so the raw pointer drops to a genuine last resort under [MEM-SAFE-015]. This is the durable form of the 2026-06-02 Span-first direction.


**Lint enforcement**: `Lint.Rule.Memory.PointerArithmetic` (rule id `pointer advanced by`) flags `unsafe …advanced(by:)` raw pointer arithmetic and recommends the Span family. Exemption scope (`Strideable.advanced(by:)`, `Tests/`-class paths, SAFETY-justified last resorts): rationale archive §[MEM-SPAN-003]. [VERIFICATION: AST]

**Cross-references**: [MEM-SPAN-001], [MEM-SAFE-012], [MEM-SAFE-014], [MEM-SAFE-015], [MEM-SAFE-025a], [INFRA-109]

---

### [MEM-SPAN-004] Match the Addressing Seam to the Index Domain — Count-Bounded Views Never Cover Capacity-Domain Slots

**Statement**: When a container computes element positions in its full-allocation domain `[0, capacity)` — wrap-around rings, head-offset layouts, occupancy-bitmap slabs — every internal read and write MUST go through the full-allocation addressing seam (the `Store.Protocol` per-slot subscript / element-store ops). The initialized-prefix span (`storage.span`, bounded to `[0, count)` — Heap's span witnesses the TRACKED-initialized prefix) under-covers the slot domain and traps on wrapped or offset layouts. The span is the right seam only when the access domain IS the initialized prefix (dense, zero-based, contiguous).

| Access domain | Correct seam |
|---------------|--------------|
| Initialized prefix `[0, count)`, dense, zero-based | `span` / `mutableSpan` (family selection per [MEM-SPAN-003]) |
| Full allocation `[0, capacity)` — wrapped, head-offset, or sparse slots | Per-slot subscript (the `Store.Protocol` element-store seam) |

**The masking shape**: a count-bounded read inside a wrap-capable discipline is invisible to suites that only exercise head-at-zero states — physical slots coincide with the logical prefix until the structure wraps, so the suite passes WITH the defect present. Pair this rule with non-default-state coverage per [TEST-035].

**Worked example (the origin incident)**: `Buffer.Ring.Scalar.next()` reading `span[physical]` on a wrapped ring — trap on iteration; fixed on the per-slot seam with wrap-state regression coverage: rationale archive §[MEM-SPAN-004].

**Rationale**: span-vs-slot is a domain distinction, not a style choice. `span` witnesses the *initialized-prefix lens*; the per-slot subscript witnesses the *allocation lens*. A count-bounded read of a capacity-relative position type-checks and behaves until the first wrapped state, so the defect ships unless the seam is chosen by domain — and unless suites exercise wrap states.


**Cross-references**: [MEM-SPAN-001], [MEM-SPAN-003], [TEST-035], [DS-*] (ring-family catalog rows)

---

### [MEM-SPAN-005] Span-First on Hot Paths Means Hoist-or-Cheapen — Per-Access Ledger-Mediated Derivation Is Hostile

**Statement**: Span-first adoption ([MEM-SPAN-003]) on a hot path MUST cost the span *derivation*, not only the access through it. Per-access span derivation that recomputes `count` through the `Store.Initialization` ledger — `Storage.Contiguous.span`'s enum match per touch, vs stdlib Array's header-word read — is hot-path-hostile and MUST NOT be the per-element access shape on a measured hot path. Span-first means **hoist** the derivation out of the access loop, or **cheapen** it to plane cost (a header-word-class `count` read). When the toolchain blocks hoisting and no cheap derivation exists, the ratified landing shape is span-typed reads over the owned region's stable base plus a minimal set of SAFETY-documented pointer transitions (the R-12 (b⁗) hybrid), with the base derived per access under [MEM-SAFE-029].

**The measured tax**: per-access ledger-mediated spans FAIL any no-regression gate; the ledger-free `capacitySpan` door PROBED-NEGATIVE; the (b⁗) hybrid is RATIFIED (R-12). Full measurement table: rationale archive §[MEM-SPAN-005].

**Why hoisting is blocked (6.3.2)**: lifetime dependence pins the WHOLE struct for a live `mutableSpan` — sibling-property mutation under a hoisted span is an exclusivity error, and `deinit` rejects hoisted spans outright (both probed, diagnostics on file). The span-typed end-state for ledger planes needs hoist-friendly lifetimes or a compiler that folds the mediated derive; the residual gap is measured and on file, so re-probing it without a toolchain change is not useful work.

**Rationale**: a span is a *view*; constructing the view has a cost the view's safety does not amortize when construction recurs per element. The ledger enum match exists for element-lifecycle integrity — correct at the seam, hostile as a per-touch toll. Hoist-or-cheapen keeps span-first honest: the discipline directs WHERE the span is derived, not merely THAT spans are used.


**Cross-references**: [MEM-SPAN-001], [MEM-SPAN-003], [MEM-SPAN-004], [MEM-SAFE-015], [MEM-SAFE-029]

---

