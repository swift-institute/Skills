# Package heritage

Companion to the `github` skill. Read this when an Institute package derives from
an external upstream, or when an owned repository is moving to a new home.

## Fork, or re-implement

Adopt git-level fork heritage only when all four hold:

- production code closely parallels upstream's structure and API shape;
- upstream's consumers materially overlap the Institute package's audience;
- upstream's license permits attributed derivative works — GPL, AGPL, and
  proprietary licences fail;
- upstream is non-owned.

If any fails, re-implement independently, with an orphan publication commit and
README attribution. That is the correct shape for that case, not a consolation
prize: a fork badge asserts an ancestry, and asserting one the code does not have
is the defect the four conditions exist to prevent.

The licence condition is the one a predicate can settle — read upstream's
LICENSE. The other three are judgment, and they are the reason this is a
decision rather than a checklist.

## Transfer, not fork, for something you own

An owned source repository is *transferred*. Transfer carries stars, issues,
pull requests, and URL redirects, and collapses the source identity into the
destination. A fork instead leaves the source in place at zero stars with a
server-side parent pointer — two identities where there was one.

For an upstream you do not own, transfer is not available, which is what the fork
path is for.

## The publication commit

The fork's publication is a single commit whose *parent* is the upstream HEAD at
fork time and whose *tree* is the Institute's publication state. Upstream commits
stay reachable below the fork point as the heritage record; consumers cloning see
only Institute code.

An orphan commit on a fork is the one shape to avoid — the badge would claim an
ancestry the history does not show.

```sh
git rm -rf .                                  # stage deletion of the upstream tree
git checkout <publication-source-ref> -- .    # bring in the publication tree
git add -A
git commit -m "Initial publication: <pkg> (fork of <upstream/repo>)"
git push origin main                          # fast-forward
```

The `git rm -rf .` is load-bearing. A bare `git checkout <ref> -- .` without it
does not propagate deletions: the result is the UNION of the two trees, not a
replacement, and it looks correct until someone notices upstream files that
should have gone.

Forks never sync afterwards — no merge or rebase from upstream, no Dependabot
pointed at the fork source. A wanted upstream change is re-authored as an
Institute commit.

## Attribution

This is a licence obligation, not a courtesy. `LICENSE.md` carries the
Institute's Apache 2.0 text plus upstream's LICENSE text and copyright notice
under an `## Attribution: <upstream>` heading, and the README carries a heritage
line under the one-liner linking upstream and the divergence analysis.

## Authorization

Fork execution needs per-action authorization at each destructive step: vacating
the destination repository, and forking upstream into the Institute org under a
new name.

The visibility consequence is easy to miss and needs its authorization at the
same moment: a fork inherits the *source's* visibility, so forking a public
upstream into a previously private slot **is** a public flip.
