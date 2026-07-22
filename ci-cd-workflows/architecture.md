# CI/CD — Architecture & Reusable Consumption

Companion of the **ci-cd-workflows** skill (navigation hub: `SKILL.md`). Load when designing or modifying the three-tier reusable-workflow topology, layer wrappers, per-package thin callers, DocC routing, the local toolchain wrapper, or deciding whether a workflow needs a per-repo file. This file reads independently: it collects the structural rules that answer "how is CI organized across the layered ecosystem?"

**Rules in this file**: [CI-001], [CI-002], [CI-003], [CI-004], [CI-004a], [CI-004b], [CI-030], [CI-031], [CI-053], [CI-054], [CI-093], [CI-108]

---

## Three-Tier Chain & Layer Wrappers

### [CI-001] Three-Tier Workflow Chain

**Statement**: CI/CD is organized in three tiers — per-package consumer thin caller, layer wrapper, universal reusable.

**Enforcement**: Mechanical — Tier 3 via `validate-thin-callers.py` ([GH-REPO-074], pilot 7); Tier 2 wrapper-file presence via `lint-org-bot-coverage.yml` axis 3; Tier 1 is single-target structural (canonical `swift-institute/.github/.github/workflows/swift-ci.yml` under branch protection). Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-001]. [VERIFICATION: WF validate-thin-callers.py + WF lint-org-bot-coverage.yml axis 3]

**Cross-references**: [CI-002], [CI-003], [CI-004]; `swift-institute/Research/ci-centralization-strategy.md`.

---

### [CI-002] Universal Reusable Owns Matrix + Ecosystem-Wide Quality Gates

**Statement**: The universal reusable at `swift-institute/.github/.github/workflows/swift-ci.yml` MUST own the universal build/test matrix AND ecosystem-wide quality gates that apply uniformly across every consumer (currently: `format` and `lint` gating jobs per [CI-054]). It MUST NOT carry layer-specific jobs (embedded build, layer-specific verifications) or layer-specific opt-in flags.

**Forbidden in the universal reusable**:
- Embedded-build jobs (those belong in the swift-primitives layer wrapper per [CI-020])
- Foundation-integration jobs (per-package, not universal)
- Inputs of the form `enable-<layer>-check: bool`

**Permitted in the universal reusable**:
- Build/test matrix per [CI-010]
- Ecosystem-wide quality gates: format ([CI-054] absorbed `swift-format lint`), lint (absorbed SwiftLint). These are platform-independent quality concerns that apply uniformly across every consumer regardless of layer.
- Advisory, non-gating ecosystem-wide linter jobs dispatched from the universal — `swift-linter` (a real `steps:`-bearing job; carries `continue-on-error: true`) plus the nested reusable linters (`lint-yaml`, `broken-symlink`, `license-header`, `test-support-spine`, `api-breakage`, `pr-title`), which are `uses:` reusable-workflow jobs and CANNOT carry `continue-on-error` per [CI-105] — each instead takes an `advisory: bool` input. Same ecosystem-wide quality-gate class as `format`/`lint`, run advisory during their soak windows (excluded from the `ci-ok` aggregator's `needs:`, not from `continue-on-error`). The gating `format`/`lint` pair remain the only quality jobs in the merge-gating set (enumeration added 2026-07-03 per CI-REVIEW dossier F33; advisory mechanics corrected 2026-07-05 per Phase-3 review).

**Rationale**: Layer-specific concepts in the universal reusable contaminate every consumer with toggles they cannot turn off, and bloat the input surface across the ecosystem. Layer wrappers are the correct home for layer-specific verifications because they are the layer's authority over its own invariants. Ecosystem-wide quality gates are different — they apply uniformly regardless of layer and are the universal reusable's natural home: each consumer gets format/lint enforcement automatically without per-package workflow files.


**Cross-references**: [CI-001], [CI-003], [CI-020], [CI-054].

---

### [CI-003] Layer-Specific Verifications Live in Layer Wrappers

**Statement**: Layer-specific verifications (e.g., L1 embedded buildability) live as jobs in the layer's `swift-ci.yml` wrapper, NOT the universal reusable.

**Enforcement**: Architectural — subsumed by [CI-004] (layer-wrapper presence enforced by `lint-org-bot-coverage.yml` axis 3) + [CI-002]'s inverse (universal MUST NOT carry layer-specific jobs). Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-003]. [VERIFICATION: ARCH]

**Cross-references**: [CI-001], [CI-002], [CI-020].

---

### [CI-004] Layer Wrappers Mirror Layer Orgs

**Statement**: Each layer org (swift-primitives, swift-standards, swift-foundations) hosts a `swift-ci.yml` wrapper as a structural anchor mirroring the org hierarchy.

**Enforcement**: Mechanical — `lint-org-bot-coverage.yml` axis 3 (anonymous-public-API check via `gh api /repos/<org>/.github/contents/.github/workflows/swift-ci.yml`); sub-org repos excluded per [CI-004b]. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-004]. [VERIFICATION: WF lint-org-bot-coverage.yml axis 3]

