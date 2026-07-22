# Documentation — Style, Currency, and External References

Part of the **documentation** skill. See `SKILL.md` for the navigation hub, four-layer audience model, and rule index.

**Rules in this file**: [DOC-030], [DOC-031], [DOC-032], [DOC-033], [DOC-040], [DOC-041], [DOC-042], [DOC-043], [DOC-044], [DOC-045], [DOC-046], [DOC-047], [DOC-048], [DOC-049], [DOC-050], [DOC-051], [DOC-052], [DOC-053], [DOC-054], [DOC-103].

---

## External Specification References

### [DOC-030] External Links

**Statement**: The root page MUST include a link to the authoritative external specification when the module models one:

**Correct**:
```markdown
- [RFC 4122 — A Universally Unique IDentifier (UUID) URN Namespace](https://www.rfc-editor.org/rfc/rfc4122)
```

```markdown
- [ISO 32000-1 — Portable Document Format](https://www.iso.org/standard/51502.html)
```

**Rationale**: The external link enables verification of the Swift model against the authoritative source.

---

### [DOC-031] Cross-Module References

**Statement**: When inline documentation references specifications outside the current module (e.g., a different RFC, a different ISO standard), the reference MUST use the full specification identifier:

**Correct**:
```swift
/// as required by RFC 3986 Section 3.3
```

```swift
/// conforms to ISO 32000-1 Section 7.5.5
```

DocC links SHOULD be used when the referenced specification has a corresponding Swift module.

**Rationale**: Full identifiers are unambiguous. Bare numbers like "3.3" are meaningless without the specification context.

---

### [DOC-032] Range Reference Pattern

**Statement**: When a specification references a range of sections, the documentation MUST link both endpoints and preserve the specification's range language:

**Correct**:
```swift
/// [Section 4.1](<doc:RFC 4122/Section 4.1>) through [Section 4.5](<doc:RFC 4122/Section 4.5>), inclusive
```

**Rationale**: Range references are a standard specification citation pattern. Linking both endpoints enables navigation to either bound.

---

### [DOC-033] Blockquote Convention

**Statement**: Verbatim specification text MUST use the `>` blockquote prefix in both inline docs and .docc articles. This delineates normative specification text from original commentary.

**Correct**:
```swift
/// > **Version 4 UUID**
/// >
/// > [1.](<doc:RFC 4122/Section 4.4/1>) The version 4 UUID is meant for
/// > generating UUIDs from truly-random or pseudo-random numbers...
```

**Incorrect**:
```swift
/// The version 4 UUID is meant for generating UUIDs from truly-random
/// or pseudo-random numbers...
// ❌ No blockquote — reader cannot distinguish spec text from commentary
```

**Exception — legal statute-encoding packages**: Legal statute-encoding packages (the `swift-nl-wetgever` GitHub org and the `rule-institute` legal domain generally) present verbatim statute text as bold numbered lid paragraphs (`**N.** <wetstekst>`) under an article heading (`## art. 2:N BW` style), NOT as `>` blockquotes. The source heading itself carries the "this is quoted law" signal that the blockquote prefix supplies elsewhere — the entire doc body under such a heading IS the quoted statute, so lid-numbered paragraphs are the domain-native presentation. This is a genuine exception, not a relaxation: the `>` blockquote MUST remain intact for specification-implementing packages (RFC, ISO, IETF, etc.), where quoted spec text and original commentary are interleaved on the same page and the blockquote is what tells them apart.

**Correct (legal domain)**:
```markdown
## art. 2:194 BW

**1.** Het bestuur houdt een register waarin de namen en adressen van alle
aandeelhouders zijn opgenomen, met vermelding van de datum waarop zij het
aandeel of het recht van vruchtgebruik of pand op een aandeel hebben
verkregen...

**2.** ...
```

**Rationale**: The blockquote visually and semantically marks text as quoted from an external authority, preventing confusion between the specification's words and the author's commentary. In the legal-encoding domain the entire document body already IS quoted law under an explicit source heading, so the blockquote's disambiguating job is done by the heading instead — lid-numbered bold paragraphs are how the domain itself presents statute text.


