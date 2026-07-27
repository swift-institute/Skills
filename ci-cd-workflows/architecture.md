# CI architecture and Actions ownership

Load this reference when deciding which workflow tier owns behavior, changing
reusable-workflow calls, or deciding whether repository-local Actions are
admissible.

### [CI-001] Use the three-tier chain

Institute package CI flows through:

```text
package thin caller → layer wrapper → universal reusable
```

These tiers are semantic owners, not templates.

### [CI-002] The universal reusable owns common jobs

The universal reusable owns the common build/test matrix, formatter,
swift-linter, documentation mechanics, planning, and aggregate result. Change a
common job once at this owner.

### [CI-003] A layer wrapper owns only layer invariants

A wrapper adds behavior required by every package in its layer, such as the L1
Embedded build. Repository- or domain-specific checks do not become layer jobs
because the wrapper is convenient.

### [CI-004] Realized layer organizations host wrappers

Each realized layer exposes the standard reusable entry points needed by its
consumers. Authority and vendor sub-organizations use their parent layer
wrapper and do not add another tier.

### [CI-030] Reusable references follow central policy

The Institute owner decides the allowed reusable identity and ref policy.
Consumers do not choose independent versions. The repository-policy whitelist
validates both the owner/path and the ref shape.

### [CI-031] Package callers are thin

A caller contains only:

- an admitted package event trigger;
- concurrency policy;
- a `uses:` job for the layer entry point;
- explicitly admitted typed inputs;
- the correct same-org inheritance or cross-org secret forwarding.

It contains no `runs-on`, `steps`, tool setup, matrix, version selection, or
validation predicate.

### [CI-ACTIONS-LOCAL] Local Actions require a whitelist grant

Repository-policy classifies every `.github/workflows/*.{yml,yaml}` and
`.github/actions/**/action.{yml,yaml}` entry. A package repository fails closed
unless each local file and invocation matches one of:

| Grant | Required evidence |
| --- | --- |
| thin caller | exact path, admitted triggers, central `uses:` target, allowed inputs/secrets, no inline jobs |
| tool-owned reusable workflow | exact tool repository/path, `workflow_call`, owned invocation glue, allowed third-party references |
| tool-owned composite/action | exact tool repository/path, declared action interface, allowed references |
| exemption | exact repository, path, grant kind, rationale, and optional expiry/review condition |

The schema is data interpreted by the Swift product. Do not recreate it with
workflow-name heuristics, a shell allowlist, comments, or prose.

### [CI-ACTIONS-TRIGGER] Trigger permission is explicit

An allowed file is not permission for every trigger. The whitelist separately
admits trigger kinds and any branch, path, schedule, dispatch, or reusable-call
constraints. Unknown or newly added triggers are denied until the policy owner
is intentionally changed.

### [CI-ACTIONS-USES] Direct invocation is explicit

Every job-level workflow call and step-level action reference is classified.
Package callers may directly invoke only targets admitted for their grant.
Shared fleet behavior belongs in central workflows; cross-repository operations
belong behind `swift-institute-bot`.

### [CI-053] Derive metadata in its Swift owner

Repository identity, product, bundle, catalogue, and display metadata are
derived from typed package/repository data when unambiguous. An explicit input
is reserved for a real ambiguity. Do not recreate derivation with expressions
or shell.

### [CI-054] Formatting and linting are universal gates

Packages do not carry standalone format or lint workflows. The universal
reusable invokes their Swift owners.

### [CI-093] Tool invocation resolves to a Swift product

Local and hosted validation invokes a versioned Swift product or verified Swift
binary through the owning interface. Do not resolve behavior through `$PATH`
guessing, a `Scripts` grab bag, or copied command blocks.

### [CI-108] Keep local workflows only for admitted repository events

A workflow remains in a package only when its trigger or output intrinsically
depends on that package and repository-policy admits the exact shape.
Scheduled fleet checks, shared predicates, GitHub settings convergence, and
aggregate reporting move to the Institute owner and bot.

## Review questions

1. Which Institute owner defines this behavior?
2. Does the package compose that owner or reproduce it?
3. Which typed whitelist grant admits every local file, trigger, and `uses:`
   reference?
4. Is this genuinely a package event, or fleet/control-plane work for the bot?
5. Does the secret path cross an organization?
6. Can Workspace and central CI invoke the same Swift predicate?
