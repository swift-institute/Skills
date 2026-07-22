# Platform — Layer Stack & Placement

The four-level platform stack (L1 Primitives → L2 Standards → L3 Foundations), where platform code lives, the shared `Kernel` namespace and platform root namespaces, the re-export chain, consumer import rules, the vocabulary/spec/composition principle, the package reference, and the L2/L3 spec-vs-policy split for the POSIX and Linux stacks.

**Rules in this file**: [PLAT-ARCH-001], [PLAT-ARCH-002], [PLAT-ARCH-003], [PLAT-ARCH-004], [PLAT-ARCH-006], [PLAT-ARCH-007], [PLAT-ARCH-008], [PLAT-ARCH-009], [PLAT-ARCH-010], [PLAT-ARCH-012], [PLAT-ARCH-014], [PLAT-ARCH-030], [PLAT-ARCH-031]

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/platform-skill-rationale.md` (the rationale archive).

---

### [PLAT-ARCH-001] Four-Level Platform Stack

**Statement**: Platform code MUST be organized into exactly four levels, each in a dedicated package. Code MUST be placed at the lowest level where it can correctly live. (Stack diagram: rationale archive §[PLAT-ARCH-001].)

| Level | Package | Layer | Contains |
|-------|---------|-------|----------|
| L1 shared | *(L1 vocabulary primitives)* | Primitives | Cross-platform file/socket/thread/memory **concepts** (vocabulary only). The shared `Kernel` namespace and `Kernel.Error` are anchored at L3 (`swift-kernel`), not L1; divergent-shape types like `Kernel.Descriptor` live at L2 spec layer when one exists, else L3-policy, with L3-unifier typealias unification per [PLAT-ARCH-005] |
| L1 vocabulary | `swift-cpu-primitives` | Primitives | CPU vocabulary: `CPU.Atomic`, `CPU.Barrier`, `CPU.Spin` |
| L2 spec | `swift-iso-9945` | Standards | POSIX specification (IEEE 1003.1), shared by Darwin and Linux |
| L2 platform | `swift-linux-standard` | Standards | Linux kernel API spec (epoll, io_uring, syscall ABI) |
| L2 platform | `swift-darwin-standard` | Standards | Darwin/XNU kernel API spec (kqueue, mach ports) |
| L2 platform | `swift-windows-32` | Standards | Win32 API spec (IOCP, WinSock) — namespace `Windows.\`32\`` per [PLAT-ARCH-008k] |
| L3 platform | `swift-{darwin,linux,windows}` | Foundations | Platform-specific foundations code (NUMA, entropy, thread affinity) |
| L3 unified | `swift-kernel` | Foundations | Anchors the shared `Kernel` namespace and `Kernel.Error`; cross-platform unification via conditional re-exports |

**Rationale**: This separation ensures platform-specific code never leaks into consumer packages. Every consumer writes `import Kernel` and gets the right platform automatically.

**Cross-references**: [ARCH-LAYER-001], **swift-institute** skill

---

### [PLAT-ARCH-002] Placement Decision Rules

**Statement**: When adding new platform code, it MUST be placed according to these rules:

| The code is... | Place it in... | Example |
|----------------|----------------|---------|
| A raw syscall wrapper used by all platforms | `swift-kernel` (L3 unifier surface) | `Kernel.File.open()`, `Kernel.Socket.create()` |
| A raw syscall wrapper specific to one platform | `swift-{platform}-primitives` | `Kernel.IO.Uring` (Linux), `Kernel.Kqueue` (Darwin) |
| A POSIX syscall shared by Darwin and Linux | `swift-iso-9945` | `POSIX.Kernel.Signal`, `POSIX.Kernel.Process.Fork` |
| A higher-level abstraction over platform primitives | `swift-{platform}` (L3) | `Darwin.System.NUMA`, `Linux.Thread.Affinity` |
| Cross-platform composed behavior | `swift-kernel` (L3) | `Kernel.File.Write.Atomic`, `Kernel.Thread.Executor` |

**Incorrect placement**:
```swift
// ❌ Platform-specific code in swift-kernel (the cross-platform unifier)
#if os(Linux)
extension Kernel.IO { public enum Uring {} }  // Belongs in swift-linux-standard
#endif
```

**Rationale**: Correct placement prevents duplication, keeps platform conditionals out of consumer code, and ensures independent compilability.

---

### [PLAT-ARCH-003] Namespace Extension Pattern

**Statement**: All platform-specific packages MUST extend the shared `Kernel` namespace rather than defining their own root types.

