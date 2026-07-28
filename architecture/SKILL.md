---
name: architecture
description: The Swift Institute's organization and layering — the three realized layers, dependency direction, Standards authority structure, Foundation-freedom, and package and namespace naming. Applies in any Swift Institute repository, always, and governs where any package, target, type, or dependency is placed.
---

# Architecture

The ecosystem is one composed Institute. Every capability has exactly one semantic owner;
every other package composes that owner.

## The three realized layers

```
L3 Foundations   swift-{concept}              What can be composed safely?
L2 Standards     swift-{spec-id} / -standard  What is specified externally?
L1 Primitives    swift-{concept}-primitives   What must exist?
```

All three are Apache 2.0. Components (L4) and Applications (L5) are reserved names, not
residences — a `swift-components/*` or `swift-applications/*` directory records an intention,
never precedent or ownership evidence. L3 is the top realized layer; extractions land in
Foundations unless a layer is deliberately being stood up.

Placement test: can you point to an external man page, spec chapter, or SDK document defining
this type's surface? Yes → L2. No → L1 if it is an atomic prerequisite, L3 if it composes.

## Dependency direction

Dependencies point downward and the graph stays acyclic.

A same-layer edge is admissible only when the edge is an essential semantic prerequisite, the
same-layer graph stays acyclic, and the edge does not push higher-layer policy into the
dependency. Convenience and incidental reuse are not admissible — the question is whether the
dependency could be understood without the dependent, not whether the edge is handy. Within L1
the stricter tier DAG applies: strictly lower tier only, no lateral edges, and tiers are
computed from the graph rather than hand-maintained.

Institute packages must not depend on `github.com/coenttb/*`. Local `coenttb/*` paths are not
prohibited; repository scope decides whether they may be changed.

- Tests bind to the layer rule too: they share `Package.swift`, and SwiftPM cannot scope a
  dependency to tests only. Move offending tests to a sibling package at the right layer; if
  one must stay, mark the dependency with an explicit disable naming the constraint.
- Layer follows essence, never dependencies. When edges violate a package's layer, refactor the
  edges — never re-home the package to the layer its dependencies imply. A capability a
  lower-layer package needs but which is homed above it moves down; the consumer never lifts.
- Count `Package.swift` files, not directories, when reporting package counts, and report
  realized versus reserved separately.

## Foundation-freedom

No package's main target at any layer imports the Foundation module family — `Foundation`,
`FoundationEssentials`, `FoundationNetworking`, `FoundationXML` — or uses Foundation types.
Primitives must additionally be deployable on Swift Embedded: no reflection, no Objective-C
interop, no runtime features absent in embedded contexts.

The single exception is a target whose name ends in `Foundation Integration`. It may import
Foundation, it must be a leaf product, and no core target may depend on it directly or
transitively. The exception covers the target class, never a per-file waiver — a core file that
wants Foundation moves that surface into the integration target.

L1 string and scalar escape hatches are withheld on purpose. Bridging an L1 typed value to
`Swift.String` by hand at L3 is the intended cost, not a gap.

A linter rule owns the import form, and it is the reason not to hand-roll the check: it has
named cases for the shapes a regex loses, including `@_exported import FoundationNetworking`.
What it cannot see is *use* of a Foundation type reached transitively, so a clean run is
evidence about imports and nothing more.

## Standards is an organization of organizations

Each authority has its own GitHub org: swift-ietf (`swift-rfc-{number}`), swift-iso
(`swift-iso-{number}`), swift-w3c, swift-whatwg, swift-ieee, swift-iec, swift-ecma,
swift-incits, and the vendor orgs swift-arm-ltd, swift-intel, swift-riscv, swift-microsoft.
swift-standards itself holds the convergence packages, `swift-{concept}-standard`, which absorb
spec revisions so consumers importing the stable module never change. Convergence packages are
policy-free — opinion lives in Foundations.

- A package's location comes from its inventory entry in Workspace. Never infer it from the
  package name, and never determine it by scanning the tree.
- One specification can carry two authorities' designations — IEEE 1003.1 *is* ISO/IEC 9945.
  Packages under different authority orgs are then not duplicates; they partition the spec by
  surface. Check that before flagging duplication.

## Naming

Package names and top-level namespaces use the noun form; gerunds are forbidden there. Pick the
shortest natural noun (`Render`, `Order`, `Format`), preferring natural over short — `parse` is
a verb, so the namespace is `Parser`. A stateful stream-processing machine takes the agent noun
(`Parser`, `Iterator`, `Cursor`); a stateless relation takes the plain or deverbal noun
(`Hash`, `Comparison`).

The gerund survives as a typealias onto the canonical capability protocol, declared at the
namespace's enclosing scope so conformance sites read as English: `public typealias Rendering =
Render.` + a backtick-escaped `Protocol`. It targets that protocol only, never a sub-protocol,
and is omitted when no gerund exists. `Memory.Pool` / `Memory.Pool.Protocol` / `Memory.Pooling`
is the shape in full.

- A protocol nested in a generic type is a compiler error — hoist it to module scope as
  `__<Namespace>Protocol` and bind the namespace typealias to it.
- The shape applies only when a concrete value type backs the namespace. A pure capability or
  marker protocol with no backing value type stays top-level; an empty namespace shell invents
  structure that is not there.
- A package may keep an external package's gerund name only for named source compatibility with
  a specific external package (Apple's swift-testing); the internal namespace still follows the
  noun rule.
- A rename collapsing a gerund-outer/noun-inner pair into `Order.Order` breaks silently: inside
  `extension Order`, bare `Order` resolves to the inner tag, so former `Ordering.Order.x` call
  sites now resolve against it. Before any mechanical rename, grep the whole ecosystem for
  `import <OldModule>` — transitive-only import sites appear in no manifest — and for `extension
  *.<OldNamespace>` / `enum <OldNamespace>` collision sites.

Type names, member names, and file names are the `swift` skill's; this section stops at the
package and its top-level namespace.
