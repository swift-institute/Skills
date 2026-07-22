---
name: swift-forums-review
description: |
  Simulate a forums.swift.org review thread for an Institute package, or predict hardest critique angles. Grounded in ~900 real threads.
  Apply when preparing a Forums announcement, pressure-testing APIs, or auditing launch-readiness.

layer: process

requires:
  - swift-institute-core
  - swift-institute

applies_to:
  - swift-primitives
  - swift-standards
  - swift-foundations
  - swift-components
  - package-launch
  - pitch-preparation
---

# Swift Forums Review Simulator

Two modes grounded in a corpus of real forums.swift.org review activity:

1. **Simulate a thread** — given a package, produce a markdown thread (OP + replies) with
   statistically-derived reviewer personas responding from different angles.
2. **Predict objections** — given a package, rank which critique angles are most likely
   to land hard in real community review.

Corpus location (public repo): `swift-institute/Engagement/swift-forums-review-corpus/`.
Analysis artifacts the skill consumes live at `…/analysis/`:

| File | Purpose |
|------|---------|
| `archetypes_labeled.json` | **Canonical archetype list** — hand-reviewed labels + usage guidance over the raw clusters. Prefer this over `archetypes.json` for persona selection. |
| `archetypes.json` | Raw k-means clusters (top TF-IDF terms, angle means, feature means, 5 sample excerpts each) |
| `critique_angles.json` | 17 critique angles with observed frequency (% of substantive posts) and thread coverage |
| `openers_closers.json` | Observed opening/closing post patterns |
| `corpus_stats.json` | Dataset metadata |
| `substantive_posts.jsonl` | Per-post feature-annotated records for grounding simulations |
| `analysis.md` | Human-readable synthesis of the corpus — what the numbers mean, how to use them |

---

### [FREVIEW-001] Corpus-grounding

**Statement**: Both modes MUST read `analysis/*.json` before generating output. The skill MUST NOT fabricate archetypes, critique-angle frequencies, or opener/closer patterns from memory.

**Rationale**: "Statistically derived" is load-bearing — the whole point is that simulated reviewers
resemble real forum reviewers, not our imagination of them. Every archetype, every angle weight,
and every opener variant must trace back to the corpus.

**How to apply**: At simulation start, open all four analysis files. If any are missing, run
`.venv/bin/python scripts/analyze.py` first. If the corpus itself is missing, run `ingest.py`.

---

### [FREVIEW-002] Package characterization is the first step

**Statement**: Before simulating or predicting, the skill MUST run
`scripts/characterize_package.py <package-path>` and use its output to weight critique angles
and select archetypes.

**How to apply**: The characterizer returns `predicted_angle_weights` — multipliers per angle.
Combine with `critique_angles.json` frequencies to rank which angles this package will attract:

```
angle_score[a] = corpus_freq_pct[a] × package_weight[a]
```

Highest-scoring angles drive which archetypes appear in the simulated thread and which
objections lead the "predict" output.

---

### [FREVIEW-003] Archetype selection rules

**Statement**: A simulated thread MUST include between 6 and 12 distinct archetypes as
responders. Archetype selection MUST be weighted by (a) archetype size in the corpus and
(b) whether the archetype's dominant angles overlap the package's predicted angle scores.

**Rationale**: A thread that's all "ownership pedants" or all "+1 template replies" doesn't
resemble a real review. Real threads mix the process-mechanics voices, the deep-technical
voices, the brief-nit voices, and the prior-art voices.

**How to apply**: Rank archetypes by
`size_pct × max(angle_mean[a] × package_angle_score[a] for a in angles)`.
Always include at least one "process/procedure" archetype and one "short +1/nit" archetype
for realism.

---

### [FREVIEW-004] Per-post grounding

**Statement**: Each simulated post MUST carry metadata linking back to the archetype it draws
from and MUST use vocabulary overlapping the archetype's top terms. Post length MUST fall
within `[0.5×, 2×]` of the archetype's mean `word_count`.

**How to apply**: In the JSON sidecar, emit per post:
```json
{
  "post_number": 3,
  "persona_archetype_cluster": 6,
  "persona_archetype_label": "The ownership-and-memory reviewer",
  "dominant_angles": ["ownership-memory", "type-system"],
  "opener_pattern": "quote-first",
  "closer_pattern": "recommendation",
  "body_markdown": "..."
}
```

