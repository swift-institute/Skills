---
name: reuse-first
description: Find, select, expose, and compose existing Swift Institute capabilities before implementing new ones. Apply before adding types, operations, helpers, dependencies, or integrations.
---

# Reuse first

Treat the ecosystem as one composed library. A capability has one owner and
every package either consumes that owner or contributes the missing lawful
operation to it.

This skill replaces static infrastructure catalogues. A copied catalogue
drifts; source, manifests, Workspace facts, compiler behavior, and owning skills
are the authority.

## Rules

### [REUSE-001] Search before design

Before declaring a type, operation, helper, accessor, conversion, collection,
test utility, or integration, establish whether the ecosystem already owns the
capability.

### [REUSE-002] Search by capability

Describe the required semantics, dimensions, constraints, ownership behavior,
and layer before searching symbol names. Equivalent capabilities often use
different vocabulary; matching text alone is insufficient.

### [REUSE-003] One semantic owner

Reuse the package that owns the vocabulary and laws. Do not choose a local copy
because it is closer, easier to import, or avoids a dependency that the
semantics genuinely require.

### [REUSE-004] Expose instead of reproduce

If the owner exists but the consumer cannot reach the capability, add the
smallest lawful dependency, product, target, import, overload, or conformance.
Do not recreate the capability at the consumer.

### [REUSE-005] Complete the owner

If the type exists but a lawful operation is missing, add the operation to its
owner or owned integration surface, verify it there, then consume it. Do not
land the operation first as an application-local helper.

### [REUSE-006] Preserve principled absences

A failed search does not authorize implementation. Determine whether the
absence protects totality, dimensional correctness, ownership, lifetime,
layering, or specification boundaries. Redesign the call site when it does.

### [REUSE-007] Make recurrence mechanical

When a duplicate or mechanism-shaped pattern can be recognized
deterministically, add or extend a swift-linter rule and enforce it through
centralized CI. Keep rationale and choice in skills; keep repeat detection out
of them.

## Workflow

1. Write a capability statement: inputs, output, laws, failure behavior,
   ownership, platform constraints, and intended layer.
2. Identify likely owners using **swift-institute-ecosystem** and the relevant
   domain skill.
3. Inspect package products and targets, then search declarations and imports.
   Prefer Workspace facts, code navigation, and the canonical ecosystem probe. If a
   text probe is necessary, pair it with a known-positive control before
   trusting a zero.
4. Compare candidates semantically, including generic constraints,
   copyability, lifetime, error, and dependency behavior.
5. Choose exactly one disposition:
   - **reuse** — depend on and call the existing capability;
   - **expose** — publish or import an existing owned capability;
   - **complete** — add a lawful operation to the owner;
   - **compose** — add integration at the lowest legal common owner;
   - **implement once** — create a new capability at the correct owner;
   - **do not implement** — preserve a principled absence.
6. Apply **modularization** to every new dependency or boundary.
7. Build and test the owner first, then its consumers.
8. Report the evidence and disposition.

## Evidence record

For non-trivial work, record:

- capability statement;
- queries and roots inspected;
- candidates considered;
- selected owner and why;
- reuse disposition;
- dependency/import changes;
- owner and consumer verification;
- linter or CI follow-up when the pattern can recur.

“No result” is not evidence unless the search root and a positive control are
shown.

## Domain routing

Load only the owner skill relevant to the capability:

| Capability | Owner guidance |
|---|---|
| typed arithmetic, functors, call-site operations | **implementation**, **conversions** |
| indices, counts, ordinals, offsets | **conversions** |
| storage, spans, pointer boundaries, lifetimes | **memory-safety** |
| collections and data structures | **ecosystem-data-structures** |
| namespace, accessors, API and error shape | **code-surface** |
| fixtures, models, assertions, generators | **testing** |
| platform seams | **platform** |
| package/product/target placement | **modularization**, **swift-package** |

Do not load every routed skill pre-emptively.

## Common stop signals

Stop and search again when code introduces:

- `.rawValue`, `Int(bitPattern:)`, pointer arithmetic, or manual index math;
- `count - 1`, partial arithmetic presented as total, or dimension mixing;
- a local `while` loop for a general iteration or bulk-storage operation;
- a new accessor wrapper, tag, bounded index, or storage view;
- a type that differs from an ecosystem type only by namespace or spelling;
- a helper whose name describes mechanism rather than domain intent;
- a conformance or integration duplicated across packages;
- a dependency avoided by copying the depended-on capability.

These are signals, not blanket prohibitions. Resolve them using the workflow and
the owning skill.
