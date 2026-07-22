---
name: github-repository
description: |
  GitHub repo metadata: description, topics, homepage, license, settings, discussion threads, per-package .github/metadata.yaml + centralized reusable propagation.
  Apply when authoring or auditing GitHub-side metadata for any ecosystem repo.

layer: implementation

requires:
  - swift-institute
  - readme

applies_to:
  - swift-institute
  - swift-primitives
  - swift-standards
  - swift-foundations
  - github-repository-metadata

created: 2026-04-29
---

# GitHub Repository

GitHub-side metadata for repositories across the Swift Institute ecosystem.
Governs per-repo description, topics, homepage URL, license, and repo
settings; defines the canonical `.github/metadata.yaml` source-of-truth file
and the centralized reusable workflows in `swift-institute/.github/.github/workflows/` (`sync-metadata.yml`, `sync-metadata-nightly.yml`, `metadata-pr-preview.yml`, `generate-metadata.yml`).

**Authority**: `swift-institute/Research/github-metadata-harmonization.md` (Tier 2 recommendation, 2026-04-29).

**Scope boundary**: this skill governs **per-repository** metadata. Org-
scoped community-health files (FUNDING.yml, CODE_OF_CONDUCT.md, etc.) are
governed separately by `Scripts/sync-community-health.sh`; a future
`github-org` skill will codify those conventions.

---

## Meta-Rules

### [GH-REPO-001] Discovery-Lens
**Statement**: Every metadata field MUST serve a discovering reader's
question — *"what is this repo, and would I look further?"* Content that does
not survive the discovery-lens belongs in the README, the package's DocC, or
not at all.

### [GH-REPO-002] Single-Source Discipline
**Statement**: The repo's `.github/metadata.yaml` is the canonical
source for description / topics / homepage / settings. The GitHub-side state
is a derived view, propagated by the centralized `sync-metadata.yml`
reusable workflow in `swift-institute/.github`. Editing GitHub metadata
directly (via the web UI or `gh repo edit` outside the workflow) is
forbidden — drift is detected and reverted automatically by the next sync
run.

### [GH-REPO-003] All-active scope
**Statement**: Metadata work applies to all non-archived repos across the
17 ecosystem orgs (public + private). The standard does not gate on
visibility — `.github/metadata.yaml` MAY be authored at any time, and
the centralized sync workflow propagates it. Private-repo metadata is
not user-facing-load-bearing but the YAML being in place pre-flip means
the private→public flip moment requires no metadata-specific work
beyond "verify `.github/metadata.yaml` is present and current" — the
YAML is typically already there from pre-flip authoring.

---

## Description

### [GH-REPO-010] Description required on public repos
**Statement**: Every public production repo MUST carry a non-empty
`description`. Empty scaffold / namespace-reservation repos MUST use the
truthful reservation form — `Namespace reserved for «domain phrase» in
Swift.` — never a capability claim the repo cannot yet back (principal
direction 2026-07-02; 40+ scaffold descriptions converted that day).

### [GH-REPO-011] Description templates by package class
**Statement**: Every public repo's description MUST fill exactly
one of the templates defined in `Research/github-metadata-harmonization.md`
§ 3.1.1. Templates are fill-in-the-blank — the maintainer authors the slot
value(s) only; the rest of the description is fixed text rendered by the
template. Class detection is mechanical from the org + repo name; template
selection is mechanical from the class.

| Class | Template |
|---|---|
| L1 primitive / L3 foundation / L4 component | `«Content phrase» for Swift.` (or `«…» in Swift.` when the phrase already contains "for") — describes the types/protocols/values the package exposes. **Do NOT repeat the layer word** (no "primitives"/"foundations"/"components") — Apple convention; redundant with package name + topic tag. |
| L2 single-spec | `Swift implementation of «AUTHORITY-FULL» «N»: «Spec Title».` |
| L2 meta-package | `«Family» meta-package combining «Specs» in Swift.` |
| L2 named standard | `Swift implementation of «AUTHORITY-FULL» «Standard Name».` |
| L3 integration | `«Addon» for swift-«base».` |
| Org `.github` | `Organization-level community-health defaults for «OrgName».` |
| Namespace-reservation scaffold | `Namespace reserved for «domain phrase» in Swift.` |
| Institute meta repo | `«Corpus purpose» for the Swift Institute ecosystem («Normativity»).` |

The `sync-metadata.yml` workflow validates the rendered description matches
its template; descriptions that don't match are a defect.

**Content-phrase richness (added 2026-07-02)**: the `«Content phrase»` slot
MUST name the package's distinctive capability, not merely restate the repo
name. Vacuous single-noun phrases ("Async for Swift.", "Dual for Swift.",
"Parser types for Swift.") are forbidden — repeated across an org they render
as templated bulk in repo listings, pins, and search, and the description is
the only prose those surfaces show. Target shape: *what it is + the one
distinguishing property*, still inside the class template. Correct:
"Phantom-typed value wrappers for zero-cost type safety in Swift.",
"Thread-safe compute-if-absent async cache for Swift." Incorrect:
"Tagged for Swift.", "Cache for Swift." Provenance: independent posture
audit + principal direction, 2026-07-02.

### [GH-REPO-012] Specification-mirroring for L2
**Statement**: L2 standards-package descriptions MUST mirror the
specification's full name and title verbatim per [API-NAME-003] (extending
the type-naming rule to the GitHub description). The `«Spec Title»` slot
in the L2 single-spec template ([GH-REPO-011]) is sourced from
`swift-institute/.github/spec-titles.yaml` per [GH-REPO-014]. Example:
`swift-rfc-5234` → "Swift implementation of RFC 5234: Augmented BNF for
Syntax Specifications."

### [GH-REPO-014] Spec-title lookup table
**Statement**: The canonical spec-title source for L2 single-spec
descriptions is `swift-institute/.github/spec-titles.yaml`. Schema is a
two-level map keyed on authority code (`rfc`, `iso`, `ieee`, `iec`, `w3c`,
`whatwg`, `ecma`, `incits`) then spec-id (`'5234'`, `'8601'`, `'4-1986'`,
etc.) → spec title string. Maintainer adds an entry whenever a new spec-id
package enters the ecosystem; the entry lands in the same PR that creates
the new repo's `.github/metadata.yaml`. The `generate-metadata.yml`
workflow reads the table and renders descriptions automatically. Drift
between a YAML's rendered description and the table is a defect surfaced
by `sync-metadata.yml`'s validation pass.

