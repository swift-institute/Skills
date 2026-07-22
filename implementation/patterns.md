# Absorbed Patterns

Part of the **implementation** skill. Rules absorbed from the former `anti-patterns` and `design` skills, plus semantic-dependency rules. Rules whose canonical home is another skill have been removed — see the Skill Index in [`swift-institute-core`](../swift-institute-core/SKILL.md) for the routing table.

For the foundational axioms ([IMPL-INTENT], [IMPL-000], [IMPL-001], [IMPL-COMPILE]) and the rule index, see `SKILL.md`. The `~Copyable`-specific nested-types rule [PATTERN-022] lives in `ownership.md`.

**Rules in this file**: [API-LAYER-001], [API-LAYER-002], [PATTERN-012], [PATTERN-013], [PATTERN-016], [PATTERN-017], [PATTERN-019], [PATTERN-020], [PATTERN-025] – [PATTERN-029], [PATTERN-052] – [PATTERN-063], [SEM-DEP-006], [SEM-DEP-008], [SEM-DEP-009].

---

## Anti-Pattern Reference

| ID | Statement | Cross-ref |
|----|-----------|-----------|
| [PATTERN-012] | Canonical implementation for type transformations MUST live in initializers or static methods on the target type | — |
| [PATTERN-013] | Protocols MUST NOT be designed before having 3+ concrete conformers; even with 3+ conformers, if unification would force axis-divergent signatures to lose information, concrete sibling types are preferred (lossy-unification criterion) | [IMPL-084], [IMPL-090] |
| [PATTERN-016] | Code violating a pattern MAY be acceptable when intentional, documented (`// WORKAROUND:`, `// WHY:`, `// WHEN TO REMOVE:`, `// TRACKING:`), bounded, and has specific removal criteria | — |
| [PATTERN-017] | `.rawValue` and `.position` MUST be confined to extension initializers and same-package implementations | [IMPL-002], [CONV-001] |
| [PATTERN-019] | Extensions on `Tagged where RawValue == T` MUST NOT provide public `init` — bypasses bounded invariants | [IMPL-001] |
| [PATTERN-020] | A throwing init on a wrapper MUST NOT validate only the base type's invariant when the wrapper specializes to stricter types | [PATTERN-019] |
| [PATTERN-054] | When tempted to invent a named type for a composition, verify academic grounding; if the composition has no standard construct, extend an existing primitive with a named method rather than minting a new type | [IMPL-INTENT], [IMPL-060], [PATTERN-013] |
| [PATTERN-055] | `@usableFromInline` property paired with `internal import` of the property's type is a compile error — downgrade visibility or make the import `public` / `package` | [PATTERN-052] |
| [PATTERN-056] | Dead-case-per-platform enum — a public enum with N unconditional cases where, on any given runtime platform, only one case is ever constructed from real data, is an anti-pattern. Signal: consumers `switch` with a dead branch per platform; construction site has `#if` picking the case. Fix: replace with the ecosystem's existing platform-conditional typealias (`Path.Char`, `String.Char`) for storage; add a local `Encoding` typealias (`UTF8`/`UTF16`) for decoder calls. Red flag: if an enum's case count equals the ecosystem's supported platform count and each case is unconditional, check whether `Path.Char`/`String.Char` already carries the distinction. Case study: `File.Name.RawEncoding` → `[Path.Char]`. | [IMPL-060], [INFRA-*] |
| [PATTERN-057] | Defensive naming at primitive layers is optimizing the wrong axis — when a defensive name at L1 (e.g., `RenderBody` instead of `Body`) is motivated entirely by a collision at one L3 bridge site (e.g., `HTML.Document` bridging `Rendering.View` and `SwiftUI.View`), every L1 conformer pays a compound-name tax for a problem it doesn't have. Prefer `@_implements(Protocol, Name)` at the bridge site — Swift's `AssociatedTypeImplements` language feature (baseline since 2019) lets a bridge type stamp its associated-type bindings per-protocol. For bridges to protocols whose `Body == Never` is fixed by a same-type constraint (`NSViewRepresentable`, `UIViewRepresentable`), the *two-stamp* pattern is required: one stamp per protocol whose `Body` requirement needs binding. When the compiler emits *"multiple matching types named 'Body'"*, the fix is to *add* another `@_implements` stamp, not to *narrow* candidates by renaming the generic parameter. Case study: `Rendering.View.Body` vs `SwiftUI.View.Body`, resolved at `HTML.Document`. | [PATTERN-016], primitives skill |
| [PATTERN-058] | `.enumerated()` + subscript-by-Int on custom Collections silently breaks semantics — when a `Collection.Index` is a domain-specific Int (byte position, token offset) rather than a 0-based element offset, callers using `for (i, _) in collection.enumerated() { use(collection[i]) }` assume element offsets and get wrong semantics with no compiler warning. Prefer iterator-based comparison (`makeIterator().next()`) or `zip(a, b)` over `.enumerated()` + subscript for non-Array Collections. Case study: `Paths.Path.Components` is a lazy `BidirectionalCollection` whose `Index` is a byte position; `hasPrefix` subscript bug caught only by code review. | — |
| [PATTERN-062] | Inline layer-replacement during migration — rewriting call sites with hardcoded / manual substitutes (hardcoded bytes, manual loops) when moving code between layers — is an anti-pattern. Preserve the original API surface and call-site syntax; move the underlying infrastructure (protocols, extensions, wrappers) DOWN to the target layer instead of inlining a replacement at each consumer. If the feature depends on higher-layer types, factor out the layer-agnostic part. (The byte-domain instance is [API-BYTE-008]'s "lift the parameter, don't bridge in the body".) Provenance: memory `feedback_preserve_original_syntax.md`. | [PATTERN-026], [PATTERN-053], [API-BYTE-008] |
| [PATTERN-063] | No `for`-loops in result-builder bodies — a `for`-loop in a builder body materializes a fresh `[Element]` per iteration (12–44× slower than imperative under SE-0289); write the sequence directly (`Builder { 0..<N }`, not `Builder { for i in 0..<N { i } }`). Genuinely-required iteration escalates + uses disable-with-reason. Enforcement: Mechanical — AST `Lint.Rule.ResultBuilder.ForLoop` (universal tier); rationale: `swift-institute/Research/result-builder-performance-optimization.md` (DECISION v2.0.0). Rule authored 2026-07-06 as the diagnostic's owning canon (principal ruling). [VERIFICATION: AST] | — |

**Lint enforcement (per-rule, Anti-Pattern Reference)**:

- **[PATTERN-016]**: SwiftLint custom rule `workaround_marker_present` (`swift-institute/.github/.swiftlint.yml`) flags `WORKAROUND:` markers in `Sources/` that are missing the canonical companion lines (`// WHY:`, `// WHEN TO REMOVE:`, `// TRACKING:`). The check verifies marker shape, not whether removal criteria are actually met — that remains a review concern. [VERIFICATION: SwiftLint workaround_marker_present]

---

## Design Pattern Reference

| ID | Statement | Cross-ref |
|----|-----------|-----------|
| [API-LAYER-001] | Code MUST be designed in layers, each depending only on layers below | — |
| [API-LAYER-002] | Operator-shape discriminator for capability-protocol migration: before migrating a type to conform to a capability protocol whose root operation has shape `(Self, Self) → Self`, verify the type's relevant operation matches Self+Self. Operations of shape `(Self, Self.Count) → Self`, `(Self, Index) → Self`, or `(Self, OtherType) → Self` are non-closure under the candidate protocol — keep as a sibling protocol or specialized variant instead. Case study (Carrier triage): `Algebra.Modular.Modulus.{add, sub, mul}` are `(Self, Self) → Self` → Carrier candidate; `Range.{distance, advance}` are `(Self, Self.Count) → Self` → NOT Carrier candidates; sibling-protocol territory. Provenance: `Reflections/2026-04-26-carrier-integration-retrospective.md:151`; `swift-carrier-primitives/Research/capability-lift-pattern.md` v1.2.0 Recommendation #7 generalised (Research doc not found on disk as of 2026-07-05 — surviving artifact is the Experiments dir `swift-carrier-primitives/Experiments/capability-lift-pattern/`; re-verify before citing); `swift-institute/Research/carrier-launch-skill-incorporation-backlog.md` #1.6. | [API-LAYER-001], [PATTERN-013], [PKG-NAME-009] |
| [PATTERN-025] | Type erasure and Sendable create tension; verify Sendable is needed before resolving | [IMPL-068], [IMPL-069] |
| [PATTERN-026] | Common patterns MUST be centralized in primitives, even when it adds call-site verbosity | [IMPL-060] |
| [PATTERN-027] | Custom `deinit` marks an architectural boundary for migration to primitives | [IMPL-064] |
| [PATTERN-028] | Refactoring MAY be driven by consistency audits: "what's still ad-hoc?" | [IMPL-060] |
| [PATTERN-029] | Protocol-conformance disambiguation via `@_disfavoredOverload` — when a generic type cascades a conformance to one protocol via an associated-type relationship AND conforms to a sibling protocol (e.g., `Tagged: Carrier` cascaded from `RawValue: Carrier`, while `Tagged: Ordinal.\`Protocol\`` is the sibling), Swift overload resolution may treat the cascaded witness as ambiguous with the sibling's witness. Mark the lower-priority conformance witness with `@_disfavoredOverload` to break the ambiguity in favor of the more specific sibling. Distinct from [API-ERR-005] (`@_disfavoredOverload` for stdlib `rethrows` compatibility) and [TEST-018] (`@_disfavoredOverload` for test-only literal conformances) — those are existing use cases of the same attribute, not the disambiguation pattern. Provenance: `Reflections/2026-04-26-carrier-integration-retrospective.md:153`; `swift-institute/Research/carrier-launch-skill-incorporation-backlog.md` #1.5. | [API-ERR-005], [TEST-018], [PKG-NAME-009] |
| [PATTERN-052] | `@inlinable` cross-module access requires `@usableFromInline package`, not `internal` | — |
| [PATTERN-053] | Packages MUST use primitives-layer types for common concepts rather than local equivalents | [IMPL-060] |
| [PATTERN-059] | Construction pins, operations generic — when a generic type's operations are expressible over a capability seam, bind the OPERATIONS to the seam (`where Allocation: Memory.Pooling`-class bounds) and pin only CONSTRUCTION to the concrete resource (`create(slotCapacity:)` stays heap-pinned). Construction is where the resource's identity is decided; operations inherit it. The recurring tower pattern, principal-ratified at the W5-1 §A15 adoption (arena 208c8d1 over pool 9dd38e7; converged plan storage-generational-purity, 2026-06-10/11). | [MEM-SAFE-029], [API-IMPL-023] |
| [PATTERN-060] | Cross-module type-name conflicts surfacing during cross-package work are a missing-reuse SIGNAL — the L2/L3 package is likely re-implementing something L1 already provides (e.g. `RFC_8259.Position` vs `Lexer.Position`, identical offset+location shape). Investigate the colliding types as direct-reuse / case-(c) pull-down candidates: promote the format-agnostic capability to L1, replace the L2/L3 type with a typealias. Provenance: memory `feedback_name_conflicts_indicate_missing_reuse.md` (Phase 4 case-(c) JSON-stack migration 2026-05-14). | [MOD-DOMAIN], [RES-018] case (c), [PATTERN-053] |
| [PATTERN-061] | Institute types needing JSON encode/decode MUST conform to swift-json's `JSON.Serializable` (implement `serialize` / `deserialize`; file `<Type>+JSON.swift`), NOT `Swift.Codable` (no Foundation-free consumer exists — Foundation is banned ecosystem-wide) and NOT `Coder_Primitives.Codable` directly (reserved for types with ONE inherent canonical codec, e.g. `RFC_8259.Value`). `JSON.Serializable` is a sibling to the typed-codable family, not a refinement. Provenance: memory `feedback_json_serializable_canonical.md`; precedents swift-impact `6f79d25`, swift-package-graph `9b33a81`. | [ARCH-LAYER-007], [ARCH-LAYER-012] |

---

## Semantic Dependencies

For detailed rules, see `Documentation.docc/Semantic Dependencies.md`.

| Rule | Statement |
|------|-----------|
| [SEM-DEP-006] | Distinguish essential vs incidental relationships; only essential creates SDG edges |
| [SEM-DEP-008] | Join-point packages resolve conflicts where two domains have mutual relevance |
| [SEM-DEP-009] | Package dependencies MUST be essential; orthogonal integrations require separate packages |

---

## Lint Enforcement

Wave 2b finalization (2026-05-10) added swift-linter AST rules covering several rules in this file. Each rule lives in `swift-foundations/swift-linter-rules` under the listed target.

| Rule | Lint rule | Target |
|------|-----------|--------|
| [PATTERN-012] | `Lint.Rule.Structure.TypeTransformPlacement` — flags instance `to<X>()` / `as<X>()` methods whose return type's leaf identifier matches `<X>`; static methods, methods whose suffix doesn't name the return type, and methods without `to`/`as` prefix are not flagged. [VERIFICATION: AST Lint.Rule.Structure.TypeTransformPlacement] | `Linter Rule Structure` |
| [PATTERN-017] | `Lint.Rule.Structure.RawValueAccess` — flags `.rawValue` / `.position` member accesses inside function / initializer / accessor / closure bodies; type-scope declarations and unrelated members exempt. [VERIFICATION: AST Lint.Rule.Structure.RawValueAccess] | `Linter Rule Structure` |
| [PATTERN-019] | `Lint.Rule.RawValue.TaggedExtensionPublicInit` — flags extensions on `Tagged` (or qualified `…Tagged` / `Tagged<…>`) containing public initializers. [VERIFICATION: AST Lint.Rule.RawValue.TaggedExtensionPublicInit] | `Linter Rule RawValue` |
| [PATTERN-020] | `Lint.Rule.Structure.ThrowingWrapperInit` — flags throwing initializers whose body has exactly one `try` statement (forward-only forms). Inits with surrounding validation logic are not flagged. The narrow heuristic targets the canonical "forward-without-validation" pattern. [VERIFICATION: AST Lint.Rule.Structure.ThrowingWrapperInit] | `Linter Rule Structure` |
| [PATTERN-052] | `Lint.Rule.Structure.InlinableInternalAccess` — flags `@inlinable` decls without `public` / `package` access or `@usableFromInline`. [VERIFICATION: AST Lint.Rule.Structure.InlinableInternalAccess] | `Linter Rule Structure` |
| [PATTERN-055] | `Lint.Rule.Structure.UsableFromInlineInternalImport` — flags every `internal import` declaration in any file that ALSO has at least one `@usableFromInline` attribute; the compile-time failure mode is "internal import used in @usableFromInline" so the heuristic is conservative but cheap. [VERIFICATION: AST Lint.Rule.Structure.UsableFromInlineInternalImport] | `Linter Rule Structure` |
| [PATTERN-056] | `Lint.Rule.Platform.DeadCasePerPlatform` — flags public enums whose 2–4 cases match a curated platform-pair set (`posix`/`windows`, `utf8`/`utf16`, `linux`/`darwin`[/`windows`[/`freebsd`]]). Domain-alternative enums (`http`/`https`/`ftp`) and internal enums are not flagged. [VERIFICATION: AST Lint.Rule.Platform.DeadCasePerPlatform] | `Linter Rule Platform` |
| [PATTERN-058] | `Lint.Rule.Idiom.EnumeratedSubscript` — flags `for (i, _) in <seq>.enumerated()` loops whose body subscripts the SAME `<seq>` with `i`. Conservative — Array call sites are correct but the linter can't tell Array from custom Collections; suppress via `// swiftlint:disable:next` + `// WHY:` for confirmed Array sites. [VERIFICATION: AST Lint.Rule.Idiom.EnumeratedSubscript] | `Linter Rule Idiom` |
