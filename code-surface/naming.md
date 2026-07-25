## Naming Rules

### [API-NAME-006] New-Code Self-Compliance During Enforcement Sweeps

**Statement**: When a session runs a rule-enforcement sweep (converting N files to comply with [API-NAME-*] or a related convention), any NEW code authored in the same session — for ANY purpose (tests, experiments, fixtures, article examples, handoff artifacts, internal helpers) — MUST be swept for the same rule before commit. The session's enforcement scope includes parallel new code, not just the enumerated enforcement target.

**Procedure**:

1. At enforcement-sweep start, note the rule being enforced and its regex / scan pattern.
2. Before any commit that includes new files (of any kind), re-run the scan pattern against the new files.
3. If the new files violate the rule, fix them in the same commit.

**Rationale**: Enforcement sweeps routinely produce incidental new code; skipping it paradoxically enlarges the non-compliance surface, and the fix is cheap at authoring time and expensive later. Full text (defect example, provenance): rationale archive §[API-NAME-006].

**Cross-references**: [API-NAME-001], [API-NAME-002]

---

### [API-NAME-005] Pre-Rename Mechanical Check for New Type Identifiers

**Statement**: Any new type identifier introduced during refactoring MUST be verified against [API-NAME-001] (Nest.Name pattern) and [API-NAME-002] (no compound identifiers) BEFORE the identifier is applied, not after. The check is a mechanical test the refactor workflow runs against the proposed name.

**Test (applied to each proposed new identifier)**:

1. Does the name contain an embedded capitalized second-word fragment (e.g., `CaseInsensitive`, `NonBlocking`, `BufferLinked`)? If yes, it is a compound — decompose into `Case.Insensitive`, `NonBlocking` (reserved — blocked), `Buffer.Linked`.
2. Does the name start with a verb-like form followed by a noun (`walkFiles`, `openWrite`)? If yes, it is a compound — decompose into `walk.files`, `open.write`.
3. Is the name exactly the same as an existing spec-literal or ecosystem-established term? If the match is intentional, cite the source; if not, rename to avoid accidental collision.

**Rationale**: Catching naming violations at the proposal step is strictly cheaper than at commit or review, and new types rarely appear in isolation (Options, Error, Iterator all inherit the violation). Full text (provenance): rationale archive §[API-NAME-005].

**Cross-references**: [API-NAME-001], [API-NAME-002]

---

### [API-NAME-007] Convention-Known-Convention-Unapplied Heuristic for Method/Property Names

**Statement**: When a proposed method or property name (a) contains an internal capital letter, OR (b) is copied or adapted from the Swift stdlib, an SE proposal, or another language's API, the name MUST be re-verified against [API-NAME-002] (no compound identifiers) BEFORE commit. Both conditions independently trigger the check; either fires it.

**Procedure**:

1. Before committing a new method or property, identify the proposed name.
2. Apply the test: does the name contain an internal capital letter? Is it copied/adapted from stdlib / SE / other-language? If either is yes, proceed to step 3.
3. Re-verify against [API-NAME-002]: is this a compound identifier? If yes, decompose into nested accessor (multi-form) per [API-NAME-008], or labeled method (single-form) per [API-NAME-008].
4. Update the implementation, file name, and commit-message subject to use the corrected name.

**Rationale**: [API-NAME-002] is declarative knowledge that fails procedurally at the moment of naming; codifying the two triggers converts the rule from ambient judgment to a mechanical pre-commit gate. Full text (origin incident — `Array.swapAt` post-ship rename, provenance): rationale archive §[API-NAME-007].

**Cross-references**: [API-NAME-002], [API-NAME-005], [API-NAME-008]

---

### [API-NAME-008] Property.View vs Labeled Method Decision Rule

**Statement**: Both Property.View nested accessors and direct labeled methods are [API-NAME-002]-compliant approaches to avoiding compound identifiers. The choice between them is structural: **multi-form operations (two or more related sub-operations under one root) MUST use Property.View nested accessors; single-form operations (one operation, disambiguated by argument labels) MUST use direct labeled methods.** A Property.View wrapper around a single method adds per-variant types + typealias + property getter for zero call-site expressivity gain.

