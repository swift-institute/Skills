# Platform — Composition Discipline & Platform Conditionals

When `#if os(...)` / `#if canImport(...)` conditionals are legitimate, the within-L3 sub-tier composition matrix (policy / unifier / domain), cross-layer composition discipline, platform-C import authority, the spec/policy namespace split, and the pre-flight checks that guard cross-package dependency direction and placement.

**Rules in this file**: [PLAT-ARCH-008a], [PLAT-ARCH-008b], [PLAT-ARCH-008c], [PLAT-ARCH-008d], [PLAT-ARCH-008e], [PLAT-ARCH-008f], [PLAT-ARCH-008g], [PLAT-ARCH-008h], [PLAT-ARCH-008i], [PLAT-ARCH-008j], [PLAT-ARCH-008k], [PLAT-ARCH-008l], [PLAT-ARCH-020], [PLAT-ARCH-021], [PLAT-ARCH-023], [PLAT-ARCH-024], [PLAT-ARCH-025], [PLAT-ARCH-028]

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/platform-skill-rationale.md` (the rationale archive).

---

### [PLAT-ARCH-008a] Domain Authority Exception (Limited)

> **Status**: PROVISIONAL — this exception requires explicit user confirmation before applying. When you encounter a case that appears to qualify, present the four criteria and ask the user to confirm before treating the conditional as accepted.

**Statement**: Non-platform-stack packages at any layer MAY contain `#if os(...)` or `#if canImport(...)` conditionals when **all four** of the following hold:

1. **Domain authority**: The package is the canonical owner of the concept that varies by platform.
2. **Kernel imports only**: All platform access goes through `import Kernel` (L3) or `import Kernel_Primitives` (L1) — never raw `import Darwin`/`Glibc`/`Musl`/`WinSDK`.
3. **Domain strategy, not syscall selection**: The conditional selects between domain-level strategies or defines platform-varying vocabulary types — it does not wrap raw syscalls. See [PLAT-ARCH-008d] for the concrete syscall-vs-policy decision test.
4. **Irreducible**: The platform variation cannot be pushed to the platform stack without Kernel absorbing domain semantics it shouldn't own.

**Examples of accepted domain authority conditionals**:

| Package | Conditional | Justification |
|---------|-------------|---------------|
| swift-paths | `#if os(Windows)` for `\` vs `/` separator | Path separators are path domain knowledge, not kernel knowledge |
| swift-io | `#if canImport(Darwin)` selecting kqueue vs epoll strategy | IO event loop strategy is IO domain logic; both backends use Kernel types |
| swift-string-primitives | `#if os(Windows)` for `UInt16` vs `UInt8` char width | Character encoding width is string vocabulary, not kernel vocabulary |
| swift-file-system | `#if os(Windows)` for permission model differences | File permission semantics are file-system domain knowledge |

**Hard line — always a violation regardless of domain authority**: Direct `import Darwin`/`Glibc`/`Musl`/`WinSDK` remains a violation in ALL non-platform-stack packages. If the platform stack doesn't expose the needed API, the fix is to extend the platform stack — not bypass it.

```swift
// ❌ ALWAYS wrong: raw platform imports outside L2 spec packages
#if canImport(Darwin)
import Darwin          // Must use import Kernel or import Kernel_Primitives
#elseif canImport(Glibc)
import Glibc           // If Kernel doesn't provide what you need, extend Kernel
#endif
```

**Within the platform stack** (revised 2026-04-30): platform-C imports are permitted EXCLUSIVELY at L2 spec packages (`swift-iso-9945`, `swift-darwin-standard`, `swift-linux-standard`, `swift-windows-32`). L3-policy packages (`swift-posix`, `swift-darwin`, `swift-linux`, `swift-windows`) and L3-unifier packages (`swift-kernel`, `swift-strings`, `swift-paths`, etc.) MUST NOT import platform C — they compose via L2's typed API per [PLAT-ARCH-008j]. L2 is the unique platform-C-import home; everything above L2 composes via L2's typed API.

**Rationale**: Domain packages that own platform-varying concepts are the natural home for composing platform abstractions differently per platform; forcing all conditionals into Kernel would make Kernel absorb domain logic. Full text: rationale archive §[PLAT-ARCH-008a].

**Cross-references**: [PLAT-ARCH-008], [PLAT-ARCH-008d], [PLAT-ARCH-008j], [PLAT-ARCH-002]

---

### [PLAT-ARCH-008b] Conditional Public API Surface in L3

**Statement**: L3 unified types (`swift-kernel`) MAY use `#if os(...)` on public enum cases when the wrapped type is defined in a platform-specific standard (e.g., `swift-iso-9945`) and cannot exist on all platforms. This is the sole acceptable form of conditional public API surface in L3.

**Conditions** (all must hold):

1. **Irreducible platform dependency**: The associated type is defined in a platform-specific standard layer (L2) with no Windows (or other absent platform) equivalent. A stub type would be semantically dishonest.
2. **No consumer impact**: No consumer exhaustively switches on the enum. Existing consumers use `default:` or match specific cases.
3. **L3 internal only**: The conditional lives in the L3 unified package itself, not in consumer code. Consumers still write `import Kernel` with no conditionals.
4. **Sole instance per type**: At most one conditional case per enum. Multiple conditional cases suggest the enum's abstraction level is wrong.

**Accepted instance**:

| Enum | Case | Guard | Wrapped Type | Source |
|------|------|-------|-------------|--------|
| `Kernel.Failure` | `.signal(Kernel.Signal.Error)` | `#if !os(Windows)` | `ISO_9945.Kernel.Signal.Error` | POSIX signals have no Windows analogue |

