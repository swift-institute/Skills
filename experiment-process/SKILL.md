---
name: experiment-process
description: Design, run, revalidate, and document implementation experiments. Apply when a design choice needs executable evidence before production adoption.
---

# Experiment process

An experiment answers one decision-relevant question under named conditions.
Keep it smaller than the production change it informs.

## Workflow

1. State a falsifiable hypothesis and the decision it will affect.
2. Record toolchain, platform, dependencies, inputs, and success criteria.
3. Build the smallest fixture that distinguishes the alternatives.
4. Include a known-positive and known-negative control.
5. Run through the Workspace package coordinator; use `--fresh` when the result
   will be cited as evidence.
6. Capture raw output separately from interpretation.
7. State what the result proves, what it does not prove, and whether it
   generalizes.
8. Promote reusable implementation to its semantic owner; do not turn the
   experiment directory into a production dependency.

## Detailed rules

Load [`catalogue.md`](catalogue.md) for exact `[EXP-*]` requirements, experiment
layouts, revalidation records, benchmark variants, and promotion or retirement
criteria.

## Related skills

- **research-process** for the surrounding decision.
- **benchmark** for performance measurements.
- **issue-investigation** for compiler or toolchain failures.
- **swift-package-build** for execution.
