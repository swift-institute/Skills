---
name: swift-institute-ecosystem
description: |
  Ecosystem tour: three layers (Primitives/Standards/Foundations), Standards per-authority sub-orgs, -standard convergence, layer-placement decision model, cross-cutting disciplines.
  Apply when orienting an agent or pointing to deeper references.

layer: architecture

requires:
  - swift-institute-core

applies_to:
  - swift
  - swift6
  - swift-primitives
  - swift-standards
  - swift-foundations

created: 2026-05-16
---

# Swift Institute Ecosystem Tour

Single-skill orientation for the Swift Institute ecosystem. Maps the published GitHub orgs, the three active layers, the per-authority Standards sub-orgs, the cross-cutting disciplines, and the deeper-reading routes. Carries no enforcement rules of its own — every rule cited here is owned by another skill, and this skill points rather than duplicates.

---

## TL;DR — 30-second view

Three active layers, each with its own GitHub organization. Standards additionally distributes across a constellation of per-authority sub-orgs — it is *"an organization of organizations"*. Every layer's main target is Apple-`Foundation`-free; dependencies never flow upward, while essential same-layer composition forms an acyclic graph. The normative five-layer model, dependency-direction rule, and per-layer licensing are owned by **swift-institute** ([ARCH-LAYER-001]); package locations on disk are owned by **swift-institute-core**. This tour maps orgs and naming onto that model rather than redefining it.

