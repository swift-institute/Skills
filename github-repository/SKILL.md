---
name: github-repository
description: Define, audit, and converge Swift Institute GitHub repository metadata, settings, community-health inheritance, and Actions posture. Apply whenever GitHub-side state or cross-repository policy changes.
---

# GitHub repository

Treat GitHub as an Institute control plane, not a collection of repository
settings to maintain by hand. Resolve live state before writing and route
cross-repository convergence through `swift-institute-bot`.

## Decision order

1. Resolve the exact `owner/repository`, visibility, archive state, and current
   setting from GitHub.
2. Identify the Institute-owned typed policy product for the concern.
3. Prefer organization inheritance or a centralized reusable workflow over a
   repository-local file.
4. Use `swift-institute-bot` for cross-repository reads, writes, convergence,
   canaries, and receipts.
5. Add package-local GitHub configuration only when the typed repository
   policy explicitly admits its class.
6. Re-read live state and retain the bot receipt after an authorized mutation.

Never put machine paths, credentials, private-repository internals, or
control-plane secrets in a public repository.

## Actions are deny-by-default

The repository-policy Swift product owns the GitHub Actions whitelist. A
package repository may host or invoke only:

- an explicitly allowed package-local trigger and thin caller;
- an explicitly allowed tool-owned reusable workflow or action;
- a typed, justified exemption with the narrowest repository and path scope.

Everything else moves to the centralized Institute workflows or is mediated by
`swift-institute-bot`. Do not infer permission from an existing workflow,
another repository, a copied template, or a successful run.

The validator owns YAML parsing, reusable-contract checking, action-reference
classification, diagnostics, and exemption matching. This skill owns the
judgment: whether behavior is genuinely package-local, reusable tool surface,
or Institute control-plane work.

## Ownership boundaries

| Concern | Owner |
| --- | --- |
| repository metadata and settings policy | repository-policy Swift product |
| cross-repository convergence | `swift-institute-bot` |
| organization community-health defaults | organization `.github` repository, converged by the bot |
| shared CI behavior | centralized and layered reusable workflows |
| package event wiring | whitelisted thin caller |
| Swift source conventions | swift-linter |
| local checkout facts | Workspace doctor |

## Detailed judgment

Load [`catalogue.md`](catalogue.md) only for metadata rationale, repository
classes, editorial choices, and exception history. Treat live schemas,
repository-policy diagnostics, Workspace facts, and central CI as the
mechanical authority.

## Related skills

- **ci-cd-workflows** for workflow ownership and the Actions whitelist.
- **readme** for repository documentation.
- **social-preview** for preview metadata and rendering.
- **release-readiness** before visibility, tag, or release changes.
