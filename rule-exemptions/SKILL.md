---
name: rule-exemptions
description: |
  Seven recurring exemption shapes for the linter rule corpus.
  Apply when authoring or amending a custom lint rule whose firing
  intersects a deliberate institute or stdlib pattern.

layer: process

requires:
  - swift-institute-core
  - code-surface

applies_to:
  - swift
  - swift6
  - lint-rule-author
created: 2026-05-12
---

# Rule Exemptions

Seven exemption shapes — six empirically validated across Wave 2 of the
2026-05-11 rule-amendment campaign (see
`swift-foundations/swift-linter-rules/Research/wave-2-rule-amendments-2026-05-11.md`),
plus the SwiftSyntax-visitor-subclass shape ([RULE-EXEMPT-7]) added in
Thread C of the 2026-05-12 rule-pack-dogfeed triage (see
`swift-foundations/swift-linter-rules/Research/2026-05-12-thread-b-rule-pack-dogfeed-triage.md`).
Each shape recurs across multiple rule packs and represents a *structural*
reason a rule should not fire — not a discretionary opt-out. Rule authors
MUST cite the shape's `[RULE-EXEMPT-N]` ID at the exemption site and reuse
the named helper.

The goal is to promote each shape from per-rule re-derivation to a
citable, named pattern. Lookup-form helpers live in each rule pack's
shared file (`Lint.Rule.<Pack>.Shared.swift`); cross-pack visibility is
not yet available, so the lightweight helpers may be duplicated across
packs — the citation comment carries the unification.

**Citation form** at the rule's exemption site:

```swift
// Exempt per [RULE-EXEMPT-N] (<short-name>): <one-line why>.
if <helperCall(node)> {
    return .visitChildren
}
```

**Canonical references**:

- `swift-foundations/swift-linter-rules/Research/wave-2-rule-amendments-2026-05-11.md` — Wave 2 dispatch ledger.
- `swift-foundations/swift-linter-rules/Research/wave-3-aggregate-2026-05-11.md` — v1.2.0 closeout aggregate.

---

## Shape Catalog

| ID | Short Name | Helper (lookup form) | Adopting Rules |
|----|-----------|----------------------|----------------|
| [RULE-EXEMPT-1] | positive-Copyable | `memoryWhereClauseHasPositiveCopyable(_:)` | `Lint.Rule.Memory.ExtensionNoncopyableConstraint` |
| [RULE-EXEMPT-2] | protocol-witness-citation-dict | `[String: <Citation>]` dict + conformance-context gate | `Lint.Rule.Naming.Compound`, `Lint.Rule.Throws.Existential`, `Lint.Rule.RawValue.TaggedExtensionPublicInit` |
| [RULE-EXEMPT-3] | conformance-context | `namingIsInsideConformingContext(_:)` | `Lint.Rule.Naming.UnificationTypealias`, `Lint.Rule.Naming.Compound`, `Lint.Rule.Platform.TypealiasedNamespace` |
| [RULE-EXEMPT-4] | extension-pattern attribute | `namingIsInsideExtensionPatternType(_:)` / `namingHasExtensionPatternAttribute(_:)` | `Lint.Rule.Naming.Compound`, `Lint.Rule.Naming.IntParameter`, `Lint.Rule.Naming.BoolParameter`, `Lint.Rule.Structure.MinimalTypeBody` |
| [RULE-EXEMPT-5] | Protocol-sentinel | `namingIsProtocolSentinelName(_:)` | `Lint.Rule.Naming.UnificationTypealias`, `Lint.Rule.Structure.MinimalTypeBody` |
| [RULE-EXEMPT-6] | stdlib-shadow | `platformSwiftQualificationIsInsideStdlibExtension(_:)` | `Lint.Rule.Platform.SwiftQualification` |
| [RULE-EXEMPT-7] | syntax-visitor-subclass | `structureExtendsSyntaxVisitor(_:)` / `namingExtendsSyntaxVisitor(_:)` | `Lint.Rule.Structure.MinimalTypeBody`, `Lint.Rule.Naming.CompoundType` |

---

## [RULE-EXEMPT-1] positive-Copyable

**Statement**: A rule that fires on the *absence* of a `~Copyable`-related
signal (`~Copyable` constraint, `~Copyable` conformance, etc.) MUST exempt
declarations whose where-clause carries an *explicit positive* `Copyable`
conformance requirement. The author has deliberately scoped the surface
to Copyable element types; firing the rule inverts the intent.

