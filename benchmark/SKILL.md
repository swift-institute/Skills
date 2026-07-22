---
name: benchmark
description: |
  Performance testing: .timed(), .build cleanup, same-package vs nested,
  comparison benchmarks.
  ALWAYS apply when writing or reviewing performance tests and benchmarks.

layer: implementation

requires:
  - testing

applies_to:
  - swift
  - swift6
  - swift-primitives
  - swift-standards
  - swift-foundations
---

# Benchmark Conventions

Performance testing patterns for the Swift Institute ecosystem. Covers benchmark placement, `.timed()` trait usage, `.build` cleanup, comparison benchmarks, and result storage.

---

## Benchmark Placement

### [BENCH-001] Same-Package vs Nested Package Decision Tree

**Statement**: Benchmark test placement MUST follow the layer-based decision tree.

| Layer | Placement | Reason |
|-------|-----------|--------|
| **Foundations** | Same-package `.testTarget()` | swift-testing is reachable within the same superrepo |
| **Standards** | Same-package `.testTarget()` | swift-testing is reachable via relative path to swift-foundations |
| **Primitives** | Nested `Tests/Package.swift` | Layer constraint prevents direct swift-testing dependency in main Package.swift |

**Foundations / Standards** (same-package target):
```swift
// In Package.swift
.testTarget(
    name: "{Module} Performance Tests",
    dependencies: [
        "{Module}",
        .product(name: "Testing", package: "swift-testing"),
    ],
    path: "Tests/{Module} Performance Tests"
)
```

**Primitives** (nested package):
```swift
// In Tests/Package.swift
.testTarget(
    name: "{Module} Performance Tests",
    dependencies: [
        .product(name: "{Module}", package: "swift-{package}"),
        .product(name: "Testing", package: "swift-testing"),
    ],
    path: "{Module} Performance Tests"
)
```

**Rationale**: Foundations and standards can reach swift-testing without circular dependency issues. Primitives packages may be transitive dependencies of swift-testing itself, requiring the nested package to break cycles.

**Cross-references**: [INST-TEST-001] for the nested package pattern details.

---

## Build Cleanup

### [BENCH-002] .build Cleanup Requirement

**Statement**: Before running benchmarks, ALWAYS `rm -rf .build` from the benchmark directory (nested `Tests/` or same-package root). Stale build artifacts cause false results and confusing failures.

```bash
# Nested package benchmarks (primitives)
cd swift-{package}/Tests
rm -rf .build
swift test --filter Performance

# Same-package benchmarks (foundations/standards)
cd swift-{package}
rm -rf .build
swift test --filter Performance
```

**Rationale**: Incremental builds can produce measurement artifacts. A clean build ensures reproducible benchmark baselines. This was a recurring footgun in swift-io development — with a stale `.build`, the Swift build system leaks memory during benchmark builds (usage ballooned to ~82 GB against io-bench before the cleanup was made mandatory). Separately, for a long-running comparison/throughput suite ([BENCH-005]) that can run for minutes or hang, verify it in-session with `swift build` (compile-check only) and surface the run command to the user rather than executing `swift test` on it.

---

## .timed() Trait

### [BENCH-003] .timed() Trait Usage

**Statement**: Performance tests MUST use the `.timed()` trait from swift-testing for structured measurement — OR, where the `.timed()` stack is unreachable from the package under measurement (an L1-isolated tree whose dependency closure cannot reach the swift-tests/swift-testing L3 stack), the **executable-target instrument** (the sanctioned variant below).

**The executable-target variant (ratified 2026-06-12; the arc-bench shape)**: a nested `Benchmarks/` package ([BENCH-001] placement, own `.build` for the [BENCH-002] wipe) holding an executable target run directly (`swift build -c release`, then the binary — never `swift test`). Required mechanics: `ContinuousClock` batch timing with per-sample floors (≥ ~0.5 ms); `@inline(never)` opaque sources/sinks with the sink printed at exit; warmup batches + ≥9 timed samples emitting FULL per-sample vectors (`BENCH {json}` lines — variance is never hidden behind a point estimate); every recorded row reports median + worst within-run CV + max cross-run spread over ≥3 process invocations; recorded runs are bracketed (process checks + load) and gated by CROSS-RUN AGREEMENT (uniform inflation across all subjects = environment, excluded); a same-binary drift canary rides each recording window. `.timed()` remains the default wherever it builds; `Lint.Rule.Testing.BenchmarkTimedRequired` carries the exemption as a citation-comment carve (a `[BENCH-003]` mention in the suite's or test's leading trivia exempts — the rule-exemptions citation shape; amended Round M ζ pilot 3, 2026-06-12; receipt `promote-BENCH-003-exemption-validation-2026-06-12.md`).

