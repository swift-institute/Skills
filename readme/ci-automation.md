---
name: readme/ci-automation
description: |
  Author / automation boundary for README content across the family. Specifies
  which sections humans write, which CI generates, which CI lints, and the
  reporting shape (tracking-issue pattern mirroring sync-metadata-nightly).
  Forward-looking — the lint workflows specified here are not yet implemented;
  the existing orchestrator infrastructure they would extend IS in production.

layer: implementation

requires:
  - readme

applies_to:
  - swift-institute
  - swift-primitives
  - swift-standards
  - swift-foundations
  - swift-nl-wetgever
  - swift-us-nv-legislature
  - swift-law
  - rule-law
  - coenttb
# Amendment/changelog history: rationale archive (Readme Skill Rationale Archive) §Changelog-Provenance (and git history of this file).
---

# README CI/CD Contract

The contract between authors and automation for README content across the ecosystem. Codifies what humans write, what CI generates, what CI validates, and the reporting shape used when drift is detected.

Loaded on demand from the **readme** skill hub (`SKILL.md`). The two universal meta-rules — [README-023] Evaluator's Lens and [README-026] No Internal Rule-ID Citations — apply to README content; this file does not author content but specifies the lint and generation contracts that enforce the family rules.

**Scope**: All README files governed by Families A, C, E, F, G (per `SKILL.md`). Some rules apply to subsets — e.g., presence sweeps target the families with mandatory READMEs; inventory auto-generation targets only Family G leaf-tier profiles.

Full evicted rationale, worked examples, and provenance for this file: the rationale archive (`Readme Skill Rationale Archive`), referenced below.

---

## Voice

This file is an engineering specification, not a content authoring guide. The voice is the most technical in the skill family — it specifies workflows, file paths, JSON schemas, and orchestrator interactions. It is the only file in the family where filenames, GitHub Actions YAML excerpts, and command-line invocations are routine content.

---

## Existing Infrastructure (As of 2026-05-01)

The contracts in this file build on infrastructure already in production. Verified paths:

| Workflow / artifact | Location | Status |
|---|---|---|
| sync-metadata (reusable) | `swift-institute/.github/.github/workflows/sync-metadata.yml` | In production |
| sync-metadata-nightly (orchestrator) | `swift-institute/.github/.github/workflows/sync-metadata-nightly.yml` | In production |
| generate-metadata (reusable) | `swift-institute/.github/.github/workflows/generate-metadata.yml` | In production |
| link-check (reusable) | `swift-institute/.github/.github/workflows/link-check.yml` | In production |
| link-check-weekly (orchestrator) | `swift-institute/.github/.github/workflows/link-check-weekly.yml` | In production |
| swift-ci (reusable per-repo CI template) | `swift-institute/.github/.github/workflows/swift-ci.yml` | In production |
| swift-docs (reusable per-repo DocC build template) | `swift-institute/.github/.github/workflows/swift-docs.yml` | In production |
| format + lint (jobs inside swift-ci.yml, not standalone reusables — post-2026-05-10 consolidation per [CI-054]) | `swift-institute/.github/.github/workflows/swift-ci.yml` (`format`/`lint` jobs) | In production |
| swift-institute-bot GitHub App | (App credentials live in repo secrets) | In production |
| Tracking-issue reporting pattern | Issues filed in `swift-institute/.github` repo | In production |
| Per-repo CI (build/test/format/lint) + docs callers | Per-repo `.github/workflows/ci.yml` (two jobs: `ci`, `docs`) invoking the reusable templates above | In production |
| `.github/metadata.yaml` per repo | Per-repo `.github/metadata.yaml` | In production |
| `spec-titles.yaml` (heuristic seeds) | `swift-institute/.github/spec-titles.yaml` | In production |

The README-relevant lint and generation workflows specified in [README-161]–[README-166] are **not yet implemented**. The contracts below specify what they will look like when built; the rule status is "specified, pending implementation" unless explicitly marked otherwise.

The pattern they will follow is the existing reusable + orchestrator + tracking-issue shape — same auth (swift-institute-bot App), same output channel (tracking issue in `swift-institute/.github`), same scoping flags (`repo=owner/name` or `org=orgname`).

---

## Rules

### [README-160] Author / Automation Boundary

**Statement**: Every README section is owned by either an author or an automation. The boundary is fixed per family per section; both sides MUST respect it. CI MUST NOT generate content the author owns; the author MUST NOT manually edit content the CI generates (such manual edits will be overwritten on the next CI run).

