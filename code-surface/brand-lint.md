## Brand-Owner Lint Configuration

### [API-IMPL-024] No Redundant Protocol-Refinement Restatement

**Statement**: A protocol composition or conformance clause MUST NOT restate a protocol that another stated member already refines — the compiler enforces the parent through the refinement.

```swift
func sort<T: Comparable>(_: [T])              // ✓ Equatable comes with Comparable
func sort<T: Comparable & Equatable>(_: [T])  // ❌ redundant: Comparable refines Equatable
```

**Enforcement**: Mechanical — AST `Lint.Rule.Idiom.RedundantRefinement` (`redundant refinement`, universal tier; stdlib refinement table). Rule authored 2026-07-06 as the diagnostic's owning canon (principal ruling). [VERIFICATION: AST]

---

### [API-BRAND-001] Brand-Owner Exclusion Vocabulary

**Statement**: Brand-owner packages (those whose primary export is a wrapper or marker establishing a brand — `Cardinal`, `Ordinal`, `Cyclic.Group.Static<n>.Element`, `Carrier.\`Protocol\`` etc.) MUST declare a per-package `Lint.swift` that excludes the rules targeting their brand-boundary vocabulary, while keeping the rule corpus brand-form-agnostic. The exclusion vocabulary varies by brand-form (protocol-form vs value-form).

**The principle**: The rule corpus is brand-form-agnostic by design — rules target idioms that are anti-patterns FOR EXTERNAL CONSUMERS but are the brand-owner's own protocol-witness or wrapper-boundary surface. The corpus stays uniform; the per-package `excluding(rules:)` declares which rules apply to external consumers but NOT to the brand-owner's own brand-boundary.

**Brand-form distinction**:

- **Protocol-form brand-owner**: the brand is a refinement protocol (e.g., `Carrier.\`Protocol\``). Consumers conform their own types to the protocol. The brand-owner's own surface is the protocol declaration + in-package conformer fixtures.
- **Value-form brand-owner**: the brand is a wrapping value type (e.g., `Cardinal` wraps `UInt`; `Ordinal` wraps `UInt`; `Cyclic.Group.Static<n>.Element` wraps `Ordinal`). The brand-owner's own surface is the wrapper type + its `__unchecked:` constructors + its `.rawValue` accessor + its arithmetic/integration overloads.

**Protocol-form exclusion vocabulary** (1 rule):

| Rule ID | Reason for exclusion at protocol-form brand-owner |
|---|---|
| `int public parameter` | In-package `Carrier.\`Protocol\`` conformers with `Underlying == Int` take `Int` directly because `Int` IS the Underlying being wrapped at the brand boundary. |

**Value-form exclusion vocabulary** (per-brand subset; the rules each value-form brand-owner MAY exclude depending on which boundary vocabulary surfaces in its API):

| Rule ID | Reason for exclusion at value-form brand-owner |
|---|---|
| `raw value access` | The brand-owner exposes `.rawValue` (or the wrapper's underlying access) at its canonical boundary. |
| `chained rawvalue access` | Same — the brand-owner is the legitimate `.rawValue` chain origin. |
| `bitpattern rawvalue chain` | Stdlib-integration overloads at the brand boundary chain `.rawValue` into `Int.init(bitPattern:)` patterns. |
| `int public parameter` | Stdlib-mirror overloads accept bare `Int` at the brand-boundary integration sites (matches the wrapped type's stdlib API). |
| `pointer advanced by` | Pointer-arithmetic stdlib-mirror overloads at the brand boundary. |
| `unchecked call site` | The brand-owner's `__unchecked:` constructors are the canonical bypass-validation entry. |
| `zero or one literal` | The brand-owner defines `.zero` / `.one` via integer literals at the wrapper's identity-element accessors. |
| `tagged extension public init` | The brand-owner's `Tagged+<Brand>.swift` extension exposes the `Tagged<Tag, Brand>` public init at the brand-domain typed-ID boundary. |

**How to apply**:

1. **Identify the brand**: what type or protocol does this package PRIMARILY export as a wrapper or marker? If it's a refinement protocol consumers conform to, it's protocol-form. If it's a wrapping value type with `__unchecked:` constructors and `.rawValue` access, it's value-form.
2. **Select exclusion subset**: from the appropriate vocabulary table above, exclude only those rules that fire on legitimate-by-construction brand-boundary sites in your package. The exclusion subset is the empirical minimum — don't exclude rules just because the vocabulary lists them; exclude only what fires on your actual surface.
3. **Declare in `Lint.swift`**: use `Lint.Rule.Bundle.primitives.excluding(rules: [ Lint.Rule.\`name\`.id, ... ])` (or the equivalent bundle for non-primitives tiers). Cite each exclusion with a `// reason:` comment naming the specific brand-boundary site that justifies it.
4. **Cross-package consumers**: external consumers using your brand should NOT exclude these rules. The corpus's strict-superset firing on external consumers IS the architectural intent.

**Rationale**: each excluded rule remains in the corpus and fires on every other consumer — brand-owners declare their boundary, not bypass the rule. Full text (per-package cohort empirical exclusion table, provenance): rationale archive §[API-BRAND-001].

**Composes with**:
- `[API-NAME-001c]` (capability-marker protocol) — value-form brand-owners often appear as `Carrier.\`Protocol\`` conformers via the capability-marker recipe.
- Rule corpus design principle: each excluded rule remains in the corpus and fires on every other consumer. The corpus stays uniform; brand-owners declare their boundary, not bypass the rule.

**Lint enforcement**: AST mechanization TBD. The configuration discipline (which exclusions a brand-owner declares, the per-entry justification comment, the protocol-form vs value-form cardinality split) is codified as `[LINT-EXCLUDE-001]` through `[LINT-EXCLUDE-004]` in the **swift-linter** skill — the linter-side application of the brand-owner vocabulary defined in this rule. Future AST candidates: rationale archive §[API-BRAND-001].

**Cross-references**: [API-NAME-001c] (capability-marker protocol); [API-IMPL-008] (minimal type body — companion note covers protocol-witness methods on associatedtype-using storage, the case that arose during the cohort cyclic.Iterator refactor); **swift-linter** skill `[LINT-EXCLUDE-*]` (linter-side application of this vocabulary).

---

