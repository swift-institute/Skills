---
name: readme/sub-package
description: |
  Family E rules — sub-package library README structure, voice, motivated examples,
  scope boundary, stability operational form. Apply when authoring or reviewing a
  sub-package library repo's README.md (e.g., swift-property-primitives, swift-html,
  swift-rfc-4122).

layer: implementation

requires:
  - readme

applies_to:
  - swift-primitives
  - swift-standards
  - swift-foundations
  - swift-nl-wetgever
  - swift-us-nv-legislature
  - swift-law
  - rule-law
  - coenttb
# Amendment/changelog history: rationale archive (Readme Skill Rationale Archive) §Changelog-Provenance (and git history of this file).
---

# Sub-Package Library README

Family E rules. Authoring contract for individual Swift package READMEs that render at `github.com/<owner>/<repo>` and Swift Package Index — the evaluator-facing surface of every implemented package in the ecosystem.

Loaded on demand from the **readme** skill hub (`SKILL.md`). The two universal meta-rules — [README-023] Evaluator's Lens and [README-026] No Internal Rule-ID Citations — apply to this family and live in the hub; do not duplicate them here.

**Scope**: All `<repo>/README.md` files in implemented Swift package repos under any leaf org (swift-primitives, swift-foundations, swift-nl-wetgever, swift-us-nv-legislature) or under an org-of-orgs that hosts package repos directly (swift-standards). Also covers individual Swift package repos under coenttb (a user account whose package repos follow the same library register, distinct from the user-profile register at `coenttb/coenttb/README.md`).

Full evicted rationale, provenance, incident narratives, and extra example variants for this family: the rationale archive (`Readme Skill Rationale Archive`), referenced below.

---

## Voice

Sub-package READMEs operate in a third-person, evaluator-shaped register. Every paragraph answers "Do I want to use this package?" — see [README-023] Evaluator's Lens in the hub.

| Element | Convention |
|---|---|
| Person | Third-person. "This package …", "Use X for Y", "The umbrella product …". No first-person ("we", "I") in consumer-facing prose. |
| Marketing language | Forbidden without quantified substance per [README-006] and [README-016]. "very fast" is forbidden; "1,939 PDFs/sec on M1 Mac Mini, macOS 14.0, Swift 5.10" earns its place. |
| Examples | Motivated per [README-024] — must demonstrate something impossible, awkward, or subtly wrong without the package. Domain-meaningful identifiers (no `Foo` / `Bar` / `x` / `y`). |
| Author-side context | Forbidden per [README-016] and [README-023]. No implementation autobiography, no design reflections, no internal workaround rationale, no ecosystem-positioning ("This package is Layer N of …"). Relocate to `Research/` or DocC. |
| Tone | Technical density appropriate to a developer evaluating adoption. Specification-mirroring naming when applicable. |
| Length | Driven by content, not template. Minimum-tier packages: ~30 lines. Standard-tier: 100–200 lines. Complete-tier: 200–400 lines. > 500 lines suggests content belongs in DocC. |

The voice generalizes across orgs: a swift-primitives package and a coenttb package follow the same register, even though the user's personal `<user>/<user>/README.md` (Family A) does not.

---

## Workflow Position

READMEs can be written at any point — even before implementation (README-driven development). Unlike `/documentation` (which synthesizes after implementation), READMEs describe **what the package does and how to use it** and can evolve alongside the code.

| Phase | README State |
|-------|-------------|
| Pre-implementation | Title, badge, one-liner, architecture sketch |
| Active development | + Installation, Quick Start |
| Feature-complete | + Key Features, Platform Support, Error Handling |
| v1.0+ | Full README with all applicable sections |

---

## Family-Scoped Meta-Rules

Three additional whole-README disciplines apply specifically to sub-package READMEs. They sit alongside the universal meta-rules ([README-023], [README-026] in the hub).

### [README-024] Motivated Examples (Earn Complexity)

**Statement**: Every code example in a README MUST demonstrate something the package enables that is **impossible, awkward, or subtly wrong** to express without the package. Trivial call-sites whose non-library equivalent is identical are forbidden.

Examples earn their complexity when they demonstrate:

| Category | Example |
|----------|---------|
| **Impossible without the package** | `Complex<Double>.i` in swift-numerics — the type does not exist in stdlib |
| **Correct-by-construction concurrency** | swift-atomics' counter incrementing to 10_000_000 across 10 concurrent queues |
| **Resource safety made visible** | swift-system's `FileDescriptor.open { ... }` via `closeAfter` — automatic close on scope exit |
| **API magic made visible** | swift-argument-parser's `@main struct Repeat: ParsableCommand` — property wrappers declare the CLI inline |
| **Failure diagnostics** | swift-testing's `#expect(greeting == "Hello")` with captured value on failure |
| **Composition at a glance** | swift-parsing's parser composition vs the nested `.split(separator:)` baseline |

**Incorrect** (`stack.inspect.count` is trivially identical to `stack.count` — readers learn nothing about why `Property.View.Read` exists):

```swift
let stack = Stack<Int>()
_ = stack.inspect.count  // ❌ Unmotivated — stack.count already does this
```

