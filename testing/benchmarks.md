# Benchmarks

Companion to the `testing` skill. Read this when writing, running, or citing a
performance measurement.

Benchmarks may be deferred for a surface that makes no performance claims. An
empty benchmark package is worse than none — it asserts coverage that is not
there.

## Shape

An executable target in a nested `Benchmarks/` package with its own
coordinator-owned clean state, built and run in release:

```sh
workspace package build --argument=-c --argument=release
workspace package run   --argument=-c --argument=release
```

Never delete `.build` directly — `workspace package clean` from the benchmark
root.

## Mechanics

None of these is guessable, and each one exists because its absence produces a
number that looks fine:

- `ContinuousClock` batch timing, with a per-sample floor large enough that clock
  resolution is not part of what you are measuring.
- `@inline(never)` opaque sources and sinks, with the sink printed at exit —
  otherwise the optimizer deletes the work and you measure an empty loop.
- Warmup batches, then enough timed samples to see a distribution, emitting the
  FULL per-sample vector: one `BENCH {json}` line per sample. Never hide variance
  behind a point estimate.
- Every recorded row reports median, worst within-run CV, and max cross-run
  spread across several separate process invocations. One process is one
  environment.
- Recording windows are bracketed by process and load checks and gated on
  cross-run agreement. Uniform inflation across every subject is the environment,
  not the code, and is excluded.
- A same-binary drift canary rides each recording window.

Store results under `.benchmarks/` relative to the benchmark root, gitignored.

## Citing a number

Every recorded baseline that gates a decision states its derivation formula
inline, next to the number. A verifier quotes that formula before comparing
numbers — re-measuring without citing the definition is not verification, it is
producing a second number.

## When an isolated measurement is not evidence

Where the consumer's access path layers a Copyable wrapper, an enum-case extract,
or a subscript indirection over raw storage, an isolated storage micro-benchmark
does not settle an architecture change. Pair it with an integrated probe walking
the consumer's real call pattern at the workload's N distribution.

Refcount-per-copy cost is invisible to the isolated mode, so the two modes can
disagree — and when they do, the integrated regression refutes the change
regardless of what the isolated mode shows. A `~Copyable` wrapper carries no such
term, which is exactly why the comparison has to be made rather than assumed.
