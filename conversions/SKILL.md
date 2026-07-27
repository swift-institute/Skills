---
name: conversions
description: Typed index patterns, conversion APIs, and raw-value access rules. Apply when working with Index values, Offset, Count, Ordinal, Cardinal, cross-domain conversion, or rawValue.
---

# Conversions

Preserve domain meaning through every conversion. Do not erase a typed value to
an integer merely because the destination API is less precise.

## Workflow

1. Name the source and destination domains and the semantic relation between
   them.
2. Search for the owning typed conversion before adding an initializer,
   `rawValue` access, or arithmetic.
3. Keep index, offset, count, ordinal, and cardinal dimensions distinct.
4. Make partiality visible in the return type or typed error.
5. Put a generally lawful conversion on the semantic owner; keep
   boundary-specific adaptation at the boundary.
6. Apply **reuse-first** before introducing a new conversion surface.
7. Verify round trips, bounds, zero/one bases, overflow, and ownership variants.

## Detailed rules

Load [`catalogue.md`](catalogue.md) when choosing an exact `Index<T>` pattern,
reviewing a `rawValue` use, assigning or interpreting an `[IDX-*]` or
`[CONV-*]` requirement, or implementing a domain-specific conversion.

## Related skills

- **reuse-first** for owner discovery.
- **implementation** for typed arithmetic and call-site shape.
- **memory-safety** for pointer and span indices.
- **modularization** when a conversion creates an integration dependency.
