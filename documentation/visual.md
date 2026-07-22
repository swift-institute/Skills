# Documentation — Page Design

Part of the **documentation** skill. See `SKILL.md` for the navigation hub, four-layer audience model, and rule index.

**Rules in this file**: [DOC-090], [DOC-091], [DOC-092], [DOC-093].

---

## Page Design

DocC supports visual customization via `@Metadata` directives. Page design is optional but MAY be used to establish visual identity for a package or ecosystem.

### [DOC-090] @PageColor

**Statement**: The root page of a catalog MAY declare a page color via `@Metadata { @PageColor({name}) }`. Supported named colors are `blue`, `gray`, `green`, `orange`, `purple`, `red`, `yellow`. The color appears as an accent on the rendered page.

```markdown
@Metadata {
    @PageColor(purple)
}
```

Package-level and ecosystem-level visual consistency:
- If the ecosystem defines a color palette, all packages in the ecosystem SHOULD use colors from that palette.
- If no ecosystem palette exists, a package MAY define its own color and apply it consistently to all its catalog root pages.
- Individual per-symbol or topical articles SHOULD NOT override the package color — consistency across the package is more valuable than per-article variation.

**Rationale**: Visual identity is a brand-level concern, not a per-article concern. Applied consistently, it differentiates the package's DocC site. Applied inconsistently, it looks chaotic.

**Cross-references**: [DOC-091], [DOC-093]

---

### [DOC-091] @PageImage

**Statement**: Landing pages MAY declare hero images via `@Metadata { @PageImage(purpose: header, source: "{filename}") }`. The image file MUST live in `.docc/Resources/` and be referenced by basename.

```markdown
@Metadata {
    @PageImage(purpose: header, source: "hero-property-primitives")
}
```

Supported purposes:
- `purpose: header` — a hero image at the top of the page
- `purpose: card` — a thumbnail image for article cards (used when the article is referenced from a landing page with `@Row`/`@Column` layout)

Image assets: PNG or JPEG, optimized for web (under 200 KB). Alternatively, SVG for vector logos.

Package-level and ecosystem-level consistency: the same rules as [DOC-090] apply — if the ecosystem defines hero imagery conventions, use them; otherwise establish package-level conventions and apply uniformly.

**Rationale**: Hero imagery signals production quality and package identity. As with color, consistency matters more than per-article variation. Per-article hero images are appropriate for topical articles and tutorials with distinct visual identity (e.g., a Getting Started article with a dedicated image) but SHOULD follow the package's overall design language.

**Cross-references**: [DOC-090], [DOC-093]

---

### [DOC-092] @Available

**Statement**: Documentation pages MAY declare platform or Swift-version availability via `@Metadata { @Available({platform}, introduced: "{version}") }`. Use when a type or feature has narrower availability than the module as a whole.

```markdown
@Metadata {
    @Available(Swift, introduced: "6.3")
    @Available(macOS, introduced: "26.0")
}
```

Most catalogs and articles will NOT need `@Available` — the module's declared platform minimums (in Package.swift) cover the general case. Use `@Available` only for per-symbol or per-article narrower gating.

**Rationale**: Availability at the page level is additive to the module-level availability. Use sparingly; for whole-package availability, rely on Package.swift's `platforms:` declaration.

**Cross-references**: [DOC-093]

---

### [DOC-093] Visual Consistency Across Catalogues

**Statement**: In a multi-module package, the page design choices (`@PageColor`, `@PageImage`, landing layout) MUST be consistent across all catalogues in the package. Variant catalogues MAY omit `@PageColor` to inherit the umbrella's color, but MUST NOT declare a *different* color.

**Rationale**: A multi-module package's DocC site is read as one entity. Visual inconsistency across its catalogues signals a broken project. Consistency is the default; deliberate variation requires a documented reason.

**Cross-references**: [DOC-090], [DOC-091]

---