**Cross-references**: [DOC-005], **legal-encoding** skill [LEG-ENC-*] (statute-text encoding conventions)

---

## Documentation Quality

### [DOC-040] Documentation Tiers

**Statement**: Documentation MUST be classified into tiers based on implementation maturity. Types SHOULD progress through tiers as they gain implementation.

| Tier | .docc Article | Inline Docs | When |
|------|--------------|-------------|------|
| 1 — Full | Spec text + examples + explanatory material + research/experiment refs + companion docs | Spec text + examples + cross-refs | Implemented type with companion material |
| 2 — Standard | Spec text + examples + research/experiment refs | Spec text + examples + cross-refs | Implemented type |
| 3 — Enumerated | @Metadata + Topics | Subsection enumeration with links | Multi-subsection type, not yet implemented |
| 4 — Minimal | @Metadata only | Summary line + abbreviated spec text | Partially documented |
| 5 — Shell | @Metadata only | None or summary only | Namespace container / placeholder |

**Rationale**: The tier system enables incremental documentation without blocking forward progress. Shell types don't need full documentation, but implemented types with available companion material should reach tier 1.

---

### [DOC-041] Section Heading Conventions

**Statement**: Specification section headings SHOULD mirror the specification's own terminology:

| Domain | Spec Heading | Explanatory Heading |
|--------|-------------|---------------------|
| RFCs | `## RFC {N} Section {M}` | `## Design Notes` |
| ISO standards | `## ISO {N} Section {M}` | `## Rationale` |
| IETF drafts | `## Draft {Name} Section {M}` | `## Design Notes` |
| General | `## Specification` | `## Rationale` |

**Rationale**: Domain-native headings help domain experts orient immediately. An engineer reading "RFC 4122 Section 4.1" immediately knows what follows.

---

### [DOC-042] Documentation Currency

**Statement**: When specification text changes, both inline docs and .docc articles MUST be updated. The .docc `@DisplayName` MUST reflect the current specification title.

**Rationale**: Stale documentation that contradicts the current specification is worse than no documentation.

---

## Code Comments and Content Quality

### [DOC-043] Comment Purpose

**Statement**: Comments in source code MUST explain *why*, not *what*.

**Correct**:
```swift
// Use non-blocking to avoid thread pool exhaustion
let selector = IO.NonBlocking.Selector()
```

**Incorrect**:
```swift
// Create a selector
let selector = IO.NonBlocking.Selector()  // ❌ Describes what, not why
```

**Rationale**: Purpose-driven comments add information the code cannot convey.

---

### [DOC-044] Anticipatory Documentation

**Statement**: When code makes a decision that future readers might question, comments MUST anticipate those questions and provide answers. The comment should transform "this looks wrong" into "this is correct for documented reasons."

| Question Type | What to Document |
|---------------|------------------|
| "Can this be done differently?" | Why alternatives don't work |
| "When will this change?" | Migration conditions |
| "Is this a bug or intentional?" | Explicit statement of intent |
| "Why isn't X used here?" | Constraints that prevent X |

**Correct**:
```swift
/// Note: Span<T> is ~Escapable, which requires special handling.
/// For now, we provide conformances only for Escapable collection types.
/// Span-based parsing will be added when lifetime annotations are stable.
associatedtype Input
```

Anticipatory documentation is REQUIRED when:

1. Language limitations prevent obvious patterns — document the limitation and workaround
2. Design defers to future language evolution — specify the trigger for change
3. Code differs from similar code elsewhere — explain why the difference is intentional
4. A pattern looks wrong but is correct — explicitly state it's intentional

**Rationale**: Most developers don't read documentation until their intuitive approach fails. Documentation that addresses failure modes meets developers where they are.

---

### [DOC-045] Workaround Documentation Template

**Statement**: Workarounds MUST be documented using a standard four-part template.

```swift
// WORKAROUND: [What this works around]
// WHY: [Why the normal approach does not work]
// WHEN TO REMOVE: [Specific condition under which the workaround can be removed]
// TRACKING: [Issue URL or internal reference]
```

**Example**:
```swift
// WORKAROUND: This Sequence conformance only compiles because all source code
// is consolidated into a single file.
// WHY: Compiler bug prevents multi-file compilation of this conformance.
// WHEN TO REMOVE: When the compiler bug is fixed.
// TRACKING: https://github.com/swiftlang/swift/issues/86669
```

