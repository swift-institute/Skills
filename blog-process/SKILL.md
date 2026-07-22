---
name: blog-process
description: |
  Blog post workflows for ideation, drafting, review, and publishing,
  with optional series planning and first-principles technical writing
  patterns. Apply when creating technical blog content.

layer: process

requires:
  - swift-institute

applies_to:
  - blog
  - documentation

---

# Blog Post Process

Two-phase workflow for capturing blog post ideas from ongoing work and developing them into published Swift Institute blog posts, with optional series planning for multi-part content.

| Phase | Purpose | Artifact |
|-------|---------|----------|
| **Phase 1: Capture** | Note blog-worthy findings as they emerge | Ideas Index entry |
| **Phase 2: Draft and Publish** | Draft, review, and publish selected ideas | Published blog post |

**Optional activity — Series Planning**: When developing a multi-part series, create a series plan (see [BLOG-008]) before drafting. Standalone posts proceed directly from capture to drafting.

**Applies to**: Technical deep dives, pattern documentation, announcements, lessons learned, tutorials derived from Swift Institute work.

**Does not apply to**: Marketing content, community management, or content not derived from documented processes.

---

## Quick Reference: Trigger Points

| Source | Trigger | Blog Category |
|--------|---------|---------------|
| Experiment | `Result: REFUTED` with novel insight | Lessons Learned |
| Experiment | Compiler limitation discovered | Technical Deep Dive |
| Experiment | Surprising `Result: CONFIRMED` | Technical Deep Dive |
| Research | DECISION with broader relevance | Pattern Documentation |
| Research | Novel convention established | Pattern Documentation |
| SE-Pitch | Pitch submitted to Swift Forums | Announcement |
| SE-Proposal | Proposal accepted/rejected | Announcement / Lessons Learned |
| Package | v1.0 or major release | Announcement |
| Discovery | Cross-cutting pattern identified | Pattern Documentation |
| Implementation | Non-obvious solution found | Tutorial/How-To |

---

## Blog Categories

| Category | Description | Typical Source |
|----------|-------------|----------------|
| **Technical Deep Dive** | Compiler behavior, language semantics, implementation details | Experiments |
| **Pattern Documentation** | Conventions, patterns, design rationale | Research |
| **Announcement** | Package releases, SE proposal status, milestones | SE work, packages |
| **Lessons Learned** | What didn't work and why | REFUTED experiments, rejected proposals |
| **Tutorial/How-To** | Step-by-step implementation guidance | Implementation work |

---

## Directory Structure

```text
swift-institute/.../Blog/
├── _index.json            # Ideas Index (Phase 1 output)
├── Series/                # Series plans (optional activity output)
│   └── {series-slug}.md
├── Draft/                 # Work in progress
│   └── {slug}.md
├── Review/                # Awaiting review
│   └── {slug}.md
└── Published/             # Historical record
    └── YYYY-MM-DD-{slug}.md
```

---

## Writing Modes

### [BLOG-010] First-Principles Writing Pattern

**Statement**: Posts SHOULD follow one of two writing modes. The first-principles mode prioritizes discovery over declaration — the post guides the reader through the same journey of exploration that produced the insight. The conventional expository mode communicates conclusions, guidance, or reference information directly.

#### First-principles mode

| Principle | Description |
|-----------|-------------|
| **Problem before solution** | Demonstrate the pain before introducing the fix |
| **Ground in source material** | Reference SE proposals, official docs, compiler source — not just opinions |
| **Build through code** | Start with a minimal example and evolve it step by step |
| **Let the reader discover** | Use exploratory framing: "let's try... surprisingly... but what if..." |
| **Tests or evidence blocks as proof** | Back claims with running tests or compiler-verifiable code samples that readers can reproduce. For posts about type-system properties or compiler behavior, evidence blocks — exact signatures and minimal samples that reproduce the claimed behavior — are a valid alternative to test suites. |
| **Hit the wall honestly** | Show where things break — limitations build credibility |
| **Earn the abstraction** | Show concrete cases before generalizing into patterns or rules |

**Anti-pattern**: Stating the conclusion upfront and then walking through justification. This is appropriate for documentation but wrong for first-principles posts. The reader should *arrive* at the insight alongside the author.

**Exception — destination-first hook**: Showing the end-state upfront is valid when the reader can see *what* the code does but cannot yet understand *why* it matters. The significance is discovered through the journey, not declared at the outset. This differs from the anti-pattern because the reader sees syntax without understanding — the journey still produces genuine discovery.

#### Mode selection

| Situation | Default mode |
|-----------|-------------|
| Compiler behavior, language semantics, unexpected limitations | First-principles |
| Reconstructing design rationale through the choices that led there | First-principles |
| Non-obvious implementation solution, workaround discovery | First-principles |
| Release notes, package announcements, status updates | Conventional expository |
| Stable conventions intended as reference material | Conventional expository |
| Design rationale where the conclusion is well-established | Writer's judgment — first-principles if the journey adds value |

Some posts may blend modes. Use first-principles for discovery sections, conventional for reference sections.

Choose first-principles mode when the value of the post lies in the reader experiencing the reasoning, discovery, or constraint process. Choose conventional expository mode when the value lies primarily in communicating conclusions, guidance, updates, or reference information efficiently.

---

### [BLOG-011] Post Narrative Arc

**Statement**: Posts using the first-principles writing mode SHOULD follow a narrative arc with these beats.

