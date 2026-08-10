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
and `institute` only when originating local build or test evidence.

## Judge with proportional evidence

Independent review means independent judgment. It does not require rerunning
every mechanical check.

Preserve existing exact-head evidence as **task-attributed** and inspect its
scope, toolchain, command, exit status, and provenance. Reproduce only an
uncertainty material to the verdict. If originating local evidence, follow the
`institute` skill; `--fresh` makes a chosen result admissible but does not oblige a
reviewer to create another result.

Treat CI as decision evidence, not a completeness exercise. Wait for a terminal
conclusion or inspect additional jobs only when the result can change the
verdict or the required fix.

## Return the verdict

When an actionable blocker or other non-clean verdict is established, determine
the smallest sufficient fixer scope, then preflight the review payload before
its first POST: the event is explicit, the body is non-empty after trimming,
and the reviewed commit matches the guarded head. The independent reviewer may
publish one precise exact-head `COMMENTED` review as `coenttb`, then read it
back. That review is evidence, never approval. Do not dispatch a bot-approval
transaction for a non-clean verdict; stop unrelated local verification, CI
watching, and matrix enumeration. Leave the PR open and draft unless authority
says otherwise.

A clean verdict requires the relevant source, policy, and required gates to be
satisfied at the exact head. When the brief authorizes formal approval or
landing of a `coenttb`-authored PR, it must also authorize the workflow dispatch
required to obtain that approval. A brief that authorizes bot approval while
forbidding that dispatch is contradictory and must be corrected before the
review mutation.

The canonical
[`review-pr-transaction`](https://github.com/swift-institute/.github/blob/main/.github/workflows/review-pr-transaction.yml)
workflow is the sole distinct-reviewer route for such a PR. Construct its
complete exact `accepted-plan`, dispatch it, and, when the task requires
terminal delivery, follow that one run in the foreground to its terminal
conclusion. Then read back a `swift-institute-bot[bot]` `APPROVED` review at the
guarded head. This bounded approval transaction is not passive CI watching or
matrix polling, and the workflow never merges.

Never use `gh pr review --approve` as `coenttb` on a `coenttb`-authored PR, and
never change or synthesize a reviewer identity locally. If merge authority is
separately explicit, re-guard the head, state, owning Issue, gates, approval,
and merge policy immediately before the merge; then use the permitted merge
method and read back the merged revision and Issue state.

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