In the markdown output, render each post as Discourse-style:
```
### Post N — <@persona-handle>

<markdown body>
```
with a trailing `<!-- archetype: <label> — angles: <ids> -->` HTML comment so the mapping is
recoverable but doesn't clutter the rendered thread.

---

### [FREVIEW-005] Opener / closer diversity

**Statement**: Across the simulated thread, openers and closers MUST be drawn with frequencies
approximately matching `openers_closers.json`. The skill MUST NOT reuse the same opener or
closer pattern for more than ~30% of posts.

**Rationale**: Every post starting with "I'd suggest" or ending with "just my 2 cents" is an
immediate tell that the thread is synthetic.

---

### [FREVIEW-006] No generic reviewer text

**Statement**: Posts MUST reference at least one concrete feature of the target package —
an actual type name, actual method, actual file path, actual Package.swift declaration.
Generic statements like "I have concerns about the naming" without a pointer are forbidden.

**Why**: Real reviewers quote. They cite `Foo.bar` at `Sources/X/Bar.swift:42`. A simulated
reviewer who generalises is a simulated reviewer who reveals they haven't read the code.

**How to apply**: Before writing each post, read at least one Swift file from the package's
sources and pick a concrete identifier to anchor the post on.

---

### [FREVIEW-007] Simulate-mode output contract

**Statement**: The simulate mode MUST write two files:

| Path | Format |
|------|--------|
| `<package>/Audits/forums-review/forums-review-simulation-<YYYY-MM-DD>.md` | Markdown thread |
| `<package>/Audits/forums-review/forums-review-simulation-<YYYY-MM-DD>.json` | Structured sidecar |

Markdown MUST start with a YAML frontmatter block containing: `package`, `path`,
`simulated_date`, `predicted_category` (community-showcase or related-projects), `archetypes`
(list of labels used).

JSON schema:
```json
{
  "package": "...",
  "path": "...",
  "simulated_date": "YYYY-MM-DD",
  "predicted_category": "community-showcase",
  "characterization": { ... output of characterize_package.py ... },
  "angle_ranking": [ {"angle_id": "...", "score": 48.0, ...}, ... ],
  "archetypes_used": [ {"cluster_id": 6, "label": "...", "posts": [3, 7, 11]}, ... ],
  "posts": [ ... FREVIEW-004 shape ... ]
}
```

---

### [FREVIEW-008] Predict-mode output contract

**Statement**: The predict mode MUST write:

| Path | Format |
|------|--------|
| `<package>/Audits/forums-review/forums-review-objections-<YYYY-MM-DD>.md` | Human-readable ranked objections |
| `<package>/Audits/forums-review/forums-review-objections-<YYYY-MM-DD>.json` | Structured sidecar |

The markdown MUST contain, per top-5 angle:
- The angle label and score.
- What about the package triggered the weight multiplier (cite specific source-file evidence).
- 1–2 predicted opening sentences grounded in the archetype that most commonly pushes this angle.
- Suggested pre-emptive mitigation (code change, docs addition, or scope narrowing).

---

### [FREVIEW-009] Venue prediction

**Statement**: The skill MUST infer the most-likely forum category the package would be
announced in and adapt archetype selection accordingly.

| Package layer / nature | Likely category | Archetype mix |
|------------------------|-----------------|---------------|
| Primitives / Standards (Apache-2.0, infra) | `related-projects` (new sub) or `community-showcase` | Heavier on process/layering/naming; fewer "-1" votes (not a proposal) |
| Foundations (infra composed) | `community-showcase` | Ergonomics + precedent + naming |
| Components / Applications | `community-showcase` | Use-case / ergonomics / docs |
| Anything posed as evolution-adjacent | Evolution `discuss` | Full Evolution archetype mix including review-template replies |

---

### [FREVIEW-010] Do not post simulations

**Statement**: Simulated threads are INTERNAL artifacts. The skill MUST NOT suggest posting
any simulated content to forums.swift.org, Bluesky, Discord, or anywhere else. Treat simulated
posts as draft-only.

**Why**: This crosses into engagement territory, which is test-only in this workspace. Also,
fabricated forum posts attributed to real-feeling handles are a misrepresentation risk.

**How to apply**: Handles in simulated threads MUST use the format `@reviewer-<cluster-id>` or
similar non-identifying tags. Never reuse the username strings from `archetypes.json` samples.

---

## Running the skill

