---
name: swift-linter
description: |
  swift-linter consumer setup: Lint.swift (default), Lint/ (advanced), Bundle.X activation, excluding(rules:), // parent: inheritance.
  Apply when wiring swift-linter into a package or tuning rule activation.

layer: implementation

requires:
  - swift-institute
  - swift-package
  - code-surface

applies_to:
  - swift
  - swift6
  - swift-primitives
  - swift-standards
  - swift-foundations
  - lint

created: 2026-05-18
---

# Swift-Linter Adoption

How a consumer package wires `swift-linter` into its build, activates rule bundles, and tunes the rule set at its own brand boundary. Author-side rule creation (text → AST / workflow validator) is out of scope — this skill covers the consumer surface only.

The two shapes have asymmetric ergonomics: `Lint.swift` (a single file at the package root) is the default and covers >95% of consumer cases; `Lint/` (a SwiftPM nested package) is the advanced shape reserved for cases that single-file cannot express.

---

## Phase A: Consumer Shape

### [LINT-SETUP-001] `Lint.swift` Is the Default Consumer Shape

**Statement**: A consumer package's lint configuration MUST be declared as a single `Lint.swift` file at the package root, alongside `Package.swift`, unless the consumer triggers one of the [LINT-SETUP-002] advanced criteria.

**Canonical shape**:

```swift
// swift-linter-tools-version: 0.1
// (Apache-2.0 license header)

import Linter
import Linter_Institute_Rules    // import the rules pack(s) the bundle pulls in

Lint.run(dependencies: [
    .package(
        path: "../swift-institute-linter-rules",
        products: ["Linter Institute Rules"]
    ),
]) {
    Lint.Rule.Bundle.institute
}
```

**Filesystem position**:

```
your-package/
├── Package.swift
├── Lint.swift          ← here
└── Sources/...
```

**Why default**: `Lint.swift` is a single file, parses with `swift-syntax` alone, requires no nested SwiftPM build, and inherits the parent chain via the `// parent:` directive ([LINT-PARENT-001]). Adding a lint configuration to a new package is one file, not one directory.

**Rationale**: Lint configuration is, for the vast majority of consumer packages, a bundle selection plus a small exclusion list. Both fit cleanly in a single file. Forcing every consumer into a nested-SwiftPM-package shape would impose build overhead (a second `Package.swift`, a second resolve graph, a second build step) without value-add for the common case.

**Cross-references**: [LINT-SETUP-002] (when to switch to advanced), [LINT-SETUP-003] (tools-version), [LINT-BUNDLE-001] (bundle selection), [LINT-PARENT-001] (parent inheritance).

---

### [LINT-SETUP-002] `Lint/` Nested-Package Shape Is the Advanced Escape Hatch

**Statement**: A consumer MAY adopt the `Lint/` nested-SwiftPM-package shape ONLY when one or more of these conditions holds:

| Trigger | Why `Lint.swift` cannot express it |
|---|---|
| In-house custom rules (Swift code defining new `Lint.Rule` instances) | Custom rules need a SwiftPM compilation unit; a single-file `Lint.swift` parses but does not compile arbitrary rule code |
| Third-party rule packs not yet declared in any institute bundle | Activating a non-institute rule pack requires declaring it as a SwiftPM dependency and importing its module — needs `Package.swift` |
| Per-rule programmatic configuration (rule constructor takes domain values from the consumer) | The `Lint.Configuration { Lint.Rule.Configuration.enable(...) }` DSL accepts constructor calls; the bundle DSL is metatype-driven |

If none of these triggers hold, [LINT-SETUP-001] (`Lint.swift` default) applies.

**Filesystem position** (when triggered):

```
your-package/
├── Package.swift
├── Sources/...
└── Lint/
    ├── Package.swift
    └── Sources/Lint/main.swift
```

The nested `Lint/Package.swift` declares the rule-pack dependencies; `Lint/Sources/Lint/main.swift` instantiates `Lint.Configuration { ... }` via the result-builder DSL with fully-qualified `Lint.Rule.Configuration.enable(X.self)` factory calls (leading-dot inference fails at the top-level position per `[IMPL-104]` in `implementation/style.md`).

**Rationale**: The nested-package shape exists for cases that genuinely need SwiftPM's compilation and dependency-resolution machinery. Reaching for it when the default would suffice imposes build cost without surface benefit. Reserving it for the advanced triggers above keeps the default lightweight while preserving the escape hatch for cases that genuinely need it.

**Cross-references**: [LINT-SETUP-001], `implementation/style.md` `[IMPL-104]` (leading-dot inference at top-level result-builder positions).

---

### [LINT-SETUP-003] `swift-linter-tools-version` Directive

