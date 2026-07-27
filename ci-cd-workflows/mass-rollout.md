# CI/CD cross-repository convergence

Load this reference when a policy or reusable-owner change affects multiple
repositories.

### [CI-050] Route fleet changes through the control plane

Cross-repository GitHub operations default to `swift-institute-bot`. Change the
typed owner first, prove a canary, then let the bot converge the measured
population with durable receipts.

Ordinary completed commits and pushes follow the standing push grant. Releases,
tags, visibility changes, archival, destructive actions, and outward
third-party publication retain their separate authority gates; bot mediation
does not broaden them.

A manual fan-out is allowed only as a bounded recovery/bootstrap exception
when the bot path cannot yet perform the authorized operation. Record why,
scope it exactly, and close the control-plane gap before treating the work as
complete.

### [CI-051] Preserve work and isolate commits

The bot and any bounded manual recovery:

- reject or skip dirty repositories;
- never reset, restore, stash, clean, rebase, or overwrite work;
- change only declared paths;
- create one logical commit per repository;
- record skips and failures for retry;
- verify the staged set and outgoing range before each push;
- retain per-repository and aggregate receipts.

The typed transaction schema owns these invariants. Do not encode them as an
ad hoc shell loop.

### [CI-052] Keep hard authority boundaries

Visibility flips, tags, releases, archival, destructive operations, and
third-party publication require their applicable explicit authority. A policy
rollout, canary approval, bot installation, or ordinary push grant does not
authorize those actions.

The bot must represent such actions as separate closed operation kinds and
refuse them without the required authority signal.

### [CI-056] Gate source-modifying convergence per package

When convergence changes Swift source, each repository is built through
`workspace package build --fresh` after modification and before commit/push.
Stop or skip on failure without rewriting the worktree.

Non-source changes still run their owning typed validator. A YAML or
configuration edit is not exempt from verification; it uses repository-policy
rather than a package build when that is the semantic gate.

### [CI-111] Mechanical transforms preserve existing valid forms

A typed transform must distinguish:

- source that needs transformation;
- source already in the target form;
- exempt source;
- source it cannot classify.

Unknown input fails closed. Fixtures cover all four classes. Inspect a canary
diff before fleet convergence; a post-condition alone is insufficient evidence
that meaning was preserved.

### [CI-113] Raise floors at the owner before consumers

Before raising a toolchain or manifest floor:

1. verify every central execution surface can load it;
2. land the universal/layer capability first;
3. run one full canary;
4. update typed repository policy if caller contracts changed;
5. let the bot converge consumers;
6. verify post-state and central CI.

The execution surfaces include macOS/Xcode, Linux containers, Windows setup,
SDK legs, documentation jobs, and any tool dependency required before a
manifest can load.

## Bot transaction contract

Every fleet transaction records:

- policy and executable revision;
- requested operation kind and authority class;
- measured population and exclusions;
- canary repository and result;
- pre-state, intended change, accepted mutation, and final readback;
- exact commit/path set for repository edits;
- skips, exemptions, retries, and terminal failures;
- a final receipt proving convergence or naming residuals.

Resume from the journal without repeating an accepted mutation. Re-measure live
state before any write; a plan is intent, not current-state evidence.

## Completion

A rollout is complete only when the owner is canonical, the bot path is
repeatable, the canary passed, the measured population converged or has typed
exceptions, central CI invokes the same predicate, and no manual-only
procedure remains load-bearing.
