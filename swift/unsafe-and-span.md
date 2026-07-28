# Unsafe containment and Span

Companion to the `swift` skill. Read this when touching raw pointers, `@safe` /
`@unsafe`, or the Span family.

## Containment

Enable `.strictMemorySafety()` on every target. `unsafe` is an expression
keyword like `try`, not a block: mark each unsafe operation individually, wrap the
whole expression from the left including the assignment destination, and remember
it does not propagate into closures.

Place `@safe` boundaries as low as possible — maximize absorbers, minimize
propagators. The acid test is whether a caller can use the complete public API
without ever writing `unsafe`.

A type encapsulating unsafe storage takes `@safe`, never `@unsafe`. `@unsafe
struct` makes `self` unsafe and warns on every ordinary member access inside the
type's own methods, which is the opposite of containment. `@unsafe` belongs on
escape hatches and on public properties vending raw pointers.

Unsafe pointer storage on a `@safe` type is `private` / `internal`. On an
`~Escapable` type a public pointer property is structurally safe; on an
`Escapable` type it is a dangling pointer waiting to happen.

### The disclosure, and what checks it

Every `@safe` declaration and every `nonisolated(unsafe)` declaration carries an
adjacent invariant disclosure — `// SAFETY:` / `// WHY:` lines in the leading
trivia with no blank line between, or a `## Safety Invariant` doc section —
stating what makes the claim sound. This is required even when the attribute
suppresses no diagnostic, because the disclosure is for the next reader, not for
the compiler.

Linter rules check that a disclosure is *present* on `@safe` and on
`nonisolated(unsafe)`. What is sound, and whether the stated invariant is the one
that actually holds, nothing checks. Treat a clean run as "the comment exists".

`nonisolated(unsafe)` statics genuinely accessed concurrently need real
synchronization, not a comment about one.

## Raw pointers

A raw pointer is admitted only when all of:

- no span fits — a C string, an FFI boundary, an allocator substrate. "Uninitialized
  tail" is not such a case;
- it lives at the deepest layer and is never re-exported upward;
- it is `@unsafe` and closure-scoped when it is an accessor;
- an adjacent `// WHY:` states which interop boundary forces it.

A retained unsafe accessor cites the specific compiler limitation *and* a
`REMOVE-WHEN:` condition. Never ship both a safe and an unsafe public overload.

At L3 consumer sites, copy a span with indexed iteration rather than
`withUnsafePointer` + `UnsafeBufferPointer` + `Array(buffer)`. At L1/L2 sites
interfacing with C, the unsafe form remains correct.

## The Span family

Span is the primary interface for contiguous memory, matched to the access mode:
`Span` reads the initialized region, `MutableSpan` mutates in place, `OutputSpan`
via `withOutputSpan(addingCapacity:)` appends into uninitialized capacity.
`MutableSpan` is undefined over uninitialized memory, but that no longer
justifies a raw pointer — `OutputSpan` is the answer to the case it used to be
reached for.

Vend spans as properties (`var span: Span<Element> { @_lifetime(borrow self)
borrowing get }`), not `withSpan(_:)` closures. `Span` is `~Escapable`, so the
type system already scopes it and a closure adds ceremony over a guarantee you
already have.

### Match the addressing seam to the index domain

Spans witness the *initialized prefix* `[0, count)`. A container computing
positions in the full allocation `[0, capacity)` — wrapped rings, head-offset
layouts, sparse slabs — must read and write through the per-slot subscript.

A count-bounded read inside a wrap-capable discipline is invisible until the
structure actually wraps, so a suite that only exercises head-at-zero states
passes with the defect present. This is a test-design consequence, not just an
addressing one.

### Cost, on a measured hot path

Span-first costs the *derivation*, not the access. Per-access derivation that
recomputes `count` through an initialization ledger is hostile — hoist it out of
the loop, or cheapen it to a header-word read.

Hoisting is currently blocked in places: a live `mutableSpan` pins the whole
struct, so sibling-property mutation under a hoisted span is an exclusivity
error, and `deinit` rejects hoisted spans outright.

Do not cache addresses in generic code over a storage seam — derive per access,
including in `deinit`. An inline-backed resource moves its bytes with the value,
so a cached base dangles after a move. A cached base is lawful only behind a
concrete heap-pinned path.

An owned region's `unsafe` has two surfaces worth separating when you reason
about what could ever go away: the allocation floor — alloc/free plus the
lifetime-held base — is permanent, while the span-vending surface is what a
safe-owning-span language feature would retire.

A read-only regime must not conform to a write-capable region protocol; reads
ride `Span`.
