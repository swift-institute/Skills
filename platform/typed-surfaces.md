# Platform — Typed Surfaces & the C-Type Boundary

Keeping raw platform C types out of public API, cross-platform descriptor unification, per-platform typed values, the OptionSet shell + values pattern, `Swift.Error` / `Swift.<Protocol>` qualification for stdlib-shadowing namespaces, typealiased-namespace path conflicts, `@convention(c)` representability, C anonymous-enum constant divergence, thread-owning executor isolation, and platform System/Core exposure.

**Rules in this file**: [PLAT-ARCH-005], [PLAT-ARCH-005a], [PLAT-ARCH-011], [PLAT-ARCH-013], [PLAT-ARCH-015], [PLAT-ARCH-016], [PLAT-ARCH-005b], [PLAT-ARCH-017], [PLAT-ARCH-018], [PLAT-ARCH-019], [PLAT-ARCH-022], [PLAT-ARCH-026], [PLAT-ARCH-027], [PLAT-ARCH-029]

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/platform-skill-rationale.md` (the rationale archive).

---

### [PLAT-ARCH-005] Cross-Platform Descriptor Unification

**Statement**: `Kernel.Descriptor` MUST be the single cross-platform name for the file descriptor / handle type. The canonical Descriptor placement is **tiered** by whether an L2 spec layer exists for the platform, and the cross-platform name unification MUST proceed through a **three-tier typealias chain** (L2 canonical struct → L3-policy typealias → L3-unifier typealias), composing one tier at a time per [PLAT-ARCH-008e]:

- **(a) Where an L2 spec layer exists** (POSIX → `swift-iso-9945`; Win32 → `swift-windows-32`): the per-platform Descriptor is **canonical at L2** (a `~Copyable` struct with platform-native storage + close-on-drop deinit). The L3-policy package (`swift-posix` / `swift-windows`) provides a `public typealias Descriptor = <L2-canonical>`. The L3-unifier (`swift-kernel`) provides a `public typealias Descriptor = <L3-policy>` — composing through L3-policy, NOT skipping to L2 directly. Behavioral equivalence holds because typealiases are transitive; the three-tier chain preserves [PLAT-ARCH-008e]'s composition discipline (L3-unifier composes its peer L3-policy tier; never reaches across into L2). Single source of truth at L2 eliminates the round-trip pattern (L3 wrapper extracts raw Int32 from L3 Descriptor, calls L2 raw form, reconstructs L3 Descriptor) that the typed-everywhere directive ([PLAT-ARCH-005a] revised) is designed to eliminate.

- **(b) Where no L2 spec layer exists** (any platform without a separate spec package): the L3-policy package hosts the canonical Descriptor with platform-native storage. The L3-unifier typealiases to the L3-policy type. (Two-tier chain in this case because L2 is absent; the L3-unifier still composes through its peer L3 tier.)

Neither the L1 vocabulary layer nor the L3-unifier `swift-kernel` defines a `Kernel.Descriptor` type itself in either case; the per-platform descriptor types live at the canonical layer (L2 when a spec layer exists, L3-policy otherwise) with platform-native storage and platform-appropriate `~Copyable` `deinit`-close behavior.

```swift
// (a) Three-tier typealias chain (POSIX) — L2 canonical struct → L3-policy typealias → L3-unifier typealias
//
// Tier 1 — L2 swift-iso-9945: ISO 9945 Core/ISO 9945.Kernel.Descriptor.swift (CANONICAL ~Copyable struct)
extension ISO_9945.Kernel {
    public struct Descriptor: ~Copyable {
        @usableFromInline package var _raw: Int32
        deinit { /* POSIX close-on-drop policy */ }
    }
}

// Tier 2 — L3-policy swift-posix: POSIX Kernel Descriptor/POSIX.Kernel.Descriptor.swift (typealias)
extension POSIX.Kernel {
    public typealias Descriptor = ISO_9945.Kernel.Descriptor   // composes one tier down (L2)
}

// Tier 3 — L3-unifier swift-kernel/Sources/Kernel/Exports.swift (typealias through L3-policy per [PLAT-ARCH-008e])
#if canImport(Darwin) || canImport(Glibc) || canImport(Musl)
    @_exported public import POSIX_Core   // L3-policy re-exports L2 transitively per [PLAT-ARCH-006]
    extension Kernel { public typealias Descriptor = POSIX.Kernel.Descriptor }   // composes one tier down (L3-policy)
