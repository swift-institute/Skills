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

## What a green tick is evidence about

Not every runtime input earns identity the same way. Classify each one into exactly one of
three classes and treat it accordingly — conflating them is how a fail-open evidence gap gets
built by accident:

- **Identity-pinned** — full commit SHA (actions) or digest (containers, binaries). Third-party
  actions, Institute composite actions, containers, and immutable tool archives are always in
  this class, with no exception. `uses: actions/checkout@v4` is a mutable tag and is prohibited;
  only `uses: actions/checkout@<40-char-sha>` is admissible. Be honest about how far the pin
  reaches — pinning an action does not pin a script that action resolves at runtime from
  somewhere else. Where the pin stops is worth stating in the file, since the next reader will
  otherwise assume it does not.
- **Tracked, verified, recorded** — resolved at runtime, verified against a published manifest,
  fails closed on mismatch, and records the identity it resolved to. The `ci-binaries` linter
  channel is this class: it is never pinned to one `LINTER_RELEASE` tag, but every run verifies a
  checksum/manifest before trusting the binary it downloaded and records what it verified.
- **Unpinnable, recorded only** — nothing to pin at all; record the resolved environment and
  never claim it as an immutable identity. Hosted runner images (`macos-26`, `ubuntu-latest`, and
  similar labels) are this class: the label is a moving target, so record the resolved image
  version the run actually used, not the label, and never treat two runs on the "same" label as
  the same environment.

Intra-Institute reusable-workflow hops (package thin caller → layer wrapper → universal
reusable) are a permanent case outside those three classes, not a fourth class: they stay on
floating `@main` at every hop, permanently, with no pin, no tag, and no override path. This is
not a transitional state awaiting a release boundary — there is no future phase in which these
hops become pinned, and no caller pin wave or pin-promotion machinery may be built to advance
one toward a commit.

The evidence signal is not the `@main` ref string — it is what GitHub's own run object resolved
that hop to. GitHub records the resolved commit SHA of every reusable-workflow hop a run actually
took. Read `referenced_workflows` on the run: for each `@main` hop, it carries that resolved SHA
alongside the source ref. Evidence is that pair, source ref plus resolved SHA, together — read
the resolved SHA only from the run that reports it, never assumed or carried over from a
different run. An empty or unavailable `referenced_workflows` list is `UNMEASURED`, not a clean
or passing result; never substitute the current tip of `main` for a resolution the run didn't
report.

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

A claim that a package resolves off-machine requires an actual clean resolve from canonical
sources. A reachability probe tests a weaker property and is not evidence for it.

## Private repositories

Private package CI is zero-signal by design: every job in the universal reusable is
guarded on repository visibility, and on an org without billing a gate that fired there
could never report. A private repository's green package CI is therefore never evidence.

The evidence path is central trusted verification. The control plane's private-verification
sweep enumerates private ordinary repositories (R10-positive-controlled), dispatches each
exact private head to the trusted verifier, and the verifier executes Workspace against
that head, seals a leak-safe envelope (`workspace verification seal`/`check`), and
publishes exactly one `verification / workspace` check-run on the exact subject head with
the dispatch's request-id as its `external_id`. Public surfaces stay opaque: run titles
and artifacts carry the request-id and binding digest only, never a private coordinate.
Stale heads, replayed requests, and invalid payloads fail closed before publication.

Private repositories cannot carry branch rulesets on the current plan (platform-refused;
Ruling R33 records the 403 readbacks as the absence control), so `verification / workspace`
is the private convergence signal rather than a required-check context. The G1 seal
contract currently runs reduced under Ruling R34 (lint not required; inventory digest
unmeasured, both Workspace-side causes); the Swift-native follow-up programme owns the
restoration and its activation gate is a green full-contract run.

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
