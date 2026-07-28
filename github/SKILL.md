---
name: github
description: Institute GitHub repository state — visibility and exposure, metadata and settings convergence through the bot, issues and the org project board, release gates and tagging authorization, Swift Package Index listing, social preview cards, and package fork heritage. Apply when a repository setting or visibility changes, when work is filed or tracked, or when a package is tagged, published, listed, forked, or made public. Workflow files and CI behavior belong to the ci-cd skill.
---

# GitHub

GitHub is an Institute control plane. Resolve live state before writing; route cross-repository convergence through
`swift-institute-bot`.

## Visibility and exposure

Visibility is a fact to resolve, never an assumption: run `gh repo view <owner>/<repo> --json visibility` before writing to a
repository. Never put machine paths, private-repository internals, credentials, or control-plane secrets in a public
repository. A pushed exposure is not undone by deleting the repository, branch, or commit — treat it as a credential-rotation
and disclosure event, not an editing mistake.

Before a payload crosses the machine boundary, scan all of it — commit messages, diffs, and code comments — against freshly
resolved visibility, and state which categories you searched; hygiene is never deferred to a later pass. Read every hit: a high
false-positive rate is not grounds to stop reading. Report any neighbouring exposure you decline to touch.

Visibility flips, tags, releases, archival, and destructive operations each need principal approval. Never force-push without
explicit per-action authorization.

## Shared checkouts

Never checkout, restore, reset, stash, clean, or delete over existing, dirty, untracked, or local-only work — stop and ask.

Commit with explicit pathspecs (`git commit -- <paths>`), re-read `git diff --cached --name-only` immediately before
committing, and prove isolation with `git show --stat` after. Never `git add -A`; never stash another actor's work. Run
`git log --oneline origin/main..HEAD` before every push, habitual ones included — a push is a decision about every unpushed
commit on the branch.

## Repository metadata and settings

Authored metadata lives in `.github/metadata.yaml`; GitHub-side state is a derived view. Convergence runs through the bot, not
hand-run `gh repo edit`, and a nightly cron (04:00 UTC) reapplies rule defaults across every non-archived repository in every
org.

```sh
gh workflow run sync-metadata.yml -R swift-institute/.github -f repo=<owner>/<repo>   # add -f dry-run=true to plan
```

- Silence in the `settings:` block means "apply the rule default", not "leave whatever is on GitHub"; a divergent live value
  is reverted.
- A settings key the schema declares but the sync workflow never reads is a silent no-op — no effect, no error. Schema keys
  and workflow reads must stay in exact correspondence.
- The gear-icon "About" sidebar toggles (Releases, Packages, Deployments) are exposed by no API: the `sidebar:` block records
  intent and enforcement is a manual click-through per repository. Secret scanning likewise has no `gh repo edit` surface —
  PATCH `security_and_analysis` via `gh api repos/{owner}/{repo}`, public repositories only.
- Discussions default to disabled fleet-wide; a repository meant to host them (`swift-institute/.github` is the hub) declares
  `settings.hasDiscussionsEnabled: true` in its own metadata.yaml or the nightly cron wipes the toggle and its categories.
  Resolve discussion categories by slug at runtime, never by ID.

## Issues and tracking

Open work goes to public issues on the repository that owns it; there is no central work register. `swift-institute/Issues`
holds minimum reproducers for Swift toolchain and compiler bugs only — a reproducer goes there even when the defect surfaced
while working elsewhere.

Every issue is filed through a form propagated from `swift-institute/.github`: `bug.yml`
for unexpected behaviour in Institute code, `change.yml` for a concrete actionable proposed outcome, `documentation.yml` for
documentation defects and gaps. An actionable issue needs a stated problem *and* an observable proposed outcome; an
implementation sketch alone does not satisfy the form. Change template content in `swift-institute/.github`, never
per-repository. Open-ended questions and early design work go to `https://github.com/orgs/swift-institute/discussions`.

A security-sensitive finding never appears in a public draft or a public issue: characterize it first, then route it to a
private destination.

Set an issue type on every issue: `Task`, `Bug`, or `Feature`. Labels are stock GitHub defaults and carry no Institute meaning
— never encode routing, priority, or ownership in one, and do not mint a taxonomy without changing this rule.

Tracking lives on one org-level board, **Institute Work**, `https://github.com/orgs/swift-institute/projects/2`.
Status: Backlog, Ready, In progress, Blocked, Done. Priority: P1, P2, P3.

```sh
gh issue create -R <owner>/<repo>          # form-driven; no blank issues
gh project item-add 2 --owner swift-institute --url <issue-url>
```

Per-repository boards stay disabled — a board scoped to one repository cannot represent work crossing the layer graph;
enabling one requires principal authorization. Issues opened by `swift-institute-bot` report machine-detected divergence — do
not board them and do not hand-close them; they close when the convergence that filed them lands.

## Release gates

Before a first public tag, a major tag, or any breaking release, produce evidence and a recommendation. Never convert a
readiness recommendation into permission to tag, publish, change visibility, deploy, or announce.

```sh
git ls-files | grep -E '^Audits/|^AUDIT-.*\.md$|\.swiftpm/.*xcuserdata|\.build/|DerivedData/|\.DS_Store$'
grep -nE '^\s*\.package\(path:' Package.swift        # and every nested */Package.swift
grep -nE 'branch:' Package.swift                     # branch pins convert to versions
find Sources Tests -name 'exports.swift' -exec grep -L 'This source file is part of' {} +
gh api repos/<org>/<pkg>/actions/permissions --jq .enabled   # must print true
```

