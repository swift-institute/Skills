---
name: swift-package-build
description: |
  Build and test Institute packages with workspace xcodebuild; use SwiftPM only for clean rooms, alternate toolchains, Linux, Embedded, or CI. Apply for local builds, toolchain selection, or resolution diagnosis.

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

Operational rules for building Institute packages. There is ONE local-iteration
story — the workspace ([PKG-BUILD-023]). Everything SwiftPM-flavored in this
skill applies only to the scoped contexts named in [PKG-BUILD-024]: release/
publication clean-rooms, forward-compat (6.4-dev) spikes, Linux/Docker runs,
Embedded builds, and CI.

| Cluster | IDs | Topic |
|---|---|---|
| Local iteration | `[PKG-BUILD-023]` | The workspace: headless xcodebuild, clean environment |
| Toolchain scoping | `[PKG-BUILD-024]`, `[PKG-BUILD-001]–[PKG-BUILD-004]`, `[PKG-BUILD-011]`, `[PKG-BUILD-022]` | Where TOOLCHAINS applies; selection, lookup, triage, assert |
| Linux via Docker | `[PKG-BUILD-005]–[PKG-BUILD-006]` | Official `swift:<version>` images; release-config convention; nightly Linux |
| Embedded Swift | `[PKG-BUILD-007]–[PKG-BUILD-008]` | `#if !hasFeature(Embedded)` source-guard pattern; build-mode invocation |
| SwiftPM clean-room discipline | `[PKG-BUILD-009]–[PKG-BUILD-022]` | Staleness, resolution identity, hang triage, gating — scoped contexts only |

---

### [PKG-BUILD-023] Local Iteration Is the Workspace — Headless xcodebuild, Clean Environment

**Statement**: Local build/test iteration runs headless `xcodebuild` against
`/Users/coen/Developer/swift-institute/Internal/institute.xcworkspace` — live
local trees, warm DerivedData. This is THE local-iteration approach; per-repo
SwiftPM builds are NOT used for local iteration.

**Canonical invocations**:

```bash
# Build a product:
xcodebuild -workspace institute.xcworkspace -scheme "<Product>" \
    -destination 'platform=macOS' build

# Run a test target:
xcodebuild -workspace institute.xcworkspace -scheme "<Test Target>" \
    -destination 'platform=macOS,arch=arm64' test
```

**Mechanics**:

- **Clean environment, always.** Never set `TOOLCHAINS` for workspace builds —
  it breaks xcodebuild's tool lookup (posix_spawn/link failures) and protects
  nothing: Xcode 26.6 bundles Swift 6.3.3, the same compiler release as the
  standalone pin ([PKG-BUILD-024]).
- **One xcodebuild at a time.** The workspace's shared build database
  serializes builds; a second concurrent invocation waits on (or fights) the
  first. Sequential invocations only.
- **Unique target names across the whole graph.** Every target name must be
  unique workspace-wide — package-prefix test/parity targets per
  [PKG-NAME-014]. A duplicate name makes the workspace unloadable.
- **New packages join via FileRef.** Add a new package to the workspace by
  adding a `FileRef` entry to `institute.xcworkspace/contents.xcworkspacedata`;
  a package outside the workspace is outside the local-verification posture.
- **Live trees.** The workspace resolves sibling packages from their live local
  checkouts — no per-consumer dependency arming, no `Package.resolved`
  staleness class, no shared-cache phantom state for local iteration.

**Rationale**: One workspace build against live trees replaces N per-repo
SwiftPM builds, eliminates the local staleness/identity failure classes that
[PKG-BUILD-010]–[PKG-BUILD-014] exist to manage, and keeps a warm DerivedData
across the whole graph. CI remains the resolved-versions evidence for gates and
close — the workspace is the iteration surface, not the publication gate.

**Cross-references**: [PKG-BUILD-024], [PKG-NAME-014], [PKG-BUILD-013]
(publication clean-rooms — the SwiftPM context that survives).

---

### [PKG-BUILD-024] Toolchain Scoping — Local = Xcode's Bundled Toolchain; TOOLCHAINS Only in Scoped SwiftPM Contexts

**Statement**: The local toolchain is Xcode's bundled Swift (Xcode 26.6 ships
Swift 6.3.3, `swiftlang-6.3.3.1.3` — the same compiler release as the
standalone `swift-6.3.3-RELEASE` pin). `TOOLCHAINS` is NEVER set for local
work. The standalone-toolchain machinery — `TOOLCHAINS` selection
([PKG-BUILD-001]), bundle-id lookup ([PKG-BUILD-002]), resolved-compiler
assert ([PKG-BUILD-022]) — applies ONLY in these contexts:

| Context | Toolchain |
|---|---|
| Local iteration (workspace, [PKG-BUILD-023]) | Xcode bundled — no env vars |
| Release/publication SwiftPM clean-rooms ([PKG-BUILD-013]) | Standalone `swift-6.3.3-RELEASE` via `TOOLCHAINS` + assert |
| Forward-compat (6.4-dev) spikes | Nightly via `TOOLCHAINS` + assert |
| CI | Pins its own toolchain; resolved-versions evidence |

The standalone toolchain stays installed, dormant, for the clean-room and
spike contexts.

**Rationale**: With Xcode bundling the exact pinned compiler release, the
env-var + assert ceremony on every local command protects nothing and adds a
silent-fallback failure class ([PKG-BUILD-022]) plus xcodebuild breakage. The
ceremony earns its cost only where a NON-default toolchain must be proven to
have taken: clean-rooms, spikes, CI.

**Cross-references**: [PKG-BUILD-001], [PKG-BUILD-002], [PKG-BUILD-011],
[PKG-BUILD-022], [PKG-BUILD-023]

---

### [PKG-BUILD-001] Use `TOOLCHAINS` Env Var, Not `xcrun --toolchain`, for Non-Default-Toolchain SwiftPM Builds

**Scope**: [PKG-BUILD-024]'s SwiftPM contexts only (clean-rooms, spikes, CI) — never local workspace iteration.

