# CI/CD — Caching Policy & Per-Package Configuration

Companion of the **ci-cd-workflows** skill (navigation hub: `SKILL.md`). Load when working on `.build/`/tool-binary caching, `restore-keys` policy, the centrally-managed `.gitignore` / gitignored `Package.resolved`, or per-package `.swift-format` / `.swiftlint.yml` autonomy. This file reads independently: it collects the caching-policy and per-package-config rules.

**Rules in this file**: [CI-040], [CI-041], [CI-042], [CI-043], [CI-044], [CI-116], [CI-055] (DEPRECATED), [CI-057]

---

## Caching Policy

### [CI-040] No `.build/` Cache, Permanent

**Statement**: CI workflows MUST NOT cache `.build/` directories via `actions/cache`. Single carve-out: L1 embedded job in swift-primitives wrapper, keyed exact-match with no `restore-keys`.

**Enforcement**: Mechanical — `validate-cache-policy.py` + `validate-cache-policy.yml` (pilot 14 of `/promote-rule` 2026-05-14). Single-repo multi-file integrity check. Carve-out detected by (file basename `swift-ci.yml` + job name `embedded` + no `restore-keys`). Tool-binary caches ([CI-044]) out of scope. Baseline 0/4 wrapper-host repos; self-firing ACTIVE. Discipline: `Audits/PROMOTE-CI-040-2026-05-14.md`. [VERIFICATION: WF validate-cache-policy.py]

**Cross-references**: [CI-041], [CI-042].

---

### [CI-041] `Package.resolved` Is Gitignored Ecosystem-Wide

**Statement**: `Package.resolved` is gitignored across every package — a permanent library convention (libraries don't pin consumer dep graphs).

**Enforcement**: Script — `swift-institute/Scripts/sync-gitignore.sh` line 47 carries the `Package.resolved` entry; propagates the canonical template across the ecosystem, overwriting per-repo edits at next sync. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-041]. [VERIFICATION: Script sync-gitignore.sh:47]

**Cross-references**: [CI-040], [CI-043]; `swift-institute/Scripts/sync-gitignore.sh:47`.

---

### [CI-042] No `restore-keys` Partial-Prefix Matching

**Statement**: `restore-keys:` MUST NOT appear on any `actions/cache@*` step (regardless of path). Cache hits MUST be exact-match-only.

