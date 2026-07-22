# Documentation — Topical Articles

Part of the **documentation** skill. See `SKILL.md` for the navigation hub, four-layer audience model, and rule index.

**Rules in this file**: [DOC-060], [DOC-061], [DOC-062], [DOC-063], [DOC-064].

---

## Topical Articles

Topical articles (Layer 3 of the four-layer audience model) are `.docc` articles whose scope is a *concept, pattern, or task* — not a single symbol. They are the canonical home for decision matrices, pattern guides, cross-symbol walkthroughs, and conceptual explanations. Per-symbol articles link TO topical articles to avoid duplicating cross-cutting material across every sibling symbol.

### [DOC-060] When to Create a Topical Article

**Statement**: A topical article SHOULD be created when the content meets ANY of the following criteria:

| Trigger | Example |
|---------|---------|
| Decision matrix across sibling symbols | "Choosing a Property Variant" — decides across `Property`, `Property.Typed`, `Property.View`, etc. |
| Pattern or recipe that uses multiple symbols | "CoW-Safe Mutation Recipe" — spans Property, CoW containers, `_modify` accessors |
| Concept that spans the package | "Phantom Tag Semantics" — explains a concept used throughout |
| Task-oriented guide | "Porting a Proxy Struct to Property" — step-by-step without `@Tutorial` overhead |
| Cross-package design context | "Why Property and Tagged Are Separate Types" |

**Topical articles MUST NOT be created** for content that naturally belongs to one symbol — that content goes in the per-symbol article's `## Rationale` (see [DOC-023]).

**Rationale**: Without topical articles, cross-symbol content either duplicates into every per-symbol article (drift, smell) or lives in README/inline where it has the wrong audience. Topical articles are the shape-fit for concepts and tasks.

**Cross-references**: [DOC-023], [DOC-027], [DOC-061], [DOC-063]

---

### [DOC-061] Topical Article Structure

**Statement**: Topical articles MUST follow this structure:

```markdown
# {Topic Title}

@Metadata {
    @DisplayName("{Human-Readable Title}")
    @TitleHeading("{Domain Heading}")
}

{One-paragraph framing: what this article answers and who it's for.}

## {First substantive section}

{Prose, tables, code snippets as needed.}

## {Second substantive section}

...

## See Also

- ``Symbol1``
- ``Symbol2``
- <doc:Related-Topical-Article>
- [Research: {Title}](../../Research/{kebab-name}.md) — Status: {STATUS}
```

Unlike per-symbol articles, topical articles do NOT have an `# ``Module/Symbol`` ` DocC heading — they have a natural-language `# Title`. DocC renders them as articles, not as symbol pages.

**Filename convention**: kebab-case, `{Topic}.md` or `{Verb}-A-{Thing}.md` — matches the article's natural-language title.

**Correct** (topical article):
```markdown
# Choosing a Property Variant

@Metadata {
    @DisplayName("Choosing a Property Variant")
    @TitleHeading("Property Primitives")
}

Pick the `Property` variant by two questions — is your `Base` `Copyable` or
`~Copyable`, and do your extensions need an `Element` type parameter in scope?

## Decision Matrix

| Container | Extension shape | Variant |
|-----------|-----------------|---------|
| `Copyable` | Methods only | ``Property`` |
| `Copyable` | Properties | ``Property/Typed`` |
| `~Copyable` | Mutable pointer | ``Property/View-swift.struct`` |
| `~Copyable` | Read-only | ``Property/View-swift.struct/Read`` |

## Why There Are Five Variants

The family splits along the ownership/access-model axis ...

## See Also

- ``Property``
- ``Property/Typed``
- ``Property/View-swift.struct``
- [Variant Decomposition Rationale](../../Research/variant-decomposition-rationale.md) — Status: DECISION.
```

**Rationale**: Topical articles are structurally DocC articles, not symbol pages. The natural-language title reflects that they're task- or concept-oriented, not tied to one symbol.

**Cross-references**: [DOC-060], [DOC-063]

---

### [DOC-062] Topical Article Location

**Statement**: Topical articles live in `.docc/` alongside per-symbol articles. They MAY be placed in any catalog, but SHOULD be placed in the catalog whose audience most naturally reaches them:

| Article scope | Target catalog |
|---------------|----------------|
| Package-wide concept or entry-point guide | Umbrella catalog |
| Module-specific pattern | That module's catalog |
| Variant-family decision matrix (spans one target's symbols) | That target's catalog |

Umbrella catalogs typically host the Getting-Started article, variant-selection guides, and cross-package concepts. Variant-target catalogs host pattern recipes specific to that variant.

**Rationale**: Readers encounter topical articles via the catalog's root page Topics or `@CallToAction` — placing them in the catalog whose audience is closest minimizes navigation cost.

**Cross-references**: [DOC-061], [DOC-063], [DOC-080]

---

### [DOC-063] Topical Articles in Topics

**Statement**: The containing catalog's root page Topics section MUST reference topical articles in appropriately named groups, distinct from per-symbol groups:

```markdown
## Topics

### Getting Started

- <doc:Getting-Started>
- <doc:Choosing-A-Property-Variant>

### Patterns

- <doc:CoW-Safe-Mutation-Recipe>
- <doc:~Copyable-Container-Patterns>

### Concepts

- <doc:Phantom-Tag-Semantics>

### Types

- ``Property``
- ``Property/Typed``
```

**Rationale**: Grouping topical articles by their role (getting-started, patterns, concepts) separates them visually from symbol references — readers navigating for a concept find concepts together, readers navigating for a symbol find symbols together.

**Cross-references**: [DOC-025], [DOC-061]

---

### [DOC-064] Per-Symbol vs Topical Article Decision

**Statement**: When a piece of content could go in either a per-symbol article's `## Rationale` section or a topical article, use this decision:

| Criterion | Per-symbol `## Rationale` | Topical article |
|-----------|---------------------------|-----------------|
| Primary referent | ONE symbol | Multiple symbols OR a concept |
| Cross-references OUT | Mostly to siblings | Mostly to per-symbol articles |
| Reader's mental starting point | "I landed on this symbol's page" | "I want to understand X" |
| Natural title | `Property/Typed` | "Choosing a Property Variant" |
| Content duplication risk | Low (per-symbol is unique) | High if inlined in N per-symbol articles |

If the same content would need to appear in more than one per-symbol article, it belongs in a topical article.

**Rationale**: The duplication test is the clearest signal. Cross-cutting content inlined in every per-symbol article drifts — each copy evolves separately. A single topical article with references from per-symbol articles stays coherent.

**Cross-references**: [DOC-023], [DOC-060], [DOC-063]

---

