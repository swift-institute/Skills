---
name: swift-institute-core
description: Swift Institute skill index and context router. Apply first in Institute repositories, then load only the task-relevant architecture, implementation, or process skills.
---

# Swift Institute Core

This is the root meta-skill for the Swift Institute ecosystem.

---

## Skill Index

### Meta Layer
- **swift-institute-core** (this skill) - [BET-*] System manifest, harness architecture bets

### Architecture Layer
- **swift-institute** - [ARCH-LAYER-*] Three realized layers, Institute-first composition, semantic dependencies
- **swift-institute-ecosystem** - [ECO-*] Ecosystem tour: rationale (cross-platform + Embedded + typed correctness + fine-grained); three active layers; per-authority Standards sub-orgs (IETF, ISO, W3C, WHATWG, IEEE, IEC, Ecma, INCITS + vendor orgs); `-standard` convergence pattern; layer-placement decision model; five cross-cutting disciplines; deeper-reading routes; essential glossary. Carries no enforcement rules — points to canonical sources
- **primitives** - Primitives-specific conventions (in swift-primitives repo)
- **swift-package** - [PKG-NAME-*], [PKG-DEP-*] Package and namespace naming: noun form for packages/namespaces; gerund reserved as top-level typealias onto `Namespace.\`Protocol\``; external-compat exception; foundations cascade; hoisted protocol for generic namespaces. Cross-repo dep declaration: path-form-as-safe-default during pre-publishable work
- **swift-package-heritage** - [HERITAGE-*] Git-level heritage for packages derived from external upstream Swift packages: fork vs re-implement decision, lineage formalization at the git/GitHub level

### Implementation Layer
- **code-surface** - [API-NAME-*], [API-ERR-*], [API-IMPL-*], [API-BRAND-*] Naming, error handling, file structure (absorbs naming, errors, code-organization)
- **byte-discipline** - [API-BYTE-*] UInt8/Byte discrimination at the byte/arithmetic-domain boundary: sibling types, no Byte arithmetic, Binary.Serializable witnesses, rawValue:UInt8 disposition
- **implementation** - [IMPL-*], [IMPL-EXPR-*], [COPY-FIX-*], [COPY-REM-*], [PATTERN-012–062] (sparse), [API-LAYER-*], [SEM-DEP-*] Call-site-first patterns, typed arithmetic, boundary overloads, dependency strategy, ~Copyable remediation (absorbs anti-patterns, design)
- **conversions** - [IDX-*], [CONV-*] Index<T> patterns, conversion APIs, rawValue access rules (absorbs primitives-conversions)
- **platform** - [PLAT-ARCH-*], [PATTERN-001–009] Platform code layering (L1–L3), compilation mechanics, Swift 6, C shims
- **modularization** - [MOD-*] Independent package, product, target, file, ownership, integration, and dependency decisions
- **memory-safety** - [MEM-COPY-*], [MEM-OWN-*], [MEM-LINEAR-*], [MEM-SAFE-*], [MEM-SEND-*], [MEM-REF-*], [MEM-LIFE-*], [MEM-SPAN-*], [MEM-UNSAFE-*] Ownership, copyability, strict safety, reference primitives, span access, unsafe operation tracking (absorbs advanced-patterns)
- **reuse-first** - [REUSE-*] Capability discovery, semantic-owner selection, owner completion, and composition before implementation
- **ecosystem-data-structures** - [DS-*] Complete catalog of data structures (Memory, Storage, Buffer, Collections) with selection guidance
- **testing** - [TEST-*] Umbrella: routing, test support infrastructure, file naming, suite categories
- **testing-swiftlang** - [SWIFT-TEST-*] Swift Testing framework: suites, naming, ~Copyable, async, model testing
- **testing-institute** - [INST-TEST-*] Nested package pattern for snapshot testing and swift-testing isolation
- **benchmark** - [BENCH-*] Performance testing: .timed(), .build cleanup, comparison benchmarks
- **documentation** - [DOC-*] Inline DocC comments, .docc catalogue conventions, code comment quality
- **readme** - [README-*] README structure, badges, maturity tiers, org-tier patterns
- **github-repository** - [GH-REPO-*] GitHub repository judgment, repository-policy routing, bot-first convergence, metadata/settings ownership, and deny-by-default Actions
- **social-preview** - [SOC-*] GitHub social preview cards: parametric chassis, organization brand in metadata.yaml, and the skill-owned rendering workflow
- **document-markup** - [DOC-MARKUP-*] Document creation using HTML, PDF, and Markdown rendering packages
- **swift-linter** - [LINT-*] Mechanical-rule ownership, predicate design, fixtures, exemptions, severity graduation, bundles, consumer setup, and centralized enforcement