| Syntax | Purpose |
|--------|---------|
| `.timed()` | Measure with defaults (10 iterations, median) |
| `.timed(threshold: .milliseconds(N))` | Fail if median exceeds budget |
| `.timed(iterations: N, warmup: M)` | Exclude warmup from measurement |
| `.timed(iterations: N, threshold: .milliseconds(T), metric: .median)` | Full control |

**Parameters**:

| Parameter | Type | Default | Purpose |
|-----------|------|---------|---------|
| `iterations` | `Int` | 10 | Measured runs |
| `warmup` | `Int` | 0 | Untimed warmup runs |
| `threshold` | `Duration?` | nil | Fails if exceeded |
| `metric` | `Metric` | `.median` | Which metric to check |

**Correct**:
```swift
@Test(.timed(iterations: 100, warmup: 10))
func `sequential read`() {
    // Performance-critical code
}

@Test(.timed(iterations: 50, threshold: .milliseconds(50)))
func `must complete within 50ms`() {
    // Fails if median exceeds 50ms
}

@Test(.timed(threshold: .milliseconds(50)))
func `descriptive name`() {
    let data = ...
    _ = data.operation()
}
```

**Rationale**: Structured measurement with statistical analysis, thresholds, and trend detection.

**Lint enforcement**: `Lint.Rule.Testing.BenchmarkTimedRequired` (in `swift-foundations/swift-linter-rules`, target `Linter Rule Testing`) flags `@Test`-attributed function decls inside a `Performance` suite (struct named `Performance`, or `extension Foo.Test.Performance`, etc.) whose `Test` attribute does NOT mention `.timed`. Added 2026-05-10 (Wave 2b finalization Batch 6).

---

### [BENCH-004] Performance Suite Serialization

**Statement**: Performance test suites MUST use `.serialized` trait to prevent parallel execution interference. The `#Tests` macro applies this automatically.

**Correct**:
```swift
@Suite(.serialized)
struct `{Type} - Performance` {

    @Test(.timed(threshold: .milliseconds(50)))
    func `descriptive name`() {
        let data = ...
        _ = data.operation()
    }
}
```

**When using `#Tests`**:
```swift
extension {Type} {
    #Tests(snapshots: .init(recording: .missing))
}

extension {Type}.Test.Performance {
    @Test(.timed(threshold: .milliseconds(50)))
    func `operation within budget`() {
        // ...
    }
}
```

**Rationale**: Parallel test execution causes timing measurement variance. `#Tests` macro handles this automatically.

---

## Comparison Benchmarks

### [BENCH-005] Comparison Benchmark Pattern

**Statement**: When comparing performance of two implementations, benchmarks SHOULD use separate benchmark targets with identical test structure and shared fixture setup.

**Pattern** (e.g., `io-bench` vs `nio-bench`):
```
swift-{package}/
  Tests/
    {Module} IO Benchmarks/         # Implementation A
      {Operation} Benchmark.swift
    {Module} NIO Benchmarks/        # Implementation B (reference)
      {Operation} Benchmark.swift
```

Each benchmark file uses the same operations and data sizes:
```swift
@Suite(.serialized)
struct `Read Benchmark` {

    @Test(.timed(iterations: 100, warmup: 10, threshold: .milliseconds(5)))
    func `sequential read 4KB`() {
        // Same workload as comparison target
    }

    @Test(.timed(iterations: 100, warmup: 10, threshold: .milliseconds(50)))
    func `sequential read 1MB`() {
        // Same workload as comparison target
    }
}
```

**Rationale**: Identical test structure and data sizes enable direct performance comparison between implementations.

---

## Result Storage

### [BENCH-006] Benchmark Result Storage

**Statement**: Benchmark results SHOULD be stored in `.benchmarks/` relative to the benchmark root. This directory MUST be excluded from version control via `.gitignore`.

```
Tests/
  .benchmarks/           # Excluded from git
    {date}-{target}.json
  {Module} Performance Tests/
```

**Rationale**: Persistent local results enable trend tracking across development iterations without polluting the repository.

---

## Benchmark Fixtures

### [BENCH-007] Standardized Benchmark Fixtures

**Statement**: I/O benchmarks SHOULD use `IO.Benchmark.Fixture` from IO Test Support for standardized thread pool configuration.

```swift
import IO_Test_Support

@Suite(.serialized)
struct `IO Read Benchmark` {

    let fixture = IO.Benchmark.Fixture()

    @Test(.timed(iterations: 100, warmup: 10))
    func `sequential read`() throws {
        try fixture.withThreadPool { pool in
            // Benchmark code using standardized pool
        }
    }
}
```

**Rationale**: Shared fixture configuration eliminates thread pool setup variance between benchmark runs. Fixture provides consistent worker counts and shutdown semantics.

