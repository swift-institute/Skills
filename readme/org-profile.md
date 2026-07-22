---
name: readme/org-profile
description: |
  Family G rules — GitHub organization profile README content, with three
  org-tier sub-rules (top-level, org-of-orgs, leaf). Apply when authoring or
  reviewing the README at <org>/.github/profile/README.md (the file GitHub
  renders at github.com/<org>). Distinguishes the institutional voice from
  user profiles (Family A) and from per-repo READMEs (Families C, E, F).

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
---

# Org Profile README

Family G rules. Authoring contract for the README that GitHub renders at `github.com/<org>` — the org's `.github/profile/README.md`. The reader is a visitor landing on the organization's page, evaluating what the org coordinates, who maintains it, and where to go next. The README is the org's public identity card.

Loaded on demand from the **readme** skill hub (`SKILL.md`). The two universal meta-rules — [README-023] Evaluator's Lens and [README-026] No Internal Rule-ID Citations — apply to this family and live in the hub.

**Scope**: All `<org>/.github/profile/README.md` files for organization accounts in the ecosystem. (Observed per-org state as of 2026-05-01: rationale archive §Family-G-context.)

The org profile is forced by GitHub: organization accounts use `.github/profile/README.md` for the rendered profile; there is no equivalent at any other path.

Full evicted rationale, provenance, and extra example variants for this family: the rationale archive (`Readme Skill Rationale Archive`), referenced below.

---

## Voice

Org profile READMEs operate in an institutional, third-person register. Every paragraph answers the org-tier-specific evaluation question — see [README-023] Evaluator's Lens in the hub for the per-tier matrix.

| Element | Convention |
|---|---|
| Person | Third-person institutional. "Swift Institute is …", "These packages …". First-person plural ("we") is permitted in the Overview / mission section when the org-as-collective is the agent ("We believe rules deserve to be written …" — observed in swift-standards). First-person singular ("I") is forbidden — that's Family A territory. |
| Tense | Present tense for what the org *is*; future tense only inside an explicit Status / "Release in progress" disclosure. |
| Marketing language | Permitted with substance — the org's pitch belongs here. The marketing-without-substance prohibition still applies per [README-016]. |
| Code examples | Forbidden — the org profile is navigation, not documentation. Code belongs in per-package READMEs. |
| Internal rule-IDs in prose | Forbidden per [README-026]. |
| Length | ~30–60 lines based on the two well-formed observed instances (swift-institute: 59 lines; swift-standards: 30 lines). > 100 lines suggests content belongs in DocC, the website, or a per-repo README. swift-institute's profile (59 lines) is the canonical upper-end reference. |

The voice contrasts with adjacent families:

- vs Family A (user profile): user is first-person and personal; org is third-person and institutional.
- vs Family E (sub-package): org profile pitches the whole collection; sub-package pitches one package's adoption decision.

---

## Why Three Tiers Exist

The org-tier hierarchy is described in `SKILL.md`'s `## Org Topology` section. Three tiers, with examples:

| Tier | Examples | What lives here |
|---|---|---|
| Top-level | `swift-institute` | The ecosystem brain — process repos, conventions, research. No code packages. |
| Org-of-orgs | `swift-standards`, `swift-law`, `rule-law` | Conceptual umbrella over a domain. May contain its own packages AND link outward to per-authority sub-orgs. |
| Leaf | `swift-primitives`, `swift-foundations`, `swift-nl-wetgever`, `swift-us-nv-legislature`, plus per-authority orgs (`swift-ietf`, `swift-iso`, `swift-w3c`, `swift-whatwg`, single-package orgs for IEEE/IEC/ECMA/INCITS/ARM/Intel/RISC-V/Microsoft) | Where actual code packages live, one repo per package. |

The three tiers serve different evaluator questions — same family, different content because the visitor's purpose differs (full text: rationale archive §Family-G-context).

---

## All-Tier Rules

These rules apply to every org profile regardless of tier.

