---
name: ci-cd-workflows
description: |
  CI/CD architecture: three-tier reusable chain, universal matrix, no-cache policy, mass-rollout discipline.
  Apply when designing/modifying workflows, planning mass changes, or auditing against ecosystem invariants.

layer: process

requires:
  - swift-institute-core

applies_to:
  - swift-institute
  - swift-primitives
  - swift-standards
  - swift-foundations
# Amendment/changelog history: Research/ci-cd-workflows-skill-rationale.md §Changelog-Provenance (and git history of this file).
---

# CI/CD Workflows

Architecture, invariants, and rollout discipline for Swift Institute CI/CD across the layered package ecosystem. The workflows themselves live in `swift-institute/.github/.github/workflows/` (universal reusables) and `<layer>/.github/.github/workflows/` (layer wrappers); consumer repos carry thin caller `ci.yml` files.

This skill is organized as a navigation hub. The three-tier framing below governs the whole skill and is always in context; detailed rule bodies live in the sibling files listed under **Files**. Claude loads the relevant companion on demand when a topic is active.

**Source authority**: `swift-institute/Research/ci-centralization-strategy.md` (Tier 2 RECOMMENDATION, 2026-04-22) established the centralization architecture; `swift-institute/Research/ci-cache-strategy-branch-pinned-dependencies.md` (v1.1.0, 2026-05-04) established the no-cache policy. Mass-rollout discipline is grounded in this skill's own provenance section. Extended rationale, evicted provenance, and worked examples: `swift-institute/Research/ci-cd-workflows-skill-rationale.md`.

---

## The Three-Tier Chain

CI/CD is organized as a three-tier reusable-workflow chain per [CI-001]. This topology is load-bearing for every rule below — each rule answers "which tier owns this, and how does it flow to the others?"

| Tier | Lives in | Carries | Anchoring rules |
|------|----------|---------|-----------------|
| 1 — Consumer thin caller | `<pkg>/.github/workflows/ci.yml` | name + `on:` + `concurrency:` + thin `uses:` jobs with `secrets: inherit` | [CI-031], [CI-030], [CI-059] |
| 2 — Layer wrapper | `<layer>/.github/.github/workflows/swift-ci.yml` (+ `swift-docs.yml`) | layer-specific verifications; secret transport across org boundaries | [CI-004], [CI-004a], [CI-003] |
| 3 — Universal reusable | `swift-institute/.github/.github/workflows/swift-ci.yml` | the universal build/test matrix + ecosystem-wide format/lint gates | [CI-002], [CI-010], [CI-054] |

Three cross-cutting axioms frame the rest: the matrix is the platform contract, never derived from any package ([CI-091]) — its SHAPE is sacred, while its per-push SCHEDULING is tiered per [CI-115] (lint/build per push; full contract at tag refs and the nightly `ci-sweep` rotation); CI on this Free-plan workspace fires only on public repos, so **correctness > security > speed** and dollar/minute cost is not an axis ([CI-096], [CI-032], [CI-060]); and runner CONCURRENCY (5 macOS / 20 total per free-plan org) IS a real speed-axis budget — the [CI-096] amendment 2026-07-20 — which is why full-matrix breadth is scheduled, not per-push.

---

## Files

| Topic | File | Rules |
|-------|------|-------|
| Architecture & Reusable Consumption | `architecture.md` | [CI-001]–[CI-004b], [CI-030], [CI-031], [CI-053], [CI-054], [CI-093], [CI-108] |
| Universal Matrix, Toolchain & L1 Invariants | `matrix.md` | [CI-010]–[CI-013], [CI-091], [CI-114], [CI-115], [CI-092], [CI-020]–[CI-022], [CI-099] |
| Secrets, Tokens, Visibility & Private-Repo Gates | `secrets-tokens.md` | [CI-032], [CI-058], [CI-059], [CI-060], [CI-109], [CI-094], [CI-095], [CI-112] |
| Security Hardening, Permissions & Version Pins | `security-hardening.md` | [CI-080], [CI-081], [CI-082], [CI-090], [CI-097], [CI-096], [CI-098], [CI-107] |
| Caching Policy & Per-Package Configuration | `caching.md` | [CI-040]–[CI-044], [CI-116], [CI-055], [CI-057] |
| Mass-Rollout Discipline | `mass-rollout.md` | [CI-050], [CI-051], [CI-052], [CI-056], [CI-111], [CI-113] |
| Workflow-Authoring Gotchas & Parse-Time Failure Classes | `workflow-authoring.md` | [CI-070], [CI-102], [CI-103], [CI-105], [CI-106], [CI-110], [CI-104], [CI-100], [CI-101] |

---

## Rule Index

One-line hooks for every rule. Load the linked file when the topic is active.

### Architecture & Reusable Consumption (`architecture.md`)