| Field | Purpose |
|-------|---------|
| `WORKAROUND` | Identifies the comment as a managed workaround, not a design choice |
| `WHY` | Prevents future readers from "fixing" load-bearing structure |
| `WHEN TO REMOVE` | Provides exit criteria so the workaround does not outlive its cause |
| `TRACKING` | Links to an external issue for status checking |

A workaround missing any of these fields is incomplete.

**Rationale**: Workarounds following a standard template are managed constraints with clear lifecycles. Workarounds without documentation become permanent because no one knows whether they are still necessary.

**Lint enforcement**: SwiftLint custom rule `workaround_marker_present` (`swift-institute/.github/.swiftlint.yml`) is an advisory regex that fires on every `// WORKAROUND:` marker as an audit reminder. It does NOT verify the four-part template's completeness — that requires multi-line context and is a future swift-linter F-rule (Batch 3 candidate). Reviewers MUST verify the four companion markers (WHY / WHEN TO REMOVE / TRACKING) are present within ±5 lines. Added Wave 2b 2026-05-10.

---

### [DOC-046] Deviation Documentation Template

**Statement**: When a type deviates from an established pattern in the same codebase, a standard documentation template MUST be used. The template acknowledges the pattern, explains the difference, and states the consequence.

```swift
/// ## [Property Name]
///
/// Unlike [Reference Type] which [does X] because [reason],
/// [This Type] [does Y] because [different reason].
/// Therefore it [has consequence].
```

**Example**:
```swift
/// ## Copyable
///
/// Unlike `Stack.Small<Element>` which is `~Copyable` because it stores
/// potentially move-only elements, `Set<Bit>.Packed.Small` stores only `UInt`
/// words (always trivial) and has no generic element type. Therefore it is
/// unconditionally `Copyable`, enabling `Sequence`, `Equatable`, and `Hashable`.
```

| Component | Purpose |
|-----------|---------|
| Acknowledge the pattern | Signals awareness of the expected behavior |
| Explain the difference | Provides the concrete reason for deviation |
| State the consequence | Shows the practical effect of the deviation |

**Rationale**: Intentional deviations that are undocumented look identical to accidental deviations. The template short-circuits unnecessary investigation by making intent explicit.

---

### [DOC-047] Learning Path Preservation

**Statement**: Documentation for unfamiliar territory SHOULD preserve learning paths, not just conclusions. A document that says "use pattern X" is less useful than one that explains why obvious alternatives Y and Z fail.

**Correct**:
```markdown
## Unsafe Expression Marking

### The Parenthesization Pattern

For assignments to unsafe storage, parentheses define the expression boundary:

` ` `swift
unsafe (self.raw = value)  // Entire assignment as one expression
` ` `

### Why Other Patterns Fail

| Failed Pattern | Why It Fails |
|----------------|--------------|
| `self.raw = unsafe value` | Only marks the value, not the destination |
| `unsafe { self.raw = value }` | Block creates closure context; can't assign to `let` |
```

**Incorrect**:
```markdown
## Unsafe Expression Marking

Use `unsafe (self.raw = value)` for pointer assignments.

❌ Missing: why the parentheses matter, what alternatives fail, why they fail
```

Apply when: (1) documenting new language features, (2) explaining patterns that contradict intuition, (3) writing migration/remediation guides, (4) capturing knowledge from exploration sessions.

**Rationale**: Developers encountering new features try the obvious patterns first. Documentation that addresses those failures provides faster onboarding.

---

### [DOC-048] Compromise Documentation

**Statement**: Documentation of compromises is more valuable than documentation of ideal code. When workarounds exist, documentation MUST include: (1) why the workaround exists, (2) what the ideal solution would be, (3) when the workaround can be removed.

**Correct**:
```markdown
## Resource Pool Effects

### Current Implementation

Uses `Reference.Box<Resource>` because Swift's associated types
implicitly require `Copyable`.

### Migration Path

When Swift Evolution accepts "Suppressed Associated Types,"
remove the `Box` wrapper and change `Value = Reference.Box<Resource>`
to `Value = Resource`.
```