**Cross-references**: [CI-001], [CI-003], [CI-004a], [CI-004b]; `swift-institute/Research/ci-cd-cross-ecosystem-reuse.md` v1.1.1.

---

### [CI-004a] swift-docs.yml Layer Wrappers Are Required (Secret Transport)

**Statement**: Each layer org hosts a `swift-docs.yml` wrapper, and consumers MUST route their `docs:` job through it — never to the universal `swift-institute/.github/.github/workflows/swift-docs.yml@main` directly. The wrapper exists for SECRET TRANSPORT per [CI-109], not layer-specific docs concerns: the consumer → universal docs hop is cross-org, where `secrets: inherit` delivers no org secrets; the same-org wrapper receives them via inherit and explicit-forwards the private-dep credential set (`PRIVATE_REPO_TOKEN` + `SWIFT_INSTITUTE_BOT_APP_CLIENT_ID` / `_APP_ID` / `_APP_PRIVATE_KEY`) across the boundary. Wrapper shape: pure routing job, [CI-032] visibility gate, full umbrella-input pass-through, explicit `secrets:` block; chain depth 3 of 4.

**v1 history (superseded 2026-06-04)**: v1 ("swift-docs.yml Wrappers Are Not Required") held that layer orgs MAY route DocC consumers directly to the universal absent layer-specific docs concerns. The "no layer-specific docs concerns exist" observation still stands — the accrued concern that flipped the rule is secret transport, surfaced when the 5 MSB private packages entered public dep graphs and the docs path's cross-org inherit delivered no credentials ([CI-109] empirical basis).

**Sub-org consumers are not served via inherit**: their hop into any layer org's wrapper is itself cross-org, where `secrets: inherit` would drop their org secrets identically. They route through their PARENT layer org's wrapper WITH the explicit-forward `secrets:` block per the [CI-059] sub-org caveat — explicit VALUES, resolved in the consumer's own org context, survive the hop (pattern (ii), executed 2026-06-04; validator support swift-institute/.github `d56e36a`).

**When to add layer-specific docs JOBS to the wrapper**: when a layer accrues layer-specific docs concerns (unchanged from v1; none exist today).


**Cross-references**: [CI-004]; [CI-053] (swift-docs.yml umbrella metadata derivation); [CI-109]; [CI-059].

---

### [CI-004b] Sub-Org Wrappers Are Future Work

**Statement**: Per-authority sub-org `.github` repos MUST NOT host `swift-ci.yml` — the `workflow_call` 4-level chain limit would push the universal's advisory-linter sub-dispatches to level 5 (parse failure). Sub-orgs route through their parent layer wrapper. Sunsets when GitHub raises the chain limit OR universal inlines advisory linters.

**Enforcement**: Mechanical — `validate-sub-org-wrappers.py` + `validate-sub-org-wrappers.yml` (pilot 28 of `/promote-rule` 2026-05-14). Negative-existence check per named sub-org `.github` repo; workflow matrix iterates 11 L2 + 2 L3 sub-orgs (`swift-ietf`, `swift-iso`, `swift-w3c`, `swift-whatwg`, `swift-ecma`, `swift-incits`, `swift-ieee`, `swift-iec`, `swift-arm-ltd`, `swift-intel`, `swift-riscv`, `swift-linux-foundation`, `swift-microsoft`). Validator clones each sub-org's `.github` repo via gh App token; fires if `.github/workflows/swift-ci.yml` exists. Test fixtures use `.github-as-sub-org` marker to simulate sub-org context. Baseline 0 ecosystem-wide; self-firing ACTIVE (weekly schedule). Discipline: `Audits/PROMOTE-CI-004b-2026-05-14.md`. [VERIFICATION: WF validate-sub-org-wrappers.py]

