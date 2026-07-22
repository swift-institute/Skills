---
name: readme/placeholder
description: |
  Family F rules — placeholder / scaffold README content. Apply when the package's
  repo exists but the package is not fully implemented (namespace reservation,
  pre-implementation scaffold, unnecessary candidate for removal, archived).
  Distinguishes legitimate placeholders from under-documented Family E packages.

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
---

# Placeholder / Scaffold README

Family F rules. Authoring contract for repos whose package is **not in a usable state for evaluators** — namespace reservations, pre-implementation scaffolds, unnecessary candidates for removal, or archived packages. The reader's evaluation question is: "What is this and is it usable yet?"

Loaded on demand from the **readme** skill hub (`SKILL.md`). The two universal meta-rules — [README-023] Evaluator's Lens and [README-026] No Internal Rule-ID Citations — apply to this family and live in the hub.

**Scope**: All `<repo>/README.md` files in repos that exist as namespace reservations or scaffolds. Today this includes a number of `swift-*-primitives` repos in the swift-primitives org; the rules generalize to any leaf-org repo in pre-implementation, archived, or unnecessary state.

Full evicted rationale, provenance, and extra example variants for this family: the rationale archive (`Readme Skill Rationale Archive`), referenced below.

---

## Voice

Placeholder READMEs operate in a third-person, factual register. Every paragraph answers "What is this and is it usable yet?" — see [README-023] Evaluator's Lens in the hub.

| Element | Convention |
|---|---|
| Person | Third-person. "This package is a namespace reservation …", "Implementation is pending …". No first-person, no marketing. |
| Status framing | Required and explicit. The status is the load-bearing signal for an evaluator who landed here from a search result or dependency graph. |
| Hype | Forbidden. No "coming soon!", no "watch this space", no future-promise language. State the current state; let the evaluator decide. |
| Length | 3–10 lines. A placeholder README that grows past 10 lines is either a Family E package that needs graduation (per [README-153]) or contains content that belongs in `Research/` or an issue. |
| Code examples | Forbidden — there is no usable code to demonstrate. |
| Architecture, install, badges | Forbidden — borrowing Family E sections creates the false impression that the package is implemented. |

The voice contrast: a Family F README is a **disclosure**, not a pitch. The evaluator must walk away knowing they cannot use this package today (or, if it is archived, that they should not).

---

## Why This Family Exists

Without explicit Family F rules, two anti-patterns emerge in production: **silent under-documentation** (working code behind a 3-line README with no status — a Family E package below the [README-002] Minimum tier that MUST graduate per [README-153], or, if genuinely a placeholder, adopt the Family F status form per [README-150]) and **scaffold without disclosure** (a namespace reservation whose README does not say so; the [README-150] status block prevents accidental adoption). Family F rules ensure that a placeholder declares itself as such, leaving no ambiguity for the evaluator. (Observed anti-pattern instances: rationale archive §Family-F-context.)

---

## Structure

### [README-150] Minimum Content — Title and Status Declaration

**Statement**: Family F READMEs MUST include exactly an H1 title and a `> **Status: <value>** — explanation` blockquote, and no other sections.

**Correct**:

```markdown
# ABI Primitives

> **Status: Unnecessary** — This package is a namespace reservation with no implementation. It declares dependencies on binary, CPU, and type primitives but contains no source code. No downstream consumers exist. Candidate for removal.
```

**Incorrect** (status without explanation):

```markdown
# ABI Primitives

> **Status: Unnecessary**
```

**Enforcement**: Mechanical — `validate-readme.py:218` (flags any `##` section beyond an allowed `## License` exception). Invoked by `validate-readme.yml` on public-repo PR/push. Scope: Family F. Discipline: `Audits/PROMOTE-readme-annotations-2026-07-06.md`. [VERIFICATION: WF validate-readme.py:218]

---

### [README-151] Status Vocabulary

**Statement**: The status value MUST be one of `Pre-implementation`, `Namespace-reservation`, `Unnecessary`, or `Archived`, title-cased, directly after the colon (e.g. `> **Status: Unnecessary**`).