**Rationale**: Workarounds documented with migration paths are technical debt with known payoff dates. Workarounds without documentation become permanent.

---

### [DOC-049] Escape Hatch Counter-Marketing

**Statement**: Documentation for escape hatches (unsafe wrappers, unchecked markers, compiler bypasses) SHOULD actively discourage use when alternatives exist.

**Correct**:
```markdown
## Sendability.Unchecked

This type bypasses the compiler's `Sendable` checking.
This wrapper provides **no runtime validation** and **no guarantees**.
It is an auditable assertion site, not a safety mechanism.

**Prefer alternatives when possible**: For domain types you control,
mark the containing type `@unchecked Sendable` directly.
```

| Claimed | Actual |
|---------|--------|
| Safety | None — bypasses compiler checking |
| Protection | None — no runtime validation |
| **Auditability** | **Yes** — grep finds every escape site |

**Rationale**: Most documentation sells its subject. Escape hatch documentation must do the opposite — discourage use and honestly state limitations.

---

### [DOC-050] Code Example Quality

**Statement**: All code examples in documentation (inline `///` and `.docc` articles) MUST:

1. Include all required `import` statements
2. Use domain-meaningful identifiers (NOT `Foo`, `Bar`, `x`, `y`)
3. Specify code block language

Non-trivial examples SHOULD demonstrate error handling explicitly.

**Correct**:
```swift
import IO

let connection = try Network.Connection(host: "api.example.com", port: 443)
```

**Incorrect**:
```swift
let foo = try Bar(x: "...", y: 123)  // ❌ Meaningless identifiers, missing import
```

**Rationale**: Complete, realistic examples demonstrate actual usage patterns and enable copy-paste verification.

**Cross-references**: [README-022]

---

## Documentation Maintenance

### [DOC-051] Automated Verification of Derived Information

**Statement**: For any property that can be computed from source (tier assignments, dependency counts, package inventories), documentation SHOULD be generated or verified automatically.

| Property | Source of Truth | Verification Method |
|----------|----------------|---------------------|
| Tier assignments | Package.swift dependency graphs | Compute `tier[pkg] = max(tier[dep] for dep in deps) + 1` |
| Dependency counts | Package.swift files | Parse and count |
| Package inventories | Directory listings | Enumerate targets |
| Module names | Package.swift product declarations | Parse and extract |

Normative documents containing derived information SHOULD include a CI verification step.

**Rationale**: Incremental changes to source produce systemic documentation drift when no global verification exists.

---

### [DOC-052] Semantic Labels vs Computed Values

**Statement**: Computed values (tier numbers, dependency counts) MUST be treated as facts. Human-assigned labels (tier names, category descriptions) MUST be treated as commentary that requires periodic re-evaluation.

**Correct**: "As of this version, tier 7 contains linear algebra and input handling packages."

**Incorrect**: "Tier 7 is for advanced numerical packages." (implies a prescriptive constraint)

**Rationale**: Treating descriptive labels as prescriptive rules creates false constraints when computed values shift.

---

### [DOC-053] Document Versioning

**Statement**: Normative documents that undergo structural revision (not just clarification) warrant major version bumps.

| Change Type | Version Increment | Example |
|-------------|-------------------|---------|
| Typo or wording fix | Patch (x.y.Z) | Fix a misspelling |
| New section or clarification | Minor (x.Y.0) | Add a new subsection |
| Structural model change | Major (X.0.0) | Nine tiers become sixteen |

A major version signals: "Re-read this document. The model changed and cross-references may be stale."

**Rationale**: Without versioned documents, structural changes propagate silently.

---

### [DOC-054] Toolchain and Snapshot Version Labels Match Empirical `swift --version`

**Statement**: Any toolchain or snapshot version label written into a documentation artifact — inline `///`, `.docc` article, README, Research bundle, Experiment record, benchmark record, Issues entry, or code comment — MUST match the version string reported by `swift --version` when that snapshot's toolchain is selected (`TOOLCHAINS=<bundle-id> swift --version`). The label MUST NOT be inferred from the toolchain's install-directory name, its bundle-ID prefix, its snapshot date, or memory. Before writing the label, select the toolchain, run `swift --version`, and cite the output verbatim.