Any tracked audit artifact, path-form dependency, or branch-pinned dependency is release-blocking; path form converts to URL
form the moment the sibling repository is public, even without a tag. The license-header `find`/`grep` walks *all*
`exports.swift` files, not just the umbrella module's, and the CI `lint-license-header` job is advisory, so a green run proves
nothing about coverage — this grep is the blocking control. Also verify a clean-worktree build, test, and lint on the
principal toolchain plus the L1 Embedded build where the layer requires it.

Four actions are staged but never executed on the agent's own initiative, each needing its own explicit principal
authorization: pushing a version tag, flipping visibility private → public, publishing the launch blog post, and deploying it
to `swift-institute.org`. One authorization does not carry to the next. Stage each command in its exact executable form and
surface anything that would make it fail as written.

End with a categorized verdict — **GO** (no CRITICAL or HIGH findings), **CONDITIONAL GO** (named MEDIUM findings the
principal accepts as known, each listed explicitly), or **NO-GO** (CRITICAL or HIGH findings to resolve first; escalate, do
not apply fixes).

## Swift Package Index

Do not submit a package until it is public, has a semantic-version tag, dumps a valid manifest on the launch toolchain, and
its *entire* dependency closure is likewise public, tagged, and declared in URL form — SPI resolves the full graph against
public URLs, so one `path:` dependency anywhere fails the build. Tag leaf-first,
in topological order — a tier-N package cannot build until tier-(N−1) is tagged, public, and resolvable, so there is no
big-bang tag day. Listing itself is a PR adding the canonical URL (`https` scheme, `.git` extension, still-valid JSON) to
`packages.json` in `SwiftPackageIndex/PackageList`.

SwiftPM picks a collection trust policy by the collection URL's *host*; only `developer.apple.com` is pinned to Apple's
bundled roots. Everything else uses the default policy, whose trust store is empty on non-Apple platforms, so a *signed*
third-party collection hard-fails on Linux unless the consumer installs the DER root, while an unsigned one merely prompts —
so the self-hosted unified collection ships unsigned, and SPI's per-owner auto-collections are SPI-signed and macOS-optimal.

`.spi.yml` is opt-in by presence at the repository root and is docs-hosting only: `version: 1`, one `builder.configs` entry,
and `documentation_targets` listing exact `Package.swift` target names — space- and case-exact, one per public library doc
target. A mismatch produces a failed or empty doc build on the first tagged release, and stays latent until then. Omit
`external_links.documentation`; SPI hosts the rendered docs. Never mirror the CI matrix into `.spi.yml`.

## Social preview cards

GitHub exposes no API for a repository's social preview image. The only path is browser session-cookie automation, and that
cookie is password-equivalent, so it must never live in CI secrets: deployment is local-only from a maintainer's machine
using their existing browser session.

Custom cards are gated to public repositories: on a private repository the Settings → Social preview element does not render
and the uploader times out on its selector, so a card cannot be prepared ahead of publication. Do not flip a repository public
for the sole purpose of deploying its card — the card is part of a publication happening for its own reasons.

An upload is not complete when its response returns — the image id is set before the storage write lands, so a card verified
too early serves a stale `og:image`. Verify that the public page's `og:image` returns 200 with bytes matching the local
render, and after changing any layout constant render the whole cohort and look at the images; count-only metrics miss
clipping.

## Package heritage

Adopt git-level fork heritage to an external upstream only when all four hold: production code closely parallels upstream's
structure and API shape; upstream's consumers materially overlap the Institute package's audience; upstream's license permits
attributed derivative works (GPL, AGPL, proprietary fail); and upstream is non-owned. If any fails, re-implement independently
with an orphan publication commit and README attribution — the correct shape, not a fallback.

An owned source repository is transferred, not forked — transfer carries stars, issues, PRs, and URL redirects and collapses
the source identity into the destination, where a fork leaves the source in place at zero stars with a server-side parent
pointer. For an upstream you do not own, transfer is impossible.

The fork's publication is a single commit whose *parent* is the upstream HEAD at fork time and whose *tree* is the Institute's
publication state. Upstream commits stay reachable below the fork point as the heritage record; consumers cloning see only
Institute code. An orphan commit on a fork is forbidden — the badge would claim ancestry the history does not show. Forks
never sync afterwards: no merge or rebase from upstream, no Dependabot pointed at the fork source. A wanted upstream change is
re-authored as an Institute commit.

```sh
git rm -rf .                                  # stage deletion of the upstream tree
git checkout <publication-source-ref> -- .    # bring in the publication tree
git add -A
git commit -m "Initial publication: <pkg> (fork of <upstream/repo>)"
git push origin main                          # fast-forward
```

A bare `git checkout <ref> -- .` without the preceding `git rm -rf .` does not propagate deletions — it produces a UNION of
the two trees, not a REPLACEMENT.

Attribution is a license obligation: `LICENSE.md` carries the Institute's Apache 2.0 text plus upstream's LICENSE text and
copyright notice under an `## Attribution: <upstream>` heading, and the README carries a heritage line under the one-liner
linking upstream and the divergence analysis.

Fork execution needs per-action authorization at each destructive step: vacating the destination repository, forking upstream
into the Institute org under a new name, and the visibility consequence — a fork inherits the source's visibility, so forking
a public upstream into a previously private slot *is* a public flip and needs that authorization simultaneously.
