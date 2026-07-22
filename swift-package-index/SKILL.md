---
name: swift-package-index
description: |
  Swift Package Index onboarding and package collections.
  Apply when listing packages on SPI, authoring or validating a .spi.yml,
  generating package collections, or planning the tagging cascade for SPI.

layer: process

requires:
  - swift-institute
  - github-repository
  - ci-cd-workflows

applies_to:
  - swift-package-index
  - spi
  - package-collections

created: 2026-07-03
---

# Swift Package Index

How the ecosystem lists its packages on the Swift Package Index (SPI) and publishes
package collections. Governs the listing prerequisites, the tagging cascade, the two
collection surfaces (per-org auto vs self-hosted unified), the signing posture, and the
canonical `.spi.yml` policy.

**Domain fact (drives everything below):** the ecosystem is *federated* — one repo per
package, spread across ~20 GitHub orgs (`swift-primitives`, `swift-foundations`,
per-authority Standards orgs, …). SPI groups packages by GitHub **owner**, so federation
has direct consequences for collections ([SPI-010]) that a single-org project never faces.

(RECOMMENDATION, 2026-07-03), verified against SwiftPM primary source.

---

## Listing on SPI

### [SPI-001] Listing Prerequisites

**Statement**: A package MUST NOT be submitted to SPI until ALL hold: (1) the repo is
public; (2) it has at least one semantic-version git tag; (3) `swift package dump-package`
emits valid JSON on the launch toolchain; (4) its **entire** dependency closure is itself
public, tagged, and declared in URL form.

**Rationale**: These are SPI's own inclusion gates (PackageList README: "at least one
release tagged as a semantic version"; "repositories must all be publicly accessible").
(4) is the non-obvious one — SPI builds each package by resolving its full graph against
public URLs, so a listing is only as ready as its closure.

**Cross-references**: [SPI-002], [SPI-003], **swift-package** [PKG-DEP-*].

---

### [SPI-002] Leaf-First Tagging Cascade

**Statement**: Tagging for SPI MUST proceed in topological (leaf-first) order. A package
whose dependency closure is not yet public+tagged CANNOT build on SPI, so a tier-N package
is tagged only after tier-(N−1) is tagged, public, and resolvable.

**Rationale**: There is no "big-bang" tag day — the graph forces a cascade. Wave 1 is the
zero-external-dependency leaf cohort (the only tier taggable with nothing else in place);
later tiers follow as each lower tier goes green. Sequencing off the existing
`leaf-package-audit` gives the cascade order for free.

**Cross-references**: [SPI-001], [SPI-004].

---

### [SPI-003] No `path:` Dependencies Reach SPI

**Statement**: Every dependency in a package's public closure MUST be declared in URL
form. A `path:` (or otherwise unpublished) dependency anywhere in the closure fails the
SPI build and MUST be resolved before the depending package is submitted.

**Rationale**: SPI clones the public repo and resolves against public URLs; a `path:` dep
is unresolvable there. Externally-visible restatement of the existing no-path-deps rule.

**Cross-references**: [SPI-001], **swift-package** [PKG-DEP-*].

---

### [SPI-004] PackageList Submission

**Statement**: A package is listed by adding its canonical URL to `packages.json` in
`SwiftPackageIndex/PackageList` via pull request. The URL MUST include the `https`
protocol and the `.git` extension, and the list MUST remain valid JSON.

**Rationale**: This is SPI's ingestion mechanism; the auto-collection ([SPI-011]) and
build matrix follow from being in this list. There is no listing without it.

---

### [SPI-005] At-Scale Submission Etiquette

**Statement**: A large federated addition (this ecosystem is ≈ 3–4% of the entire ~11k
index in one source) SHOULD be preceded by a heads-up to the SPI maintainers via a
**GitHub Discussion** on `SwiftPackageIndex/SwiftPackageIndex-Server`, and SHOULD be
staged in waves rather than one monolithic PackageList PR.

**Rationale**: SPI is a sponsor-funded service that builds every package across every
toolchain/platform; hundreds of tiny interdependent packages are a real infra load. The
Discussions forum is the sanctioned channel; a pilot wave first (per [SPI-002]) is the
good-faith on-ramp.

---

## Package Collections

### [SPI-010] Two Collection Surfaces

**Statement**: The ecosystem MUST provide BOTH collection surfaces: (a) the per-owner
auto-collections SPI generates for free, and (b) exactly one **self-hosted unified**
collection on `swift-institute.org` spanning all orgs.

