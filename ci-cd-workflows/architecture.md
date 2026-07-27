# CI architecture and reusable consumption

Load this reference when deciding which workflow tier owns behavior or when
editing reusable-workflow calls.

### [CI-001] Use the three-tier chain

Institute CI flows through:

```text
package caller → layer wrapper → universal reusable
```

The three tiers are semantic owners, not templates to copy.

### [CI-002] The universal reusable owns common jobs

The universal reusable owns the common build/test matrix, formatter,
swift-linter, documentation mechanics, planning, and aggregate result. A common
job changes once here and reaches every layer.

### [CI-003] A layer wrapper owns only layer invariants

A wrapper adds behavior required by every package in that layer, such as the
L1 Embedded build. Repository- or domain-specific checks do not become layer
jobs merely because a wrapper is convenient.

### [CI-004] Realized layer organizations host wrappers

Each realized layer organization exposes the standard reusable entry points
needed by its consumers. The wrapper forwards common work to the universal
owner and declares only its layer delta.

### [CI-004a] Documentation also traverses the layer wrapper

Documentation workflows use a layer wrapper when credentials must cross an
organization boundary. Direct consumer-to-universal calls bypass the secret
transport boundary and are not an optimization.

### [CI-004b] Authority sub-organizations do not add another wrapper tier

GitHub reusable-workflow depth is finite. An authority or vendor
sub-organization caller explicitly forwards the closed secret set to its
parent layer wrapper; it does not introduce a fourth semantic tier.

### [CI-030] Reusable references follow the central release policy

During active coordinated development, Institute workflow callers track the
approved central development ref. Once a versioned workflow contract is
released, migration to that contract is a deliberate central rollout.
Consumers do not choose independent pins.

### [CI-031] Package callers are thin

A consumer caller contains only:

- workflow name and triggers;
- concurrency policy;
- a `uses:` job for the layer entry point;
- explicit supported inputs;
- the correct same-org inherit or cross-org secret forwarding.

Tool setup, job steps, matrices, versions, and validation predicates belong
upstream.

### [CI-053] Documentation metadata is derived by its Swift owner

Repository identity, product, bundle, catalogue, and display metadata are
derived from typed package/repository data when the defaults are unambiguous.
An explicit input is reserved for a real ambiguity. Do not recreate derivation
with shell expressions in the caller.

### [CI-054] Formatting and linting are universal quality gates

Packages do not carry separate workflow files for common format or lint jobs.
The universal reusable invokes the centralized formatter and swift-linter
owners in parallel with compilation.

### [CI-093] Tool invocation resolves to a Swift product

Local and hosted format/lint operations invoke a versioned Swift product or
verified Swift binary through the owning interface. Do not resolve behavior
through `$PATH`, a repository `Scripts` directory, or a copied command block.

### [CI-108] Keep a workflow per repository only for repository events

A workflow remains in a package only when its trigger or output intrinsically
depends on that package's event, branch, diff, environment, or permissions.
Scheduled fleet checks, shared predicates, and aggregate reporting move to the
central owner.

## Review questions

1. Which tier semantically owns the behavior?
2. Does this change duplicate a job, setup step, or predicate?
3. Is a caller input closed and necessary, or is it an implementation leak?
4. Does the secret path cross an organization?
5. Can the same Swift executable reproduce the gate locally?
