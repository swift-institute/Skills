# Documentation — .docc Catalogue

Part of the **documentation** skill. See `SKILL.md` for the navigation hub, four-layer audience model, and rule index.

**Rules in this file**: [DOC-020], [DOC-019a], [DOC-021], [DOC-022], [DOC-023], [DOC-024], [DOC-025], [DOC-026], [DOC-027], [DOC-028], [DOC-029], [DOC-100], [DOC-101], [DOC-102].

---

## .docc Catalogue

### [DOC-020] Catalogue Location

**Statement**: Every module MUST have a `.docc` catalogue directory inside its `Sources/` directory, named to match the module:

```
Sources/{Module Name}/{Module Name}.docc/
```

**Exception — umbrella-consolidation pattern**: in a package with a multi-target + umbrella + `@_exported public import` shape (see the multi-target consolidation rule below), variant modules whose documentation is consolidated under the umbrella catalog MAY omit the `.docc/` directory entirely. The umbrella owns the sole catalog; variant modules are documented through the umbrella's archive. No `.gitkeep` placeholder is needed: the CI runner's symbol-graph extraction emits no warnings for absent variant catalogs. The retired Xcode documentation-build workaround is not a supported compatibility surface.

**Rationale**: DocC discovers catalogue content by matching directory names to module names. Mismatched names prevent catalogue association. The exception preserves the literal-rule invariant while allowing packages to route all reader-facing content through a single umbrella catalog. With the CI symbol-graph route, the umbrella-owns-everything invariant becomes visible on disk — there are no empty placeholder directories obscuring which target carries documentation.

**Lint enforcement**: Reusable workflow `validate-docc-structure.yml` (`swift-institute/.github/.github/workflows/`) checks `.docc/` presence per Swift module under `Sources/`; honours [DOC-019a] umbrella-consolidation exception (target whose only source is `exports.swift` is exempt). Added Wave 2b finalization 2026-05-10.

**Cross-references**: [DOC-019a], research `swift-institute/Research/docc-multi-target-documentation-aggregation.md` v1.2.0.

---

### [DOC-019a] Multi-Target Consolidation Pattern

**Statement**: Packages with a multi-target + umbrella + `@_exported public import` shape SHOULD consolidate all per-symbol articles, tutorials, topical articles, and the landing page under the umbrella's `.docc` catalogue — NOT distributed across per-variant catalogues. Variant modules SHOULD omit `.docc/` entirely (per [DOC-020]'s exception clause); the umbrella owns the sole catalog.

**Why**: DocC's `@_exported public import` re-exports symbols into the umbrella's API surface but strips their doc comments during symbol-graph extraction. Without consolidation, readers entering the umbrella archive see signature-only pages for every re-exported symbol, while the variant archives (accessible via the sidebar) carry full docs. The result is a multi-catalog sidebar with no reader payoff — six `struct Property` entries, with the real documentation scattered across catalogues. Consolidation gives readers one `struct Property` with full docs in one catalogue.

**Correct (single-catalogue shape)**:

```
Sources/
├── Property Primitives/
│   └── Property Primitives.docc/         ← everything lives here
│       ├── Property Primitives.md        ← landing page
│       ├── GettingStarted.tutorial
│       ├── Tutorials.tutorial
│       ├── Resources/…                   ← tutorial step files
│       ├── Choosing-A-Property-Variant.md
│       ├── …
│       ├── Property.md                   ← per-symbol article (heading: Property_Primitives/Property)
│       ├── Property.Typed.md             ← heading: Property_Primitives/Property/Typed
│       └── …
├── Property Primitives Core/
│   └── Property.swift                    ← no .docc/ directory at all
├── Property Typed Primitives/
│   └── Property.Typed.swift              ← no .docc/
└── … (variant targets follow same shape — source files only)
```

**Per-symbol article headings**: in the consolidated catalogue, every per-symbol article's `#` heading MUST address the symbol through the umbrella module, not its declaring module. A per-symbol article for `Property.Typed` (declared in `Property_Typed_Primitives`) consolidated into the umbrella catalogue uses `# ``Property_Primitives/Property/Typed`` `, not `# ``Property_Typed_Primitives/Property/Typed`` `. DocC attaches the article as a documentation extension of the symbol as seen through the catalogue's primary module; the umbrella IS the catalogue's primary module.