### Process Layer
- **audit** - Systematic compliance audit of code against skill requirement IDs
- **research-process** - [RES-*] Research workflows
- **experiment-process** - [EXP-*] Experiment workflows
- **blog-process** - [BLOG-*] Blog post workflows
- **skill-lifecycle** - Skill creation, update, review, and deprecation
- **package-export** - [PKG-EXPORT-*] Export packages for LLM consumption
- **swift-package-build** - [PKG-BUILD-*] Workspace-owned Swift build boundary, isolated fresh evidence, generated-state discipline, and CI parity
- **collaborative-discussion** - [COLLAB-*] Multi-agent collaborative discussions
- **reflect-session** - Structured post-session reflection capture
- **issue-investigation** - [ISSUE-*] Systematic compiler/toolchain issue investigation: reproduce, reduce, verify, resolve
- **swift-pull-request** - [SWIFT-PR-*] Submit PRs to swiftlang/swift: fork, branch, commit, test, CI, reviewers
- **swift-evolution** - [PITCH-PROC-*] Pitch phase: triggers, evidence, scope, drafting, submission, iteration, bidirectional evidence
- **swift-forums-review** - [FREVIEW-*] Pressure-test a package pre-launch: simulate a forums.swift.org review thread with statistically-derived reviewer archetypes, predict which critique angles will land hardest, and triage outputs along two orthogonal axes — classification (load-bearing vs archetype-shaped) per [FREVIEW-012] and correctness (verified-true vs false-premise) per [FREVIEW-018]
- **release-readiness** - [RELEASE-*] Multi-phase release-readiness brief and final pre-release scan: 4-phase release-prep brief, 7-phase final scan, skill-incorporation gate for pilot launches in a cohort, per-action authorization gates (tag/visibility/blog/deploy), GO/CONDITIONAL GO/NO-GO recommendation
- **ci-cd-workflows** - [CI-*] Three-tier reusable-workflow chain, typed Actions whitelist, bot-first fleet convergence, universal matrix, secret transport, and generated-state policy
- **rule-exemptions** - [RULE-EXEMPT-*] Eleven recurring exemption shapes for the linter rule corpus: authoring or amending a custom lint rule whose firing intersects a deliberate institute or stdlib pattern
- **swift-package-index** - [SPI-*] SPI onboarding + package collections: listing gates (public + semver tag + valid manifest + URL-form closure), leaf-first tagging cascade, per-org auto vs self-hosted-unified collections, unsigned-v1 signing posture (host-based trust selection), PackageList submission + at-scale etiquette, and the canonical `.spi.yml` policy (docs-hosting only, no CI-matrix mirror)

### Requirement ID convention

Requirement IDs follow `[PREFIX-NNN]` with a zero-padded integer. Foundational decisions may use a stable semantic name (for example `[IMPL-INTENT]`, `[IMPL-COMPILE]`, `[MOD-OWNER]`). Tools that pattern-match IDs accept both forms.

### Absorption History
- **naming**, **errors**, **code-organization** → absorbed into **code-surface**
- **primitives-conversions** → absorbed into **conversions**
- **design** (carried `[API-DESIGN-*]`), **anti-patterns** → absorbed into **implementation**; current rules use `[IMPL-*]` / `[API-LAYER-*]` / `[PATTERN-*]`
- **skill-creation** → absorbed into **skill-lifecycle**

---

## Context routing

Do not load a transitive skill graph. Select context progressively:

1. Load this index and **swift-institute** for ecosystem orientation.
2. Load the one skill whose description directly matches the task.
3. Follow a cross-reference only when the current decision requires it.
4. Load detailed companion references only for the active variant or rule.
5. Prefer Workspace facts, linter diagnostics, compiler output, and CI results
   over prose that duplicates deterministic state.

Common routes:

| Task | Load |
|---|---|
| add or change a capability | **reuse-first**, then the domain owner skill |
| package/product/target/file change | **modularization**, **swift-package** |
| implementation inside a target | **implementation** plus one relevant domain skill |
| tests | **testing**, then **testing-swiftlang** or **testing-institute** as needed |
| build or test | **swift-package-build** |
| mechanical rule or exemption | **swift-linter**, **rule-exemptions** |
| CI architecture | **ci-cd-workflows** |
| GitHub settings or fleet convergence | **github-repository**, **ci-cd-workflows** |

---

## Canonical Sources

| Artifact | Purpose | Authority |
|----------|---------|-----------|
| Skills/ | Rules, requirements, workflows | CANONICAL (WHAT) |
| Research/ | Rationale, trade-offs, history | AUTHORITATIVE (WHY) |
| Documentation.docc/ | Explanation, onboarding | NON-NORMATIVE (HOW) |

---

## Harness Boundary

### [BET-EVAL] Human-reviewed skill evolution

**Statement**: Skills and control artifacts MUST remain human-reviewed sources. The workspace MUST NOT optimize its rules against a self-referential evaluation or auto-mutate skills from quantitative metrics. Decisions remain human.

---

## Package Locations

| Package | Repository |
|---------|-----------|
| swift-primitives | https://github.com/swift-primitives |
| swift-standards | https://github.com/swift-standards |
| swift-foundations | https://github.com/swift-foundations |
| swift-institute | https://github.com/swift-institute |
