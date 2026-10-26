---
name: architecture
description: The Swift Institute's organization and layering — the four layers and their organizations, dependency direction, Standards authority structure, Foundation-freedom, and package and namespace naming. Applies in any Swift Institute repository, always, and governs where any package, target, type, or dependency is placed.
---

# Architecture

The ecosystem is one composed Institute. Every capability has exactly one semantic owner;
every other package composes that owner.

## The four layers

```
L4 Compositions  org swift-compositions, repo swift-{concept}   What can be composed safely?
L3 Standards     swift-standards and the authority     What is specified externally?
                 orgs: swift-{spec-id} / -standard
L2 Molecules     org swift-molecules, repo swift-{concept}      What is built from atoms alone?
L1 Atoms         org swift-atoms, repo swift-{concept}          What must exist?
```

The authority is `swift-institute/.github`'s `.github/policy/fleet.json`, which assigns every
organization its layer; `swift-institute` is the control organization and roots no layer. The
August–September 2026 reorganization split the former Primitives layer (`swift-primitives`,
`swift-{concept}-primitives`) into atoms and molecules, dropped the `-primitives` suffix, and
renamed the former Foundations layer (`swift-foundations`) to `swift-compositions`; text that
still says Primitives means L1–L2 and Foundations means L4.

All four are Apache 2.0. `swift-components` and `swift-applications` were emptied on
2026-07-28 and are not residences — a directory under either records an intention, never
precedent or ownership evidence. L4 is the top layer; extractions land in `swift-compositions`
unless a layer is deliberately being stood up.

Placement test: can you point to an external man page, spec chapter, or SDK document defining
this type's surface? Yes → L3. No → L1 if it is an atomic prerequisite, L2 if it is built from
atoms alone, L4 if it composes beyond that.

## Dependency direction

Dependencies point downward and the graph stays acyclic.

A same-layer edge is admissible only when the edge is an essential semantic prerequisite, the
same-layer graph stays acyclic, and the edge does not push higher-layer policy into the
dependency. Convenience and incidental reuse are not admissible — the question is whether the
dependency could be understood without the dependent, not whether the edge is handy. Within L1
and L2 the stricter tier DAG applies: strictly lower tier only, no lateral edges, and tiers are
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
Atoms and molecules must additionally be deployable on Swift Embedded: no reflection, no
Objective-C interop, no runtime features absent in embedded contexts.

Macro targets are allowed at L1, L2 and L4, and not at L3: a Standards package carries no
`.macro` target. A macro's plugin runs on the host at compile time, so the code it expands into
a main target is what must stay Embedded-deployable at L1 and L2. No machine check enforces
the L3 rule yet.

The single exception is a target whose name ends in `Foundation Integration`. The exception covers the target class, never a per-file waiver — a core file that
wants Foundation moves that surface into the integration target.

L1 string and scalar escape hatches are withheld on purpose. Bridging an L1 typed value to
`Swift.String` by hand at L4 is the intended cost, not a gap.

A linter rule owns the import form, and it is the reason not to hand-roll the check: it has
named cases for the shapes a regex loses, including `@_exported import FoundationNetworking`.
What it cannot see is *use* of a Foundation type reached transitively, so a clean run is
evidence about imports and nothing more.

## Standards is an organization of organizations

Each authority has its own GitHub org: swift-ietf (`swift-rfc-{number}`), swift-iso
(`swift-iso-{number}`), swift-w3c, swift-whatwg, swift-ieee, swift-iec, swift-ecma,
swift-incits, swift-linux-foundation, swift-bipm, and the vendor orgs swift-arm-ltd,
swift-intel, swift-riscv, swift-microsoft. They and swift-standards are L3.
swift-standards itself holds the convergence packages, `swift-{concept}-standard`, which absorb
spec revisions so consumers importing the stable module never change. Convergence packages are
policy-free — opinion lives in `swift-compositions`.

- A package's location comes from its entry in the Institute inventory
  (`Institute.json`). Never infer it from the package name, and never determine
  it by scanning the tree.
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
- The namespace typealias binding is available only when the namespace is a **non-generic** type,
  or a generic **nominal** type. It is NOT available when the namespace's public spelling is a
  [DS-028] generic front-door **typealias**: member-type lookup does not look through an unbound
  generic typealias on any toolchain (swift-institute/Issues#81), and the family noun cannot carry
  both a generic and an arity-0 declaration (`invalid redeclaration`, verified). A family fronted
  by `X<E>` therefore has **no** `X` namespace to nest into; its capability protocol stays a
  top-level, non-underscored protocol, as `Iterable`, `Buildable`, and `Initiable` already do. A
  generic front-door alias may appear as a member-lookup base only in its **bound** form.
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
