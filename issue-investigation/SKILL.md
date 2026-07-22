---
name: issue-investigation
description: |
  Systematic investigation of compiler and toolchain issues: reproduce, reduce, verify, resolve.
  Apply when encountering a compiler crash, SIL verification failure, miscompile, or
  unexpected toolchain behavior that blocks development.

layer: process

requires:
  - swift-institute-core
  - experiment-process

applies_to:
  - compiler-issue
  - toolchain-issue
  - silgen-bug
  - sil-optimizer-bug

last_updated: 2026-07-05
---

# Issue Investigation

Systematic workflow for investigating compiler and toolchain issues. Designed to minimize
wasted effort by front-loading cheap checks before expensive analysis.

The ordering of steps reflects empirical cost: checking the dev toolchain (30s)
has prevented hours of unnecessary compiler source analysis in multiple sessions.

---

## Step 0: Classify the Issue

### [ISSUE-010] Bug Classification

**Statement**: Before investigation, classify the issue into one of five categories. The category determines the investigation strategy and the kind of evidence needed.

| Category | Description | Evidence Needed |
|----------|-------------|-----------------|
| **ICE/Crash** | Compiler itself crashes (signal, assertion, verifier) | Stack trace, reproducer, SIL dump |
| **Miscompile** | Compiles but produces wrong output | Expected vs actual output, optimization level |
| **Rejects-valid** | Correct code rejected with error | Code sample, expected behavior, diagnostic ID |
| **Accepts-invalid** | Incorrect code accepted without error | Code sample, spec reference |
| **Diagnostic** | Confusing or incorrect error message | Diagnostic text, `-debug-diagnostic-names` output |

**Crash/ICE** and **Miscompile** follow the full pipeline below (Steps 1-6). **Rejects-valid**, **Accepts-invalid**, and **Diagnostic** skip SIL analysis (Step 3) and focus on type checker (`-debug-constraints`) or diagnostic investigation (`-debug-diagnostic-names`).

**Rationale**: Adopted from GCC, LLVM, Rust, and GHC -- all four ecosystems use this taxonomy. Explicit classification prevents applying crash-investigation techniques to diagnostic issues and vice versa.

---

## Step 0.5: Check Recent SE Proposals

### [ISSUE-020] SE-Proposal Constraint Check

**Statement**: When an issue appears on a newer compiler version (e.g., 6.4-dev) that worked on the previous version, check whether recent Swift Evolution proposals changed protocol constraints before pursuing a compiler-regression investigation.

**Key signals**:
- Multiple different workarounds all fail with the same class of error (e.g., "requires Copyable")
- Standalone reproducer compiles clean — the issue only appears in production with specific generic constraints
- The error diagnostic names a constraint that wasn't explicitly written in the code

**Check procedure**:
1. Identify which protocol constraint the error message references
2. Search Swift Evolution proposals for changes to that protocol's implicit requirements
3. Test whether adding the explicit inverse constraint (e.g., `& ~Copyable`) resolves the issue

**Example**: SE-0499 removed implicit `Copyable` from `Comparable`/`Equatable`/`Hashable`. Extensions using `where T: Comparable` gained implicit `T: Copyable` via backwards compatibility. Adding `& ~Copyable` to the extension constraint resolves the issue — it's a semantic change, not a compiler bug.

**Rationale**: The issue-investigation skill's reproducer step ([ISSUE-002]) assumes bugs are in the compiler. When the real cause is a language evolution change removing an implicit guarantee, no standalone reproducer can trigger it. This check prevents multi-hour investigation of "compiler regressions" that are actually correct enforcement of new semantics.

**Cross-references**: [ISSUE-010], [ISSUE-001]


---

## Step 0.75: Surface Shape Constraints Before Designing

### [ISSUE-022] Ask Before Designing the Fix

**Statement**: When an issue investigation will produce a design proposal (not just a reproducer or a tactical workaround), the investigating agent MUST surface the user's *shape* preference for the fix before drafting the proposal. A fix-shape preference is distinct from the constraint list given in the brief — briefs typically enumerate forbidden approaches (no atomics, no existentials, typed throws required) but rarely enumerate aesthetic preferences (additive vs subtractive, runtime vs compile-time, new types vs deletion).

**Clarifying-question axes**:

| Axis | Options | Example question |
|------|---------|------------------|
| Additive vs subtractive | Add new types / methods vs remove existing ones | "Should the fix introduce new types, or should it remove/relocate existing state?" |
| Runtime vs compile-time | Atomics / checks at runtime vs type-system invariants | "Are runtime checks acceptable, or must the invariant be compile-time?" |
| New types vs relocation | Introduce new primitives vs move existing ones | "Do you prefer new primitives for this, or refactoring existing ones?" |
| Workaround vs refactor | Localized patch vs structural change | "Is a localized workaround acceptable for this release, or do we want the structural fix now?" |

**Procedure**: Ask one clarifying question that narrows the design space before writing more than a paragraph of proposal. The question should present two or three shape-options so the user's answer is a recognition task, not a composition task.

**Example (correct)**:
```
Brief says: "Design a structural fix. No atomics, no nonisolated(unsafe),
             no existentials. Type-system enforced."

Before writing: "Before I draft this — are you picturing (a) new types
                 that encode the invariant (e.g., ~Copyable tokens),
                 (b) removing the field entirely and accepting a looser
                 contract, or (c) something else? I can take either
                 direction, but they lead to very different proposals."
```

**Example (defect)**:
```
Brief says: "Design a structural fix. No atomics, no nonisolated(unsafe),
             no existentials."

Agent writes: 32 KB proposal introducing ~Copyable AdmissionSlip type
              plus Synchronization atomics on Loop.

User rejects in under a sentence: "I'd rather NOT add new checks,
                                    and instead fix the structure."

Proposal is discarded. 90% of the design work was wasted on a shape
the user was never going to accept.
```

**Applies when**:
- The brief asks for a "design proposal" or "structural fix"
- The investigation produces a writeup larger than ~500 words
- Multiple reasonable shapes exist and the brief does not explicitly rule any in or out

**Does not apply when**:
- The fix is a localized tactical workaround ([ISSUE-008] "apply workaround, document")
- The bug has a single obvious shape (e.g., compiler fix matching a TODO comment)
- The brief explicitly prescribes the shape ("add a new case to the enum", "delete the field")

