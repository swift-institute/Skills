---
name: swift-package-build
description: |
  Build, test, and resolve Swift Institute packages through the machine-wide coordinator. Apply for SwiftPM, xcodebuild, build concurrency, toolchains, or dependency resolution.

layer: process

requires:
  - swift-institute-core

applies_to:
  - swift
  - swift6
  - swift-build
  - swiftpm
  - xcodebuild

created: 2026-05-03
---

# Swift Package Build

All local Swift build-capable work crosses one boundary:

```text
/Users/coen/Developer/swift-institute/Scripts/swift-build
```

The coordinator owns machine-wide capacity, same-root serialization, workspace
resolution, Xcode path isolation, and subprocess lifetime. Harness hooks only
reject bypasses; they are not the lock.

## Canonical commands

```bash
# SwiftPM, from the package root
/Users/coen/Developer/swift-institute/Scripts/swift-build package build
/Users/coen/Developer/swift-institute/Scripts/swift-build package test
/Users/coen/Developer/swift-institute/Scripts/swift-build package resolve

# SwiftPM, from elsewhere
/Users/coen/Developer/swift-institute/Scripts/swift-build package build \
  --package-path /absolute/package/path -- --target TargetName

# The sole local Xcode workspace
/Users/coen/Developer/swift-institute/Scripts/swift-build workspace build \
  --scheme ProductName
/Users/coen/Developer/swift-institute/Scripts/swift-build workspace test \
  --scheme TestTargetName
/Users/coen/Developer/swift-institute/Scripts/swift-build workspace resolve \
  --scheme ProductName

# Capacity inspection
/Users/coen/Developer/swift-institute/Scripts/swift-build status

# Impact analysis and affected-package builds
/Users/coen/Developer/swift-institute/Scripts/swift-build impact -- \
  --upstream /absolute/upstream/package \
  --workspace /Users/coen/Developer

# Machine-readable SwiftPM leaves
/Users/coen/Developer/swift-institute/Scripts/swift-build package dump-package
/Users/coen/Developer/swift-institute/Scripts/swift-build package get-mirror -- \
  --original https://example.invalid/dependency.git
```

Defaults are two concurrent build processes and three SwiftPM jobs per process.
`SWIFT_BUILD_SLOTS` and `SWIFT_BUILD_JOBS` may override those values for a
measured experiment. Do not persist a different default without benchmark
evidence on the target machine.

---

### [PKG-BUILD-023] One Workspace, Concurrent Coordinator-Owned Invocations

**Statement**: The only local Xcode integration surface is
`/Users/coen/Developer/swift-institute/Internal/institute.xcworkspace`.
Invoke it only through `swift-build workspace build|test|resolve`. Every
workspace action requires a concrete scheme before dependency resolution. The
coordinator:

- reserves one machine-wide build slot for the full process lifetime;
- serializes package resolution when the workspace or a member manifest changes;
- includes the scheme in the resolution fingerprint and passes it to Xcode, so
  one scheme's resolution cannot suppress another scheme's required resolution;
- disables automatic resolution during the build;
- assigns each active slot its own persistent DerivedData lane and an isolated
  result-bundle path, so concurrent builds never share a build database;
- shares only the prepared source-package cache; and
- enables Xcode's compilation cache.

Concurrent workspace builds are permitted through the coordinator. Direct
`xcodebuild`, sibling workspaces, shared DerivedData paths, background bypasses,
and hand-managed Xcode build databases are forbidden.

The workspace uses Xcode's bundled toolchain. Do not set `TOOLCHAINS` for it.
Target names remain unique across the complete graph per [PKG-NAME-014]. New
packages join the master workspace as FileRefs.

---

### [PKG-BUILD-009] Global Capacity and Same-Root Safety

**Statement**: Parallel builds are allowed only through `swift-build`.
The machine-wide slot count limits aggregate compiler pressure across agents,
terminals, SwiftPM roots, and Xcode builds. SwiftPM operations against the same
package root serialize and reuse that root's default `.build`; operations on
different roots may run concurrently.

Never use `--ignore-lock`, a machine-global `SWIFTPM_BUILD_DIR`, ad hoc
background `swift`/`xcodebuild` processes, or a second scheduler. Separate git
worktrees are separate package roots and are the correct isolation when two
builds must exercise different source states of one repository.

An orchestrator may submit every independent package in one dependency wave,
then wait at the wave barrier, but submission fan-out is not capacity
ownership. The orchestrator MUST NOT retain or reacquire a package-root lock or
global slot around its lifetime. A coordinator-owned launcher that must build
the orchestrator first releases both the orchestrator root lock and its global
slot before executing it; only the subsequently submitted leaf actions acquire
locks and slots. Operational `swift-impact` runs use `swift-build impact`, not
a nested `package run` from the swift-impact root.