| Beat | Purpose | Example |
|------|---------|---------|
| **Hook** | Show why this matters in 2–3 sentences | A concrete problem the reader has felt |
| **Scope** | (Optional) State what the post/series is *not* claiming | "This series is not arguing that all public APIs should use typed throws" |
| **Foundation** | Establish shared ground — define terms from source material | Reference the SE proposal, quote the key paragraph |
| **Build** | Evolve a working code example step by step | Start simple, add complexity incrementally |
| **Surprise** | Reveal something unexpected — positive or negative | "This compiles, and it works" or "This should work, but..." |
| **Wall** | Show the boundary of what works today | Where the approach breaks down, and why |
| **Resolution** | Provide the takeaway — what to do given the wall | A decision framework, workaround, or design principle |
| **Tease** | (Series only) Open the question that motivates the next post | "But what happens when you try this with..." |

Not every post needs every beat. Short posts may combine Foundation and Build. Standalone posts omit the Tease. The Scope beat is recommended for posts that argue for a specific approach — pre-empting strawman interpretations buys credibility with skeptical audiences. But the arc from Hook through Resolution is the backbone.

Posts using the first-principles pattern SHOULD contain at least one genuine moment of discovery — a compiler error, semantic limitation, surprising success, tradeoff, or failed intuition. This is often what makes the reasoning legible and the lesson stick. Do not manufacture drama where none exists. If a post has no natural moment of discovery, the conventional expository mode is likely a better fit.

---

### [BLOG-012] Running Example Design

**Statement**: Each post (or series) using the first-principles mode SHOULD center on a single running example that evolves, rather than presenting disconnected code snippets.

| Property | Requirement |
|----------|-------------|
| Minimal start | Begin with the simplest possible version |
| Motivated additions | Each change to the example is driven by a problem or question |
| Reproducible at every step | Every intermediate state can be reproduced by the reader. Intentionally failing states (compiler errors, crashes, test failures) are allowed when they are clearly labeled as the point of the step. |
| Realistic enough | Not a toy — the reader should see their own code in the example |
| Small enough | The reader can hold the full example in their head |

**Evolving the example**: When the example grows across a post, show only the diff (new or changed lines) with enough surrounding context to locate the change. Show the full example at most once near the end.

---

## Phase 1: Capture

### Phase Contract

**Entry criteria**: Trigger event occurred, source artifact exists, insight is communicable to external Swift developers.

**Exit criteria**: Ideas Index entry created per [BLOG-003], source documents linked bidirectionally, category assigned, working title provided.

---

### [BLOG-001] Idea Capture Triggers

**Statement**: A blog idea SHOULD be captured when work produces an insight valuable to the broader Swift community that is not adequately served by internal documentation alone.

| Signal | Priority |
|--------|----------|
| Novel insight (not documented elsewhere) | High |
| Common pitfall (mistake others will make) | High |
| Pattern emergence (broad applicability) | Medium |
| Milestone (significant release/acceptance) | Medium |
| Narrative (interesting journey) | Low |

**Integration with other processes**: When these events occur, evaluate for blog capture:

| Process | Event | Question |
|---------|-------|----------|
| Experiment [EXP-006] | Result documented | Would external developers benefit? |
| Experiment [EXP-006a] | Findings promoted | Significant enough for broader communication? |
| Research [RES-006] | DECISION reached | Does this establish an adoptable pattern? |
| Research [RES-006a] | Findings promoted | Would the rationale interest the community? |

**Filter**: Not everything interesting internally is worth a public blog post. The test is "would external Swift developers benefit?"

**Cross-references**: [BLOG-002], [BLOG-003]

---

### [BLOG-002] Ideas Index Format

**Statement**: The Ideas Index MUST be maintained in `Blog/_index.json` with entries organized into section objects by status and sorted by capture date. Each section object has `heading`, optional `blurb`, a `columns` array naming the fields for that section's entries, and an `entries` array. Markdown-link cells (`source`, `draft`, `post`) parse into `{label, url}` objects. Schema: `https://swift-institute.org/schemas/blog-index-v1.json`.

Sections (in order): **Ready for Drafting**, **Needs More Context**, **In Progress**, **Published**.

Each section uses a table with these fields:

| Section | Required Columns |
|---------|-----------------|
| Ready for Drafting | ID, Title, Category, Source, Captured, Notes |
| Needs More Context | ID, Title, Category, Source, Captured, Blocker |
| In Progress | ID, Title, Category, Writer, Started, Draft |
| Published | ID, Title, Published, Post |

Ideas are numbered sequentially: `BLOG-IDEA-001`, `BLOG-IDEA-002`, etc.

```markdown
## Ready for Drafting

| ID | Title | Category | Source | Captured | Notes |
|----|-------|----------|--------|----------|-------|
| BLOG-IDEA-007 | The Hidden ~Copyable Sequence Trap | Lessons Learned | [experiment](link) | 2026-01-23 | Bug #86669, workaround documented |
```

**Cross-references**: [BLOG-001], [BLOG-003]

---

### [BLOG-003] Idea Entry Template

**Statement**: Each Ideas Index entry MUST include sufficient context for someone else to draft the post.

**Required fields**: ID (`BLOG-IDEA-XXX`), Title (working, can change), Category, Source (link to artifact), Captured (date), Notes/Blocker.

For complex ideas, create extended context in `Blog/Ideas/BLOG-IDEA-XXX-context.md` covering: source links, key points to cover, target audience, estimated complexity.

**Cross-references**: [BLOG-001], [BLOG-002]

---

### [BLOG-004] Bidirectional Linking (Phase 1)

**Statement**: When a blog idea is captured, the source artifact SHOULD be updated with a reference to the blog idea.

In source artifact (experiment header, research document):

```markdown
## Blog Potential

This {experiment/research/finding} has been captured as a blog idea:
- [BLOG-IDEA-XXX: {Title}](../Blog/_index.json) — section matching the idea's current status
```

