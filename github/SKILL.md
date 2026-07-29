---
name: github
description: Institute GitHub repository state — visibility and exposure, metadata and settings convergence through the bot, issues and the org project board, research documents and where a finding is recorded, release gates and tagging authorization, Swift Package Index listing, social preview cards, and package fork heritage. Apply when a repository setting or visibility changes, when work is filed or tracked, when a finding or design rationale is written down, or when a package is tagged, published, listed, forked, or made public. Workflow files and CI behavior belong to the ci-cd skill.
---

# GitHub

GitHub is an Institute control plane. Resolve live state before writing to it, and route
cross-repository convergence through `swift-institute-bot` rather than by hand.

## Visibility and exposure

Visibility is a fact to resolve, never an assumption:

```sh
gh repo view <owner>/<repo> --json visibility
```

Run it before writing to a repository. It costs a second, and it is the only thing standing
between a private-repository internal and a public commit.

What must never reach a public repository: machine paths, private-repository internals,
credentials, and control-plane secrets. Whether a given payload contains one of those is a
judgment — but the check around it is not, so make the check unconditional. Before a payload
crosses the machine boundary, scan all of it — commit messages, diffs, code comments — against
freshly resolved visibility, and state which categories you searched. A scan whose scope is
unstated is not evidence of anything. Read every hit; a high false-positive rate is a reason
to read faster, not a reason to stop. Report any neighbouring exposure you decline to touch.

A pushed exposure is not undone by deleting the repository, branch, or commit. Treat it as a
credential-rotation and disclosure event.

Visibility flips, tags, releases, archival, and destructive operations each need principal
approval, and force-pushing needs explicit per-action authorization.

## Shared checkouts

Other sessions work in the same trees. Never checkout, restore, reset, stash, clean, or delete
over existing, dirty, untracked, or local-only work — stop and ask.

Commit with explicit pathspecs (`git commit -- <paths>`), re-read `git diff --cached
--name-only` immediately before committing, and prove isolation with `git show --stat` after.
Never `git add -A`; never stash another actor's work.

Run `git log --oneline origin/main..HEAD` before every push, habitual ones included. A push is
a decision about every unpushed commit on the branch, not only about the one you just made.

## Repository metadata and settings

Authored metadata lives in `.github/metadata.yaml`; GitHub-side state is a derived view.
Convergence runs through the bot, not a hand-run `gh repo edit`, and a nightly cron (04:00
UTC) reapplies rule defaults across every non-archived repository in every org.

```sh
gh workflow run sync-metadata.yml -R swift-institute/.github -f repo=<owner>/<repo>   # add -f dry-run=true to plan
```

- Silence in the `settings:` block means "apply the rule default", not "leave whatever is on
  GitHub". A divergent live value is reverted.
- A settings key the schema declares but the sync workflow never reads is a silent no-op — no
  effect, no error. Schema keys and workflow reads must stay in exact correspondence, and that
  correspondence is checkable by reading the two side by side; nothing checks it for you.
- The gear-icon "About" sidebar toggles (Releases, Packages, Deployments) are exposed by no
  API. The `sidebar:` block records intent, and enforcement is a manual click-through per
  repository. Secret scanning likewise has no `gh repo edit` surface — PATCH
  `security_and_analysis` via `gh api repos/{owner}/{repo}`, public repositories only.
- Discussions default to disabled fleet-wide. A repository meant to host them
  (`swift-institute/.github` is the hub) declares `settings.hasDiscussionsEnabled: true` in its
  own metadata.yaml, or the nightly cron wipes the toggle and its categories. Resolve
  discussion categories by slug at runtime, never by ID.

## Issues and tracking

Open work goes to public issues on the repository that owns it; there is no central work
register. `swift-institute/Issues` holds minimum reproducers for Swift toolchain and compiler
bugs only — a reproducer goes there even when the defect surfaced while working elsewhere.

Every issue is filed through a form propagated from `swift-institute/.github`: `bug.yml` for
unexpected behaviour in Institute code, `change.yml` for a concrete actionable proposed
outcome, `documentation.yml` for documentation defects and gaps. Change template content in
`swift-institute/.github`, never per-repository. Open-ended questions and early design work go
to `https://github.com/orgs/swift-institute/discussions` instead.

An actionable issue needs a stated problem *and* an observable proposed outcome. An
implementation sketch alone does not satisfy the form — it says what to do without saying how
anyone would know it worked.

A security-sensitive finding never appears in a public draft or a public issue. Characterize
it first, then route it to a private destination.

