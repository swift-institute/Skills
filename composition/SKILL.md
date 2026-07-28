---
name: composition
description: Compose before implementing — search the ecosystem for an owning package, product, target, type, operation, or CI/linter capability before adding a local version, resolve to one disposition, and declare the dependency correctly. Apply before declaring any type, operation, helper, conversion, test utility, or integration, and whenever adding or auditing a package dependency.
---

# Composition

Before declaring a type, operation, helper, accessor, conversion, collection, test utility, or
integration, establish whether the ecosystem already owns it. Search by capability —
semantics, dimensions, constraints, ownership behavior, layer — before searching symbol names;
equivalent capabilities routinely use different vocabulary. Search tooling too: a CI check or
linter rule may already own the enforcement you are about to hand-roll.

## Dispositions

Every reuse decision resolves to exactly one:

- **reuse** — depend on and call the existing capability;
- **expose** — add the smallest lawful dependency, product, target, import, overload, or
  conformance so the consumer can reach the owner;
- **complete** — add the missing lawful operation to the owner, verify it there, then consume it;
- **compose** — add integration at the lowest legal common owner;
- **implement once** — create the capability at the correct owner;
- **do not implement** — the absence is principled, protecting totality, dimensional
  correctness, ownership, lifetime, layering, or a spec boundary; redesign the call site.

Build and test the owner first, then its consumers.

## Stop and search again

Treat each of these as proof the search was not finished:

- a local `.rawValue` reach-through, `Int(bitPattern:)`, pointer arithmetic, or manual index math;
- `count - 1` or partial arithmetic presented as total;
- a hand-rolled `while` loop for general iteration or bulk storage;
- a new accessor wrapper, tag, bounded index, or storage view;
- a type differing from an ecosystem type only by namespace or spelling;
- a helper named for mechanism rather than domain intent;
- a conformance duplicated across packages;
- a dependency avoided by copying the depended-on capability.

"No result" is not evidence unless you show the search root and a positive control. Never
accept an unexplained zero from an ecosystem sweep.

When an Institute package is insufficient, improve that package. Do not reach for Apple
`Foundation`, a third-party library, or a hand-rolled workaround. If no Institute path exists
at all, the answer is a new Institute package, not a third-party adoption.

## Declaring the dependency

Every committed manifest spells dependencies exactly `https://github.com/<org>/<repo>.git` —
current org home, `.git` suffix, no bare form, no retired org spelling, no `.package(path:)`.

- Two spellings of one identity put it under two canonical locations and fire SwiftPM's
  conflicting-identity branch, which enumerates every distinct dependency path — an effective
  hang on institute-scale graphs. One divergent edge suffices.
- `.product(name:, package:)` spells the URL's repo name, never the on-disk directory
  basename; the basename resolves only with the machine-local mirror.
- Two packages in one closure declaring the same `name:` stall the build planner: parent
  process at 99% CPU, zero `swift-frontend` children, no `.build/` artifacts, never
  terminates, and SwiftPM emits no diagnostic. Audit for it before adding a dependency,
  enumerating the closure from manifests plus `Package.resolved` — not `swift package
  show-dependencies`, whose dumpers are independently exponential on large graphs.
- Declare every dependency the target's source actually imports; never rely on a transitive
  import. Imported but not declared as a `.product` is under-declared — add the product, do not
  remove the import.
- A full build (not resolve, not dump) emits SwiftPM's own unused-dependency warning; that is
  the authoritative prune signal.
- Test Support spine dependencies are exempt: absence from literal imports means the spine
  needs `@_exported public import`, not that the dependency is dead.
- `Package.resolved` is generated state — never commit, hand-edit, copy, or delete it to force
  resolution.
