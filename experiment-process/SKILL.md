---
name: experiment-process
description: |
  Experiment workflows: hypothesis, validation, documentation.
  Apply when testing implementation approaches or validating designs.

layer: process

requires:
  - swift-institute

applies_to:
  - experiments
  - validation

---

# Experiment Process

Workflows for conducting implementation experiments. Three source documents define the experiment system:

| Document | Purpose | IDs |
|----------|---------|-----|
| Experiment.md | Shared infrastructure | EXP-002 – EXP-010d |
| Experiment Investigation.md | Reactive workflow | EXP-001, EXP-004, EXP-004a, EXP-011 |
| Experiment Discovery.md | Proactive workflow | EXP-012 – EXP-017 |

**Experiment vs Unit Test**: Experiments verify Swift compiler/language capabilities. Unit tests verify your implementation. If it tests YOUR code → unit test. If it tests SWIFT behavior → experiment.

**Experiment vs Research**: Experiments produce empirical results (CONFIRMED/REFUTED). Research produces analysis and recommendations (DECISION/RECOMMENDATION). Experiments are Swift packages; research is Markdown.

---

## Investigation Workflow (Reactive)

**Entry point**: Something failed, behaves unexpectedly, or a technical claim needs empirical verification.

### [EXP-001] Investigation Triggers

**Statement**: An investigation experiment MUST be created when a technical claim cannot be verified without executing code. SHOULD NOT be created when documentation answers the question.

| Category | Action |
|----------|--------|
| Compiler behavior uncertainty ("Does X compile?") | Create experiment |
| Documentation contradiction ("Docs say X, I see Y") | Create experiment |
| Feature interaction ("Do A and B work together?") | Create experiment |
| Error diagnosis ("What causes this error?") | Create experiment |
| Syntax question ("What's the syntax?") | Read docs first |
| API lookup | Read docs first |

**Cross-references**: [RES-001], [EXP-001]

---

### [EXP-004] Reduction Methodology

**Statement**: Code MUST be reduced until removing any single element would eliminate the behavior being tested.

**Composite:** reduction procedure (semantic) + build-verification anti-stale-cache rule (mechanical).

Reduction steps: (1) Start with failing code, (2) remove unused imports, (3) remove uninvolved types, (4) inline function calls, (5) remove unexercised properties/methods, (6) simplify type hierarchies, (7) remove generic parameters if possible. Verify behavior persists after each step.

**Build verification**: Each reduction step MUST use a verified clean build. For SwiftPM experiments, run the machine-wide coordinator's `package clean` action before its `package build` action; never delete `.build` directly. Alternatively, build a standalone reproducer with `swiftc` directly (no SwiftPM cache). Stale caches have caused false reductions in multiple investigations — a "crashing" reduction may actually be running cached SIL from a previous variant.

```swift
// CORRECT — Minimal reproduction
struct Resource: ~Copyable {
    consuming func use() throws(SimpleError) { }
}
enum SimpleError: Error { case failed }

// INCORRECT — Non-minimal (Foundation, unused properties, unexercised conformances)
```

**Cross-references**: [EXP-004a]

---

### [EXP-004a] Incremental Construction Methodology

**Statement**: When investigating a hypothesis without existing failing code, complexity SHOULD be added incrementally — one feature at a time — until the behavior appears.

This is the inverse of [EXP-004]. Reduction strips down; construction builds up. Use construction when testing hypotheses or when production code is too complex to port.

**Context-sensitive bugs**: When all experiment variants pass but production fails, the bug requires the *combination* of factors. The experiments proved no single factor causes it — only their interaction does. Experiments that "fail to reproduce" are still valuable: they narrow the search space.

**Cross-references**: [EXP-004], [EXP-011]

---

### [EXP-011] Experiment-First Debugging

**Statement**: When production code fails with uncertain cause, an experiment SHOULD verify the capability works in isolation BEFORE debugging production.

Sequence: (1) Identify uncertainty, (2) create minimal experiment, (3) run — success proves capability works, (4) apply to production, (5) if production fails, compare delta between experiment and production.

**Workaround validation trap**: Minimal reproductions validate that a bug exists. They CANNOT validate that a workaround works at scale. Test workarounds in the actual codebase — the production code may have structural properties the reproduction lacks.

**Cross-references**: [EXP-001], [EXP-004a]

---

### [EXP-011a] First Clean Signal Is The Result

**Statement**: An experiment's first clean signal — positive OR negative — IS the result. Subsequent variants MUST test a different hypothesis, not repeat the same hypothesis with more pressure. Adding minor variations (more iterations, larger inputs, slightly different code shape) to a variant that already returned a definitive signal is asking the same question louder, not testing something new.

**The rule**:

| After V1 produces | V2 MUST |
|-------------------|---------|
| Clean CONFIRMED (hypothesis validated, evidence captured) | Test a different hypothesis, or stop |
| Clean REFUTED (hypothesis invalidated) | Test a different hypothesis (what else could cause the observed behavior?), or stop |
| Ambiguous / flaky signal | First stabilize the experiment (see [EXP-004] reduction, [EXP-004a] construction), not add variants |

**What counts as "the same hypothesis with more pressure"**:
- 1000 iterations when 10 iterations already showed the pattern clearly
- Adding unused code or state that does not exercise a new mechanism
- Running the same test under a slightly different optimization flag (-Onone → -O) without a specific reason to expect it to matter
- Scaling up variables (buffer size, thread count) without a theoretical basis for the scaling to trigger something new

**What counts as "testing a different hypothesis"** (legitimate continuation):
- Adding a feature or interaction the initial variant did not exercise (concurrency, lifetime-scoped access, a specific language feature)
- Testing whether a refuted hypothesis rules out a broader class (if memory ordering is NOT the cause, is it code motion? inlining? WMO?)
- Reducing toward a smaller reproducer after an initial positive signal ([EXP-004])

**Context-sensitive bugs caveat**: when production fails but all variants pass, the hypothesis "the bug is reproducible in isolation from this simple shape" has been refuted. That IS the result. The next step is to accept the negative result and narrow from the production side (add production code incrementally per [EXP-004a]), not to keep enlarging the isolated variant.

**Documenting a negative result**: an experiment that refutes a hypothesis is valuable and MUST be written up as a finding, not hidden or treated as a failure. The header note SHOULD state the specific hypothesis refuted and what that rules out about the production bug's shape.