**Statement**: Every `Lint.swift` MUST declare the tools-version directive on the FIRST line of the file:

```swift
// swift-linter-tools-version: 0.1
```

The directive informs the engine which DSL version the file targets, mirroring SwiftPM's `swift-tools-version` discipline. Files without the directive are rejected by the parser.

**Position**: line 1, before the license header. The license header follows on lines 2+.

**Rationale**: The DSL is pre-1.0 and admits source-breaking changes at minor-version boundaries (per the swift-linter README §Stability and SemVer). The tools-version directive lets the parser route a file to the correct DSL grammar without inferring from content shape, and lets later DSL versions ship without breaking files pinned to 0.1.

**Cross-references**: [LINT-SETUP-001].

---

### [LINT-SETUP-004] `Lint.run(dependencies:) { ... }` Is the Canonical Lint.swift DSL Entry

**Statement**: The body of a `Lint.swift` file (after directive + license header + imports) MUST be a single `Lint.run(dependencies:) { ... }` call. The `dependencies:` parameter declares the SwiftPM packages whose rule products the file consumes; the trailing result-builder closure declares the active rule set (typically `Lint.Rule.Bundle.X` per [LINT-BUNDLE-001], optionally narrowed via `.excluding(rules:)` per [LINT-EXCLUDE-001]).

**Canonical example** (institute-tier consumer):

```swift
Lint.run(dependencies: [
    .package(
        path: "../swift-institute-linter-rules",
        products: ["Linter Institute Rules"]
    ),
]) {
    Lint.Rule.Bundle.institute
}
```

**Path form vs URL form**: pre-publish, `.package(path: ...)` is the working form. Post-publish (when both packages are tagged and public), the form rotates to `.package(url: ..., from: ...)` per `[PKG-DEP-*]` and `[RELEASE-015]`. Both forms are valid; the path form is for development cycles, the url form is the published consumer surface.

**Multiple dependencies**: when activating rules from more than one tier (e.g., primitives bundle needs both `swift-primitives-linter-rules` and `swift-institute-linter-rules`), each dependency is its own array entry; the product list within each entry enumerates the rule-pack products that file imports.

**Rationale**: The single-call shape makes the file's contract auditable at a glance — one closure, one set of activations. The split between the `dependencies:` parameter (SwiftPM-shape) and the closure body (rule-shape) keeps build-graph declaration separate from rule-activation declaration. Adding a rule pack is two edits: add the dependency, import the module — never a structural rewrite.

**Cross-references**: [LINT-SETUP-001], [LINT-BUNDLE-001], [LINT-EXCLUDE-001], `swift-package` `[PKG-DEP-*]`.

---

### [LINT-SETUP-005] Lint Configuration and Metadata Are All-Swift at Every Layer

**Statement**: Every layer of the swift-linter configuration surface MUST be expressed in Swift. This covers BOTH:

- **Per-run orchestrator configuration** — the `Lint.Configuration` value type (`Linter_Primitives`), authored via the Swift result-builder DSL; and
- **Per-package consumer manifest** — the `Lint.swift` file at each package root (evaluated at runtime under Shape γ per [LINT-SETUP-001]).

Per-package metadata — brand-type lists, allow-lists, rule parameters, exclusions,
and custom-rule activations — MUST ride as ordinary Swift values inside the
consumer's `Lint.swift` (typically as arguments to rule-activation calls). It
MUST NOT live in a `.swift-linter.json`, `.lint-paths.json`, `.yaml`, or any other
sidecar file. JSON/YAML configuration sidecars are forbidden at every layer.
Consumer, package, bundle, and parent/child configuration MUST neither restate
nor override severity. Generated activation and registry records MAY project
the canonical value as evidence. Warning-to-error graduation is recorded in
the canonical rule definition, never in consumer or package configuration.

**When a new rule needs per-package data**: the rule exposes a parameterized initializer that takes the domain values, and each consumer's `Lint.swift` passes them. The eval-project already runs the consumer's `Lint.swift` at runtime, so per-package expressions do NOT need to be syntactically extractable without compilation — the "discoverability from the source tree without running the file" argument does not justify a sidecar.

**Correct**:

```swift
// Per-package brand metadata as Swift values in Lint.swift
Lint.Rule.brandAudit(brands: [Cardinal.self, Ordinal.self])
```

**Incorrect**:

```json
// .swift-linter.json  — ❌ sidecar config file, forbidden at every layer
{ "brands": ["Cardinal", "Ordinal"] }
```