```bash
# One-time setup (already done for the corpus repo):
cd /Users/coen/Developer/swift-institute/Engagement/swift-forums-review-corpus
python3 -m venv .venv && .venv/bin/pip install numpy scikit-learn beautifulsoup4
.venv/bin/python scripts/ingest.py --category evolution/proposal-reviews --id 21 --all
.venv/bin/python scripts/ingest.py --category evolution/pitches --id 5 --max-topics 400 --min-posts 5
.venv/bin/python scripts/ingest.py --category community-showcase --id 66 --max-topics 150 --min-posts 3
.venv/bin/python scripts/ingest.py --category related-projects --id 25 --max-topics 120
.venv/bin/python scripts/analyze.py

# Per-package use:
.venv/bin/python scripts/characterize_package.py /Users/coen/Developer/swift-primitives/swift-algebra-group-primitives
```

The skill itself is invoked by the agent: given a package path, follow rules
[FREVIEW-001]–[FREVIEW-010] to produce the simulation and/or objection-prediction artifacts
under the target package's `Audits/forums-review/` directory.

**Why `Audits/` and not `Research/`**: forums-review artifacts are pre-launch
internal readiness exercises — synthetic personas predicting objections, with
mitigation talking points. `Research/` is the consumer/contributor-facing
surface (durable design rationale per `[RES-*]` / `[DOC-101]`); it gets
indexed and rendered. Forums-review content is time-bound (a launch window),
synthetic (predicted critiques, not findings), and bad public-optics
(reads as "we knew this would land hard and prepared spin"). `Audits/` is
gitignored ecosystem-wide, semantically captures internal
verification artifacts, and survives across sessions for the supervisor /
pre-tag check to re-read. Subdirectory `forums-review/` keeps related
artifacts grouped without colliding with `Audits/audit.md`.

---

---

### [FREVIEW-011] Refresh atomicity

**Statement**: When the corpus re-ingests or archetype labels change, a simulation refresh
MUST regenerate the full artifact — post bodies, HTML comments with archetype metadata,
JSON `cluster_id` fields, and every prose reference to corpus state. Metadata-only refreshes
are forbidden.

**Why**: In the 2026-04-24 carrier-primitives pass, the YAML front-matter was updated to
"corpus_state: full" while the `<!-- archetype: cluster 6 -->` inline comments and the JSON
sidecar's `cluster_id` fields were left pointing at the pre-canonical clusters. The file
*claimed* refreshed and *was* partially stale — worst of both.

**How to apply**: Either fully re-render the simulation (preferred for substantive refreshes)
or write a `superseded_by:` front-matter field pointing to a newer artifact and do not edit
the body. Touching metadata without touching body is a bug.

---

### [FREVIEW-012] Archetype-vs-substance triage

**Statement**: After generating a simulated thread, the skill MUST produce a triage file
classifying each surfaced critique into one of three buckets:

| Bucket | Meaning | Disposition |
|--------|---------|-------------|
| `load-bearing` | Identifies a genuine property of the package that would change a design or docs decision | Act on |
| `partially-load-bearing` | Raises a real question answered cheaply by a sentence-scale write-up | Answer cheaply |
| `archetype-shaped-noise` | Reads as a thing this archetype always says, not grounded in the package's specifics | Discount |

**Heuristic for automated pre-classification** (the `concreteness-anchor count` per post):

- Count per post: file-path mentions (`Sources/…\.swift`), file-line refs (`…\.swift:\d+`),
  backticked identifiers with internal CamelCase, explicit type/function keywords adjacent to
  quoted names, named cross-references (SE-XXXX, SP-XXXX, ST-XXXX).
- Pre-classify: `anchors >= 3` → candidate for load-bearing; `anchors == 0–1` → candidate for
  archetype-shaped; `anchors == 2` → partially.
- Manual escape hatch: a post with low concreteness-anchor count MAY be load-bearing if it
  surfaces a genuine semantic property of the package. The agent MUST flag any such "escape"
  classification in the triage file with an explanation.

**Why**: Archetypes have predictable output (c5 always produces "-1", c2 always asks about
SemVer, c0b always asks "where's the generic consumer?"). Without a triage pass, the skill's
user cannot distinguish "this is what this cluster says to every package" from "this is a
real concern about YOUR package." The triage IS the filter that makes simulated threads
actionable.

**Output**: `<package>/Audits/forums-review/forums-review-triage-<YYYY-MM-DD>.md` with one row per
non-OP post: post number, archetype label, concreteness-anchor count, pre-classification,
final classification (may differ from pre-classification with explanation), and one-sentence
disposition recommendation.

