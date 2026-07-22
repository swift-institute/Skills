---
name: release-readiness
description: |
  Multi-phase release-readiness brief and pre-release scan; pilot launches add a skill-incorporation gate.
  Apply when preparing a major-version tag (0.1.0 or breaking). Stages but does not execute tag/visibility/blog.

layer: process

requires:
  - swift-institute

applies_to:
  - swift
  - swift6
  - swift-primitives
  - swift-standards
  - swift-foundations
  - release

created: 2026-04-30
---

# Release Readiness

A package preparing to ship a major-version tag passes through two structured artifacts: a **release-readiness brief** authored when the work begins, and a **final pre-release scan** authored after substantial recent changes. Both produce findings in `<package>/Audits/audit.md`; the scan ends in a categorized GO / CONDITIONAL GO / NO-GO recommendation. For pilot launches in a release cohort, the brief carries a fifth phase — a skill-incorporation gate — whose Tier 1 items block the *next* package's audit, not the pilot's own tag.

This skill captures the shape that the `swift-carrier-primitives` 0.1.0 publication arc validated (April 2026). It is grounded in two reference artifacts that ship in the carrier package's tree:

- `swift-carrier-primitives/AUDIT-0.1.0-release-readiness.md` (382 lines) — the four-phase release-prep brief.
- `swift-carrier-primitives/AUDIT-0.1.0-final-pre-release-scan.md` (416 lines) — the seven-phase final scan.

Both are gitignored at the package level. Treat them as the canonical templates this skill references.

---

## Workflow Position

Release-readiness is the **gate before the tag**. It comes after all in-package work (research, experiments, implementation, documentation, testing) is feature-complete and after at least one round of `/audit`. It comes before the actual tag, repo-visibility flip, and launch-blog publish.

```
Research → Experiments → Implementation → Tests → Documentation → /audit → release-readiness → tag
                                                                              ↑
                                                                this skill
```

The skill does not drive feature work. It captures the discipline of going from "feature-complete" to "shipped" without leaving regressions, dangling commitments, or skill-system drift behind.

---

## Rule Index

