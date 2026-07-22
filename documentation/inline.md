# Documentation — Inline DocC Comments

Part of the **documentation** skill. See `SKILL.md` for the navigation hub, four-layer audience model, and rule index.

**Rules in this file**: [DOC-001], [DOC-002], [DOC-003], [DOC-004], [DOC-005], [DOC-006], [DOC-007], [DOC-008], [DOC-009], [DOC-010].

---

## Inline DocC Comments

### [DOC-001] Summary Line

**Statement**: Every public declaration MUST have a one-line `///` summary as the first documentation line. The summary describes caller-visible behavior, not implementation details. The summary MUST be optimized for the call-site hover audience — it is the first and often only line an autocomplete pop-up or quick-help panel will render.

**Correct**:
```swift
/// Submits work to the executor pool.
public func submit<T>(_ work: @Sendable () throws -> T) async throws(IO.Lifecycle.Error<IO.Error>) -> T
```

**Incorrect**:
```swift
/// This struct uses @Splat macro and stores arguments in a nested type.
public struct Arena: ~Copyable { ... }  // ❌ Describes implementation, not behavior
```

**Call-site audience constraints**:
- The summary MUST fit on one line, readable at a glance.
- It MUST be parseable without the rest of the doc comment visible — hover pop-ups often truncate.
- Verb-first or noun-first is fine; what matters is information density per character.
- Links in summaries (`` ``OtherSymbol`` ``) render in most pop-ups — use them for the single most relevant sibling reference.

**Rationale**: The summary line is the first thing readers see in quick help and symbol lists. It must orient, not explain internals. Under the four-layer audience model, the inline `///` layer exists for coders actively using the package — the summary is their primary affordance and must carry its weight in isolation.

**Cross-references**: [DOC-002], [DOC-010]

---

### [DOC-002] Type Documentation Structure

**Statement**: Type declarations (struct, enum, class, actor) MUST follow this documentation structure:

1. One-line summary
2. Blank line
3. Specification section heading (when modeling an external spec)
4. Specification text in blockquote (`>`) when modeling external specs
5. `## Example` with working Swift code (when implemented)

