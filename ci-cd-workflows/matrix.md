# CI/CD — Universal Matrix, Toolchain & L1 Invariants

Companion of the **ci-cd-workflows** skill (navigation hub: `SKILL.md`). Load when working on the universal build/test matrix, toolchain/runner pins, the Linux container image, the L1 embedded-buildability invariants encoded in CI, or a per-job gating posture. This file reads independently: it collects the rules that define the platform contract and its job shapes.

**Rules in this file**: [CI-010], [CI-011], [CI-012], [CI-013], [CI-091], [CI-114], [CI-115], [CI-092], [CI-020], [CI-021], [CI-022], [CI-099]

---

## Universal Matrix

### [CI-010] Universal Matrix Shape

**Statement**: The universal CI matrix consists of four hardcoded gating jobs — `macos-release`, `linux-release`, `linux-nightly` (continue-on-error), `windows-release` — plus the advisory `apple-simulator-build` leg: a macOS-runner job with a `strategy.matrix.platform` over the four Apple simulator platforms (`iOS`, `tvOS`, `watchOS`, `visionOS`), carrying `continue-on-error: true` during the soak window per [CI-021]/[CI-091]. The Apple-simulator leg exists because `xcodebuild` against a simulator destination exercises the resource-bundle CodeSign phase that `swift build` / `swift test` never run — the step that catches resource bundles that fail iOS codesign. (The trigger: a SwiftPM resource bundle containing a top-level directory named `Resources` — from `.copy("Resources")` — collides with the reserved bundle layout and fails with `bundle format unrecognized, invalid, or unsuitable` on the simulator, invisible to the macOS/Linux/Windows `swift test` legs. Origin: swift-iso/swift-iso-639#3; fixed by renaming the copied dir, e.g. `.copy("Data")`.) Promote to gating (drop `continue-on-error`, add to `ci-ok` `needs:`) once the legs are green ecosystem-wide.

**Enforcement**: Mechanical — `validate-ci-matrix.py` + `validate-ci-matrix.yml` (pilot 10 of `/promote-rule` 2026-05-14, extended at pilot 20 with [CI-099] windows-release gating-posture check compose-in-script; extended 2026-06-08 with the `apple-simulator-build` presence + advisory-posture + uniform-platform-matrix checks). Centralized-config integrity check (single canonical file: `swift-institute/.github/.github/workflows/swift-ci.yml`). Discipline: `Audits/PROMOTE-CI-010-2026-05-14.md`; pilot-20 outcome `Audits/PROMOTE-CI-099-2026-05-14.md`. [VERIFICATION: WF validate-ci-matrix.py (CI-010, CI-099)]


**Cross-references**: [CI-011], [CI-012], [CI-013], [CI-091], [CI-099].

---

### [CI-011] Toolchain Pins

**Statement**: CI workflows pin to exactly Swift 6.3 stable + Swift main nightly (currently 6.5-dev; floats as main moves through dev versions).

**Enforcement**: Architectural — canonical reusable hardcodes pins (`swift-ci.yml` default 6.3 + hardcoded nightly); [CI-031] forbids consumer override (`validate-thin-callers.py`); branch protection on `swift-institute/.github`. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-011]. [VERIFICATION: ARCH]

**Cross-references**: [CI-010], [CI-012], [CI-031]; memory `feedback_toolchain_versions.md`.

---

### [CI-012] Linux Runs in Docker Containers

**Statement**: Linux jobs run in `swift:6.3` stable + `swiftlang/swift:nightly-main-jammy` nightly containers; bare-runner installation forbidden.

**Enforcement**: Architectural — canonical reusable hardcodes `container:` (`swift-ci.yml` parameterized via `inputs.swift-version` default 6.3; hardcoded nightly); [CI-031] forbids consumer override; branch protection. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-012]. [VERIFICATION: ARCH]

**Cross-references**: [CI-010], [CI-011], [CI-031]; **swift-package-build** [PKG-BUILD-*].

---

### [CI-013] macOS and Windows Runner Specifics

