---
name: swift-institute
description: |
  Five-layer architecture and core conventions for Swift Institute.
  ALWAYS apply when working in any Swift Institute repository.

layer: architecture

requires:
  - swift-institute-core

applies_to:
  - swift
  - swift6
  - swift-primitives
  - swift-standards
  - swift-foundations
---

# Swift Institute Conventions

Core architectural conventions for all Swift Institute packages.

---

## Five-Layer Architecture

```
Layer 5: Applications    (Commercial)   - End-user products
              ↑
Layer 4: Components      (Flexible)     - Opinionated assemblies
              ↑
Layer 3: Foundations     (Apache 2.0)   - Composed building blocks
              ↑
Layer 2: Standards       (Apache 2.0)   - Specification implementations
              ↑
Layer 1: Primitives      (Apache 2.0)   - Atomic building blocks
```

### [ARCH-LAYER-001] Dependency Direction

Packages MUST depend only on layers below them. Upward and lateral dependencies are FORBIDDEN.

| Layer | Question Answered | Examples |
|-------|-------------------|----------|
| Primitives | What must exist? | Buffer, Geometry, Time |
| Standards | What is specified externally? | ISO 32000, RFC 3986 |
| Foundations | What can be composed safely? | File I/O, JSON, TLS |
| Components | What is reusable with defaults? | PDF rendering, HTTP |
| Applications | What is an end-user system? | Products |

---

### [ARCH-LAYER-002] L3 Imports L2-Only When L2 Re-exports L1

**Statement**: For ecosystem packages with a full three-layer cascade (L1 primitive → L2 spec → L3 composition), L3 MAY import both the L1 primitive and the L2 spec, but the **preferred** shape is L3 imports L2 only and L2 re-exports the L1 namespace via `@_exported public import`. Double-imports are acceptable but flagged as cleanup targets.

**Why**: Minimizes consumer fan-out, makes L2 the canonical entry point for downstream code, and reflects layering intent — L3 is composition over a spec, not over the raw primitive. Distinct from the no-umbrella-imports rule (`[MOD-015]`), which is about narrow-variant target imports within a single multi-target package — this rule is about cross-package layer cascade.

**How to apply**: When finding an L3 package that imports both L1 and L2 of the same namespace family (e.g., `swift-ascii` importing both `ASCII_Primitives` and `INCITS_4_1986`):
1. Check L2's `exports.swift` for `@_exported public import {L1 namespace}`. If present, drop the L1 import from L3.
2. If L2 does NOT re-export L1 sufficiently, fix at L2 (add the re-export), then narrow L3 to L2 only.


---

### [ARCH-LAYER-003] L2 Is the Syscalls Level

**Statement**: L2 spec packages (swift-iso-9945, swift-windows-standard, swift-linux-standard, swift-darwin-standard) ARE the syscalls level. There MUST be NO `swift-syscall-primitives`, `swift-outcome-primitives`, or similar L1 primitives package for syscall-framework machinery. Each L2 spec package owns its own syscall-declaration framework.

**Why**: Syscall machinery is platform-specific (POSIX read/write, Win32 ReadFile/WriteFile). Different platforms have different error conventions (errno vs LastError), different result shapes (Int return vs BOOL+OUT param), different retry semantics (POSIX EINTR vs Windows none). A unified L1 framework forces a least-common-denominator abstraction; per-L2-package frameworks fit each platform's syscall ABI naturally. Consistent with `[ARCH-LAYER-001]` (no upward/lateral dependencies) and `feedback_authority_not_platform` (placement follows spec authority).

**How to apply**:
- For relocation cycles: treat as L2 absorption (Bucket A / G3), NOT L1 domain-primitive (Bucket B / G1).
- When designing future syscall-framework abstractions: scope to a single L2 package; do NOT create a shared L1 primitives package for "syscall infrastructure."
- swift-kernel L3 may host cross-platform unifier abstractions for syscalls but the syscall MACHINERY (declaring + invoking syscalls) lives at L2 per package.
- Affected types historically misplaced at L1: `Kernel.Syscall`, `Kernel.Outcome`, `Kernel.Interrupt`, `Kernel.IO` — all distribute to per-platform L2 packages (Path X relocation).