**Why**: A rule that demands a `where Element: ~Copyable` constraint
treats absence as accidental shrinkage to Copyable. A `where Element: Copyable`
is the opposite signal: an explicit author choice to keep the surface
Copyable-only. Treating that as a violation prescribes the inverse of
the author's documented intent.

**How to apply**:

1. At the call site (rule's visitor), call the lookup helper
   `memoryWhereClauseHasPositiveCopyable(_:)` (or the pack-local
   equivalent — the helper is internal to the pack hosting the rule).
2. The helper walks the generic where clause for any
   `ConformanceRequirementSyntax` whose right side trims to bare
   `Copyable` (no tilde). Composition forms (`Base: Comparable & Copyable`)
   are descended into.
3. If true, return `.visitChildren` (no finding) with the citation
   comment.

**Example**:

```swift
// Exempt per [RULE-EXEMPT-1] (positive-Copyable): author explicitly
// scoped to a Copyable surface; the rule's "implicit shrink to
// Copyable" premise is inverted by the explicit conformance.
guard !memoryWhereClauseHasPositiveCopyable(node.genericWhereClause) else {
    return .visitChildren
}
```

**Adopting rules**:

- `Lint.Rule.Memory.ExtensionNoncopyableConstraint` (lives in
  swift-foundations/swift-linter-rules, target `Linter Rule Memory`).

**Source signal**: swift-product-primitives, swift-property-primitives,
swift-comparison-primitives.

---

## [RULE-EXEMPT-2] protocol-witness-citation-dict

**Statement**: A rule that fires on a method / initializer / property name
whose *exact name* is a protocol-required witness MUST exempt the
declaration when both conditions hold:

1. The name appears as a key in a static `[String: <Citation>]` dict
   declared adjacent to the rule, and
2. The enclosing context (extension or type decl) declares conformance
   to the corresponding protocol.

The dict is the citation surface — each entry pairs a witness name with
the specific protocol whose contract dictates it. Adding an entry without
a citation is indefensible at review time. The conformance-context gate
([RULE-EXEMPT-3]) ensures the same name outside the conformance context
still fires.

**Why**: Stdlib (and institute) protocols dictate names that a free
choice would never spell that way (`flatMap`, `init(from:)`, `encode(to:)`,
`makeIterator`, `init(integerLiteral:)`). A naming or shape rule that
flags the conformer is asking the conformer to break the protocol's
contract. The exemption is structural, not discretionary — without it,
conformance is impossible.

**How to apply**:

1. Author the dict at the rule's file level:

   ```swift
   @usableFromInline
   internal let <ruleName>WitnessCitations: [String: String] = [
       "<witnessName>": "<Swift.Protocol.method() — why exempt>",
   ]
   ```

2. In the visitor: when the name matches a dict key, call
   `namingConformanceProtocolNames(Syntax(node))` (from
   `Lint.Rule.Naming.Shared.swift`) — or the pack-local conformance
   walker if Naming.Shared isn't reachable — to retrieve the leaf names
   of the enclosing context's inheritance clause.
3. If the cited protocol is in the inheritance leaf set, return
   `.visitChildren` with the citation comment.

**Dict shape variants**:

- Simple `[String: String]` — the citation IS the value. Used by
  `namingCompoundProtocolWitnessMethodCitations` in
  `Lint.Rule.Naming.Compound.swift`.
- Tuple-valued — when the same witness key can satisfy multiple
  protocols. Used by `throwsExistentialStdlibProtocolWitnessCitations`
  in `Lint.Rule.Throws.Existential.swift`:
  `[String: (witness: String, protocols: [String])]`.

**Example**:

```swift
// Exempt per [RULE-EXEMPT-2] (protocol-witness-citation-dict):
// `encodeAtomicRepresentation` is `Swift.AtomicRepresentable`'s
// protocol-required witness; the conformer cannot rename it.
if namingCompoundProtocolWitnessMethodCitations[name] != nil {
    let conformances = namingConformanceProtocolNames(Syntax(node))
    if !conformances.isEmpty {
        return .visitChildren
    }
}
```

**Adopting rules**:

- `Lint.Rule.Naming.Compound` —
  `namingCompoundProtocolWitnessMethodCitations` (3 entries).
- `Lint.Rule.Throws.Existential` —
  `throwsExistentialStdlibProtocolWitnessCitations` (2 entries,
  tuple-valued).
- `Lint.Rule.RawValue.TaggedExtensionPublicInit` —
  `taggedExtensionPublicInitProtocolWitnessCitations` (14 entries,
  gates entire extension).

**Source signal**: swift-either-primitives (6 `flatMap` findings),
swift-product-primitives (Existential×2), swift-tagged-primitives
(11 Tagged-init findings).

---

## [RULE-EXEMPT-3] conformance-context

**Statement**: A rule that fires on a declaration's *name* MUST exempt
the declaration when its nearest enclosing context (extension or type
decl) carries a non-empty inheritance clause AND the declaration's name
is one that the inheritance clause's protocols dictate (typealiases
satisfying associatedtypes, methods satisfying requirements, properties
satisfying property requirements).

