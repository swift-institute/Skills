---
name: readme/process
description: |
  Family C rules — process / workflow repo README structure, voice, table-driven
  shape, length budget. Apply when authoring or reviewing the README of a repo
  that documents a workflow, process, or workspace tooling rather than a software
  product (Skills, Scripts, Research, Audits, Blog, Experiments, Swift-Evolution,
  swift-institute.org).

layer: implementation

requires:
  - readme

applies_to:
  - swift-institute
---

# Process / Workflow README

Family C rules. Authoring contract for repos whose README describes a **workflow, process, or workspace tooling** — not a software product. The reader is a maintainer running or contributing to the workflow, not an evaluator deciding whether to integrate a Swift package.

Loaded on demand from the **readme** skill hub (`SKILL.md`). The two universal meta-rules — [README-023] Evaluator's Lens and [README-026] No Internal Rule-ID Citations — apply to this family and live in the hub.

**Scope**: All `<repo>/README.md` files in process/workflow repos. Today this is the swift-institute org's process repos: `Skills`, `Scripts`, `Research`, `Audits`, `Blog`, `Experiments`, `Swift-Evolution`, `swift-institute.org`. The rules generalize to any process repo in any org (e.g., a future `rule-law/Research`).

Full evicted rationale and extra example variants for this family: the rationale archive (`Readme Skill Rationale Archive`), referenced below.

---

## Voice

Process READMEs operate in a third-person, organizational register. Every paragraph answers "What does this workflow do and do I need it?" — see [README-023] Evaluator's Lens in the hub.

| Element | Convention |
|---|---|
| Person | Third-person, organizational. "These scripts coordinate …", "Each subdirectory is …", "The convention is documented at …". Implicit org-voice without first-person plural ("we") in declarative content. First-person plural is acceptable in the workflow-process narrative section when the org-as-collective is the agent. |
| Tense | Present tense for what the repo *is*; past tense for historical context (rare). |
| Marketing language | Forbidden. The reader is already a maintainer; pitching is unnecessary. |
| Code examples | Permitted only when they document the *workflow* (e.g., "run `swift-build package build` inside the experiment directory"), not when they advertise a capability. |
| Tables | Preferred for structure documentation. Two-column (path/role) is the typical shape. |
| Internal rule-IDs in prose | Forbidden per [README-026]. The Swift-Evolution README's reference to `[PITCH-PROC-001]` is a known instance; pending cleanup. |
| Author-side context | Forbidden. No "this repo evolved from …", no implementation autobiography. Process READMEs document the *current* shape and workflow only. |
| Length | Tight: 30–50 lines typical. > 80 lines suggests content belongs in a governing skill or a DocC article. |

The voice generalizes across process repos: a Skills README and a Blog README operate in the same register, even though the workflows they document differ.

---

## Structure

### [README-130] Title + 1-Line Workflow Scope

