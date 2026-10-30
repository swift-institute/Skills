---
name: institute
description: How the Swift Institute is built — its four layers and organizations, dependency direction, Standards authority structure, Foundation-freedom, package and namespace naming — and how to work in it locally (SwiftPM for standalone packages, the app's Xcode workspace for app work), what counts as evidence, and where CI and lint own the rules. Applies in any Swift Institute repository, and governs where any package, target, type, or dependency is placed.
---

# Institute

The ecosystem is one composed Institute. Every capability has exactly one semantic owner; every
other package composes that owner. When an Institute package is insufficient, improve it — do
not reach for Foundation, a third-party library, or a local workaround.

Any rule a machine can check lives in that check (swift-linter, Institute validators, CI), not
here. This skill holds what remains: the architecture, and the judgment a check cannot express.

## The four layers

```
L4 Compositions  org swift-compositions, repo swift-{concept}   What can be composed safely?
L3 Standards     swift-standards and the authority     What is specified externally?
                 orgs: swift-{spec-id} / -standard
L2 Molecules     org swift-molecules, repo swift-{concept}      What is built from atoms alone?
L1 Atoms         org swift-atoms, repo swift-{concept}          What must exist?
```

The authority is `swift-institute/.github`'s `.github/policy/fleet.json`, which assigns every
organization its layer; `swift-institute` is the control organization and roots no layer. Text
that still says Primitives (`swift-primitives`, `-primitives`) means L1–L2, and Foundations
(`swift-foundations`) means L4. `swift-components` and `swift-applications` are empty and are
not residences. Extractions land in `swift-compositions` unless a layer is deliberately being
stood up.

Placement test: can you point to an external man page, spec chapter, or SDK document defining
this type's surface? Yes → L3. No → L1 if it is an atomic prerequisite, L2 if it is built from
atoms alone, L4 if it composes beyond that.

## Dependency direction

Dependencies point downward and the graph stays acyclic. A same-layer edge is admissible only
when it is an essential semantic prerequisite, keeps the graph acyclic, and pushes no
higher-layer policy down. Within L1 and L2, edges go to a strictly lower tier only. Institute
packages never depend on `github.com/coenttb/*`.

- Layer follows essence, never dependencies. When edges violate a package's layer, refactor the
  edges; a capability a lower layer needs moves down — the consumer never lifts.
- Tests share `Package.swift` and bind to the layer rule too. Move offending tests to a sibling
  package at the right layer.

## Foundation-freedom

No main target at any layer imports the Foundation family or uses Foundation types; the one
exception is a target whose name ends in `Foundation Integration`. Atoms and molecules must
also deploy on Swift Embedded. Standards packages carry no macro target. The linter checks
imports only, not Foundation types reached transitively, and Embedded compatibility is proved
by compiling, never by searching.

## Standards is an organization of organizations

Each authority has its own GitHub org: swift-ietf (`swift-rfc-{number}`), swift-iso
(`swift-iso-{number}`), swift-w3c, swift-whatwg, swift-ieee, swift-iec, swift-ecma,
swift-incits, swift-linux-foundation, swift-bipm, and the vendor orgs swift-arm-ltd,
swift-intel, swift-riscv, swift-microsoft — all L3. swift-standards holds the policy-free
convergence packages, `swift-{concept}-standard`, which absorb spec revisions so consumers
never change; opinion lives in `swift-compositions`.

- A package's organization is the GitHub org that holds it; its layer comes from `fleet.json`.
  Never infer either from the name.
- One spec can carry two authorities' designations (IEEE 1003.1 is ISO/IEC 9945). Such
  packages partition the spec by surface; they are not duplicates.

## Package and namespace naming

Package names and top-level namespaces are nouns, never gerunds: the shortest natural noun
(`Render`, `Order`, `Format`); a stateful machine takes the agent noun (`Parser`, `Cursor`).
The gerund survives only as a typealias onto the capability protocol at the enclosing scope —
`Memory.Pool` / `Memory.Pool.Protocol` / `Memory.Pooling` is the full shape — and only where a
concrete value type backs the namespace.

Before a namespace rename, search the whole ecosystem for `import <OldModule>` (transitive
imports appear in no manifest) and for collision sites: collapsing `Ordering.Order` into
`Order.Order` re-binds bare `Order` inside `extension Order` without any error.

## Local development

Pick the build path by what the change is:

- **Standalone package work** (a package's own sources and tests, no app in scope): SwiftPM in
  the package directory — `swift build`, `swift test`, `swift test --filter`. Do not open Xcode.
- **App work** (Laurie or another app, its hosts, or a package change that must be proven
  through the app): the app's `.xcworkspace` (for Laurie, `Laurie.xcworkspace`) through the
  selected Xcode's connector, with the local package checkouts in that workspace by relative
  reference. Never rewrite manifests to machine-local absolute paths.

In the app workspace:

- Hold one instance. List workspaces first and target the open window; opening it again starts
  a second headless instance and the two re-plan against each other until Xcode hangs. Keep it
  open across tasks; identifiers do not survive a close.
- Let Xcode own package resolution, and check the resolved revisions before reading a result.
- Pick one scheme, action, destination and test plan per task and keep them: every new
  combination re-plans the whole graph from scratch. Narrow by test identifier inside the plan.
- One build or test at a time. A timed-out call leaves Xcode building; wait, do not retry.
- A run with failing tests returns as a successful call; read `counts.failed`.
- If the connector lacks a needed operation, report it; do not silently substitute SwiftPM,
  `xcodebuild`, or a wrapper.

## Evidence

- A cached green is not new evidence. For a new correctness or performance claim, confirm the
  changed sources compiled and the intended tests ran. `canImport`-gated code does not
  re-evaluate on an incremental build, so a clean build is the gate when conditional
  compilation is in scope.
- Record what a run was: roots, full SHAs and uncommitted changes, command or scheme, test
  selection, toolchain and SDK, result, clean or incremental. A filtered run proves only that
  filter.
- Pair every probe with a positive control. An absence claim ends with an unfiltered
  enumeration, never a pattern. Bare `grep` in this shell honours `.gitignore`; use
  `/usr/bin/grep` for evidence, quote paths (target directories contain spaces), and remember
  imports often live in `exports.swift` as `@_exported public import`.
- Report the first compiler diagnostic with the full log. Do not infer a source defect from a
  setup, resolution or toolchain failure; recheck nightly-only failures on stable.
- Stop unrelated verification once a decisive blocker fixes the next action.

## CI, lint and generated state

- CI full-tier `workflow_dispatch` is the evidence of record for issue closure; a local green
  is iteration evidence. `gh run rerun` replays an old snapshot — dispatch fresh.
- Institute lint is `institute ci -- source …`; CI's `Quality · source` job is the evidence. A
  stray `swift-format` or `swiftlint` run is not Institute lint.
- A convention recognisable from syntax or the package graph belongs in a rule, not in prose:
  swift-linter owns Swift syntax, Institute validators own package-graph facts,
  repository-policy owns GitHub state. Rules ship with positive, negative and exemption
  fixtures; suppress a finding only with `// swift-linter:disable:next <rule>` plus a
  `// REASON:` line.
- `Package.resolved` is generated: never commit, hand-edit or delete it to force resolution.
  Never delete `.build` or DerivedData as a reset; use a supported clean build.
- Institute tooling is Full Swift; no Python or shell automation.
- Toolchain bugs go to swift-institute/Issues' "Toolchain bug" form; nothing goes upstream
  until `issue-check` admits `upstream-ready` and Coen says yes.