**Why**: A typealias `Index` inside `extension Tagged: Collection`
satisfies `Collection.Index`. A method `makeIterator()` inside an
`extension X: Sequence` satisfies `Sequence.makeIterator()`. The name is
dictated by the protocol shape, not by a discretionary author choice.
Naming rules that target [API-NAME-002] (no compound identifiers),
[API-NAME-004] (rename-bridge typealiases), or [PLAT-ARCH-018]
(namespace-bridge typealiases) flag these false positives without the
gate.

**How to apply**:

1. Call `namingIsInsideConformingContext(_:)` from
   `Lint.Rule.Naming.Shared.swift` (institute pack) — or duplicate the
   short walker if cross-pack visibility isn't available.
2. The helper walks the parent chain. If the first enclosing
   `ExtensionDeclSyntax` / type decl has a non-empty `inheritanceClause`,
   returns true.
3. If true, the rule MAY exempt; the name is dictated by the protocol.

**Example**:

```swift
// Exempt per [RULE-EXEMPT-3] (conformance-context): typealias inside
// an extension whose inheritance clause names a protocol — the LHS
// name is dictated by the protocol's associatedtype, not by discretion.
if namingIsInsideConformingContext(Syntax(node)) {
    return .visitChildren
}
```

**When NOT to apply**: a rule whose firing is independent of the
declared name (e.g., an existential-throws rule that fires on the THROWS
clause shape) should pair this with [RULE-EXEMPT-2]'s witness-key
matching — bare conformance context is too coarse for shape rules.

**Adopting rules**:

- `Lint.Rule.Naming.UnificationTypealias` (associatedtype-satisfaction).
- `Lint.Rule.Naming.Compound` (witness-method allowlist gate).
- `Lint.Rule.Platform.TypealiasedNamespace`
  (associatedtype-satisfaction).

**Source signal**: swift-tagged-primitives (bridge × 3),
swift-carrier-primitives (minimal Protocol × 1).

---

## [RULE-EXEMPT-4] extension-pattern attribute

**Statement**: A rule that fires on a method / nested-type name or
on type-body composition MUST exempt declarations whose enclosing type
is annotated with an *extension-pattern attribute* — currently
`@resultBuilder` or `@Suite`. For `@resultBuilder`, the method's name
must additionally match one of the informal-protocol names
(`buildExpression`, `buildBlock`, `buildPartialBlock`, `buildOptional`,
`buildEither`, `buildArray`, `buildLimitedAvailability`,
`buildFinalResult`); for `@Suite`, no fixed method-name set applies —
the attribute alone is sufficient because swift-testing's
extension-pattern places `@Test` methods in extensions on nested
`@Suite` substructures rather than as direct members.

**Why**: An extension-pattern attribute IS the specification of the
type's member shape — the attribute alone determines which members the
compiler / framework expects. Two members of this family currently:

- `@resultBuilder` (Swift SE-0289 result-builder feature) — requires the
  exact static method names listed above on a type marked with the
  attribute. The conformer cannot rename them.
- `@Suite` (swift-testing) — legitimately holds nested `@Suite`
  substructures per the institute's [SWIFT-TEST-002] extension-pattern.
  The outer @Suite is a namespace container; tests live in extensions
  on the leaf @Suite types.

A naming rule treating builder methods as compound identifiers is
asking the type to break its `@resultBuilder` contract. A type-body
rule ([API-IMPL-008] minimal type body) demanding the static-method
members of a `@resultBuilder enum` move to an extension yields an
empty body + extension full of the actual builders — semantic-zero.
Likewise, demanding the nested `@Suite` substructures inside an outer
`@Suite` move to an extension breaks the extension-pattern's
namespace-shape.

