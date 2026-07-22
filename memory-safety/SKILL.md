---
name: memory-safety
description: |
  Memory ownership, copyability, lifetime safety, strict memory safety, unsafe marking, sendable, references.
  ALWAYS apply when working with ~Copyable, ownership annotations, unsafe ops, references, or concurrency safety.

layer: implementation

requires:
  - swift-institute
  - code-surface
  - implementation

applies_to:
  - swift
  - swift6
  - primitives

# Amendment/changelog history: Research/memory-safety-skill-rationale.md §Changelog-Provenance (and git history of this file).
---

# Memory Safety Conventions

Rules for safety isolation, strict memory safety (SE-0458), ownership, copyability, concurrency safety, reference primitives, and lifetime management.

This skill is organized as a navigation hub. The rule bodies live in sibling files; Claude loads the relevant file on demand when a topic is active.

**Canonical reference**: `swift-institute/Research/swift-safety-model-reference.md`

**Rationale archive** (evicted provenance, extended worked examples, dated changelog): `swift-institute/Research/memory-safety-skill-rationale.md`

---

## Files

| Topic | File | Rules |
|-------|------|-------|
| Safety Isolation & Strict Memory Safety | `safety-isolation.md` | [MEM-SAFE-001]–[MEM-SAFE-004], [MEM-SAFE-010]–[MEM-SAFE-015], [MEM-SAFE-020]–[MEM-SAFE-025] (SUPERSEDED), [MEM-SAFE-025a], [MEM-SAFE-025b], [MEM-SAFE-025c], [MEM-SAFE-026], [MEM-SAFE-027], [MEM-SAFE-028], [MEM-SAFE-029], [MEM-SAFE-030], [MEM-SAFE-031], [MEM-UNSAFE-001]–[MEM-UNSAFE-004] |
| Ownership | `ownership.md` | [MEM-COPY-001], [MEM-COPY-001a], [MEM-COPY-002]–[MEM-COPY-006], [MEM-COPY-014], [MEM-COPY-015], [MEM-OWN-001]–[MEM-OWN-002], [MEM-OWN-015] |
| Linear and Affine Types | `linear.md` | [MEM-LINEAR-001]–[MEM-LINEAR-003] |
| Span Access | `span.md` | [MEM-SPAN-001]–[MEM-SPAN-005] |
| Concurrency Safety | `concurrency.md` | [MEM-SEND-001]–[MEM-SEND-013] |
| Advanced Ownership Techniques | `advanced-ownership.md` | [MEM-COPY-010]–[MEM-COPY-013], [MEM-COPY-016], [MEM-COPY-017], [MEM-COPY-018], [MEM-COPY-019], [MEM-LIFE-001], [MEM-OWN-010]–[MEM-OWN-014], [MEM-OWN-016], [MEM-OWN-017], [MEM-OWN-018] |
| Reference Primitives | `references.md` | [MEM-REF-001]–[MEM-REF-005] |
| Lifetime Primitives | `lifetime.md` | [MEM-LIFE-002]–[MEM-LIFE-008] |

---

## Rule Index

One-line hooks for every rule. Load the linked file when the topic is active.

### Safety Isolation (`safety-isolation.md`)

| ID | Hook |
|----|------|
| [MEM-SAFE-020] | Isolation Principle — `@safe` boundaries as low as possible |
| [MEM-SAFE-021] | No `@unsafe` on encapsulating types |
| [MEM-SAFE-022] | `@unsafe` only on escape hatches |
| [MEM-SAFE-023] | Private unsafe storage |
| [MEM-SAFE-024] | `@unchecked Sendable` semantic categories |
| [MEM-SAFE-025] | SUPERSEDED 2026-05-11 by [MEM-SAFE-025a]/[MEM-SAFE-025b] |
| [MEM-SAFE-025a] | `nonisolated(unsafe)` requires invariant comment |
| [MEM-SAFE-025b] | `@safe` attribute admitted with invariant disclosure |
| [MEM-SAFE-025c] | `@safe` declarations require invariant disclosure (`// SAFETY:` / `// WHY:` block or `## Safety Invariant` doc section) |
| [MEM-SAFE-026] | No Optional-based replacement for `@_rawLayout` |
| [MEM-SAFE-027] | `_deinitWorkaround` placement for the cross-package `@_rawLayout` deinit-skip — substrate-leaf or on-type, never buffer-level |
| [MEM-SAFE-028] | Drain-box rule — a refcounted box over move-only storage owns element teardown in its class deinit |
| [MEM-SAFE-029] | No generic address caching — derive per access through the seam; cached bases only behind concrete heap-pinned paths |
| [MEM-SAFE-030] | The read-only fence — read-only regimes never conform `Memory.Region`; reads ride Span via `Span.Protocol` |
| [MEM-SAFE-031] | Two unsafe surfaces of an owned region — permanent alloc/free + cached-base floor vs SE-0465-gated span-vending |

