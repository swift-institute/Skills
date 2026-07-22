# Modularization — @_spi Visibility Escape Hatch

Companion of the **modularization** skill (navigation hub: `SKILL.md`). Load when introducing, auditing, or migrating an `@_spi` group or site. This file reads independently: it collects the `@_spi` per-file opt-in mechanics and last-resort minimization discipline.

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/modularization-skill-rationale.md` (referenced below as the rationale archive).

**Rules in this file**: [MOD-016], [MOD-039]

---

### [MOD-016] @_spi Per-File Opt-In

**Statement**: `@_spi` visibility is per-file. An `@_spi(Syscall) @_exported public import` in `exports.swift` re-exports the SPI surface to *downstream modules* that import the target with `@_spi(Syscall)`. It does NOT grant SPI access to sibling `.swift` files within the same target. Each implementation file MUST independently declare its own `@_spi` import.

**Correct** (every file that touches SPI members opts in):
```swift
// exports.swift — re-exports SPI to downstream modules
@_spi(Syscall) @_exported public import Kernel_Descriptor_Primitives

// IO.Read.swift — same target, still needs its own @_spi import
@_spi(Syscall) import Kernel_Descriptor_Primitives

// File.Open.swift — same target, still needs its own @_spi import
@_spi(Syscall) import Kernel_Descriptor_Primitives
```

**Incorrect**:
```swift
// ❌ Assuming exports.swift's @_spi import propagates to siblings
// exports.swift
@_spi(Syscall) @_exported public import Kernel_Descriptor_Primitives

// IO.Read.swift — no @_spi import, expects to inherit from exports.swift
let fd = descriptor._rawValue  // ❌ Compile error: _rawValue is not accessible
```

**Rationale**: Each `.swift` file is an independent compilation unit for SPI purposes; the per-file ceremony makes the SPI boundary auditable (`grep @_spi(Syscall)` identifies all boundary code). Full text + provenance: rationale archive §[MOD-016].

**Lint enforcement (DEFERRED, mechanization attempted 2026-05-13)**: AST-only detection cannot distinguish the institute's intra-module `_storage`/`_base` private-storage convention from cross-module SPI access (module-of-origin semantic info is not surfaced by SwiftSyntax); rule artifacts reverted, outcome record `swift-institute/Audits/PROMOTE-MOD-016-2026-05-13.md`. Deferred pending a semantic-aware linter pass or a build-diagnostics workflow validator. Detail: rationale archive §[MOD-016].

**Cross-references**: [MOD-002], [MOD-005]

---

### [MOD-039] Minimize `@_spi` — Last-Resort Cross-Module Visibility Escape Hatch

**Statement**: `@_spi` is a last-resort cross-module visibility escape hatch, NOT a design tool. Before introducing a new `@_spi` group or site, the alternatives MUST be exhausted, in preference order:

1. **Design the public API properly** — if downstream genuinely needs the symbol, it belongs in the public surface with a designed shape ([API-NAME-001], [API-ERR-001]), not smuggled through SPI.
2. **Extract a shared target** ([MOD-DOMAIN], [MOD-008]) — when two targets in the same package need a symbol, factor the shared concept into its own target and depend on it, rather than SPI-exporting internals.
3. **Keep the symbol internal to one target** — if only one target needs it, it stays `internal` (or `fileprivate` / `private`); no cross-module surface is created at all.
4. **`package` access level** — for same-package cross-target sharing, the `package` modifier exposes the symbol to sibling targets without the SPI escape hatch and without leaking to downstream packages.

Only when all four fail — a symbol that genuinely must cross the *package* boundary yet must not become supported public API — is `@_spi` warranted. Each new `@_spi` site MUST carry an explicit justification at the declaration naming why the four alternatives do not apply. Every existing `@_spi` site is tracked debt subject to a standing audit pass; the audit re-tests each site against the alternatives above and migrates the ones that no longer need SPI.

**Platform corner**: on the platform stack this rule is already applied at its strictest — [PLAT-ARCH-005a] forbids raw platform C types on any exposed surface *including* `@_spi`, and the former `@_spi(Syscall)` raw-companion exception was removed in favor of typed-only L2 surfaces (raw C types stay `internal` / `fileprivate` / `private`). The residual `@_spi(Syscall)` companions are the Path-X tactical exception ([PLAT-ARCH-019]), explicitly staged for removal — i.e. tracked debt of exactly the kind this rule's audit pass targets.

**Not a licence to drop SPI in unrelated rewrites**: minimization means not *introducing* new SPI; it does NOT license silently dropping an existing `@_spi` import while rewriting a file for another reason — that build-breaking side effect is what [IMPL-095] forbids. Removing an existing SPI site is a deliberate migration (one of alternatives 1–4), not a rewrite by-product.


**Cross-references**: [MOD-016] (`@_spi` per-file opt-in — the auditable-boundary mechanics this rule's audit pass relies on), [MOD-DOMAIN] and [MOD-008] (the extract-a-shared-target alternative), [PLAT-ARCH-005a] and [PLAT-ARCH-019] (platform application: typed-only surfaces, no SPI exception, Path-X residual debt), [IMPL-095] (preserve `@_spi` imports during rewrites — the distinct don't-accidentally-drop rule), [INFRA-026] and [RES-021] (`@_spi` stripped from `.swiftinterface`).
