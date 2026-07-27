---
name: swift-package-build
description: Swift-owned package build, test, resolution, toolchain, and evidence workflow through Workspace. Always apply when running or reviewing SwiftPM operations in the Institute ecosystem.
---

# Swift package build

Workspace owns local SwiftPM execution. This skill explains evidence and
toolchain judgment; `workspace package` owns the command mechanics.

## Route

Use this skill when the task runs, changes, or interprets:

- package builds, tests, executable runs, clean, resolve, update, or manifest
  evaluation;
- non-default Swift toolchains, Linux, Embedded Swift, or release mode;
- a gate whose result will be reported as evidence.

Use **testing** for test design, **issue-investigation** for reproductions,
**ci-cd-workflows** for hosted matrices, and **swift-linter** for linting.

## Commands

Run from a package root, or supply `--package-path`:

```sh
workspace package build
workspace package test
workspace package resolve
workspace package update
workspace package clean
workspace package run
workspace package dump-package
```

For evidence:

```sh
workspace package build --fresh
workspace package test --fresh
```

Forward unusual SwiftPM arguments explicitly and repeat the option:

```sh
workspace package test \
  --argument=--filter \
  --argument Performance
```

Use the `=` form when a forwarded value begins with `-`, so the command parser
does not mistake that value for a Workspace option.

## Requirements

### [PKG-BUILD-OWNER] One Swift-owned execution boundary

Route supported SwiftPM operations through `workspace package`. Do not create a
repository-local wrapper, revive a Scripts collection, or add Python or shell
automation. If the typed Workspace surface lacks a required operation, extend
its owning Swift product and test that extension.

### [PKG-BUILD-FRESH] Evidence uses isolated state

Use `--fresh` for a build or test result that supports a release, audit,
benchmark, migration, or correctness claim. Fresh runs use unique scratch state
and remove that generated state afterward.

### [PKG-BUILD-GENERATED] Resolved state is generated

`Package.resolved` is generated and ignored. Change `Package.swift`, then use
`workspace package resolve` or `update`. Never hand-edit, copy, delete, stage,
or commit resolved state to force dependency movement.

### [PKG-BUILD-EVIDENCE] Report the exact measured scope

Record the package root, action, toolchain, meaningful forwarded arguments,
exit status, and whether the run was fresh. A cached green, a partial target,
or a build that did not run is not evidence for a wider claim.

On failure, preserve the first compiler diagnostic and the complete log. Do
not infer a source defect from a setup, resolution, capacity, or toolchain
failure.

### [PKG-BUILD-TOOLCHAIN] Toolchain selection is explicit and verified

Use the repository's declared stable toolchain unless the task specifically
requires another. When selecting a nightly or development toolchain, record
`swift --version` and confirm that the resolved executable belongs to the
intended Xcode or toolchain bundle before interpreting results.

Recheck a nightly-only failure on stable. Treat disagreement as evidence about
the toolchain boundary, not permission to change unrelated source.

### [PKG-BUILD-EMBEDDED] Embedded is a compiled configuration

For an Embedded claim, use the declared SDK and compiler mode through forwarded
Workspace arguments. A text search for imports cannot prove Embedded
compatibility; compilation is the evidence.

### [PKG-BUILD-CI] CI and local verification share semantics

Hosted CI may use its reusable Swift action directly, but its action,
toolchain, configuration, and package root must be reproducible through the
Workspace-owned local interface. Central CI owns matrices and aggregation;
consumer repositories remain thin callers.

## Stop conditions

Stop and report an unmeasured result when:

- Workspace does not expose the required operation;
- the selected toolchain cannot be established;
- dependency resolution fails before compilation;
- another process or dirty generated state makes the measured scope ambiguous;
- a command would require manipulating `Package.resolved`.