**Boundary by family and section** (existing or specified):

| Family | Section | Owner | Status |
|---|---|---|---|
| All | H1 title | Author | Existing convention |
| All | One-liner | Author | Existing convention |
| All | License footer link | Author | Existing convention |
| E (sub-package) | Development status badge | Author | Existing convention |
| E (sub-package) | SPI badges | Auto (Swift Package Index renders the badge endpoint; author writes the URL) | Existing — SPI is upstream auto |
| E (sub-package) | CI badge | Auto (GitHub renders from workflow status; author writes the URL) | Existing — GH is upstream auto |
| E (sub-package) | Installation block | Author writes; CI lints version currency per [README-164] | Lint specified, pending |
| G (leaf-org profile) | Package catalog | Auto generates per [README-166] from `Package.swift` files in the org; author edits roles column | Specified, pending |
| G (leaf-org profile) | Architecture diagram | Author | Existing convention |
| B (local-disk grouping) | Sub-repo inventory | Auto could generate from `gh repo list <org>` per [README-166]; author edits roles column | Specified, pending |
| All | Internal cross-references | Auto could validate per [README-165] | Specified, pending |

**Decision test**: For each section in a README, can you point to the rule that says who owns it? If neither author nor automation has clear ownership, the section is unmaintained — assign ownership.

**Rationale**: Drift is the long-term cost of unmaintained sections; the explicit boundary lets each side trust the other's contributions and reduces the cost of regeneration and lint (full text: rationale archive §[README-160]).

**Cross-references**: [README-021] in `sub-package.md` (existing maintenance obligations); [README-166] (auto-generation rule).

---

### [README-161] Presence Sweep

**Statement**: A scheduled workflow MUST verify that every README the family rules require to exist actually exists. Missing READMEs SHOULD surface as a tracking issue in `swift-institute/.github`, mirroring the sync-metadata-nightly drift report shape.

**Specified contract** (pending implementation):

```yaml
# swift-institute/.github/.github/workflows/readme-presence-sweep.yml
# Reusable + scheduled (nightly + manual)
# For each scoped repo:
#   - check existence of <expected-paths> per family routing
#   - emit row to consolidated report
# Aggregate: open/update tracking issue "README presence sweep — YYYY-MM-DD"
```

**Required-presence matrix** (derived from family rules):

| Path | Family | Required? |
|---|---|---|
| `<user>/<user>/README.md` for every user account | A | MUST exist |
| `<org>/.github/profile/README.md` for every org | G | MUST exist |
| `<repo>/README.md` for every Swift package repo | E or F | MUST exist |
| `<repo>/README.md` for every workflow/process repo | C | MUST exist |
| `~/Developer/<org>/README.md` for every clone-mirror directory | B | SHOULD exist |

**Possibly vestigial — pending cleanup decision (principal flagged 2026-05-01)**:

The directories `~/Developer/rule-law/`, `~/Developer/swift-nl-wetgever/`, and `~/Developer/swift-us-nv-legislature/` are each single GH repos on disk (have own `.git/`) whose CLAUDE.md descriptions imply they hold large package collections ("1057 statute packages", "820 NRS packages", "Legal encoding ecosystem home"). The principal has indicated this on-disk structure may be vestigial — it does not necessarily reflect the current intended topology for the legal domain. The presence sweep should NOT add these to the missing-README list until the topology is resolved:

- `~/Developer/swift-law/README.md` — exists (3-line stub); reclassification depends on whether the legal-domain topology is being kept, updated, or retired.
- `~/Developer/swift-nl-wetgever/README.md` — pending topology decision.
- `~/Developer/swift-us-nv-legislature/README.md` — pending topology decision.
- `~/Developer/rule-law/README.md` — pending topology decision.
- Any `*/.github/profile/README.md` for these orgs — pending verification that the corresponding GH org exists separately.

When the principal resolves the legal-domain topology, the corresponding family-routing rules apply (Family E or F per-repo if they remain single repos; Family G profile if a corresponding GH org exists separately).

**Rationale**: Family rules without enforcement become aspirational; the nightly sweep mirrors the existing sync-metadata-nightly pattern, making the workflow cheap to add and the reporting cadence familiar. (Known state of Family G org profiles at the 2026-05-01 inaugural-sweep baseline: rationale archive §[README-161].)

**Cross-references**: [README-167] (reporting shape); existing `sync-metadata-nightly.yml`.

---

### [README-162] Structure Linter Contract