**Cross-references**: [TEST-026] for IO Test Support module reference.

---

## Build and Test Commands

### [BENCH-008] Build and Test Commands

**Statement**: Benchmark execution depends on placement pattern.

**Same-package benchmarks** (foundations/standards):
```bash
cd swift-{package}
rm -rf .build                          # [BENCH-002]
swift test --filter Performance
swift test --filter "Benchmark"        # Named benchmarks
```

**Nested package benchmarks** (primitives):
```bash
cd swift-{package}/Tests
rm -rf .build                          # [BENCH-002]
swift package resolve                  # First run only
swift test --filter Performance
swift test --filter "Benchmark"        # Named benchmarks
```

**Rationale**: The nested package has its own `.build/` directory and dependency graph.

**Origin**: INST-TEST-010

---

## Warmup Patterns

### [BENCH-009] Manual Warmup When .timed() Unavailable

**Statement**: When `.timed()` trait is unavailable (e.g., Apple Testing without swift-testing), performance tests MUST include explicit warmup loops.

**Correct**:
```swift
@Test
func `slice creation`() {
    let buffer = Memory.Buffer.Mutable.allocate(count: 1000, alignment: 1)
    defer { buffer.deallocate() }

    // Warmup
    for _ in 0..<10 {
        _ = buffer.slice(start: 0, count: 10)
    }

    // Measured
    for _ in 0..<100 {
        _ = buffer.slice(start: 0, count: 10)
    }
}
```

**Rationale**: Warmup eliminates cold-start variance from measurements.

**Origin**: TEST-016

---

## Deferral

### [BENCH-010] Deferral Permitted for Tier 0 Surface with No Performance Claims

**Statement**: A primitives package at Tier 0 (zero primitive dependencies, Foundation-free, embedded-compatible) MAY defer authoring a benchmark target at its initial `0.x.0` release when **both** of the following hold:

(a) the package makes no public performance claims (in README, blog post, DocC, or external comms);
(b) the package's API does not expose a primary operation whose value proposition is performance.

The deferral MUST be re-evaluated when ANY of the following events occur:

| Re-opening trigger | Why |
|---|---|
| A comparative claim is added (e.g., README mentions "faster than X") | Comparative claim is unverifiable without a benchmark; [BENCH-005] applies immediately |
| The package ascends to Tier 1+ in [PRIM-ARCH-001] | Higher tiers compose Tier 0 primitives; downstream consumers benchmark through the surface |
| A downstream consumer ships a benchmark whose hot path runs through this package | Performance becomes contractually visible at the package's API |

**When deferral is appropriate**:

- Tier 0 vocabulary types (typed wrappers, marker types, capability protocols, `~Copyable` discipline scaffolding)
- Packages whose primary value is correctness or expressiveness, not throughput
- Pre-1.0 packages without external consumers

**When deferral is inappropriate**:

- Packages whose README, blog post, or DocC discusses performance characteristics
- Packages that ship comparison benchmarks against an alternative (immediate trigger for [BENCH-005])
- Foundations or standards packages where the API's runtime cost is part of the contract

