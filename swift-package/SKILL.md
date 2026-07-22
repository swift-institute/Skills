---
name: swift-package
description: |
  Package/namespace naming (noun-form, gerund-as-capability-typealias) and cross-repo dep form (path pre-publish, URL post-tag).
  ALWAYS apply when creating/renaming a package, choosing a namespace, or declaring a sibling-repo dep.

layer: architecture

requires:
  - swift-institute

applies_to:
  - swift
  - swift6
  - swift-primitives
  - swift-standards
  - swift-foundations

created: 2026-04-21
---

# Swift Package Naming

This skill governs the naming of Swift Institute packages and their
top-level namespaces. It extends the Nest.Name discipline in **code-surface**
([API-NAME-001]) with a specific rule for the outermost level: the domain
name of a package and its namespace.

---

## Core Rule

### [PKG-NAME-001] Noun Form for Packages and Namespaces

**Statement**: Package names and the top-level Swift namespace declared by
a package MUST use the **noun** form. Gerund forms (words ending in `-ing`
denoting an activity or process) are FORBIDDEN at package and namespace
level.

**Correct**:

```swift
// Package: swift-render-primitives
// Namespace:
public enum Render {}

// Package: swift-format-primitives
public enum Format {}

// Package: swift-position-primitives
public enum Position {}

// Package: swift-order-primitives
public enum Order {}
```

**Incorrect**:

```swift
// Package: swift-rendering-primitives  ❌ gerund
public enum Rendering {}                // ❌ gerund namespace

// Package: swift-formatting-primitives ❌ gerund
public enum Formatting {}               // ❌ gerund namespace
```

**Rationale**: Apple, Rust, Haskell, and Go all use nouns for package and
module names. None uses gerunds as the primary form. The Swift Institute's
historical drift toward gerund forms for a handful of primitives
(`Rendering`, `Formatting`, `Positioning`, `Ordering`) is out of step with
every adjacent ecosystem and creates ambiguity for new package authors. A
uniform noun rule aligns the ecosystem with Apple's SwiftUI / Foundation /
UIKit naming pattern and makes package naming mechanical.

**Which noun — machine vs relation (clarified 2026-05-26).** For *operation
domains* (packages whose primary export is a verb-derived capability — see
`operation-domain-naming-and-organization.md`), the noun is chosen by sub-class:

- a **stateful stream-processing machine** (carries per-step state you drive —
  parse, iterate, serialize, format, lex, cursor) takes the **agent noun**:
  `Parser`, `Iterator`, `Serializer`, `Formatter`, `Lexer`, `Cursor`;
- a **stateless relation / value** (hash, compare, render-as-result) takes the
  **deverbal or plain noun**: `Hash`, `Comparison`, `Equation`, `Render`.

The agent noun is the *only universally available* form for the machine class
(`Cursor` has no gerund and no distinct deverbal noun), so it anchors the class.
Consequently there is **no deverbal-noun namespace for a machine**: `Iteration`
is *not* the iterator namespace and `Parsing` is *not* the parser namespace —
the machine namespace is the agent noun, and the deverbal noun (where it exists)
is reserved for the witness alias per [PKG-NAME-015].

**Package-level register (2026-06-13)**: the machine *package* takes the same
agent noun as its namespace — the 2026-06-12 domain-over-object proposal
(`swift-iteration-primitives`-class renames) was evaluated and REJECTED; see
[PKG-NAME-017] and `package-naming-domain-vs-object.md` v2.0.0.

**Lint enforcement (DEFERRED, 2026-05-14 pilot 8 of `/promote-rule`)**: sound principle with live FAIL instances (`swift-translating`, `swift-numeric-formatting-standard`, `swift-standards/Sources/Parsing/Parsing.swift:65 enum Parsing {}`), but the `-ing`-suffix boundary is unbounded — legitimate `-ing` nouns (`Ring`, `Semiring`, `String`) and external-compat names (`swift-testing` per `[PKG-NAME-003]`) must be discriminated from gerunds. Re-promotable once a curated gerund denylist is authored OR the 3 candidate live violations are dispositioned. Outcome: `swift-institute/Audits/PROMOTE-PKG-NAME-001-2026-05-14.md`.

**Cross-references**: [PKG-NAME-002], [PKG-NAME-005], [PKG-NAME-017], [API-NAME-001]

---

### [PKG-NAME-002] Canonical Capability Protocol

**Statement**: The canonical capability protocol of a namespace MUST be
declared as `Namespace.\`Protocol\`` (backtick-escaped, because `Protocol`
is reserved in Swift). A top-level `typealias` MUST export the gerund
reading so conformance sites can read as English.

**Correct**:

```swift
public enum Render {
    public protocol \`Protocol\`<Input, Output>: ~Copyable {
        // ...
    }
}

public typealias Rendering = Render.\`Protocol\`

// Usage
struct MyView: Rendering { ... }                // reads as English
struct MyView: Render.\`Protocol\` { ... }       // equivalent; preferred in library code
```

**Incorrect**:

```swift
public enum Rendering {}                        // ❌ gerund namespace; violates [PKG-NAME-001]
public protocol Rendering { ... }               // ❌ module-scope protocol; not nested in namespace

public enum Render {}
public protocol RenderProtocol { ... }          // ❌ compound name; violates [API-NAME-002]

public enum Render {
    public typealias Rendering = Self.\`Protocol\`  // ❌ nested; should be top-level for English reading
}
```

**Rules for the typealias**:

- The typealias is declared at the agent noun's **enclosing scope**, not nested
  inside the namespace. For a **root** namespace that scope is module-root
  (`Rendering`, not `Render.Rendering`); for a **subject-nested machine** it is
  the subject's namespace (`Memory.Allocating` for `Memory.Allocator` — NOT a
  bare top-level `Allocating`, and NOT `Memory.Allocator.Allocating`). This
  preserves the English reading at conformance sites (`T: Rendering`,
  `…: Memory.Allocating`).
- The typealias targets `Namespace.\`Protocol\``, never a specific
  sub-protocol. Non-canonical protocols (e.g., `Render.View`) do NOT
  receive gerund typealiases.
- If the namespace has no meaningful single "canonical capability"
  protocol, the typealias MAY be omitted. The namespace still follows
  [PKG-NAME-001].

**Active vs passive — the protocol pair (clarified 2026-05-26).** The
`Namespace.\`Protocol\`` + gerund-typealias is the **active** capability — the
protocol the *machine* conforms to ("a parser *is* parsing"). For operation
domains it is paired with a **passive** attachment protocol: a top-level `-able`
adjective the *value* conforms to ("an `Int` *is* parseable"), declaring its
canonical machine (`Parseable`, `Iterable`, `Serializable`). Active (`-ing`)
names the doer; passive (`-able`) names the done-to. The type-erased witness of
the active protocol is governed separately by [PKG-NAME-015]. See
`operation-domain-naming-and-organization.md` §4.

**Rationale**: The `Namespace.\`Protocol\`` pattern is already load-bearing
across `swift-parser-primitives` (`Parser.\`Protocol\``),
`swift-array-primitives` (`Array.\`Protocol\``), `swift-algebra-*-primitives`
(`Algebra.Field.\`Protocol\``, `Algebra.Group.\`Protocol\``,
`Algebra.Monoid.\`Protocol\``, `Algebra.Magma.\`Protocol\``), and
`swift-affine-primitives` (`Affine.Discrete.Vector.\`Protocol\``). The
gerund-typealias layer is strictly additive: it gives a grammatical English
reading at conformance sites without losing the noun discipline of the
namespace or the generic-constraint clarity of the nested protocol name.

**Enforcement**: TEXT-ONLY (linguistically unbounded, /promote-rule 2026-07-06) — the gerund-alias mandate is conditional on gerund existence (24 of 30 live `\`Protocol\`` namespaces are nouns with no gerund form); re-promotable via the curated gerund list [PKG-NAME-001] also awaits: `Audits/PROMOTE-PKG-NAME-002-2026-07-06.md`.

**Cross-references**: [PKG-NAME-001], [PKG-NAME-006], [API-NAME-001],
[API-NAME-002], [PKG-NAME-015]

---

### [PKG-NAME-015] Witness — `Namespace.Witness` with a Gated Result-Noun Alias