**How to apply**:

1. For name-based rules: when the function name matches an entry in
   `namingResultBuilderProtocolMethods` (from
   `Lint.Rule.Naming.Shared.swift`) AND
   `namingIsInsideExtensionPatternType(Syntax(node))` returns true,
   exempt. The method-name set remains @resultBuilder-specific (Swift
   builder protocol method names); the helper widens to recognize both
   attributes — extending `@Suite` is benign because `buildBlock` etc.
   don't conventionally appear inside @Suite types.
2. For type-body rules: when visiting a struct / class / enum / actor
   decl, call `namingHasExtensionPatternAttribute(node.attributes)`
   (or pack-local equivalent). If true,
   `return .visitChildren` (skip the body check entirely).

**Example** (naming rule):

```swift
// Exempt per [RULE-EXEMPT-4] (extension-pattern attribute):
// protocol-required witness names on a @resultBuilder type;
// the attribute IS the spec.
if namingResultBuilderProtocolMethods.contains(name),
   namingIsInsideExtensionPatternType(Syntax(node)) {
    return .visitChildren
}
```

**Example** (type-body rule):

```swift
// Exempt per [RULE-EXEMPT-4] (extension-pattern attribute):
// the @resultBuilder / @Suite attribute dictates the type's
// member-shape surface; forcing extraction to an extension yields
// zero semantic gain.
if hasExtensionPatternAttribute(node.attributes) {
    return .visitChildren
}
```

**Adopting rules**:

- `Lint.Rule.Naming.Compound` (name-based gate, @resultBuilder method-name set).
- `Lint.Rule.Naming.IntParameter` (name-based gate, @resultBuilder method-name set).
- `Lint.Rule.Naming.BoolParameter` (name-based gate, @resultBuilder method-name set).
- `Lint.Rule.Structure.MinimalTypeBody` (type-body gate, both attributes).

**Source signal**: swift-standard-library-extensions (#14, 234
findings cleared) for the original @resultBuilder shape;
swift-foundations/swift-linter foundation-up dogfeed 2026-05-12 (11
findings cleared) for the @Suite extension.

---

## [RULE-EXEMPT-5] Protocol-sentinel

**Statement**: A rule that fires on a typealias or member named exactly
`Protocol` (or the backtick-escaped form `` `Protocol` ``) MUST exempt
the declaration when the rule's firing logic is naming-shape-based
rather than visibility- or content-based.

**Why**: The institute uses `Protocol` as a sentinel typealias name per
[API-IMPL-009] / [PKG-NAME-001]: a hoisted-protocol pattern where the
visible protocol is exposed via the type's nested namespace
(`Carrier.Protocol`, `Ordering.Protocol`) and the underscored
implementation lives at file scope. The `Protocol` typealias is
intentionally in the type body — extracting it to an extension yields
empty-body `enum X {}` with extension-with-one-typealias awkwardness
for zero semantic gain. Rename-bridge rules treating it as a foreign
namespace rename flag the institute pattern itself.

**How to apply**:

1. At a typealias-visit site or member-walk site, check the leaf token
   text against the literal strings `"Protocol"` and `` "`Protocol`" ``.
2. If matched, exempt. The matching is shallow on purpose — the
   sentinel is a single fixed name, not a family.

A free-function helper `namingIsProtocolSentinelName(_ name: String) -> Bool`
encapsulates the two-string check; pack-local duplication is acceptable
because the helper is one line.

**Example**:

```swift
// Exempt per [RULE-EXEMPT-5] (Protocol-sentinel): `Protocol` is the
// institute hoisted-protocol sentinel ([API-IMPL-009] / [PKG-NAME-001]);
// the typealias is intentionally in the type body.
if namingIsProtocolSentinelName(aliasName) {
    continue
}
```

**Adopting rules**:

- `Lint.Rule.Naming.UnificationTypealias` (RHS leaf `Protocol`).
- `Lint.Rule.Structure.MinimalTypeBody` (typealias name `Protocol`).
- `Lint.Rule.RawValue.TaggedExtensionPublicInit` (cited as a witness
  name in the protocol-witness dict — composes with [RULE-EXEMPT-2]).