#elseif os(Windows)
    @_exported public import Windows_Kernel
    extension Kernel { public typealias Descriptor = Windows.Kernel.Descriptor }  // composes one tier down (L3-policy)
#endif
```

**Incorrect**:
```swift
// ❌ L1 type definition with platform-conditional storage (the eliminated exception)
extension Kernel {
    public struct Descriptor: ~Copyable {
        #if os(Windows)
        public let _rawValue: UInt
        #else
        public let _rawValue: Int32
        #endif
    }
}

// ❌ Parallel ~Copyable struct definitions at L2 AND L3 (duplicate; L3 must be a typealias)
// L2: extension ISO_9945.Kernel { public struct Descriptor: ~Copyable { ... } }
// L3: extension POSIX.Kernel { public struct Descriptor: ~Copyable { ... } }
```

**Gotcha**: each link in the chain composes ONE TIER DOWN — swift-kernel does NOT import or reference iso-9945/windows-32 directly; it imports swift-posix/swift-windows and references their typealiases (satisfies [PLAT-ARCH-008e] and [PLAT-ARCH-008j]).

**Rationale**: The unification point lives at the layer where the type's canonical home actually is; L2-canonical placement eliminates the raw-integer round-trip class of problems wholesale. Full text (residual-case (b) reference pattern, source-compatibility verification, round-trip-elimination mechanism, placement history, provenance): rationale archive §[PLAT-ARCH-005].

**Lint enforcement**: Workflow `validate-platform-architecture.yml` flags any `Descriptor` struct declaration in the L3-unifier (`swift-kernel/Sources/`) — the unifier carries only the unifying typealias, never a Descriptor struct. The three-tier chain itself is not mechanically verified. [VERIFICATION: WF validate-platform-architecture.py (PLAT-ARCH-005)]

**Cross-references**: [PLAT-ARCH-005a], [PLAT-ARCH-006], [PLAT-ARCH-008c], [PLAT-ARCH-008e], [PLAT-ARCH-008h], [PLAT-ARCH-008j], [PLAT-ARCH-015]

---

### [PLAT-ARCH-005a] No Platform C Types in Public API

**Statement**: Public APIs in the platform stack MUST NOT expose C types in parameters, return types, associated types, or generic constraints. All platform C types MUST be wrapped in ecosystem types at L1. This is the general principle; [PLAT-ARCH-005] is the specific instance for descriptors.

**Scope**: `kevent`, `epoll_event`, `OVERLAPPED`, `sockaddr`, `iovec`, `io_uring_sqe`, `io_uring_cqe`, `timespec`, and any other C struct or typedef from system headers.

**Correct** — ecosystem type wraps the C type:
```swift
public static func register(
    _ kq: borrowing Kernel.Descriptor,
    events: [Kernel.Kqueue.Event]        // ✓ Ecosystem type
) throws(Kernel.Kqueue.Error)
```

**Incorrect** — C type leaks through the API:
```swift
// ❌ C type in public API
public static func register(
    _ kq: borrowing Kernel.Descriptor,
    changelist: UnsafeBufferPointer<kevent>   // ❌ Exposes kevent
) throws(Kernel.Kqueue.Error)