**Decision test**: Write the shortest non-library-using equivalent of the example. If the non-library version is identical or trivially shorter, the example is unmotivated and must be replaced with something the package genuinely enables.

**Recommended technique — baseline contrast**: When the library's value is not self-evident from a single API call, show the naive solution first, then the library's version. `swift-parsing`'s opening is the canonical case. See [README-022].

**Rationale**: Motivated examples are the near-universal practice across surveyed first-class Swift OSS (8 of 15 packages' first example would be impossible, awkward, or subtly wrong without the library); the unmotivated-example anti-pattern triggered the v2.0.0 skill revision (full text + correct example variant: rationale archive §[README-024]).

**Cross-references**: [README-009], [README-022], [README-023]

---

### [README-025] Scope Boundary (Package vs Ecosystem)

**Statement**: Sub-package READMEs MUST NOT include Institute-level ecosystem-hierarchy content. Content describing "where this package fits in the Swift Institute five-layer architecture" belongs in Institute-level documentation, not in the package's own README.

**Where ecosystem-hierarchy content belongs**:

| Content | Correct location |
|---------|------------------|
| Five-layer architecture diagram | `swift-institute.org` DocC catalog (`Layers.md`), or linked from CLAUDE.md |
| "This org sits at Layer N" framing | Org profile README per [README-020] |
| Cross-layer dependency rules | `swift-institute` skill [ARCH-LAYER-*]; `swift-institute.org` |
| Organization-to-ecosystem navigation | `.github/profile/README.md` per [README-020] |
| Package inventory across an org | Org profile README per [README-020] |

**What IS permitted in sub-package READMEs** (peer/parent/competitor references that serve the evaluator's lens):

| Reference | Example |
|-----------|---------|
| Sibling packages (peer references) | swift-nio's "Repository organization" table; TCA's "Companion libraries" |
| Parent relationships with load-bearing comparison | swift-crypto's Evolution section documenting its relationship to Apple CryptoKit |
| Competitor libraries | swift-dependencies' "Alternatives" section |
| Intra-package target graph | The package's own variant decomposition, umbrella/variant structure, target boundaries — per [README-010] |

**Incorrect** (ecosystem-hierarchy positioning serves the author, not the evaluator):

```markdown
## Architecture

Five-layer Swift Institute ecosystem position:

Layer 5: Applications
Layer 4: Components
Layer 3: Foundations
Layer 2: Standards
Layer 1: Primitives      ← swift-property-primitives
```

**Decision test**: Does this sentence (or diagram) answer "*where this package fits in the architecture*" or "*what this package does / enables / is used for*"? The former belongs at swift-institute.org, the org profile README, or the org-of-orgs profile README — and MUST be removed from a sub-package README. The latter stays.

**Rationale**: None of the 15 surveyed top-tier Swift OSS READMEs include parent-ecosystem hierarchical positioning; the evaluator's adoption decision doesn't depend on which layer the package occupies (full text + correct example variant: rationale archive §[README-025]).

**Cross-references**: [README-010], [README-016], [README-020], [README-023]

---

### [README-027] Stability Section Operational Form

**Statement**: Stability sections in pre-1.0 package READMEs MUST be operational — answering "what source surfaces may the reader rely on in the current release line?" They MUST NOT carry internal workaround rationale, speculative Swift Evolution alignment, or deprecation choreography. Recommended form is a compact table identifying stable public type names, documented initializers/accessors, and non-committed implementation strategy.

Pre-1.0 infrastructure packages SHOULD include this section when omission would leave source-compatibility expectations unclear; small-surface utility packages MAY omit when the development-status badge is sufficient.

**Recommended form** (3-row operational table):

| Surface | 0.1.x expectation |
|---|---|
| Public type names | Stable within 0.1.x |
| Documented initializers / accessors / conformance set | Stable within 0.1.x |
| Internal storage shapes / implementation strategy | Not part of the source-stability commitment |

**Correct**:

```markdown
## Stability

`swift-foo-primitives` follows SemVer pre-release semantics in 0.x.

| Surface | 0.1.x expectation |
|---|---|
| Public type names | Stable within 0.1.x |
| Documented initializers / accessors | Stable within 0.1.x |
| Internal storage shapes | Not part of the source-stability commitment |

Notes on possible interaction with SE-XYZ are tracked in [`Research/stdlib-interaction-notes.md`](./Research/stdlib-interaction-notes.md).
```

(Incorrect variant — the canonical 50-line Stability/Migration/Constraints instance mixing evaluator SemVer with workaround rationale: rationale archive §[README-027].)

**Decision test**: Does this paragraph or row tell the reader what they may rely on in the current release line, or does it explain *why* the package is shaped a particular way internally? If the latter, relocate to `Research/` or inline `///` doc comments at the call site; the README keeps only the operational consumer-facing surface.

**Rationale**: The pre-1.0 evaluator question ("will my code break in 0.x?") is operational — which surfaces can I rely on — while internal-implementation rationale and in-flight-proposal deprecation plans answer the contributor's question and belong in `Research/` or DocC (full text + provenance: rationale archive §[README-027]).

**Cross-references**: [README-016], [README-023]

---

## Structure

### [README-001] Required Inventory and Recommended Sequence

**Statement**: README.md files MUST include title + badges, a one-liner, and a `## License` section, in order; the remaining sections SHOULD follow the recommended sequence, with Quick Start MAY preceding Installation.

**Correct (discovery-oriented package — Quick Start precedes Installation)**:

```markdown
# swift-property-primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Fluent accessor property primitives — one `Property<Tag, Base>` family replaces bespoke proxy structs across containers.

## Quick Start
...motivated worked example...

## Installation
...

## License
Apache 2.0. See [LICENSE](LICENSE).
```

**Incorrect**:

```markdown
# swift-io

## Installation  <!-- ❌ Missing one-liner and badges — inventory violation -->
```

**Enforcement**: Mechanical — `validate-readme.py:150` (checks `## License` section presence). Invoked by `validate-readme.yml` on public-repo PR/push. Scope: Family E. Discipline: `Audits/PROMOTE-readme-annotations-2026-07-06.md`. [VERIFICATION: WF validate-readme.py:150]

**Cross-references**: [README-006], [README-008], [README-009], [README-023], [README-024]

---

### [README-002] Maturity Tiers

**Statement**: READMEs MUST meet the minimum tier for their package's maturity. Packages SHOULD progress through tiers as they develop.

| Tier | When | Required Sections |
|------|------|-------------------|
| Minimum | All packages, always | Title, badge, one-liner, Installation, License |
| Standard | Packages with public API documentation | + Key Features, Quick Start, Architecture, Platform Support |
| Complete | Packages at v1.0+ or with external users | + Error Handling, Related Packages, optional sections as applicable |

**Minimum-tier example**:

```markdown
# swift-pool-primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Pool allocation primitives for Swift.

## Installation

` ` `swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-pool-primitives.git", from: "0.1.0")
]
` ` `

## License

Apache 2.0. See [LICENSE](LICENSE).
```

**Rationale**: The ecosystem has many packages; tiers provide a clear upgrade path while ensuring every package has at minimum identity, purpose, usability, and legal clarity.

---

### [README-015] Optional Sections

**Statement**: Optional sections MAY be inserted at logically appropriate positions. Recognized optional sections:

- **Table of Contents** — READMEs > ~200 lines
- **Motivation** — Why this package exists (the problem it solves). Include when the package's existence is not self-evident from its name — e.g., `swift-dependencies` (DI has 20+ years of context), `swift-parsing` (parsing spans many approaches). Omit when the package name already states the mandate — e.g., `swift-deque-primitives`. The baseline-contrast technique per [README-022] is a recommended form.
- **Design Philosophy** — How the package thinks: goals and explicit non-goals. Distinct from Motivation: Motivation answers *why does this exist?*, Design Philosophy answers *how does this package reason?* (e.g., swift-system's "No Cross-platform Abstractions" section).
- **Alternatives** — Named comparison with competing libraries. Include when the package occupies a crowded problem space with plausible competing choices (DI, parsing, snapshot testing). Omit when no credible alternative exists (atomics, numerics, primitives). List competitors by name without disparaging them. Point-Free's `## Alternatives` section in `swift-dependencies` is the canonical example.
- **Performance** — Benchmarks with methodology per [README-012]
- **Usage Examples** — Beyond Quick Start
- **Error Handling** — Typed error hierarchy (MUST for non-trivial error shapes per [README-013])
- **Configuration** — Configurable parameters
- **Monitoring** — Observability hooks
- **Testing** — Test patterns specific to the package
- **Test Support** — Test utilities exported for consumers
- **Related Packages** — Dependencies, dependents, third-party per [README-014]
- **Contributing** — Or link to CONTRIBUTING.md
- **Acknowledgments** — Credits

**Decision test (Motivation vs Design Philosophy vs Alternatives)**:

- Do readers need convincing the problem exists? → **Motivation**
- Does the package take a specific design stance readers should know? → **Design Philosophy**
- Are there obvious competing packages? → **Alternatives**

An individual package MAY include zero, one, two, or all three — these sections are complementary, not alternatives.

**Rationale**: Top-tier Swift OSS uses Motivation and Alternatives as distinct named sections where the v1.0 catalog merged them under a catch-all label; the rename clarifies author intent and aligns with external practice (full text: rationale archive §[README-015]).

**Cross-references**: [README-022], [README-023], [README-025]

---

### [README-016] Prohibited Content

**Statement**: READMEs MUST NOT include Roadmap/TODO/Changelog sections, failing CI badges, screenshots (unless inherently visual), unsubstantiated marketing language, or author-oriented content (ecosystem-hierarchy framing, implementation autobiography, design reflections, pre-tag process notes, unverified compatibility claims).

**Enforcement**: Mechanical — `validate-readme.py:180` (flags literal `## Roadmap`, `## TODO`, `## Changelog` section headers; the remaining prohibited-content rows are not yet mechanically checked). Invoked by `validate-readme.yml` on public-repo PR/push. Scope: Family E. Discipline: `Audits/PROMOTE-readme-annotations-2026-07-06.md`. [VERIFICATION: WF validate-readme.py:180]

**Cross-references**: [README-010], [README-020], [README-023], [README-025], [DOC-010] (inline-comment counterpart of this exclusion rule), [RELEASE-001b] (Phase 0 baseline that GENERATES the evidence this rule requires).

---

## Badges

### [README-003] Development Status Badge

**Statement**: Every README MUST include a development status badge, using a value from the allowed status vocabulary, as the first badge immediately after the H1 title.

**Correct**:

```markdown
![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)
```

**Incorrect**:

```markdown
![Status](https://img.shields.io/badge/status-beta-yellow.svg)  <!-- ❌ Non-standard status -->
```

**Enforcement**: Mechanical — `validate-readme.py:144` (first badge line MUST match the Development Status shield pattern). Invoked by `validate-readme.yml` on public-repo PR/push. Scope: Family E. Discipline: `Audits/PROMOTE-readme-annotations-2026-07-06.md`. [VERIFICATION: WF validate-readme.py:144]

---

### [README-004] CI Badge

**Statement**: CI badges MAY be included only when CI is configured and passing.

**Composite:** badge-URL regex (mechanical) + CI-status liveness check via `gh api` (mechanical, External: GitHub Actions API).

```markdown
[![CI](https://github.com/{ORG}/{REPO}/workflows/CI/badge.svg)](https://github.com/{ORG}/{REPO}/actions/workflows/ci.yml)
```

A failing CI badge MUST be removed until CI passes. An absent CI should not display as present.

**Rationale**: Failing CI badges signal unacknowledged technical debt.

---

### [README-005] Swift Package Index Badges

**Statement**: When a package is published to Swift Package Index, SPI endpoint badges SHOULD be included after the development status badge. SPI badges are preferred over static version/platform badges because they auto-update from build results.

```markdown
[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F{owner}%2F{repo}%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/{owner}/{repo})
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2F{owner}%2F{repo}%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/{owner}/{repo})
```

**Badge ordering**:

1. Development status (required — [README-003])
2. SPI Swift versions (recommended)
3. SPI platforms (recommended)
4. CI status (optional — [README-004])

**Rationale**: SPI badges reflect actual build results, not manually maintained claims. They auto-update when SPI rebuilds the package, eliminating badge maintenance.

---

## One-Liner

### [README-006] One-Liner and Opening Contract

**Statement**: The one-liner MUST:

- Be a single sentence
- Describe **what** the package does, not how
- End with a period
- Include quantified claims where appropriate

The one-liner MUST NOT:

- Start with "A Swift package for ..."
- Use marketing language without technical substance
- Include implementation details

**Opening contract**: The first screen of the README — H1 + one-liner + (first badge block OR first code example) — MUST be sufficient for the reader to decide to keep reading. The opening contract is falsified when:

- No one-liner is present;
- The first code example is unmotivated per [README-024];
- The first prose paragraph describes author-oriented content (package history, internal organization, ecosystem-hierarchy positioning) rather than what-this-package-does;
- The first paragraph describes something other than the package (e.g., framing about the broader ecosystem or about another package that uses this one).

**Correct**:

```
A high-performance async I/O executor for Swift. Isolates blocking syscalls from Swift's cooperative thread pool.
```

**Incorrect**:

```
A Swift package for doing I/O operations.  <!-- ❌ Starts with "A Swift package for" -->
```

**Decision test (opening contract)**: If you hide everything below the first code example or the first paragraph, can an evaluator still answer "what is this, and would I keep reading?" If no, the opening contract is not met.

**Composition-claim completeness**: When the one-liner (or any opening-contract paragraph) names dependencies the package "composes" or "builds on" — `composes A, B, C` / `builds on X, Y` / `combines D and E` — the listed names MUST equal the full dep set in `Package.swift` for that target, or the prose MUST explicitly mark the list as a subset (`composes A, B, C, among others` / `notably depends on X, Y`). A composition-claim that names 4 of 7 actual deps without marking subset is a false-completeness signal: the evaluator infers "these are all the deps" and may make incorrect compatibility judgments downstream.

**Rationale**: Technical precision enables accurate package selection; the opening contract addresses first-paragraph ecosystem-positioning defects, and the composition-claim sub-rule extends the precision discipline to dep lists (full text, extra example variants, and the 2026-05-01 swift-geometry-primitives origin incident: rationale archive §[README-006]).

**Cross-references**: [README-023], [README-024], [README-025], [README-162] (count-claim consistency lint)

---

## Key Features

### [README-007] Key Features Format

**Statement**: Key Features sections are RECOMMENDED for Standard-tier+ packages [README-002]. When included, they SHOULD use the bold-keyword bullet form. Two alternative forms are permitted: feature-as-subsection-with-example (H3 per feature, immediately followed by a short code example), and prose (for packages with fewer than 3 distinctive features).

**Bold-keyword bullets** (default form; 4–8 bullets, bold keyword + em-dash):

```markdown
## Key Features

- **Typed throws end-to-end** — No `any Error` escapes the API surface
- **Swift 6 strict concurrency** — Full `Sendable` compliance
- **Zero-copy where possible** — Minimizes allocation overhead
- **Cross-platform** — macOS, Linux, and Windows support
```

(Feature-as-subsection-with-example and prose alternative-form examples: rationale archive §[README-007].)

**Incorrect**:

```markdown
- This library uses typed throws throughout the entire codebase to ensure
  that errors are always handled properly.  <!-- ❌ Multi-line in bullet form, no bold keyword -->
- Fast  <!-- ❌ No explanation -->
- ✅ Supports typed throws  <!-- ❌ Emoji checkbox instead of bold keyword -->
```

**Decision test**: If the package has 4+ genuinely distinct features worth scanning, use bold-keyword bullets. If fewer than 3, use prose. If each feature needs a small code example to be meaningful, use feature-as-subsection.

**Rationale**: The bold-keyword bullet pattern enables quick scanning across many packages but was over-prescriptive for small primitives and for packages whose features are best shown inline with code (full text: rationale archive §[README-007]).

**Cross-references**: [README-023], [README-024]

---

## Installation

### [README-008] Installation Format

**Statement**: The `## Installation` section MUST include both a Package.swift dependency block and a target configuration block, with the pin form (`from:` vs `branch:`) matching the package's actual published-tag state (branch pin pre-tag, tag pin only once that tag exists).

**Correct**:

```swift
dependencies: [
    .package(url: "https://github.com/{ORG}/{REPO}.git", from: "X.Y.Z")
]
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "ProductName", package: "package-name")
    ]
)
```

**Incorrect** (pre-tag README that pins to a tag that doesn't exist):

```swift
// In a README for a package with no published tags:
.package(url: "...", from: "0.1.0")  // ❌ Resolution fails — 0.1.0 doesn't exist
```

**Enforcement**: Mechanical — `validate-readme.py:154` (checks `## Installation` presence, `.package(` dependency block, and `.target(` configuration block within the section). Invoked by `validate-readme.yml` on public-repo PR/push. Scope: Family E. Discipline: `Audits/PROMOTE-readme-annotations-2026-07-06.md`. [VERIFICATION: WF validate-readme.py:154]

---

## Quick Start

### [README-009] Quick Start Requirements

**Statement**: Quick Start examples MUST:

- Be copy-paste runnable
- Show the primary use case
- Include all required imports
- Be 10–20 lines

If the package has multiple entry points, show up to three distinct quick starts.

**Correct**:

```swift
import IO

let executor = try IO.Executor()
let result = try await executor.read(from: path)
print(result)
```

**Incorrect**:

```swift
// Assume you have an executor configured...
let result = try await executor.read(from: path)  // ❌ Missing import, setup
```

**Rationale**: Runnable examples enable immediate verification. A Quick Start that requires context from other sections defeats its purpose.

---

## Architecture

### [README-010] Architecture Section

**Statement**: Multi-target packages SHOULD include either an ASCII target-graph diagram or a key-types table. Single-target packages MAY omit the Architecture section. The diagram, when present, documents the **intra-package** target graph — not the package's position in the Institute five-layer architecture (that is [README-025]-forbidden in sub-package READMEs).

**Intra-package ASCII target graph** (example from a multi-target L1 primitives package):

```
┌───────────────────────────────────────────────────────────┐
│              Property Primitives (umbrella)               │
├────────────────┬──────────────┬──────────────┬────────────┤
│ View Read      │ View         │ Consuming    │            │
│ ~Copyable RO   │ ~Copyable RW │ Copyable     │            │
│ pointer        │ pointer      │ state-tracked│            │
├────────────────┴──────────────┴──────────────┴────────────┤
│ Property Primitives Core (internal target, no product)    │
└───────────────────────────────────────────────────────────┘
```

**Key types table** (single-module):

| Type | Purpose |
|------|---------|
| `Buffer.Ring.Inline<E, N>` | Fixed-capacity FIFO ring buffer |
| `Buffer.Ring.Inline.Iterator` | Consuming iteration |

**Incorrect** (ecosystem-layer framing — [README-025] violation): the five-layer "Layer 1: Primitives ← this package" diagram; it belongs at swift-institute.org or in the org profile README [README-020], NOT in a sub-package README.

**Decision test**: Does the diagram show the structure of targets **inside this package**? If yes, it belongs here. Does it show the **position of the package within the Institute's layering**? If yes, remove it — it belongs in Institute-level docs.

**Earning sub-rule** (added v2.1.0): Architecture content earns its place only if each row, box, or diagram element answers a consumer dependency / import / capability / adoption question. Product/target tables SHOULD include a "When to import" or equivalent consumer-choice column. Rows without a consumer implication relocate to contributor docs or `Research/`.

**Correct** (every row answers a consumer choice):

| Product | When to import |
|---|---|
| `Foo Primitives` (umbrella) | Prototyping; tests; small consumers willing to pay the umbrella surface cost |
| `Foo Read Primitives` | Production code that only reads; minimizes surface |
| `Foo Mutate Primitives` | Production code that mutates; depends transitively on Read |

**Incorrect** (mixes consumer-relevant rows with internal-target rows that have no consumer choice implication):

| Target | Contents | Public product |
|---|---|---|
| `Foo Primitives Core` | Core protocol declarations | internal |  <!-- ❌ No consumer can import this; the row is contributor info -->
| `Foo Read Primitives` | Read variant | yes |
| `Foo Mutate Primitives` | Mutate variant | yes |

**Rationale**: ASCII layer diagrams were absent in surveyed first-class Swift OSS (0 of 15); the diagram is useful only when it documents this package's own target graph, and even intra-package rows are contributor content if they don't map to consumer choices (full text + provenance: rationale archive §[README-010]).

**Cross-references**: [README-020], [README-025]

---

## Platform Support

### [README-011] Platform Support Table

**Statement**: Platform support SHOULD be expressed as a table with Platform, CI, and Status columns. The table MAY be omitted when a functional SPI platforms badge [README-005] is published, because the badge is authoritative and auto-updates from actual build results. The table SHOULD be included when the package is pre-SPI-publication or when platform subtleties exist that the badge cannot convey (e.g., "Supported on iOS with caveats on watchOS").

| Platform | CI | Status |
|----------|-----|--------|
| macOS | Yes | Full support |
| Linux | Yes | Full support |
| Windows | Yes | Full support |
| iOS/tvOS/watchOS | — | Supported |
| Swift Embedded | — | Supported |

**Allowed status values**:

| Status | Meaning |
|--------|---------|
| `Full support` | CI-tested, production-ready |
| `Supported` | Works, not CI-tested |
| `Planned` | Architecture ready, implementation pending |
| `Possible` | Could be supported with work |
| `Not supported` | Fundamental limitation |

**Decision test**: Does this package have a functional SPI platforms badge? If yes, the table is optional — it duplicates what the badge already asserts, and it can drift when CI changes. If no, or if the badge cannot express a subtlety, include the table.

**Rationale**: A manually-maintained platform table drifts when CI configuration changes, creating a false-confidence trap; the relaxation preserves the useful content for pre-SPI packages while removing duplicative maintenance (full text: rationale archive §[README-011]).

**Cross-references**: [README-005], [README-021]

---

## Performance

### [README-012] Performance Documentation

**Statement**: When performance data is included, hardware, OS, Swift version, and what is actually being measured MUST be stated. Performance comparisons MUST be tabular.

**Correct**:

```markdown
## Performance

Benchmarked on M1 Mac Mini, macOS 14.0, Swift 5.10.

| Operation | Throughput | p99 Latency | Memory |
|-----------|------------|-------------|--------|
| Read      | 150K ops/s | 2.3ms       | 12 MB  |
| Write     | 120K ops/s | 3.1ms       | 15 MB  |
```

**Incorrect**:

```markdown
## Performance

This library is very fast.  <!-- ❌ No methodology, no data -->
```

Include only meaningful metrics: throughput, latency (p50, p95, p99), memory (steady-state and peak).

**Rationale**: Reproducible benchmarks enable accurate performance comparisons and prevent misleading claims.

---

## Error Handling

### [README-013] Error Handling Section

**Statement**: Packages with a non-trivial error shape (≥ 3 catch arms, a nested generic error envelope, or multiple throwing surfaces) MUST include a `## Error Handling` section with an ASCII error tree and an exhaustive pattern-matching example.

**Correct** (error hierarchy + exhaustive matching):

```
IO.Lifecycle.Error<E>
├── .shutdownInProgress    // Lifecycle: pool shutting down
├── .cancelled             // Lifecycle: task cancelled
└── .failure(E)            // Wraps operational errors
    └── IO.Error<Leaf>
        ├── .leaf(Leaf)    // Your operation's error type
        ├── .handle(...)   // Handle errors
        ├── .executor(...) // Executor errors
        └── .lane(...)     // Lane errors
```

**Exhaustive matching**:

```swift
do {
    try await executor.submit(work)
} catch .shutdownInProgress {
    // Handle shutdown
} catch .cancelled {
    // Handle cancellation
} catch .failure(let ioError) {
    switch ioError {
    case .leaf(let leaf): // Handle leaf
    case .handle(let h): // Handle handle error
    // ... exhaustive
    }
}
```

**Enforcement**: Mechanical — `validate-readme.py:173` (any public `throws(NonNever)` signature in `Sources/` requires a `## Error Handling` section). Invoked by `validate-readme.yml` on public-repo PR/push. Scope: Family E. Discipline: `Audits/PROMOTE-readme-annotations-2026-07-06.md`. [VERIFICATION: WF validate-readme.py:173]

**Cross-references**: [API-ERR-001], [README-001]

---

## Related Packages

### [README-014] Related Packages Organization

**Statement**: When included, Related Packages MUST be organized into subsections (omit empty subsections). All linked repositories MUST be public AND have at least one shipped tag; unreleased siblings MUST be marked explicitly rather than presented as live links. Prose rationale about cross-package relationships belongs in `Research/`, not in this section.

**Dependencies**: Packages this package depends on.

```markdown
- [swift-kernel](url) — Typed kernel syscall wrappers.
```

**Used By**: Packages that depend on this package.

```markdown
- [swift-io](url) — High-performance async I/O executor.
```

**Third-Party Dependencies**: External dependencies not maintained by this organization.

```markdown
- [swift-argument-parser](url) — Command-line argument parsing.
```

**Public + tagged constraint**:

```markdown
- [swift-kernel](url) — Typed kernel syscall wrappers.        <!-- ✓ Public, tagged -->
- swift-future-primitives (private, unreleased) — Forthcoming.            <!-- ✓ Marked, not a live link -->
- [swift-future-primitives](url) — Forthcoming.                            <!-- ❌ Live link to private/unreleased — 404s for external readers -->
```

**Prose rationale exclusion**: A sentence like "conformances of a foreign protocol live in the conformer's home package" is contributor-shaped, not consumer-shaped. The Related Packages section names the package and describes its role; the *why* of the cross-package relationship belongs in `Research/`.

**Rationale**: Structured dependency documentation enables package graph traversal, and the public + tagged constraint prevents advertising URLs that 404 or packages that don't ship yet (full text + the 2026-04-29 carrier provenance: rationale archive §[README-014]).

---

## Formatting

### [README-017] Formatting Rules

**Statement**: READMEs MUST use exactly one H1 (package name, as the first non-empty line), `---` separators between major sections, H2/H3-only heading depth, language-tagged code blocks, and column-aligned tables.

**Enforcement**: Mechanical — `validate-readme.py:119` (H1 count == 1 and the first non-empty line is the H1; the remaining sub-rules — separators, heading depth, code-block language tags, table alignment — are not yet mechanically checked). Invoked by `validate-readme.yml` on public-repo PR/push. Scope: Universal. Discipline: `Audits/PROMOTE-readme-annotations-2026-07-06.md`. [VERIFICATION: WF validate-readme.py:119]

---

## Code Examples

### [README-022] Code Examples in README

**Statement**: All code examples in a README MUST:

1. Include all required `import` statements
2. Use domain-meaningful identifiers (NOT `Foo`, `Bar`, `x`, `y`)
3. Be copy-paste runnable where possible
4. Satisfy [README-024] Motivated Examples — demonstrate something that is impossible, awkward, or subtly wrong to express without the package

Non-trivial examples SHOULD demonstrate error handling explicitly.

**Baseline-contrast technique** (RECOMMENDED for packages whose value is not self-evident): show the naive or painful solution first, then the library's version. This pattern is used to strong effect in `swift-parsing`'s opening, which demonstrates a nested `.split(separator:)` + `compactMap` + `guard let` solution before introducing the library's composable parsers.

```swift
// Baseline (without the library):
let users = input
  .split(separator: "\n")
  .compactMap { row -> User? in
    let fields = row.split(separator: ",")
    guard fields.count == 3,
          let id = Int(fields[0]),
          let isAdmin = Bool(String(fields[2]))
    else { return nil }
    return User(id: id, name: String(fields[1]), isAdmin: isAdmin)
  }

// With the library:
let userParser = Parse {
  Int.parser()
  ","
  Prefix { $0 != "," }
  ","
  Bool.parser()
}
```

The contrast makes the library's value visible without narration.

**Incorrect**:

```swift
let foo = try Bar(x: "...", y: 123)  // ❌ Meaningless identifiers, missing import
```

**Rationale**: Complete, realistic examples demonstrate actual usage and enable immediate verification; the baseline-contrast technique is the single sharpest teaching pattern observed in the surveyed corpus (full text + extra example variants: rationale archive §[README-022]).

**Cross-references**: [DOC-050], [README-024]

---

## Sub-Package Within an Org

### [README-019] Sub-Package README is Self-Contained

**Statement**: Sub-package READMEs MUST be self-contained — they MUST NOT assume the reader has seen the org profile README, the local-disk grouping README, or any sibling package's README.

Self-contained means: the sub-package README includes its own title, badge, one-liner, installation (with the per-package GH repo URL), and any other applicable sections per [README-002] maturity tiers.

**Installation in sub-package README** (URL is the per-package repo, not a parent — every Swift package is a single GitHub repo):

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-buffer-primitives.git", from: "0.1.0")
]
.target(
    name: "App",
    dependencies: [
        .product(name: "Buffer Ring Inline Primitives", package: "swift-buffer-primitives")
    ]
)
```

**Rationale**: Developers often land on a sub-package README via search or link; a self-contained README serves them without navigation to the org profile or a sibling repo, and the installation URL points directly to the package (v3.0.0 update history: rationale archive §[README-019]).

---

## Maintenance

### [README-021] Maintenance Obligations

**Statement**: README maintenance obligations:

**Composite:** number/version extraction (mechanical) + link validity lint (mechanical, External) + badge-status currency (mechanical, External) + currency-discipline judgment (semantic).

| Obligation | Requirement |
|-----------|-------------|
| Performance numbers | MUST be kept current with each major release |
| Installation snippets | MUST match latest release version |
| Links | MUST all be valid; prefer relative links |
| Badge status | MUST reflect actual package state |
| Platform Support | MUST reflect actual CI and testing state |

**Rationale**: Stale READMEs generate incorrect usage patterns and erode user trust.

---

## Community

### [README-040] Community Section (public Family E packages)

**Statement**: Every PUBLIC Family E package's README MUST include a
`## Community` section between the Maintenance and License sections. The
section contains a single auto-generation marker block:

````markdown
## Community

<!-- BEGIN: discussion -->
Discuss this package: [swift-institute/discussions/{N}]({URL})
<!-- END: discussion -->
````

The marker block contents are auto-generated by `sync-discussion-threads.yml`
per **github-repository** [GH-REPO-092] and `ci-automation.md` [README-168].
Authors leave the markers in place but do NOT edit the contents directly —
edits are reverted on the next sync run.

**Pre-flip state** (private repo, before [RELEASE-004a] Stage 2): the marker
block contains the placeholder

````markdown
<!-- BEGIN: discussion -->
*Discussion thread will be created at first public flip.*
<!-- END: discussion -->
````

The placeholder is replaced with the live URL when the workflow opens its
PR after thread creation.

**Scope**: public Family E packages. Private Family E (pre-flip), Family
C/F/G repos: section is omitted. The section becomes required at flip-time
alongside [GH-REPO-091]'s `discussion:` field becoming required.

**Cross-references**: [README-001] (required inventory — Community sits
between Maintenance and License), [README-021] (Maintenance, the section
that precedes), [README-026] (no rule-ID citations — section content is
consumer-language only), **github-repository** `[GH-REPO-090..093]`,
`ci-automation.md` [README-168]. (Provenance: rationale archive §[README-040].)

---

## Deprecated

### [README-018] (DEPRECATED in v3.0.0)

**Status**: DEPRECATED. The original v2.1.0 rule specified the structure of monorepo root READMEs. The workspace has no monorepos and no superrepos — every Swift package is a single GitHub repo, and the local-disk directory at `~/Developer/<org>/` is a clone-mirror, not a "repo" in any GitHub sense.

**Content roles redistributed**:

| Original [README-018] content | New home |
|---|---|
| Title and badges for the collection | [README-110] / [README-111] in `org-profile.md` (leaf-org tier) |
| One-liner describing the collection's scope | [README-110] in `org-profile.md` |
| Package inventory table | [README-111] in `org-profile.md` (leaf tier) |
| Architecture overview / layer diagram | [README-113] in `org-profile.md` (leaf tier) |
| Installation (how to depend on a single package) | [README-008] in this file (per-package, since each package = one repo) |

The ID is preserved for stability of the changelog audit trail. Authors writing a new README should not consult [README-018]; route to the family-appropriate rule above.

---

## Cross-References

- **readme** skill hub (`SKILL.md`) — Family routing matrix, universal meta-rules ([README-023], [README-026]).
- **readme/org-profile** sibling — Org profile READMEs ([README-020], [README-100..119]); destination for content removed from [README-018].
- **documentation** skill — Inline DocC and `.docc` catalogue conventions.
- **swift-institute** skill — Five-layer architecture (referenced by [README-025] as the content that does NOT belong in sub-package READMEs).
- **code-surface** skill [API-NAME-001a] — Precedent for the Decision test pattern.
- **code-surface** skill [API-ERR-001] — Typed throws requirement that grounds [README-013].
- Research: `swift-institute/Research/package-readme-standard.md` (Tier 2, 2026-04-21) — ecosystem audit of 15 first-class Swift OSS READMEs.
- Research: `swift-institute/Research/cohort-readme-evaluator-pass.md` (2026-05-01) — audience-inversion convergence; provenance for [README-024], [README-025], [README-027].

---

### [README-029] Six Audience-Inversion Patterns and Their Canonical Rewrites

**Statement**: The audience-inversion failure mode that `[README-023]` describes manifests through SIX surface patterns. Sub-package README audits MUST audit for each pattern explicitly; each pattern has a canonical rewrite. Verdict taxonomy for audit passes per paragraph: KEEP / COMPRESS / RELOCATE / DELETE.

**The six patterns**:

| # | Pattern | Canonical rewrite |
|---|---------|-------------------|
| 1 | Pre-tag interim / release-process notes (author-process state, stale after release) | DELETE |
| 2 | Sibling-package taxonomy paragraphs (rationale-shaped instead of decision-aid-shaped) | Peer comparison → 1-sentence decision aid ("Use X for verb-namespace, use Y for domain-identity"), not "two-class taxonomy" |
| 3 | Stability sections mixing evaluator SemVer with internal workaround rationale (heap-alloc costs, non-`@inlinable` for ABI, deprecation choreography) | Stability → 3-row operational table (Public type names / Documented initializers / Internal strategy not-committed) when present; conditional, not mandatory |
| 4 | Exhaustive negative documentation (200-word enumeration of N absences with research citations) | 1 sentence + link to a single catalogue document (e.g., `Research/sli-deliberate-absences.md`); not a prose enumeration |
| 5 | Ecosystem-convention framing in feature bullets ("matching the convention where conformances live with the protocol's home package…") | State the capability directly; relocate convention to contributor docs |
| 6 | Quick Start examples using unreleased downstream packages (the import doesn't compile) | Quick Start MUST compile against published packages; "lifted from a downstream consumer" is a contributor signal |

**Function-based destination**:
- Adoption examples → DocC.
- Design / historical / principled-absence rationale → Research.
- Capability statements → README directly.
- Sibling-positioning as a decision aid → README at one sentence max.

**Architecture rows** (if the README has an Architecture table): every row, box, or diagram element MUST answer a consumer dependency / import / capability / adoption question; "When to import" column for product tables.

**Carrier post-cleanup is the discipline reference for the cohort**, NOT a universal section template — match its discipline (no Stability, no Migration, no exhaustive absences, no design-rationale paragraphs), not necessarily its section set.


**Cross-references**: [README-023], [README-016], [README-010], [README-027]
