# CI security, permissions, and pins

Load this reference for token-holding workflows, permissions, downloaded
artifacts, action pins, or admin-class GitHub operations.

### [CI-080] Harden real work at its central owner

Every in-scope job that runs steps uses the centrally approved runner-hardening
action as its first step, pinned by the approved digest and configured at the
current policy floor. Pure routing jobs and aggregate jobs have no runner to
harden.

Repository-policy owns the structural predicate and its fixtures; package
callers do not invoke hardening directly.

### [CI-081] Token-holding workflows accept closed inputs

A workflow holding an elevated token must not interpolate caller-supplied text
into command execution. Its interface uses booleans, enums, typed lists, or a
schema decoded by the Swift owner.

The contract must make arbitrary caller-supplied execution unrepresentable.

### [CI-082] Verify every downloaded executable

A fetched executable is installed only after its immutable digest is verified.
The version and digest change together. Verification failure is terminal and
cannot be swallowed.

Prefer a published Institute Swift tool or verified binary over installer
snippets. Repository-policy detects unapproved download/install shapes in
workflow and action definitions.

### [CI-090] Permissions follow trigger shape

Standalone workflows declare a least-privilege top-level floor. Reusable
workflows avoid a top-level declaration that would cap caller grants and place
least privilege at the job that performs the operation.

Repository-policy parses the trigger and permission shapes and reports the
exact file/job mismatch.

### [CI-097] Reusable workflows never deny all at the top level

A workflow with `workflow_call` must not declare workflow-level
`permissions: {}`. The reusable-call intersection would cap every caller at
zero.

### [CI-096] Evaluate correctness, security, then speed

Correctness comes first, security second, speed third. Runner concurrency is a
real speed/capacity constraint; dollar-minute arguments alone do not justify
weakening the platform contract.

### [CI-098] Admin operations use the typed bot boundary

Cross-repository administration defaults to `swift-institute-bot`, using a
closed operation type, least-privilege installation token, durable journal,
and final live readback. Do not create an admin-scoped workstation token or use
an untyped API mutation loop.

The web UI remains a bounded path for operations the App cannot perform, App
installation/permission changes, or an explicitly selected one-off recovery.
It is not the fleet operating model.

Visibility, tags, releases, archival, destructive actions, and third-party
publication retain independent authority gates. Bot capability does not imply
authorization.

### [CI-107] Pins follow the central release policy

The Institute owner decides the current allowed version and ref shape for each
action, runner, toolchain, SDK, and downloaded tool. Security-sensitive actions
use immutable commit digests with a human-readable version annotation.

Package callers do not choose pins. Tool-owned reusable workflows/actions may
hold pins only when their whitelist grant admits that owner and path.
Repository-policy rejects unknown owners, paths, versions, and ref shapes.

## Review checklist

- the local workflow/action class is whitelisted;
- real work is hardened at the central owner;
- privileged interfaces accept only closed inputs;
- every downloaded executable is digest-verified;
- permissions can traverse the complete reusable chain;
- `swift-institute-bot` tokens are narrow and short-lived;
- no workstation admin token or manual fleet mutation path is introduced;
- action and tool pins match the central typed policy;
- authority-gated operations remain separate.
