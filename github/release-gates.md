# Release gates and package listing

Companion to the `github` skill. Read this when a package is about to be tagged,
made public, published, or submitted to the Swift Package Index.

## What a readiness pass produces

Evidence and a recommendation. A readiness recommendation never becomes
permission — the decision to tag, publish, flip visibility, deploy, or announce
is the principal's, taken separately, after reading the evidence.

Four actions are staged and never executed on the agent's own initiative:
pushing a version tag, flipping visibility private → public, publishing the
launch blog post, and deploying it to `swift-institute.org`. Each needs its own
explicit authorization, and one does not carry to the next. Stage each command
in its exact executable form, and surface anything that would make it fail as
written rather than letting the principal discover it at the prompt.

## The blocking controls

These are predicates. Each either finds something or does not, and the finding is
not a matter of opinion.

```sh
git ls-files | grep -E '^Audits/|^AUDIT-.*\.md$|\.swiftpm/.*xcuserdata|\.build/|DerivedData/|\.DS_Store$'
grep -nE '^\s*\.package\(path:' Package.swift        # and every nested */Package.swift
grep -nE 'branch:' Package.swift                     # branch pins convert to versions
find Sources Tests -name 'exports.swift' -exec grep -L 'This source file is part of' {} +
gh api repos/<org>/<pkg>/actions/permissions --jq .enabled   # must print true
```

A tracked audit artifact, a path-form dependency, or a branch-pinned dependency
is release-blocking. Path form converts to URL form the moment the sibling
repository is public — a tag is not required for that conversion, only
publication.

The license-header check walks *every* `exports.swift`, not just the umbrella
module's. CI's `lint-license-header` job is advisory, so a green run is not
coverage evidence; this grep is the control of record. Also verify a
clean-worktree build, test, and lint on the principal toolchain, plus the L1
Embedded build where the layer requires it — through Workspace, and fresh, since
a cached green is not evidence.

## The verdict

The controls are decidable; the verdict is a judgment about what the findings
mean, and it is stated as one:

- **GO** — no CRITICAL or HIGH findings.
- **CONDITIONAL GO** — named MEDIUM findings the principal accepts as known,
  each listed explicitly. A finding that is not named is not accepted.
- **NO-GO** — CRITICAL or HIGH findings to resolve first. Escalate; do not apply
  fixes inside the readiness pass, because a pass that edits what it is
  measuring no longer measures it.

## Swift Package Index

SPI resolves a package's entire dependency closure against public URLs, which is
what makes the submission bar transitive rather than local. Do not submit until
the package is public, carries a semantic-version tag, dumps a valid manifest on
the launch toolchain, and every package in its closure is likewise public,
tagged, and declared in URL form. One `path:` dependency anywhere fails the
build.

That transitivity dictates the order: tag leaf-first, in topological order. A
tier-N package cannot build until tier-(N−1) is tagged, public, and resolvable,
so there is no big-bang tag day to plan for.

Listing itself is a pull request adding the canonical URL — `https` scheme,
`.git` extension, still-valid JSON — to `packages.json` in
`SwiftPackageIndex/PackageList`.

### Collection trust is decided by host, not by signature

SwiftPM picks a collection trust policy from the collection URL's *host*. Only
`developer.apple.com` is pinned to Apple's bundled roots; everything else uses
the default policy, whose trust store is empty on non-Apple platforms. The
consequence inverts the intuition: a *signed* third-party collection hard-fails
on Linux unless the consumer installs the DER root, while an unsigned one merely
prompts. So the self-hosted unified collection ships unsigned, and SPI's
per-owner auto-collections are SPI-signed and macOS-optimal.

### `.spi.yml`

Opt-in by presence at the repository root, and docs-hosting only: `version: 1`,
one `builder.configs` entry, and `documentation_targets` listing exact
`Package.swift` target names, space- and case-exact, one per public library doc
target.

A target-name mismatch is latent — it produces a failed or empty doc build on
the first tagged release and is invisible until then, which is why it is worth
checking against the manifest rather than against memory. Omit
`external_links.documentation`; SPI hosts the rendered docs. Never mirror the CI
matrix into `.spi.yml`.