### [README-020] Org Profile README Structural Baseline

**Statement** (migrated from v2.1.0): GitHub organization profile READMEs (`.github/profile/README.md`) are a distinct artifact from package READMEs. They render on the GitHub organization landing page and SHOULD include:

1. Organization name as H1 (proper-name title-cased: `# Swift Institute`, not `# swift-institute`)
2. One-liner describing the org's role
3. Overview / pitch section
4. Tier-specific content (see per-tier sections below)
5. Status / current-state disclosure (when the org is pre-public or partially released)
6. License section (Apache 2.0 link or equivalent)

Org profile READMEs MUST NOT include: installation instructions, code examples, badges, or per-package README content. Those belong in the per-package READMEs the org profile links to.

**Rationale**: The org profile is navigation, not documentation — borrowing per-package conventions creates the false impression that the org-page itself is something to install or import (full text: rationale archive §[README-020]).

**Cross-references**: [README-016] in `sub-package.md` (marketing-language prohibition still applies).

---

### [README-115] Visibility Markers on Linked Repos

**Statement**: When the org profile links to specific repos that are not yet public, the README MUST mark them as such — either with an inline marker or with a status disclosure paragraph. External readers MUST NOT click on a link that 404s.

**Correct (inline marker)**:

```markdown
| Layer | Organization | Role |
|-------|--------------|------|
| 1 | [swift-primitives](https://github.com/swift-primitives) | Atomic building blocks |
| 4 | Components (private — planned) | Opinionated assemblies |
```

**Correct (status disclosure paragraph)**:

```markdown
> **Release in progress.** The organization links above are being made world-readable over the coming weeks. Some may currently 404; they resolve as each layer's release lands.
```

(The blockquote form is the recommended shape when multiple links are pending.)

**Incorrect**:

```markdown
| Layer | Organization |
|-------|--------------|
| 4 | [Components](https://github.com/swift-components) |  <!-- ❌ Live link to a 404 — visitor cannot tell from the markup -->
```

**Decision test**: For each link in the README, can an unauthenticated external reader click through and see real content? If no, mark the link or absorb it into a status disclosure.

**Rationale**: Org profile READMEs are the ecosystem's front door — broken links read as carelessness, and the blockquote-disclosure pattern handles staged releases without per-link maintenance (full text: rationale archive §[README-115]).

**Cross-references**: [README-014] in `sub-package.md` (analogous public+tagged constraint for sub-package Related Packages sections).

---

### [README-116] No Installation Block at Org Level

**Statement**: Org profile READMEs MUST NOT include a Package.swift dependency block, target configuration block, or any other code-level install snippet — install instructions belong in the per-package README the org profile links to.

**Correct (the org profile points to packages; install lives in the package README)**:

```markdown
| If you want to... | Go to |
|-------------------|-------|
| Use atomic primitives | [swift-primitives](https://github.com/swift-primitives) |
```

**Incorrect** (org-level install block — borrowed from Family E):

```markdown
## Installation

\```swift
dependencies: [
    .package(url: "https://github.com/swift-institute/swift-institute.git", from: "0.1.0")
]
\```

<!-- ❌ swift-institute is not a package; this URL is wrong by construction -->
```

**Enforcement**: Mechanical — `validate-readme.py:238` (flags a literal `## Installation` section in the org-profile README). Invoked by `validate-readme.yml` on public-repo PR/push. Scope: Family G. Discipline: `Audits/PROMOTE-readme-annotations-2026-07-06.md`. [VERIFICATION: WF validate-readme.py:238]

**Cross-references**: [README-008] in `sub-package.md`.

---

### [README-117] Tier-Aware Navigation

**Statement**: Org profile READMEs SHOULD include outward-pointing links to adjacent tiers — top-level orgs link out to org-of-orgs / leaf orgs they coordinate; org-of-orgs link both up to their parent top-level (when one exists) and down to leaf orgs they umbrella; leaf orgs link up to their parent org-of-orgs or top-level (when one exists).