Manifest and mirror inspection used by an orchestrator are leaf actions too:
route them through `package dump-package` and `package get-mirror`. Their child
standard output remains machine-readable because coordinator tracing uses
standard error.

The default budget is deliberately conservative: `2 × 3` permits concurrency
without multiplying SwiftPM's usual per-process job count across agents. Any
change requires measured wall time, peak memory, thermal behavior, and failure
rate for at least `1×8`, `2×4`, `2×3`, `3×2`, and `3×3`.

---

### [PKG-BUILD-010] Package.resolved Is Generated, Ignored State

**Statement**: `Package.resolved` MUST NOT be committed anywhere in this
workspace. Every repository ignores it recursively. Builds and resolution may
generate or refresh it, but agents MUST NOT hand-edit it, copy candidate pins
into it, stage it, diff it as an intended source change, or delete it to force
dependency advancement.

Change dependency requirements in `Package.swift`, then run the coordinator's
`package resolve`, `package update`, build, or test operation. Diagnose the
manifest, repository identity, mirrors, credentials, and resolver output—not
individual lockfile pins. CI resolves from the manifest and may retain the
generated file only as an uncommitted diagnostic artifact.

`--force-resolved-versions` is forbidden in local, Docker, and CI commands: it
turns ignored ephemeral state into an undeclared input.

---

### [PKG-BUILD-012] Resolution and Builds Share the Same Root Lock

**Statement**: SwiftPM resolve, update, clean, reset, build, test, and run
operations use the coordinator's same per-package-root exclusive lock. This
prevents a resolver from changing root-local generated state while another
process uses it. Do not run a separate resolution process around an active
build.

For Xcode, the coordinator fingerprints the master workspace plus all member
`Package.swift` files. A changed fingerprint forces one exclusive dependency
resolution; unchanged builds share the prepared resolution under a read lock.

---

### [PKG-BUILD-013] Clean-Room and Publication Evidence Uses Source Isolation

**Statement**: Release/publication evidence runs from a clean checkout or git
worktree, not by deleting `.build` or `Package.resolved` in a dirty working
tree. Route the worktree's SwiftPM command through the coordinator and preserve
its actual exit status. A clean room proves the manifest can resolve from its
declared URLs without local edits; it does not prove a committed lockfile.

---

### [PKG-BUILD-014] Dependency Identity Comes From the Manifest and Repository

**Statement**: Diagnose dependency identity from canonical repository URLs,
package identities, product names, mirrors, and the resolved graph emitted by
SwiftPM. Do not repair identity problems by editing a `Package.resolved` pin.
When a dependency changes ownership or URL, update the manifest and verify from
a clean worktree.

---

### [PKG-BUILD-015] Resolution Failures Are Evidence, Not Pin Work

**Statement**: On a resolution failure, capture the coordinator command, exit
status, resolver diagnostics, manifest diff, applicable mirror configuration,
and authentication state. Fix the declared dependency or environment. Never
manufacture a lockfile, transplant revisions, or perform manual pin surgery.

---

### [PKG-BUILD-016] Preserve Command and Exit-Status Evidence

**Statement**: A green claim requires the exact coordinator command and its
actual exit status. Capture pipeline status from the build process, not a
trailing formatter. A cached success is valid build evidence but not fresh
compilation evidence; state which one was measured.

Do not repeatedly rerun a long failure merely to recover diagnostics already
present in a complete log. Reduce to a focused target or test and retain the
first trustworthy failure.

---

### [PKG-BUILD-017] Bound Apparent Hangs

**Statement**: Distinguish dependency resolution, graph planning, compilation,
linking, and test execution before calling a build hung. Inspect the process and
log, and preserve evidence. A bounded SwiftPM leaf uses the coordinator's
`--timeout-seconds`; its deadline begins only after the package-root lock and a
global slot have both been acquired. At expiry the coordinator sends TERM to
the owned process group, waits the configured grace period, escalates to KILL,
reaps the direct child, and proves the complete process group absent before it
returns 124 or releases either lock. The caller MUST leave swift-process's own
timeout nil for coordinator children and MUST NOT kill the coordinator to
enforce a competing outer deadline.

Never use broad `pkill`, stale PID files, or open-ended polling. A user-requested
SIGINT or SIGTERM follows the same group-cleanup invariant while preserving the
signal-derived exit status.

---

