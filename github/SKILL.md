---
name: github
description: Institute GitHub repository state — visibility and exposure, metadata and settings convergence through the bot, issues and the org project board, release gates and tagging authorization, Swift Package Index listing, social preview cards, and package fork heritage. Apply when a repository setting or visibility changes, when work is filed or tracked, or when a package is tagged, published, listed, forked, or made public. Workflow files and CI behavior belong to the ci-cd skill.
---

# GitHub

GitHub is an Institute control plane. Resolve live state before writing to it, and route
cross-repository convergence through `swift-institute-bot` rather than by hand.

## Route package behavior separately from Institute control-plane integration

The repository that owns a reusable package owns its portable functionality: formats,
reporters, rule execution, and autofix mechanics. Institute-specific workflow wiring,
GitHub mutations, Issue and Project admission, bot identity and permissions, rate-limit
policy, and cross-repository control-plane automation belong to `swift-institute/.github`.
A tool being consumed by CI does not make it the owner of the Institute integration around
that tool. If a proposal mixes these concerns, split it into exact-owner work items and
cross-link them. For example, `swift-foundations/swift-linter#9` routes the general linter
question to the linter repository, while the Institute integration is tracked by
`swift-institute/.github#83`.

Workflow structure and CI behavior remain governed by the [CI/CD skill](../ci-cd/SKILL.md);
this skill owns the GitHub control-plane boundary and its mutations.

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

**The `--name-only` read-back is necessary and not sufficient — keep it, and add `git diff
--quiet`.** `--name-only` answers *"is this path in the commit?"* The question that matters is
*"does the committed blob match my working tree?"* Those differ precisely for renamed-then-edited
files, because `git mv` stages the rename and later content edits are not staged — so the path
appears in the read-back on the strength of its rename alone, with an old body. That is every
file in a rename refactor, i.e. exactly the operation this guard exists for. It has now shipped a
non-compiling commit twice, the second time to a session that had read the warning that morning
and was actively trying to avoid it.

After staging and before committing, run `git diff --quiet`: a clean exit means the index matches
the working tree, and anything else names what would be left behind. It also catches the other
failure mode explicit pathspecs invite — omitting a directory outright, which is easy when you
enumerate paths by hand. Then verify against the committed tree, never the worktree:

```sh
git diff --quiet || git diff --name-only     # nothing left unstaged
git show HEAD:<path>                         # the blob that actually shipped
git grep -n '<old-token>' HEAD -- .          # plus a positive control
```

A local build, test run and lint pass can all be green against a correct working tree while the
commit is wrong. No amount of pre-commit testing detects this; only reading the committed tree
does.

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

Every actionable human work item has exactly one live technical work object: an Issue in the
repository that exactly owns the work. The Issue is the sole authority for the problem and
observable outcome, assignees, native hierarchy and dependencies, discussion and history,
linked implementation, open or closed state and close reason, and completion or cancellation.
Do not copy any of those facts into another work record.

`Workspace` Issues own only technical work whose exact owner is `Workspace`.
`swift-institute/Issues` owns only isolated Swift compiler or toolchain reproducers and
maintenance of that repository — a reproducer goes there even when the defect surfaced while
working elsewhere. Neither repository is a central programme register.

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
work — do not encode routing, priority, ownership, or programme state in one. They are not all
stock defaults:
the sweep workflows label their bot-filed divergence reports to name which sweep filed them,
so `swift-institute/.github` carries six minted labels beside the nine GitHub ships. A sweep
that keys control flow off such a label fails silently when the label is absent — one searched
`--label` for a label that had never been created, so its close-when-clean path could not fire
even on a clean fleet. Match the issue title instead.

Programme admission and programme priority live on one org-level Project, **Institute Work**,
`https://github.com/orgs/swift-institute/projects/2`.

```sh
gh issue create -R <owner>/<repo>          # form-driven; no blank issues
gh project item-add 2 --owner swift-institute --url <issue-url>
```

An actionable Issue's one authoritative Project membership edge is its sole programme
admission fact. One Project-only `Priority` is its sole programme priority fact. Membership
and Priority are the only Project-owned facts. Never copy Priority to labels, milestones,
Issue bodies, or another Project. The Project's built-in columns for Issue facts are live
views of that same Issue object, not copied stores.

Issue open or closed state plus close reason is the sole completion state. Keep built-in
Status unset: there is no Project `Done`, `Cancelled`, or `Blocked` mirror. Do not add Phase.
The open Programme view derives from `is:issue is:open`; Active work derives from open Issues
with assignees; and programme history remains visible in a Done view derived from
`is:issue is:closed reason:completed`. Do not copy these Issue facts into Project fields.

A genuine completed exact-owner Issue remains a Project row: completion ends the work, not
its programme membership or history. A superseded, stale, duplicate, or routing predecessor
closed as not planned has no Project row. Removal of those rows is authority cleanup, not a
second completion signal. Inspect Project fields and item values live when operating on them;
do not freeze their inventory, options, or implementation-time availability in doctrine.

Draft Project items are ephemeral intake. Convert an accepted draft to its exact-owner Issue
before it becomes actionable, and never retain both. Pull requests are normally linked
implementation for the Issue, not additional Project rows.

Each programme item belongs to exactly one authoritative Project. Multiple Projects are
permitted only when deterministic, non-overlapping governance, access, or lifecycle scopes
give every item exactly one home. Never create mirrored portfolio views, overlapping
memberships, or fields that must synchronize across Projects. Per-repository Projects remain
disabled unless such a scope has principal approval.

Issues opened by `swift-institute-bot` report machine-detected convergence or divergence.
Keep them off Project and never hand-close them; their owning workflow closes them when the
reported state converges.

Project descriptions contain the stable authority contract and links to canonical doctrine.
Do not put volatile counts, copied rulings, live field inventories, or other programme facts
in a description.

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