**Cross-references**: [CI-004], [CI-001]; `swift-institute/Research/ci-cd-cross-ecosystem-reuse.md` v1.1.1 §Q2; `swift-institute/Research/ci-centralization-strategy.md` (4-level limit citation).

---

## Reusable Consumption Pattern

### [CI-030] Reusable Refs Pin to `@main` During Active Dev

**Statement**: Caller `uses:` references to intra-Institute reusable workflows MUST pin to `@main` during active dev; tag pins (`@v1`, `@v1.0.0`) and SHA pins are forbidden until the surface stabilizes at `@v1`.

**Enforcement**: Mechanical — `validate-thin-callers.py` + `validate-thin-callers.yml` (pilot 17 of `/promote-rule` 2026-05-14, compose-in-script with [GH-REPO-074] and [CI-059]). Intra-Institute path discriminator is the `.github/.github/workflows/` double-infix shape (third-party action refs use a different shape and are exempt per [CI-107]). Baseline 0/240 consumer repos; self-firing DEFERRED — `validate-thin-callers.yml` is `workflow_call`-only (no `push`/`pull_request` trigger), so the caller family is validated via the weekly `lint-validators-weekly` sweep only (manifest `self-firing: deferred`), not per-push (corrected 2026-07-03 per CI-REVIEW dossier F8 — the prior "self-firing ACTIVE" annotation was doc-drift). Discipline: `Audits/PROMOTE-CI-030-CI-059-2026-05-14.md`. [VERIFICATION: WF validate-thin-callers.py]

**Cross-references**: [CI-031], [CI-059], [CI-107]; `swift-institute/Research/ci-centralization-strategy.md`.

---

### [CI-031] Per-Package `ci.yml` Is the Absolute Minimum

**Statement**: Per-package consumer `ci.yml` contains only workflow name + `on:` + `concurrency:` + thin `uses:` jobs with `secrets: inherit` ([CI-059]). No inline build/test logic, caching, matrices, or toolchain overrides.

**Enforcement**: Mechanical — `validate-thin-callers.py` + `validate-thin-callers.yml` (pilot 7 of `/promote-rule` 2026-05-14, extended at pilot 17 with [CI-030] + [CI-059] compose-in-script). [GH-REPO-074] checks (no inline `runs-on:`, no inline `steps:`, ≥1 `uses:` job; standalone `swift-format.yml`/`swiftlint.yml` forbidden) plus [CI-030] @main pinning and [CI-059] `secrets: inherit` co-presence. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-031]; pilot-17 outcome `Audits/PROMOTE-CI-030-CI-059-2026-05-14.md`. [VERIFICATION: WF validate-thin-callers.py (GH-REPO-074, CI-030, CI-059)]

**Cross-references**: [CI-030], [CI-032], [CI-053], [CI-054], [CI-058], [CI-059], [CI-060]; memory `project_per_repo_vs_centralized_ci.md`.

---

### [CI-053] DocC Umbrella Metadata Derivation

**Statement**: `swift-docs.yml` derives umbrella module / display name / bundle id / catalog path from `${{ github.event.repository.name }}` per the `swift-{kebab}-primitives` → `{Title}_Primitives` convention; per-package overrides accepted.

**Enforcement**: Architectural — derivation logic IS in `swift-institute/.github/.github/workflows/swift-docs.yml`; every consumer routes through this reusable per [CI-031]; reviewer discipline via branch protection. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-053]. [VERIFICATION: ARCH]

**Cross-references**: [CI-031], [CI-002].

---

### [CI-054] Format/Lint Absorbed in Universal Reusable

**Statement**: `format` and `lint` run as parallel jobs in `swift-ci.yml`; per-repo `swift-format.yml` / `swiftlint.yml` workflow files are forbidden. Developer contract: run `swift-format format --in-place Sources Tests` locally before pushing — `format:` job runs `lint --strict` with no auto-commit.

**Note (2026-07-03, clarifying per CI-REVIEW dossier F33; advisory mechanics corrected 2026-07-05, Phase-3 review)**: `format`/`lint` are the gating quality jobs but not the only quality jobs the universal runs — it also dispatches 7 advisory, non-gating linters (`swift-linter` + nested `lint-yaml`/`broken-symlink`/`license-header`/`test-support-spine`/`api-breakage`/`pr-title`), enumerated in [CI-002]'s Permitted list, plus an `advisory-summary` job that renders their results to the run summary. Only `swift-linter` (a real `steps:`-bearing job) carries `continue-on-error: true`; the six nested linters are `uses:` reusable-workflow jobs and CANNOT carry `continue-on-error` per [CI-105] (the Actions parser rejects the co-presence with `startup_failure`) — each instead takes an `advisory: bool` input, and their non-gating status comes from exclusion from `ci-ok`'s `needs:` list, not from `continue-on-error`. Those are soak, not merge gates.