In experiment main.swift header:
```swift
// Blog: BLOG-IDEA-007 "The Hidden ~Copyable Sequence Trap"
```

**Cross-references**: [BLOG-007]

---

## Optional Activity: Series Planning

### [BLOG-008] Series Concept

**Statement**: When related ideas form a natural progression, they SHOULD be planned as a multi-part series with a shared arc.

A series groups posts under a shared title where each part builds on what came before. The key property: a reader can start at Part 1 with no prior knowledge and follow the entire arc.

| Property | Requirement |
|----------|-------------|
| Ordered but accessible | Parts are designed to be read in sequence. Each part opens with a brief orientation (2–3 sentences) so readers arriving mid-series can understand the local goal, but prior parts are assumed for full depth. Each part should also advance the shared example, conceptual model, or both. |
| Shared running example | A single example evolves across parts, not a new example per post |
| Cliffhanger endings | Each part (except the last) ends with a question that motivates the next |
| Consistent voice | Same tone and style across all parts |

**When to use a series vs. standalone posts**:

| Series | Standalone |
|--------|------------|
| Topic requires layered understanding | Insight is complete in one post |
| Natural "walls" create dramatic pauses | No progression needed |
| Running example benefits from evolution | Examples are independent |
| 3+ related ideas in the index | 1–2 ideas |

---

### [BLOG-009] Series Plan Format

**Statement**: Each series MUST have a plan document in `Blog/Series/{series-slug}.md`.

```markdown
# {Series Title}

## Arc

{One paragraph describing the journey from start to finish.}

## Parts

### Part 1: {subtitle}
- **Opens with**: {the problem or question}
- **Builds to**: {the key insight}
- **Ends with**: {the cliffhanger}
- **Source ideas**: BLOG-IDEA-XXX, BLOG-IDEA-YYY

### Part 2: {subtitle}
- **Opens with**: {picks up from Part 1's cliffhanger}
- **Builds to**: {the key insight}
- **Ends with**: {the cliffhanger}
- **Source ideas**: BLOG-IDEA-ZZZ

### Part N: {subtitle}
...

## Target audience

{Who is this series for? What should they already know?}

## Entry assumptions

{What knowledge is assumed? What is explicitly NOT assumed?}

## Shared example

{Description of the running example that evolves across parts.}

## References

- {SE proposals, research docs, experiments that feed into this series}
```

**Series metadata in post frontmatter**:

```markdown
series: {series-slug}
series_part: 1
series_title: {Series Title}
```

---

## Phase 2: Draft and Publish

### Phase Contract

**Entry criteria**: Idea in "Ready for Drafting", writer assigned, entry moved to "In Progress".

**Exit criteria**: All required sections complete per [BLOG-005], technical accuracy verified (code examples tested), review completed, publication metadata complete, file in `Published/`, Ideas Index updated, source artifacts updated with post link.

---

### [BLOG-005] Blog Post Structure

**Statement**: Blog posts MUST follow a consistent structure appropriate to their category.

#### Universal Metadata

```markdown
<!--
---
id: BLOG-IDEA-XXX
title: {Final Title}
slug: {url-friendly-slug}
category: {Category}
series: {series-slug}           # optional — omit for standalone posts
series_part: {N}                # optional — part number within series
series_title: {Series Title}    # optional — shared series title
date_drafted: YYYY-MM-DD
date_published: YYYY-MM-DD
author: {name}
source_artifacts:
  - {path/to/experiment}
  - {path/to/research}
tags:
  - swift
  - {relevant-tags}
---
-->
```

#### Structure by Category

**Technical Deep Dive**: The Problem → What We Found → Why This Happens → Implications → References

**Pattern Documentation**: Context → The Pattern → Alternatives We Considered → When to Use This → References

**Announcement**: What's New → Highlights → Getting Started → What's Next → Links

**Lessons Learned**: What We Tried → What Went Wrong → What We Learned → The Fix/Workaround → Takeaway → References

**Tutorial/How-To**: Goal → Prerequisites → Steps (numbered with code) → Complete Example → Common Issues → References

#### Relationship to writing modes

The category structures above define minimum section coverage and deliverable expectations. Posts following the first-principles writing pattern [BLOG-010] use the narrative arc [BLOG-011] as their rhetorical progression *within* these sections. Posts using conventional expository mode follow the category structure directly. See the mode selection table in [BLOG-010] for guidance on which mode to use.

Example: a Technical Deep Dive may include sections such as "Why this happens" and "Implications," while the reasoning inside those sections follows the first-principles arc from setup through discovery to resolution.

**Cross-references**: [BLOG-006], [BLOG-010], [BLOG-011]

---

### [BLOG-006] Review Process

**Statement**: Blog posts MUST be reviewed before publication.

| Criterion | Required |
|-----------|----------|
| Technical accuracy (code compiles, examples work) | MUST |
| Clarity (understandable to target audience) | MUST |
| Completeness (all sections filled) | MUST |
| Links verified (all references accessible) | MUST |
| Tone appropriate (professional, educational) | SHOULD |
| Length appropriate (not padded, not truncated) | SHOULD |

Process: (1) Move draft to `Blog/Review/`, (2) request review, (3) address feedback, (4) reviewer approves.

After review, add metadata: `review_date`, `reviewer`, `review_notes`.

**Series-level review**: For multi-part series, conduct a series-level review pass in addition to per-post checks. Evaluate: tone consistency across parts, evidence standards, rhetoric calibration, running example continuity, and cross-part forward/backward references.