```swift
// swift-kernel (L3) — anchors the shared root
public enum Kernel {}

// swift-linux-standard — extends it
extension Kernel.IO { public enum Uring {} }

// swift-iso-9945 — extends it
extension Kernel { public enum Signal {} }
```

**Incorrect**:
```swift
// ❌ Own root namespace
public enum LinuxKernel {}           // Should extend Kernel

// ❌ Compound names
public enum KqueueEventNotification {}  // Should be Kernel.Kqueue
```

**Rationale**: A single `Kernel` namespace means consumers see one unified API. Platform-specific extensions appear naturally under `Kernel.*` without separate import paths.

**Lint enforcement**: `Lint.Rule.Platform.NamespaceRoot` flags top-level compound platform-prefix declarations (`<Platform>Kernel`, `KqueueEventNotification`, etc.). Scope detail: rationale archive §[PLAT-ARCH-003]. [VERIFICATION: AST Lint.Rule.Platform.NamespaceRoot]

**Cross-references**: [API-NAME-001]

---

### [PLAT-ARCH-004] Platform Root Namespaces

**Statement**: Each platform-specific package MUST also define a platform root namespace for platform-only types that don't fit under `Kernel`.

```swift
// swift-darwin-standard
public enum Darwin: Sendable {}

// swift-linux-standard
public enum Linux: Sendable {}

// swift-windows-32
public enum Windows {}
extension Windows { public enum `32`: Sendable {} }
extension Windows.`32` { public enum Kernel: Sendable {} }

// swift-iso-9945
public enum ISO_9945: Sendable {}
public typealias POSIX = ISO_9945
```

The platform namespace convention follows `Platform.Domain.Concept`:

| Darwin | Linux | Windows |
|--------|-------|---------|
| `Darwin.Kernel.Kqueue` | `Linux.Kernel.IO.Uring` | `Windows.Kernel.IO.Completion.Port` |
| `Darwin.Identity.UUID` | `Linux.Identity.UUID` | `Windows.Identity.UUID` |
| `Darwin.Memory.Allocation` | `Linux.Memory.Allocation` | `Windows.Memory.Allocation` |

**Rationale**: Parallel namespace structure across platforms makes the architecture predictable. Conceptual equivalents occupy the same namespace position.

**Lint enforcement**: Workflow `validate-platform-architecture.yml` checks each platform L2 spec package for its required `public enum <Platform>` root declaration. Detail: rationale archive §[PLAT-ARCH-004]. [VERIFICATION: WF validate-platform-architecture.py (PLAT-ARCH-004)]

**Cross-references**: [API-NAME-001], [API-NAME-003]

---

### [PLAT-ARCH-006] Re-Export Chain Architecture

**Statement**: Each level MUST re-export everything below it using `@_exported public import`, so that consumers only need one import at their chosen abstraction level. (Consumer-view chain diagram: rationale archive §[PLAT-ARCH-006].)

**The unification file** (`swift-kernel/Sources/Kernel/Exports.swift`):

```swift
@_exported public import Kernel_Core

#if canImport(Darwin) || canImport(Glibc) || canImport(Musl)
    @_exported public import POSIX_Kernel
#endif

#if canImport(Darwin)
    @_exported public import Darwin_Kernel
#elseif canImport(Glibc) || canImport(Musl)
    @_exported public import Linux_Kernel
#elseif os(Windows)
    @_exported public import Windows_Kernel
#endif
```

**Platform foundations exports** (e.g., `swift-darwin/Sources/Darwin Kernel/Exports.swift`):

```swift
@_exported public import Darwin_Kernel_Standard
```

**Result**: Platform conditionals exist in exactly two places — the L3 `Exports.swift` files and `Package.swift` dependency conditions. Consumer code is unconditional.

**Rationale**: The re-export chain is what makes `import Kernel` work as a single cross-platform entry point. Without it, consumers would need platform conditionals in every file.

**Lint enforcement**: Workflow `validate-platform-architecture.yml` checks each L3 platform package for at least one `@_exported public import` of its expected L2 spec module prefix. Detail: rationale archive §[PLAT-ARCH-006]. [VERIFICATION: WF validate-platform-architecture.py (PLAT-ARCH-006)]

**Cross-references**: [PATTERN-004], [PATTERN-004a]

---

### [PLAT-ARCH-007] POSIX Code Belongs in ISO 9945