**Rationale**: SPI's auto-collections are single-owner-scoped, so federation across ~20
orgs yields ~20 separate auto-collections and no whole-ecosystem view. The self-hosted
unified collection is the single URL that means "the entire ecosystem" — the
pointfree-style experience, which pointfree gets for free only because it is one org.

**Cross-references**: [SPI-011], [SPI-012].

---

### [SPI-011] Per-Org Auto-Collections

**Statement**: The per-org auto-collections at `swiftpackageindex.com/{owner}/collection.json`
MUST NOT be hand-generated — SPI produces and signs them automatically once a package is
indexed. The only action is to surface their URLs (e.g. on `swift-institute.org`).

**Rationale**: These are SPI-signed with SPI's Apple "Swift Package Collection"
certificate (empirically confirmed), so they add cleanly on macOS/Xcode with no prompt.
Note the trust asymmetry per [SPI-013]: on Linux a *signed* third-party collection
requires the consumer to install the Apple root — so the auto-collections are the
macOS-optimal surface, and the unsigned self-hosted collection ([SPI-012]/[SPI-013]) is
the Linux-optimal one. The two surfaces are complementary on the trust axis, not
redundant.

**Cross-references**: [SPI-010], [SPI-013].

---

### [SPI-012] Self-Hosted Unified Collection

**Statement**: The self-hosted collection MUST be generated with
`swiftlang/swift-package-collection-generator` over the enumerated set of public+tagged
repos across all orgs, producing two artifacts: the complete-index `collection.json`
(discoverability) and a curated `starter.json` ([SPI-014]). Both are deployed to
`swift-institute.org`.

**Rationale**: A single generator input list (the same enumeration that feeds the
PackageList PR) is the source of truth for both the complete index and the starter set.

**Cross-references**: [SPI-013], [SPI-014], **ci-cd-workflows** [CI-*].

---

### [SPI-013] Signing Posture — Unsigned for v1

**Statement**: The self-hosted unified collection MUST ship **unsigned** for v1.
*(Ratified 2026-07-03.)*

**Rationale**: SwiftPM selects the trust policy by the collection URL's **host**; only
`developer.apple.com` is pinned to Apple's bundled roots. Any other host — including SPI's
own `swiftpackageindex.com` and our `swift-institute.org` — uses the `.default` policy,
whose trust store on non-Apple platforms is empty. Consequently a *signed* third-party
collection **hard-fails** on Linux unless the consumer first installs the DER root into
`~/.swiftpm/config/trust-root-certs`, whereas an *unsigned* collection merely prompts for
confirmation and proceeds. For a Linux-first ecosystem, signing regresses the majority
path; HTTPS from `swift-institute.org` already provides transport authenticity for the
realistic threat model. A signed collection also embeds the full base64 payload → >2× file
size (SPI Discussion #1365).

**Aspirational — signed as a future upgrade**: if signing is later
adopted, it requires an Apple "Swift Package Collection Certificate" (2048-bit RSA, one
per paid account), PEM-key custody as an org CI secret, embedding the full chain, publishing
the DER root plus a `trust-root-certs` setup snippet on the landing page, and re-signing on
each regeneration. **Open verification before finalizing either way**: empirically confirm
`swift package-collection add` behavior for a signed third-party collection on a clean
Linux host — the host-based policy mechanism is verified from source, but the exact
prompt-vs-hard-fail Linux behavior should be observed once in the pipeline dry-run.

**Cross-references**: [SPI-011], **ci-cd-workflows** [CI-*].

---

### [SPI-014] Curated Starter Collection

**Statement**: Alongside the complete index, the ecosystem SHOULD publish a small curated
`starter.json` — the newcomer-facing entry point — seeded from the zero-external-dependency
leaf cohort and kept deliberately short.

**Rationale**: A ~457-package complete index is a machine surface, not a human one.
Consistent with the public-posture discipline (curate the human face; keep the exhaustive
list as the index).

**Cross-references**: [SPI-010], [SPI-012].

---

## `.spi.yml` Policy

### [SPI-020] Presence and Location

**Statement**: A package opts into SPI doc hosting by the **presence** of a repo-root
`.spi.yml` (beside the root `Package.swift`). The file SHOULD be added as a package enters
the tagging wave, not ahead of it. A repo without the file is simply not doc-hosted by SPI.

**Rationale**: Opt-in-by-presence is the same safety property as `.github/metadata.yaml`
rollout — a package with no file is untouched, so partial rollout is always consistent.

**Cross-references**: [SPI-021], **github-repository** [GH-REPO-*].

---

### [SPI-021] Canonical Shape

**Statement**: A `.spi.yml` MUST be exactly: `version: 1`; a single `builder.configs`
entry; **no** `platform` and **no** `swift_version` key; 2-space block style.

```yaml
version: 1
builder:
  configs:
  - documentation_targets:
    - <Exact Package.swift target name>
```

**Rationale**: The only per-package variable is `documentation_targets` ([SPI-022]); the
rest of the skeleton is invariant. This mirrors the fixed-schema/package-specific-values
model of `.github/metadata.yaml`.

**Cross-references**: [SPI-022], [SPI-024].

---

### [SPI-022] `documentation_targets` Fidelity

**Statement**: `documentation_targets` MUST list the EXACT `Package.swift` target name(s)
— **space- and case-exact** — one entry per public library doc target (multi-target
packages list all of them).

**Rationale**: SPI matches these against the manifest target name; a mismatch produces a
failed/empty doc build on the package's first tagged release. This is the single
highest-value rule — 7 of the 17 pre-existing `.spi.yml` files point at non-existent
targets (copy-paste `EmailAddress`, truncated suffixes, underscore-module names) and are
latent only because the ecosystem's own `swift-docs.yml` does not consume `.spi.yml`.

**Cross-references**: [SPI-021], [SPI-030].

---

### [SPI-023] SPI Hosts the Docs

**Statement**: `.spi.yml` MUST omit `external_links.documentation` — SPI renders and hosts
the DocC output on each tagged release. `custom_documentation_parameters` is the sanctioned
(opt-in, never mandated) per-package override for the rare package needing extra
`generate-documentation` flags.

**Rationale**: The ecosystem decision is that published rendered docs come from SPI; an
external doc link would contradict that and drift.

**Cross-references**: [SPI-021].

---

### [SPI-024] Do Not Mirror the CI Matrix

**Statement**: `.spi.yml` MUST NOT carry the ecosystem's build matrix (platforms, Swift
versions). SPI's role here is docs hosting, not build-matrix enforcement.

