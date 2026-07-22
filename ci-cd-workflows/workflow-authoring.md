# CI/CD — Workflow-Authoring Gotchas, Parse-Time Failure Classes & Validators

Companion of the **ci-cd-workflows** skill (navigation hub: `SKILL.md`). Load when authoring or auditing a workflow / composite action for correctness: composite-action call-site eligibility, the parse-time (`startup_failure`) failure classes, scheduled-workflow canary discipline, and custom-lint-rule discipline. This file reads independently: it collects the "this shape fails at workflow-load or evades a check" rules that the `validate-*` probes police.

**Rules in this file**: [CI-070], [CI-102], [CI-103], [CI-105], [CI-106], [CI-110], [CI-104], [CI-100], [CI-101]

---

## Composite Actions

### [CI-070] Composite-Action Call-Site Eligibility

**Statement**: GitHub Actions composite actions (under `<repo>/.github/actions/<name>/`) have call-site constraints distinct from reusable workflows. Three rules govern composite-action use across the corpus:

| Constraint | Rule |
|---|---|
| (a) **No in-loop calls** | A composite action MUST be invoked as a top-level workflow step. Composite actions cannot be invoked inside a shell `for`-loop or any other shell-level iteration construct. Per-iteration work that recurs across callers stays inline; alternatives include sourced shell helpers at `.github/scripts/<name>.sh` or refactoring the iteration to a matrix-driven dispatch. |
| (b) **`./local/path` refs require checkout** | Composite refs of the form `./.github/actions/<name>` require an `actions/checkout@vN` step earlier in the same job. Container-based jobs without checkout (e.g. swift:6.3 sweep jobs that fetch helpers via curl) cannot resolve `./local/path` refs and fail at job-start with `Can't find 'action.yml' under .../<name>`. |
| (c) **Cross-repo `@main` refs are the corpus standard** | `<owner>/<repo>/.github/actions/<name>@main` refs are fetched by the runner's action-resolver without requiring a local checkout. This is the corpus's standard pattern across every in-tree composite consumer, even when the calling workflow lives in the same repository as the composite. |

**Reference precedents** (corpus-canonical cross-repo refs):

```yaml
- uses: swift-institute/.github/.github/actions/configure-private-repos@main
- uses: swift-institute/.github/.github/actions/install-swift-sdk@main
- uses: swift-institute/.github/.github/actions/enumerate-org-public-repos@main
- uses: swift-institute/.github/.github/actions/upsert-tracking-issue@main
- uses: swift-institute/.github/.github/actions/read-orgs@main
```

The pattern holds even within the calling repository — the cross-repo form avoids the checkout dependency that `./local/path` imposes and matches what every other composite consumer uses.

**When composite extraction is wrong** — Axis-2 failure of the refactor framework:

- Recurring shell snippets inside `for target in "${targets[@]}"; do ... done` loops cannot be extracted as composites without restructuring the iteration (e.g., into a `fromJSON`-driven matrix). When restructure cost exceeds extraction benefit, the inline pattern stays.
- The `clone-repo-with-app-token` extraction proposed in this audit's PM #2 was such a case — every clone site is in-loop; a composite cannot be invoked there. Inline pattern stays at all 6 sites; the framework articulation caught this at design-time, preempting code overreach.

**Composite vs reusable workflow — choice axis**:

- **Composite action** (`.github/actions/<name>/action.yml`): step-level reuse. Inputs are strings; outputs are strings. Cannot read `secrets` context — caller passes the value via `with:`. Runs as steps inside the calling job. Use for: per-step fragments, multi-step recipes (clone + install + run), encapsulating an installation pattern.
- **Reusable workflow** (`.github/workflows/<name>.yml` with `on: workflow_call`): job-level reuse. Inputs are typed (string/boolean/number); outputs are typed; secrets pass via `secrets: inherit` or explicit forwarding. Runs as its own job(s) with its own runner. Use for: whole-job orchestration, matrix-shaped sweeps, anything that needs `permissions:`/`runs-on:`/`container:` at the job level.

**Rationale**: Composite-action constraints are silent in GitHub Actions documentation but bite consistently in practice. Codifying the three call-site eligibility rules + the composite-vs-reusable-workflow choice axis preempts design speculation: PM #2 of the 2026-05-05 audit's refactor inventory was framed as a composite extraction in the original brief, but the in-loop call-site made it Axis-2-impossible — a fact the framework articulation surfaced at design time, before any code was written. The PM #1 fix-forward (cross-repo `@main` switch from `./local/path` after the swift:6.3 container-without-checkout case failed canary) is the same lesson applied retroactively: the constraint exists; codifying it makes it discoverable before it bites.


