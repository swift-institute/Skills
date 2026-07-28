# Choosing a data structure

Companion to the `swift` skill. Read this when picking a container, or when
tempted to add a new one.

## The four layers

Containers compose in four layers, each adding one concern:

```
Memory   raw allocation
Storage  element lifecycle
Buffer   mutation semantics and state
ADT      user-facing API
```

Most code uses an ADT. Drop to Buffer for direct mutation control, to Storage when
building a new Buffer discipline, to Memory only for allocator work. Select by
laws and ownership behavior, not by familiar spelling, and confirm against live
source rather than against the shape you remember.

## Family first, variant second

Choose the ADT family by access pattern. A variant is not a new family:
allocation placement (heap by default, `Small<n>` inline-bytes with heap spill,
`Inline<n>` fixed element count), capacity (growable by default, `Bounded` with
typed overflow), and ownership (unique move-only by default, `Shared` for CoW)
are three free axes, declared as front-door typealiases and never hand-written.
Which variants exist per family is consumer-pulled.

`Small<n>` counts **bytes**; `Inline<n>` counts **elements**.

A semantic sibling — distinct observable laws, like an insertion-ordered
dictionary — is a separate package, not a variant.

Institute containers pass `~Copyable` through: base variants are `~Copyable` and
gain `Copyable` conditionally when the element is. Never frame a container
question as "can stdlib `Array` hold this?" and fall back to `[String]` citing a
typed-system gap. The axis is resource-shaped (wants `~Copyable` → institute
container) versus data-shaped (happy Copyable → stdlib array is fine).

## Before proposing a new primitive

Demonstrate that composition over the existing catalogue does not cover the case,
and state which property it lacks. `stdlib.ManagedBuffer` is vestigial but its
replacement does not exist yet — direct use is the right interim choice, and
wrapping it in a ceremony-only Storage primitive is the premature-primitive trap.

### Match by algorithm, not by the label in a comment

The word in the name is not the data structure. In this ecosystem:

- `Buffer.Slab` is bitmap-tracked occupancy. No generation tokens, so no
  use-after-free detection.
- `Memory.Allocator.Arena` is a bump allocator: O(1) allocation, no individual
  deallocation, bulk reclaim through `reset()` or the backing region's `deinit`.
  Also no generation tokens.
- `Memory.Allocator.Pool` is the free-list.
- `Machine.Value.Arena` is the one that carries generation tokens — a counter
  incremented on `reset()`, with each handle recording the generation it was
  issued under and every operation validating the match. That is what gives
  use-after-reset detection.

So "arena" alone does not tell you whether stale handles are caught; two types
here spell it and only one does. Match by the algorithmic requirement — free
list? generation tokens? O(1) alloc *and* dealloc? — and check the type you mean
rather than the word.

## Composition rules that are easy to violate quietly

Liveness and teardown live in the single-allocation leaf, never in the buffer —
for inline and heap, dense and sparse alike. Pick the leaf and compose the one
generic buffer rather than reaching for a concrete `.Inline` / `.Small` *buffer*
type. Tower ops must not hardcode a memory leaf: prefer a seam-generic form, then
an allocation-generic pin fenced on growability, and only then a thin ownership
twin.

A public mutating op calls the CoW gate exactly once at entry, before its first
write; seam-generic helpers never gate, and say so in their doc comment.
Double-gating and an ungated helper write are both defects, and they look
different at the call site but the same in a passing test.

Iteration flows from the column and is never re-implemented per family: a
container is iterable exactly when its column vends borrowing iteration. A
move-only element can be borrow-iterated but never consume-iterated. Multipass
iteration is claimed only where the column vends it.

A type conforming to both the store and buffer seams and consumed as an ADT
column must honor the seam ledger — initialize increments count by one, move
decrements it, the element subscript leaves it alone, and none of them changes
capacity — and prove it by running the shipped law suite from its own tests. The
generic bound cannot express this contract, so a conformer that satisfies both
seams without ledgering corrupts silently. That is the whole reason the law suite
exists rather than a stricter constraint.