---

### [ARCH-LAYER-004] L1 Kernel ABI Uses Raw Types, Not Collection-Index Infrastructure

**Statement**: L1 kernel shared-memory protocol counters (e.g., io_uring head/tail) MUST stay as raw `UInt32` with a typed Mask for slot extraction. Collection-index infrastructure (`Index.Modular`, `Buffer.Ring.Header`, ecosystem collection types) MUST NOT be used at L1 for kernel-protocol values.

**Why**: io_uring counters are monotonically increasing UInt32 values with wrapping at 2^32. Fullness check (`sqEntries &- (tail &- head)`) relies on UInt32 overflow semantics — widening to UInt (64-bit) via Ordinal breaks wrapping. The `head: .zero` parameter in Index.Modular.physical() is a semantic void that violates `[IMPL-INTENT]`. Converting `UInt32 → Ordinal → Index<T>` at every atomic load adds four constructors for a value used once then discarded — zero safety gain. L1 ABI surfaces are the C-language boundary; the abstractions that make those values ergonomic live further up.

**How to apply**: L1 (linux-primitives) = Mask + raw UInt32 counters for kernel shared-memory protocol. L3 (swift-io, swift-kernel) = Index.Modular, Buffer.Ring for userspace overflow queues and completion batch buffers. Each layer uses the right abstraction for its boundary.


---

### [ARCH-LAYER-005] Blocking-Dispatch Primitive Lives in swift-threads, Not swift-io

**Statement**: The generic `() throws(E) -> T` blocking-work dispatcher lives in `swift-threads` as `Kernel.Thread.Pool.run`. Proposals to add `IO.run(.blocking)`, `IO.run.blocking { … }`, or to re-introduce `IO.Blocking.run` / `IO.Blocking.Error` to swift-io are FORBIDDEN. Citations to `swift-io/Research/perfect-api.md` type names are stale (the doc is banner-ed as INTENT and predates the 2026-04-14 extraction).

**Why**: The 2026-04-14 strict-mission refactor (Phase A) deliberately extracted `IO.Blocking`'s admission-gated closure-dispatch API out of swift-io into a new L3 package `swift-threads`; swift-io's `IO.Blocking` collapsed to a shard provider for the witness impl actor (~7 files / ~380 LoC deleted). The dispatch primitive belongs at the thread layer, not the IO layer. swift-io's witness (`read` / `write` / `close` / `ready` on a `Kernel.Descriptor`) is for descriptor-based stream I/O; generic blocking work is a separate concern owned by `Kernel.Thread.Pool` (executors + async-semaphore admission). Fusing them re-layers what was deliberately separated.

**How to apply**: Consumers needing arbitrary blocking syscalls off the cooperative pool depend on `swift-threads` → `Thread Pool` product, calling `Kernel.Thread.Pool.shared.run { body }` with throw shape `Either<Kernel.Thread.Pool.Error, E>`. Consumers also needing descriptor-based stream I/O additionally depend on swift-io and use `io.read` / `io.write` through the witness. If a session's first instinct is "swift-io should provide X for blocking dispatch," stop — that's the anti-pattern.


---

### [ARCH-LAYER-006] Domain Completeness, Not Consumer Count, Determines L1 Existence

**Statement**: Layer 1 primitives exist because they belong to their scoped domain, not because something currently imports them. Consumer count MUST NOT be used as a reason to remove, deprecate, or question a primitive type's existence. Existence is determined by domain scope (the question each layer answers per `[ARCH-LAYER-001]`).

**Why**: The five-layer architecture defines each layer by the question it answers. Layer 1 answers "What must exist?" — existence is determined by domain scope, not adoption. A `Memory.Pool` with zero current consumers is still a valid memory-primitives type if pool allocation belongs to the memory domain. Consumer count may inform prioritization of implementation work, but never the question of whether something should exist. This composes with `[ARCH-LAYER-008]`: split/reshape decisions are correctness-driven, not adoption-driven.

