# CI/CD — Security Hardening, Permissions & Version Pins

Companion of the **ci-cd-workflows** skill (navigation hub: `SKILL.md`). Load when working on harden-runner, binary-install checksums, workflow `permissions:` shape, CI prioritization axes, admin-scope GitHub operations, or latest-version pin discipline. This file reads independently: it collects the supply-chain and least-privilege rules.

**Rules in this file**: [CI-080], [CI-081], [CI-082], [CI-090], [CI-097], [CI-096], [CI-098], [CI-107]

---

## Runner & Binary Hardening

### [CI-080] Harden-Runner Audit-Mode Floor; Block-Mode After Observation

**Statement**: Every in-scope job installs `step-security/harden-runner` as its FIRST step, SHA-pinned (`@<40-hex>`), with `egress-policy: audit` as the floor. Block-mode flip per-workflow after 2-cycle observation window. Excluded: aggregator jobs (`ci-ok`); pure `uses:`-only routing jobs.

**Enforcement**: Mechanical — `validate-harden-runner.py` + `validate-harden-runner.yml` (pilot 15 of `/promote-rule` 2026-05-14). Single-repo multi-file integrity check; detects two failure modes (missing harden-runner, major-tag-pinned instead of SHA). Carve-outs by name (`ci-ok`) + structure (pure uses-only routing). Baseline 0; self-firing ACTIVE (triggers: `push` + `pull_request`) — confirmed 2026-07-03 with positive+negative fixture controls on the live swift-institute/.github (prior baseline 3 on weekly-orchestrator `config` jobs, since remediated). Discipline: `Audits/PROMOTE-CI-080-2026-05-14.md`. [VERIFICATION: WF validate-harden-runner.py]

**Cross-references**: [CI-013], [CI-070], [CI-097], [CI-096].

---

### [CI-081] No Caller-Supplied Shell in Token-Holding Reusables

**Statement**: A reusable workflow that holds an elevated token (cross-org App-installation token, repository-scoped contents/issues PAT, or any privileged credential minted from `actions/create-github-app-token` / `secrets.*` inside the reusable) MUST NOT interpolate a caller-supplied STRING input into a `run:` block. Structured inputs (typed paths to scripts checked out from a trusted source, JSON-decoded config dicts handled inside Python/etc., enums with closed value sets) are the only permitted contract shape for caller-driven behavior in such workflows. The prohibition is structural: the contract MUST make caller-supplied shell un-expressible at the input surface, not merely "discouraged" or "trust-boundary-mitigated."