**Rationale**: The 2026-04-08 swift-io actor-state investigation produced a 32 KB proposal (`~Copyable AdmissionSlip`) that was rejected with one sentence because the user wanted *deletion*, not *addition*. The brief's explicit constraints (no atomics, no existentials, type-system enforced) were satisfied by the proposal — what the proposal missed was an implicit shape preference. A 30-second clarifying question would have redirected the effort before the 32 KB was written. Surfacing aesthetic constraints up front is the lowest-cost insurance against proposal-shape mismatch.


**Cross-references**: [ISSUE-010] Bug Classification, [ISSUE-008] Resolution Paths

---

## Step 1: Verify Against Latest Toolchain

### [ISSUE-001] Check Dev Toolchain First

**Statement**: Before ANY investigation, the issue MUST be tested against the latest available Swift development toolchain. If the issue does not reproduce, it is already fixed upstream — stop investigation.

```bash
# Test with installed dev toolchain:
TOOLCHAINS=swift xcrun swiftc -O reproducer.swift -o /tmp/test 2>&1

# Or via SwiftPM:
TOOLCHAINS=swift /Users/coen/Developer/swift-institute/Scripts/swift-build package build -- -c release
```

**If it passes on dev**: Record the finding ("fixed in 6.x-dev"), apply a source-restructuring workaround for current Xcode (never `@_optimize(none)` or other optimization-suppressing attributes — forbidden per [ISSUE-008]), and move on. No issue or PR needed.

**If it fails on dev**: Proceed to Step 2.

**"Blocked by unrelated crash" is not evidence of distinctness**: If a dev-toolchain build fails due to an unrelated crash (e.g., DeinitDevirtualizer ICE blocks the superrepo build), that does NOT prove the issue under investigation is distinct from a known fix. Use a standalone reproducer ([ISSUE-002]) to bypass the blocker and test the specific trigger pattern on the dev toolchain. Concluding "distinct" from inability to test is an absence-of-evidence fallacy.

