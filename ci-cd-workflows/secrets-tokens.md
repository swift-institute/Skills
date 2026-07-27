# CI secrets, bot credentials, and private repositories

Load this reference when a call crosses organizations, a workflow mints a
token, or a gate reads private repositories.

### [CI-032] Visibility is an explicit planning input

The central planner resolves repository visibility and selects only supported
work. A skipped private job is not evidence that its contract passed.

Do not duplicate visibility expressions throughout jobs. Repository-policy and
the planning job own the classification; required jobs consume the closed
result.

### [CI-058] Private-repository support fails closed

A reusable that supports private dependencies declares that capability in its
typed contract. Missing credentials, an inaccessible dependency, or an
unmeasured repository is a failure or explicit not-run result, never an
anonymous fallback reported as green.

### [CI-059] Same-organization callers may inherit

A package caller reaching a wrapper in the same organization may use
`secrets: inherit`. Repository-policy validates that the hop is same-org and
the caller is an admitted thin caller.

### [CI-060] Do not duplicate long-lived repository secrets

Production cross-repository authentication uses the
`swift-institute-bot` GitHub App. Do not distribute a long-lived token to every
repository or create a workstation admin token as a fleet mechanism.

Where a legacy org secret remains during migration, central policy reports it
as transitional state; new workflows do not make it a dependency.

### [CI-109] Cross-organization hops forward a closed set

`secrets: inherit` does not transport organization secrets across an
organization boundary. A cross-org call explicitly forwards only the secrets
declared by the called workflow.

The preferred fleet path avoids consumer-held credentials entirely: a central
workflow mints a short-lived `swift-institute-bot` installation token scoped to
the exact repositories and permissions, then invokes the typed Swift product.

### [CI-BOT-TOKEN] Mint narrowly and late

For every bot operation:

1. derive the exact repository population before minting;
2. request only the permissions needed by the closed operation kind;
3. mint per organization or narrower when supported;
4. keep the token out of arguments, output, journals, and receipts;
5. perform live readback with the same identity;
6. let the short-lived token expire.

The App's installation ceiling and the token's requested permissions are both
policy inputs. An unexpected permission or missing installation fails closed.

### [CI-094] Private-package gates use the same local executable

When hosted private-repository CI cannot provide reliable signal, run the same
Swift-owned executable locally through Workspace. Record the substitution and
its scope. Do not replace the predicate with a text probe or a different local
script.

Build and test evidence uses:

```text
workspace package build --fresh
workspace package test --fresh
```

Source and repository policy use their owning Swift products. A local green is
not a hosted matrix result; describe exactly which contract it proves.

### [CI-095] Distinguish activation from alignment

Repository-policy may validate configuration across public and private
repositories even when hosted execution runs only on a subset. Report these as
separate populations:

- **activation** — repositories where the hosted gate actually ran;
- **alignment** — repositories whose checked-in configuration matches policy.

Never add the populations or call alignment a CI pass.

### [CI-112] Clean-room resolution is non-substitutable

A claim that a package resolves off-machine requires an actual clean,
mirror-bypassed resolve from canonical sources. Reachability probes and a
mirror-backed build are different evidence.

Run the resolve through the coordinator and keep `Package.resolved` generated.
Central CI and local verification use the same manifest-owned operation.

## Review checklist

- cross-repository mutations route through `swift-institute-bot`;
- no long-lived admin token is created or copied;
- every cross-org secret is explicitly declared and forwarded;
- token permissions and repository scope are closed and minimal;
- missing private access is a failure/not-run state, not a silent fallback;
- local substitution invokes the same Swift predicate;
- activation and alignment populations are reported separately.
