---
name: readme
description: |
  README conventions across the ecosystem: five families, family-routing, voice registers,
  required structure, badges, maturity tiers, org-tier patterns, CI/CD contract.
  Apply when creating or reviewing any README.md file.
---

# README

Conventions for README.md files across the ecosystem. The skill is organized as a navigation hub: this file holds the always-loaded surface — workflow position, family routing, universal meta-rules — and topic siblings hold structural rules and voice registers per family.

Full rationale, provenance, extended worked examples, and the dated version changelog (v1.0.0–v3.1.0) for every rule in this skill family: the rationale archive (`Readme Skill Rationale Archive`), referenced below.

---

## Workflow Position

READMEs can be written at any point — even before implementation (README-driven development). Unlike `/documentation` (which synthesizes after implementation), READMEs describe **what the artifact is and how it surfaces to its audience** and can evolve alongside the work.

| Phase | README State |
|-------|-------------|
| Pre-implementation | Title, badge (or status line), one-liner, scope sketch |
| Active development | + sections appropriate to family (Quick Start for sub-package; Structure for process; Inventory for org profile) |
| Feature-complete | + remaining sections per family rules |
| Released / live | Full README at the family's "Complete" tier |

**Scope**: All README.md files anywhere in the ecosystem — package repos, GH org profiles, GH user profiles, process/workflow repos, local-disk grouping directories, scaffold packages. Inline DocC and `.docc` catalogue conventions are covered by the **documentation** skill.

---

## Org Topology

The README family routing depends on understanding how the ecosystem is organized on GitHub.

### Three org tiers + user accounts

GitHub orgs in the ecosystem play one of three conceptual tiers:

| Tier | Example | What lives here |
|------|---------|-----------------|
| **Top-level** | `swift-institute` | The ecosystem brain — skills, scripts, research, processes. No code packages. |
| **Org-of-orgs** | `swift-standards`, `swift-law`, `rule-law` | Conceptual umbrella over a domain with multiple sub-categories (e.g., swift-standards umbrella-covers RFC / ISO / IETF spec bodies, even though the repos are flat within one GH org). |
| **Leaf** | `swift-primitives`, `swift-foundations`, `swift-nl-wetgever`, `swift-us-nv-legislature` | The org where actual code packages live, one repo per package. |

Plus user accounts (e.g., `coenttb`), which are not orgs at all but a separate GitHub entity type with their own profile mechanism.

### Every Swift package is one repo

The workspace has **no monorepos and no superrepos**. Every Swift package is a single GitHub repo. Workspace materialization roots group independent repositories locally; they are not GitHub artifacts or README targets.

Ecosystem orientation is a **published artifact**, not agent-side context: the `swift-institute/Workspace` repository is the front door, carrying the package inventory (`Workspace.json`, the sole name → org → path authority) and machine-checked checkout facts (`workspace doctor`). Its README, not a private instruction file, is the document a newcomer reads. Each org's GH profile (Family G) remains the per-org catalog. When a README needs to point a reader at "where the ecosystem is described", it points there.

---

## Family Routing

Every README belongs to exactly one of five families. The family determines:

- Which sibling file holds the structural rules (see Files table)
- The voice register the README operates in (see the family file's `## Voice` section)
- The audience the README serves

### Family matrix

| # | Family | Path | Renders at | Audience | Voice |
|---|---|---|---|---|---|
| **A** | User profile | `<user>/<user>/README.md` | `github.com/<user>` | Visitors to the user's GitHub page | First-person, mission-anchored, portfolio-shaped, marketing-with-substance allowed |
| **C** | Process / workflow repo | `<repo>/README.md` (workflow repo) | `github.com/<owner>/<repo>` | Maintainers running the workflow | Third-person plural ("we"), terse, instructional, table-driven |
| **E** | Sub-package library repo | `<repo>/README.md` (package repo) | `github.com/<owner>/<repo>` + Swift Package Index | Evaluators deciding adoption | Third-person, evaluator-shaped, motivated examples, no marketing |
| **F** | Placeholder / scaffold repo | `<repo>/README.md` (stub) | `github.com/<owner>/<repo>` | Anyone landing on a stub | Third-person, terse, factual, status-explicit |
| **G** | Org profile (3 sub-tiers) | `<org>/.github/profile/README.md` | `github.com/<org>` | Visitors to the organization's GitHub page | Institutional, third-person plural ("we"), tier-aware (top-level / org-of-orgs / leaf) |

### Decision flow

Walk this in order. The first match wins.

1. **Path is `<user>/<user>/README.md`** on GitHub (a user account's special same-name repo)? → **Family A**.
2. **Path is `<org>/.github/profile/README.md`**? → **Family G**. Then determine sub-tier (top-level / org-of-orgs / leaf) per Org Topology above; rules differ in `org-profile.md`.
3. **Repo describes a workflow, process, or workspace tooling** rather than a software product (Skills, Scripts, Research, Audits, Blog, Experiments, Swift-Evolution, swift-institute.org)? → **Family C**.
4. **Repo is an implemented Swift package** with working code and a public API? → **Family E**.
5. **Repo is an unimplemented namespace reservation** or scaffold with title + status only? → **Family F**.

(Local materialization-root READMEs are out of scope — ecosystem orientation is published in the `swift-institute/Workspace` front door, not in generated directory groupings.)

**Step 3 / step 4 collision — a process repo that ships an executable.** Some workspace-tooling repos are *both*: workspace tooling by role, and an implemented Swift package with a public command surface. `swift-institute/Workspace` is the canonical instance — it is the ecosystem front door (step 3) and ships the `workspace` command-line application (step 4). First-match-wins routes it to Family C, whose rules then forbid exactly the content such a repo needs: [README-137] prohibits a Quick Start, and [README-138] caps length at 80 lines. Both are mechanically enforced.

Route these to **Family C**, and apply the executable carve-outs stated in [README-137] and [README-138]. The reader of such a repo is still a maintainer, not a package evaluator — the Family C voice is correct — but a command surface they are expected to run must be documented, and that content is not optional prose to be evicted to a skill.

**Mechanical destination**: centralized Swift repository-policy validation reads
`readme.family` from each repository's canonical metadata and reports
family-routing diagnostics. The reusable workflow only invokes that Swift-owned
predicate; it does not own a second implementation. A legacy validator is
transitional evidence until this owner lands.

### Family-specific path conventions

- **Family A** is forced by GitHub: user accounts use the special `<user>/<user>/README.md` path. There is no `.github/profile/README.md` equivalent for user accounts.
- **Family G** is forced by GitHub: organization accounts use `.github/profile/README.md`.
- **Family C, E, F** are normal repo READMEs at `<repo>/README.md` that render on GitHub.

### Same org, multiple families

A single GitHub organization typically owns multiple READMEs across families. For `swift-institute` (top-level org):

| README | Family | Renders at |
|---|---|---|
| `swift-institute/.github/profile/README.md` | G (top-level tier) | github.com/swift-institute |
| `swift-institute/Skills/README.md` | C | github.com/swift-institute/Skills |
| `swift-institute/Workspace/README.md` | C | github.com/swift-institute/Workspace |
| `swift-institute/swift-institute.org/README.md` | C | github.com/swift-institute/swift-institute.org |

(Analogous leaf-org and org-of-orgs example tables — swift-primitives, swift-standards: rationale archive §Family-routing.)

The org profile (Family G) is the canonical public catalog for each org. CI auto-generation of its inventory section is specified in `ci-automation.md` [README-166].

---

## Universal Meta-Rules

These two rules apply to every README in every family. Section-level rules in any sibling are subordinate: a section that satisfies its local requirements but violates a meta-rule is non-conforming.

### [README-023] Evaluator's Lens

**Statement**: Every paragraph in a README MUST serve the reader's evaluation question for the family's audience. Content that serves the author rather than the reader MUST be removed or relocated.

**The evaluation question varies by family**:

| Family | Reader's evaluation question |
|---|---|
| A. User profile | *Who is this person and should I work with / hire / follow them?* |
| C. Process / workflow | *What does this workflow do and do I need it?* |
| E. Sub-package library | *Do I want to use this package?* |
| F. Placeholder / scaffold | *What is this and is it usable yet?* |
| G — top-level | *What does this ecosystem coordinate and where do I go next?* |
| G — org-of-orgs | *What domain does this umbrella cover and which sub-orgs implement it?* |
| G — leaf org | *What do this org's packages collectively enable and which one do I want?* |

A paragraph earns its place when it answers the family's evaluation question. Content that doesn't earn its place is author-oriented and belongs elsewhere — in `Research/`, in DocC, in a blog post, or in a CHANGELOG.

**Common violating patterns** (sub-package family, but the principle generalizes):

- Author-oriented ecosystem-positioning ("This package is Layer 1 of …") — belongs in Institute-level docs (sub-package family: see [README-025]).
- Implementation autobiography ("This package evolved out of an internal tool …") — belongs in a blog post or CHANGELOG entry.
- Author's design reflections on why a specific API shape was chosen — belongs in `Research/` or a DocC philosophy article.
- Pre-tag / release-process residue — bake into the operational form, remove the prose.
- Internal workaround rationale — relocate to `Research/`; the reader needs the *cost*, not the *why*.

**Decision test**: Cover a paragraph with your hand. Could a reader skip it and still answer the family's evaluation question? If yes, the paragraph probably doesn't earn its place. Either rewrite it or relocate.

**Rationale**: Section-level rules admit content that satisfies their local form but dilutes the reader's evaluation; the lens catches errors no section-level rule can (full text: rationale archive §[README-023]).

**Cross-references**: [README-026]; per-family Voice sections; [README-016] and [README-024] in `sub-package.md`; an internal feedback note.

---

### [README-026] No Internal Rule-ID Citations

**Statement**: README content (any family) MUST NOT cite internal rule IDs (`[MOD-IMPORT]`, `[PRIM-FOUND-001]`, `[API-NAME-001]`, `[README-*]`, etc.). Rule IDs are author-oriented; readers don't know what they mean. Implementation rationale belongs in `Research/`; consumer-facing prose names the *behaviour*, not the rule.

**Correct**:

```markdown
This package depends on no other Swift packages outside the standard library.
```

**Incorrect**:

```markdown
This package complies with [PRIM-FOUND-001] and depends on no Foundation imports.
```

**Decision test**: Cover the bracketed `[ID]` with your hand. Does the surrounding prose still convey the rule's intent to a reader who has never seen the skills directory? If no, rewrite the prose to name the behaviour. If yes, the citation was decorative; remove it.

**Rationale**: Rule IDs are author-side scaffolding for skill enforcement — the reader has no access to the rule body, and the citation reads as opaque jargon; zero of 15 surveyed first-class Swift OSS READMEs cite internal convention IDs (full text + provenance: rationale archive §[README-026]).

**Mechanical destination**: the centralized Swift repository-policy validator scans
README prose outside fenced code blocks for bracketed convention IDs and emits
`README-026`. Universal reusable CI invokes that same predicate for every
README family. A legacy validator is transitional evidence until this owner
lands. [VERIFICATION: centralized repository-policy gate]

**Cross-references**: [README-023]; per-family Voice sections.

---

### [README-028] Speculative Family / Rule Validation Discipline

**Statement**: A new family, sub-tier, or rule proposed in this skill MUST be backed by at least one existing instance in the workspace at the time of authoring. When zero instances exist, the proposed family or rule MUST be flagged `speculative — pending validation` in its frontmatter or changelog entry, AND the skill author MUST identify the validation criterion (the first concrete artifact whose existence will retire the speculative flag).

**Procedure** (for any new family / sub-tier / [README-*] rule):

1. Before authoring the new family or rule body, enumerate existing instances through the Workspace inventory and repository-policy tool.
2. If the count is zero, mark the addition `speculative — pending validation` in the changelog and frontmatter.
3. Identify the validation criterion: the first concrete artifact whose creation will trigger removal of the flag. Cite it explicitly ("retires when the first <X> README ships").
4. The speculative flag MUST persist until step 3's criterion is met. A rule that has never been applied to a real artifact has accumulated zero empirical pressure; promoting it to MUST risks mandating shape that conflicts with downstream realities the rule could not have anticipated.

**Decision test**: Can the author cite at least one existing artifact in the workspace that the new family or rule will apply to today? If no, the proposal is speculative and MUST be flagged accordingly.

**Scope**: applies to new families, new sub-tiers within an existing family, and new [README-*] rules whose enforcement targets are not yet present. Does NOT apply to amendments to existing rules whose targets exist (e.g., extending [README-016] with a new prohibited-content row whose origin instance was already encountered).

**Rationale**: Speculative skill content carries authoring, maintenance, and integrity costs; the "no existing instances" signal is visible at design time, and the rule converts it into a deferral that prevents downstream-detected drops (full text + the canonical 2026-05-01 Family B/D origin incident: rationale archive §[README-028]).

**Cross-references**: [README-023] evaluator's lens.

---

### [README-030] Capability Coverage

**Statement**: A README MUST name every distinct entry point of the artifact's user-facing surface — each command or subcommand of a CLI, each top-level product of a library — at least by name and purpose. A capability the reader is expected to invoke MUST NOT be discoverable only from source, `--help`, or a design document. Depth may vary; **presence may not**.

This is the additive counterpart to [README-023]. The evaluator's lens is a *subtractive* test — it asks whether each paragraph present earns its place, and a document can pass it completely while omitting the artifact's central capability. Nothing catches an absence except a rule that requires coverage.

**Decision test**: List the artifact's entry points from its own surface — the CLI's operation enum or usage string, the manifest's `products`. Grep the README for each name. Every one MUST appear. A zero count is a finding, regardless of how well-written the rest of the README is.

**Correct** (each command named with its purpose, before any deep-dive section):

```markdown
| Command | What it does |
| --- | --- |
| `sync` | Clone missing repositories and fast-forward eligible ones. |
| `doctor` | Report what is measurably true about this checkout. |
| `compose` | Point one package's dependency at your local checkout of it. |
| `restore` | Undo a composition, restoring the declared clause byte-for-byte. |
| `verify` | Report which source a dependency actually compiled from. |
```

**Incorrect**: a README covering `sync` and `doctor` thoroughly while `compose`, `restore`, and `verify` appear zero times — the reader cannot discover that local-source composition exists at all.

**Rationale**: The origin instance is `swift-institute/Workspace` (2026-07-26). A test-drive of the contributor path found the README mentioned `sync` seven times and `doctor` throughout, and `compose` / `restore` / `verify` **zero times** — the package's central local-development capability was invisible to anyone reading the repository. No rule in this corpus was violated: [README-009] governs Quick Start *quality* ("show the primary use case"), not surface *coverage*, and [README-023] cannot fire on absent content. The gap was structural, not a lapse in applying an existing rule.

**Every instruction surface, not only the README.** In the origin instance the *same* capability was absent from `CLAUDE.md` as well — the agent-facing instruction surface listed `sync`, `doctor`, and `test` and named the three composition verbs zero times. Two independent surfaces, one omission each, same author-side cause: a capability that no rule required anyone to enumerate. (`AGENTS.md` there is a symlink to `CLAUDE.md`, so it is one surface, not a third — verify before counting.)

Apply the decision test to **every instruction surface the repository publishes**, not only `README.md`. Note the boundary honestly: this skill's scope is README files, and **no skill in the corpus currently owns `CLAUDE.md` / `AGENTS.md` content** — several reference those files, none govern them. Until that owner exists, this clause is the only thing asking the question of the agent-facing surface, and it is deliberately stated as a coverage obligation rather than as a structural rule for a file this skill does not own. A skill that does own the agent instruction surface would be the better home; that is a gap to fill, not a fiction to paper over here.

**Mechanical-check candidate**: this rule is a strong rule → check migration target. For a package with an executable target, a check can extract the declared operation names from the command schema and assert each appears in `README.md`. That check would have caught the origin instance exactly, and it subsumes the prose rule for the CLI case. See [README-161]–[README-166] for the enforcement chassis.

**Cross-references**: [README-023] evaluator's lens (subtractive counterpart); [README-009] Quick Start requirements; [README-137].

---

### [README-031] First-Run Cost Disclosure

**Statement**: When a README documents a command a reader is expected to run, and that command takes **more than roughly 30 seconds** or produces **no output while it works**, the README MUST say so at the point of instruction — stating the expected magnitude and that silence is normal. When a quieter or more legible alternative exists (running the build as its own step first), the README SHOULD offer it.

**Decision test**: Would a first-time reader, thirty seconds into this command with a blank terminal, have any way to distinguish "working" from "hung"? If no, disclose.

**Correct**:

```markdown
**The third command is slow the first time, and it is silent while it works.** Before it can
sync anything, `swift run` compiles the application and its whole dependency graph — several
thousand compile steps. Expect several minutes with no output at all. That is normal and it is
not a hang.
```

**Incorrect**: a bare quickstart block whose first command silently compiles for minutes, with no note — the reader's only signal that anything is happening is an unchanging cursor.

**Rationale**: The origin instance is `swift-institute/Workspace` (2026-07-26). The quickstart's first command compiles roughly four thousand steps and emits nothing for minutes; the agent test-driving the contributor path had to inspect the machine's running processes to convince itself the command had not hung. A newcomer without that option concludes the tool is broken and leaves. A grep of this skill and the **documentation** skill for first-run duration, expected timing, or output silence returned nothing: the entire corpus was silent on first-run experience, treating a README as a description of an artifact rather than of an encounter with it.

**Scope**: applies to every family whose README documents runnable commands (C, E, and any F/G README carrying a command block). Long-running commands that *do* stream progress need no disclosure — the defect is silence, not duration alone.

**Cross-references**: [README-009] Quick Start requirements; [README-030].

---

## Files

| Family | File | Existing IDs | New ID range |
|--------|------|---|---|
| Universal meta-rules | this file (`SKILL.md`) | [README-023], [README-026], [README-028], [README-030], [README-031] | [README-032..039] |
| A. User profile | `user-profile.md` | — | [README-120..129] |
| C. Process / workflow | `process.md` | — | [README-130..139] |
| E. Sub-package library | `sub-package.md` | [README-001..017], [README-019], [README-021], [README-022], [README-024], [README-025], [README-027], [README-029], [README-040] | [README-041..049] (reserved) |
| F. Placeholder / scaffold | `placeholder.md` | — | [README-150..159] |
| G. Org profile (3 tiers) | `org-profile.md` | [README-020] | [README-100..119] |
| CI/CD contract | `ci-automation.md` | [README-160..167], [README-168], [README-170] | [README-169] (reserved) |

The [README-140..149] range is reserved (formerly Family B "Local-disk grouping", dropped 2026-05-01).

---

## Rule Index

One-line hooks for every rule. Load the linked file when the family is active.

### Universal Meta-Rules (`SKILL.md`)

| ID | Hook |
|----|------|
| [README-023] | Evaluator's Lens — every paragraph serves the family's evaluation question |
| [README-026] | No Internal Rule-ID Citations — no `[MOD-*]`, `[README-*]`, etc. in README prose |
| [README-028] | Speculative family / rule validation discipline — zero-instance proposals flagged pending validation |
| [README-030] | Capability Coverage — every user-facing entry point named, on every instruction surface; presence is mandatory, depth varies |
| [README-031] | First-Run Cost Disclosure — a slow or silent documented command must say so at the point of instruction |

### Family A: User Profile (`user-profile.md`)

| ID | Hook |
|----|------|
| [README-120] | Identity line — name + roles + contact-friendly hook |
| [README-121] | Mission paragraph — the future the user is building toward |
| [README-122] | Flagship projects format — bold name + link + 1-line scope + bulleted highlights |
| [README-123] | Quantified-claim convention — stars / metrics in italics, no marketing-without-substance |
| [README-124] | Professional work section — links + 1-line scope per engagement |
| [README-125] | Philosophy section — beliefs grounded in the user's body of work |
| [README-126] | Recent writing — 3–5 most relevant pieces, linked, dated implicitly by ordering |
| [README-127] | Connect block — canonical channels (website, X, LinkedIn, professional) |
| [README-128] | Closing call-to-action — italicized, single sentence, opt-in |
| [README-129] | (reserved) |

### Family C: Process / Workflow (`process.md`)

| ID | Hook |
|----|------|
| [README-130] | Title + 1-line workflow scope |
| [README-131] | Structure / What's here table — paths + roles |
| [README-132] | Overview section (optional) — 1–2 paragraphs of context between the 1-liner and structure table, when needed |
| [README-133] | Workflow / Process section — links to skill that governs the workflow |
| [README-134] | Companion repositories table — peer process repos in the same org |
| [README-135] | Tooling derives layout instead of requiring machine paths |
| [README-136] | License section — Apache 2.0 link or per-org standard |
| [README-137] | No installation block, no badges, no Quick Start (this is not a software product) — carve-out for repos that ship an executable |
| [README-138] | Length budget — 30–50 lines typical; >80 lines suggests content belongs in DocC or `Research/` — carve-out for repos that ship an executable |
| [README-139] | (reserved) |

### Family E: Sub-Package Library (`sub-package.md`)

| ID | Hook |
|----|------|
| [README-001] | Required inventory and recommended sequence |
| [README-002] | Maturity tiers (Minimum / Standard / Complete) |
| [README-003] | Development status badge |
| [README-004] | CI badge |
| [README-005] | Swift Package Index badges |
| [README-006] | One-liner and opening contract |
| [README-007] | Key Features format |
| [README-008] | Installation format |
| [README-009] | Quick Start requirements |
| [README-010] | Architecture section |
| [README-011] | Platform Support table |
| [README-012] | Performance documentation |
| [README-013] | Error Handling section |
| [README-014] | Related Packages organization |
| [README-015] | Optional sections |
| [README-016] | Prohibited content |
| [README-017] | Formatting rules |
| [README-018] | Org-level inventory README (DEPRECATED in v3.0.0 — workspace has no monorepos; content absorbed by [README-111], [README-113], [README-008]) |
| [README-019] | Sub-package README is self-contained — full per-package GH repo URL in installation, no nested-package reference |
| [README-021] | Maintenance obligations |
| [README-022] | Code examples in README |
| [README-024] | Motivated examples |
| [README-025] | Scope boundary (package vs ecosystem) |
| [README-027] | Stability section operational form |
| [README-029] | Six audience-inversion patterns and their canonical rewrites — KEEP/COMPRESS/RELOCATE/DELETE verdict taxonomy per paragraph |
| [README-040] | Community section (public packages — auto-generated discussion-link marker block) |

### Family F: Placeholder / Scaffold (`placeholder.md`)

| ID | Hook |
|----|------|
| [README-150] | Minimum content — title + 1-line scope + status |
| [README-151] | Status vocabulary — `namespace-reservation`, `scaffold`, `unnecessary`, `pre-implementation` |
| [README-152] | Explicit "this is scaffolding" signal |
| [README-153] | Graduation criteria — when a placeholder becomes Family E |
| [README-154] | (reserved) |
| [README-155] | (reserved) |

### Family G: Org Profile (`org-profile.md`)

Three org tiers within one family file; the tier determines which subset of rules applies.

#### All tiers

| ID | Hook |
|----|------|
| [README-020] | Org profile README structural baseline (migrated from v2.1.0) |
| [README-115] | Visibility markers (public / private) on linked repos |
| [README-116] | No installation block at org level (install belongs in package READMEs) |
| [README-117] | Tier-aware navigation — link parent (org-of-orgs leaf → its umbrella) and children (top-level → org-of-orgs; org-of-orgs → leaves) |
| [README-118] | (reserved) |
| [README-119] | (reserved) |

#### Top-level org tier (e.g., swift-institute)

| ID | Hook |
|----|------|
| [README-100] | Ecosystem brain pitch — what the umbrella exists to coordinate (no code packages live here) |
| [README-101] | Process-repo inventory — link out to canonical workflow repos (Skills, Scripts, Research, Audits, Blog, Experiments) |
| [README-102] | Outward links to domain umbrellas (org-of-orgs) |
| [README-103] | No package catalog (no code lives in a top-level org) |
| [README-104] | (reserved) |

#### Org-of-orgs tier (e.g., swift-standards, swift-law, rule-law)

| ID | Hook |
|----|------|
| [README-105] | Domain pitch — what specifications, jurisdictions, or categories the umbrella covers |
| [README-106] | Sub-category grouping — one section per spec body / jurisdiction / category (e.g., `## RFC` / `## ISO` / `## IETF`) |
| [README-107] | Outward links to leaf orgs in the umbrella |
| [README-108] | Per-sub-category package list with 1-line role |
| [README-109] | (reserved) |

#### Leaf org tier (e.g., swift-primitives, swift-foundations, swift-nl-wetgever)

| ID | Hook |
|----|------|
| [README-110] | Org pitch — what the org's packages collectively enable |
| [README-111] | Curated "Start here" catalog + native repo-tab filter routing; no exhaustive link-walls above ~20 repos |
| [README-112] | Per-package consumer install pointer |
| [README-113] | Layered architecture diagram (when applicable, e.g., 21-tier swift-primitives) |
| [README-114] | Org pinned repositories — six slots spanning capability dimensions |

### CI/CD Contract (`ci-automation.md`)

| ID | Hook |
|----|------|
| [README-160] | Author / automation boundary — what humans write vs what CI generates |
| [README-161] | Presence sweep — README must exist per family expectation matrix |
| [README-162] | Structure linter contract — required sections per family |
| [README-163] | Badge format validator — order, status values, SPI URL shape |
| [README-164] | Installation-snippet currency — version drift detection |
| [README-165] | Cross-repository link validator — canonical repository identities |
| [README-166] | Inventory auto-generation — package tables derived from `Package.swift` |
| [README-167] | Reporting shape — drift surfaces as a tracking issue (mirror sync-metadata-nightly) |
| [README-168] | Discussion-link auto-generation and validation (cross-refs **github-repository** [GH-REPO-090..093]) |
| [README-169] | (reserved) |
| [README-170] | Composed-example empirical validation — real call-site citation or coordinator-built scratch package, not `swiftc -parse` alone |

---

## Cross-References

- **documentation** skill — Inline DocC and `.docc` catalogue conventions.
- **swift-institute** skill — Five-layer architecture (referenced by [README-025] in `sub-package.md` as the content that does NOT belong in sub-package READMEs).
- **github-repository** skill — `.github/metadata.yaml` source-of-truth, sync-metadata orchestrator (consumed by `ci-automation.md`); `[GH-REPO-090..093]` discussion-thread rules grounded by [README-040] and [README-168].
- **code-surface** skill [API-NAME-001a] — Precedent for the Decision test pattern.
- **code-surface** skill [API-ERR-001] — Typed throws requirement that grounds [README-013] in `sub-package.md`.
- **skill-lifecycle** — Navigation-hub pattern that this skill adopts in v3.0.0.
- Research: `swift-institute/Research/package-readme-standard.md` (Tier 2, 2026-04-21) — ecosystem audit.
- Research: `swift-institute/Research/cohort-readme-evaluator-pass.md` (2026-05-01) — audience-inversion convergence.
- Research: `swift-institute/Research/readme-skill-design.md` (SUPERSEDED) — original v1.0 design.
- Memory: an internal feedback note — six audience-inversion patterns + canonical rewrites.