**Enforcement**: Mechanical + architectural — (a) `format` and `lint` jobs ARE in `swift-ci.yml`; every consumer routes through them via [CI-031]. (b) `validate-thin-callers.py` forbids standalone per-repo `swift-format.yml`/`swiftlint.yml` files (post-2026-05-10 consolidation). Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-054]. [VERIFICATION: ARCH + WF validate-thin-callers.py]

**Cross-references**: [CI-002], [CI-031], [CI-057].

---

### [CI-093] Local Toolchain Wrapper for Format / Lint Tools

**Statement**: Local invocations of toolchain-version-sensitive Swift tooling (currently `swift-format`) resolve to a wrapper script at `swift-institute/Scripts/<tool>` that exec's the same toolchain CI uses; direct `$PATH` invocation forbidden.

**Enforcement**: Script — file-presence at `swift-institute/Scripts/swift-format`; auto-tracks highest installed `swift-6.3.*-RELEASE.xctoolchain`; hard-fail with install URL if missing (no `$PATH` fallback). Developer setup prepends `Scripts/` to `$PATH` per `CONTRIBUTING.md`. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-093]. [VERIFICATION: Script Scripts/swift-format]

**Cross-references**: [CI-054], [CI-092], [PKG-BUILD-001], [PKG-BUILD-004].

---

## Per-Repo vs Centralized Partition

### [CI-108] Per-Repo vs Centralized CI Partition Rule

**Statement**: A workflow needs a per-repo file ONLY if its trigger or output is intrinsically tied to that repo's diff or branch. Everything else MUST centralize on a schedule with bot-driven cross-repo writes.

**Three mechanical tests for "needs per-repo file"**:
1. Does it run against PR diff?
2. Does it commit back to the repo's branch?
3. Does it gate a merge?

If ANY → per-repo (thin caller, ~10 lines, calling a central reusable). If NONE → centralize.

**Per-repo (thin callers + central reusable)**:
- Build/test (`ci.yml` → `swift-ci.yml@v1`): gates merge on diff
- DocC validation (`ci.yml` → `swift-docs.yml@v1`): gates merge, per-repo config
- Lint (`swiftlint.yml` → `swiftlint.yml@v1`): gates merge on diff
- Format auto-commit (`swift-format.yml` → `swift-format.yml@v1`): commits back to branch

**Centralized only (no per-repo file)**:
- Link rot detection (`link-check-weekly.yml` orchestrator + `link-check.yml` per-org reusable): scheduled, freshness within 7d acceptable
- Metadata sync (`sync-metadata-nightly.yml` + `sync-metadata.yml`): scheduled, enforces YAML→GitHub state
- Ecosystem audits/dashboards: pure aggregation
- Mass evolution (Swift bumps, cache rotations): bot-driven campaign workflows that open PRs to per-repo files

**Rejected alternative — global "umbrella" reusable**: at ~400 repos with diverse layers (primitives need full Linux+macOS+Windows matrix; statute packages need only Linux; web infra needs deploy steps), an umbrella's lowest-common-denominator pressure proliferates inputs (`enable-lint`, `extra-test-flags`, `release-mode`, …) faster than it saves files. Per-repo callers are already 10–30 lines and stable; the marginal saving is small, the LCD risk is real, and it conflicts with the established sync-script pattern.

**How to apply**: When proposing a new CI concern, answer the three tests first. If centralizable, mirror the `sync-metadata` shape (per-org reusable + cross-org orchestrator + bot installation tokens via `actions/create-github-app-token@v1` with `METADATA_APP_ID` / `METADATA_APP_PRIVATE_KEY` secrets). If per-repo, add a thin caller that points at a central reusable workflow tagged `@v1`. Don't bridge the two via a router workflow.

**Cross-repo execution mechanism**: `swift-institute-bot` GitHub App installed across all 17 orgs. Issues are filed/updated idempotently per target repo via per-org installation tokens. Workflow runs in `swift-institute/.github` (public) so Actions minutes are free even when scanning private targets — but visibility filtering is still applied (default `public`) because the bot's installations on private orgs may have constraints.


**Cross-references**: [CI-001], [CI-094], [CI-100]

---