**Cross-references**: [CI-001] (three-tier reusable-workflow chain — distinguishes composite scope from reusable-workflow scope), [CI-030] (`@main` pinning during active dev — applies to both forms), [CI-031] (per-package consumer `ci.yml` — uses reusable workflows, not composites).

---

## Parse-Time Failure Classes

### [CI-102] Composite-Action Description Plain Text

**Statement**: Composite-action description fields (top-level, per-input, per-output) MUST NOT contain `${{ ... }}` expressions — Actions evaluates expressions at composite-action parse time and rejects with HTTP 422.

**Enforcement**: Mechanical — `validate-composite-action-descriptions.py` + `validate-composite-action-descriptions.yml` (pilot 25 of `/promote-rule` 2026-05-14). Single-repo multi-file integrity check on `<repo>/.github/actions/*/action.yml`; PyYAML walks `description` at three positions (top-level, `inputs.<name>.description`, `outputs.<name>.description`) and fires on `${{` substring. Expression syntax in non-description positions (`runs.steps[*].env`, `outputs.<name>.value`, `if:`) is permitted and silent. Baseline 0; self-firing ACTIVE. Discipline: `Audits/PROMOTE-CI-102-2026-05-14.md`. [VERIFICATION: WF validate-composite-action-descriptions.py]

**Cross-references**: [CI-070], [CI-103]; memory `feedback_composite_action_description_no_expressions.md`.

---

### [CI-103] `env.*` Forbidden in `runs-on:` / `container:`

**Statement**: Workflow-level `env:` MUST NOT be referenced from `runs-on:` or `container:` fields — Actions resolves these fields before workflow-level `env:` is bound, producing parse-time HTTP 422. Use `inputs.*`, `vars.*`, or literal hardcode.

**Enforcement**: Mechanical — `validate-env-context.py` + `validate-env-context.yml` (pilot 21 of `/promote-rule` 2026-05-14). Single-repo multi-file integrity check; per-job PyYAML inspection of `runs-on:` (string or list) and `container:` (string or dict with `image:`) for `${{ env.X }}` substring. Other contexts (`inputs.*`, `vars.*`, `matrix.*`, `github.*`) are permitted and not flagged; step-level `env.*` references (in `run:` blocks, `with:` blocks, etc.) are out of scope (env: binds before step execution). Baseline 0/4 wrapper-host repos; self-firing ACTIVE. Discipline: `Audits/PROMOTE-CI-103-2026-05-14.md`. [VERIFICATION: WF validate-env-context.py]

**Cross-references**: [CI-102], [CI-104]; memory `feedback_env_invalid_in_runs_on_container.md`.

---

### [CI-105] `continue-on-error` Invalid on `workflow_call` Jobs

**Statement**: `continue-on-error: true` MUST NOT co-exist with `uses:` at the same job level. The Actions parser rejects the shape with `Unexpected value 'continue-on-error'` causing `startup_failure` across the entire chain; use the `inputs.advisory: bool` pattern instead.

