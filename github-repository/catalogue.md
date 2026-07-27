---
name: github-repository
description: |
  GitHub repo metadata: description, topics, homepage, license, settings, discussion threads, per-package .github/metadata.yaml + centralized reusable propagation.
  Apply when authoring or auditing GitHub-side metadata for any ecosystem repo.
---

<!-- Judgment and rationale catalogue retained for progressive disclosure.
Mechanical schemas, inventories, defaults, and validators live in the
repository-policy Swift product and outrank illustrative shapes below. -->

# GitHub Repository

GitHub-side metadata for repositories across the Swift Institute ecosystem.
Governs per-repo description, topics, homepage URL, license, and repo
settings; defines the canonical `.github/metadata.yaml` source-of-truth file
and the centralized reusable workflows in `swift-institute/.github/.github/workflows/` (`sync-metadata.yml`, `sync-metadata-nightly.yml`, `metadata-pr-preview.yml`, `generate-metadata.yml`).

**Authority**: `swift-institute/Research/github-metadata-harmonization.md` (Tier 2 recommendation, 2026-04-29).

**Scope boundary**: this catalogue governs editorial judgment, repository
classification, rationale, and exception history. The repository-policy Swift
product owns schemas and deterministic evaluation for metadata, settings,
community-health inheritance, Dependabot, and GitHub Actions. Central CI runs
that product; `swift-institute-bot` converges cross-repository state.

---

## Meta-Rules

### [GH-REPO-001] Discovery-Lens
**Statement**: Every metadata field MUST serve a discovering reader's
question — *"what is this repo, and would I look further?"* Content that does
not survive the discovery-lens belongs in the README, the package's DocC, or
not at all.

### [GH-REPO-002] Single-source discipline
**Statement**: The repository's typed policy input is canonical for authored
metadata and settings; GitHub-side state is a derived view. Cross-repository
convergence runs through `swift-institute-bot`, not direct manual edits or a
second repository-local implementation. The repository-policy product owns the
current input schema and default derivation.

### [GH-REPO-003] Scope comes from typed inventory
**Statement**: Repository-policy derives its population from the canonical
Workspace inventory and live GitHub facts, with archived, unavailable, and
exception cases reported explicitly. A prose organization count or remembered
repository list is not authority.

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
| Vendor / platform authority package (implements no numbered spec) | `«Content phrase» for Swift.` — identical to the L1/L3 row. See the non-spec-implementation clause below. |

Template conformance is enforced by review, not by CI. **No workflow validates
that a rendered description matches its template** (measured 2026-07-25:
`sync-metadata.yml` contains no template or spec-title validation pass). Do not
cite `sync-metadata.yml` as the gate for this rule.

**Non-spec-implementation packages (added 2026-07-25)**: residence in an
authority org does NOT make a package an L2 class. A package that implements
**no numbered specification** — an instruction-set surface, a platform ABI, a
vendor API — takes the **content-phrase** template and MUST NOT use
`Swift implementation of …`. Current instances: `swift-arm-standard`,
`swift-x86-standard`, `swift-windows-32`, `swift-riscv-standard`. Such
packages get **no `spec-titles.yaml` entry**, and their org MUST NOT be added
to the authority map in `generate-metadata.sh`: the generator would then match
its own naming pattern against the repo name and emit a placeholder such as
`Swift implementation of ARM TODO-standard-name.` The distinguishing test is
"does a numbered specification exist that this package implements?", not
"which org holds it?".

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
two-level map keyed on authority code (`rfc`, `bcp`, `iso`, `iso-iec`,
`ieee`, `iec`, `w3c`, `whatwg`, `ecma`, `incits`) then spec-id (`'5234'`,
`'8601'`, `'4-1986'`, etc.) → spec title string. (`bcp` and `iso-iec` are
real sections with dedicated generator branches; both were omitted from
this list until 2026-07-25.) Maintainer adds an entry whenever a new
spec-id package enters the ecosystem; the entry lands in the same PR that
creates the new repo's `.github/metadata.yaml`.

**The table is a default seed, not an equality constraint (clarified
2026-07-25).** Its sole consumer is `generate-metadata.sh`, invoked by
`generate-metadata.yml`, which renders a **draft** description only for
repos that do not yet have a `.github/metadata.yaml` — it never rewrites an
existing one, and `sync-metadata.yml` does not read the table at all.
Consequently:

- A repo's description MAY diverge from the rendered title once authored,
  and such divergence is **not** a defect. Descriptions legitimately
  **narrow** (`swift-ieee-1003` implements only POSIX Chapter 12) and
  legitimately **elaborate** (`swift-rfc-6066` enumerates the six TLS
  extensions it covers). Equality cannot hold as a general rule, so it MUST
  NOT be asserted as one.
- The defect the table actually prevents is a **missing entry**, which makes
  the generator emit a literal `TODO add title to spec-titles.yaml`
  placeholder into a generated draft. That placeholder is the thing to fix.
- Because entries for already-authored repos are documentary rather than
  operational, adding one is a low-risk registry completion, not a
  behavioural change to any live repo.

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
unaffected. **Applied at (2026-07-25)**: schema reconciled to 2–10; every site
read rather than cited — `SKILL.md:442` `3-10`→`2-10` (`Skills@b691932`),
`metadata-schema.json` 0–20→2–10 (`.github@643cfdc`), and the three org meta-repos
this rule exempts, which now omit `topics` rather than declare `[]` because a schema cannot express the exemption (`swift-foundations/.github@2b979e7`, `swift-ietf/.github@d1f194c`, plus one private org-website stub whose SHA a public reader could not resolve).

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
topics: [<string>, ...]   # required, 2-10 entries per [GH-REPO-023]
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

### [GH-REPO-070] Central policy and bot convergence
**Statement**: Repository-policy owns metadata/settings evaluation in Swift.
Central workflows schedule that product and `swift-institute-bot` performs
cross-repository convergence with a canary, journal, receipt, and final
readback.

The workflow names below are historical/current integration examples, not a
canonical inventory. Read the central repository and typed policy for the live
surface:

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

**Centralized by design**: package repositories do not host metadata/settings
convergence callers. Central CI mints a narrowly scoped App token and invokes
the Swift product. Manual dispatch may select timing or canary scope, but does
not replace the bot transaction with hand-authored mutations.

### [GH-REPO-071] Drift detection and convergence cadence
**Statement**: The bot periodically evaluates the typed desired state against
live GitHub state, reports drift, and converges authorized fields. A targeted
dispatch runs the same product for a canary or immediate convergence. Dry-run
uses the same population and predicate and emits a mutation-free receipt.

The following legacy trigger descriptions illustrate scheduling only; the
repository-policy/bot contract above is authoritative:

1. **Nightly cron sweep**. The full ecosystem (all 17 orgs, all
   non-archived repos) is reconciled every 24 hours at 04:00 UTC by
   `sync-metadata-nightly.yml`. Drift introduced via web-UI edits or
   out-of-band `gh repo edit` is reverted to the YAML state. Tracking
   issue summarises what changed.
2. **Targeted `workflow_dispatch` for immediate sync**. After merging a
   policy-changing PR, dispatch the central bot-backed workflow with an exact
   organization or repository scope.
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
**Statement**: The exact executable/product map lives in repository-policy and
central CI. The semantic boundaries are:

| Concern | Tool | Lives in | Triggered by |
|---|---|---|---|
| Per-repo metadata/settings | repository-policy + bot | central control plane | cron / dispatch |
| Org community-health files | repository-policy + org `.github` defaults | central control plane | cron / dispatch |
| Per-package Actions whitelist | repository-policy | Workspace doctor + central CI | local / PR / sweep |
| Per-package CI execution | reusable workflows + whitelisted thin caller | central/layer owner + package | admitted repo events |

Cross-repository concerns do not require package callers. Package-local files
exist only for whitelisted repository events or tool-owned reusable surfaces.

### [GH-REPO-073] Authentication

**Statement**: Cross-org workflow authentication uses the
**`swift-institute-bot`** GitHub App. The typed operation declares the exact
repositories and least permissions it needs; repository-policy verifies the
operation class before mutation.

- Repository: **Metadata: Read**, **Administration: Read & Write**.
- Pull requests: **Read & Write** (PR preview comments).
- Issues: **Read & Write** (tracking issues).