**Collaborative review**: For Lessons Learned and Technical Deep Dive posts targeting public audiences, the **collaborative-discussion** skill SHOULD be invoked as part of the Review phase before publication. External LLM perspective tends to catch framing issues that author-only review does not — tone inconsistency, overloaded hooks, misalignment between body and closing sections, redundancy between summary sections and body. For posts targeting critical audiences (e.g., Swift Forums) or first-of-its-kind content, this SHOULD be treated as a gating step rather than optional.

**Closing-material pass**: Takeaway, Summary, and References sections MUST receive a dedicated review pass before moving to `Review/`. Author revision passes tend to target body content and leave closing material inherited from earlier drafts. Specifically check: (a) the Takeaway does not restate conclusions already in the body, (b) bullet lists do not restate table contents, (c) every reference in References has at least one textual mention in the body (otherwise drop the reference).

**Cross-references**: [BLOG-005], [BLOG-007], [BLOG-014]


---

### [BLOG-013] Receipts: Link Every Load-Bearing Claim to a Runnable Experiment

**Statement**: Each load-bearing technical claim in a blog post MUST be backed by a reproducible experiment per [EXP-002], and the post MUST link from the claim's prose directly to the experiment's source on GitHub.

A *load-bearing claim* is any assertion the post relies on for its argument: "the compiler rejects X with diagnostic Y", "approach A compiles but approach B does not", "this fix produces these specific lines of code". Style claims, opinions, and expository background are exempt — only claims that the reader could in principle dispute by running code.

**Why**: Blog posts are written for external audiences who do not start from a position of trust. Every claim is implicitly a "trust me on this." Linking each claim to a runnable Swift package converts the post from assertion to demonstration. The reader can clone, build, and verify. This is the same evidence-over-assertion ethos that grounds [EXP-002] for internal research.

**How to apply**:

| Step | Action |
|------|--------|
| 1. Audit claims | Before drafting, list every claim in the post that asserts compiler/runtime/language behavior. Each one is a candidate for a backing experiment. |
| 2. Map to experiments | For each claim, identify whether an experiment already exists (often yes, since posts emerge from experimental work). If no, plan a variant. |
| 3. Add experiment variants | Create per-claim variants in the existing experiment package most relevant to the claim, never in a per-post directory. The experiment is named by what it tests, not by who consumes it. Naming: `V{N}_{descriptive}` (e.g., `V7_Retroactive`, `V8_ModuleSelectors`). Each variant should be minimal and prove exactly one claim. If no existing experiment fits, create a new package in `Experiments/` flat (no `blog-` prefix) per [EXP-002]. |
| 4. Link inline | In the post, link from the claim's prose to the variant's GitHub URL. Format: parenthetical or inline reference, not a footnote. |
| 5. Verify on draft completion | Before moving to Review per [BLOG-006], every load-bearing claim must have its link in place. |

**Inline link format** — preferred:

```markdown
Every variant fails. Identical error.
([V1–V5](https://github.com/swift-institute/Experiments/tree/main/{experiment-name}))
```

**Acceptable alternative** — footnote-style for dense passages:

```markdown
The compiler emits a different error here[^v7].

[^v7]: [V7_Retroactive](https://github.com/swift-institute/Experiments/tree/main/{experiment-name}/Sources/V7_Retroactive)
```

**Anti-pattern**: A claim asserted in prose without a link, when an experiment exists or could trivially be added. Any reader who wants to verify must hunt through the repo. Trust degrades.

**Anti-pattern**: A blanket "see this experiment for all claims" link at the bottom of the post. Per-claim links are higher-friction to write but dramatically lower-friction to verify. The asymmetry is the point.

**Exception**: Posts published while the author is still establishing their public footprint MAY ship with partial receipts (the author commits to backfilling). The idea entry's `notes` field in `Blog/_index.json` SHOULD record what's pending.

**Cross-references**: [EXP-002], [EXP-005], [EXP-006], [BLOG-005], [BLOG-006], [BLOG-014]

---

### [BLOG-014] Active Claim Verification

**Statement**: Before moving a draft from `Blog/Draft/` to `Blog/Review/`, every load-bearing claim about compiler, language, or API behavior MUST be re-verified against the current toolchain, independent of whether a receipt link exists.

**Why this is distinct from [BLOG-013]**: [BLOG-013] requires that each claim *link to* a reproducible experiment. That proves the claim was true *when the experiment was written*. Between then and publication, toolchain versions change, the author's memory of what a diagnostic says drifts, quoted text gets paraphrased in revisions, and references can become stale. [BLOG-013] is the provenance step; [BLOG-014] is the freshness step.

**How to apply**:

| Step | Action |
|------|--------|
| 1. List verifiable claims | Enumerate every claim about compiler behavior, error messages, feature flags, source code locations, or SE-proposal text. These are the candidates for verification. |
| 2. Re-run experiment | For each claim with an existing experiment variant, run `swift-build package clean` and `swift-build package build` against the current toolchain through the coordinator. If the claim is about a failure mode, confirm the failure still triggers. If it's about a compile pass, confirm it still compiles. |
| 3. Re-verify quoted text | Every quoted passage from SE proposals, compiler source files, or diagnostic messages MUST be checked against the current source. Paraphrases presented as quotes are a load-bearing integrity failure; verified quotes are cheap to maintain. |
| 4. Re-verify source paths | Every cited source file path (e.g., `lib/AST/Decl.cpp`) MUST resolve at the cited location in the referenced branch. Functions named in references MUST still exist in that file. |
| 5. Confirm before promotion | A draft MUST NOT move to `Blog/Review/` with unverified verifiable claims. If a claim cannot be verified (e.g., production-only failure that resists minimal reproduction), [BLOG-014a] applies. |