| ID | Hook |
|----|------|
| [CI-001] | Three-tier chain — per-package thin caller → layer wrapper → universal reusable |
| [CI-002] | Universal reusable owns the matrix + ecosystem-wide format/lint gates; no layer-specific jobs |
| [CI-003] | Layer-specific verifications live in layer wrappers, not the universal |
| [CI-004] | Each layer org hosts a `swift-ci.yml` wrapper mirroring the org hierarchy |
| [CI-004a] | `swift-docs.yml` layer wrappers are REQUIRED for secret transport; route docs through them |
| [CI-004b] | Sub-org `.github` repos MUST NOT host `swift-ci.yml` (4-level chain limit); future work |
| [CI-030] | Caller `uses:` refs pin `@main` during active dev; tag/SHA pins forbidden until `@v1` |
| [CI-031] | Per-package `ci.yml` is the absolute minimum — name + `on:` + `concurrency:` + thin `uses:` jobs |
| [CI-053] | `swift-docs.yml` derives umbrella/display/bundle/catalog from repo name; overrides accepted |
| [CI-054] | `format`/`lint` absorbed as parallel jobs in the universal; per-repo workflow files forbidden |
| [CI-093] | Local format/lint tooling resolves to a `Scripts/<tool>` wrapper on the CI toolchain; no `$PATH` |
| [CI-108] | A workflow needs a per-repo file only if its trigger/output ties to that repo's diff/branch |

### Universal Matrix, Toolchain & L1 Invariants (`matrix.md`)

| ID | Hook |
|----|------|
| [CI-010] | Universal matrix shape — 4 gating jobs + advisory apple-simulator leg |
| [CI-011] | Toolchain pins — Swift 6.3 stable + Swift main nightly |
| [CI-012] | Linux runs in `swift:6.3` / nightly Docker containers; bare-runner install forbidden |
| [CI-013] | macOS `macos-26` + Xcode 26.4; Windows `windows-latest` + SwiftyLab/setup-swift (SHA-pinned) |
| [CI-091] | Uniform-platform-matrix doctrine — the matrix is the platform contract, never derived from `platforms:` (platform-identity carve-out: [CI-114]) |
| [CI-114] | Platform-identity CI declaration — never CI-gate a package on a platform its identity excludes; `platform-support` input; platform emulation to green a leg forbidden |
| [CI-115] | Tiered verification scheduling — plan job selects lint/build/full per push; full contract at tags + nightly ci-sweep rotation; ci-ok attests the selected tier |
| [CI-092] | `swift:6.3` image is minimal — no curl/python3/gh; default shell is `sh -e`, not bash |
| [CI-020] | Embedded buildability is an L1 invariant — every L1 package builds under `-enable…Embedded` |
| [CI-021] | `embedded` job carries `continue-on-error: true` during the main-nightly window |
| [CI-022] | Foundation forbidden in main targets; interop via a `* Foundation Integration` subtarget |
| [CI-099] | `windows-release` stays gating; `continue-on-error: true` forbidden — Windows is first-class |

### Secrets, Tokens, Visibility & Private-Repo Gates (`secrets-tokens.md`)

| ID | Hook |
|----|------|
| [CI-032] | Every job in every intra-Institute reusable carries the `!repository.private` visibility gate |
| [CI-058] | `enable-private-repos` input defaults `true`; consumers opt OUT |
| [CI-059] | Per-repo `uses:` of intra-Institute reusables include `secrets: inherit` (sub-org caveat: explicit-forward) |
| [CI-060] | `PRIVATE_REPO_TOKEN` is org-level `--visibility all`; per-repo redundant; free-plan alignment |
| [CI-109] | Cross-org secret transport — `secrets: inherit` is same-org-only; explicit-forward at org boundaries |
| [CI-094] | Private-repo pre-publication CI gates satisfied via local clean-build, not Actions (free-plan) |
| [CI-095] | Rule-activation surface (public pkgs) vs bookkeeping surface (all pkgs); private = inert diagnostic |
| [CI-112] | "Resolves from scratch" gates require an actual mirror-bypassed clean-room resolve, no substitutes |

### Security Hardening, Permissions & Version Pins (`security-hardening.md`)

| ID | Hook |
|----|------|
| [CI-080] | harden-runner as first step, SHA-pinned, `egress-policy: audit` floor; block-mode after soak |
| [CI-081] | No caller-supplied shell in token-holding reusables; structured inputs only |
| [CI-082] | Binary-install checksum verification via `sha256sum -c`; re-lock digest on version bump |
| [CI-090] | Permissions shape per trigger — reusables OMIT top-level; standalone DECLARE a floor |
| [CI-097] | `workflow_call` reusable MUST NOT declare `permissions: {}` (deny-all → startup_failure) |
| [CI-096] | CI prioritization axes — correctness > security > speed; cost is not an axis |
| [CI-098] | Admin-class GitHub ops via web UI; no admin-scope `gh` CLI tokens |
| [CI-107] | Latest-version pin discipline — pins carry current latest on every touch; digest-pin for privileged refs |