**How to apply**: When auditing, reviewing, or making disposition recommendations for primitive types, evaluate whether the type is theoretically complete within its scoped domain and layer. Reject "zero consumers" framings as a basis for removal or doubt. Composes with `[ARCH-LAYER-001]` (layer-defining question) and Wave 5 `[CI-*]` correctness-driver rules.


---

### [ARCH-LAYER-007] No-Foundation Discipline Extends Through All Five Layers

**Statement**: Across all five layers (Primitives, Standards, Foundations, Components, Applications), no package's main target imports `Foundation`. The `[PRIM-FOUND-001]` rule covers L1 explicitly; this rule extends the same discipline to L2/L3/L4/L5 as an ecosystem-wide architectural policy. Foundation-adjacent interop is allowed via separately-declared `* Foundation Integration` subtargets that consumers opt into — mirroring the existing `* Standard Library Integration` pattern.

**Why**: The Foundation-free guarantee at L1/L2 is hard; extending it upward propagates the no-Foundation property through the entire stack. Consumers get predictable deployment profiles (Embedded-viable, Linux-portable without corelibs-Foundation) and explicit opt-in when they want Foundation-adjacent interop.

**How to apply**:
- L3+ packages that need Foundation-adjacent interop ship a `* Foundation Integration` subtarget; their main target stays Foundation-free.
- When pitching the ecosystem externally, Foundation-freedom is a design feature across ALL layers, not just L1/L2.
- When auditing a package at any layer, `foundation_imports > 0` in the main target is a violation regardless of layer.


**Cross-references**: [PRIM-FOUND-001], [ARCH-LAYER-001], [MOD-010]

---

### [ARCH-LAYER-008] Correctness Is the Sole Driver of Split / Reshape / Extraction Decisions

**Statement**: Package split / reshape / extraction decisions MUST be driven by correctness (architectural, semantic, contract correctness) and architectural merit, NOT by adoption metrics. Consumer-count / adoption-count gating MUST NOT be invoked as a decision driver — at any phase, pre- or post-1.0. The right shape is the right shape regardless of how many consumers currently use it.

