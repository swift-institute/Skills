---
name: ci-cd-workflows
description: Design, change, audit, or converge Swift Institute CI, GitHub Actions, reusable workflows, matrices, security, and cross-repository policy. Apply whenever CI behavior, workflow ownership, or repository Actions posture changes.
---

# CI/CD workflows

CI is Institute infrastructure. Put reusable behavior and typed policy at the
Institute owner first; packages compose those owners and never reimplement
them.

## Ownership

### [CI-OWNER] Put each behavior at one executable owner

| Concern | Owner |
| --- | --- |
| common build, test, format, lint, and docs behavior | universal Institute reusable workflow |
| layer-specific verification | layer wrapper |
| package event trigger and concurrency | whitelisted thin caller |
| GitHub Actions structure and invocation policy | repository-policy Swift product |
| Swift source predicate | swift-linter rule pack |
| package graph or manifest predicate | owning Swift package-analysis product |
| checkout facts and local orchestration | Workspace |
| cross-repository convergence | `swift-institute-bot` |

GitHub Actions YAML schedules and connects these owners. It must not contain a
second implementation of their policy.

### [CI-CHAIN] Preserve the three-tier execution chain

```text
package thin caller → layer wrapper → universal reusable
```

- The package caller owns only admitted events, concurrency, and typed inputs.
- The layer wrapper adds only a genuine invariant shared by the layer.
- The universal reusable owns common jobs, matrix selection, and aggregation.
- Authority sub-organizations enter through their parent layer wrapper; do not
  add a fourth reusable-workflow tier.

### [CI-ACTIONS] Deny package-local Actions by default

The repository-policy Swift product evaluates every workflow, local action,
trigger, job, and `uses:` reference against a typed whitelist.

Only three classes are admissible:

1. an explicitly allowed package-local trigger with a thin caller;
2. an explicitly allowed tool-owned reusable workflow or action;
3. a typed, justified exemption with exact repository and path scope.

Absence from the whitelist is a denial. Existing files, successful runs,
another repository's configuration, and copied templates do not establish
permission. Move denied behavior to the centralized owner or mediate it with
`swift-institute-bot`.

### [CI-BOT] Use the bot for fleet behavior

`swift-institute-bot` is the default actor for cross-repository GitHub reads,
writes, canaries, convergence, and receipts. A local or manual path is a
bounded recovery or bootstrap exception, not a second operating model.

The bot consumes the same typed repository policy used by local validation and
central CI. It fails closed on unknown repository classes, workflow shapes,
permissions, and exemptions.

## Designing a change

### [CI-PREDICATE] Promote deterministic prose to Swift

When a sentence can be decided from source, manifests, workflow files,
repository state, or a dependency graph:

1. identify the semantic owner;
2. implement one typed Swift predicate there;
3. add positive, negative, edge, and exemption fixtures;
4. expose a stable diagnostic identifier;
5. invoke that exact executable from Workspace or centralized CI;
6. remove the duplicated algorithm from skills and YAML.

Use **swift-linter** for SwiftSyntax predicates. Use repository-policy for
GitHub repository and Actions structure. Use Workspace for checkout,
inventory, and cross-package facts.

### [CI-PARITY] Local and hosted gates share an executable boundary

Hosted CI and local verification invoke the same Swift-owned behavior.
`workspace package` owns package operations; swift-linter owns source rules;
repository-policy owns GitHub repository policy. A substitute implementation
that checks a similar-looking condition is not parity.

### [CI-EVIDENCE] Report what actually ran

Required aggregation fails when planning, setup, or any selected required job
fails. Advisory posture is explicit. Skipped and unmeasured work is not
described as green.

For a CI claim, record the workflow, selected tier, executable revision,
toolchain, package, required/advisory posture, and result.

## Stable architecture decisions

### [CI-MATRIX] Keep the platform contract centralized

The universal reusable owns the platform and toolchain contract. Ordinary
pushes may select a smaller deterministic tier; tags, scheduled sweeps, and
explicit full dispatch run the full contract. Platform exclusions express
package identity, never convenience or current consumer count.

Load `matrix.md` only when changing legs, runners, toolchains, scheduling
tiers, Embedded Swift, or platform declarations.

### [CI-SECRETS] Transport credentials explicitly

Same-organization calls may inherit secrets. Cross-organization calls forward
the closed credential set explicitly. Token-holding workflows accept typed or
closed inputs and never caller-supplied shell.

Load `secrets-tokens.md` for visibility, private repositories, clean-room
resolution, bot credentials, or credential transport.

### [CI-CACHE] Cache immutable tools, not unresolved graphs

Do not cache ordinary SwiftPM `.build` state and do not use partial
`restore-keys`. Versioned tool binaries may use exact immutable keys.
`Package.resolved` remains generated and ignored.

Load `caching.md` for cache, generated-state, or binary-delivery changes.

### [CI-SECURITY] Make dangerous states unrepresentable

Use least privilege, verify downloaded artifacts, pin sensitive actions, keep
untrusted strings out of privileged execution, and express local Actions
permission through the whitelist rather than review convention.

Load `security-hardening.md` for permissions, downloads, pins, or elevated
tokens. Load `workflow-authoring.md` for GitHub expression and trigger
constraints.

### [CI-ROLLOUT] Change the owner, prove a canary, let the bot converge

For a cross-repository change:

1. land and verify the reusable owner and typed policy;
2. run positive, negative, and exemption fixtures;
3. prove one representative canary;
4. inspect the receipt and live readback;
5. have `swift-institute-bot` converge the measured population;
6. report skips, exemptions, and post-state.

Preserve dirty repositories. Releases, tags, visibility, archival, and
destructive operations keep their separate authority gates. Load
`mass-rollout.md` for fleet work.

## Companion routing

| Active decision | Load |
| --- | --- |
| tier placement, thin callers, or Actions whitelist | `architecture.md` |
| platforms, toolchains, runners, Embedded | `matrix.md` |
| secrets, bot credentials, private repos | `secrets-tokens.md` |
| permissions, downloads, action pins | `security-hardening.md` |
| cache and generated state | `caching.md` |
| workflow syntax and expression phases | `workflow-authoring.md` |
| cross-repository convergence | `mass-rollout.md` |
