---
name: documentation
description: |
  Inline DocC comments and .docc catalogue conventions.
  ALWAYS apply when writing or reviewing documentation comments or .docc articles.

layer: implementation

requires:
  - swift-institute
  - code-surface

applies_to:
  - swift-primitives
  - swift-standards
  - swift-foundations
  - swift-institute
  - documentation
  - docc
---

# Documentation

Conventions for inline DocC comments (`///`) and `.docc` catalogue documentation. Covers type/method/property docs, specification mirroring, per-symbol articles, topical articles, tutorials, landing pages, page design, and content layering across all four documentation layers.

This skill is organized as a navigation hub. The foundational workflow position and audience model below govern the whole skill and are always in context. Detailed rule text lives in sibling files; Claude loads the relevant file on demand when a topic is active.

## Workflow Position

Documentation is the **synthesis step** — it comes last and captures everything that came before:

```
Research → Experiments → Implementation → Iterate → Testing → Documentation
```

| Phase | Artifact | What it produces |
|-------|----------|-----------------|
| Research | `Research/*.md` | Design rationale, trade-off analysis |
| Experiments | `Experiments/*/` | Empirical verification of design decisions |
| Implementation | `Sources/**/*.swift` | Working code |
| Testing | `Tests/**/*.swift` | Verified behavior |
| **Documentation** | `///` + `.docc/` | **Synthesis of all of the above** |

Documentation does not drive research or experiments — it captures them. Inline `///` describes the implementation as it IS. The `.docc` articles reference the research that informed the design, the experiments that verified it, and the tests that guard it.

**Scope**: All inline DocC comments, `.docc` catalogue files, and code comment quality patterns (workaround/deviation/anticipatory templates). README conventions are covered by the **readme** skill.

## The Four-Layer Audience Model

Documentation lives in four distinct layers, each optimized for a different audience. Getting this model right is load-bearing for every rule below; every rule answers the question *"what does THIS layer need to do for THIS audience?"*.

| Layer | File kind | Primary audience | Optimize for | Canonical content |
|-------|-----------|------------------|--------------|-------------------|
| **1. Inline `///`** | `.swift` source | Coders and agents *actively using* the package | Call-site hover, autocomplete, quick-help pop-up | Summary line + canonical usage snippet + `` ``Symbol`` `` cross-refs |
| **2. Per-symbol article** | `.docc/{Symbol}.md` | Readers searching for *more depth* on a type | DocC symbol page (rendered) | Overview + Example + Rationale + Topics (member groupings) + Research/Experiments links |
| **3. Topical article** | `.docc/{Topic}.md` | Readers searching for *more depth* on a concept, task, or pattern that spans symbols | DocC catalog navigation, task-oriented reading | Extended prose, decision matrices, multi-symbol walkthroughs |
| **4. Tutorial** | `.docc/{Name}.tutorial` + `.docc/Resources/*.swift` | *Newer or less experienced* readers | Learning by doing, step-by-step | `@Intro` + `@Chapter` + `@Section` + `@Step` + `@Code` with catalog-resident source |

### Layer audiences compose

A single feature's documentation typically lives in all four layers. The feature's inline `///` is for someone typing `.push.` at a call site and seeing autocomplete. The per-symbol article is for someone who clicked through to the `Push` type's rendered page. A topical article is for someone who landed on "Choosing a Property Variant" without a specific symbol in mind. A tutorial is for someone who opened the package for the first time. Each layer reaches its audience in its natural context; they do not substitute for each other.

### Layer content ownership

Any given fact is authored in exactly one layer and referenced from the others. The four rules of thumb:

| Fact type | Canonical home | Other layers |
|-----------|----------------|---------------|
| API behavior / contract | Inline `///` | Per-symbol article may mirror |
| Decision matrix / pattern guide | Topical article | Per-symbol articles link to it |
| Walkthrough / guided sequence | Tutorial | Topical article or per-symbol article may link to it |
| Historical rationale / research summary | `.docc` article's `## Rationale` / `## Research` sections | Inline `///` MUST NOT carry this |

Duplication across layers is a smell unless it's a *deliberate mirror* of core contract (specification text, canonical usage snippet) that the audience at that layer needs in-context.

### Cross-references flow in both directions

- Inline `///` links to per-symbol articles via `` ``Symbol`` `` backticks.
- Per-symbol articles link to topical articles via `<doc:Choosing-A-Property-Variant>` and to research via relative markdown links.
- Topical articles link to per-symbol articles, tutorials, and research.
- Tutorials link to per-symbol articles for "learn more" pointers.

