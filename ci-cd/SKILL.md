---
name: ci-cd
description: GitHub Actions and continuous integration for Institute packages — the one-hop generated caller topology, the typed Actions whitelist, the universal matrix, secret transport, caching, and reading run results. Apply when authoring or changing a workflow file or local action, when CI behavior or a build matrix changes, when a run fails or hangs, or when deciding whether a result counts as off-machine evidence.
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

Institute-authored CI semantics are Swift, owned by packages under `Tools/` in
`swift-institute/.github` — `institute-ci`, `institute-ci-control`, `repository-policy`, and
`pull-request-transaction` (kebab-case package roots, per the house convention). Workflow YAML
is wiring: triggers, `uses:`, permissions, and typed inputs. A semantic `run:` block —
classification, policy, mutation, or verdict logic embedded in a workflow or a companion
script — belongs in one of those packages instead. Institute-authored CI semantics in
`swift-institute/.github` are Swift, with exactly three named exception categories:
22 files transferred out of Institute semantics by the CW ruling (the Workspace-owned
predicate-script transfer class, ported under TX-APP1W), 13 fixture
stubs that are test corpus data pinned by a guard test, and the small retained-typed set
recorded per file in the `terminalCensus` of
`SWIFT-NATIVE-PROGRAMME/swift-purity-receipt.json` (at 1f8e2737) — consult that receipt,
not this skill, for the exact inventory before asserting purity.

## One hop, one artifact

Package CI is exactly one hop: a generated leaf caller calls the universal reusable directly.
There are no layer wrapper workflows. Every package repository in the fleet carries one
uniform generated `.github/workflows/ci.yml` and nothing else — standalone `swift-format.yml`
and `swiftlint.yml` do not exist, and neither does a per-layer `swift-ci.yml` to route through.

The caller owns only admitted events, concurrency, declared read permissions, the visibility
gate, and a `uses:` job with typed inputs — no `runs-on`, `steps`, tool setup, matrix, or
validation predicate. The universal reusable owns the common build/test matrix, format, lint,
docs, planning, and aggregation. Its shape is fixed:

```yaml
on:
  push: { branches: [main] }
  pull_request: { branches: [main] }
  workflow_dispatch:
permissions: { actions: read, contents: read }
jobs:
  ci:
    if: ${{ !github.event.repository.private }}
    name: ci / matrix
    uses: swift-institute/.github/.github/workflows/swift-ci.yml@main
```

Four properties of that file are load-bearing and none of them are stylistic. The job id `ci`
and the job name `ci / matrix` are the required-check contexts the rulesets name, so renaming
either silently un-gates the repository. The `if:` is the visibility gate — private
repositories skip hosted CI entirely rather than reporting a meaningless green. There is no
`tags:` trigger anywhere, because the Institute develops main-only and does not tag or release;
a `tags:` entry in a caller is a defect, not a leftover. And the caller is *generated*: edit
the generator and re-converge the fleet, never one repository by hand.

Uniformity is not conditional on the repository having content. A scaffold repository with no
root `Package.swift` carries the identical caller, so that the fleet reads one artifact
everywhere and a scaffold that later gains a package needs no CI mutation. The only exceptions
are named, bespoke, control-plane repositories — they are exceptions by ruling, not by drift.

GitHub itself permits a chain of ten levels (the caller plus nine nested reusable workflows).
The Institute uses one hop out of those ten by choice. Depth is available and deliberately
unspent: a shared invariant belongs in the universal reusable or in the generator, never in a
new intermediate workflow, and "the platform allows it" is not an argument for adding a hop.

Scheduling tier follows the event, and is a property of the universal reusable's `plan` job,
not of the call chain: `workflow_dispatch` runs the full tier, a pull request does not. Verify
unmerged work by dispatching the full tier on the branch and fast-forwarding only when green. A
pull request silently downgrades platform coverage, so a green PR is not the evidence it looks
like.

## Converging the fleet

A generated artifact that exists in 470 repositories converges as one wave, not as 470 pull
requests. The ratified mechanism is a bounded bypass window, executed from the principal's
terminal: add the App as a bypass actor on the target repository's protected main, push the
generated bytes, byte-compare the result against the intended generator output, and close the
window unconditionally — closed whether the push succeeded, failed, or was skipped, so a
failure mid-wave never leaves a repository unprotected. Every repository touched is journaled
with its class, and the wave's terminal claim is a re-census of the whole fleet, not the
per-repository exit statuses.

Two things do not follow from this. The window is opened per repository for one push and is
never a standing grant, and the mechanism is authorized for converging generated artifacts —
it is not a general route around PR-only main for ordinary work.

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

The intra-Institute reusable-workflow hop (generated leaf caller → universal reusable) is a
permanent case outside those three classes, not a fourth class: it stays on floating `@main`,
permanently, with no pin, no tag, and no override path. This is
not a transitional state awaiting a release boundary — there is no future phase in which these
it becomes pinned, and no caller pin wave or pin-promotion machinery may be built to advance
it toward a commit.

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
- `secrets: inherit` is scoped to the same organization *or the same enterprise* — GitHub's
  boundary is not the org alone. Getting this backwards in either direction is a real failure
  mode: assuming inherit dies at the org boundary hides a real credential path across sibling
  orgs of one enterprise, and assuming it always crosses orgs ships a caller whose secrets
  silently arrive empty. Institute policy is narrower than the platform either way — see below.
- `restore-keys` is forbidden on every `actions/cache` use — a cache matches its complete key
  or it misses. Do not cache ordinary SwiftPM `.build` at all: branch dependencies plus
  uncommitted `Package.resolved` mean no key can prove it represents the resolved graph. Only
  immutable versioned tool binaries earn an exact-key cache, and the install must still verify
  the digest.

## The secret profile

The terminal Institute profile is exactly two names: the org **variable**
`SWIFT_INSTITUTE_BOT_APP_ID`, carrying the swift-institute-bot App's *client id*, and the org
**secret** `SWIFT_INSTITUTE_BOT_APP_PRIVATE_KEY`. Both are provisioned org-wide with
visibility `all` in every layer org. Nothing else is part of the contract.

Two rules follow, and they are policy rather than platform limits. Every hop maps its names
explicitly — `secrets: inherit` is not used even where the platform would allow it, because an
explicit map is what makes each hop's credential surface readable at the call site instead of
inferable from org configuration. And credentials are forwarded only for a *measured* private
dependency closure; a package with no private dependency receives none. There is no PAT
fallback.

An id-shaped name that exists as a *secret* rather than a variable is legacy. Legacy names
survive in org configuration until their deletion transaction clears zero-use; their continued
existence is not permission to reference them. New work references the two terminal names only,
and reads a leftover legacy name as something to be deleted, never as a fallback to preserve.

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

Private package CI is zero-signal by design. The generated caller's
`if: ${{ !github.event.repository.private }}` skips the hop outright, so a private repository
runs no hosted package CI at all — and on an org without billing a gate that fired there could
never report anyway. A private repository's package CI is therefore never evidence, and its
absence is not a finding.

The designated evidence path is central trusted verification. Designated is the operative
word: the mechanism below is the ruled topology, and until its implementing transaction
closes, a private repository has no operational off-machine evidence path. Do not cite a
private head as verified on the strength of the design, and do not treat the gap as licence to
relax the visibility gate.

The control plane's private-verification
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