---

### [FREVIEW-013] Venue-angle deflation

**Statement**: Base angle frequencies in `critique_angles.json` are aggregated across ALL
corpus venues. The proposal-reviews venue dominates the corpus (78%) and injects the Evolution
review template vocabulary, inflating `evolution-process` (56.2%) and related process-angle
figures for any non-Evolution target venue. The skill MUST load per-venue stratified base
rates from `critique_angles_by_venue.json` when the target venue is not `evolution-*`.

**Mapping** (target venue → corpus categories to aggregate for base rates):

| Target venue | Base rates drawn from |
|---|---|
| `evolution-pitches`, `evolution-discuss`, `evolution-reviews` | proposal-reviews + pitches |
| `related-projects` | related-projects + community-showcase |
| `community-showcase` | community-showcase + related-projects |

**How to apply**: `prepare_simulation.py` picks the target venue via `predict_venue()` and
loads the matching stratified base rates. The global `critique_angles.json` is a fallback if
the stratified file is unavailable.

**Why**: In the 2026-04-24 pass, the pre-deflation ranking put `evolution-process` at #1 with
score 56.2, which is wrong for a `related-projects` target — nobody announcing a package in
`related-projects` is going to face "what's your evolution-acceptance rationale?" as the top
critique, because that's not what that venue does.

---

### [FREVIEW-014] Terminal-posture detection

**Statement**: The characterizer MUST parse the target package's `README.md` and `CHANGELOG.md`
(if present) for terminal-posture framings. When detected, it MUST set
`terminal_posture=true` in its output and down-weight the `evolution-process` and
`abi-source-stability` angle multipliers to 0.5× (half the baseline).

**Detected framings** (case-insensitive):
- `terminal <version>`, `<version> is the final shape`, `<version> is terminal`
- `shape committed`, `FINAL`, `no further protocol shape changes planned`
- `1.0 committed` (on a 0.x package), `feature-complete`

**Why**: Archetype c6 (Core-Team-aware process voice) and c2 (SwiftPM/modularity) both
produce SemVer-shaped critiques that presume the package will grow new requirements. That
presumption is wrong for a package whose author has committed to a terminal shape. Adopting
c2's frame on a terminal-posture package is the failure mode identified in the 2026-04-24
carrier-primitives review.

---

### [FREVIEW-015] Temporal correction via era multiplier (implemented)

**Statement**: When the target package shows Swift-6-era signals (`~Copyable` types,
`borrowing`/`consuming` parameters, `actor` declarations, or typed throws), the skill MUST
apply a per-angle era multiplier to venue-stratified base rates. The multiplier is
`post_2024_rate / pooled_rate` per angle, computed from `critique_angles_by_era.json`.

**How to apply**: `prepare_simulation.py` auto-detects the era via `infer_era()` from the
characterizer output; `--era` flag overrides. Effective base rate per angle becomes
`venue_base_pct × era_multiplier`. The skill preserves venue stratification as primary;
era correction is a multiplicative adjustment on top, not a replacement.

**Why**: Applying to carrier-primitives: ownership-memory base rate is 11.6% pooled but
20.3% effective after the swift-6-era × 1.75 multiplier — pushing it from tied-for-8th to
2nd place. Evolution-process gets a 0.82× multiplier and deflates. The era correction
reflects that modern infra packages face 2024-era critique, not 2018-era critique.

---

### [FREVIEW-016] Post-authoring triage is mandatory

**Statement**: After authoring a simulated thread, the skill MUST produce a triage artifact
via `scripts/triage_simulation.py <simulation.md>`. The automated pre-classification is the
skill's output; human-review final classification is the consumer's responsibility.

**Why**: Without a triage pass, the consumer cannot distinguish load-bearing critiques from
archetype-shaped ones, and will act on all of them (or none) rather than the 30-50% that
matter. The triage is the filter that makes simulated threads actionable.

**Output contract**: one triage markdown + one triage JSON beside the simulation file. Each
reviewer post gets an anchor count, pre-classification, and `_pending` fields for the human
reviewer's final-classification and disposition decisions.

---

### [FREVIEW-018] Anchor correctness verification (consumer-side)