**Statement**: The type-erased, closure-backed value that conforms to a
namespace's active capability protocol (the **witness**) MUST be declared
**nested** as `Namespace.Witness` (e.g., `Parser.Witness`, `Iterator.Witness`).
A single top-level alias naming the witness by the operation's **result-noun**
MAY be added — and is exempt from `[API-NAME-004a]`'s rename-bridge prohibition —
iff ALL four gates hold: (1) it is the deverbal result-noun of the operation
(`iterate → Iteration`, `serialize → Serialization`), not a gerund or bare verb;
(2) it is a first-class English noun; (3) it is free in the ecosystem (does not
shadow a stdlib type or another package's namespace); (4) it is the only alias
for that witness. Where no noun clears the gates, the witness has no alias and
consumers use `Namespace.Witness`.

**Correct**:

```swift
extension Iterator {
    public struct Witness<Element, Failure: Swift.Error>: Iterator.\`Protocol\` { ... }
}
public typealias Iteration = Iterator.Witness        // ✓ gates clear (clean, free noun)
// parse:   Parser.Witness,   NO alias — "parse" is verb-only (gates 1–2 fail)
// format:  Formatter.Witness, NO alias — "Format" is taken by the descriptor namespace (gate 3)
```

**Incorrect**:

```swift
public struct Parse<...>: Parser.\`Protocol\` { ... }      // ❌ top-level bare-verb witness (superseded)
public struct Iterate<...>: Iterator.\`Protocol\` { ... }  // ❌ ditto
```

**Terminology**: "witness" here is the type-erased struct. Named canonical
*instances* (static properties such as `UInt32.bigEndianParser`) are instances,
not the witness type.

**Rationale**: nesting under the (non-generic `enum`) namespace incurs no
generic-binding tax, so the prior top-level-verb placement bought nothing while
reintroducing collisions (`Format` vs the descriptor namespace, `Sequence` vs
`Swift.Sequence`) and forcing a method-stem-divergence exception. `X.Witness` is
uniform and collision-free. The result-noun alias is the witness-side twin of
[PKG-NAME-002]'s gerund protocol alias: the gerund names the capability you
*conform to*; the result-noun names the value you *hold*.

**Generic (tower) nests**: when the agent-noun is modelled as a *generic* struct
directly under a non-generic root namespace (`Memory.Allocator<Resource>` under
`enum Memory`) rather than as a non-generic `enum` with a separate nested
`.Witness`, the witness IS that generic struct, and its active protocol is
exposed as `Namespace.\`Protocol\`` via the [API-IMPL-009] hoist (the struct
conforms via the hoisted name; consumers use `Namespace.\`Protocol\``). See
code-surface [API-IMPL-023]. The result-noun (`Allocation`) stays reserved by
this rule and MUST NOT be spent as the protocol's namespace. `[Verified: 2026-06-22]`
swiftc 6.3.2.

**Backward compatibility**: BREAKING — supersedes the prior top-level-verb
witness convention (`Parse` / `Iterate` / `Sequence<E>`). Authorized by the
principal 2026-05-26.

**Enforcement**: TEXT-ONLY (judgment alias gates; nesting slice uncalibrated — zero live top-level-Witness violations, compound shapes covered by `Lint.Rule.Naming.CompoundType`; /promote-rule 2026-07-06): `Audits/PROMOTE-PKG-NAME-015-2026-07-06.md`.

**Cross-references**: [PKG-NAME-002], [PKG-NAME-006], [API-NAME-004a],
**code-surface** [API-IMPL-023] / [API-IMPL-009] (generic tower nests),
`operation-domain-naming-and-organization.md` §5, §6.1

---

### [PKG-NAME-003] External-Compatibility Exception

**Statement**: When a package MUST share a name with an external,
named, non-Institute package (e.g., Apple's `swift-testing`, the
community `swift-distributed-tracing` lineage), the external name MAY
be retained as the **package name** even if it is a gerund. The internal
namespace MUST still follow [PKG-NAME-001].

**Correct**:

```swift
// Package: swift-testing  (name retained for external compat with Apple's swift-testing)
// Internal namespace still follows noun rule:
public enum Test {
    public protocol \`Protocol\` { ... }
}
public typealias Testing = Test.\`Protocol\`
```

**Incorrect**:

```swift
// Package: swift-testing  (name retained)
public enum Testing {}     // ❌ internal namespace still violates [PKG-NAME-001]
```

**Scope of the exception**:

- The external name MUST be a **specific, named** package we are
  establishing source-compatible interop with, not an aesthetic
  preference.
- Document the exception in the package's README (state which external
  package forces the gerund) and in `swift-institute/Research/` if the
  decision is non-obvious.
- Aesthetically similar external packages that we are NOT interoping with
  do not qualify. "Gerund names are common in this domain" is not an
  external-compat reason.

**Rationale**: Strict noun-rule enforcement would prevent us from shipping
a package that drops into a consumer's existing `import swift_testing`
site. The exception is narrow and named: only real external-compat
constraints override the noun rule, and even then only at the package
name, not inside the namespace.

**Cross-references**: [PKG-NAME-001]

---

### [PKG-NAME-004] Foundations Cascade

**Statement**: Layer 3 foundations that are **purely primitive
vocabularies** (renderers mapping a typed tree to a serialized output
form, formatters emitting a typed value as text, etc.) SHOULD be
relocated to Layer 1 under the noun-convention naming, provided they
satisfy the Layer 1 constraints in **primitives** ([PRIM-FOUND-*]).

| L3 gerund-suffix (historical) | Hypothetical L1 noun form | Actual outcome (2026-04-21) |
|-------------------------------|---------------------------|------------------------------|
| `swift-html-rendering`         | `swift-render-html-primitives`          | stayed L3; renamed `swift-html-render` |
| `swift-pdf-rendering`          | `swift-render-pdf-primitives`           | stayed L3; renamed `swift-pdf-render` |
| `swift-svg-rendering`          | `swift-render-svg-primitives`           | stayed L3; renamed `swift-svg-render` |
| `swift-markdown-html-rendering`| `swift-render-markdown-html-primitives` | stayed L3; renamed `swift-markdown-html-render` |
| `swift-css-html-rendering`     | `swift-render-css-html-primitives`      | stayed L3; renamed `swift-css-html-render` |
| `swift-pdf-html-rendering`     | `swift-render-pdf-html-primitives`      | stayed L3; renamed `swift-pdf-html-render` |

All six were disqualified from L1 relocation at execution time — each
has L2 standards deps, L3 deps, or Foundation source imports. The
hypothetical L1 column remains as the target shape for future
relocation if the dependency graph simplifies.

**Conditions for L3 → L1 relocation**:

- No `import Foundation` in the package or its dependencies.
- All dependencies are also L1 (no lateral or upward deps).
- The package ships the `-primitives` suffix on its renamed form.
- The namespace follows [PKG-NAME-001] (noun form) and [PKG-NAME-002]
  (capability protocol + gerund typealias).

**If the foundation cannot satisfy these conditions**, it stays at L3
with a noun-form name (e.g., rename to `swift-html-render` at L3
rather than relocate to L1). Relocation is opportunistic, not mandatory.

**Foundations that are not purely primitive vocabularies** (e.g.,
`swift-user-interface`, whose namespace composes multiple concerns and
whose rendering layer is a sibling foundation) stay at L3 with a
noun-form name.

**Rationale**: The L3 renderer family was placed at L3 historically because
the `-rendering` suffix was a de-facto foundations pattern. That pattern
is an artifact of the gerund drift identified in
`package-namespace-noun-convention.md`. Once the noun rule is in place,
these packages are re-assessed on their actual dependency graph — most are
Foundation-independent and belong at L1.

**Cross-references**: [PKG-NAME-001], [PRIM-FOUND-001], [ARCH-LAYER-*]

---

## Tie-Breaking and Edge Cases

### [PKG-NAME-005] Shortest Natural Noun

**Statement**: When multiple noun forms of a domain are available (e.g.,
"render" vs "rendering" as noun, "order" vs "ordering" as noun), the
SHORTEST natural noun wins. A noun form is "natural" if it is a
first-class English noun independent of the gerund reading.

**Examples**:

| Domain verb | Noun forms available | Choose |
|-------------|----------------------|--------|
| render      | render (rare noun), rendering (gerund/noun) | `render` (shortest) |
| order       | order (noun), ordering (gerund/noun) | `order` (shortest) |
| format      | format (noun), formatting (gerund) | `format` (shortest) |
| position    | position (noun), positioning (gerund) | `position` (shortest) |
| parse       | parse (verb only), parser (agent noun), parsing (gerund) | `parser` (only natural noun) |
| translate   | translate (verb only), translator, translation (noun) | `translation` (canonical noun) |
| route       | route (noun), router (agent noun), routing (gerund) | `route` (shortest natural) |