**Rationale**: The all-Swift discipline is load-bearing. The moment one rule introduces a JSON/YAML sidecar for per-package data, the next rule that needs similar data reaches for the same hammer and config-file sprawl follows. Swift gives compile-time safety on rule references (typed symbols, not stringly-typed keys), the module system enforces dependency correctness, and one fewer file format keeps the cognitive surface narrow. [LINT-SETUP-001] fixes the consumer *shape* (a single `Lint.swift`); this rule fixes the *substrate* (Swift, never a sidecar) across every configuration layer.


**Cross-references**: [LINT-SETUP-001] (consumer shape — single `Lint.swift`), [LINT-SETUP-002] (per-rule programmatic configuration via the `Lint.Configuration` DSL), [LINT-SETUP-004] (`Lint.run(dependencies:)` entry point).

---

## Phase B: Bundle Activation

### [LINT-BUNDLE-001] Bundle Activation by Consumer Layer

**Statement**: A consumer activates the bundle matching its layer in the five-layer architecture:

| Consumer layer | Activate | Imports needed |
|---|---|---|
| L1 (Primitives) | `Lint.Rule.Bundle.primitives` | `Linter_Primitives_Rules` (+ per-rule modules per [LINT-BUNDLE-003]) |
| L2 (Standards) | `Lint.Rule.Bundle.standards` | `Linter_Standards_Rules` |
| L3 (Foundations) | `Lint.Rule.Bundle.institute` | `Linter_Institute_Rules` |
| Universal (rules-shape consumer or non-institute Swift code) | `Lint.Rule.Bundle.universal` | `Linter_Rules` |