**Statement**: A reusable workflow SHOULD verify each README satisfies the structural rules of its family — required sections present, section ordering correct, badge order matches [README-005], H1 present and unique, language tags on all code blocks per [README-017]. Findings SHOULD surface as PR check failures (when run on a PR) or as a tracking issue (when run nightly).

**Composite:** per-rule predicate set (mechanical) + per-family aggregation (mechanical) + composite-violation flagging (hybrid). (`**API-Gap:**` annotation already documents workflow-not-yet-implemented status; out of scope for this annotation pass.)

**Specified contract** (pending implementation):

```yaml
# swift-institute/.github/.github/workflows/lint-readme-structure.yml
# Reusable + workflow_dispatch
# Inputs: family (auto-detect from path) or explicit family override
# Output: per-rule pass/fail; failed rules listed with file:line and the violated rule
```

**Detection rules** (the linter should encode these — derived from family rules):

| Family | Lint check | Source rule |
|---|---|---|
| All | One H1 per file | [README-017] |
| All | All code blocks have language tag | [README-017] |
| All | No `[README-*]` or `[XX-NNN]` rule-IDs in prose | [README-026] |
| E | Title + badge + one-liner present in first ~10 lines | [README-001] |
| E | Development status badge first; SPI badges second; CI badge optional last | [README-005] |
| E | One-liner does not start with "A Swift package for …" | [README-006] |
| E | Required sections present per maturity tier | [README-002] |
| E | Composition-claim names match Package.swift dep set (or carry "among others") | [README-006] (composition-claim completeness) |
| F | `> **Status: <value>** — explanation` block present in first 5 lines | [README-150] |
| F | Status value is one of {Pre-implementation, Namespace-reservation, Unnecessary, Archived} | [README-151] |
| C | No installation block, no badges, no Quick Start | [README-137] |
| C | Length within 30–80 lines | [README-138] |
| G | No installation block | [README-116] |
| G | Tier-specific structural rules | [README-100..114] (per-tier) |
| G | Count-claim consistency (1-liner / opening / footer / catalog row count) | [README-006], [README-111] |

**Count-claim consistency check** (the highest-leverage cross-section lint, MUST fire on first run):

When an org profile cites "N packages" in the 1-liner, opening, footer, OR catalog header, the linter MUST verify all citations agree on N AND that N equals the actual catalog row count. The check fires across these four citation sites whenever any of them names a numeric package count.

| Citation site | Lint check |
|---|---|
| 1-liner ("Catalog of N packages") | N matches catalog-table row count |
| Opening paragraph ("organized across … N packages") | N matches catalog-table row count |
| Footer / closing ("listing all N packages") | N matches catalog-table row count |
| Catalog table | Row count is the source-of-truth N for this README |

A mismatch (e.g., 1-liner says 129, opening says 130, table has 137 rows) MUST fail the lint. The detection is grep + per-section count + cross-comparison; the fix is mechanical (the catalog table is authoritative). (Worked example — the 2026-05-01 swift-foundations origin incident: rationale archive §[README-162].)

**Rationale**: The structural linter encodes the family rules so authors get immediate feedback on PR rather than during manual audit.

**Constraints**:

- The linter MUST be written so it can extend the lychee orchestrator pattern (Python or shell, runs in the same Linux runner image, reports via the same tracking-issue shape).
- The linter MUST NOT auto-fix — fixes that destroy author intent (e.g., reordering rule violations into "correct" places without understanding context) are worse than no automation.
- New family rules added in future skill versions MUST add their checks to the linter as part of the same change.

**Cross-references**: [README-167] (reporting shape); [README-160] (boundary — lint is on the automation side); existing `link-check.yml` orchestrator pattern.

---

### [README-163] Badge Format Validator

**Statement**: A reusable workflow SHOULD verify badge URLs match the canonical formats specified in [README-003], [README-004], [README-005]. Validation covers URL shape, status values, and SPI endpoint structure.

**Specified contract** (pending implementation, often combined with [README-162] in a single workflow):

| Badge | Validation |
|---|---|
| Development status | URL matches `https://img.shields.io/badge/status-<value>-<color>.svg` where `<value>` is one of `active--development`, `stable`, `maintenance`, `experimental` and color matches the [README-003] table |
| CI | URL matches `https://github.com/<org>/<repo>/workflows/CI/badge.svg`; the linked workflow file MUST exist |
| SPI Swift versions | URL matches `https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F<owner>%2F<repo>%2Fbadge%3Ftype%3Dswift-versions` |
| SPI platforms | URL matches the same shape with `type%3Dplatforms` |
| Other badges | Free-form; lint warns if status value or color doesn't match the [README-003] vocabulary |