**Revisit if**: Swift gains `@nonExhaustive` semantics for non-resilient libraries (analogous to Rust's `#[non_exhaustive]`), which would allow unconditional cases without forcing consumer `#if` guards on exhaustive switches.

**Rationale**: A stub type on a platform with no underlying concept would be semantically dishonest; the conditional case preserves domain specificity. Full text (why-not-unconditional, why-not-absorb-into-`.platform`, swift-system prior art, provenance): rationale archive §[PLAT-ARCH-008b].

**Cross-references**: [PLAT-ARCH-008], [PLAT-ARCH-007], [API-ERR-001]

---

### [PLAT-ARCH-008c] L1 Primitives Are Unconditionally Platform-Agnostic

**Statement**: L1 Primitives packages MUST NOT contain platform-conditional code in any form — neither platform-conditional **type definitions** nor platform-conditional **implementation** — without exception. (a) When a lower-layer type requires platform-specific behavior, the implementation MUST live in platform packages as extensions on the lower-layer type — NOT as `#if os(...)` blocks inside the primitive package. (b) When a type's storage shape genuinely differs per platform, the type MUST be defined per L3-policy package (`swift-posix` / `swift-darwin` / `swift-linux` / `swift-windows`) with cross-platform name unification at L3-unifier (`swift-kernel`) via typealias per [PLAT-ARCH-005] — NOT as an inner `#if os(...)` storage definition at L1. The platform package boundary replaces conditional compilation in both dimensions: implementation and definition.

**No L1 exceptions**: prior to the 2026-04-26 revision, [PLAT-ARCH-005] permitted `Kernel.Descriptor` as a single L1 type with inner `#if os(...)` storage. That exception is eliminated; the L1-types-only invariant holds without carve-out. Three previously-divergent shapes (`Kernel.Descriptor`, `Kernel.Process.ID`, `Kernel.Directory.Entry`) MUST relocate per [PLAT-ARCH-005] / [PLAT-ARCH-015]. New types facing the same tension MUST follow the L3-typealias unification pattern from inception. (Descriptor relocation completed 2026-05-01; transition history: rationale archive §[PLAT-ARCH-008c].)

**Decision procedure**:

| Question | If Yes | If No |
|----------|--------|-------|
| Does the type's storage shape differ per platform (signedness, width, native handle vs fd, encoding width)? | Define per L3-policy with cross-platform name unification at L3-unifier via typealias per [PLAT-ARCH-005] | Define once at L1 with uniform storage |
| Does the operation require platform-specific knowledge (separators, syscall conventions, encoding)? | Implement in the platform package | Implement in the primitive package |
| Is the type visible in the platform package via re-exports? | Extend it directly | Add the dependency or re-export |
| Does the platform package only compile on one platform? | No `#if os()` needed inside — the package boundary is the conditional | Use `#if os()` per [PLAT-ARCH-008a] |

**Correct** — platform package extends lower-layer type:
```swift
// In swift-iso-9945 (compiles on POSIX only — no #if needed)
import Path_Primitives  // via Kernel_Primitives re-export

extension Path.View {
    public var parentBytes: Span<Path.Char>? { ... }  // Scans for '/' only
}

// In swift-windows-32 (compiles on Windows only)
extension Path.View {
    public var parentBytes: Span<Path.Char>? { ... }  // Scans for '/' and '\'
}
```

**Incorrect** — conditionals inside the primitive:
```swift
// ❌ In swift-path-primitives — platform-conditional implementation
extension Path.View {
    public var parentBytes: Span<Path.Char>? {
        #if os(Windows)
        // Windows separator logic
        #else
        // POSIX separator logic
        #endif
    }
}

// (Platform-conditional TYPE definition at L1 — the eliminated Descriptor exception — is
//  equally forbidden; see the [PLAT-ARCH-005] Incorrect example.)
```

**Rationale**: L1 primitives stay unconditionally platform-agnostic — uniform storage shape, uniform implementation, no carve-out; the re-export chain (behavior) and the L3-typealias chain (divergent shape) make per-platform definitions visible to cross-platform consumers. Full text (relationship to [PLAT-ARCH-008a], mechanism, provenance): rationale archive §[PLAT-ARCH-008c].

**Lint enforcement**: Workflow `validate-platform-architecture.yml` flags `^#if (os|canImport)` in every `*-primitives` package's `Sources/` (`swift-kernel-primitives` and `swift-cpu-primitives` exempt per [MOD-EXCEPT-001]). Detail + fixtures: rationale archive §[PLAT-ARCH-008c]. [VERIFICATION: WF validate-platform-architecture.py (PLAT-ARCH-008c)]

**Cross-references**: [PLAT-ARCH-005], [PLAT-ARCH-008a], [PLAT-ARCH-008e], [PLAT-ARCH-008h], [PLAT-ARCH-002], [PLAT-ARCH-006], [PLAT-ARCH-015]

---

### [PLAT-ARCH-008d] Syscall vs Policy Test for L3 Domain Packages

**Statement**: An L3 domain package's `#if os(...)` conditional is legitimate only when the conditional encodes DOMAIN POLICY visible to the consumer — not SYSCALL MECHANICS that the platform stack should unify. Syscall dispatch belongs in `swift-kernel` (and sibling L3 unifiers: `swift-strings`, `swift-paths`). Domain policy — semantics the consumer genuinely sees differ per platform — belongs in the L3 domain package itself.

The L3 layer has two distinct roles:

| Role | Packages | Owns |
|------|----------|------|
| **Unification** | `swift-kernel`, `swift-strings`, `swift-paths` | Syscall dispatch, encoding dispatch, platform-neutral vocabulary. No policy or opinion. |
| **Policy / Features** | `swift-file-system`, and other domain L3 packages | Domain opinions, default behaviors, features. Uses unified APIs from the unification packages. |

**Decision test**:

For each `#if os(...)` in an L3 domain package, ask: *"If `swift-kernel` / `swift-strings` / `swift-paths` already provided a unified API for this, would the consumer-observable behavior still differ per platform?"*

| Answer | Category | Action |
|--------|----------|--------|
| Yes — the domain model itself differs | **Policy** (permission models, ownership models, path-root conventions, domain-level error taxonomy) | `#if` stays in the L3 domain package; it is legitimate |
| No — only the kernel call differs, consumer sees unified behavior | **Syscall** (unlink vs `DeleteFileW`, fsync vs `FlushFileBuffers`, errno → error-enum mapping, UTF-8 vs UTF-16 decode) | Push the unification up into `swift-kernel` / `swift-strings` / `swift-paths`; remove the `#if` from the domain package |

**Relationship to [PLAT-ARCH-008a]**: This rule operationalizes [PLAT-ARCH-008a] condition 3 ("domain strategy, not syscall selection") with a concrete decision procedure. A conditional that appears to satisfy the four conditions of [PLAT-ARCH-008a] but fails the syscall-vs-policy test here is NOT legitimate — it represents an ecosystem gap where the unification layer (swift-kernel / swift-strings / swift-paths) needs a new unified API. [PLAT-ARCH-008a]'s "permission to have `#if`" is necessary; this rule's "observable policy differs" is sufficient.

**What this is NOT**: This rule does not forbid `#if` in L3 domain packages. It clarifies which `#if`s are legitimate and which signal ecosystem gaps. A domain package carrying syscall-dispatch `#if`s is not broken — it is expressing a gap. The fix is to extend the unification layer, not to suppress the gap with a workaround.

**Rationale**: swift-kernel unifies but cannot add policy/opinion; domain packages add the policy/opinion and features. Full text (site-classification examples table, ideal-state discussion, provenance): rationale archive §[PLAT-ARCH-008d].

**Cross-references**: [PLAT-ARCH-008], [PLAT-ARCH-008a], [PLAT-ARCH-008c], [PLAT-ARCH-008e], [PLAT-ARCH-007], [PLAT-ARCH-009]

---

### [PLAT-ARCH-008e] L3 Unifier Composition Discipline

**Statement**: The L3 cross-platform unifier (`swift-kernel`) MUST compose over its peer L3 platform-policy packages (`swift-posix`, `swift-darwin`, `swift-linux`, `swift-windows`) when those packages host policy-normalized wrappers — EINTR retry, partial-IO loops, platform error normalization — for the target syscall. The unifier MUST NOT inherit a method directly from L2 raw (`swift-iso-9945`, `swift-windows-32`, `swift-darwin-standard`, `swift-linux-standard`) via namespace-alias extension when a corresponding L3 platform-policy wrapper exists.

The platform stack composes in four tiers, not three:

| Tier | Packages | Role |
|------|----------|------|
| L2 raw | swift-iso-9945, swift-windows-32, swift-darwin-standard, swift-linux-standard | Spec-literal syscall wrappers. Zero policy. Documents "does NOT retry on EINTR". |
| L3 platform policy | swift-posix, swift-darwin, swift-linux, swift-windows | Normalize platform quirks: retry-wrap, partial-IO loop, error-normalize. |
| L3 cross-platform unifier | swift-kernel | Cross-platform API. Inherits normalized behavior from the L3 tier below. |
| L3 domain | swift-file-system, swift-io, etc. | Domain composition + domain opinion per [PLAT-ARCH-008d]. |

**Decision test**:

For each method `Kernel.T.m(_:)` visible through `import Kernel`, ask:

| Check | If yes |
|-------|--------|
| 1. `Kernel.T.m(_:)` is inherited from an L2 raw package via namespace-alias extension (not explicitly defined in swift-kernel) | proceed |
| 2. A method with the same name exists in an L3 platform-policy package (swift-posix / swift-darwin / swift-linux / swift-windows), delegating to the L2 raw | proceed |
| 3. The L3 platform wrapper adds behavior (retry, loop, normalization) — not a pure re-export | **violation** |

**Fix**: define `Kernel.T.m(_:)` explicitly in `swift-kernel` via file-level-guarded extensions that delegate to the L3 platform-policy wrapper on each platform. Raw access remains available under the spec-literal L2 path (e.g., `ISO_9945.Kernel.T.m(_:)`) for power-user call sites.

**Correct**:

```swift
// swift-kernel, file-level POSIX guard (Windows twin delegates to Windows.Kernel.File.Flush)
extension Kernel.File.Flush {
    public static func flush(_ fd: borrowing Kernel.Descriptor) throws(Error) {
        try POSIX.Kernel.File.Flush.flush(fd)   // retry-wrapped; inherits EINTR normalization
    }
}
```

**Incorrect**:

```swift
// swift-iso-9945 — adds Kernel.File.Flush.flush(_:) to the unifier's surface via namespace alias.
// swift-kernel consumers get raw fsync, silently skipping swift-posix's retry wrapper.
extension ISO_9945.Kernel.File.Flush {
    public static func flush(_ fd: borrowing Kernel.Descriptor) throws(Error) {
        let result = fsync(fd._rawValue)   // raw; no retry
        // ...
    }
}
```

**When this rule does NOT apply**: if no L3 platform-policy wrapper exists for the target syscall, or the L3 wrapper is a pure re-export with no added behavior, the unifier MAY delegate to L2 raw directly. The rule is "don't skip a load-bearing tier"; if the tier is empty, there is nothing to skip. Example: `Kernel.File.Flush.flush(_:)` on Windows may delegate directly to `windows-standard` if no `swift-windows` Flush wrapper exists (Windows has no EINTR — the would-be wrapper carries no policy).

**Namespace-identity decision check for choice (i) vs choice (ii)**: when the L3 platform package shares namespace identity with L1 via typealias (e.g., `Windows.Kernel ≡ Kernel` in `swift-windows-standard`), L2 and L3 extensions occupy the same syntactic slot at the same namespace. Consequence: **choice (i)** (add an L3 wrapper at the same intent name for architectural symmetry) is infeasible when L2 already defines that name — the L3 declaration collides at declaration time or creates use-site ambiguity; **choice (ii)** (unifier delegates directly to L2 per the empty-tier exception) is the only feasible path when the intent name is already claimed at L2. The correct planning check when scoping an L3 platform-policy wrapper: *"is the intent name currently defined at L2 under the same namespace identity?"* If yes, choice (i) requires first renaming L2 to spec-literal (the Phase-A-rename pattern); if no Phase A rename is justified, choice (ii) is forced. For the empty-tier exception to apply, L2 and L3 method names MUST be disjoint at the same namespace. (POSIX/Windows asymmetry narrative: rationale archive §[PLAT-ARCH-008e].)

**Relationship to sibling rules**:

- [PLAT-ARCH-008c] governs L1 → L2 discipline (L1 primitives stay platform-agnostic; platform behavior lives in L2).
- [PLAT-ARCH-008d] governs L3-domain `#if` usage (syscall-vs-policy test).
- [PLAT-ARCH-008e] (this rule) governs L3 → L3 discipline (cross-platform unifier composes over peer L3 platform-policy tier).

Together the three rules enforce strict downward composition: L1 → L2 → L3-platform-policy → L3-unifier → L3-domain. Each tier composes only over the tier directly below; no tier-skipping.

**Rationale**: any L2 method inherited via namespace alias silently leaks raw behavior through the unifier whenever a policy wrapper exists beside it. Full text (origin audit incident, provenance commits): rationale archive §[PLAT-ARCH-008e].

**Cross-references**: [PLAT-ARCH-001], [PLAT-ARCH-006], [PLAT-ARCH-008], [PLAT-ARCH-008c], [PLAT-ARCH-008d], [PLAT-ARCH-009], [PLAT-ARCH-010].

---

### [PLAT-ARCH-008f] Naming-Parity-Collision Pre-Check for L3 Unifiers

**Statement**: Before landing an L3 unifier method whose name is identical to the POSIX (or other spec-literal) name on the L2 raw surface reachable via the `Kernel_Primitives.Kernel` namespace alias, the writer MUST land a disambiguation step in the same commit. "L2 names are already spec-literal" is insufficient justification when the L3 unifier's chosen name is also spec-literal — both occupy the same syntactic slot.

**Four solution families** (choose one, document the choice in the commit):

| Solution | What it does | When it applies |
|----------|--------------|-----------------|
| (a) L2 spec-literal rename | Rename L2 to its POSIX man-page spelling (e.g., `flush` → `fsync`) to free the intent name for L3 | L2's name was already informal (`flush` vs. `fsync`); no ABI consumer breakage expected |
| (b) L3 abstract rename | Choose an L3 name that is intentionally distinct from L2 (e.g., `sync` at L3, `fsync` at L2) | L2's name is the spec-literal form; renaming L2 would violate [PLAT-ARCH-012] |
| (c) Sub-namespace on L2 | Expose L2 under a dedicated sub-namespace (`Raw`, `IO.Read`, `IO.Write`) so the unifier's intent name doesn't collide | Call sites want both surfaces; neither side can reasonably be renamed |
| (d) Package-level separation | Split L2 and L3 into visibility-separate packages (the socket precedent) | The collision is pervasive across many names in the family |

**Verification requirement**: `/Users/coen/Developer/swift-institute/Scripts/swift-build package build -- --build-tests` MUST be clean before the unifier lands. Test-target compilation catches import-level ambiguity that source-target compilation misses.

**Example (defect)**: A `swift-kernel` unifier landed `Kernel.File.Read.read(...)` / `Kernel.File.Write.write(...)` where L2's ISO 9945 package had already defined the same names at the same paths via the `Kernel_Primitives.Kernel` alias. The commit passed a source-only package build in isolation; the downstream `swift-file-system` build hit ambiguous-overload errors at every call site.

**Rationale**: When both sides are spec-literal at the same intent, the collision is silent at the L2-raw package boundary and surfaces only at downstream consumers; enumerating the solution families forces an explicit choice at commit time. Full text (worked solution-(a) example: `Kernel.Thread.Local` → L2 `Key`/`Index` renames; provenance): rationale archive §[PLAT-ARCH-008f].

**Cross-references**: [PLAT-ARCH-008e], [PLAT-ARCH-012], [API-NAME-003], [MOD-*]

---

### [PLAT-ARCH-008g] Pre-Flight Consultation Before Cross-L2 Dependencies

**Statement**: When a fix candidate involves adding a `.package(path: ...)` dependency (code or test) that crosses L2 package boundaries, the writer MUST grep the tracked homes — `Skills/platform/`, `Skills/modularization/`, `Internal/CLAUDE.md` (and `Internal/inbox.md` for undrained corrections) — for layering-direction entries matching the two packages' layer positions BEFORE proposing the dependency. Cross-L2 dependencies are the single most common site of ecosystem-wide dep-direction violations.

**Procedure**:

```bash
# Example: considering adding a dep from iso-9945 tests to linux-standard
grep -rl "iso9945\|iso-9945\|linux-standard" \
  ~/Developer/swift-institute/Skills/platform/ \
  ~/Developer/swift-institute/Skills/modularization/ \
  ~/Developer/swift-institute/Internal/CLAUDE.md \
  ~/Developer/swift-institute/Internal/inbox.md
```

If the grep returns a relevant layering rule, the rule governs. If no entry exists, proceed but consider whether the decision warrants a dated one-liner in `Internal/inbox.md` for the reflections pipeline to promote.

**Rationale**: The tracked-home consultation is the redundant backup that catches layering rules at the moment a cross-L2 dependency is written, even when the platform skill isn't loaded. Full text: rationale archive §[PLAT-ARCH-008g].

**Cross-references**: [PLAT-ARCH-007]

---

### [PLAT-ARCH-008h] Within-L3 Sub-tiering and Composition Matrix

**Statement**: L3-Foundations is internally sub-tiered into three roles. Composition flows through a 3×3 directional matrix with per-cell rules. Each L3 cross-package import MUST resolve to a permitted matrix cell.

**The three sub-tiers**:

| Sub-tier | Role | Members |
|----------|------|---------|
| **L3-policy** | Per-spec policy wrappers. Each L3-policy package wraps an L2-spec sibling and adds policy (EINTR retry, partial-IO loop, error normalization). | swift-posix (wraps swift-iso-9945), swift-darwin (wraps swift-darwin-standard), swift-linux (wraps swift-linux-standard), swift-windows (wraps swift-windows-32) |
| **L3-unifier** | Cross-platform unification. Provides unified API across platforms; composes L3-policy packages downward per [PLAT-ARCH-008e]. May internally layer (some unifiers compose other unifiers as a base). | swift-kernel (kernel-level base unifier), swift-strings, swift-paths, swift-ascii (cross-platform ASCII spec facade), swift-systems (cross-platform system info — composes per-platform L3-policy directly per the [PLAT-ARCH-008e] pattern), swift-io (IO event scheduling on top of swift-kernel), swift-threads (thread synchronization on top of swift-kernel), swift-environment (env access on top of swift-kernel) |
| **L3-domain** | Domain-specific composition. Composes L3-unifier downward; SHOULD NOT compose L3-policy directly (must go through unifier). | swift-file-system + future domain packages |

**Composition matrix** (FROM source-tier × TO target-tier):

|                           | → L3-unifier | → L3-policy | → L3-domain |
|---------------------------|:------------:|:-----------:|:-----------:|
| **FROM L3-unifier**       | ✓ peer composition allowed (internal L3-unifier-feature layering — e.g., swift-io builds on swift-kernel) | ✓ codified [PLAT-ARCH-008e] | ✗ forbidden (unifiers don't depend on domain) |
| **FROM L3-policy**        | ✗ forbidden (UPWARD composition) | ~ POSIX-shared base only ([PLAT-ARCH-008i]) | ✗ forbidden (policy doesn't depend on domain) |
| **FROM L3-domain**        | ✓ canonical (the "use the unified API" pattern — L3-domain MUST compose L3-unifier, not L3-policy) | ✗ forbidden (must go through unifier) | (peer composition: no current observed instance; if it surfaces, evaluate per-cluster) |

**Decision test**:

For each `import X` from L3-package `P` targeting L3-package `Q`:

1. Classify `P` by sub-tier (L3-policy / L3-unifier / L3-domain).
2. Classify `Q` by sub-tier.
3. Check the matrix cell `(P-tier → Q-tier)`. Permitted, ~ conditional, or ✗ forbidden.

If a domain package needs platform-specific policy, the missing capability belongs in the unifier — extend the unifier rather than reach past it.

**Rationale**: [ARCH-LAYER-001] permits essential acyclic same-layer composition; the sub-tier matrix specializes that permission for the platform stack and makes the allowed L3 directions SPM-enforceable via the dependency DAG. Full text (architectural background, provenance): rationale archive §[PLAT-ARCH-008h].

**Lint enforcement**: Workflow `validate-layer-deps.yml` flags (a) L3-policy packages depending on L3-unifier/L3-domain (upward), (b) L3-domain packages depending on L3-policy directly. The [PLAT-ARCH-008i] permission is enforced at `validate-platform-architecture.py`. [VERIFICATION: WF validate-layer-deps.py (PLAT-ARCH-008h)]

**Cross-references**: [PLAT-ARCH-001], [PLAT-ARCH-008e], [PLAT-ARCH-008i], [ARCH-LAYER-001]

---

### [PLAT-ARCH-008i] L3-policy Peer Composition for POSIX-shared Base

**Statement**: swift-posix is the POSIX-shared L3-policy base. swift-darwin and swift-linux MAY compose swift-posix as their POSIX-subset policy provider; this is the only sanctioned L3-policy peer composition pattern. swift-windows is non-POSIX and MUST NOT compose swift-posix. Other L3-policy peer compositions (e.g., swift-darwin composing swift-linux directly) remain FORBIDDEN.

**Permitted**:

```swift
// In swift-darwin — Darwin extends its POSIX subset by composing swift-posix's POSIX policy.
import POSIX_Kernel_File
```

**Forbidden**:

```swift
// In swift-windows
import POSIX_Kernel  // ❌ Windows is non-POSIX; MUST NOT compose swift-posix

// In swift-darwin
import Linux_Kernel  // ❌ Darwin and Linux are platform peers; no peer-extension relationship
```

This is the only [PLAT-ARCH-008h] "L3-policy → L3-policy" cell that is permitted. Any other L3-policy peer composition requires either:
1. Codifying it as an additional `[PLAT-ARCH-008i*]` rule (with explicit peer-extension justification), or
2. Restructuring to eliminate the lateral.

**Decision test**: For an L3-policy package `P` proposing to compose another L3-policy package `Q`:

| Question | If yes | If no |
|----------|--------|-------|
| Is `Q` a spec-shared base that `P`'s platform extends? | Permitted under [PLAT-ARCH-008i] (cite the spec relationship) | Forbidden — restructure or seek principal review for a new rule |

Today: only `(P=swift-darwin, Q=swift-posix)` and `(P=swift-linux, Q=swift-posix)` satisfy the test. swift-windows fails (non-POSIX). swift-darwin → swift-linux fails (no peer-extension relationship).

**Rationale**: Without this permission, swift-darwin/swift-linux would either duplicate POSIX policy or reach past swift-posix to L2 and re-apply policy — both bad. Full text (architectural background, provenance): rationale archive §[PLAT-ARCH-008i].

**Lint enforcement**: Workflow `validate-platform-architecture.yml` applies the permission matrix to L3-policy Package.swift deps (only darwin→posix and linux→posix permitted). [VERIFICATION: WF validate-platform-architecture.py (PLAT-ARCH-008i)]

**Cross-references**: [PLAT-ARCH-008e], [PLAT-ARCH-008h], [PLAT-ARCH-007]

---

### [PLAT-ARCH-008j] Platform-C Import Authority

**Statement**: L2 spec packages are the EXCLUSIVE home for `import Darwin` / `import Glibc` / `import Musl` / `import WinSDK` (and equivalent platform C imports) within the platform stack. L3-policy / L3-unifier / L3-domain packages MUST NOT import platform C — they compose via L2's typed API exclusively. Within L2, raw libc/WinSDK calls live at `private` / `fileprivate` / `internal` scope; L2's public API exposes typed wrappers only ([PLAT-ARCH-005a]).

**The four L2 spec packages** are the unique platform-C-import home:

| L2 spec package | Imports | Owns spec encoding for |
|-----------------|---------|------------------------|
| `swift-iso-9945` | `Glibc` / `Musl` / `Darwin` (POSIX subset) | IEEE 1003.1 (POSIX) — shared by Darwin + Linux |
| `swift-darwin-standard` | `Darwin` | Darwin/XNU kernel API (kqueue, mach, etc.) |
| `swift-linux-standard` | `Glibc` / `Musl` | Linux kernel API (epoll, io_uring, eventfd, etc.) |
| `swift-windows-32` | `WinSDK` | Win32 API (IOCP, WinSock, GetConsoleMode, etc.) |

**Decision procedure**:

| Question | Action |
|----------|--------|
| Does this package belong to the L2 spec tier (one of the four above)? | YES → may `import` platform C; raw types MUST stay at private/internal scope; public API typed-only per [PLAT-ARCH-005a] |
| Does this package belong to L3-policy / L3-unifier / L3-domain? | NO platform C imports under any circumstance; compose via the appropriate L2 spec package's typed API |
| Is the package outside the platform stack (consumer / domain / application layer)? | NO platform C imports per [PLAT-ARCH-008a] — must use `import Kernel` or equivalent |

**L3-policy composition shape** (no `import Glibc` / `import Darwin`):

```swift
// swift-posix L3-policy
import ISO_9945_Core   // L2 typed API only

extension POSIX.Kernel.File {
    public static func read(...) throws(POSIX.Kernel.Read.Error) -> ... {
        while true {
            do throws(ISO_9945.Kernel.Read.Error) {
                return try ISO_9945.Kernel.File.read(...)
            } catch where error.isInterrupted {
                continue   // EINTR retry — typed-error-driven
            } catch {
                throw POSIX.Kernel.Read.Error(error)   // typed normalization
            }
        }
    }
}
```

**L2 self-deinit libc-inline (structural exception)**: L2 `~Copyable` type deinits MAY inline platform C imports directly (libc `close`, WinSDK `CloseHandle`, libc `closesocket`, libc `closedir`, `pthread_*_destroy`, `munmap`, etc.) when the type is the canonical owner of the underlying kernel resource. This is structurally forced — deinit cannot consume self to delegate to a typed close form that itself takes `consuming Descriptor` (would re-trigger deinit). The libc-inline pattern is permitted at L2 internal scope under this rule's import-authority grant. (Production instances: rationale archive §[PLAT-ARCH-008j].)

**Rationale**: L2's role is spec encoding, including spec-mandated raw FFI; L3's role is composition + policy on the typed surface — the rule is mechanical: L2 yes, everything else no. Full text (experiment, migration-debt counts, provenance): rationale archive §[PLAT-ARCH-008j].

**Lint enforcement**: Workflow `validate-platform-architecture.yml` greps every package's `Sources/` for platform-C imports and flags any package not on the four-package L2 allowlist. Fixture detail: rationale archive §[PLAT-ARCH-008j]. [VERIFICATION: WF validate-platform-architecture.py (PLAT-ARCH-008j)]

**Cross-references**: [PLAT-ARCH-005a], [PLAT-ARCH-008], [PLAT-ARCH-008a], [PLAT-ARCH-008e], [PLAT-ARCH-008h], [PLAT-ARCH-008k], [PLAT-ARCH-019]

---

### [PLAT-ARCH-008k] Spec/Policy Namespace Split

**Statement**: L2 spec packages and L3-policy packages MUST own GENUINELY DISTINCT namespaces — distinct nominal types in the Swift type system, not typealiases of each other. The shape is asymmetric per platform's natural authority structure: POSIX-side uses twin top-level roots (ISO_9945 = formal spec authority; POSIX = policy/colloquial name); Windows-side uses sub-namespace under the platform root (`Windows.\`32\`` = spec-encoding; `Windows` = policy/consumer-facing). Cross-platform consumer ergonomics are preserved via L3-unifier (`swift-kernel`) per-platform typealiases per [PLAT-ARCH-005].

**Canonical mapping**:

| Spec namespace (L2) | Hosted by | Policy namespace (L3-policy) | Hosted by |
|---------------------|-----------|------------------------------|-----------|
| `ISO_9945.Kernel.X` (top-level twin) | `swift-iso-9945` | `POSIX.Kernel.X` (top-level twin) | `swift-posix` |
| `` Windows.`32`.Kernel.X `` (sub-namespace) | `swift-windows-32` | `Windows.Kernel.X` (top-level) | `swift-windows` |
| `Linux.Kernel.X` (Linux-specific spec; distinct nominal type) | `swift-linux-standard` | `Linux.Kernel.X` extensions composing POSIX policy via [PLAT-ARCH-008i] | `swift-linux` |
| `Darwin.Kernel.X` (Darwin-specific spec; distinct nominal type) | `swift-darwin-standard` | `Darwin.Kernel.X` extensions composing POSIX policy via [PLAT-ARCH-008i] | `swift-darwin` |

The spec namespace and policy namespace MUST be distinct types — no `public typealias POSIX = ISO_9945` or equivalent collapse on the Windows side. Each names a distinct level in the spec/policy split.

**Per-platform spec ownership** (Linux + Darwin, post-Wave-3): `Linux.Kernel` and `Darwin.Kernel` are each their own `public enum` in their L2 spec package — NOT typealiases to `ISO_9945.Kernel`. Linux-specific spec encoding (epoll, io_uring, eBPF, etc.) lives under `Linux.Kernel.X`; Darwin-specific spec encoding (kqueue, mach, etc.) lives under `Darwin.Kernel.X`. POSIX-shared spec content remains under `ISO_9945.Kernel.X` and is consumed by Linux/Darwin via re-export or via L3-policy composition per [PLAT-ARCH-008i] — NOT via namespace identity. (Pre-Wave-3 typealias migration debt: rationale archive §[PLAT-ARCH-008k].)

**Cross-platform name unification** lives at L3-unifier (`swift-kernel`):

```swift
// swift-foundations/swift-kernel L3-unifier (Sources/Kernel/Exports.swift)
#if canImport(Darwin) || canImport(Glibc) || canImport(Musl)
public typealias Kernel = POSIX.Kernel        // L3-policy on POSIX
#elseif os(Windows)
public typealias Kernel = Windows.Kernel      // L3-policy on Windows
#endif
```

Cross-platform consumer code writes `Kernel.X` and gets the policy-wrapped form per platform. To reach the L2 spec-literal form, consumers write `ISO_9945.Kernel.X` (POSIX) or `` Windows.`32`.Kernel.X `` (Windows) explicitly.

**Declaration shape** (Windows-side `` `32` `` sub-namespace):

```swift
// swift-windows-32 L2
extension Windows {
    public enum `32` {}                       // Win32 spec sub-namespace
}
extension Windows.`32`.Kernel.Close {
    public static func close(_ handle: Windows.Kernel.Descriptor) throws(Windows.`32`.Kernel.Close.Error) {
        // L2 spec form — calls into private WinSDK helper per [PLAT-ARCH-008j]
    }
}

// swift-windows L3-policy
extension Windows.Kernel.Close {
    public static func close(_ handle: Windows.Kernel.Descriptor) throws(Windows.Kernel.Close.Error) {
        // L3 policy form — composes via Windows.`32`.Kernel.Close.close + retry/normalization
    }
}
```

`Windows.\`32\`.Kernel` and `Windows.Kernel` are distinct nominal types — same `Windows` parent root but different sub-types. Same-signature methods coexist cleanly.

**Multi-spec extensibility (first-principles, per platform)**: Each platform's namespace structure reflects its actual authority hierarchy, NOT artificial symmetry with other platforms. The shape a future second-spec L2 package takes is governed by the spec's own authority/organization: Microsoft's "single owner, multiple hierarchical specs" maps to sub-namespacing under `Windows` (sibling L2 packages `swift-windows-nt`, `swift-winrt`, etc.); POSIX's "shared spec consumed by multiple platforms with platform-specific extensions" maps to `ISO_9945` + per-platform L2 packages with their own roots; Linux's and Darwin's future second-specs are case-by-case per the spec's authority. (Per-platform detail: rationale archive §[PLAT-ARCH-008k].)

**Rationale**: Distinct nominal types are architecturally robust against L2/L3 method-name collision in the typed-everywhere world; the asymmetric naming reflects the actual platform-authority structure. Full text (why-`32`-not-Win32, why-distinct-types, migration scope, experiments, provenance): rationale archive §[PLAT-ARCH-008k].

**Cross-references**: [PLAT-ARCH-005], [PLAT-ARCH-008e], [PLAT-ARCH-008f], [PLAT-ARCH-008i], [PLAT-ARCH-008j], [PLAT-ARCH-018], [API-NAME-001], [API-NAME-003]

---

### [PLAT-ARCH-008l] Deinit-Context Composition

**Statement**: L2 syscall APIs called FROM other types' deinit contexts (e.g., `ISO_9945.Kernel.Lock.Token.deinit` calling `Lock.unlock`) MUST use the typed throwing form via the `try?` pattern, NOT raw `(_:Int32)` / `(_:UInt)` companion forms via `_rawValue` extraction. The ecosystem (swift-memory, swift-io, swift-linux-standard, swift-kernel DocC examples) has converged on this pattern; raw companion forms are not L2 public API surface and MUST be downgraded to `internal`/`package` where typed forms exist.

**L3-policy compat-wrapper deletion clause**: L3-policy compat wrappers extending L2 namespaces (e.g., `extension ISO_9945.Kernel.Lock` declared in swift-posix) that exist solely to preserve a transitional call shape MUST be deleted once the L2 canonical typed form exists with the same signature. Same-signature parallel declarations across L2 and L3-policy create recursion hazards under overload resolution (a body calling the same-namespace same-signature method may resolve to the local-module declaration → infinite recursion) and architectural ambiguity about which tier owns the API. The L2 canonical wins; L3-policy provides typealiases (per [PLAT-ARCH-005] revised), not parallel declarations.

**Composition with [PLAT-ARCH-008j]**:

| Pattern | Site | Mechanism |
|---------|------|-----------|
| L2 type's OWN deinit (Descriptor.deinit, Socket.Descriptor.deinit, Mutex.deinit, etc.) | The type itself owns the kernel resource | Inlines libc/WinSDK directly per [PLAT-ARCH-008j] (structurally forced — deinit cannot consume self into typed close) |
| OTHER L2 type's deinit holding a typed wrapper (Lock.Token.deinit holding a Descriptor) | Wrapper-holding type — wrapper has its own deinit | `try?` over the typed throwing form per this rule (`try? Lock.unlock(descriptor, range:)`) |

**Worked example**:

```swift
// L2 syscall family with typed + raw forms:
extension ISO_9945.Kernel.Lock {
    // Public typed form (L2 canonical):
    public static func unlock(
        _ descriptor: borrowing ISO_9945.Kernel.Descriptor,
        range: ISO_9945.Kernel.Lock.Range
    ) throws(ISO_9945.Kernel.Lock.Error) { /* ... */ }

    // Internal raw companion (downgraded from @_spi(Syscall) public):
    internal static func unlock(
        fd: Int32,
        range: ISO_9945.Kernel.Lock.Range
    ) throws(ISO_9945.Kernel.Lock.Error) { /* libc fcntl */ }
}

// L2 wrapper-holding type's deinit calls typed form via try?:
extension ISO_9945.Kernel.Lock.Token {
    deinit {
        guard !isReleased else { return }
        try? ISO_9945.Kernel.Lock.unlock(descriptor, range: range)
        // descriptor's own deinit then closes the fd via libc (per [PLAT-ARCH-008j]).
    }
}
```

**Rationale**: `try?` at the call site is idiomatic, ecosystem-consistent, and preserves the typed throwing form as the single canonical entry point — non-throwing twins would double the L2 surface, and raw-companion call sites reintroduce raw integers at boundaries the typed-everywhere directive eliminates. Full text (options analysis, escalation history, provenance): rationale archive §[PLAT-ARCH-008l].


**Cross-references**: [PLAT-ARCH-008j] (libc-inline at L2 self-deinit), [PLAT-ARCH-005a] (no platform C in public API), [PLAT-ARCH-005] (descriptor type tiered placement; L3-policy as typealias)

---

### [PLAT-ARCH-020] L3-Unifier Shadow Pre-Flight Check

**Statement**: Before adding or modifying a typed form at L2 path `Kernel.X.Y` (e.g., adding new typed overloads, removing `@_disfavoredOverload`, restructuring overload signatures), the writer MUST grep `swift-foundations/swift-kernel/Sources/` (and other L3-unifier sources) for parallel extension files (`Kernel.X.Y+CrossPlatform.*.swift` or any `extension Kernel.X.Y { ... }`). If found, the L2 typed form MUST carry `@_disfavoredOverload` to defer overload resolution to the L3-unifier; the L3-unifier wins the unified surface, and L2 access remains reachable via the explicit spec-namespace path (`ISO_9945.Kernel.X.Y` on POSIX or `` Windows.`32`.Kernel.X.Y `` on Windows).

The rule predates the [PLAT-ARCH-019] supersession; the shadow concern persists for typed-only L2 surfaces — when L2 and L3-unifier each declare a typed overload at the same path, ambiguity surfaces at consumer sites with or without raw companions.

**The shadow-detection grep**:

```bash
# At the L2 typed-form's namespace path Kernel.X.Y:
find /Users/coen/Developer/swift-foundations/swift-kernel/Sources -name "Kernel.X.Y*.swift"
grep -rn "extension Kernel\.X\.Y" /Users/coen/Developer/swift-foundations/swift-kernel/Sources

# Also check sibling L3-unifier packages:
grep -rn "extension Kernel\.X\.Y" /Users/coen/Developer/swift-foundations/{swift-strings,swift-paths,swift-systems,swift-io,swift-threads}/Sources
```

If any grep returns a match, the L2 typed form is L3-unifier-shadowed. Without `@_disfavoredOverload` on the L2 typed forms, both layers' typed overloads become equally-ranked candidates → ambiguity errors at every site importing `Kernel`.

**Canonical patterns are precondition-bound**: reading a canonical shape from prior code as a rule-without-preconditions is a recurring failure mode. When applying canonical shapes to a new file, the writer MUST check the precondition (for the no-`@_disfavoredOverload` shape: *no other layer declares a typed overload at the same namespace path*).

**Concrete preconditions for L2 typed-form additions**:

| Check | Question | If true |
|-------|----------|---------|
| L3-unifier shadow | Does `swift-foundations/swift-kernel/Sources/.../Kernel.X.Y+CrossPlatform.*.swift` declare a typed overload at the same name? | L2 typed form needs `@_disfavoredOverload` |
| L3-policy delegate | Does `swift-{platform}/Sources/.../Kernel.X.Y.swift` declare an extension at the same path that may shadow? | L2 typed form needs `@_disfavoredOverload` |
| L2 sibling-platform | Do other L2 packages (darwin-standard, linux-standard, windows-standard) declare extensions at the same path? | Resolve via [PLAT-ARCH-008f] solution-family rules |

Where any check returns true, the L2 typed form needs disambiguation. Where all checks return false, the canonical shape applies directly.

**Rationale**: L3-unifier and L2 are parallel authors at the same namespace path; the pre-flight grep is the mechanical check that closes the gap. Full text (IO.Read/IO.Write origin incident, fixup commit, provenance): rationale archive §[PLAT-ARCH-020].

**Cross-references**: [PLAT-ARCH-008e], [PLAT-ARCH-008f], [PLAT-ARCH-018], [PLAT-ARCH-019]

---

### [PLAT-ARCH-021] Domain-Specific Cross-Platform Unification Lives in Domain L3 Packages

**Statement**: L3 domain-specific cross-platform unification — and the domain-specific spec dependencies that come with it (IETF RFCs, ISO standards, vendor SDKs, domain-specific value types) — MUST live in the domain L3 package (`swift-sockets`, `swift-io`, `swift-file-system`, future `swift-time`, `swift-cpu`, etc.), NOT in `swift-kernel`. `swift-kernel` hosts only kernel-level primitives and stays domain-neutral.

**Decision test**:

| Surface | Belongs in `swift-kernel`? | Belongs in domain L3? |
|---------|---------------------------|----------------------|
| Cross-platform `Kernel.Descriptor` typealias | Yes — kernel-level primitive | No |
| `Kernel.Socket.Connect` policy unifier | No — but the *POSIX-shared base* is in `swift-posix` per [PLAT-ARCH-008i]; the cross-platform domain unifier with RFC-typed addresses lives in `swift-sockets` | Yes — domain L3 (swift-sockets) |
| `Kernel.IO.Read.read` policy unifier | Yes — kernel-level operation; no domain-specific spec deps | No (until a domain wraps async IO with HTTP/2 semantics, etc.) |
| File-system retry policy across platforms | No — domain L3 (swift-file-system) holds policy + composes swift-kernel's primitives | Yes — domain L3 (swift-file-system) |

**Composition with [PLAT-ARCH-008e] / [PLAT-ARCH-008h]**:

- [PLAT-ARCH-008e] codifies that `swift-kernel` (kernel L3-unifier) composes the L3-policy tier — kernel domain only.
- [PLAT-ARCH-008h] codifies the within-L3 composition matrix; the L3-domain row's permitted target is L3-unifier.
- [PLAT-ARCH-021] (this rule) clarifies that the *kernel* L3-unifier (`swift-kernel`) is one instance of the L3-unifier sub-tier. Other L3-unifiers exist for non-kernel domains (`swift-sockets`, `swift-io`, etc.). Each domain L3-unifier composes the L3-policy tier *for its domain* and adds its own domain-specific spec deps.

**Rationale**: `swift-kernel` as a dumping ground for domain spec deps would become a networking aggregator in name only; moving domain unifiers while the surface is small is cheap, later it compounds. Full text (swift-sockets origin incident, provenance): rationale archive §[PLAT-ARCH-021].

**Cross-references**: [PLAT-ARCH-008d], [PLAT-ARCH-008e], [PLAT-ARCH-008h], [PLAT-ARCH-008i]

---

### [PLAT-ARCH-023] L2 POSIX (iso-9945) Has No Platform-Standard Dependencies

**Statement**: `swift-iso-9945` (L2 POSIX) MUST NOT take a package or target dependency on `swift-linux-standard` or `swift-darwin-standard`, in production code OR in test targets. The dependency direction is one-way: Linux/Darwin standards depend on iso-9945 because POSIX is the shared substrate; the reverse is a layering cycle.

**Why**: Per [PLAT-ARCH-007], `darwin-standard` and `linux-standard` both depend on `iso-9945` because POSIX is what they extend. Inverting this creates a build-breaking dependency cycle and destroys the layer architecture.

**Test targets are not exempt**: even a `.when(platforms: [.linux])`-guarded test-target product dep from `iso-9945` to `swift-linux-standard` is a cycle.

**When iso-9945 sources or tests reach for a Linux/Darwin-specific symbol** (e.g., `Kernel.File.Open.Options.direct`, `O_DIRECT`, or any other member defined via extension in `Linux_Kernel_File_Standard`), the answer is NEVER to import linux-standard. It is one of:

| Situation | Resolution |
|---|---|
| Test references a Linux-only symbol from iso-9945 | Move the test to swift-linux-standard's own test suite where the symbol is in scope |
| Production code in iso-9945 references a Linux-only symbol | Restructure; the symbol does not belong at L2 POSIX. Move the consumer to L3 (swift-linux) where the platform composition happens. |
| Platform-conditional behavior is genuinely needed | Implement at L3 (swift-kernel unifier or platform-specific L3 packages), not L2 |

**Symmetric rule for darwin-standard**: same prohibition.

**Related L3 invariant**: `swift-posix` (L3 POSIX composition) depends on `swift-iso-9945` but ALSO does not depend on `swift-linux-standard` or `swift-darwin-standard`. `swift-posix` is the platform-neutral L3 composition layer over POSIX; the platform-specific L3 layers are `swift-linux` / `swift-darwin`. Platform-specific integration happens at `swift-kernel` (L3 unified) via conditional re-exports, NOT by `swift-posix` reaching sideways to platform standards.

**Lint enforcement**: Workflow `validate-platform-architecture.yml` flags `swift-linux-standard` / `swift-darwin-standard` dependency declarations in `swift-iso-9945`'s Package.swift. [VERIFICATION: WF validate-platform-architecture.py (PLAT-ARCH-023)]

**Cross-references**: [PLAT-ARCH-007], [PLAT-ARCH-008e], [PLAT-ARCH-008i]

---

### [PLAT-ARCH-024] L2 Platform-Extension Pre-Check Before L3 Placement

**Statement**: Before classifying a cross-platform vocabulary type as L3-placed (in `swift-kernel`, `swift-posix`, `swift-darwin`, `swift-linux`, `swift-windows`, etc.), the writer MUST grep for `extension <Namespace>.<Type>` patterns across the L2 spec packages (`swift-iso-9945`, `swift-darwin-standard`, `swift-linux-standard`, `swift-windows-standard`, `swift-windows-32`). If the grep returns ANY platform L2 extension binding the type, L3 placement is structurally blocked — the type MUST live at L2 (or below; L1 if vocabulary is platform-neutral). L2 cannot upward-import L3.

**Procedure**:

```bash
# Before classifying type Kernel.Event as L3:
grep -rn "extension.*Kernel\.Event" swift-iso-9945/Sources \
  swift-darwin-standard/Sources \
  swift-linux-standard/Sources \
  swift-windows-standard/Sources \
  swift-windows-32/Sources

# If non-empty: L3 placement is structurally blocked.
# If empty: L3 placement is structurally feasible (still verify against
# other criteria like [PLAT-ARCH-008e] composition discipline).
```

**Generalization to non-Kernel namespaces**: the rule is `extension <Namespace>.<Type>` for any namespace. When relocating types under `Memory.*`, `System.*`, `Algebra.*`, etc., apply the same L2 grep pre-check.

**Gotcha — misleading precedent**: reasoning "Cycle X precedent applies" without re-running the L2 pre-check on the candidate type is the canonical failure mode this rule prevents; a type can look syntactically like a previously-relocated one yet have a completely different L2 extension surface.

**Rationale**: L2 platform-extension binding is the load-bearing constraint that determines vertical placement, not the type's content — "is this content cross-platform?" and "where can this type be placed?" have different answers when L2 packages already extend the namespace. Full text (Path X worked-example table, cost asymmetry, provenance): rationale archive §[PLAT-ARCH-024].

**Cross-references**: [PLAT-ARCH-005], [PLAT-ARCH-008e], [PLAT-ARCH-008g], [PLAT-ARCH-015]

---

### [PLAT-ARCH-025] Class A vs Class B Classification by Declaration Site

**Statement**: When applying a taxonomic classifier (e.g., the Wave 3.5-Final-Atomic Class A vs Class B distinction) to determine whether a type needs a platform bridge, the classifier MUST be the type's *declaration site*, not its *usage site*. Cross-platform usage of a type does NOT make the type cross-platform; the declaration site does. Run the empirical "where is this type ACTUALLY declared?" check at pre-flight rather than classifying by intuition or naming pattern.

**Procedure**:

```bash
# Before classifying type X as Class A (cross-platform pure-error/value):
# 1. Find the declaration site
grep -rn "struct X\|enum X\|typealias X\b" {iso-9945,darwin-standard,linux-standard,windows-standard,windows-32}/Sources

# 2. Inspect the result:
#    - Declared at swift-iso-9945 or shared L2: Class A candidate
#    - Declared at platform-specific L2 (darwin-standard, linux-standard,
#      etc.): Class B (needs platform bridge at L3-policy peer, not L3-shared)
```

**Rationale**: Usage-grounded classifications produce false-positive Class A determinations that fail at compile time; declaration-grounded classifications fail (or succeed) on the architectural axis they describe. Full text (Kernel.Thread.ID origin incident, provenance): rationale archive §[PLAT-ARCH-025].

**Cross-references**: [PLAT-ARCH-008e], [PLAT-ARCH-024]

---

### [PLAT-ARCH-028] Typealiased-Namespace Unifier Collapse Forbids swift-kernel Delegate

**Statement**: When a platform L3 package's namespace is typealiased to the primitives Kernel namespace (`Darwin.Kernel = Kernel_Primitives.Kernel`, `Linux.Kernel = Kernel_Primitives.Kernel`, `Windows.Kernel = Kernel_Primitives.Kernel`), an `extension Darwin.Kernel.X { public static func y(_:) }` is *syntactically equivalent to* `extension Kernel.X { public static func y(_:) }`. Adding BOTH a swift-kernel L3 unifier (`extension Kernel.X { public static func y { Darwin.Kernel.X.y(...) } }`) AND a platform-package extension with the same signature is a redeclaration of the same method on the same type — a compile error, not composition. The platform packages own the canonical definition directly; swift-kernel MUST NOT add a unifier delegate at the same name.

**Asymmetry with POSIX**: swift-posix avoids this because `POSIX.Kernel` is declared as its own empty enum (NOT typealiased to `Kernel`). So `POSIX.Kernel.File.Flush.flush(_:)` is genuinely distinct from `Kernel.File.Flush.flush(_:)`; the swift-kernel unifier can explicitly delegate to POSIX per `[PLAT-ARCH-008e]` without redeclaration.

**Decision procedure when placing a cross-platform method on `Kernel.X.y`**:

| L3 policy tier | Composition shape |
|----------------|-------------------|
| swift-posix (shared POSIX policy; method available on every supported POSIX platform via the same syscall) | swift-kernel hosts the unifier via explicit POSIX delegate. Sibling Windows dispatch (if any) sits in a `+CrossPlatform.Windows.swift` file under its own file-level `#if os(Windows)` guard. |
| Platform-specific (differs per platform — `fdatasync` on Linux, `fcntl(F_BARRIERFSYNC)` on Darwin; or one-platform-only) | Platform package owns the unified name directly. NO swift-kernel unifier method. Consumers write `Kernel.X.y(fd)` — Swift resolves per platform automatically through the typealias. |

**Recognize the collapse shape**: if, when sketching the swift-kernel unifier, the body reads `try Darwin.Kernel.X.y(...)` (platform-namespace-qualified call to a method you also plan to define in the platform package), the collision is immediate. Either back off the unifier (preferred) or rename the platform-package method to something distinct from `y`.

**Documentation-in-code**: when omitting a swift-kernel unifier for a platform-specific method, leave a comment block at the site where the unifier would sit explaining why — future audits will grep `Kernel.X.y` and ask "why no unifier here?"; the comment short-circuits re-derivation.

**Contrast with Read/Write**: the Read/Write collision is between two different modules both extending `Kernel.IO.Read` (L2 + L3 unifier), where `@_disfavoredOverload` on the L2 side is the fix ([PLAT-ARCH-020]); the typealiased-namespace collision here is a redeclaration error on the SAME nominal type — a different failure mode demanding a different fix.

**Rationale**: Typealias-collapsed namespaces make the platform package and swift-kernel the same declaration target. Full text (ecosystem landing commits, provenance): rationale archive §[PLAT-ARCH-028].

**Cross-references**: [PLAT-ARCH-008e], [PLAT-ARCH-018], [MOD-027]

---
