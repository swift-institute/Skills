# Documentation — Tutorials

Part of the **documentation** skill. See `SKILL.md` for the navigation hub, four-layer audience model, and rule index.

**Rules in this file**: [DOC-070], [DOC-071], [DOC-072], [DOC-073], [DOC-074].

---

## Tutorials

Tutorials (Layer 4 of the four-layer audience model) are interactive, step-by-step walkthroughs for first-time or less experienced readers. They live as `.tutorial` files inside the `.docc/` catalog, with Swift source for each step in `.docc/Resources/`.

### [DOC-070] Tutorial Table of Contents (Required)

**Statement**: A `.docc/` catalog containing one or more `@Tutorial` files MUST also contain a `@Tutorials` table-of-contents file. Without it, `xcodebuild docbuild` emits a warning ("Missing tutorial table of contents page") and silently omits the tutorial from the rendered archive.

**Correct**:
```
Sources/{Module}/{Module}.docc/
├── {Module}.md
├── Tutorials.tutorial              ← @Tutorials TOC — required
├── GettingStarted.tutorial         ← @Tutorial
└── Resources/
    ├── step-01-empty.swift
    └── step-02-with-api.swift
```

`Tutorials.tutorial` contents:
```
@Tutorials(name: "{Module Display Name}") {
    @Intro(title: "Tutorials for {Module}") {
        One-paragraph description of the tutorial collection.
    }

    @Chapter(name: "Getting Started") {
        @TutorialReference(tutorial: "doc:GettingStarted")
    }
}
```

**Rationale**: DocC's tutorial rendering requires the TOC; `@Tutorial` files MUST be referenced from a `@Tutorials` file. Verified at `swift-institute/Experiments/docc-tutorial-host-necessity/`.

**Lint enforcement**: Reusable workflow `validate-docc-structure.yml` checks: when a `.docc/` directory contains any `*.tutorial` files, it MUST also contain `Tutorials.tutorial`. Added Wave 2b finalization 2026-05-10.


**Cross-references**: [DOC-071], [DOC-072]

---

### [DOC-071] Tutorial Code Layout (Catalog-Resident)

**Statement**: Swift source files referenced by `@Code` directives MUST live inside the catalog's `Resources/` subdirectory. A separate SwiftPM "tutorial host" target is NOT needed and MUST NOT be introduced — DocC reads the catalog-resident files directly.

**Correct**:
```
Sources/{Module}/{Module}.docc/
├── GettingStarted.tutorial
└── Resources/
    ├── step-01-empty.swift
    └── step-02-with-api.swift
```

Tutorial references step files by filename:
```
@Code(name: "main.swift", file: "step-01-empty.swift")
```

**Incorrect** (introducing a host target):
```swift
// Package.swift
.target(
    name: "{Module} Tutorial Host",   // ❌ Not needed
    dependencies: ["{Module}"],
    path: "Sources/Tutorials"
)
```

**Rationale**: DocC treats tutorial step files as text to render, not Swift to compile. A host target adds maintenance overhead without functional benefit. Verified at `swift-institute/Experiments/docc-tutorial-host-necessity/`.

**Lint enforcement**: Reusable workflow `validate-docc-structure.yml` parses each `*.tutorial` for `@Code(file: "...")` references and verifies the file resolves to `.docc/Resources/<name>`. Added Wave 2b finalization 2026-05-10.


**Cross-references**: [DOC-070], [DOC-073]

---

### [DOC-072] Tutorial Structure

**Statement**: Individual `.tutorial` files MUST follow the DocC tutorial directive hierarchy:

```
@Tutorial(time: {minutes}) {
    @Intro(title: "{Title}") {
        {Framing paragraph: what the reader will accomplish.}
    }

    @Section(title: "{Section Title}") {
        @ContentAndMedia {
            {Section introduction.}
        }

        @Steps {
            @Step {
                {Step description — what the reader does.}

                @Code(name: "main.swift", file: "step-01-empty.swift")
            }

            @Step {
                {Next step description.}

                @Code(name: "main.swift", file: "step-02-with-api.swift")
            }
        }
    }
}
```

Naming: `.tutorial` files use `PascalCase.tutorial`. Step source files use `kebab-case-with-step-number.swift` (e.g., `step-01-empty.swift`, `step-02-with-api.swift`).

**Rationale**: Consistent structure makes tutorials predictable for both authors and readers. The PascalCase-for-tutorials / kebab-case-for-steps split mirrors the natural-language-vs-filename pattern used elsewhere.

**Cross-references**: [DOC-070], [DOC-071]

---

### [DOC-073] Tutorial Code Verification

**Statement**: DocC does NOT verify the correctness of tutorial step code — `xcodebuild docbuild` renders step files as text even when the Swift is invalid. Packages that ship tutorials as part of a long-lived release MUST establish a separate verification mechanism so tutorial code stays valid as the underlying API evolves.

Three acceptable mechanisms:

| Mechanism | Cost | Benefit |
|-----------|------|---------|
| Test target mirroring the final step's code | One test file per tutorial | Compile breaks the test suite; visible on CI |
| CI step running `swiftc` on each `Resources/*.swift` | One shell step | Compile check without a test target |
| Explicit manual review discipline (documented policy) | Zero infrastructure | Fragile — humans forget |

The choice is package-specific; the constraint is that ONE mechanism MUST be in place for any package whose tutorials are part of a timeless or long-lived release. Packages that ship tutorials as exploratory material (with explicit "may rot" notice) MAY skip this.

**Rationale**: Tutorials carry first-impression weight. A tutorial whose step code no longer compiles is worse than no tutorial — it misleads newcomers. DocC's text-rendering model means the tutorial-host question is settled but the verification question must be answered separately. Verified experimentally: `swift-institute/Experiments/docc-tutorial-host-necessity/` — invalid Swift in a step file builds the archive successfully without warning.


**Cross-references**: [DOC-070], [DOC-071]

---

### [DOC-074] Tutorial Scope

**Statement**: Each tutorial SHOULD target a focused scope achievable in 5–15 minutes. A single package SHOULD start with ONE tutorial (typically "Getting Started"); additional tutorials SHOULD only be added when the first tutorial's scope has proven insufficient for the target audience.

Acceptable scopes:
- A 5-minute Getting Started covering tag → typealias → accessor → call-site.
- A 10-minute guided migration from one API shape to another.
- A 15-minute introduction to a package-specific pattern with full walkthrough.

Scopes that SHOULD be topical articles, not tutorials:
- Decision matrices (they don't walk through a task — they compare options).
- Pattern references with no sequential step structure.
- Multi-tutorial learning paths covering a full curriculum (typically out of scope for a single package).

**Rationale**: Tutorials are the highest-maintenance layer (per [DOC-073] verification discipline). Starting with one tutorial scoped narrowly ensures the verification mechanism is right before scaling. Expanding from there is cheap; contracting from a broad set is not.

**Cross-references**: [DOC-070], [DOC-073]

---