### [GH-REPO-013] README ↔ description mirroring
**Statement**: When a repo has both a README and a GitHub
description, the description SHOULD mirror the README's first-paragraph
one-liner truncated to fit GitHub's 350-char limit. Cross-references
[README-006] (opening contract).

---

## Topics

### [GH-REPO-020] Recommended topic shape
**Statement**: Topics are per-repo editorial per [GH-REPO-021] — each repo
establishes its own tags based on its content. The following shape is
RECOMMENDED for public production repos as a starting point, not enforced
beyond the format constraints in [GH-REPO-022] and the forbidden-values
list in [GH-REPO-024]:

- one **bare** layer tag where applicable (`primitives` / `standards` /
  `foundations` / `components` — no `swift-` prefix; the prefix repeats
  the org name and is redundant per Q2 resolution 2026-04-29),
- when the package implements a named specification, an authority tag
  (`rfc` / `iso` / `ieee` / `iec` / `w3c` / `whatwg` / `ecma` / `incits`)
  plus a matching spec-id tag (`rfc-5234`, `iso-8601`, `ieee-754`,
  `incits-4-1986`, etc.),
- 1–3 domain tags chosen by the repo author to describe the content
  (open vocabulary; see [GH-REPO-021]).

The `swift` topic is conventionally omitted (redundant with the package
name's `swift-` prefix and the org context — Apple's own
`swift-collections`, `swift-system`, `swift-numerics`, `swift-atomics`
all omit it). Specific forbidden values are in [GH-REPO-024].

### [GH-REPO-021] Topics are per-repo editorial — open vocabulary
**Statement**: Topics are per-repo editorial. Each repo establishes its
own tags based on its content. There is no closed vocabulary, no central
registry of "allowed" domain tags, and no governance ceremony required
to introduce a new tag.

The schema at `swift-institute/.github/metadata-schema.json` validates
SHAPE only (kebab-case and length per [GH-REPO-022], uniqueness within
a repo, count cap per the schema's `maxItems`). Vocabulary is open. Per
[GH-REPO-024] a small set of specific values is forbidden (redundant
prefixes, version-specific tags, marketing tones); everything else is at
the repo author's discretion.

**Lint enforcement**: The `validate-github-metadata.yml` reusable workflow
validates each repo's `.github/metadata.yaml` against
`metadata-schema.json` (using `python3 -m jsonschema` or equivalent). The
schema enforces shape; vocabulary is open. Topics that fail schema
validation are exclusively shape failures (typo, length, count) or
forbidden-value failures per [GH-REPO-024] — the fix is editing the
metadata.yaml. Added Wave 2b 2026-05-10; revised Wave 2b finalization
2026-05-10 per Decision 6 architectural pivot; revised again 2026-05-10
per principal direction retracting the closed enum entirely.

### [GH-REPO-022] Topic format constraints
**Statement**: Topic values MUST be lowercase, kebab-case, ≤ 50
characters (GitHub limit). Spec-id tags follow the spec authority's natural
identifier in kebab-case (e.g., `rfc-5234` not `rfc5234`; `ieee-754` not
`ieee_754`).

### [GH-REPO-023] Topic count range
**Statement**: Topic count MUST be between 2 and 10 inclusive on
production packages. The lower bound is 2 — one bare layer tag
([GH-REPO-020]) plus at least one domain tag; a lone layer tag is
insufficient signal. 3+ topics are RECOMMENDED where a package spans
multiple domains, but **atomic single-concept packages — whose name *is*
their one domain** (e.g. `swift-tree-primitives` → `[primitives, tree]`,
`swift-html-render` → `[foundations, html]`) legitimately carry exactly 2;
padding them to 3 forces a noise tag. Upper bound 10 = the empirical cap on
signal-density observed in apple/swift-* topics. Org meta-repos
([GH-REPO-080]) are exempt.

**3→2 relaxation (2026-07-03)**: a topic-count audit found 237 non-archived
repos (156 public: 104 primitives + 52 foundations) carrying exactly
`[layer, single-domain]` — the honest tag set for an atomic package. The
prior floor of 3 ("layer + 2 domain") assumed two domain tags are always
available; for single-concept packages the second is noise. Relaxed per
principal direction; a *relaxation*, so previously-conforming repos (3+) are
unaffected. NOTE — `metadata-schema.json` currently declares `topics`
`minItems: 0, maxItems: 20`, which neither enforced the old floor nor matches
this range; reconciling the schema bounds to 2–10 is deferred (25 repos carry
0 topics and 1 carries 12, so tightening needs its own remediation pass).

### [GH-REPO-024] Forbidden topics
**Statement**: The following topic values are forbidden:
- `swift` — redundant with package-name `swift-` prefix and org context
  (per [GH-REPO-020]);
- `swift-primitives` / `swift-standards` / `swift-foundations` /
  `swift-components` — redundant `swift-` prefix; use bare layer tag;
- `swift-package` / `spm` — redundant;
- `swift5` / `swift6` / `swift7` — version-specific tags go stale;
- the maintainer's personal handle (`coenttb`, etc.) on Institute repos;
- marketing-tone tags (`fast`, `blazing`, `awesome`, `delightful`).

---

## Homepage

### [GH-REPO-030] Homepage URL by repo class
**Statement**: Homepage URL is chosen by repo class. No-trailing-
slash form per Q3 resolution 2026-04-29.

| Class | URL |
|---|---|
| Public production package on Swift Package Index | `https://swiftpackageindex.com/{org}/{repo}/documentation` |
| Public production package not yet on SPI | `https://swift-institute.org` |
| Org `.github` community-health repo | empty |
| Institute meta repo (`Research`, `Experiments`, `Skills`, ...) | `https://swift-institute.org` |

### [GH-REPO-031] Personal-URL prohibition
**Statement**: The maintainer's personal homepage (e.g.,
`https://coenttb.com`) MUST NOT appear in the `homepageUrl` field of any
public repo across the 17 ecosystem orgs. The 47 currently-existing
violations (per `Research/github-metadata-harmonization.md` § 1.5) are
remediated as part of the rollout per § 5 Phase 3-4.

---

## License

### [GH-REPO-040] LICENSE.md required on package repos; auto-detection MUST succeed
**Statement**: Every public **package** repo MUST carry a top-level
`LICENSE.md` file. GitHub's license auto-detection MUST succeed (i.e., the
`licenseInfo` field returned by `gh repo view --json licenseInfo` MUST NOT
be `null`). If auto-detection fails, fix the LICENSE filename or content
rather than the metadata.

**`.github` org repos are exempt** per Q4 resolution 2026-04-29: they hold
community-health files (FUNDING.yml, CODE_OF_CONDUCT.md, etc.) that carry
their license via the canonical sources in `swift-institute/.github`.
GitHub does not support org-level license inheritance, but the absence is
conventionally unremarkable for community-health repos. See [GH-REPO-080].

