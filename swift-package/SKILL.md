---
name: swift-package
description: Package and namespace naming, product identity, and dependency declaration rules. Apply when creating or renaming a package, choosing a namespace, or declaring a cross-repository dependency.
---

# Swift package

A package name communicates semantic ownership; a manifest makes that ownership
and its dependency direction executable.

## Governing decisions

- Use noun-form package and namespace identities. Reserve a gerund for a
  capability typealias when that is the established domain shape.
- Keep package, product, target, and namespace names distinct; apply
  **modularization** rather than deriving one automatically from another.
- Declare every directly used dependency at the owning target. Never rely on a
  transitive import.
- Use local paths for deliberate local composition and canonical GitHub URLs
  for published dependencies. Institute packages must not depend on
  the personal `coenttb/*` namespace.
- Treat dependency spelling and identity as correctness, not presentation.

## Workflow

1. State the package’s semantic owner, layer, capability, and intended
   consumers.
2. Search the ecosystem with **reuse-first**.
3. Decide package, product, target, and namespace boundaries independently.
4. Check the proposed identity against existing packages, products, and
   modules.
5. Declare the narrowest direct dependencies and verify graph direction.
6. Validate the manifest through Workspace-owned package analysis.
7. Build and test through **swift-package-build**.

## Detailed rules

Load [`catalogue.md`](catalogue.md) for exact `[PKG-NAME-*]` and `[PKG-DEP-*]`
rules, naming exceptions, manifest spellings, namespace protocols, and
collision procedures.

## Related skills

- **modularization** for boundary and graph decisions.
- **reuse-first** for capability ownership.
- **swift-institute** for layer direction.
- **swift-package-build** for verification.