**Rationale**: The 2026-04-08 actor-state investigation ran V1–V5 testing essentially the same "actor state read stale via inline fallback" hypothesis, then concluded (correctly) that the bug could not be reproduced from the minimal shape. V2–V5 added nothing V1 had not established; they consumed time that a different-hypothesis variant (or an early stop) would have saved. The retrospective lesson is structural: experiments have a finite number of hypotheses to discriminate among, and variants must advance the discrimination, not repeat it.


**Cross-references**: [EXP-004], [EXP-004a], [EXP-006], [EXP-011]

---

### [EXP-018] Experiment Consolidation

**Statement**: When an investigation produces 5 or more experiments exploring related aspects of the same bug, feature, or design question, they SHOULD be consolidated into thematically coherent groups before further investigation. Each consolidated experiment groups variants by the specific hypothesis they test, with a shared `EXPERIMENT.md` documenting the relationships between variants.

**Composite:** count threshold (mechanical) + 5-step procedure (semantic) + standalone-vs-context-sensitive sub-judgment (semantic).

**Consolidation procedure**:

| Step | Action |
|------|--------|
| 1. Categorize | Group experiments by the distinct hypothesis each tests |
| 2. Create | One consolidated package per category, containing the relevant variants |
| 3. Archive | Add `SUPERSEDED.md` to originals pointing to the consolidated package (do not delete) |
| 4. Update | Fix cross-references in all research documents that referenced the originals |
| 5. Index | Update `_index.json` (see [EXP-003e]). |

**Why consolidate**: Scattered experiments obscure the investigation's structure. Consolidation makes the evidence base visible as a whole — which hypotheses have been tested, which remain open, and how findings relate to each other. This visibility often reveals the investigation's actual structure (e.g., "three distinct bugs, not one") and accelerates root-cause identification.

**When NOT to consolidate**: Independent experiments that happen to involve the same package but test unrelated hypotheses SHOULD remain separate.

**Standalone vs context-sensitive reproducers**: If a consolidated experiment includes a standalone reproducer (one that crashes without the full dependency graph), elevate it to its own package. Context-sensitive experiments that only fail within the full dependency graph should be clearly documented as such — their value is in narrowing the search space, not in standalone bug reporting.

**Cross-references**: [EXP-004], [EXP-004a], [EXP-011]

---

## Shared Infrastructure

### [EXP-002] Package Location Convention

**Statement**: Experiment packages MUST be in an `Experiments/` directory at the
root of the appropriate repository, with descriptive kebab-case names. Only two
kinds of `Experiments/` container are valid:

| Scope | Repository |
|-------|------------|
| Ecosystem-wide / standalone / cross-cutting | `swift-institute/Experiments/` |
| Per-package (highest-layer dep) | `<pkg>/Experiments/` (e.g. `swift-array-primitives/Experiments/`) |

**Layer-level containers are forbidden**: `swift-primitives/Experiments/`,
`swift-standards/Experiments/`, `swift-foundations/Experiments/` MUST NOT exist.
These directories were historically used when the three layers were superrepos;
they have been dismantled into standalone sibling packages. An experiment that
would have lived at a layer-container level has exactly two canonical homes:
(a) the per-package `<pkg>/Experiments/` of its highest-layer dependency
(per [EXP-002c]), or (b) the ecosystem-wide `swift-institute/Experiments/` when
standalone, cross-cutting, or testing general compiler/runtime behavior.

If a layer-level `Experiments/` directory is encountered, it MUST be triaged
per [EXP-002c]: relocate each experiment per the highest-layer-dep rule, update
the relevant `_index.json` files per [EXP-003e], and remove the layer-level
container. This is the canonical remediation, not a migration option.

**Cross-references**: [EXP-002a], [EXP-002c], [EXP-003e], [EXP-008]

---

### [EXP-002a] Experiment Triage

**Statement**: Before creating an experiment, determine scope. Experiments that
exercise one or more packages' APIs go in the highest-layer dep's
`<pkg>/Experiments/` per [EXP-002c]. Experiments that test general Swift
behavior, compiler/runtime mechanics, or cross-layer/cross-package interaction
with no clear dep owner go in `swift-institute/Experiments/`.

| Criterion | Repo |
|-----------|------|
| Depends on one package P | `P/Experiments/` |
| Depends on packages at multiple tiers — one clear highest-layer owner | That owner's `<pkg>/Experiments/` |
| General Swift behavior (language feature, compiler) with no package imports | `swift-institute/Experiments/` |
| Cross-package interaction with no single dep owner (truly cross-cutting) | `swift-institute/Experiments/` |

**Decision rule**: resolve the highest-layer dependency (per [EXP-002c]); that
package's `Experiments/` directory is the home. If the experiment has no
package imports at all, or the cross-package shape has no unambiguous owner,
the home is `swift-institute/Experiments/`. Layer-level containers
(`swift-primitives/Experiments/` etc.) are forbidden per [EXP-002].

**Cross-references**: [EXP-002], [EXP-002c], [EXP-006a]

---

### [EXP-002b] Package Isolation

**Statement**: Each experiment directory MUST contain its own `Package.swift`. The parent package MUST NOT reference experiments as targets, products, or dependencies.

**Cross-references**: [EXP-002], [EXP-003]

---

### [EXP-003] Minimal Package Structure

**Statement**: Experiment packages MUST contain only what is needed to verify the behavior. No unnecessary files, dependencies, or complexity.

```text
Experiments/sendable-closure-test/
├── Package.swift
└── Sources/
    └── main.swift
```

**Cross-references**: [EXP-003a], [EXP-003b]

---

### [EXP-003a] Package.swift Template

**Statement**: Package.swift MUST specify minimum configuration. Experiments MUST use Swift 6.3 and v26 platforms. Only include Swift settings being tested.

```swift
// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "sendable-closure-test",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "sendable-closure-test",
            swiftSettings: [
                // Only flags being tested
            ]
        )
    ]
)
```

**Cross-references**: [EXP-003], [EXP-003b]

---

### [EXP-003b] main.swift Template

**Statement**: main.swift MUST include a header comment with: purpose, hypothesis, toolchain, platform, result, date.

```swift
// MARK: - Sendable Closure Verification
// Purpose: Verify @Sendable closures compile in Embedded Swift
// Hypothesis: @Sendable attribute is available without runtime
//
// Toolchain: swift-DEVELOPMENT-SNAPSHOT-2026-01-18-a
// Platform: macOS 15.0 (arm64)
//
// Result: CONFIRMED - compiles and links successfully
// Date: 2026-01-19

func takeSendableClosure(_ closure: @Sendable () -> Int) -> Int {
    return closure()
}
let result = takeSendableClosure { 42 }
print(result)  // Output: 42
```