**Decision test**:

| Operation shape | Convention |
|-----------------|------------|
| `remove.{first, last, all}` — three related sub-operations | Property.View (`remove`) — multi-form |
| `peek.{front, back}` — two related sub-operations | Property.View (`peek`) — multi-form |
| `forEach.{borrowing, consuming, index}` — three related forms | Property.View (`forEach`) — multi-form |
| `swap(at:with:)` — one operation, two indices distinguished by labels | Labeled method (`swap`) — single-form |
| `truncate(to:)` — one operation, target distinguished by label | Labeled method — single-form |
| `clone()` / `clone(capacity:)` — same operation with optional capacity | Labeled method, overloaded — single-form |

**Procedure (decision-test for new APIs)**:

1. Enumerate the related sub-operations the proposed API would expose.
2. Are there 2+ sub-operations naturally under one root noun? → Property.View nested accessor.
3. Is there 1 operation, disambiguated by argument labels? → Direct labeled method.
4. Layer-consistency soft tie-breaker: when a labeled method exists at the layer below (e.g., `Buffer.Linear.swap(at:with:)`), match the name at the higher layer (`Array.swap(at:with:)`) — different names at different layers create friction at every delegation; matching names make the delegation invisible.

**Rationale**: [API-NAME-002] bans compound identifiers but is silent on when nested-accessor ceremony is warranted; codifying multi-form-vs-single-form prevents Property.View ceremony on single-form operations. Full text (origin incident — `swap` Option A/B analysis, provenance): rationale archive §[API-NAME-008].