**Statement**: To build a SwiftPM package against an installed non-default Swift toolchain (e.g. a 6.4-dev nightly), the `TOOLCHAINS` environment variable MUST be set to the toolchain's bundle identifier. The `xcrun --toolchain '<snapshot-name>' swift build` invocation is INSUFFICIENT and produces silent false-negative diagnostics.

**Correct**:
```bash
TOOLCHAINS=org.swift.64202603161a swift build
```

**Incorrect**:
```bash
xcrun --toolchain 'swift-DEVELOPMENT-SNAPSHOT-2026-03-16-a' swift build
```

**Why the wrong invocation fails silently**: `xcrun --toolchain '<snapshot-name>'` selects the toolchain's compiler binary (`swift`, `swiftc`) but does NOT redirect SwiftPM's stdlib resolution. SwiftPM continues to read `Swift.swiftinterface` from the host Xcode SDK, which on a stable-Xcode host is older than the nightly's bundled stdlib. The compiler binary is from the nightly; the stdlib `.swiftinterface` it resolves against is from the host SDK. Mismatch.

`TOOLCHAINS=<bundle-id>` is the established mechanism: SwiftPM (and the Swift driver more broadly) reads `TOOLCHAINS` and resolves the entire toolchain root from the installed `.xctoolchain` whose `Info.plist` declares that bundle identifier — including its bundled stdlib. The compiler and the stdlib it sees come from the same toolchain.

**Verification**: assert the resolved compiler per [PKG-BUILD-022] — `swift --version` under the same env var, matched on the build tag.

**Rationale**: Without this rule, verification spikes against new stdlib features can produce false negatives — the proposal text says one thing, the build says another, and the disagreement looks like the upstream feature is unlanded when it's actually a build-config error.

**Cross-references**: [PKG-BUILD-002], [PKG-BUILD-003], [PKG-BUILD-022], [PKG-BUILD-024]

---

### [PKG-BUILD-002] Look Up the Bundle Identifier via `defaults read`

**Scope**: [PKG-BUILD-024]'s SwiftPM contexts only.

**Statement**: The bundle identifier for [PKG-BUILD-001]'s `TOOLCHAINS` env var MUST be obtained from the toolchain's `Info.plist` via `defaults read`, not guessed from the snapshot name.

**Correct**:
```bash
$ defaults read /Users/<user>/Library/Developer/Toolchains/swift-DEVELOPMENT-SNAPSHOT-2026-03-16-a.xctoolchain/Info CFBundleIdentifier
org.swift.64202603161a
```

The bundle ID format (`org.swift.<6-digit-version-prefix><YYYYMMDD><suffix>`) is determined by the toolchain's build script, not by the snapshot directory name. Treating the snapshot directory name as the identifier is wrong and silently fails to select the toolchain.

**Procedure** when adopting a new nightly:

```bash
ls ~/Library/Developer/Toolchains/                    # find installed toolchains
defaults read ~/Library/Developer/Toolchains/<dir>/Info CFBundleIdentifier
TOOLCHAINS=<output> swift build                       # use the looked-up ID
```

**Locations**:
- User-installed nightlies: `~/Library/Developer/Toolchains/`
- System-installed toolchains: `/Library/Developer/Toolchains/`

`xcode-select -p` returns the active Xcode (unrelated to toolchain selection — `xcode-select` controls the developer dir, not the active toolchain).

**Rationale**: The bundle identifier is the only stable handle on a toolchain across snapshots and installations. Snapshot directory names change between snapshots; `swift-latest.xctoolchain` symlinks may point at the wrong target. The `Info.plist` is authoritative — and the lookup is still only necessary, not sufficient: assert per [PKG-BUILD-022].

**Cross-references**: [PKG-BUILD-001], [PKG-BUILD-022]

---

### [PKG-BUILD-003] When `.swiftinterface` and Build Result Disagree, Suspect Build-Config First

**Statement**: When a build fails with diagnostics that contradict an independent inspection of the toolchain's stdlib `.swiftinterface` (e.g., the build says `type does not conform to inherited protocol 'Copyable'` but the `.swiftinterface` declares `public protocol Equatable : ~Copyable, ~Escapable`), the first hypothesis MUST be a build-config defect (wrong toolchain selected, wrong SDK resolution) — NOT that the upstream change is missing.

**Triage order**:

1. Run `swift --version` under the same invocation as the failing build. Confirm it reports the expected toolchain.
2. If wrong toolchain → fix per [PKG-BUILD-001] / [PKG-BUILD-002].
3. If correct toolchain but build still fails → check whether SwiftPM is reading the toolchain's stdlib or the host SDK's:
    ```bash
    grep -A2 "^public protocol <ProtocolName>" \
        $(xcrun -f swift | xargs dirname | xargs dirname)/lib/swift/macosx/Swift.swiftmodule/arm64-apple-macos.swiftinterface
    ```
    Compare against the build's diagnostic.
4. Only after build-config is ruled out: file a bug, check upstream PR status, or conclude the feature is unlanded.

**Worked example (the origin incident)**: An SE-0499 verification spike under `xcrun --toolchain 'swift-DEVELOPMENT-SNAPSHOT-2026-03-16-a' swift build` failed with diagnostics matching pre-SE-0499 stdlib. The first conclusion was that SE-0499 was unlanded. Independent `.swiftinterface` inspection showed the nightly's bundled stdlib already had the change; the contradiction surfaced the build-config defect (`xcrun --toolchain` selecting only the compiler binary). Re-run with `TOOLCHAINS=org.swift.64202603161a` passed clean.

**Rationale**: Build failures look authoritative — they cite specific source locations and protocol names. But toolchain selection at the driver level does not propagate to stdlib resolution unless the env var path is used. Inverting the triage order — concluding upstream is missing before checking build config — wastes hours and produces incorrect research conclusions ([RES-023]).

**Cross-references**: [PKG-BUILD-001], [PKG-BUILD-002], [RES-021], [RES-023]

---

### [PKG-BUILD-004] Toolchain per Context — Xcode Bundled Locally; Standalone 6.3.3 for Clean-Rooms; Nightly for Forward-Compat Spikes