**When "shortest" conflicts with "natural"**: prefer natural. `parse` is
a verb, not a noun; `parser` is the natural noun form and MUST be chosen
over any forced `parse` noun use.

**Rationale**: The rule is deterministic — given a domain verb, the
package author should reach the same name regardless of aesthetic. A
shortest-natural-noun rule eliminates bike-shedding and reduces naming
variation across the ecosystem.

**Cross-references**: [PKG-NAME-001]

---

### [PKG-NAME-006] Hoisted Protocol for Generic Namespaces

**Statement**: Swift does not allow declaring a protocol nested inside a
generic type. When a namespace is a generic type (or `extension
GenericType where ...`), the canonical capability protocol MUST be
declared at **module scope** under a conventional name
`__<Namespace>Protocol`, and re-exported via an `extension Namespace:
public typealias \`Protocol\` = __<Namespace>Protocol` binding.

**Correct**:

```swift
// Module scope — hoisted protocol
public protocol __ArrayProtocol: Collection.Bidirectional & ~Copyable {
    subscript(_ position: Index) -> Element { get set }
}

// Re-export via namespace typealias
extension Array where Element: ~Copyable {
    public typealias \`Protocol\` = __ArrayProtocol
}

// Module scope — gerund typealias
public typealias Arraying = __ArrayProtocol
//  ^ note: typealias name drops the double-underscore, stays gerund-readable
```

**Incorrect**:

```swift
// Attempt to nest protocol inside a generic type — Swift forbids this:
public struct Array<Element> {
    public protocol \`Protocol\` { ... }  // ❌ compiler error
}
```

**Naming rules for the hoisted protocol**:

- Name: `__<Namespace>Protocol` (double-underscore prefix to mark it as an
  escape hatch, not a primary API surface)
- Target of the namespace typealias: the hoisted protocol
- Gerund typealias, if applicable, targets the hoisted protocol directly
  (not via the namespace typealias) so it stays resolvable from module
  scope

**Rationale**: This pattern is already in use by `swift-array-primitives`
(`__ArrayProtocol` hoisted with `Array.\`Protocol\`` typealias) and handles
the Swift syntax limitation without breaking the `Namespace.\`Protocol\``
user-facing surface. The `__` prefix signals "implementation escape hatch";
primary consumers use `Array.\`Protocol\`` or the gerund typealias.

**Cross-references**: [PKG-NAME-002], [API-IMPL-005]

---

## Application Checklist

### When creating a new package

- [ ] Package name follows [PKG-NAME-001] (noun form, `-primitives` suffix if L1).
- [ ] Swift namespace matches the package-name noun.
- [ ] If the package has a canonical capability protocol:
  - [ ] It is declared as `Namespace.\`Protocol\`` ([PKG-NAME-002]).
  - [ ] A top-level gerund typealias targets `Namespace.\`Protocol\``.
  - [ ] If the namespace is generic, use the hoisted-protocol pattern
        ([PKG-NAME-006]).
- [ ] Shortest natural noun chosen when multiple forms exist ([PKG-NAME-005]).
- [ ] If an external-compat exception is claimed ([PKG-NAME-003]), document
      it in the README and cite the external package.

### When renaming an existing package

- [ ] Confirm the current name violates a [PKG-NAME-*] rule (not just
      aesthetic).
- [ ] Write a migration note documenting the rename and the breaking-change
      scope.
- [ ] Update all consumers in the Swift Institute monorepos before the
      rename is public.
- [ ] Update the Skill Index in `swift-institute-core/SKILL.md` if the
      package previously carried a skill.

---

### [PKG-NAME-007] Phase-0 Pre-Rename Audit Requirements

**Statement**: Before executing an ecosystem-wide package or namespace rename via mechanical regex, Phase 0 MUST run two enumeration greps to surface collision-risk sites:

1. **Ecosystem-wide `import <OldModule>` grep** — not just `Package.swift` `.package(path:)` references — to catch transitive-only import sites that depend on the old module name without declaring a direct dependency.
2. **Consumer-side grep for collision patterns** — `extension *.<OldNamespace>`, `enum <OldNamespace>`, `struct <OldNamespace>` — to identify sites where the rename will collapse a gerund-outer/noun-inner pair into a same-name collision.

**Procedure**:

```bash
# (1) Transitive-only imports:
grep -rln "^import $OldModule" Sources/ Tests/ ~/Developer

# (2) Collision-risk declarations:
grep -rnE "(extension|enum|struct) +[A-Za-z._]*\.$OldNamespace" Sources/ ~/Developer
```

Both greps MUST be run and their output reviewed before the mechanical rename fires.

**Rationale**: Mechanical regex-driven renames succeed on the declaring-site surface but miss two classes of site that only break at build time: transitive-only imports (where the old name appears in `import` statements but not in `Package.swift`) and namespace-collision sites (where the rename collapses a gerund/noun pair into a shadow). Two Phase-0 defects in the 2026-04-21 `Rendering` → `Render` cascade would have been prevented by these greps; instead they surfaced as post-rename build failures across many downstream packages.


**Cross-references**: [PKG-NAME-*]

---

### [PKG-NAME-008] Shadow-on-Merge Hazard

**Statement**: When a rename collapses a gerund-outer/noun-inner pair into a noun-outer/same-noun-inner pair (e.g., `Ordering.Order` → `Order.Order`, `Rendering.Render` → `Render.Render`), Swift's lexical lookup inside `extension Order` resolves bare `Order` to the INNER tag, shadowing the outer namespace. Call sites that previously worked as `Ordering.Order.something` silently break because `Order.something` now references the inner tag, not the outer namespace.

**Remediation options** (ranked):

1. **Drop the redundant qualifier at call sites** (preferred). Since the outer and inner now share a name, `Order.something` remains valid where appropriate; where it's not, drop to the bare member.
2. **Module-qualify via `<Module>.<Namespace>.X`** at specific call sites where the outer must be referenced inside an extension on the inner.
3. **Rename inner tag** (last resort). Changes the public API; avoid unless option 1 and 2 both fail to express the intent cleanly.

**Rationale**: Lexical shadowing is a Swift-language-level consequence that cannot be worked around by the rename tooling; the mitigation is call-site-level discipline post-rename. Documenting the hazard at the skill level alerts rename authors to audit call-site resolutions as part of the Phase 0 pre-check.


**Cross-references**: [PKG-NAME-007]

---

### [PKG-NAME-009] Capability-Protocol vs Noun-Type Distinction

**Statement**: The `Namespace.\`Protocol\`` convention from [PKG-NAME-002] applies only when the namespace has backing noun-type identity — a concrete value type that exists alongside the namespace via the back-tick-escaped Protocol trick (Cardinal, Ordinal, Hash, Render, Affine.Discrete.Vector). For pure capability protocols WITHOUT noun-type backing (Carrier, Mutator, hypothetical Serializable / Validator / HasSerializer), the protocol MUST be top-level and MUST NOT be nested in a namespace shell. Forcing a capability protocol into a namespace.Protocol mold creates an empty enum with nothing in it but punctuation around the dotted form — inventing structure that isn't there.

**Decision test**:

| Question | Answer | Apply |
|----------|--------|-------|
| Is there a concrete value type with the namespace's name that consumers instantiate? (e.g., `let c = Cardinal(...)`) | Yes | [PKG-NAME-002] (namespace.Protocol convention with the backing value type as the noun) |
| Is the name purely a capability or marker (no concrete value type by that name)? | Yes | Top-level protocol; NO namespace shell |

**Worked examples**:

| Type | Has noun-type backing? | Convention |
|------|------------------------|------------|
| `Cardinal` | Yes (concrete `Cardinal` value type) | `Cardinal.\`Protocol\`` per [PKG-NAME-002] |
| `Ordinal` | Yes | `Ordinal.\`Protocol\`` |
| `Hash` | Yes | `Hash.\`Protocol\`` |
| `Render` | Yes (concrete `Render` value type) | `Render.\`Protocol\`` |
| `Affine.Discrete.Vector` | Yes (concrete vector value) | `Affine.Discrete.Vector.\`Protocol\`` |
| `Carrier` | NO (pure capability) | Top-level `Carrier` protocol; no `Carrier.\`Protocol\`` shell |
| `Mutator` (in swift-mutator-primitives) | NO (pure capability) | Top-level `Mutator` protocol; separate package, not nested under Carrier |
| Hypothetical `Serializable`, `Validator`, `HasSerializer`, `HasValidator`, `HasHasher` | NO (pure capability per concept) | Top-level protocol per concept; not a single meta-protocol abstracting "has-a" |