Permissions accrete only when a real typed operation requires them. The App is
the default cross-repository actor; a narrower sibling App is justified only
by a materially different installation or permission boundary.

App credentials remain only in the central control-plane secret context.
Workflows mint short-lived installation tokens scoped more narrowly than the
App ceiling and never copy the private key or a long-lived token to consumers.

App installation status is independent of secret distribution: the App
is installed on every org (granting it permission to act on those
repos), but only `swift-institute/.github`'s workflows hold the keys
needed to mint a token.

A personal token is not a production or fleet fallback. Bounded local
read-only diagnosis may use the user's existing authentication; writes route
through the bot or an explicitly selected one-off recovery.

### [GH-REPO-074] Package-local Actions are denied unless whitelisted

**Statement**: The repository-policy Swift product denies every package-local
workflow and action unless a typed whitelist grant admits its exact repository
class, path, triggers, and direct `uses:` references.

The default package grant is a thin caller to the approved layer entry point.
A thin caller contains the admitted trigger/concurrency surface and job-level
`uses:` calls with only declared inputs and secrets. It contains no
`runs-on:`, `steps:`, matrix, tool setup, validation predicate, scheduled fleet
job, or cross-repository mutation.

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

**Scope**: applies to every file below `.github/workflows/` and
`.github/actions/`, not only `ci.yml`. Release automation, deploy events,
custom integrations, and new filenames are denied until a typed grant places
the behavior at the correct owner. Common format/lint behavior remains
central.

**Tool-owned grant**: a package whose product is a reusable tool may host
invocation glue only when the whitelist names the exact workflow/action path
and allowed references. Co-location is justified by shared lifecycle and
ownership, not detected merely from the presence of `workflow_call`.

**Mechanical owner**: repository-policy parses the full YAML structure,
classifies all local files/triggers/jobs/references, matches the typed grant,
and emits stable diagnostics. Positive, negative, edge, and exemption fixtures
are the contract. Workspace doctor and central CI invoke that product.

**Cross-references**: [GH-REPO-070], [GH-REPO-072], [GH-REPO-073], [GH-REPO-075].

---

### [GH-REPO-075] Caller and reusable contracts are typed

**Statement**: Repository-policy parses both a package caller and the selected
reusable contract. Every caller `with:` and `secrets:` key must be declared by
`workflow_call`; a mismatch fails with the caller path, offending key, and
expected contract. It also verifies that the caller's file, trigger, reusable
identity, and ref are admitted by the whitelist.

**Composite:** YAML parse of caller (mechanical) + YAML parse of centralized `workflow_call:` declaration (mechanical) + key-set comparison (mechanical) + diagnostic emission (mechanical).

The exact parse/comparison algorithm belongs in the Swift product and tests,
not in this skill.

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

The repository-policy Swift product derives one closed shape — Swift,
GitHub Actions, both, or absent — from repository class plus the typed Actions
grant. There is no copied template and no independent prose detector.

**Speculative ecosystem configuration is forbidden**: configuring
`github-actions` in a per-package repo because "a future inline step
might add a real pin" is the failure mode this rule corrects.
Per-package repos following [GH-REPO-074] have no bumpable action
refs; configuring an ecosystem with nothing to scan adds drift surface
without value.

**Tool-host classification**: a workflow declaring `workflow_call` does not
grant itself tool-owner status. The typed whitelist names the tool repository,
path, and allowed action references. Repository structure is evidence checked
against that declaration, not the authority that creates it.

**Conformance interaction**: when the repository-policy validator detects a
per-package repo whose workflow files contain inline version-pinned action
refs in non-`workflow_call:` workflows (i.e., NOT a tool-host), it MUST fail
with the repo path and a [GH-REPO-074]
migration citation. The fix is to migrate the repo to a thin caller,
NOT to add `github-actions` to its `dependabot.yml`. Tool-host repos
(`workflow_call:` shape) are exempt from this gate per [GH-REPO-074]'s
tool-reusables carve-out.

Repository-policy reports the derived class and exact mismatch. A deterministic
repair is applied through `swift-institute-bot` only after the policy owner,
fixtures, and canary are green.

**Cross-references**: [GH-REPO-070], [GH-REPO-074], [GH-REPO-075].

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
- Adjacent tooling: centralized CI and its Swift repository-policy products.
