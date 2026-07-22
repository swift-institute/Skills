---
name: swift-institute-core
description: |
  Swift Institute system manifest and skill index.
  This meta-skill declares canonical sources and loading order.
  ALWAYS loaded first when working in Swift Institute repositories.

layer: meta

requires: []

applies_to:
  - swift
  - swift6
  - swift-primitives
  - swift-standards
  - swift-foundations
---

# Swift Institute Core

This is the root meta-skill for the Swift Institute ecosystem.

---

## Skill Index

### Meta Layer
- **swift-institute-core** (this skill) - [BET-*] System manifest, harness architecture bets

### Architecture Layer
- **swift-institute** - [ARCH-LAYER-*] Five-layer architecture, semantic dependencies
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
- **modularization** - [MOD-*], [MOD-EXCEPT-*] Intra-package target decomposition, constraint isolation, layering exceptions
- **memory-safety** - [MEM-COPY-*], [MEM-OWN-*], [MEM-LINEAR-*], [MEM-SAFE-*], [MEM-SEND-*], [MEM-REF-*], [MEM-LIFE-*], [MEM-SPAN-*], [MEM-UNSAFE-*] Ownership, copyability, strict safety, reference primitives, span access, unsafe operation tracking (absorbs advanced-patterns)
- **existing-infrastructure** - [INFRA-*] Catalog of typed boundary overloads, Standard Library Integration modules, Tagged functors, Ratio scaling
- **ecosystem-data-structures** - [DS-*] Complete catalog of data structures (Memory, Storage, Buffer, Collections) with selection guidance
- **testing** - [TEST-*] Umbrella: routing, test support infrastructure, file naming, suite categories
- **testing-swiftlang** - [SWIFT-TEST-*] Swift Testing framework: suites, naming, ~Copyable, async, model testing
- **testing-institute** - [INST-TEST-*] Nested package pattern for snapshot testing and swift-testing isolation
- **benchmark** - [BENCH-*] Performance testing: .timed(), .build cleanup, comparison benchmarks
- **documentation** - [DOC-*] Inline DocC comments, .docc catalogue conventions, code comment quality
- **readme** - [README-*] README structure, badges, maturity tiers, org-tier patterns
- **github-repository** - [GH-REPO-*] GitHub-side repository metadata: description templates, topic taxonomy, homepage URL, license auto-detection, repo settings, .github/metadata.yaml source-of-truth, centralized reusable workflows in swift-institute/.github
- **social-preview** - [SOC-*] GitHub social preview cards: parametric chassis, org brand in metadata.yaml's socialPreview block, local render+upload via Scripts/social-preview.sh
- **document-markup** - [DOC-MARKUP-*] Document creation using HTML, PDF, and Markdown rendering packages
- **swift-linter** - [LINT-SETUP-*], [LINT-BUNDLE-*], [LINT-EXCLUDE-*], [LINT-PARENT-*], [LINT-COHORT-*] Consumer-side swift-linter setup: Lint.swift (default) vs Lint/ nested-package (advanced), Bundle.X activation per consumer layer, excluding(rules:) brand-owner vocabulary (Shape γ), // parent: inheritance chain.