**Correct (top-level pointing down)** — observed in `swift-institute/.github/profile/README.md`'s "Where to go next" table:

```markdown
## Where to go next

| If you want to... | Go to |
|-------------------|-------|
| Use atomic primitives (buffer, geometry, algebra, memory, kernel) | [swift-primitives](https://github.com/swift-primitives) |
| Consume an RFC or ISO specification | [swift-ietf](https://github.com/swift-ietf), [swift-iso](https://github.com/swift-iso), or the relevant per-authority org |
| Use composed building blocks (IO, HTML, CSS, SVG, PDF) | [swift-foundations](https://github.com/swift-foundations) |
```

(Leaf-pointing-up "Part of Swift Institute" variant: rationale archive §[README-117].)

**Decision test**: Could a visitor who landed at the wrong tier (e.g., arrived at swift-primitives looking for the ecosystem overview) navigate to the right tier in one click? If no, the navigation is incomplete.

**Rationale**: The three tiers form a graph that visitors traverse; each org profile being a navigation node lets visitors recover from arriving at the wrong page (full text: rationale archive §[README-117]).

---

### [README-118] (reserved)

---

### [README-119] (reserved)

---

## Top-Level Org Tier (e.g., swift-institute)

A top-level org coordinates the ecosystem; it does not host code packages. The visitor's question is "What does this ecosystem coordinate and where do I go next?"

### [README-100] Ecosystem Brain Pitch

**Statement**: Top-level org profiles MUST open with a 1-line scope and a 1–2 paragraph explanation of what the ecosystem coordinates and what the unifying principle is. The ecosystem-brain framing distinguishes this tier from leaf orgs that host code.

**Correct** (observed in swift-institute):

```markdown
# Swift Institute

A layered Swift package ecosystem organized around shared conventions.

## What this is

Swift Institute is a set of layered Swift packages organized as separate GitHub organizations, one per layer. The layers share dependency rules, naming conventions, error handling, memory ownership, and API shape — so that compile-time guarantees hold across the entire stack rather than stopping at package boundaries.
```

**Constraints**:

- The 1-liner names the org's coordinating role (not its code, since there is no code).
- The pitch identifies the unifying principle (e.g., "shared conventions", "layered architecture", "compile-time guarantees across the stack") that justifies the ecosystem's existence.
- The pitch MUST NOT promise specific deliverables or roadmaps.

**Decision test**: After reading the pitch, can a visitor explain in one sentence why this ecosystem exists as an ecosystem rather than as independent packages? If no, the pitch hasn't earned its place.

**Rationale**: Top-level orgs justify their existence by the value of coordination; the pitch makes the coordination visible (full text: rationale archive §[README-100]).

**Cross-references**: [README-101], [README-102].

---

### [README-101] Process-Repo Inventory

**Statement**: Top-level org profiles SHOULD link to the process and tooling repos within the org that govern how the ecosystem operates — Skills, Scripts, Research, Audits, Blog, Experiments, swift-institute.org. The inventory is selective: link the repos a visitor benefits from knowing about, omit private-internal-only repos.

**Correct (selective navigation table)** — observed pattern:

```markdown
| If you want to... | Go to |
|-------------------|-------|
| Read the website, architecture overview, or blog | [swift-institute.org](https://swift-institute.org) |
| Browse design rationale | [swift-institute/Research](https://github.com/swift-institute/Research) |
| Browse the empirical receipts behind technical claims | [swift-institute/Experiments](https://github.com/swift-institute/Experiments) |
| Report a security vulnerability | See the [security policy](https://github.com/swift-institute/.github/blob/main/SECURITY.md) |
```

**Constraints**:

- Each row pairs a visitor intent with a destination. The intent column drives the choice of which repos to include.
- Private repos (Audits, Blog when private, Skills) MAY be linked when their existence is publicly relevant but the content is private; mark per [README-115].
- Repos MUST NOT be listed without an intent — a flat list of every process repo dilutes the navigation.

