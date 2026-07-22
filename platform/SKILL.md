---
name: platform
description: |
  Platform code layering (L1–L3), compilation mechanics, Swift 6 features, C shims, build infrastructure.
  ALWAYS apply when placing platform-specific code, configuring Package.swift, or using platform conditionals/feature flags.

layer: architecture

requires:
  - swift-institute

applies_to:
  - swift
  - swift6
  - swift-primitives
  - swift-standards
  - swift-foundations
  - kernel
  - darwin
  - linux
  - windows
  - posix
  - platform
# Amendment/changelog history: Research/platform-skill-rationale.md §Changelog-Provenance (and git history of this file).
---

# Platform

Platform code architecture, compilation mechanics, and build infrastructure. Covers where system/platform code lives, how cross-platform abstraction is achieved, and how packages are configured.

This skill is organized as a navigation hub. The stack orientation below governs the whole skill and is always in context. Detailed rule bodies live in sibling files; Claude loads the relevant file on demand when a topic is active.

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/platform-skill-rationale.md` (the rationale archive).

## The Platform Stack (orientation)

Platform code is organized into a four-level stack, each level in its own package, with code placed at the lowest level where it can correctly live:

- **L1 Primitives** — our cross-platform vocabulary (file/socket/thread/memory concepts). Unconditionally platform-agnostic. The shared `Kernel` namespace and `Kernel.Error` are anchored one level up, at the L3 unifier (below) — not here.
- **L2 Standards** — external specifications faithfully encoded (`swift-iso-9945` for POSIX, `swift-linux-standard`, `swift-darwin-standard`, `swift-windows-32`, ISA specs). The **exclusive** home for platform-C imports.
- **L3 Foundations** — composition, internally sub-tiered into **policy** (per-spec wrappers: `swift-posix`/`swift-darwin`/`swift-linux`/`swift-windows`), **unifier** (`swift-kernel` and siblings — anchors the shared `Kernel` namespace and `Kernel.Error`, exposing a cross-platform API via conditional re-exports), and **domain** (`swift-file-system`, `swift-io`, …).

The two load-bearing invariants: composition flows strictly downward (each tier composes only the tier below), and consumers above L3 write `import Kernel` with **no** platform conditionals — `#if os(...)` lives only at the designated L3 boundary. The detailed stack table, placement rules, and the spec/policy split are in `layering.md` ([PLAT-ARCH-001]); the conditions under which conditionals are legitimate are in `composition.md`.

The L1/L2/L3 layers map onto the ecosystem's five-layer architecture ([ARCH-LAYER-*], **swift-institute** skill): L1 = Primitives, L2 = Standards, L3 = Foundations.

---

## Files

| Topic | File | Rules |
|-------|------|-------|
| Layer Stack & Placement | `layering.md` | [PLAT-ARCH-001]–[PLAT-ARCH-004], [PLAT-ARCH-006]–[PLAT-ARCH-010], [PLAT-ARCH-012], [PLAT-ARCH-014], [PLAT-ARCH-030], [PLAT-ARCH-031] |
| Composition Discipline & Platform Conditionals | `composition.md` | [PLAT-ARCH-008a]–[PLAT-ARCH-008l], [PLAT-ARCH-020], [PLAT-ARCH-021], [PLAT-ARCH-023], [PLAT-ARCH-024], [PLAT-ARCH-025], [PLAT-ARCH-028] |
| Typed Surfaces & the C-Type Boundary | `typed-surfaces.md` | [PLAT-ARCH-005], [PLAT-ARCH-005a], [PLAT-ARCH-005b], [PLAT-ARCH-011], [PLAT-ARCH-013], [PLAT-ARCH-015]–[PLAT-ARCH-019], [PLAT-ARCH-022], [PLAT-ARCH-026], [PLAT-ARCH-027], [PLAT-ARCH-029] |
| Compilation Mechanics & C Shims | `compilation.md` | [PATTERN-001], [PATTERN-004], [PATTERN-004a]–[PATTERN-004c] (+ Namespace Collision Handling, Conditional Compilation Foresight) |
| Swift 6 & Build Infrastructure | `build.md` | [PATTERN-002], [PATTERN-003], [PATTERN-005], [PATTERN-005a], [PATTERN-005b], [PATTERN-006]–[PATTERN-009] (+ Import Visibility as Module Contract) |

---

## Rule Index

One-line hooks for every rule. Load the linked file when the topic is active.

### Layer Stack & Placement (`layering.md`)

| ID | Hook |
|----|------|
| [PLAT-ARCH-001] | Four-level platform stack — L1/L2/L3 packages; code at the lowest correct level |
| [PLAT-ARCH-002] | Placement decision rules — where new platform code goes |
| [PLAT-ARCH-003] | Namespace extension pattern — extend shared `Kernel`, no own roots |
| [PLAT-ARCH-004] | Platform root namespaces — `Darwin`/`Linux`/`Windows` + `Platform.Domain.Concept` |
| [PLAT-ARCH-006] | Re-export chain — each level `@_exported public import`s the one below |
| [PLAT-ARCH-007] | POSIX code belongs in ISO 9945, not duplicated per platform |
| [PLAT-ARCH-008] | Consumer import rule — above L3 imports `Kernel`, no platform conditionals |
| [PLAT-ARCH-009] | L3 platform package responsibilities — re-export + platform-specific functionality |
| [PLAT-ARCH-010] | Platform package reference — the complete stack; namespace-anchor pattern |
| [PLAT-ARCH-012] | Vocabulary / spec / composition principle — who defined the types → layer |
| [PLAT-ARCH-014] | ISA standard packages are L2 (external spec), not L1 primitives |
| [PLAT-ARCH-030] | L3 POSIX layer — re-export raw syscalls or layer policy; L2 stays spec-faithful |
| [PLAT-ARCH-031] | Linux stack mirrors POSIX — standard at L2, Linux at L3 |