**Rationale**: Platform/toolchain coverage is owned by the CI matrix (**ci-cd-workflows**
[CI-*]). Pinning it per-package across hundreds of interdependent packages would drift and
need bumping on every toolchain move. Mirroring the CI matrix into `.spi.yml` is an
explicit anti-pattern for this ecosystem.

**Cross-references**: [SPI-021], **ci-cd-workflows** [CI-*].

---

## Ownership and CI

### [SPI-030] Skill Boundary and CI Mechanics

**Statement**: This skill owns SPI domain **policy** (`[SPI-*]`), including the `.spi.yml`
authoring rules ([SPI-020]–[SPI-024]). The CI **mechanics** live in **ci-cd-workflows**
(`[CI-*]`): a centralized reusable `validate-spi-manifest.yml` in `swift-institute/.github`
(cheap JSON-Schema PR-gate + a weekly `swift package dump-package` target-fidelity sweep —
the check that catches the [SPI-022] defects), and the cross-org collection-generation
workflow ([SPI-012]). **github-repository** carries a one-line cross-reference (its
homepage rule already points at SPI docs).

**Rationale**: Domain policy and workflow plumbing have different review cadences and
owners; separating them keeps each skill coherent. This supersedes the source research
doc's tentative §3.2 placement of `.spi.yml` authoring rules under `[GH-REPO-*]` — that
recommendation assumed no dedicated SPI skill; a domain skill is the better home once one
exists.

**Cross-references**: **ci-cd-workflows** [CI-*], **github-repository** [GH-REPO-*].

---

## Cross-References

- **swift-package** — [PKG-DEP-*] URL-vs-path dependency form (gates [SPI-001]/[SPI-003]).
- **github-repository** — [GH-REPO-*] per-package metadata + centralized reusable
  propagation (the precedent `.spi.yml` mirrors); homepage → SPI docs.
- **ci-cd-workflows** — [CI-*] the validation + collection-generation workflow mechanics.
- **release-readiness** — [RELEASE-*] the tag/visibility gates that precede a wave.
- **research-process** — source doc `swift-package-index-onboarding-and-spi-manifest-harmonization.md`.