// ❌ C type in return position
public func poll() -> [epoll_event]           // ❌ Exposes epoll_event
```

**No SPI exception** (revised 2026-04-30): typed-only at every layer's exposed surface, including `@_spi`. Raw platform C types (`Int32` for fd, `UInt`/`HANDLE` for handles, `pid_t`, `kevent`, `OVERLAPPED`, etc.) appear ONLY at `private` / `fileprivate` / `internal` scope inside L2 spec packages, where they call into Glibc/Musl/Darwin/WinSDK directly without exposing the raw shape. The previous `@_spi(Syscall)` exception clause is REMOVED. See [PLAT-ARCH-008j] for the L2-only-libc-import rule and the migration path for existing `@_spi(Syscall)` raw companion sites.

**Decision test**: Can a consumer of this API write their code without importing the platform's C module? If no, a C type is leaking.

**Rationale**: C types in public APIs force consumers to understand platform-specific representations, defeating the purpose of the typed wrapper layer. Full text (SPI-exception history, experiment, provenance): rationale archive §[PLAT-ARCH-005a].

**Lint enforcement**: `Lint.Rule.Platform.CTypeInPublicAPI` flags curated C-type identifiers in `public`/`open` parameter and return positions. Scope detail: rationale archive §[PLAT-ARCH-005a]. [VERIFICATION: AST Lint.Rule.Platform.CTypeInPublicAPI]

**Cross-references**: [PLAT-ARCH-005], [PLAT-ARCH-003], [PATTERN-001], [PLAT-ARCH-008], [PLAT-ARCH-008j], [PLAT-ARCH-019]

---

### [PLAT-ARCH-011] `Swift.Error` Qualification (Always)

**Statement**: All references to the stdlib `Error` protocol — generic constraints, conformance clauses, type references in `throws(...)` clauses — MUST use the fully-qualified form `Swift.Error`, not bare `Error`. The rule applies in **every** authoring context, not only inside `.Error` namespace blocks.

**Correct**:
```swift
public func parse<E: Swift.Error>(...) throws(E) -> ...
public enum Validation: Swift.Error { ... }
```

**Incorrect**:
```swift
public func parse<E: Error>(...) throws(E) -> ...        // ❌ unqualified
extension Parser.Error {
    public struct Located<E: Error>: Error { ... }       // ❌ resolves to Parser.Error
}
```

**Self-referential conformance trap**: When using protocol typealiases inside generic types, the conformance declaration in the declaring module MUST use the hoisted protocol name directly. `extension Located: Located.Protocol` creates a cycle — the compiler must resolve `Located.Protocol` while computing `Located`'s conformances. Consumer modules CAN use the typealias path.

**Rationale**: Always-qualifying eliminates the per-context judgment call and makes code copyable across contexts without re-evaluation. Full text (scope-broadening history, provenance): rationale archive §[PLAT-ARCH-011].

**Lint enforcement**: SwiftLint custom rule `swift_error_qualification` (regex; warning, gated by `--strict` in `swift-ci.yml`) + AST rule `Lint.Rule.Platform.SwiftQualification` (type-position walk; member-type accesses like `MyDomain.Error` exempt). See [PLAT-ARCH-022]. [VERIFICATION: SwiftLint swift_error_qualification, AST Lint.Rule.Platform.SwiftQualification]

**Cross-references**: [PLAT-ARCH-022], [API-NAME-001], [API-IMPL-009]

---

### [PLAT-ARCH-013] Shell + Values OptionSet Pattern

**Statement**: When a concept is universal (all platforms) but the constants are platform-specific, the type MUST use the shell + values pattern:

1. **L1** defines the empty OptionSet shell (type + rawValue + init)
2. **L2** adds platform-specific static constants via extension

```swift
// L1 vocabulary — the shell (no constants)
extension Kernel.File.Open {
    public struct Options: OptionSet, Sendable {
        public let rawValue: Int32
        public init(rawValue: Int32) { self.rawValue = rawValue }
    }
}

// L2 swift-iso-9945 — POSIX adds its constants (swift-linux-standard adds Linux-only ones the same way)
extension Kernel.File.Open.Options {
    public static let create = Self(rawValue: O_CREAT)
}
```

**When the concept is POSIX-only** (not universal — e.g., AT_* flags, mlockall flags), the type MUST be defined in `swift-iso-9945` directly — not as a shell in the shared cross-platform layer. The shell pattern is only for genuinely cross-platform concepts.

**Naming convention**: OptionSet types use `.Options` suffix, not `.Flags`. `.Flags` is C-speak for mechanism; `.Options` reads as intent per [IMPL-INTENT].

**Rationale**: The shell exists at L1 because the concept is the same everywhere; constants live per layer. Boolean-init ergonomics example + provenance: rationale archive §[PLAT-ARCH-013].

**Lint enforcement**: `Lint.Rule.Platform.OptionSetShell` flags `static let X = Self(rawValue: ...)` platform constants declared inside an `OptionSet`-conforming struct body (constants belong in extensions). [VERIFICATION: AST Lint.Rule.Platform.OptionSetShell]

**Cross-references**: [PLAT-ARCH-005a], [IMPL-002], [IMPL-INTENT]

---

### [PLAT-ARCH-015] Per-L2 Platform-Native Typed Values

**Statement**: When a type's raw representation genuinely differs per platform (thread IDs, process-level identifiers, scheduler tokens), the type MUST be defined per L2 platform package with the native integer width, expressed in Swift stdlib types (`Int32`, `UInt32`, `UInt64`) so the C typedef does not leak across the L2 boundary. A uniform L1 type that normalizes the values (e.g., widening every platform to `UInt64`) MUST NOT be introduced — it is lossy and misrepresents the platform reality.

**Correct** — per-L2 with native int widths:

| L2 package | Type | Underlying C | Swift stdlib | Rationale |
|-----------|------|--------------|--------------|-----------|
| `swift-darwin-standard` | `Darwin.Kernel.Thread.ID` | `mach_port_t` | `UInt32` | Mach kernel port concept |
| `swift-linux-standard` | `Linux.Kernel.Thread.ID` | `pid_t` (tid) | `Int32` | Linux tid namespace |
| `swift-windows-32` | `Windows.\`32\`.Kernel.Thread.ID` | `DWORD` | `UInt32` | Win32 scheduler concept |