**Cross-references**: [EXP-005], [EXP-006]

---

### [EXP-003c] Output Artifacts

**Statement**: Outputs are ephemeral by default. Capture during execution via `tee`. MUST NOT commit unless the header excerpt is insufficient (multi-page diagnostics, benchmark tables). If committed, use `Outputs/` directory with stable names (`build.txt`, `build-release.txt`, `run.txt`, `build-embedded.txt`).

**Cross-references**: [EXP-003], [EXP-005]

---

### [EXP-003d] Naming Alignment

**Statement**: Directory name, `Package.name`, and executable target name MUST be identical.

**Cross-references**: [EXP-002], [EXP-003]

---

### [EXP-003e] Experiment Index

**Statement**: If `Experiments/` contains 2+ directories, `Experiments/_index.json` MUST exist and is the authoritative index. It MUST contain, for each experiment: `directory`, `category`, `purpose`, `date`, `toolchain`, `status` (from the canonical enum: `CONFIRMED | REFUTED | PARTIAL | SUPERSEDED | CONSOLIDATED | DEFERRED | PENDING | INVESTIGATION | MOVED | FIXED | ANALYSIS | COMPLETE`), optional `statusDetail`, `statusRaw`, `supersededBy`, and `crossRefs`. Consolidated packages use a separate `consolidatedPackages[]` section with `absorbedCount`/`absorbedNote`. Narrative sections (e.g. compiler-bug writeups) use `narrativeSections[]` with `heading` + `body`. Schema: `https://swift-institute.org/schemas/experiments-index-v1.json`.

**Composite:** existence (mechanical) + schema (mechanical) + canonical enum (mechanical) + forbidden-location triple (mechanical).

**Valid index locations**: `_index.json` exists exactly at the two kinds of
`Experiments/` container valid per [EXP-002]:

| Index location | Corresponds to |
|---|---|
| `swift-institute/Experiments/_index.json` | Ecosystem-wide experiments corpus |
| `<pkg>/Experiments/_index.json` | Per-package experiments (e.g. `swift-array-primitives/Experiments/_index.json`) |

Layer-level `_index.json` files (`swift-primitives/Experiments/_index.json`,
`swift-standards/Experiments/_index.json`,
`swift-foundations/Experiments/_index.json`) are forbidden — their parent
containers are forbidden per [EXP-002]. Relocating an experiment per
[EXP-002c] MUST update both the source index (remove the entry) and the
destination index (add the entry) in the same commit wave; when the source is
a layer-level container being retired, the retirement MUST delete the index
file once all entries have been relocated.