**Source signal**: swift-carrier-primitives (minimal Protocol × 1),
swift-property-primitives (minimal Protocol × 1).

---

## [RULE-EXEMPT-6] stdlib-shadow

**Statement**: A rule that fires inside an extension MUST exempt sites
inside `extension <X> { ... }` where `X` is a stdlib type whose
declaration lives in the `Swift` module (`Set`, `Array`, `Dictionary`,
`String`, `Optional`, `Result`, etc.). The `Swift.<...>` qualification
the rule may prescribe is structurally inexpressible: inside the
extension, Swift name resolution treats the bare `Swift` identifier as
the type's nested scope, yielding `'X' is not a member type of 'Swift.<X>.Swift'`
at compile.

**Why**: The motivation is for rules that DEMAND a stdlib qualifier
(e.g., `swift protocol qualification` rule prescribing `some Swift.Sequence<UInt8>`).
Inside `extension Array { ... }`, that prescription is rejected at
type-check; the bare form `some Sequence<UInt8>` is the only legal
spelling and resolves correctly because stdlib-Array's extension scope
inherits stdlib's Sequence.

**How to apply**:

1. Maintain a set `<rule>StdlibShadowingTypes: Set<String>` of stdlib
   type names whose extensions trigger the shadow.
2. Implement `<rule>IsInsideStdlibExtension(_:)` that walks the parent
   chain to the nearest `ExtensionDeclSyntax`. If its extended type's
   leaf name is in the set, return true.
3. At each visit point (`InheritedTypeSyntax`, `GenericParameterSyntax`,
   etc.), call the predicate before checking.

**Example**:

```swift
override func visit(_ node: ConformanceRequirementSyntax) -> SyntaxVisitorContinueKind {
    // Exempt per [RULE-EXEMPT-6] (stdlib-shadow): inside an
    // extension on a stdlib type, the `Swift.<Protocol>` form the
    // rule prescribes is structurally inexpressible.
    if platformSwiftQualificationIsInsideStdlibExtension(Syntax(node)) {
        return .visitChildren
    }
    check(node.rightType)
    return .visitChildren
}
```

**Adopting rules**:

- `Lint.Rule.Platform.SwiftQualification`.

**Source signal**: swift-standard-library-extensions (#19, 1 finding
cleared).

---

## [RULE-EXEMPT-7] syntax-visitor-subclass

**Statement**: A rule that fires on a class declaration's *name* or on its
*body composition* MUST exempt class declarations whose inheritance clause
includes a member of the SwiftSyntax visitor family — currently
`SyntaxVisitor`, `SyntaxAnyVisitor`, `SyntaxRewriter`. The base class
dictates the subclass's member shape (mandatory `override func visit(_:)`
hooks per syntax-kind) and its naming convention (`<RuleName>Visitor`,
which is structurally compound).

**Why**: The SwiftSyntax visitor pattern colocates state, init, and
`override func visit(_:)` overrides inside a `final class XVisitor:
SyntaxVisitor` body. The base class is an *open class* whose per-syntax-kind
visitation hooks are the subclass's only legitimate extension surface —
their NAMES (`visit`, `visitPost`) and SIGNATURES are dictated by the
parent class. Moving the overrides to extensions yields a
`final class XVisitor { /* stored properties + init */ }` paired with an
extension full of override implementations for zero semantic gain; the
overrides cannot stand alone because they reference per-instance state.
The class-NAME constraint is also structural: the SwiftSyntax convention
is `<Subject>Visitor`, which trips [API-NAME-001] (compound type name)
even though the suffix is dictated by the framework's idiom.

The same rationale that broadens [RULE-EXEMPT-4] to `@resultBuilder` and
`@Suite` applies: the parent type's contract dictates the member shape;
the rule should not fire.

**How to apply**:

1. For type-body rules visiting a class declaration: call
   `<pack>ExtendsSyntaxVisitor(node.inheritanceClause)`. If true, return
   `.visitChildren` (skip the body check entirely).
2. For name-shape rules visiting a class declaration: call the same
   helper on the inheritance clause. If true, return `.visitChildren`
   without firing the compound-name check.
3. The helper walks the inheritance clause leaf names and returns true if
   any name is in the SwiftSyntax visitor family set
   (`SyntaxVisitor`, `SyntaxAnyVisitor`, `SyntaxRewriter`). Leaf-name
   semantics match `namingInheritanceLeafNames` — both bare and
   `SwiftSyntax.SyntaxVisitor` qualifications resolve to `"SyntaxVisitor"`.

