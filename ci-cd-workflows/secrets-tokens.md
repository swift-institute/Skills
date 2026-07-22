# CI/CD — Secrets, Tokens, Visibility & Private-Repo Gates

Companion of the **ci-cd-workflows** skill (navigation hub: `SKILL.md`). Load when working on the public/private visibility gate, org-level tokens, cross-org secret transport, `secrets: inherit` vs explicit-forward, or how pre-publication CI gates are satisfied on this workspace's Free-plan private repos. This file reads independently: it collects the credential-transport and private-repo-signal rules.

**Rules in this file**: [CI-032], [CI-058], [CI-059], [CI-060], [CI-109], [CI-094], [CI-095], [CI-112]

---

## Visibility Gate

### [CI-032] Public/Private Visibility Gate

**Statement**: Every job in every intra-Institute reusable workflow carries `if: ${{ !github.event.repository.private }}` at the job level (simple form, or compound via `&&`). Excluded: pure `uses:`-only routing jobs (job-level `uses:` with no `steps:`/`runs-on:`) — the gate lives on the called workflow's real work job, not the routing shim; NARROWS [CI-080]'s pure-`uses:`-only routing exclusion (corrected 2026-07-05, Phase-3 review — the two are not a mirror: [CI-080]'s carve-out (`validate-harden-runner.py`) requires only the absence of `steps:`, while [CI-032]'s additionally requires the absence of `runs-on:` so the exemption stays narrower). A job carrying real work (`steps:`/`runs-on:`) is never treated as routing even if it also declares `uses:`.

**Enforcement**: Mechanical — `validate-visibility-gate.py` + `validate-visibility-gate.yml` (pilot 13 of `/promote-rule` 2026-05-14). Single-repo multi-file integrity check. Carve-outs: pure `uses:`-only routing jobs (structural — job-level `uses:` with no `steps:`/`runs-on:`; mirrors [CI-080]), `if: false` disabled jobs, non-`workflow_call:` workflows (out of scope). Self-firing ACTIVE; post-carve-out the true baseline of genuinely-ungated jobs is 0 on `swift-institute/.github`. Provenance: the 18 findings that surfaced 2026-07-03 were pure-routing `scan:` jobs in the `validate-*.yml` thin callers (each routes to `validate-base.yml`, whose real work job carries the gate), un-masked when the Slice-A `validate-base.yml` aggregation fix (`12c9d5a`) restored real finding counts. They were routing-job artifacts, not gate violations, and are resolved by the routing carve-out added here. Discipline: `Audits/PROMOTE-CI-032-2026-05-14.md`. [VERIFICATION: WF validate-visibility-gate.py]

**Cross-references**: [CI-031], [CI-060], [CI-080]; memory `feedback_no_public_or_tag_without_explicit_yes.md`.

---

## Secrets & Tokens

### [CI-058] Universal `enable-private-repos` Default True

**Statement**: Any reusable workflow declaring an `enable-private-repos` input MUST default it to `true`; consumers opt OUT (rare public-only case) rather than opt IN.

**Enforcement**: Mechanical — `validate-input-defaults.py` + `validate-input-defaults.yml` (pilot 24 of `/promote-rule` 2026-05-14). Single-repo multi-file integrity check; PyYAML navigates `on.workflow_call.inputs.enable-private-repos.default` and fires if not literally `True`. Silent on workflows that don't declare the input. Covers the swift-institute/.github reusables (swift-ci.yml + swift-docs.yml) and swift-primitives/.github's swift-ci.yml. NOTE (2026-07-03, per CI-REVIEW dossier F34): the swift-standards/.github and swift-foundations/.github layer wrappers ALSO declare `enable-private-repos` (verified) and are currently OUTSIDE the validator's target set — a coverage gap tracked for follow-up (extend the validator's target list to the standards + foundations wrappers). Consumer-side redundant-pass-through check deferred — future composition into validate-thin-callers.py. Baseline 0/2 wrapper-host repos; self-firing ACTIVE. Discipline: `Audits/PROMOTE-CI-058-2026-05-14.md`. [VERIFICATION: WF validate-input-defaults.py]

