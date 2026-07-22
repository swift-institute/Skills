---
name: swift-package-heritage
description: |
  Git-level heritage for Institute packages derived from external upstream Swift packages.
  ALWAYS apply when seeding from an external upstream, deciding fork vs re-implement, or formalizing lineage at the git/GitHub level.

layer: architecture

requires:
  - swift-institute
  - swift-package

applies_to:
  - swift
  - swift6
  - swift-primitives
  - swift-standards
  - swift-foundations

created: 2026-04-30
---

# Swift Package Heritage

Git-level heritage shape for Institute packages whose design materially
derives from an external (non-owned) upstream Swift package. The rules
here govern *whether* to fork and *how* to compose the fork relationship
with the Institute's publication-squash discipline.

This skill is distinct from:

| Concern | Skill / artifact |
|---|---|
| Owned-source heritage (coenttb/* → swift-foundations/* via `gh api .../transfer`) | [`coenttb-ecosystem-heritage-transfer-plan.md`](../../Research/coenttb-ecosystem-heritage-transfer-plan.md) (Tier 2 RECOMMENDATION) |
| Git-history mechanics (squash, transfer, force-push discipline) | [`git-history-transfer-patterns.md`](../../Research/git-history-transfer-patterns.md) (Tier 2 RECOMMENDATION) |
| Per-package divergence rationale (what differs from upstream and why) | Per-package `Research/comparative-analysis-<upstream>.md` |
| Package shape / naming conventions | `swift-package` skill — `[PKG-NAME-*]`, `[PKG-DEP-*]` |
| Publication-readiness (single-commit publication discipline) | `release-readiness` skill |

`swift-package-heritage` governs the *origin* of the publication, not
its *content*.

---

### [HERITAGE-001] When the Fork-as-Heritage Rule Fires

**Statement**: An Institute package SHOULD adopt git-level fork heritage
to an external upstream IFF **all four** conditions hold:

| Condition | Test |
|---|---|
| Material lineage | Production code closely parallels upstream's structure / API shape / type signatures. The Institute package is recognizably "the same family" of type or function, even if every divergence is principled. |
| Community / consumer overlap | Some material fraction of upstream consumers would also be candidates for the Institute package. Heritage signal is consumer-trust capital; if the audiences don't overlap, the signal does no work. |
| License compatibility | Upstream license (MIT, BSD, Apache 2.0) permits derivative works with attribution. GPL / AGPL / proprietary licenses fail this test — fork would create license-compliance burden the Institute is not equipped to carry. |
| Upstream is non-owned | We do not have admin access to the upstream repo — `gh api .../transfer` is unavailable. (Owned-source heritage is governed by [`coenttb-ecosystem-heritage-transfer-plan.md`](../../Research/coenttb-ecosystem-heritage-transfer-plan.md), not this skill.) |

When **any** of the four fails, the Institute package SHOULD use
**independent re-implementation** (orphan publication commit; no shared
git ancestry) with README + research-doc attribution as the sole
heritage record.

**Example (fires)**: `swift-tagged-primitives` derives from
`pointfreeco/swift-tagged`. Production code closely parallels upstream's
`Tagged<Tag, RawValue>` structure (every divergence — `~Copyable`,
`~Escapable`, Foundation-independence — is principled but builds on the
same conceptual seed). Consumers of phantom-typed wrappers in the Swift
community know upstream first; the audiences overlap. Upstream is MIT
(permissive). Upstream is Point-Free, non-owned. All four conditions
hold → fork-as-heritage.

**Example (does not fire)**: `swift-carrier-primitives` originates
entirely within the Institute (super-protocol generalization of
`RawRepresentable` + the `Carrier<Underlying>` cascade). No external
upstream lineage → independent (Option 1).

**Example (does not fire — owned)**: `coenttb/swift-html` →
`swift-foundations/swift-html` is owned-source heritage transfer, not
external-upstream fork. Governed by the heritage-transfer plan, not this
skill.

**Cross-references**: [`external-upstream-fork-heritage.md`](../../Research/external-upstream-fork-heritage.md) §Outcome (decision test).


---

### [HERITAGE-002] Fork-as-Heritage Shape Composes with Publication Squash

**Statement**: When [HERITAGE-001] fires, the Institute publication
MUST be a **single commit on top of the fork point** — the upstream's
HEAD at fork-creation time. The publication commit's *parent* is the
upstream commit; the publication commit's *tree* is the Institute's
publication state (replacing all upstream files). Subsequent Institute
work (Phase 7a-style revalidations, post-publication remediation, etc.)
is layered on top of the publication commit per the regular
release-readiness discipline.

**Shape**:

```
[upstream history, intact, fully reachable via `git log`]
    │
    ◇ ← <fork-point-commit> (upstream's HEAD when forked)
    │
    ◇ ← Initial publication: <pkg> (fork of <upstream/repo>) [Institute]
    │   parent: <fork-point-commit>
    │   tree: Institute publication state (replaces all upstream files)
    │
    ◇ ← (subsequent Institute work, optional)
```

**Rationale**: The upstream commits remain in `git log` below the fork
point — this is the heritage record. The publication commit's tree is
self-contained — consumers cloning the Institute repo see the
Institute's code, not upstream's. The parent-pointer chain encodes the
lineage; the tree contents encode the Institute's content. The two
dimensions are orthogonal: a future reader curious about "where did
this come from" walks `git log`; a build / test consumer just sees the
publication state.

**Forbidden alternatives**:

| Anti-pattern | Why forbidden |
|---|---|
| **Orphan publication on a fork** | Fork badge says "forked from X" but `git log` shows no shared ancestry — confusing to consumers; defeats the heritage signal that fork was supposed to provide. If you don't want git ancestry, use independent re-implementation (no fork badge, no half-signal). |
| **Mirror-and-sync** (`git merge upstream/main`) | The Institute package diverges deliberately. Live merging upstream changes contradicts the divergence stance; produces merge-noise commits with no semantic value. |
| **Publication squash that drops the parent pointer** (`git checkout --orphan` followed by force-push to fork's `main`) | Same defect as orphan-publication-on-a-fork: badge ≠ ancestry. |

**Recipe** (from a fresh local clone of the fork at the fork-point HEAD):

```bash
# Inside the cloned fork at fork-point HEAD:
git rm -rf .                                  # stage deletion of upstream tree
git checkout <publication-source-ref> -- .    # bring in Institute publication tree
git add -A                                    # ensure deletion+addition both staged
git commit -m "Initial publication: <pkg> (fork of <upstream/repo>)"
git push origin main                          # regular push (fork's main was at fork point; we added one commit on top)
```

The Institute publication commit appears as a fast-forward on the fork.
No force-push needed at this step.

**Plumbing alternative** (atomic; reserve for cases where transient
states between `rm` and `checkout` are unacceptable):

```bash
TREE=$(git rev-parse <publication-source-ref>^{tree})
NEW=$(git commit-tree $TREE -p HEAD -m "Initial publication: <pkg> (fork of <upstream/repo>)")
git update-ref HEAD $NEW
git checkout -- .
git push origin main
```

Both produce identical results. See
[`coenttb-ecosystem-heritage-transfer-plan.md`](../../Research/coenttb-ecosystem-heritage-transfer-plan.md)
§"Apply-on-top recipe notes" for the empirical reproduction history of
this recipe shape (the bare `git checkout ref -- .` form does NOT
propagate deletions and produces a UNION not a REPLACEMENT — verified
2026-04-23).

**Cross-references**: `release-readiness` skill (publication-squash
discipline composes); [`git-history-transfer-patterns.md`](../../Research/git-history-transfer-patterns.md)
§B (squash recipe table).


---

### [HERITAGE-003] Attribution + License Discipline

**Statement**: When [HERITAGE-001] fires, the Institute package's
LICENSE, README, GitHub repo description, and Research/ MUST encode
attribution per the table below. The attribution discipline is
load-bearing for license compliance (MIT and similar permissive
licenses require attribution preservation in derivative works) and for
the heritage signal the fork relationship is meant to convey.

| Artifact | Required content | Mechanism |
|---|---|---|
| **`LICENSE.md`** | Combined Apache 2.0 (Institute) + upstream LICENSE text + upstream copyright notice. | Append upstream LICENSE text + copyright notice to the Institute's Apache-2.0 LICENSE.md, separated by `---` and a heading like `## Attribution: <upstream>`. Reference both in the README. |
| **`README.md`** | Top-of-README heritage line directly under the one-liner: `> Forked from [<upstream/repo>](url) — see [<comparative-analysis>](./Research/...) for divergence rationale.` | Markdown blockquote; explicit link to upstream + link to per-package comparative analysis. |
| **`Research/comparative-analysis-<upstream>.md`** | Per-package divergence analysis (what differs from upstream and why each divergence is principled). Tier 2 DECISION typical. | Pre-existing or authored at fork time; required reading for the decision to fork. |
| **GitHub repo description** | Brief acknowledgement of the fork relationship (e.g. "Phantom-typed value wrappers — fork of pointfreeco/swift-tagged with `~Copyable` and Foundation-independence."). | `gh repo edit --description "<text>"` |

**Examples**:

**Correct (LICENSE.md combined)**:
```markdown
# License

Copyright 2026 The Swift Institute

Licensed under the Apache License, Version 2.0 (the "License");
[... full Apache 2.0 text ...]

---

## Attribution: pointfreeco/swift-tagged

This package is a fork of [pointfreeco/swift-tagged](https://github.com/pointfreeco/swift-tagged).
The original work is licensed under the MIT License:

> MIT License
>
> Copyright (c) 2018 Point-Free, Inc.
> [... full MIT text ...]
```

**Correct (README top)**:
```markdown
# Tagged Primitives

![Development Status](...)

Phantom-typed value wrappers for zero-cost type safety [...].

> Forked from [pointfreeco/swift-tagged](https://github.com/pointfreeco/swift-tagged) —
> see [comparative-analysis-pointfree-swift-tagged.md](./Research/comparative-analysis-pointfree-swift-tagged.md)
> for the dimension-by-dimension divergence rationale.

---
```

**Incorrect (no LICENSE attribution)**:
```markdown
# License

Apache 2.0. Copyright 2026 The Swift Institute.
```
(Missing upstream MIT text + copyright — fails MIT compliance even if
the repo has a fork badge.)

**Incorrect (README mentions upstream casually but no fork acknowledgement)**:
```markdown
# Tagged Primitives

[...] verified in `Experiments/tagged-zero-cost-codegen` [...]
*Inspired by Point-Free's swift-tagged but with material divergences.*
```
(The "inspired by" framing is the *independent* attribution shape — not
the *fork* shape. If the repo IS a fork, the README must say so directly.)

**Cross-references**: `readme` skill `[README-014]` (related packages
discipline — heritage line is a peer obligation).


---

### [HERITAGE-004] Divergence Policy — No Upstream Merges

**Statement**: After [HERITAGE-002] establishes the fork+publication
shape, the Institute package and its upstream MUST NOT sync.
Specifically:

- **No `git merge upstream/main`**: divergence is principled and permanent.
- **No `git pull --rebase upstream/main`**: same.
- **Upstream releases / tags do not propagate**: the Institute tags its
  own releases (`0.1.0`, etc.); upstream tags remain visible in
  `git tag` but are not the Institute's release line.
- **Upstream commits remain in `git log` below the fork point**: this
  is the heritage record, not a live tracking mechanism.

**If the Institute wants an upstream change**: an Institute commit
re-authors the change, optionally citing the upstream commit SHA in the
Institute commit message. The fork relationship is heritage-only;
substantive code flows are re-authored, not merged.

**Rationale**: The Institute's primitives layer carries constraints that
upstream does not (Foundation-independence, `~Copyable` admission,
operator-non-forwarding-as-feature, etc.). Upstream changes are net-
negative-or-zero relative to those constraints — even when an upstream
fix is desirable, the right shape for the Institute usually requires
re-authoring rather than merging. Avoiding the merge keeps the
publication's commit-graph linear and the divergence-rationale legible.

**Forbidden patterns**:

| Anti-pattern | Why forbidden |
|---|---|
| Periodic `git merge upstream/main` ("staying current") | Produces merge-noise commits with no semantic value; obscures the divergence. |
| `dependabot.yml` configured to track upstream | Dependabot is for dependencies, not for fork-source tracking. Misuse. |
| Re-applying every upstream change as an Institute commit ("ports") | Subordinates Institute design to upstream's release cadence. The Institute decides what to port and when, not the upstream. |

**Permitted**:

- Periodic *manual* review of upstream changes for "is this worth
  porting?" — a comparative-analysis update reflects the result.
- Citing a specific upstream commit SHA in an Institute commit message
  when the Institute commit re-authors / ports a specific upstream
  change. (Optional; useful when the lineage is direct.)

**Cross-references**: `swift-package` skill — package independence
norms.


---

### [HERITAGE-005] Distinguishing Fork Heritage from Owned-Source Transfer

**Statement**: The fork-as-heritage shape ([HERITAGE-001] – [HERITAGE-004])
applies *only* to non-owned external upstream. Owned-source heritage
(an Institute-org package whose ancestor is in `coenttb/*` or another
Institute-controlled org) is governed by
[`coenttb-ecosystem-heritage-transfer-plan.md`](../../Research/coenttb-ecosystem-heritage-transfer-plan.md)
and uses **`gh api .../transfer`** (preserves stars, issues, PRs, URL
redirects), NOT `gh repo fork`.

**Decision triage**:

| Question | If yes | If no |
|---|---|---|
| Do we have admin access to the source repo (`gh api repos/<src> -X PATCH ...` works)? | Owned-source path: see [`coenttb-ecosystem-heritage-transfer-plan.md`](../../Research/coenttb-ecosystem-heritage-transfer-plan.md). Use `gh api .../transfer`. | Non-owned path: this skill applies. Use `gh repo fork`. |
| Do we want to preserve stars / issues / PRs / external `Package.resolved` resolution from the source? | Owned-source / transfer is the only mechanic that does this. | Fork is fine — no stars or PRs to preserve. |
| Will the source repo continue existing as a separate authoritative project? | Fork heritage is appropriate (upstream remains the live Point-Free / external project; we are a derivative). | Transfer is appropriate (source repo's identity collapses into the destination). |

**Rationale**: `gh api .../transfer` and `gh repo fork` are different
GitHub mechanics with different semantics:

- **Transfer**: source repo *moves* to destination org; same repo,
  redirects from old URL; stars / PRs / issues all move; ownership
  changes. Source URL becomes a redirect.
- **Fork**: source repo stays where it is; destination is a new repo
  with a parent-pointer to the source; stars / PRs / issues do NOT
  move (fork starts at 0); both URLs exist independently.

For an external upstream we don't own, transfer is impossible; fork is
the only mechanic that produces a server-side parent-pointer
relationship.

**Cross-references**: [`coenttb-ecosystem-heritage-transfer-plan.md`](../../Research/coenttb-ecosystem-heritage-transfer-plan.md)
(owned-source case); [`git-history-transfer-patterns.md`](../../Research/git-history-transfer-patterns.md)
§A (transfer-vs-fork comparison).


---

### [HERITAGE-006] Negative Space — When Independent Re-Implementation Is Right

**Statement**: When [HERITAGE-001]'s four-condition test does not all
hold, the Institute package SHOULD use **independent re-implementation**
(orphan publication commit; no shared git ancestry) with README +
research-doc attribution as the sole heritage record. The independent
shape is not a fallback — it is the *correct* shape for these cases:

| Case | Why independent is right |
|---|---|
| Institute package's design originates entirely within the Institute (no external lineage) | There is no heritage to encode; fork would invent one. |
| Lineage is "we read the README and got an idea" (concept-level, not implementation-level) | The fork badge would imply implementation derivation; "we reimplemented inspired by X" is honest documentation, not git ancestry. |
| Upstream license incompatible with Apache 2.0 (GPL, AGPL, proprietary) | License-compliance burden the Institute is not equipped to carry; fork creates the burden. |
| Upstream archived / abandoned / no live community | The heritage signal does no work — the audiences don't overlap because upstream has no live audience. README citation suffices. |
| API surface differs structurally (we use Carrier-cascade and they use RawRepresentable, e.g.) | The "same family" criterion of [HERITAGE-001] fails; calling it a fork misleads consumers about the relationship. |

**Independent attribution shape** (when [HERITAGE-006] applies):

- README: bullet-style attribution in Key Features ("Inspired by [X]")
  or a "Related Packages" entry; not a top-of-README heritage line.
- Research/: comparative-analysis doc may exist but its framing is
  "comparison to a related project," not "rationale for forking."
- LICENSE: Apache 2.0 only; no upstream LICENSE attribution required
  (because no derivative-works claim is made).
- GitHub: no fork badge; repo description does not call out a fork
  relationship.

---

### [HERITAGE-007] Per-Action Authorization for Fork Execution

**Statement**: Executing the fork-as-heritage workflow ([HERITAGE-001]
fires + [HERITAGE-002] applies) involves at least three destructive
GitHub-side operations, each requiring its own explicit per-action
authorization per `feedback_no_public_or_tag_without_explicit_yes`:

| Step | Operation | Authorization required |
|---|---|---|
| 1 | Vacate destination repo (delete or rename existing Institute repo) | `YES DO NOW DELETE <repo>` (or rename auth) |
| 2 | Fork upstream into Institute org with rename | `YES DO NOW FORK <upstream> AS <new-name>` |
| 3 | Public visibility flip (fork inherits source visibility; if upstream is PUBLIC, the new fork is PUBLIC immediately on creation) | If upstream PUBLIC + Institute repo was PRIVATE, the fork operation IS the public flip. Requires `YES DO NOW PUBLIC <repo>` simultaneously with the fork auth. |

The Institute publication-squash on top of the fork ([HERITAGE-002]
recipe) is non-destructive (regular fast-forward push); does not
require separate auth beyond the workflow's start.

**Recovery path**: at every step before step 2, the unwind is "do
nothing" (no GitHub state has changed). After step 2, the unwind is
"delete the fork; restore the original Institute repo from the local
recovery tag." Unwinding is reversible *as long as no consumer has
bound to the new URL* — once external consumers have updated their
`Package.swift` to the new URL, unwinding requires consumer-side
coordination.

**Cross-references**: `feedback_no_public_or_tag_without_explicit_yes`
(memory entry); `release-readiness` skill `[RELEASE-004]`.


---

## Provenance

- Research: [`external-upstream-fork-heritage.md`](../../Research/external-upstream-fork-heritage.md)
  (Tier 2 RECOMMENDATION, 2026-04-30, v1.0.0). The skill codifies the
  RECOMMENDATION's rules into normative form.
- Concrete instance that surfaced the rule:
  `swift-tagged-primitives` ↔ `pointfreeco/swift-tagged` (2026-04-30
  user direction).

## Related Skills

| Skill | Relationship |
|---|---|
| `swift-package` | Package shape / naming conventions. This skill governs the *origin* of the publication shape; `swift-package` governs the shape's content. |
| `release-readiness` | Publication-squash discipline. The Institute publication commit produced by [HERITAGE-002] composes with the regular release-readiness workflow — the publication just has a parent (fork point) instead of being orphan. |
| `readme` | `[README-014]` Related Packages discipline composes with [HERITAGE-003] attribution discipline; the fork-heritage line is a peer obligation. |
| `audit` | `/audit` invocations on a forked package check `[HERITAGE-001]`–`[HERITAGE-006]` against the package state in addition to the regular code-surface / implementation rules. |

## Cross-Skill References

- [`coenttb-ecosystem-heritage-transfer-plan.md`](../../Research/coenttb-ecosystem-heritage-transfer-plan.md)
  — owned-source heritage; this skill's complement.
- [`git-history-transfer-patterns.md`](../../Research/git-history-transfer-patterns.md)
  — git mechanics; this skill applies its recipes to the fork case.
- Per-package `Research/comparative-analysis-<upstream>.md` — per-package
  divergence content. Required when [HERITAGE-001] fires.