**Statement**: The `[FREVIEW-012]` triage pre-classification measures *checkability*, not *correctness*. High anchor counts signal that a post's claims can be verified against source; they do not signal that the claims are true. The skill's consumer MUST source-verify every anchor-grounded factual claim in a load-bearing-classified post before acting on it.

**Why**: Archetype-sampled simulations produce anchor-dense posts whose anchors are real (taken from the package's actual source) but whose surrounding claims may still be wrong — a reviewer can correctly cite `Foo.swift:42` while drawing a false conclusion about what's at that line, whether the surrounding `#if` chain makes it platform-restricted, how many sibling sites exist in Sources/ vs Tests/, or whether a count includes conformances, generic constraints, or doc mentions. Anchors make claims *checkable*; they do not make claims *true*. The triage's classification axis catches archetype-shaped noise but is structurally unable to catch anchor-grounded falsehood — a separate source-verification pass is required.

**How to apply** (consumer-side):

For every post pre-classified as load-bearing (or escape-hatched to load-bearing), the consumer MUST verify each anchor-grounded factual claim:

| Claim form | Verification |
|---|---|
| "X is at `file:L`" | Open the file, check the line — does X exist there with the claimed shape? |
| "N sites of Y in source" | Run the grep yourself; scope (Sources/ vs Tests/) matters; don't trust the number without running the command |
| "X is gated to platform Y" | Read the full `#if` chain, including `#elseif` branches — partial reading produces false portability claims |
| "X has semantic property Z" | Read the code; docstrings can lie; the source is ground truth |

If verification fails, the disposition for that post's claim becomes `false-premise`. The triage JSON should record this so calibration (`[FREVIEW-017]`) can track per-angle false-claim rates alongside per-angle hit rates.

**Relationship to `[FREVIEW-012]`**: orthogonal axis. The triage classifies critiques as load-bearing / partially / archetype-shaped; `[FREVIEW-018]` classifies claims as correct / false / unverifiable. A post may be load-bearing-classified with correct claims (act on it), load-bearing-classified with false claims (archive with `false-premise` disposition), archetype-shaped with correct claims (rare — a stereotyped reviewer happened to be right; still consider), or archetype-shaped with false claims (discount by both axes).

**Output contract**: the triage markdown's `disposition` column SHOULD record anchor-verification outcomes. A disposition like "act-on: X (verified)" vs "act-on but claim-X-false-premise; archive" vs "claim-verified-correct but archetype-shaped; discount" captures both axes.

---

### [FREVIEW-017] Weight Calibration Against Observed Reception — PENDING (placeholder; not operational)

> ⚠ **STATUS — PENDING DATA**: this rule is a forward-looking placeholder. No calibration has run; no observed-reception records exist on disk. Consumers MUST NOT attempt to follow this rule until the corpus produces ≥5 observed-reception records per the threshold below. The rule is documented here so that calibration methodology is discoverable when records accumulate; current usage of `swift-forums-review` proceeds with the hand-estimated weights cited under "Why".

**Statement** (forward-looking, not yet active): When the ecosystem produces observed-reception records (real package launches
with real forum threads), the skill SHOULD be periodically calibrated: fit per-angle weight
multipliers against observed angle frequencies and update `characterize_package.py` coefficients.

**How to apply**: Methodology in `analysis/calibration/CALIBRATION.md`. Record schema in
`observed_reception_schema.json`. Fit stub in `analysis/calibration/calibrate_weights.py`.
Threshold for first pass: ≥ 5 records. Threshold for trusted weights: ≥ 15 records.

**Why**: Current weights (e.g. `× 2.0 for ownership-memory when noncopyable_types > 0`) are
hand-estimates. Calibration converts them to measurements. The skill ships uncalibrated —
which is honest about the epistemic state, and improvable.

**Status (2026-04-24)**: No records on disk; no calibration has run. Track as a standing
refresh item alongside the corpus refresh cadence.

---

### [FREVIEW-019] Re-Simulation Cadence After Substantial Recent Changes

**Statement**: When a package about to ship a major-version tag has accumulated **substantial recent changes** since its last forums-review simulation — README rewrite, source restructure, dependency-graph change, workflow trim, vision consolidation, or test-suite naming sweep — a re-simulation MUST be run before the tag. The re-simulation covers the same archetypes against the current state and is compared to the prior simulation; flag (a) any prior load-bearing critique that is NOT yet resolved in current state (open risk for tag), and (b) any new critique that did not appear in the prior run (introduced by recent changes).

**Procedure**:

1. Re-invoke the skill against the current package state with the same archetype roster used in the prior run.
2. Output goes to `<package>/Audits/forums-review/forums-review-{simulation,objections,triage}-{DATE}.md` per the post-2026-04-29 output convention.
3. Diff the new triage against the prior triage. Carry forward any persistently-load-bearing critique into the release-readiness brief's findings.
4. New objections that did not appear in the prior run are post-change-introduced — investigate before tag.

**When NOT to re-simulate**: if no substantial change set has landed since the last simulation, the prior simulation remains current and re-simulation adds no signal. The threshold is qualitative — substantial means a change a reviewer would notice on cold read of the package, not a cosmetic edit.

**Caller context**: when used as Phase 4 of the release-readiness skill's final pre-release scan ([RELEASE-002]), the re-simulation is mandatory. The **release-readiness** skill is the canonical caller of this rule.

**Worked example (the origin incident)**: `swift-carrier-primitives` 0.1.0 release arc ran a forums-review simulation 2026-04-24 (before substantial recent changes including Vision consolidation, README cleanup, forums-review relocation, centralized workflow trim, lint fix, and test-suite naming sweep) and a re-simulation 2026-04-29 (after those changes). The two-simulation pattern caught critique angles introduced by the README rewrite that the original simulation did not surface, and confirmed that prior load-bearing critiques from the 2026-04-24 run had been resolved by the intervening changes.


**Cross-references**: [FREVIEW-007], [FREVIEW-008], [FREVIEW-011], [FREVIEW-012], [FREVIEW-020], [RELEASE-002], **release-readiness** skill.

---

### [FREVIEW-020] Delta Re-Simulation Mode for Low-Change Windows

**Statement**: For low-change windows between simulations (small commit count + minimal LOC / public-decl-count delta since the prior simulation), [FREVIEW-019]'s full re-simulation is unnecessary overhead. A *delta re-simulation mode* re-scores the prior simulation's top angles against current state, then evaluates new probes introduced by commits-since-prior-sim under an "amplification" axis distinct from "score." Mode applies when (a) prior simulation exists at `Audits/forums-review/`, (b) <10 commits since prior sim, AND (c) no LOC / public-decl-count change >10%.

**Output shape**: a single delta-validation section appended to `Audits/audit.md` rather than new sim/objections/triage files. Captures most of the value at ~10% of the cost of full re-simulation; keeps the full skill invocation available for substantial-change windows.

**Procedure**:

1. **Trigger check**: verify (a) prior simulation exists, (b) commit count since prior sim < 10, (c) LOC / public-decl-count delta < 10%. If all three hold, use delta mode; otherwise fall through to [FREVIEW-019].
2. **Prior-angle re-score**: for each top angle from prior simulation, evaluate whether evidence still applies under current state. Output: `RETAINED`, `RESOLVED-by-{commit}`, `WEAKENED`, or `STRENGTHENED`.
3. **New-probe amplification**: for each commit-since-prior-sim, identify whether it amplifies an existing angle, introduces a new probe, or is review-irrelevant.
4. **Amplification scoring**: score only new probes against the prior corpus's archetype calibration; do not re-score every angle from scratch.
5. **Output**: a single `## Forums-review delta re-simulation — {DATE}` section in the package's `Audits/audit.md`.

**Why "amplification" is a separate axis**: a commit that introduces a public-API decision relevant to a Mid-tier critique angle doesn't necessarily change the angle's score — it amplifies the angle's anchor coverage. Mixing amplification into score conflates "more anchors" with "stronger reception likelihood"; keeping them separate preserves the score-vs-substance distinction documented in `swift-institute/Engagement/swift-forums-review-corpus/analysis/calibration/score-vs-substance-divergence-2026-04-25.md`.

**Worked example (the origin incident)**:

The 2026-04-30 ownership-primitives final pre-release scan Phase 4 ran delta mode against the 2026-04-24 simulation. Trigger conditions held (4 commits since 2026-04-24; ~50 LOC delta; no public-decl-count change). The delta-validation section in `Audits/audit.md` re-scored prior top-3 angles (all RETAINED), identified 1 new probe (the `@inlinable`-removal Borrow refactor) under amplification, and concluded with go/no-go recommendation. Full [FREVIEW-019] re-simulation would have produced ~3 new files for substantively the same outcome.

**When NOT to use delta mode**:

- Substantial-change windows (≥10 commits, or >10% LOC change, or any public-API restructure) — use [FREVIEW-019] full re-simulation.
- Major-version bump windows (v1.0 → v2.0) — full re-simulation required regardless of change count.
- Pre-launch (initial release) — no prior simulation to delta against.


**Cross-references**: [FREVIEW-007], [FREVIEW-008], [FREVIEW-011], [FREVIEW-019], [RELEASE-002]

---

### [FREVIEW-021] Post-Triage Critical Re-Assessment of Surviving Critiques

**Statement**: After [FREVIEW-018] anchor verification surfaces critiques as load-bearing-with-correct-claims, the consumer MUST run a post-triage critical re-assessment pass before applying any prescribed fix. Anchor correctness is necessary but not sufficient for prescription correctness — a critique can cite a correct anchor with a correct surrounding claim and still propose a fix that conflicts with the type's stated purpose, with existing-ecosystem namespaces, or with the package's API consistency rules. The re-assessment classifies each surviving prescription as `apply`, `apply-with-modification`, or `discard-as-anchor-correct-prescription-wrong`.

**Procedure** (consumer-side, after [FREVIEW-018] anchor verification):

For each load-bearing-with-correct-claims critique, ask three questions in order:

| Question | Failure shape | Action on failure |
|---|---|---|
| Does the prescribed fix translate cleanly to the type's stated purpose? | Adding `Sendable where Value: Sendable` to a type whose existence is to-be-Sendable when Value is not (e.g., `Mutable.Unchecked`) | discard-as-anchor-correct-prescription-wrong |
| Does the prescribed fix conflict with existing-ecosystem namespaces? | Proposed package split into `swift-storage-primitives` when that name is already taken | discard-as-anchor-correct-prescription-wrong |
| Does the prescribed fix introduce new API consistency problems? | Rename split that breaks generic-over-Copyable-status code; renaming half the Borrow API on a type whose Copyable variant must keep the original name for source-compat | apply-with-modification (narrow to a sub-prescription) |

A critique that fails any of the three questions is `discard-as-anchor-correct-prescription-wrong`. The consumer MUST capture the discard rationale in the triage's `disposition` column so subsequent calibration ([FREVIEW-017]) can track per-angle prescription-correctness rates alongside per-angle anchor-correctness rates.

**Why this is a separate pass**: [FREVIEW-018] verifies that a claim about source state is true. A critique can have a true claim and still prescribe a fix the package's authors would never accept because the fix conflicts with the type's purpose, the ecosystem's namespace topology, or the API's existing consistency contract. The two axes are orthogonal — anchor-correct-but-prescription-wrong is a real category that the surface signals (load-bearing classification + anchor verification) cannot catch on their own. User pushback or against-existing-ecosystem fact-checks have historically been the corrective signal; codifying the re-assessment pass converts that ad-hoc intervention into a procedure.

**Worked example** (canonical 2026-05-01 origin incident): The 2026-05-01 ownership-primitives forums-review re-simulation produced 11 surviving critiques after [FREVIEW-018] anchor verification. User pushback during application surfaced three distinct failure shapes:

- "Add `Sendable where Value: Sendable` conformance to `Ownership.Mutable.Unchecked`" — anchor correct, prescription conflicts with the type's purpose (Unchecked exists specifically to be Sendable when Value is not).
- "Split into `swift-storage-primitives` cohort" — anchor correct, prescription conflicts with the existing ecosystem (swift-storage-primitives is already a different package).
- "Rename half the Borrow API for naming consistency" — anchor correct, prescription introduces source-compat break across generic-over-Copyable-status code.

Without the re-assessment pass, all three would have applied. With the pass, 6 of 11 critiques downgraded to `discard-as-anchor-correct-prescription-wrong` after re-assessment.

**Composite:** anchor verification (mechanical, [FREVIEW-018]) + prescription-correctness assessment per question (semantic) + disposition recording (mechanical).


**Cross-references**: [FREVIEW-012], [FREVIEW-016], [FREVIEW-018], [RELEASE-002].

---

## Refresh cadence

The corpus is a snapshot; review culture evolves. Re-run `scripts/ingest.py` (resumable — skips
existing threads) and `scripts/analyze.py` every 3–6 months, or before a major package launch
you plan to pressure-test. Rerun the archetype clustering and update any downstream references.

Per `[FREVIEW-011]`: a corpus refresh obliges a full re-render of any prior simulation
artifacts that are still live as references — not a metadata-only touch-up.