**Anti-pattern**: Citing a compiler source file path without checking the cited function still lives there. `lib/Parse/` reorganizations silently break citations that were accurate when the draft started.

**Anti-pattern**: Quoting SE-proposal text from memory or from an early draft, without re-checking against the proposal's current prose. Proposals are edited during review phases; paraphrases drift into misquotes.


**Cross-references**: [BLOG-006], [BLOG-013], [BLOG-014a]

---

### [BLOG-014a] Production-Verified but Not Minimally-Reproducible Claims

**Statement**: Some claims about compiler or language behavior are empirically true in production code but resist minimal reproduction. When this happens, the post MUST: (a) link the production artifact (e.g., a permalinked commit or source file on the relevant repo) as the failure receipt, (b) link any minimal experiment that demonstrates the adjacent mechanism or the solution, and (c) explicitly acknowledge the reproduction gap in prose. The post MUST NOT pretend to have a minimal reproduction that does not exist.

**Why**: [BLOG-013] prefers minimal reproductions because they are cheapest for readers to verify. But some failures only manifest under scope-rich conditions (deep import graphs, multi-file typechecking order, refinement chain depth, etc.) that minimal tests don't capture. Pretending these failures reproduce minimally destroys trust the moment a reader tries to reproduce them.

**Example framing** (from the associated-type-trap post):

> V11 demonstrates the `@_implements` mechanism in isolation; V12 demonstrates the two-stamp solution shape. The *failure* that makes two stamps necessary was observed in production (see the applied fix at {permalink}) but I could not reduce it to a minimal reproduction despite adding refinement depth, ambient types, and cross-file conformance splits to V12. The reproduction gap is acknowledged; the fix is verified in situ.


**Cross-references**: [BLOG-013], [BLOG-014]

---

### [BLOG-007] Publication Process

**Statement**: When a post passes review, it MUST be published following the standard process.

| Step | Action |
|------|--------|
| 1 | Finalize metadata (`date_published` set) |
| 2 | Rename and move: `Blog/Published/YYYY-MM-DD-{slug}.md` |
| 3 | Update Ideas Index (entry → "Published" section) |
| 4 | Update source artifacts (add link to published post) |
| 5 | Publish to blog platform |
| 6 | Update all landing-page pins that reference "latest post" or "featured writing" |

File naming: `YYYY-MM-DD-{slug}.md` (e.g., `2026-01-25-the-hidden-noncopyable-sequence-trap.md`)

Source artifact update:
```markdown
## Blog Post

This finding was published as:
- [{Title}](../Blog/Published/YYYY-MM-DD-{slug}.md) (YYYY-MM-DD)
```

Traceability chain: Source Artifact → Blog Idea → Published Post (bidirectional).

**Landing-page pin audit**: Publication frequently requires updating more than the Blog directory itself. Before closing out a publish, audit each of the following for stale references to the previous post:

| Location | What to update |
|----------|---------------|
| Blog index page (e.g., `Blog.md`, `blog/index.md`) | Add the new post to the Posts list (reverse-chronological). |
| Landing page "Latest writing" / "Featured post" pin | Update any `<doc:{PrevPost}>` references to point at the new article. On DocC catalogs this is typically in the module's index file (e.g., `{Module}.md`). |
| Ideas index JSON (`Blog/_index.json`) | Move the entry from the In Progress section to the Published section per [BLOG-002]. |
| Source artifact(s) | Add the "Blog Post" section per the template above. |

Pins are manually maintained and do not auto-derive from post dates. Each new post requires an explicit audit of every site that advertises a "latest" or "featured" pointer.


**Cross-references**: [BLOG-004], [BLOG-006]

---

### [BLOG-015] Rhetorical-Energy Check for Paired-Post Reveals

**Statement**: When a precursor post teases a follow-up launch, the precursor's closing MUST make the launch feel consequential (reader asks *"what is this library?"*), not trivial (reader infers *"any library of this shape would do"*). The rhetorical-energy check is a specific bar applied to precursor closings.

**Check (applied at Review stage)**: read the last paragraph of the precursor in isolation. Does this tease make the reader want to know what the launched library is? Or does it feel like the library is an inevitable consequence of the preceding argument? If the latter, compress or rewrite the preceding argument so the launched library is a non-obvious specific solution, not a deductive necessity.

**Example (defect)**: Precursor argues the language now has composable ownership primitives, closes with *"it's straightforward to build a library on top of this once the language supports it."* Reader infers the launched library is inevitable given the premise; launch feels redundant.

**Example (correct)**: Same precursor closes with *"the next post shows one way to do this — and the choice of carrier shape turns out to matter more than the ownership primitives it sits on."* Reader must read the launch to learn the specific choice.


**Cross-references**: [BLOG-008]

---

### [BLOG-016] Release-Post Non-Blending Rule

**Statement**: Release posts (package launches, version releases, status updates) MUST NOT blend modes with Pattern Documentation, First-Principles, or Technical Deep Dive. If the primary trigger is a package ship event, the category is Announcement and the mode is conventional expository; hybrid framings belong in separate posts.

**Trigger detection**: A post is a release post when any of these hold — (a) the post coincides with a git tag or package version bump, (b) the post's call-to-action is "install the package", (c) the post's primary factual claim is that the package exists and is ready for consumers.

**Reference shape**: The Point-Free launch-post model — clear "what it is", clear "why you'd want it", clear "how to try it", minimal digression into adjacent ideas. Adjacent ideas get their own posts.