**Statement**: Local work uses Xcode's bundled toolchain with no env vars ([PKG-BUILD-024]). Where SwiftPM runs in a scoped context:

| Context | Selection | Notes |
|---|---|---|
| Release/publication clean-room | `TOOLCHAINS=org.swift.633202606251a` + assert `swift-6.3.3-RELEASE` ([PKG-BUILD-022]) | The standalone 6.3.3 release toolchain |
| Forward-compat spike | `TOOLCHAINS=<nightly bundle-id>` + assert | 6.4-dev only: unlanded SE proposals, `#if swift(>=6.4)` source-compat checks. Snapshots are currently broken — never conclude a hash / ownership / build problem from one; re-check on 6.3.3 first ([PKG-BUILD-011]) |
| CI | CI pins its own toolchain | Resolved-versions evidence for gates/close |

Other versions (6.1, 6.2, etc.) are not supported. The 6.4 flip is gated on CI green under 6.4.

**Rationale**: Nightly for routine work risks landing on regressions and compiler bugs that won't ship to consumers. Where a pin is claimed, the pin must be asserted — `TOOLCHAINS` silently falls back on an unknown identifier ([PKG-BUILD-022]).

**Cross-references**: [PKG-BUILD-001], [PKG-BUILD-011], [PKG-BUILD-022], [PKG-BUILD-024]

---

### [PKG-BUILD-005] Linux Builds Use the Official `swift:<version>` Docker Image

**Scope**: cross-platform validation and CI parity — not part of local macOS iteration.

**Statement**: Local Linux builds and tests for SwiftPM packages MUST use the official `swift:<version>` Docker image (Apple-published on Docker Hub). The package directory is volume-mounted into `/workspace`; `swift build` / `swift test` runs inside the container.

**Canonical invocation**:
```bash
docker run --rm \
    -v "$(pwd)":/workspace \
    -w /workspace \
    swift:6.3 \
    swift test -c release
```