### Strict Memory Safety (`safety-isolation.md`)

| ID | Hook |
|----|------|
| [MEM-SAFE-001] | Enable strict memory safety |
| [MEM-SAFE-002] | Unsafe expression marking |
| [MEM-SAFE-003] | Warning classification |
| [MEM-SAFE-004] | Five dimensions of memory safety |
| [MEM-UNSAFE-001] | Unsafe operation tracking |
| [MEM-UNSAFE-002] | Lifetime annotations |
| [MEM-UNSAFE-003] | Safe attribute |
| [MEM-UNSAFE-004] | `unsafe` is expression keyword, not block |
| [MEM-SAFE-010] | No dual public overloads |
| [MEM-SAFE-011] | Inline clarity over helper consolidation |
| [MEM-SAFE-012] | Span as normative interface |
| [MEM-SAFE-013] | API surface reduction as safety |
| [MEM-SAFE-014] | Closure scope over property access |
| [MEM-SAFE-015] | Raw pointer is the last resort, deeply encapsulated |

### Ownership (`ownership.md`)

| ID | Hook |
|----|------|
| [MEM-COPY-001] | Noncopyable type declaration |
| [MEM-COPY-001a] | Deinit immutability for ~Copyable structs |
| [MEM-COPY-014] | Native ownership for resource types |
| [MEM-COPY-002] | Noncopyable in error types |
| [MEM-COPY-003] | Noncopyable in collections |
| [MEM-COPY-004] | Suppression restatement — every suppressed param, on extensions, refinements, AND conformances |
| [MEM-COPY-005] | Nested accessor pattern incompatibility |
| [MEM-COPY-006] | ~Copyable propagation gotchas |
| [MEM-COPY-015] | Never degrade ~Copyable to raw values |
| [MEM-OWN-001] | Consuming parameters |
| [MEM-OWN-002] | Borrowing parameters |
| [MEM-OWN-015] | No raw extraction or reconstruction across boundaries |

### Linear and Affine Types (`linear.md`)

| ID | Hook |
|----|------|
| [MEM-LINEAR-001] | Exactly-once types |
| [MEM-LINEAR-002] | At-most-once types |
| [MEM-LINEAR-003] | Proof categories |

### Span Access (`span.md`)

| ID | Hook |
|----|------|
| [MEM-SPAN-001] | Property-based span access |
| [MEM-SPAN-002] | Span-indexed iteration over `withUnsafePointer` at L3 consumer sites |
| [MEM-SPAN-003] | Span family selection — match the access mode (`Span`/`MutableSpan`/`OutputSpan`) |
| [MEM-SPAN-004] | Match the addressing seam to the index domain — count-bounded spans never cover capacity-domain slots (rings, offsets, occupancy) |
| [MEM-SPAN-005] | Span-first on hot paths means hoist-or-cheapen — per-access ledger-mediated span derivation is hostile; blocked-hoist fallback = the R-12 hybrid |

### Concurrency Safety (`concurrency.md`)

