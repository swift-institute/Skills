# Platform code

Companion to the `swift` skill. Read this when placing platform code, writing a
conditional, importing platform C, or extending the kernel vocabulary.

## The stack

- **L2 spec packages** encode a kernel's published API exactly as its authority
  documents it — POSIX/IEEE 1003.1, Linux epoll/io_uring, Darwin kqueue/mach,
  Win32/IOCP. ISA specs are L2 too: they encode a vendor manual, not hardware
  primitives. L2 mirrors the spec and adds no policy.
- **L3-policy packages** wrap one L2 sibling and add opinion: EINTR retry,
  partial-IO loops, error normalization. A pure re-export file at L3-policy is a
  feature — it reserves the namespace slot for policy that lands later. Policy
  always delegates to L2 and never re-implements a syscall.
- **L3-unifier packages** provide one cross-platform API, anchored by
  `swift-kernel`.
- **L3-domain packages** compose unifiers only.

Composition directions: unifier → policy and unifier → unifier allowed; domain →
unifier canonical; domain → policy forbidden, go through the unifier; policy →
unifier and policy → domain forbidden, as those are upward.

The single sanctioned policy-to-policy edge is Darwin → POSIX and Linux → POSIX,
because those platforms extend the POSIX subset. Windows is not POSIX. Darwin →
Linux is never permitted. A POSIX spec package must not depend on the Linux or
Darwin spec packages, including from test targets.

Domain-specific cross-platform unification and its spec dependencies belong in
the domain package — the kernel unifier stays domain-neutral.

Creating a new platform package, or a shared platform-namespace anchor when one
platform grows a second L2 spec, needs architectural approval. Sibling L2
packages otherwise re-declare the platform root and produce duplicate symbols.

## Kernel vocabulary

`swift-kernel` anchors `public enum Kernel {}` and `Kernel.Error`. Every platform
package extends that shared namespace rather than declaring a root of its own —
no `LinuxKernel`, no `KqueueEventNotification`. Each L2 platform package
additionally declares its own platform root (`public enum Darwin`, `Linux`,
`` Windows.`32` ``, `ISO_9945` with `typealias POSIX`), following
`Platform.Domain.Concept`.

`Linux.Kernel` and `Darwin.Kernel` are each their own `public enum` in their own
L2 spec package — **not** typealiases to `ISO_9945.Kernel`. POSIX-shared content
stays under `ISO_9945.Kernel.X` and is consumed by re-export or L3-policy
composition, never by namespace identity. L2 spec and L3-policy namespaces are
genuinely distinct nominal types, and the split is asymmetric per platform.

Consumers above L3 write `import Kernel` and nothing else. A platform conditional
in consumer code means the unifier is missing a capability — extend the unifier.
Each level re-exports the level below with `@_exported public import` in its
`Exports.swift`, so `Kernel` is the single entry point.

## Conditionals

`#if os(...)` is confined to L3 `Exports.swift` files and `Package.swift`
dependency conditions. Inside a package that only compiles on one platform, the
package boundary *is* the conditional. L1 primitives are unconditionally
platform-agnostic: no conditional implementations, no conditional storage. When
storage shape differs per platform, define the type per L3-policy — or L2 where a
spec package exists — and unify the name by typealias at the unifier.

An L3 unifier may put `#if os(...)` on a public enum case when the wrapped type
comes from a platform-specific spec and a stub would be dishonest. That is
allowed only when no consumer switches exhaustively, and with at most one
conditional case per enum.

A non-platform package may carry `#if` only when it owns the varying concept,
reaches the platform solely through `import Kernel`, selects a domain strategy
rather than a syscall, and cannot push the variation down without the kernel
absorbing domain semantics. Path separators, kqueue-vs-epoll strategy, and
Windows permission models qualify; syscall dispatch never does.

Placement test — **who defined the types?** They defined it (man page, spec
chapter, SDK doc) → L2. We defined it as vocabulary → L1. We composed it → L3.
Before classifying a cross-platform type as L3-placed, grep the L2 spec packages
for `extension <Namespace>.<Type>`; any hit blocks L3 placement, since L2 cannot
import upward.

Use `#if os()` for platform identity, never `#if canImport()`. `os()` is
evaluated against the target triple and is deterministic; `canImport()` depends
on module resolution. Reserve `canImport` for genuinely optional modules like
`SwiftUI`.