### [PKG-BUILD-018] Graph-Planning Stalls Escalate with a Reproducer

**Statement**: If SwiftPM remains CPU-active in graph planning beyond the
bounded window, record a sample, manifest/target counts, toolchain, and the
smallest reproducer. A workspace scheme may be used as an engine comparison,
but it still runs through the coordinator.

---

### [PKG-BUILD-019] Supersession Swaps Gate the Swapped Surface

**Statement**: A dependency, macro, or engine replacement must build the
swapped surface before landing. When external state makes that impossible,
name the un-gated targets and reason explicitly; do not imply green evidence.

---

### [PKG-BUILD-020] Full Error Inventory Uses a Controlled Target Sweep

**Statement**: When a full SwiftPM build halts before sibling targets are
visited, derive the target list from `swift-build package dump-package` and run
each target serially through the coordinator. Deduplicate diagnostics by
`file:line:message` and retain each coordinator exit status.

---

### [PKG-BUILD-021] Check Capacity Before Interpreting Toolchain Failure

**Statement**: On output-stream failure, malformed target-info JSON, errno 28,
or unexplained compiler termination, inspect free disk, memory pressure, and
the coordinator's active-slot state before concluding the source or compiler
is defective.

---

### [PKG-BUILD-024] Toolchain Scope

**Statement**: Local workspace work uses Xcode's bundled toolchain with no
`TOOLCHAINS` environment variable. A standalone release or nightly toolchain is
allowed only for an explicit clean-room, forward-compatibility, Embedded, or CI
context. Pass it through the coordinator and assert the resolved compiler
before treating the result as evidence.

### [PKG-BUILD-001] Select Non-Default SwiftPM Toolchains with `TOOLCHAINS`

Use the installed toolchain's bundle identifier, not `xcrun --toolchain`, for
an explicit alternate-toolchain SwiftPM run. Keep the environment scoped to the
single coordinator invocation.

### [PKG-BUILD-002] Read the Bundle Identifier from `Info.plist`

Obtain `CFBundleIdentifier` with `defaults read` from the installed
`.xctoolchain`; never infer it from the directory or snapshot name.

### [PKG-BUILD-003] Verify Build Configuration Before Blaming Source

When compiler output contradicts the selected toolchain's interfaces, first
verify the resolved compiler, SDK, standard-library path, and environment.

### [PKG-BUILD-004] Toolchain Choice Is Contextual

Use Xcode's bundled compiler for the workspace, a stated standalone release for
publication clean rooms, a nightly only for explicit forward-compatibility
spikes, and the CI image's compiler in CI.

### [PKG-BUILD-011] Recheck Nightly Failures on Stable

A nightly compiler or SDK is an experimental variable. Reproduce any nightly
failure with the stable toolchain before attributing it to source, dependency
identity, or the coordinator. Record both outcomes.

### [PKG-BUILD-022] Assert Every Explicit Toolchain Selection

`TOOLCHAINS` silently falls back when its identifier is invalid. In the same
environment used by the coordinator, match `swift --version` on the expected
build tag—not only the marketing version—before accepting build evidence.

---

### [PKG-BUILD-005] Linux Uses an Official Swift Container

Stable Linux validation uses an official `swift:<version>` image. Route the
outer Docker command through the applicable CI or experiment workflow; inside
the container, limit SwiftPM jobs to the allocated capacity and do not rely on
a committed `Package.resolved`.

### [PKG-BUILD-006] Linux Nightly Is Forward-Compatibility Evidence

Use `swiftlang/swift:nightly-main-jammy` only for an explicit nightly lane.
Nightly failure does not override stable evidence without diagnosis.

### [PKG-BUILD-007] Guard Non-Embedded Source Surface

Code unavailable to Embedded Swift—including reflection, Foundation, and
unsupported concurrency surface—belongs under `#if !hasFeature(Embedded)`.

### [PKG-BUILD-008] Embedded Builds Use the Declared SDK and Mode

Embedded evidence states the SDK, target, toolchain, and feature mode. It runs
in an isolated clean room with bounded coordinator capacity; a source guard by
itself is not build evidence.

---

## Cross-references

- **swift-institute-core** owns skill routing.
- **testing** and **testing-institute** own test design; their build-capable
  commands are payloads for this coordinator.
- **benchmark** owns measurement design; build concurrency experiments vary
  `SWIFT_BUILD_SLOTS` and `SWIFT_BUILD_JOBS` only for the measured invocation.
- **release-readiness** and **ci-cd-workflows** consume build evidence but do
  not create alternate local schedulers or lockfile policy.