**Rationale**: Badges drift silently — a copy-pasted badge with the wrong owner/repo or a fabricated status value renders fine but signals incorrect package state; SPI endpoint URLs are especially easy to copy wrong (full text: rationale archive §[README-163]).

**Cross-references**: [README-003], [README-004], [README-005].

---

### [README-164] Installation-Snippet Currency

**Statement**: A reusable workflow SHOULD compare the version reference in a sub-package README's installation block against the latest tag of that package's GitHub repo. Drift (README cites `from: "0.1.0"` when the latest tag is `0.3.0`) SHOULD surface as a low-priority finding (warning, not error).

**Specified contract** (pending implementation):

| Input | Source |
|---|---|
| README installation block version | Parse `from: "X.Y.Z"` or `exact: "X.Y.Z"` from the README's first ` ```swift ... ``` ` block following an `## Installation` heading |
| Latest published tag | `gh release list --repo <owner>/<repo> --limit 1` or `gh api repos/<owner>/<repo>/tags?per_page=1` |
| Drift threshold | Minor or major version drift = warning. Patch drift = no finding. |

**Output shape**:

```
[INFO] swift-property-primitives: README cites 0.1.0; latest tag is 0.3.1 (1 minor version behind)
[WARN] swift-buffer-primitives: README cites 0.1.0; latest tag is 1.0.0 (major version drift — README likely stale)
```

**Rationale**: [README-021]'s installation-currency obligation is unreliable to enforce manually across many packages; the currency check surfaces drift cohort-wide on a regular cadence (full text: rationale archive §[README-164]).

**Cross-references**: [README-021] in `sub-package.md`; [README-008] in `sub-package.md`.

---

### [README-165] Cross-Repo Path Link Validator

**Statement**: A reusable workflow SHOULD validate cross-repo path links in READMEs that reference sibling repos via local paths (e.g., `../swift-buffer-primitives/Sources/...` or `~/Developer/swift-primitives/...`). The existing lychee link-check excludes `file://` URLs deliberately; this validator complements it for the workspace's actual cross-repo path style.

**Specified contract** (pending implementation):

| Pattern | Resolution |
|---|---|
| `[text](../<sibling-repo>/<path>)` | Validate `<sibling-repo>` is a real GH repo in the same org; `<path>` exists in that repo's main branch |
| `[text](~/Developer/<org>/<repo>/<path>)` | Treat the `~/Developer/` prefix as a clone-mirror reference; resolve against `<org>/<repo>` on GitHub |
| `[text](./<path>)` | Existing same-repo link; lychee already validates |
| `[text](https://github.com/<org>/<repo>/...)` | Lychee already validates |

**Rationale**: Filesystem-relative cross-repo links don't resolve on GitHub — they should be rewritten as fully-qualified `https://github.com/...` URLs (preferred) or flagged as workspace-only references; the validator surfaces both cases (full text: rationale archive §[README-165]).