**Rationale**: Swift cannot kind-polymorphism over protocols; per-capability protocols communicate semantic intent at the type level. The noun-rule from [PKG-NAME-001] grew up in noun-type contexts where the namespace doubles as a value type via the back-tick trick, giving the dotted form genuine structure (a concrete value, a namespace, a refining protocol — triple identity). For pure capability protocols without that backing, the dotted form is punctuation, not structure. Forcing the convention onto capability protocols also creates surface friction: consumers writing `T: Carrier.\`Protocol\`` instead of `T: Carrier` add ceremony without clarity.

**Re-derivation history**: This distinction recurred at least four times during 2026-04-26 carrier-primitives session — `Carrier.Mutable` rejected as nested protocol; swift-mutator-primitives chosen as separate package over nested Mutator; ecosystem inventory's classification distinguishing capability-shaped (Cardinal, Ordinal, Hash, Affine.Discrete.Vector — 4 adopters of the back-tick pattern) from witness-style (Equation, Comparison, Coder, Serializer, etc. — 13 protocols, all top-level capability protocols); HasSerializer-style discussion converging on per-capability top-level protocols. Codifying the distinction prevents future re-derivation from first principles.


**Cross-references**: [PKG-NAME-001], [PKG-NAME-002], [PKG-NAME-006]

---

### [PKG-NAME-010] GitHub Release vs Git Tag — Different Questions

**Statement**: GitHub Releases and git tags answer different questions and MUST NOT be used interchangeably. For heritage-transfer / squash recipes / version-detection / pre-publication audits that cite "the package's version," the appropriate API depends on what the question is asking:

| Question | Correct API | Wrong API (common mistake) |
|----------|-------------|---------------------------|
| "Is there a git tag, and what's its name?" | `git describe --tags --abbrev=0` (or `git tag -l`) | `gh repo view --json latestRelease` (returns null when tag exists without GitHub Release) |
| "Is there a published GitHub Release?" | `gh repo view --json latestRelease` (or `gh release list`) | `git describe --tags` (returns the tag even if no release was published) |
| "What version is this package?" | First check `Package.swift`, fallback to `git describe --tags` | Either of the above alone |
| "Has the package been released to the public?" | Combination: tag + Release published + repo visibility = public | `git describe --tags` alone (private repo with tag is not "released") |

**The canonical mistake**: classifying a package as "no tag" or "no version" based on `gh repo view --json latestRelease` when the package has a tag but no GitHub Release wrapping it. GitHub's UI emphasizes Releases (which combine a tag with release notes); many ecosystem packages have tags without Releases, especially for internal versioning before public launch.

**Worked example (the origin incident)**:

A 2026-04-23 heritage-transfer audit classified `swift-html-prism` as "no tag" based on `gh repo view --json latestRelease` returning null. The package actually had `0.1.0` tagged via `git describe --tags --abbrev=0`; the absence was of a GitHub Release wrapping the tag, not of the tag itself. Mis-classification routed the package into the wrong heritage-transfer bucket.

**Procedure for heritage-transfer / squash / version-detection recipes**:

1. Identify what the question is actually asking (tag presence? release publication? canonical Package.swift version?).
2. Use the API matching the question per the table above.
3. When in doubt, call BOTH APIs and surface the divergence — a tagged-but-not-released package is a real ecosystem state worth handling explicitly.


**Cross-references**: [PKG-NAME-001]

---

## Dependencies

### [PKG-DEP-001] Path-Form-as-Safe-Default for Pre-Publishable Cross-Repo Deps

**Statement**: When a `Package.swift` declares a dep on a sibling Institute
repo whose publishable visibility is uncertain — active architecture work,
pre-1.0 packages, or any case where the target repo might flip between
PRIVATE and PUBLIC — the dep declaration MUST use the path-based form
`.package(path: "../<sibling-repo>")`. URL-based form
`.package(url: ..., from: ...)` is reserved for deps whose target is
publicly resolvable AND has a stable tag.

**Correct** (pre-publishable cross-repo dep, sibling-clone topology):

```swift
dependencies: [
    .package(path: "../../swift-primitives/swift-linter-primitives"),
    .package(path: "../swift-json"),
]
```

**Correct** (URL form for deps whose target is publicly resolvable + tagged):

```swift
dependencies: [
    .package(url: "https://github.com/swiftlang/swift-syntax.git", "602.0.0"..<"603.0.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.5.0")),
]
```

**Incorrect** (URL form against a target whose visibility is uncertain):

```swift
dependencies: [
    // ❌ Sibling is PRIVATE pre-1.0; URL form fails on GH Actions
    //    runners that lack auth tokens for the org.
    .package(url: "https://github.com/swift-foundations/swift-linter-rules.git", from: "0.1.0"),
]
```

**When path-form is mandatory**:

| Scenario | Why path-form |
|----------|---------------|
| Sibling repo is currently PRIVATE | URL fetch 404s for any consumer without auth credentials, including consumer-CI runners |
| Sibling repo is pre-1.0 with no tag | URL form requires a tag for resolution |
| Architecture work in flight | Repo may flip PRIVATE→PUBLIC mid-cycle; path stays valid through both states |
| GH Actions consumer-CI runner | Path resolves against the checked-out workspace; URL requires either public visibility or a token in the runner |

**The path → URL switch**: Once the dep target is public AND tagged, swap
path-form to URL-form in a small follow-up commit. The switch is a routine
change, not a hard architectural decision; do not anticipate the eventual
URL shape during the pre-publishable phase.

**Rationale**: Path-form works regardless of publishable state and
regardless of CI runner credentials. URL-form encodes assumptions that may
not yet hold (target is public; tag exists). Encoding the dep's
eventual-shape during pre-publishable work creates a CI brittleness window
where the package builds locally but breaks on every consumer-CI run that
lacks runner credentials. The path-form-as-safe-default rule eliminates
the window without losing the URL-form's eventual shape — the switch
lands when the target's state actually supports it.

**Pointer — current institute pin model (2026-06-02)**: the path-form-as-safe-default guidance above predates the ecosystem-wide path→URL conversion, which is now complete (0 `path:` deps remain across the layered packages; cross-repo deps resolve URL→global mirror locally and URL→token on CI). The institute's current cross-repo dependency lifecycle — URL-form throughout, with `branch:"main"` (pre-tag) vs `from:` (post-tag) as the live axis, switched bottom-up at tag time under the one-form-per-package invariant — is governed by `swift-institute/Research/versioning-and-release-strategy.md`. Consult that doc for institute pin decisions; the path-form rule above remains the general SwiftPM principle and the rationale for mirror-less / external-consumer contexts.

**Cross-references**: [PKG-NAME-001], [PKG-NAME-010], [PKG-DEP-002], `swift-institute/Research/versioning-and-release-strategy.md`

---

### [PKG-DEP-002] Package-Identity Audit Before Path-Form Sibling Deps

**Statement**: Before adding a path-form dep on a sibling Institute repo,
the consumer's resolved-graph MUST be audited for package-identity
collisions: any other dep (URL-form or path-form) whose `Package.swift`
declares the same `name:` as the new dep will produce a build-planner
stall when both forms appear in the closure together. The audit is
mechanical (`grep -r 'name:' Package.swift` across the closure) and MUST
run before the new dep can land. A collision MUST be resolved by
dropping or redirecting the conflicting source — not by attempting to
disambiguate within the same closure.

**Composite:** identity-grep (mechanical) + closure enumeration via
`swift package show-dependencies` (mechanical, External: SwiftPM) +
collision detection (mechanical).

**Procedure** (consumer-side, before merging the new dep):

1. Enumerate the consumer's full resolved closure
   (`swift package show-dependencies --format json` or equivalent).
2. For each dep in the closure, extract the `name:` declaration from
   its `Package.swift`.
3. Collect identity duplicates: any pair of deps where both declare the
   same `name:` but resolve to different URLs / paths / tags.
4. If any duplicate is found, the new dep MUST NOT be added until the
   conflict is resolved. Resolution options:
   - Drop the older dep (URL or path form, whichever is
     non-canonical).
   - Redirect the conflicting URL through the workspace mirror
     (per the swift-package-mirrors recipe, when both forms must
     coexist temporarily).
   - Rename one of the colliding packages (rare; only when both
     are owned by the same author and the rename is otherwise
     justified).