**CI-runner shape**: CI may invoke SwiftPM directly to emit per-module symbol graphs, followed by a symbol-graph post-processing step and one `xcrun docc convert` on the umbrella catalogue with `--additional-symbol-graph-dir` pointing at a directory containing ONLY the patched umbrella graph. Local reproduction MUST route the SwiftPM build through `/Users/coen/Developer/swift-institute/Scripts/swift-build package build -- ...`. The post-processing step serves two roles: (a) inject any missing doc comments into the umbrella graph from sibling graphs — defensive no-op under the CI symbol-graph build, guarding against future regression; (b) **isolate** the umbrella graph into a dedicated output directory so `docc convert` can receive only the umbrella — isolation is load-bearing per the "cross-module ambiguity gotcha" below. Reference implementation: `swift-institute/Scripts/patch-umbrella-symbol-graph.py` (stdlib-only Python 3, authored 2026-04-24 under the ecosystem-wide R3 mandate of research `docc-multi-target-documentation-aggregation.md`).

**Correct pipeline invocation**:
```bash
# 1. CI runner emits per-module symbol graphs (preserves @_exported doc comments)
#    Local reproduction passes the same arguments after `swift-build package build --`.
swift build -c release \
    -Xswiftc -emit-symbol-graph \
    -Xswiftc -emit-symbol-graph-dir -Xswiftc "${DOCS_WORK}/symbol-graphs-raw"

# 2. Pool distribution graphs, excluding test support
mkdir -p "${DOCS_WORK}/symbol-graphs"
cp "${DOCS_WORK}/symbol-graphs-raw"/*.symbols.json "${DOCS_WORK}/symbol-graphs/"
rm -f "${DOCS_WORK}/symbol-graphs/<TestSupportModule>.symbols.json"

# 3. Patch umbrella graph with any still-missing doc comments AND isolate it
#    into its own directory. Output dir contains ONLY the patched umbrella
#    graph — NOT sibling graphs — because passing all graphs creates
#    cross-module reference ambiguity (see gotcha below). The doc-comment
#    injection is a defensive no-op under swift build; the isolation is
#    load-bearing.
python3 path/to/patch-umbrella-symbol-graph.py \
    --symbol-graph-dir "${DOCS_WORK}/symbol-graphs" \
    --umbrella-module <UmbrellaModuleName> \
    --output-dir "${DOCS_WORK}/umbrella-symbol-graph"

# 4. Convert. --additional-symbol-graph-dir gets ONLY the umbrella graph.
xcrun docc convert "Sources/<Umbrella>/<Umbrella>.docc" \
    --additional-symbol-graph-dir "${DOCS_WORK}/umbrella-symbol-graph" \
    --fallback-display-name "<Umbrella>" \
    --fallback-bundle-identifier "<package>.<Umbrella-kebab>" \
    --output-path "${DOCS_WORK}/archives/<Umbrella>.doccarchive"
```

**Why the SwiftPM symbol-graph route**:

| Property | Retired Xcode documentation route | SwiftPM symbol-graph route |
|----------|-----------------------------------|-----------------------------|
| Doc comments on `@_exported` re-exports | Stripped | Preserved (patch is defensive no-op) |
| Empty variant `.docc/` | Warns "No valid content" | No warning |
| Build footprint | Full derived-data tree | Object files + symbol graphs |
| Cross-platform portability | macOS-only | Any supported SwiftPM platform |

**Cross-module ambiguity gotcha**: `xcrun docc convert` must receive ONLY the patched umbrella graph via `--additional-symbol-graph-dir`, NOT the full pool of graphs. Passing the pool causes DocC to see the same precise identifier under both its declaring module AND the umbrella, and every in-catalog cross-reference to the symbol becomes ambiguous — DocC cannot choose which module path to resolve under, and `` `SymbolName` `` code spans in articles silently fail to resolve. Symptom: "Failed to resolve reference" warnings for every symbol referenced in articles. Fix: isolate the umbrella-graph file in a dedicated directory and pass only that directory.

