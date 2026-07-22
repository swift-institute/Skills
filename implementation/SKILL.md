---
name: implementation
description: |
  Intent-over-mechanism and compiler-enforced strictness: expression-first, call-site-first, typed arithmetic, boundary overloads, ownership-first.
  ALWAYS apply when writing or reviewing implementation code.

layer: implementation

requires:
  - swift-institute
  - code-surface
  - conversions

applies_to:
  - swift
  - swift6
  - primitives
  - standards
  - foundations
# Amendment/changelog history: Research/implementation-skill-rationale.md §Changelog-Provenance (and git history of this file).
---

# Implementation

Every line of implementation code reads as intent — and is verified by the compiler.

This skill is organized as a navigation hub. The foundational axioms below govern the whole skill and are always in context. Detailed rule text lives in sibling files in this directory; Claude loads the relevant file on demand when a topic is active.

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/implementation-skill-rationale.md` (referenced below and in the sibling files as the rationale archive).

## Files

| Topic | File | Rules |
|-------|------|-------|
| Ownership & `~Copyable` | `ownership.md` | [IMPL-063], [IMPL-064], [IMPL-065], [IMPL-067], [IMPL-070], [IMPL-071], [IMPL-072], [IMPL-078], [IMPL-080], [IMPL-096], [IMPL-106], [IMPL-107], [PATTERN-022], [COPY-FIX-003]–[COPY-FIX-011], [COPY-REM-003] |
| Concurrency & Isolation | `concurrency.md` | [IMPL-062], [IMPL-066], [IMPL-068], [IMPL-069], [IMPL-073], [IMPL-076], [IMPL-083], [IMPL-085], [IMPL-088], [IMPL-091], [IMPL-098], [IMPL-099] |
| Property Accessors & Static Layer | `accessors.md` | [IMPL-020], [IMPL-021], [IMPL-022], [IMPL-023], [IMPL-024], [IMPL-025], [IMPL-026], [IMPL-079], [IMPL-081], [IMPL-082], [IMPL-100] |
| Errors | `errors.md` | [IMPL-040], [IMPL-042], [IMPL-075], [IMPL-092], [IMPL-093], [IMPL-108], [IMPL-109], [IMPL-112] |
| Expression Style & Component Shape | `style.md` | [IMPL-EXPR-001], [IMPL-033], [IMPL-034], [IMPL-035], [IMPL-036], [IMPL-037], [IMPL-084], [IMPL-086], [IMPL-087], [IMPL-094], [IMPL-097], [IMPL-101]–[IMPL-105], [IMPL-110], [IMPL-111] |
| Infrastructure & Boundaries | `infrastructure.md` | [IMPL-002], [IMPL-010], [IMPL-011], [IMPL-012], [IMPL-050], [IMPL-060], [IMPL-061], [IMPL-074], [IMPL-077], [IMPL-089], [IMPL-090], [IMPL-095] (+ body sub-labels [IMPL-003]/[IMPL-003a]/[IMPL-004]/[IMPL-005]/[IMPL-006] under [IMPL-002]; [IMPL-051]–[IMPL-053] under [IMPL-050]) |
| Absorbed Patterns | `patterns.md` | [API-LAYER-001]–[API-LAYER-002], [PATTERN-012]/[013]/[016]/[017]/[019]/[020]/[025]–[029]/[052]–[063], [SEM-DEP-006]/[008]/[009] |

---

## Foundational Axioms

### [IMPL-INTENT] Code Reads as Intent, Not Mechanism

**Statement**: All implementation code MUST read as a declaration of *what* is being accomplished, never as a description of *how* the machine accomplishes it. This is the governing principle of the entire skill. Every other rule is a corollary.

- If a line describes *what* happens → intent. Keep it.
- If a line describes *how* it happens → mechanism. Refactor it.

**Intent** is the domain operation: initialize, move, copy, insert, remove, count, compare, iterate.
**Mechanism** is the implementation machinery: offset computation, pointer arithmetic, raw value extraction, bitPattern conversion, closure scaffolding, manual index construction.

Mechanism belongs inside infrastructure (operators, overloads, accessors, boundary methods). Intent belongs at call sites. When mechanism leaks into a call site, the infrastructure is incomplete.

**Cross-references**: [Research: intent-over-mechanism-expression-first.md]

---

### [IMPL-000] Call-Site-First Design

**Statement**: Write the ideal expression first. If the infrastructure doesn't support it, improve the infrastructure — unless the absence is principled (see [IMPL-001]).

1. **If it compiles** → done.
2. **If it doesn't compile** → is the absence principled?
   - **Yes** → rethink the expression. The type system is telling you something.
   - **No** → improve the infrastructure:

| What's missing | Where to add it |
|----------------|----------------|
| Operator (`+`, `-`, `<`) | Arithmetic primitives for the type |
| Stdlib overload (`initialize`, `distance`) | Stdlib integration layer (e.g., affine-primitives) |
| Accessor (`.span` / `.mutableSpan` / `subscript(at:)`; raw `.pointer(at:)` only as a [MEM-SAFE-015] last resort) | The type itself |
| Property.View tag | Tag enum + `Property` extension |
| Iteration (`.forEach`, `.reduce`) | The collection/enum type |
| Transformation (`.map.bounds`) | Range/collection primitives |

After improving infrastructure, all other call sites also benefit. The infrastructure serves the expression — not the other way around.

---

### [IMPL-001] Principled Absences

**Statement**: Before adding missing infrastructure, verify the absence is not principled. An absence is principled when the operation would violate mathematical properties, type-theoretic foundations, or established design constraints.

**Principled — do NOT add:**

| You want to write | Why it doesn't exist | What to write instead |
|---|---|---|
| `count - count` with `-` | Subtraction on naturals isn't total | `count.subtract.saturating(other)` or `try count.subtract.exact(other)` |
| `index * 2` | Indices are ordinals; scaling a position is meaningless | Rethink: do you mean `offset * 2`? |
| `bounded + .one` returning `Bounded<N>` | Addition on bounded ordinal is partial | `bounded.successor()` (returns `Optional`) |

For the complete catalog of principled absences, see [INFRA-200].

**Gap — DO add:**

| You want to write | Why it should exist | Where to add it |
|---|---|---|
| `count + .one` | `Cardinal + Cardinal → Cardinal` is total | cardinal-primitives |
| `pointer.initialize(from:count: typedCount)` | Valid operation; only the `Int` bridge is missing | affine-primitives stdlib integration |
| `slot < capacity` (Index vs Count) | Comparison is well-defined between position and size | ordinal-primitives |

**The test**: Does the operation preserve the mathematical properties of the types involved? If it would make a partial operation look total, mix dimensions, or violate affine space rules — the absence is a feature.

**Cross-references**: [CONV-010]

---

### [IMPL-COMPILE] Compiler as Primary Correctness Mechanism

**Statement**: Code MUST be written so the compiler enforces as many correctness properties as possible at compile time. Every invariant expressible in the type system MUST be expressed there, not verified at runtime.

This is the dual of [IMPL-INTENT]: intent-over-mechanism governs *how code reads*; compiler-as-enforcer governs *what the compiler proves*.

**Corollaries**:

| Invariant | Mechanism | Rule |
|-----------|-----------|------|
| Resource has exactly-once lifecycle | `~Copyable` | [IMPL-064] |
| View must not outlive its source | `~Escapable` | [IMPL-065] |
| Value crosses isolation boundary | `sending` | [IMPL-066] |
| Parameter ownership semantics | `consuming` / `borrowing` / `inout` | [IMPL-067] |
| Type does not need thread sharing | Non-`Sendable` by default | [IMPL-068] |
| Concurrency mechanism selection | Isolation hierarchy | [IMPL-069] |
| ~Copyable ownership through locks | Coroutine accessor or layer model | [IMPL-070] |
| Interior mutability from let binding | `nonmutating _modify` | [IMPL-071] |
| Error domain | Typed throws | [API-ERR-001] |
| Capacity bound | `Bounded<N>` | [IMPL-050] |
| Unsafe operation boundary | `@safe` / `@unsafe` | [MEM-SAFE-020] |

**The question at every declaration**: *"Is there a compile-time constraint I could add that would make a class of runtime bugs impossible?"*

---

## Rule Index

One-line hooks for every rule. Load the linked file when the topic is active.

### Ownership (`ownership.md`)

| ID | Hook |
|----|------|
| [IMPL-063] | Ownership subsumes synchronization — ~Copyable + mutating is exclusive access |
| [IMPL-064] | Types default to `~Copyable`; Copyable is the exception requiring justification |
| [IMPL-065] | `~Escapable` for scoped views, pointer-based access, borrowed iterators |
| [IMPL-067] | Explicit `consuming` / `borrowing` / `inout` on non-obvious parameters; not an overload axis |
| [IMPL-070] | Transfer `consuming ~Copyable` through coroutine Mutex; `.take()!` at Layer 2 is a violation |
| [IMPL-071] | `nonmutating _modify` for interior mutability on `let`-bound containers |
| [IMPL-072] | `~Copyable` multi-value return uses Optional bundle + consuming extraction |
| [IMPL-078] | Widen Copyable → `~Copyable` on existing APIs; duplicate only when semantics diverge |
| [IMPL-080] | `consuming` ternary for `~Copyable` selection (`max`, `min`, conditional return) |
| [PATTERN-022] | `~Copyable` nested types use `extension Parent where Element: ~Copyable { }` in separate files |
| [COPY-FIX-003] | Every extension on `~Copyable`-generic type needs explicit `where Element: ~Copyable` |
| [COPY-FIX-004] | Conditional conformances in the same file as the type (or split modules, [COPY-FIX-010]) |
| [COPY-FIX-005] | `Sequence` / `Collection` conditional on `Element: Copyable`; use custom protocols for ~Copyable |
| [COPY-FIX-006] | Multi-file `-emit-module` bug — consolidate to single file when six conditions present |
| [COPY-FIX-007] | CoW in all mutating ops when `Element: Copyable`; update cached pointers after copy |
| [COPY-FIX-008] | `Sendable` conditional on `Element: Sendable`, independent of Copyable |
| [COPY-FIX-009] | `@_rawLayout` deinit bug — `_deinitWorkaround: AnyObject?` + manual cleanup |
| [COPY-FIX-010] | Module boundary splits prevent constraint propagation |
| [COPY-FIX-011] | Prefer the non-restricting fix (borrow-based body, no added `Copyable`) over a `Copyable` constraint; expedient constraints are tracked follow-up debt |
| [COPY-REM-003] | Trace every associated type through conformers before a `~Copyable` / `~Escapable` change |
| [IMPL-096] | Layout-soundness pre-check for typed-pointer wrappers — `MemoryLayout<Wrapper>.stride ≤ minimum allocation size`; use `OpaquePointer?` for variant/family-dispatched types |
| [IMPL-106] | Language features over custom ownership types — `borrowing`/`consuming`/`~Copyable`/`inout`, never `Raw`/`Borrow` shadow types or raw-Int overloads |
| [IMPL-107] | `Reference<T>` / `Owned<T>` for recursive value-type indirection; never ad-hoc `_Box` classes |

### Concurrency (`concurrency.md`)

| ID | Hook |
|----|------|
| [IMPL-062] | `nonisolated(nonsending)` for async methods inheriting caller's isolation |
| [IMPL-066] | `sending` on parameters / returns / channel payloads crossing isolation boundaries |
| [IMPL-068] | `Sendable` minimalism — non-Sendable by default; avoid viral Sendability |
| [IMPL-069] | Isolation hierarchy — start at rank 1 (Actor), move down only with documented constraint |
| [IMPL-073] | SE-0461 `@concurrent` inference is body-sensitive; no `await` → no `@concurrent` |
| [IMPL-076] | Struct wrapping a Sendable class uses plain `Sendable`, not `@unchecked` |
| [IMPL-083] | Custom-executor → actor bridge: SE-0424 hooks + local weak-box Handle |
| [IMPL-085] | `sending` + `nonisolated(unsafe)` for locked transfer, not `@unchecked Sendable` |
| [IMPL-088] | Lock-ordering analysis: separate lock scopes unless total ordering documented |
| [IMPL-091] | Materialise closure result into Sendable locals BEFORE `assumeIsolated` |
| [IMPL-098] | Unmanaged self-retention is a code smell for wrong ownership boundary; prefer actor state or Swift-native C-callback bridges |
| [IMPL-099] | Fake replacing a blocking kernel wait must gate its drain on a condvar until actor init completes |

### Property Accessors & Static Layer (`accessors.md`)

| ID | Hook |
|----|------|
| [IMPL-020] | Verb-as-property with `callAsFunction`; tag types + `Property` extensions |
| [IMPL-021] | `Property<Tag, Base>` for Copyable; `Property<Tag, Base>.View` for `~Copyable` |
| [IMPL-022] | `_read` + `_modify` coroutines when the View extension includes mutating methods |
| [IMPL-023] | Core logic in static methods; instance methods delegate — eliminates overload recursion |
| [IMPL-024] | Compound identifiers allowed in the static layer; nested accessors required in public API |
| [IMPL-025] | Two-tier overload resolution — both tiers delegate to the same static |
| [IMPL-026] | `Property.View` protocol delegation — defaults on the protocol, no per-type duplication |
| [IMPL-079] | `Property.View` methods return Copyable or use closures; never another `~Escapable` |
| [IMPL-081] | Sub-view return type reflects whether hidden invariants (null-termination, alignment) survive |
| [IMPL-082] | Extension extraction loses sibling-type scope; fully qualify after extraction |
| [IMPL-100] | Coroutine `_read`/`_modify` property accessors over `with*` closure APIs for borrowed access to ~Copyable resources in classes/actors |

### Errors (`errors.md`)

| ID | Hook |
|----|------|
| [IMPL-040] | Typed throws for caller-checkable conditions; preconditions for programming errors |
| [IMPL-042] | Duplicate hot-path body under `where Failure == Never` — forwarding does not specialize |
| [IMPL-075] | `do throws(E) { } catch { }` preserves the concrete error type in non-throwing contexts |
| [IMPL-092] | Callback outcomes as `() throws(E) -> T` thunk, not `Result<T, E>`; two-callback storage fallback for toolchain-blocked composition |
| [IMPL-093] | Optional-capture reinitialization for `~Copyable` async closure boundaries — `descriptor = nil` after `consume descriptor` |
| [IMPL-108] | No `try?` — silently discards errors. Use `do throws(E) { } catch { }` with explicit error handling. |
| [IMPL-109] | Result-wrapper pattern for typed-throws shims around stdlib `rethrows` — `Result<T, E>` materialised inside closure + `try result.get()` outside; locally types catch-bound error per [IMPL-075] |
| [IMPL-112] | `Either<DomainError, CrossCutting>` + typed throws for cross-cutting errors; never pollute domain enums or invent custom Outcome wrappers |

### Expression Style & Component Shape (`style.md`)

| ID | Hook |
|----|------|
| [IMPL-EXPR-001] | Single expressions over intermediate bindings; extract named functions, not locals |
| [IMPL-033] | Iteration climbs the abstraction ladder: bulk → iteration infra → typed while → never raw |
| [IMPL-034] | `unsafe` wraps the whole expression from the left |
| [IMPL-035] | Uniform execution model at a given structural level; never mix immediate/deferred |
| [IMPL-036] | When you can't store X, find Y where X = f(Y) and store Y |
| [IMPL-037] | String interpolation as the non-throwing bridge for `ExpressibleByStringLiteral` types |
| [IMPL-084] | Single-inhabitant namespace is a variant label (see [API-NAME-001a]) |
| [IMPL-086] | Deletion-first structural fix — is the invariant load-bearing before escalating to types? |
| [IMPL-087] | Does the component need to exist? Architectural-level [IMPL-000] |
| [IMPL-094] | Swift 6.3 rejects chained property access via `&&`/`\|\|` on `borrowing Self`; use tuple comparison or local let-bindings |
| [IMPL-097] | Nested-generic-dispatch forces overload resolution to base method when shadowed; also workaround for certain SILGen cases |
| [IMPL-101] | YAGNI targets API-surface complexity (parameter/return/constraint types), not complexity confined behind `@usableFromInline`/constrained-extension internals |
| [IMPL-102] | Verify a proposed cross-type conformance scheme avoids overlapping conditional conformances (Swift rejects them) before reaching RECOMMENDATION status |
| [IMPL-103] | SwiftSyntax descendant search MUST use `SyntaxVisitor` + `.walk()`; manual `children()`-cast recursion silently truncates at intermediate node types |
| [IMPL-104] | Leading-dot is ambiguous at top-level positions in multi-overload `buildExpression` result builders; use fully-qualified static factories there |
| [IMPL-105] | When a proposed type's value-add is shape not semantics, evaluate an overload accepting the existing protocol before minting a new wrapper type |
| [IMPL-110] | Tagged-based identity over a stdlib underlying MUST pair the typealias with typed operations — `.underlying` at call sites signals the rim-typing defect |
| [IMPL-111] | Pre-design ecosystem grep before introducing any per-platform shape; check `string-type-ecosystem-model.md` and existing `Path.Char` / `String.Char` typealiases |

### Infrastructure & Boundaries (`infrastructure.md`)

| ID | Hook |
|----|------|
| [IMPL-002] | Write the math, not the mechanism — typed operators, no `.rawValue` at call sites |
| [IMPL-003]/[IMPL-003a]/[IMPL-004]/[IMPL-005]/[IMPL-006] | Sub-labels under [IMPL-002] — functor ops, domain-crossing-before-ops, comparison, min/max, typed stored properties |
| [IMPL-010] | Push `Int` to the edge — `Int(bitPattern:)` lives inside boundary overloads |
| [IMPL-011] | Typed `subscript(at:)` + Span family encapsulate offset computation; raw pointer is last resort |
| [IMPL-012] | `range.map.bounds { }` for range-bound transformation |
| [IMPL-050] | `Index<Element>.Bounded<N>` on static-capacity types; bounded is the sole public API |
| [IMPL-051]–[IMPL-053] | Sub-labels under [IMPL-050] — narrowing/widening, API flow (bounded-only), arithmetic |
| [IMPL-060] | Ecosystem dependencies over ad-hoc implementation |
| [IMPL-061] | Compiler fix before workaround accumulation; cascade signal = structural fix at compiler |
| [IMPL-074] | Cross-layer type reference test: stable concept, no boundary reasoning, wrapping adds no value |
| [IMPL-077] | Verify the constraint by minimal experiment before implementing a workaround |
| [IMPL-089] | Foundation-free string scanning defaults to `content.utf8` byte view |
| [IMPL-090] | Abstraction seam validity requires data-contract alignment, not surface-shape similarity |
| [IMPL-095] | Preserve platform-guarded imports verbatim on file rewrites; `diff pre.imports post.imports` before commit |

### Absorbed Patterns (`patterns.md`)

Anti-patterns: [PATTERN-012], [PATTERN-013], [PATTERN-016], [PATTERN-017], [PATTERN-019], [PATTERN-020], [PATTERN-054], [PATTERN-055], [PATTERN-056], [PATTERN-057], [PATTERN-058], [PATTERN-062], [PATTERN-063] (no for-loops in result-builder bodies; AST-enforced).
Design patterns: [API-LAYER-001]–[API-LAYER-002], [PATTERN-025]–[PATTERN-029], [PATTERN-052], [PATTERN-053], [PATTERN-059], [PATTERN-060], [PATTERN-061].
Semantic dependencies: [SEM-DEP-006], [SEM-DEP-008], [SEM-DEP-009].

---

## Cross-References

See also:
- **conversions** skill for [IDX-*], [CONV-*] type definitions and conversion APIs
- **code-surface** skill for [API-NAME-*], [API-ERR-*], [API-IMPL-*] naming, errors, file structure
- **memory-safety** skill for [MEM-*] ownership patterns, ~Copyable mechanics, unsafe marking
- **testing** skill for [TEST-018] literal conformances in tests
- **existing-infrastructure** skill for [INFRA-*] catalog of typed operations, integration modules, and principled absences
- **Semantic Dependencies.md** for [SEM-DEP-*] dependency classification rules

---

## Lint Enforcement

Wave 2b finalization (2026-05-10) added swift-linter AST rules covering several rules in this skill. Each rule lives in `swift-foundations/swift-linter-rules` under the listed target. Wave 3 (2026-05-11) extended coverage with seven additional rules, including a new `Linter Rule Idiom` module for implementation-style rules.

| Rule | Lint rule | Target |
|------|-----------|--------|
| [IMPL-033] | `Lint.Rule.Idiom.IterationIntent` — flags `for <i> in <a>..<<b>` counter loops with simple identifier binding | `Linter Rule Idiom` |
| [IMPL-042] | `Lint.Rule.Throws.GenericNeverSpecialization` — flags public generic functions throwing `<G>.<Sub>` to prompt review for `where <G>.<Sub> == Never` specialization | `Linter Rule Throws` |
| [IMPL-050] | `Lint.Rule.Idiom.BoundedIndex` — flags raw `Int` subscripts on static-capacity types (`<let N: Int>`) | `Linter Rule Idiom` |
| [IMPL-075] | `Lint.Rule.Throws.DoCatchTyped` — flags bare `do { try ... } catch { ... }` blocks (no typed-throws specifier) where the body contains an unwrapped `try`. Wave 3 companion `Lint.Rule.Throws.DoCatchTypedThrow` flags the `throw`-only form (`do { throw ... } catch { ... }` with no `try`). [VERIFICATION: AST Lint.Rule.Throws.DoCatchTyped, AST Lint.Rule.Throws.DoCatchTypedThrow] | `Linter Rule Throws` |
| [IMPL-089] | `Lint.Rule.Idiom.StringUTF8Scanning` — flags `.unicodeScalars` member access | `Linter Rule Idiom` |
| [IMPL-092] | `Lint.Rule.Throws.ResultCallback` — flags callback closure parameters typed `Result<T, E>` | `Linter Rule Throws` |
| [IMPL-094] | `Lint.Rule.Memory.BorrowingSelfShortCircuit` — flags operator overloads with `borrowing Self` parameters using `&&` / `||` | `Linter Rule Memory` |
| [IMPL-109] | `Lint.Rule.Throws.RethrowsResultShim` — flags `try` inside closures passed to stdlib `rethrows` higher-order methods (`map`, `compactMap`, `filter`, `flatMap`, `forEach`, `reduce`, `first`, etc.) | `Linter Rule Throws` |