**Audit extension — URL-spelling identity split (2026-07-08)**: the `name:` grep
misses collisions created by ONE repo referenced under two URL spellings (`.git`
vs bare vs trailing-slash, or a retired-org URL) across the closure's manifests.
SwiftPM canonicalizes both spellings to one identity, but mirror lookup is
exact-string — so a raw-URL ref coexisting with a mirror-redirected-to-local ref
forms a URL/local pair and the same non-terminating consolidation walk (observed:
99% CPU in `findAllTransitiveDependencies` → `createResolvedPackages`, zero
frontends, never terminates). The audit MUST therefore also group every
`.package(url:)` in the closure by computed identity (last path component, minus
`.git`, lowercased) and flag any identity spelled ≥2 ways, or any identity where
a raw-URL ref coexists with a mirror-redirected ref. Remediation: align the
outlier spelling to the mirror/ecosystem convention ([PKG-DEP-009]). Enumerate
the closure from manifests + `Package.resolved`, NOT
`swift package show-dependencies` — its dumpers are independently exponential on
large graphs (once-per-path tree print, 41.7 GB observed on a healthy graph;
catalog §A26).

**Failure signature** (when [PKG-DEP-002] is violated):

- `swift build` parent process at 99% CPU
- ZERO `swift-frontend` children
- Log frozen after duplicate-product warnings (or no log if it's a
  no-output stall)
- No `.build/` artifacts produced
- Persists indefinitely (the dedup walk does not terminate)

This signature is operationally indistinguishable from an infinite loop
without source-level evidence; the only diagnostic that surfaces the
identity collision is the manual identity-grep this rule mandates.

**Worked examples** (canonical 2026-05-08 origin incident):

- coenttb/swift-money + coenttb/swift-document-templates migration
  attempted to add `.package(path: "../../swift-foundations/swift-dependencies")`
  while keeping a transitive URL-form `.package(url: "https://github.com/pointfreeco/swift-dependencies.git", from: "1.3.x")` (via `coenttb-foundation-extensions`).
  Both upstream Package.swift files declare `name: "swift-dependencies"`.
  Build planner stalled at 99% CPU for 42+ min; minimal reproducer at
  `/tmp/timekeeping-repro/` confirms 8-dep closure + identity collision
  reproduces the stall. Fix: drop `coenttb-foundation-extensions` (which
  was the transitive bringer of the pointfree URL-form), add direct
  path-form `.package(path: "../swift-foundations/swift-dependencies")`,
  rebuild succeeds in 274s.
- The 2026-05-01 SPM-stall investigation independently surfaced the
  same upstream defect class on the swift-foundations/swift-io
  workspace (5 URL/local pairs in closure produced a similar stall).
  Workspace-side mitigation via comprehensive mirror
  (coenttb/swift-package-mirrors) resolves the immediate need; the
  upstream bug class is the same, the consumer-side audit gate is
  the per-dep correctness rule.

**Why an audit gate, not a runtime catch**: SwiftPM produces no
diagnostic for the collision — the planner enters consolidation logic
that never terminates. Without the pre-merge audit, the failure mode is
a 99%-CPU silent stall that consumers cannot diagnose without bisecting
their own dep tree. The audit cost is sub-second per dep; the failure
cost is hours to days of misdiagnosis.

**Mitigation pattern (workspace-wide)**: when an entire workspace is
prone to URL/path-form coexistence (e.g., during migration arcs across
many consumers), the canonical mitigation is `coenttb/swift-package-mirrors`'s
comprehensive-mirror recipe — redirect every URL-form to its local
file:// path so the dedup walk has nothing to dedup. This is workspace
infrastructure, not per-package, and complements [PKG-DEP-002]'s
per-dep-merge audit discipline.

**Cross-references**: [PKG-DEP-001], [PKG-NAME-001], [ISSUE-013]
variable isolation in negative experiments.

---

### [PKG-DEP-003] Package.swift Declares Used-Only Deps; `@_exported` Is Consumer Convenience

**Statement**: `Package.swift` dependency declarations MUST be limited to modules that source files (`Sources/` or `Tests/Support/`) actually `import`. The kitchen-sink "add semantically-adjacent lower deps and re-export them even if unused" practice is forbidden. Separately, `@_exported public import` in `exports.swift` is for *consumer convenience* — re-export upstream modules whose types appear in this package's public API so consumers don't have to manually `import` them too.

**Why**: Unused deps inflate the dep graph, slow builds, and lie about coupling. `@_exported` re-exports are deliberate consumer-facing decisions about which upstream namespaces flow through. Conflating "I declare a dep" with "I re-export it" produces silent transitive surface that consumers can't reason about.

**How to apply**:
1. Audit `Package.swift` deps against literal source-file imports; remove any dep not imported.
2. For each upstream type that appears in this package's public API, add `@_exported public import {Module}` in `exports.swift` so consumers don't need to repeat the import.
3. Test Support spine deps are EXCLUDED from this audit per `[PKG-DEP-004]`.


**Cross-references**: [MOD-015], [MOD-024], [PKG-DEP-004], [PKG-DEP-007]

---

### [PKG-DEP-004] Test Support Spine Deps Stay Even When Literal-Import-Unused

**Statement**: Test Support targets' dependency declarations follow the `[MOD-024]` spine discipline: TS deps ⊆ {TS-of-deps, own product}, anchored on the lowest in-scope upstream Test Support. These spine deps MAY NOT appear as literal `import` statements in the TS module's source — that absence is a *spine setup gap*, NOT a dep-removal candidate. Cleanup audits MUST exclude `* Test Support` deps declared on `* Test Support` targets from UNUSED findings; the proper remediation when a spine link is missing is to ADD `@_exported public import <upstream>_Test_Support` to `exports.swift`, not drop the dep.

**Why**: The Test Support spine is a structural contract — any consumer of this package's Test Support gets the upstream Test Support transitively. Removing a spine dep because it's not literally imported breaks the spine for downstream consumers, who then have to add the dep themselves at every level. The spine MUST be re-exported to honor `[MOD-024]`; missing `@_exported` is a fix-it, not a remove-it.

**How to apply**:
- During dep cleanup audits, partition deps into:
  1. Main-target deps (`* Primitives`, `*`) — apply `[PKG-DEP-003]` (used-only).
  2. Test Support target deps — apply this rule (spine-discipline; literal-import-absence is not removal evidence).
- When a spine TS dep has no literal import in TS source, ADD `@_exported public import <upstream>_Test_Support` to `* Test Support/exports.swift`.


**Cross-references**: [MOD-024], [PKG-DEP-003]

---

### [PKG-DEP-005] Canonical-Config Swift Packages Live in the Owning Org, Not in `swift-foundations/`

**Statement**: When a canonical configuration legitimately needs SwiftPM-resolvable form (NOT lint — see `[PKG-DEP-006]` for file-based superseding pattern), the canonical Swift package MUST live in the org-clone-mirror that owns the rules:
- Tier 1 ecosystem-wide canonicals → `swift-institute/`
- Tier 2 per-org canonicals → `<org>/` (e.g., `swift-microsoft/`, `swift-linux-foundation/`)
- NOT in `swift-foundations/` regardless of layer

**Why**: `swift-foundations/` is a layer-3 composition org, NOT an authority/canonical-config org. Mistakenly placing canonical configs there muddles the layer's mission and makes the canonical hard to discover (consumers expect canonicals at the org owning the rule set). The org-mirror structure already encodes ownership; canonical placement should follow.

**How to apply**:
- When dispatching a canonical Swift package: place at the rule-owning org's clone-mirror root.
- When auditing existing canonicals: any in `swift-foundations/` is a relocation candidate; relocate to the rule-owning org.
- Lint canonicals follow `[PKG-DEP-006]` (file-based at `<org>/.github/Lint.swift`), NOT this rule.


**Cross-references**: [PKG-DEP-001], [PKG-DEP-006], [ARCH-LAYER-001]

---

### [PKG-DEP-006] Lint Canonical Configuration Is File-Based at `<org>/.github/Lint.swift`

**Statement**: Linter Tier-N canonical configuration MUST be published as a single `Lint.swift` file at `<org>/.github/Lint.swift` for the org owning the rule set; per-package consumers declare a `// parent: <raw URL>` directive at the top of their own `Lint.swift` to inherit. This mirrors SwiftLint's `<org>/.github/.swiftlint.yml` `parent_config:` pattern and SUPERSEDES the prior canonical-as-Swift-package design.

**Why**: A Swift-package-shaped lint canonical was the prior design; in practice it fragmented configuration across SwiftPM resolution boundaries and required full package machinery for what is fundamentally a config-file inheritance graph. The file-based design uses raw-URL inheritance, gives instant resolution (no `swift package update`), and parallels SwiftLint's existing parent-config mechanism.