**Cross-references**: [CI-031], [CI-032], [CI-059], [CI-060].

---

### [CI-059] `secrets: inherit` for Per-Repo Reusable Workflow Calls

**Statement**: Per-repo `ci.yml` `uses:` invocations of intra-Institute reusable workflows MUST include `secrets: inherit` in the same job; explicit per-secret forwarding and omission are both forbidden — for LAYER-ORG-hosted consumers. Sub-org-hosted consumers follow the sub-org caveat below.

**Sub-org caveat (principal-confirmed 2026-06-04, pattern (ii))**: consumers hosted in per-authority SUB-ORGS (the 11 L2 + 2 L3 orgs enumerated in [CI-004b]) are the exception: their hop 1 into the parent layer wrapper is itself cross-org, where `secrets: inherit` delivers no org secrets ([CI-109]). Sub-org thin callers therefore MUST explicit-forward the named private-dep credential set (`PRIVATE_REPO_TOKEN`, `SWIFT_INSTITUTE_BOT_APP_CLIENT_ID`, `SWIFT_INSTITUTE_BOT_APP_ID`, `SWIFT_INSTITUTE_BOT_APP_PRIVATE_KEY`) instead of `secrets: inherit` — values resolve in the consumer's own org context and survive the cross-org hop. (Validator support SHIPPED: `validate-thin-callers.py` accepts the explicit-forward shape for sub-org-hosted callers as of swift-institute/.github `d56e36a` (2026-06-04), matching [CI-004a]'s landed-note. The prior "aspirational / would fire on them today" parenthetical was doc-drift, corrected 2026-07-03 per CI-REVIEW dossier F9.)

**Enforcement**: Mechanical — `validate-thin-callers.py` + `validate-thin-callers.yml` (pilot 17 of `/promote-rule` 2026-05-14, compose-in-script with [GH-REPO-074] and [CI-030]). Per-job indentation walk requires same-job co-presence of `uses: <intra-Institute>` and `secrets: inherit`; distinguishes explicit-forwarding from omission for diagnostic clarity. Baseline 0/240 consumer repos; self-firing DEFERRED — `validate-thin-callers.yml` is `workflow_call`-only (no `push`/`pull_request` trigger); validated via the weekly `lint-validators-weekly` sweep only (manifest `self-firing: deferred`) (corrected 2026-07-03 per CI-REVIEW dossier F8). Sub-org explicit-forward acceptance: SHIPPED (`d56e36a`, 2026-06-04). Discipline: `Audits/PROMOTE-CI-030-CI-059-2026-05-14.md`. [VERIFICATION: WF validate-thin-callers.py]

**Cross-references**: [CI-031], [CI-032], [CI-058], [CI-060], [CI-004b], [CI-109].

---

### [CI-060] Org-Level `PRIVATE_REPO_TOKEN` + Free-Plan Visibility Alignment

**Statement**: `PRIVATE_REPO_TOKEN` lives as an org-level Actions secret with `--visibility all` on every ecosystem org that hosts CI-running consumer repos; per-repo `PRIVATE_REPO_TOKEN` secrets are forbidden as redundant. Free-plan constraint: org secrets inherit only to public repos — aligns with [CI-032] (private consumer repos skip jobs).

**Enforcement**: Mechanical — `lint-org-bot-coverage.yml` axis 2 verifies org-level secret exists with `--visibility all` for each org in `orgs.yaml`; gap surfaces as tracking issue per [README-167]. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-060]. [VERIFICATION: WF lint-org-bot-coverage.yml axis 2]

**Cross-references**: [CI-031], [CI-032], [CI-058], [CI-059].

---

### [CI-109] Cross-Org Secret Transport (Explicit-Forward at Org Boundaries)

