---
name: release-readiness
description: Produce a release-readiness brief and pre-release evidence for a major or breaking package release. Apply before a first public tag, a major-version tag, or another breaking release; do not execute release actions without approval.
---

# Release readiness

This skill prepares evidence and a recommendation. Tags, releases, visibility
changes, announcements, and deployment remain separately authorized actions.

## Workflow

1. Define the exact package, intended version, release scope, and consumers.
2. Resolve repository visibility, branch, dirty state, and existing tags.
3. Verify semantic ownership, package decomposition, and reuse with
   **modularization** and **reuse-first**.
4. Audit public API, documentation, README, license, metadata, CI, linter
   adoption, and dependency form.
5. Run fresh build and test evidence through **swift-package-build**.
6. Validate representative downstream consumers for breaking changes.
7. List blockers, accepted risks, migration requirements, and irreversible
   actions.
8. Produce GO, CONDITIONAL GO, or NO-GO with evidence.

Never convert a readiness recommendation into permission to tag, publish,
change visibility, deploy, or announce.

## Detailed phases

Load [`catalogue.md`](catalogue.md) for exact `[RELEASE-*]` gates, pilot
skill-incorporation checks, dependency cascades, downstream matrices, and the
full release brief format.

## Related skills

- **swift-package-build**, **ci-cd-workflows**, and **swift-linter** for gates.
- **github-repository** and **readme** for repository surface.
- **blog-process** and **swift-forums-review** for separately authorized launch
  preparation.