**When NOT to apply**: packages whose downstream consumers genuinely need per-variant `.doccarchive` artifacts (e.g., a hosting pipeline that serves each variant's docs separately). Such cases are rare; most ecosystems want a single distribution archive.

**Rationale**: The source-level multi-target split exists for compile-time dependency-graph control (narrow imports per `[MOD-015]`). None of the justifications for that split apply to documentation fragmentation. Option F in the cited research is the ecosystem-idiomatic pattern — single archive, single sidebar, full per-symbol docs, while retaining the source-level narrow-import benefit.

**Cross-references**: [DOC-020], [DOC-023] (per-symbol article structure), [API-IMPL-005] (one type per file), research `swift-institute/Research/docc-multi-target-documentation-aggregation.md` v1.2.0 (DECISION).


---

### [DOC-021] Root Page

**Statement**: Every `.docc/` catalogue MUST contain a root page matching the module name. The root page serves one of two roles depending on the module's position in the package:

| Role | Module position | Content expectation |
|------|-----------------|---------------------|
| **Module root** | Any single library target's catalog | Baseline structure: `@Metadata`, preamble, Topics |
| **Landing page** | The umbrella / package-entry catalog in a multi-module package | Expanded structure: `@Metadata` + preamble + Featured/Tutorials/Topics, often `@CallToAction` — see [DOC-080] |

**Baseline structure** (module root):

```markdown
# ``{Module_Identifier}``

@Metadata {
    @DisplayName("{Human-Readable Name}")
    @TitleHeading("{Domain Heading}")
}

> Important: {Disclaimers or version notes if applicable.}

{Preamble text if applicable.}

## Topics

### {Domain Section Name}

- ``{Symbol}``
```

`@DisplayName` provides human-readable title. `@TitleHeading` provides domain context (e.g., "RFC 4122", "Swift Primitives", "Swift Institute").

**Correct** (module root):
```markdown
# ``RFC_4122``

@Metadata {
    @DisplayName("RFC 4122")
    @TitleHeading("A Universally Unique IDentifier (UUID) URN Namespace")
}

> Important: This module implements RFC 4122 as published July 2005.

## Topics

### Section 4: Algorithms for Creating a UUID

- ``Section_4``
```

For umbrella landing pages, see [DOC-080]. The landing page extends this baseline with visual hierarchy, tutorials, and featured content.

**Rationale**: The root page is the entry point. In multi-module packages, the umbrella's root page becomes the package-wide landing page; the two roles share structure with the landing page adding visual organization on top.

**Lint enforcement**: Reusable workflow `validate-docc-structure.yml` checks for the root `<Module>.md` file in every `.docc/` catalog (accepts both `Module_Name.md` and the human-readable `Module Name.md` form). Added Wave 2b finalization 2026-05-10.

**Cross-references**: [DOC-025], [DOC-080]

---

### [DOC-022] Article Pages — Navigation Level

**Statement**: Article pages at minimum MUST contain @Metadata:

```markdown
# ``{Module_Identifier}/{Symbol Path}``

@Metadata {
    @DisplayName("{Human-Readable Title}")
    @TitleHeading("{Domain Heading}")
}
```

This is sufficient for early development, shell types, or types whose inline documentation is self-contained.

**Rationale**: Even minimal article pages provide human-readable titles and domain context in rendered documentation.

---

### [DOC-023] Article Pages — Substantive Level (Per-Symbol)

**Statement**: Per-symbol article pages (Layer 2 of the four-layer model) MAY expand with substantive content sections. Recognized sections, in order:

| Section | Purpose | Content Source |
|---------|---------|---------------|
| `## Overview` | Framing context for the symbol | Mirrors inline summary + brief expansion |
| `## Specification` | Blockquoted spec text with cross-links | Mirrors inline docs |
| `## Example` | Working Swift code example | Mirrors inline docs (may be expanded) |
| `## Rationale` | Explanatory material for why the symbol exists | Exclusive to .docc |
| `## Research` | Links to relevant research documents | Exclusive to .docc |
| `## Experiments` | Links to relevant experiment packages | Exclusive to .docc |
| `## Topics → ### Conclusions` | Derived conclusions as navigable symbols | Exclusive to .docc |
| `## See Also` | Sibling symbols + topical articles + tutorials | Exclusive to .docc |

When specification text or code examples appear in both inline `///` and the .docc article, they MUST match semantically. The article is the superset — it mirrors inline content and adds explanatory depth.

**Dutch-language legal-domain equivalents**: Legal-domain packages in Dutch-language jurisdictions (the `swift-nl-wetgever` org, `rule-institute` Dutch-domain packages) MAY use the Dutch equivalent heading for a recognized section — the reader-facing terminology is domain-native Dutch, not English. Recognized mapping:

| Dutch heading | ≙ Canonical section |
|---|---|
| `## Substantiëring` | `## Rationale` |

The mapping is extensible — further Dutch equivalents get added to this table as they surface in practice. The underlying section semantics (content source, ordering, per-symbol vs topical placement per the table above) are unchanged; only the heading terminology localizes.


**Per-symbol vs topical scope**: a per-symbol article's content is specific to ONE symbol (the one named by the article's file name and `# ``Path/To/Symbol`` ` heading). Cross-symbol concepts, decision matrices, and task guides go in TOPICAL articles — see [DOC-060].