**Enforcement**: Architectural — current ecosystem has zero instances of caller-supplied shell into token-holding reusables. The canonical pre-2026-05-14 instance (`cron-audit-base.yml`'s `run: ${{ inputs.audit-step }}` interpolating bash from 3 layer-wrapper-resident callers into a job holding a cross-org App-installation token) was refactored to a structured-input contract in Phase C of the 2026-05-14 CI review per Q2=B sealed adjudication; the runner (`cron-audit-runner.py`) consumes a JSON-decoded `audit-runner-args` config dict inside Python with no shell expansion of caller content. Branch protection on layer-wrapper repos (where applicable; this workspace currently runs no-branch-protection) is defense-in-depth that catches review-level reintroduction; the structural floor holds regardless of branch-protection state. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-081]; Phase C execution: `Audits/Outcome-CI-REVIEW-Phase-C-2026-05-14.md`. [VERIFICATION: ARCH]

**Cross-references**: [CI-001], [CI-004a], [CI-070], [CI-080]. Source authority: `swift-institute/Research/ci-cd-security-review.md`; `swift-institute/Audits/CI-REVIEW-OPEN-QUESTIONS-2026-05-14.md` § Open Q2 Option B (the Phase C adjudication brief).

---

### [CI-082] Binary-Install Checksum Verification

**Statement**: Workflow steps that fetch versioned binaries via curl MUST verify the artifact via `sha256sum -c` against a hardcoded digest in the same `run:` block before installation; the verification's exit code MUST NOT be swallowed. Version bumps MUST re-lock the digest in the same PR.

**Enforcement**: Mechanical — `validate-binary-install-checksum.py` + `validate-binary-install-checksum.yml` (pilot 18 of `/promote-rule` 2026-05-14). Single-repo multi-file integrity check; per-step shell-content inspection detects four failure modes: (A) `curl ... | bash`, (B) `curl + install indicators` without `sha256sum -c`, (C) `sha256sum ... || true` swallowed exit, (D) `sha256sum ... 2>/dev/null` swallowed stderr. Install indicators: `mv ... /bin/`, `chmod +x`, `tar -x`, `unzip`, `tee /etc/apt/keyrings/`, `install -m`. Permitted exception: pure `apt-get install` (apt-managed signatures). Baseline 0; self-firing ACTIVE (triggers: `push` + `pull_request`) — confirmed 2026-07-03 with positive+negative fixture controls on the live swift-institute/.github (prior baseline 4, since remediated). Discipline: `Audits/PROMOTE-CI-082-2026-05-14.md`. [VERIFICATION: WF validate-binary-install-checksum.py]

**Cross-references**: [CI-013], [CI-044], [CI-080], [CI-107]; `swift-institute/Research/ci-cd-security-review.md` G4. Statement-amendment queued: original title "Binary-Install Version-Bump Protocol" under-emphasized the ongoing CI invariant; retitled here to lead with the structural invariant. Version-bump procedure (update version env var → re-lock digest → verify gate fires) preserved in outcome record's Discipline reference.

---

## Permissions Shape

### [CI-090] Reusable-vs-Standalone Permissions-Shape

**Statement**: Workflow-level `permissions:` MUST be applied per trigger shape — reusables (`workflow_call`) and combined workflows OMIT top-level permissions (workflow_call intersection rule caps caller grant); standalone workflows (`schedule` / `workflow_dispatch` / `push` / `pull_request` only) DECLARE top-level permissions (least-permissions floor).

**Enforcement**: Mechanical — `validate-permissions-shape.py` + `validate-permissions-shape.yml` (pilot 27 of `/promote-rule` 2026-05-14, paired with [CI-097]). Single-repo multi-file integrity check; PyYAML inspects `on:` trigger shape + top-level `permissions:` state. Fires CI-097 for the specific deny-all-on-reusable case (the M2 incident shape) and CI-090 for the broader top-perms-on-reusable / missing-floor-on-standalone cases. Combined workflows treated as reusable per the workflow_call intersection rule. Baseline 0; self-firing ACTIVE — the batch-fix landed (`5161e33..74ae3d0`, the permission-floor sweep across the standalone weekly orchestrators; prior baseline 9/1: 1 reusable with top-perms + 8 standalone missing floor) (synced 2026-07-03 per CI-REVIEW dossier F10). Discipline: `Audits/PROMOTE-CI-090-CI-097-2026-05-14.md`. [VERIFICATION: WF validate-permissions-shape.py]

**Cross-references**: [CI-051], [CI-080], [CI-097], [CI-106]; `swift-institute/Research/Reflections/2026-05-06-ci-reviewer-feedback-rollout-permissions-pitfall-and-doctrines.md`; memory `feedback_top_level_permissions_on_reusables.md`.

---

### [CI-097] Reusable Top-Level Permissions Restriction

**Statement**: A `workflow_call` reusable MUST NOT declare workflow-level `permissions: {}` (deny-all) — the intersection rule caps the effective grant at zero, producing `startup_failure` at every caller.

**Enforcement**: Mechanical — `validate-permissions-shape.py` + `validate-permissions-shape.yml` (pilot 27 of `/promote-rule` 2026-05-14, paired with [CI-090]). Compose-in-script: validator inspects `on:` trigger shape and fires CI-097 for the specific deny-all-on-reusable case; CI-090 covers the broader top-perms-on-reusable case. Combined workflows treated as reusable. Baseline 0 wrapper-host (the M2 incident was reverted within minutes; current ecosystem state has no `permissions: {}` on reusables); self-firing ACTIVE — inherits CI-090, whose batch-fix `5161e33..74ae3d0` landed (synced 2026-07-03 per CI-REVIEW dossier F10). Discipline: `Audits/PROMOTE-CI-090-CI-097-2026-05-14.md`. [VERIFICATION: WF validate-permissions-shape.py]

**Cross-references**: [CI-051], [CI-090], [CI-106]; memory `feedback_top_level_permissions_on_reusables.md`.

---

## Prioritization & Admin Scope

### [CI-096] CI Prioritization Axes

**Statement**: CI/CD changes (new workflows, refactors, cohort proposals, third-party action introductions) MUST be evaluated on three axes in this order: **correctness > security > speed**. Dollar/minute cost is NOT a significant axis for swift-institute CI/CD work. **Amendment (2026-07-20)**: runner CONCURRENCY is not "cost" — it is a hard free-plan capacity budget (5 concurrent macOS / 20 total per org) whose exhaustion manifests as queue latency, i.e. the SPEED axis. Arguments from concurrency/queue-latency are legitimate speed-axis arguments and must be evaluated as such, not dismissed under this rule. (This distinction is what [CI-115] tiered scheduling rests on; measured 2026-07-20: 7–12.5h macOS queue tails against 36–144s leg compute.)

**Rationale**: CI workflows in swift-institute run only on public repos (per [CI-032] visibility gate + [CI-060] free-plan billing alignment). Public repos have unlimited GitHub Actions runner MINUTES on the Free plan; private repos never get CI cycles per [CI-094]. The dollar-cost dimension that drives CI prioritization in commercial codebases does not constrain this ecosystem — but concurrent-runner capacity does, and history conflating the two delayed the [CI-115] redesign.

**How to apply**: When proposing a CI cohort, comparing approaches, or weighing trade-offs:

| Framing | Axis | Treatment |
|---|---|---|
| "This adds 30 minutes to PR latency" | Speed | Evaluate against correctness/security gain |
| "This costs $1.50 per PR on macos-26" | (none) | Reject; not a meaningful concern unless it ALSO improves speed/security/correctness |
| "This adds a third-party dependency" | Security | Evaluate against the value provided |
| "Collapse the matrix to save cost" | (none) | Reject the SHAPE collapse ([CI-091]); per-push SCHEDULING is governed by [CI-115] tiers |
| "This saturates the org's 5-runner macOS pool" | Speed | Legitimate concurrency/queue-latency argument; evaluate against correctness gain |

Consistent with the harden-runner / SHA-pinning / cosign-attestation prioritization in [CI-080] / [CI-082]: those each carry non-trivial speed costs but high security/correctness value, and the trade-off resolves toward proposing them.


**Cross-references**: [CI-032], [CI-060], [CI-080], [CI-082], [CI-094].

---

### [CI-098] Admin-Scope GitHub Operations Via Web UI

**Statement**: Admin-class GitHub operations (App install permissions, org settings, branch-protection settings, repo settings) MUST be performed via the github.com web UI. The `gh` CLI MUST NOT be invoked with admin scopes (`admin:org`, `admin:repo`); read-only `gh` calls (`read:org`, `repo:read`) are permitted.

**Rationale**: Admin-scope CLI tokens carry session-state implications (audit-log attribution, MFA prompts, cross-org bleed) that the web UI handles cleanly and the CLI does not. Web UI also provides confirmation dialogs and visible diffs for settings changes that a CLI PUT does not. Principal explicitly does not want admin-scope CLI tokens to exist on the workstation.

**How to apply**:

| Operation class | Path |
|---|---|
| Trim/expand GitHub App installation permissions | Web UI — `https://github.com/organizations/<org>/settings/installations/<id>` |
| Org settings (members, secrets, default permissions, App management) | Web UI |
| Branch-protection rule edits | Web UI — `https://github.com/<owner>/<repo>/settings/branches` |
| Repo settings (visibility, default branch, topics outside metadata.yaml flow) | Web UI |
| Org membership changes | Web UI |
| Read-only API calls (`gh api orgs/<org>/installations`, `gh api repos/<owner>/<repo>/branches/main/protection` GET, `gh repo list`, `gh search code`, `gh api orgs/<org>/audit-log`) | `gh` CLI permitted (read-only scopes) |
| Reading-back-state-after-web-UI-write (verification gate) | `gh` CLI permitted |

**Forbidden**: `gh auth refresh -h github.com -s admin:org`, `-s admin:repo`. If a workflow proposes a step that requires admin scope on `gh` CLI, redirect to web UI.

**Doc-vs-execute distinction**: `gh api -X PUT` framings in security-review documents are documentation-grade (specifying the protection shape concretely), not execution-grade. When a cohort lands, execution is via web UI on each repo's settings page; the `gh api` shape doc is the spec, not the runbook.


**Cross-references**: [CI-052].

---

## Version Pins

### [CI-107] Latest-Version Pin Discipline

**Statement**: Files that pin versions — GitHub Actions workflows, runner images, action refs, tooling pins — MUST carry the current latest version on every touch. No older versions, no deferred bumps, no "leave it alone because it works." Lazy-carrying older version pins on touched files accumulates staleness across the ecosystem.

**Two forms satisfy the latest-version floor for action refs** — the "latest" floor governs the *version*, not the *ref shape*:

- **Floating major tag** (e.g., `actions/checkout@v6`) — permitted for benign refs. A floating major tag is not, by itself, a [CI-107] violation.
- **Digest-pin at latest** — the full commit SHA of the latest release plus a `# vX.Y.Z` version comment (e.g., `actions/checkout@11bd71901…  # v4.2.2`). Permitted for any action ref, and the PREFERRED form for credential-minting / privileged / security-sensitive actions (those handed a private key or elevated token). Both forms carry "latest"; the digest form additionally freezes the ref against floating-tag repointing — the supply-chain property that matters when the action holds a credential. Digest-pin-at-latest composes with [CI-082]: bump to the latest release AND re-lock the commit SHA on every touch.

This is a permission and a preference, NOT a universal digest-pin mandate: benign refs MAY keep floating major tags. [CI-107] governs staleness (is the pin at latest?), not ref shape (tag vs SHA).

**Rationale**: Principal direction — *"latest of the latest only. no older versions. Must be latest version always"* — issued when a workflow-file edit left `runs-on: macos-15` in place. The "latest" floor is the same one that motivates the [CI-082] re-lock-on-bump discipline; the two compose: bump to latest AND re-lock the digest.

**How to apply**:

| Pin class | Target | Verification |
|---|---|---|
| Action refs | Current major floating tag (e.g., `actions/checkout@v6`) for benign refs; digest-pin at latest (full commit SHA + `# vX.Y.Z`) for credential-minting / privileged / security-sensitive refs — PREFERRED there, permitted anywhere | `gh api repos/<owner>/<repo>/releases/latest --jq .tag_name`; for the digest form, dereference the tag to its **commit** SHA (`git/ref/tags/<tag>` → if `type: tag`, deref via `git/tags/<sha>.object.sha`; a tag-object SHA is not a valid action ref) |
| Runner images | Highest available (e.g., `macos-26`, not `macos-15`) | `gh api repos/actions/runner-images/releases --jq '.[0:5][].tag_name'` |
| Curl-fetched binaries | Latest release tag + re-locked SHA-256 per [CI-082] | Per-binary release page |
| Swift toolchain | Per memory `feedback_toolchain_versions.md` (6.3 stable + Swift main nightly) | Toolchain memory overrides "latest" |

**Floating-tag rule**: if a floating tag (e.g., `@v3`) points to a pre-release that is more recent than the latest stable release tag, the floating tag wins — that is the "latest" intended.

**Exceptions**:

- Swift toolchain pins follow `feedback_toolchain_versions.md`, not "latest"; only Swift 6.3 stable and Swift main nightly (`swiftlang/swift:nightly-main-jammy`) are permitted.
- Do not silently bump version pins deliberately chosen to match other infrastructure (e.g., a specific toolchain a downstream project requires). If unsure, ask.
- Harden-runner is SHA-pinned per [CI-080], NOT major-tag-pinned — security action exception.


**Cross-references**: [CI-013], [CI-080], [CI-082].

---