```swift
// swift-darwin-standard
extension Darwin.Kernel.Thread {
    public struct ID: Sendable, Hashable {
        public let rawValue: UInt32   // matches mach_port_t 1:1, no typedef leak
        public init(rawValue: UInt32) { self.rawValue = rawValue }
    }
}
```

**Incorrect** — uniform L1 type:
```swift
// ❌ uniform L1 type — forces lossy bit-pattern conversions at each platform
extension Kernel.Thread {
    public struct ID: Sendable { public let rawValue: UInt64 }   // lossy
}
```

**Decision test** — per-L2 native typed value is correct when:

| Condition | Check |
|-----------|-------|
| Raw representation differs per platform (signedness, width, semantics) | Yes → per-L2 |
| The concept has no equivalent on one platform | Per-L2 with `#if os()` exclusion on that package, not L1 stub |
| The same bit pattern means different things per platform (e.g., mach_port_t vs pid_t) | Per-L2 — unification is lying |
| Only the constants vary (universal concept, platform-specific values) | Use [PLAT-ARCH-013] Shell + Values, not per-L2 |

**Contrast with [PLAT-ARCH-013]**: the Shell + Values OptionSet pattern is for universal concepts with platform-specific constants — the L1 shell exists because the *concept* is the same everywhere. [PLAT-ARCH-015] applies when even the concept differs: a Linux tid is not a mach_port_t is not a Win32 DWORD thread ID. No amount of aliasing unifies them without information loss.

**Swift stdlib types over C typedefs**: the raw value MUST use `Int32`/`UInt32`/`UInt64` (stdlib) rather than `pid_t`/`mach_port_t`/`DWORD` (C typedefs imported from platform headers). The stdlib types match the native widths 1:1 and do not require consumers of the L2 module to import the platform's C module to use the type.

**Corollary — cross-platform name unification via L3-typealias, not L1 exception**: When a per-L2 (or per-L3-policy) platform-native typed value benefits from a cross-platform name (consumers want to write `Kernel.Descriptor` / `Kernel.Process.ID` / `Kernel.Directory.Entry` once and have it resolve per platform), the unification SHOULD use an L3-typealias-via-`#if-os` pattern in the L3-unifier package (`swift-kernel`) rather than introducing a uniform L1 type with inner `#if os(...)` storage. The L3 typealias preserves source compatibility for cross-platform consumers without forcing L1 to host a platform-conditional definition. Per [PLAT-ARCH-008c], an L1 exception is no longer admissible; per [PLAT-ARCH-008e], the L3-unifier composes the L3-policy tier where the per-platform types live.

**Decision shape for the corollary** — when both per-L2/L3-policy native shape AND cross-platform name are wanted:

| The cross-platform name is... | Mechanism | Example |
|-------------------------------|-----------|---------|
| Genuinely useful (consumers cross-platform with the type) | Define per L3-policy (or L2) per the main rule; add an L3-unifier `#if-os`-gated typealias per [PLAT-ARCH-005] | `Kernel.Descriptor` resolving to `POSIX.Kernel.Descriptor` / `Windows.Kernel.Descriptor` |
| Not needed (consumers always reach via the platform namespace) | Stop at per-L2/L3-policy; no typealias | `Linux.Kernel.Thread.ID`, no `Kernel.Thread.ID` |
| Forced into uniform storage at L1 (the eliminated anti-pattern) | Forbidden per [PLAT-ARCH-008c] | n/a |

**Rationale**: Platform-native ABI fidelity is stronger than uniform portable types for values that genuinely differ per platform. Full text (transition note, mechanism discussion, provenance): rationale archive §[PLAT-ARCH-015].

**Cross-references**: [PLAT-ARCH-001], [PLAT-ARCH-004], [PLAT-ARCH-005], [PLAT-ARCH-006], [PLAT-ARCH-008c], [PLAT-ARCH-008e], [PLAT-ARCH-008h], [PLAT-ARCH-013]

---

### [PLAT-ARCH-016] `checkIsolated` for Thread-Owning SerialExecutors

