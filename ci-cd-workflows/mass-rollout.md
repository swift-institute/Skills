# CI/CD — Mass-Rollout Discipline

Companion of the **ci-cd-workflows** skill (navigation hub: `SKILL.md`). Load when planning or executing a change that spans multiple consumer repos: workflow-file fan-outs, `gh workflow enable/disable` sweeps, sed/rewrite sweeps, push waves, visibility/tag flips, or mass source-modifying transforms. This file reads independently: it collects the authorization, surgical-commit, build-verify, and rewrite-safety rules for cross-repo operations.

**Rules in this file**: [CI-050], [CI-051], [CI-052], [CI-056], [CI-111], [CI-113]

---

### [CI-050] Mass Changes Require Per-Action Authorization

**Statement**: Any mass change spanning multiple consumer repos (workflow-file edits, `gh workflow enable/disable` fan-outs, sed sweeps, push waves) MUST be authorized per-action by the user. A multi-step plan described by the user is a roadmap, not blanket authorization for the whole chain — each push wave, each fan-out, each visibility flip needs its own explicit go-ahead.

**What counts as a "mass change"**:
- Edits applied across ≥3 consumer repos
- Sweeps via `sed`, `gh workflow enable/disable`, or scripted `gh api` calls
- Pushes to ≥2 ecosystem-shared repos in sequence (e.g., universal reusable + layer wrapper)

**Authorization granularity**:
- Per-canary-test (one repo) — explicit YES required
- Per-fan-out (N repos) — explicit YES required, separate from any prior canary auth
- Per-push to shared infrastructure (`swift-institute/.github`, `<layer>/.github`) — explicit YES required

**Rationale**: Mass operations on shared infrastructure have non-trivial blast radius; even reversible operations consume reviewer attention to verify post-state. The per-action discipline prevents "the user said proceed once, so I'll chain everything" failures.

**Cross-references**: [CI-051], [CI-052]; memory `feedback_user_plan_is_roadmap_not_authorization.md`.

---

### [CI-051] Surgical Commits, Dirty-Skip Discipline

**Statement**: Mass workflow-file changes MUST be applied via surgical commits — one logical change per commit, scope limited to the in-scope files. Repos with uncommitted local changes ("dirty") MUST be skipped during the fan-out and tracked for follow-up; the fan-out MUST NOT silently rebase, stash, or overwrite the dirty state.

**Procedure**:

1. Enumerate target repos via grep (record the count at start).
2. For each target: check `git status -s`; if dirty, skip and add to a tracked skip-list.
3. For each non-dirty target: apply the surgical edit; commit with a focused message; push.
4. Re-run the enumeration grep at end (record the post-state count, expect zero remaining for find-and-replace operations).
5. Verify on a canary repo's next CI run before declaring the fan-out complete.

**Forbidden**:
- `git stash` followed by edit followed by pop, on a dirty target
- Overwriting uncommitted changes
- "Skip dirty" without recording the skip-list for follow-up

**Rationale**: Dirty repos may carry the user's in-progress work or other agents' parallel changes; touching them via the fan-out silently entangles the unrelated changes with the rollout, creating a debugging mess if the rollout needs revert. The discipline is to leave dirty repos alone and triage them as a separate step.

**Cross-references**: [CI-050].

---

### [CI-052] Visibility/Tag Changes Require Explicit "YES DO NOW"

**Statement**: Repository visibility flips (private→public, public→private) and git tag operations on Swift Institute repos MUST be authorized by an explicit "YES DO NOW PUBLIC" / "YES DO NOW TAG" (or equivalent unambiguous per-action authorization) from the user. Visibility/tag changes MUST NOT proceed on inferred authorization, "/loop" continuation, auto-mode default, or any chain-authorization signal.

**Operations covered**:
- `gh repo edit --visibility public/private`
- `git tag` (any operation creating a tag pointing at a commit on a Swift Institute repo)
- `gh release create` (which creates a tag as a side effect)

**Out of scope** (these have their own per-action auth via [CI-050], not this stricter rule):
- `gh workflow enable/disable` (does not change visibility or create tags)
- Workflow file edits

**Rationale**: Visibility flips are externally-observable instantly (the repo appears in/disappears from public listings) and partially irreversible (caches, mirrors, search indexes may persist the public view). Tags are partially-immutable references that downstream consumers may pin to. The stricter authorization barrier prevents "good intent + ambiguous wording" failures.

**Cross-references**: [CI-050]; memory `feedback_no_public_or_tag_without_explicit_yes.md`; memory `feedback_blog_publish_two_steps.md` (analogous discipline for swift-institute.org publication).

---

### [CI-056] Per-Package Build Verification Before Push During Mass Source-Modifying Rollouts

**Statement**: When a mass rollout applies source-modifying transforms (e.g., `swift-format format --in-place`, sed sweeps, automated rewrites) across multiple consumer packages, EACH per-package commit MUST be gated on a successful local `swift build` (or equivalent compile-verify) BETWEEN the source modification and `git push`. Stop-on-first-build-failure for the package; track and surface dirty/failing packages rather than continuing the fan-out.