**Decision test**: For each row, would a visitor with that intent benefit from clicking through? If the row's destination doesn't serve the stated intent, drop the row.

**Rationale**: A flat process-repo list is a "what's here" inventory; an intent-driven table is a routing affordance that directs visitors arriving with a question to the right artifact (full text: rationale archive §[README-101]).

---

### [README-102] Outward Links to Domain Umbrellas (Org-of-Orgs)

**Statement**: Top-level org profiles SHOULD link out to the org-of-orgs and leaf orgs that the top-level org coordinates. The outward links sit either in the layer table (when the layering is the org-tier hierarchy) or in the navigation table (per [README-101]).

**Correct (layer table — observed in swift-institute)**:

```markdown
| Layer | Organization | Role |
|-------|--------------|------|
| 1 | [swift-primitives](https://github.com/swift-primitives) | Atomic building blocks — buffer, geometry, algebra, memory, kernel |
| 2 | [swift-standards](https://github.com/swift-standards) + per-authority orgs | Specification implementations |
| 3 | [swift-foundations](https://github.com/swift-foundations) | Composed building blocks — IO, HTML, CSS, SVG, PDF, networking |
```

**Correct (org-of-orgs disclosure paragraph)** — observed pattern:

```markdown
Layer 2 is an organization of organizations. Each standards authority has its own GitHub organization hosting the packages it governs: [swift-ietf](https://github.com/swift-ietf) (RFCs), [swift-iso](https://github.com/swift-iso), [swift-w3c](https://github.com/swift-w3c), [swift-whatwg](https://github.com/swift-whatwg), plus single-package organizations for IEEE, IEC, ECMA, INCITS, ARM, Intel, RISC-V, and Microsoft.
```

**Constraints**:

- When the top-level coordinates an org-of-orgs, the org-of-orgs is named alongside its sub-orgs (so the visitor can navigate either to the umbrella or directly to a sub-org).
- The layer table form is preferred when the org-tier hierarchy maps cleanly to the ecosystem's layers.

**Decision test**: From the top-level profile, can a visitor reach any leaf org in one or two clicks? If no, the outward navigation is incomplete.

**Rationale**: Top-level orgs are the entry point for visitors who don't know which leaf org holds what they need; the dual presentation (layer table + org-of-orgs disclosure paragraph) is the recommended form (full text: rationale archive §[README-102]).

---

### [README-103] No Package Catalog at the Top Level

**Statement**: Top-level org profile READMEs MUST NOT include a list of individual Swift packages. Package catalogs belong in the leaf org's profile (per [README-111]) or the org-of-orgs's profile (per [README-108]). The top-level org has no packages of its own to catalog.

**Incorrect**:

```markdown
## Packages

- swift-buffer-primitives
- swift-memory-primitives
- swift-property-primitives
- ... (60+ packages)  <!-- ❌ Package catalog at the top level is wrong tier -->
```

**Decision test**: Does a row or list entry refer to a Swift package that produces an importable module? If yes, that entry belongs at the leaf-tier or org-of-orgs-tier profile, not at the top level.

**Rationale**: Top-level orgs coordinate rather than host code — a package list at the top level invites the visitor to expect installable artifacts the org doesn't provide (full text + correct variant: rationale archive §[README-103]).

---

### [README-104] (reserved)

---

## Org-of-Orgs Tier (e.g., swift-standards, swift-law, rule-law)

An org-of-orgs is a conceptual umbrella over a domain. It may host its own packages AND/OR link outward to per-authority sub-orgs. The visitor's question is "What domain does this umbrella cover and which sub-orgs implement it?"

### [README-105] Domain Pitch

**Statement**: Org-of-orgs profiles MUST open with a 1-liner naming the domain and a pitch (1–4 paragraphs) explaining the unifying principle that justifies the umbrella's existence — what makes these specifications, jurisdictions, or categories belong together.

**Correct** (observed in swift-standards, with caveats — see [README-106]):

