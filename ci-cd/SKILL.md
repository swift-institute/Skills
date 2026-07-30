---
name: ci-cd
description: GitHub Actions and continuous integration for Institute packages — the three-tier reusable-workflow chain, the typed Actions whitelist, the universal matrix, secret transport, caching, and reading run results. Apply when authoring or changing a workflow file or local action, when CI behavior or a build matrix changes, when a run fails or hangs, or when deciding whether a result counts as off-machine evidence.
---

# CI/CD

Institute CI is a deny-by-default control plane. Resolve what a workflow is allowed to do
before writing it, because the whitelist is what decides, not what compiles.

## Route package behavior separately from Institute integration

Package repositories own reusable functionality and reporting, including formats, rule
execution, and portable autofix mechanics. `swift-institute/.github` owns Institute-specific
workflow wiring and cross-repository control-plane automation, including GitHub mutations,
Issue and Project admission, bot identity and permissions, and rate-limit policy. A tool
consumed by CI does not thereby own the Institute integration around it. Split mixed proposals
into exact-owner work items and cross-link them. The [GitHub skill](../github/SKILL.md) defines
the GitHub control-plane boundary; this skill defines CI workflow structure, authorization,
and evidence.

## The three tiers

Package CI flows through three tiers, which are semantic owners rather than templates:
`package thin caller → layer wrapper → universal reusable`.

The caller owns only admitted events, concurrency, a `uses:` job, and typed inputs — no
`runs-on`, `steps`, tool setup, matrix, or validation predicate. The wrapper adds only the
invariants shared by every package in its layer. The universal reusable owns the common
build/test matrix, format, lint, docs, planning, and aggregation. Sub-orgs route through their
parent layer's wrapper; there is no fourth tier. A per-package repository carries `ci.yml`
only — standalone `swift-format.yml` and `swiftlint.yml` do not exist.

Tier follows the event: `workflow_dispatch` runs the full tier, a pull request does not. Verify
unmerged work by dispatching the full tier on the branch and fast-forwarding only when green. A
pull request silently downgrades platform coverage, so a green PR is not the evidence it looks
like.

Never relax, exclude, or `continue-on-error` the Windows leg. It is the fleet's only
assertions-enabled compiler, and therefore its only SIL-validity gate. A platform leg is
dropped by an identity declaration — the package's specification excludes that platform — never
as a cost measure.

## Pin what a green tick is evidence about

A `uses:` reference to `@main` is a floating ref: the callee can change without the caller
changing, so a past green proves nothing about the code that produced it. Pin a caller to a
commit, and be honest about how far the pin reaches — pinning a reusable workflow does not pin
a script that workflow resolves at runtime from somewhere else. Where the pin stops is worth
stating in the file, since the next reader will otherwise assume it does not.

## Whitelist

Actions are deny-by-default: repository-policy classifies every workflow file, local action,
trigger, job, and `uses:` reference against a typed whitelist. Only three classes are
admissible — an allowed package-local trigger with a thin caller, an allowed tool-owned
reusable workflow or action, or a typed exemption with exact repository and path scope.

An existing file, a successful run, or a copied template establishes nothing. An allowed file
is not permission for every trigger, and an allowed grant is not permission for every `uses:`
target.

## Traps GitHub will not warn you about

- A `workflow_call` workflow must not declare workflow-level `permissions: {}` — the
  reusable-call intersection caps every caller at zero. Put least privilege on the job that
  performs the operation.
- `env.*` is unavailable in `runs-on` and `container`; those resolve before job environment
  bindings. Use a literal, a matrix value, or an input.
- A job with job-level `uses:` cannot carry `continue-on-error`. Model advisory posture as a
  typed input interpreted inside the called workflow.
- `secrets: inherit` does not cross an organization boundary. Same-org callers may inherit;
  cross-org calls forward only the declared closed set.
- `restore-keys` is forbidden on every `actions/cache` use — a cache matches its complete key
  or it misses. Do not cache ordinary SwiftPM `.build` at all: branch dependencies plus
  uncommitted `Package.resolved` mean no key can prove it represents the resolved graph. Only
  immutable versioned tool binaries earn an exact-key cache, and the install must still verify
  the digest.

## What a check is evidence of

A check that has never been observed to fail is not evidence that the thing it names is absent
— it is evidence of nothing at all. Every gate needs a control that makes it fire, run on
every change to the gate. This is the same discipline as a positive control on a local probe,
and it fails the same way when skipped: a broken checker and a clean corpus produce identical
output.

Relatedly, a check's name is not its predicate. When a finding fires, read the condition it
actually tested; when one does not fire, the guarantee you have is that condition's absence and
nothing broader.

## Private repositories

Private repositories do not run CI: every job in the universal reusable is guarded on
repository visibility. On an org without billing this is not a policy choice but the only
workable shape — a gate that fired there could never report. Run the same Swift-owned
executables locally through Workspace instead, and record the substitution and its scope.

## Reading results

Evaluate a run at the run level (`conclusion`), not per job; patching source in reaction to a
failing `continue-on-error` job is churn.

Wait for a terminal run or enumerate additional jobs only while the result can change the
decision. Once an exact-head source or policy blocker fixes the verdict, record the existing run
and stop unrelated CI watching and matrix classification. A clean verdict may require every
required gate; a blocked verdict needs enough CI evidence to define the blocker and its owner.

`gh run view --log-failed` is run-scoped, not job-scoped — it returns the failed-step logs of
every failing job in the run, so sampling them and labelling the result with one platform's
name manufactures a dominant cause that does not exist in that job. Pass `--job <id>`.

Do not dispatch a workflow while Actions is disabled on the repository: runs queued in that
state are unrecoverable, and delete, cancel, and rerun all fail.