### Caching Policy & Per-Package Configuration (`caching.md`)

| ID | Hook |
|----|------|
| [CI-040] | No `.build/` cache (single L1-embedded carve-out, exact-match, no restore-keys) |
| [CI-041] | `Package.resolved` gitignored ecosystem-wide — permanent library convention |
| [CI-042] | No `restore-keys` partial-prefix matching on any `actions/cache` step |
| [CI-043] | `.gitignore` is centrally managed by `sync-gitignore.sh`; per-repo edits don't persist |
| [CI-044] | Tool-binary cache permitted with exact-match-only key on the version env var |
| [CI-116] | Main-tracking linter binaries ship via the rolling `ci-binaries` release (built once, checksum-verified download), never per-repo cache bakes |
| [CI-055] | DEPRECATED 2026-05-14 — `UseShorthandTypeNames: false` ecosystem-mandatory (dismissed) |
| [CI-057] | `.swift-format`/`.swiftlint.yml` are per-package; ecosystem uniformity is not a goal |

### Mass-Rollout Discipline (`mass-rollout.md`)

| ID | Hook |
|----|------|
| [CI-050] | Mass changes across ≥3 repos require per-action authorization; a plan is a roadmap, not a blanket YES |
| [CI-051] | Surgical commits, dirty-skip discipline — one logical change per commit; skip dirty repos |
| [CI-052] | Visibility flips / tag ops require explicit "YES DO NOW PUBLIC" / "YES DO NOW TAG" |
| [CI-056] | Per-package coordinator build verify between a source-modifying transform and push |
| [CI-111] | Mass rewrite scripts preserve pre-existing transformed forms + require sample diff-inspection |
| [CI-113] | Toolchain-floor bumps verify every CI execution surface first — workflow updates land before the mass push, one-repo canary before the fleet |

### Workflow-Authoring Gotchas & Parse-Time Failure Classes (`workflow-authoring.md`)

| ID | Hook |
|----|------|
| [CI-070] | Composite-action call-site eligibility — no in-loop calls; cross-repo `@main` refs are the standard |
| [CI-102] | Composite-action `description` fields MUST NOT contain `${{ }}` (parse-time HTTP 422) |
| [CI-103] | `env.*` forbidden in `runs-on:`/`container:` (resolved before env binds → HTTP 422) |
| [CI-105] | `continue-on-error` invalid alongside `uses:` at job level (startup_failure); use `advisory:` input |
| [CI-106] | `workflow_call` permissions chain — every level grants equal-or-greater or the chain collapses at parse |
| [CI-110] | Mixed-trigger workflows null-coerce typed-boolean input forwarding (`== true`) or startup_failure |
| [CI-104] | Scheduled-workflow canary — exercise `schedule:`-only workflows via explicit `gh workflow run` |
| [CI-100] | SwiftLint `toggle_bool` rule excluded from the canonical config (prefer `x = !x`) |
| [CI-101] | No regex-evasion of custom lint rules; escalate + `// swiftlint:disable:next` with reason instead |

---

## Cross-References

- **github-repository** ([GH-REPO-*]) — per-repository GitHub metadata; the `sync-metadata.yml` reusable workflow family is an analogous metadata-propagation pattern. [GH-REPO-070]–[GH-REPO-072] describe the metadata-workflow architecture.
- **readme/ci-automation** ([README-160]–[README-167]) — README-related CI workflows (presence sweeps, structure linters, badge validators, inventory generation). Different workflow class from this skill's build/test/lint family; both follow [README-167]'s tracking-issue reporting shape.
- **swift-package-build** ([PKG-BUILD-*]) — operational build instructions (TOOLCHAINS env var, Linux Docker, Embedded source-guard pattern). The CI containers in [CI-012] and the embedded job in [CI-020] exercise these operations.
- **primitives** [PRIM-FOUND-001] — the Foundation-free invariant manifested in CI as [CI-022].
- **swift-institute** [ARCH-LAYER-*] — five-layer architecture; layer wrappers in [CI-001] correspond to L1–L4 layers.

### Source authority (research)

- `swift-institute/Research/ci-centralization-strategy.md` (Tier 2 RECOMMENDATION, 2026-04-22, v1.1.0) — established Option A (reusable workflows) + Option D (sync-script) hybrid; permission scoping (Path B); ref-strategy recommendation (`@v1` post-stabilization).
- `swift-institute/Research/ci-cache-strategy-branch-pinned-dependencies.md` (Tier 2 RECOMMENDATION, 2026-05-04, v1.1.0) — established no-`.build/`-cache policy permanent under the gitignored-`Package.resolved` constraint.
- `swift-institute/Research/gitignore-sync-strategy.md` — sync-script precedent for [CI-043].