### [GH-REPO-041] Apache 2.0 for L1-L3
**Statement**: L1 (primitives) / L2 (standards) / L3 (foundations)
packages MUST be licensed under Apache 2.0 per the architecture in
`swift-institute.md`. L4-L5 (components / applications) license is at the
maintainer's discretion.

---

## Repo settings

### [GH-REPO-050] hasIssuesEnabled = true
**Statement**: Every public repo MUST have `hasIssuesEnabled =
true`. Issues are the canonical bug-report and feature-request surface;
disabling them violates the Institute's contributor-engagement posture.

### [GH-REPO-051] hasDiscussionsEnabled = false
**Statement**: Every public repo MUST have `hasDiscussionsEnabled
= false` unless the principal explicitly authorizes discussions on a
specific repo. If discussions become valuable across the ecosystem, they
centralize at `swift-institute/.github` or `swift-institute/swift-institute.org`
rather than per-package.

### [GH-REPO-052] hasWikiEnabled = false
**Statement**: Every public repo MUST have `hasWikiEnabled =
false`. Wiki content drifts faster than DocC content rendered from source;
the Institute does not maintain wikis anywhere; the default-on state risks
accidental wiki authorship by external contributors.

### [GH-REPO-053] defaultBranch = main
**Statement**: Every repo's default branch MUST be `main`.
Experiment branches that became default by accident (e.g., the existing
`experiment/typed-algebra-dsl` outlier) are remediated via
`gh repo edit --default-branch main`.

### [GH-REPO-054] Sidebar visibility — Packages and Deployments off by default; Releases on
**Statement**: On every public repo, the gear-icon "About" sidebar
checkboxes default as follows:

| Section | Default | Rationale |
|---|---|---|
| **Releases** | **ON** | Every Swift package publishes tagged releases; consumers navigate here to find them. |
| **Packages** | OFF | Institute packages distribute via Swift Package Manager (Git tag → SPI), not via GitHub Packages registry. The empty "Publish your first package" link directs visitors at nonexistent functionality. |
| **Deployments** | OFF | Institute packages do not run GitHub Actions deployments (no GitHub Pages, no deploy events). The empty section is noise. |

Override via `.github/metadata.yaml`'s `sidebar:` block per [GH-REPO-060]
when a specific package genuinely publishes Packages or Deployments.

**API gap**: GitHub does not expose these toggles via REST or GraphQL as
of 2026-04-29. `gh repo edit` has no flag for them; `UpdateRepositoryInput`
does not include `hasReleasesEnabled` / `hasPackagesEnabled` /
`hasDeploymentsEnabled` fields. The web UI's gear-icon panel uses an
internal endpoint that is not public. **Enforcement is currently manual**
(one click-through per repo via the gear icon).

The `.github/metadata.yaml` schema includes a `sidebar:` block recording
the intended state per [GH-REPO-060]; once GitHub exposes the API, the
sync workflow will read it and enforce. Until then, the YAML serves as
the audit-able record of intended state and the manual click is required
at public-flip time.

### [GH-REPO-055] hasProjectsEnabled = false
**Statement**: Every repo MUST have `hasProjectsEnabled = false`. Institute
work is tracked in code, skills, and `swift-institute/Issues` — not in
per-repo GitHub Projects boards. The default-on state (GitHub enables
Projects on every new repo) surfaces an empty "Projects" tab that directs
visitors at nonexistent planning boards and invites accidental board
creation by external contributors. This is the direct analog of the wiki
default-off rule ([GH-REPO-052]): a default-on GitHub feature the Institute
uses nowhere. A per-repo override to `true` is permitted only when the
principal explicitly authorizes a Projects board on a specific repo (the
[GH-REPO-094] hub-override pattern).

**Managed field**: unlike the sidebar toggles of [GH-REPO-054], the Projects
toggle IS exposed by `gh repo edit` (`--enable-projects=<bool>`), so
enforcement is automatic, not manual. `hasProjectsEnabled` is propagated by
`sync-metadata.yml` and defaults off when the YAML `settings:` block is
silent per [GH-REPO-062]; drift (a board re-enabled via the web UI) is
reverted on the next sync run.

**Cross-references**: [GH-REPO-052] (wiki default-off — the direct analog),
[GH-REPO-060] (schema), [GH-REPO-062] (silence → default), [GH-REPO-070]
(sync workflow), [GH-REPO-094] (hub-override pattern).

### [GH-REPO-056] Merge method: squash-only + auto-delete merged branches
**Statement**: Every repo MUST allow ONLY squash merging and MUST auto-delete
head branches on merge — concretely `allowSquashMerge = true`,
`allowMergeCommit = false`, `allowRebaseMerge = false`,
`deleteBranchOnMerge = true`. Squash-only keeps `main` a linear sequence of
one-commit-per-PR — every merge is a single revertable, bisectable unit —
matching the "timeless infrastructure" posture (no merge-bubble or
rebase-replay noise in history). Auto-delete removes the stale head branch
the moment its PR lands, keeping the branch list to live work only. GitHub
requires at least one merge method enabled, so squash-only is the minimal
valid configuration.

**Managed field**: propagated by `sync-metadata.yml`. Because `gh repo edit`
exposes no flag for the merge-method allows, these four apply via
`gh api PATCH repos/{owner}/{repo}` (`deleteBranchOnMerge` is folded into the
same PATCH). Silence in the YAML `settings:` block applies the defaults above
per [GH-REPO-062]; drift (a merge method re-enabled via the web UI) is
reverted on the next sync run.

**Cross-references**: [GH-REPO-053] (defaultBranch — the linear-history
companion), [GH-REPO-060] (schema), [GH-REPO-062] (silence → default),
[GH-REPO-070] (sync workflow).

### [GH-REPO-057] Secret scanning + push protection on public repos
**Statement**: Every PUBLIC repo MUST have GitHub secret scanning AND secret-
scanning push protection enabled (`secretScanning = true`,
`secretScanningPushProtection = true`). Secret scanning catches committed
credentials; push protection blocks them at push time before they land. Both
are free on public repositories. PRIVATE repos are EXEMPT — secret scanning on
private repos requires GitHub Advanced Security, which this workspace's account
does not carry (no billing); the exemption lifts automatically if GHAS becomes
available.

