# Documentation — Landing Pages

Part of the **documentation** skill. See `SKILL.md` for the navigation hub, four-layer audience model, and rule index.

**Rules in this file**: [DOC-080], [DOC-081], [DOC-082], [DOC-083], [DOC-084].

---

## Landing Pages

Landing pages are catalog root pages ([DOC-021]) that serve as a package's primary entry point. They extend the baseline root page with visual hierarchy, featured content, and cross-layer navigation.

### [DOC-080] Umbrella Catalog as Landing Page

**Statement**: In a package with multiple library targets (Core + variants + umbrella), the umbrella catalog's root page MUST serve as the package's landing page. The landing page's content structure:

```markdown
# ``{Umbrella_Module}``

@Metadata {
    @DisplayName("{Package Name}")
    @TitleHeading("{Domain Heading}")
    @PageColor({color})           // optional, see [DOC-090]
    @PageImage(                     // optional, see [DOC-091]
        purpose: header,
        source: "{hero-image}"
    )
    @CallToAction(                  // recommended for packages with tutorials
        url: "<doc:Getting-Started>",
        purpose: link,
        label: "Get Started"
    )
}

One-paragraph package description.

## Overview

{Longer framing — 2-3 paragraphs on what the package offers and who it's for.}

@Row {                              // optional, see [DOC-082]
    @Column {
        ### Getting Started
        {Pointer to first tutorial or Getting-Started article.}
    }
    @Column {
        ### Choose a Variant
        {Pointer to decision guide.}
    }
    @Column {
        ### Learn the Concepts
        {Pointer to key topical article.}
    }
}

## Topics

### Tutorials

- <doc:tutorials/Tutorials>

### Getting Started

- <doc:Getting-Started>
- <doc:Choosing-A-Property-Variant>

### Patterns

- <doc:CoW-Safe-Mutation-Recipe>

### Concepts

- <doc:Phantom-Tag-Semantics>

### Core Types

- ``Property``
- ``Property/Typed``

### Related Modules

- ``{Variant_Module_1}``
- ``{Variant_Module_2}``
```

Non-umbrella module catalogs (Core, variants) SHOULD remain at baseline [DOC-021] structure — they are module roots, not landing pages.

**Rationale**: Readers encountering a multi-module package need a single entry point. The umbrella landing page is that entry — it carries visual affordances and cross-layer navigation that variant-module roots don't need. Placing all entry-point navigation on the umbrella keeps variant-module roots focused on their type catalog.

**Note on "umbrella"**: "Umbrella" here is the DocC catalog sense — a root `.docc` that hosts the landing page and consolidated docs. Distinct from the SwiftPM umbrella target ([MOD-005]) and the testing-routing umbrella skill (`testing`).

**Cross-references**: [DOC-021], [DOC-081], [DOC-082], [DOC-083], [MOD-005]

---

### [DOC-081] @CallToAction

**Statement**: Landing pages SHOULD include an `@CallToAction` in their `@Metadata` block to direct readers to the package's primary entry point (typically the Getting-Started article or tutorial).

```markdown
@Metadata {
    @CallToAction(
        url: "<doc:Getting-Started>",
        purpose: link,
        label: "Get Started"
    )
}
```

Purposes:
- `purpose: link` — in-package navigation (default for most landing pages)
- `purpose: download` — for packages that distribute an external artifact

The `@CallToAction` renders as a prominent button at the top of the landing page.

**Rationale**: First-time visitors need an obvious next step. Without an explicit call-to-action, the Topics section is the only navigation; readers must scan it and choose. The call-to-action removes one decision point from the onboarding flow.

**Cross-references**: [DOC-080]

---

### [DOC-082] @Row and @Column Layout

**Statement**: Landing pages MAY use `@Row { @Column { ... } @Column { ... } }` layouts to surface 2–4 featured entry points side-by-side. Use this pattern for featured content groupings (e.g., Getting Started / Decision Guide / Concept Overview), not for dense content.

```markdown
@Row {
    @Column {
        ### Getting Started
        Start here if you're new — a 5-minute walkthrough.

        <doc:Getting-Started>
    }
    @Column {
        ### Choose a Variant
        Decide which Property type fits your container.

        <doc:Choosing-A-Property-Variant>
    }
    @Column {
        ### Understand the Concepts
        Why phantom tags, and what they discriminate.

        <doc:Phantom-Tag-Semantics>
    }
}
```

Each column should contain a heading (H3), one sentence of framing, and one link. Don't put dense content in columns — it breaks the scan-ability the layout provides.

**Rationale**: Side-by-side featured content is more scan-able than a linear list on a landing page. A 3-column row of entry points is a common pattern for package landing pages; DocC supports it natively.

**Cross-references**: [DOC-080]

---

### [DOC-083] @TabNavigator

**Statement**: Landing pages for packages with multiple distinct audiences (e.g., "for app developers" vs "for library authors") MAY use `@TabNavigator` to split the landing page into audience-specific panels. This is an optional pattern — prefer a single landing path unless audience bifurcation is real.

```markdown
@TabNavigator {
    @Tab("For App Developers") {
        ## Getting Started
        ...
    }

    @Tab("For Library Authors") {
        ## Advanced Patterns
        ...
    }
}
```

**Rationale**: Some packages serve fundamentally different audiences whose paths through the documentation diverge from the start. `@TabNavigator` splits the landing without duplicating the full catalog. For most packages, a single landing path is clearer; `@TabNavigator` is a specialized tool.

**Cross-references**: [DOC-080]

---

### [DOC-084] Topics Grouping on Landing Pages

**Statement**: Landing page Topics sections MUST group entries by role, ordered from most-newcomer-friendly to most-reference-oriented:

1. Tutorials
2. Getting Started (task-oriented topical articles for first-time users)
3. Patterns (cross-symbol pattern guides)
4. Concepts (cross-symbol concept articles)
5. Core Types (primary symbols)
6. Related Modules (variant modules or sibling packages)

Only include sections that actually have content — empty group headings are noise.

**Rationale**: The order mirrors the reader's progression: newcomer lands on Tutorials, explorer lands on Patterns, reference-seeker lands on Core Types. Grouping symbols and articles into distinct sections prevents the landing page from collapsing into an undifferentiated symbol dump.

**Cross-references**: [DOC-025], [DOC-063], [DOC-080]

---

