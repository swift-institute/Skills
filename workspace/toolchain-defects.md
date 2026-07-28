# Investigating a toolchain failure

Companion to the `workspace` skill. Read this when a failure may be the compiler,
the optimizer, or the build system rather than product logic.

## Produce a decision, not a pile of diagnostics

An investigation ends in exactly one of these:

- a product defect, with a verified fix;
- a toolchain defect, with a minimum reproducer and a safe workaround;
- a language constraint, with an implementation decision;
- a stale-state or resolution failure, with its source named;
- an explicitly bounded inconclusive result.

"Inconclusive" is a legitimate ending. An unbounded one is not — say what was
covered and what was not.

## Eliminate the cheap explanations first

Record the exact command and `swift --version`. Check the dependency URL and
requirement, the selected toolchain and any unintended `TOOLCHAINS` override,
resolver diagnostics, and a fresh operation. Then retest on the latest
development toolchain, because the bug may already be fixed:

```bash
ls /Library/Developer/Toolchains/
TOOLCHAINS=swift xcrun swiftc -O reproducer.swift -o /tmp/test 2>&1
```

Do not call a failure a compiler bug because the diagnostic is confusing. A
blocked super-repository build does not prove the bug persists on another
toolchain — it proves the super-repository is still blocked.

## Reduce, one variable at a time

Reduce until removing any single remaining element would eliminate the behavior.

A reproducer is faithful only if it preserves the compilation phase and
optimization mode, the diagnostic or crash signature or wrong behavior, the
generic / ownership / isolation / conformance constraints that trigger it, and
the relevant file and module boundaries. If the trigger cannot itself compile,
drive `swiftc` out of process from a test and assert on the process result.

Every reduction step needs a verified clean build: run `workspace package clean`
before building, or build a standalone `swiftc` reproducer with no SwiftPM cache.
Stale caches have produced false reductions here — a "crashing" reduction may be
running cached SIL from a previous variant, which looks exactly like a successful
reduction.

Vary exactly one dimension per experiment: optimization, file boundary, target
boundary, declaration order, generic constraint, ownership annotation, module
resilience, toolchain. Every claimed required ingredient needs an A/B result — A
contains the ingredient and fails, B removes only that ingredient and passes.
State the coverage of a negative experiment: "not reproduced in this shape" is
not "impossible".

## Verify in the production shape

A reduced reproducer establishes a mechanism, not its prevalence. Insert the
exact trigger into each cited production package and confirm the real code
behaves the same before recommending a production change. A minimal reproduction
validates that a bug exists; it cannot validate that a workaround works at scale,
because the real codebase has structural properties the reproducer was reduced to
remove.

Anything whose confirmation would admit production adoption of a feature,
pattern, or workaround must pass in release mode **and** across a module boundary
— a second target, or a sibling package importing the first.

Debug single-module passes routinely hide SIL-level bugs that fire only once
optimization enables the path (CopyPropagation, CopyToBorrowOptimization,
specialization), and hide access-control and serialization effects that depend on
`package` versus `public`. A pattern safe in debug and unsafe in release is
failed evidence dressed as success.

```bash
workspace package build --fresh --argument=-c --argument release
```

## Compiler-level diagnosis

Escalate only as far as needed: source logging, debug-versus-release, file- and
module-level elimination, compiler views, pass bisection, compiler source. Use
the same frontend mode and flags as the reproducer when comparing stages.

```console
swiftc -typecheck Reproducer.swift
swiftc -emit-silgen Reproducer.swift
swiftc -emit-sil -Onone Reproducer.swift
swiftc -emit-sil -O Reproducer.swift
swiftc -emit-ir -O Reproducer.swift
swiftc -S -O Reproducer.swift
swiftc -Xfrontend -debug-constraints Reproducer.swift
swiftc -Xfrontend -debug-generic-signatures Reproducer.swift
swiftc -Xfrontend -sil-verify-all Reproducer.swift
```

Compiler flags change between toolchains, so confirm availability with the
selected toolchain rather than treating this list as an interface.

Reading the stages: broken `-emit-silgen` points at SIL generation; correct raw
SIL with broken canonical SIL points at a mandatory pass; correct canonical SIL
with broken optimized SIL points at optimization. Compare the smallest differing
function, never whole module dumps.

For optimization-only failures, prove `-Onone` passes, capture the pass pipeline
for that exact toolchain, binary-search the executed pass count, then inspect the
before/after SIL. Pass numbering is toolchain-specific evidence and never a
portable conclusion.

## Known traps

When a testing-framework macro reports an `@section` or lexical-context failure,
remove or simplify the surrounding test macros first. Macro diagnostics can mask
an ordinary semantic error in the test body; investigate the macro only after the
underlying source type-checks independently.

A recommendation to conform to a stdlib protocol needs a verification spike — a
minimal external-package target declaring the conformance, built successfully —
before adoption. Two mechanisms strip protocols from the SDK's `.swiftinterface`:
`@_spi`-gated declarations disappear from the public interface, and new stdlib
protocols may be `public` in `swiftlang/swift` source but not yet shipping in a
given SDK's compiled interface, driven by SDK-build availability annotations
rather than source visibility. Both surface as the same "no such type in module"
failure, which is why reading the source is not enough.

Never suppress optimization to hide a miscompile. A proposed fix must change the
diagnosed behavior in the production shape; an explicit conformance or a no-op
rewrite is not a fix merely because it looks related.

Searching upstream issues is evidence gathering. It does not authorize filing or
modifying an upstream issue.