**Statement**: Custom `SerialExecutor` types that own a dedicated OS thread AND invoke user code from that thread outside `runSynchronously(on:)` MUST implement both `isIsolatingCurrentContext()` and `checkIsolated()`. This is the designed bridge between "the thread owns this code" and "a Swift Task owns this code" — the Swift concurrency runtime's fallback chain calls these protocol members precisely when the per-Task executor tracking has no entry for the current code (tick callbacks, run-loop invocations, main-thread callbacks).

**When required**:

| Pattern | Required? |
|---------|-----------|
| Executor invokes user closures from its own thread outside `runSynchronously(on:)` (e.g., tick, run-loop hook) | Yes |
| Executor is main-thread anchored and user code can run on the main thread without going through `runSynchronously` | Yes (pattern: `DispatchMainExecutor`) |
| Executor is `TaskExecutor` only (never `SerialExecutor`) | No — TaskExecutor has no isolation assertion path |
| Executor delegates to a base executor for all invocations | No — base's implementation carries |

**Implementation shape** (pthread-backed executor):

```swift
extension Kernel.Thread.Executor.Polling: SerialExecutor {
    public func isIsolatingCurrentContext() -> Bool? {
        threadHandle?.isCurrent
    }

    public func checkIsolated() {
        precondition(
            isIsolatingCurrentContext() == true,
            "Called from thread not owned by Polling executor"
        )
    }
}
```

**Why both members**: `isIsolatingCurrentContext()` is the fast-path predicate; `checkIsolated()` is the backstop called when the predicate returns `nil` — implementing only one leaves `assumeIsolated` with no correct behavior in the fallback case.

**What this is NOT**: `nonisolated(unsafe)` is not the answer for cross-thread actor-state visibility in a thread-owning executor.

**Rationale**: Custom executors that own threads and invoke user code outside `runSynchronously(on:)` need a way to self-certify when code runs on their thread; the protocol extension point exists for exactly this. Full text (runtime fallback-chain reference, DispatchMainExecutor prior art, provenance): rationale archive §[PLAT-ARCH-016].

**Lint enforcement**: SwiftLint custom rule `no_thread_ismainthread_in_primitives` flags `Thread.isMainThread` in `Sources/` (partial — Thread-Owning subset; the both-members discipline is not mechanically verifiable). [VERIFICATION: SwiftLint no_thread_ismainthread_in_primitives] (partial — Thread-Owning subset)

**Cross-references**: [PLAT-ARCH-001], [MEM-SEND-001]

---

### [PLAT-ARCH-005b] @convention(c) Representability Pre-Check

**Statement**: Before proposing a typed Swift wrapper as a `UnsafeMutablePointer<T>?` parameter in a `@convention(c)` function type, verify the wrapper is `@objc`-representable. Pure Swift structs (including `@safe` / layout-compatible wrappers over imported C structs) are NOT `@objc`-representable and cannot appear in `@convention(c)` signatures, even when the wrapper's layout is identical to the underlying C type.

**Correct pattern when a typed wrapper is needed for a C-callback parameter**:

1. Keep the callback signature using `OpaquePointer?`, `UnsafeMutableRawPointer?`, or the imported-C-struct pointer directly.
2. Expose typed access via a separate helper `init` on the wrapper that consumes the opaque pointer at the callback's first line.

```swift
// Correct: callback uses C-representable pointer; wrapper binds internally.
let callback: @convention(c) (OpaquePointer?) -> Void = { rawInfo in
    guard let rawInfo = rawInfo else { return }
    let info = Kernel.Signal.Information(unsafelyBitCasting: rawInfo)
    // use info...
}

// Incorrect: @safe wrapper in a @convention(c) parameter position.
let callback: @convention(c) (UnsafeMutablePointer<Kernel.Signal.Information>?) -> Void = { ... }
// Compiler rejects: type is not @objc-representable.
```

**Why `@convention(c, cType: "...")` does not help**: The `cType:` variant is Clang-importer-generated; it does not override the `@objc`-representability check for user-written types. The rule is Clang-importer-internal, not a type-system property the user can opt into.

**Authoritative reference**: `swift/test/ClangImporter/clang-function-types.swift`.

**Rationale**: Layout compatibility is necessary but not sufficient — the compiler's ABI check requires `@objc`-representability, unavailable to user-written structs. Full text: rationale archive §[PLAT-ARCH-005b].

**Lint enforcement**: `Lint.Rule.Platform.ConventionCRepresentability` flags qualified-path `Unsafe(Mutable)Pointer<X>` parameters inside `@convention(c)` function types (primitive C types and opaque/raw pointers not flagged). [VERIFICATION: AST Lint.Rule.Platform.ConventionCRepresentability]