| ID | Topic | Hook |
|----|-------|------|
| [RELEASE-001] | Release-readiness brief | Four-phase template; per-package, gitignored |
| [RELEASE-001a] | Phase 0 partial-verification (private-repo CI) | Substitute CI-green gate with local clean-build when repo is PRIVATE |
| [RELEASE-001b] | Phase 0 baseline MUST include lint + L1 Embedded build | `swift-format lint`, `swiftlint lint`, and (for L1) `swift build -enable-experimental-feature Embedded` are baseline checks, not Phase 1 work |
| [RELEASE-002] | Final pre-release scan | Seven-phase template; runs after substantial recent changes |
| [RELEASE-003] | Skill-incorporation gate | Phase 4 for pilot launches (the fifth phase by count); Tier 1 backlog blocks next-package audit |
| [RELEASE-004] | Per-action authorization gates | Tag, visibility flip, blog publish, deploy — stage but never execute |
| [RELEASE-004a] | Cross-cohort visibility prerequisite + discussion-thread Stage 2 prerequisite | Stage 2 (visibility flip) checklist enumerates external `// parent:` URL references AND requires centralized discussion-thread creation per **github-repository** [GH-REPO-090..093] |
| [RELEASE-005] | Final go/no-go recommendation | GO / CONDITIONAL GO / NO-GO categorization |
| [RELEASE-006] | Findings destination | `<package>/Audits/audit.md`; forums-review at `Audits/forums-review/` |
| [RELEASE-007] | Empirical example-compile gate | Every README/DocC code example extract-and-compile-verified before per-action gates |
| [RELEASE-008] | Filter-parameter runtime-enforcement gate | Public filter-API surface elements verified end-to-end at runtime |
| [RELEASE-009] | "Save progress" / WIP commit detection | Phase 0 grep recent commit messages for save-progress patterns; sanity-rerun verification before treating as baseline |
| [RELEASE-010] | Tracked-artifact pre-flip check | Phase 0 grep `git ls-files` for `Audits/`, root-level `AUDIT-*.md`, `.swiftpm/xcuserdata`; surface violations of tracking policy |
| [RELEASE-015] | Path-form dependency pre-flip check | Phase 0 grep `Package.swift` for `.package(path: ...)`; public packages MUST NOT carry path-form cross-repo deps |
| [RELEASE-016] | License-header coverage on generated re-exports | Phase 0 find-grep enumerates ALL `Sources/*/exports.swift` and `Tests/*/exports.swift` for missing Apache-2.0 banner; advisory CI linter is non-blocking, so the Phase 0 grep is the compensating blocking control |
| [RELEASE-017] | CI-signal-exists vet | Phase 0: `ci.yml` thin-caller present AND Actions enabled (`gh api .../actions/permissions`); companion-skill must-loads for publish/flip arcs |
| [RELEASE-018] | Strict publication mode | Publication rejects migration-pending legacy unless current policy or a named evidence-backed exception with disposition and expiry authorizes it |
| [RELEASE-011] | Post-flip metadata immediate-sync | After visibility flip, immediately dispatch `sync-metadata.yml` per [GH-REPO-002] (don't wait for nightly cron; never direct `gh repo edit`) |
| [RELEASE-012] | Sidebar manual-UI checklist | Releases ON / Packages OFF / Deployments OFF per [GH-REPO-054] — no API; manual gear-icon panel verification |
| [RELEASE-013] | First-publication clean-history procedure | Optional: squash to 2 commits + delete CI run history for clean "first publication" surface |

---

## Release-Readiness Brief

### [RELEASE-001] Release-Readiness Brief

**Statement**: A package preparing for a major-version tag (initial 0.1.0 or otherwise breaking) MUST have a release-readiness brief at `<package>/AUDIT-{VERSION}-release-readiness.md`. The brief follows a four-phase structure, plus an optional fifth phase for pilot launches per [RELEASE-003].

**Phase structure**:

| Phase | Purpose | Output |
|-------|---------|--------|
| **0 — Baseline** | Working tree clean, CI green, prior-pass findings re-verified, locked decisions enumerated | Confirmed-state line in brief |
| **1 — Gap closure** | Package-specific gaps: `Research/_index.json` sweep, decision-record placement, naming/filename convention sweeps, contributor-section additions, anything package-shape-specific | Per-gap closure note with commit SHA |
| **2 — Systematic audit** | Invoke `/audit` against the target package; per-skill priority weighted by package shape (e.g., `code-surface` and `memory-safety` heavy for primitives that exercise `~Copyable`/`~Escapable`); findings written to `Audits/audit.md` | Per-skill findings table per [RELEASE-006] |
| **3 — Release-readiness checks** | Package.swift metadata current; LICENSE present; README install snippet matches version; CI green across configured matrix; `Research/_index.json` and `Experiments/_index.json` consistent; no debug artifacts; repo visibility correct; launch-blog readiness; deploy plan staged | Nine-item table in brief |
| **4 — Skill-incorporation gate** | (Pilot launches only — see [RELEASE-003]) | Tier 1 backlog status table |

**Earlier phases gate later phases**: don't open Phase 2 until Phase 1 is closed; don't proceed to tag-procedure prep (Phase 3) until the per-skill audit (Phase 2) is in landed state.

**Locked decisions** are enumerated in the brief's "Parent Context" section. The brief explicitly states that the investigating agent MUST NOT re-deliberate them. Examples from the carrier brief: mutability deferred; `@dynamicMemberLookup` rejected; trivial-self default covers all four quadrants; operator-ergonomics protocols stay sibling.

**Reference implementation**: `swift-carrier-primitives/AUDIT-0.1.0-release-readiness.md`.

**Cross-references**: [RELEASE-001a], [RELEASE-002], [RELEASE-003], [RELEASE-006], **audit** skill, **swift-forums-review** skill.

---

### [RELEASE-001a] Phase 0 Partial-Verification Convention for Private-Repo CI

**Statement**: When the package's repository is PRIVATE at brief-authoring time AND CI signal on the principal toolchain is unreliable per `feedback_private_repos_no_ci_runs` and `feedback_free_plan_private_ci_unrunnable`, the [RELEASE-001] Phase 0 "CI green" gate MUST be substituted with local clean-build verification on the principal toolchain (Swift 6.3 macOS), AND remaining matrix entries (Swift 6.4-dev nightly, Linux Docker) MUST be deferred explicitly to a named post-flip dispatch. Substituting silently — running the brief's Phase 0 against an unrunnable CI surface and treating "no failures observed" as "CI green" — is a procedural defect that masks pre-flip drift and lets coverage-gap regressions slip through to the post-flip surface.

**Substitution shape (mandatory three steps)**:

| Step | Action |
|------|--------|
| (a) Cite rationale | The brief's Phase 0 section MUST cite `feedback_private_repos_no_ci_runs` AND `feedback_free_plan_private_ci_unrunnable` (or successor memories) as the explicit reason for substitution. The citation grounds the substitution in the Free-plan billing-constraint root cause; without it, future readers will not understand why the CI gate was bypassed. |
| (b) Execute clean-build locally + record | Run `swift build` and `swift test` on the principal toolchain (Swift 6.3 macOS unless the principal directs otherwise) from a clean state (`.build` deleted). Record the result verbatim in the brief's Phase 0 §Build & Test sub-section: command, exit code, duration, test count, and any warnings. The local clean-build is the substituted gate; the record is the audit trail. |
| (c) Defer matrix entries to named post-flip dispatch | Enumerate the remaining matrix entries (Swift 6.4-dev nightly, Linux Docker, Windows when in scope) and name the post-flip dispatch that will run them. The dispatch SHOULD be named in the brief (e.g., "post-flip CI matrix re-verification dispatch") and tracked as a release-blocking follow-up before the cohort's NEXT package's audit, not before the pilot's tag. |

**When the rule fires**:

| Repository state at brief-authoring time | Action |
|------------------------------------------|--------|
| Private + free-plan workspace (no CI minutes available) | Substitute per (a)/(b)/(c). |
| Private + paid-plan workspace (CI runs, but signal is intermittent) | Run CI; substitute only if CI is observed-broken per the brief's verification step. |
| Public + CI green | No substitution — Phase 0 runs the standard CI-green gate. |
| Public + CI broken | Standard release-blocking finding; substitution is NOT a fix path. |

**Cross-references**: [RELEASE-001] (parent rule — this codifies its Phase 0 substitution shape), [RELEASE-002] (Final Pre-Release Scan Phase 0 — the same substitution shape applies there), [RELEASE-004a] (cross-cohort visibility — the post-flip dispatch named here MAY converge with the visibility-flip prerequisite). Per-action authorization for the visibility flip itself is a settings.json gate.

---

### [RELEASE-001b] Phase 0 Baseline MUST Include Local Lint + L1 Embedded Build

**Statement**: [RELEASE-001] Phase 0's "CI green" gate (or its [RELEASE-001a] private-repo substitute) MUST verify the FULL local-checkable surface, not just `swift build` + `swift test`. On the principal toolchain (Swift 6.3 macOS unless directed otherwise), the following checks all MUST exit 0 before Phase 0 closes. Any non-zero exit is a Phase 0 failure to close before opening Phase 1.

| Check | Required when | Tool | Catches |
|-------|---------------|------|---------|
| `swift build` clean | Always | toolchain default | Compile errors |
| `swift test` matches published count | Always | toolchain default | Test regressions |
| `swift-format lint --strict --recursive Sources/` | Always | swift-format paired with CI's `swift:6.3` image (currently 6.3.1; see workspace tooling pin) | Formatting + missing doc + structural issues that swift-format covers |
| `swiftlint lint --strict` (Sources + Tests) | Always | SwiftLint paired with workspace pin | Institute custom rules: `swift_error_qualification` ([PLAT-ARCH-011]), `cardinal_count_minus_one_anti_pattern` ([INFRA-025]), `l1_no_platform_conditionals` ([PLAT-ARCH-008c]), `no_foundation_import_*` ([PRIM-FOUND-001]), etc. — disjoint from swift-format's coverage |
| `swift build -Xswiftc -enable-experimental-feature -Xswiftc Embedded` per [PKG-BUILD-008] | L1 packages only (in `swift-primitives` org or `metadata.yaml` topic includes `primitives`) | Swift 6.4-dev nightly | Concurrency-surface (`Actor`, `_Concurrency`, `CheckedContinuation`, `UnsafeContinuation`, `async`/`await`), Foundation leaks, non-Embedded-stdlib usage that grep-for-`import Foundation` cannot detect |

**Why these specific tools**:

- `swift build` + `swift test` only verify what the compiler accepts. Lint surface is independent and CI gates on it.
- `swift-format` (institute-canonical config in `.swift-format`) covers formatting, doc-comment presence, structural issues.
- `swiftlint` carries institute-specific custom rules that swift-format does NOT cover. Both must run.
- The Embedded build is the only way to surface concurrency-surface (`Actor`, `_Concurrency`, continuations, `async`/`await`) usage that breaks on Embedded — grep for `import Foundation` is necessary but NOT sufficient for L1 Embedded compatibility per `[PRIM-FOUND-001]` / `[PKG-BUILD-007]`.

**Procedure** (additions to [RELEASE-001a] step (b) "Execute clean-build locally + record"):

After `swift build` and `swift test`:

1. Run `swift-format lint --strict --recursive Sources/`. Record exit code and violation count.
2. Run `swiftlint lint --strict` (full scope, including Tests/). Record exit code and violation count.
3. For L1 packages, run `TOOLCHAINS=<6.4-dev-bundle-id> swift build -Xswiftc -enable-experimental-feature -Xswiftc Embedded` per [PKG-BUILD-008]. Record exit code and any unguarded-stdlib-surface findings.

**Cross-references**: [RELEASE-001] (parent), [RELEASE-001a] (substitution shape this extends), [PKG-BUILD-007] (Embedded source-guard pattern), [PKG-BUILD-008] (Embedded build invocation), [CI-054] (developer contract for lint), `[PRIM-FOUND-001]` (Foundation-free invariant).

---

### [RELEASE-001c] Phase 0 Baseline Build MUST Use `rm -rf .build` Clean State

**Statement**: [RELEASE-001] / [RELEASE-001a] / [RELEASE-001b] Phase 0 baseline build/test runs MUST start from a clean state via `rm -rf .build`. Incremental-cache builds report success against a stale on-disk cache that masks upstream-package state divergence — a class of pre-tag defect that ONLY surfaces under clean rebuild.

**Composite:** clean-state requirement (mechanical) + cache-invalidation rationale (semantic) + worked-example mapping (semantic).

**Procedure** (sub-step inserted before [RELEASE-001a] step (b) "Execute clean-build locally + record"):

```bash
# At Phase 0 start, before swift build / swift test:
rm -rf .build
# If consumers depend on this package, also clean their .build/ directories:
# (per multi-package workspace; consumer caches retain stale resolution against the prior public API surface)
```

**Why incremental-cache builds mask this defect**:

| Cause | Effect |
|-------|--------|
| Upstream package removed/relocated a public type | Downstream resolution cache retains the prior resolution |
| `swift build` runs in incremental mode | Touched-file recompile only; un-touched-file resolutions unchanged |
| `swift package resolve` may not always force re-resolve | Manifest-vs-resolution drift |

The cache-invalidation boundary is not always observable from the package-author's desk. The mechanical safeguard (`rm -rf .build`) is one shell command per Phase 0 run; the cost is wall-clock seconds (small package) to minutes (large package) of additional rebuild time. The benefit is catching upstream-state divergence at brief-author time, not at post-flip CI time.

**Relationship to [RELEASE-001b]**: [RELEASE-001b] specifies WHAT to verify (build + test + lint + Embedded). This rule specifies the prerequisite STATE (clean cache) before those verifications run. Both are necessary; one without the other leaves a verification gap.

**Cross-references**: [RELEASE-001], [RELEASE-001a], [RELEASE-001b]

---

### [RELEASE-009] Phase 0 "Save Progress" / WIP Commit Detection

**Statement**: [RELEASE-001] Phase 0 MUST grep recent commit messages on the target branch for save-progress / WIP / temporary patterns and treat any match as a sanity-rerun trigger before treating the current HEAD as a Phase 0 baseline. Save-progress commits commonly carry incomplete or broken state — treating them as a baseline without re-verification masks defects that surface later as scope expansion.

**Procedure**:

```sh
git log --oneline -20 \
  | grep -iE "^[a-f0-9]+ (save progress|wip|tmp|temp|fix later|todo|scratch)"
```

If any match returns: re-run `swift build`, `swift test`, `swift-format lint --strict`, `swiftlint lint --strict` per [RELEASE-001b] before declaring Phase 0 baseline. The save-progress commit's tree may pass on the author's machine while failing on the next clean build because the author saved before completing the change.

**What patterns the grep should match** (all case-insensitive):

| Pattern | Why it's a flag |
|---------|-----------------|
| `save progress` | Common WIP marker; indicates work was unfinished at commit time |
| `wip` / `WIP` | Explicit WIP marker |
| `tmp` / `temp` | Temporary state, often partially reverted |
| `fix later` / `todo` | Acknowledged incomplete work |
| `scratch` | Throwaway work that may not have been cleaned |

**Cross-references**: [RELEASE-001] Phase 0, [RELEASE-001b] (full lint + Embedded baseline checks).

---

### [RELEASE-010] Phase 0 Tracked-Artifact Pre-Flip Check

**Statement**: [RELEASE-001] Phase 0 MUST grep `git ls-files` for tracked artifacts that violate ecosystem tracking policies. Audit artifacts (`Audits/`, root-level `AUDIT-*.md`), package-local canonical-skill copies at ANY depth (`Skills/SKILL.md` AND `Skills/<name>/SKILL.md` — canonical source lives at `swift-institute/Skills/<name>/SKILL.md`; only the symlinked path is consumed by Claude routing), Xcode user state (`.swiftpm/xcuserdata`, `.swiftpm/xcode/xcuserdata`), build products (`.build/`, `DerivedData/`), and OS noise (`.DS_Store`) MUST NOT be tracked per `Scripts/sync-gitignore.sh` canonical state. Phase 0 surfaces violations; Phase 1 closes them via `git rm --cached`.

**Procedure**:

```sh
git ls-files | grep -E '^Audits/|^AUDIT-.*\.md$|^Skills/([^/]+/)?SKILL\.md$|\.swiftpm/.*xcuserdata|\.build/|DerivedData/|\.DS_Store$|/\.DS_Store$'
```

Each match is a release-blocking finding to clear via `git rm --cached <file>` (file remains on disk; only stops being tracked) before flip. The canonical `.gitignore` blocks NEW additions, but pre-existing tracked files persist until explicitly untracked.

**Coverage classes** (the canonical .gitignore should already block ADDITIONS but pre-existing tracked files require Phase 0 surfacing):

| Pattern | Reason it must not be tracked |
|---------|-------------------------------|
| `Audits/` (any path under) | audit findings are contributor-internal; not consumer-facing |
| Root-level `AUDIT-*.md` | release-readiness briefs / final scans are contributor-internal |
| `Skills/SKILL.md` AND `Skills/<name>/SKILL.md` (nested) | Canonical skill source is `swift-institute/Skills/<name>/SKILL.md`; package-local copies at ANY depth (top-level `Skills/SKILL.md` or nested `Skills/<name>/SKILL.md` mirroring the canonical layout) are reachable via the symlinked `.claude/skills/` path generated by `swift-institute/Scripts/sync-skills.sh` and MUST NOT be tracked at the package level. Tracked package-local copies drift from the canonical source. |
| `.swiftpm/xcuserdata` / `.swiftpm/xcode/xcuserdata` | Per-user Xcode state; differs per machine |
| `.build/` | Build outputs |
| `DerivedData/` | Xcode derived data |
| `.DS_Store` | macOS finder state |

**Cross-references**: [RELEASE-001] Phase 0, `Scripts/sync-gitignore.sh` (canonical .gitignore source).

---

### [RELEASE-015] Phase 0 Path-Form Dependency Pre-Flip Check

**Statement**: [RELEASE-001] Phase 0 MUST grep `Package.swift` (and every sibling `*/Package.swift` in nested-package layouts) for `.package(path: ...)` declarations. Public packages MUST NOT carry path-form cross-repo dependencies — every match is a release-blocking finding that MUST be converted to url-form before flip. The rule applies to the package under release; private packages MAY retain path-form deps during pre-publishable work per `[PKG-DEP-001]`, but the moment a sibling-repo is public (on `main`, even without a version tag), every public consumer of it MUST switch to url-form.

**Procedure**:

```sh
# In the package root, before flip:
grep -nE '^\s*\.package\(path:' Package.swift
# Nested-package layouts (Tests/Testing/Package.swift, Lint/Package.swift, Experiments/*/Package.swift) — only audit nested manifests that ship as part of the public surface; gitignored nested manifests are out of scope.
```

Each match MUST be converted to:

```swift
.package(url: "https://github.com/<org>/<name>.git", branch: "main"),
```

(`branch: "main"` is the ecosystem-canonical pre-tag form per existing url-form uses in `swift-ordinal-primitives`, `swift-affine-primitives`, etc. Switch to `from: "X.Y.Z"` only when the target package is itself tagged.)

**Coverage classes**:

| Pattern | Reason it must not appear in a public package |
|---------|-----------------------------------------------|
| `.package(path: "../<sibling>")` | A consumer cloning the public repo has no `../<sibling>` to resolve against; only the maintainer's sibling-clone topology does |
| `.package(path: "../../<org>/<sibling>")` | Same — depends on the maintainer's local workspace shape, not on the public dep graph |
| Commented `// .package(path: ...)` | Out of scope — commented declarations don't resolve; flag only if uncommenting is imminent |

**Why this is a release-blocking finding**: SwiftPM resolves path-form deps only against the local filesystem. Public-consumer `swift package resolve` runs in environments without the sibling-clone — CI runners, downstream consumers, Linux build hosts. The resolve will fail with a path-not-found error at the first non-local resolve. The defect is undetectable in the maintainer's environment (resolve succeeds) and 100%-detectable in any consumer's environment. Phase 0 is the only place this surfaces before public flip; downstream consumers cannot work around the violation.

**Cross-references**: [RELEASE-001] Phase 0, `[PKG-DEP-001]` (path pre-publish / url post-publish), `[PKG-DEP-002]` (package-identity audit before path-form sibling deps), **swift-package** skill, `swift-institute/Research/versioning-and-release-strategy.md` (the canonical bottom-up visibility-flip × tag × pin-form-switch phase model + one-form-per-package invariant this Phase-0 path-form check serves).

---

### [RELEASE-016] Phase 0 License-Header Coverage Check on Generated Re-Export Files

**Statement**: [RELEASE-001] Phase 0 MUST verify that every `Sources/*/exports.swift` and `Tests/*/exports.swift` re-export file in the package carries the institute Apache-2.0 license-header banner. Auto-generated re-export files often ship with a 2-line autogen comment header instead of the canonical banner. The universal `swift-ci.yml` `lint-license-header` job is **advisory** (non-blocking) — a passing CI run does NOT guarantee banner coverage. Phase 0 is the blocking compensating control; it MUST enumerate ALL `exports.swift` files in the package, not just the umbrella module's.

**Procedure** (additions to [RELEASE-001b] Phase 0 lint pass):

```sh
# In the package root, before flip:
find Sources Tests -name 'exports.swift' -exec grep -L 'This source file is part of' {} +
```

Each match is a release-blocking finding to fix by prepending the institute Apache-2.0 banner (canonical template per the **swift-pull-request** skill). The grep walks ALL `exports.swift` files in multi-target packages (umbrella module, Core / internal modules, Test Support modules); partial sweeps that visit only the umbrella silently miss sub-target gaps.

**Why the find-grep is needed despite the CI advisory linter**: the universal `swift-ci.yml` `lint-license-header` job runs as an advisory (non-blocking) job per the free-plan CI policy. A passing CI run does not guarantee banner coverage — it only guarantees the run did not fail. Phase 0's find-grep is the blocking compensating control that the advisory linter complements but does not replace. Once the advisory linter graduates to blocking-with-full-scope, this rule MAY be relocated to the lint gate per minimal-edit (same supersession pattern as [RELEASE-015]).

**Cross-references**: [RELEASE-001] Phase 0, [RELEASE-001b] (Phase 0 lint pass — this rule extends), **ci-cd-workflows** skill (`lint-license-header` advisory job), **swift-pull-request** skill (canonical Apache-2.0 banner template).

---

### [RELEASE-017] Phase 0 CI-Signal-Exists Vet

**Statement**: [RELEASE-001] Phase 0 — and any flip cadence whose validation relies on CI — MUST verify the CI signal actually exists before treating "CI green" as meaningful: (a) the `.github/workflows/ci.yml` thin caller is present per ci-cd-workflows [CI-001]/[CI-031]; (b) GitHub Actions is enabled on the repo. A package can pass every other check with NO CI workflow at all, and an Actions-disabled repo produces neither a CI signal nor a failure — the flip ships unvalidated. If either leg fails, run the local build/test floor per [RELEASE-001a]/[RELEASE-001b] or close the gap before proceeding. Publish/flip arcs MUST load **ci-cd-workflows** and **github-repository** as companion skills.

**Procedure**:

```sh
ls .github/workflows/ci.yml                                 # (a) thin caller present
gh api repos/<org>/<pkg>/actions/permissions --jq .enabled  # (b) must print true
```

**Cross-references**: [RELEASE-001] Phase 0, [RELEASE-001a], [RELEASE-001b], [CI-001], [CI-031], **ci-cd-workflows** skill, **github-repository** skill.

---

### [RELEASE-018] Strict Publication Mode

**Statement**: Release readiness MUST distinguish ordinary development scans
from publication scans. A publication scan MUST reject migration-pending legacy
that violates a current `MUST` or `MUST NOT` requirement unless either the
requirement itself authorizes the structure or the release contract names an
evidence-backed exception with an explicit disposition and expiry.

“Known legacy,” “planned migration,” and “historically accepted” describe
state; they do not establish conformance. Development scans MAY preserve those
states as non-blocking migration findings, but publication mode MUST remain
strict.

This rule owns publication-mode behavior.

**Cross-references**: [RELEASE-005].

---

## Final Pre-Release Scan

### [RELEASE-002] Final Pre-Release Scan

**Statement**: When substantial recent changes have landed since the release-readiness brief was authored — README rewrite, source restructure, dependency-graph changes, workflow trim, vision consolidation, or test-suite naming sweep — a final pre-release scan MUST be run before the tag. The scan goes at `<package>/AUDIT-{VERSION}-final-pre-release-scan.md` and follows a seven-phase structure.

**Phase structure**:

| Phase | Purpose |
|-------|---------|
| **0 — Baseline verification** | Working tree clean and HEAD matches origin; CI green on the latest commit; `swift build` clean; `swift test` count matches the published claim; `swift package dump-package` matches README's Architecture section |
| **1 — Re-audit prior findings** | Every entry in `Audits/audit.md` re-verified independently; mark `RE-VERIFIED`, `RESOLVED` (with resolving SHA), or `CORRECTED` (new finding); do NOT trust prior verdicts |
| **2 — Independent fresh-eyes sweep** | Each relevant skill applied independently and produces findings whether or not the prior pass found them; particular attention to areas the prior pass may have skimmed. Phase 2 MUST include an explicit **discovery-lens** sub-pass on the README and the org/repo profile (per [README-023] evaluator's lens): for each paragraph, cover-with-your-hand test ("could the reader skip this and still answer the family's evaluation question?"). Single-package per-rule audits do not surface cohort-recurring patterns where the rules themselves need extension; the discovery-lens pass catches such patterns before launch. Cost: minutes per package; benefit: avoids the post-launch ecosystem-uniformity sweep that propagates the missed pattern across N already-shipped READMEs. |
| **3 — Recent-change regression check** | Per substantial-change set, verify no regression: spot-check claims in any consolidated narrative, re-read the README cold, grep the repo for dangling references after relocations, trigger workflow dry-runs |
| **4 — Forums-review re-simulation** | Invoke `swift-forums-review` against current state; output to `Audits/forums-review/forums-review-{simulation,objections,triage}-{DATE}.md`; compare to prior simulation; flag new objections + unresolved load-bearing ones |
| **5 — Tag-procedure prep verification** | Each Phase-3 release-readiness item from the original brief gets current status: `Package.swift` metadata, LICENSE, README install snippet, CI, indexes, debug artifacts, visibility, launch-blog, deploy |
| **6 — Backlog status** | Per Tier 1 item in the skill-incorporation backlog (pilot launches), verify status accuracy by re-deriving each row's claim from current source — NOT just reading the row's text. `LANDED` items confirmed against commit SHAs AND current code state; `OPEN` items confirmed not blocking the pilot's own tag AND that the pre-OPEN state still applies. A row that says "Test Support relocation needed" must be cross-checked against `Tests/Support/` actually missing or present; a row that says "ID X added" must be cross-checked that ID X is at the cited skill rule. Without re-derivation, an auditor following the row blindly may queue a no-op or contradict a state that's already changed. |
| **7 — Final go/no-go** | Categorized recommendation per [RELEASE-005] |

**Why this is a separate artifact, not a re-run of the original brief**: the brief is gap-closure-oriented ("what's missing? close gaps"). The scan is regression-oriented ("what recent changes might have broken this? verify"). The scan trusts none of the brief's prior verdicts — it reproduces conclusions. The two artifacts compose: the brief proves the package was in shape at audit time; the scan proves nothing has drifted since.

**The scan's "Do Not Touch" boundary**: the investigating agent MUST NOT modify `Sources/`, `Tests/`, `Research/`, `README.md`, `Package.swift`, `LICENSE.md`, `.github/workflows/`, `.gitignore`, or `.github/metadata.yaml`. The release is final; any required code change is principal-decision territory. If a finding warrants a code fix before tag, the audit MUST escalate — not apply.

**Reference implementation**: `swift-carrier-primitives/AUDIT-0.1.0-final-pre-release-scan.md`.

**Cross-references**: [RELEASE-001], [RELEASE-005], [RELEASE-006], **audit** skill, **swift-forums-review** skill.

---

## Skill-Incorporation Gate (Pilot Launches)

### [RELEASE-003] Skill-Incorporation Gate

**Statement**: When a package is the first in a release cohort (the **pilot launch**), its release-readiness brief MUST include a skill-incorporation gate as a fifth phase. The gate enumerates Tier 1 skill amendments derived from the launch process. The amendments DO NOT block the pilot's own tag, but they DO block the next package's audit. The cohort treats the pilot's launch as the primary learning event; lessons feed back into the skills system before subsequent tags so each subsequent audit runs against an updated rule set.

**Backlog file**: the canonical source is `swift-institute/Research/<package>-launch-skill-incorporation-backlog.md`. The file inventories all skill / convention / research follow-ups whose provenance is the pilot's launch arc, classified into tiers:

| Tier | Definition | Cohort impact |
|------|-----------|---------------|
| **Tier 1** | Direct skill amendments | Block the **next** package's audit; not the pilot's own tag |
| **Tier 2** | Process / craft skill improvements | Improve future launches; do not block any tag |
| **Tier 3** | Research investigations | Open new questions; not rule changes |
| **Tier 4** | Speculative / consolidation | Lower priority |

**Procedure for landing a Tier 1 item** (verbatim from the carrier backlog template):

1. Update the relevant skill file in `swift-institute/Skills/<skill>/`.
2. Bump the skill's `last_reviewed`.
3. Run `swift-institute/Scripts/sync-skills.sh` to regenerate the `~/.claude/skills/` symlinks.
4. Annotate the matching row in the backlog: change `Status` from `OPEN` to `LANDED <commit-sha> <date>`.
5. Cross-link from the skill commit message back to the backlog row and the originating reflection.

**Procedure for deferring a Tier 1 item** past the next package's audit: annotate `Status: DEFERRED <date> — <one-line rationale> — re-evaluate at <trigger>`. The downstream audit MUST cite the deferral when running against the un-amended rule.

**The pilot model is explicit**: the principal MAY choose to tag the pilot with the skill backlog still open, then process the backlog before the cohort's subsequent tags. The pilot's audit is a *snapshot against the rule set at audit time*; landing Tier 1 items afterward does NOT retroactively edit the pilot's findings.

**When does this rule fire vs not?**:

| Situation | Phase 5 in brief? |
|-----------|-------------------|
| Pilot of a multi-package release cohort | **Yes** |
| Single-package release (no cohort siblings) | No |
| Non-pilot package in a cohort (after pilot has shipped) | No — backlog already exists; brief just cites it |

**Reference implementation**: `swift-institute/Research/carrier-launch-skill-incorporation-backlog.md` (12 Tier 1 items, 11 Tier 2, 10 Tier 3, 4 Tier 4, plus 3 package-local items at time of authoring).

**Cross-references**: [RELEASE-001], **skill-lifecycle** skill.

---

## Per-Action Authorization Gates

### [RELEASE-004] Per-Action Authorization Gates

**Statement**: The release-readiness brief and final pre-release scan MUST stage but NOT execute the following actions. Each requires explicit principal authorization at the moment of execution. Per-action means each action requires its own authorization at the moment of execution; one authorization does not carry to the next.

| Action | Authorization required |
|--------|------------------------|
| `git tag {VERSION} && git push --tags` | Per-action authorization |
| Repo visibility flip (private → public) | Per-action authorization |
| Launch blog publish (push to swift-institute.org) | Per-action authorization (separate from blog-repo push) |
| `swift-institute.org` deploy of the launch post | Per-action authorization |

**The investigating agent MUST**:

- Stage the commands and verify they're correct.
- List them in the brief / scan with the exact form they will be executed in.
- Surface any reason a command might not work as written (missing remote, wrong branch, missing tag-author signing key).

**The investigating agent MUST NOT**:

- Execute any of the four staged actions on its own initiative.
- Treat principal approval of an earlier action as authorization for a later one.

**Why per-action**: each action has a different blast radius and a different rollback cost. A pushed tag is hard to retract; a public visibility flip is hard to reverse for SEO; a published blog post propagates to RSS, the org website, and possibly social channels. Bundling them under one approval would conflate four different decisions.

**Cross-references**: [RELEASE-001], [RELEASE-002], [RELEASE-004a].

---

### [RELEASE-004a] Cross-Cohort Visibility Prerequisite for Stage 2 Visibility Flip

**Statement**: When a pilot package's nested-package consumers (or any in-tree consumer fixture) inherit configuration via `// parent: <URL>` directives — or any analogous file-based canonical reference — pointing to repositories OUTSIDE the active release cohort, those external repositories MUST also be flipped to public BEFORE the pilot's launch is consumer-experience-complete. Stage 2 of [RELEASE-004] (the Repo Visibility Flip authorization) MUST extend its checklist to require enumerating + verifying every cross-repo URL reference reachable from the pilot's consumer surface. A visibility flip on the pilot alone leaves consumers with broken `// parent:` resolution at the moment of first contact — the worst possible UX failure on a launch.

**Stage 2 extended checklist**:

| Check | Detail |
|-------|--------|
| 1. Enumerate cross-repo references | Grep the pilot's source tree (and any in-tree consumer fixture, e.g., `Lint/Sources/Lint/main.swift`, `Examples/`, README code blocks) for `// parent:`, `parent_config:`, raw GitHub URLs, and any analogous external-repo pointer. Record each reference's source file, target repo, and target file path. |
| 2. Verify each external repo's visibility | For each enumerated reference, check the target repo's current visibility via `gh repo view <owner>/<repo> --json visibility` or equivalent. Flag any private repo whose URL is reachable from the pilot's consumer surface. |
| 3. Stage flips for prerequisite repos | Stage `gh repo edit <owner>/<repo> --visibility public` for every prerequisite repo. Each flip is its own [RELEASE-004] per-action authorization — bundling them under the pilot's flip would conflate four different repository decisions. |
| 4. Sequence the flips | Authorize prerequisite-repo flips BEFORE the pilot's flip. The pilot's flip is the last step in Stage 2; if any prerequisite repo's flip fails or is denied, the pilot's flip MUST NOT proceed (the consumer surface would still be broken). |
| 5. Re-verify post-flip resolution | After all flips, re-fetch one or two of the `// parent:` URLs as an unauthenticated user (or with a tokenless `curl`) to confirm the public surface resolves correctly. Record the verification in the brief / scan. |
| 6. Create centralized discussion thread | Before authorizing the visibility flip, dispatch `sync-discussion-threads.yml` per **github-repository** [GH-REPO-092] with `repo={owner}/{repo}`, `create=true`, `dry-run=false`. The workflow creates the thread on `swift-institute/.github`'s "Packages" category, opens a PR back to the target repo writing the URL into `.github/metadata.yaml` and updating the README marker block per [README-040] (in `readme/sub-package.md`). Principal reviews + merges the PR. Verify thread is live at the returned URL before proceeding to the flip itself. |
| 7. Re-verify discussion thread post-flip | After step 5: re-fetch the discussion URL as an unauthenticated user. Confirm the thread is publicly visible at `https://github.com/orgs/swift-institute/discussions` and at its direct URL. Record the verification in the brief / scan's Phase 3 section. |

**Scope note for rows 6–7 (added 2026-05-10)**: rows 6 and 7 extend the Stage 2 checklist beyond cross-cohort URL prerequisites to include centralized discussion-thread creation per [GH-REPO-090..093]. Both classes of work share the same Stage 2 timing and per-action-authorization shape, so they live on the same checklist; the rule's title and statement stay focused on cross-cohort visibility because that remains the dominant authoring concern. The pilot rollout (swift-primitives, with `swift-carrier-primitives` + `swift-tagged-primitives` as canaries) validates the discussion-thread row before broader cohort expansion.

**Why this is a Stage 2 concern, not a Stage 1 concern**: tag-time resolution of cross-repo URLs is not affected by the pilot's tag — the tag is a private-repo internal commit reference. The breakage surfaces only at visibility-flip time, when the pilot becomes publicly cloneable and a first consumer attempts to follow the `// parent:` URL. Therefore the prerequisite check belongs in Stage 2 (visibility flip), not Stage 1 (tag).

**Cross-references**: [RELEASE-004] (parent — this extends Stage 2), [RELEASE-001] (Phase 3 release-readiness checks list cross-cohort references for staging), `feedback_lint_canonical_file_based_org_mirror.md` (the `// parent:` directive convention this rule guards), `feedback_no_public_or_tag_without_explicit_yes.md` (per-action authorization for each flip in the prerequisite chain), **github-repository** [GH-REPO-090..093] (discussion-thread Stage 2 prerequisite — rows 6 and 7), [README-040] in `readme/sub-package.md` (Community section the workflow PR targets), [README-168] in `readme/ci-automation.md` (CI validation contract).

---

## Final Recommendation

### [RELEASE-005] Final Go/No-Go Recommendation

**Statement**: The final pre-release scan MUST end with a categorized recommendation. The category determines what authorization the principal can grant.

| Category | Criteria | Action |
|----------|----------|--------|
| **GO** | Zero CRITICAL or HIGH findings; all release-readiness items green; forums-review re-simulation surfaces no unresolved load-bearing critique | Recommend authorizing the per-action gates per [RELEASE-004] |
| **CONDITIONAL GO** | Specific MEDIUM findings the principal must accept-as-known before tag (e.g., known-deferred work documented in research) | Recommend conditional authorization with each accepted-as-known item explicitly listed |
| **NO-GO** | CRITICAL or HIGH findings that MUST be resolved before tag | Escalate to principal; the investigating agent MUST NOT apply fixes — fixes are principal-decision territory per [RELEASE-002]'s "Do Not Touch" boundary |

**The recommendation MUST include**:

- Summary table of findings by severity (CRITICAL / HIGH / MEDIUM / LOW counts).
- Specific re-test recommendations for any deferred items (e.g., "if the launch blog mentions X, re-verify the install snippet matches the actual tag").
- Predicted forums-review reception for the post-launch window, derived from the Phase 4 re-simulation.

**What goes wrong without categorization**: an open-ended "here are the findings, what do you think?" report puts the categorization burden on the principal at exactly the moment they need a clear authorization decision. The categorization removes that burden. GO is a green light. NO-GO is a stop. CONDITIONAL GO names what's being accepted-as-known so the principal can authorize with eyes open.

**Cross-references**: [RELEASE-002], **audit** skill.

---

## Findings Destination

### [RELEASE-006] Findings Destination

**Statement**: All release-readiness findings live in `<package>/Audits/audit.md`, gitignored. The file MAY be created during the release-readiness brief's Phase 2 if it does not yet exist.

**Conventions**:

- One top-level `## {Skill}` section per audit pass, dated, with a per-finding table. The shape mirrors the property-primitives precedent.
- Final pre-release scan findings get a top-level `## {VERSION} Final Pre-Release Scan — {DATE}` section appended to the same file. The scan's seven phases each have a sub-section under that header.
- Forums-review artifacts (simulation, objections, triage) go to `<package>/Audits/forums-review/forums-review-{stage}-{DATE}.md` per the **swift-forums-review** skill. This directory is gitignored at the workspace level.

**Why gitignored**: the audit findings include pre-mortem critique simulation, locked-decision rationale, and skill-incorporation tactics that are contributor-internal. They inform the release; they are not part of the consumer-facing surface.

**Reference implementation**: `swift-carrier-primitives/Audits/audit.md` (the per-skill findings log) plus `swift-carrier-primitives/Audits/forums-review/` (the relocated forums-review pre-mortem artifacts).

**Cross-references**: [RELEASE-001], [RELEASE-002], **swift-forums-review** skill.

---

### [RELEASE-007] Empirical Example-Compile Gate

**Statement**: Phase 3 of [RELEASE-001] (Release-Readiness Brief) and [RELEASE-002] (Final Pre-Release Scan) MUST include an empirical-compile gate for every README, DocC article, and skill-rule example. Each code example in a customer-facing artifact MUST be empirically validated — extracted as-is and either parsed (`swiftc -parse`) or fully built (`swift build` against a scratch SwiftPM package) — before the package can pass to the per-action authorization gates per [RELEASE-004]. Examples that fail the gate are a release-blocking defect; the package CANNOT proceed to tag until they compile.

**Validation tier mapping** (per [README-170] composed-example matrix):

| Example shape | Validation discipline | Gate status |
|---------------|------------------------|-------------|
| Single type, ≤2 method calls | `swiftc -parse` | Required |
| Composed example (≥2 ecosystem types) | Real call-site citation per type OR `swift build` against scratch SwiftPM package | Required |
| Quick Start examples | `swift build` against scratch SwiftPM package | Required |
| DocC code blocks marked `// docc-test` (or equivalent) | `swift test` via DocC plugin (when available) | Required |
| Skill-rule examples (illustrative code in `[ID]` blocks) | `swiftc -parse` | Required |

**Procedure** (Phase 3 of release-readiness brief / final pre-release scan):

1. Enumerate every customer-facing artifact: README, DocC articles in `Documentation.docc/`, skill rules referenced from the package's documentation.
2. Extract each code example to `/tmp/<package>-release-validate/example<N>.swift` (or equivalent scratch location).
3. Apply the validation discipline per the tier-mapping table.
4. Record the per-example result (file path, validation mechanism, status) in the brief / scan's Phase 3 section.
5. Any failure is a release-blocking finding; route to remediation before proceeding to per-action authorization.

**Pre-existing READMEs are a high-risk class**: examples authored before API churn can document removed or renamed APIs (memory's README still showed `Memory.Address.Buffer.Mutable` after its removal); the compile gate MUST re-verify pre-existing examples against the CURRENT API surface, not only newly-authored ones (Reflections/2026-06-02-storage-primitives-closure-publication.md).

**Cross-references**: [RELEASE-001], [RELEASE-002], [README-009], [README-022], [README-170]

---

### [RELEASE-008] Filter-Parameter Runtime-Enforcement Test Gate

**Statement**: Phase 3 of [RELEASE-001] / [RELEASE-002] MUST include a runtime-enforcement test gate for every public-API surface element that accepts a filter parameter — `paths`, `included`, `excluded`, `predicates`, `kinds`, `severities`, or any equivalent. The gate verifies that the filter ACTUALLY narrows behavior end-to-end at the runtime layer, not merely that the parameter is accepted at the API surface. Filter-API surface elements without a runtime-enforcement test are a release-blocking defect; pure-unit-test discipline (per-rule / per-component) is structurally insufficient because the unit's filter is tested in isolation while the integration may ignore it.

**The failure mode this gate catches**:

A filter parameter declared at L1 (`Lint.Rule.Configuration.paths: Path.Filter?`), accepted by factory methods (`Lint.Rule.Configuration.enable(R.self, paths: ...)`), and threaded through `Lint.Configuration` — but `Lint.Run.run` ignores `entry.paths` at the runtime layer. Per-rule unit tests pass (the rule operates correctly when activated). API-surface tests pass (the configuration accepts the parameter). The runtime ignores it. Only an integration test that activates a rule WITH a `paths:` filter, runs against a directory containing both in-scope and out-of-scope files, and verifies findings come from the in-scope subset only would expose the gap.

**Procedure** (Phase 3 of release-readiness brief / final pre-release scan):

1. Enumerate every public-API surface element with a filter parameter.
2. For each, identify the corresponding runtime entry point (the function/method that consumes the filter).
3. Verify a test exists at the integration layer that:
   a. Constructs the API surface with the filter set to a non-trivial predicate.
   b. Invokes the runtime entry point against an input set spanning both in-scope and out-of-scope items.
   c. Asserts the runtime output reflects ONLY the in-scope subset.
4. If no such test exists, the filter is unverified-end-to-end; mark as release-blocking finding.

**Cross-references**: [RELEASE-001], [RELEASE-002], [TEST-*]

---

## Post-Flip Procedures

### [RELEASE-011] Post-Flip Metadata Immediate-Sync

**Statement**: After [RELEASE-004] Stage 2 (visibility flip private → public), `.github/metadata.yaml` deltas that have not yet been propagated to the GitHub-side state MUST be reconciled IMMEDIATELY by dispatching the centralized `sync-metadata.yml` workflow against the flipped repo — never via direct `gh repo edit` (forbidden per [GH-REPO-002]; the workflow is the only writer), and not deferred to the next centralized `sync-metadata-nightly.yml` cron run. Centralized sync runs at 04:00 UTC daily per [GH-REPO-071]; consumers hitting the public repo between flip and next cron see stale metadata. The metadata sync is part of the flip step, not a separate scheduled concern.

**Procedure**:

After the visibility flip succeeds:

1. Diff `.github/metadata.yaml` (canonical, in-repo) vs `gh repo view --json description,homepageUrl,repositoryTopics`. Identify any drift.
2. Apply the deltas by dispatching the centralized sync against the flipped repo (per [GH-REPO-002] the workflow is the only writer; direct `gh repo edit` is forbidden): `gh workflow run sync-metadata.yml -R swift-institute/.github -f repo=<owner>/<repo>` (or dispatch from the Actions UI per [GH-REPO-070]).
3. Re-run `gh repo view --json …` to confirm the GitHub-side state matches the YAML.

**What about settings (issues/discussions/wiki/defaultBranch)**: these were already verified in Phase 3 row 7 ("Repo visibility correct") since they don't change at flip-time. Only description/homepage/topics typically drift between YAML and GitHub state because the centralized sync workflow is what propagates YAML edits.

**Why this is a release-readiness concern, not a metadata-sync concern**: the centralized `sync-metadata-nightly.yml` is correct as a *drift-detection* mechanism over time, but at flip-moment specifically the YAML state should be the GitHub state. Embedding the immediate sync in [RELEASE-004]'s Stage 2 closes the consumer-experience gap; relying on the cron leaves a 0–24-hour first-impression-broken window.

**Cross-references**: [RELEASE-004] Stage 2 (visibility flip), [GH-REPO-060] (`.github/metadata.yaml` schema), [GH-REPO-070] (centralized sync workflow), [GH-REPO-071] (convergence cadence; nightly cron).

---

### [RELEASE-012] Sidebar Manual-UI Checklist for Public-Flip

**Statement**: GitHub repository sidebar checkbox state per [GH-REPO-054] (Releases ON / Packages OFF / Deployments OFF) is NOT API-exposed. The release brief's [RELEASE-004] Stage 2 (visibility flip) authorization MUST include a manual UI verification step at the gear-icon "About" panel of `https://github.com/<owner>/<repo>` to confirm the three checkboxes match the canonical state.

**Procedure** (after [RELEASE-011] metadata sync):

1. Open `https://github.com/<owner>/<repo>` (the public landing page now that flip is complete).
2. Click the gear icon next to "About" in the right-hand sidebar.
3. Confirm:
   - **Releases**: ☑ checked (every Swift package publishes tagged releases; consumers click here to find them)
   - **Packages**: ☐ unchecked (Institute packages distribute via SwiftPM tag → SPI, not GitHub Packages registry; the empty section is noise)
   - **Deployments**: ☐ unchecked (no GitHub Pages, no deploy events on Institute repos; the empty section is noise)
4. If any state diverges, correct via the panel's checkboxes, then save.

**Why this is manual**: GitHub does not expose `hasReleasesEnabled` / `hasPackagesEnabled` / `hasDeploymentsEnabled` via REST or GraphQL as of 2026-04-29. The web UI's gear-icon panel uses an internal endpoint that is not public. `gh repo edit` has no flag for these toggles. The canonical source of truth (per [GH-REPO-060] schema's `sidebar:` block) records the intended state, but enforcement is currently manual at flip-time. When GitHub exposes the API, this rule becomes automatable.

**Cross-references**: [RELEASE-004] Stage 2 (visibility flip), [GH-REPO-054] (sidebar default state), [GH-REPO-060] (`.github/metadata.yaml` `sidebar:` block).

---

### [RELEASE-013] First-Publication Clean-History Procedure (Optional)

**Statement**: For first-public-flip packages where the principal wants the public repo to present as a fresh first publication (no working history of internal iteration), this rule defines an OPTIONAL squash + run-cleanup procedure. The procedure rewrites history (force-push) and deletes prior CI run records. It MUST be authorized via the settings.json force-push gate and applies only to first-public-flip; subsequent releases (0.2.0 etc.) accumulate history normally.

**When to apply**:

| Situation | Apply? |
|-----------|--------|
| First public flip + author wants clean "Initial publication" surface | Yes, optional |
| Second/subsequent release of an already-public package | No — would orphan tags / consumer-pinned references |
| Release with no working history that would benefit from squashing | No — pointless rewrite |
| Author indifferent to surface presentation | No — preserve history; cheaper |

**Procedure**:

1. **Confirm Phase 1+2+3 complete and CI green** on the current HEAD (do NOT squash a not-yet-validated state).
2. **Tag local backup ref** for recovery: `git tag backup/pre-squash <current-HEAD>`. Do NOT push the backup tag; local-only is the recovery mechanism.
3. **Identify the boundary**: the very first commit (typically `Initial commit`) preserves; everything since collapses.
   ```sh
   git log --oneline --reverse | head -1   # → the boundary commit
   ```
4. **Soft-reset** to the boundary commit, keeping all changes since in the index:
   ```sh
   git reset --soft <boundary-commit-sha>
   ```
5. **Re-commit** with a clean release-shaped message ("Initial publication of `<pkg>`" — NOT "release", which carries different connotations than the principal may want).
6. **Force-push** with `--force-with-lease` per the settings.json force-push gate (explicit per-action authorization).
7. **Delete prior CI run history** via `gh run list … | gh run delete` loop (one ID per call; shell-loop iteration combining IDs into one arg fails GitHub URL parsing). Keep the new run triggered by the force-push.
8. **Watch the new CI run complete** (the force-push triggers a fresh CI run on the new commit SHA). Confirm success.
9. **Delete the local backup tag** once the post-squash state is stable: `git tag -d backup/pre-squash`.

**Known pitfalls**:

- **Stuck queued runs**: workflow_dispatch runs queued while Actions was repo-disabled (e.g., dispatched pre-flip when Actions wasn't enabled at the repo level) can enter an unrecoverable queued state. `gh api -X DELETE /actions/runs/<id>` returns 403, `cancel` returns 500, `rerun` returns 403 ("already running"). Workaround: file a GitHub Community / support report; OR live with the orphaned run (it doesn't affect badges or new runs, just shows in the Actions tab queue). Pre-emptive: don't dispatch via `gh workflow run` while Actions is repo-disabled — see [RELEASE-014] (don't-dispatch-while-disabled rule).
- **Tags on the squashed history**: if any tags reference commits in the squashed range, the tags become orphaned. Squash BEFORE the first tag (typical first-publication case); if tags exist, the procedure does not apply.
- **Wording**: prefer "Initial publication" over "Initial release" in the squashed-commit message — "release" carries version-tagging connotations that may not apply to the squash itself.

**Cross-references**: [RELEASE-004] (per-action authorization gates). Force-push authorization is a settings.json gate.

---

### [RELEASE-014] Post-Flip First-Public-CI Baseline Discipline

**Statement**: After [RELEASE-004] Stage 2 (visibility flip private → public), the first public CI run MUST be evaluated at the **run-level** (`conclusion` field), NOT at the **job-level** (per-job status). Reactive source-patching on job-level failures of `continue-on-error: true` jobs is unnecessary churn that does NOT resolve the diagnostic and may add risk; the run-level conclusion is the gate. Additionally, before the first public CI run, the pre-flip baseline MUST verify that cohort-canonical lint configs (`.swiftlint.yml`, `.swift-format`) are present in the repo and match sibling cohort packages — strict-default lint without a `parent_config` directive produces hundreds of violations the disabled-manually pre-flip workflow hides, surfacing only after public flip + workflow re-enable.

**Procedure** (Stage 2 first-public-CI evaluation):

1. **Pre-flip lint-config presence check**: confirm `.swiftlint.yml` AND `.swift-format` (or their cohort-equivalent canonical files) are tracked AND match the sibling cohort's reference (verified by diff-or-checksum against the canonical reference per [GH-REPO-074] thin-caller schema). A missing or stale config produces post-flip lint storms.
2. **Watch the first public CI run** triggered by the visibility flip.
3. **Query run-level conclusion**: `gh run view <run-id> --json conclusion`. The `conclusion` field is the gate:
   - `success` — all gating jobs passed; gated `continue-on-error: true` job-level failures (e.g., Swift 6.4-dev nightly RegionIsolation) do NOT block the launch.
   - `failure` — at least one gating job failed; investigate the gating job specifically.
   - `cancelled` — runs cancelled by force-push or manual intervention; re-watch the new run.
4. **DO NOT reactive-patch on job-level failures of `continue-on-error: true` jobs**. The continue-on-error matrix is a deliberate gating decision; patching source for a moving-target diagnostic on a gated job:
   - May not resolve the diagnostic (the patch lands against a moving compiler target).
   - Adds churn to the launch SHA without changing the gate.
   - Risks introducing real defects in the patch.
   The disciplined response is to document the diagnostic as known + gated (e.g., a one-line note in package docs naming the nightly diagnostic) and proceed.

**Authorization-gate visibility lives at run-level, not job-level**: a workflow run with N jobs and 1 `continue-on-error: true` job is indistinguishable, at the GitHub PR-status surface, from a run with N gating jobs — both can report job-level failures. The `conclusion` field is the only place the distinction lives. Reactive source-patching on a job-level failure can patch the wrong target; if the patched job is gated, the patch was unnecessary churn.

**Composite:** lint-config presence (mechanical) + run-level conclusion check (mechanical, External: GitHub Actions API) + job-level filter for continue-on-error gating (mechanical) + diagnostic disposition decision (semantic).

**Cross-references**: [RELEASE-004] (per-action authorization gates), [RELEASE-011] (post-flip metadata sync), [CI-091] (uniform platform matrix), [GH-REPO-074] (thin-caller schema).

---

## Application Checklist

### Authoring a release-readiness brief

- [ ] Confirm the package is feature-complete and has at least one round of `/audit` against `Audits/audit.md`.
- [ ] Author `<package>/AUDIT-{VERSION}-release-readiness.md` following the four-phase structure per [RELEASE-001].
- [ ] If this is a pilot in a release cohort, add Phase 4 per [RELEASE-003] and confirm the backlog file at `swift-institute/Research/<package>-launch-skill-incorporation-backlog.md` exists and enumerates Tier 1 items.
- [ ] Enumerate locked decisions in the brief's "Parent Context" section; the agent investigating the brief MUST NOT re-deliberate them.

### Authoring a final pre-release scan

- [ ] Confirm at least one substantial-change set has landed since the release-readiness brief.
- [ ] Author `<package>/AUDIT-{VERSION}-final-pre-release-scan.md` following the seven-phase structure per [RELEASE-002].
- [ ] List the substantial-change sets explicitly in "Parent Context" so Phase 3 has the right scope.
- [ ] Set the "Do Not Touch" boundary explicitly per [RELEASE-002]; the investigating agent MUST NOT modify source code.

### Tagging

- [ ] Final pre-release scan returns GO or CONDITIONAL GO per [RELEASE-005].
- [ ] Each per-action gate from [RELEASE-004] receives its own principal authorization at the moment of execution.
- [ ] Pilot launches: the skill-incorporation backlog Tier 1 items are processed before the cohort's next package proceeds to its own audit.

---

## Cross-References

- **audit** skill — for systematic compliance scanning during Phase 2 of the brief.
- **swift-forums-review** skill — `[FREVIEW-*]` for forums-review pre-mortem and Phase 4 re-simulation of the scan.
- **skill-lifecycle** skill — for the discipline by which Tier 1 backlog items are landed in skills.
- **github-repository** skill — `[GH-REPO-*]` for repo metadata gates (description, topics, homepage, license auto-detection) checked in Phase 3. Must-load companion for publish/flip arcs per [RELEASE-017].
- **ci-cd-workflows** skill — `[CI-*]` for the thin-caller chain and Actions posture the [RELEASE-017] CI-signal vet checks. Must-load companion for publish/flip arcs per [RELEASE-017].
- **readme** skill — `[README-*]` for README readiness checks in Phase 3.
- **documentation** skill — `[DOC-*]` for DocC catalogue readiness checks in Phase 2.
- Reference implementations: `swift-carrier-primitives/AUDIT-0.1.0-release-readiness.md`, `swift-carrier-primitives/AUDIT-0.1.0-final-pre-release-scan.md`.
- Reference backlog: `swift-institute/Research/carrier-launch-skill-incorporation-backlog.md`.