**Statement**: POSIX syscall wrappers shared by Darwin and Linux MUST live in `swift-iso-9945` (Layer 2, Standards), NOT be duplicated in `swift-darwin-standard` and `swift-linux-standard`. (Diagram: rationale archive §[PLAT-ARCH-007].)

Both `swift-darwin-standard` and `swift-linux-standard` depend on `swift-iso-9945`. `swift-windows-32` does NOT — Windows is not POSIX.

**Incorrect**:
```swift
// ❌ In swift-darwin-standard (and duplicated in swift-linux-standard)
extension Kernel.Process {
    public static func fork() -> ... { }  // This is POSIX — belongs in swift-iso-9945
}
```

**Rationale**: ISO 9945 is the IEEE 1003.1 (POSIX) specification. Placing shared POSIX code there follows [API-NAME-003] (specification-mirroring names) and eliminates duplication between Darwin and Linux.

**Lint enforcement**: Workflow `validate-platform-architecture.yml` greps darwin-standard/linux-standard sources for direct calls to a curated POSIX-shared syscall list (Linux-/Darwin-specific syscalls excluded). Detail: rationale archive §[PLAT-ARCH-007]. [VERIFICATION: WF validate-platform-architecture.py (PLAT-ARCH-007)]

**Cross-references**: [API-NAME-003], [ARCH-LAYER-001]

---

### [PLAT-ARCH-008] Consumer Import Rule

**Statement**: Packages above Layer 3 (Components, Applications) MUST import `Kernel`, NOT individual platform modules. Platform conditionals in consumer code are forbidden.

**Correct**:
```swift
// In any L4/L5 consumer package
import Kernel

func read(from descriptor: Kernel.Descriptor) throws(Kernel.Error) -> [UInt8] {
    // Works on Darwin, Linux, and Windows — no conditionals needed
}
```

**Incorrect**:
```swift
// ❌ Platform imports / platform conditionals in consumer code
#if canImport(Darwin)
import Darwin_Kernel_Standard
#elseif canImport(Glibc)
import Linux_Kernel_Standard
#endif
```

**Exception**: L3 foundation packages (`swift-darwin`, `swift-linux`, `swift-windows`, `swift-kernel`) are the designated boundary where platform conditionals live. They exist precisely so that no one else needs them.

**Rationale**: The entire point of the platform stack is that consumers never write `#if os(...)`. If platform conditionals appear in consumer code, it means the L3 abstraction is missing a capability.

**Lint enforcement**: Workflow `validate-layer-deps.yml` flags L2-spec / L3-policy module imports in non-platform-stack packages (registry- or dep-derived membership). Detail: rationale archive §[PLAT-ARCH-008]. [VERIFICATION: WF validate-layer-deps.py (PLAT-ARCH-008)]

---

### [PLAT-ARCH-009] L3 Platform Package Responsibilities

**Statement**: Each L3 platform package (`swift-darwin`, `swift-linux`, `swift-windows`) MUST serve exactly two purposes: (1) re-export its platform primitives for the `swift-kernel` unification, and (2) provide L3-level platform-specific functionality.

| L3 Package | Re-exports | L3 Functionality |
|------------|------------|------------------|
| `swift-darwin` | `Darwin_Kernel_Standard` | `Darwin.System.NUMA`, `Darwin.Random` (arc4random) |
| `swift-linux` | `Linux_Kernel_Standard` | `Linux.System.NUMA`, `Linux.Thread.Affinity`, `Linux.Random` (getrandom) |
| `swift-windows` | `Windows_Kernel_Standard` | `Windows.System.NUMA`, `Windows.Thread.Affinity`, `Windows.Random` |

The L3 unified package `swift-kernel` then:
- Re-exports the correct platform's L3 module via conditionals
- Adds cross-platform composed behavior (`Kernel.File.Write.Atomic`, `Kernel.Thread.Executor`)

**Rationale**: L3 platform packages are the composability layer. They bridge the gap between raw primitives and cross-platform foundations.

---

### [PLAT-ARCH-010] Platform Package Reference

**Statement**: The following packages constitute the complete platform stack. New platform packages MUST NOT be created without explicit architectural discussion.

**L1 — Vocabulary (cross-platform concepts, domain-agnostic):**

| Package | Location | Contains |
|---------|----------|----------|
| *(no L1 kernel package)* | — | The shared `Kernel` namespace, `Kernel.Error`, and file/socket/memory vocabulary are anchored at **L3** `swift-kernel` (see below), not L1. Divergent-shape descriptor / process / directory types live per L3-policy per [PLAT-ARCH-005] |
| `swift-cpu-primitives` | `swift-primitives/swift-cpu-primitives/` | `CPU.Atomic`, `CPU.Barrier`, `CPU.Spin`, `CPU.Timestamp` |