**Statement**: Process READMEs MUST open with an H1 title (the repo's role, not its lowercase repo name) and a single sentence describing the workflow's scope. The sentence MUST link the parent org or ecosystem by name. The 1-liner is the entire opening; no badges, no taglines, no mission paragraph.

**Title form**: title-cased proper name of the role.

| Repo | Title |
|---|---|
| `swift-institute/Skills` | `# Skills` |
| `swift-institute/Scripts` | `# Scripts` |
| `swift-institute/Audits` | `# Audits` |
| `swift-institute/Research` | `# Research` |
| `swift-institute/Experiments` | `# Experiments` |
| `swift-institute/Blog` | `# Blog` |
| `swift-institute/Swift-Evolution` | `# Swift Evolution` |
| `swift-institute/swift-institute.org` | `# swift-institute.org` |

(The last is an exception — the title matches the domain, not a role.)

**1-line scope form**: "<role-noun> for the [<parent-org>](<link>) ecosystem" or "<role-noun> documenting <X> for the [<parent-org>](<link>)".

**Correct**:

```markdown
# Skills

Canonical development conventions for the [Swift Institute](https://swift-institute.org) ecosystem — naming, errors, memory safety, testing, modularization, and more. Each skill is the canonical source for its area.
```

**Incorrect**:

```markdown
# swift-institute/Skills  <!-- ❌ Repo path as title -->

A repository for skills.  <!-- ❌ "A repository for…" anti-pattern; mirrors the [README-006] sub-package prohibition -->
```

**Decision test**: Does the 1-liner tell a reader who lands here cold "what is this directory and what role does it play in the ecosystem"? If no, rewrite.

**Rationale**: A process repo's identity is its role within an ecosystem; the title-cased role + parent-org-anchored 1-liner is the minimal contract, consistent across the eight observed swift-institute process repos (full text + extra variants: rationale archive §[README-130]).

---

### [README-131] Structure / What's Here Table

**Statement**: Process READMEs MUST include a structure table immediately after the 1-liner (or after a brief Overview if present per [README-132]). Two-column form: path/file/directory in the left column, role/contents in the right column. The table answers "what's in this repo and where".

The section heading is `## Structure`, `## Directory structure`, or `## What's here` — pick one that fits the repo's content. Use `## Structure` as the default.

**Correct** (two-column path/role):

```markdown
## Structure

| File | Contents |
|------|----------|
| [`_index.json`](_index.json) | Authoritative manifest of audit documents in this repo |
| [`audit.md`](audit.md) | The institute-level rolling audit |
| `*.md` | Older or topic-specific audit findings (consolidated into `audit.md` over time) |
```

**Incorrect**:

```markdown
## Structure

The repository is organized into directories. The `Draft/` directory holds drafts. The `Published/` directory holds published posts. <!-- ❌ Prose where a table is clearer -->
```

**Decision test**: Could a reader scanning only this table answer "where would I look to find X?" If no, the row descriptions are too thin.

**Rationale**: Process repos are inventory — a two-column path/role table answers the reader's lookup question scannably; prose lists fail to scan and single-column tables are equivalent to `ls` output (full text + extra variants: rationale archive §[README-131]).

---

### [README-132] Overview Section (Optional)

**Statement**: An `## Overview` section MAY appear between the 1-liner and the structure table when the repo's purpose requires 1–2 paragraphs of context that the 1-liner cannot carry. Omit when the 1-liner is sufficient.

**When to include**:

- The repo's role depends on a non-obvious convention (e.g., "audits document compliance violations against skills, one rolling audit per scope").
- The repo coordinates a workflow whose stages benefit from a paragraph of framing before the structure table.

**When to omit**:

- The role is self-evident from the title and 1-liner (Skills, Scripts).
- The structure table speaks for itself.

**Correct (Overview earns its place — Audits)**:

```markdown
## Overview

Audit reports document compliance violations, gaps, and remediation plans against the conventions defined in [swift-institute/Skills](https://github.com/swift-institute/Skills). Each scope (per-package, per-org, ecosystem-wide) gets exactly one `audit.md` per scope, updated in place.

The audit workflow itself is documented in the [`audit`](https://github.com/swift-institute/Skills/blob/main/audit/SKILL.md) skill.
```

**Incorrect (Overview adds no information beyond the 1-liner)**:

```markdown
## Overview

This repository contains skills.  <!-- ❌ The 1-liner already said this -->
```

**Decision test**: Could a reader skip the Overview and still understand the structure table that follows? If yes, the Overview is decorative; remove it.

**Rationale**: Three of eight observed process READMEs include an Overview, five do not — "include when the role-context warrants a paragraph; omit otherwise" matches observed practice (full text + extra variants: rationale archive §[README-132]).

**Cross-references**: [README-023]

---

### [README-133] Workflow / Process Section

**Statement**: Process READMEs SHOULD include a section that links to the governing skill, dashboard, or external process documentation when one exists. Section heading: `## Workflow`, `## Process`, or `## Browse` (for dashboard-backed corpora). The body links out and does not duplicate the skill's content inline.

**When the workflow is governed by a skill**:

```markdown
## Workflow

See the [`blog-process`](https://github.com/swift-institute/Skills/blob/main/blog-process/SKILL.md) skill for the full two-phase drafting and review workflow, the ideas index at [`_index.json`](_index.json), and the style guide at [`_Styleguide.md`](_Styleguide.md).
```

(Dashboard-backed `## Browse` and external-process `## Process` example variants: rationale archive §[README-133].)

**Incorrect** (rule-ID citations in prose — observed in current Swift-Evolution README at line 22, pending cleanup):

```markdown
## Process

The pitch phase is documented in the [`swift-evolution`](...) skill, which defines triggers ([PITCH-PROC-001]), evidence requirements ([PITCH-PROC-002]), scope analysis ([PITCH-PROC-003])...  <!-- ❌ Rule IDs in consumer prose; violates [README-026] -->
```

The corrected form names the workflow phases by their role rather than by rule ID.

**Decision test**: Does the link-out replace the need to read the skill? It should not. A process README's job is to point readers at the canonical workflow source, not to inline it.

**Rationale**: Workflow rules belong in the governing skill; inlining creates a duplicate that drifts — the link-out pattern is consistent across observed process READMEs (full text: rationale archive §[README-133]).

**Cross-references**: [README-026]

---

### [README-134] Companion Repositories Table

**Statement**: When the process repo coordinates with other process repos in the same org, a `## Companion repositories` (or `## Related Repositories`) table SHOULD list them with links and 1-line roles. Omit when the process repo stands alone.

**Correct**:

```markdown
## Companion repositories

| Repository | Contents |
|------------|----------|
| [swift-institute/swift-institute.org](https://github.com/swift-institute/swift-institute.org) | Website + DocC catalog |
| [swift-institute/Research](https://github.com/swift-institute/Research) | Design rationale and trade-off analysis |
| [swift-institute/Experiments](https://github.com/swift-institute/Experiments) | Standalone Swift packages backing technical claims |
| [swift-institute/Scripts](https://github.com/swift-institute/Scripts) | Workspace tooling |
```

**Constraints**:

- Linked repos MUST be public; if a companion repo is private, it MUST be marked explicitly rather than presented as a live link.
- Repo names match the GitHub repo path (org/name) or shorthand (just name) — pick one and stay consistent within the table.

**Decision test**: Would a maintainer arriving at this repo have value from knowing about the linked repos? If yes, the table earns its place. If the repo stands alone (e.g., a single-purpose Scripts repo with no peer process repos), omit.

**Rationale**: Process repos in the swift-institute org form a network; cross-linking it in each repo's README orients arriving maintainers without requiring them to navigate the org page (full text: rationale archive §[README-134]).

---

### [README-135] Layout Assumption (When Scripts Depend on Disk Shape)

**Statement**: When the repo contains scripts or tooling that depend on a specific disk layout, a `## Layout assumption` section MUST document that layout. Omit when the repo's content does not depend on disk position.

**When to include**:

- The repo is a Scripts/tooling repo whose scripts use relative paths (e.g., `~/Developer/<org>/...`).
- The README documents how to run scripts that assume a particular clone-mirror structure.

**Correct (Scripts repo)**:

```markdown
## Layout assumption

The scripts expect the `swift-institute` org as a directory under `~/Developer/`, holding its sub-repos as siblings:

\```
~/Developer/
├── swift-institute/
│   ├── Scripts/                 (this repo)
│   ├── Skills/
│   ├── swift-institute.org/
│   ├── Research/
│   ├── Experiments/
│   └── …
├── swift-primitives/            (clone-mirror of the swift-primitives org)
├── swift-standards/             (clone-mirror of the swift-standards org)
└── swift-foundations/           (clone-mirror of the swift-foundations org)
\```

`SCRIPT_DIR` resolves to `swift-institute/Scripts/`. From there:

- `ORG_ROOT` (org dir) is `swift-institute/`
- `DEVELOPER_DIR` is `~/Developer/`
- Other ecosystem clone-mirrors live at `$DEVELOPER_DIR/swift-*` (flat); the institute's Skills repo lives at `$ORG_ROOT/Skills`.
```

**Decision test**: Does running this repo's scripts/tooling break if the disk layout differs from what the README implies? If yes, document the layout. If the repo has no scripts (Skills, Audits, Research, Experiments, Blog, Swift-Evolution), omit.

**Rationale**: Without the layout block, a fresh maintainer cannot run layout-dependent scripts; no other observed process repo includes this section because no other observed process repo needs it (full text: rationale archive §[README-135]).

---

### [README-136] License Section

**Statement**: Process READMEs SHOULD end with a `## License` section linking to the license file. Apache 2.0 is the ecosystem default for swift-institute process repos.

**Correct**:

```markdown
## License

[Apache 2.0](LICENSE.md).
```

**Variants permitted** (when the repo's license differs from the ecosystem default — rare):

```markdown
## License

This repository is private; no public license. See organization terms.
```

**Decision test**: Does the repo have a `LICENSE.md` or `LICENSE` file? If yes, link to it. If no, the License section MAY be omitted (Blog, Swift-Evolution observed without it).

**Rationale**: Six of eight observed process READMEs end with a License section. The two exceptions (Blog, Swift-Evolution) omit it; both are private or pre-public. The link is the entire section — no body text, no commentary.

---

### [README-137] No Installation, No Badges, No Quick Start

**Statement**: Process READMEs MUST NOT include an Installation block, any badge (development status, CI, or SPI), a Quick Start section, or other software-product-shaped sections (Architecture, Platform Support, Performance, Error Handling, Stability) — process repos are not software products.

**Enforcement**: Mechanical — `validate-readme.py:190,194,198` (flags a literal `## Installation` section, any badge line, or a `## Quick Start` section; the remaining forbidden sections are not yet mechanically checked). Invoked by `validate-readme.yml` on public-repo PR/push. Scope: Family C. Discipline: `Audits/PROMOTE-readme-annotations-2026-07-06.md`. [VERIFICATION: WF validate-readme.py:190]

**Cross-references**: [README-003], [README-004], [README-005], [README-009], [README-010], [README-011], [README-013]

---

### [README-138] Length Budget

**Statement**: Process READMEs SHOULD be 30–50 lines; exceeding 80 lines flags content that belongs in a governing skill, a DocC article, or `Research/`.

**Enforcement**: Mechanical — `validate-readme.py:204` (flags READMEs exceeding 80 lines). Invoked by `validate-readme.yml` on public-repo PR/push. Scope: Family C. Discipline: `Audits/PROMOTE-readme-annotations-2026-07-06.md`. [VERIFICATION: WF validate-readme.py:204]

---

### [README-139] (reserved)

---

## Cross-References

- **readme** skill hub (`SKILL.md`) — Family routing matrix, universal meta-rules ([README-023], [README-026]).
- **readme/sub-package** sibling — Family E rules; for contrast, the rules process READMEs deliberately do NOT inherit (badges, Quick Start, Architecture, etc.).
- **documentation** skill — Where workflow details belong when they outgrow the README's length budget.
- Skill repos that govern observed process READMEs: `audit`, `blog-process`, `research-process`, `experiment-process`, `swift-evolution`, `reflect-session`.