Set an issue type on every issue: `Task`, `Bug`, or `Feature`. Those three are the org's
enabled types; there is no fourth to choose. Labels carry no Institute meaning on human-filed
work — do not encode routing, priority, or ownership in one. They are not all stock defaults:
the sweep workflows label their bot-filed divergence reports to name which sweep filed them,
so `swift-institute/.github` carries six minted labels beside the nine GitHub ships. A sweep
that keys control flow off such a label fails silently when the label is absent — one searched
`--label` for a label that had never been created, so its close-when-clean path could not fire
even on a clean fleet. Match the issue title instead.

Tracking lives on one org-level board, **Institute Work**,
`https://github.com/orgs/swift-institute/projects/2`.

```sh
gh issue create -R <owner>/<repo>          # form-driven; no blank issues
gh project item-add 2 --owner swift-institute --url <issue-url>
```

The board defines Status and Priority fields and **no item on it sets either** — every row is
unset. This skill used to print their vocabulary as convention, which made setting Status look
like the practice. It is not: doing so produces the only classified row on an otherwise
unclassified board, where it compares to nothing and therefore says nothing. Add the item and
leave the fields alone. If the board is ever given a vocabulary that is used, it will arrive
with something enforcing it rather than as prose here.

Per-repository boards stay disabled — a board scoped to one repository cannot represent work
crossing the layer graph; enabling one requires principal authorization. Issues opened by
`swift-institute-bot` report machine-detected divergence: do not board them and do not
hand-close them, since they close when the convergence that filed them lands.

## Research and findings

A finding goes to the `Research/` directory of the repository that owns it.
`swift-institute/Research` holds findings whose conclusions are not one package's to act on —
cross-package and ecosystem-wide work, and the arrangement of the ecosystem itself. Most packages
already carry their own `Research/`; the central repository is the named exception, not the
default destination.

Ownership follows conclusions, not occasion. Ask what would have to change if the finding were
acted on: one package makes it that package's, more than one makes it central. The Embedded-Wasm
feasibility paper was written to answer a question about `swift-html`, but its conclusions are a
172-package closure and blockers spread across all three layers — central research that a
`swift-html` question occasioned. A document has one home; the repository that occasioned it
links to it rather than holding a copy.

Every `Research/` directory carries an `_index.json` manifest, and scope is recorded there. In a
package the manifest declares scope once for the whole directory; centrally each document declares
its own, because reach varies document to document. Roughly half the central entries leave it
unset, so the field does not yet answer the ownership question for work already filed — recording
it as documents are added is what makes the answer readable without re-reading the document.

Research and issues are one question asked of different objects: what would have to change. An
issue is what someone must do — it meets the filing bar above and goes to whoever must act.
Research is what was learned, and goes where its conclusions reach; one document can raise issues
on several owners and still be central itself. A finding that raises no issue is finished work
with a home, not a loose end: the manifest's status vocabulary carries recommendations, decisions
and deferrals so that a document nobody must act on today is filed rather than left open. A
question with no finding behind it yet is neither, and goes to org discussions.

One half of this is checkable and one is not. Whether a document states a problem and an
observable proposed outcome for a named repository can be settled by reading it, and so can
whether a manifest entry records a scope. Whether a finding's conclusions reach one package or
several is judgement, and nothing checks it.

`Research/` holds reasoning, not instruments. A script that produces a measurement is source: it
belongs with the package's own sources, or in `swift-institute/Experiments` alongside the
standalone packages that back technical claims. The document interpreting the measurement is the
research. This holds for every package including the workspace coordinator, whose `Research/`
keeps its design corpus and stays for the same reason any package's does.

## Social preview cards

GitHub exposes no API for a repository's social preview image. The only path is browser
session-cookie automation, and that cookie is password-equivalent — so it must never live in
CI secrets. Deployment is local-only, from a maintainer's machine, using their existing
browser session.

Custom cards are gated to public repositories: on a private repository the Settings → Social
preview element does not render and the uploader times out on its selector, so a card cannot
be prepared ahead of publication. Do not flip a repository public in order to deploy its card
— the card is part of a publication happening for its own reasons.

An upload is not complete when its response returns. The image id is set before the storage
write lands, so a card verified too early serves a stale `og:image`. Verify that the public
page's `og:image` returns 200 with bytes matching the local render. After changing any layout
constant, render the whole cohort and look at the images — count-only metrics miss clipping.

## Elsewhere

- Tagging, publication, and Swift Package Index submission — [release-gates.md](release-gates.md).
- Fork heritage, transfers, and attribution — [package-heritage.md](package-heritage.md).
- Workflow files and CI behavior — the `ci-cd` skill.