## Platform C and typed surfaces

L2 spec packages are the **exclusive** home for `import Darwin` / `Glibc` /
`Musl` / `WinSDK`. L3-policy, L3-unifier, and L3-domain packages do not import
platform C at all; they compose L2's typed API. Inside L2 the raw libc calls stay
`private` / `fileprivate` / `internal`.

C shims are minimal, isolated C targets under `_Shims/include/`, and every
platform gets its **own** header file even when the C function is identical. A
shared header with `__APPLE__` / `__linux__` branches breaks independent
compilability; the duplication is deliberate.

No platform C type appears in any exposed signature — parameter, return,
associated type, or generic constraint — and there is no `@_spi` exception. The
test: can a consumer write their code without importing the platform's C module?

L2 wrappers model the domain rather than renaming raw fields. A `_fd: Int32` or
`_rawFlags: UInt32` accessor is the shape to avoid; each semantic use of a C
union field gets its own type. Syscalls called from another type's `deinit` use
the typed throwing form via `try?`.

`Kernel.Descriptor` is the single cross-platform name, reached by a chain
composing exactly one tier per link: the canonical `~Copyable` struct with native
storage and close-on-drop `deinit` at L2, a `public typealias` at L3-policy,
another at the L3-unifier. `swift-kernel` never references an L2 spec package
directly and never declares a `Descriptor` of its own.

Types whose raw representation genuinely differs — thread IDs, process IDs,
scheduler tokens — are defined per L2 package at native width in stdlib types.
Never normalize them into one widened L1 type, and never use the C typedef as the
raw value. For a universal concept with platform-specific constants, L1 declares
an empty OptionSet shell (type, `rawValue`, `init`) and each L2 adds its constants
by extension; a POSIX-only concept is defined in the POSIX spec package outright.

Errors are typed at every platform boundary — `throws(<Namespace>.Error)` — with
L3-policy normalizing platform error codes into them. Every reference to a stdlib
protocol the ecosystem also uses as a namespace is written qualified:
`Swift.Error`, `Swift.Sequence`, `Swift.Collection`. A transitive dependency can
introduce the shadowing later, so the qualification is cheap insurance rather
than pedantry.

## Traps

- Kernel shared-memory protocol counters — io_uring head/tail and anything like
  them — stay raw `UInt32` with a typed mask for slot extraction. The fullness
  check `sqEntries &- (tail &- head)` depends on `UInt32` wrapping at 2^32;
  widening to a 64-bit index type breaks the wrap and the check silently stops
  being correct. Collection-index infrastructure is the wrong tool here.
- Declaring a nested type through a typealiased namespace adds it to the
  *foreign* module. With `ISO_9945.Kernel = Kernel_Primitives_Core.Kernel`, an
  `extension ISO_9945.Kernel { struct Descriptor }` actually declares
  `Kernel_Primitives_Core.Kernel.Descriptor` and silently conflicts with anything
  already there. Resolve the alias chain and grep the foreign module before
  declaring. The same mechanism means sub-namespaces under a typealiased
  L3-policy parent cannot be method-wrapped at L3-policy, and that an L3 extension
  on such a namespace *is* the L2 extension — adding a unifier delegate with the
  same signature is a redeclaration, not composition.
- Before adding an L3-unifier method whose name matches the spec-literal L2 name
  reachable through the `Kernel` alias, land the disambiguation in the same
  change: mark the L2 typed form `@_disfavoredOverload` so the unifier wins.
- POSIX `si_code` subgroups (`FPE_*`, `ILL_*`, `SEGV_*`, `BUS_*`, `CLD_*`, `SI_*`)
  import as `Int` on glibc and `Int32` on Darwin. Wrap case labels — `case
  Int32(FPE_INTDIV):` — or Linux fails to compile.
- A pure Swift struct is not `@objc`-representable and cannot appear as
  `UnsafeMutablePointer<T>?` in a `@convention(c)` signature, however
  layout-compatible it is. `@convention(c, cType:)` does not help. Keep the
  callback on `OpaquePointer?` and bind the typed wrapper on the callback's first
  line.
- Platform `System` targets extend `System` from `System_Primitives` directly. Do
  not create `Darwin.System` / `Linux.System` / `Windows.System` namespace enums.