**Enforcement**: Mechanical — `validate-continue-on-error.py` + `validate-continue-on-error.yml` (pilot 19 of `/promote-rule` 2026-05-14). Single-repo multi-file integrity check; per-job YAML inspection of co-presence of `continue-on-error: true` and `uses:`. Step-level `continue-on-error` and `continue-on-error` on regular `runs-on:`/`steps:` jobs are out of scope (rule applies to workflow_call'd jobs only). Baseline 0/4 wrapper-host repos; self-firing ACTIVE. Discipline: `Audits/PROMOTE-CI-105-2026-05-14.md`. [VERIFICATION: WF validate-continue-on-error.py]

**Cross-references**: [CI-099], [CI-106]; `swift-institute/Research/centralized-swift-ci-and-spine-gate.md` §3.5.1.

---

### [CI-106] `workflow_call` Permissions Chain

**Statement**: When a `workflow_call` reusable declares `permissions:` at job level (e.g., `contents: write`), every level of the call chain (consumer ci.yml → layer wrapper → universal `swift-ci.yml` → reusable) MUST grant equivalent or greater permissions. Mismatch produces `startup_failure` at workflow-load time with `jobs: []` and `conclusion: startup_failure` — no diagnostic logs available. The behavior is parse-time, not runtime.

**Rationale**: Discovered 2026-05-05 when `submit-dep-graph.yml`'s `permissions: contents: write` (declared per [CI-090] caller-side trigger-shape pattern) caused three consecutive consumer CI dispatches to fail with no jobs run (commit `2480628` broke; fix `41e1815` commented out the caller). Effective-grant rule: `min(caller_grant, reusable_top_level, reusable_per_job)`. If any level falls short of any sibling's declaration, the chain collapses at parse.

**How to apply**:

1. For any reusable that needs elevated permissions (write, issues, etc.), the caller chain at every level MUST declare equivalent or greater. With [CI-031] minimum at consumer `ci.yml` (no permissions block by design), the only viable invocation is a NON-reusable pattern — a separate per-package workflow that takes its top-level `permissions:` directly.
2. For dep-graph submission (`vapor-community/swift-dependency-submission` action), this means accepting per-package opt-in workflow files rather than transitively chaining through the universal CI.
3. When designing a new reusable, prefer the lowest possible permissions. If `contents: read` works, declare it; never declare `contents: write` speculatively.
4. Composes with [CI-097]: reusable's top-level `permissions:` block is a *ceiling*, not a floor; do not declare top-level on reusables.


**Cross-references**: [CI-031], [CI-090], [CI-097], [CI-105].

---

### [CI-110] Mixed-Trigger Workflows Null-Coerce Typed-Boolean Input Forwarding

**Statement**: A workflow carrying BOTH inputs-bearing triggers (`workflow_dispatch` / `workflow_call`) AND inputs-less triggers (`push` / `pull_request` / `schedule`) MUST null-coerce any forwarding of `inputs.<name>` into a typed-**boolean** reusable-workflow input: `${{ inputs.<name> == true }}`, never bare `${{ inputs.<name> }}`. On inputs-less events the `inputs` context does not exist, the bare expression yields `''`, and boolean type-validation fails at workflow-load: `startup_failure`, zero jobs, NO logs — the silent class. String-typed inputs tolerate the empty value and are exempt.

**Empirical basis**: all 18 `validate-*` thin callers forwarded `dry-run: ${{ inputs.dry-run }}` into `validate-base.yml`'s typed-boolean input and startup-failed on EVERY push/PR run from the Phase B-1 migration (2026-05-14/21) until 2026-06-04 — while `workflow_dispatch`/orchestrator `workflow_call` runs (inputs present) stayed green, masking the defect from the May Phase-6 dispatch probes. Fixed in swift-institute/.github `105b3b5` (`== true` across all 18).

**Diagnosis signature**: run `conclusion: failure` + `jobs: []` + no fetchable logs (`gh run view --log-failed` returns empty — startup_failure produces no log stream; a tool-reach trap).

**Workflow-grep discipline**: when auditing workflows for expression literals (`${{ … }}`), use `grep -F` — BSD grep parses `{` and `$` as pattern syntax and silently returns 0 matches, so a BRE/ERE sweep reads as "no occurrences" while the sites exist. Example: `grep -F 'dry-run: ${{ inputs.dry-run }}' .github/workflows/*.yml`. Same tool-reach class as the no-logs signature above (Reflections/2026-06-04-porter-ci-private-dep-access-arc.md).

**Provenance notes** (grep-trap in `validate-base.yml` `12c9d5a`; `|| true` crash-swallow follow-up `0abdfa1`; validator fail-fixture backfill + out-of-family `validate-schema-workflow-keys.py` note): Research/ci-cd-workflows-skill-rationale.md §[CI-110]. All non-normative; no Statement changed.

**Enforcement**: Candidate validator — flag `<name>: ${{ inputs.<name> }}` forwarded toward a `type: boolean` input of a `uses:` target inside mixed-trigger workflows. Until mechanized: review discipline at workflow authoring. [VERIFICATION: ARCH]


**Cross-references**: [CI-103], [CI-105], [CI-106] (sibling parse-time failure classes), [CI-109].

---

## Scheduled-Workflow Canary

### [CI-104] Scheduled-Workflow Canary Discipline

**Statement**: Any change touching a workflow whose only triggers are `schedule:` (and optionally `workflow_dispatch:`) MUST be exercised by an explicit `gh workflow run <name>.yml --ref main` canary. The standard "trigger consumer ci.yml on a public consumer" canary does NOT exercise scheduled workflows; failures escape until the next scheduled firing — up to a week away for weekly crons.

**Rationale**: Lesson from 2026-05-05 deep-cleanup pass. Commits `ecf36e6` + `91dd8db` landed a parse-time bug per [CI-103] in 2 cron orchestrators. The cleanup-pass canary on swift-tagged-primitives reported all jobs GREEN, but tested only consumer-CI. The bug only surfaced 30+ minutes later when a cleanup-cohort canary explicitly triggered the cron orchestrators via `workflow_dispatch`.

**How to apply**: For any change touching a `*-weekly.yml` or `*-nightly.yml` (or any workflow without `push` / `pull_request` triggers):

1. Push the change.
2. Explicitly trigger via `gh workflow run <name>.yml --repo <repo> --ref main [--field dry-run=true]`.
3. Watch the run via `gh run view <id>`.
4. Verify both parse (job starts) AND execution (steps succeed).

**Sub-axis** for `pull_request`-only-triggered reusables (e.g., `lint-api-breakage.yml` gated on `if: github.event_name == 'pull_request'`): even `workflow_dispatch` on a consumer's `ci.yml` doesn't exercise them — the if-condition skips. Verification options: structural-trust (next organic PR provides signal post-merge), or trigger a real test PR.


**Cross-references**: [CI-051], [CI-103].

---

## Custom Lint-Rule Discipline

### [CI-100] SwiftLint `toggle_bool` Rule Exclusion

**Statement**: The SwiftLint opt-in rule `toggle_bool` MUST NOT be enabled in the canonical Tier 1 `.swiftlint.yml`; user-direction prefers `x = !x` over `x.toggle()`.

**Enforcement**: Mechanical — `validate-swiftlint-rules.py` + `validate-swiftlint-rules.yml` (pilot 22 of `/promote-rule` 2026-05-14). Centralized-config integrity check on single canonical `swift-institute/.github/.swiftlint.yml`; PyYAML inspection scans enable-position keys (`opt_in_rules`, `analyzer_rules`, `enabled_rules`) for forbidden rule name; explicit-disable position (`disabled_rules`) and absence-from-config (default off) are correctly silent. Baseline 0; self-firing ACTIVE. Discipline: `Audits/PROMOTE-CI-100-2026-05-14.md`. [VERIFICATION: WF validate-swiftlint-rules.py]

**Cross-references**: [CI-057], [CI-101]; memory `feedback_no_toggle_bool_rule.md`.

---

### [CI-101] No Regex-Evasion of Custom Lint Rules

**Statement**: Regex-based SwiftLint custom rules MUST NOT be satisfied by syntactically-different-but-semantically-identical rephrases (paren-wrapping, typename-swap, identifier rename, etc.). Such rephrases are FORBIDDEN — they are hidden disable-with-reason: same restraint, no audit trail, doesn't survive reformatting, reviewer cannot tell why the rephrase is there. When the canonical fix grid does not apply (typed-system bottom-out where the wrapper IS what the site implements), the engineer MUST escalate to supervisor and apply `// swiftlint:disable:next <rule>  // reason: <citation>` instead.

**Rationale**: 2026-05-06 R1–R4 cleanup wave 2a — subordinate applied `lhs.rawValue.addingReportingOverflow(rhs.rawValue)` → `(lhs.rawValue).addingReportingOverflow(rhs.rawValue)` (paren-wrap evasion of R3 `\.rawValue\.\w+`) and `self = Int(bitPattern: cardinal.rawValue)` → `self.init(bitPattern: cardinal.rawValue)` (typename-swap evasion of R4 `Int\(bitPattern:`). Both are semantically identical to the original anti-pattern; the rule fires because the code chains through `.rawValue` to call methods on the underlying primitive, and parens / typename change don't address that. Supervisor rejected; Tier 2 SwiftLint config hardened in `swift-primitives/.github` commit `7622a8b` to close the regex gap.

**How to apply**:

1. When a SwiftLint custom rule fires and the canonical fix grid (e.g., R3 options retag / map / typed accessor / bare-`.rawValue` rephrase) does not apply, the situation is "wrapper IS what this site implements" (typed-system bottom-out). Examples: arithmetic-operator implementations on Cardinal that must call stdlib `UInt.addingReportingOverflow`; the `Int.init(bitPattern: Cardinal)` integration overload.
2. Do NOT attempt syntactic rephrases (paren-wrap, typename-swap, identifier rename) to dodge the regex.
3. Escalate to supervisor BEFORE applying any fix — describe the bottom-out reasoning, get explicit approval.
4. Apply `// swiftlint:disable:next <rule_name>  // reason: <citation>` ABOVE the line, with a specific rationale (e.g., `typed-system bottom-out — Cardinal IS the wrapper implementing this primitive, [INFRA-103] options (i)–(iv) circular`). The reason citation makes the deliberate exception auditable and survives reformatting.
5. The Tier 2 ruleset is hardened against demonstrated evasion patterns (`chained_rawvalue_access_paren_evasion` companion rule; broadened R4 regex `\b\w+\(bitPattern:`) — but this meta-rule applies to any future custom rule.


**Cross-references**: [CI-057], [CI-100].

---