**Why the proxies fail**:

| Proxy | Why it is unreliable |
|-------|----------------------|
| Bundle-ID prefix | `org.swift.64202605121a` starts with `64` but the toolchain reports `6.5-dev` — snapshot tooling enforces no strict prefix↔version mapping |
| Snapshot date | The 6.4-dev → 6.5-dev cutover fell between the 2026-05-07-a and 2026-05-12-a snapshots (five days); "early 2026 = 6.4-dev" is already wrong by mid-May |
| Install-dir name / memory | Both are second-hand copies of a claim the toolchain itself answers authoritatively |

**Empirically verified examples** (2026-05-23):

| Bundle ID | Snapshot | `swift --version` reports |
|-----------|----------|---------------------------|
| `org.swift.64202603161a` | 2026-03-16-a | `Apple Swift version 6.4-dev` |
| `org.swift.64202605071a` | 2026-05-07-a | `Apple Swift version 6.4-dev` |
| `org.swift.64202605121a` | 2026-05-12-a | `Apple Swift version 6.5-dev` |

**When auditing existing docs**: grep for snapshot-date or bundle-ID patterns paired with a version claim; cross-reference each against `swift --version`; correct every mismatch with an explicit citation to the verified output.

**Rationale**: Snapshot version labels are factual claims that propagate into public artifacts. A mislabel misleads downstream readers and embarrasses the Institute when a Swift maintainer follows a link and finds the label wrong. The 2026-05-23 Arc 6 audit found mislabels in *both* directions (docs calling 6.4-dev snapshots "6.5-dev" and vice-versa) precisely because authors guessed from the bundle-ID prefix or the date. The single source of truth is the toolchain's own report.


**Cross-references**: [DOC-042] (documentation currency), [DOC-051] (automated verification of derived information), [DOC-052] (semantic labels vs computed values); **swift-package-build** skill (`TOOLCHAINS` env-var toolchain selection).

---

### [DOC-103] Documentation Code Examples MUST Comply With Code-Surface Rules

**Statement**: All identifiers in documentation code examples — README snippets, inline `///` doc comments, `.docc` article code blocks, Research/Experiments illustrative samples, blog post examples — MUST comply strictly with the code-surface naming rules: [API-NAME-001] (`Nest.Name` pattern), [API-NAME-002] (no compound method/property names), [API-NAME-003] (specification-mirroring exception). Examples that violate these rules teach the wrong convention even when the package's shipped API is clean.

**Correct documentation example**:
```swift
let stack = Stack.Inline<Int>()       // ✓ Nest.Name
dir.walk.files()                       // ✓ nested accessor
let entry = dir.find(name: "config")   // ✓ single word
```

**Incorrect documentation example**:
```swift
let stack = InlineStack<Int>()         // ❌ compound type name
dir.walkFiles()                        // ❌ compound method
let entry = dir.findEntry("config")    // ❌ compound method
```

**Boolean-naming exception**: `is + adjective` boolean property names (`isEmpty`, `isFinished`, `isFulfilled`, `isClosed`, `isConsumed`) are **explicitly permitted** under [API-NAME-002] per Swift API Design Guidelines. Do NOT "correct" canonical `is*` boolean property names; only rename genuine verb-noun compounds (`borrowBase`, `consumeBase`, `walkFiles`, `openWrite`).

**Historical/comparison framing exception**: documentation that explicitly contrasts non-compliant external code with the compliant pattern (e.g., a migration narrative *from* `walkFiles()` *to* `walk.files()`) MAY include the non-compliant form when the framing is unambiguous. Default to compliance; the migration narrative is the genuine exception.

**Pre-write scope check**: every type referenced must be `Nest.Name` or single-word; every method/property must be single-word or explicitly nested.

**Why**: documentation is part of the API surface — readers learn conventions from examples regardless of what the underlying package ships. A README with `InlineStack<Element>` teaches the wrong pattern even if the package exports `Stack.Inline<Element>`. Examples are templates that propagate.


**Cross-references**: [API-NAME-001], [API-NAME-002], [API-NAME-003], [DOC-050]