**L2 — Specification Implementations (external specs faithfully encoded):**

| Package | Organization | Location | Spec Authority |
|---------|-------------|----------|---------------|
| `swift-iso-9945` | `swift-iso` | `swift-iso/swift-iso-9945/` | IEEE 1003.1 (POSIX) |
| `swift-linux-standard` | `swift-linux-foundation` | `swift-linux-foundation/swift-linux-standard/` | Linux kernel (kernel.org) |
| `swift-darwin-standard` | `swift-standards` | `swift-standards/swift-darwin-standard/` | Apple (Darwin/XNU) |
| `swift-windows-32` | `swift-microsoft` | `swift-microsoft/swift-windows-32/` | Microsoft (Win32 API) — renamed from `swift-windows-standard` 2026-04-30 to align with `Windows.\`32\`` namespace per [PLAT-ARCH-008k] |
| `swift-x86-standard` | `swift-intel` | `swift-intel/swift-x86-standard/` | Intel SDM / AMD APM |
| `swift-arm-standard` | `swift-arm-ltd` | `swift-arm-ltd/swift-arm-standard/` | ARM Architecture Reference Manual |
| `swift-riscv-standard` | `swift-riscv` | `swift-riscv/swift-riscv-standard/` | RISC-V ISA Specification |

**L3 — Foundations (composition, Swift-native ergonomics):**

| Package | Location | Contains |
|---------|----------|----------|
| `swift-darwin` | `swift-foundations/swift-darwin/` | Darwin L3: re-exports L2 + Darwin-specific composition |
| `swift-linux` | `swift-foundations/swift-linux/` | Linux L3: re-exports L2 + Linux-specific composition |
| `swift-windows` | `swift-foundations/swift-windows/` | Windows L3: re-exports L2 + Windows-specific composition |
| `swift-kernel` | `swift-foundations/swift-kernel/` | Anchors the shared `Kernel` namespace and `Kernel.Error`; unified cross-platform surface — re-exports L3 platform packages |

All paths are relative to the workspace root.

**Namespace anchor packages (L2 pattern, reserved)**: when a single platform host needs multiple sibling L2 spec packages each extending the same platform root (e.g., future `swift-windows-32` + `swift-windows-nt` + `swift-winrt` all extending `Windows`; or future Linux multi-spec extraction `swift-linux-standard` + `swift-linux-bpf` all extending `Linux`), the platform root namespace (`public enum Windows {}`, `public enum Linux {}`, `public enum Darwin {}`) MUST live in a SHARED L2 namespace anchor package — `swift-windows-namespace`, `swift-linux-namespace`, `swift-darwin-namespace`, etc. — that the multi-spec L2 packages all depend on for the root declaration. Without the anchor, each L2 spec package would re-declare `public enum <Platform> {}` and produce duplicate-symbol build errors.

Namespace anchor packages contain ONLY the bare platform root declaration (e.g., `public enum Windows {}`) — no platform-C imports, no syscall wrappers, no spec encoding. Despite being platform-specific by name, they ARE L2 (NOT L1) — the anchor's role is to host the root namespace under which platform-specific L2 specs are encoded, an L2 spec-host concern (see rationale archive §[PLAT-ARCH-010]).

The pattern is RESERVED — currently no namespace anchor packages exist. When the first multi-spec L2 lands per platform, the platform-namespace anchor package is introduced concurrently and the existing single-spec L2 package migrates to depend on it. Pre-multi-spec, the root declaration lives directly in the single L2 package (current state: `Windows` is declared in `swift-windows-32/Sources/Windows 32 Core/Windows.swift`).

**Cross-references**: [PLAT-ARCH-001], [PLAT-ARCH-008c], [PLAT-ARCH-008k]

---

### [PLAT-ARCH-012] Vocabulary / Spec / Composition Principle

**Statement**: The L1/L2/L3 distinction is determined by WHO defined the types:

| Question | Answer | Layer |
|----------|--------|-------|
| Did **we** define these types? | Our abstractions, our naming, our design | **L1 Vocabulary** |
| Did **they** define these types? | External spec, their documentation, their ABI | **L2 Spec Implementation** |
| Do we **compose** both into a Swift-native API? | Ergonomics, async, composed abstractions | **L3 Composition** |

**Examples**:

| Domain | L1 (our concepts) | L2 (their spec) | L3 (our composition) |
|--------|-------------------|------------------|---------------------|
| Time | `swift-time-primitives` (Duration, Instant) | `swift-iso-8601` (ISO 8601 encoding) | `swift-time` (composed API) |
| CPU | `swift-cpu-primitives` (Atomic, Barrier) | `swift-x86-standard` (CPUID, RDTSC) | `swift-cpu` (feature detection, dispatch) |
| Platform | `Kernel` vocabulary — our concepts, anchored at L3 `swift-kernel` (no separate L1 package) | `swift-linux-standard` (io_uring, epoll) | `swift-linux` (event loops, async); `swift-kernel` typealias unifies divergent-shape per-L3-policy types per [PLAT-ARCH-005] |

**Test**: Can you point to an external man page, spec chapter, or SDK document that defines this type's API surface? Yes → L2. No → L1 (if atomic concept) or L3 (if composed).

**Cross-references**: [PLAT-ARCH-001], [PLAT-ARCH-010]

---

### [PLAT-ARCH-014] ISA Standard Packages

**Statement**: CPU instruction set architecture (ISA) packages are L2 — they faithfully encode an external specification. They are NOT L1 hardware primitives.

| Package | Spec Authority | Contains |
|---------|---------------|----------|
| `swift-x86-standard` | Intel SDM / AMD APM | CPUID, RDTSC, RDRAND, MSR access |
| `swift-arm-standard` | ARM Architecture Reference Manual | CNTFRQ, WFE, SEV, DMB, counter/timestamp reads |
| `swift-riscv-standard` | RISC-V ISA Specification | (stub — future ISA features) |

`swift-cpu-primitives` (L1) defines the **cross-arch vocabulary** — `CPU.Atomic`, `CPU.Barrier`, `CPU.Spin`. The ISA standards (L2) faithfully encode **each architecture's specification**. `swift-cpu` (L3, future) would compose both into runtime feature detection and ISA-adaptive dispatch.

**Cross-references**: [PLAT-ARCH-001], [PLAT-ARCH-010], [PLAT-ARCH-012]

---

### [PLAT-ARCH-030] L3 POSIX Layer: Re-Export Raw Syscalls or Layer Policy

**Statement**: The POSIX layer at L3 (`swift-posix`) has exactly two roles: (a) re-export L2 syscalls unchanged, OR (b) layer policy onto them (EINTR retry, partial-write loops, composed operations). L2 (ISO_9945) MUST stay spec-faithful (faithful mirror of POSIX manual pages); L3 makes opinionated choices. Re-export targets at L3 are NOT empty — they reserve the namespace slot for future policy.

**Why**: L2 must mirror the spec faithfully for trust and traceability. The gap between "what the spec says" and "what applications need" is L3's job. Mixing policy into L2 corrupts the spec mirroring; omitting L3 policy forces consumers to re-implement EINTR retry, partial-write loops, etc. across every consumer site.

**How to apply**:
- When adding new POSIX domain coverage at L3, default to re-export.
- Add policy ONLY where the raw L2 interface is a footgun.
- Policy at L3 MUST delegate to L2 — never re-implement the syscall.
- A re-export L3 file is a feature, not boilerplate; it reserves the namespace and signals "policy may land here later."

**Cross-references**: [ARCH-LAYER-003], [PLAT-ARCH-009], [PLAT-ARCH-008e]

---

### [PLAT-ARCH-031] Linux Stack Mirrors POSIX: Standard at L2, Linux at L3

**Statement**: The Linux stack follows the POSIX-stack L2/L3 split:
- `swift-linux-standard` (L2) faithfully encodes the Linux manual pages — io_uring, epoll, signalfd, etc. The Linux manual IS the specification. Located in `swift-linux-foundation` org.
- `swift-linux` (L3) adds policy, ergonomics, and composition on top of L2; provides the user-facing API.

The parallel: `ISO_9945` → `POSIX` is the same pattern as `Linux_Standard` → `LINUX`.

**Why**: L2 stays spec-faithful (mirror the man pages). L3 makes opinionated choices for end-user ergonomics. Feedback loop: end-user usage at L3 inspires how L2 encodes the spec; L2 NEVER adds policy.

**How to apply**:
- When modularizing `swift-linux-standard`, apply the same principles as the ISO 9945 modularization.
- When the `LINUX` namespace conflicts with `Linux_Standard`, `LINUX` belongs to L3 (`swift-linux`), NOT L2.

**Cross-references**: [PLAT-ARCH-030], [ARCH-LAYER-003]

---