**Cross-references**: [PLAT-ARCH-005], [PLAT-ARCH-005a]

---

### [PLAT-ARCH-017] Cross-Platform C Anonymous-Enum Constant Type Divergence

**Statement**: POSIX `si_code` subgroups (`FPE_*`, `ILL_*`, `SEGV_*`, `BUS_*`, `CLD_*`, `SI_*`) and other C anonymous-enum constant groups import as `Int` on glibc (Linux) but `Int32` on Darwin. When matching these constants in a `switch` over an `Int32`-typed value, an explicit `Int32(...)` wrap is REQUIRED on Linux case labels.

**Pattern**:

```swift
switch info.si_code {
case Int32(FPE_INTDIV): ...   // works on both Darwin (already Int32) and Linux (wrapped)
case Int32(FPE_INTOVF): ...
// Without Int32(...) wrap: Linux produces type-mismatch error.
}
```

**Scope**: Applies to any C anonymous-enum constant group imported via the Clang importer that is part of a POSIX spec. Does NOT apply to Swift-defined enums.

**Rationale**: The Clang importer assigns `Int` to glibc's untyped anonymous-enum constants but infers `Int32` from Darwin's typed definitions; wrapping consistently is a no-op on Darwin and a correctness fix on Linux. Full text: rationale archive §[PLAT-ARCH-017].

**Cross-references**: [PLAT-ARCH-005a], [PLAT-ARCH-010]

---

### [PLAT-ARCH-018] Typealiased Namespace-Path Conflict Rule

**Statement**: When a namespace path `A.X.Y` resolves through a typealias `A.X = ForeignModule.X`, declaring `extension A.X.Z` from package A adds the type `Z` to ForeignModule's namespace at the path `ForeignModule.X.Z`, not to package A's own namespace. New-type declarations at `A.X.Z` SILENTLY CONFLICT with any existing `ForeignModule.X.Z` at the same logical path. Before declaring a new nested type via a typealiased namespace path, the writer MUST grep the foreign module for existing declarations at the same path.

**The conflict mode**:

```swift
// Package A — iso-9945
extension ISO_9945 {
    public typealias Kernel = Kernel_Primitives_Core.Kernel   // typealias chain to L1 Kernel
}

// Author intent: declare ISO_9945.Kernel.Descriptor in package A
extension ISO_9945.Kernel {
    public struct Descriptor: ~Copyable, Sendable { ... }
}

// Compiler resolves: extension Kernel_Primitives_Core.Kernel { public struct Descriptor }
// → Conflicts with existing L1 Kernel.Descriptor IF one exists at that path.
```

The source-level path *looks like* it's authoring package-A-resident code; the compiler sees an addition to the foreign module — the conflict surfaces only at resolution time.

**Procedure (writer-side)**:

1. Before declaring a new type at namespace path `A.X.Z` where `A.X` is a typealias:
2. Resolve the typealias chain — `A.X = ForeignModule.X` (one or more steps).
3. Grep the foreign module for existing declarations at `ForeignModule.X.Z`.
4. If a declaration exists, the new declaration would silently conflict. Choose one of:
   - Different sub-path (e.g., `A.X.SubNamespace.Z` if a non-conflicting sub-namespace is appropriate).
   - Different namespace entry-point (declare under a non-typealiased namespace, e.g., directly under `A`).
   - Resolve the foreign declaration first (relocate or delete it before declaring the new type).

**Procedure (reviewer-side)**: When reviewing a PR that declares a new type at a typealiased namespace path, mechanically resolve the typealias chain to the foreign module and grep for collisions. Source-level review alone does not catch the conflict mode.

**Method-wrapping exception**: L3-policy method-wrapping cannot extend a typealiased parent's sub-namespaces. When an L3-policy type is a typealias to its L2 canonical (e.g., `POSIX.Kernel.Descriptor = ISO_9945.Kernel.Descriptor` per [PLAT-ARCH-005]), Swift resolves `extension POSIX.Kernel.Descriptor { public enum X {} }` through the typealias and attempts to declare `X` on the L2 canonical — colliding at compile time if `X` already exists at L2. **Structural consequence**: sub-namespaces nested under typealiased L3-policy parents (`Descriptor.Duplicate`, `Socket.Descriptor.X`, etc.) MUST NOT be method-wrapped at L3-policy via the Option (ii) "distinct enums + method-wrapping" pattern that Wave 3.5 prescribes for flat-named L3-policy sub-namespaces. Their consumer call shape works transparently via the typealias chain (`Kernel.Descriptor.X.method() → POSIX.Kernel.Descriptor.X.method() → ISO_9945.Kernel.Descriptor.X.method()`) without policy. This is acceptable when the L2 method is not policy-relevant; when it IS policy-relevant, the L2 sub-namespace must be flattened (a separate L2 restructure cycle).