```markdown
# Swift Standards

Swift implementations of standards and protocols.

## Overview

Rules sit at the heart of every system we build and rely on. When those rules are clear and consistently expressed, everything built atop them becomes simpler, safer, and more predictable. We believe rules deserve to be written in a form that leaves no ambiguity — where structure, constraints, and intent can be validated rather than interpreted.

Swift's type system makes that possible. By modeling the logic of standards directly in types, authoritative specifications become precise, executable rules that the compiler can enforce.
```

**Constraints**:

- The 1-liner names the domain ("standards and protocols", "legal encoding", "rule-of-law infrastructure"), not the org structure.
- The pitch identifies what makes the domain a domain — the unifying principle (e.g., "specifications deserve unambiguous machine-readable form") rather than just what the umbrella contains.
- First-person plural ("we") is permitted in the pitch when the org-as-collective takes a stance.

**Decision test**: After reading the pitch, can a visitor explain why these specifications/jurisdictions/categories belong together rather than each living independently? If no, the umbrella's reason-for-existing isn't clear.

**Rationale**: Org-of-orgs justify their existence by the unifying domain principle — without it, the umbrella reduces to a flat list of unrelated specs (full text: rationale archive §[README-105]).

**Cross-references**: [README-100] (analogous pitch at the top-level tier).

---

### [README-106] Sub-Category Grouping (When Applicable)

**Statement**: When the umbrella's contents naturally group by sub-category — spec body, jurisdiction, category — the org profile MUST include those groupings as section headings (`## RFC` / `## ISO` / `## IETF`, or `## Federal Statutes` / `## State Statutes`, etc.). When the umbrella is genuinely flat (no natural grouping), use a single inventory table per [README-108].

**Correct (hypothetical for swift-standards)**:

```markdown
## Coverage by spec authority

### IETF (RFCs)

Implementations live at [swift-ietf](https://github.com/swift-ietf):

- [swift-rfc-3986](url) — URI Generic Syntax
- [swift-rfc-4122](url) — UUID URN Namespace
- [swift-rfc-5322](url) — Internet Message Format
- ...

### ISO

Implementations live at [swift-iso](https://github.com/swift-iso):

- [swift-iso-8601](url) — Date and Time
- [swift-iso-32000](url) — PDF
- ...

### W3C / WHATWG

- [swift-w3c](https://github.com/swift-w3c) — W3C specifications
- [swift-whatwg](https://github.com/swift-whatwg) — WHATWG specifications
```

**Decision test**: Could a visitor scanning the org profile answer "is RFC 5322 covered?" If no, the grouping or inventory is missing.

**Rationale**: Org-of-orgs are useful precisely because they organize a domain; hiding the organization defeats the umbrella's purpose (observed anti-pattern instance: rationale archive §[README-106]).

**Cross-references**: [README-108] (per-sub-category package list); [README-105] (the pitch the grouping serves).

---

### [README-107] Outward Links to Leaf Orgs

