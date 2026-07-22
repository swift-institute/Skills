---
name: research-process
description: |
  Research workflows: investigation, discovery, documentation.
  Apply when conducting design research or exploring alternatives.

layer: process

requires:
  - swift-institute

applies_to:
  - research
  - design

---

# Research Process

Workflows for conducting design research. Three source documents define the research system:

| Document | Purpose | IDs |
|----------|---------|-----|
| Research.md | Shared infrastructure | RES-002 – RES-010, RES-020 – RES-026 |
| Research Investigation.md | Reactive workflow | RES-001, RES-001a, RES-004, RES-004a, RES-011 |
| Research Discovery.md | Proactive workflow | RES-012 – RES-017 |

**Research vs Experiment**: Research analyzes design decisions (Markdown). Experiments verify compiler/runtime behavior (Swift packages). Use experiments for "does X compile?"; use research for "should we use X or Y?"

---

## Investigation Workflow (Reactive)

**Entry point**: Design question arose during implementation.

### [RES-001] Investigation Triggers

**Statement**: An investigation research document MUST be created when a design decision cannot be made without systematic analysis of alternatives. SHOULD NOT be created when existing conventions clearly answer the question.

| Category | Description | Action |
|----------|-------------|--------|
| Naming ambiguity | Multiple valid names | Create research |
| Pattern selection | Multiple patterns could apply | Create research |
| Trade-off resolution | Competing concerns | Create research |
| Architecture choice | Structural decision | Create research |
| Convention clarity | Existing convention answers it | Read docs first |
| Implementation detail | Does not affect API | No research needed |

**Cross-references**: [RES-001a], [RES-004]

---

### [RES-001a] Research Granularity

**Statement**: Research documents SHOULD NOT be created when: (1) conventions clearly answer the question, (2) no meaningful alternatives were considered, or (3) the rationale is implementation-specific rather than design-level.

If the decision affects HOW code is written → code comments. If it affects WHAT is built or WHY → research.

**Cross-references**: [RES-001], [RES-004a]

---

### [RES-004] Investigation Methodology

**Statement**: Design questions MUST be investigated by enumerating options, identifying evaluation criteria, and systematically comparing alternatives.

| Step | Action | Output |
|------|--------|--------|
| 1 | State the question precisely | Clear question |
| 2 | Enumerate all viable options | Option list |
| 3 | Identify evaluation criteria | Criteria list |
| 4 | Analyze each option against criteria | Comparison table |
| 5 | Document constraints | Constraint list |
| 6 | Make recommendation or decision | Outcome |

**Cross-references**: [RES-005], [RES-006]

---

### [RES-004a] Convention Consultation

**Statement**: Before creating a research document, existing conventions MUST be consulted. Research SHOULD only be created when conventions do not clearly answer the question.

Consultation process: (1) Identify decision category, (2) consult convention doc (Naming.md, Design.md, etc.), (3) if convention answers → follow it, no research; if ambiguous → create research.

**Cross-references**: [RES-001], [API-NAME-001]

---

### [RES-011] Research-First Design

**Statement**: When implementation is blocked by a design question, a research document SHOULD be created to resolve the question BEFORE attempting multiple implementation approaches.

Sequence: Identify blocking question → Create research → Enumerate options → Analyze trade-offs → Make decision → Implement chosen approach.

Research-first prevents implementation thrashing, documents rationale, and creates institutional knowledge.

**Cross-references**: [RES-001], [RES-004]

---

## Shared Infrastructure

### [RES-002] Document Location Convention

**Statement**: Research documents MUST be created in a `Research/` directory at
the root of the appropriate repository, with a descriptive, kebab-case filename.
Only two kinds of `Research/` container are valid:

| Scope | Repository |
|-------|------------|
| Ecosystem-wide / cross-layer / cross-package | `swift-institute/Research/` |
| Per-package (scoped to that package's design/naming/architecture) | `<pkg>/Research/` (e.g. `swift-buffer-primitives/Research/`) |

**Layer-level containers are forbidden**: `swift-primitives/Research/`,
`swift-standards/Research/`, `swift-foundations/Research/` MUST NOT exist.
These directories were historically used when the three layers were superrepos;
they have been dismantled into standalone sibling packages. Research that would
have lived at a layer-container level has exactly two canonical homes:
(a) the per-package `<pkg>/Research/` when the analysis is scoped to a single
package's design/naming/architecture, or (b) the ecosystem-wide
`swift-institute/Research/` for anything cross-package, cross-layer, or
genuinely ecosystem-wide.

If a layer-level `Research/` directory is encountered, it MUST be triaged per
[RES-002a]: relocate each doc to its correct per-package or ecosystem-wide
home, update the relevant `_index.json` files per [RES-003c], and remove the
layer-level container. This is the canonical remediation, not a migration
option.

**Forbidden subdirectories**: `Research/` MUST NOT contain `_work/`,
`_scratch/`, `prompts/`, or any other underscore-prefixed subdirectory.
These paths historically accumulated session-internal artifacts — phase
notes from process runs, investigation brief templates, scratch drafts —
that do not belong in a public research corpus. Process skills that
previously staged intermediate output there MUST instead emit their
output to the conversation or
to a skill-specific local staging area outside of `Research/`. The
repository `.gitignore` actively ignores these paths.

Allowed subdirectories of `Research/`:

| Subdirectory | Purpose |
|--------------|---------|
| `Reflections/` | Session reflections per **reflect-session** |
| `References/` | BibTeX citation files per [RES-026] |

SUPERSEDED research stays in place in the flat `Research/` root
— no `_archived/` subdirectory is created or maintained;
consumers filter on `status` in `_index.json`.

Any other subdirectory structure MUST be proposed via skill update, not
created ad hoc. Notably, non-underscore-prefixed topical subdirectories (e.g.,
`Research/data structures/`) are also forbidden — they bypass the `_index.json`
discovery mechanism; flatten to prefixed filenames at the `Research/` root
(e.g., `data-structures-linear-collections.md`).

**Cross-references**: [RES-002a], [RES-003c], [RES-008]

---

### [RES-002a] Research Triage

**Statement**: Before creating a research document, determine scope. Research
specific to one package goes in that package's `Research/` directory.
Ecosystem-wide, cross-package, or cross-layer analysis goes in
`swift-institute/Research/`. Layer-level containers are forbidden per
[RES-002].

| Criterion | Repo |
|-----------|------|
| One package's types, naming, or design | `<pkg>/Research/` |
| Multiple packages at the same layer, all owned by one clear domain owner | That owner's `<pkg>/Research/` |
| Multiple packages, no clear owner, or spanning layers | `swift-institute/Research/` |
| General Swift design philosophy, architecture | `swift-institute/Research/` |
| Skill/process design | `swift-institute/Research/` |

**Decision rule**: if the research only matters to consumers of one package
(its API, its internal design, its name), it goes in that package's
`Research/`. If it matters across packages — comparative analyses, tier
architecture, cross-layer protocols, general Swift shape — it goes in
`swift-institute/Research/`. **Layer-level `<layer>/Research/` containers do
not exist** and MUST NOT be created as a fallback for "sort-of primitives-wide"
content; that fallback IS `swift-institute/Research/`.

**Post-dismantle anti-pattern + correction (2026-04-24)**: before 2026-04-23,
the three layer containers (`swift-primitives`, `swift-standards`,
`swift-foundations`) were git superrepos that each owned a layer-level
`Research/`. When those superrepos were dismantled, the layer-level research
corpora became orphan content. ~80 research docs across the three layers had
to be triaged: package-scoped ones to each package's `Research/`, cross-cutting
ones to `swift-institute/Research/`. This skill now codifies the rule forward.

**Cross-references**: [RES-002], [RES-003c], [RES-006a]

---

### [RES-003] Document Structure

**Statement**: Research documents MUST contain: Title, Metadata, Context, Question, Analysis, Outcome. SHOULD include References.

Template:

```markdown
# {Topic Title}

<!--
---
version: 1.0.0
last_updated: YYYY-MM-DD
status: DECISION | RECOMMENDATION | DEFERRED | IN_PROGRESS
---
-->

## Context
{Why this research is needed}

## Question
{The specific design question}

## Analysis
### Option A: {Name}
{Description, pros, cons}

### Comparison
| Criterion | Option A | Option B |
|-----------|----------|----------|

## Outcome
**Status**: {DECISION | RECOMMENDATION | DEFERRED}
{Conclusion and rationale}

## References
```

**Cross-references**: [RES-003a], [RES-003b]

---

### [RES-003a] Metadata Requirements

**Statement**: Research documents MUST include metadata: version, last_updated date, and status.

| Status | Meaning |
|--------|---------|
| IN_PROGRESS | Analysis ongoing |
| DECISION | Complete, decision made and implemented |
| RECOMMENDATION | Complete, not yet implemented |
| DEFERRED | Complete, awaiting future information |
| SUPERSEDED | Replaced by newer research |

**Cross-references**: [RES-003], [RES-008]

---

### [RES-003b] Naming Alignment

**Statement**: Filename (kebab-case) and title (natural language) MUST be aligned. Example: `heap-storage-variants.md` → `# Heap Storage Variants`.

**Cross-references**: [RES-002], [RES-003]

---

### [RES-003c] Research Index

**Statement**: If `Research/` contains 2+ documents, `Research/_index.json` MUST exist and is the authoritative index. It MUST contain, for each document: `file`, `displayName`, `topic`, `status` (from the canonical enum: `DECISION | RECOMMENDATION | IN_PROGRESS | DEFERRED | SUPERSEDED | ACTIVE | ANALYSIS | COMPLETE | CONVERGED | DRAFT | IMPLEMENTED | INVENTORY | MOVED | REFERENCE | TRANSCRIPT`), optional `statusDetail`, `statusRaw`, `tier` (integer 1/2/3 or null), `scope` (`ecosystem-wide`/`cross-package`/`cross-layer` or null). Pointer-only notes about external destinations (reflections index, moved research, workflow notes, see-also) use `narrativeSections[]` with `heading` + `body`. Schema: `https://swift-institute.org/schemas/research-index-v1.json`.

**Valid index locations**: `_index.json` exists exactly at the two kinds of
`Research/` container valid per [RES-002]:

| Index location | Corresponds to |
|---|---|
| `swift-institute/Research/_index.json` | Ecosystem-wide research corpus |
| `<pkg>/Research/_index.json` | Per-package research (e.g. `swift-buffer-primitives/Research/_index.json`) |

Layer-level `_index.json` files (`swift-primitives/Research/_index.json`,
`swift-standards/Research/_index.json`,
`swift-foundations/Research/_index.json`) are forbidden — their parent
containers are forbidden per [RES-002]. Relocating a document per [RES-002a]
MUST update both the source index (remove the entry) and the destination
index (add the entry) in the same commit wave; when the source is a
layer-level container being retired, the retirement MUST delete the index
file once all entries have been relocated.

The canonical human-browsable view of a public research corpus is the [Research dashboard](https://swift-institute.org/dashboard/#research) on swift-institute.org; it fetches `_index.json` directly at runtime. For private research corpora there is no dashboard — consumers read `_index.json` directly (GitHub pretty-prints it) or via tooling that parses the manifest. `_index.md` is forbidden; the markdown table was historically load-bearing but is now strictly redundant with `_index.json`. `_index.json` is the only allowed non-research file in `Research/`.

**Multi-phase migration transition clause**: when the present-tense rule above is true for *new work* but legacy artifacts exist in the ecosystem that have not yet been migrated (as was briefly the case between the skill update and the ecosystem-wide `_index.md → _index.json` sweep), both statements are simultaneously accurate: the rule applies to new work; legacy artifacts migrate on a named condition. Skills describing rules during multi-phase rollouts SHOULD use this pattern when a gap between rule-text and ecosystem-state exists: *"{rule} applies to new work. Legacy {artifacts} migrate on {condition}; once migrated, {rule} becomes strict for that repo."* The absence of a transition clause forces the rule-writer into aspirational text (the rule pretends the ecosystem already complies) OR weakened text (the rule softens to describe current reality) — neither is accurate during a staged rollout. The transition clause preserves rule strictness while accurately describing the in-flight state.

**Cross-references**: [RES-002], [RES-008]

---

### [RES-004b] Scope Escalation

**Statement**: If analysis reveals implications beyond the original scope: cross-package → recommend Discovery; single-package → MAY spawn targeted Investigation. Must record escalation with cross-reference.

**Cross-references**: [RES-002a], [RES-012]

---

### [RES-005] Analysis Methodology

**Statement**: Research analysis MUST be systematic: enumerate options, identify criteria, analyze trade-offs.

| Component | Required |
|-----------|----------|
| Options enumeration | MUST |
| Criteria identification | MUST |
| Trade-off analysis | MUST |
| Constraints documentation | SHOULD |
| Prior art review | SHOULD |

**Cross-references**: [RES-006]

---

### [RES-006] Outcome Documentation

**Statement**: Outcomes MUST include clear status, rationale, and implementation notes.

| Outcome | Action |
|---------|--------|
| DECISION | Document choice, rationale, implementation path |
| RECOMMENDATION | Document recommendation with caveats |
| DEFERRED | Document why deferred, what would resolve it |
| IN_PROGRESS | Document current state, next steps |

**Cross-references**: [RES-006a], [RES-003]

---

### [RES-006a] Documentation Promotion

**Statement**: When research establishes conventions or patterns, findings SHOULD be promoted to authoritative documentation.

| Criterion | Action |
|----------|--------|
| New convention | Promote to Naming.md or similar |
| Documents pattern | Promote to Implementation Patterns |
| Reveals constraint | Promote to requirements doc |
| One-time decision | Keep in Research only |

The outcome status remains unchanged. Promotion is elevation, not invalidation.

**Cross-references**: [RES-006], [API-NAME-001]

---

### [RES-007] Context Documentation

**Statement**: Research documents MUST record context: trigger (what prompted it), constraints, timeline, stakeholders.

**Cross-references**: [RES-003]

---

### [RES-008] Research Document Lifecycle

**Statement**: Research documents are persistent and git-tracked. Lifecycle: Active → Concluded → Referenced → Updated → Superseded.

When updating concluded research: increment version, update date, add changelog, preserve original analysis.

**Cross-references**: [RES-002], [RES-003a]

---

### [RES-009] Multi-Option Analysis

**Statement**: When analyzing multiple related options, all viable alternatives MUST be documented with consistent structure enabling comparison.

Each option needs: Description, Advantages, Disadvantages, Constraints. Plus a comparison table.

**Cross-references**: [RES-005], [RES-006]

---

### [RES-010] Common Research Patterns

**Statement**: Research documents SHOULD follow established templates for common analysis types.

**Cross-references**: [RES-003], [RES-005]

---

### [RES-010a] Naming Analysis Template

For naming decisions: Context → Question ("What should X be named?") → Options with rationale, precedent, conflicts → Comparison against spec terminology, existing APIs, Foundation conflicts → Outcome.

---

### [RES-010b] Architecture Analysis Template

For architecture decisions: Context → Question ("How should X be architected?") → Options with structure, complexity, performance, maintainability → Comparison → Outcome.

---

### [RES-010c] Trade-off Analysis Template

For trade-offs: Context → Question ("How to balance A vs B?") → Concerns with importance and impact → Trade-off matrix (prioritize A / prioritize B / balance) → Outcome.

---

## Research Rigor (Tiered)

### [RES-020] Research Tiers

**Statement**: Research MUST be classified into tiers based on precedent risk, not scope alone.

| Criterion | Tier 1: Quick | Tier 2: Standard | Tier 3: Deep |
|-----------|---------------|------------------|--------------|
| Scope | Package-specific | Cross-package | Ecosystem-wide |
| Precedent-setting | No | No or reversible | Yes, hard to undo |
| Semantic commitment | None | Informal | Normative/foundational |
| Cost of error | Low | Medium | Very high |
| Expected lifetime | Single release | Several releases | Timeless infrastructure |
| Formalization | Not required | Optional | Mandatory |

**Tier 3 threshold**: Establishes long-lived semantic contract that future APIs depend on. Exceptional — very few per year.

**Cross-references**: [RES-002a], [RES-004b]

---

### [RES-021] Prior Art Survey

**Statement**: Tier 2+ MUST include Prior Art Survey: Swift Evolution proposals/forums, related languages (Rust RFCs, Haskell GHC, OCaml), academic literature (arXiv, ACM DL, POPL/ICFP/OOPSLA).

**Statement**: When a prior art survey identifies a pattern that is universally adopted across surveyed systems but absent from the ecosystem, the survey MUST include a "contextualization step" before classifying the absence as a gap: concretely describe what the proposed concept would look like in the ecosystem's type system, and evaluate what it would cost (type erasure, loss of typed throws, constraint violations, etc.). Universal adoption does not imply universal necessity — the absence may be a deliberate design decision.

**Cross-references**: [RES-005], [RES-022]

---

### [RES-022] Theoretical Grounding

**Statement**: Tier 2+ SHOULD include theoretical grounding (type theory, category theory, operational/denotational semantics) when it improves precision.

**Cross-references**: [RES-023], [RES-024]

---

### [RES-023] Systematic Literature Review

**Statement**: Tier 3 MUST include SLR per Kitchenham methodology: research questions, explicit search strategy, inclusion/exclusion criteria, screening, data extraction, synthesis.

**Cross-references**: [RES-021], [RES-024]

---

### [RES-024] Formal Semantics

**Statement**: Tier 3 MUST include formal semantics with typing rules, operational semantics, and soundness arguments.

| Tier | Main body | Appendices |
|------|-----------|------------|
| Tier 1 | Prose only | None |
| Tier 2 | Light formalism, explained | Optional |
| Tier 3 | Formal definitions inline | Extended proofs |

**Cross-references**: [RES-022], [RES-023]

---

### [RES-025] Empirical Validation

**Statement**: Tier 2+ for API-facing decisions SHOULD include empirical validation using Cognitive Dimensions Framework: visibility, consistency, viscosity, role-expressiveness, error-proneness, abstraction.

**Cross-references**: [RES-005], [RES-009]

---

### [RES-026] Citations

**Statement**: Tier 2+ research SHOULD cite its sources; Tier 3 research MUST include a References section with traceable links to Swift Evolution proposals, Swift Forums threads, academic papers, upstream compiler source, or other primary material. Citations are plain Markdown links — there is no BibTeX or formal citation machinery.

**Cross-references**: [RES-003], [RES-021]

---

## Discovery Workflow (Proactive)

**Entry point**: Audit design decisions, verify convention compliance, or document architectural rationale.

### [RES-012] Discovery Triggers

**Statement**: A discovery research document SHOULD be created when proactive analysis would improve consistency, document rationale, or identify improvements.

| Category | Priority |
|----------|----------|
| Package milestone (v1.0) | High |
| Cross-package review | High |
| Convention evolution | Medium |
| Rationale documentation | Medium |
| Pattern extraction | Medium |
| Retrospective | Low |

**Discovery vs Investigation**: Investigation starts from uncertainty to make a decision. Discovery starts from a working design to verify/document it.

**Cross-references**: [RES-001], [RES-002a]

---

### [RES-013] Design Audit Methodology

**Statement**: Design audits MUST follow systematic methodology: (1) Scope definition, (2) Decision inventory, (3) Evaluation criteria, (4) Evaluate, (5) Synthesize, (6) Recommend.

Scope defines: packages, decision types, relevant conventions. Inventory catalogs all design decisions. Evaluation uses criteria like convention compliance and cross-package consistency. Recommendations propose actions.

**Cross-references**: [RES-013a], [RES-014], [RES-015]

---

### [RES-013a] Synthesis Verification

**Statement**: When a research document synthesizes findings from prior documents, each carried-forward finding MUST be verified against current source before inclusion. Prior documents are leads, not ground truth. **This applies to ANY load-bearing reliance on a prior artifact's state-claims — a research doc, a placement/architecture map, an executor brief, a ruling, or in-session reasoning — not only research-document synthesis.** A `Verified: DATE` tag has a **shelf life**: if source changed since DATE (`git log` the cited paths), the claim is *unverified* until re-checked. **Live source outranks any dated-verified artifact — including the layer-placement calculus/map — on type names and current state.**

Each finding MUST include a verification tag:

| Tag | Meaning |
|-----|---------|
| `Verified: YYYY-MM-DD` | Finding confirmed against current code |
| `Carried forward (unverified)` | Taken from prior document, not re-checked |
| `Resolved: YYYY-MM-DD` | Finding no longer applies (with explanation) |

**Forcing function** — a stated discipline is weak; prefer a **mechanical, always-fresh check that reads live source** (a lint/inventory, e.g. `Scripts/layer-placement-classify.py`) over a prose state-claim that silently ages. A lint cannot go stale; a dated doc does.

**Cross-references**: [RES-013], [RES-008]

---

### [RES-014] Consistency Analysis

**Statement**: Consistency analysis MUST compare related design decisions across packages, identifying deviations and evaluating whether deviations are justified.

Categories: naming patterns, structural patterns, API patterns, error patterns, convention compliance.

Use template: Pattern definition → Current state table → Deviations (with justification assessment) → Recommendations.

**Cross-references**: [RES-013], [RES-015]

---

### [RES-015] Convention Compliance Verification

**Statement**: Convention compliance verification MUST check decisions against relevant convention rules, documenting compliance and justified exceptions.

Convention sources: Naming.md [API-NAME-*], Errors.md [API-ERR-*], Design.md [API-DESIGN-*], Code Organization.md [API-IMPL-*].

Use template: Convention reference → Items checked (compliance table) → Non-compliant items (current, required, resolution) → Summary.

**Cross-references**: [RES-013], [RES-014]

---

### [RES-016] Rationale Documentation

**Statement**: Significant design decisions SHOULD have documented rationale. Discovery research MAY retroactively document rationale.

| Criterion | Requirement |
|-----------|-------------|
| Affects multiple packages | SHOULD document |
| Establishes precedent | MUST document |
| Deviates from convention | MUST document |
| Has non-obvious trade-offs | SHOULD document |
| Frequently questioned | SHOULD document |

Use template: Decision → Context → Alternatives considered (with rejection reasons) → Chosen approach → Implications → References.

**Cross-references**: [RES-006], [RES-013]

---

### [RES-017] Pattern Extraction

**Statement**: When similar solutions appear across multiple packages, the pattern SHOULD be extracted and documented.

Process: (1) Identify recurring solution, (2) Collect instances, (3) Abstract common elements, (4) Document variations, (5) Propose standardization.

Use template: Pattern definition → Instances found table → Common elements → Variations → Standardized pattern → Application guidance.

**Cross-references**: [RES-014], [RES-006a]

---

### [RES-018] Cross-Cutting Primitive: Compose-First Justification

**Statement**: Tier 2+ research that proposes a **new cross-cutting primitive** — a type family intended for re-use across multiple unrelated domains (Memory, Storage, Buffer, Collection grade) — MUST include a *"Why not compose existing primitives?"* section demonstrating that composition of the existing catalog cannot cover the use case. Whether the proposal is genuinely cross-cutting (case (a) below) rather than domain-owned (case (b)) or a layer-agnostic pull-down (case (c)) is decided **structurally** — by the type's shape and layer-agnosticism — NOT by counting current or prospective consumers.

Symmetric-completeness reasoning ("this cell is empty in the orthogonal grid", "this family has ℝⁿ variants but we lack the ℝᵐ case") is explicitly disallowed as the sole justification for a cross-cutting primitive. It is permitted as supporting evidence inside a single domain's L1 lattice.

**Scope carve-outs — rule does NOT fire**:

The rule classifies a proposal into one of four cases; only case (a) is gated by this rule.

| Case | Description | Gating |
|------|-------------|--------|
| (a) **Cross-cutting primitive** | Type family intended for re-use across multiple unrelated domains (Memory, Storage, Buffer, Collection grade). | Gated by this rule: the composition check. Cross-cutting status is a structural judgment about the type's shape, not a consumer count. |
| (b) **Domain-owned vocabulary at L1** | A type a single domain uses to express its own concepts inside its `swift-{domain}-primitives` package. Per Five-Layer Architecture: "each domain owns its vocabulary and L1 functionality." | Governed by `[MOD-DOMAIN]` (semantic coherence) alone. No consumer-count gate. |
| (c) **Layer-agnostic primitive surfaced at L2/L3** | Implementation work that surfaced inside an L2 standards or L3 composition package, whose shape is layer-agnostic (e.g., parser combinators surfacing inside `swift-json`, scanning primitives surfacing inside an HTTP package, text-position primitives surfacing inside diagnostics). **Pulling the type down to L1 is the architecturally mandated default**, not a "premature primitive" candidate. The originating L2/L3 package IS the first consumer; future consumers materialize *because* the type lives at L1. | Architecturally mandated by `[ARCH-LAYER-001]`. The "pull-down" move requires only that the proposed L1 home is correct per `[MOD-DOMAIN]`. No consumer-count gate. |
| (d) **L2 standards-internal type mirroring a spec** | Types added inside a standards-implementation package whose names and shape mirror the specification per `[API-NAME-003]`. | Justified by spec fidelity per `[API-NAME-003]`; no additional hurdle. |

Additional first-principles companions (consistent with — not exceptions to — this rule):

- `[ARCH-LAYER-008]` — correctness / architectural merit is the sole driver of split / reshape / extraction decisions, at any phase.
- `[RES-020a]` — total-taxonomy packages justify their types by lattice-cell merit.
- `feedback_correctness_and_evergreen` — adoption of `~Copyable` / `~Escapable` / ownership-model changes on existing types is judged on structural correctness + evergreen.

- **Original direction (over-promotion)**: an internal-to-one-package need misclassified as cross-cutting, producing an unjustified new top-level primitive package whose shape no other domain actually shares. Long tails — maintenance surface, review cost on adjacent changes, "absorb or add?" decision forks — accrue against the ecosystem.
- **Newly recognized direction (under-pull-down)**: a layer-agnostic need misclassified as originating-package-specific, leaving the implementation trapped inside the L2/L3 package where it surfaced. Future consumers must then either depend on the originating package (wrong: pulls a JSON/HTTP/etc. dep through unrelated code) or re-derive (worse: parallel divergent re-implementations). The "no second consumer yet" objection inverts the architecture's intent — L1 *creates* the conditions for future consumers by making the type discoverable at the right layer.

The classification is structural: (a) genuinely cross-cutting → the shape is domain-agnostic across unrelated domains; (b) domain-owned vocabulary → governed by `[MOD-DOMAIN]` alone; (c) layer-agnostic primitive surfaced higher up → pulled down to L1 by default, with the originating L2/L3 package as the first consumer.

**Example (defect, case a misuse — original failure mode)**: A Tier 2 research note proposes `Kernel.Thread.Pool.Deque.Specialized` as a new cross-cutting primitive because the existing catalog has `Deque`, `Deque.Bounded`, and `Deque.Ring` — the "Specialized" cell is empty in the orthogonal variant grid. Structurally the shape is specific to the thread-pool domain — nothing makes it cross-cutting — and the symmetric-completeness argument is the sole justification. **Rejected** by the composition check + structural classification (it is case (b), domain-owned, at most).

**Example (defect, case c misuse — newly recognized failure mode)**: While building `swift-json`, the team needs a parser-combinator scaffold and text-position tracking. Both are JSON-agnostic. A reviewer cites [RES-018] to block their extraction into `swift-parser-primitives` / `swift-text-primitives`: "no second consumer; JSON is the only user." **The citation is wrong**: this is case (c), not case (a). The agnostic implementations belong at L1 *because* they are agnostic; trapping them in `swift-json` would force CBOR / MessagePack / TOML implementations to either depend on `swift-json` (wrong) or re-derive (worse). The pull-down is architecturally mandated.

**Example (correct, case a)**: A Tier 2 research note proposes `Kernel.Thread.Executor.WorkStealing` with a demonstrated *"composition of Pool + Scheduler leaks priority-inheritance through the scheduler interface"* section, and shows the shape is structurally domain-agnostic — work-stealing scheduling is not thread-pool-specific (Foundation's HTTP request-dispatch needs the identical structure). The composition check is cleared and the cross-cutting status is structural.

**Procedure for proposal authors**:

1. Classify the proposal into one of cases (a)–(d) above — structurally, by the type's shape and layer-agnosticism.
2. If case (a): apply the composition check, and show the shape is domain-agnostic (applies across unrelated domains by its structure). Do NOT cite a current or prospective second consumer as evidence — cross-cutting status is structural, not a consumer count.
3. If case (b): cite `[MOD-DOMAIN]`; demonstrate the type belongs to the domain's coherent semantic vocabulary. No further hurdle.
4. If case (c): identify the correct L1 home per `[MOD-DOMAIN]` (existing primitives package or, if none fits, a new domain package whose scope is justified independently). The originating L2/L3 package becomes the first consumer; no second-consumer evidence required. Document the pull-down decision so the architectural intent is visible.
5. If case (d): demonstrate spec fidelity per `[API-NAME-003]`. No further hurdle.

- 2026-04-16-chase-lev-spike-and-premature-primitive-trap.md (original anti-pattern)
- 2026-05-14 amendment: cross-cutting scope made operational; case (c) layer-agnostic pull-down carve-out added; case (b) domain-owned vocabulary carve-out made structural rather than phase-bounded. Anchors: `feedback_correctness_and_evergreen.md`, principal-stated five-layer architectural rule ("L2 standards-impl maximize re-use of L1; L3 composition maximize re-use of L1; L1 modularization per domain — each domain owns its vocabulary").
- 2026-06-09 BREAKING: removed the consumer-demand gate (the case-(a) "name a second-domain consumer / cross-domain-fit" hurdle) and retitled the rule; case (a) is now gated by the composition check plus a *structural* cross-cutting judgment. Consumer / adoption count is no longer a decision driver. Principal direction (first-principles MO, not YAGNI); anchors `feedback_correctness_and_evergreen.md`.

**Cross-references**: [RES-005], [RES-020], [RES-020a], [MOD-DOMAIN], [MOD-RENT], [ARCH-LAYER-001], [ARCH-LAYER-008], [API-NAME-003]

---

### [RES-019] Step-0 Internal Research Grep

**Statement**: Before starting external prior-art survey (academic literature, upstream projects, language spec), the research agent MUST grep the internal `swift-institute/Research/` and the target package's `Research/` corpus for topic keywords. Internal prior research is often stronger than external commentary and often already answers the question.

**Procedure**:

```bash
# Target package's Research/
grep -rl "<topic-keyword>" {target-package}/Research/

# Ecosystem-wide
grep -rl "<topic-keyword>" swift-institute/Research/
ls swift-institute/Research/*-ecosystem-model.md
```

If internal research exists, cite it before extending; if it conflicts with the external survey you're about to run, the internal research governs pending explicit override.

**Source-shape sweep**: when the research question includes "does X already exist?", the step-0 grep MUST also sweep `Sources/` for candidate type shapes (e.g. `grep -rn "struct Map\|extension Memory" <candidate-pkg>/Sources/`), not only `Research/` docs — shipped source outranks a doc that still treats the type as hypothetical. Rationale: `Memory.Map` was found already shipped while the owning research doc treated the mapped envelope as hypothetical (Reflections/2026-06-12-memory-foreign-arc-third-ownership-regime.md).

**Cross-references**: [RES-004a]

---

### [RES-020a] Total-Taxonomy / Lattice-Position Justification for Foundational Packages

**Statement**: For foundational / total-taxonomy packages — packages that aspire to cover a domain *completely* (e.g., `swift-ownership-primitives` covering the 5-axis ownership lattice, `swift-numeric-primitives` covering numeric type families) — per-type evaluation MUST be framed by *position-in-the-domain-lattice (merit)*, NOT by *adoption count (usage)*. Deprecation by adoption count is forbidden for these packages.

**Decision test**: *"Does this package aspire to cover a domain completely, such that adding a type fills a lattice cell, not a consumer need?"* If yes → merit framing is mandatory.

**Why merit-not-adoption for total-taxonomy packages**: usage-driven deprecation removes types whose lattice cells are real-but-currently-unused. The lattice's value comes from completeness — a consumer designing in the domain consults the lattice expecting all cells to be present. Removing low-usage cells creates lattice gaps that mis-direct consumers ("the type doesn't exist, so the design space doesn't include this position") even though the position is structurally valid.

**Procedure** (when proposing additions OR removals to a total-taxonomy package):

1. Identify the lattice / domain structure the package covers.
2. For each existing type, identify its lattice cell.
3. For proposed additions: justify the cell being filled (which lattice position is currently empty?).
4. For proposed removals: prove the cell is no longer a valid position in the lattice (the structural axis itself is no longer relevant), NOT that the cell has low adoption.

**Relationship to [MOD-RENT]**: [MOD-RENT]'s criteria (capability + theoretical content) apply to all primitive packages. [RES-020a] (this rule) adds the lattice-completeness lens for total-taxonomy packages: their types are justified by lattice-cell merit (which structural position they fill), and — like every package under [ARCH-LAYER-008] — never by adoption count.

**Cross-references**: [RES-020], [MOD-RENT], [MOD-DOMAIN]

---

### [RES-034] Parallel Subagent Verification for Tier 2+ Prior-Art Surveys

**Statement**: Tier 2+ prior-art surveys MUST use parallel subagent verification against primary sources before writing load-bearing claims. The `[Verified: YYYY-MM-DD]` tag per load-bearing claim is a **MUST**, not a SHOULD.

**Composite:** tag-presence regex (mechanical) + verification-quality check (semantic).

**Why parallel**: Serial verification creates confirmation pressure (the agent that wrote the claim verifies its own claim); parallel subagents dispatched with the primary source and asked "does this claim match the source?" produce independent reads. The dispatch overhead is trivial compared to the cost of publishing an unverified claim.

**What counts as primary**: the paper's actual text, the runtime's actual code, the platform's actual API documentation, the experiment's actual measurement. Secondary sources (blog posts, tutorials, textbooks citing the primary) do not count.

**Cross-references**: [RES-013a], [RES-014]

---
### [RES-035] Stdlib-Protocol Conformance Verification Spike

**Statement**: Any research recommendation to conform to a stdlib protocol whose binary-interface availability has not been independently verified MUST include a verification spike (a minimal external-package test confirming the conformance actually works) before the recommendation reaches DECISION status. Two distinct mechanisms strip protocols from the SDK's `.swiftinterface`:

1. **SPI stripping**: `@_spi`-gated types can silently become unconformable from external packages when `.swiftinterface` stripping removes the declarations from the public interface.
2. **SDK-availability lag**: New stdlib protocols (e.g., `RunLoopExecutor`, `SchedulingExecutor` introduced in Swift 6.x) may be `public` in `swiftlang/swift` source but not yet shipping in a given SDK's compiled `.swiftinterface` — driven by SDK-build availability annotations, not by source visibility.

Both manifest as the same compile-time failure ("no such type in module") and both invalidate a research DECISION that did not check.

**Procedure**:

1. Before publishing the DECISION: author a minimal external-package target that declares the proposed conformance.
2. Build the external target. A build failure invalidates the conformance path even if the spec looks correct.
3. If the spike fails, the recommendation downgrades to BLOCKED with an upstream-tracking note (PR / issue link, or SDK-version-availability ETA when known).

**Cross-references**: [RES-013a], [EXP-003], [INFRA-026]

---

### [RES-036] Recommendation-Section Framing Heuristic

**Statement**: When an investigation Doc's Recommendation section evaluates multiple options with different trade-offs, the default heuristic MUST prioritize structural correctness (long-run shape) over minimum-diff lowest-risk. Diff-size and migration-risk are tiebreakers among structurally-equivalent options, NOT selection criteria over structurally-distinct options. A Recommendation that prefers a structurally-deficient option for diff-size or risk-cost reasons MUST explicitly invoke a documented exception.

**Documented exceptions** (when secondary axes legitimately dominate structural):

| Axis | When it overrides structural | What to document |
|------|------------------------------|------------------|
| Velocity | User explicitly opts for it (e.g., release-window deadline) | The user's explicit opt-in, with the deadline cited |
| Ecosystem gating | Structurally-correct option requires unlanded dependencies | The specific gating dependency + its ETA or unblock condition |
| Reversibility | Structurally-correct option is one-way; structurally-deficient is reversible later | The reversal-cost analysis showing the cheaper path forward |

Absent one of these (or an equivalent explicit user/principal directive), structural correctness dominates.

**Decision test for the Recommendation author**:

| Step | Question |
|------|----------|
| 1 | What is the structural goal? (Single typed value? Compose-over-L2? Type-with-two-initializers vs two-types?) |
| 2 | Which options recognize the structural goal? Which options reify an accidental historical split into a permanent shape? |
| 3 | Among structurally-correct options, which has the smallest diff? (Tiebreaker, not selector.) |
| 4 | If recommending a structurally-deficient option: which exception applies? Document it inline. |

**Cross-references**: [RES-001], [RES-003], [RES-013a]

---

### [RES-037] Empirical-Claim Verification for Dependent-Package State

**Statement**: [RES-013a] (Synthesis Verification) requires verification of carried-forward findings from prior research documents. This rule extends the same verification discipline to ANY empirical claim a research document makes about the live state of a dependent package or upstream source — file existence, API presence, substrate availability, type/method/property visibility, version-current behavior. Research documents that assert facts about external state MUST verify the facts at write time, not assume them from prior knowledge or inferred ecosystem state.

**Scope of empirical claims requiring verification**:

| Claim type | Verification mechanism |
|------------|------------------------|
| "X type/API exists in package P" | Grep package P's source for the declaration; cite the file:line. |
| "X is visible across module boundary" | Build a sibling target that imports P and references X; verify build clean. |
| "X is `package`-scoped / `internal`" vs "public" | Grep for the visibility modifier; cite the file:line. |
| "Substrate Y already exists" | Locate Y in the dependent package; cite the file:line. If Y is claimed to "exist internally," verify cross-package visibility per the bullet above. |
| "Upstream source S has property Q" (e.g., SE proposal status, stdlib release version) | Cite the canonical source URL or file path; quote the relevant sentence. |
| "N items match a temporal/content predicate" (e.g., "~10-15 files older than 14 days," "all packages with pattern X") — including in Q4 / Execution Plan / Next Steps sections that prescribe future triage based on the predicate | Run the prescribed enumeration command (`find -mtime +N`, `grep -l pattern`, etc.) at write time and paste the live count or set; do not estimate from prior knowledge or earlier-session context. Plan-time predictions about an external state are empirical claims subject to this rule even though they describe a future action — the prediction's accuracy depends on present state. |

**Procedure**:

1. At research-doc write time, identify each empirical claim (statements of the form "X exists in P" / "Y is visible" / "Z has property Q" / "N items match predicate P").
2. For each claim, execute the verification mechanism per the table above.
3. Annotate the claim with the verification result inline (file:line, build status, canonical-source quote, or live count from the enumeration command).
4. If verification fails, the claim either (a) needs correction, or (b) needs an explicit "hypothesis pending verification" annotation that flags it for follow-up.
5. For Q4 / Execution Plan / Next Steps sections specifically: include the enumeration command in the section body and paste its live output; the executing session re-runs the same command as step 0 of staleness check.

**Operative-evaluator clause**: verifying a derived predicate — a gate passes, a dependent set is empty, a conformer set shares a derivation, a symbol exists — MUST run the *operative evaluator* (the gate script exactly as the gate runs it, the dependency-graph grep, the conformer enumeration, the symbol-table grep) against real inputs, never a reconstruction or content-proxy of what you believe the evaluator computes. Example: a YAML content-load measured a skill description at 245 chars and declared a reported 251-char sync blocker a phantom — the operative gate (`check-skill-descriptions.sh`) runs `wc -c` on the awk-extracted block *including* the 2-space indent and newlines → 251 > 250 ceiling; the blocker was real. Rationale: names the root of a verify-the-wrong-thing cluster paid 4× in one session, unifying the corresponding per-domain memory entries per the CLAUDE.md memory-write guardrail (Reflections/2026-06-02-derive-for-free-tier3-and-operative-gate-verification.md).

**Relationship to [RES-013a]**: [RES-013a] codifies verification for synthesis (carried-forward findings from prior docs). [RES-037] (this rule) generalizes the discipline to all empirical claims, regardless of whether the claim is carried forward or originated in this doc. [RES-013a] remains the specialized rule for synthesis; [RES-037] is the umbrella covering write-time empirical claims.

**Cross-references**: [RES-001], [RES-003], [RES-013a]

---

### [RES-038] Empirical-Reproduction Requirement for Git-Recipe Claims

**Statement**: Research documents and handoffs that prescribe git command sequences (apply-on-top recipes, history-rewrite recipes, submodule-conversion recipes, multi-step rebase/cherry-pick procedures) MUST empirically reproduce the prescribed sequence in a scratch repo before publishing. Git's behavior is rich with edge cases (deletion propagation, worktree resolution, ref ambiguity, working-directory state); claims about "step N produces state Y" age silently when not verified.

**Procedure**:

1. Author the prescribed git sequence in the research doc / handoff.
2. Before publishing (DECISION / RECOMMENDATION / dispatch authorization), run the sequence in a scratch repo with the simplest possible reproduction state.
3. Verify the post-state matches the doc's claim. Pay particular attention to:
   - Deletion propagation (does `git checkout ref -- .` delete files removed in `ref`?)
   - Worktree state (does the command resolve worktree before or after the operation?)
   - Ref ambiguity (does `git describe --tags` find the tag the doc assumes?)
   - Working-directory cleanliness assumption (does the recipe assume a clean working directory?)
4. If the verification surfaces a divergence, patch the recipe to match observed behavior, with the corrective addition documented.

**Cross-references**: [RES-013a], [RES-037]

---

### [RES-039] Shape-vs-Decisions Coherence in Investigation Docs

**Statement**: When an investigation Doc has both a *Shape* section (prose description of an option) and a *Principal Decisions* table (or equivalent normative-claim section), every Decision that makes a runtime/semantic claim about the Shape's behavior MUST either amend the Shape prose to match OR insert a "see Decision #N" cross-reference at the relevant Shape clause. Latent Shape-vs-Decisions contradictions propagate into dispatch instructions (principal paraphrases Shape, misses the Decision override) and surface as rule-#6 escalations at implementation time — a gap the investigation author had context to close cheaply at authoring time.

**Procedure** (at investigation Doc write time):

1. After authoring the Decisions table, re-read the Shape section.
2. For every Decision that constrains Shape behavior, verify the Shape prose either matches the Decision OR carries a cross-reference to the Decision.
3. If the Shape prose contradicts a Decision, amend the Shape prose to match (preferred — Shape and Decisions read coherently together) OR add a "see Decision #N" cross-reference (acceptable when the Shape needs to retain the original framing for narrative reasons).

**Why this matters**: Investigation Docs feed dispatch instructions. A principal authoring a dispatch typically reads the Shape section's prose to derive the instruction; if a Decision overrides Shape but the Shape prose isn't updated, the dispatch carries the pre-Decision claim, and the subordinate executes against the wrong claim. The escalation that follows (rule-#6 silent-decision) is a downstream symptom of the Shape-Decisions incoherence at the investigation Doc.

**Cross-references**: [RES-003], [RES-036]

---

### [RES-027] Loose-End Follow-Up Requires Extant or Immediate Experiment Package

**Statement**: When a research document files a "loose end" or "separate investigation" — typically in the Residual / Open Questions / Future Work section — the close-out MUST either (a) cite an extant experiment package whose work would refute or confirm the framing, or (b) immediately create one with a minimal hypothesis variant that would refute or confirm the framing in ≤1 hour. Loose ends without empirical follow-up become architectural multipliers in subsequent design conversations: every downstream session inherits the unverified premise as a constraint and reasons forward from it.

**The cost asymmetry**:

| Action at write time | Downstream cost if premise wrong |
|----------------------|----------------------------------|
| Cite extant experiment | None — the experiment is the verification |
| Create minimal experiment (≤1 hour) | Bounded — at worst, the experiment reveals the framing was wrong |
| File as loose end without experiment | Unbounded — every downstream design conversation reasons from the unverified premise; refutation may take weeks |

**Procedure**:

1. At research-doc write time, identify each Residual / Open Questions / Future Work item.
2. For each item, ask: does this item present a *premise* (a claim about the world that downstream design will rely on) or a *direction* (a research question whose answer might or might not affect downstream design)?
3. **Premise items** MUST be backed by an extant experiment package OR an immediately-created minimal experiment. The doc's close-out cites the package by path.
4. **Direction items** MAY be filed as "future work" without empirical follow-up — they don't carry forward as constraints.
5. The Residual section MUST distinguish premises from directions so future readers can tell which items are unverified-but-load-bearing vs. unverified-and-not-load-bearing.

**The minimal experiment recipe**:

When creating an immediate experiment for a premise item, the experiment package is at `<repo>/Experiments/<topic>-<question-keyword>/`, follows [EXP-002] structure, has ONE hypothesis variant designed to refute the premise (not confirm it — refutation is more informative), and runs in ≤1 hour wall-clock. The bar is lower than a full experiment package; this is a verification spike, not a productionized benchmark.

**Cross-references**: [RES-003], [RES-013a], [RES-037], [EXP-002], [EXP-003]

---

### [RES-029] Framing-Challenge for Binding/Membership/Placement Questions

**Statement**: When a research dispatch frames a question as "rank options on axis X vs axis Y" AND the underlying entity is an instance/binding/membership/placement question (IS-A, NOT-A, where-does-it-live), the research MUST drive on semantic identity FIRST. Cost / pragmatism / aesthetics serve as tiebreakers ONLY after multiple options remain semantically valid. For IS-A evidence: operational behavior of adjacent ecosystem types ranks higher than use-site counts in the candidate site itself, because use-site counts can be artificially zero when type-availability binding has not yet propagated, while operational consensus across siblings is dispositive.

**Composite:** discipline rule (semantic) + ranking-axis priority (mechanical) + reframe-protocol (semantic).

**Ranking axis priority**:

| Tier | Axis | When dispositive |
|------|------|------------------|
| 1 | Semantic identity (IS-A, NOT-A, where-does-it-live) | Always. If this axis disambiguates, the question is closed. |
| 2 | Operational behavior of adjacent ecosystem types | When tier 1 is ambiguous; cross-sibling consensus is the empirical anchor |
| 3 | Cohesion / coupling / cost / pragmatism / use-site counts | Tiebreaker only — engaged when tiers 1 + 2 leave multiple options structurally valid |

**Reframe protocol**: when the dispatch's question text uses cost-vs-cohesion ranking language but the entity is a binding question, the supervisor MUST reframe at the orchestrator desk before dispatching. "Pragmatism is downstream of truth — IS-A or NOT-A is semantic, not a cost calculation."

**Licensed fresh-take review**: when a *ratified* direction is questioned, the review session MUST be licensed to refute the questioner's own frame — the principal's AND the seat's — proceeding prior-art-first, then fresh derivation; a review confined to the inherited frame reproduces the frame's blind spot. Example: three framed passes (direction, census, seat) missed the `typealias Iteration = Iterator.Witness` collision because each grepped the package name, never the type name; the licensed fresh-take session found it and the rename was CANCELLED-ratified. Rationale: re-derivation, not "grep harder," was the remedy in all three of that day's census misses (Reflections/2026-06-13-tower-phase-4-seat-round-m-supervision.md).

**Cross-references**: [RES-036] (Recommendation-Section Framing Heuristic), [RES-005] (Analysis Methodology)

---

### [RES-028] Smallest-Isolation-First Heuristic for Build-Target-Scoped Investigations

**Statement**: Before accepting a build target's measurements as evidence about a code construct's intrinsic cost, the investigator MUST attempt to reproduce the phenomenon in the smallest possible build artifact — typically `swiftc -O bench.swift` (single-file, no SwiftPM, no concurrency-mode default, no entry-point-function-name wrapping, no library-evolution flags). If the gap doesn't reproduce in the smallest isolation, the cause is build-context-conditioned, not code-construct-intrinsic, and the investigation MUST pivot to the build configuration before continuing on the source-construct hypothesis.

**The bisection cascade**:

| Reproduction layer | What it eliminates | What it preserves |
|--------------------|--------------------|--------------------|
| Single-file `swiftc -O bench.swift` | Concurrency mode default, `-entry-point-function-name` wrapping, library-evolution flags, cross-module-optimization state, SwiftPM target shape | Source code, Swift version, optimization level |
| SwiftPM `swift build -c release` minimal package | (above factors come back) | Source code, Swift version, optimization level, package shape |
| SwiftPM full target | (all factors come back) | Source code + full ecosystem build context |

The cascade lets the investigator localize the cause: a phenomenon visible at every layer is source-intrinsic; a phenomenon visible only at SwiftPM layers is build-context-conditioned; a phenomenon visible only in the full target is workspace-state-conditioned (e.g., specific dep version, specific cross-module specialization state).

**Procedure**:

1. When a performance phenomenon is reported at a SwiftPM target, before deep-diving into compiler attributes, runtime mechanisms, or specialization machinery, copy the minimal source construct into a single `.swift` file.
2. Run `swiftc -O bench.swift -o bench && ./bench` (or the equivalent for the metric).
3. Compare the single-file timing to the SwiftPM target timing.
4. If the gap reproduces: the cause is source-construct-intrinsic; continue the investigation on the source axis (compiler attributes, specialization, runtime).
5. If the gap doesn't reproduce: the cause is build-context-conditioned; pivot the investigation to the build configuration axis (concurrency mode, library-evolution, entry-point wrapping, cross-module-optimization).

**Composite with [RES-037] / [RES-013a]**: a handoff brief or research doc may carry BOTH measured values AND a causal explanation. The empirical predictions can be correct while the mechanism explanation is wrong — same-magnitude predictions can fit different mechanisms (a "specialization gap" and an "actor-isolation runtime check" can both predict ~40 ns/element on Apple Silicon — measurement-indistinguishable). The mechanism IS part of the verifiable-claims set per [RES-037]; the smallest-isolation-first reproduction is one of the cheapest mechanism-verification mechanisms available.

**Cross-references**: [RES-013a], [RES-037], [BENCH-001], [EXP-003]

---

### [RES-030] Explicit-Class Enumeration in Taxonomy-Classification Subagent Prompts

**Statement**: When a research dispatch delegates taxonomy classification to subagents (γ-roadmap classes, layer designations, requirement-ID prefix schemes, mechanical/hybrid/semantic verification classes, etc.), the dispatch prompt MUST enumerate the valid class names verbatim AND instruct the subagent to report unmatched cases as "no class" rather than analogizing to the closest existing class. Negative formulations ("do not force-fit") are insufficient — analogical-completion bias activates at the level of operational-shape recognition, before the prompt's negation applies.

**Procedure** (when authoring a subagent prompt for taxonomy classification):

1. Identify the taxonomy classes the subagent must apply (e.g., γ-1a / γ-1b / γ-1c / γ-2 / γ-2b / γ-3 / γ-3b / γ-4).
2. Enumerate the valid class names verbatim in the prompt body, ideally in a list or table; include the per-class scope statement so the subagent has the named-scope criterion, not just the class label.
3. Add an explicit positive instruction: "Only the enumerated classes are valid. If a rule does not match any enumerated class, report 'no class' / leave unmarked. Do NOT extend, reach for analogous classes, or invent new class names."
4. The negative formulation ("do not force-fit") is permitted as supplementary, but MUST appear AFTER the positive enumeration; on its own, it is insufficient.
5. At synthesis time, verify the subagent's output respects the enumeration — strip any class invocations outside the enumerated set as artifacts of analogical-completion bias.

**Failure signature** (when [RES-030] is violated): a subagent reaches for the most analogous existing class for a rule whose body fits the operational shape (e.g., "deterministic scan", "schema audit", "file-presence check") of the closest class but isn't in its named scope. The invented force-fit produces a creative-but-wrong γ classification that requires synthesis-time normalization. At scale (~95 force-fits across 4 of 8 subagents in the canonical incident), normalization adds substantial post-dispatch overhead.

**Composite:** prompt-enumeration check (mechanical) + post-dispatch verify-against-enumeration (mechanical) + synthesis-time strip pass (mechanical).

**Cross-references**: [RES-034] parallel subagent verification.

---

### [RES-031] Independent Verification of Subagent-Reported Version-Pinned Claims

**Statement**: Version-pinned claims relayed from a subagent (changelog entries, release-note text, version numbers tied to behavior) MUST be independently verified before being quoted to the user. Subagent reports can fabricate plausible version numbers and paraphrased changelog lines that are syntactically valid but factually wrong; relaying them with confidence misleads the user. The verification step looks up BOTH the version AND the cited text against the primary source.

**Procedure** (when relaying a subagent's version-pinned claim):

```bash
# For changelog entries — fetch the primary source:
gh api repos/<owner>/<repo>/releases/tags/<version> --jq '.body'
# OR navigate to the canonical changelog URL and verify the line verbatim.
```

If the version OR the text does not match the subagent's report, the subagent fabricated; surface the discrepancy and either (a) re-dispatch the subagent with the primary-source URL, or (b) verify and re-quote the correct text directly.

**Why**: Subagent fabrication of version-pinned claims is a documented failure mode — plausible-looking changelog lines tied to plausible-looking version numbers, both wrong. The cost of independent verification is one CLI call; the cost of relaying the fabrication is misleading the user with confidence and re-doing the analysis when the fabrication is discovered.

**Cross-references**: [RES-037], [RES-026]

---

### [RES-032] Research Notes Cite Verified Primary Sources

**Statement**: Research notes (Tier 1, Tier 2, ad-hoc spikes) MUST cite VERIFIED PRIMARY sources for every claim about runtimes, papers, platform APIs, language features, or compiler behavior. Dreamed-up claims — plausible but unverified citations to runtimes/papers/APIs that don't exist as cited — are FORBIDDEN. Each empirical claim MUST trace to a source the writer has actually read or run.

**Why**: Research notes accumulate authority over time as they're cited from skills, handoffs, and downstream research. A dreamed-up citation calcifies into "established truth" the moment the note is referenced, and undoing it requires tracing every citation chain. Verifying at write-time is one read per claim; un-doing post-hoc is many reads plus retracting downstream claims.

**How to apply**:
- Every "Foo runtime does X" claim in research: cite the runtime's docs, source code, or a verified empirical run.
- Every "Paper Y proves Z" claim: cite the paper with section/page; ideally include a one-line excerpt.
- Every "Platform API Q has Y semantic" claim: cite the platform docs or a verified empirical run.
- If a claim cannot be verified, mark it explicitly as `(unverified)` or `(claim by subagent — needs verification)` rather than asserting it.

**Cross-references**: [RES-037], [RES-038], [RES-031]

---

### [RES-033] Dispatch-Time Skill-Load Gate

**Statement**: Before drafting a research document — or dispatching an executor to draft one — the author MUST map the topic's rule-prefix territory (MEM-SEND, API-NAME, MOD, …) via the CLAUDE.md skill-routing table, LOAD the owning skills, and cite the loaded set in the doc's Context/Constraints section. [RES-004a] requires consulting conventions; this rule makes the load itself a dispatch-time gate.

**Example**: a `Memory.Foreign` design doc's territory maps to **memory-safety** ([MEM-*]), **code-surface** ([API-NAME-*]/[API-ERR-*]), **implementation** ([API-IMPL-*]); its Constraints section cites "Skills loaded: memory-safety, code-surface, implementation."

**Cross-references**: [RES-004a], [RES-019]

---

## Cross-References

See also:
- **experiment-process** skill for validation workflows
- **blog-process** skill for publishing findings
- **code-surface** skill for [API-NAME-*] and [API-ERR-*] conventions