### Process Layer
- **audit** - Systematic compliance audit of code against skill requirement IDs
- **research-process** - [RES-*] Research workflows
- **experiment-process** - [EXP-*] Experiment workflows
- **blog-process** - [BLOG-*] Blog post workflows
- **skill-lifecycle** - Skill creation, update, review, and deprecation
- **package-export** - [PKG-EXPORT-*] Export packages for LLM consumption
- **swift-package-build** - [PKG-BUILD-*] Operational build instructions: local iteration via the workspace (headless xcodebuild against institute.xcworkspace, clean environment — no TOOLCHAINS) [PKG-BUILD-023–024]; toolchain selection/assert for scoped SwiftPM contexts (release/publication clean-rooms, 6.4-dev spikes, CI); Linux via Docker (`swift:<version>` stable + `swiftlang/swift:nightly-main-jammy` nightly, release-config convention); Embedded Swift source-guard pattern (`#if !hasFeature(Embedded)`) + build-mode invocation; clean-room + resolution-identity discipline (pin-assert cold-room; canonical-basename identity; mirror-first publication) [PKG-BUILD-013–015]
- **collaborative-discussion** - [COLLAB-*] Multi-agent collaborative discussions
- **reflect-session** - Structured post-session reflection capture
- **issue-investigation** - [ISSUE-*] Systematic compiler/toolchain issue investigation: reproduce, reduce, verify, resolve
- **swift-pull-request** - [SWIFT-PR-*] Submit PRs to swiftlang/swift: fork, branch, commit, test, CI, reviewers
- **swift-evolution** - [PITCH-PROC-*] Pitch phase: triggers, evidence, scope, drafting, submission, iteration, bidirectional evidence
- **swift-forums-review** - [FREVIEW-*] Pressure-test a package pre-launch: simulate a forums.swift.org review thread with statistically-derived reviewer archetypes, predict which critique angles will land hardest, and triage outputs along two orthogonal axes — classification (load-bearing vs archetype-shaped) per [FREVIEW-012] and correctness (verified-true vs false-premise) per [FREVIEW-018]
- **release-readiness** - [RELEASE-*] Multi-phase release-readiness brief and final pre-release scan: 4-phase release-prep brief, 7-phase final scan, skill-incorporation gate for pilot launches in a cohort, per-action authorization gates (tag/visibility/blog/deploy), GO/CONDITIONAL GO/NO-GO recommendation
- **ci-cd-workflows** - [CI-*] Three-tier reusable-workflow chain (consumer → layer wrapper → universal); universal matrix shape (Swift 6.3 + 6.4-dev nightly); L1 embedded-build invariant; reusable consumption pattern (`@main` pinning, public/private visibility gate, minimal per-package callers); no-`.build/`-cache policy; mass-rollout discipline (per-action authorization, surgical commits, dirty-skip)
- **rule-exemptions** - [RULE-EXEMPT-*] Seven recurring exemption shapes for the linter rule corpus: authoring or amending a custom lint rule whose firing intersects a deliberate institute or stdlib pattern
- **swift-package-index** - [SPI-*] SPI onboarding + package collections: listing gates (public + semver tag + valid manifest + URL-form closure), leaf-first tagging cascade, per-org auto vs self-hosted-unified collections, unsigned-v1 signing posture (host-based trust selection), PackageList submission + at-scale etiquette, and the canonical `.spi.yml` policy (docs-hosting only, no CI-matrix mirror)

### Requirement ID convention

Requirement IDs follow `[PREFIX-NNN]` with a zero-padded integer. Exception: foundational axioms that name themselves semantically MAY use `[PREFIX-WORD]` (for example `[IMPL-INTENT]`, `[IMPL-COMPILE]`, `[MOD-DOMAIN]`). These are declared axioms, not numbered rules — the word is the axiom's identity. Tools that pattern-match IDs should accept both `[A-Z]+(-[A-Z]+)+` and `[A-Z]+-\d+`.

### Absorption History
- **naming**, **errors**, **code-organization** → absorbed into **code-surface**
- **primitives-conversions** → absorbed into **conversions**
- **design** (carried `[API-DESIGN-*]`), **anti-patterns** → absorbed into **implementation**; current rules use `[IMPL-*]` / `[API-LAYER-*]` / `[PATTERN-*]`
- **skill-creation** → absorbed into **skill-lifecycle**

---

## Loading Order

Skills are loaded based on their `requires:` DAG. The order is:

1. `swift-institute-core` (no requirements)
2. `swift-institute` (requires: swift-institute-core)
3. `swift-package` (requires: swift-institute)
4. `code-surface` (requires: swift-institute)
5. `platform` (requires: swift-institute)
6. `memory-safety` (requires: swift-institute)
7. `modularization` (requires: swift-institute, code-surface)
8. `conversions` (requires: swift-institute)
9. `implementation` (requires: swift-institute, code-surface, conversions)
10. `existing-infrastructure` (requires: swift-institute, implementation, conversions)
11. `testing` (requires: swift-institute, code-surface)
12. `testing-swiftlang` (requires: testing)
13. `testing-institute` (requires: swift-institute-core, testing, platform)
14. `benchmark` (requires: testing)
15. `documentation` (requires: swift-institute, code-surface)
16. `readme` (requires: swift-institute)
17. `github-repository` (requires: swift-institute, readme)
18. Process skills (requires: swift-institute or swift-institute-core)
    - `swift-package-build` (requires: swift-institute-core)
19. `release-readiness` (requires: swift-institute; cross-references audit, swift-forums-review, skill-lifecycle, github-repository, readme, documentation)

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