The flags decompose as:
- `--rm`: container is deleted after the build/test finishes
- `-v "$(pwd)":/workspace`: bind-mount the package's working directory into `/workspace`
- `-w /workspace`: set the container's working directory
- `swift:6.3`: the official image tag (matches the workspace's stable Swift version)
- `swift test -c release`: per the centralized CI's Linux convention

**Why the official image**: `swift:<version>` is built and published by Apple and includes the matching Swift toolchain + Linux runtime libraries. Multi-arch (amd64 + arm64). No SwiftPM stdlib-resolution gotcha applies on Linux: the toolchain bundled in the container IS the toolchain SwiftPM resolves against.

**Convention: release config on Linux**: ecosystem CI runs `swift test -c release` (not debug) on Linux, per the centralized workflow `swift-institute/.github/.github/workflows/swift-ci.yml`. Local Docker invocations SHOULD match this for consistency. macOS runs debug; Linux runs release; this asymmetry is deliberate (release surfaces optimizer-driven bugs that debug doesn't).

**Cache hint**: `.build/` populated inside the container persists in the host workspace via the volume mount, so subsequent runs reuse it. To force a clean build: `rm -rf .build && docker run ...`.

**Rationale**: Official Apple-published images give reproducible Linux builds without setting up a local Linux toolchain. The volume-mount pattern keeps the package's source on the host while the build runs in a clean Linux environment.

**Cross-references**: [PKG-BUILD-006]

---

### [PKG-BUILD-006] Linux Nightly Builds Use `swiftlang/swift:nightly-main-jammy`

**Scope**: forward-compat spikes on Linux only.

**Statement**: To build a SwiftPM package against the Swift 6.4-dev nightly on Linux, use the `swiftlang/swift:nightly-main-jammy` image (the swiftlang-org-published nightly built from `main` on Ubuntu Jammy).

**Canonical invocation**:
```bash
docker run --rm \
    -v "$(pwd)":/workspace \
    -w /workspace \
    swiftlang/swift:nightly-main-jammy \
    swift test -c release
```

**Image semantics**:

| Image | Source | Update cadence |
|---|---|---|
| `swift:6.3` | Apple-published official | Locked to a stable Swift release |
| `swiftlang/swift:nightly-main-jammy` | swiftlang org-published | Tracks `main` branch; pulled each run gets the latest nightly |

The nightly image is published by the same source as the macOS DEVELOPMENT-SNAPSHOT toolchains, so a given date's image contains roughly the same Swift commit as that date's macOS nightly.

**Use case**: same as the macOS spike context — verification against unlanded SE proposals, cross-platform validation of `#if swift(>=6.4)` branches. Routine Linux CI uses [PKG-BUILD-005]'s stable image.

**No env-var gotcha on Linux**: the container's bundled toolchain is the only toolchain available; SwiftPM resolves against the container's `/usr/share/swift/`. No equivalent of `TOOLCHAINS` is needed.

**CI usage** (per the centralized workflow): the Ubuntu nightly job runs as `continue-on-error: true` because nightly may regress. Local nightly runs SHOULD treat failure the same way — diagnose the regression, but don't block stable work on it.

**Rationale**: A stable image covers routine Linux work; a nightly image covers SE-proposal-validation work, mirroring the macOS toolchain scoping per [PKG-BUILD-004].

**Cross-references**: [PKG-BUILD-001], [PKG-BUILD-004], [PKG-BUILD-005]

---

### [PKG-BUILD-007] Embedded Swift Source-Guard Pattern: `#if !hasFeature(Embedded)`

**Statement**: Code that depends on stdlib features unavailable in Embedded Swift mode (`Codable`, `String` interpolation with reflection, Mirror-based introspection, certain Foundation-derived types) MUST be guarded with `#if !hasFeature(Embedded)`. The guard is the source-side discipline that keeps a package compatible with future embedded builds, even when the package is not currently being built for embedded.

**Correct**:
```swift
public enum Comparison: Sendable, Hashable, CaseIterable {
    case less
    case equal
    case greater
}

#if !hasFeature(Embedded)
extension Comparison: Codable {}
#endif
```

The `Comparison` enum itself is embedded-compatible; its `Codable` conformance is not (Codable depends on Mirror reflection in stdlib). The guard preserves the enum's embedded usability while keeping `Codable` for non-embedded consumers.

**What requires guarding** (verified-incompatible-with-Embedded surface, non-exhaustive):

| stdlib / Foundation surface | Reason |
|---|---|
| `Codable` / `Encodable` / `Decodable` conformances | Mirror-based reflection unavailable |
| `String` interpolation with custom interpolators | Reflection-driven |
| `Mirror`, `CustomReflectable` | Reflection unavailable |
| `Any` / existential erasure beyond simple cases | Existential metadata unavailable |
| `Foundation` types (`Date`, `Data`, `URL`, etc.) | Foundation not in embedded |
| **`Actor` protocol + extensions on `Actor`** | The `Actor` protocol lives in `_Concurrency` which is unavailable in Embedded (verified 2026-05-08, `swift:6.3` Wasm SDK + `swiftlang/swift:nightly-main-jammy` 6.4-dev) |
| **`async` / `await` outside concurrency-feature-flagged builds** | `_Concurrency` module not imported by default in Embedded — error: `'_Concurrency' module not imported, required for async` |
| **`_Concurrency.withTaskCancellationHandler`, `withCheckedContinuation`, `withUnsafeContinuation`** | All in `_Concurrency`; not available in Embedded |
| **`CheckedContinuation` / `UnsafeContinuation` types** | `_Concurrency` module types |
| **`Task`, `TaskGroup`, `AsyncStream`, `AsyncSequence`** | All in `_Concurrency` |
| **`@MainActor`, `nonisolated(nonsending)`, isolation annotations** | Concurrency annotations require `_Concurrency` |

**Ecosystem prevalence**: the source-guard pattern is in active use across `swift-set-primitives`, `swift-tagged-primitives`, `swift-time-primitives`, `swift-dimension-primitives`, `swift-comparison-primitives`, and others. No package currently OPTS INTO embedded mode in its `Package.swift` — the ecosystem prepares the source for embedded compatibility but does not currently ship embedded builds. (The build-mode invocation is covered by [PKG-BUILD-008].)

**Companion compiler check**: `#if compiler(>=5.9)` is sometimes paired with `#if hasFeature(Embedded)` — `hasFeature` was introduced in Swift 5.9. For ecosystem packages targeting Swift 6.3+, no compiler-version guard is needed.

**Rationale**: Embedded compatibility is a forward-compatibility discipline. Guarding non-embedded surface today costs little (a few `#if` blocks) and preserves the option to ship an embedded build later without a source rewrite. Without the discipline, every later embedded-build attempt rediscovers the same `Codable`-style incompatibilities and patches them ad hoc.

**Cross-references**: [PKG-BUILD-008]

---

### [PKG-BUILD-008] Embedded Build-Mode Invocation (Verified on Swift 6.4-dev)

**Scope**: a forward-compat spike context ([PKG-BUILD-024]) — the nightly toolchain + `TOOLCHAINS` apply here.

**Statement**: To build a SwiftPM package in Embedded Swift mode, pass `-Xswiftc -enable-experimental-feature -Xswiftc Embedded` to `swift build`. The package's `Package.swift` does NOT need to opt in via `SwiftSetting.enableExperimentalFeature("Embedded")` — the command-line flag enables Embedded mode for the whole build. A target triple is NOT required when targeting `arm64-apple-macosx` for local development; Swift 6.4-dev ships an Embedded stdlib for this target.

**Canonical invocation** (verified against `swift-carrier-primitives` 2026-05-04):
```bash
TOOLCHAINS=org.swift.64202603161a swift build \
    -Xswiftc -enable-experimental-feature -Xswiftc Embedded
```

**Version requirement**: Swift 6.4-dev or newer. Swift 6.3.x FAILS with:
```
error: unable to load standard library for target 'arm64-apple-macosx26.0'
```
The macOS Embedded stdlib ships only in 6.4+. This implies [PKG-BUILD-001] applies — the `TOOLCHAINS` env var is required for selecting the nightly, not `xcrun --toolchain`.

**Cross-compilation to true embedded targets** (ARM Cortex-M, RISC-V): pass an explicit freestanding target triple:
```bash
TOOLCHAINS=org.swift.64202603161a swift build \
    -Xswiftc -enable-experimental-feature -Xswiftc Embedded \
    -Xswiftc -target -Xswiftc arm64-apple-none-macho     # or armv7em-none-none-eabi, etc.
```

This was verified to build clean against `arm64-apple-none-macho`. The platform-target matrix (`armv7em-none-none-eabi` for ARM Cortex-M, `riscv32-none-none-eabi` for RISC-V, etc.) has not been spot-tested in this skill cycle; per-target-triple validation is a follow-up.

**Source-side prerequisite**: per [PKG-BUILD-007], non-embedded surface MUST be guarded with `#if !hasFeature(Embedded)`. Packages that satisfy `[PRIM-FOUND-001]` (no Foundation imports) and use the source-guard pattern are embedded-buildable as-is — `swift-carrier-primitives` is the verified reference.

**What the verification spike found** (provenance for this rule):

| Toolchain | Target triple | Result |
|---|---|---|
| Swift 6.3.x (Xcode default) | default macOS | ❌ `unable to load standard library` |
| Swift 6.4-dev (`org.swift.64202603161a`) | default `arm64-apple-macosx` | ✅ Build complete |
| Swift 6.4-dev | freestanding `arm64-apple-none-macho` | ✅ Build complete |

Spike artifact: `swift-carrier-primitives` (a Foundation-free, dependency-free L1 primitive — clean test bed).

**Rationale**: Embedded mode in Swift 6.4 is mature enough to compile production-Foundation-free primitives without source modification. Every Foundation-free primitive can be CI-checked under Embedded mode with a single flag.

**Cross-references**: [PKG-BUILD-001], [PKG-BUILD-007], [PRIM-FOUND-001]

---

### [PKG-BUILD-009] No Parallel Builds

**Statement**: Multiple build invocations MUST NOT run in parallel — not via background Bash tool calls, not via xargs/parallel, not in a Monitor loop. This applies to workspace `xcodebuild` (the shared build database serializes; a second invocation only contends, [PKG-BUILD-023]) and to `swift build` in the scoped SwiftPM contexts. Build sequentially, one at a time, in the foreground; read the trailing output before moving on.

**Why (SwiftPM contexts)**: SwiftPM serializes per-package via a `.build` directory lock, but cross-package parallelism still fights for CPU, memory, and module-cache slots. The visible symptom is a `swift-build` process accumulating 20+ CPU-minutes with no terminal output.

**Recovery procedure when contention is suspected**: kill the mid-flight process(es); in SwiftPM contexts the `.build` directory MAY be partially corrupted after the kill — `rm -rf .build` ([PKG-BUILD-010]) before retry. Never re-launch a sibling parallel process to "make progress" — sequential retry is the only correct path.

**Cross-references**: [PKG-BUILD-010], [PKG-BUILD-023]

---

### [PKG-BUILD-010] Clean Build (`rm -rf .build`) Before Debugging Unexpected SwiftPM Failures

**Scope**: SwiftPM contexts only ([PKG-BUILD-024]) — workspace iteration has no per-package `.build` staleness class.

**Statement**: When a `swift build` or `swift test` in a scoped SwiftPM context fails unexpectedly — especially after a cross-package change, branch switch, or upstream-dependency update — the FIRST step is `rm -rf .build && swift package clean` before investigating the error message. Stale build caches frequently cause false failures whose source-level cause is non-existent.

**When the rule fires** (most common triggers):

| Situation | Why stale cache misleads |
|---|---|
| Compiler crash with signal 6 / segfault | Often a stale cache rather than a real source bug; clean-rebuild first |
| Type-not-found errors after upstream package change | Module-cache holds the prior interface |
| `.swiftinterface` content disagrees with build behavior | See [PKG-BUILD-003]; clean build is the diagnostic |
| Test failure after a branch switch or rebase | Resolved-deps and module-cache may be inconsistent with current Package.swift |
| Tests pass locally but fail in CI (or reverse) | Cache vs fresh-checkout asymmetry |

**Procedure**:

```bash
rm -rf .build
swift package clean
swift package resolve   # only after dep changes
swift build
```

Note `rm -rf .build` is NOT a clean-room — the shared SwiftPM cache survives it ([PKG-BUILD-013]).

**Cross-references**: [PKG-BUILD-003], [PKG-BUILD-009], [PKG-BUILD-013]

---

### [PKG-BUILD-011] Toolchain Version Policy: 6.3.3 Is THE Validation Compiler; 6.4-dev for Forward-Compat Spikes Only

**Statement**: Validation runs on Swift 6.3.3 — locally as Xcode 26.6's bundled compiler with no env vars ([PKG-BUILD-024]); in SwiftPM clean-rooms as the standalone release toolchain via `TOOLCHAINS` + assert ([PKG-BUILD-022]). 6.4-dev nightly is reserved for forward-compat spikes only (unlanded features, `#if swift(>=6.4)` source-compat checks) and is currently broken — its snapshots trip `#if swift(>=6.4)` forward gates and stricter `~Copyable`-param ownership rules, so NEVER conclude a hash / ownership / build problem from a snapshot; re-check on 6.3.3 first. Other versions (6.1, 6.2, etc.) MUST NOT be used for validation.

**Linux Docker images** — release vs nightly:

| Use | Image |
|-----|-------|
| Release (the validation toolchain) | `swift:6.3` |
| Nightly main (forward-compat spikes only) | `swiftlang/swift:nightly-main-jammy` |
| FORBIDDEN | `swiftlang/swift:nightly-6.3-jammy` |

The `nightly-6.3` image has `+assertions` compiler config that triggers assertion failures / ICE on valid `~Copyable` code (e.g., `Queue.Dynamic ~Copyable.swift` crashes the nightly compiler `f30e11b820448ef` but compiles fine under release). Symptom: hours wasted diagnosing a "compiler crash" that is actually a nightly-only assertion. Apply: `docker run --rm swift:6.3 sh -c "..."` — NOT `swiftlang/swift:nightly-6.3-jammy`.

**Verification surface**: macOS via the workspace ([PKG-BUILD-023]) is the primary local surface; Linux validation runs in the `swift:6.3` Docker container (the tag floats to the latest 6.3.x and needs no bump); CI is the resolved-versions gate.

**Cross-references**: [PKG-BUILD-004], [PKG-BUILD-005], [PKG-BUILD-006], [PKG-BUILD-024]

---

### [PKG-BUILD-012] Check `Package.resolved` Revision Before Claiming a Compiler / Overload-Resolution Bug

**Scope**: SwiftPM contexts only — workspace builds resolve live local trees and have no resolved-revision staleness.

**Statement**: When, in a SwiftPM build, a downstream consumer's call, extension, overload, or conformance "silently fails to resolve" against an upstream Institute package — and the upstream working tree looks correct — the FIRST hypothesis MUST be a stale resolved revision, NOT a Swift compiler bug. `Package.resolved` is gitignored (per-developer) and can lag the local upstream HEAD by months. `swift package update` refreshes the resolved revision and the local mirror; `rm -rf .build` alone does NOT. Diff the consumer's resolved revision against the upstream local HEAD before opening any compiler/SIL bug investigation.

**Rationale**: A stale resolved revision presents identically to a compiler overload-resolution bug — the new/renamed upstream symbol genuinely is not visible — but the cause is dependency staleness, not the compiler. Misdiagnosis burns an `/issue-investigation` cycle on a non-bug.

**Cross-references**: [PKG-BUILD-010], [PKG-BUILD-013], [ISSUE-030] (issue-investigation — the compiler-bug-claim gate)

---

### [PKG-BUILD-013] `rm -rf .build` Is NOT Cold — the Shared SwiftPM Cache Survives; Pin-Assert Is the Only Honest Local Clean-Room

**Scope**: release/publication gates and closure re-verifies — a clean-room discipline, never local-iteration guidance.

**Statement**: Removing a package's `.build` directory does NOT produce a cold build. The SHARED SwiftPM package cache (`~/Library/Caches/org.swift.swiftpm`) survives it and can serve dependency content that exists on NO branch of the dependency's repository (a previously-fetched commit later abandoned, rewritten, or never pushed). A warm-cache green is therefore untrustworthy wherever the green is read as a clean-room claim (publication gates, closure re-verifies, "resolves from scratch" assertions). The only honest local clean-room is a PIN-ASSERT: per package, clear BOTH `.build` AND `Package.resolved`, re-resolve, then assert every resolved revision equals the corresponding dependency's live `main` HEAD.

```bash
# Pin-assert clean-room, per package:
rm -rf .build Package.resolved
swift package resolve
# Assert each pin == its dep's live main HEAD (map identity → local repo across
# the org roots: swift-{primitives,standards,foundations,incits}/<identity>):
jq -r '.pins[] | "\(.identity) \(.state.revision)"' Package.resolved | while read -r dep rev; do
  live=$(git -C "<org-root-for>/$dep" rev-parse main)
  [ "$rev" = "$live" ] || echo "STALE PIN: $dep resolved=$rev live=$live"
done
```

**Escalation ladder** — three distinct staleness tools within SwiftPM contexts, in order of reach:

| Symptom | Tool | Reach |
|---------|------|-------|
| Stale build artifacts (crashes, type-not-found after upstream edits) | `rm -rf .build` ([PKG-BUILD-010]) | Build dir only |
| Stale resolved revision (upstream symbol "doesn't resolve") | `swift package update` ([PKG-BUILD-012]) | Pins + local mirror refresh |
| A green that will be READ as clean-room/publication evidence | Pin-assert (this rule) | Pins verified against live dep HEADs; phantom cache state exposed |

**Worked example (the origin incident)**: an MSB W3 publication-stage warm `swift build` was serving a no-branch commit (`11e1611`) out of the shared cache after `rm -rf .build`; the gate's greens were phantom. The cold re-run with pin-assert (36/36 packages, every pin == live main) is what made the stage's greens trustworthy.

**Rationale**: "clean" is a claim about a tool's reach, not about reality — `rm -rf .build` claims cold but does not reach the shared cache. Align the tool's reach with the claim's scope before trusting the green.

**Cross-references**: [PKG-BUILD-010], [PKG-BUILD-012], [PKG-BUILD-014]

---

### [PKG-BUILD-014] SwiftPM Package Identity Is the Directory Basename — Overrides Unify Only at Canonical Basenames

**Scope**: SwiftPM resolution contexts (publication/mirror flows) — local iteration uses the workspace's live trees and needs no override scheme.

**Statement**: A path-dependency's package identity is its directory BASENAME, and a root path-dep override beats a transitive url-dep to the same package ONLY when the basenames match. A suffixed working copy (`swift-foo--wip`) mints a DISTINCT identity that does NOT unify with the canonical identity arriving transitively (via url/mirror) → two checkouts with identical target names → `multiple similar targets`. Any local-override scheme MUST preserve canonical basenames (re-home at canonical basenames in a separate parent directory when a variant checkout is unavoidable).

**Mechanics**:

| Fact | Consequence |
|------|-------------|
| Identity = dir basename | `swift-foo--wip` ≠ `swift-foo`; the resolver unifies on basename, never on "obviously the same package" |
| Override wins only on identity match | A suffixed root path-dep coexists with (not replaces) the canonical transitive checkout |
| Transitive edges re-introduce the canonical identity | Chasing a suffixed mesh package-by-package never converges |
| `git worktree move` bakes stale absolute paths in ModuleCaches | `rm -rf .build` per package after re-homing a worktree |

Note: when a mirror maps urls to local paths ([PKG-BUILD-015]), the override surfaces as path-vs-path "Conflicting identity" WARNINGS (the direct path-dep wins); these disappear after merge-back to url form.

**Worked example (the origin incident)**: the MSB W3 `--w2`-suffixed worktree mesh produced `multiple similar targets` through every transitive edge; the canonical-basename whole-closure re-home dissolved every collision, and the closure verified 12/12 green.

**Rationale**: package identity is a filesystem fact composed transitively by the resolver. Schemes that encode "variant" in the directory name fight the resolver's unification rule and lose at the closure's edges.

**Cross-references**: [PKG-BUILD-013], [PKG-BUILD-015]

---

### [PKG-BUILD-015] Mirror-First Publication — URL-Resolved Packages Cannot Carry `path:` Dependencies

**Statement**: SwiftPM forbids a package that is itself resolved by url/revision from carrying `path:` dependencies (hard resolution error). "HOLD" designs — merging url-consumed packages to main with temporary `path:` deps on not-yet-published siblings, to be reverted post-publish — are therefore structurally unsound. The publication-safe order is MIRROR-FIRST: (1) create the dependency repos (private; they may be EMPTY) and add mirror entries mapping each url to the local checkout; (2) flip every HOLD line to url form; (3) verify with a pin-assert clean-room ([PKG-BUILD-013]). A mirror entry makes a url resolve to the LOCAL checkout without the remote needing any content — the mirror, not the remote, is what makes a url-form dep resolvable pre-publish.

**The two regimes**:

| Package is consumed via | `path:` deps in its manifest | Pre-publish dep form |
|------------------------|------------------------------|----------------------|
| Root / path (dev tree) | Allowed | `path:` is fine ([PKG-DEP-*] pre-publish default) |
| url/revision (any transitive consumer resolves it by url) | FORBIDDEN — resolution error | url + mirror entry to the local checkout |

**Worked example (the origin incident)**: the MSB W3 merge plan carried HOLD `path:` deps on 5 unpublished packages; Stage 2 halted on the resolution error. Resolution inverted the order: 5 repos created private+empty, 5 mirror entries added, 36 HOLD→url flips across 27 manifests, post-assert ZERO path-deps on any main, then the pin-assert cold re-run (36/36) sealed it.

**Rationale**: decouple "url-form dep" from "remote has content." The mirror supplies resolvability; the remote supplies publication. Sequencing repo-creation + mirror entries before the url flip makes the intermediate state buildable at every step.

**Cross-references**: [PKG-BUILD-013], [PKG-BUILD-014]

---

### [PKG-BUILD-016] A Build's First Error Output Is the Scope Evidence — Do Not Re-Run to Re-Enumerate

**Statement**: When a build (workspace xcodebuild or SwiftPM) fails, its FIRST emitted error output IS the scope evidence — the count and spread of failing files. An agent MUST NOT re-run a long build merely to re-enumerate the same failure, and MUST NOT start a second long-running command (build / test / install) to obtain information a command already running in the background will produce. Use `run_in_background` once, then make other progress while it runs; never issue a duplicate for the same information. Scope-driven routing: N ≤ 3 failing files in a single package → fix in place; a broad cascade (N > 3 across packages, or errors in packages not previously in scope) → STOP, do not grind through it build-by-build; write up the scope with the principled-pattern playbook and surface the scope question to the user.

**Rationale**: Redundant long builds consume wall-clock with no progress the user can see. The first failure already carries the scope; a second run only re-derives it. Broad cascades are escalation-shaped, not grind-shaped.

**Cross-references**: [PKG-BUILD-009], [PKG-BUILD-020].

---

### [PKG-BUILD-017] Verbose-Before-Kill — Silence Is Not Livelock Evidence

**Statement**: Before killing a silent build/resolve as hung — and ALWAYS before stamping a BLOCKED/LIVELOCK verdict on a package — run one watched retry with `--very-verbose` (xcodebuild: `-verbose`, or sample the live process) and judge on VISIBLE PROGRESS, not on output silence. Known legitimate-silence class at institute scale: sequential manifest loading (~1.5s × ~300 packages) plus per-checkout git churn = 10–18+ minutes of zero output with low-parallelism CPU — not a livelock. A genuine loop shows repeating lines / no manifest progression under verbose. The 5-minute reaction threshold (Workspace CLAUDE.md, hang discipline) still fires — but its FIRST action is the verbose probe, not the kill.

**Rationale**: a 49-minute zero-output "hang" (stripe-live) was walled as a suspected livelock; the verbose retry unmasked the same signature as legitimate manifest-loading silence. The converse case (a driver spinning with ZERO frontends at 51 min) was a real hang — the probe distinguishes the two where silence cannot.

**Cross-references**: hang discipline (Workspace CLAUDE.md), [PKG-BUILD-010] (SIGTERM-poisoned `.build`), [PKG-BUILD-018] (planning-blowup triage).

---

### [PKG-BUILD-018] Planning-Blowup Triage at Institute Graph Scale (SwiftPM Contexts)

**Scope**: swift-build's planner in SwiftPM contexts — the workspace posture ([PKG-BUILD-023]) already routes local iteration through XCBuild, which survives these graph sizes.

**Statement**: On an institute-scale SwiftPM graph, distinguish three planner states before acting: (1) **manifest toll** — legitimate; measured ~35 min per cold load (× retries) at ~300 packages; verbose shows manifest progression ([PKG-BUILD-017]). (2) **planner wedge** — 100% single-core CPU past the known toll with ZERO compiled artifacts, zero frontend processes, empty/frozen log: the build will never exit planning; kill it (registered PIDs only) and take the escape lane. (3) **poisoned state** — a previous SIGTERM left `.build` corrupt ([PKG-BUILD-010]): wipe `.build` before diagnosing anything else. Arm a COMPOUND watch (artifact-growth + log-growth + frontend-process + PID-death), never a single signal; set the planning fork explicitly (no compile evidence by +20 min past toll → stop and escalate, don't wait forever).

**Escape lane (evidence-backed)**: XCBuild — for a standalone package, `xcodebuild -scheme <exe> -destination 'platform=macOS' -derivedDataPath .xcbuild build`; XCBuild's planner survives graph sizes that wedge swift-build (a 2,082-target institute-ALL graph reached compilation under xcodebuild the same night swift-build wedged). This is the same engine the workspace posture uses by default.

**Rationale**: one app build burned 1h35m wedged at 100% CPU with a watch that would have waited forever; a second was killed at 51 min spinning in planning over SIGTERM-poisoned state. The triage table + compound watch + explicit fork turn both from open-ended stalls into ≤20-min decisions.

**Cross-references**: [PKG-BUILD-010], [PKG-BUILD-017], [PKG-BUILD-023], catalog §A26 (`show-dependencies` dumper blowup — a DIFFERENT exponential; never the probe).

---

### [PKG-BUILD-019] A Supersession-Swap Commit MUST Gate the Swapped Surface, or Name the Un-Gated Residue

**Statement**: A commit that swaps one dependency, macro, or engine for another (replacing X with Y — e.g. `@DependencyClient` → `@Witness`, `TestDependencyKey` → `Dependency.Key.Test`, a third-party parser for an institute one) MUST at minimum build the swapped surface (workspace scheme per [PKG-BUILD-023], or `swift build --target <T>` in a SwiftPM context) before landing. When an in-session gate is genuinely impossible (unresolvable graph, absent upstream), the commit message MUST name the un-gated residue explicitly — which targets were NOT built and why — so a never-green tree is a recorded state, not a silent landmine.

**Rationale**: three same-day supersession swaps each landed without a gate and left never-green trees that unrelated later arcs then tripped over (a @Witness port left 364 errors; a `DependencyKey` swap; a 67-row API drift). The swap is exactly the commit class most likely to leave residue, because it changes the surface the rest of the graph compiles against. A cheap build of the swapped surface catches the residue at authorship; an explicit residue note makes an un-gatable swap honest instead of a trap.

**Cross-references**: [PKG-BUILD-016], [PKG-BUILD-020], [PKG-DEP-012] (consumer-sweep-on-breaking-change).

---

### [PKG-BUILD-020] Full Error Inventory Is a Serial Per-Target Sweep, Not the Halting Full Build

**Scope**: SwiftPM builds (clean-rooms, CI diagnosis).

**Statement**: When a package's full `swift build` halts early on the first parallel target(s) to fail — masking sibling targets' errors — the honest full-error inventory is a SERIAL per-target sweep: iterate the manifest's regular targets (`swift package dump-package` → `.targets[].name`, excluding test/plugin/system targets as appropriate), run `swift build --target <T>` for each, and dedupe the collected diagnostics by `file:line:message`. Per-target exit status MUST be captured via `${pipestatus[1]}` (zsh) when the build is piped (e.g. `| tail`), NEVER `$?` after the pipe — `$?` reports the tail's status, not the build's.

**Rationale**: a full build of mailgun-types surfaced 11 errors before halting; the serial per-target sweep surfaced 77 real errors across the sibling targets the early halt had masked — scoping remediation off the 11-error view under-counts the work by ~7×. The full build answers "does it build"; the sweep answers "what is ALL the work", and only the sweep is a trustworthy inventory.

**Relationship to [PKG-BUILD-016]**: [PKG-BUILD-016] forbids re-running a long build to re-enumerate the SAME failure. [PKG-BUILD-020] is the complementary case: when the goal is the COMPLETE inventory across targets a parallel build never reached, the serial per-target sweep is the correct single derivation, not a redundant re-run.

**Cross-references**: [PKG-BUILD-009], [PKG-BUILD-016], [PKG-BUILD-019].

---

### [PKG-BUILD-021] Free-Space Precheck — ENOSPC Masquerades as a Compilation/JSON Verdict

**Statement**: A build-gate MUST treat a near-full data volume as a first-class failure cause, not a source verdict. When a build fails with `fatal error encountered during compilation` + `IO failure on output stream`, or SwiftPM emits `Failed to parse target info (malformed json 'error: other(28)')` (errno 28 = ENOSPC), the FIRST diagnostic step is `df -h` on the build volume — NOT reading the error as a compiler bug or a source defect. Free space and re-gate: a package that "failed" at N/M files on a full disk builds clean once space is reclaimed. A free-space check belongs in the gate's pre-flight.

**Why it misleads**: the disk-full condition surfaces at the output-stream write, so the toolchain reports it in compiler / JSON-parse terms with no mention of disk. `error: other(28)` is the only tell, and only if read as an errno.

**Worked example (origin incident — 2026-07-12)**: `swift build` on swift-email died at 5560/5576 files with the compilation/IO-failure signature on a 98%-full data volume; it built clean after space was freed. The ~400-package `.build` forest is a standing ~100GB+ reclaim — a recurring source of this false verdict.

**Cross-references**: [PKG-BUILD-017], [PKG-BUILD-018], [PKG-BUILD-020].

---

### [PKG-BUILD-022] Assert the RESOLVED Compiler Wherever `TOOLCHAINS` Is Set — It Does Not Error on an Unknown Identifier, It Silently Falls Back

**Scope**: every context that sets `TOOLCHAINS` ([PKG-BUILD-024]: clean-rooms, spikes, CI, index scripts). Local workspace builds never set it, so this rule never fires there.

**Statement**: `TOOLCHAINS` does NOT validate its argument. An unknown identifier — a typo, or an id whose toolchain has been uninstalled — produces **no error and no warning**: the driver silently falls back to Xcode's bundled toolchain and exits **0**. Therefore any gate, script, or CI step that sets `TOOLCHAINS` MUST **assert the compiler it actually resolved** — run `swift --version` under the *same* environment as the build, match it against an expected toolchain, and **fail closed** when it does not match. Selecting a toolchain ([PKG-BUILD-001]) and looking its identifier up ([PKG-BUILD-002]) are not sufficient: neither tells you the selection *took*. **A toolchain you did not verify is a claim, not a measurement.**

**Match the BUILD TAG, not the marketing version** — two different toolchains report the same `6.3.3`:

| `TOOLCHAINS` | resolved | exit |
|---|---|---|
| `org.swift.633202606251a` (installed, correct) | `Apple Swift version 6.3.3 (`**`swift-6.3.3-RELEASE`**`)` | 0 |
| a retired/uninstalled id | `Apple Swift version 6.3.3 (`**`swiftlang-6.3.3.1.3`**` clang-2100.1.1.101)` | **0** |
| `total.garbage.xyz` | *identical fallback* | **0** |

An assertion that greps for `6.3.3` **passes on the fallback** and enforces nothing. Assert on `swift-6.3.3-RELEASE` (the standalone toolchain's build tag); `swiftlang-*` is Xcode's bundled compiler — the correct answer for local builds, the wrong one for a clean-room that claimed the standalone pin.

**Why the existing rules do not already cover this**: [PKG-BUILD-003]'s triage runs `swift --version` — but *reactively*, as step 1 of diagnosing a **failure**. This defect's output is a **GREEN**, and a green never triggers triage. The check MUST be a fail-closed **precondition on every gate that sets the var**, not a diagnostic step available on request.

**Mechanism (already shipped — cite it, do not build a second one)**: `swift-institute/Scripts/gate.sh` (`e81a0ed`) performs this as PREFLIGHT 0 and exits **3** (a distinct code — a toolchain that did not resolve is not a compiler red) rather than gate on the wrong tower. Its `GATE_EXPECT` env var carries the expected build-tag regex, defaulting to `swift-6\.3\.3-RELEASE`. Use `Scripts/gate.sh`; a hand-rolled gate is unverified on this axis.

**Cross-references**: [PKG-BUILD-001], [PKG-BUILD-002], [PKG-BUILD-003], [PKG-BUILD-004], [PKG-BUILD-013], [PKG-BUILD-024]

---

## Cross-References

- **swift-institute-core** skill for the Skill Index
- **research-process** skill: [RES-021] Stdlib-Protocol Conformance Verification Spike, [RES-023] Empirical-Claim Verification (both rely on [PKG-BUILD-001]/[PKG-BUILD-003] discipline at execution time)
- **experiment-process** skill: experiments that toggle toolchain follow [PKG-BUILD-001]; cross-platform experiments use [PKG-BUILD-005]/[PKG-BUILD-006]
- **testing** / **testing-institute** skills: local test invocation follows [PKG-BUILD-023]; `swift test`-based rules there apply in the scoped SwiftPM contexts