**Correct** (specification-mirroring type):
```swift
/// Version 4 (random) UUID.
///
/// ## RFC 4122 Section 4.4
///
/// > The version 4 UUID is meant for generating UUIDs from truly-random
/// > or pseudo-random numbers.
/// >
/// > The algorithm is as follows:
/// >
/// > - Set the two most significant bits (bits 6 and 7) of the
/// >   clock_seq_hi_and_reserved to zero and one, respectively.
/// > - Set the four most significant bits (bits 12 through 15) of the
/// >   time_hi_and_version field to the 4-bit version number from
/// >   Section 4.1.3.
/// > - Set all the other bits to randomly (or pseudo-randomly) chosen
/// >   values.
///
/// ## Example
///
/// ```swift
/// let uuid = RFC_4122.UUID.v4()
/// ```
public struct V4: Sendable { ... }
```

**Correct** (infrastructure type):
```swift
/// A bump allocator for batch allocations.
///
/// Arena allocation provides:
/// - O(1) allocation (bump pointer)
/// - No individual deallocation overhead
/// - Single bulk deallocation via `reset()`
///
/// ## Invariants
///
/// - Capacity is always > 0 (enforced at construction)
/// - `_storage` is always non-null
public struct Arena: ~Copyable { ... }
```

**Rationale**: Consistent structure enables predictable navigation. The specification heading signals "this is normative text from an external source."

**Cross-references**: [DOC-005], [DOC-033]

---

### [DOC-003] Method Documentation

**Statement**: Public methods MUST document: parameters (`- Parameter name:`), return value (`- Returns:`), thrown errors (`- Throws:`). Methods with concurrency concerns MUST also document executor/threading guarantees and cancellation behavior.

**Correct**:
```swift
/// Submits work to the executor pool.
///
/// - Parameter work: The work item to execute.
/// - Returns: The result of the work execution.
/// - Throws: `IO.Lifecycle.Error` if the pool is shutting down or the task is cancelled.
///
/// This method is safe to call from any thread. Work executes on the pool's
/// dedicated threads, not the Swift cooperative thread pool.
public func submit<T>(_ work: @Sendable () throws -> T) async throws(IO.Lifecycle.Error<IO.Error>) -> T
```

**Incorrect**:
```swift
/// Submits work.
public func submit<T>(_ work: @Sendable () throws -> T) async throws(IO.Lifecycle.Error<IO.Error>) -> T
// ❌ Missing parameter, return, throws, threading docs
```

**Rationale**: Complete method documentation enables correct use without reading implementation code.

**Cross-references**: [API-ERR-001]

---

### [DOC-004] Property Documentation

**Statement**: Properties MUST NOT be documented when self-evident. Properties MUST be documented when: (a) computed with side effects, (b) has non-obvious invariants, (c) deviates from an established pattern in the codebase.

**Correct**:
```swift
/// Whether the pool has been shut down and will reject new work.
public let isTerminating: Bool
```

```swift
var count: Int  // ✓ Self-evident, no documentation needed
```

**Incorrect**:
```swift
/// The count.
var count: Int  // ❌ Documentation adds no information
```

**Rationale**: Redundant documentation creates noise that dilutes meaningful content.

---

### [DOC-005] Specification-Mirroring Documentation

**Statement**: When a type models an external specification (RFC, ISO, etc.), the inline documentation MUST contain:

1. Summary line = specification section title
2. Specification section heading (domain-appropriate, see [DOC-041])
3. Specification text in blockquote (`>` prefix) — verbatim or summarized
4. Cross-references to related specification sections via DocC links

**Correct**:
```swift
/// Name String UUID from a namespace (Version 5, SHA-1).
///
/// ## RFC 4122 Section 4.3
///
/// > [1.](<doc:RFC 4122/Section 4.3/1>) The version 5 UUID is meant for
/// > generating UUIDs from "names" that are drawn from, and unique within,
/// > some "name space".
/// >
/// > [2.](<doc:RFC 4122/Section 4.3/2>) The concept of name and name space
/// > should be broadly construed, and not limited to textual names.
public struct V5: Sendable { ... }
```

**Incorrect**:
```swift
/// Deals with namespace UUIDs.
public struct V5: Sendable { ... }  // ❌ No spec text, no section heading, vague summary
```

**Rationale**: Specification-mirroring types exist to model a specification. The documentation must carry that specification text so developers don't need to consult external sources.

**Cross-references**: [API-NAME-003], [DOC-033]

---

### [DOC-006] Subsection Enumeration

**Statement**: When a specification section has numbered subsections, each MUST be listed with a DocC link and one-line summary:

**Correct**:
```swift
/// > [1.](<doc:RFC 4122/Section 4.4/1>) The version 4 UUID is meant for
/// > generating UUIDs from truly-random or pseudo-random numbers.
/// >
/// > [2.](<doc:RFC 4122/Section 4.4/2>) Set the two most significant bits
/// > of the clock_seq_hi_and_reserved to zero and one, respectively.
/// >
/// > [3.](<doc:RFC 4122/Section 4.4/3>) Set the four most significant bits
/// > of the time_hi_and_version field to the 4-bit version number.
```

**Rationale**: Subsection links create a navigable table of contents within the parent type's documentation, enabling direct navigation to specific clauses.

**Cross-references**: [DOC-024]

---

### [DOC-007] Abbreviated Subsection Syntax

**Statement**: When subsections are too dense to reproduce verbatim, they MAY be abbreviated using bracketed descriptions:

**Correct**:
```swift
/// > 3.-6. [Specifies the conversion of the name to a canonical sequence
/// > of octets, the hashing strategy, and the byte ordering rules for
/// > the resulting UUID fields]
```

**Rationale**: Brackets signal summarization versus verbatim text, preserving the reader's ability to distinguish between exact specification language and editorial summaries.

---

### [DOC-008] Cross-Reference Formats

**Statement**: Two cross-reference formats are recognized:

| Format | Use Case | Example |
|--------|----------|---------|
| DocC link | Explicit authored links, cross-article, defined terms | `[Section 4.1](<doc:RFC 4122/Section 4.1>)` |
| Backtick auto-link | Casual sibling references | `` ``V4`` `` |

DocC links MUST be used when linking to a different specification section or a defined term. Backtick auto-links MAY be used for sibling references within the same parent scope.

**Correct**:
```swift
/// > The [namespace](<doc:RFC 4122/Namespaces>) provides a way to generate
/// > [name-based UUIDs](<doc:RFC 4122/Section 4.3>), ensuring that the same
/// > name in the same namespace always produces the same UUID, as defined in
/// > [Section 4.1](<doc:RFC 4122/Section 4.1>).
```

```swift
/// Delegates to ``V4`` and ``V5`` depending on the requested version.
```

**Rationale**: Consistent link formatting enables navigation. DocC links for cross-article references create clickable paths; backtick links for siblings keep local references lightweight.

---

### [DOC-009] Definition Index Pattern

**Statement**: When a section defines multiple terms (e.g., a definitions article), the documentation SHOULD list each definition with an italic title and DocC link:

**Correct**:
```swift
/// > _[UUID](<doc:RFC 4122/UUID>)_: A 128-bit number used to uniquely
/// > identify information in computer systems.
/// >
/// > _[Namespace](<doc:RFC 4122/Namespace>)_: A UUID that uniquely
/// > identifies the context of a name.
```

```swift
/// RFC 4122 Section 4.1.7: _[Nil UUID](<doc:RFC 4122/Nil>)_
/// RFC 4122 Section 4.4: _[Version 4 UUID](<doc:RFC 4122/V4>)_
```

**Rationale**: Definition indices create a navigable glossary. The italic-plus-link pattern is visually consistent and DocC-renderable.

---

### [DOC-010] Explanatory Material Exclusion

**Statement**: Explanatory material (design commentary, rationale prose, historical context, decision matrices, multi-paragraph concept explanations) MUST NOT appear in inline `///` comments. References to Research/ documents and Experiments/ packages MUST NOT appear in inline `///` comments. Inline docs contain summary + canonical usage snippet + specification text + cross-references only.

Explanatory material belongs in layers 2 (per-symbol article's `## Rationale`), 3 (topical article), or 4 (tutorial), depending on its nature:

| Explanatory content | Layer | Location |
|---------------------|-------|----------|
| Why this type exists | Layer 2 | Per-symbol article's `## Rationale` |
| How to choose between siblings (decision matrix) | Layer 3 | Topical article |
| Step-by-step walkthrough | Layer 4 | Tutorial |
| Research references / historical context | Layer 2 or 3 | Per-symbol article's `## Research` / topical article |

**Rationale**: Inline docs are the call-site affordance for the four-layer model's Layer 1 audience — coders actively using the package. Explanatory material at the call site distracts, takes space in hover pop-ups, and mixes the normative contract (what the API does) with non-normative context (why it was designed this way). The call-site reader either needs the contract and can get it from inline, or wants the context and clicks through to the rendered article.

**Cross-references**: [DOC-001], [DOC-027], [DOC-028], [DOC-029], [DOC-060], [README-016] (README counterpart of this exclusion rule)

---