**How to apply**:
- Tier-1 canonical: `swift-institute/.github/Lint.swift`.
- Tier-2 canonical: `<org>/.github/Lint.swift` (e.g., `swift-microsoft/.github/Lint.swift`).
- Per-package consumer: top-of-file `// parent: <raw URL to canonical>` directive in its own `Lint.swift`.
- Do NOT package the canonical as a Swift package; do NOT propose returning to that design.


**Enforcement**: TEXT-ONLY (insufficient empirical grounding, /promote-rule 2026-07-06) — one live org→org `// parent:` edge, zero per-package directive consumers (inheritance runs through Bundle composition); no mechanical source for the owning-org set. Re-promotable at the directive rollout or a ratified owning-org list: `Audits/PROMOTE-PKG-DEP-006-2026-07-06.md`.

**Cross-references**: [PKG-DEP-005], [CI-094]

---

### [PKG-DEP-007] Declared-Dependency Pruning Is Verified by Source-Import Grep + Clean Build, Not Judgement

**Statement**: Before removing a `Package.swift` dependency as unused per `[PKG-DEP-003]`, the used/unused determination MUST be made by a deterministic source-import check, not by manual or LLM judgement. For each candidate package, derive its importable module names from its target names (SwiftPM c99 mangling: non-identifier chars → `_`) and grep the consumer's `Sources/` and `Tests/` for `import <Module>` (comment-masked). A candidate whose module IS imported but which no target declares via `.product(name:, package:)` is **under-declared, not unused** — the fix is to ADD the `.product` to the importing target, NOT to remove the dependency (the manifest-declaration analogue of `[PKG-DEP-004]`'s `@_exported` fix-it). A candidate with no source import is prune-eligible, and MUST then be proven by a clean build (`rm -f Package.resolved && rm -rf .build && swift build`) whose `Package.resolved` diff shows ONLY the intended removal — the package either leaves the graph or persists transitively under its canonical URL (both safe); a *new* dangling pin means the removal was wrong.

