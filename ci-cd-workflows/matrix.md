# CI matrix, toolchains, and platform identity

Load this reference when changing platform coverage, toolchains, runners,
verification tiers, or L1 Embedded Swift behavior. Read the canonical reusable
workflow for the current matrix values; this reference owns the decisions, not
a duplicate inventory.

### [CI-010] The universal reusable owns matrix shape

All common release, nightly, Windows, macOS, Linux, and Apple-simulator jobs are
declared in the universal reusable. A layer wrapper may extend that contract
with a real layer invariant; a consumer may not copy or reshape it.

The aggregate job includes planning and every required selected leg. An
advisory leg is named and represented as advisory rather than omitted from the
contract.

### [CI-011] Toolchain pins have one source of truth

Stable and development toolchain selections live in the universal workflow.
Consumers and wrappers do not override them. When the floor changes, update the
workflow first and verify each runner can load manifests at that floor.

### [CI-012] Linux uses declared Swift containers

Linux jobs use the canonical Swift container for their selected toolchain.
Do not install an alternate Swift toolchain onto a generic Linux runner.

### [CI-013] Apple and Windows jobs verify their real execution surfaces

Apple jobs select a runner and Xcode whose bundled Swift satisfies the manifest
floor. Simulator jobs use `xcodebuild` where bundle signing and platform
packaging are part of the claim.

Windows jobs use the centrally pinned setup action and toolchain. Security-
sensitive action references follow the digest policy in
`security-hardening.md`.

### [CI-091] Matrix shape is the ecosystem platform contract

The full matrix expresses supported ecosystem surfaces. Do not derive it from
an individual package manifest, reduce it because a platform has few
consumers, or let packages choose cheaper subsets.

The contract may evolve at its universal owner. Per-push scheduling may select
a smaller tier without changing which surfaces constitute the full contract.

### [CI-114] Platform exclusions express package identity

A package whose specification or semantic identity excludes a platform
declares that through the closed `platform-support` workflow input. This is for
identity boundaries such as a platform-specific implementation or
specification, not convenience, current consumer count, or a failing build.

The planning job validates tokens, rejects duplicates and empty declarations,
and selects only supported legs. Quality gates remain platform-neutral. Never
add platform emulation inside a package merely to green an inapplicable leg.

### [CI-115] Scheduling selects a tier without mutating the contract

The planning job selects one of:

- **lint** — format and Swift-owned lint gates for changes that cannot affect
  compilation;
- **build** — lint plus one supported release build, the default for ordinary
  source pushes and pull requests;
- **full** — every applicable contract leg, used for tags, scheduled sweeps,
  explicit dispatch, and requested full verification.

Classification fails safe to `build`. A source or test change must not force
the lint-only tier. `ci-ok` attests that the selected tier passed; only a full
run attests the full contract.

### [CI-092] Container jobs assume only their declared interface

Do not assume a Swift container contains convenience tools or uses Bash.
Prefer invoking the Swift-owned executable directly. When a third-party tool
is genuinely required, install it in one owned setup action with an explicit
shell, version, and digest rather than scattering setup snippets across jobs.

Do not add Python or shell programs as custom validators. A missing validation
capability is completed in its Swift owner and then scheduled here.

### [CI-020] Embedded Swift buildability is an L1 invariant

The L1 wrapper compiles every primitives package in the canonical Embedded
configuration against the selected development toolchain. The job exercises
the compiler mode; a source grep is not equivalent evidence.

### [CI-021] Development-toolchain instability is explicitly advisory

An Embedded or nightly job may be advisory while it depends on an unstable
development toolchain. The posture is encoded in the wrapper and removed when
the toolchain and ecosystem are ready to gate. Do not weaken stable platform
jobs to compensate for nightly noise.

### [CI-022] Foundation independence is a linter-owned source rule

Foundation imports in Foundation-independent main targets are rejected by the
appropriate swift-linter bundle. Integration targets are explicit opt-in
boundaries. CI invokes the rule; it does not reimplement the predicate in YAML.

### [CI-099] Applicable stable platform jobs gate

A stable release job gates whenever the package declares support for that
platform. `continue-on-error` is not a substitute for a legitimate
platform-identity exclusion.

## Change procedure

1. Read the live universal workflow and relevant layer wrapper.
2. State whether the change affects contract shape, scheduling, or platform
   identity.
3. Update the single owner and its Swift-backed validators.
4. Run local parity checks where possible.
5. dispatch a canary full run;
6. verify the planning and aggregate jobs as well as the changed leg;
7. only then fan out any caller input change.