A pack-local helper named `<pack>ExtendsSyntaxVisitor(_:)` (e.g.
`structureExtendsSyntaxVisitor`, `namingExtendsSyntaxVisitor`)
encapsulates the leaf-name check; pack-local duplication is acceptable
because cross-pack visibility isn't yet available and the helper is short.

**Example** (type-body rule):

```swift
override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    if hasExtensionPatternAttribute(node.attributes) {
        return .visitChildren
    }
    // Exempt per [RULE-EXEMPT-7] (syntax-visitor-subclass): the
    // SwiftSyntax visitor family's `override func visit(_:)` hooks
    // are protocol-shaped members dictated by the base class.
    if structureExtendsSyntaxVisitor(node.inheritanceClause) {
        return .visitChildren
    }
    checkMembers(node.memberBlock.members)
    return .visitChildren
}
```

**Example** (name-shape rule):

```swift
override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
    // Exempt per [RULE-EXEMPT-7] (syntax-visitor-subclass): the
    // SwiftSyntax convention names visitor subclasses `<Subject>Visitor`,
    // which trips compound-name even though the suffix is dictated by
    // the framework's idiom.
    if namingExtendsSyntaxVisitor(node.inheritanceClause) {
        return .visitChildren
    }
    check(name: node.name, modifiers: node.modifiers)
    return .visitChildren
}
```

**Adopting rules**:

- `Lint.Rule.Structure.MinimalTypeBody` (type-body gate — closes
  ~336 findings across the three rule packs).
- `Lint.Rule.Naming.CompoundType` (name-shape gate — closes ~17
  findings across the institute + primitives rule packs).

**Source signal**: Thread B rule-pack dogfeed 2026-05-12
(`swift-foundations/swift-linter-rules/Research/2026-05-12-thread-b-rule-pack-dogfeed-triage.md`)
surfaced A4 (336 MinimalTypeBody findings) + A5 (17 CompoundType findings)
as a single dominant defect class driven by the SwiftSyntax visitor
pattern's structural co-presence of state, init, and protocol-shaped
visit overrides inside the class body.

---

## Cross-shape composition

Some declarations are exempt by multiple shapes simultaneously. The
rule's visit logic SHOULD short-circuit on the first match — order
matters only for readability:

| Composing shapes | Where seen |
|------------------|-----------|
| [RULE-EXEMPT-2] + [RULE-EXEMPT-5] | `Lint.Rule.RawValue.TaggedExtensionPublicInit` — `Protocol` listed in the protocol-witness dict |
| [RULE-EXEMPT-2] + [RULE-EXEMPT-3] | `Lint.Rule.Naming.Compound` — witness names dict + conformance-context gate |
| [RULE-EXEMPT-3] + [RULE-EXEMPT-5] | `Lint.Rule.Naming.UnificationTypealias` — both gates fire on the typealias |
| [RULE-EXEMPT-4] (type-level) + [RULE-EXEMPT-4] (member-level) | `Lint.Rule.Structure.MinimalTypeBody` — both the visited type and its nested types' attributes are checked |
| [RULE-EXEMPT-4] + [RULE-EXEMPT-7] | `Lint.Rule.Structure.MinimalTypeBody` — class-decl visitor short-circuits on `@resultBuilder`/`@Suite` first, then on SwiftSyntax visitor-family inheritance |

---

## Cross-references

- `[API-NAME-002]` (code-surface) — the rule [RULE-EXEMPT-2]/[RULE-EXEMPT-3]
  primarily defends.
- `[API-IMPL-008]` (code-surface) — the rule [RULE-EXEMPT-4]/[RULE-EXEMPT-5]/[RULE-EXEMPT-7]
  primarily defends.
- `[API-NAME-001]` (code-surface) — the rule [RULE-EXEMPT-7] additionally
  defends (visitor-family subclasses follow `<Subject>Visitor` naming).
- `[MEM-COPY-004]` (memory-safety) — the rule [RULE-EXEMPT-1] primarily
  defends.
- `[PLAT-ARCH-022]` (platform) — the rule [RULE-EXEMPT-6] primarily
  defends.

**Source dispatch ledger**:
`swift-foundations/swift-linter-rules/Research/wave-2-rule-amendments-2026-05-11.md`.