**ADT Tower rider — the remove-op naming decree (M5, ratified 2026-07-03; transcribed at W4, 2026-07-06).** Tower-wide, a SINGLE-WORD removal op that can fail on empty returns `Optional` — `pop() -> Element?` (extending the SEAT's remove-from-empty ruling, adt-tower §9.3, into a naming decree): `Array.removeLast()` → `pop()`, and every family's single-word remove follows. This supersedes any [API-NAME-008] compound-name pressure for `~Copyable`-carrier remove ops — the `Optional`-consuming return is available for `~Copyable` elements. Carve-out: a `~Copyable` BORROW of `Element?` is structurally unavailable, so borrowing accessors keep crashing preconditions (e.g. `min`) rather than vending `Optional`. Provenance: `Research/adt-tower.md` §4.7, §9.3.

**Cross-references**: [API-NAME-002], [API-NAME-007]

---

### [API-NAME-009] Educational-Diagnostic Message Format

**Statement**: When a diagnostic-emitting rule (linter rule, validation rule, error-reporter) cites an institutional source — a skill rule ID, a feedback-memory file, a research doc — the message text MUST follow the format `"[<rule_id>] <citation>: <description>"` at the message-text layer itself, not just in the rule's source code or the reporter's structured envelope.

**Correct**:
```
[compound_identifier] [API-NAME-002]: method/property `walkFiles` is a compound
identifier; use nested accessor `walk.files()` per the Nest.Name pattern.
```

**Incorrect**:
```
Don't use try?                           // ❌ no rule_id, no citation, no description
[try_optional] Avoid try?                // ❌ no citation, terse description
try? is not allowed here                 // ❌ no rule_id at message layer
```

**Lint enforcement**: Reusable workflow `validate-diagnostic-format.yml` + `.github/scripts/validate-diagnostic-format.py` flag rule-source message strings not beginning with `[<rule_id>] <citation>: `; namespace placeholder files and non-rule sources are out of scope; citation existence is not verified. Scope detail: rationale archive §[API-NAME-009]. [VERIFICATION: WF validate-diagnostic-format.py (API-NAME-009)]

**Cross-references**: [API-NAME-001], [API-NAME-002], [API-ERR-001]

---

### [API-NAME-010] No `*Tag` Suffix for Phantom Types

**Statement**: Phantom-type tags used as generic parameters (typically with `Tagged<Tag, RawValue>`) MUST use the bare concept name. The `*Tag` suffix is FORBIDDEN.

**Correct**:
```swift
public typealias Ticket = Tagged<IO.Blocking.Ticket, UInt64>
//                                ^^^^^^^^^^^^^^^^^ bare concept name
```

**Incorrect**:
```swift
public typealias Ticket = Tagged<IO.Blocking.TicketTag, UInt64>  // ❌ Tag suffix
```

**Lint enforcement**: SwiftLint custom rule `no_tag_suffix_phantom` catches `Tagged<\w+Tag,` literals; AST counterpart `Lint.Rule.Naming.Tag` flags `Tag`-suffixed struct/enum declarations with empty bodies (the empty-body heuristic isolates phantom markers from legitimate `*Tag` domain types). Scope detail: rationale archive §[API-NAME-010]. [VERIFICATION: SwiftLint no_tag_suffix_phantom, AST Lint.Rule.Naming.Tag]

**Cross-references**: [API-NAME-001], [API-NAME-002], [API-NAME-010a]

---

### [API-NAME-010a] No Nested `.Tag` Sub-Name for Phantom Types

**Statement**: When a phantom-type parameter is needed for `Property<Tag, Base>`, `Tagged<Tag, Underlying>`, or any similar Tagged-shape API, the surrounding namespace enum MUST play the phantom role directly — introducing an inner `.Tag` sub-type as the phantom is FORBIDDEN. This rule complements [API-NAME-010] (suffix form) by closing the nested-sub-name form: `Order.Tag` is wrong for the same reason `OrderTag` is wrong — the namespace itself is the concept.

**Correct**:
```swift
public enum Order: Sendable {}

extension Property.Inout where Tag == Order, Base: ~Copyable { ... }

extension Order.Orderable where Self: ~Copyable {
    public var order: Property<Order, Self>.Inout { ... }
}
```

**Incorrect**:
```swift
public enum Order: Sendable {}

extension Order {
    public enum Tag {}                                       // ❌ inner .Tag sub-name
}

extension Property.Inout where Tag == Order.Tag, Base: ~Copyable { ... }
//                                    ^^^^^^^^^ — Order alone is the answer
```

**Lint enforcement**: `Lint.Rule.Naming.NestedTag` flags struct/enum declarations literally named `Tag` with empty bodies inside an enclosing type-decl or extension context; domain `.Tag` types with stored properties / cases and top-level `Tag` declarations pass through. Sibling of `Lint.Rule.Naming.Tag` per [API-NAME-010]. Scope detail: rationale archive §[API-NAME-010a]. [VERIFICATION: AST Lint.Rule.Naming.NestedTag]

**Cross-references**: [API-NAME-001] Nest.Name, [API-NAME-001a] Single-Type-No-Namespace (the file-scope phantom-tag pattern that IS endorsed), [API-NAME-010] No `*Tag` Suffix, [IMPL-INTENT]

---

### [API-NAME-010b] Maximal Suppression on Phantom Parameters

**Statement**: A generic type parameter that is *phantom* — never stored as a value and never flowing through any operation; a pure compile-time discriminator — MUST be bound `~Copyable & ~Escapable`, whether it is **bare** today (`<Tag>`, no suppression → both Copyable and Escapable required) or partially suppressed (`<Tag: ~Copyable>`, which still requires Escapable). A non-suppressed marker-protocol requirement on a phantom is forbidden as vacuous over-constraint: by Reynolds parametricity the implementation witnesses no capability of a phantom, so the requirement shrinks the admissible domain while enabling nothing.

**Scope**: Applies uniformly to (a) the `Tagged` / `Index` / `Property` infrastructure (the `Tag` of `Tagged`/`Property`, the `Element` of `Index`) — declarations, `extension Tagged where … Tag: ~Copyable` operation/conformance sites, and free `func`/`init`/`subscript` op-sites that use the param only as a `Tagged`/`Index`/`Property` discriminator — AND (b) **domain-type declarations** whose phantom is a discriminator: `Graph.Sequential<Tag, Payload>` / `Graph.Node<Tag>` (node-identity `Tag`), `Identity.ID<Domain, RawValue>` (`Domain`). A per-domain capability-marker protocol's phantom `associatedtype` (e.g. `Ordinal.Protocol.Domain`) widens the same way when a recursive `Tagged` conformance forces it (composes with [API-NAME-001c]).

**Correct**:
```swift
public typealias Index<Element: ~Copyable & ~Escapable> = Tagged<Element, Ordinal>
public struct Property<Tag: ~Copyable & ~Escapable, Base: ~Copyable>: ~Copyable { var _base: Base }
extension Tagged where Underlying == Ordinal, Tag: ~Copyable & ~Escapable { /* … */ }
public struct Sequential<Tag: ~Copyable & ~Escapable, Payload> { let storage: Tagged<Tag, Array<Payload>> }
```

**Incorrect**:
```swift
public typealias Index<Element: ~Copyable> = Tagged<Element, Ordinal>   // ❌ still requires Escapable
public struct Property<Tag, Base: ~Copyable>: ~Copyable { /* … */ }     // ❌ bare Tag requires both
```

**Stored-value boundary (the rule does NOT apply)**: a *stored* value parameter — `Queue<Element>`, `Array<Element>`, `Graph.Sequential`'s `Payload`, an `Adjacent: Sequence` type, the `Underlying`/`Base`/`RawValue`/`Pointee`/`Word`/`Scalar` of a wrapper — is governed by the container's value-semantics needs, NOT this rule. Relaxing a stored param to `~Escapable` is a *breaking* error. Discriminator: *does any value of the parameter type get stored or flow through an operation (by-value param/return, `[P]`, `Container<P>`, `P?`, `consuming`/`borrowing`/`inout P`)?* No → phantom (this rule); Yes → stored (out of scope).

**Companion edits the relax forces** (surfaced during execution):
- **Conditional conformances** on a relaxed type must restate the suppression: `extension Property: Copyable where Tag: ~Copyable & ~Escapable, Base: Copyable {}` — a bare `extension … where Base: Copyable` no longer infers `Tag`'s bound and errors with *"must explicitly state whether 'Tag' is required to conform to 'Escapable'"*.
- A phantom **associatedtype** carrying the domain (`associatedtype Domain: ~Copyable`) must widen to `~Copyable & ~Escapable` for `Tagged<~EscapableTag, …>` to satisfy the conformance.

**Toolchain caveat — genuinely-Escapable-required sites are NOT phantom**: a `#if swift(<6.4)` backport conformance refining a stdlib protocol that is not yet `~Escapable` on that toolchain — e.g. `extension Tagged: Hash.\`Protocol\` where Tag: ~Copyable, …` where `Hash.\`Protocol\`: Swift.Hashable` (Swift.Hashable requires Escapable pre-SE-0499) — genuinely requires an Escapable tag and MUST stay `~Copyable`. The Escapable requirement is load-bearing, not vacuous; the conformance is excluded on 6.4+ where SE-0499 makes it automatic.

**Non-breaking**: widening `~Copyable` (or bare) → `~Copyable & ~Escapable` strictly enlarges the admissible tag domain; every previously-valid instantiation stays valid (no site keys on a phantom's Copyable/Escapable-ness). Surfacing a missed phantom site later is a *completeness* fix, not a *safety* fix.

**Lint enforcement**: shipped, UNBUNDLED (fires nowhere; Phase 7 deferred — see an internal audit record) — flags a `typealias`/`struct`/`enum`/`func` generic param used only in `Tagged<P,…>`/`Property<P,…>`/`Index<P>` positions (never in a stored-property/by-value type) whose bound lacks `& ~Escapable`. Will promote to GATING (bundled at `.warning`, then `.error`) after the ecosystem sweep is green.

**Cross-references**: [API-NAME-010] No `*Tag` Suffix, [API-NAME-010a] No Nested `.Tag` Sub-Name, [API-NAME-001c] Per-Domain Capability-Marker Protocol, [IDX-001] Index as Tagged Ordinal, [MEM-LIFE-001], [IMPL-INTENT]

---

### [API-NAME-011] `Options` Not `Flags` for OptionSet Types

**Statement**: OptionSet types and their semantic models MUST use `.Options` suffix, not `.Flags`; types mirroring a specification's exact terminology per [API-NAME-003] MAY retain `.Flags` if that is the spec's literal term.

**Correct**:
```swift
Kernel.File.Rename.Options
Kernel.Socket.Message.Options
Kernel.IO.Uring.Setup.Options
```

**Incorrect**:
```swift
Kernel.File.Rename.Flags         // ❌ C-speak
Kernel.Socket.Message.Flags      // ❌
```

**Lint enforcement**: SwiftLint custom rule `options_not_flags` catches `struct *Flags` / `enum *Flags` declarations (spec-mirroring exception opts out via `// swiftlint:disable:next options_not_flags  // reason: spec literal`); AST counterpart `Lint.Rule.Naming.Options` flags `Flags`-suffixed structs whose inheritance clause names `OptionSet`. Scope detail: rationale archive §[API-NAME-011]. [VERIFICATION: SwiftLint options_not_flags, AST Lint.Rule.Naming.Options]

**Cross-references**: [API-NAME-002], [API-NAME-003]

---

### [API-NAME-012] No `impl` / `obj` / `inst` Local-Binding Abbreviations

**Statement**: Local bindings for concrete types MUST use the type's own name (or a descriptive domain word). The abbreviations `impl`, `obj`, `inst`, `instance` are FORBIDDEN.

**Correct**:
```swift
let actor = IO.Blocking.Actor(executor: executor)
let reader = Channel.Reader(...)
let primary = Pool.acquire()
```

**Incorrect**:
```swift
let impl = IO.Blocking.Actor(executor: executor)   // ❌ implementation-speak
let obj = Pool.acquire()                            // ❌ generic
let instance = Channel.Reader(...)                  // ❌ pure mechanism
```

**Lint enforcement**: SwiftLint custom rule `no_impl_obj_inst_bindings` catches `let|var (impl|obj|inst|instance) =`; AST counterpart `Lint.Rule.Naming.Impl` flags bindings named `impl` or `_impl`. Scope detail: rationale archive §[API-NAME-012]. [VERIFICATION: SwiftLint no_impl_obj_inst_bindings, AST Lint.Rule.Naming.Impl]

**Cross-references**: [API-NAME-001], [API-NAME-002]

---

### [API-NAME-013] Drop Redundant Prefix When Namespace Supplies Context

**Statement**: When a property is named `<noun1><Noun2>` (e.g., `packageRoot`, `packageName`) and lives in a typed namespace where `<noun2>` alone disambiguates within that namespace, the redundant `<noun1>` prefix MUST be dropped. The containing type IS the missing context. This is a strict reading of [API-NAME-002] — the "domain phrase reads naturally" defense is NOT an [API-NAME-002] carve-out (that exception is reserved for spec-mirroring identifiers per [API-NAME-003]).

**Correct**:
```swift
extension Manifest.Configuration {
    var root: Path           // package is implicit — Configuration's domain
    var binding: Identifier  // 'value' carries no domain meaning; binding is the Swift binding name
}

extension Manifest.Dependency {
    var name: String   // a Dependency IS a package
    var path: Path     // siblings: name, product, imports
}
```

**Incorrect**:
```swift
extension Manifest.Configuration {
    var packageRoot: Path     // ❌ "package" redundant inside Configuration
    var valueName: Identifier // ❌ "value" carries no domain meaning
}

extension Manifest.Dependency {
    var packageName: String   // ❌ "package" redundant inside Dependency
}
```

**Lint enforcement**: `Lint.Rule.Naming.RedundantPrefix` flags nested type declarations whose name begins with the enclosing namespace's name followed by an uppercase-led suffix (for extensions on member types, the LAST component is the enclosing name); top-level decls and exact-match nested decls are exempt. The property-naming variant (e.g., `Manifest.Configuration.packageRoot` → `root`) is currently human-enforced — only the type-prefix variant is mechanized. Scope detail: rationale archive §[API-NAME-013]. [VERIFICATION: AST Lint.Rule.Naming.RedundantPrefix]

**Cross-references**: [API-NAME-002], [API-NAME-003], [API-NAME-008]

---

### [API-NAME-014] Module Disambiguation Over Shadow-Avoidance Renames

**Statement**: When a nested type name would shadow a Swift stdlib type (e.g., `Base62.String` shadows `Swift.String`), the domain-correct name MUST be retained and the call site MUST disambiguate via module-qualification (`Base62_Primitives.String`). Renaming the type to dodge the shadow (e.g., `Text` instead of `String`) is FORBIDDEN.

**Correct**:
```swift
// Type definition
extension Base62 {
    public struct String { ... }  // Base62.String — domain-correct
}

// Call site with ambiguity
let encoded: Base62_Primitives.String = ...
let plain: Swift.String = "..."
```

**Incorrect**:
```swift
extension Base62 {
    public struct Text { ... }  // ❌ rename to dodge stdlib String shadow
}
```

**Cross-references**: [API-NAME-001], [API-NAME-003]

---

### [API-IMPL-016] Typealiases Allow Nested Type Extensions

**Statement**: Extensions on typealiased types CAN add nested types. A typealias `Kernel.Time = Kernel.Instant` does NOT block `Kernel.Time.Specification` — `extension Kernel.Time { struct Specification {} }` resolves through the typealias to `extension Kernel.Instant { struct Specification {} }`.

**Correct mental model**:
```swift
public typealias Time = Instant  // in Kernel namespace

extension Kernel.Time {
    public struct Specification { ... }  // ✓ resolves to extension Kernel.Instant
}

let s: Kernel.Time.Specification = ...  // ✓ works
```

**Common false claim** (do not propose alternative naming or defer relocation on this basis):
> "We can't nest under Kernel.Time because it's a typealias."

**How to apply**: Before claiming a namespace is "blocked" by a typealias, write the extension and verify it compiles. Swift's extension mechanism resolves through typealiases — the compiler check is the authoritative answer.

**Cross-references**: [API-NAME-001], [API-NAME-004], [API-NAME-004a]

---

### [API-IMPL-017] Preserve Labeled Call-Site Syntax When Migrating Protocols to Witness Structs

**Statement**: When converting a protocol to a witness struct with stored closures, the call-site syntax regresses (`context.set(attribute: key, value)` becomes `context.setAttribute(key, value)`) because stored closures don't carry argument labels. The migration MUST add `@inlinable` convenience methods on the witness struct that forward to the stored closures with proper labels. Stored closures are kept (for factory/interpret use) but the labeled API is provided on top.

**Correct**:
```swift
extension Rendering.Context {
    @inlinable public func set(attribute name: String, _ value: String?) { setAttribute(name, value) }
    @inlinable public func write(raw bytes: [UInt8]) { writeRaw(bytes) }
    @inlinable public func add(class name: String) { addClass(name) }
}
```

**Why**: Labeled syntax is more readable at call sites and was deliberately chosen during the protocol-era API design; losing labels on a witness migration is a regression even when the functionality is identical. Composes with `[API-NAME-002]` (no compound identifiers) — `setAttribute` is a compound identifier; `set(attribute:)` is the correct shape.

**How to apply**: For every stored closure on a witness struct, add a labeled convenience method. The convenience methods are `@inlinable` so the indirection is optimized away.

**Cross-references**: [API-NAME-002], [API-IMPL-013]

---

