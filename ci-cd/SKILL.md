---
name: ci-cd
description: GitHub Actions and continuous integration for Institute packages — the three-tier reusable-workflow chain, the typed Actions whitelist, the universal matrix, secret transport, caching, and reading run results. Apply when authoring or changing a workflow file or local action, when CI behavior or a build matrix changes, when a run fails or hangs, or when deciding whether a result counts as off-machine evidence.
---

# CI/CD

Institute CI is a deny-by-default control plane. Resolve what a workflow is allowed to do before
writing it; nothing about an existing file establishes permission.

## The three tiers

Package CI flows through three tiers, which are semantic owners, not templates:
`package thin caller → layer wrapper → universal reusable`. The caller owns only admitted events,
concurrency, a `uses:` job, and typed inputs — no `runs-on`, `steps`, tool setup, matrix, or
validation predicate. The wrapper adds only invariants shared by every package in its layer. The
universal reusable owns the common build/test matrix, format, lint, docs, planning, and aggregation.
Sub-orgs route through their parent layer's wrapper; there is no fourth tier. Per-package
repositories carry `ci.yml` only — standalone `swift-format.yml` and `swiftlint.yml` must not exist.

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
  cross-org calls forward only the declared closed set. Better: a central workflow minting a
  short-lived `swift-institute-bot` installation token scoped to the exact repositories and
  permissions.
- `restore-keys` is forbidden on every `actions/cache` use — a cache matches its complete key or
  misses. Do not cache ordinary SwiftPM `.build` at all: branch dependencies plus uncommitted
  `Package.resolved` mean no key can prove it represents the resolved graph. Only immutable
  versioned tool binaries earn an exact-key cache, and the install must still verify the digest.

A claim that a package resolves off-machine requires an actual clean, mirror-bypassed resolve from
canonical sources; a reachability probe and a mirror-backed build are different evidence.

## Private repositories

Private repositories must not trigger CI. The chain currently gates on credentials rather than
visibility, so a private repository can start runs that cannot produce signal; closing that gap is a
design requirement. Until it closes, run the same Swift-owned executables locally through Workspace
and record the substitution and its scope.

## Reading results

Evaluate a run at the run level (`conclusion`), not per job; patching source in reaction to a
failing `continue-on-error` job is churn. Do not dispatch a workflow while Actions is disabled on
the repository: runs queued in that state are unrecoverable — `gh api -X DELETE /actions/runs/<id>`
returns 403, `cancel` returns 500, `rerun` returns 403.