Every layer should leave the reader with a natural next step — the next layer up (more depth) or the next layer down (back to the API surface they'll actually write).

---

## Files

| Topic | File | Rules |
|-------|------|-------|
| Inline DocC Comments (Layer 1) | `inline.md` | [DOC-001]–[DOC-010] |
| .docc Catalogue (Layer 2, structure + architecture) | `catalogue.md` | [DOC-019a], [DOC-020]–[DOC-029], [DOC-100]–[DOC-102] |
| Topical Articles (Layer 3) | `topical.md` | [DOC-060]–[DOC-064] |
| Tutorials (Layer 4) | `tutorial.md` | [DOC-070]–[DOC-074] |
| Landing Pages | `landing.md` | [DOC-080]–[DOC-084] |
| Page Design | `visual.md` | [DOC-090]–[DOC-093] |
| Style, Currency, and External References | `style.md` | [DOC-030]–[DOC-033], [DOC-040]–[DOC-053], [DOC-054], [DOC-103] |

---

## Rule Index

One-line hooks for every rule. Load the linked file when the topic is active.

### Inline DocC Comments (`inline.md`)

| ID | Hook |
|----|------|
| [DOC-001] | Summary line — every public decl needs a one-line `///` summary |
| [DOC-002] | Type documentation structure |
| [DOC-003] | Method documentation |
| [DOC-004] | Property documentation |
| [DOC-005] | Specification-mirroring documentation |
| [DOC-006] | Subsection enumeration |
| [DOC-007] | Abbreviated subsection syntax |
| [DOC-008] | Cross-reference formats |
| [DOC-009] | Definition index pattern |
| [DOC-010] | Explanatory material exclusion — no rationale/research in inline `///` |

### .docc Catalogue (`catalogue.md`)

| ID | Hook |
|----|------|
| [DOC-020] | Catalogue location |
| [DOC-019a] | Multi-target consolidation pattern |
| [DOC-021] | Root page |
| [DOC-022] | Article pages — Navigation Level |
| [DOC-023] | Article pages — Substantive Level (Per-Symbol) |
| [DOC-024] | Subsection pages |
| [DOC-025] | Topics organization |
| [DOC-026] | Flat catalogue layout — no author-facing subdirectories |
| [DOC-027] | Content layering principle |
| [DOC-028] | Research references in .docc articles |
| [DOC-029] | Experiment references in .docc articles |
| [DOC-100] | Layering principle — inline and .docc carry distinct weight |
| [DOC-101] | Consumer/contributor boundary in DocC |
| [DOC-102] | Preview-and-convert parity in DocC tooling guidance |

### Topical Articles (`topical.md`)

| ID | Hook |
|----|------|
| [DOC-060] | When to create a topical article |
| [DOC-061] | Topical article structure |
| [DOC-062] | Topical article location |
| [DOC-063] | Topical articles in Topics |
| [DOC-064] | Per-symbol vs topical article decision |

### Tutorials (`tutorial.md`)

| ID | Hook |
|----|------|
| [DOC-070] | Tutorial table of contents (required) |
| [DOC-071] | Tutorial code layout (catalog-resident) |
| [DOC-072] | Tutorial structure |
| [DOC-073] | Tutorial code verification |
| [DOC-074] | Tutorial scope |

### Landing Pages (`landing.md`)

| ID | Hook |
|----|------|
| [DOC-080] | Umbrella catalog as landing page |
| [DOC-081] | @CallToAction |
| [DOC-082] | @Row and @Column layout |
| [DOC-083] | @TabNavigator |
| [DOC-084] | Topics grouping on landing pages |

### Page Design (`visual.md`)

| ID | Hook |
|----|------|
| [DOC-090] | @PageColor |
| [DOC-091] | @PageImage |
| [DOC-092] | @Available |
| [DOC-093] | Visual consistency across catalogues |

### Style, Currency, and External References (`style.md`)

| ID | Hook |
|----|------|
| [DOC-030] | External links |
| [DOC-031] | Cross-module references |
| [DOC-032] | Range reference pattern |
| [DOC-033] | Blockquote convention |
| [DOC-040] | Documentation tiers |
| [DOC-041] | Section heading conventions |
| [DOC-042] | Documentation currency |
| [DOC-043] | Comment purpose |
| [DOC-044] | Anticipatory documentation |
| [DOC-045] | Workaround documentation template |
| [DOC-046] | Deviation documentation template |
| [DOC-047] | Learning path preservation |
| [DOC-048] | Compromise documentation |
| [DOC-049] | Escape hatch counter-marketing |
| [DOC-050] | Code example quality |
| [DOC-051] | Automated verification of derived information |
| [DOC-052] | Semantic labels vs computed values |
| [DOC-053] | Document versioning |
| [DOC-054] | Toolchain/snapshot version labels MUST match empirical `swift --version`, never inferred |
| [DOC-103] | Documentation code examples MUST comply with code-surface naming rules |

---

## Cross-References

- **code-surface** skill for [API-NAME-003] specification-mirroring names, [API-IMPL-005] one type per file, [API-ERR-001] typed throws
- **research-process** skill [RES-002] for research document location and structure
- **experiment-process** skill [EXP-002] for experiment package location and structure
- **readme** skill [README-*] for README conventions (separate skill)
- Research: `swift-institute/Research/documentation-skill-design.md`
- Research: `swift-institute/Research/documentation-research-experiments-integration.md`