**Statement**: Intra-Institute reusable-workflow call chains MUST carry secrets across org boundaries via explicit `secrets:` value-forwarding. `secrets: inherit` is same-org-only: a chain hop whose `uses:` target lives in a DIFFERENT org silently delivers no org-level secrets — jobs behave as if unsecreted, with no parse-time or run-time diagnostic. Chain-design corollary: hop 1 (consumer → wrapper) MUST be same-org so inherit lands the org secrets in the wrapper; every subsequent cross-org hop explicit-forwards the values. Sub-org-hosted consumers, whose hop 1 is itself cross-org, follow the [CI-059] sub-org caveat (explicit-forward at the thin caller).

**Empirical basis**: byte-primitives run 26959288611 (2026-06-04), paired within one run, same org, same secrets: the docs job (consumer → swift-institute/.github cross-org, `secrets: inherit`) produced `Configured 0 git url rewrite rule(s)`; the matrix path (consumer → swift-primitives/.github same-org inherit → swift-institute/.github cross-org EXPLICIT) produced `Configured 4`. The configure-private-repos composite's `Configured N` echo is the canonical canary check for this rule.

**Enforcement**: Architectural today — the layer wrappers (`<layer>/.github/.github/workflows/swift-ci.yml` + `swift-docs.yml`) carry the explicit `secrets:` blocks; consumers reach the universal only through them per [CI-004a] and [CI-031]. Mechanical candidate (queued): extend `validate-thin-callers.py` to fire on `uses: <other-org>/…` + `secrets: inherit` co-presence. [VERIFICATION: ARCH]

**Rationale**: The gap is silent by construction — the empty-credential path degrades to anonymous fetch, which works for all-public dependency graphs and fails only when a private dep enters the graph (the 2026-06-04 public-cohort redness class). Encoding the transport rule prevents new chain edges from reintroducing the latent gap.


**Cross-references**: [CI-001], [CI-004a], [CI-059], [CI-060].

---

## Private-Repo CI Gates (Free-Plan)

### [CI-094] Local Clean-Build Substitution for Private-Repo Gates

**Statement**: On this workspace's Free-plan GitHub account (no billing configured), CI on private repositories does not produce reliable signal — private-repo minutes are constrained (2000/month default); exhausted minutes silently fail subsequent runs and absent billing there is no extension path. Any pre-publication CI gate that targets a private repo (e.g., [RELEASE-001] Phase 0 "CI green", [RELEASE-002] Phase 0) MUST be satisfied via local-equivalent verification, NOT via GitHub Actions output, until the visibility flip to public.

**Local-equivalent substitution shape**:

```bash
rm -rf .build && swift build && swift test    # per package
swift run <linter>                             # if the repo's CI runs a linter step
```

The release brief's Phase 0 verification section MUST document the substitution so the next reviewer can confirm the gate cleared via local-equivalent.

**Visibility flip ordering**: the visibility-flip-to-public is a CI-activation step in addition to a launch step. Sequence the flip just before the tag, AFTER local equivalents are clean. Per-action authorization still applies to the flip itself (settings.json gate).

**Failure-mode discipline**: any "CI failure" on a private repo is billing-constraint UNTIL proven otherwise. Read the run logs to confirm (minutes-exhausted vs actual error) — default suspicion is billing. Treating billing-constraint failures as code defects burns dispatches chasing nothing.


**Cross-references**: [CI-052] (visibility/tag explicit-authorization), [CI-095] (the surface-distinction companion), [RELEASE-001], [RELEASE-002].

---

### [CI-095] Rule-Activation Surface vs Bookkeeping Surface

**Statement**: The `swift-ci.yml` reusable workflow's job-level `if: ${{ !github.event.repository.private }}` causes all consumer-orchestrated CI jobs to skip on private repositories. Rollout-strategy planning and blast-radius estimation MUST distinguish two surfaces:

| Surface | Population | What CI activity fires |
|---------|------------|------------------------|
| Rule-activation | Public packages only (e.g., currently 4 in swift-primitives — swift-carrier-primitives, swift-tagged-primitives, swift-ownership-primitives, swift-property-primitives) | New rule-tier additions immediately affect these on next CI run |
| Bookkeeping / alignment | All sub-packages (132+ in swift-primitives) | Local config alignment maintained; produces no rule-firing CI signal under current configuration |

"Broad rollout" framing implies wide CI signal; under the private-no-CI gate, broad-rollout describes alignment, not activation. Phase-2+ rule-addition decisions MUST be made considering only public-package CI signal as the active diagnostic surface; the private-package surface is currently inert as a diagnostic.

**Dispatch-surface rider (2026-07-03)**: the `!github.event.repository.private` gate evaluates against the ORCHESTRATING/triggering repo (the repo whose event fired the run), not the dependency target. For the consumer-orchestrated surface tabled above, that repo IS the consumer, so a private consumer's jobs skip. The centrally-dispatched surface is different: `ci-dispatch.yml` (added 2026-07-03, runs from the PUBLIC `swift-institute/.github`) fires with the public hub as the triggering repo, so its jobs are NOT subject to the private-skip — they run. A private dispatch target is therefore not silenced at the gate; it instead fails downstream at the target checkout (private-repo access), a distinct failure mode from the silent gate-skip. Rollout planning MUST account for both: the gate protects consumer-orchestrated runs, not centrally-dispatched ones. See [CI-032] (the gate itself) and [CI-096] (public-hub dispatch = free Actions minutes).

**Composes with [CI-094]**: pre-publication gates on private packages substitute local-equivalent (per [CI-094]); the activation/bookkeeping distinction is the framing-level companion that describes WHY the substitution is needed and WHEN the gate will eventually clear via real CI signal (post-visibility-flip).


**Cross-references**: [CI-032] (the visibility gate itself), [CI-094], [CI-052], [CI-096], `project_per_repo_vs_centralized_ci.md`.

---

### [CI-112] Clean-Room (Mirror-Bypassed) Resolve Is a Non-Substitutable Off-Machine Gate

**Statement**: A gate that asserts a package "resolves from scratch" / off-machine (publication, public-flip, closure re-verify) MUST be satisfied by an ACTUAL mirror-bypassed clean-room `swift package resolve` — never by substitute proofs (`grep` + `git ls-remote` reachability + a mirror-backed resolve) declared "equivalent." Only the mirror-bypassed resolve catches the off-machine failures the substitutes miss: empty/unpushed dependency repos (`git ls-remote <url> HEAD` exits 0 on an EMPTY repo, so a reachability sweep counts it green while it has no `main` off-machine) and off-machine package identity ([PKG-DEP-008]). A mirror-backed resolve only proves the graph is internally consistent against LOCAL clones. Run it on PRIVATE repos WITHOUT a temp HOME or token injection ([CI-094] free-plan discipline): keep the real session's ambient auth, briefly `mv ~/.swiftpm/configuration/mirrors.json` aside, `git clone` a consumer-root fresh + resolve, then restore the mirror via a `trap`-guarded self-restoring script. CI-runner form (a clean-runner resolve job on the public hub) + full safe-run recipe: Research/ci-cd-workflows-skill-rationale.md §[CI-112].

**Enforcement (CI-runner form, LANDED)**: `clean-room-resolve.yml` on the public hub (/promote-rule 2026-07-06) — weekly + dispatch, matrix over the heaviest consumer-roots, per-org bot-token `insteadOf` injection, `rm Package.resolved` + full resolve, per-pin `refs/heads/main` sweep. ADVISORY during soak (`gating=false`); flip gating before any publication flip. Discipline: `Audits/PROMOTE-CI-112-2026-07-06.md`. [VERIFICATION: WF]


---