**Why mandatory**: source-modifying rollouts can produce semantically-equivalent changes ON AVERAGE while breaking SPECIFIC packages (e.g., the `[UseShorthandTypeNames]` rule rewriting `Array<X>` → `[X]` in packages that shadow `Swift.Array`). Without per-package build-verify, the fan-out ships broken commits to remote main where they trigger red CI and require recovery.

**Procedure**:

```text
For each target package P in the mass-rollout scope:
  1. Apply transform locally to P's source.
  2. Run swift build -c release (or equivalent compile-verify).
  3. If build succeeds: commit + push P. Continue to next package.
  4. If build fails:
     a. Reset P's working tree (git reset --hard HEAD).
     b. Add P to a tracked skip-list with the failure mode.
     c. Continue to next package OR halt fan-out depending on failure pattern (e.g., halt if >5 packages fail, suggesting systemic issue).
```

**Exceptions**: rollouts that are PROVABLY non-source-modifying (e.g., CI-yml edits, .swift-format config edits, README updates) do not require build verification — only the source-modifying class triggers this rule.


**Relationship to [CI-051]**: this rule is the mass-rollout-discipline extension specifically for source-modifying transforms. [CI-051] covers surgical-commit + dirty-skip discipline universally; [CI-056] adds the per-package build-verify gate for the source-modifying subclass.

**Cross-references**: [CI-051]; HANDOFF residual section of the per-repo-workflow-drift rollout (B6.5b R-chain provenance).

---

### [CI-111] Mass Mechanical Rewrite Scripts Preserve Pre-Existing Transformed Forms and Require Sample Diff-Inspection

**Statement**: Any script that mechanically rewrites or renames identifiers en masse (camelCase→backticked `@Test` names, symbol renames, sed/regex sweeps across ≥3 packages) MUST (1) SKIP or specially handle identifiers that already carry the target transform's output shape — pre-existing backticked names, already-renamed symbols — so they are NOT fed back through the transform and corrupted; AND (2) be validated by diff-inspecting a SAMPLE of the produced changes (at least one change per package) BEFORE the mass commit. The "N changes produced" success signal is insufficient: a re-transformed pre-existing form still satisfies the transform's post-condition (e.g. the name still contains a space, so the lint rule still passes) while silently destroying the original semantic content.

**How to apply**:

- The identifier-extraction regex MUST match ONLY bare transform targets (e.g. `[a-z][a-zA-Z0-9_]*` WITHOUT the alternation to already-backticked forms), OR the transform MUST short-circuit when its input already satisfies the post-condition — detect via `name.startswith('`')` (or test the match against the raw source text, not the transformed form).
- Surface a sample of the diff to the user BEFORE committing a mass-rename across multiple packages. Even one sample per package would have caught the origin incident. The "lint passes, therefore correct" inference is invalid whenever the lint post-condition is coarser than the transform's intent — build-green and lint-green do not prove the rewrite preserved semantic content.


**Cross-references**: [CI-050], [CI-051], [CI-056].

---

### [CI-113] Toolchain-Floor Bumps Verify Every CI Execution Surface FIRST

**Statement**: Before any mass change that raises the fleet's toolchain floor — a `swift-tools-version` bump, a minimum-Swift bump, or any manifest change an older toolchain cannot load — the rollout plan MUST verify that EVERY CI execution surface can load the new floor, land the required workflow updates BEFORE or WITH the mass push, and canary ONE repo's full matrix before the fleet push fires.

**The execution surfaces to check** (each fails independently):

| Surface | What to verify |
|---|---|
| macOS + simulator legs | The `XCODE_VERSION` pin's bundled Swift ≥ the new floor ([CI-013]); the pinned `Xcode_<v>.app` exists on the runner image (actions/runner-images README) |
| Linux container legs | The `swift:<version>` tag on Docker Hub resolves to ≥ the new floor ([CI-012]) |
| Windows leg | `SwiftyLab/setup-swift` resolves a toolchain ≥ the new floor for the given `swift-version` input |
| SDK legs (Android / Embedded Wasm / Static) | The pinned SDK artifactbundles are built for ≥ the new floor |
| Docs / auxiliary containers | Any other container-pinned job (e.g. `swift-docs.yml`'s `swift:<version>`) |
| New workflow steps' tool deps | Minimal containers lack curl/python3/etc. ([CI-092]) — steps added near the bump must carry their own installs |

**Sequencing**: workflow-capability commits land FIRST (they are a single universal-reusable edit per [CI-091]'s matrix-evolution clause), then a one-repo canary run proves the matrix green, then the mass push. A mass push against an incapable matrix converts the whole fleet red at once and burns a full queue cycle on doomed runs.

**Rationale**: manifests are loaded by every leg before any code builds, so a floor the runner toolchain cannot load fails 100% of legs regardless of code correctness — the highest-blast-radius failure a mass push can produce, and the cheapest to prevent (a read of two pins and one canary run).


**Cross-references**: [CI-050] (per-action authorization), [CI-107] (pin discipline), [CI-011]–[CI-013] (the pins themselves), [CI-092] (minimal containers), [CI-091] (matrix evolution at the universal layer).

---
