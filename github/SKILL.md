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

Visibility flips, tags, releases, archival, and destructive operations each need principal approval. Never force-push without
explicit per-action authorization.

## Repository metadata and settings

Authored metadata lives in `.github/metadata.yaml`; GitHub-side state is a derived view. Convergence runs through the bot, not
hand-run `gh repo edit`, and a nightly cron (04:00 UTC) reapplies rule defaults across every non-archived repository in every
org.

```sh
gh workflow run sync-metadata.yml -R swift-institute/.github -f repo=<owner>/<repo>
gh workflow run sync-metadata.yml -R swift-institute/.github -f repo=<owner>/<repo> -f dry-run=true
```

- Silence in the `settings:` block means "apply the rule default", not "leave whatever is on GitHub"; a divergent live value
  is reverted.
- A settings key the schema declares but the sync workflow never reads is a silent no-op — no effect, no error. Schema keys
  and workflow reads must stay in exact correspondence.
- The gear-icon "About" sidebar toggles (Releases, Packages, Deployments) are exposed by neither REST nor GraphQL,
  `gh repo edit` has no flag, and the web UI uses a private endpoint. The `sidebar:` block records intent; enforcement is a
  manual click-through per repository. Secret scanning likewise has no `gh repo edit` surface: PATCH `security_and_analysis`
  via `gh api repos/{owner}/{repo}`, public repositories only.
- Discussions default to disabled fleet-wide. A repository meant to host them — `swift-institute/.github` is the hub — must
  set `settings.hasDiscussionsEnabled: true` in its own metadata.yaml, or the nightly cron wipes the toggle and category
  visibility, and the discussion-thread workflow then fails at `createDiscussion` with an unresolvable category ID. Resolve
  categories by slug at runtime, never by ID.

## Issues and tracking

Open work goes to public issues on the repository that owns it; there is no central work register. `swift-institute/Issues`
holds minimum reproducers for Swift toolchain and compiler bugs only — a reproducer goes there even when the defect surfaced
while working elsewhere.

Blank issues are disabled org-wide. Every issue is filed through a form propagated from `swift-institute/.github`: `bug.yml`
for unexpected behaviour in Institute code, `change.yml` for a concrete actionable proposed outcome, `documentation.yml` for
documentation defects and gaps. An actionable issue needs a stated problem *and* an observable proposed outcome; an
implementation sketch alone does not satisfy the form. Change template content in `swift-institute/.github`, never
per-repository. Open-ended questions and early design work go to `https://github.com/orgs/swift-institute/discussions`.

Set an issue type on every issue: `Task`, `Bug`, or `Feature`. Labels are stock GitHub defaults and carry no Institute meaning
— do not encode routing, priority, or ownership in one, and do not mint a taxonomy without changing this rule first.

Tracking lives on one org-level board, **Institute Work**, `https://github.com/orgs/swift-institute/projects/2`, spanning
every repository. Status: Backlog, Ready, In progress, Blocked, Done. Priority: P1, P2, P3.

```sh
gh issue create -R <owner>/<repo>          # form-driven; no blank issues
gh project item-add 2 --owner swift-institute --url <issue-url>
```

Per-repository boards stay disabled: a board scoped to one repository cannot represent work that crosses the layer graph.
Enabling one requires principal authorization. Issues opened by `swift-institute-bot` report machine-detected divergence — do
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
authorization at the moment of execution: pushing a version tag, flipping visibility private → public, publishing the launch
blog post, and deploying it to `swift-institute.org`. One authorization does not carry to the next. Stage each command in its
exact executable form and surface anything that would make it fail as written.

End with a categorized verdict — **GO** (no CRITICAL or HIGH findings), **CONDITIONAL GO** (named MEDIUM findings the
principal accepts as known, each listed explicitly), or **NO-GO** (CRITICAL or HIGH findings to resolve first; escalate, do
not apply fixes).

## Swift Package Index

