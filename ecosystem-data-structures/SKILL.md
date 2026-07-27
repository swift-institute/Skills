---
name: ecosystem-data-structures
description: Select existing Swift Institute storage, buffer, collection, span, and memory structures. Apply before introducing or recommending any container, buffer, storage, or memory type.
---

# Ecosystem data structures

Select by laws and ownership behavior, not by familiar spelling. The live source
and manifests are authoritative; this skill routes the choice.

## Selection workflow

1. State element type, cardinality, ordering, uniqueness, mutability, ownership,
   lifetime, contiguity, allocation, and concurrency requirements.
2. Search current ecosystem products and declarations with **reuse-first**.
3. Eliminate candidates whose laws are weaker or stronger than required.
4. Prefer the lowest-level owner that exactly models the needed semantics.
5. Use a view or adapter when ownership must remain elsewhere.
6. Add a new structure only when no existing owner can lawfully express the
   capability.
7. Verify empty, singleton, boundary, mutation, lifetime, and allocation
   behavior appropriate to the choice.

## Detailed catalogue

Load [`catalogue.md`](catalogue.md) when comparing concrete `[DS-*]` types or
families. Confirm any inventory entry against current source before relying on
it; package contents evolve faster than prose catalogues.

## Related skills

- **reuse-first** for live discovery and disposition.
- **memory-safety** for lifetime, span, pointer, and ownership decisions.
- **conversions** for typed indices and counts.
- **modularization** when selection adds a dependency.
