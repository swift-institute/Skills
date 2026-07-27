---
name: ci-cd-workflows
description: Design, change, or audit Swift Institute CI, reusable workflows, matrices, security, and cross-repository rollouts. Apply whenever CI behavior or workflow ownership changes.
---

# CI/CD workflows

CI is a centralized execution system, not a collection of copied repository
scripts. This hub supplies the architecture and decision order. Load one
companion only when its topic becomes active.

## Ownership

### [CI-OWNER] Put each behavior at one executable owner

Choose the narrowest owner whose change reaches every intended consumer:

| Concern | Owner |
| --- | --- |
| universal build, test, format, lint, and docs behavior | Institute reusable workflow |
| layer-specific verification | layer wrapper |
| repository trigger and concurrency | thin consumer caller |
| Swift source predicate | swift-linter rule pack |
| package graph or manifest predicate | owning Swift package-analysis product |
| workspace facts and local orchestration | Workspace |

GitHub Actions YAML schedules and wires these owners. Custom validation logic
must be implemented and tested in Swift, not embedded as Python, shell, or
duplicated YAML expressions.

### [CI-CHAIN] Preserve the three-tier call chain

```text
consumer caller → layer wrapper → universal reusable
```

- The consumer owns events, concurrency, and a thin `uses:` job.
- The layer wrapper adds only genuine layer behavior and transports secrets.
- The universal reusable owns common jobs, matrix selection, and aggregation.

An authority sub-organization caller still enters through its parent layer
wrapper; do not add a fourth reusable-workflow hop.

### [CI-CALLER] Consumers declare policy, never reimplement mechanics

A package caller may declare explicit inputs such as supported platform
identity. It must not copy setup steps, choose tool versions, or shadow a
central job. When a package needs behavior that other packages could use,
change the shared owner first.

## Designing a change

### [CI-PREDICATE] Promote deterministic prose to Swift

When a skill sentence can be decided from source, manifests, repository files,
or a dependency graph:

1. name the semantic owner;
2. implement a Swift predicate there;
3. add positive, negative, and exemption fixtures;
4. expose a stable diagnostic identifier;
5. call it from the appropriate reusable workflow;
6. remove duplicated procedural instructions from skills.

Use **swift-linter** for SwiftSyntax predicates and **modularization** plus
**reuse-first** before creating a new analysis product.

### [CI-PARITY] Local and hosted gates share the same executable boundary

Hosted CI and local verification must invoke the same Swift-owned behavior.
`workspace package` owns local package operations. swift-linter owns source
rules. A green substitute that evaluates a different predicate is not parity.

### [CI-EVIDENCE] A gate reports what actually ran

Every aggregate job must fail when planning, setup, or a required child job
fails. Advisory jobs are explicitly identified. Skipped jobs are not silently
treated as full-contract evidence.

For a CI claim, record the workflow, selected tier, toolchain, package,
required/advisory posture, and run result.

## Stable architecture decisions

### [CI-MATRIX] The universal matrix is a scheduled platform contract

The universal reusable owns the platform and toolchain contract. Ordinary
pushes may run a smaller deterministic tier; tags, scheduled sweeps, and
explicit full dispatch run the full contract. Platform exclusions express
package identity, never cost or convenience.

Load `matrix.md` when changing legs, runners, toolchains, tier selection,
Embedded Swift, or platform declarations.

### [CI-SECRETS] Transport credentials explicitly across organization boundaries

`secrets: inherit` is useful only at a same-organization hop. Cross-organization
hops explicitly forward the closed credential set. Token-holding workflows
accept structured inputs and never caller-supplied shell.

Load `secrets-tokens.md` for visibility, private repositories, clean-room
resolution, or credential transport.

### [CI-CACHE] Cache immutable tools, not unresolved package graphs

Do not cache SwiftPM `.build` state for ordinary package jobs and do not use
partial `restore-keys`. A versioned tool binary may use an exact immutable key.
`Package.resolved` remains generated and ignored.

Load `caching.md` when changing caches, generated-state policy, linter binary
distribution, or per-package format/lint configuration.

### [CI-SECURITY] Make dangerous workflow states unrepresentable

Use least privilege, checksum downloaded binaries, pin security-sensitive
actions by digest, and keep user-controlled strings out of privileged command
execution.

Load `security-hardening.md` for permissions, runner hardening, downloads,
action pins, or elevated tokens. Load `workflow-authoring.md` for GitHub
Actions parse-time and expression constraints.

### [CI-ROLLOUT] Central changes use a canary and measured fan-out

Before changing multiple repositories:

1. inspect dirty state and skip any affected repository;
2. land and verify the semantic owner;
3. prove one representative consumer;
4. inspect the real diff;
5. fan out only the minimal caller or configuration change;
6. measure post-state and list skips.

Visibility, tags, releases, archival, and destructive operations retain their
separate approval gates. Load `mass-rollout.md` for multi-repository work.

## Companion routing

| Active decision | Load |
| --- | --- |
| tier placement or reusable call chain | `architecture.md` |
| platforms, toolchains, runners, Embedded | `matrix.md` |
| secrets, private repos, clean-room resolve | `secrets-tokens.md` |
| permissions, downloads, pins | `security-hardening.md` |
| cache and generated state | `caching.md` |
| GitHub Actions syntax and expression traps | `workflow-authoring.md` |
| multi-repository rollout | `mass-rollout.md` |