**Reference application**: `swift-carrier-primitives` 0.1.0 — Tier 0 (Foundation-free, zero deps); the package's value is the typed-wrapper protocol surface, not measurable runtime cost. No benchmark target shipped at 0.1.0; the deferral is recorded in the package's release-readiness brief's Phase 2 audit table (`benchmark | Low | No benchmarks shipped; check whether that's a finding or intended at Tier 0`). The deferral re-opens if Carrier ever makes a performance claim or Tier 1+ packages begin benchmarking through it.

**Rationale**: Mandating benchmarks for every package is over-broad — a typed-wrapper protocol surface has nothing meaningful to benchmark, and an empty `Benchmarks/` directory creates maintenance debt without informing the consumer. The deferral rule names the conditions under which the absence is intentional rather than missing; the re-opening triggers prevent the deferral from drifting into unconditional permission.


**Cross-references**: [BENCH-001], [BENCH-005], [PRIM-ARCH-001], [RELEASE-001].

---

## Integration-Probe Requirement

### [BENCH-011] Integration Probe Required for Storage Benches Under Copyable Wrappers

**Statement**: When measuring a storage primitive whose consumer access path layers a Copyable wrapper, an enum-case extract, or a `subscript`-through-the-wrapper indirection over raw storage access, isolated storage micro-benches MUST be paired with an end-to-end integration probe through the consumer's actual call pattern before the measurement drives an architecture decision. Single-mode isolated benches are insufficient evidence to promote a storage-swap architecture proposal to DECISION status when the access path includes wrapper indirection.

**Composite**: trigger condition (semantic) + dual-mode requirement (mechanical) + status-gate (mechanical).

**When the rule fires**:

| Consumer access shape | Rule fires? |
|---|---|
| Direct storage access (e.g., `buffer[index]` with no enclosing wrapper) | No — isolated bench is sufficient evidence |
| Copyable wrapper around the storage with pattern-match-extract (e.g., `case .object(let o) = raw`) | **Yes** — integration probe required |
| `subscript`-through-the-wrapper indirection (e.g., `wrapper[key]` calls `wrapper.subscript` getter that extracts storage by copy) | **Yes** — integration probe required |
| Enclosing struct's stored property accessed by copy on every read | **Yes** — integration probe required |
| `~Copyable` wrapper (no copy on extract) | No — wrapper-copy term is zero by construction |

**Why**: Isolated benches with pre-warmed caches and direct storage access can overstate integrated performance materially when the consumer pays refcount-per-copy overhead along the hot path (~10× in the swift-json v2 reference case at N=4, where the storage shape paid 3-4 refcounts per Object copy; the generalization of that factor across consumer shapes is unverified — the rule fires regardless of magnitude). Multi-buffer storage primitives (e.g., `Dictionary.Ordered = Set.Ordered + Buffer.Linear + Hash.Table`) compound the refcount cost with the number of heap-backed components in the storage shape; the isolated bench measures the O(1) algorithmic win but not the N × K compound refcount term that fires on every wrapper copy along the hot path.

**How to apply**: Before proposing an architecture change that swaps storage primitives behind a Copyable wrapper, ship two bench modes alongside the proposal:

1. **Isolated storage-only mode** (the existing `crossover`-style micro). Measures the raw lookup / set / iterate cost of the storage primitive against the candidate alternative at varying input sizes. Catches algorithmic regressions.
2. **Integrated mode** that walks the consumer's actual access path at the workload's representative N distribution. Catches refcount-per-copy regressions invisible to mode 1.

If the integrated mode shows a regression, the architectural change is empirically refuted regardless of what the isolated mode shows. Per [BENCH-010] / [RES-018], do not pursue speculative storage swaps without both probes green.

**Reference harness pattern**: `swift-foundations/swift-json/Experiments/parse-performance-bench/` exhibits the dual-mode shape — `crossover` mode (isolated storage micro) + `synthetic-lookup` mode (end-to-end integrated) + `size-dist` mode (workload N-distribution characterization). The harness's L1-1 disposition (where `crossover` showed Dict.Ordered winning at every N but `synthetic-lookup` showed +226% regression) is the canonical worked example of the rule firing.

**Reference mechanical validation**: `swift-institute/Experiments/copyable-wrapper-refcount-cost/` mechanically validates the underlying cost model (Copyable struct with K heap-backed properties incurs K retain operations per pattern-match-extract). Cited as standing evidence for the "wrapper-copy term is real and load-bearing" premise the rule rests on.


**Cross-references**: [BENCH-001], [BENCH-005], [BENCH-010], [RES-018], [RES-020].

---

## Metric of Record

### [BENCH-012] Recorded Baselines State Their Derivation Formula

**Statement**: Every recorded baseline that gates a decision MUST state its derivation formula inline, next to the number (e.g. "door = growRelocate − build.control, per slot"), and verification of that baseline MUST cite the formula — re-measuring without citing the definition is not verification.

**Why**: independent re-measurement protects against copied errors, not shared frame errors — executor and seat independently computed raw `growRelocate/n` against a recorded DELTA metric and converged on the same wrong conclusion (the W2/W3 raw-vs-delta symmetric misread; Reflection 2026-06-13 tower-phase-4-seat-round-m-supervision).

**How to apply**: put a method note in the baselines doc making the metric definition load-bearing; verifiers quote the formula in their verdict before comparing numbers.

**Cross-references**: [BENCH-006] (result storage), [BENCH-011] (evidence discipline for architecture-driving benches)

---

## Cross-References

See also:
- **testing** skill — [TEST-*] for umbrella routing and test support infrastructure
- **testing-swiftlang** skill — [SWIFT-TEST-004] for performance suite serialization in Swift Testing
- **testing-institute** skill — [INST-TEST-001] for nested package pattern details
- **existing-infrastructure** skill — for IO Test Support module inventory
- **research-process** skill — [RES-018] (Cross-Cutting Primitive: Compose-First Justification) + [RES-020] (Tier classification); [BENCH-011] composes with [RES-018]'s compose-first discipline (demonstrate composition of existing primitives fails before promoting a cross-cutting primitive). [RES-018] re-scoped 2026-06-09 to remove consumer-count gating; the composition with [BENCH-011] is unchanged in substance (both demand structural/empirical evidence, not adoption)