**Correct** (per-symbol article with research and experiment references):
```markdown
# ``Buffer_Ring_Inline_Primitives/Buffer.Ring.Inline``

@Metadata {
    @DisplayName("Buffer.Ring.Inline")
    @TitleHeading("Swift Primitives")
}

## Overview

Fixed-capacity ring buffer stored inline, enabling stack allocation on hot paths.

## Rationale

The inline ring buffer trades dynamic resizing for compile-time capacity,
enabling stack allocation and ~Copyable storage...

## Research

- [Ring Buffer Storage Variants](../../Research/ring-buffer-storage-variants.md) — Compares inline, heap, and hybrid storage strategies. Status: DECISION.
- [Bounded Index Precondition Elimination](../../Research/bounded-index-precondition-elimination.md) — Demonstrates that bounded indices eliminate runtime checks. Status: DECISION.

## Experiments

- [inline-ring-capacity-overflow](../../Experiments/inline-ring-capacity-overflow/) — Verifies compile-time capacity enforcement. Status: CONFIRMED.

## See Also

- ``Buffer/Ring`` — the heap-backed variant
- <doc:Choosing-A-Ring-Variant> — decision guide across ring buffer variants
```

**Rationale**: The substantive per-symbol article transforms .docc from navigation scaffolding into a complete Layer 2 reference. Explanatory material, research rationale, and experiment verification that don't belong in source code find their home here. Cross-symbol concepts escalate to topical articles ([DOC-060]) to avoid duplicating decision matrices across every sibling symbol.

**Cross-references**: [DOC-010], [DOC-027], [DOC-028], [DOC-029], [DOC-060], **legal-encoding** skill [LEG-ENC-*] (Dutch section-name equivalents)

---

### [DOC-024] Subsection Pages

**Statement**: When a type has documented subsections (RFC sub-clauses, ISO sub-sections), each SHOULD have its own article page:

```markdown
# ``{Module_Identifier}/{Parent}/{Subsection}``

@Metadata {
    @DisplayName("{Parent}.{Subsection} {Title}")
    @TitleHeading("{Domain Heading}")
}
```

**Correct**:
```markdown
# ``RFC_4122/Section 4.1/3``

@Metadata {
    @DisplayName("RFC 4122 Section 4.1.3 Version")
    @TitleHeading("RFC 4122")
}
```

**Rationale**: Per-subsection pages enable deep linking into specific clauses, which is essential for cross-reference navigation.

---

### [DOC-025] Topics Organization

**Statement**: The root page's `## Topics` section MUST group symbols by logical domain sections, not alphabetically. Section headings MUST match the domain's own organizational structure.