**Statement**: macOS uses `runs-on: macos-26` + Xcode 26.6; Windows uses `runs-on: windows-latest` + `SwiftyLab/setup-swift` (SHA-pinned per [CI-107]). The Xcode pin is floor-coupled: its bundled Swift MUST be ≥ the fleet's `swift-tools-version` floor, or every macOS/simulator leg fails at manifest load ("package is using Swift tools version X but the installed version is Y") — verify the coupling per [CI-113] before any fleet toolchain bump.

**Enforcement**: Architectural — canonical reusable hardcodes runner + action (`swift-ci.yml` `macos-runner` default `macos-26`; `XCODE_VERSION` workflow-env `26.6`, bumped from 26.4 at the 2026-07-10 tools-6.3.3 fleet normalization, `.github` `c540822`; Windows `SwiftyLab/setup-swift`, SHA-pinned per [CI-107]); [CI-031] forbids consumer override; branch protection. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-013]. [VERIFICATION: ARCH]

**Cross-references**: [CI-010], [CI-031]; [CI-107], [CI-113].

---

### [CI-091] Uniform-Platform-Matrix Doctrine

**Statement**: The CI matrix per [CI-010] is the **canonical platform contract** for the ecosystem. Every package MUST conform to the matrix; the matrix is NEVER derived from per-package `Package.swift`'s `platforms:` declaration. If a package cannot build for a matrix entry, the package is wrong — not the matrix. **Exception (2026-07-14, [CI-114])**: a package whose *specification or identity* excludes a platform (a POSIX spec package, a per-platform root) is NOT wrong for failing that platform's leg — forcing conformance there manufactures the violation [CI-114] forbids. Such packages declare the exclusion via the CI-level `platform-support` input; for every other package this doctrine holds unchanged. **Amendment (R1/R2 principal ruling 2026-07-20, [CI-115])**: this doctrine governs the contract's SHAPE (which platforms count), not its per-push SCHEDULING. Full-contract execution runs at release boundaries (tag refs), on the nightly `ci-sweep` rotation, and on demand; ordinary pushes run a tier per [CI-115]. Collapsing the shape (dropping a platform, sampling the simulator matrix) remains rejected.

**What this rule rejects**:

- **Matrix-derivation arguments** — "the matrix should be auto-generated from each package's `Package.swift` `platforms:` block" — REJECTED. Per-package opt-out via `platforms:` is a deployment-target declaration for SwiftPM resolvers, NOT a CI-coverage signal.
- **Matrix-collapse arguments** — "platform X has no consumers, drop the matrix entry to save cycles" — REJECTED. Cost is not an axis (per [CI-096]); coverage is the spec, not the cost center.
- **Per-package matrix overrides** — "this package targets only Linux, skip the macOS leg" — REJECTED when argued from preference, cost, or convenience. The matrix shape is hard-coded ecosystem-wide per [CI-010]; per-package divergence is forking, not parameterization. The sole carve-out is the platform-identity declaration per [CI-114] — an explicit, diff-reviewed `platform-support` declaration available ONLY to packages whose specification or identity excludes the platform.

**What this rule accepts**:

- **Matrix evolution at the universal-reusable layer** — adding/removing/upgrading toolchain pins or runner images in `swift-institute/.github/.github/workflows/swift-ci.yml` per [CI-010]–[CI-013] is a single ecosystem-wide commit. Per-package rollout to follow.
- **Layer-specific verifications via wrappers** — per [CI-003], layer wrappers MAY add jobs (e.g., the L1 `embedded` job). That extends the matrix for one layer; it doesn't *derive* the matrix from any package.
- **Advisory `continue-on-error` legs** during a matrix transition — e.g., `linux-nightly` per [CI-021] and the `embedded-wasm-sdk` / `android-build` / `static-linux-musl-build` / `apple-simulator-build` advisories. These remain matrix entries (the doctrine holds); they're temporarily non-gating per documented soak protocols.
- **Platform-identity declarations per [CI-114]** (amendment 2026-07-14) — a package whose specification or identity excludes a platform declares `platform-support` in its thin caller and the excluded legs skip. This is NOT matrix derivation (nothing is read from `Package.swift`), NOT cost-based collapse ([CI-096] unchanged), and default-inert (a non-declaring package gets the full matrix). Provenance: principal ruling 2026-07-14, `Workspace/handoffs/DECISIONS-pass2/ci-health.md` §7f.