| Layer | Question answered | Org | Package naming | License |
|-------|-------------------|-----|----------------|---------|
| L1 Primitives | What must exist? | [swift-primitives](https://github.com/swift-primitives) | `swift-{concept}-primitives` | Apache 2.0 |
| L2 Standards (convergence) | What is the stable form? | [swift-standards](https://github.com/swift-standards) | `swift-{concept}-standard` | Apache 2.0 |
| L2 Standards (spec-direct) | What does spec X require? | swift-ietf, swift-iso, swift-w3c, swift-whatwg, swift-ieee, swift-iec, swift-ecma, swift-incits, swift-arm-ltd, swift-intel, swift-riscv, swift-microsoft | `swift-{rfc-id}` / `swift-{iso-id}` / `swift-{spec-id}` | Apache 2.0 |
| L3 Foundations | What can be composed? | [swift-foundations](https://github.com/swift-foundations) | `swift-{concept}` (no suffix) | Apache 2.0 |
| L4 Components (reserved) | What is reusable with defaults? | TBD | TBD | Flexible |
| L5 Applications (reserved) | What is an end-user system? | TBD | TBD | Commercial |

**The umbrella org**: [github.com/swift-institute](https://github.com/swift-institute) — holds cross-cutting documentation, development conventions (Skills/), research, experiments, and the public website (swift-institute.org). Not a layer; the meta-home.

---

### [ECO-001] Why the Ecosystem Exists

**Statement**: The ecosystem exists for four reasons — a tour reader MUST be able to recite them when asked "why not just use Foundation?":

1. **Cross-platform consistency.** Apple's `Foundation` drifts between Darwin and `swift-corelibs-foundation` on Linux. Building on Swift directly lets every package iterate without waiting for Foundation's release cycle and without inheriting cross-platform behavior divergence. Portability target: Darwin (macOS/iOS/tvOS/watchOS/visionOS) and Linux supported now; Embedded Swift and Windows coming.
2. **Embedded Swift compatibility.** Embedded Swift has no Foundation runtime. Keeping Foundation out of every layer means the same packages compile for baremetal targets.
3. **Typed correctness as the primary verification approach.** The compiler enforces *meaning*, not just *shape* — each semantically distinct concept gets its own type even when the underlying representation is shared. The ecosystem treats the type system as the *primary* verification tool, the role tests and runtime contracts play in `Int`/`String`/`Data`-flavored designs. Investments span typed values, typed errors, ownership and lifetime annotations, strict memory safety, Sendability and isolation, and specification-as-namespace (`RFC_4122.UUID`, not `UUID`). See [ECO-007] for the discipline-level breakdown.
4. **Fine-grained packaging over monolith.** A consumer needing only affine transforms does not pull in temporal primitives. Smaller dependency graphs compile faster; breaking changes propagate only to actual dependents; each package answers one question well.

**Cross-references**: `swift-institute.org/Swift Institute.docc/FAQ.md`; [PRIM-FOUND-001] in **primitives**, [ARCH-LAYER-007] in **swift-institute**.

---

### [ECO-002] Layer-Placement Decision Model

**Statement**: When deciding which layer a new package belongs to, ask the FAQ's three-question decision model in order. The first "yes" determines the layer.

| Question | If yes → |
|----------|---------|
| Does an external specification define it (ISO, RFC, IEEE, W3C, WHATWG, vendor spec)? | L2 Standards |
| Do standards need it but not define it (prerequisite for standards)? | L1 Primitives |
| Does it compose standards and primitives into a reusable domain abstraction? | L3 Foundations |

**Worked examples**:
- `RFC 4122` (UUID): specified by IETF → L2 (swift-ietf/swift-rfc-4122, with `RFC_4122.UUID`)
- `Buffer.Ring`: prerequisite for many specs (storage substrate) → L1 (swift-buffer-primitives)
- `swift-pdf` (composed PDF rendering): composes ISO 32000 + I/O + geometry → L3
- `swift-json` (composed JSON I/O): composes RFC 8259 + I/O + parser → L3

**Cross-references**: [ARCH-LAYER-001] in **swift-institute**; `swift-institute.org/Swift Institute.docc/FAQ.md`.

---

### [ECO-003] Primitives Are Atomic, Foundation-Free, Tiered Internally

**Statement**: The Primitives layer answers *"what must exist?"* — irreducible types that higher layers compose. Primitives MUST NOT import Apple `Foundation`, MUST be deployable on Swift Embedded, and are organized internally as a 13-tier DAG (tiers 0–12). The tier mechanism is unique to Primitives; Standards and Foundations do not tier internally.

**Surface shape**:
- Package name: `swift-{concept}-primitives`
- Library name in `Package.swift`: `{Concept} Primitives` (spaces)
- Import statement: `import {Concept}_Primitives` (underscores)
- Tier 0 (Atomic) packages have no primitive dependencies; each higher tier may only depend on lower tiers. Sample tier 0: `swift-ascii-primitives`, `swift-error-primitives`, `swift-ownership-primitives`, `swift-tagged-primitives`, `swift-hash-primitives` (and ~16 others).

**Cross-references**: [PRIM-FOUND-001], [PRIM-ARCH-001], [PRIM-ARCH-002] in **primitives**; `swift-primitives/Documentation.docc/Primitives Tiers.md`, `Primitives Layering.md`, `Primitives Requirements.md`.

---

### [ECO-004] Standards Are an Organization of Organizations

**Statement**: The Standards layer is *"primarily an organization of organizations"* — each standards-authority body has its own GitHub org holding the packages specific to that authority. Org membership signals authority at a glance. The question each org name answers is *"who standardized this?"*

| Org | Authority | Spec-direct package shape |
|-----|-----------|---------------------------|
| [swift-ietf](https://github.com/swift-ietf) | IETF (RFCs) | `swift-rfc-{number}` (e.g. `swift-rfc-4122`, `swift-rfc-3986`, `swift-rfc-8259`) |
| [swift-iso](https://github.com/swift-iso) | ISO | `swift-iso-{number}` (e.g. `swift-iso-32000`) |
| [swift-w3c](https://github.com/swift-w3c) | W3C | `swift-{spec-id}` |
| [swift-whatwg](https://github.com/swift-whatwg) | WHATWG | `swift-{spec-id}` |
| [swift-ieee](https://github.com/swift-ieee) | IEEE | `swift-{spec-id}` |
| [swift-iec](https://github.com/swift-iec) | IEC | `swift-{spec-id}` |
| [swift-ecma](https://github.com/swift-ecma) | Ecma | `swift-{spec-id}` |
| [swift-incits](https://github.com/swift-incits) | INCITS | `swift-{spec-id}` |
| [swift-arm-ltd](https://github.com/swift-arm-ltd) | ARM (vendor) | `swift-{spec-id}` |
| [swift-intel](https://github.com/swift-intel) | Intel (vendor) | `swift-{spec-id}` |
| [swift-riscv](https://github.com/swift-riscv) | RISC-V (vendor) | `swift-{spec-id}` |
| [swift-microsoft](https://github.com/swift-microsoft) | Microsoft (vendor) | `swift-{spec-id}` |
| [swift-standards](https://github.com/swift-standards) | Convergence + cross-body / historical | `swift-{concept}-standard` (see [ECO-005]) |

**Type-naming consequence**: standards types MUST mirror the spec terminology — `RFC_4122.UUID`, not `UUID`; `ISO_32000.Page`, not `PDFPage`. The spec namespace IS the type's identity. *Specifications as namespaces* is one of the ecosystem's distinctive features.

**Dual-designation note — POSIX (2026-07-14)**: one specification can carry designations from two bodies — IEEE 1003.1 *is* ISO/IEC 9945 (POSIX). Two packages under different authority orgs are then NOT automatically duplicates: the packages partition by SURFACE, not by body (`swift-ieee-1003` carries the utility/shell-syntax surface under its spec-direct authority; `swift-iso-9945` carries the kernel/system-interface surface). Before flagging a cross-org pair as duplication, check whether the designations name one spec and the packages partition its surfaces (adjudicated: `DECISION-posix-spec-home-2026-07-14`, principal-ruled — keep separate).

**Cross-references**: [API-NAME-003] in **code-surface**; `swift-institute.org/Swift Institute.docc/Swift Standards.md`; blog post `Restarting-the-Blog.md` §"The standards refactor".

---

### [ECO-005] The `-standard` Convergence Pattern

**Statement**: When a domain is defined by multiple specifications (or one specification that undergoes revision), a `-standard` package in [swift-standards](https://github.com/swift-standards) converges the spec implementations into a single stable Swift module. Consumers depend on the `-standard` package; spec revisions are absorbed internally without consumer code change.

```
swift-standards/swift-{concept}-standard    ← consumer's stable import
         ↑
swift-{authority}/swift-{spec-id}           ← spec-direct packages
```

| Pattern | Consumer imports | When a spec changes |
|---------|------------------|---------------------|
| Spec-direct | The spec-specific module | Consumer code references the new spec |
| `-standard` convergence | The stable `*_Standard` module | `-standard` package absorbs the revision; consumer unchanged |

**Sample convergence packages**: `swift-html-standard`, `swift-pdf-standard`, `swift-time-standard`, `swift-uri-standard`, `swift-color-standard`, `swift-css-standard`, `swift-locale-standard`. (Many more.)

**Policy stance**: `-standard` packages are policy-free. They do not add opinion, ecosystem integration, or convenience. Higher-layer opinion lives in Foundations.

**Cross-references**: [ARCH-LAYER-001] in **swift-institute**; `swift-institute.org/Swift Institute.docc/Swift Standards.md`.

---

### [ECO-006] Foundations Are Composition Without Umbrella

**Statement**: The Foundations layer answers *"what can be composed?"* — primitives and standards integrated into reusable infrastructure. There is no umbrella `swift-foundations` library; each package is a standalone Swift package and consumers add dependencies individually. Foundations may depend on Standards and Primitives; Standards and Primitives may NOT depend on Foundations.

**Surface shape**:
- Package name: `swift-{concept}` (no suffix — clean names)
- Examples: `swift-json`, `swift-pdf`, `swift-tls`, `swift-http`, `swift-html`, `swift-css`, `swift-crypto`, `swift-config`, `swift-executors`, `swift-clocks`

**Multi-product packages**: many Foundations packages expose multiple library products; consumers depend only on what they need (umbrella vs narrow product). Import precision rules in **modularization** govern when to import the umbrella vs a narrow variant.

**Cross-references**: [ARCH-LAYER-001] in **swift-institute**; [PKG-DEP-001] in **swift-package**; [MOD-015] in **modularization**; `swift-institute.org/Swift Institute.docc/Swift Foundations.md`.

---

### [ECO-007] Cross-Cutting Disciplines Every Agent Must Know Upfront

**Statement**: These five disciplines are visible in every ecosystem package, regardless of layer. An agent that internalizes these before reading any specific skill will avoid the most common orientation mistakes.

| # | Discipline | Canonical source |
|---|------------|------------------|
| 1 | **No upward dependencies**: packages may compose lower layers and essential same-layer prerequisites through an acyclic graph. Same-layer convenience and cycles are forbidden. Within L1, the stricter tier DAG applies. | [ARCH-LAYER-001] in **swift-institute**, [PRIM-ARCH-002] in **primitives** |
| 2 | **No Apple `Foundation` in main targets**: applies to all five layers (not just L1). Foundation-adjacent interop lives in opt-in `* Foundation Integration` subtargets. | [PRIM-FOUND-001] in **primitives**, [ARCH-LAYER-007] in **swift-institute** |
| 3 | **Typed everything**: typed throws (`throws(IO.Error)`); typed indices (`Index<T>`); typed counts/positions (`Cardinal<N>`, `Ordinal<N>`); ownership and lifetime annotations (`~Copyable`, `~Escapable`, `borrowing`/`consuming`, `@_lifetime`); strict memory safety. Before writing arithmetic, conversions, or accessors, check **existing-infrastructure** — the missing operator is usually intentional. | [API-ERR-001] in **code-surface**, [INFRA-*] in **existing-infrastructure**, [MEM-COPY-*] in **memory-safety** |
| 4 | **Nested-namespace, noun-form naming**: `File.Directory.Walk`, not `FileDirectoryWalk`; `Stack.push.front(_:)`, not `stackPushFront(_:)`; specification-mirroring (`RFC_4122.UUID`, not `UUID`). One type per file. | [API-NAME-001], [API-NAME-002], [API-NAME-003], [API-IMPL-005] in **code-surface**, [PKG-NAME-001] in **swift-package** |
| 5 | **`~Copyable` passes through**: institute containers (Array, Stack, Queue, Deque, Buffer, etc.) support `~Copyable` elements via conditional Copyability. Reaching for `[Element]` when `Element: ~Copyable` is an anti-pattern; use the institute container instead. | [MEM-COPY-*] in **memory-safety**, [DS-021] in **ecosystem-data-structures** |

---

### [ECO-008] Deeper-Reading Routes

**Statement**: This skill is a tour, not a rule corpus. When more depth than this tour is required, route to the canonical sources by intent.

| Intent | Canonical source |
|--------|------------------|
| Apply layer-architecture rules | **swift-institute** ([ARCH-LAYER-*]) |
| Work within Primitives (tiers, Foundation-freedom, `~Copyable` patterns) | **primitives** ([PRIM-*]); `swift-primitives/Documentation.docc/Primitives Tiers.md`, `Primitives Layering.md`, `Primitives Requirements.md` |
| Name a package / namespace / module / dep | **swift-package** ([PKG-NAME-*], [PKG-DEP-*]) |
| API surface (naming, errors, file structure) | **code-surface** ([API-NAME-*], [API-ERR-*], [API-IMPL-*]) |
| Select a data structure (Memory / Storage / Buffer / Collection) | **ecosystem-data-structures** ([DS-*]) |
| Reuse existing typed infrastructure (boundary overloads, Tagged functors, Ratio scaling) | **existing-infrastructure** ([INFRA-*]) |
| Ownership, copyability, lifetime, sendability | **memory-safety** ([MEM-*]) |
| Skill index, harness bets, package locations on disk | **swift-institute-core** ([BET-*]); `/Users/coen/Developer/CLAUDE.md` |
| Public-facing layer descriptions (outside readers) | `swift-institute.org/Swift Institute.docc/{Layers,Swift Primitives,Swift Standards,Swift Foundations,FAQ}.md` |
| Public framing in user's own voice | `swift-institute.org/Swift Institute.docc/Blog/Restarting-the-Blog.md` and the `Introducing-*` series |
| Fork heritage decisions | **swift-package-heritage** ([HERITAGE-*]) |

---

### [ECO-009] Glossary — Essential Disambiguations

**Statement**: Terms whose meaning is ambiguous outside the ecosystem context. Other ecosystem terms (Tagged, Variant, Heritage, etc.) are defined in their owning skills — see [ECO-008] routes.

| Term | Meaning |
|------|---------|
| **Foundation** (Apple's) | Apple's `Foundation` framework — explicitly NOT used in any layer's main target. |
| **Foundations** (layer) | L3 of the ecosystem — composed building blocks. Distinct from Apple's Foundation framework. |
| **Layer** | One of five architectural positions (L1 Primitives, L2 Standards, L3 Foundations, L4 Components reserved, L5 Applications reserved). Each is its own GitHub org. |
| **Tier** | A position in the L1 Primitives DAG (0–12). Tier ≠ layer; tier is intra-L1. |
| **Authority** | A standards body (IETF, ISO, W3C, WHATWG, IEEE, IEC, Ecma, INCITS, ARM, Intel, RISC-V, Microsoft). Each has its own GitHub org. |
| **Umbrella org** | swift-institute — holds cross-cutting documentation, Skills/, Research/, Experiments/, the website. Not a layer. |
| **Umbrella library product** | A library product within a multi-product package that re-exports narrower variants. Distinct from umbrella org. |

---

## Cross-References

- **swift-institute-core** — System manifest, skill index, harness bets
- **swift-institute** — Five-layer architecture rules, semantic dependencies
- **swift-package** — Package and namespace naming, cross-repo dep form
- **primitives** — Primitives-layer extensions (Foundation independence, tiers)
- **code-surface** — Naming, error handling, file structure
- **memory-safety** — Ownership, `~Copyable`, lifetime safety
- **ecosystem-data-structures** — Data-structure selection across Memory/Storage/Buffer/Collection
- **existing-infrastructure** — Typed boundary overloads, Tagged, Ratio
- **swift-package-heritage** — Fork-as-heritage at the git/license/README level
- **modularization** — Intra-package target decomposition, import precision
- `swift-institute.org/Swift Institute.docc/` — Public layer descriptions
- `swift-primitives/Documentation.docc/` — Primitives Tiers, Layering, Requirements
- `/Users/coen/Developer/CLAUDE.md` — Workspace-level routing, package locations, package resolution

**Related-ecosystem cross-reference**: a parallel legal-domain ecosystem lives under [rule-institute](https://github.com/rule-institute) — out of scope for this skill; see `/Users/coen/Developer/CLAUDE.md` § Legal Skills.