Do not submit a package until it is public, has a semantic-version tag, dumps a valid manifest on the launch toolchain, and
its *entire* dependency closure is likewise public, tagged, and declared in URL form. SPI resolves the full graph against
public URLs, so a listing is only as ready as its closure and one `path:` dependency anywhere fails the build. Tag leaf-first,
in topological order — a tier-N package cannot build until tier-(N−1) is tagged, public, and resolvable, so there is no
big-bang tag day. Listing itself is a PR adding the canonical URL (`https` scheme, `.git` extension, still-valid JSON) to
`packages.json` in `SwiftPackageIndex/PackageList`.

SwiftPM picks a collection trust policy by the collection URL's *host*; only `developer.apple.com` is pinned to Apple's
bundled roots. Everything else uses the default policy, whose trust store is empty on non-Apple platforms, so a *signed*
third-party collection hard-fails on Linux unless the consumer installs the DER root, while an unsigned one merely prompts.
The self-hosted unified collection therefore ships unsigned; SPI's per-owner auto-collections are SPI-signed and
macOS-optimal.

`.spi.yml` is opt-in by presence at the repository root and is docs-hosting only: `version: 1`, one `builder.configs` entry,
and `documentation_targets` listing exact `Package.swift` target names — space- and case-exact, one per public library doc
target. A mismatch produces a failed or empty doc build on the first tagged release, and nothing else in the ecosystem
consumes the file, so the defect stays latent. Omit `external_links.documentation`; SPI hosts the rendered docs. Never mirror
the CI matrix into `.spi.yml`.

## Social preview cards

GitHub exposes no REST, GraphQL, or CLI API for a repository's social preview image. The only path is browser session-cookie
automation, and that cookie is password-equivalent — broader privilege than `admin:org`. It must never live in CI secrets, so
deployment is local-only from a maintainer's machine using the maintainer's existing browser session.

Custom cards are gated to public repositories: on a private repository the Settings → Social preview element does not render
and the uploader times out on its selector, so a card cannot be prepared ahead of publication. Do not flip a repository public
for the sole purpose of deploying its card — the card is part of a publication happening for its own reasons.

After the upload response, the uploader must wait for `page.waitForLoadState("networkidle")` before closing the browser.
Without it the image id is set before the S3 PUT completes, leaving a stale `og:image` that serves HTTP 403 AccessDenied.
Verify that the public page's `og:image` returns 200 with bytes matching the local render.

Auto-fit estimates width per glyph class, not by character count, in a 640 px right-pane safe area: 0.74 em uppercase/digit,
0.57 em lowercase, 0.30 em space — a flat average underestimates all-caps strings and clips the margin. Layout priority is
full-size single line at 132 px, then the largest shrunk single line down to 84 px, then full-size two-line at 84 px. After
changing a layout constant, render the whole cohort without uploading and look at the images; count-only metrics miss
clipping.

## Package heritage

Adopt git-level fork heritage to an external upstream only when all four hold: production code closely parallels upstream's
structure and API shape; upstream's consumers materially overlap the Institute package's audience; upstream's license permits
attributed derivative works (GPL, AGPL, proprietary fail); and upstream is non-owned. If any fails, re-implement independently
with an orphan publication commit and README attribution — the correct shape, not a fallback.

An owned source repository is transferred, not forked: transfer moves the repo and carries stars, issues, PRs, and URL
redirects, collapsing the source identity into the destination, while a fork leaves the source in place, starts at zero stars
and issues, and creates a server-side parent pointer. For an upstream you do not own, transfer is impossible.

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
git push origin main                          # fast-forward; no force-push needed
```

A bare `git checkout <ref> -- .` without the preceding `git rm -rf .` does not propagate deletions — it produces a UNION of
the two trees, not a REPLACEMENT.

Attribution is a license obligation: `LICENSE.md` carries the Institute's Apache 2.0 text plus upstream's LICENSE text and
copyright notice under an `## Attribution: <upstream>` heading, and the README carries a heritage line under the one-liner
linking upstream and the divergence analysis.

Fork execution needs per-action authorization at each destructive step: vacating the destination repository, forking upstream
into the Institute org under a new name, and the visibility consequence — a fork inherits the source's visibility, so forking
a public upstream into a previously private slot *is* a public flip and needs that authorization simultaneously.