**Correct** (RFC sections):
```markdown
## Topics

### Section 3: Namespace Registration Template

- ``Section_3``

### Section 4: Algorithms for Creating a UUID

- ``V1``
- ``V4``
- ``V5``
```

**Incorrect**:
```markdown
## Topics

### V

- ``V1``
- ``V4``
- ``V5``
```

**Rationale**: Domain-native organization preserves the specification's own structure, making navigation intuitive for domain experts.

---

### [DOC-026] Flat Catalogue Layout

**Statement**: A `.docc/` catalogue MUST keep all articles, tutorials, and companion documents at the top level. Subdirectories (other than `Resources/` for tutorial step files and image assets) MUST NOT be introduced for author-facing organization.

**Correct**:
```
Sources/{Module Name}/{Module Name}.docc/
├── {Module Name}.md              ← Root/landing page
├── {PerSymbol}.md                ← Per-symbol articles, flat
├── {Topical-Article}.md          ← Topical articles, flat
├── {Chapter-1}.md                ← Companion-document chapters, flat
├── {Chapter-2}.md                ← Flat (not nested under a subdir)
├── {Tutorial}.tutorial
├── Tutorials.tutorial            ← Tutorial TOC ([DOC-070])
└── Resources/                    ← ONLY allowed subdirectory
    ├── step-01-empty.swift
    └── hero-image.png
```

**Incorrect**:
```
{Module}.docc/
├── {Module}.md
├── Articles/              ← ❌ author-facing nesting
│   └── Guide.md
└── Design Rationale/      ← ❌ companion-document subdirectory
    └── Chapter 1.md
```

**Rationale**: DocC resolves articles by filename, not path. Subdirectories add zero rendered-navigation value and break mechanical tooling that globs `*.md` at one level.

**Lint enforcement**: Reusable workflow `validate-docc-structure.yml` enumerates each `.docc/` catalog's immediate subdirectories and flags any non-`Resources/` subdir as a finding. Added Wave 2b finalization 2026-05-10.

Scale-out response: when a flat catalogue grows to the point of being hard to scan (~40+ articles), the correct answer is to promote stable concepts into per-symbol or topical article groups visible in the Topics section of the landing page ([DOC-084]), or to split the module, NOT to introduce subdirectories.

**Exceptions**: `Resources/` is mandatory for tutorial step files ([DOC-071]) and image assets ([DOC-091]). It is the only subdirectory permitted.


---

### [DOC-027] Content Layering Principle

**Statement**: Documentation lives in four distinct layers per the four-layer audience model in the preamble. Inline `///` is the call-site reference; `.docc` articles are the expanded reference (per-symbol and topical); tutorials are the learning path; extended companion material lives as additional flat `.docc` articles ([DOC-026]). Content authored in one layer MAY mirror into adjacent layers but MUST have a canonical home.

**The four layers — what goes where**:

| Content Type | Inline `///` (L1) | Per-symbol article (L2) | Topical article (L3) | Tutorial (L4) |
|-------------|:---:|:---:|:---:|:---:|
| Summary line | MUST | MUST (mirrored from inline) | — | — |
| Canonical usage snippet | SHOULD | MAY mirror | MAY mirror | — |
| Specification text (blockquoted) | MUST | MAY mirror | — | — |
| Cross-references (`` ``Symbol`` ``) | MUST | MUST | MUST | MUST |
| Per-symbol rationale | MUST NOT | MUST (when available) | MAY reference | — |
| Decision matrix / pattern guide | MUST NOT | MUST NOT (link out) | MUST (canonical home) | MAY reference |
| Task-oriented walkthrough | MUST NOT | MUST NOT | MAY (brief) | MUST (canonical home) |
| Research references | MUST NOT | SHOULD | SHOULD | MAY |
| Experiment references | MUST NOT | SHOULD | SHOULD | MAY |
| `@Metadata` block | — | MUST | MUST | MUST |
| Hero imagery, `@CallToAction` | — | — | — (optional) | — (optional) |

**Mirroring vs duplication**: specification text and canonical usage snippets appearing in both inline `///` and the per-symbol article are intentional mirrors — the call-site audience needs them in-source, the DocC audience needs them in-context. Other material has one canonical layer and is referenced (via DocC links) from others, not duplicated.