**Rationale**: This is the single highest-ROI check. In the 2026-03-31 session, hours were spent investigating a CopyPropagation crash that was already fixed in Swift 6.4-dev (swiftlang/swift#85743). A 30-second toolchain check would have prevented the entire deep-dive.

---

## Step 2: Create Minimal Reproduction

### [ISSUE-002] Standalone Reproducer

**Statement**: A reproducer MUST compile with `swiftc` directly (no SwiftPM). It MUST be a single `.swift` file. It MUST crash or fail without any project structure, dependencies, or build system.

```bash
# The gold standard: single file, single command
swiftc reproducer.swift -o /tmp/test
# or
swiftc -O reproducer.swift -o /tmp/test
```

**If the issue requires SwiftPM** (WMO, multi-module): document this as a constraint, but continue trying to reduce to `swiftc`.

**Rationale**: `swiftc`-reproducible bugs are unambiguous. SwiftPM-only bugs can be conflated with build system behavior, caching artifacts, or dependency interactions.

---

### [ISSUE-003] Reduction Protocol

**Statement**: Reduce per [EXP-004] with ONE critical addition: **every reduction step MUST use a clean build**. For SwiftPM reproducers, run `swift-build package clean` and verify its exit status before the coordinator-owned build; never delete `.build` directly.

**Reduction order** (remove one element per step, verify crash persists):
1. Remove async/await, closures, actors
2. Remove framework dependencies (Synchronization, Dispatch, etc.)
3. Remove class wrappers — use structs or top-level code
4. Remove protocol conformances (Sendable, Equatable, etc.)
5. Remove generic parameters — use concrete types
6. Remove extra enum cases — try single-case
7. Remove extra tuple fields
8. Remove function wrapping — try top-level code
9. Remove SwiftSettings (strictMemorySafety, experimental features)

**At each step**: If removal eliminates the crash, that element is REQUIRED — restore it and continue reducing other elements.

**Stale build trap**: If a coordinator-owned clean/build result contradicts the reduction, test the standalone file with `swiftc` directly to separate SwiftPM state from compiler behavior.

**Rationale**: The 2026-03-31 investigation produced multiple false reductions because direct generated-state deletion silently failed, leaving stale artifacts from earlier variants. Every "crash" in the reduction series was actually running against cached SIL from the first successful reproduction. Coordinator-owned cleaning removes that unmanaged failure mode.

---

### [ISSUE-004] Required Ingredient Verification

**Statement**: After reduction, each remaining element MUST be independently verified as necessary. For each element, remove ONLY that element and rebuild from clean. If the crash disappears, that element is required. If the crash persists, remove it permanently.

**Document the ingredient list**:
```markdown
Required ingredients (removing any one makes it pass):
1. Generic ~Copyable enum (non-generic passes)
2. Tuple payload with trivial field (single-payload passes)
3. Consuming switch destructuring (borrowing passes)
```

**Rationale**: Systematic ingredient verification prevents over-reduction (removing something that happens to coincide with the fix) and under-reduction (keeping unnecessary elements).

---

## Step 3: Diagnose

### [ISSUE-023] Debug-Prints-First Ladder for Release-Mode-Only Bugs

**Statement**: When debug mode passes and release mode fails, the first diagnostic tool MUST be `print()` statements on the suspect code path, NOT source-reading or SIL inspection. Theorizing about what the compiler *might* do with optimizations is strictly worse than observing what the binary *actually* does. Only after prints confirm the divergence point should source-reading or SIL analysis begin.

**The ladder** (ascending cost, descending need for creativity):

| Step | Tool | Cost | Signal |
|------|------|------|--------|
| 1 | `print()` statements on suspect path | ~90 seconds (edit + rebuild) | Definitive — observes ground truth values and control flow |
| 2 | Minimal standalone experiment | ~30 minutes | Confirms the bug is in Swift/compiler, not our code |
| 3 | `-emit-sil -O` inspection | ~1 hour | Definitive on compiler output |
| 4 | Compiler source reading per [ISSUE-012] | hours | Root cause in the optimizer |

**Procedure**: Start at step 1. Advance only when the current step's signal is insufficient for the next action. Skipping step 1 to start at step 3 or 4 is the anti-pattern this requirement prevents.

**What to print**:
- Entry/exit of the suspect function (confirms control flow reached the site)
- Values of fields read or written at the suspect operation (confirms state)
- Thread or executor identity if cross-thread visibility is suspected (confirms isolation)
- Timestamps or sequence counters if ordering is suspected (confirms happens-before)

**Example (correct)**:
```
Symptom: three shutdown tests fail in release, pass in debug.
Step 1: Add three prints to Runtime.shutdown() and Runtime.register():
        DEBUG: shutdown called, state = running
        DEBUG: shutdown set state = .shuttingDown
        DEBUG: register called, state = running   ← stale read
Diagnosis time: 90 seconds. The output pins the visibility failure
to the cross-thread read after shutdown joined the executor.
```

**Example (defect)**:
```
Symptom: three shutdown tests fail in release, pass in debug.
Step 3 (skipped 1+2): Read Runtime source, theorize about lost-wakeup
race between drainJobs and poll. Confidently call it a bug.
20 minutes later: realize the kernel buffers EVFILT_USER until consumed,
closing the window. Theory was wrong. Walk it back.
Net effect: 20 minutes of wasted time + degraded user trust + original
bug still undiagnosed.
```

**Why release-mode-only bugs specifically**: the debug/release divergence narrows the suspect space to (a) compiler optimization, (b) memory ordering, or (c) UB that debug builds happen to hide. None of those three is visible from source reading — the source is the same in both modes. Only observed binary behavior distinguishes them.

**Rationale**: The 2026-04-07 swift-io session spent ~20 minutes source-reading and building theories about why the admission check wasn't catching shutdown. Three `print()` statements immediately revealed that `Runtime.register()` was reading `state = running` after `Runtime.shutdown()` had written `state = .shuttingDown`. The cost of prints (90s) vs the cost of theorizing (20min+) makes prints the correct first reach — and the print output pinned the cross-thread visibility failure more precisely than any source-reading could have.


**Cross-references**: [ISSUE-005] SIL Dump Analysis, [ISSUE-006] Hypothesis Discipline, [ISSUE-013] Variable Isolation for Context-Sensitive Bugs

---

### [ISSUE-005] SIL Dump Analysis

**Statement**: For SIL-level bugs (CopyPropagation, ownership verification, etc.), dump the SIL around the failing pass to identify the exact instruction sequence.

```bash
# Print SIL before/after the crashing pass:
swiftc -O -Xllvm -sil-print-around=CopyPropagation reproducer.swift 2>&1 | head -200

# Print SIL for a specific function:
swiftc -O -Xllvm '-sil-print-function=MANGLED_NAME' reproducer.swift 2>&1

# Print functions whose mangled name contains a substring:
swiftc -O -Xllvm '-sil-print-functions=MyType' reproducer.swift 2>&1

# Verify ownership after every pass (finds the first failing pass):
swiftc -Xfrontend -sil-verify-all reproducer.swift 2>&1
```

**`-sil-verify-all` as pipeline-stage disambiguator**: When a crash is attributed to an optimization pass (e.g., CopyPropagation) but the suspected root cause is earlier (e.g., SILGen), `-sil-verify-all` is the definitive diagnostic. It verifies ownership after every pipeline stage. If verification fails before the attributed pass runs, the root cause is upstream — the optimization pass was just the messenger. This resolved a multi-session misattribution where a CopyPropagation crash was actually a SILGen `load [take]` on a trivial type (#85743).

**Read the error message carefully**. The compiler often prints:
- The exact SIL value and instruction that violate ownership
- The function name (mangled)
- The pass that detected the violation
- Suggested flags for further diagnosis

---

### [ISSUE-011] Pass Bisection

**Statement**: For optimization bugs (crash or miscompile at `-O` but not `-Onone`), use pass count bisection to identify the exact failing pass. For multi-transformation passes, use sub-pass bisection.

```bash
# Step 1: Binary search for the bad pass number
swiftc -O -Xllvm -sil-opt-pass-count=100 reproducer.swift    # works?
swiftc -O -Xllvm -sil-opt-pass-count=1000 reproducer.swift   # crashes?
# Binary search between 100 and 1000...

# Step 2: Once found, print SIL before/after the bad pass
swiftc -O -Xllvm -sil-opt-pass-count=550 -Xllvm -sil-print-last reproducer.swift 2>sil.txt

# Step 3: For multi-transformation passes (SILCombine, SimplifyCFG):
swiftc -O -Xllvm '-sil-opt-pass-count=550.25' reproducer.swift

# Step 4: Disable a suspect pass entirely:
swiftc -O -Xllvm '-sil-disable-pass=sil-combine' reproducer.swift
```

**For large projects**: Read pass counts from a file with `-Xllvm -sil-pass-count-config-file=<file>`.

**Automated bisection**: The `llvm/utils/bisect` utility automates the binary search:
```bash
llvm-project/llvm/utils/bisect --start=0 --end=10000 ./invoke_swift_passing_N.sh "%(count)s"
```

**Rationale**: Pass bisection is the primary technique used by the Swift compiler team (documented in `DebuggingTheCompiler.md`). Sub-pass notation (`<n>.<m>`) was contributed by meg-gupta for multi-transformation passes. Issue swiftlang/swift#66312 demonstrates the gold standard: bisection to sub-pass 13669.10 got a same-day fix from the SIL optimizer owner.

---

### [ISSUE-006] Hypothesis Discipline

**Statement**: Form hypotheses from evidence, not from prior investigations. Each hypothesis MUST be testable by a specific code change or compiler flag.

**Anti-pattern**: "This looks like Bug 2 (#88022) because it's also a CopyPropagation crash" — different CopyPropagation crashes have different root causes. The pass name is not a diagnosis.

**Correct pattern**: "The SIL shows `load [take]` on `$*Optional<Bool>` which is trivial. Hypothesis: the enum destructuring generates `load [take]` unconditionally for all tuple elements, including trivial ones. Test: remove the trivial field from the enum."

**Rationale**: The 2026-03-31 investigation initially hypothesized SILCloner forwarding ownership, then generic specialization, then multi-pass interaction — each more complex than the actual root cause (SILGen using `createLoad(...Take)` instead of `TypeLowering::emitLoad()`). The SIL evidence was available from the first dump.

---

### [ISSUE-012] Compiler Source Reading

**Statement**: For optimizer bugs, reading the compiler source SHOULD be attempted early — particularly when the SIL dump reveals the failing pass and instruction. Look for TODO/FIXME comments, known-limitation guards, and bailout conditions near the crash site.

**Local clone**: `${DEV_ROOT}/swiftlang/swift` (clone from https://github.com/swiftlang/swift)

**Key directories for SIL optimizer bugs**:

| Path (relative to swiftlang/swift) | Content |
|-------------------------------------|---------|
| `SwiftCompilerSources/Sources/Optimizer/` | SIL passes written in Swift (e.g., `SimplifyMarkDependence.swift`) |
| `lib/SILOptimizer/` | SIL passes written in C++ (e.g., `CopyPropagation.cpp`) |
| `lib/SIL/IR/` | SIL core (e.g., `OperandOwnership.cpp`) |
| `lib/SILGen/` | SIL generation from AST |
| `lib/IRGen/` | LLVM IR generation from SIL (e.g., `GenStruct.cpp`) |
| `include/swift/SILOptimizer/PassManager/Passes.def` | All pass names and tags |
| `docs/DebuggingTheCompiler.md` | Canonical debugging reference |

**When to read source**:
1. The SIL dump clearly identifies the crashing pass and the specific operation
2. Multiple experiments have failed to reproduce in isolation (the bug is in how the optimizer handles a pattern)
3. The bug has been narrowed to a specific pass but the root cause is unclear

**What to look for**:
- `TODO` / `FIXME` comments acknowledging known limitations (the Bug 2 TODO at `OSSACanonicalizeOwned.cpp:40-46` provided more signal than 7 experiments)
- Bailout conditions for specific IR patterns (e.g., `PointerEscape` classification in `OperandOwnership.cpp`)
- Assertions that guard the failing code path

**Rationale**: The 2026-03-22 investigation resolved Bug 2 by reading compiler source — a TODO comment confirmed the hypothesis before any fix was written. The 2026-03-22 rawlayout investigation fixed the compiler in 21 lines after reading `GenStruct.cpp`. In both cases, source reading was more efficient than continued empirical exploration.

---

## Step 4: Search for Duplicates

### [ISSUE-007] Duplicate Search

**Statement**: Before staging a dossier, search upstream for duplicates using the exact error message, the SIL instruction pattern, and the Swift feature combination — the dossier's duplicate-differentiation section depends on it. (Searching swiftlang is read-only research; filing there is not a step — see [ISSUE-008].)

**Search strategy**:
```
site:github.com/swiftlang/swift/issues "EXACT ERROR MESSAGE"
site:github.com/swiftlang/swift/issues FEATURE1 FEATURE2 crash
```

**Also search**:
- The swiftlang/swift commit log for recent fixes matching the pattern
- The compiler source for TODO comments mentioning the limitation

**If a fix exists on main**: Check if it's in the dev toolchain (Step 1 should have caught this, but the fix may be very recent).

---

## Step 5: Resolve

### [ISSUE-008] Resolution Paths

**Statement**: Choose the resolution path based on the diagnosis. **Standing policy (principal, 2026-06-11): upstream filing at swiftlang — issues OR pull requests — does not exist as a resolution step.** Dossiers staged in `swift-institute/Issues` are the TERMINAL records: do not propose, queue, or re-raise filing. Watching issues filed before the policy is passive-only. (Pushing the public Issues repo remains an outward act needing a fresh principal YES.)

| Situation | Path |
|-----------|------|
| Fixed on dev toolchain, not in Xcode | Apply workaround, document, wait for release |
| Unfixed (clear OR unclear root cause) | Stage a terminal dossier in `swift-institute/Issues` (reproducer + evidence per [ISSUE-017]); apply and document the workaround; add/update the catalog entry |
| Our code triggers a known limitation | Restructure our code to avoid the trigger |

**Forbidden workarounds — optimization-suppressing attributes**: `@_optimize(none)` (and other optimization-suppressing attributes) MUST NOT be used to work around a SIL-optimizer crash, even when behaviour-preserving and green in CI. For a crash triggered by `-O` inlining collapsing an `@inlinable` ~Copyable/generic chain into one sink function (the `Mem2Reg`/`OSSACompleteLifetime`/`SILBitfield.h:60` per-function bitfield overflow), **restructure the source** — split the sink function, or reduce its per-function inlined complexity so the inliner cannot collapse the chain past the budget. `@_optimize(none)` is not merely disfavoured: inside an `-O` module it is itself miscompile-prone — it can elide a `consume`d move-only value's element `deinit`s (a silent teardown miscompile). See `swift-institute/Research/swift-compiler-bug-catalog.md` §A18 (the crash) and §A19 (the `@_optimize(none)` teardown miscompile).

**Enforcement (mechanical slice)**: AST `Lint.Rule.Platform.OptimizeSuppression` (`optimize suppression attribute`, `Bundle.institute`; /promote-rule 2026-07-06) flags `@_optimize(none)` / `@_optimize(size)` / `@_semantics("optimize.no.*")` on any declaration; exemption only via `swift-linter:disable:next` + `REASON:` citing a dossier/catalog-§ (disposition-1). Discipline: `Audits/PROMOTE-ISSUE-008-optimize-suppression-2026-07-06.md`. [VERIFICATION: AST]

**Workaround documentation**: When applying a source-restructuring (or other permitted) workaround, ALWAYS include:
```swift
// WORKAROUND: {what it works around}
// WHY: {root cause}
// TRACKING: {dossier path / catalog § / upstream commit hash of an existing fix}
// WHEN TO REMOVE: {condition — e.g., "when Xcode ships Swift 6.4+"}
```

---

## Step 6: Record

### [ISSUE-009] Investigation Record

**Statement**: Every investigation MUST be recorded in the relevant package's `Audits/audit.md` (`Research/` is public and audits are private) with: severity, location, finding, status (WORKAROUND/RESOLVED/DEFERRED), and tracking reference.

**For experiments created during investigation**: Follow [EXP-006] to document results in the experiment's main.swift header.

**For reflections**: If the investigation produced significant learning, invoke `/reflect-session`.

---

## Step 7: Context-Sensitive Reproduction

### [ISSUE-013] Variable Isolation for Context-Sensitive Bugs

**Statement**: When a bug reproduces in the full build but not in a standalone experiment, systematically vary one integration dimension at a time to build a constraint model.

**Variables to test independently**:

| Variable | Test |
|----------|------|
| Access level | `public` vs `internal` (different codegen paths) |
| Field count | 1-field vs 2+ fields |
| Dependencies | Zero deps vs full dependency graph |
| Generic vs concrete | Generic type parameters vs concrete types |
| Optimization mode | `-Onone` vs `-O` vs `-Osize` |
| Compilation mode | Single-file vs WMO |
| Module isolation | Same-module vs cross-module |

**Build a constraint model**:
```
Required: public + 2+ fields + @_rawLayout + deinit + release = crash
Removing any one dimension: passes
```

**Rationale**: The 2026-03-22 investigation discovered the access-level trigger (`public` crashes, `internal` works) through systematic variable isolation. Without testing `public` access, the combined @_rawLayout approach appeared to work — a false positive.

---

### [ISSUE-014] File-Level Elimination

**Statement**: For WMO or cross-module bugs that don't reduce to a single file, use file-level elimination: empty all source files in the target, add back one at a time, rebuild after each. This identifies the trigger file in minutes.

```bash
# Save originals, empty all files
for f in Sources/MyTarget/*.swift; do cp "$f" "$f.bak"; echo "" > "$f"; done

# Add files back one at a time, rebuild between each
cp Sources/MyTarget/Buffer.swift.bak Sources/MyTarget/Buffer.swift
/Users/coen/Developer/swift-institute/Scripts/swift-build package build -- -c release  # Crash? → Buffer.swift is involved.
```

**Rationale**: Proved decisive for the LLVM verifier crash investigation (2026-03-20). File-level elimination took minutes and gave definitive answers, while code-level modification consumed hours without progress.

---

### [ISSUE-015] Superrepo Validation

**Statement**: For ecosystems with layered superrepos, sub-repo release builds are necessary but NOT sufficient. The full superrepo build MUST be used for release-mode validation because deeper cross-module inlining exposes bugs invisible in isolation.

**Evidence**: Bug 2 affected 5 functions in sub-repo builds but 60+ functions across 9 repos in the superrepo. CMO bugs are latent in existing passes, only exposed when cross-module inlined code creates new patterns.

---

## Reduction Tooling

### [ISSUE-016] Available Reduction Tools

**Statement**: Use the appropriate reduction tool for the abstraction level of the bug.

**Source-level reduction**:
- **C-Reduce** (external, works on Swift via language-agnostic passes): Write an interestingness test shell script, run `creduce interestingness_test.sh reproducer.swift`. The C-specific passes fail silently; agnostic passes still achieve significant reduction.
- **Manual reduction** per [EXP-004]: Remove imports, types, functions, generics one at a time. Verify behavior persists after each step.

**SIL-level reduction**:
- **`bug_reducer.py`** (`swiftlang/swift/utils/bug_reducer/`): Reduces pass count and function set to minimal triggering configuration. Alpha quality; function-level only.
- **`sil-func-extractor`**: Extract specific SIL functions for targeted analysis.

**Pass-level reduction**:
- **`-sil-opt-pass-count=<n>`** with binary search per [ISSUE-011].
- **`-sil-disable-pass=<tag>`** to confirm a specific pass is involved.

**Interestingness test pattern** (from C-Reduce/llvm-reduce):
```bash
#!/bin/bash
# interestingness_test.sh — exit 0 if bug reproduces, 1 if not
swiftc -O "$1" 2>&1 | grep -q "Found ownership error"
```

**Rationale**: Swift has a significant tooling gap in test case reduction compared to C/C++ (C-Reduce, llvm-reduce) and Rust (treereduce, icemelter, cargo-bisect-rustc). Documenting available tools and the interestingness test pattern makes the best of what exists.

---

## The Terminal Dossier

### [ISSUE-017] Dossier Characterization Format

**Statement**: When staging a terminal dossier in `swift-institute/Issues`, the characterization MUST include at minimum: classification ([ISSUE-010]), environment (version labels per `swift --version`, never bundle-ID/date proxies), reproducer, observed behavior, duplicate differentiation ([ISSUE-007]), and a STAGED terminal-record header. Upstream filing does not exist as a step ([ISSUE-008] standing policy); the format below is retained because it is what makes a record decisive.

**Template**:
```markdown
**Classification**: [ICE/Miscompile/Rejects-valid/Accepts-invalid/Diagnostic]
**Environment**: Swift X.Y, macOS/Linux, -O/-Onone/-Osize, WMO/single-file
**Reproducer**: [standalone .swift file, buildable with bare swiftc]

[code block]

**Command**: swiftc -O reproducer.swift
**Observed**: [crash output / wrong behavior / wrong diagnostic]
**Expected**: [what should happen]

**Investigation** (if done):
- Pass bisection: crashes at pass #N (PASS_NAME), passes at N-1
- Before/after SIL: [diff or description]
- Ingredient list: [what's required to trigger]
```

**What makes a record decisive** (empirical, from merged upstream PRs — kept as the dossier quality bar):
1. Standalone single-file reproducer buildable with bare `swiftc`
2. Pass bisection to specific pass or sub-pass number
3. Before/after SIL diff
4. Clear explanation of the invariant violation

**What weakens a record**:
- Reproducers requiring a SwiftPM project or external dependencies
- Missing version/platform information
- No reduction attempted

**Rationale**: Academic research (Bettenburg et al. 2008) confirms: steps to reproduce (89% importance), stack traces, and test cases are the top-3 elements correlated with fast resolution. swiftlang/swift#66312 demonstrates the gold standard — bisection to sub-pass 13669.10 got a same-day fix.

---

## Known Recurring Workarounds

### [ISSUE-021] Reference Indirection for SIL Verifier Crashes

**Statement**: When the SIL verifier (MoveOnlyAddressChecker, CopyPropagation) crashes
on a `~Copyable` pattern involving complex generic or pack types, wrap the problematic
payload in a reference-counted class. The class reference is a simple pointer in SIL,
sidestepping the verifier's value-tracking logic.

**Applies when**:
- A `CheckedContinuation` with a complex `Result<T, E>` type appears as an associated
  value in a `~Copyable` enum
- A generic pack or tuple is pattern-matched via `consuming switch` on a `~Copyable` type
- The SIL dump shows `load [take]` on a sibling value being flagged as a lifetime leak

**Procedure**:
```swift
// BEFORE (triggers verifier crash)
enum Request: ~Copyable {
    case register(CheckedContinuation<Result<Payload, IO.Event.Error>, Never>, Interest)
}

// AFTER (reference indirection sidesteps crash)
final class IO.Event.Registration.Continuation: Sendable {
    let continuation: CheckedContinuation<Result<Payload, IO.Event.Error>, Never>
    init(_ c: CheckedContinuation<Result<Payload, IO.Event.Error>, Never>) {
        self.continuation = c
    }
}
enum Request: ~Copyable {
    case register(IO.Event.Registration.Continuation, Interest)
}
```

**Complementary workarounds at the same abstraction level** (prefer when applicable — all source-restructuring, per [ISSUE-008]):
- `while let dequeue` instead of closure-based `drain { }` on shutdown paths
- Static helper functions instead of inline closures

`@_optimize(none)` (and optimization-suppressing attributes generally) MUST NOT be used here: it is forbidden per [ISSUE-008] and is itself a teardown-miscompile risk (catalog §A19).

**Workaround documentation** per [ISSUE-008]:
```swift
// WORKAROUND: Wrap continuation in class to sidestep MoveOnlyAddressChecker
// WHY: Swift 6.3 SIL verifier incorrectly flags sibling `load [take]` as leak
//      when CheckedContinuation<Result<...>, Never> is in a ~Copyable enum
// TRACKING: revisit on Swift 6.4+ (per feedback_toolchain_versions.md)
// WHEN TO REMOVE: when the verifier handles the pattern directly
```

**Rationale**: Reference indirection reduces the type complexity the SIL verifier
tracks. This is the lowest-cost workaround when the crash is in value-tracking logic
and the affected payload can tolerate a heap allocation. Three instances in swift-io
(Unbounded channel, Registration.Continuation, shutdown drain helpers) share the
same root cause — the verifier cannot track value lifetimes through complex
~Copyable patterns.


**Cross-references**: [ISSUE-008] Resolution Paths, [ISSUE-005] SIL Dump Analysis

---

## Extended Debugging Toolkit

### [ISSUE-018] Diagnostic Investigation Tools

**Statement**: For non-crash issues (rejects-valid, diagnostic quality), use the appropriate diagnostic tool.

| Tool | Flag | Purpose |
|------|------|---------|
| Diagnostic names | `-Xfrontend -debug-diagnostic-names` | Appends `[diagnostic_id]` to every error — search compiler source for this ID |
| Type checker trace | `-Xfrontend -debug-constraints` | Full constraint solver log (verbose; essential for type inference bugs) |
| Assert on error | `-Xllvm -swift-diagnostics-assert-on-error=1` | Stack trace at the exact point the error is emitted |
| AST dump | `swiftc -dump-ast file.swift` | Type-checked AST (identifies type inference results) |
| Parse-only dump | `swiftc -dump-parse file.swift` | Parse tree without type checking (isolates parsing issues) |
| Type-check only | `swiftc -typecheck file.swift` | Fastest way to check for type errors (no codegen) |

---

### [ISSUE-019] SIL Pipeline Stages

**Statement**: When investigating, dump SIL at the appropriate pipeline stage to isolate whether the bug is in SILGen, mandatory passes, or optimization passes.

| Stage | Command | What it shows |
|-------|---------|---------------|
| Raw SIL | `swiftc -emit-silgen file.swift` | SIL immediately after SILGen (before any optimization) |
| Canonical SIL | `swiftc -emit-sil -Onone file.swift` | After mandatory passes |
| Optimized SIL | `swiftc -emit-sil -O file.swift` | After full optimization pipeline |
| LLVM IR (pre-opt) | `swiftc -emit-irgen -O file.swift` | After IRGen, before LLVM optimization |
| LLVM IR (post-opt) | `swiftc -emit-ir -O file.swift` | After LLVM optimization |

Use `-save-sil`, `-save-irgen`, `-save-ir` to save alongside normal compilation output.

If the bug is in raw SIL (`-emit-silgen`), the problem is in SILGen. If raw SIL is correct but canonical SIL is broken, a mandatory pass is at fault. If canonical SIL is correct but optimized SIL is broken, an optimization pass is at fault. Use [ISSUE-011] pass bisection to narrow further.

---

## Quick Reference

```
0. Classify: ICE / Miscompile / Rejects-valid / Accepts-invalid / Diagnostic
1. TOOLCHAINS=swift xcrun swiftc -O repro.swift    # Fixed? → Stop.
2. Reduce to single swiftc-reproducible file        # Clean build each step.
3. Verify each ingredient independently              # Remove one, rebuild clean.
4. Bisect: -Xllvm -sil-opt-pass-count=<n>           # Find the bad pass.
5. Dump SIL: -Xllvm -sil-print-last (with count)    # Read the before/after diff.
6. Read compiler source if pass is identified        # Look for TODOs, bailouts.
7. Search github.com/swiftlang/swift/issues          # Duplicate? (read-only research)
8. Stage terminal dossier; apply workaround           # Document everything. Never file upstream.
```

---

### [ISSUE-024] Multi-Repo Shell Iteration Detection Predicate

**Statement**: When iterating over sub-repos in a mixed-layout tree (independent repos + submodules + worktree-aliased directories), use `[[ -e "$d/.git" ]]` (matches file OR directory), not `[[ -d "$d/.git" ]]` (directory only). Submodules use a `.git` file pointing at the superrepo's `modules/` tree; independent repos use a `.git` directory; both are sub-repos for iteration purposes.

**Example (correct)**:

```bash
for d in */; do
    [[ -e "$d/.git" ]] || continue   # matches both repo types
    # operate on the sub-repo at $d
done
```

**Example (defect)**:

```bash
for d in */; do
    [[ -d "$d/.git" ]] || continue   # silently skips all submodules
    # operates on independent repos only; submodules invisible
done
```

**Rationale**: Sub-repo iteration scripts that use `-d` silently skip every submodule in the tree. The defect is invisible in a homogeneous repo layout but breaks as soon as the tree mixes independent repos with submodules — which most ecosystem-wide tooling encounters. The predicate is a one-character fix that must be applied everywhere the pattern occurs.


**Cross-references**: [ISSUE-*]

---

### [ISSUE-025] In-Package Verification of Synthetic-Reproducer Claims

**Statement**: When a compiler-bug investigation reduces the failing shape to a minimum reproducer, claims about which production consumers are affected MUST be verified by writing an in-package release-mode test that exercises the production shape. The reduced reproducer proves the bug exists in the reduced shape; it does NOT prove the bug exists in shapes where the stripped features may be load-bearing structural discriminators. Without in-package verification, the cascade claim is unverified — the reproducer narrows the bug to a specific feature combination, and production code may evade the combination by structural accident or design.

**Procedure** (extends [ISSUE-013] Variable Isolation):

1. Reduce the failing shape to a minimum reproducer per [EXP-004] / [ISSUE-013].
2. Identify the candidate production consumers (grep for the call pattern, the ownership shape, the type combination).
3. For each candidate consumer, identify the production shape's structural features that differ from the reduced reproducer (e.g., `@_rawLayout` storage, generic specialization, stride arithmetic, function-call boundaries).
4. Write an in-package release-mode test exercising the production shape under the failure trigger.
5. Run the test:
   - **PASSED**: the production shape evades the bug. The cascade claim is refuted for that consumer; the stripped feature is a load-bearing discriminator.
   - **FAILED**: the production shape exhibits the bug. The cascade claim is verified for that consumer.
6. Both outcomes are informative; skipping the step forecloses the distinction.

**Worked example (the origin incident)**:

V11 narrow-shape reproducer: non-generic `~Copyable` container with plain stored `~Copyable` field, `@inlinable` method doing `withUnsafePointer(to: _storage)`. Two successive calls returned addresses 8 bytes apart with garbage dereferences. Initial extrapolation: "Memory.Inline.pointer(at:) is therefore broken in production" → Finding #12 HIGH/HOLD on swift-memory-primitives + swift-buffer-primitives + swift-async-primitives.

Step 4 in-package release-mode tests:
- `Memory.Inline<Int, 4>.pointer(at:)` stability test in swift-memory-primitives → **PASSED**
- `Buffer.Ring.Bounded.peek.front/back` test in swift-buffer-primitives → **PASSED**
- `Async.Timer.Wheel` cross-module public-state reads in swift-async-primitives → **PASSED**

3/3 production shapes evaded the bug. The structural discriminator (`@_rawLayout(likeArrayOf: Element, count: capacity)` + generic Element + stride arithmetic) was load-bearing. Finding #12 inverted to LOW/watchflag; shipping scope restored to NORMAL; tests retained as positive-assertion regression guards (commits `e390d7a`, `92e53fe`, `26e76e1`).

Without [ISSUE-025], the audit would have shipped a HOLD recommendation on three packages based on synthetic extrapolation. The in-package verification is the missing step between "the reproducer shows the pattern" and "production code is affected."

**Relationship to [ISSUE-013] and [EXP-020]**: [ISSUE-013] Variable Isolation tests integration dimensions to build a constraint model. [ISSUE-025] (this rule) extends the discipline through to production: the constraint model must be validated against each cited production shape, not just the reduced shape. [EXP-020] is the experiment-process counterpart for the same defect class on the experiment side.


**Cross-references**: [ISSUE-013], [EXP-011], [EXP-020]

---

### [ISSUE-026] Negative-Experiment Conclusion Must Cite Coverage Scope

**Statement**: When reporting a negative experimental result during an investigation (a fix attempt that failed, a hypothesis ruled out, a mitigation that did not resolve the symptom), the conclusion MUST explicitly state the experiment's coverage scope alongside the result. A bare "X did not help" reads as "approach X is exhausted"; the truthful form is "X with [stated coverage scope] did not help; broader-coverage variants not yet tested." The two are categorically different and the latter prevents premature dispatch closure.

**Procedure** (when writing the conclusion sentence of a negative experiment):

1. Identify the experiment's coverage parameters: which variables / inputs / scopes were exercised, and which were left at default / partial / out-of-scope.
2. Compose the conclusion sentence in the form:
   `[Experiment X] with [enumerated coverage] did NOT [resolve / refute / produce] [target]. [Untested coverage variants] not yet exercised.`
3. If the conclusion sentence cannot be written without ambiguity about coverage scope, the experiment is under-specified — extend it to the missing coverage rather than reporting the negative result as definitive.
4. Cite the conclusion sentence in any handoff / supervisor report / Path-B dispatch that consumes the result; the consumer of the negative result inherits the coverage discipline.

**Failure signature** (when [ISSUE-026] is violated): an investigation autonomously concludes "approach exhausted, time to file upstream" or "hypothesis refuted, move to next" when the negative experiment actually tested only a fraction of the approach's possible coverage. The user / supervisor catches the gap by asking the meta-question (e.g., "can't we test the broader variant?"); without that intervention, the investigation stages a premature "compiler bug" terminal dossier or pivots to a less-promising direction.

**Worked example** (canonical 2026-05-01 origin incident): SPM-stall investigation at swift-foundations/swift-io. Phase 3 mirror experiment redirected swift-syntax (1 of 5 URL deps in closure) to local file:// path; stall persisted. Conclusion as initially reported: "mirror approach does not help; recommend Path B (file upstream)." User redirected: "structural how?" The truthful conclusion was "mirror with 1-of-5 URL coverage did not help; comprehensive coverage (all 5 URL/local pairs) not yet tested." Comprehensive-mirror experiment (test all 5 in one pass) immediately resolved the stall. The premature single-URL conclusion would have triggered upstream-issue filing without exhausting the workspace-side approach.

**Relationship to [ISSUE-013]**: [ISSUE-013] Variable Isolation prescribes the per-variable test discipline during reduction. [ISSUE-026] is the conclusion-writing step that locks in the coverage discipline at the result-reporting boundary; without it, even a well-isolated experiment can produce a generalized conclusion that exceeds the experiment's coverage.


**Cross-references**: [ISSUE-013], [EXP-004].

---

### [ISSUE-027] swift-testing `@section` Errors Mask Underlying Semantic Errors

**Statement**: When `swift test` fails with an error like `global variable must be a compile-time constant to use @section attribute` referencing `Testing.__TestContentRecord` in macro-expanded code, the `@section` complaint MUST NOT be believed at face value. It is a downstream symptom of the swift-testing macro failing to const-evaluate the test record because the test body itself has a real semantic error. The trigger is `~Copyable` consume semantics inside the `#expect` macro, NOT memory-safety mode itself.

**Most common cause**: a `~Copyable` value being consumed inside an `#expect(...)` expression. `#expect` captures the comparison expression in an escaping closure which prohibits consume operations. Example: `#expect(Swift.String(noncopyableValue) == fixture)` where `Swift.String.init` is `consuming`.

**Procedure**:

```bash
# When you see @section attribute errors, surface the actual semantic errors:
/Users/coen/Developer/swift-institute/Scripts/swift-build package test 2>&1 | grep -E "^/Users/.*error:" | head -20
```

Fix the semantic errors (typically by hoisting the consume out of the macro expression):
```swift
let consumed = Swift.String(value)
#expect(consumed == fixture)
```

The `@section` errors disappear once the underlying issue is resolved. Do NOT chase strict-memory-safety configuration — the `#StrictMemorySafety` documentation linking on these errors is misleading.


**Cross-references**: [ISSUE-018], [SWIFT-TEST-014]

---

### [ISSUE-028] Consult the Compiler Bug Catalog Before Designing Around an Apparent Compiler Limitation

**Statement**: Before designing a workaround for an apparent Swift compiler limitation (miscompile, SIGSEGV, type-system rejection, optimization mishap), the engineer MUST consult `swift-institute/Research/swift-compiler-bug-catalog.md`. The catalog enumerates verified bugs/patterns/workarounds with Swift-version pin, symptom, root cause where known, and recommended workaround. If the symptom matches an existing entry, follow that entry's workaround. If not, add a new entry to the catalog as part of the issue investigation.


**Cross-references**: [ISSUE-001], [ISSUE-002], [ISSUE-027]

---

### [ISSUE-029] Out-of-Process Reproducer Harness for Non-Compilable Triggers

**Statement**: When a dossier's trigger cannot be a compiled target of the Issues-repo entry — the reproducer ICEs/crashes the compiler OR is rejects-valid — the entry MUST use the out-of-process harness: the trigger ships as a `.swift.txt` resource, staged to `.swift` at test time and fed to a `swiftc` subprocess (`-O`-class flags for crash-class, `-typecheck` for rejects-valid); the test greps the output for the bug's signature and disposes THREE ways — signature found → still firing; exit 0 → fixed (the `withKnownIssue` flip); anything else → inconclusive, human re-triage. The three-way disposition is load-bearing: a future rephrased diagnostic surfaces as inconclusive instead of a false flip in either direction.

**Shipped exemplars**: `swift-institute/Issues` — the FunctionSignatureOpts entry (#89617, crash-class: `Crash.swift.txt` + `swiftc -O`) and the conditional-extension name-capture entry (#89684, rejects-valid: `Reject.swift.txt` + `swiftc -typecheck`); only the flag and the signature differ between classes.

**Rationale**: the pattern transferred unchanged from crash-class to rejects-valid in the #89684 landing (Reflection 2026-06-04 assay-independent-verification-issue-89684).

**Cross-references**: [ISSUE-002] (standalone reproducer), [ISSUE-010] (classification), [ISSUE-017] (dossier format)

---

### [ISSUE-030] Rule Out Stale Dependency / Build State Before Claiming a Compiler Bug

**Statement**: Before diagnosing a "the compiler can't see this overload / picks the wrong one" symptom as a Swift compiler bug, rule out stale LOCAL state first — the cheaper explanation, and the front-loaded check per [ISSUE-001]. When a downstream consumer cannot resolve a typed overload, extension, or SLI member from an upstream institute package, verify the dependency requirement and canonical URL in `Package.swift`, the applicable mirror, the upstream repository state, and the resolver diagnostics before claiming an overload-resolution bug. `Package.resolved` is generated and ignored; do not inspect or adjust individual pins as the remediation workflow. This is the dependency-resolution sibling of the isolated-build discipline in [ISSUE-003] and [ISSUE-028].

**Procedure**:
```bash
git -C <upstream-pkg> rev-parse main
/Users/coen/Developer/swift-institute/Scripts/swift-build package resolve \
  --package-path <consumer-package>
/Users/coen/Developer/swift-institute/Scripts/swift-build package build \
  --package-path <consumer-package>
```
A one-line module-scope `@inlinable` probe calling the same overload outside any extension disambiguates: if it also fails after a clean-worktree resolve/build, the overload is absent from the resolved dependency graph (dependency level, not a compiler bug); if it resolves, the issue is extension-context-specific.


**Cross-references**: [ISSUE-001], [ISSUE-003], [ISSUE-028], [PKG-BUILD-012] (swift-package-build — build-side triage of the same failure)

---

### [ISSUE-031] Convention ≠ Type-System Constraint; Probe Before Claiming Impossibility

**Statement**: Before asserting a design is impossible because "the type system forbids it" or "a skill rule says MUST", separate **convention** (a skill SHOULD / idiomatic style rule) from **type-system constraint** (a compiler-enforced rule). A skill "MUST" is a style convention, not a compiler wall. Before stating "X can't be expressed in Swift", write a ~15-line probe and `swiftc` it — and rule out the ADJACENT mechanisms, not just the first spelling: one mechanism failing does NOT generalise to its neighbours (the first failing spelling is not a proof of impossibility). Run the probe in-package when the target package is isolated (nothing depends on it yet) — coordinator-owned package build/test actions are faster and higher-fidelity than a hand-reconstructed `/tmp` probe; reserve `/tmp` probes for consumed packages, in-flight parallel work, destructive checks, or genuinely toolchain-level questions (e.g. stdlib API availability).

**Example**: `@_rawLayout(size: N)` rejects a non-literal `N` — TRUE, but stopping there and calling `Memory.Inline<n>` impossible was a false wall; the adjacent `@_rawLayout(likeArrayOf: UInt8, count: n)` accepts a value-generic `count` and built + tested green.


**Cross-references**: [ISSUE-002], [ISSUE-020]; **experiment-process** [EXP-004]

---

### [ISSUE-032] A Proposed Resolution MUST Move the Diagnosed Defect

**Statement**: A fix proposed as resolving a diagnosed defect MUST verifiably move that defect. Before proposing a "no-op because the code already does the right thing" conformance/change, (a) verify the "already-correct default" claim with file:line evidence read from the actual primitive — not assertion (for coordinate/direction claims, also confirm the coordinate convention); AND (b) verify the change actually engages the diagnosed user-visible defect. If the default is already correct AND the change only adds an explicit conformance, it does NOT fix the defect — the cause is elsewhere; find it before resubmitting. A no-op dressed as a fix is a withdrawal trigger under supervision and an [ISSUE-008] resolution that resolves nothing. Resolve-phase sibling of [ISSUE-025] (verify a reproducer claim against the production shape before shipping it).


**Cross-references**: [ISSUE-008], [ISSUE-022], [ISSUE-025]

---

## Cross-References

- **experiment-process** skill for [EXP-004] reduction methodology, [EXP-004a] incremental construction, [EXP-018] experiment consolidation
- **swift-pull-request** skill for [SWIFT-PR-011] dev toolchain check, PR submission workflow
- **reflect-session** skill for post-investigation reflection
- **implementation** skill for [IMPL-061] compiler fix over workaround accumulation
- Research: `swift-institute/Research/issue-investigation-best-practices.md` — literature study and comparative analysis
- Research: `swift-institute/Research/Reflections/2026-03-22-copypropagation-nonescapable-root-cause-and-fix.md`
- Research: `swift-institute/Research/Reflections/2026-03-31-noncopyable-io-completion-cascade-and-silgen-bug-discovery.md`
- Issues: `swift-institute/Issues/swift-issue-copypropagation-nonescapable-mark-dependence/INVESTIGATION-ARC.md` (moved 2026-05-11 from `Research/compiler-pr-copypropagation-mark-dependence-handoff.md`)
- External: `swiftlang/swift/docs/DebuggingTheCompiler.md` — canonical debugging reference
- External: `swiftlang/swift/utils/bug_reducer/README.md` — SIL-level reduction tool
- External: `swiftlang/swift/include/swift/SILOptimizer/PassManager/Passes.def` — all SIL pass names