**Rationale**: Release posts optimize for one audience action (adopt the package). Blending in pattern-documentation or first-principles content dilutes the action by shifting the reader's cognitive frame mid-post. Two posts published in sequence outperform one blended post at both jobs: adoption AND pattern adoption.


**Cross-references**: [BLOG-010]

---

### [BLOG-017] Mechanical Link-Reference Audit at Closing-Material Pass

**Statement**: [BLOG-006]'s closing-material pass is extended with a mechanical link-reference audit step. After compression or deletion of body paragraphs, grep each `[slug]:` link definition in the References section against the body; drop any slug whose referencing paragraph was compressed or deleted.

**Procedure**:

```bash
# For each link-reference definition in the post:
grep -c "\[slug\]" post.md  # expect ≥2 — the definition + at least one body reference
# If count is 1 (only the definition), the reference is orphaned — delete it.
```

**Rationale**: Orphaned references survive author revision passes because readers rarely re-parse the References cluster; the drift is invisible until a citation-aware reader catches it. A grep-based audit closes the blind spot in seconds.


**Cross-references**: [BLOG-006]

---

### [BLOG-018] Phase-1 Findings Claim Verification

**Statement**: [BLOG-014] Active Claim Verification is extended from draft-only to include Phase-1 design-brief Findings. Every load-bearing factual claim in a Phase-1 Findings section about compiler state, source state, or package state MUST be verified against current repo state (git log, source grep, release build) before the claim is written as an established premise.

**Rationale**: Phase-1 Findings feed directly into the drafter. Unverified Findings claims propagate into drafts; [BLOG-014] as currently written targets drafts only, which means Findings are an unprotected upstream. Extending the rule to Phase-1 closes the gap. The 2026-04-22 "README drift" flag in Findings was a [BLOG-014] violation that should have been impossible under the rule as originally scoped.


**Cross-references**: [BLOG-014]

---

### [BLOG-019] Companion-Experiment Parallel Authoring

**Statement**: When a blog post describes a technical artifact — a pattern, an API, a workflow — the companion experiment package (if one exists) MUST be authored alongside the draft, not after. Experiments are the correctness harness for the draft's claims, not a post-publication receipt.

**Rationale**: Parallel authoring catches defects at the cheapest moment (before publication). The 2026-04-22 V5 draft of `namespaced-accessors-walkthrough` would have shipped with a stale `mutating _modify` example if the companion experiment hadn't been built in parallel; the stale example surfaced when the parallel build failed. Post-publication experimentation, even when scheduled, routinely gets deprioritized.


**Cross-references**: [BLOG-013], [BLOG-014]

---

### [BLOG-020] Audience-Magnitude Check Before Timing Advice

**Statement**: Before applying timing heuristics like "wait for the newsletter window," "publish at peak forum traffic," or "schedule for high-engagement hours," the writer MUST first verify that audience magnitude is non-trivial. At effectively-0 audience, conventional engagement-optimization heuristics invert: the right move is "ship now for indexing time and low-stakes pipeline rehearsal" rather than "wait for optimal timing." Engagement-timing advice without an audience-magnitude precondition mis-applies heuristics that assume a non-trivial audience.

**Decision test**:

| Audience baseline | Timing posture | Why |
|-------------------|----------------|-----|
| Effectively 0 readers (new blog, no subscriber list, no inbound traffic) | Ship now | Indexing time accumulates; pipeline rehearsal is the value at this stage; no "optimal window" exists |
| Modest steady audience (~hundreds of monthly readers, some forum/newsletter presence) | Conventional timing heuristics apply | Newsletter windows + peak traffic windows have measurable effect |
| Large engaged audience | Conventional + amplified timing discipline | Cost of mistimed publishing is real; coordination across channels matters |

**Worked example (the origin incident)**:

A 2026-04-24 session's initial recommendation was to delay a blog post until a Tuesday newsletter window. User surfaced the actual baseline: 0 readers. The Monday-morning timing recommendation was grounded in engagement heuristics that didn't apply at the user's baseline. Correction inverted to "ship now"; the precursor + paired-post URL question became the load-bearing concern, not optimal timing.

**Rationale**: Timing heuristics are calibrated to non-trivial-audience contexts. At 0 audience, the cost of missing an "optimal window" is zero (no audience means no readers to miss). The benefit of shipping now is measurable: search indexing accumulates, the publishing pipeline is rehearsed, and the writer-side feedback loop closes. The audience-magnitude check is a free precondition that prevents misapplication.


**Cross-references**: [BLOG-002], [BLOG-008]

---

### [BLOG-021] Paired-Post URL Dependency Handling

**Statement**: When a blog post links to a sibling post that hasn't published yet (a "paired-post" forward reference), the writer MUST choose one of three canonical handling shapes at draft-finalization time and document the choice. Ad-hoc handling produces 404s on launch day or mid-week stripped-link confusion.

**Three canonical handling shapes**:

| Shape | When | Mechanism |
|-------|------|-----------|
| (a) **Resolve-and-accept-404** | Short publish lag (≤24h), near-0 audience | Publish the precursor with the dead link; the sibling lands within indexing latency; readers in the lag window see a 404 (low-stakes). Easiest. |
| (b) **Strip-and-restore-on-launch-day** | Default; 3+ day lag, any audience | Strip the forward-reference paragraph from the precursor at publish time; restore it on the sibling's launch day with a small edit commit in both repos (Blog + DocC site). |
| (c) **Same-day-publish-both** | Load-bearing cross-reference where the forward-reference paragraph carries the precursor's argument | Coordinate same-day publish for both posts; no live 404 window. Highest coordination cost. |

**Selection heuristic**:

| Question | If yes | If no |
|----------|--------|-------|
| Is the forward-reference paragraph load-bearing for the precursor's argument? | Use (c) Same-day-publish-both | Continue |
| Is publish lag ≤24h AND audience effectively 0? | Use (a) Resolve-and-accept-404 | Use (b) Strip-and-restore |

**Tuesday-restore checklist** (option (b)):

When restoring a stripped section:
1. Restore the forward-reference paragraph in `Blog/Published/{precursor}.md`.
2. Restore the same paragraph in the DocC site source file (`swift-institute.org/Swift Institute.docc/...`).
3. Verify rendered output in browser (DocC hydrates client-side; `WebFetch` returns empty shells — see [BLOG-022]).
4. Commit each restore in its own repo with a small "restore paired-post link" message.
5. Re-push.


**Cross-references**: [BLOG-008], [BLOG-013], [BLOG-020], [BLOG-022]

---

### [BLOG-022] DocC Deploy Verification Path

**Statement**: After publishing or restoring DocC-hosted content, verification MUST distinguish three independent layers — HTTP availability, build status, and rendered content — because each layer has different failure modes and different verification mechanisms. Conflating "the URL returned 200" with "the content is rendered" produces silent staleness when DocC's client-side hydration is broken.

**Three-layer verification**:

| Layer | Mechanism | What it confirms |
|-------|-----------|------------------|
| HTTP availability | `curl -I {url}` (or `curl -sLo /dev/null -w '%{http_code}'`) | URL exists and routes to a live host. Trailing-slash 301 normalization is a known not-a-bug signal. |
| Build status | `gh run list --repo {site-repo} --workflow {deploy-workflow} -L 5` | The site's deploy workflow ran successfully and the new commit landed on the deployed branch. |
| Rendered content | Browser load (manual visual check) | DocC's client-side hydration produced the actual page DOM. `WebFetch` and curl see the empty shell HTML; only a real browser executes the JS that hydrates. |

**Why all three**:

| Layer alone | Failure modes that pass |
|-------------|------------------------|
| HTTP only | Old cached content; build failed but old version still served; trailing-slash redirect masks deeper issue |
| Build only | Build succeeded but didn't actually update routing or the page |
| Rendered only | Site is up but the specific page doesn't exist or isn't reachable |

The three layers together form a complete verification surface; any one alone leaves a class of silent-failure modes uncovered.

**Trailing-slash 301 normalization**: DocC's hosted output normalizes URLs by issuing a 301 redirect from `path` to `path/`. This is a known not-a-bug signal — `curl` will report the 301 with no `-L` flag, which can read as "the URL is broken." Add `-L` (follow redirects) when verifying to see the final 200.

**WebFetch + DocC pitfall**: DocC pages are client-side-hydrated single-page applications. `WebFetch` (and `curl` without a JS engine) sees the empty shell HTML — `<div id="root"></div>` or similar — not the rendered article body. The shell is the same for every DocC page; if WebFetch returns "looks empty / minimal content," that's not evidence the page is broken — it's evidence the page is DocC-style. Use a real browser for content verification.


**Cross-references**: [BLOG-013], [BLOG-021]

---

### [BLOG-023] Schedule-Shift Cohort Sweep

**Statement**: When a publish or launch date moves, the implementer MUST grep the prior date string across ALL cohort surfaces — the draft, the `Blog/_index.json` entry notes, cohort-package READMEs, research/Documentation.docc references, and any companion-experiment docs cross-cutting the launch — and update each. Single-file edits routinely miss the cascade; a moved date in only some surfaces produces stale-by-construction launch artifacts.

**Composite:** discipline rule (mechanical) + cohort-surface enumeration (mechanical) + procedure (mechanical).

**Cohort surfaces to grep on every date shift**:

| Surface | Grep target |
|---------|-------------|
| The blog draft itself | `<draft>.md` |
| `Blog/_index.json` entry notes | `Blog/_index.json` |
| Cohort-package READMEs | `<cohort-pkg>/README.md` for each package in the launch cohort |
| Research / Documentation.docc references cross-cutting the launch | `<pkg>/Research/*.md`, `<pkg>/Documentation.docc/*.md` |
| Companion-experiment docs | `Experiments/<name>/main.swift` headers, etc. |
| Cross-cohort dependent posts (e.g., the launch announcement post that cites the cohort-flagship post) | Other Blog drafts |

**Procedure** (when a date shifts from `2026-05-12` to `2026-05-11`):

```bash
# 1. Grep the prior date string across all cohort surfaces:
grep -rln "2026-05-12" \
  Blog/ \
  swift-pair-primitives/ \
  swift-either-primitives/ \
  swift-product-primitives/ \
  swift-coproduct-primitives/

# 2. For each match, update with the new date.
# 3. Re-grep to confirm zero remaining instances.
```

**Worked example (the origin incident)**:

The 2026-05-10 coproduct-blog-annotations session shifted the launch date from Tuesday (2026-05-12) to Monday (2026-05-11), compressing the schedule by one day. The blog draft's `## What we are watching for` section had references to "Tuesday's post" / "the Wednesday coproduct post"; these required flipping. Single-file edits would have left the cohort-package READMEs ("The first three landed 2026-05-09" → must update for new Monday) stale. Cohort-wide grep is the only complete remediation.

**Rationale**: Date references are the most common cross-cutting metadata in launch cohorts. They appear in marketing prose, technical documentation, README badges, JSON manifest notes, and inter-post links. A single-file edit at the moved-document boundary misses the parallel surfaces; cohort-wide grep ensures the launch ships with consistent dates everywhere.


**Cross-references**: [BLOG-007], [BLOG-021]

---

