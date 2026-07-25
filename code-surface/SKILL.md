---
name: code-surface
description: |
  API surface conventions: namespace structure, nested accessors, spec-mirroring, typed throws, error naming, one type per file.
  ALWAYS apply when declaring types, methods, properties, errors, or organizing files.

layer: implementation

requires:
  - swift-institute

applies_to:
  - swift
  - swift6
  - primitives
  - standards
  - foundations

absorbs:
  - naming
  - errors
  - code-organization
# Amendment/changelog history: Research/code-surface-skill-rationale.md §Changelog-Provenance (and git history of this file).
---

# Code Surface Conventions

All types, methods, properties, error types, and source files MUST follow these rules.

This skill is organized as a navigation hub, following the same pattern as the **memory-safety** skill. The rule bodies live in sibling files; load the file whose topic is active rather than reading all of them. The index below is complete — every rule in this skill appears in it, so a rule you cannot find here is a rule this skill does not have.

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/code-surface-skill-rationale.md` (referenced below as the rationale archive).

---

## Files

| Topic | File | Rules |
|-------|------|-------|
| Namespace structure and type naming | `namespace.md` | [API-NAME-001], [API-NAME-001a]–[API-NAME-001c], [API-NAME-002]–[API-NAME-004], [API-NAME-004a], [API-NAME-015] |
| Brand-owner lint configuration | `brand-lint.md` | [API-IMPL-024], [API-BRAND-001] |
| Error handling | `errors.md` | [API-ERR-001]–[API-ERR-009] |
| File structure and type bodies | `file-structure.md` | [API-IMPL-005]–[API-IMPL-009], [API-IMPL-018]–[API-IMPL-023] |
| State modeling | `state-modeling.md` | [API-IMPL-003], [API-IMPL-010], [API-IMPL-011] |
| Parameter ordering | `parameters.md` | [API-IMPL-012]–[API-IMPL-014] |
| Method, property, and phantom-type naming | `naming.md` | [API-NAME-005]–[API-NAME-014], [API-NAME-010a], [API-NAME-010b], [API-IMPL-016], [API-IMPL-017] |

---

## Rule Index

One-line hooks for every rule. Load the linked file when the topic is active.

### Namespace structure (`namespace.md`)

| ID | Hook |
|----|------|
| [API-NAME-001] | `Nest.Name` pattern — the base rule for every type name |
| [API-NAME-001a] | Single type, no namespace — when nesting is not warranted |
| [API-NAME-001b] | `LargerDomain.Subdomain` — subject-first when domain exceeds role |
| [API-NAME-001c] | Per-domain capability-marker protocol |
| [API-NAME-002] | No compound identifiers — nested accessors instead |
| [API-NAME-003] | Specification-mirroring names (`RFC_4122.UUID`, `ISO_32000.Page`) |
| [API-NAME-004] | No typealiases for type unification |
| [API-NAME-004a] | Namespace adoption typealiases — the permitted case |
| [API-NAME-015] | Namespace depth is not a design constraint |

### Brand-owner lint configuration (`brand-lint.md`)

| ID | Hook |
|----|------|
| [API-IMPL-024] | No redundant protocol-refinement restatement |
| [API-BRAND-001] | Brand-owner exclusion vocabulary |

### Error handling (`errors.md`)

| ID | Hook |
|----|------|
| [API-ERR-001] | Typed throws required — `throws(IO.Error)`, not bare `throws` |
| [API-ERR-002] | Nested error types |
| [API-ERR-003] | Describe the failure, not the recovery |
| [API-ERR-004] | Explicit closure annotation for typed throws |
| [API-ERR-005] | stdlib typed-throws compatibility (Swift 6.2.4) |
| [API-ERR-006] | No existential throws, ever |
| [API-ERR-007] | Public API path for error types, not hoisted internals |
| [API-ERR-008] | Lifecycle typealias only when ALL cases apply |
| [API-ERR-009] | No phantom-generic error types in typed throws |

### File structure and type bodies (`file-structure.md`)

| ID | Hook |
|----|------|
| [API-IMPL-005] | One type per file |
| [API-IMPL-006] | File naming convention |
| [API-IMPL-007] | Extension files — the documented exception to one-type-per-file |
| [API-IMPL-008] | Minimal type body |
| [API-IMPL-009] | Hoisted protocol with nested typealias |
| [API-IMPL-018] | `@retroactive` is package-scoped, not module-scoped |
| [API-IMPL-019] | Qualified names inside conforming extensions |
| [API-IMPL-020] | Explicit `Body = Never` on generic parser/serializer leaf conformers |
| [API-IMPL-021] | Coroutine accessors and `borrowing get` over `get`/`set` |
| [API-IMPL-022] | Tower value types are `@frozen` |
| [API-IMPL-023] | Capability seams are deletable conveniences; canonical spellings stay concrete |

### State modeling (`state-modeling.md`)

| ID | Hook |
|----|------|
| [API-IMPL-003] | Enum over Boolean |
| [API-IMPL-010] | A visibility change triggers a naming audit |
| [API-IMPL-011] | Wrapper completeness |

### Parameter ordering (`parameters.md`)

| ID | Hook |
|----|------|
| [API-IMPL-012] | Closure parameters trail the signature |
| [API-IMPL-013] | Multiple closures follow lifecycle order |
| [API-IMPL-014] | Configuration parameter placement |

### Method, property, and phantom-type naming (`naming.md`)

| ID | Hook |
|----|------|
| [API-NAME-005] | Pre-rename mechanical check for new type identifiers |
| [API-NAME-006] | New-code self-compliance during enforcement sweeps |
| [API-NAME-007] | Convention-known-convention-unapplied heuristic for method/property names |
| [API-NAME-008] | `Property.View` vs labeled method — the decision rule |
| [API-NAME-009] | Educational-diagnostic message format |
| [API-NAME-010] | No `*Tag` suffix for phantom types |
| [API-NAME-010a] | No nested `.Tag` sub-name for phantom types |
| [API-NAME-010b] | Maximal suppression on phantom parameters |
| [API-NAME-011] | `Options`, not `Flags`, for OptionSet types |
| [API-NAME-012] | No `impl` / `obj` / `inst` local-binding abbreviations |
| [API-NAME-013] | Drop a redundant prefix when the namespace supplies context |
| [API-NAME-014] | Module disambiguation over shadow-avoidance renames |
| [API-IMPL-016] | Typealiases allow nested type extensions |
| [API-IMPL-017] | Preserve labeled call-site syntax when migrating protocols to witness structs |

---

## Cross-References

See also:
- **implementation** skill for [IMPL-*] expression style, typed arithmetic, Property.View patterns
- **memory-safety** skill for [MEM-COPY-006] ~Copyable type organization exceptions