**Managed field**: propagated by `sync-metadata.yml` for public repos only
(the workflow guards on visibility — the PATCH errors on a private repo without
GHAS). `gh repo edit`/`gh repo view --json` expose no security-analysis
surface, so the workflow reads current state via `gh api repos/{owner}/{repo}`
and applies a `security_and_analysis` PATCH. Silence in the YAML `settings:`
block applies the defaults above (both enabled) per [GH-REPO-062]; drift is
reverted on the next sync run.

**Cross-references**: [GH-REPO-060] (schema), [GH-REPO-062] (silence →
default), [GH-REPO-070] (sync workflow), [GH-REPO-073] (bot App holds
Administration: R&W, which covers the security-analysis write for the nightly
cross-org run).

---

## Metadata file

### [GH-REPO-060] `.github/metadata.yaml` location and schema
**Statement**: The canonical metadata source is a YAML file at
`.github/metadata.yaml` in the repo (resolved 2026-04-29; alongside
`.github/FUNDING.yml`, `.github/dependabot.yml`,
`.github/pull_request_template.md`, `.github/ISSUE_TEMPLATE/*`). Schema:

```yaml
description: <string, required, ≤ 350 chars>
topics: [<string>, ...]   # required, 3-10 entries per [GH-REPO-023]
homepage: <string, optional; default per [GH-REPO-030]>
settings:                 # optional; keys default per [GH-REPO-050..053, 055-057]
  hasIssuesEnabled: <bool>
  hasDiscussionsEnabled: <bool>
  hasWikiEnabled: <bool>
  hasProjectsEnabled: <bool>
  defaultBranch: <string>
  allowMergeCommit: <bool>      # default false per [GH-REPO-056]
  allowSquashMerge: <bool>      # default true  per [GH-REPO-056]
  allowRebaseMerge: <bool>      # default false per [GH-REPO-056]
  deleteBranchOnMerge: <bool>   # default true  per [GH-REPO-056]
  secretScanning: <bool>               # public only; default true per [GH-REPO-057]
  secretScanningPushProtection: <bool> # public only; default true per [GH-REPO-057]
sidebar:                  # optional; keys default per [GH-REPO-054]; manually
                          # enforced today (no API), encoded for future
                          # auto-enforcement when GitHub exposes the toggle
  showReleases: <bool>     # default true (Swift packages publish tagged releases)
  showPackages: <bool>     # default false (Institute distributes via SwiftPM, not GitHub Packages)
  showDeployments: <bool>  # default false (no GitHub Actions deployments on Institute repos)
```

Required keys: `description`, `topics`. Optional keys default per the
relevant rules above.

### [GH-REPO-061] Idempotency contract
**Statement**: The `sync-metadata.yml` reusable workflow MUST be
idempotent — running it twice in succession against the same repo MUST
produce zero edits on the second run. Idempotency is the convergence
criterion for the rollout.

### [GH-REPO-062] Field defaults when YAML omits a key
**Statement**: When `.github/metadata.yaml` omits an optional key,
the script applies the default from the corresponding rule. The script MUST
NOT preserve a divergent existing GitHub-side value when the YAML is silent
— silence in the YAML means "apply the rule default", not "leave whatever
is there".

### [GH-REPO-063] Schema ↔ workflow settings-key consistency
**Statement**: Every key under `settings:` in `metadata-schema.json` MUST be
consumed by `sync-metadata.yml` (read into a `desired_*`/`current_*` pair and
diffed), and every `.settings.<key>` the workflow reads MUST be declared in
the schema. A key documented in the schema but ignored by the workflow (or a
workflow read with no schema declaration) is a silent no-op: a maintainer who
authors that key in a metadata.yaml gets no effect and no error.

**Mechanical check**: `.github/scripts/validate-schema-workflow-keys.py`
extracts the `settings.properties` key set from `metadata-schema.json` and the
`.settings.<key>` reads from `sync-metadata.yml`, and exits non-zero when the
two sets diverge. Wired into `validate-github-metadata.yml`. Mirrors the
prose-rule + mechanical-check pattern.

**Cross-references**: [GH-REPO-060] (schema), [GH-REPO-070] (sync workflow),
[GH-REPO-072] (tooling boundary).

---

## Tooling

### [GH-REPO-070] Centralized reusable workflows
**Statement**: All metadata propagation logic lives in
`swift-institute/.github/.github/workflows/` as three reusable workflows
(resolved 2026-04-29; revised same day to centralised-only architecture
per § 7 Q9):

- **`sync-metadata.yml`** — `workflow_call`, inputs `org` (optional),
  `repo` (optional), `dry-run` (bool). Reads each in-scope repo's
  `.github/metadata.yaml`, diffs against GitHub state, emits `gh repo edit`
  per divergent field. Idempotent. Fans across non-archived repos in the
  selected org (or single repo) regardless of visibility.
- **`sync-metadata-nightly.yml`** — cron `0 4 * * *` (daily 04:00 UTC) +
  `workflow_dispatch`. Calls `sync-metadata.yml` over each ecosystem org
  via a matrix strategy. When any matrix leg fails or applies edits, opens
  or updates a tracking issue in `swift-institute/.github`.
- **`generate-metadata.yml`** — `workflow_dispatch` + `workflow_call`.
  Heuristic-seeded `.github/metadata.yaml` drafts; opens a PR per
  in-scope repo without one. Phase-1 bulk authoring lever.

**Centralised-only by design**: per-repo caller workflows are NOT used.
All token-minting happens from `swift-institute/.github` (the only repo
that holds `SWIFT_INSTITUTE_BOT_APP_*` secrets), keeping cross-org auth simple.
Trade-off: convergence on metadata edits has up to 24h latency (next
nightly run), or the maintainer manually dispatches `sync-metadata.yml`
post-merge for immediate sync. PR-time preview is achievable by
dispatching `sync-metadata.yml` with `dry-run=true` against the affected
repo; the run summary contains the proposed `gh repo edit` invocations.

### [GH-REPO-071] Drift detection and convergence cadence
**Statement**: Three mechanisms catch drift between `.github/metadata.yaml`
and GitHub state (resolved 2026-04-29; revised same day for centralised-
only architecture per [GH-REPO-070]):

1. **Nightly cron sweep**. The full ecosystem (all 17 orgs, all
   non-archived repos) is reconciled every 24 hours at 04:00 UTC by
   `sync-metadata-nightly.yml`. Drift introduced via web-UI edits or
   out-of-band `gh repo edit` is reverted to the YAML state. Tracking
   issue summarises what changed.
2. **Manual `workflow_dispatch` for immediate sync**. After merging a
   metadata-changing PR (or batched waves of merges), the maintainer
   dispatches `sync-metadata.yml` from the GitHub Actions UI (or via
   `gh workflow run`) with `org=<org>` or `repo=<owner>/<repo>` to
   converge immediately rather than waiting for the next cron tick.