### Composition Discipline & Platform Conditionals (`composition.md`)

| ID | Hook |
|----|------|
| [PLAT-ARCH-008a] | Domain authority exception (PROVISIONAL) — four criteria for `#if` outside the stack |
| [PLAT-ARCH-008b] | Conditional public API surface in L3 — sole acceptable `#if os()` on public enum cases |
| [PLAT-ARCH-008c] | L1 primitives unconditionally platform-agnostic — no `#if` type or implementation |
| [PLAT-ARCH-008d] | Syscall-vs-policy test for L3 domain `#if` |
| [PLAT-ARCH-008e] | L3 unifier composition discipline — compose peer L3-policy, don't skip tiers |
| [PLAT-ARCH-008f] | Naming-parity-collision pre-check for L3 unifiers |
| [PLAT-ARCH-008g] | Pre-flight memory consultation before cross-L2 dependencies |
| [PLAT-ARCH-008h] | Within-L3 sub-tiering and composition matrix (policy / unifier / domain) |
| [PLAT-ARCH-008i] | L3-policy peer composition for POSIX-shared base (darwin/linux → posix) |
| [PLAT-ARCH-008j] | Platform-C import authority — L2 spec packages exclusively |
| [PLAT-ARCH-008k] | Spec / policy namespace split — distinct nominal types, asymmetric per platform |
| [PLAT-ARCH-008l] | Deinit-context composition — typed `try?` form, not raw companions |
| [PLAT-ARCH-020] | L3-unifier shadow pre-flight check — `@_disfavoredOverload` when shadowed |
| [PLAT-ARCH-021] | Domain-specific cross-platform unification lives in domain L3, not swift-kernel |
| [PLAT-ARCH-023] | L2 POSIX (iso-9945) has no platform-standard dependencies (incl. tests) |
| [PLAT-ARCH-024] | L2 platform-extension pre-check before L3 placement |
| [PLAT-ARCH-025] | Class A vs Class B classification by declaration site, not usage |
| [PLAT-ARCH-028] | Typealiased-namespace unifier collapse forbids swift-kernel delegate |

### Typed Surfaces & the C-Type Boundary (`typed-surfaces.md`)

| ID | Hook |
|----|------|
| [PLAT-ARCH-005] | Cross-platform descriptor unification — three-tier typealias chain |
| [PLAT-ARCH-005a] | No platform C types in public API (including `@_spi`) |
| [PLAT-ARCH-011] | `Swift.Error` qualification (always) |
| [PLAT-ARCH-013] | Shell + values OptionSet pattern — L1 shell, L2 constants |
| [PLAT-ARCH-015] | Per-L2 platform-native typed values — no lossy uniform L1 type |
| [PLAT-ARCH-016] | `checkIsolated` for thread-owning SerialExecutors |
| [PLAT-ARCH-005b] | `@convention(c)` representability pre-check |
| [PLAT-ARCH-017] | Cross-platform C anonymous-enum constant type divergence (`Int` vs `Int32`) |
| [PLAT-ARCH-018] | Typealiased namespace-path conflict rule |
| [PLAT-ARCH-019] | INVERTED Pattern A — additive raw-alongside-typed at L2 [SUPERSEDED 2026-04-30] |
| [PLAT-ARCH-022] | `Swift.<Protocol>` qualification for stdlib-shadowing namespaces |
| [PLAT-ARCH-026] | Platform System extends `System` directly, not as a subdomain |
| [PLAT-ARCH-027] | Platform Core internal with `@_exported` re-export from variants |
| [PLAT-ARCH-029] | L2 spec wrappers must model the domain, not wrap raw C fields |

### Compilation Mechanics & C Shims (`compilation.md`)

| ID | Hook |
|----|------|
| [PATTERN-001] | C shim layer structure — minimal, per-platform, isolated |
| [PATTERN-004] | SwiftPM platform conditions — `.when(platforms:)` |
| [PATTERN-004a] | Source-level platform conditionals — `#if os()` not `#if canImport()` for identity |
| [PATTERN-004b] | Module name normalization — spaces → underscores in imports |
| [PATTERN-004c] | C library linker flags — platform-conditioned `.linkedLibrary` |
| (subsection) | Namespace Collision Handling — fully-qualified paths for system-module collisions |
| (subsection) | Conditional Compilation Foresight — proactive Embedded / WebAssembly guards |

### Swift 6 & Build Infrastructure (`build.md`)

| ID | Hook |
|----|------|
| [PATTERN-002] | Fine-grained library exposure — multiple products |
| [PATTERN-003] | Nested test-package pattern — break swift-testing cycles |
| [PATTERN-005] | Swift 6 language mode — 6.3+, `swiftLanguageModes: [.v6]` |
| [PATTERN-005a] | Memory-safety warnings as design feedback |
| [PATTERN-005b] | Expression granularity of unsafe |
| [PATTERN-006] | Upcoming feature flags — forward compatibility |
| [PATTERN-007] | Experimental feature flags — memory-critical packages |
| [PATTERN-008] | Parameter packs for n-ary types |
| [PATTERN-009] | Typed-throws-safe catch patterns — implicit `error` binding |
| (subsection) | Import Visibility as Module Contract — `public import` for `@inlinable` |

---

## Cross-References

See also:
- **swift-institute** skill for five-layer architecture [ARCH-LAYER-*]
- **code-surface** skill for namespace structure [API-NAME-001], specification-mirroring [API-NAME-003]
- **implementation** skill for API layering rules [API-LAYER-*]
- **memory-safety** skill for [MEM-SAFE-002], [MEM-SAFE-003]