**Rationale**: Documentation is a synthesis of everything that came before — research, experiments, implementation, and tests. Four audiences need this synthesis at different depths and in different contexts. The Layer 1 audience (coder at the call site) gets the contract without leaving their editor. Layer 2 (reader on the symbol's DocC page) gets the same contract plus per-symbol rationale. Layer 3 (reader exploring a concept) gets cross-symbol guidance. Layer 4 (first-time learner) gets a walkthrough. Each layer stands alone; each has a natural next step.

**Cross-references**: [DOC-010], [DOC-023], [DOC-060], [DOC-070]

---

### [DOC-028] Research References in .docc Articles

**Statement**: When relevant research documents exist in the package's `Research/` directory, the **landing page** (or the README's `## Further reading` section) SHOULD include a `## Research` section with relative markdown links to those documents. Per-symbol and topical .docc articles MUST NOT carry a `## Research` section per [DOC-101]. Research/ stays at the package root — the landing page references it, not the other way around.

Each link MUST include the document title and its status (from the research document's metadata).

**Correct** (on the landing page):
```markdown
## Research

- [Heap Storage Variants](../../Research/heap-storage-variants.md) — Compares inline, heap, and hybrid storage. Status: DECISION.
- [Bounded Index Precondition Elimination](../../Research/bounded-index-precondition-elimination.md) — Demonstrates bounded indices eliminate runtime checks. Status: DECISION.
```

**Incorrect** (in a per-symbol article — violates [DOC-101]):
```markdown
# ``Buffer.Linear``
...
## Research                             <!-- ❌ per-symbol article carrying Research section; consumer/contributor boundary violation per [DOC-101] -->
- [Heap Storage Variants](...)
```

**Incorrect** (in inline `///` — violates [DOC-010]):
```swift
/// See Research/heap-storage-variants.md for rationale.
public struct Arena { ... }  // ❌ Research reference in inline docs
```

The `## Research` section SHOULD appear on the landing page after explanatory material sections and before `## Topics`.

**Rationale**: Research documents explain WHY design decisions were made. Linking them from the landing page creates a single navigable gateway from "what does this package do" to "why was it designed this way" — without polluting inline source documentation or cluttering per-symbol articles with maintainer-context the consumer doesn't need (per [DOC-101]). Research/ stays at the package root per [RES-002]; the landing page simply points to it.


**Cross-references**: [DOC-010], [DOC-023], [DOC-101], [RES-002], [RES-006]

---

### [DOC-029] Experiment References in .docc Articles

**Statement**: When relevant experiments exist in the package's `Experiments/` directory, the **landing page** (or the README's `## Further reading` section) SHOULD include a `## Experiments` section with relative markdown links to those experiment directories. Per-symbol and topical .docc articles MUST NOT carry a `## Experiments` section per [DOC-101]. Experiments/ stays at the package root — the landing page references it, not the other way around.

Each link MUST include the experiment name and its status (CONFIRMED/REFUTED/SUPERSEDED from the experiment header).

**Correct** (on the landing page):
```markdown
## Experiments

- [inline-ring-capacity-overflow](../../Experiments/inline-ring-capacity-overflow/) — Verifies compile-time capacity enforcement. Status: CONFIRMED.
- [noncopyable-inline-deinit](../../Experiments/noncopyable-inline-deinit/) — Verifies deinit behavior for ~Copyable inline storage. Status: CONFIRMED.
```

**Incorrect** (in a per-symbol article — violates [DOC-101]):
```markdown
# ``Buffer.Linear``
...
## Experiments                           <!-- ❌ per-symbol article carrying Experiments section; consumer/contributor boundary violation per [DOC-101] -->
```

**Incorrect** (in inline `///` — violates [DOC-010]):
```swift
/// Verified in Experiments/inline-ring-capacity-overflow/
public struct Ring { ... }  // ❌ Experiment reference in inline docs
```

The `## Experiments` section SHOULD appear on the landing page after `## Research` and before `## Topics`.