**Cross-references**: existing `link-check.yml` (handles HTTP URLs); [README-014] in `sub-package.md` (Related Packages section's public+tagged constraint, related discipline).

---

### [README-166] Inventory Auto-Generation

**Statement**: For Family G leaf-org profiles ([README-111]), the package inventory table SHOULD be machine-generated from the org's repo list and per-repo `Package.swift` files. The author edits the roles column and the grouping structure; the inventory's name/URL/visibility columns regenerate from source-of-truth. Following the 2026-07-02 revision of [README-111], generation targets the small-org (≤ ~20 repos) full-table form and the mechanical columns of curated Start-here tables; exhaustive link-walls for large orgs are no longer a generation target.

**Specified contract** (pending implementation):

```yaml
# swift-institute/.github/.github/workflows/generate-readme-inventory.yml
# Reusable + workflow_dispatch
# Input: target_repo (the repo holding the README), target_path (e.g., .github/profile/README.md), org (the org to inventory)
# Process:
#   1. gh repo list <org> → enumerate repos with name, visibility, description
#   2. For each repo: clone shallow, parse Package.swift, extract product names
#   3. Read target README's existing inventory; preserve roles/grouping; regenerate name/URL/visibility columns
#   4. Open PR with regenerated README
```

**Boundary** (per [README-160]):

| Inventory column | Owner |
|---|---|
| Package name | Auto (from `gh repo list`) |
| Package URL (link target) | Auto (constructed from `<org>/<name>`) |
| Visibility (Public / Private / Local-only) | Auto (from `gh repo list --json visibility`) |
| Role (1-line description) | Author |
| Tier / domain grouping (which subsection the row belongs to) | Author |

**Rationale**: Hand-maintaining a large org inventory is brittle; auto-generating the structural columns while the author owns roles/grouping preserves editorial value and removes the maintenance burden, with PR-based regeneration keeping a human in the loop (full text: rationale archive §[README-166]).

**Cross-references**: [README-111]; existing `sync-metadata` pattern.

---

### [README-167] Reporting Shape

**Statement**: README-related CI workflows MUST report findings using the existing tracking-issue pattern: a single tracking issue per workflow, opened or updated idempotently in `swift-institute/.github` (or the equivalent governance repo for non-swift-institute orgs).

**Pattern** (mirrors `sync-metadata-nightly.yml` and `link-check-weekly.yml`):

| Element | Convention |
|---|---|
| Issue location | `swift-institute/.github` (default) or per-org governance repo |
| Issue title | `<Workflow-name> — <YYYY-MM-DD>` (e.g., `README presence sweep — 2026-05-01`) |
| Idempotency key | Workflow name + week (or month, depending on cadence) — repeated runs update the same issue, not open new ones |
| Body shape | Markdown, with per-repo or per-rule sections; closes-cleanly when no findings |
| Auto-close | When the next run finds zero issues, the tracking issue is closed; reopens when findings recur |
| Auth | swift-institute-bot GitHub App (existing) |

**Rationale**: Maintainers already triage tracking issues from sync-metadata-nightly and link-check-weekly; the same channel keeps cognitive load low and the idempotent update pattern prevents notification noise (full text: rationale archive §[README-167]).

**Constraints**:

- The reporting workflow MUST NOT email or chat-notify by default. Tracking issues are the canonical channel.
- High-severity findings (e.g., a leaf-tier org profile is a 1-line stub) MAY be flagged with the `priority/high` label; the label drives no automated action but informs human triage.

**Cross-references**: existing `sync-metadata-nightly.yml`, `link-check-weekly.yml`; `feedback_engagement_test_only_phase.md` (related discipline: drafts only, no auto-publish).

---

### [README-168] Discussion-link auto-generation and validation

**Statement**: The `sync-discussion-threads.yml` workflow per
**github-repository** [GH-REPO-092] is responsible for keeping every public
Family E package's README "Community" section synchronized with the
package's `.github/metadata.yaml` `discussion:` field per [README-040] in
`sub-package.md`.

**Validation rules** (run on every sync invocation, regardless of `create`
flag):

| Check | Trigger | Outcome |
|---|---|---|
| Marker block presence | README missing `<!-- BEGIN: discussion -->` block on a public Family E package | Defect; tracking issue per [README-167] |
| URL match | `metadata.yaml.discussion` set BUT marker block doesn't link to that URL | Defect; auto-fixed by next sync (or surfaced as PR) |
| Pre-flip placeholder | `metadata.yaml.discussion` empty AND marker block ≠ placeholder text | Defect; auto-fixed |
| URL resolves | URL set BUT GitHub returns 404 / archived | Defect; tracking issue |

**Reporting shape**: drift surfaces in the same nightly tracking issue as
[README-167] (no separate issue stream) — keeps the maintainer's attention
surface unified.

**Auto-generation discipline**: the marker block is the ONLY README
content auto-generated by this workflow. Any edits inside the markers are
reverted on the next sync. Author edits BEFORE `<!-- BEGIN: discussion -->`
or AFTER `<!-- END: discussion -->` are preserved.

**Cross-references**: [README-040] in `sub-package.md` (the Community
section structural rule this workflow targets), [README-160]
(author/automation boundary), [README-167] (reporting shape),
**github-repository** [GH-REPO-090..093]. (Provenance: rationale archive §[README-168].)

---

### [README-169] (reserved)

---

### [README-170] Composed-Example Empirical Validation

**Statement**: When a README example composes ≥2 distinct ecosystem types in a single code block (e.g., `Source.Location` + `Diagnostic.Record` + `Lint.Rule.Protocol` in one snippet), `swiftc -parse` validation alone is structurally insufficient. The validation discipline MUST cite (a) a real call-site reference for each composed type — `<package>/Sources/<path>/<file>.swift:<line>` — confirming the example's API shapes match the call site's API shapes, OR (b) a full `swift build` of an extracted scratch package containing the example, demonstrating the example type-checks against the real type definitions.

`swiftc -parse` validates that the example is grammatically Swift; it does NOT validate that the example uses real APIs in their real shapes — a composed example can parse and still not compile against the real types. (Full "why parse-only is structurally insufficient" analysis: rationale archive §[README-170].)

**Validation matrix**:

| Example shape | Validation discipline |
|---------------|------------------------|
| Single type, ≤2 method calls (e.g., `UUID().uuidString`) | `swiftc -parse` is sufficient |
| Composed example (≥2 ecosystem types) | (a) Cite real call-site for each composed type, OR (b) extract to scratch SwiftPM package and run `swift build` |
| Quick Start examples (high-visibility, evaluator-facing) | (b) — full build, regardless of complexity |
| Code blocks inside narrative (lower-visibility) | (a) — real call-site citation per composed type |

**Procedure**:

1. At README authoring time, identify each code block's composition class.
2. For composed examples, before declaring the README "validated," locate each composed type's nearest real call site in the ecosystem (`grep -rn "<typename>(" <ecosystem>/Sources/`) and verify the README's invocation shape matches the call site's shape.
3. For Quick Start examples, additionally extract the example to a scratch SwiftPM package whose `Package.swift` declares deps on every composed type's owning package; run `swift build`.
4. Document the validation report in the commit message or PR description: list each composed type + its cited real call-site OR the extracted scratch-package path + `swift build` result.

**Rationale**: Per-example call-site discipline catches non-compiling examples at authoring time, composing with [RELEASE-007]'s publication-gate check; the 30-second grep per composed type is strictly cheaper than post-publication rework (full text, origin incident, and the 4-of-5 swift-linter cohort finding: rationale archive §[README-170]).

**Cross-references**: [README-009], [README-022], [RELEASE-007]

---

## Implementation Order

When the lint and generation workflows are built, the recommended ordering is highest-leverage-first:

1. **[README-161] Presence sweep** — cheapest to build (file existence check), highest immediate value (catches the 9 missing READMEs identified in the rule body). Adds a single workflow + nightly orchestrator + tracking-issue. Estimated effort: low.
2. **[README-162] Structure linter** — moderate effort. Encodes the structural rules of each family. Estimated effort: medium; recommend starting with Family E (largest cohort) and adding Family C, F, G as additional checks.
3. **[README-167] Reporting shape** — implemented inline with [README-161]; reusable across all subsequent workflows.
4. **[README-163] Badge format validator** — combine with the structure linter into a single workflow file; minimal incremental cost.
5. **[README-166] Inventory auto-generation** — higher effort (requires parsing `Package.swift` and managing PR-based regeneration); defer until the inventory drift becomes a maintenance pain point.
6. **[README-164] Installation-snippet currency** — moderate effort; deferrable.
7. **[README-165] Cross-repo path link validator** — lowest priority; the cross-repo path link pattern is uncommon in current READMEs.

Each entry corresponds to a real workflow file path under `swift-institute/.github/.github/workflows/`; the convention and auth model are already in place for them to slot in.

---

## Cross-References

- **readme** skill hub (`SKILL.md`) — Family routing matrix, universal meta-rules ([README-023], [README-026]).
- **readme/sub-package** sibling — [README-021] maintenance obligations that the currency lint enforces.
- **github-repository** skill — `.github/metadata.yaml` convention; the existing sync-metadata orchestrator pattern this file's specifications mirror.
- Existing infrastructure (verified 2026-05-01):
  - `swift-institute/.github/.github/workflows/sync-metadata.yml` (reusable)
  - `swift-institute/.github/.github/workflows/sync-metadata-nightly.yml` (orchestrator)
  - `swift-institute/.github/.github/workflows/generate-metadata.yml` (reusable)
  - `swift-institute/.github/.github/workflows/link-check.yml` (reusable)
  - `swift-institute/.github/.github/workflows/link-check-weekly.yml` (orchestrator)
- Memory: `feedback_latest_versions_only.md` — workflow action/runner-image pin discipline that any new workflow MUST follow.
- Memory: `project_per_repo_vs_centralized_ci.md` — partition rule (per-repo workflow vs centralized orchestrator); README workflows are centralized per the partition.
- Memory: `project_lychee_orchestrator_tuning.md` — non-obvious tuning lessons from the link-check orchestrator that the README workflows should reuse.