### [BLOG-024] Ownership / Reference Primitives Are Last-Resort, Not Marquee

**Statement**: `swift-ownership-primitives` and `swift-reference-primitives` are used across the ecosystem but they are escape hatches for cases the language semantics cannot express. They MUST NOT be promoted as flagship first-release candidates or lead blog topics. When ranking L1 release candidates, blog topics, or featured examples, ownership/reference primitives MUST rank below packages whose role is to express language-semantic patterns (identity, algebra, error, random, positioning, lifetime). They MAY still ship — just not as the flagship.

**Why**: The preferred approach is always Swift's language-level ownership: `borrowing`, `consuming`, `~Copyable`, `~Escapable`. Ownership primitives provide escape hatches (`Ownership.Unique`, `Ownership.Mutable`, `Reference.Weak`, `Reference.Unowned`) for cases the language can't express. Promoting these as flagship would miseducate readers about idiomatic Swift Institute code — the *absence* of these types in most code is the point.

**How to apply**:
- When ranking L1 release candidates, propose language-semantic packages first; rank ownership/reference packages below.
- When proposing blog topics, rank the same way.
- When picking featured examples for a launch, the example MUST showcase language-semantic patterns first; ownership/reference appears only when the example genuinely needs the escape hatch.


**Cross-references**: [BLOG-019]

---

### [BLOG-025] Blog Voice — Direct Technical, No Whimsy, No Internal Skill Refs, Reasoning Follows Logically

**Statement**: Blog drafts targeting external Swift developers (Medium / swift.org / forums announcement) MUST follow three voice rules:

1. **No whimsical / storytelling phrasing.** Avoid "spelunking", "before lunch", "Brief intermission", "burning hours", "the day that shape stopped compiling", "nobody on the team had predicted." Replace with direct technical statements ("this is where the investigation stalls", "the hours between were avoidable"). The investigation/discovery arc per `[BLOG-011]` still applies, but the prose stays measured.
2. **No direct references to Swift Institute internal rules.** Do NOT cite `[API-NAME-002]`, "Swift Institute's convention", or "see the **code-surface** skill" in the post body. Restate the principle as personal preference or general advice ("I prefer nested namespaces over concatenated identifiers"). Internal taxonomy is opaque to external readers and reads as in-group jargon. The principle stands on argumentative ground without referring to internal authority.
3. **Reasoning sentences MUST follow logically from the claim they support.** Don't justify "X was tempting" with an unrelated comparison. If the reasoning is "X is in wide use across Swift APIs", say that — don't substitute "X matches Apple's Y style" when Y isn't analogous. Each justification sentence is checked against the claim it follows.

**Why**: External audience needs confident-and-observational voice, not dramatic / storytelling register. Internal-jargon citations break the post's argumentative ground; reasoning that doesn't follow undermines the post's authority. All three failure modes are recurring user-flagged issues during voice-review of associated-type-trap-class drafts.

**How to apply**: When drafting, prefer factual restatement over narrative coloring. When a draft would naturally cite an internal convention, restate the principle in general terms. When drafting reasoning passages, verify each justification sentence supports the claim it follows; substitute concrete examples (e.g., "SwiftUI itself uses `associatedtype Content` in `ForEach`, `Group`, `ViewModifier.Content`") for vague style comparisons.


**Cross-references**: [BLOG-011], [BLOG-026], [README-026]

---

### [BLOG-026] Blog Content Selection by Reader Interest, Not Editorial / Organizational History

**Statement**: Blog posts MUST be written for what external Swift developers find interesting — NOT for what documents internal editorial or organizational decisions. Maintainer-audience content MUST be cut from the post body during the Blog/Review pre-promotion pass:

- "Why one post for three packages" / "shapes vs refinements" framing about post structuring decisions
- Package-extraction backstory paragraphs (e.g., "this package graduated out of swift-X-primitives because…")
- Post-meta lede sentences ("This post covers X because…")
- `source_artifacts` entries / Links list entries that don't ground a load-bearing reader-facing claim

**Decision test** (apply during draft authoring AND Blog/Review pre-promotion):

For each paragraph, section heading, and link:
- Would an external Swift developer reading this post for the first time find this paragraph useful?
- Does this content explain *what the package does* and *how to use it*, or does it explain *why we organized the launch this way* / *where this package came from internally*?
- For each link: does the post body depend on this artifact for a load-bearing reader-facing claim? If not, drop it.

**Editorial scope-storytelling exception**: acceptable ONLY when a research doc grounds a load-bearing technical claim in the post body. Internal decision-tracking is NEVER load-bearing for readers.

**Distinct from `[BLOG-025]`**: `[BLOG-025]` targets sentence-level voice register (no whimsy, no internal skill refs, reasoning follows logically). `[BLOG-026]` (this rule) targets content selection — which paragraphs and links belong in the post at all. Both fire during Blog/Review.

**Worked example (the origin incident, 2026-05-09)**: a draft launching `swift-pair-primitives`, `swift-either-primitives`, `swift-product-primitives` shipped with two inward-facing sections that user feedback flagged: a `## Why one post for three packages` section (precedent comparison + algebra-extraction backstory) and a post-meta lede ("This post covers all three together because…"). Both were maintainer-audience. The same audit cut a private decision-tracking research doc from `source_artifacts`.


**Cross-references**: [BLOG-016], [BLOG-025], [README-023]

---

## Cross-References

See also:
- **research-process** skill for research that becomes blog posts ([RES-006], [RES-006a])
- **experiment-process** skill for experiments that become blog posts ([EXP-006], [EXP-006a])
- `Blog/_Styleguide.md` for formatting, voice, and style conventions