**Enforcement**: Mechanical — `validate-readme.py:227` (status value MUST be a member of the canonical set). Invoked by `validate-readme.yml` on public-repo PR/push. Scope: Family F. Discipline: `Audits/PROMOTE-readme-annotations-2026-07-06.md`. [VERIFICATION: WF validate-readme.py:227]

**Cross-references**: [README-162] in `ci-automation.md`.

---

### [README-152] Explicit Scaffolding Signal — Blockquote Form

**Statement**: The status MUST appear inside a Markdown blockquote (`>` prefix) on the line immediately following the H1 title. No body text, no preamble, no badge between the H1 and the status block.

**Correct**:

```markdown
# ABI Primitives

> **Status: Unnecessary** — ...
```

**Incorrect** (status as plain paragraph):

```markdown
# ABI Primitives

**Status: Unnecessary** — ...    <!-- ❌ Not visually distinguished from normal README content -->
```

**Decision test**: Does the status block appear within the first 5 visible lines of the rendered README? If no, the placeholder signal is too soft.

**Rationale**: The blockquote `>` rendering pulls the eye and visually labels the entire content as metadata; section headers imply other sections exist, the blockquote form rules them out (full text + extra incorrect variants: rationale archive §[README-152]).

---

### [README-153] Graduation Criteria — When a Placeholder Becomes a Real Package

**Statement**: A Family F README MUST graduate to Family E [README-002] Tier 1 (Minimum) when ANY of the following becomes true:

1. The package gains a public API surface that consumers can depend on.
2. The package's documented Status would change to a non-placeholder state (the package is now usable).
3. The package's `Sources/` directory contains files that produce a public, importable module.

When graduation is triggered, the README MUST be rewritten to satisfy [README-002] Minimum tier rules in `sub-package.md`:

- Title and badges
- Development status badge ([README-003])
- One-liner ([README-006])
- Installation ([README-008])
- License section

The Status blockquote is removed; the package's actual lifecycle is now communicated through the Development status badge ([README-003] values: `active--development`, `stable`, `maintenance`, `experimental`).

**Decision test**: If a developer integrating this package would hit a working `import` statement and a non-empty public API, the package is not a placeholder; it is a Family E package below Tier 1. Graduate the README, do not document the package as a placeholder.

**Graduation skeleton** (the output of a graduation):

```markdown
# Parsing Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

<one-liner per [README-006] describing what Parsing Primitives provides>

## Installation

\```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-parser-primitives.git", from: "0.1.0")
]
\```

## License

Apache 2.0. See [LICENSE](LICENSE).
```

**Rationale**: The graduation rule prevents the workspace from accumulating packages that are simultaneously usable (have code) and undocumented (no Tier 1 README) — either the package is a placeholder (Family F, has Status block) or it is implemented (Family E, at least Tier 1); there is no third state. (Observed anti-pattern instances: rationale archive §[README-153].)

**Cross-references**: [README-002] (Maturity Tiers in `sub-package.md`); [README-150] (when to apply Family F status form instead of graduating).

---

### [README-154] (reserved)

---

### [README-155] (reserved)

---

## Cross-References

- **readme** skill hub (`SKILL.md`) — Family routing matrix, universal meta-rules ([README-023], [README-026]).
- **readme/sub-package** sibling — Family E rules; the destination when a placeholder graduates per [README-153].
- **readme/ci-automation** sibling [README-162] — Structure linter contract that verifies placeholder READMEs use a valid status from [README-151].
- Provenance: `swift-primitives/swift-space-primitives/README.md` is the canonical instance of a correctly-formed Family F README (re-pointed 2026-07-05 — `swift-abi-primitives` does not exist on disk; checked via full-corpus grep for the Status blockquote across every `swift-primitives` README; `swift-transform-primitives/README.md` is an equally valid second instance).
- Anti-pattern provenance: `swift-primitives/swift-{parser,decimal,geometry,algebra-linear}-primitives/README.md` are the observed instances of under-documented Family E packages incorrectly mistaken for placeholders.
