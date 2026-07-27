---
name: modularization
description: Design Swift package, product, target, file, ownership, and dependency boundaries. Apply when decomposing packages, placing capabilities, changing manifests, or reviewing module graphs.
---

# Modularization

Design boundaries from semantic ownership and dependency direction. Do not infer
one boundary from another: a package, product, target, namespace, type, and file
answer different questions.

## Governing rules

### [MOD-OWNER] Factor the law, not the code

Give each capability one semantic owner: the package and layer that define its
vocabulary, invariants, and lawful operations. Shared code, file size,
namespace spelling, and consumer count are evidence to inspect, not owners.

Institute tooling and policy follow the same rule. A package consumes the
Institute-owned executable or reusable workflow; it does not reproduce policy
in package-local YAML, helpers, or validators.

### [MOD-BOUNDARY] Decide every boundary independently

Choose:

- a **package** for release, repository, dependency, or ecosystem ownership;
- a **product** for a supported consumer choice;
- a **target** for a compile-time dependency and import boundary;
- a **file** for a focused declaration or conformance unit.

Do not create one merely because another exists. Read
[`references/decisions.md`](references/decisions.md) before proposing or
reviewing a structural change.

### [MOD-COMPOSE] Compose before implementing

Before adding a capability, apply **reuse-first**. Depend on and expose the
existing owner when it exists. If an owner lacks a lawful operation, add the
operation there and consume it; do not reproduce it locally.

For GitHub operations, compose repository-policy and
`swift-institute-bot`. Package-local Actions are a deny-by-default boundary,
not a convenient integration site.

### [MOD-GRAPH] Make ownership visible in the graph

Dependencies point from composition to capability and from higher layers to
lower layers. Keep package and target graphs acyclic. A convenience import,
umbrella, integration target, or SPI must not obscure the real owner or create
a reverse edge.

### [MOD-EVIDENCE] Change structure from facts

Inspect the manifest, products, targets, declared dependencies, source imports,
re-exports, consumers, and test-support edges before changing the graph. Never
accept an unexplained zero from an ecosystem sweep.

## Workflow

1. State the capability or responsibility being placed in one sentence.
2. Identify its present and intended semantic owner.
3. Apply **reuse-first** and record the existing capabilities considered.
4. Inventory the current package, product, target, import, and re-export graph.
5. Decide package, product, target, and file boundaries independently using
   [`references/decisions.md`](references/decisions.md).
6. Place optional integration at the lowest owner that may legally depend on
   every participant. Prefer an owner extension or trait-gated conformance;
   introduce an integration target or package only when it creates a real
   consumer or dependency boundary.
7. Minimize declared and imported dependencies without relying on transitives.
8. Run the linter and centralized CI for mechanical contracts, then build and
   test through **swift-package-build**.
9. Report the before/after graph and why each changed boundary exists.

## Required output for a structural decision

Record:

- semantic owner and layer;
- reuse evidence;
- package decision;
- product decision;
- target decision;
- file decision;
- dependency edges added and removed;
- integration ownership, if any;
- deterministic checks run;
- unresolved judgment or migration work.

“Cleaner”, “smaller”, “more modular”, and module count are not sufficient
reasons. Name the ownership, consumer, compilation, release, or dependency
property that improves.

## Decision rules

### [MOD-PACKAGE] Package means independent ecosystem ownership

Use a package for a coherent capability with an independent release,
dependency, repository, authority, or cycle-breaking boundary.

### [MOD-PRODUCT] Product means supported consumer choice

Publish products for stable adoption paths. Do not publish implementation
targets automatically.

### [MOD-TARGET] Target means compile-time boundary

Use a target for dependency pruning, optionality, constraint or platform
isolation, parallel compilation, or an independently importable capability.

### [MOD-FILE] File means declaration and review unit

Split files for focused declarations and conformances without inventing
dependency semantics.

### [MOD-LAYER] Place at the lowest lawful owner

Decompose independent axes, then place each at the lowest layer that owns its
meaning and can enforce its invariants.

### [MOD-INTEGRATION] Integration has an owner

Prefer an owner extension or trait-gated conformance. Add an integration target
or package only for an actual import, dependency, or release boundary.

### [MOD-IMPORT] Imports reveal direct ownership

Import the narrowest supported owner directly and declare every used dependency.
Reserve exported imports for deliberate aggregate products.

### [MOD-SPI] SPI is boundary debt

Exhaust public API, co-location, owned integration, and package access before
SPI. Keep unavoidable SPI local, explicit, and tracked.

### [MOD-VERIFY] Machines verify structure, reviewers verify ownership

Linter and CI diagnostics own exact syntax and graph predicates. Review decides
semantic ownership, cohesion, and whether a boundary should exist.

## Tool boundary

- Use Workspace's typed inventory and ecosystem probes for ecosystem facts.
- Use swift-linter and centralized validators for syntax and graph predicates.
- Use repository-policy for GitHub files, settings, Actions grants, and typed
  exemptions; use `swift-institute-bot` for cross-repository convergence.
- Use the compiler and coordinated build/test boundary for compilation facts.
- Keep semantic ownership, cohesion, and boundary choice as explicit review
  judgments. A detector may supply evidence but cannot decide them.

## Related skills

- **reuse-first** for capability discovery and composition.
- **swift-institute** for layer direction.
- **swift-package** for package identity and dependency declarations.
- **implementation** for code inside a target.
- **code-surface** for namespace and API shape.
- **swift-package-build** for verification.
