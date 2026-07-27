---
name: github-repository
description: Define and audit GitHub repository metadata, settings, topics, visibility-sensitive content, and centralized workflow adoption. Apply whenever GitHub-side repository state or metadata changes.
---

# GitHub repository

Repository metadata is a public product surface and must have one canonical
source. Resolve live state before writing; never infer visibility or settings
from local files.

## Workflow

1. Resolve the exact `owner/repository` and current visibility with GitHub.
2. Classify the repository family, layer, maturity, and authority.
3. Read its canonical metadata source and the central repository policy.
4. Reuse the centrally owned workflow or metadata capability; do not copy it
   into the consumer.
5. Prepare the minimal local or GitHub-side change.
6. Verify schema, topics, description, homepage, license, settings, and
   workflow ownership that are in scope.
7. Re-read live GitHub state after any authorized remote mutation.

Never put machine paths, credentials, private-repository facts, or private
control-plane details in a public repository.

## Detailed rules

Load [`catalogue.md`](catalogue.md) for exact `[GH-REPO-*]` requirements,
family-specific metadata, discussion setup, topic vocabularies, license
handling, and repository-settings procedures.

## Related skills

- **readme** for repository documentation.
- **ci-cd-workflows** for reusable workflow ownership.
- **social-preview** for preview metadata and rendering.
- **release-readiness** before visibility, tag, or release changes.