| ID | Hook |
|----|------|
| [MEM-SEND-001] | Conservative Sendable defaults |
| [MEM-SEND-002] | Sendability tiers |
| [MEM-SEND-003] | Accurate risk description |
| [MEM-SEND-004] | ~Copyable structs can use plain Sendable |
| [MEM-SEND-005] | Non-mutating concurrent access for ~Copyable wrappers |
| [MEM-SEND-006] | Compiler-limitation `@unchecked Sendable` requires revalidation anchor |
| [MEM-SEND-007] | ~Copyable cannot capture in `@Sendable` closures |
| [MEM-SEND-008] | No `Element: Sendable` constraint as region-merge workaround |
| [MEM-SEND-009] | `inout sending Value` for `Mutex.withLock` wrappers |
| [MEM-SEND-010] | `sending R` over `R: Sendable` on actor returns |
| [MEM-SEND-011] | Continuation dispatch avoids `T: Sendable` |
| [MEM-SEND-012] | Region-based isolation supersedes Sendable constraint in protocol-layer designs |
| [MEM-SEND-013] | Region-based isolation supersedes Sendable in combinator-layer designs (Pattern A: protocol-bound cascade; Pattern B: Mode-parameter cascade) |

### Advanced Ownership Techniques (`advanced-ownership.md`)

| ID | Hook |
|----|------|
| [MEM-COPY-010] | Noncopyable workarounds for associated types |
| [MEM-COPY-011] | Two-world separation for owned and borrowed types |
| [MEM-COPY-012] | Protocol property dispatch for ~Copyable return types |
| [MEM-COPY-013] | Redundant annotations on compiler optimization boundaries |
| [MEM-COPY-016] | Conditional-Copyable cleanup triangle — lifecycle oracles live at a class boundary (Box-relocation; one truth-holder) |
| [MEM-COPY-017] | Construction captures copyability evidence — split constructor/helper overloads on Element copyability, never a single ~Copyable-generic form |
| [MEM-COPY-018] | Same-type method pins derive suppression-only conditions — protocol-bound conformances don't derive through `where S ==` pins; obligations belong in the declaration bound |
| [MEM-COPY-019] | Box-replacing overloads split per the [MEM-COPY-017] pinned pair — a single ~Copyable-bounded overload silently drops the clone strategy, trapping on first post-fork mutation |
| [MEM-LIFE-001] | ~Escapable class stored property limitation |
| [MEM-OWN-010] | Always-consume transfer (closure path) |
| [MEM-OWN-011] | Maybe-consume transfer (closure path) |
| [MEM-OWN-012] | Action enum dispatch |
| [MEM-OWN-013] | Consuming does not suppress deinit |
| [MEM-OWN-014] | Batch slot staging for non-Sendable sequences |
| [MEM-OWN-016] | `isolated` parameter for borrowing ~Copyable across actor boundaries |
| [MEM-OWN-017] | A closure capture cannot be consumed — thread `~Copyable` payloads as `consuming` closure PARAMETERS, never as captures |
| [MEM-OWN-018] | Guarded deinit for closure-bearing ~Copyable types — Optional field + nil-in-consuming-op; `consuming sending` boundary spelling |

### Reference Primitives (`references.md`)

| ID | Hook |
|----|------|
| [MEM-REF-001] | Reference primitive selection |
| [MEM-REF-002] | Reference.Box |
| [MEM-REF-003] | Reference.Indirect |
| [MEM-REF-004] | Reference.Transfer |
| [MEM-REF-005] | Reference.Slot |

### Lifetime Primitives (`lifetime.md`)

| ID | Hook |
|----|------|
| [MEM-LIFE-007] | Lifetime.Scoped |
| [MEM-LIFE-002] | Lifetime.Lease |
| [MEM-LIFE-003] | Lifetime.Disposable |
| [MEM-LIFE-004] | Experimental Lifetime annotation version skew |
| [MEM-LIFE-005] | Nested coroutine ~Escapable scope limitation |
| [MEM-LIFE-006] | ~Escapable parameters in async methods |
| [MEM-LIFE-008] | ~Escapable views over new `with*` closure APIs for borrowed access |

---

## Cross-References

See also:
- **implementation** skill for [IMPL-*] expression style, Property.View patterns
- **implementation** skill for [COPY-FIX-*] ~Copyable constraint patterns (absorbed from copyable-remediation)
- **implementation** skill for [PATTERN-026]–[PATTERN-028] centralization and refactoring patterns (absorbed from advanced-patterns)