**Worked example (M4 REJECT, 2026-05-06)**: reviewer feedback proposed collapsing `apple-simulator-build` (per-platform matrix: iOS / tvOS / watchOS / visionOS Simulators) to a single representative platform "to save cycles." Rejected because (a) cost is not an axis (public-only repos = unlimited free runner minutes per [CI-096]); (b) the matrix IS the platform contract — collapsing to one platform abandons coverage of the others; (c) any package that fails on, e.g., visionOS would be "the package is wrong" per this rule, not "the matrix is too wide."

**Why doctrine, not just rule**: this is a decision-axis principle that applies whenever any matrix-shaped contract is challenged. Codifying as a typed rule prevents the same arbitration cost on every future cohort that touches platform matrices.


**Cross-references**: [CI-010] (the matrix shape itself), [CI-002] (universal reusable owns the matrix), [CI-003] (layer wrappers extend, don't derive), [CI-021] (advisory continue-on-error during transitions), [CI-096] (companion doctrine — cost is not an axis), [CI-114] (platform-identity carve-out, amendment 2026-07-14). Source authority: `swift-institute/Research/Reflections/2026-05-06-ci-reviewer-feedback-rollout-permissions-pitfall-and-doctrines.md` § Two doctrines codified mid-session.

---

### [CI-114] Platform-Identity CI Declaration

**Statement**: A platform-specific package MUST NOT be CI-gated on a platform it does not target. The platform seam lives at the designated L3 boundary per **platform** [PLAT-ARCH-001] — never inside an L2 specification package — and emulating a platform inside a package to satisfy a CI leg is FORBIDDEN. A package whose *specification or identity* excludes a platform (POSIX spec packages — ISO/IEC 9945 and IEEE Std 1003.1 ARE POSIX and Windows is not a POSIX system; per-platform roots per [PLAT-ARCH-004] such as swift-linux / swift-darwin / swift-windows and their `-standard` L2 counterparts) declares the exclusion via the universal reusable's `platform-support` input in its thin caller's `with:` block (comma-separated subset of `apple,linux,windows`, e.g. `platform-support: apple,linux`); the declared-out platform legs skip.

**Scope discipline** (what this rule does NOT open):

- **NOT a cost knob** — [CI-096] unchanged; cost is not an axis. A declaration is justified by platform identity ONLY, never by "no consumers on X" or "save cycles."
- **NOT matrix derivation** — [CI-091]'s rejection of deriving the matrix from `Package.swift` `platforms:` stands. The declaration is an explicit CI-level statement in the thin caller, diff-visible and reviewed like any workflow change.
- **Default-inert** — a package that declares nothing gets the full matrix; [CI-091] holds unchanged for every non-declaring package.
- **Quality gates unaffected** — format / lint / swift-linter / advisory linters are platform-neutral and never consult the declaration.
- **Dispatch unaffected** — ci-dispatch.yml passes no declaration, so single-job dispatch can still force any leg on any package (debug surface preserved).

**Why (the manufactured-violation mechanism)**: a platform-blind matrix does not merely produce noise on platform-identity packages — it MANUFACTURES architectural violations. The only way a POSIX specification package can green a Windows leg is to emulate POSIX inside the POSIX specification (swift-iso-9945 `06fc4b2`: `os(Windows)` CRT import branches, `_close`, 9 hand-mapped errno values — reverted the same day). The emulation corrupts the exact surface the leg claims to verify — and did not even green the leg (the `06fc4b2` run's Windows leg still failed). The honest platform-mismatch mechanism at source level is the `#if !os(X)` gate on the genuinely platform-less symbol (the `06fc4b2` EDQUOT/getpgrp gates were kept); the honest CI-level mechanism is this declaration.

**Evidence**: proven on a real run 2026-07-14 — swift-iso/swift-iso-9945 run 29320018487 (`4f7754f`): `windows-release` **skipped** via the declaration; every other leg enumerated identically vs the pre-mechanism baseline run 29315907291 (`06fc4b2`).

**Enforcement**: Architectural — the universal reusable's six platform-leg `if:` guards consult `inputs.platform-support` (`swift-institute/.github/.github/workflows/swift-ci.yml`, threaded through all three layer wrappers; empty default reproduces the pre-input matrix bit-identically). Declaration legitimacy review is human (the `with:` block is diff-visible in the thin caller). Mechanical enforcement (validate that declarations appear only on identity-qualified packages) is a `/promote-rule` candidate.


**Cross-references**: [CI-091] (amended with this carve-out), [CI-099] (windows-release stays gating for every package that targets Windows), [CI-010], [CI-096], [CI-031]; **platform** [PLAT-ARCH-001], [PLAT-ARCH-004].

---

### [CI-115] Tiered Verification Scheduling

**Statement** (R1/R2 principal ruling 2026-07-20): the universal `swift-ci.yml` selects a verification TIER per run via its `plan` job; the matrix SHAPE ([CI-010]/[CI-091]) is unchanged — every leg stays defined in the universal, and the `full` tier runs all of them.

- **lint** — `format` + `lint` + `swift-linter` (Linux-only; ~90–120s wall-clock). Selected by the `[ci lint]` commit token or automatically when the pushed range touches only docs/metadata/lint-config classes (`*.md`, `LICENSE*`, `CITATION*`, `.gitignore`, `.spi.yml`, `Lint.swift`, `Lint/*`, `.swiftlint.yml`, `.swift-format`, `*.docc/*` — deliberately NOT `.github/*`: a caller-workflow edit changes CI behavior and rides the build tier, 2026-07-20).
- **build** — lint tier + `linux-release`. The DEFAULT for ordinary pushes and PRs; any classification obstacle (force-push zeros, unfetchable before-SHA) fails safe to build.
- **full** — the complete platform contract including the advisory legs. Unconditional on tag refs; forced by `[ci full]`, consumer `workflow_dispatch`, and `ci-sweep.yml` (`tier: full`).

Selection mechanics: the `plan` job classifies (forced `tier` input > tag ref > commit token > dispatch > diff classification > build default), emits a `legs` CSV output, and every leg's `if:` guard composes `!cancelled()` + the job-selector disjunct + a `contains()` check on `legs` (same guard family as `platform-support`). `plan` sits in `ci-ok`'s `needs:` so a plan failure (identity conflict, classifier error) fails the run even though every leg skips; tier-skipped legs pass via the pre-existing skipped-as-passing semantics. **`ci-ok` therefore attests "the SELECTED tier passed"; the full-contract attestation lives at tag refs and the nightly sweep.** Single-job dispatch bypasses the plan (`inputs.job != ''` → plan skips; the leg's job-selector disjunct fires), preserving ci-dispatch's exactly-one-job property.

**Scheduled sweep**: `ci-sweep.yml` (swift-institute/.github; nightly 02:11 UTC) partitions the public fleet into `slices` buckets (default 7) by stable name-hash and runs `tier: full` on tonight's bucket via a matrix `uses:` of the universal — every repo gets full-contract verification at least weekly, under swift-institute's own runner quota (never competing with consumer-push queues). Failures aggregate into a rolling tracking issue on swift-institute/.github. Canary/manual: `gh workflow run ci-sweep.yml -f repos="owner/name"`.

**Rationale** (measured 2026-07-20, `Research/ci-tiered-verification.md`): free-tier runner CONCURRENCY — not minutes — is the binding budget. A free-plan org has 5 concurrent macOS runners; the pre-tier matrix scheduled 5 macOS jobs per push (4 advisory), so one push saturated an org's macOS pool and queue tails reached 7–12.5 hours while median leg compute was 36–144s. 57% of sampled runs were red/cancelled (red-baseline re-verification). [CI-096]'s "cost is not an axis" holds for MINUTES; it never licensed ignoring concurrency, which is a SPEED-axis constraint.

**Campaign token policy** (compliance-push discipline, 2026-07-20): do NOT put `[ci lint]` on pushes whose diff touches `Sources/`/`Tests/` — a mechanical lint fix that does not compile is exactly what the default build tier exists to catch, on the uncontended Linux pool, in a few minutes. Reserve `[ci lint]` for pushes that cannot break compilation (docs, metadata, `Lint.swift`/lint-config tuning); those classes auto-select lint anyway, so the token is normally redundant. The plan job reads the token from the HEAD commit of the push only.

**What this does NOT change**: matrix shape and toolchain pins ([CI-010]–[CI-013]); the [CI-091] shape doctrine and [CI-114] carve-out; [CI-099]'s Windows gating posture (Windows gates whenever it runs — full tier and tags); quality gates run in EVERY tier.

**Cross-references**: [CI-010], [CI-091] (amended), [CI-096] (amended), [CI-114] (guard-mechanism precedent), [CI-104] (sweep canary discipline), [CI-108] (centralize-on-schedule). Implementation: `swift-institute/.github/.github/workflows/swift-ci.yml` (`plan` job), `ci-sweep.yml`. Source authority: `swift-institute/Research/ci-tiered-verification.md` (R1/R2 ruling record + measurements).

---

### [CI-092] swift:6.3 Container Image Is Minimal

**Statement**: The official `swift:6.3` Docker image (and likely all `swift:N` images per [CI-012]) is built on `ubuntu:jammy` carrying ONLY the Swift toolchain and bare dependencies. It does NOT ship `curl`, `python3`, or the GitHub CLI (`gh`). The default shell for `run:` blocks inside a container is `sh -e` (POSIX dash), NOT bash — which rejects `set -o pipefail` as `Illegal option -o pipefail` (exit code 2). Workflow authors MUST account for both gaps.

**Why**: discovered 2026-05-05 across three sequential CI failures during Phase β rollout — shell rejection (fix `4756b74`), curl missing (fix `2c1b429`), python3 missing (fix `bd52c33`). Spec authoring assumed jammy defaults; actual base image is more minimal. Failing to handle these gaps surfaces as opaque shell errors or "command not found" — symptoms that look like a workflow logic bug but are actually image-shape bugs.

**How to apply**:

- **Preferred for multi-step bash-idiom jobs**: declare **job-level `defaults: run: shell: bash`** on any `container:` job whose `steps:` contain MULTIPLE bash-idiom `run:` blocks. Job-level defaults apply to ALL `run:` blocks in the job and cannot be missed by accident when adding a new step. Per-step `shell: bash` is fragile precisely because the failure mode is sentinel-then-cascade: the FIRST bash-idiom step fails at `Illegal option -o pipefail`, masking downstream bash-idiom steps from canary visibility; after fixing the first per-step, the next bash-idiom step fails identically. Discovered 2026-05-15 during Phase D-2.2 → D-2.3 cascade (canary surfaced step A; targeted per-step fix masked step B; job-level defaults closed both at once).
- For single-step bash-idiom jobs OR mixed bash + sh jobs: declare per-step `shell: bash` on every container `run:` step that uses bash idioms (`set -euo pipefail`, `mapfile`, `[[ ]]`, `<<<`, `<( ... )`). Without the explicit declaration, the step runs under `sh -e` and rejects the bash-only constructs.
- Container `run:` steps that need `curl`, `python3`, or `gh` MUST `apt-get update -qq && apt-get install -qq -y <tools>` first. This mirrors the existing pattern in `swift-ci.yml`'s SwiftLint install step.
- `gh` CLI is NOT installable via plain `apt-get install gh` — it requires the official PPA: `curl` + GPG keyring import + apt source line + install. When a cron orchestrator's sweep step needs `gh`, factor the installation into a setup step.
- For pure-Python work that does NOT need `swift package dump-package` or any Swift toolchain operation, prefer `runs-on: ubuntu-latest` no-container over `swift:6.3` container. ubuntu-latest ships `curl`, `python3`, and `gh` pre-installed; saves ~3–5 min per run on container pull + apt install.


**Cross-references**: [CI-012] (Linux container choice); **swift-package-build** [PKG-BUILD-*] for the operational expectations these containers must satisfy.

---

## L1 Invariants Encoded in CI

### [CI-020] Embedded Buildability Is an L1 Invariant

**Statement**: Every L1 primitives package must build under `-enable-experimental-feature Embedded` against Swift main nightly.

**Enforcement**: Architectural — `embedded` job in `swift-primitives/.github/.github/workflows/swift-ci.yml` (L1 layer wrapper); every L1 consumer routes through this wrapper via [CI-001]; wrapper-file presence enforced by `lint-org-bot-coverage.yml` axis 3 per [CI-004]. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-020]. [VERIFICATION: ARCH]

**Cross-references**: [CI-021], [CI-003], [CI-004]; **primitives** [PRIM-FOUND-001]; **swift-package-build** [PKG-BUILD-007], [PKG-BUILD-008].

---

### [CI-021] Embedded Job Continue-On-Error During Main-Nightly Window

**Statement**: When any layer-wrapper `swift-ci.yml` declares a job named `embedded`, that job MUST carry `continue-on-error: true` while Swift main is the active development branch (currently 6.5-dev; floats as main moves). Sunsets via skill amendment when the embedded gate moves to a stable-toolchain pin.

**Enforcement**: Mechanical — `validate-embedded-job.py` + `validate-embedded-job.yml` (pilot 23 of `/promote-rule` 2026-05-14). Centralized-config integrity check on `<repo_root>/.github/workflows/swift-ci.yml`; PyYAML inspects `jobs.embedded.continue-on-error` and fires if not literally `True`. Silent when no embedded job exists. Currently the only target is `swift-primitives/.github` (L1 wrapper). Baseline 0; self-firing ACTIVE. Discipline: `Audits/PROMOTE-CI-021-2026-05-14.md`. [VERIFICATION: WF validate-embedded-job.py]

**Cross-references**: [CI-020]; linux-nightly precedent in `swift-institute/.github/.github/workflows/swift-ci.yml`.

---

### [CI-022] Foundation Forbidden in Main Targets

**Statement**: Main targets in primitives/standards/foundations packages MUST NOT import Foundation; interop is opt-in via a `* Foundation Integration` subtarget.

**Enforcement**: Mechanical — SwiftLint custom rule pair `no_foundation_import_*` at `swift-primitives/.github/.swiftlint.yml` (Tier 2 ruleset; migrated 2026-05-05 from the advisory `lint-foundation-family-import` workflow). Fires on every PR via the universal `lint` job. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-022]. [VERIFICATION: SwiftLint no_foundation_import_*]

**Cross-references**: [CI-020]; **primitives** [PRIM-FOUND-001]; **readme/ci-automation** [README-167].

---

## Windows Gating Posture

### [CI-099] Windows-Release Job Gating Posture

**Statement**: The `windows-release` job in the canonical `swift-ci.yml` MUST stay gating; `continue-on-error: true` is forbidden — Windows is a first-class target platform whose visibility outweighs upstream-driven noise. A platform-identity declaration per [CI-114] skips the leg entirely for a package that does not target Windows; it never weakens the leg's gating posture — for every package that targets Windows the leg runs and gates exactly as before.

**Enforcement**: Mechanical — `validate-ci-matrix.py` + `validate-ci-matrix.yml` (pilot 20 of `/promote-rule` 2026-05-14, compose-in-script with [CI-010]). Centralized-config integrity check (single canonical file: `swift-institute/.github/.github/workflows/swift-ci.yml`); PyYAML inspection of `jobs.windows-release.continue-on-error` — fires if `is True`. Inverse-of-[CI-010] posture check: where [CI-010] asserts `linux-nightly` HAS `continue-on-error: true` (toolchain-noise scope), this rule asserts `windows-release` does NOT (target-shipped-to scope). Baseline 0; self-firing ACTIVE (inherits pilot 10's workflow triggers). Discipline: `Audits/PROMOTE-CI-099-2026-05-14.md`. [VERIFICATION: WF validate-ci-matrix.py]

**Cross-references**: [CI-010], [CI-096], [CI-105], [CI-114]; memory `feedback_windows_first_class_ci_gating.md`.

---