**Why**: manual/LLM "is it used?" judgement is unreliable — during the 2026-07-01 dependency-reference-hygiene arc it produced a false negative on `swift-console` (a live `import Terminal_Input_Primitives` a workflow's LLM pass missed and a deterministic grep caught). Build-green alone does not protect against it: under `MemberImportVisibility` an undeclared product makes the import fail to compile, but a package can currently build via a *different* transitively-provided module of the same name, so the removal looks safe until a downstream consumer breaks. The grep gate is the safe-by-construction check; the clean build with a `Package.resolved` diff is the confirmation.

**How to apply**:
1. Candidate = a top-level `.package` with zero `.product(name:, package:<id>)` references across all targets (the vestigial transitive-collision-override signature that pre-canonicalization overrides leave behind; see `[MOD-024]`).
2. Grep the consumer's `Sources/`+`Tests/` for `import <Module>` of each candidate's vended modules (comment-masked). Any hit ⇒ ADD-PRODUCT (declare the missing `.product` on the importing target); do NOT prune.
3. No hit ⇒ prune, then `rm -f Package.resolved && rm -rf .build && swift build`; confirm green and a `Package.resolved` diff limited to the intended change.
4. The determination is per-package and empirical — a workflow's aggregate LLM pass is not a substitute for the per-consumer grep.


**Enforcement**: SwiftPM-native — `swift build` emits `warning: '<pkg>': dependency 'X' is not used by any target` for exactly the unused-dependency case (verified 2026-07-01; note it surfaces only on a full build, NOT `swift package resolve`/`dump-package`). Since pruning is done after a green build, that native warning is the authoritative signal — no custom validator is needed. Act on it per How-to-apply above: remove the declaration, or ADD the `.product` if a source imports the module. A regex static validator was piloted then removed as redundant with SwiftPM's own diagnostic — see `Audits/PROMOTE-PKG-DEP-007-2026-07-01.md`. [VERIFICATION: Native tooling]

**Cross-references**: [PKG-DEP-003], [PKG-DEP-004], [MOD-024]

---

### [PKG-DEP-008] Consumer `.product(package:)` Uses the URL Repo-Name, Not the Local-Dir Basename

**Statement**: Every consumer `.product(name:, package: X)` MUST spell the dependency's canonical off-machine identity — the `.package(url:)` URL's last path component minus `.git` (path deps: the git repo name, not the on-disk dir basename) — never the mirror-only local-dir basename, which resolves only WITH the machine-local mirror.

```swift
// dir `swift-windows-32`, origin `swift-windows-standard.git`:
.product(name: "Windows", package: "swift-windows-standard")   // ✓ resolves WITH and WITHOUT the mirror
.product(name: "Windows", package: "swift-windows-32")         // ❌ off-machine: unknown package 'swift-windows-32'
```

**Enforcement**: Mechanical — `validate-package-identity.py` (+ `validate-package-identity.yml` org sweep; /promote-rule 2026-07-06). Discipline: `Audits/PROMOTE-PKG-DEP-008-2026-07-06.md`. [VERIFICATION: WF]

**Cross-references**: [PKG-DEP-001], [RELEASE-015], [CI-112].

---

### [PKG-DEP-009] Canonical `.git`-Suffixed Dependency URLs; No Path Deps or Retired-Org Spellings in Committed Manifests

**Statement**: Every `.package(url:)` in a committed manifest MUST spell the dependency exactly as `https://github.com/<org>/<repo>.git` — current org home, `.git` suffix, no bare form. Committed manifests MUST NOT use `.package(path:)` (local resolution is the mirror table's job) and MUST NOT spell retired/foreign org homes (`coenttb/`, `swift-web-standards/`); those spellings live only in immutable historical tags.

```swift
.package(url: "https://github.com/swift-ietf/swift-rfc-7578.git", branch: "main")   // ✓
.package(url: "https://github.com/swift-ietf/swift-rfc-7578", branch: "main")       // ❌ bare — second canonical location the moment the .git spelling is mirrored
.package(url: "https://github.com/swift-standards/swift-rfc-7578.git", ...)          // ❌ historical org home
.package(path: "../swift-rfc-7578")                                                  // ❌ machine-local layout in a committed manifest
```

**Why**: SwiftPM's mirror substitution is an exact-string lookup, and `createResolvedPackages` compares canonical *locations*, not identities: two spellings of one identity where only one hits a mirror key (or an org-rename divergence, mirror-free) put the identity under two canonical locations and fire the conflicting-identity branch — which on SwiftPM 6.2+ enumerates every distinct dependency path (exponential; an effective hang on institute-scale graphs; one edge suffices). Dossier: `Issues/swift-issue-spm-identity-conflict-path-enumeration-hang/` (catalog §A26).

**Enforcement**: Mechanical — `validate-dependency-spelling.py` (+ `validate-dependency-spelling.yml` org sweep). Machine-side companions: `Scripts/scan-identity-conflicts.py` (fleet divergence scan across HEAD+tags+pins, both mirror contexts), `Scripts/normalize-dependency-spellings.py` (mechanical fixer, dump-package-gated), `Scripts/sync-mirrors.py --check` (mirror-table closure guard). [VERIFICATION: WF]

**Cross-references**: [PKG-DEP-001], [PKG-DEP-008], [CI-112].

---

### [PKG-NAME-011] Package Placement Follows Specification Authority, Not Deployment Platform

**Statement**: L2 packages MUST be named after the specification authority that defines the API contract (IEEE 1003.1 / POSIX, BSD, GNU), NOT after the deployment platform where the API compiles (Darwin, Linux). Package naming follows the contract source, not the compile target.

**Why**: The spec authority is the stable identity — POSIX is POSIX whether on Darwin or Linux. Naming by platform conflates "what's specified" with "what compiles where" and produces duplicate L2 packages for the same spec across platforms. The org-mirror structure has dedicated platform packages (`swift-darwin`, `swift-linux`, `swift-windows`) for platform-specific concerns; the L2 spec layer should not duplicate them.

**How to apply**:
- L2 spec name follows the authority's identifier (`swift-iso-9945` for POSIX, `swift-rfc-4122` for UUIDs, `swift-iso-32000` for PDF).
- Platform-specific concerns (Darwin's kqueue, Linux's epoll/io_uring) live in platform packages, NOT in L2.
- When a spec is platform-only (e.g., a Win32 API), the L2 name still follows the spec authority — e.g., `swift-windows-standard` for the Microsoft platform spec (the authority IS Microsoft as platform-spec author, distinct from "compiles on Windows").


**Cross-references**: [PKG-NAME-001], [PKG-NAME-002], [ARCH-LAYER-003], [PLAT-ARCH-014]

---

### [PKG-NAME-012] Renames Stay Mechanical: No Canonical Protocol or Typealias Additions

**Statement**: When renaming a package or namespace per `[PKG-NAME-001]`, the rename MUST stay mechanical. The agent MUST NOT add a canonical `Namespace.\`Protocol\`` or a gerund typealias unless the namespace ALREADY had one before the rename. Renames change the identifier, not the API surface.

**Why**: Adding a canonical protocol or typealias as part of a rename conflates two distinct decisions: (a) what to call the package, (b) whether to introduce a new capability protocol. The capability-protocol question per `[PKG-NAME-002]` requires its own design discussion; bundling it into a rename hides the API addition under "rename scope."

**How to apply**:
- Rename: change identifier in Package.swift, source paths, imports. Done.
- Canonical-protocol addition: separate dispatch with its own design rationale per `[PKG-NAME-002]`.
- If the namespace had a canonical protocol BEFORE the rename, preserve it — that's not "adding," it's continuity.


**Cross-references**: [PKG-NAME-001], [PKG-NAME-002], [PKG-NAME-006]

---

### [PKG-NAME-013] Rename Collisions Surface at Build Time — Two Pre-Build Greps Required

**Statement**: Mechanical package renames miss two classes of issue that surface only at build time:
1. Nested L3 namespaces colliding with the renamed L1 namespace.
2. Transitive-only source imports not listed in any `Package.swift`.

Phase 0 of any rename MUST run two greps before commit:
- `grep -rln "import {OLD_MODULE}"` to find any `import` of the old name (catches transitive-only imports).
- `grep -rln "extension .*\.{OLD_NAMESPACE}"` to find nested-namespace collisions.

**Procedure** (Phase 0 pre-rename):

```bash
# Grep 1 — transitive-only source imports
grep -rln "import OldName_Primitives\b\|@_exported public import OldName_Primitives\b"

# Grep 2 — nested L3 namespace collisions
grep -rln "extension .*\.OldNamespace\b\|extension OldNamespace\b"
```

Both greps run against the FULL workspace (not just the renamed package's repo) — transitive consumers and L3 consumers commonly live in sibling org-mirror directories.

**Why**: Mechanical renames update the obvious surfaces (Package.swift, source-file imports declared in this repo). They miss (a) consumers that import the namespace transitively without declaring a Package.swift dep on the renamed module, (b) L3 packages that nest a namespace whose path shadows the new L1 namespace path. Both surface as build errors at consumer time, often after the rename is "done." Pre-build greps catch them at the rename PR's diff time.


**Cross-references**: [PKG-NAME-007]

---

### [PKG-NAME-014] Org-Prefix on Pack-Targets When Layered Packages Mirror a Vocabulary

**Statement**: When two or more sibling packages in a layered dependency graph each decompose their content into pack-targets along the same conceptual vocabulary (e.g., a base package + a tier package each having "Rule Memory", "Rule Closure", "Rule Throws" packs), every package above the base MUST prefix its pack-target names with an org/tier identifier. SwiftPM rejects duplicate module names in a single compilation graph; unprefixed pack-target names in layered packages produce build errors at the consumer's compile time.

**Convention** (canonical instance — three-tier linter rule packages):

| Package | Pack-target name shape | Compiled module shape |
|---------|------------------------|------------------------|
| `swift-linter-rules` (base tier) | `Linter Rule <Pack>` | `Linter_Rule_<Pack>` |
| `swift-institute-linter-rules` | `Institute Linter Rule <Pack>` | `Institute_Linter_Rule_<Pack>` |
| `swift-primitives-linter-rules` | `Primitives Linter Rule <Pack>` | `Primitives_Linter_Rule_<Pack>` |

```swift
.target(name: "Institute Linter Rule Memory", ...)  // ✓ layered pack, org-prefixed
.target(name: "Linter Rule Memory", ...)            // ❌ collides with the base pack — consumer graph refused
```

**Enforcement**: Mechanical — `validate-package-naming.py` [PKG-NAME-014] check (/promote-rule 2026-07-06): non-test target names intersected against every locally-resolvable direct dependency's; SwiftPM's own duplicate-module rejection fires only at consumer compile time, this is the authoring-time pre-check. Ecosystem sweep at landing: 0 collisions. Full procedure + scope notes displaced to the discipline record: `Audits/PROMOTE-PKG-NAME-014-2026-07-06.md`. [VERIFICATION: WF]
- The prefix MUST be a single word identifying the layer (e.g., `Institute`, `Primitives`) — NOT a multi-word qualifier. Multi-word prefixes create awkward module names (e.g., `Institute_Layer_Linter_Rule_Memory`) and obscure the prefix's role.
- Order of words: `<Prefix> <BaseVocabulary>` (prefix first, base vocabulary last). Convention parallels the noun-first ordering of `Linter Rule X` (where `Linter Rule` is the vocabulary stem); prefix adds tier context without disrupting the stem's grammar.

**When the base tier's name already includes a prefix**: the base tier's own prefix counts as its tier identifier. Don't re-prefix. Example: if a hypothetical `swift-foundation-rules` published `Foundation Rule X`, then institute mirroring it would be `Institute Foundation Rule X`, NOT `Institute Linter Rule X`.

**Rationale**: SwiftPM resolves the dependency graph into a single set of modules per consumer. Two `.library` products in different packages that publish the same module name produce a build-time error — there's no module-aliasing escape hatch at the consumer level. The collision can only be solved at the **publishing** package's target-name level. Org-prefixing is the cleanest mechanization: every package author can predict the prefix from the layered position; the prefix doubles as documentation of tier provenance.

The alternative (renaming the base tier to add its own prefix, e.g., `Universal Linter Rule X`) is rejected: the base tier's name is the most consumer-facing vocabulary; renaming it forces every consumer to update their imports. The asymmetric rule — base unprefixed, layered packages prefixed — keeps the base stable and pushes the renaming burden onto the layered packages, which have fewer consumers.


**Cross-references**: [PKG-NAME-001], [MOD-001], [MOD-024]

---

### [PKG-NAME-016] Decomposition vs Integration Token Order

**Statement**: A multi-token package/namespace name orders its domain tokens by whether the package **decomposes** one domain into a sub-part or **integrates** two independent domains:

- **Decomposition → larger-then-smaller** (owning domain first, sub-part second), mirroring the namespace path `Owner.Part`. The sub-part has no independent existence outside the domain. Examples: `set-ordered` (`Set.Ordered`), `bit-vector` (`Bit.Vector`), `algebra-field` (`Algebra.Field`), `memory-pool` (`Memory.Pool`).
- **Integration → recipient-then-provider** (the domain *receiving* the conferred structure first, the structure-*providing* domain second), mirroring the recipient-owned facet `Recipient.Provider`. Both tokens are independent domains. Examples: `bit-algebra` (Bit gains Algebra's structure), `cardinal-algebra`, `affine-algebra`.

Both collapse to one invariant ([PKG-NAME-001]): the package noun mirrors the namespace its surface occupies, **owner-first**. In decomposition the owner is the larger domain; in integration the owner is the recipient — its namespace gains the integration facet, and the structure-provider does NOT own the bridge.

**Distinguishing test**: is the second token an independent top-level domain that heads its own package family? NO (it exists only nested — `Ordered`, `Vector`, `Field`, `Pool`) → decomposition → larger-smaller. YES (both head families — `Bit` and `Algebra`) → integration → recipient-first. The recipient is the domain the value is conferred ON: the consumer who already holds the recipient type reaches for the bridge.

**Correct**:
```
swift-set-ordered-primitives     // decomposition: Set.Ordered
swift-bit-algebra-primitives     // integration: Bit (recipient) gains Algebra (provider) structure
```

**Incorrect**:
```
swift-ordered-set-primitives     // ❌ decomposition written recipient-first
swift-algebra-bit-primitives     // ❌ integration written provider-first (decomposition order misapplied)
```

**Known violations (RESOLVED 2026-05-29)**: `swift-algebra-cardinal-primitives` (surface `extension Cardinal`, e.g. `Cardinal.Monoid`) and `swift-algebra-affine-primitives` (`extension Affine.Discrete.Vector`) applied decomposition order to integrations; both were **renamed to the conforming forms `swift-cardinal-algebra-primitives` / `swift-affine-algebra-primitives`** (algebra-consolidation arc P4; repos renamed, PRIVATE preserved, old names gone). NOT violations: `algebra-field` / `algebra-ring` / `algebra-group` / `algebra-module` / `algebra-modular` / `algebra-semiring` / `algebra-law` — these genuinely decompose `Algebra` (their types nest under `Algebra.*`), so larger-smaller is correct for them.

**Collision caveat**: when the conferred-structure token would collide with an established unrelated concept in the recipient's space, choose the structural-domain noun over the specific structure. E.g. `bit-field` collides with the C "bit field"; use `bit-algebra` (the algebra bridge) rather than `bit-field`.

**Backward compatibility**: ADDITIVE — governs future bridge names and documents the existing-correct `algebra-<substructure>` family. The two known-violation renames are separate BREAKING changes, **executed 2026-05-29** (algebra-consolidation arc P4) — not by this rule itself.


**Cross-references**: [PKG-NAME-001], [PKG-NAME-005], [API-NAME-001], [MOD-014] (cross-package optional integration — the integration packages this orders), [MOD-029]

---

### [PKG-NAME-017] L1 Package Name Mirrors the Shipped Surface (Per-Layer Register Rule)

**Statement**: An L1 package's name MUST be the layer-affixed kebab form of the surface it ships:

- **(a) Root namespace path** when a root exists — the package declares `enum X` (or struct-namespace) with `X.Protocol` and/or `X.Witness` nested (`swift-buffer-linear-primitives` ⇄ `Buffer.Linear`, `swift-iterator-primitives` ⇄ `Iterator`);
- **(b) Recipient ⊗ provider token pair** for integration bridges per [PKG-NAME-016] (`swift-empty-iterator-primitives` ⇄ `Empty: Iterator.Protocol`);
- **(c) Family label** ONLY in a root vacuum — no shipped type's name can serve as the mirror (`swift-dimension-primitives` ⇄ Axis/Interval/Winding; likewise `symmetry`, `package`, `structured-queries`). Root-existence test (binary, greppable): the package declares `enum X` with `X.Protocol` and/or `X.Witness` nested. Root exists → mirror; no root → family label. No vacuum → no field word;
- **(d) Protocol name** for pure-capability packages per [PKG-NAME-009] (`swift-carrier-primitives` ⇄ `Carrier`).

The L1 package level introduces NO independent vocabulary: deverbal activity nouns (*iteration*, *serialization*, *parsing*) MUST NOT name a machine-domain package whose root exists — the agent-noun namespace names it ([PKG-NAME-001]) and the deverbal noun stays reserved for the witness alias ([PKG-NAME-015]).

**Register table (normative)** — a package name keys to its layer's identity-giving property; field vocabulary belongs to L3+, never to an L1 cell:

| Layer | Unit identity | Name register | Rule | Instances |
|---|---|---|---|---|
| L1 primitives | a vocabulary cell — the shipped namespace/family | **mirror** (object noun) | this rule + [PKG-NAME-001]/[PKG-NAME-016] | `swift-parser-primitives` ⇄ `Parser`; the ~221-package census |
| L2 standards | an external specification | **authority/spec ID** | [PKG-NAME-011] — NOT this rule | `swift-ieee-1003`, `swift-rfc-*` |
| L3+ foundations | a composed capability — a field | **field/umbrella/plural** | existing practice | `swift-file-system`, `swift-executors`, `swift-clocks` |

A field word (`serialization`, `iteration`) is *reserved for* the L3+ register and MUST NOT be spent on an L1 cell — spending it at L1 forecloses the correctly-sized L3 umbrella name (`swift-serialization` / `swift-iteration` remain the legitimate home of the field instinct).

**Rationale**: package names are `-primitives`-headed compounds whose modifier is classificatory — the object noun already supplies the domain reading (Levi 1978 FOR-relation); agent nominals are participant-denoting and unambiguous where deverbal nominals are event/result-ambiguous (Rappaport Hovav & Levin 1992; Grimshaw 1990); every surveyed ecosystem places field words at grouping nodes and object nouns at cells (Go `encoding/json`, Python `email.parser`, Rust `std::iter` → `Iterator`, Java `java.util.concurrent` → `Executor`); the root namespace is the package's only time-invariant property — content character is a phase that migrations change; 221-cell derivability and the 9,906-line stem-identity surface. Domain-naming at L1 was evaluated and REJECTED 2026-06-12, cancelling the suspended `iterator→iteration` rename class with it.

**Enforcement**: Mechanical — `validate-package-naming.py` [PKG-NAME-017] check (/promote-rule 2026-07-06): root detection via `X[.Y].{Protocol,Witness}.swift` filenames (conformance `+`-files excluded), ancestor-path kebab match; family-label (no-root) packages skip. Three live findings, all tower-terrain, adjudication tower-gated: `Audits/PROMOTE-PKG-NAME-017-2026-07-06.md`. [VERIFICATION: WF]

**Backward compatibility**: ADDITIVE — ratifies the live census (no package violates; the would-have-been rename class is CANCELLED, not migrated).


**Cross-references**: [PKG-NAME-001], [PKG-NAME-005], [PKG-NAME-009], [PKG-NAME-011], [PKG-NAME-015], [PKG-NAME-016]

---

### [PKG-DEP-010] Forbidden Third-Party Dependencies

**Statement**: `pointfreeco/*` packages and `swift-standards/swift-standards`
MUST NOT appear anywhere in an institute package's dependency closure — direct
or transitive, current manifests or old-tag graphs. Sole exception:
`pointfreeco/swift-macro-testing`, and only inside a nested test package per
[INST-TEST-001]. There is NO grandfathering and no "resolves with another
arc": every occurrence is an ACTIVE migration item onto the institute
equivalent, not a pin to manage — including in-flight rewrites, which must
land on institute engines, not third-party forks.

**Scope — the ban is on package IDENTITY, not DSL shape** (principal
clarification 2026-07-11): the root cause is SPM package-identity collision
from same-name packages (catalog §A26), NOT the API/DSL surface. An
institute-IMPLEMENTED DSL of pointfree-compatible SHAPE — matching type names
like `OneOf`/`Parse`/`Router` in institute-owned modules — is acceptable. What
is forbidden is any `pointfreeco` PACKAGE in the graph AND any institute module
or package named identically to a pointfree one (no `Parsing` module, no
`swift-parsing`-identity package). Ratified for the url-routing W2 compat-DSL.

**Rationale**: the institute vends its own equivalent for each such surface;
third-party pins re-import the dependency classes the ecosystem exists to
replace (Foundation coupling, untyped throws, compound naming), and their
old-tag graphs grind the version solver against mirror-redirected mains.

**Cross-references**: [PKG-DEP-001], [PKG-DEP-009], [INST-TEST-001]

---

### [PKG-DEP-011] One Manifest Per Package (No Variant Manifests)

**Statement**: Each package carries exactly ONE `Package.swift`.
`Package@swift-*.swift` variant manifests are FORBIDDEN (removed fleet-wide
2026-07-10); the single manifest normalizes to institute norms — current
tools version, `.v26` platform floors, canonical `.git` + `branch:"main"`
institute dep spellings per [PKG-DEP-009].

**Rationale**: a governing variant silently overrides the `Package.swift`
that every reader and tool edits, hiding legacy deps and floors (origin
incident: a variant@6.0 governed over a tools-5.10 main; the version solver
ground ancient tag graphs for 20+ minutes before anyone found the variant).

**Cross-references**: [PKG-DEP-001], [PKG-DEP-009]

---

### [PKG-DEP-012] Consumer Sweep in the Same Arc as a Breaking Public-Surface Change

**Statement**: When a package reshapes its public surface in a way that breaks
consumers (a renamed/removed/re-typed public symbol, a dissolved dependency, a
vanished method), the SAME arc MUST run a consumer sweep: grep the direct
consumers of the changed surface and rebuild them, fixing or filing the
breakage then and there. Do NOT land the breaking change and leave red
consumer trees for an unrelated later arc to discover.

**Rationale**: a breaking surface change with no consumer sweep converts every
downstream consumer into a latent failure that surfaces at the worst time —
mid-way through an unrelated arc that now has to diagnose a breakage it did not
cause. Same-arc evidence 2026-07-11: a mailgun surface reshape left 77 rows of
consumer drift; a dissolved `whatwg-url-encoding` left a dangling dependency; a
`.render()` method vanished mid-wave and stranded its callers. The producing
arc holds all the context to fix the consumers cheaply; a later arc pays full
re-diagnosis cost.

**Cross-references**: [PKG-DEP-007], [PKG-DEP-010], [PKG-BUILD-019]

---

## Cross-References

- **swift-institute** — layer architecture ([ARCH-LAYER-*])
- **primitives** — L1 Foundation-independence ([PRIM-FOUND-*])
- **code-surface** — type-level naming ([API-NAME-*]), one type per file
- **research-process** — promotion path for convention research to skill