**Why**: Architecture is decided from first principles — the structure that is correct for the domain, the layering, and the contracts. Adoption-driven shaping optimizes for the current consumer set rather than the right architecture, baking accidental coupling into the public API surface. "How many consumers use it today" measures the past, not the correct shape; it is never the axis on which a split / reshape / extraction turns. (Pre-1.0 is also the only window where ABI constraints don't yet prevent fixing the shape — but the driver is correctness at every phase, not the phase.)

**How to apply**:
- When evaluating "should this package be split / reshaped / extracted?" the answer is "yes if the architecture says so" — independent of how many consumers exist.
- Do NOT cite "only one consumer" / "no second consumer" / "no adoption yet" as a reason to defer or to proceed.
- Decisions are justified structurally (capability, layer-correctness, contract integrity, theoretical content), never by consumer count.
- Do NOT propose sibling-type workarounds — a non-conforming twin that preserves an old API alongside a new one (e.g. `Parser.Machine.OwnedCompiled` beside `Compiled`) — as the resolution to a **protocol-level** relaxation goal (making a protocol `~Copyable` / `~Escapable`-compatible). Sibling types preserve the underlying protocol-level blocker while papering over one consumer's need, and accrue as latent debt; drive the protocol decision through empirical-blocker validation (`/experiment-process`) instead. Pre-existing L1-`~Copyable` / L3-`Copyable` bifurcations that ARE the architecture (predating any consumer need) are not this pattern.


**Cross-references**: [ARCH-LAYER-006], [ARCH-LAYER-009], [ARCH-LAYER-010], [MOD-008]

---

### [ARCH-LAYER-009] Package / Source-Module Removal Is Correctness-Driven and Git-Recoverable

**Statement**: Packages and source modules (`Sources/<X>/`) MAY be removed when correctness or architectural merit says they are dead or superseded — at any phase — per `[ARCH-LAYER-008]` and the `[MOD-RENT]` Deletion disposition. "No consumers" is not, by itself, a *reason* to remove (correctness is); but it is equally not a *bar*. Removal is gated only by two correctness guards: the removed code MUST be **git-recoverable** and **verified dead** first.

**Two guards before any removal**:
1. **Recoverable** — the code MUST already be committed (present in git history) before deletion, so it is recoverable. NEVER `rm -rf` *uncommitted* exploratory work; commit it first, then delete it in a follow-up commit. Git history is the recovery mechanism that makes removal reversible.
2. **Verified dead** — confirm the target is genuinely unreferenced before deleting, via a build-level pre-flight (a grep is insufficient — check transitive / accidental visibility; a clean build *after* removal is the proof). Do NOT delete another session's parallel WIP.

**Not removals — always permitted**: renaming packages or source modules; reshaping public APIs; removing `Package.swift` *dep declarations* the source does not import (per `[PKG-DEP-003]`); reorganizing files within a module.

**Why**: Carrying dead / superseded packages forward accrues the long tails `[MOD-RENT]` names (maintenance surface, review cost, "absorb or add?" forks). The prior blanket "no removal for any reason during pre-1.0" rested on two premises that don't hold: that a package's value is "non-obvious until consumers materialize" (consumer-demand reasoning, removed 2026-06-09) and that removal is "irreversible loss" (false — committed code is recoverable from git history). Correctness drives the decision; the two guards make it safe.

**How to apply**:
- When `[MOD-RENT]` or `[ARCH-LAYER-008]` identifies dead / superseded code, remove it: commit-first, verify-dead, then delete. No separate per-action authorization — git is the safety net.
- If the target is not yet committed, commit it first (history preserves it), then delete in a follow-up commit.
- Composes with `[ARCH-LAYER-008]` (correctness / merit is the driver) and `[MOD-RENT]` (whose Deletion disposition is now executable rather than blocked).


**Cross-references**: [ARCH-LAYER-008], [MOD-RENT], [PKG-DEP-003]

---

### [ARCH-LAYER-010] Strict-Mission Package Boundaries, Optimized Early

**Statement**: Package scope MUST follow strict-mission rules. Architectural moves that improve mission boundaries MUST NOT be deferred on pragmatic grounds (cost, schedule, "this works for now"). Strict-mission boundaries are optimized early, during the architectural-shaping window, NOT post-hoc once consumers depend on the loose-mission shape.

**Why**: Loose-mission packages tend to grow accidental coupling — types from adjacent missions get added because "they fit somewhere." The mission boundary then has to be recovered through extraction post-hoc, which is more expensive than getting it right early. Pragmatic deferral compounds: each deferred mission-boundary fix shifts cost to the next architectural review, where the deferred set has accumulated.

**How to apply**:
- When drafting a new package: state its mission in one sentence; reject types that don't fit.
- When auditing an existing package: identify mission-violators (types that don't belong) and rename / extract / reshape them ELO BEFORE adding new types.
- Don't defer mission-boundary fixes on cost grounds during pre-1.0.


**Cross-references**: [ARCH-LAYER-008], [MOD-008], [MOD-026]

---

### [ARCH-LAYER-011] Improve Institute Foundation, Don't Reach for Apple Foundation or Third-Party Libs

**Statement**: When an institute foundation package (swift-json, swift-pdf, swift-file, etc.) is insufficient for a task, the canonical resolution is to IMPROVE that package — NOT to reach for Apple Foundation, a third-party library, or a hand-rolled workaround. The institute's own ecosystem is the authoritative target; ecosystem-extension work flows back into the institute, never around it.

**Why**: Reaching for Foundation or 3rd-party libs as a workaround has two costs: (a) the institute's ecosystem stays incomplete (the gap is invisible until the next consumer hits it), and (b) the workaround calcifies into a dependency the institute later has to extract. Both costs compound. Improving the institute foundation pays once, fixes the gap permanently for all future consumers, and grows the institute's surface area in the right direction. Composes with `[ARCH-LAYER-007]` (no-Foundation across all layers): when L3+ wants Foundation-adjacent functionality, the rule is "build it in the institute," not "import Foundation here just this once."

**How to apply**:
- When an institute foundation package is insufficient for the task: open a dispatch to improve THAT package as the resolution path. Bundle the improvement into that dispatch.
- Do NOT reach for Apple `Foundation`, third-party libraries (PointFree, swift-collections, etc.), or hand-rolled workarounds when an institute path exists.
- When NO institute path exists at all (genuine new domain), the new institute package is the right answer — not a 3rd-party adoption.


**Cross-references**: [ARCH-LAYER-007], [PRIM-FOUND-001]

---

### [ARCH-LAYER-012] Layer Dependency Rule Applies to Test Targets

**Statement**: `[ARCH-LAYER-001]`'s upward/lateral dependency prohibition applies to **test targets too**. Tests share the package's `Package.swift`, so an L2 package's test target MUST NOT declare a dependency on an L3 foundation (e.g. an L2 `swift-*-standard`'s tests depending on L3 `swift-json`). The layer position is the package's, not the target's; SwiftPM has no mechanism to scope one product's dependency to a different layer for tests only, so a test-only upward dep is still a `Package.swift`-level layer violation.

**How to apply** — an L2 package whose tests need an L3 foundation:
1. **Preferred (architecturally clean)**: author a new sibling L3 package depending on the L2 package (downward) + the L3 foundation (lateral L3↔L3, permitted by orchestrator disposition), and move the tests + any retroactive-conformance helpers there.
2. **Pragmatic (accepted with caveat)**: leave the violating dep in the L2 tests with an explicit `// swiftlint:disable` + comment citing the structural constraint — a marked, known exception (e.g. Codable-round-trip tests whose coverage mostly exercises Foundation anyway, with the load-bearing wire-shape coverage living in real-data tests elsewhere).
3. **Forbidden**: silently adding the L3 dep to the L2 test target.

**Enforcement**: Mechanical — `validate-test-target-layers.py` (+ `validate-test-target-layers.yml` org sweep; /promote-rule 2026-07-06): dump-package manifest check flagging institute-org test-target deps strictly above the host's layer; sanctioned option-2 exceptions in the sibling `.test-target-layer-allowlist`. Discipline: `Audits/PROMOTE-ARCH-LAYER-012-2026-07-06.md`. [VERIFICATION: WF]

**Cross-references**: [ARCH-LAYER-001] (the rule this extends), [ARCH-LAYER-002] (L3→L2 import cascade), [ARCH-LAYER-007] (no-Foundation across layers), [PATTERN-061] (`JSON.Serializable` — the canonical institute JSON pattern that informs when the sibling-L3 path is worth authoring).

---

## Collaboration Protocol

You are a co-architect on production infrastructure. Requirements:

1. **Challenge implementations** - If you see issues, say so directly
2. **Cite specific lines** - Reference exact file paths and line numbers
3. **No drift** - Deviation from converged design requires explicit discussion
4. **Complete answers** - Do not summarize or abbreviate
5. **Ask before assuming** - If ambiguous, ask

This is "timeless infrastructure" quality. Treat every decision as permanent.

---

### [ARCH-LAYER-013] Standards Layer Is Foundation-Free

**Statement**: Standards packages (L2) MUST NOT import Foundation or use Foundation types in main targets — the same discipline [PRIM-FOUND-001] imposes on primitives (L1). Foundation interop, where genuinely needed, lives in a `* Foundation Integration` subtarget per [CI-022].

**Exception — `<Name> Foundation Integration` targets (principal ruling 2026-07-14, all layers)**: a dedicated, opt-in integration target whose name ends in `Foundation Integration` MAY import Foundation, in the identical shape as [PRIM-FOUND-001]'s L1 exception: the integration target is a LEAF product; no core target may depend (directly or transitively) on it; the exception covers the target/module class, never per-file waivers inside core targets. Migration of existing L2 vendor-type Foundation usage into Integration targets proceeds over time (Workspace BACKLOG row, 2026-07-14) — the exception governs shape, not a same-day cascade.

**Rationale**: L2 encodes external specifications over L1 vocabulary; a Foundation import at L2 would poison every downstream layer's Foundation-freedom and break Embedded buildability. CI enforces this ecosystem-wide via [CI-022].


**Cross-references**: [PRIM-FOUND-001] (primitives layer), [CI-022] (CI enforcement), [ARCH-LAYER-011]

---

### [ARCH-LAYER-014] Layer Identity Follows Essence; Dependencies Conform to the Layer

**Statement**: A package's layer is determined by its ESSENCE — the question it answers per [ARCH-LAYER-001]'s layer table — and that layer assignment is the INVARIANT in every placement decision. When a package's dependencies violate its layer (e.g., upward edges), the dependencies MUST be refactored to conform to the layer (dissolved downward, decomposed out to a correctly-layered sibling, or re-pointed to a lower-layer equivalent). The package MUST NOT be moved, re-labeled, or re-homed to the layer its dependencies imply. Resolving a layering mismatch by conforming the package to its dependencies is the inverted resolution and is FORBIDDEN.

**How to apply**:
- First fix the essence: what question does this package answer? (Externally specified → L2; prerequisite vocabulary → L1; composition → L3 — the [ECO-002] decision model.) That answer is fixed unless the package's CONTENT changes.
- Then audit each dependency edge against the essence-layer. A violating edge is work on the EDGE: dissolve it, decompose the depending machinery out to a sibling at the machinery's own essence-layer, or re-point to a layer-legal equivalent.
- A capability needed by a lower-layer package's essence-content but homed above it (e.g., a macro or vocabulary type at L3 consumed by L2 encodings) is a mis-homed CAPABILITY: re-home the capability downward to its own essence-layer; never lift the consumer upward.
- Content partition inside one package follows the same test per-component: components whose essence belongs to a higher layer (client machinery inside a vocabulary package) decompose OUT; the package keeps only its essence-layer content.

**Rationale**: Layers are defined by the questions they answer, not by the transitive closure of whatever their packages happen to import today. Re-homing a package to match its dependencies launders the dependency defect into a permanent misclassification, erodes the layer's semantics for every future reader ([ECO-004] org membership signals essence), and composes badly with [ARCH-LAYER-008] — the "correct shape" it protects is the essence-shape, not the accidental import graph.


**Cross-references**: [ARCH-LAYER-001] (the layer-defining questions), [ARCH-LAYER-008] (correctness-driven reshaping — this rule pins WHICH shape is correct), [ARCH-LAYER-010] (strict mission — the per-component partition test), [ECO-002] (placement decision model), [ECO-004] (org membership signals authority)

---

## Semantic Dependencies

Package dependencies are classified as Implementation (IDG) or Semantic (SDG). Key rules:

| Rule | Statement |
|------|-----------|
| [SEM-DEP-006] | Distinguish essential vs incidental relationships; only essential creates SDG edges |
| [SEM-DEP-008] | Join-point packages resolve conflicts where two domains have mutual relevance |
| [SEM-DEP-009] | Package dependencies MUST be essential; orthogonal integrations require separate packages |

Canonical rule bodies: `implementation/patterns.md` ([SEM-DEP-006/008/009]); explanatory background in `Documentation.docc/Semantic Dependencies.md` (non-normative).

---

## Cross-References

Child skills:
- **code-surface** - Naming, error handling, and file structure rules
- **memory-safety** - Ownership, safety isolation, and copyability rules
- **implementation** - API design, layering, semantic dependencies, expression-first style (absorbs former `design` and `anti-patterns` skills)

Repository-specific:
- **primitives** (in swift-primitives) - Primitives layer conventions