The universal/institute/primitives bundles compose additively: `institute = universal + institute-pack`; `primitives = institute + primitives-pack`. Activating a higher-tier bundle transitively activates the lower tiers' rules. `Lint.Rule.Bundle.standards` is NOT part of that additive chain — it is a **subtractive bundle-level opt-out** (principal ruling 2026-07-07): `standards = institute − {compound identifier, compound type name}`. L2 Standards packages optimize for 1:1 spec encodings, and identifiers that are deterministic transliterations of spec-defined tokens — per the spec community's own naming convention (W3C CSSOM camelCase like `animationName`/`timingFunction`; IEEE 754 operation names like `roundAwayFromZero`; POSIX symbols) — are spec-mirroring names governed by `code-surface` `[API-NAME-003]`, so `[API-NAME-001]`'s compound-type-name rule and `[API-NAME-002]`'s compound-identifier rule do not mechanically fire at L2 (both rules remain fully active at L1 and L3). Primitives stays routed through institute (`primitives = institute + primitives-pack`) and is NOT layered on top of standards — the two are siblings, not a chain. A consumer activates ONE bundle; multi-bundle activation in the same `Lint.swift` is not the consumer pattern (it's already implicit in the additive/subtractive composition).

**Known enforcement gap**: the standards subtraction is broader than the
semantic exception. It disables both detectors for invented non-spec compound
names as well as legitimate spec-token transliterations. A clean standards
bundle therefore does not prove [API-NAME-001]/[API-NAME-002] conformance; the
requirement remains hybrid until a detector can distinguish spec-mirroring
tokens from invented compounds.

**Where rules live** (which tier a rule belongs to): rule PLACEMENT is an author-side decision. This rule covers only the consumer-side activation decision. Placement and consumer activation MUST stay consistent — if a rule moves between tiers (e.g., `[PRIM-FOUND-001]` moved from primitives to institute mid-pilot), the consumer's bundle activation may change accordingly.

**Rationale**: The layer-to-bundle mapping is mechanical: a consumer's layer determines the broadest applicable rule set. Manually composing rule packs at the consumer level would re-litigate placement decisions made authoritatively in the rule-promotion phase and produce inconsistent consumer surfaces. The standards-tier subtraction is the one deliberate exception: L2's job is 1:1 spec fidelity, and two of the institute-tier naming rules actively fight that job when the spec itself dictates compound-shaped tokens.

**Cross-references**: [LINT-SETUP-004], [LINT-BUNDLE-002], [LINT-BUNDLE-003], `swift-institute` `[ARCH-LAYER-*]` (five-layer architecture), `code-surface` `[API-NAME-001]`, `[API-NAME-002]`, `[API-NAME-003]` (L2 spec-token-transliteration exception, principal ruling 2026-07-07).

---

### [LINT-BUNDLE-002] Bundle Composition Is Additive — Do Not Duplicate Rules

**Statement**: A consumer's `Lint.swift` MUST NOT manually enumerate rules that are already members of the activated bundle. Activating `Bundle.institute` AND then explicitly enabling individual `[API-NAME-*]` rules is a redundant configuration that risks drift when the bundle gains or loses members.

**Allowed**: bundle activation plus `.excluding(rules:)` for the brand-owner subtraction case per [LINT-EXCLUDE-001].

**Not allowed**: bundle activation plus manual `.enable(...)` calls for rules the bundle already carries.

**Rationale**: The bundle IS the canonical declaration of which rules apply at a tier. Manually re-listing bundle members at the consumer creates two sources of truth — the bundle definition and the consumer's enumeration — which drift independently. The exclusion case is the inverse: it's a subtraction from a known superset, with the brand-boundary justification explicit at each excluded rule.

**Cross-references**: [LINT-BUNDLE-001], [LINT-EXCLUDE-001].

---

### [LINT-BUNDLE-003] Per-Rule Module Imports Under SE-0444 MemberImportVisibility

**Statement**: Under Swift 6.3+ `MemberImportVisibility` (SE-0444), each rule referenced by name in `Lint.swift` (including inside `.excluding(rules:)` lists) MUST have its declaring module directly imported. Transitive imports through `Linter_Primitives_Rules` no longer expose the leaf rule's identifier — only umbrella imports cover the umbrella; leaf-rule references need leaf-module imports.

**Concrete shape** (from `swift-cardinal-primitives/Lint.swift` lines 42-49):

```swift
import Linter
import Linter_Primitives_Rules         // umbrella for bundle activation
import Institute_Linter_Rule_Memory    // leaf for `unchecked call site`
import Institute_Linter_Rule_Naming    // leaf for `nested tag`, etc.
import Institute_Linter_Rule_Structure // leaf for `single type per file`
import Institute_Linter_Rule_Unchecked // leaf for `unchecked sendable`
import Institute_Linter_Rule_Cardinal  // leaf for `zero or one literal`, etc. (A5 move 2026-07-07)
import Institute_Linter_Rule_RawValue  // leaf for `bitpattern rawvalue chain` (A5 move 2026-07-07)
```

The umbrella covers the BUNDLE; each leaf module covers the rules referenced by name in the `excluding(rules:)` list.

**Detection of missing imports**: `error: cannot find 'Lint.Rule.<name>' in scope`, or worse — silent inference of a different identifier. The fix is always: add the leaf-module import.

**Rationale**: SE-0444 closed the transitive-imports loophole; the fix preserves the principle (modules are import-scoped) at the cost of more import lines in consumer files. The consumer pays one import per exclusion-set vocabulary item — small, mechanical, no semantic surprise.

**Cross-references**: [LINT-SETUP-004], [LINT-EXCLUDE-001], `swift-package` `[PKG-DEP-*]`.

---

## Phase C: Brand-Owner Exclusions (Shape γ)

### [LINT-EXCLUDE-001] `excluding(rules:)` Vocabulary at Brand-Owner Packages

**Statement**: A package that owns a brand vocabulary (a typed primitive whose rules target external consumers' access to the brand) MUST narrow its activated bundle via `.excluding(rules:)` to subtract the rules that fire on the brand-owner's own surface. The rule corpus is brand-form-agnostic by design — each rule targets the brand-boundary, which fires on EXTERNAL consumers AND on the brand-owner's own internal use, even though only the external-consumer firing is the intended target.

**Canonical example** (cardinal-primitives — value-form brand-owner):

```swift
Lint.Rule.Bundle.primitives.excluding(rules: [
    Lint.Rule.`raw value access`.id,
    Lint.Rule.`chained rawvalue access`.id,
    Lint.Rule.`int public parameter`.id,
    Lint.Rule.`pointer advanced by`.id,
    Lint.Rule.`bitpattern rawvalue chain`.id,
    Lint.Rule.`unchecked call site`.id,
    Lint.Rule.`zero or one literal`.id,
])
```

Each excluded rule is referenced by `.id` (the rule's stable identifier). The seven exclusions above carve out the cardinal brand-owner's own surface so the same rules continue to fire on external `Cardinal` consumers (cross-package strict-superset firing).

**Where the vocabulary is codified**: `[API-BRAND-001]` in `code-surface/SKILL.md` carries the brand-owner vocabulary; this rule carries the linter-side application. The vocabulary side names which RULES fire at the brand boundary; the linter-side names how a brand-owner subtracts them.


**Cross-references**: [LINT-EXCLUDE-002], [LINT-EXCLUDE-003], [LINT-EXCLUDE-004], [LINT-BUNDLE-003] (leaf-module imports for the excluded rules), `code-surface` `[API-BRAND-001]` (brand-owner vocabulary).

---

### [LINT-EXCLUDE-002] Protocol-Form Brand-Owner Exclusion Cardinality

**Statement**: A protocol-form brand-owner (a package whose brand is a `.Protocol` capability marker per `code-surface` `[API-NAME-001c]`) excludes exactly ONE rule from its activated bundle. The canonical case is `swift-carrier-primitives`, which excludes the single rule that fires on protocol-witness adoption at the brand boundary.

The 1-rule cardinality is empirical — the protocol-form brand only owns one boundary shape, so only one rule targets that boundary. Protocol-form brand-owners with `> 1` exclusion are a signal to re-examine: either the brand has unexpected boundary shapes (potential design defect) or the exclusion list is over-broad (potential over-subtraction).

**Rationale**: Protocol-form brands extend the type system at the protocol layer (witness adoption), which has a narrow boundary surface (the witness slot). Value-form brands extend at the value layer (typed initialization, raw-value access, integer parameter overloads), which has multiple boundary surfaces — hence value-form's higher exclusion cardinality per [LINT-EXCLUDE-003].

**Cross-references**: [LINT-EXCLUDE-001], [LINT-EXCLUDE-003], `code-surface` `[API-NAME-001c]` (capability-marker protocol).

---

### [LINT-EXCLUDE-003] Value-Form Brand-Owner Exclusion Cardinality

**Statement**: A value-form brand-owner (a package whose brand is a typed value vocabulary like `Cardinal`, `Ordinal`, `Cyclic`, `Byte`) excludes a per-brand subset of an 8-rule vocabulary covering the value-form boundary shapes:

| Brand | Empirical exclusion count | Reference |
|---|---|---|
| `Cardinal` | 7 | `swift-cardinal-primitives/Lint.swift` |
| `Ordinal` | 5 | `swift-ordinal-primitives/Lint.swift` |
| `Cyclic` | 3 | `swift-cyclic-primitives/Lint.swift` |
| `Byte` | (TBD as byte-arc consolidates) | `swift-byte-primitives/Lint.swift` (forthcoming) |

The variance is principled: each brand owns a different subset of the boundary shapes (some brands have no integer-parameter overloads, some don't expose pointer arithmetic, etc.). The empirical exclusion count is the EXACT subset that fires on the brand-owner's own surface — not a default subset, not a maximal subset.

**Procedure for a new value-form brand-owner**:

1. Activate `Lint.Rule.Bundle.primitives` (or `.institute` if L2/L3) with NO exclusions.
2. Run the linter; observe which rules fire on the brand-owner's own surface.
3. Add each firing rule to the `excluding(rules:)` list with a one-line justification (per [LINT-EXCLUDE-004]).
4. Re-run; verify clean. Any remaining firings are legitimate violations to fix, not exclusion candidates.

**Rationale**: The value-form vocabulary is wider because typed values participate in more language surfaces than typed protocols (literals, arithmetic, integration overloads, raw access, conversions). Each brand's empirical exclusion subset is its own boundary fingerprint; standardizing to a default subset would either over-subtract (silencing real rule firings) or under-subtract (leaving the brand-owner's own surface flagged).

**Cross-references**: [LINT-EXCLUDE-001], [LINT-EXCLUDE-002], [LINT-EXCLUDE-004], `code-surface` `[API-BRAND-001]`.

---

### [LINT-EXCLUDE-004] Each Excluded Rule Cites Its Brand-Boundary Justification

**Statement**: Every `excluding(rules:)` entry MUST have an in-file comment justifying WHY the brand-owner subtracts that specific rule from its activated bundle. The comment names the boundary shape the rule targets and confirms the brand-owner's own surface is the legitimate-by-construction case the rule was not designed to flag.

**Canonical comment block** (from `swift-cardinal-primitives/Lint.swift` lines 13-33):

```swift
// Shape-γ unified consumer manifest. swift-cardinal-primitives owns the
// `Cardinal` brand-newtype, so seven consumer-side recognizer rules fire
// on legitimate-by-construction same-package access at the brand's
// boundary:
//
//   - `raw value access` — `.rawValue` accessor on the brand surface
//   - `chained rawvalue access` — `.rawValue.<method>` patterns at the
//     same boundary
//   - `int public parameter` — `Int`-parameter integration overloads
//     bridging the brand to the stdlib boundary
//   ...
//
// Excluding these seven rules locally preserves cross-package strict-
// superset firing.
```

**Why the justification matters**: an exclusion silently subtracts a rule's firing at this consumer. Six months from now, a reader inspecting the `Lint.swift` needs to know whether each exclusion is a brand-boundary carve-out (legitimate) or a forgotten cleanup item (an excluded rule that SHOULD fire and the exclusion is stale). The justification comment makes the distinction local to the exclusion site.

**Rationale**: Lint exclusions accumulate. Without per-entry justification, a `.excluding(rules:)` list of 7 rules becomes a black box — no reader can audit whether each entry is still load-bearing. The justification comment makes each exclusion individually auditable; review reduces to checking that each cited boundary still holds.

**Cross-references**: [LINT-EXCLUDE-001], [LINT-EXCLUDE-003].

---

## Phase D: Parent-Chain Inheritance

### [LINT-PARENT-001] `// parent:` Directive Position

**Statement**: A `Lint.swift` file MAY declare ONE `// parent:` directive in the first 30 lines. The directive's value is a URL pointing to another `Lint.swift` (or `Lint/Sources/Lint/main.swift`) that this file inherits from.

**Canonical shape**:

```swift
// swift-linter-tools-version: 0.1
// parent: https://raw.githubusercontent.com/swift-institute/.github/main/Lint.swift
// (Apache-2.0 license header)

import Linter
// ...
```

The directive name is `parent:`; the value is the URL; the comment-line marker is the standard `//` line comment. The first 30 lines is the parsing window (the engine does not scan the entire file looking for the directive).

**Rationale**: The first-30-lines window bounds the parser's scan cost while leaving room for the tools-version directive, license header, and brief file-purpose comment. Multiple `// parent:` directives in one file would create ambiguous inheritance; the constraint is one parent per file.

**Cross-references**: [LINT-PARENT-002], [LINT-PARENT-003], [LINT-PARENT-004], [LINT-PARENT-005].

---

### [LINT-PARENT-002] Accepted URL Schemes

**Statement**: The `// parent:` directive accepts three URL schemes:

| Scheme | Use case |
|---|---|
| `https://` | Production — the canonical org-pointer pattern per [LINT-PARENT-005] |
| `http://` | Discouraged; permitted only for explicit non-TLS testbeds |
| `file://` | Local development — point at a sibling clone's `Lint.swift` for offline iteration |

The driver fetches the parent via `curl`, memoized per process. On fetch failure (network error, 404, schema mismatch), the driver emits a warning and falls back to the consumer-only configuration — the parent chain is best-effort, not blocking.

**Rationale**: The three schemes cover the three deployment contexts (production HTTPS, legacy/test HTTP, local file). Best-effort fallback prevents a network blip from blocking a lint run — the consumer's own rules always apply; only the inherited rules are at risk.

**Cross-references**: [LINT-PARENT-001], [LINT-PARENT-003].

---

### [LINT-PARENT-003] Cycle Detection and Depth-16 Backstop

**Statement**: The parent-chain resolver detects cycles (a file that transitively inherits from itself) and bounds traversal at 16 hops. Both conditions emit a warning and stop the chain walk at the offending boundary; rules accumulated up to that point still apply.

**Cycle case**: `A → B → A` is detected at the second visit to `A`; the second visit's rules do not re-apply (they're already in the accumulated set). The walk stops with a warning.

**Depth backstop**: `A → B → C → ... → P` (16 deep) stops at `P`; the 17th hop is not attempted. A legitimate chain rarely exceeds 3 hops (consumer → org → ecosystem); 16 is a generous safety margin that catches runaway pathological chains.

**Rationale**: A parent chain is a directed-acyclic-graph in normal use. Cycles arise from misconfiguration (typically a forked `Lint.swift` that points back to the parent it copied from). The detection + warning is the recovery — the chain stops, the consumer is alerted, the configuration still loads. The depth backstop catches the same class of misconfiguration when the cycle is wider than the immediate two hops.

**Cross-references**: [LINT-PARENT-001], [LINT-PARENT-002], [LINT-PARENT-004].

---

### [LINT-PARENT-004] Later-Layer-Wins Override Semantics

**Statement**: When a parent and child both specify a per-rule parameter or
exclusion, the CHILD's value wins. The parent provides the default and the child
specializes. This rule does not authorize severity graduation: a child MUST NOT
promote a canonical `.warning` rule to `.error`. Error severity comes only from
the canonical rule definition.

**Concrete cases**:

| Parent says | Child says | Effective |
|---|---|---|
| Rule X enabled at `.warning` | Rule X enabled at `.error` | invalid, noncanonical override |
| Rule X enabled | Rule X excluded via `.excluding(rules:)` | excluded (child wins) |
| Rule X not present in parent's bundle | Rule X explicitly enabled in child | enabled (child adds) |
| Rule X enabled in parent | Rule X not mentioned in child | enabled (parent provides default) |

**Walking direction**: the resolver walks parent → child, applying overrides at each layer; the child is the LAST layer, hence "later-layer-wins". A grandparent's setting is overridden by a parent's setting which is overridden by the child's setting.

**Rationale**: Inheritance exists so that org-canonical rules can be specified
once at the parent and reused across all consumers, while individual consumers
retain the ability to specialize parameters and exclusions for their context.
Allowing a child to turn a warning into an error would make the consumer config
a second policy source and bypass the objective graduation evidence gate.

**Cross-references**: [LINT-PARENT-001], [LINT-PARENT-005].

---

### [LINT-PARENT-005] Canonical Org-Pointer URL Form

**Statement**: An organization's canonical lint configuration SHOULD live at the raw URL of its `.github` repo's main-branch `Lint.swift`:

```
https://raw.githubusercontent.com/<your-org>/.github/main/Lint.swift
```

This is the conventional pointer that consumer packages in the org reference via `// parent:`. It mirrors SwiftLint's `parent_config:` cascade pattern at the file layer.

**Concrete examples** (Swift Institute ecosystem):

| Tier | URL | Provides |
|---|---|---|
| Tier 1 (ecosystem-wide) | `https://raw.githubusercontent.com/swift-institute/.github/main/Lint.swift` | Universal rules every institute package inherits |
| Tier 2 (primitives) | `https://raw.githubusercontent.com/swift-institute/swift-primitives/main/.github/Lint.swift` (or equivalent primitives-org pointer) | Primitives-tier rules for L1 packages |
| Consumer | per-package `Lint.swift` | Inherits via `// parent: <Tier 2 URL>` for L1 packages, or `<Tier 1 URL>` for L2/L3 |

**Why the `.github` repo**: every GitHub org has a `.github` repo for org-level community-health files (CONTRIBUTING, SECURITY, etc.). Hosting `Lint.swift` there gives it a stable, single-file URL with no nesting under `Sources/` and no SwiftPM build to traverse.

**Rationale**: A conventional pointer URL means a new consumer in the org knows where to point its `// parent:` without bespoke configuration. The `.github`-repo-at-main-branch pattern is durable across renames and refactors because the `.github` repo is owned at the org level, not the per-project level.

**Cross-references**: [LINT-PARENT-001], [LINT-PARENT-002].

---

## Phase E: Cohort Reference

### [LINT-COHORT-001] Five-Package Cohort — Authoritative Source Is the Engine README

**Statement**: `swift-linter` factors across five sibling packages (engine L3, default rules L3, manifests L3, manifest-primitives L1, linter-primitives L1). The authoritative description of the cohort's package layering, role table, and dependency direction lives in `swift-foundations/swift-linter/README.md` §Five-package cohort.

This skill does NOT duplicate the cohort description. A consumer wiring `Lint.swift` interacts with the cohort only via the SwiftPM dependency declared in `Lint.run(dependencies:)` (per [LINT-SETUP-004]) — the internal layering is transparent.

**When the cohort matters to consumers**: extremely rare. Consumer packages depend on `swift-linter` (the engine) and one or more rule packs; the L1 primitive packages (`swift-manifest-primitives`, `swift-linter-primitives`) are pulled in transitively and do not require explicit consumer awareness.

**When the cohort matters to authors**: when promoting a new rule, placement decides which of the three rule packs (`swift-linter-rules`, `swift-institute-linter-rules`, `swift-primitives-linter-rules`) the new rule lands in.

**Rationale**: The cohort is the linter's own internal architecture; consumers and authors interact with it through different surfaces (consumer: dependency declaration; author: placement decision). Surfacing the full cohort description in this skill would duplicate the engine README's authoritative content; the cross-reference preserves single-source-of-truth.

**Cross-references**: [LINT-SETUP-004].

---

## Phase F: Suppression Directive Discipline

### [LINT-SUPPRESS-001] `swift-linter:` Suppression Directives Must Match the Engine Grammar

**Statement**: A `swift-linter:` suppression directive MUST be written as `// swift-linter:disable:next <rule-id>` or `// swift-linter:disable:line <rule-id>` with a non-empty rule id; no block form and no `enable` form exist — malformed forms are silently inert (the targeted finding is NOT suppressed).

**Enforcement**: Mechanical — `Lint.Rule.Suppression.Malformed` (`malformed suppression directive`, universal tier; /promote-rule 2026-07-07). Scope is the engine's own `swift-linter:` namespace only; `swiftlint:` directive validity (unknown-rule / blanket forms) is SwiftLint's own concern (`superfluous_disable_command` / `blanket_disable_command`), and rule-id existence needs the run registry — both out of the per-file AST rule's scope. Discipline: `Audits/PROMOTE-malformed-suppression-directive-2026-07-07.md`. [VERIFICATION: AST]

**Cross-references**: [LINT-BUNDLE-001] (universal bundle activation).

---

## Post-Setup Checklist

- [ ] `Lint.swift` exists at the package root (NOT under `Sources/`) per [LINT-SETUP-001]
- [ ] Line 1 is `// swift-linter-tools-version: 0.1` per [LINT-SETUP-003]
- [ ] `// parent:` directive present in first 30 lines (if inheriting from an org-canonical parent) per [LINT-PARENT-001]
- [ ] Single `Lint.run(dependencies:) { ... }` call in the body per [LINT-SETUP-004]
- [ ] Activated bundle matches consumer layer per [LINT-BUNDLE-001]
- [ ] No manual `.enable(...)` calls duplicating bundle members per [LINT-BUNDLE-002]
- [ ] Per-rule leaf-module imports for each rule referenced by name per [LINT-BUNDLE-003]
- [ ] If brand-owner: `.excluding(rules:)` list narrows the bundle per [LINT-EXCLUDE-001]
- [ ] Each exclusion has a justification comment per [LINT-EXCLUDE-004]
- [ ] No JSON/YAML config sidecar — all configuration and metadata is Swift per [LINT-SETUP-005]
- [ ] `/Users/coen/Developer/swift-institute/Scripts/swift-build lint --package-path <consumer>` runs clean (or surfaces only intended violations)

## Local Invocation

Lint locally through the coordinator's `lint` subcommand
(`swift-package-build` `[PKG-BUILD-025]`):

```bash
/Users/coen/Developer/swift-institute/Scripts/swift-build lint \
  --package-path /absolute/consumer/package
```

The coordinator caches the dispatcher + standard-runner binaries machine-wide
(keyed on engine + rule-pack HEADs + compiler) and provisions
`SWIFT_LINTER_RUNNER` / `SWIFT_LINTER_PATH` per run. Pure-bundle consumers
([LINT-BUNDLE-001] shapes, with or without `.excluding(rules:)`) lint warm in
about a second via the baked runner; inline-rule consumers, non-baked bundles,
and `--format sarif` take the eval fallback, whose `.swift-lint/eval` project
the coordinator auto-refreshes when the rule sources or `Lint.swift` moved.
Rule-pack changes must be COMMITTED to be seen (the digest and mirror
resolution both read HEAD). The legacy
`swift-build package run --package-path <swift-linter> -- swift-linter <consumer>`
form remains valid but serializes all lints on the swift-linter root.

---

## Cross-References

### Within ecosystem

- **code-surface** ([API-BRAND-001]) — brand-owner exclusion vocabulary lives here; [LINT-EXCLUDE-*] carries the linter-side application.
- **code-surface** ([API-IMPL-006]) — file-naming enforcement uses `validate-file-naming.py`, a workflow validator that runs alongside `Lint.swift` in CI.
- **code-surface** ([API-NAME-001c]) — capability-marker protocol; [LINT-EXCLUDE-002] cites it for protocol-form brand-owner exclusion cardinality.
- **swift-package** ([PKG-DEP-*]) — `path:` vs `url:` form rotation for `Lint.run(dependencies:)`.
- **ci-cd-workflows** ([CI-*]) — per-package CI invokes the linter executable against the consumer's `Lint.swift`; local reproduction uses `swift-build lint`.
- **swift-package-build** ([PKG-BUILD-025]) — the coordinator's `lint` subcommand: machine-wide binary cache, consumer-root locking, eval auto-refresh.
- **implementation/style.md** ([IMPL-104]) — leading-dot inference at top-level result-builder positions (relevant to advanced `Lint/` shape).

### Related research

- `swift-foundations/swift-linter/README.md` — canonical engine docs; cohort architecture, two-shape posture, parent-chain semantics
- `swift-institute/Research/three-tier-linter-rules-partition.md` — three-tier rules architecture (the WHY behind universal/institute/primitives)
- `swift-foundations/swift-linter-rules/Research/numerics-rule-recognizer-2026-05-12.md` — Shape γ rationale (Option 7: rule decomposition via bundle composition)
- `swift-institute/Research/2026-05-07-swift-linter-consumer-syntax.md` — DSL evolution history
- `swift-institute/Research/2026-05-12-swift-linter-unified-consumer-manifest.md` — unified consumer manifest design
- `swift-institute/Research/2026-05-07-single-file-lint-swift-deprecation-decision.md` — historical context on the single-file vs nested-package decision (note: superseded 2026-05-18 — `Lint.swift` is the consumer default, `Lint/` is the advanced shape; the swift-linter README §Two consumer shapes + §Internal model document the principle that `Lint/` remains the canonical internal implementation that `Lint.swift` is built on top of)
- `swift-institute/Research/swift-linter-launch-skill-incorporation-backlog.md` — cohort launch backlog (this skill closes the consumer-setup ownership gap that the backlog never assigned)

### Audit / handoff

- `swift-institute/Audits/2026-05-07-swift-linter-cohort-independent-audit.md` — cohort independent audit synthesis
- `swift-institute/Audits/COHORT-TRIAGE-POST-ENGINE-FIX-2026-05-15.md` — per-package exclusion vocabulary empirical data
