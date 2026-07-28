---
name: ci-cd
description: GitHub Actions and continuous integration for Institute packages — the three-tier reusable-workflow chain, the typed Actions whitelist, the universal matrix, secret transport, caching, and reading run results. Apply when authoring or changing a workflow file or local action, when CI behavior or a build matrix changes, when a run fails or hangs, or when deciding whether a result counts as off-machine evidence.
---

# CI/CD

Institute CI is a deny-by-default control plane. Resolve what a workflow is allowed to do before
writing it.

## The three tiers

Package CI flows through three tiers, which are semantic owners, not templates:
`package thin caller → layer wrapper → universal reusable`. The caller owns only admitted events,
concurrency, a `uses:` job, and typed inputs — no `runs-on`, `steps`, tool setup, matrix, or
validation predicate. The wrapper adds only invariants shared by every package in its layer. The
universal reusable owns the common build/test matrix, format, lint, docs, planning, and aggregation.
Sub-orgs route through their parent layer's wrapper; there is no fourth tier. Per-package
repositories carry `ci.yml` only — standalone `swift-format.yml` and `swiftlint.yml` must not exist.

Tier follows the event: `workflow_dispatch` runs the full tier, a pull request does not. Verify
unmerged work by dispatching the full tier on the branch and fast-forwarding only when green — a
pull request silently downgrades platform coverage.

Never relax, exclude, or `continue-on-error` the Windows leg: it is the fleet's only
assertions-enabled compiler, and therefore its only SIL-validity gate. A platform leg is dropped
only by an identity declaration — the package's specification excludes that platform — never as a
cost measure.

## Whitelist

Actions are deny-by-default: repository-policy classifies every workflow file, local action,
trigger, job, and `uses:` reference against a typed whitelist. Only three classes are admissible —
an allowed package-local trigger with a thin caller, an allowed tool-owned reusable workflow or
action, or a typed exemption with exact repository and path scope. An existing file, a successful
run, or a copied template establishes nothing; an allowed file is not permission for every trigger,
and an allowed grant is not permission for every `uses:` target.

## Traps GitHub will not warn you about

- A `workflow_call` workflow must not declare workflow-level `permissions: {}` — the reusable-call
  intersection caps every caller at zero. Put least privilege on the job that performs the
  operation.
- `env.*` is unavailable in `runs-on` and `container`; those resolve before job environment
  bindings. Use a literal, matrix value, or input.
- A job with job-level `uses:` cannot carry `continue-on-error`. Model advisory posture as a typed
  input interpreted inside the called workflow.
- `secrets: inherit` does not cross an organization boundary. Same-org callers may inherit;
  cross-org calls forward only the declared closed set.
- `restore-keys` is forbidden on every `actions/cache` use — a cache matches its complete key or
  misses. Do not cache ordinary SwiftPM `.build` at all: branch dependencies plus uncommitted
  `Package.resolved` mean no key can prove it represents the resolved graph. Only immutable
  versioned tool binaries earn an exact-key cache, and the install must still verify the digest.

## Private repositories

Private repositories do not run CI: every job in the universal reusable is guarded on repository
visibility. Run the same Swift-owned executables locally through Workspace instead, and record the
substitution and its scope.

## Reading results

Evaluate a run at the run level (`conclusion`), not per job; patching source in reaction to a
failing `continue-on-error` job is churn. Do not dispatch a workflow while Actions is disabled on
the repository: runs queued in that state are unrecoverable — delete, cancel, and rerun all fail.