**Pre-flight grep** (per sub-cycle plan stage of L3-policy build-out cycles):

```bash
grep -rn 'public typealias.*= ISO_9945\.Kernel\.' /Users/coen/Developer/swift-foundations/swift-posix/Sources/
```

Each typealiased parent's existing L2 sub-namespaces are out-of-Option-(ii) scope — flag in the plan's empirical-state section so the principal disposition is bounded upfront.

**Rationale**: Typealias chains make namespace ownership context-dependent; codifying the conflict mode and the mechanical grep makes the failure case detectable at write time. Full text (origin incident, relationship discussion, known typealiased parents, provenance): rationale archive §[PLAT-ARCH-018].

**Lint enforcement**: `Lint.Rule.Platform.TypealiasedNamespace` flags namespace-bridging typealiases (`typealias Kernel = <Anything>.Kernel`). [VERIFICATION: AST Lint.Rule.Platform.TypealiasedNamespace]

**Cross-references**: [PLAT-ARCH-005], [PLAT-ARCH-008c], [PLAT-ARCH-008e], [PLAT-ARCH-008l], [API-NAME-001]

---

### [PLAT-ARCH-019] INVERTED Pattern A — Additive Raw-Alongside-Typed at L2 [SUPERSEDED 2026-04-30]

**Statement**: SUPERSEDED 2026-04-30 by [PLAT-ARCH-008j] (Platform-C Import Authority — L2 exclusive) and [PLAT-ARCH-008k] (Spec/Policy Namespace Split). The full historical body lives in git history. See [PLAT-ARCH-008j], [PLAT-ARCH-008k], and the experiment at `swift-institute/Experiments/spi-syscall-phase-out-layering/` for the rationale and replacement pattern.

**Cross-references**: [PLAT-ARCH-008j], [PLAT-ARCH-008k]

---

### [PLAT-ARCH-022] `Swift.<Protocol>` Qualification for Stdlib-Shadowing Namespaces

**Statement**: When stdlib protocols (e.g., `Sequence`, `Collection`, `Error`, potentially `String`) are shadowed by institute namespace types of the same name in scope, references to the stdlib protocol MUST use `Swift.<Protocol>` qualification. This generalizes [PLAT-ARCH-011]'s `Swift.Error` everywhere convention to any stdlib protocol whose name the institute also uses as a namespace.

**Known collisions**:

| Stdlib (qualified `Swift.<X>`) | Institute namespace (`<X>` unqualified) | Where the namespace lives |
|---|---|---|
| `Swift.Error` | per-package `<Module>.Error` enums | every package |
| `Swift.Sequence` | `Sequence` (struct namespace) | `swift-sequence-primitives` |
| `Swift.Collection` | (potential — verify) | tbd |

When the institute namespace is in scope (transitively or directly), the bare name resolves to the institute type, not the stdlib protocol.

**Correct**:
```swift
public func consume(_ bytes: some Swift.Sequence<UInt8>) { ... }
```

**Incorrect**:
```swift
public func consume(_ bytes: some Sequence<UInt8>) { ... }   // ❌ resolves to Sequence namespace if in scope
```

**How to apply**:

1. When authoring code that consumes stdlib protocols (Sequence, Collection, Error, etc.) AND imports institute primitives that may host same-name namespaces, default to `Swift.<X>` qualification on the stdlib reference.
2. Generic constraints, conformances, and type references all use `Swift.<X>` form mechanically — no semantic change.
3. Counter-pattern: when the code is in a target with no transitive dep on the colliding namespace package, bare `Sequence` resolves to stdlib correctly. **Default to qualifying anyway** — the code becomes copyable to other contexts without re-evaluation.

**Why "always", even without observable collision**: collisions can be introduced by transitive deps later. The mechanical-qualification cost is one prefix; the discovery-and-fix cost when a transitive dep introduces the collision is search-and-replace across the consumer.

**Lint enforcement**: `Lint.Rule.Platform.SwiftQualification` walks type-position syntax and flags leaf identifiers in the shadowed set (`Sequence`, `Collection`, `Error`) not Swift-prefixed; member-type accesses exempt. Subsumes the [PLAT-ARCH-011] SwiftLint regex for `Error`. [VERIFICATION: AST Lint.Rule.Platform.SwiftQualification]

