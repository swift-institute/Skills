# Concurrency and isolation

Companion to the `swift` skill. Read this when touching `Sendable`, actors,
`Mutex`, or isolation boundaries.

## Start at the top of the hierarchy

Non-Sendable is the default; avoid viral Sendability. Start at an actor and move
down only with a documented constraint.

A `~Copyable` struct whose stored properties are all Sendable uses plain
`Sendable`. `@unchecked` is about a non-Sendable field, never about `~Copyable`
itself — that confusion produces `@unchecked` conformances that were never
needed.

## `@unchecked Sendable`, and which half of it is checked

Classify every `@unchecked Sendable`:

- **A** — synchronized; document the mechanism.
- **B** — ownership transfer.
- **C** — thread-confined; should become `~Sendable`, deferred.
- **D** — structural workaround, where the type is provably safe but inference
  cannot see it. A narrow hatch, not a bucket.

**The category is judgment, and nothing enforces it.** No predicate can tell a
correct B from a lazy D; the classification is yours and a wrong one costs
nothing mechanically. Choose it as if the next reader will rely on it, because
that is the only thing that makes it worth anything.

**The justification markers are checked.** A justification citing a compiler
limitation carries `WHY:` (the limitation), `WHEN TO REMOVE:` (the toolchain or
compiler-fix trigger), and `TRACKING:` (the experiment path or issue link). A
linter rule requires all three in the declaration's leading trivia, and fires
only when limitation language is present in that trivia. It checks marker
*presence* — not that `TRACKING:` is a real link, not that `WHEN TO REMOVE:`
names a reachable condition. Without the anchors the justification ages into
folklore as compilers fix the thing it cites; with them, it can at least be
revisited.

One more mechanical fact, easy to get backwards because the rule that owns it is
named after the categories: the conformance clause carries bare `@unchecked
Sendable`, never `@unsafe @unchecked Sendable`. `@unsafe` is scoped to the
memory-safety dimensions and belongs on the type or member declaration; thread
safety is the separate dimension `@unchecked Sendable` carries alone. That
pairing is what the rule actually fires on.

Describe the risk accurately when you write the disclosure: `@unchecked` removes
the compiler's data-race prevention. It does not "assert thread safety".

## Prefer regions to constraints

Use `sending T` on boundary-crossing parameters and returns rather than `T:
Sendable`. Do not put `& Sendable` on a protocol associatedtype — the transport
decision belongs to the consumer, and baking it into the protocol takes it away
from every conformer.

At the combinator layer, `: Sendable` on the struct, `where Upstream: Sendable`,
`@Sendable` on stored closures, and `where Self: Sendable` on the extension form
one coupled cascade — drop all four together or none.

Conditional Sendable written as `extension C: Sendable where T: Sendable` is
fine; the same bound written as `struct C<T: Sendable>` is not, because it binds
at instantiation.

## Locks

Never add `Element: Sendable` to dodge a region-merge diagnostic in a `withLock`
closure — repair the transfer with an `Ownership.Slot` intermediary, or
restructure. A `Sequence` of non-Sendable elements entering a lock is staged
through `Ownership.Slot(Array(elements))` before the lock and taken inside;
`sending` on the parameter alone is not enough, because the capture merges with
the `inout sending State` region.

A `Mutex.withLock` wrapper declares `(inout sending State) throws(E) -> sending
R`.

**Hazard.** `mutex.withLock { $0 }` compiles even when `State` is non-Sendable,
and hands a region-disconnected alias out of the lock with no diagnostic. That is
a real, undiagnosed race. Return a Sendable snapshot instead, or move a move-only
value out via the Slot + `inout sending` path.

Inside a lock, do a pure state transition and return a `~Copyable` action enum;
run side effects outside the lock via `switch consume action`. Side effects under
the lock invite reentrancy and deadlock.

## `~Copyable` across isolation

`~Copyable` values cannot be captured in `@Sendable` or `@escaping` closures —
including `TaskGroup.addTask`, `Task.detached`, and
`withTaskCancellationHandler.onCancel`.

To reach an actor with a `borrowing ~Copyable` parameter, take an `isolated
Actor` parameter on a private helper. To dispatch blocking work without forcing
`T: Sendable`, use `withCheckedContinuation` plus `Task<Void,
Never>(executorPreference:)`.

A closure *capture* cannot be consumed even in a non-escaping closure — thread
the payload as a `consuming` closure *parameter*: `withUnique(consuming: payload)
{ column, payload in … }`.

Copyable payloads mask this: the "consume" silently copies, so an API tested only
with Copyable elements breaks on its first move-only client. A move-only
instantiation in the suite is what turns this from a latent break into a
compile error at the right time.
