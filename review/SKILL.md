---
name: review
description: Independently review an Institute pull request or exact revision, produce a guarded verdict with proportional evidence, and land only when explicitly authorized. Apply when reviewing a PR, re-reviewing a changed head, classifying whether findings or CI failures block landing, or acting as an independent reviewer/lander.
---

# Independent review

Own the verdict, not the implementation. Do not change source while acting as
the independent reviewer; route actionable findings to a separate fixer.

## Bind the review

Resolve the repository, visibility, owning Issue, open/draft state, base,
current head, current default branch, merge policy, prior reviews, and relevant
gates. Bind every finding and mutation to the exact reviewed head.

Read the complete changed surface and its commits. Load only the domain skills
the diff actually triggers. Use `github` for public tracking policy,
`github-access` for authenticated mutations, `ci-cd` for off-machine evidence,
and `workspace` only when originating local build or test evidence.

## Judge with proportional evidence

Independent review means independent judgment. It does not require rerunning
every mechanical check.

Preserve existing exact-head evidence as **task-attributed** and inspect its
scope, toolchain, command, exit status, and provenance. Reproduce only an
uncertainty material to the verdict. If originating local evidence, follow the
Workspace skill; `--fresh` makes a chosen result admissible but does not oblige a
reviewer to create another result.

Treat CI as decision evidence, not a completeness exercise. Wait for a terminal
conclusion or inspect additional jobs only when the result can change the
verdict or the required fix.

## Return the verdict

When an actionable blocker is established, determine the smallest sufficient
fixer scope, then preflight the review payload before its first POST: the event
is explicit, the body is non-empty after trimming, and the reviewed commit
matches the guarded head. Submit one precise exact-head review, read it back,
and stop unrelated local verification, CI watching, and matrix enumeration.
Leave the PR open and draft unless authority says otherwise.

A clean verdict requires the relevant source, policy, and required gates to be
satisfied at the exact head. If landing authority is explicit, re-guard the
head, state, owning Issue, gates, and merge policy immediately before the merge;
then use the permitted merge method and read back the merged revision and Issue
state.

Formal approval may be unavailable when reviewer and author share an identity.
Do not change identity to manufacture approval. Record an independent
`COMMENTED` verdict when repository policy permits task-level independence, and
merge only when the review brief explicitly authorizes landing.

## Preserve the boundary

Report:

- exact reviewed head and current-base relation;
- checked, task-attributed, and inferred evidence separately;
- public review or merge URL;
- actionable blocker or clean-verdict rationale;
- exact next owner and mutations made or deliberately withheld.

Scan every public payload for machine paths, private internals, credentials,
control-plane data, task/session identifiers, and prohibited attribution.

Read [references/verdict-rubric.md](references/verdict-rubric.md) when the
verdict is high-consequence, the evidence conflicts, or the review skill itself
is being evaluated.