**Statement**: When the org-of-orgs umbrella points to per-authority leaf orgs (each leaf hosting the spec body's packages), the umbrella's profile MUST link to each leaf org by name with a 1-line role description.

**Correct (recommended shape)**:

```markdown
## Companion organizations

Each spec authority has its own GitHub organization hosting the packages it governs:

| Organization | Role |
|---|---|
| [swift-ietf](https://github.com/swift-ietf) | IETF RFCs |
| [swift-iso](https://github.com/swift-iso) | ISO specifications |
| [swift-w3c](https://github.com/swift-w3c) | W3C specifications |
| [swift-whatwg](https://github.com/swift-whatwg) | WHATWG specifications |
| [swift-ieee](https://github.com/swift-ieee) | IEEE standards (single-package) |
| [swift-arm](https://github.com/swift-arm) | ARM architecture (single-package) |
```

**Constraints**:

- Each row links to a real GH org. Pending/private orgs are marked per [README-115].
- Single-package orgs (IEEE, ARM, etc.) MAY be grouped into a single row or listed separately depending on density.

**Decision test**: From the umbrella's profile, can a visitor navigate to any per-authority leaf org in one click? If no, the link-out is incomplete.

**Rationale**: Visitors arrive at the conceptual umbrella expecting code, but the code lives in the per-authority leaves; the link-out resolves the redirection in one click (full text: rationale archive §[README-107]).

---

### [README-108] Per-Sub-Category Package List

**Statement**: When the umbrella hosts its own packages (rather than only pointing to leaf orgs), the org profile MUST include an inventory of those packages, optionally grouped per [README-106].

**Correct (flat inventory)** — for an umbrella with a small number of packages and no natural sub-categorization:

```markdown
## Packages

| Package | Role |
|---|---|
| [swift-law](url) | Type-level common base for legal encoding |
| [swift-judiciary](url) | Court and judiciary type system |
```

**Correct (grouped — see [README-106])**: per the example in [README-106].

**Constraints**:

- Each row provides 1-line role description sufficient for the visitor to decide whether to investigate further.
- Status markers (per [README-115]) for non-public or unreleased packages.

**Rationale**: When the umbrella hosts code, the visitor wants the catalog; the inventory makes it discoverable.

**Cross-references**: [README-106], [README-111] (analogous catalog at the leaf-org tier).

---

### [README-109] (reserved)

---

## Leaf Org Tier (e.g., swift-primitives, swift-foundations, swift-nl-wetgever, per-authority orgs)

A leaf org hosts the actual code packages. The visitor's question is "What do this org's packages collectively enable and which one do I want?"

### [README-110] Leaf Org Pitch

**Statement**: Leaf-org profiles MUST open with a 1-liner naming what the org's packages collectively enable, and a 1–2 paragraph pitch positioning the org within the parent ecosystem.

**Correct (recommended shape)**:

```markdown
# Swift Primitives

Atomic building blocks for Swift — buffer containers, geometry types, memory regions, kernel syscalls, and value-generic primitives across 21 tiers of layered dependency. 126 packages, 304 library products.

## Part of Swift Institute

swift-primitives is the Layer 1 organization within the [Swift Institute](https://github.com/swift-institute) ecosystem. The packages here have no dependencies outside the Swift standard library; everything in higher layers composes against them.
```

**Constraints**:

- The 1-liner names the capability category (atomic primitives, composed foundations, Dutch legislature, Nevada statutes), not just the org's structural role.
- The "Part of <ecosystem>" paragraph positions the org within its parent (top-level or org-of-orgs) so visitors arriving from the parent's outward link land oriented.
- For per-authority leaf orgs (swift-ietf, swift-iso, etc.), the pitch names the spec body and links back to the org-of-orgs umbrella (swift-standards).

**Decision test**: After reading the pitch, can a visitor explain what differentiates this leaf from sibling leaves in the same parent? If swift-primitives' pitch could equally describe swift-foundations, the differentiation is missing.

**Rationale**: Leaf-org profiles compete for the visitor's attention with sibling leaves; the pitch makes the org's distinctive contribution visible and the "Part of" framing anchors it to its parent (observed anti-pattern instance: rationale archive §[README-110]).

---

### [README-111] Curated Package Catalog with Native Browse Routing

**Statement**: Leaf-org profiles MUST include a curated package catalog: a "Start here" table of 5–8 packages with a one-line role each, chosen to span the org's distinct capability dimensions (not merely its most-starred repos). Above ~20 repos, the profile MUST NOT enumerate packages exhaustively — a names-only link-wall is strictly less informative than GitHub's native Repositories tab (which renders description, stars, language, and activity from repo metadata) and goes stale on every rename. Instead the profile MUST route into the native tab with filter links (`https://github.com/orgs/<org>/repositories?q=<term>`), one per major domain. Orgs at or below ~20 repos MAY carry a full catalog table with one-line roles, grouped by tier or domain when a documented layering exists.

**Correct (recommended shape — large leaf org)**:

```markdown
## Start here

| Package | What it gives you |
|---|---|
| [swift-pdf](https://github.com/swift-foundations/swift-pdf) | PDF document generation from HTML views and Markdown |
| [swift-io](https://github.com/swift-foundations/swift-io) | Async I/O executor that isolates blocking syscalls |
| ... 3–6 more rows spanning distinct capability dimensions ... | ... |

## Browse everything

The [repositories tab](https://github.com/orgs/swift-foundations/repositories) lists every package with its description. Narrow it down:

[http](https://github.com/orgs/swift-foundations/repositories?q=http) · [html](https://github.com/orgs/swift-foundations/repositories?q=html) · [pdf](https://github.com/orgs/swift-foundations/repositories?q=pdf) · ...
```

**Incorrect**: an exhaustive names-only link list (`[swift-http] · [swift-http2] · [swift-http3] · ...` across a 100+-repo org) — duplicates the Repositories tab with less information per entry and a per-rename maintenance cost.

**Constraints**:

- Every Start-here row links to a live repo with a working README; placeholders (Family F) are excluded, or marked per [README-115] in small-org full catalogs.
- The role column is 1-line; multi-line descriptions belong in the package's own README.
- Filter links use terms that match repo names or descriptions; the pattern presumes per-repo description hygiene (governed by the **github-repository** skill).
- Division of labor across the org page's three surfaces: pinned repos curate the first click ([README-114]), the profile README orients and routes, the Repositories tab is the exhaustive self-updating index. The README never duplicates what a lower surface renders better.

**Decision test**: For each catalog element, does it tell the visitor something the Repositories tab would not already show them one click away? Curated roles, grouping, and dimension-spanning selection do; bare name links do not.

**Rationale**: The catalog is the leaf org's primary navigation affordance, but exhaustive enumeration optimizes for a completeness the native tab already provides while sacrificing the scannability only curation provides. Breaking revision of the 2026-05-01 exhaustive-catalog form; provenance: principal direction 2026-07-02 (visitor-first org-page rewrite). Reference implementations: the live org profiles of [swift-foundations](https://github.com/swift-foundations) and [swift-primitives](https://github.com/swift-primitives) (large leaf), [swift-standards](https://github.com/swift-standards) (org-of-orgs, ≤20 full table retained), and the per-authority orgs ([swift-ietf](https://github.com/swift-ietf): Start-here + spec-number search routing at scale; full tables only on the smallest single-purpose orgs).

**Cross-references**: [README-018] in `sub-package.md` (DEPRECATED — content roles redistributed here, including the package-catalog role); [README-113] (architecture overlay); [README-114] (pinned repos); [README-166] in `ci-automation.md` (auto-generation targets the small-org full-table form and the mechanical columns of curated tables).

---

### [README-112] Per-Package Consumer Install Pointer

**Statement**: Leaf-org profiles MAY include a brief "How to use a package" pointer that explains the workspace's one-repo-per-package convention without inlining package-specific install snippets. The pointer prevents visitors from looking for a "swift-primitives" parent install URL that doesn't exist.

**Correct (recommended shape)**:

```markdown
## How to use a package

Each package in this organization is a separate Swift Package Manager package with its own GitHub repo. To depend on a package, follow the installation snippet in that package's README.

For example, to depend on `swift-property-primitives`:

\```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-property-primitives.git", from: "0.1.0")
]
\```

(See the package's README for current version, target configuration, and umbrella-vs-variant product choices.)
```

**Constraints**:

- The pointer states the one-repo-per-package convention explicitly (not all visitors will have read the swift-institute parent profile).
- The example uses a real package URL, but the visitor is directed to the package's README for current details rather than the org profile attempting to be a one-stop shop.
- The pointer MUST NOT enumerate install snippets for every package — that's what package READMEs are for.

**Decision test**: After reading the pointer, can a visitor who knows nothing about the workspace correctly form a `dependencies: [...]` block targeting any package in the org? If yes, the pointer earns its place. If the example would mislead, rewrite.

**Rationale**: The one-repo-per-package convention is non-obvious to visitors familiar with monorepo SPM packages; the pointer disambiguates, and the link-out keeps maintenance bounded (full text: rationale archive §[README-112]).

**Cross-references**: [README-008] in `sub-package.md`; [README-019] in `sub-package.md`.

---

### [README-113] Layered Architecture Diagram (When Applicable)

**Statement**: Leaf-org profiles SHOULD include a layered architecture diagram or table when the org has a documented internal layering. The diagram documents the cross-package dependency structure. When the org is flat (no layering), this rule does not apply.

**Correct (table form — recommended for swift-primitives)**:

```markdown
## Architecture

The 21-tier ordering organizes packages by dependency depth — Tier 0 packages depend only on the Swift standard library; Tier 20 packages compose all lower tiers. Tier assignments are computed deterministically: `tier(P) = max(tier(dep) for dep in deps(P)) + 1`. The full layering is documented at [Primitives Tiers](https://github.com/swift-primitives/swift-primitives/blob/main/Documentation.docc/Primitives%20Tiers.md).

| Tier | Examples | Role |
|---|---|---|
| 1 | buffer, memory, geometry | Atomic — no inter-package dependencies |
| 2 | property, ownership | Composed within Tier 1 |
| ... | ... | ... |
| 9 | (top tier) | Composes the full stack |
```

(ASCII-diagram variant for small layered stacks: rationale archive §[README-113].)

**Constraints**:

- The diagram or table MUST link to the canonical architecture documentation (DocC catalog or governing skill) rather than reproduce the full content inline.
- The form is chosen by what scans best: ASCII diagrams for small layered stacks (~5 layers); tables for larger stacks (21-tier swift-primitives).

**Decision test**: After viewing the diagram, can a visitor predict which tier a package belongs to from its name or role? If no, the diagram is decorative.

**Rationale**: The layering is load-bearing for visitors choosing which packages to depend on; surfacing it at the org profile prevents package-by-package discovery, and the single-source-of-truth link prevents drift (full text: rationale archive §[README-113]).

**Cross-references**: [README-010] in `sub-package.md` (intra-package architecture, distinct from the org-level layering documented here).

---

### [README-114] Organization Pinned Repositories

**Statement**: Orgs SHOULD fill GitHub's six pinned-repository slots, choosing pins that span the org's distinct capability dimensions rather than only its most-starred repos. Pins render above the profile README and are the org page's first curation surface — an empty pin row hands the visitor's first impression to an alphabetical repo list, and star-only pinning duplicates what the Repositories tab's star sort already shows.

**Constraints**:

- Each pin proves a different dimension, following the same selection logic as the Start-here table in [README-111]; the two surfaces may overlap but need not be identical.
- Pins are set in the org page UI ("Customize pins"); no public API mutation exists as of 2026-07, so pin state is manually maintained and SHOULD be re-checked at each org-profile review.

**Rationale**: The pin row is what a visitor sees before any prose; all four layer orgs had zero pins when this rule was authored (provenance: principal direction 2026-07-02, visitor-first org-page rewrite).

**Cross-references**: [README-111].

---

## Cross-References

- **readme** skill hub (`SKILL.md`) — Family routing matrix, universal meta-rules ([README-023], [README-026]), `## Org Topology` section (the source of the org-tier classification).
- **readme/sub-package** sibling — Family E rules; the destination for content that belongs in per-package READMEs rather than the org profile.
- **readme/user-profile** sibling — Family A rules; voice contrast (first-person personal vs third-person institutional).
- **readme/ci-automation** sibling — [README-166] auto-generates the package inventory from `Package.swift` files; reduces drift in the leaf-tier catalog.
- Provenance (per-tier canonical / partial / stub reference instances, observed 2026-05-01): rationale archive §Family-G-context.