The canonical human-browsable view of a public experiments corpus is the [Experiments dashboard](https://swift-institute.org/dashboard/#experiments) on swift-institute.org; it fetches `_index.json` directly at runtime. For private experiment corpora there is no dashboard — consumers read `_index.json` directly (GitHub pretty-prints it) or via tooling that parses the manifest. `_index.md` is forbidden; the markdown table was historically load-bearing but is now strictly redundant with `_index.json`. `_index.json` is the only allowed non-experiment file in `Experiments/`.

**Cross-references**: [EXP-002], [EXP-002c], [EXP-008]

---

### [EXP-005] Execution Protocol

**Statement**: Experiments MUST be built with standard commands and output captured verbatim.

```bash
cd Experiments/sendable-closure-test
mkdir -p Outputs
/Users/coen/Developer/swift-institute/Scripts/swift-build package clean
/Users/coen/Developer/swift-institute/Scripts/swift-build package build 2>&1 | tee Outputs/build.txt
/Users/coen/Developer/swift-institute/Scripts/swift-build package build -- -c release 2>&1 | tee Outputs/build-release.txt
/Users/coen/Developer/swift-institute/Scripts/swift-build package run 2>&1 | tee Outputs/run.txt
```

Output files are working artifacts, NOT committed by default. The main.swift header is the primary evidence record.

**Cross-references**: [EXP-003c], [EXP-006], [EXP-007]

---

### [EXP-006] Result Documentation

**Statement**: Results MUST be documented in the main.swift header immediately after execution.

**Composite:** canonical-enum check (mechanical) + revalidation-line shape (mechanical) + cross-skill memory-update sub-rule (hybrid).

| Outcome | Action |
|---------|--------|
| Confirmed | `Result: CONFIRMED` + evidence ([EXP-006b]) |
| Refuted | `Result: REFUTED` + primary diagnostic line + command |
| Unexpected | Update header, consider filing bug report |
| Limitation | Update header, reference in relevant docs |

For REFUTED: header MUST include (1) primary diagnostic line, (2) command that produced it, (3) pointer to full output only if committed.

**Revalidation verdicts** (applied when re-running the experiment against a newer toolchain, per [EXP-007]): use exactly one of four canonical verdicts for each revalidation line:

| Verdict | Meaning |
|---------|---------|
| `PASSES` | Experiment builds/runs and documented outcome still holds |
| `STILL PRESENT` | Documented bug/limitation is still present — the experiment intentionally fails to compile or produces the documented failure mode |
| `STILL CRASHES` | Documented runtime crash is still reproducible on the new toolchain |
| `FIXED` | Documented expected outcome was crash/failure; observed outcome is clean build/run — the upstream bug has been silently fixed |

Revalidation lines are anchored under the `// Toolchain:`, `// Status:`, or `// Revalidated:` header (per [EXP-007]) with shape `// Revalidated: Swift X.Y.Z (YYYY-MM-DD) — {VERDICT}`. Mechanical awk insertion depends on the anchor existing; see [EXP-007a] header anchor requirement.

**FIXED verdict special handling**: when introducing FIXED for a prior proactive crash reproducer, update `~/.claude/projects/-Users-coen-Developer/memory/swift-6.3-fix-status.md` (or the current compiler-version memory) and sweep the ecosystem for workarounds that can now be removed. Many proactive reproducers never had production workarounds — they existed precisely to detect silent fixes.

**Cross-references**: [EXP-006a], [EXP-006b], [EXP-003b], [EXP-007], [EXP-007a]

---

### [EXP-006a] Documentation Promotion

**Statement**: When results affect Swift Institute packages, findings MUST be promoted to relevant documentation with: rule ID, scope, statement, test package path, toolchain, date.

**Cross-references**: [EXP-006]

---

### [EXP-006b] Confirmation Evidence

**Statement**: If `Result: CONFIRMED`, the header MUST include at least one form of evidence: output snippet (`// Output: 42`), measured value (`// Time: 0.003s`), or compile-time proof (`// Build Succeeded`). Bare "CONFIRMED" without evidence is insufficient.

**Cross-references**: [EXP-006]

---

### [EXP-006c] FIXED-Verdict Retention

**Statement**: An experiment whose Status is `FIXED` per [EXP-006] MUST be retained indefinitely as a regression guard. FIXED is structurally distinct from `SUPERSEDED` and the two MUST NOT be conflated for archival or pruning purposes:

**Composite:** retention rule (hybrid) + index-signaling shape (mechanical) + revalidation cadence (hybrid).

| Status | Meaning | Retention |
|--------|---------|-----------|
| `SUPERSEDED` | Pattern absorbed into production code or skill rule; experiment's standalone signal is redundant with the canonical record | Stays in place; status surfaces through `_index.json`. May be revisited in long-horizon corpus pruning if absorption target becomes ABI-stable + the experiment adds no marginal regression-guard value. |
| `FIXED` | Documented bug/crash no longer reproduces on a newer toolchain | **Indefinite retention**. The experiment's standalone signal is its ability to detect *re*-occurrence of the original failure mode. Pruning a FIXED experiment loses the cheapest available regression witness. |

**Periodic revalidation**: FIXED experiments SHOULD be re-run on each new Swift toolchain (toolchain-triggered revalidation). A FIXED experiment that flips back to STILL CRASHES / STILL PRESENT against a future toolchain is a real-time regression signal — the experiment was always meant to catch exactly this.

**Index-level signaling**: an experiment in `Experiments/_index.json` with `status: "FIXED"` SHOULD include the toolchain stamp in `statusDetail` (e.g., `"FIXED on Apple Swift 6.3.1; revalidate on each new toolchain"`). The `statusRaw` field SHOULD preserve the verdict chain (e.g., `"DEFERRED -> FIXED (Phase 1b 2026-04-30)"`).

**Distinction from SUPERSEDED rationale**: SUPERSEDED experiments derive their continuing value from history — *why* the canonical pattern was chosen — whereas FIXED experiments derive theirs from forward-looking utility — *whether* the upstream fix sticks. Conflating retention policy collapses the distinction and risks pruning the latter as if it were the former.


**Cross-references**: [EXP-006], [EXP-007]

---

### [EXP-006d] FIXED-Verdict Methodological Caveat for Reducers with Unverified Pre-History

**Statement**: When a FIXED verdict ([EXP-006c]) applies to a reducer whose original failure was never empirically reproduced — for example, the reducer's `Package.swift` was rejected by SwiftPM and the minimal program was never compiled to SIL by anyone before today — the verdict line MUST include a "pre-history unverified" caveat. The verdict text "FIXED on Apple Swift X.Y.Z" claims a transition from failing to passing; without a verified failing baseline, the only honest claim is "compiles clean today."

**Composite:** caveat rule (semantic) + verdict-line shape (mechanical) + worked-example mapping (semantic).

**When the caveat fires**:

| Pre-history state | Verdict shape |
|-------------------|---------------|
| Reducer was empirically failing on a prior toolchain (test logs, crash dumps, SIL output) | `FIXED on Apple Swift X.Y.Z; revalidate on each new toolchain` — standard [EXP-006c] form. |
| Reducer's pre-history is unverified (package config blocked compile, original investigation produced no SIL signal, no reproducible failing baseline) | `FIXED on Apple Swift X.Y.Z (pre-history unverified — investigation never produced a verifiable failing signal; today's verdict is "compiles clean," not "regression resolved")`. |
| Reducer's pre-history is partially verified (e.g., crash text recorded but no toolchain stamp, no minimal Package.swift retained) | Treat as unverified for caveat purposes; the burden of proof for "was failing" sits with the writer. |

**Why the distinction matters**: [EXP-006c] retains FIXED experiments as regression guards on the implicit theory that the experiment, when run, witnesses an upstream fix. If the reducer never failed empirically, today's clean compile cannot evidence an upstream fix — only continued absence of failure. The retention rationale ("cheapest available regression witness") still holds; the *transition* claim does not.

**Procedure when adopting [EXP-006d]**:

1. Inspect the experiment's prior history. Look for: failing test log committed to the experiment directory, header line stating the failing toolchain, prior-session reflection citing the empirical failure.
2. If any of those exist: standard [EXP-006c] FIXED verdict — the caveat does NOT fire.
3. If none exist: prepend the caveat to the FIXED line. The audit doc's Disposition Summary MUST also distinguish (e.g., "23 SUPERSEDED, 1 FIXED, 1 FIXED [pre-history unverified]" instead of "23 SUPERSEDED, 2 FIXED").

**Worked example (the origin incident)**:

`bit-packed-crash` was a 2026-Q1 minimal reducer for synthesized-Equatable-on-`~Copyable`-outer-generic. Its `Package.swift` placed `main.swift` inside a `.target` (not `.executableTarget`), which SwiftPM has rejected since tools-version 5.4. The reducer was likely never compiled to SIL by anyone before 2026-04-30. On that date the layout was repaired and the reducer ran clean against Swift 6.3.1. The audit doc initially recorded "FIXED" with the same shape as `equatable-crash` (which had verifiable failing logs). Per [EXP-006d], `bit-packed-crash` should have been recorded as `FIXED on Apple Swift 6.3.1 (pre-history unverified — original Package.swift blocked SIL emission; today's verdict is "compiles clean," not "regression resolved")`.

**Rationale**: An experiment with a FIXED verdict that ships without the caveat reads as evidence of an upstream fix landing. When that evidence chain is broken at the start (no verified failing state), the misread cascades into ecosystem narrative ("Swift 6.3 fixed N bugs") and skill-rule provenance ("[X] cites this experiment as evidence"). The caveat is small, mechanical, and prevents the misread without blocking adoption — the experiment remains retained per [EXP-006c], just with honest framing.


**Cross-references**: [EXP-006c]

---

### [EXP-007a] Header Anchor Requirement

**Statement**: Every experiment's `main.swift` (or library entry file) MUST include at least one canonical header anchor line for revalidation sweeps to attach to. The anchor MUST match the regex `^//[[:space:]]+(Toolchain|Status|Result|Revalidated):` so `/tmp/add-reval.sh` — or equivalent mechanical insertion tooling — can anchor `// Revalidated:` lines idempotently under it.

**Correct** (any one of these anchors is sufficient):
```swift
// Toolchain: swift-6.3.1 (2026-04-17)
// Status: STILL PRESENT (as of Swift 6.3.0)
// Result: CONFIRMED — mutex lock contention measurable at N=1000
```

**Incorrect** (anchor-less):
```swift
// This experiment demonstrates the fsync EINTR retry behavior.
// Original discovery: 2026-02-15.
```

**When the anchor is missing**: mechanical revalidation sweeps either skip the file (leaving it un-revalidated and invisible to future sweeps) or require per-file manual inspection — both expensive at corpus scale. The 2026-04-17 Swift 6.3.1 sweep hit ~15 experiments with no anchor and had to either skip or add headers retroactively under user direction.

**Placement rule cross-reference**: experiment files that are standalone packages (per [EXP-002]) MUST carry the anchor in `main.swift`; library-target experiments MUST carry it in the primary source file where the hypothesis is stated.

**Rationale**: Headers ARE the experiment's interface to future revalidation. An experiment without a Toolchain/Status/Result line is opaque to anyone but its author and briefly at that. Making the anchor mandatory lets revalidation scale mechanically — the sweep becomes uniform across the corpus, which is the precondition for catching silent regressions and fixes ([EXP-006] FIXED verdict).


**Cross-references**: [EXP-002], [EXP-003b], [EXP-006], [EXP-007]

---

### [EXP-002c] Placement by Highest-Layer Dependency

**Statement**: Experiments MUST live in the `Experiments/` directory of their
highest-layer dependency package, where the maintenance owner is the package
owner. Experiments testing general compiler/runtime behavior with no package
dependencies (standalone, compiler-only) belong in `swift-institute/Experiments/`.
**Layer-level `<layer>/Experiments/` containers
(`swift-primitives/Experiments/`, `swift-standards/Experiments/`,
`swift-foundations/Experiments/`) are forbidden** — experiments live either
in-package under `<pkg>/Experiments/` or ecosystem-wide under
`swift-institute/Experiments/`.

**Decision rule**:

| Experiment shape | Location |
|------------------|----------|
| Depends on package P only | `P/Experiments/` |
| Depends on packages `{P1, P2, …}` at mixed tiers | Highest-layer owner among them (tier N+1 > tier N) |
| Depends on multiple packages at the same tier, but one is the clear *domain owner* of the experiment's subject | That domain owner's `<pkg>/Experiments/` |
| Depends on multiple packages at the same tier with no clear domain owner (genuinely cross-cutting) | `swift-institute/Experiments/` |
| Tests spans/buffers/views crossing into a standards package | The standards-package home (e.g., `swift-standards/swift-rfc-4122/Experiments/`) |
| Standalone compiler-behavior repro (no package imports) | `swift-institute/Experiments/` |

**Ambiguity-handling rules**:

- *Multiple same-tier primitives with no clear domain owner* → `swift-institute/Experiments/` (not a layer-level container, which does not exist)
- *Multiple same-tier primitives with a domain owner (e.g. `Property.View` is the subject, experiment also imports Ownership + Tagged)* → the domain-owner's `<pkg>/Experiments/`
- *Primitive + standard* → the standard's home (higher layer owns)
- *Foundation consumer of primitive* → the foundation's home (highest layer owns)

**Applied examples from 2026-04-17 corpus sweep**:

- `actor-state-inline-fallback-repro` moved `swift-io/Experiments/` → `swift-institute/Experiments/` (tests general compiler behavior, not swift-io)
- `declarative-parser-typed-throws` moved `swift-institute/Experiments/` → `swift-parser-primitives/Experiments/` (depends on parser-primitives)
- `array-totality-patterns` moved (renamed from `api-totality-design`) to `swift-array-primitives/Experiments/` (API surface is Array, even though only imports Index_Primitives — design owner wins over import list)

**Post-dismantle anti-pattern + correction (2026-04-24 superrepo dismantle)**:

Before 2026-04-23, `swift-primitives`, `swift-standards`, and `swift-foundations` were git superrepos that owned layer-level `Experiments/`, `Research/`, `Audits/`, and `Documentation.docc/` containers. When those superrepos were dismantled (`rm -rf .git`), the layer-level artifact containers became orphan content — files previously tracked by the container's own `.git` with no version-control home. 49 experiments across three containers had to be relocated. This skill now codifies the rule forward: layer-level containers are permanent anti-patterns regardless of whether a future umbrella is reintroduced. Cross-cutting experiments go ecosystem-wide; per-package experiments go to the highest-layer dep's own repo.

**Worked example — orphan triage (2026-04-24)**:

| Experiment at `swift-primitives/Experiments/X/` | Package.swift deps | Correct destination |
|---|---|---|
| `borrowing-foreach-view-read` (no imports) | — | `swift-institute/Experiments/` |
| `bounded-index-preconditions` (imports `Index Primitives`) | single package at T6 | `swift-index-primitives/Experiments/` |
| `double-tagged-bounded-index` (imports `Index T6 + Finite T8`) | mixed-tier | `swift-finite-primitives/Experiments/` (T8 > T6) |
| `property-view-ownership-inout-factoring` (imports Ownership T0 + Tagged T0 + Property T0) | same-tier, clear domain owner = Property.View | `swift-property-primitives/Experiments/` |

**Rationale**: Co-location follows dependency, not topic. Experiments depending on P are maintained by P's owner, build against P's current API, and revalidate in sync with P's evolution. Topic-based placement (authoring-session-based) creates orphan experiments whose build breaks when the depended-on package drifts, with no maintenance signal to anyone. Layer-level containers specifically concentrate orphan risk because when the layer container is dismantled (as happened 2026-04-23), every experiment in that container becomes orphan simultaneously.


**Cross-references**: [EXP-002], [EXP-002a], [EXP-002b], [EXP-003e]

---

### [EXP-007] Toolchain Specification

**Statement**: Results MUST record exact toolchain. Development snapshots MUST include snapshot date.

```swift
// Toolchain: swift-DEVELOPMENT-SNAPSHOT-2026-01-18-a
// Platform: macOS 15.0 (arm64)
// Xcode: 16.2
```

**Cross-references**: [EXP-005], [EXP-006]

---

### [EXP-008] Experiment Package Lifecycle

**Statement**: Experiments are persistent and git-tracked. Lifecycle: Active → Documented → Referenced → Superseded → Archived (optional, `_archived/` directory).

When superseded, add header note with reason and link to replacement. Git history provides: historical record, collaboration, discoverability, bisection capability.

**Cross-references**: [EXP-002], [EXP-006a]

---

### [EXP-009] Multi-Variant Testing

**Statement**: Multiple related scenarios SHOULD be organized in clearly delimited `MARK` sections with individual results.

```swift
// MARK: - Variant 1: Basic Sendable
// Hypothesis: Basic Sendable struct compiles
// Result: CONFIRMED

struct V1: Sendable { let value: Int }

// MARK: - Variant 2: Sendable with closure
// Hypothesis: Sendable with @Sendable closure compiles
// Result: CONFIRMED

struct V2: Sendable { let action: @Sendable () -> Void }

// MARK: - Results Summary
// V1: CONFIRMED
// V2: CONFIRMED
```

For complex variants, use multi-file organization with `Variant1_*.swift` files.

**Cross-references**: [EXP-003], [EXP-006]

---

### [EXP-010] Common Experiment Patterns

**Statement**: Experiments SHOULD follow established templates for common types.

**Cross-references**: [EXP-003b], [EXP-006]

---

### [EXP-010a] Feature Availability Test

Template for "Does {feature} compile with {configuration}?": Purpose, hypothesis, toolchain → minimal code using feature → build command → expected result (Build Succeeded / specific error).

---

### [EXP-010b] Runtime Behavior Test

Template for "What does {operation} actually do?": Purpose, hypothesis, toolchain → test function with explicit `print("Input: ...")` and `print("Output: ...")` → run command → expected vs actual output.

---

### [EXP-010c] Error Message Discovery

Template for "What error does {invalid code} produce?": Purpose, hypothesis, toolchain → intentionally invalid code → build command → captured exact diagnostic text verbatim.

---

### [EXP-010d] Configuration Comparison

Template for "Does {behavior} differ between debug and release?": Purpose, hypothesis, toolchain → test code → run coordinator-owned package builds for both debug and release configurations → document debug result, release result, and any differences.

---

## Discovery Workflow (Proactive)

**Entry point**: Audit a package, verify claims, or systematically explore behavior.

### [EXP-012] Discovery Triggers

**Statement**: A discovery experiment SHOULD be created when proactive verification would increase confidence, document evidence for claims, or identify improvements.

| Category | Priority |
|----------|----------|
| Package milestone (v1.0) | High |
| Toolchain update | High |
| Assumption audit | Medium |
| Claim verification | Medium |
| Boundary exploration | Medium |
| Cross-package verification | Medium |
| Improvement hypothesis | Low |

**Discovery vs Investigation**: Investigation starts from broken code to fix it. Discovery starts from working code to verify it.

**Cross-references**: [EXP-001], [EXP-002a]

---

### [EXP-013] Package Audit Methodology

**Statement**: Package audits MUST follow: (1) Inventory public types/APIs, (2) Extract testable claims from docs/comments, (3) Identify implicit assumptions, (4) Prioritize by risk, (5) Generate experiments, (6) Execute, (7) Document.

**Composite:** 7-step procedure (hybrid) + ID-scheme (mechanical) + risk × importance ranking (hybrid).

Claims use `[CLAIM-XXX]` IDs. Assumptions use `[ASSUMP-XXX]` IDs. Prioritize by risk × importance (P0/P1/P2).

**Cross-references**: [EXP-014], [EXP-015], [EXP-016]

---

### [EXP-014] Assumption Inventory

**Statement**: Implicit assumptions MUST be inventoried before creating experiments. Examine: type constraints, memory semantics (~Copyable, ownership), concurrency (Sendable, isolation), platform requirements, performance claims, compiler feature dependencies.

Each assumption becomes an experiment hypothesis. Extract from code patterns like `consuming func` (assumes move semantics), optional returns (assumes empty state valid), `@unchecked Sendable` (assumes thread safety by construction).

**Cross-references**: [EXP-013], [EXP-015]

---

### [EXP-015] Claim Verification

**Statement**: Testable claims in documentation SHOULD be verified through experiments.

| Category | Verification Method |
|----------|---------------------|
| Complexity | Benchmark with varying input sizes |
| Conformance | Compile-time check |
| Behavior | Runtime test with assertions |
| Compatibility | Cross-version compilation |
| Interoperability | Integration test |

**Cross-references**: [EXP-013], [EXP-014]

---

### [EXP-016] Boundary Exploration

**Statement**: Boundary experiments SHOULD test: empty states, capacity limits, type extremes, overflow/underflow, error paths, concurrency contention.

Test boundaries systematically: collection sizes (empty, one, many, max), numeric limits (min, max, overflow), string edge cases (empty, unicode), optional states, all error paths, concurrency levels.

**Cross-references**: [EXP-013], [EXP-009]

---

### [EXP-019] Improvement Discovery

**Statement**: When a potential improvement is identified, an experiment SHOULD test it with baseline comparison.

Template: Purpose, hypothesis, baseline measurement → current implementation → proposed implementation → benchmark comparison → evidence (baseline vs proposed).

| Evidence | Decision |
|----------|----------|
| Significant improvement, no regression | Recommend adoption |
| Marginal improvement, added complexity | Document, defer |
| No improvement | Document, do not adopt |
| Regression in some cases | Document tradeoffs |

**Cross-references**: [EXP-013], [EXP-015]

---

### [EXP-017] Release-Mode + Cross-Module Validation for Adoption Experiments

**Statement**: Experiments whose CONFIRMED verdict would admit production adoption of a language feature, pattern, or workaround MUST be validated in release mode AND across a module boundary (a second target in the same package or a sibling test package importing the first). Single-module debug passes are insufficient evidence to promote a design-adoption experiment to CONFIRMED.

**Composite:** dual-file existence (mechanical) + status-gate rule (mechanical).

**Why both dimensions**:

1. **Release mode**: Debug-only passes routinely hide SIL-level bugs that only fire when optimization enables code paths (CopyPropagation, CopyToBorrowOptimization, specialization). An experiment that proves a pattern safe in debug and unsafe in release is failed evidence of safety, dressed up as success.
2. **Cross-module**: Same-module passes hide access-control and SIL-emission effects that depend on `package` vs `public` or on serialization. An experiment that works within one target and fails across a module boundary has not validated the design consumers will use.

**Procedure additions to [EXP-003]**:

1. Add a `release-mode-pass.txt` receipt file capturing `/Users/coen/Developer/swift-institute/Scripts/swift-build package build -- -c release` output.
2. Add a `cross-module-pass.txt` receipt file capturing build output from a sibling target that imports the experimental API.
3. Only upon both passing does the experiment advance to CONFIRMED.

**Rationale**: The 2026-04-21 property-consuming-value-state experiment and the `sendnonsendable-iife-borrowing-init-crash` reducer both exhibited the gap — single-module debug passes suggested safety; release mode and cross-module tests surfaced the failure. The rule moves the discovery to the experiment phase, where it is cheap, rather than to the consumer-migration phase, where it is expensive.


**Cross-references**: [EXP-003], [EXP-003a], [EXP-017a]

---

### [EXP-017a] Matrix Disambiguation for #if-Gated Probes

**Statement**: When an experiment validates an `#if`-conditional production mechanism (e.g., a typealias whose underlying type differs per platform, a function whose body branches on `#if os()`, or any compile-time-selected pathway whose downstream behavior is leg-dependent), the empirical result-table MUST enumerate `{selected-leg, else-leg}` as a first-class axis alongside `{build mode}` and `{module shape}` per [EXP-017]. A row reading "cross-module debug + release" without leg-disambiguation understates coverage when the cross-module variant on a single host only exercises whichever leg the literal `#if` selects.

**Composite:** mechanism-detection (hybrid) + matrix-shape (mechanical) + canonical-restoration (mechanical).

**Procedure**:

1. **Identify** whether the probe's mechanism includes any `#if` branch selecting different underlying types or behaviors.
2. **For each `{build mode} × {module shape}` cell** in the matrix, run the experiment twice: once with the literal `#if` (selected leg, exercising whichever branch the host platform satisfies), and once with the `#if` inverted to force the else branch on-host.
3. **Restore** the literal `#if` after the inverted run; verify the canonical state before reporting closure.
4. **Capture** both legs in the result-table as separate rows per cell. The minimum disambiguated matrix when all three axes are relevant has shape `{single-module, cross-module} × {debug, release} × {selected-leg, else-leg}` = 8 cells.

**Why the leg-axis is structural, not retrospective**: A probe that gates an `#if`-conditional production mechanism inherently has a `{selected-leg, else-leg}` axis. On a single host the literal `#if` exercises one leg only; the else leg requires inverting the `#if` to force on-host. Treating the leg-axis as first-class at table-design time makes gap-detection structural — the matrix-shape reveals the gap before publication. Without it, a result-table row reading "covered debug + release" implicitly conflates "covered for the selected leg only" with "covered for both legs," a partial truth that downstream readers can read past.

**Worked example (the origin incident)**:

A 2026-04-26 typealias-probe sandbox validated whether `~Copyable` typealiases of distinct per-platform `~Copyable` types compose with extension methods declared once on the typealias name. The probe gated an L1-to-L3 type-placement migration (relocating divergent-shape types off the shared vocabulary layer). Initial §6.2.1 result-table reported "Cross-module debug + release green" — true for the literal-`#if` selected leg (A-leg on the host platform) but silently uncovered for the else leg (B-leg). Re-derivation from primary source revealed three B-leg gaps, not one. Three additional inverted-`#if` passes closed the matrix from 5/8 to 8/8, yielding an evidence-only v1.1.0 → v1.1.1 doc bump.

**Relationship to [EXP-017]**: [EXP-017] mandates two axes (build mode, module shape) for adoption-experiment validation. [EXP-017a] (this rule) adds the third axis when the experiment's mechanism is `#if`-gated. The two rules compose: `#if`-gated adoption experiments have a 2×2×2 minimum matrix, not 2×2.

**Rationale**: Result tables are claims about experimental evidence, not the evidence itself. Verifying claims against primary sources is the correction-from-primary-source discipline. Detecting under-specified claims at the table-design phase — *before* publication — requires explicit matrix-axis enumeration. The cost is one additional run per cell (typically 4 extra passes on an 8-cell matrix); the benefit is closing a class of silent under-coverage that supervisor pushback or downstream readers will otherwise surface retrospectively.


**Cross-references**: [EXP-017], [EXP-009]

---

### [EXP-020] Claim Validation Trap — Synthetic-to-Production Extrapolation

**Statement**: Minimal reproductions validate that a bug EXISTS. They do NOT validate which production code paths are AFFECTED. Synthetic reproducer claims about production-code impact MUST be validated by package-level regression tests in each cited target package before extrapolation. Without per-target empirical verification, "the reproducer shows the pattern in production X" is unverified extrapolation.

**Composite:** 5-step procedure (hybrid) + walkback shape (hybrid) + status-relabel chain (mechanical).

**Relationship to [EXP-011]**: [EXP-011]'s "Workaround validation trap" rule states that minimal reproductions cannot validate workarounds at scale. [EXP-020] is the dual: minimal reproductions cannot validate claims at scale either. Both directions — workaround AND claim — require package-level testing on the production shape. [EXP-011] catches claims about which fixes work; [EXP-020] catches claims about which production sites break.

**Procedure** (mirrors [EXP-011]'s workaround-validation discipline):

1. Construct the minimum failing reproducer (per [EXP-004] reduction methodology).
2. Identify the candidate production consumers (grep for the call pattern, the ownership shape, the type combination).
3. For each cited consumer, write a package-level regression-guard test exercising the consumer's production shape under release mode. Wrap initial tests in `withKnownIssue` so CI stays green during the investigation phase.
4. Run each regression-guard test:
   - **PASSED**: the production shape evades the bug. Cascade claim refuted for that consumer; the stripped feature in the reproducer is a load-bearing structural discriminator.
   - **FAILED**: the production shape exhibits the bug. Cascade claim verified; the consumer is genuinely affected.
5. Only after each regression-guard test fails empirically may the production-impact claim ship as durable doctrine (audit finding, shipping HOLD, ecosystem sweep, etc.).

**Walkback procedure when claims invert**:

When regression-guard tests pass on production shapes (cascade claim refuted):
- Convert each `withKnownIssue` wrapper to a positive-assertion regression guard.
- Commit each test as durable regression coverage in the target package.
- Downgrade the audit finding from HIGH to LOW (watchflag).
- Restore the package's shipping scope to NORMAL.
- Retain the synthetic reproducer in the experiment for upstream filing; mark its status as "narrow-shape; production unaffected pending V13 discriminator-isolation experiment."

**Worked example (the origin incident)**:

V10/V11 narrow-shape reproducer (`@inlinable + withUnsafePointer(to: borrowing _storage) + ~Copyable container`) triggered SIGTRAP cross-module. Initial extrapolation: "Memory.Inline.pointer(at:) is therefore broken in production" → Finding #12 HIGH/HOLD on three packages.

Step 4 in-package release-mode tests:
- swift-memory-primitives: `Memory.Inline<Int, 4>.pointer(at:)` stability → **PASSED**
- swift-buffer-primitives: `Buffer.Ring.Bounded.peek.front/back` → **PASSED**
- swift-async-primitives: `Async.Timer.Wheel` cross-module reads → **PASSED**

3/3 production shapes evaded the bug. The structural discriminator (`@_rawLayout(likeArrayOf: Element, count: capacity)` + generic Element + stride arithmetic) was load-bearing. Finding #12 inverted to LOW/watchflag (commit `64f8362`); regression guards retained as positive-assertion tests (commits `e390d7a`, `92e53fe`, `26e76e1`).

**Three empirical passes on three different production shapes is a much stronger signal than N synthetic variants**. The in-package tests are the load-bearing artifact: they force the experimenter to construct the production shape, which exposes whether the extrapolation holds. The synthetic reproducer narrows the bug; only the production-shape test can refute the cascade claim.


**Cross-references**: [EXP-004], [EXP-011], [EXP-011a], [EXP-017], [EXP-017a], [ISSUE-025]

---

### [EXP-021] One-Factor-At-A-Time at the Reduction-to-Trigger-Narrowing Boundary

**Statement**: When a variant shows "could-not-reproduce" and the next variant is intended to find the trigger, the next variant MUST add exactly one new structural factor from the candidate set — not a leap to the full real dependency graph. Reinforces [EXP-004a]'s "add complexity one feature at a time" principle at the specific reduction-to-trigger-narrowing boundary, where the rule is most often violated.

**The failure mode**: a CAN'T-REPRODUCE → CAN-REPRODUCE jump skips the trigger-isolation step. The variant that reproduces the bug confirms it exists somewhere in the delta between the two variants, but if the delta is multiple factors (different storage class, different protocol conformance, different generic constraint, different containing structure), the trigger remains unidentified. Subsequent V12-style "fixes" then patch a guess at which factor is the trigger; if the guess is wrong, the fix is structurally incorrect even though it appears to work locally.

**Procedure**:

1. After a CAN'T-REPRODUCE variant, enumerate the structural factors that differ between the variant and the production failure case.
2. The next variant adds exactly ONE of those factors — not "all the missing factors at once."
3. If the next variant reproduces, the added factor is the trigger (or part of it). If it doesn't, repeat with one more factor added.
4. Only after the trigger is structurally isolated should the fix be designed.

**Worked example (the origin incident)**:

A 2026-04-23 property-view-lifetime-escape investigation jumped V2 (parallel primitives + conditional Copyable) → V3 (real Buffer.Ring with Storage<Element>.Heap). V2 was CAN'T-REPRODUCE, V3 was CAN-REPRODUCE — but the delta included multiple factors (real Buffer.Ring vs parallel; class-backed Storage.Heap; conditional Copyable in real types vs parallel). V12's fix worked, but the structural trigger remained ambiguous. Action item from the reflection proposed adding V2.5 (parallel + class-field) and V2.6 (parallel + conditional-Copyable-via-extension) to isolate which factor trips the lifetime checker; that's the structurally-correct narrowing path.

**Rationale**: [EXP-004a] codifies "add complexity one feature at a time" generally; [EXP-021] (this rule) names the specific boundary where it's most often violated — when the variant that doesn't reproduce gives way to the variant that does, the temptation to ship the working variant overrides the discipline of isolating which factor mattered. Without trigger isolation, fixes become guesses at which factor was load-bearing; the next regression in the same family produces another fix with no shared structural understanding.


**Cross-references**: [EXP-004a], [EXP-011a]

---

## Cross-References

See also:
- **research-process** skill for design analysis workflows
- **blog-process** skill for publishing findings
- **implementation** skill for [COPY-FIX-*] ~Copyable constraint patterns (often triggers experiments)

---

### [EXP-022] Experiment Placement by Highest-Layer Dependency

**Statement**: An experiment with package dependencies MUST live in the `Experiments/` directory of its **highest-layer dependent package**. An experiment with no package dependencies (compiler-only or genuinely cross-cutting) MUST live in `swift-institute/Experiments/`. Layer-level `Experiments/` containers (`swift-primitives/Experiments/`, `swift-standards/Experiments/`, `swift-foundations/Experiments/`) are FORBIDDEN.

**Placement rule** (highest layer wins):

| Dependency profile | Location |
|---|---|
| Single package P | `P/Experiments/` |
| Mixed-tier deps | Highest-layer owner (e.g., Index T6 + Finite T8 → `swift-finite-primitives/Experiments/`) |
| Same-tier with clear domain owner | That owner's `<pkg>/Experiments/` (e.g., Ownership + Tagged + Property when subject is `Property.View` → `swift-property-primitives/Experiments/`) |
| Same-tier with no clear owner (genuinely cross-cutting) | `swift-institute/Experiments/` |
| No package deps (compiler-only / standalone) | `swift-institute/Experiments/` |

**Why**: co-located experiments stay in sync with the package's API as it evolves; orphaned cross-repo experiments rot into "drift" bugs. The rule also makes the maintenance owner obvious — whoever owns the package owns its experiments.

**Why layer-level containers are forbidden**: when the three superrepos (`swift-primitives`, `swift-standards`, `swift-foundations`) were dismantled 2026-04-23 (`rm -rf .git`), every artifact in their layer-level `Experiments/` became orphan content simultaneously (~48 experiments). The post-dismantle triage established this as a permanent anti-pattern regardless of whether umbrella packages are reintroduced — the orphan-risk concentration is the structural problem.

**How to apply**:

1. Before creating an experiment, identify the highest-layer dep; that package's `Experiments/` is the home.
2. With no deps / genuinely cross-cutting: `swift-institute/Experiments/`.
3. When inheriting an experiment with stale layer-level-container placement, relocate per the rule. Path-deps require rewriting:
   - From `<layer>/Experiments/X/` to `<layer>/swift-Y/Experiments/X/`
   - `../..` resolves to the umbrella, which is now the package itself
   - Sibling-package deps rewrite to `../../../swift-Z-primitives` (3 levels up)
   - Reference precedent: `swift-ownership-primitives/Experiments/` (commit `992eb03`+)

**Cross-references**: [EXP-002], [EXP-002c], [EXP-003e], [RES-002a]