**Enforcement**: Mechanical — `validate-cache-policy.py` + `validate-cache-policy.yml` (pilot 16 of `/promote-rule` 2026-05-14, extending pilot 14's script). Single-repo multi-file integrity check; no carve-out. Detects single-line and multi-line block-scalar forms; correctly skips `restore-keys` on non-`actions/cache` actions. Baseline 0/4 wrapper-host repos; self-firing ACTIVE (shared with [CI-040]). Discipline: `Audits/PROMOTE-CI-042-2026-05-14.md`. [VERIFICATION: WF validate-cache-policy.py]

**Cross-references**: [CI-040], [CI-041].

---

### [CI-043] `.gitignore` Is Centrally Managed

**Statement**: `.gitignore` files are propagated by `swift-institute/Scripts/sync-gitignore.sh`; per-repo edits don't persist past next sync.

**Enforcement**: Script — `swift-institute/Scripts/sync-gitignore.sh` overwrites each consumer's `.gitignore` with the canonical template. Discipline: `Audits/PROMOTE-ci-corpus-sweep-2026-05-14.md` § [CI-043]. [VERIFICATION: Script sync-gitignore.sh]

**Cross-references**: [CI-041]; **github-repository** [GH-REPO-070]–[GH-REPO-072].

---

### [CI-044] Tool-Binary Cache Permitted with Exact-Match-Only Key

**Statement**: Cache steps targeting versioned tool binaries (SwiftLint, lychee, yq, gh CLI, etc.) MAY use `actions/cache@vN` keyed exact-match-only on the tool's version env var (or equivalent immutable version string). The carve-out is distinct from the [CI-040] `.build/`-cache prohibition: tool binaries cache cleanly because their cache key is the version env var (immutable per release), not a Package.resolved-style branch-pinned-deps hash that the no-cache rule was designed around. `restore-keys:` partial-prefix fallback remains forbidden per [CI-042] regardless of artifact class.

**Reference precedent** (already-shipped):

```yaml
- name: Cache SwiftLint binary
  id: cache-swiftlint
  uses: actions/cache@v5
  with:
    path: /usr/local/bin/swiftlint
    key: ${{ runner.os }}-swiftlint-${{ env.SWIFTLINT_VERSION }}
```

(`swift-institute/.github/.github/workflows/swift-ci.yml`)

**Permitted under this rule**:

- SwiftLint binary cache (existing precedent)
- lychee binary cache, keyed on `LYCHEE_VERSION`
- yq binary cache, keyed on the version literal embedded in the install URL
- gh CLI install caching where the install pattern is otherwise duplicated across containers
- Any other versioned tool binary fetched via curl/apt-get in workflow steps

**Forbidden under this rule** (preserves [CI-040]/[CI-042] semantics):

- `.build/` caching outside the L1-embedded carve-out per [CI-040]
- Any `restore-keys:` partial-prefix fallback regardless of artifact class
- Cache keys derived from `hashFiles(...)` patterns where the hash space includes branch-pinned dep state

**Rationale**: The [CI-040] no-cache rationale is specific: SwiftPM's `.build/` cannot key on resolved-graph state because `Package.resolved` is gitignored ecosystem-wide. Tool binaries are a structurally distinct class — their cache key is a version env var (immutable per release). The SwiftLint precedent in `swift-ci.yml` already uses this shape; codifying it propagated the same pattern to yq (`read-orgs` composite) and lychee (`link-check.yml`), both now cached (formerly re-installed on every invocation). Cache hit at runtime cuts ~5–15s per call site per workflow run; per the cron-orchestrator matrix shape, the savings compound across orgs.


**Cross-references**: [CI-040], [CI-042], [CI-107] (version env vars are the immutable key the cache leverages); SwiftLint precedent at swift-institute/.github/.github/workflows/swift-ci.yml.

---

### [CI-116] Prebuilt Linter Binaries via Rolling Release, Not Per-Repo Cache Bakes

**Statement** (approved 2026-07-20): binaries that track `main` of an actively-developed tool (the swift-linter dispatcher + standard runner) are distributed via a rolling, NON-SEMVER, prerelease-marked GitHub release (`ci-binaries` on swift-foundations/swift-linter) built ONCE by that repo's `publish-ci-binaries.yml`, and downloaded + `sha256sum -c`-verified by consumer CI. They MUST NOT be distributed via per-consumer `actions/cache` bakes.

**Why the cache shape failed** (measured 2026-07-20): `actions/cache` is REPOSITORY-scoped. A composite-keyed "shared" bake is not shared — every one of ~450 consumer repos pays its own ~310–560s rebuild after any keyed-repo commit, which during active rule-pack development is constant (18 of 28 sampled runs cold, 393–1450s; median swift-linter job 502s). Additionally, `--exit-policy strict` force-routed to the eval path until the exit-policy channel landed (swift-linter `0f61c4e`), so the baked runner went unused in CI entirely. Post-fix: swift-linter job ~60–77s all-in, lint tier ~97s wall-clock.

**Shape invariants**:

- The `ci-binaries` tag is created ONCE and never moved (no force-push); assets are replaced in place (`gh release upload --clobber`). Non-semver → invisible to SwiftPM version resolution and SPI, so this is NOT a package release and needs no release approval cascade. Build provenance (engine + rule-pack HEAD SHAs, image, digest) lives in the uploaded `MANIFEST.txt`, not the tag.
- Binaries are built inside the SAME container image the consumer job runs in (`swift:6.3`; bump in lockstep with the universal's `swift-version` default).
- Consumer verification is `sha256sum -c` against the release's `SHA256SUMS` ([CI-082]-class; the trust anchor is GitHub TLS + release write-control, the same anchor the previous `git ls-remote` + `@main` checkout relied on). On ANY download/verify failure the consumer job falls back to the legacy source build — never red on a missing release.
- Freshness (instant-republish, 2026-07-20): push-to-main republishes, and a push to any of the five rule-pack repos (`swift-primitives-linter-rules`, `swift-linter-primitives`, `swift-standards-linter-rules`, `swift-institute-linter-rules`, `swift-linter-rules`) dispatches `publish-ci-binaries.yml` within ~1 min via the shared `notify-linter-republish.yml` reusable in swift-institute/.github — each rule-pack `ci.yml` calls it on push to main with explicit App-secret forwarding per [CI-109]; it mints a swift-institute-bot App token downscoped to `actions:write` on swift-foundations/swift-linter only (no PAT, no new standing credential). A 6-hourly cron remains as a safety net for missed dispatches, recomputing the engine+rule-pack composite digest and rebuilding only on movement; the digest gate also makes duplicate/racing dispatches no-ops. `Package.resolved` stays gitignored per [CI-041]; the MANIFEST is the provenance record.

**Cross-references**: [CI-040] (not a `.build` cache), [CI-042] (no restore-keys anywhere), [CI-044] (the cache carve-out this supersedes for main-tracking binaries; version-pinned tools like SwiftLint stay on [CI-044] caches), [CI-082] (checksum discipline), [CI-115] (the lint tier this makes fast). Implementation: swift-foundations/swift-linter `.github/workflows/publish-ci-binaries.yml`; consumer side in the universal `swift-ci.yml` swift-linter job ("Download prebuilt linter binaries" step).

---

## Per-Package Configuration

### [CI-055] ~~`UseShorthandTypeNames: false` Is Ecosystem-Mandatory~~ — DEPRECATED 2026-05-14

**Status**: **DEPRECATED** per pilot 26 of `/promote-rule` (2026-05-14). Empirically dismissed: consumers ALWAYS access shadowing types via the qualified-namespace form (`Array_Primitives.Array<T>`); swift-format's shorthand rewrite only touches *unqualified* `Array<T>`, which would refer to `Swift.Array` anyway. The "structural protection" rationale that motivated this rule does not materialize in practice — `swift-format` cannot rewrite a qualified namespace reference back to `[T]` shorthand, and unqualified `Array<T>` in shadowing-package source code never points to the package's own shadowing type (which always requires qualified access).

**Evidence**: Tier-A.5 canonical-sync commit `3d5b5ce` flipped `UseShorthandTypeNames: true` ecosystem-wide AFTER the original `365c69d` "set false" rollout, with no observable build failures on shadowing packages (`swift-array-primitives`, `swift-dictionary-primitives`). Current state: 296/298 consumers have `: true`; 2 (`swift-affine-primitives`, `swift-standard-library-extensions`) retain `: false` for unrelated reasons. Discipline: `Audits/PROMOTE-CI-055-2026-05-14.md` (REMOVE disposition).

**No enforcement**: deprecated rules are not mechanized. The pre-deprecation rule body is preserved in the outcome record for historical lineage. `.swift-format` configuration is per-package autonomy per [CI-057].

**Cross-references**: [CI-057]; `Audits/PROMOTE-CI-055-2026-05-14.md`.

---

### [CI-057] `.swift-format` and `.swiftlint.yml` Are Per-Package

**Statement**: Each consumer's `.swift-format` and `.swiftlint.yml` configuration files MUST be per-package. Ecosystem-wide uniformity of these files is NOT a goal; per-package customization (additional disabled rules, alternative `lineLength` / `tabWidth`, parent_config inheritance, etc.) is supported and expected. There are no current ecosystem-mandatory `.swift-format` rules (the prior [CI-055] `UseShorthandTypeNames: false` exception was deprecated 2026-05-14 per pilot 26 of `/promote-rule` — qualified-namespace access pattern empirically dismissed the structural concern). Package authors decide.

**Counterexample to [CI-043]**: unlike `.gitignore` (which IS centrally managed), `.swift-format` and `.swiftlint.yml` are deliberately per-package. The asymmetry is intentional:
- `.gitignore` is structural infrastructure (what NOT to track) — uniformity prevents drift in `Package.resolved` handling and similar invariants.
- `.swift-format` / `.swiftlint.yml` are stylistic preference (what code SHOULD look like) — packages with different domains (math, parsing, IO) have legitimately different formatting needs.

**Examples of legitimate per-package customization**:
- Math packages (`swift-cpu-primitives`, `swift-complex-primitives`, `swift-decimal-primitives`, etc.) carry additional `disabled_rules` in `.swiftlint.yml` for `identifier_name`, `line_length`, `nesting`, etc. — math notation often requires single-letter identifiers (`x`, `θ`, `r`) and nested expressions.
- `swift-base62-primitives` carries a different `.swift-format` (`lineLength: 120` vs canonical `200`, `tabWidth: 8`, `AlwaysUseLowerCamelCase: true`) — preserved as legitimate per-package customization.

**Permitted operations on these files**:
- Per-package edits by the package author (no ecosystem-wide approval needed).
- Cosmetic backfill from a sibling when missing (per the established backfill pattern; preserves rather than imposes).
- Header-comment cleanup (e.g., aligning stale `# SwiftLint configuration for swift-X-primitives` to canonical `# SwiftLint configuration`).

**Forbidden operations**:
- Sync-script propagation that overwrites per-package customization with a central template.
- Ecosystem-wide rule changes claimed as "structurally necessary" without empirical verification (the deprecated [CI-055] was an instance of this failure mode).


**Cross-references**: [CI-043] (counterexample — `.gitignore` IS centrally managed); historical deprecation: [CI-055] (deprecated 2026-05-14).

---

