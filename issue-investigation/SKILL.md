---
name: issue-investigation
description: |
  Investigate Swift compiler, toolchain, dependency-resolution, and build-system
  failures by reproducing, reducing, diagnosing, and verifying them. Apply when
  a failure may come from the compiler or toolchain rather than product logic.
---

# Issue investigation

Produce a decision, not a pile of diagnostics. The useful result is one of:

- a product or package defect with a verified fix;
- a toolchain defect with a minimum reproducer and a safe workaround;
- a language constraint with an implementation decision;
- a stale-state or dependency-resolution failure with its source identified;
- an explicitly bounded inconclusive result.

Use **swift-package-build** for all package operations and **experiment-process**
when comparing implementation alternatives. Consult
`references/compiler-diagnostics.md` only when ordinary source-level reduction
does not locate a compiler failure.

## Investigation loop

### [ISSUE-CLASSIFY] Classify before debugging

Separate the symptom from the responsible layer. Start with these competing
explanations:

1. source or test defect;
2. package graph, mirror, or stale build state;
3. documented language constraint or accepted evolution change;
4. compiler diagnostic defect;
5. compiler crash, verifier failure, or miscompile;
6. build-system or IDE integration defect.

Do not call a failure a compiler bug merely because the diagnostic is confusing.
Check the relevant language or evolution rule when the error follows a recent
semantic change.

### [ISSUE-CHEAP-CHECKS] Eliminate cheap explanations first

Record the exact command and `swift --version`. Then check:

- the package requirement and canonical dependency URL;
- the selected toolchain and absence of an unintended `TOOLCHAINS` override;
- resolver diagnostics, without editing `Package.resolved`;
- a fresh package operation through `workspace package ... --fresh`;
- the same source shape on the current development toolchain, when available.

A blocked super-repository build does not prove the bug persists on another
toolchain. Test a standalone reproducer when unrelated failures obscure the
result.

### [ISSUE-REPRODUCE] Build the smallest faithful reproducer

Preserve the failure while removing unrelated package structure, dependencies,
types, and declarations. A reproducer is faithful only if it retains the same:

- compilation phase and optimization mode;
- diagnostic, crash signature, incorrect runtime behavior, or emitted-code flaw;
- generic, ownership, isolation, or conformance constraints that trigger it;
- relevant file and module boundaries.

If the trigger cannot itself compile, use an out-of-process test that writes the
source, invokes `swiftc`, and asserts the process result and diagnostics.

### [ISSUE-013] Isolate one variable at a time

Vary exactly one dimension per experiment: optimization, file boundary, target
boundary, declaration order, generic constraint, ownership annotation, module
resilience, or toolchain. Record both positive and negative controls.

Every claimed required ingredient needs an A/B result:

- A contains the ingredient and fails;
- B removes only that ingredient and passes.

Before generalizing from a synthetic reproducer, insert its exact shape into
the production environment. State the coverage of a negative experiment; “not
reproduced in this shape” is not “impossible”.

### [ISSUE-025] Verify the production shape

A reduced or synthetic reproducer establishes a mechanism, not its prevalence.
Insert the exact trigger into each cited production package and verify that the
real code exhibits the same result before recommending a production change.

### [ISSUE-DIAGNOSE] Escalate diagnostics by information value

Use the cheapest tool that can distinguish the remaining hypotheses:

1. source-level logging, assertions, and boundary checks;
2. debug versus release comparison;
3. file- and module-level elimination;
4. compiler diagnostic flags and intermediate representations;
5. optimization-pass bisection;
6. compiler source inspection.

Stop escalating when the evidence already determines a safe resolution.
Diagnostic commands and SIL-stage interpretation are in
`references/compiler-diagnostics.md`.

### [ISSUE-HYPOTHESIS] Make predictions before experiments

For each hypothesis, write:

- the observation it explains;
- the smallest experiment that distinguishes it;
- the predicted result if true;
- the predicted result if false.

Discard hypotheses contradicted by evidence. Do not accumulate mutually
incompatible stories.

### [ISSUE-DUPLICATES] Search before recording a compiler defect

Search upstream issues using the exact diagnostic or crash text, relevant SIL
instruction, affected language features, and toolchain versions. Record why
nearby reports are the same or different. Searching is evidence gathering; it
does not authorize filing or modifying an upstream issue.

### [ISSUE-RESOLVE] Choose the narrowest verified resolution

Prefer, in order:

1. correct the source, manifest, or package graph;
2. redesign around the actual language constraint;
3. use a local source-structure workaround that preserves semantics;
4. stage a compiler-defect dossier and document the workaround.

Never suppress optimization to hide a miscompile. A proposed fix must change the
diagnosed behavior in the production shape; an explicit conformance or no-op
rewrite is not a fix merely because it looks related.

Ask before undertaking a broad API or architecture redesign when multiple
reasonable fixes have different downstream consequences. A localized,
semantics-preserving repair does not require that pause.

### [ISSUE-VERIFY] Re-run the causal checks

Verification includes:

- the original failure now passes;
- the minimum reproducer changes as predicted;
- the negative control still distinguishes the cause;
- a fresh affected-package test passes;
- relevant downstream consumers still build or test;
- the workaround comment names the trigger and removal condition.

Do not report a cached green as evidence.

### [ISSUE-RECORD] Leave a terminal record

A durable record contains:

- classification and user-visible symptom;
- exact toolchain version and command;
- minimum reproducer and controls;
- required ingredients;
- diagnosis and competing hypotheses rejected;
- duplicate-search result;
- production verification;
- resolution or workaround;
- evidence commands and outcomes.

For an unresolved compiler defect, stage this record in the Institute issue
catalogue. Upstream submission is a separate, explicitly authorized workflow.

## Known diagnostic trap

When a `swift-testing` macro reports an `@section` or lexical-context failure,
remove or simplify the surrounding test macros first. Macro diagnostics can mask
an ordinary semantic error in the test body; only investigate the macro after
the underlying source type-checks independently.
