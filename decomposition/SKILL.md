---
name: decomposition
description: Design discipline for splitting a system into units that each own exactly one thing — finding the seam, choosing package, product, target, and file boundaries independently, and judging split, extraction, and removal. Apply whenever adding, growing, splitting, reshaping, or deleting a unit of structure, or when a boundary feels wrong.
---

# Decomposition

Decompose by semantic ownership. A unit's owner is whatever defines its vocabulary,
invariants, and lawful operations — not what shares its file, its size, or its callers.

The default failure is under-decomposition. Every unit should own exactly one thing, and a
reader should be able to name that thing in one sentence without conjunctions. If the sentence
needs an "and", the unit is two units.

## Boundaries are independent

Choose each boundary on its own evidence; never use one as a proxy for another:

- a **package** for release, repository, dependency, or ecosystem ownership;
- a **product** for a supported consumer choice;
- a **target** for a compile-time dependency and import boundary;
- a **file** for a focused declaration or conformance unit.

Two things belonging in one package says nothing about whether they belong in one target, and
one target says nothing about one file. Decide each independently, then check the set is
coherent.

## Finding the seam

Cut where meaning already separates:

- what varies independently — two parts that change on different schedules are two units;
- what has its own reason to change — one unit, one source of change;
- what a different consumer would want alone — if any plausible consumer wants half, that half
  is a unit;
- what carries its own invariants — an invariant that only some of the code must uphold marks
  its own boundary;
- what could be understood, named, and tested without the rest.

Place each unit at the narrowest owner that can host it without reversing the dependency graph.
Prefer an owner extension or a trait-gated conformance for integration; add a new target or
package only for a real import, dependency, or release boundary.

## Signals a unit is doing too much

- Its name is a category, a mechanism, or ends in a grab-bag noun.
- Its description needs "and", or a list of unrelated responsibilities.
- Consumers import it for one part and carry the rest.
- Parts of it are tested with disjoint fixtures, or one part is untestable without the other.
- Changing one concern in it forces recompilation or re-review of unrelated concerns.
- It exposes an escape hatch so callers can reach past its own abstraction.

## Judging a change

Correctness alone drives split, reshape, extraction, and removal decisions.

- Consumer count and adoption are evidence to inspect, never owners or drivers. "Only one
  consumer" and "zero consumers" are not reasons to defer, proceed, remove, or doubt, at any
  phase — and a count derived from manifests is a lower bound anyway, since `@_exported`
  re-exports let a consumer bind a package's types without naming it in any manifest.
- "Cleaner", "smaller", "more modular", and module count are not sufficient reasons on their
  own. Name the ownership, consumer, compilation, release, or dependency property that
  improves. If you cannot name one, the change is a preference.
- Do not resolve a protocol-level relaxation goal by adding a non-conforming sibling type
  alongside the original; that preserves the blocker as latent debt while looking like
  progress.
- Exhaust public API, co-location, owned integration, and package-level access before reaching
  for SPI; unavoidable SPI stays local, explicit, and tracked.

## Deletion gate

Before deleting a package, module, or unit, prove both:

- The code is already committed, and so git-recoverable. Never destroy uncommitted exploratory
  work — it is the one state no later command recovers.
- It is dead at build level. A clean build after removal is the proof; a grep is not, for the
  same re-export reason above.

Never delete another session's work in flight.