**Cross-references**: [PLAT-ARCH-011], [API-NAME-001], [API-NAME-014]

---

### [PLAT-ARCH-026] Platform System Extends `System` Directly, Not as a Subdomain

**Statement**: Platform System targets (`Darwin System`, `Linux System`, `Windows System`) MUST extend the `System` namespace directly from `System_Primitives`, NOT through a `{Platform}.System` namespace enum. `Darwin.System`, `Linux.System`, `Windows.System` namespace enums MUST NOT be created.

**Why**: System is a cross-platform concept (processor count, memory, NUMA topology). Platform-specific discovery (sysctl, /proc/meminfo, WinSDK) is mechanism, not a new domain. Nesting under the platform namespace creates unnecessary indirection and would require Core to be published.

**How to apply**: When adding platform-specific System implementations, extend `System.*` types directly from the platform System target. Composes with `[PLAT-ARCH-027]` (Core internal + variant `@_exported` re-export) — variants flow the namespace without publishing Core.

**Lint enforcement**: `Lint.Rule.Platform.SystemSubdomain` flags `extension <Platform>.System` and nested `enum System { … }` inside a platform namespace (non-System subdomains and file-scope `enum System` not flagged). [VERIFICATION: AST Lint.Rule.Platform.SystemSubdomain]

---

### [PLAT-ARCH-027] Platform Core Internal With `@_exported` Re-Export From Variants

**Statement**: Platform packages (`darwin-primitives`, `linux-primitives`, `windows-primitives`) MUST keep `{Platform} Primitives Core` as an internal target with no published product. Core contains only the namespace enum (e.g., `public enum Darwin {}`). Variant targets (`Kernel`, `Kernel Event`, `Loader`, `Memory`) MUST add `@_exported public import {Platform}_Primitives_Core` in their `Exports.swift` so the namespace flows to consumers.

**Why**: Per `[MOD-001]` Core SHOULD NOT be published. But L3 packages need the namespace. The `@_exported` re-export from variants solves this without publishing Core.

**How to apply**: When a consumer needs the `Darwin` / `Linux` / `Windows` namespace, depend on a published variant product (e.g., `Darwin Kernel Primitives`), not Core directly. Composes with `[PLAT-ARCH-026]` — variants are the discovery surface that carries the namespace.

**Lint enforcement**: Workflow `validate-platform-architecture.yml` verifies each platform-primitives variant target has an `Exports.swift` containing the Core re-export (defensive — no platform-primitives packages exist on disk currently). [VERIFICATION: WF validate-platform-architecture.py (PLAT-ARCH-027)]

---

### [PLAT-ARCH-029] L2 Spec Wrappers Must Model the Domain, Not Wrap Raw C Fields

**Statement**: L2 spec packages (linux-standard, darwin-standard, windows-standard, iso-9945) MUST create wrapper TYPES that model the domain. Thin accessor wrappers that rename raw C fields (`_fd: Int32`, `_rawFlags: UInt32`) are FORBIDDEN. When a C union field has multiple semantic uses, each use gets its own typed domain model — not a renamed raw accessor. L2 surfaces are modern Swift typed encoding without raw C types in public signatures.

**How to apply** when wrapping C union fields:
1. Create new types that combine related flags/options (e.g., `Timeout.Flags` encapsulating clock + absolute + multishot).
2. Extend existing types to cover new semantic cases (e.g., `Target.none` instead of `_fd = -1`).
3. Every accessor accepts/returns a domain type — if no type exists, create one.
4. Raw integer accessors are a last resort, not the first tool.

**Tactical exception**: during Path X execution, raw `@_spi(Syscall)` companions co-exist with typed forms per `[PLAT-ARCH-019]` (INVERTED Pattern A). The strategic destination — typed-only L2 surfaces ecosystem-wide — is reached post-Path-X (queued cleanup cycle); see `project_path_x_windows_pattern.md` for the staging.

**Rationale**: Thin accessors describe mechanism, not domain; the pre-1.0 standard is "L2 spec packages are modern Swift spec wrappers — raw integers should never be visible." Composes with [PLAT-ARCH-013] and [PLAT-ARCH-015] as the L2 typed-modeling standard. Full text: rationale archive §[PLAT-ARCH-029].

**Cross-references**: [PLAT-ARCH-013], [PLAT-ARCH-015], [PLAT-ARCH-019], [API-NAME-003]

---