**Rationale**: Experiments provide empirical verification of design decisions. Linking them from the landing page closes the loop: specification text (what) → research (why) → experiments (proof). Experiments/ stays at the package root per [EXP-002]; the landing page simply points to it. Per [DOC-101], the consumer-facing per-symbol surface stays focused on API behavior; the contributor-facing experiment record lives behind the landing-page gateway.


**Cross-references**: [DOC-010], [DOC-023], [DOC-101], [EXP-002], [EXP-003]

---


---

## DocC Architecture and Tooling

### [DOC-100] Layering Principle — Inline and .docc Carry Distinct Weight

**Statement**: Inline `///` documentation carries call-site recall (summary + canonical usage + the 1-2 most important cross-references); `.docc` articles carry reference depth (decision matrices, rationale, architectural context, comparative tables). Neither layer is a placeholder for the other. A first-pass [DOC-010] application that strips inline down to *"see .docc"* destroys call-site discoverability and MUST be reverted.

**What belongs where**:

| Layer | Content |
|-------|---------|
| Inline `///` | One-sentence summary; 1-3 lines of canonical usage; 1-2 xrefs to the most relevant .docc articles |
| `.docc` article | Decision matrices; rationale paragraphs; architectural context; comparative tables; design history |

**Anti-pattern**: inline docs reduced to `/// See \`<ArticleName>\` for details.` — the reader pressing option-click on the symbol in the IDE gets nothing actionable.

**Rationale**: [DOC-002] covered inline minimum content; [DOC-010] covered the .docc article shape. Neither rule forbade the degenerate case where an over-eager [DOC-010] application strips inline of actionable content. The layering principle makes the distribution of content between layers an explicit rule.


**Cross-references**: [DOC-002], [DOC-010]

---

### [DOC-101] Consumer/Contributor Boundary in DocC

**Statement**: Per-symbol and topical DocC articles MUST NOT carry `## Research`, `## Experiments`, `Status: DECISION` tags, or See-Also links into `Research/` / `Experiments/`. The consumer-facing DocC catalog is for consumers of the API; research and experiments belong to contributors and live outside DocC. Exactly one page — the landing page (or the README's `## Further reading` section) — SHOULD carry a consolidated gateway to `Research/`.

**Where supersession records live**: Decision records with supersession get a `### Resolution` subsection in the Research doc — not a historical note in DocC. DocC articles describe what the API currently does, not what prior decisions led to it.

**Rationale**: DocC is the consumer surface; Research/ is the contributor surface. Mixing them inflates per-symbol articles with maintainer-context the consumer doesn't need and leaks contributor-scoped supersession records into the consumer narrative. The consumer model should read as stable; the contributor model can be volatile. Keeping the two models in separate artifacts protects both.

**Lint enforcement**: Reusable workflow `validate-docc-structure.yml` greps each non-root `.md` file in `.docc/` for `^## Research` / `^## Experiments` / `^Status: DECISION` markers and flags occurrences. Added Wave 2b finalization 2026-05-10.


**Cross-references**: [DOC-027], [DOC-028], [DOC-029]

---

### [DOC-102] Preview-and-Convert Parity in DocC Tooling Guidance

**Statement**: [DOC-019a]'s "Cross-module ambiguity gotcha" guidance applies to `docc preview` as well as `docc convert`. The same patch-script + `--exclude-module` + `--additional-symbol-graph-dir` isolation discipline MUST be applied when running local preview of a multi-target umbrella catalog.

**Patch-script citation rule**: Cited tooling artifacts (patch-umbrella-symbol-graph.py, preview-docs.sh) MUST exist at the cited path in the workspace, OR the citation MUST be written in the aspirational tense and linked to the tracking handoff. A citation that references a non-existent artifact is a defect in the skill text, not a gap in the tooling.

**Rationale**: Preview-only gaps in the tooling guidance cost one diagnostic round-trip when the preview fails where the build succeeded. Skill texts that cite artifacts accumulate reference rot when the artifact's build trails the citation; the aspirational-tense discipline makes the gap visible without withholding the eventual reference.


**Cross-references**: [DOC-019a]

---
