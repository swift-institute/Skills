# Compiler diagnostics

Load this reference only after source-level reduction leaves a compiler,
optimizer, or emitted-code hypothesis.

## Useful compiler views

Use the same frontend mode and flags as the reproducer when comparing stages.
Common views include:

```console
swiftc -typecheck Reproducer.swift
swiftc -emit-silgen Reproducer.swift
swiftc -emit-sil -Onone Reproducer.swift
swiftc -emit-sil -O Reproducer.swift
swiftc -emit-ir -O Reproducer.swift
swiftc -S -O Reproducer.swift
```

Add diagnostic flags only when they answer a specific question:

```console
swiftc -Xfrontend -debug-constraints Reproducer.swift
swiftc -Xfrontend -debug-generic-signatures Reproducer.swift
swiftc -Xfrontend -sil-verify-all Reproducer.swift
```

Compiler flags change between toolchains. Confirm availability with the selected
toolchain rather than treating this list as an exhaustive interface.

## Locate the failing stage

- Broken `-emit-silgen` output points toward SIL generation.
- Correct raw SIL but broken canonical SIL points toward a mandatory pass.
- Correct canonical SIL but broken optimized SIL points toward optimization.
- Correct SIL but broken IR or machine code points farther downstream.

Compare the smallest differing function, not entire module dumps.

## Pass bisection

For optimization-only failures:

1. prove the reproducer succeeds under `-Onone` and fails under the relevant
   optimization mode;
2. capture the optimized pass pipeline for that exact toolchain;
3. vary the number of executed passes with the toolchain’s supported pass-count
   option;
4. binary-search the first failing count;
5. inspect the before/after SIL and the pass name;
6. confirm by disabling or isolating that pass when the toolchain permits it.

Pass numbering is toolchain-specific evidence, never a portable conclusion.

## Reading SIL

Track ownership, borrows, copies, destroys, enum payload extraction, function
substitution, and cleanup blocks. For verifier failures, find the first invalid
value or lifetime edge rather than the final verifier message alone.

Reference indirection can change optimizer behavior. When a failure disappears
after introducing a local binding or helper function, treat that as a candidate
source-structure workaround and verify it in the production shape.

## Compiler source

Read compiler source only after the failing phase or pass is narrow enough to
name. Search by:

- emitted diagnostic text;
- pass name;
- SIL instruction or verifier assertion;
- feature implementation type;
- nearby regression tests.

The goal is a testable causal account, not a tour of the compiler.