3. **Pre-merge dry-run preview**. To preview what sync will do before
   merging a metadata PR, dispatch `sync-metadata.yml` with the same
   scope inputs and `dry-run=true`. The run summary shows the proposed
   `gh repo edit` invocations.

Daily cron is the default convergence cadence: rare metadata edits +
drift detection are both well-served by once-per-day. Centralised-only
auth means there is no on-merge auto-trigger (which would require per-
repo callers in each org's secret context); the manual-dispatch path
covers the "need it now" case at minimal friction.

### [GH-REPO-072] Boundary with adjacent CI tooling
**Statement**:

| Concern | Tool | Lives in | Triggered by |
|---|---|---|---|
| Per-repo metadata | `sync-metadata.yml` + `sync-metadata-nightly.yml` + `generate-metadata.yml` | `swift-institute/.github/.github/workflows/` | cron / dispatch (no per-repo caller) |
| Org community-health files | `Scripts/sync-community-health.sh` | `swift-institute/Scripts/` | Manual run |
| Per-package CI templates | `Scripts/sync-ci-callers.sh` (aspirational — not yet present as of 2026-07-05; tracked via `REPORT-corpus-review.md`) | `swift-institute/Scripts/` | Manual run |
| Per-package CI execution | reusable workflows + per-repo `ci.yml` | `swift-institute/.github` + each repo | PR / push |

Metadata is the only concern in this table that does NOT involve a
per-repo caller — by design, to keep cross-org auth contained to
`swift-institute/.github`. No new locally-run tooling is
introduced.

### [GH-REPO-073] Authentication

**Statement**: Cross-org workflow authentication uses the **`swift-institute-bot`**
GitHub App, installed across all 17 orgs (per § 7 Q9 resolution 2026-04-29).
Initial App permissions:

- Repository: **Metadata: Read**, **Administration: Read & Write**.
- Pull requests: **Read & Write** (PR preview comments).
- Issues: **Read & Write** (tracking issues).

Permissions accrete only when a new cross-org concern actually requires
them, with PR-review gating against `swift-institute/.github`. The App is
positioned as the cross-org bot; concerns needing a narrower install scope
(only some orgs) get separate sibling Apps named `swift-institute-{concern}-bot`.

App credentials live as `swift-institute/.github` org-level secrets
`SWIFT_INSTITUTE_BOT_APP_ID` + `SWIFT_INSTITUTE_BOT_APP_PRIVATE_KEY` and **only** there. Other
orgs do NOT receive duplicate copies of the secrets — the Path B
centralised-only architecture (per § 7 Q9 resolution) means all
token-minting workflows run from `swift-institute/.github`'s context,
where the secrets are already available. Workflows mint short-lived
(1-hour) installation tokens per run via `actions/create-github-app-token@v1`,
using `repositories:` and `permissions:` inputs to scope each minted
token narrower than the App's ceiling.

App installation status is independent of secret distribution: the App
is installed on every org (granting it permission to act on those
repos), but only `swift-institute/.github`'s workflows hold the keys
needed to mint a token.

Fine-grained Personal Access Token is permitted only for ephemeral local
prototyping (e.g., debugging a workflow before the App is set up); production
operation requires the App per § 7 Q9.

### [GH-REPO-074] Per-Package Workflow Files MUST Be Thin Callers

**Statement**: Per-repository workflow files at `<package>/.github/workflows/*.yml` MUST be thin callers to centralized reusable workflows in `swift-institute/.github/.github/workflows/`. A thin caller contains: workflow name, trigger (`on:`), and one `jobs:` block in which every job uses `uses:` syntax to reference a centralized reusable workflow with `with:` and `secrets:` blocks as required. Thin callers MUST NOT contain inline `runs-on:`, `steps:`, or job-step definitions.

**Correct** (current canonical shape, post-2026-05-10 consolidation — the per-package thin caller is `ci.yml` ONLY; `swift-format.yml` and `swiftlint.yml` are absorbed into the layer wrapper's universal matrix and MUST NOT exist as standalone per-package files):

```yaml
name: CI

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main
  workflow_dispatch:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  # Build + test matrix — see <layer>/.github/.github/workflows/swift-ci.yml
  ci:
    uses: <layer>/.github/.github/workflows/swift-ci.yml@main
    secrets: inherit

  # DocC umbrella-catalog pipeline per [DOC-019a]
  docs:
    uses: swift-institute/.github/.github/workflows/swift-docs.yml@main
    secrets: inherit
```

`<layer>` is the org wrapping the package: `swift-primitives`, `swift-foundations`, or `swift-standards`. Sub-org packages (`swift-ietf`, `swift-iso`, `swift-iec`, `swift-w3c`, etc.) route through their parent layer's wrapper per [CI-004b] — currently `swift-standards/.github/.github/workflows/swift-ci.yml@main` for spec-authority sub-orgs.

**Incorrect**:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest                  # ❌ inline runs-on
    steps:                                   # ❌ inline steps
      - uses: actions/checkout@v4
      - run: swift build
      - run: swift test
```

**Scope**: applies to the canonical `ci.yml` workflow under `<package>/.github/workflows/`. Package-specific workflows (release automation, deploy events, custom integrations) where centralized abstraction adds no value MAY be inline; the thin-caller rule targets the canonical CI file that every package ships. **Per-package `swift-format.yml` and `swiftlint.yml` MUST NOT exist as standalone files** — the format and lint legs are part of the layer wrapper's universal matrix (via `swift-institute/.github/.github/workflows/swift-ci.yml`'s `format` and `lint` jobs).

**Tool reusables carve-out**: a package whose primary product is a CLI tool MAY host a reusable workflow (`on: workflow_call:`) in its own repo at `<package>/.github/workflows/<tool>.yml`, exposing the invocation glue for that tool. Such workflows are NOT thin callers; they own version-pinned action refs because they ARE the reusable consumed by downstream repos. The tool and its invocation glue share a lifecycle (single SHA pin, single release, no two-repo coordination) — co-locating them is the deliberate model, mirroring the broader open-source convention (`actions/setup-node`, `swift-actions/setup-swift`, `golangci/golangci-lint-action`). The CI hierarchy (`<org>/.github`) is for CI invariants that vary by layer; it is NOT for tool packaging. Reference case: `swift-foundations/swift-linter/.github/workflows/lint.yml` (consumed by ecosystem repos to run the swift-linter CLI). Tool-reusable repos are an explicit class in [GH-REPO-077] and configure both `swift` and `github-actions` Dependabot ecosystems.

**Lint enforcement**: Reusable workflow `validate-thin-callers.yml` + companion `.github/scripts/validate-thin-callers.py` parse each per-package repo's `.github/workflows/ci.yml` and flag (a) inline `runs-on:` in any job, (b) inline `steps:` in any job, (c) absence of any `uses:` reference. Additionally flags standalone `.github/workflows/swift-format.yml` and `swiftlint.yml` files (forbidden post-2026-05-10 consolidation). Honors the tool-reusable carve-out: workflow files declaring `on: workflow_call:` are exempt from the inline-job checks. Added pilot 7 of `/promote-rule` 2026-05-14. [VERIFICATION: WF validate-thin-callers.py (GH-REPO-074)]

**Cross-references**: [GH-REPO-070], [GH-REPO-072], [GH-REPO-073], [GH-REPO-075].

---

### [GH-REPO-075] Thin-Caller Schema Validation

**Statement**: (Aspirational — `Scripts/sync-ci-callers.sh` is not yet present as of 2026-07-05; tracked via `REPORT-corpus-review.md`. The live mechanism today is `validate-thin-callers.py`/`.yml`, which validates an already-committed caller — it does not regenerate one.) When `Scripts/sync-ci-callers.sh` regenerates per-package thin-caller workflows from a canonical reference, the regenerator MUST validate that each generated caller's `secrets:` and `with:` blocks are accepted by the centralized workflow's `workflow_call:` declaration. A schema mismatch — caller passing a secret or input that the centralized workflow does not declare — MUST fail the regeneration with a clear diagnostic naming the offending key, caller path, and expected schema.

**Composite:** YAML parse of caller (mechanical) + YAML parse of centralized `workflow_call:` declaration (mechanical) + key-set comparison (mechanical) + diagnostic emission (mechanical).

**Procedure** (regenerator-side):

1. Parse the centralized workflow YAML (`swift-institute/.github/.github/workflows/<reusable>.yml`); extract the `on.workflow_call.inputs:` and `on.workflow_call.secrets:` key sets.
2. For each generated caller, parse the caller YAML; extract the `jobs.<job>.with:` and `jobs.<job>.secrets:` key sets.
3. Compare: caller-side keys MUST be a subset of centralized-side declarations.
4. On mismatch, emit a diagnostic naming the offending key + caller path + expected schema; the regeneration MUST exit non-zero rather than write the broken caller.

**Reference-template movement caveat**: When the canonical-reference template moves from one package to another (the historical reason for the EXCLUDE list in `sync-ci-callers.sh` — aspirational, script not yet present as of 2026-07-05; tracked via `REPORT-corpus-review.md`), the EXCLUDE entry MUST be updated to match the new reference, AND the schema validation gate MUST run against the prior reference on first regeneration after the move. Stale EXCLUDE entries leave the prior reference's caller files un-refreshed against the new centralized contract. The 2026-05-01 property launch surfaced this exact failure mode: property was the pre-trim reference, EXCLUDE'd in the script; the 2026-04-29 trim moved the reference to carrier; property's callers were never refreshed against the trimmed centralized side; force-flip to public produced silent `startup_failure` on both `swiftlint.yml` and `swift-format.yml`. Direct cost: ~30 minutes of diagnosis.

**Cross-references**: [GH-REPO-070], [GH-REPO-074], [CI-053].

---

### [GH-REPO-076] metadata.yaml as exclusive source; custom properties are derived projections

**Statement**: Per-repo metadata authored in the workspace MUST live in
`.github/metadata.yaml`. GitHub repository custom properties MUST NOT be
authored as a parallel or duplicate metadata store. Custom properties MAY
be added only when ALL of the following hold:

1. The field needs a GitHub-native custom-property capability that
   metadata.yaml cannot provide — capability-fit, decided by data shape,
   not by whether a consumer currently exists. Qualifying capabilities are limited to:
   - Org-wide single-call queryability across the ecosystem (a tool that
     would otherwise fetch metadata.yaml from every repo in the org)
   - GitHub ruleset targeting (policy whose application diverges by the
     property value)
   - GitHub Actions OIDC token claim inclusion (per the 2026-03-12 changelog)
2. The property value is a projection of an existing metadata.yaml field —
   never a new authoring surface. metadata.yaml is canonical; the custom
   property is a derived view, on the same footing as description / topics /
   homepage / settings per [GH-REPO-070].
3. The projection is one-way (yaml → property), automated by
   `sync-metadata.yml`, and included in the existing drift-detect-and-revert
   logic per [GH-REPO-070]. Editing the custom property directly (web UI,
   `gh api` outside the workflow) is drift and reverted.

**Cross-references**: [GH-REPO-070] (metadata.yaml canonical for
description / topics / homepage / settings), [GH-REPO-091] (`discussion:`
field in metadata.yaml), [GH-REPO-073] (institute-bot App authentication
and accrete-on-need permission policy — the bot's Custom Properties
read & write permission was granted ahead of the 2026-05-10 probe but
is currently used only for the no-projection scenario above).

---

### [GH-REPO-077] Dependabot ecosystem scoping by repo class

**Statement**: A repo's `.github/dependabot.yml` MUST configure update
ecosystems strictly by which dependency classes the repo OWNS, mapped
by repo class:

| Repo class | `Package.swift` at root? | `on: workflow_call:` workflow with bumpable refs? | Version-pinned action refs in non-reusable workflows? | `dependabot.yml` ecosystems |
|---|---|---|---|---|
| Per-package repo, thin-caller workflows | Yes | No | No (only `<org>/.github/.../@main` refs) | `swift` only |
| **Tool-host package** (CLI-shipping package hosting its own reusable invocation glue) | **Yes** | **Yes** | (typically no) | **`swift` AND `github-actions`** |
| `.github` repo with bespoke workflow jobs (master reusables; layer wrappers that ADD jobs) | No | (these workflows ARE the reusables) | Yes (e.g., `actions/checkout@v6`, `actions/cache@v5`, `step-security/harden-runner@<SHA>`) | `github-actions` only |
| `.github` pure pass-through wrapper (layer wrapper that ONLY delegates `uses: …@main`) | No | No | No | NO `dependabot.yml` |
| `.github` stub repo (no workflows) | No | No | No | NO `dependabot.yml` |

Three canonical templates are authoritative:
- `Scripts/dependabot-canonical-swift.yml` (swift only)
- `Scripts/dependabot-canonical-actions.yml` (github-actions only)
- `Scripts/dependabot-canonical-tool-host.yml` (swift AND github-actions)

A repo gets one of them or none — never duplicates — per its class.

**Speculative ecosystem configuration is forbidden**: configuring
`github-actions` in a per-package repo because "a future inline step
might add a real pin" is the failure mode this rule corrects.
Per-package repos following [GH-REPO-074] have no bumpable action
refs; configuring an ecosystem with nothing to scan adds drift surface
without value.

**Tool-host detection** (safe auto-detection — distinct from the
mechanical-grep approach this rule otherwise rejects): a per-package
repo qualifies as tool-host iff at least one workflow file under
`.github/workflows/` declares `on: workflow_call:` AND contains
version-pinned third-party action refs. The `on: workflow_call:`
trigger is deliberate — a workflow with that trigger is INTENTIONALLY
exposing a reusable surface and therefore is INTENDED to host action
refs. Auto-detection on this signal cannot silently mask
[GH-REPO-074] violations because non-thin "regular" workflows use
`on: push:` / `pull_request:`, not `on: workflow_call:`. The two
shapes are mutually exclusive. Reference case:
`swift-foundations/swift-linter` (CLI package shipping
`.github/workflows/lint.yml` consumed by ecosystem repos to run the
linter in CI).

**Conformance interaction**: when `Scripts/sync-dependabot.sh` detects
a per-package repo whose workflow files contain inline version-pinned
action refs in non-`workflow_call:` workflows (i.e., NOT a tool-host),
it MUST fail the sync with the repo path and a [GH-REPO-074]
migration citation. The fix is to migrate the repo to a thin caller,
NOT to add `github-actions` to its `dependabot.yml`. Tool-host repos
(`workflow_call:` shape) are exempt from this gate per [GH-REPO-074]'s
tool-reusables carve-out.

**Procedure** (sync side):

1. For each per-package repo (has `Package.swift` at root): write
   `dependabot-canonical-swift.yml`. Assert thin-caller status of
   every `.github/workflows/*.yml`; on inline version-pinned action
   refs, FAIL with repo path + [GH-REPO-074] citation.
2. For each `.github` repo with bespoke action pins (today:
   `swift-institute/.github`, `swift-primitives/.github`): write
   `dependabot-canonical-actions.yml`. (The existing self-tuned
   `swift-institute/.github/.github/dependabot.yml` with weekly
   cadence is a permitted variant of this template.)
3. For each `.github` repo without bespoke action pins (today:
   `swift-foundations/.github`, `swift-standards/.github`, plus
   `swift-ietf/.github`, `swift-iso/.github`, `swift-iec/.github`
   stubs): remove `dependabot.yml` if present.
4. Dry-run mode prints planned classification + diffs before writing.

**Cross-references**: [GH-REPO-070] (centralized reusable workflows — the architectural anchor that concentrates action pins in two `.github` repos), [GH-REPO-074] (thin-caller rule — the structural basis for per-package repos owning no bumpable github-actions deps), [GH-REPO-075] (thin-caller schema validation — the `sync-ci-callers.sh` regenerator gate is aspirational as of 2026-07-05, tracked via `REPORT-corpus-review.md`; the live check today is `validate-thin-callers.py`/`.yml`).

---

## Org meta-repos

### [GH-REPO-080] `.github` repo metadata
**Statement**: Each org's `.github` community-health repo carries
the canonical description `Organization-level community-health defaults
for {OrgName}.`, no topics, no homepage, and the same repo-settings rules
([GH-REPO-050..053]) as production repos. **`.github` repos are exempt
from [GH-REPO-040] LICENSE.md requirement** per Q4 resolution 2026-04-29 —
they are not packages; their content's license is governed by the canonical
sources in `swift-institute/.github`.

### [GH-REPO-081] Org website stub repo (RETIRED 2026-07-02)
**Statement**: RETIRED. swift-institute.org is the ecosystem's sole
website; per-layer sites are not planned, and the `swift-{layer}.org`
stub repos were made private per principal direction 2026-07-02 (retained non-publicly, not deleted). Do NOT create
`swift-{layer}.org` repos. (A GitHub repo does not reserve a domain —
domain reservation happens at the registrar.) The ID is retained as a
redirect anchor; the scaffold-description convention now lives in
[GH-REPO-010].

---

## Discussion threads

Centralized GitHub Discussions surface for the ecosystem. All discussion
threads for public Family E packages live in `swift-institute/.github`'s
"Packages" category and aggregate at
`https://github.com/orgs/swift-institute/discussions`. Pre-authorized as a
centralization candidate by [GH-REPO-051]; the infrastructure was enabled
2026-05-10 (discussions toggled on, "Packages" category created with ID
`DIC_kwDOSDTLes4C8spE`, swift-institute-bot App granted Discussions:
Read & Write).

### [GH-REPO-090] Centralized discussion thread for public Family E packages

**Statement**: Every public Family E package (sub-package library, per the
**readme** skill's family taxonomy) MUST have one corresponding discussion
thread in `swift-institute/.github`'s "Packages" category. The thread URL
is per-package metadata, recorded in `.github/metadata.yaml`'s `discussion:`
field. The thread is created at visibility-flip time per [RELEASE-004a]
Stage 2, before the package becomes consumer-cloneable.

**Scope**: Family E only. Family C (process / workflow), Family F
(placeholder / scaffold), and Family G (org profile) repos do NOT get
discussion threads — they are not packages and the consumer-evaluation
audience the thread serves doesn't exist for them.

**Cross-references**: [GH-REPO-051] (centralization candidate), [GH-REPO-091]
(metadata.yaml schema), [GH-REPO-092] (workflow contract), [GH-REPO-093]
(title and body conventions), [GH-REPO-094] (hub repo metadata override
without which sync-metadata-nightly reverts the discussions toggle),
[README-040] (Family E README Community section), [README-168] (CI
validation contract), [RELEASE-004a] (Stage 2 visibility-flip prerequisite).

---

### [GH-REPO-091] `.github/metadata.yaml` `discussion:` field

**Statement**: When [GH-REPO-090] applies, `.github/metadata.yaml` MUST
include a top-level `discussion:` field. Schema extension to [GH-REPO-060]:

```yaml
discussion: <string; required for public Family E, optional pre-flip;
             accepted forms (both resolve to the same thread):
               https://github.com/orgs/swift-institute/discussions/{N}      # preferred — what `createDiscussion` returns
               https://github.com/swift-institute/.github/discussions/{N}   # equivalent — repo-specific form
            >
```

**Field state by lifecycle phase**:

| Phase | `discussion:` state |
|---|---|
| Pre-implementation | absent |
| Active development (private) | absent or empty |
| Visibility-flip Stage 2 (per [RELEASE-004a]) | populated with thread URL via the workflow PR per [GH-REPO-092] |
| Public | populated; immutable thereafter except for thread renumbering (structurally rare) |

**Idempotency**: per [GH-REPO-061]; once populated, future sync runs treat
the field as source-of-truth and produce zero edits.

**Cross-references**: [GH-REPO-060] (parent schema), [GH-REPO-061],
[GH-REPO-090], [GH-REPO-092].

---

### [GH-REPO-092] `sync-discussion-threads.yml` workflow contract

**Statement**: A new reusable workflow at
`swift-institute/.github/.github/workflows/sync-discussion-threads.yml`
governs discussion-thread creation and validation per [GH-REPO-090]. The
workflow is the centralized counterpart to `sync-metadata.yml` per
[GH-REPO-070] for the discussion concern.

**Inputs**:

| Input | Type | Default | Purpose |
|---|---|---|---|
| `repo` | string | — | Target repo in `<owner>/<repo>` form |
| `create` | bool | `false` | When true, creates threads where missing; when false, validation-only |
| `dry-run` | bool | `true` | When true, prints intended actions without executing writes |

**Behaviour**:

1. **Read** the target repo's `.github/metadata.yaml` `discussion:` field.
2. **Resolve category ID** by slug (`packages`) at runtime against
   `swift-institute/.github`. The category ID is NOT hard-coded in the
   workflow — slugs are stable across category recreation, IDs are not.
3. **If field is empty AND `create=true`**: create discussion via GraphQL
   `createDiscussion` against `swift-institute/.github` (repository ID
   `R_kgDOSDTLeg`, category resolved at step 2), title and body per
   [GH-REPO-093]. Open PR back to target repo writing the URL to
   `.github/metadata.yaml` and updating the README marker block per
   [README-040].
4. **If field is set**: validate URL resolves; validate README marker
   block contents match metadata.yaml. Drift surfaces as warnings in the
   run log; nightly aggregator (`sync-discussion-threads-nightly.yml`)
   opens a tracking issue when any matrix leg fails the called workflow
   (mirrors [README-167] / sync-metadata-nightly's reporting shape).
5. **`dry-run=true` short-circuits all writes**: workflow prints intended
   GraphQL mutation, PR diff, and drift findings without executing.

**Authentication**: per [GH-REPO-073], runs from `swift-institute/.github`
with the `swift-institute-bot` App. Permissions required:
`Discussions: Read & Write` (added 2026-05-10), `Contents: Read` (target
repo metadata.yaml + README), `Pull requests: Write` (PR creation). If
the App's current Contents permission is absent, raise as PR against
`swift-institute/.github` per [GH-REPO-073]'s permission-accretion
discipline before first live run.

**Triggers**:

- `workflow_dispatch` — manual invocation, typically as part of
  [RELEASE-004a] Stage 2 with `create=true, dry-run=false`.
- `workflow_call` — invoked by `sync-discussion-threads-nightly.yml`
  (cron 04:30 UTC daily) per pilot package with `create=false,
  dry-run=true`. Each matrix leg's failure surfaces as a tracking issue
  via the `report` job, mirroring `sync-metadata-nightly.yml`'s pattern.

**Idempotency**: once `discussion:` populated AND README marker block
matches, future runs produce zero edits.

**Cross-references**: [GH-REPO-070] (centralized workflow architecture),
[GH-REPO-073] (authentication; verify Contents permission), [GH-REPO-091]
(metadata field), [GH-REPO-093], [README-040], [README-168],
[RELEASE-004a].

---

### [GH-REPO-093] Discussion thread title and body conventions

**Statement**: Threads created by [GH-REPO-092] follow these conventions:

| Field | Convention |
|---|---|
| **Title** | Repo name verbatim (e.g., `swift-carrier-primitives`) — no version suffix, no trailing punctuation |
| **Category** | `Packages` (slug `packages` on `swift-institute/.github`). The category ID is resolved at runtime by slug per [GH-REPO-092] — slugs are stable across category recreation; IDs are not. |
| **Body** | Minimal — single paragraph: `Discussion thread for [{repo-name}](https://github.com/{owner}/{repo}). Questions, feedback, and announcements welcome.` |

**Cross-references**: [GH-REPO-090], [GH-REPO-092].

---

### [GH-REPO-094] Hub repo metadata.yaml MUST override hasDiscussionsEnabled

**Statement**: Because [GH-REPO-051]'s default for `hasDiscussionsEnabled`
is `false` (every public repo MUST have discussions disabled unless
principal-authorized), the centralization candidate
`swift-institute/.github` MUST explicitly override
`settings.hasDiscussionsEnabled: true` in its own `.github/metadata.yaml`.
Without the override, `sync-metadata-nightly.yml` applies the default-false
on each cron tick (daily 04:00 UTC), reverting the discussions toggle and
wiping category visibility — which in turn breaks the
`sync-discussion-threads.yml` workflow at the `createDiscussion` mutation
step (the category ID becomes unresolvable).

**Required block** in `swift-institute/.github/.github/metadata.yaml`:

```yaml
settings:
  hasDiscussionsEnabled: true
```

**Generalization**: any future centralization repo (per [GH-REPO-051]:
"...they centralize at `swift-institute/.github` or
`swift-institute/swift-institute.org` rather than per-package") MUST
include the same override. The rule generalizes per the centralization-
candidate framing, not just `.github`.

**Cross-references**: [GH-REPO-051] (default-false rule this overrides),
[GH-REPO-070] (sync-metadata workflow that applies the revert),
[GH-REPO-090] (discussion thread setup), [GH-REPO-092] (workflow that
fails when the toggle is reverted).

---

## Cross-References

- **readme** skill — `[README-006]` opening contract; `[README-001]` required
  inventory; `[README-025]` scope boundary; `[README-040]` Community section;
  `[README-168]` CI auto-generation and validation.
- **swift-package** skill — `[PKG-NAME-001]` noun form (informs description
  format).
- **code-surface** skill — `[API-NAME-003]` specification-mirroring names
  (informs L2 description shape).
- **documentation** skill — `[DOC-080]` umbrella catalog landing pages
  (informs homepage URL choice).
- **skill-lifecycle** skill — update provenance; absorption criteria.
- Research: `swift-institute/Research/github-metadata-harmonization.md`
  (Tier 2 RECOMMENDATION, 2026-04-29) — provenance for this skill.
- Adjacent tooling: `Scripts/sync-community-health.sh`,
  `Scripts/sync-ci-callers.sh` (aspirational — not yet present as of 2026-07-05; tracked via `REPORT-corpus-review.md`).
