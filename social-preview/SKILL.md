---
name: social-preview
description: |
  GitHub social preview cards: parametric chassis, org brand in metadata.yaml's socialPreview block, local render+upload via Scripts/social-preview.sh.
  Apply when adding preview cards, modifying the chassis, or adding an org brand variant.

layer: implementation

requires:
  - github-repository
  - swift-institute

applies_to:
  - swift-primitives
  - swift-standards   # umbrella org, has its own swift-* packages
  - swift-ietf        # standards-body sub-org under swift-standards
  - swift-iso         # standards-body sub-org
  - swift-ieee
  - swift-iec
  - swift-w3c
  - swift-whatwg
  - swift-ecma
  - swift-incits
  - swift-foundations
  - swift-institute

created: 2026-05-07
---

# Social Preview

Social preview cards (the 1280×640 image GitHub displays when a repo URL is
shared on Twitter/X, LinkedIn, Slack, Discord, iMessage) for all ecosystem
repositories. Defines the parametric chassis, the per-org brand declaration,
the namespace derivation rule, and the render-then-upload local flow.

**Scope boundary**: this skill governs the **rendering + deployment** of
social preview cards. The card *content* (chassis design, brand colors per
tier) is editable via the chassis template + per-org metadata.yaml. Other
GitHub repo metadata (description, topics, homepage) is governed by
`github-repository`.

---

## Why local-only (no CI)

GitHub does not expose a public REST/GraphQL/CLI API for setting a
repository's social preview image (verified 2026-05; staff-confirmed
2025-09-04). The only deployment path is browser session-cookie automation
via Playwright. The session cookie is **password-equivalent** (full account
access, broader privilege than `admin:org`) and **cannot live in CI
secrets** — anyone with workflow-write on a shared infrastructure repo
could exfiltrate it.

Consequence: deployment is local-only. The `Scripts/social-preview.sh`
script renders + uploads from the maintainer's laptop using the maintainer's
existing browser session. Same privilege as manually clicking "Edit" in the
Settings UI; no new attack surface.

---

### [SOC-001] Local-Only Deployment

**Statement**: Social preview deployment MUST run locally on a
maintainer's machine, never in CI. The vendored Playwright uploader at
`swift-institute/Scripts/social-preview-uploader/` uses a
`user_session`-cookie-based authentication that is password-equivalent
and MUST NOT be stored in shared CI secrets.

**Cross-references**: `feedback_no_gh_cli_admin_scope`,
`Research/social-preview-cards-ecosystem-strategy.md` § Capability finding.

---

### [SOC-002] Parametric Chassis

**Statement**: The social preview chassis is a single parametric SVG
template at `swift-institute/.github/social-preview/chassis.svg.tmpl`,
rendered by `swift-institute/.github/social-preview/render.py`. The
chassis is org-agnostic — it knows nothing about specific orgs or
package names. All variation (gradient color, caption, namespace) is
substituted at render time from caller-supplied inputs.

**Chassis design** (variant 07 "diptych-clean", selected 2026-05-07):

| Region | Content |
|---|---|
| Left half (520×640) | Tier-coloured gradient flood + 4-bar pyramid glyph (white-on-accent), centered slightly below canvas optical center to anchor the pyramid base |
| Right half (760×640) | Headline namespace (≥48 px font, auto-fits 132 px / shrunk single-line / two-line CamelCase split); kebab subline; uppercase tier caption in accent color |

**Required placeholders** in the chassis template:

| Placeholder | Source | Example |
|---|---|---|
| `{{ACCENT_FROM}}` | org metadata.yaml | `#D88751` |
| `{{ACCENT_TO}}` | org metadata.yaml | `#A04A1B` |
| `{{ACCENT_TEXT}}` | org metadata.yaml | `#A04A1B` |
| `{{CAPTION}}` | org metadata.yaml | `PRIMITIVES` |
| `{{NAMESPACE_L1}}` | derived / override | `Buffer` |
| `{{NAMESPACE_L2}}` | derived / override | `` (empty) or `Representation` |
| `{{PACKAGE_NAME}}` | repo name | `swift-buffer-primitives` |

**Forbidden**: per-org or per-package chassis SVG files. There is one
chassis. Brand variation lives entirely in the substituted values.

---

### [SOC-003] Org-Level Brand Declaration

**Statement**: Each org that ships social preview cards MUST declare its
brand in its `.github` repo's `metadata.yaml` under the `socialPreview`
key. The block schema is:

```yaml
socialPreview:
  accent:
    from: "#HEX"   # gradient top
    to: "#HEX"     # gradient bottom
    text: "#HEX"   # caption ink (typically same as `to`)
  caption: "UPPERCASE"
```

**Conventions per layer** (informational; not enforced by tooling):

| Layer | Accent | Caption |
|---|---|---|
| Primitives | bronze (`#D88751` → `#A04A1B`) | `PRIMITIVES` |
| Standards | silver (`#A8AEB8` → `#4D5664`) | `STANDARDS` |
| Foundations | gold (`#EFC868` → `#C99932`) | `FOUNDATIONS` |
| Institute (org-of-orgs) | capstone (`#FCE39A` → `#E5BD5A`) | `INSTITUTE` |

**Co-residence**: the `socialPreview` block lives alongside `description`,
`homepage`, `topics`, etc. in the same `metadata.yaml`. Schema is uniform
between org-level (defaults) and per-repo (overrides) per
`github-repository` [GH-REPO-*].

**Cross-references**: [GH-REPO-070], `Research/github-metadata-harmonization.md`.

---

### [SOC-004] Namespace Derivation

**Statement**: The headline display name MUST resolve in the following
order, with the first non-empty match used:

1. **Per-repo override**: `socialPreview.displayName` in the target repo's
   `.github/metadata.yaml`. May contain a literal `|` to force a 2-line break.
2. **Mechanical derivation** (in `social-preview.sh`'s `awk` rule):
   1. Strip `swift-` prefix and trailing `-primitives` / `-standards` /
      `-foundations` / `-standard` (singular) suffix.
   2. If the first kebab-segment is an **authority code** (`rfc`, `iso`,
      `ieee`, `iec`, `w3c`, `whatwg`, `ecma`, `incits`, `bcp`), uppercase it
      and **space-separate** subsequent segments.
   3. **Numeric continuation**: when authority-mode is active and two
      consecutive segments are numeric (standard-year pattern), join them
      with `-` instead of space (e.g. `incits-4-1986` → `INCITS 4-1986`).
   4. **Acronym uppercasing**: tokens matching the acronym list (`uri`,
      `url`, `uuid`, `pdf`, `css`, `html`, `xml`, `json`, `rss`, `svg`,
      `png`, `http`, `https`, `dns`, `tcp`, `udp`, `ip`, `io`, `smtp`,
      `imap`, `pop3`, `sql`, `sha`, `md5`, `utf`, `ascii`, `iana`,
      `ietf`, `cpu`, `epub`) are uppercased regardless of position.
   5. **Mixed-case map**: `ipv4` → `IPv4`, `ipv6` → `IPv6` (extend as needed).
   6. **Other tokens**: title-cased (first letter upper, rest lower).
   7. **Non-authority mode**: tokens are space-separated for readability
      (e.g. `swift-html-css-pointfree` → `HTML CSS Pointfree`).

**Worked examples** (mechanical, no override):

| package-name | derived display |
|---|---|
| `swift-buffer-primitives` | `Buffer` |
| `swift-rfc-8259` | `RFC 8259` |
| `swift-iso-32000` | `ISO 32000` |
| `swift-incits-4-1986` | `INCITS 4-1986` |
| `swift-bcp-47` | `BCP 47` |
| `swift-w3c-svg` | `W3C SVG` |
| `swift-whatwg-html` | `WHATWG HTML` |
| `swift-ipv6-standard` | `IPv6` |
| `swift-uri-standard` | `URI` |
| `swift-html-css-pointfree` | `HTML CSS Pointfree` |
| `swift-html-fontawesome` | `HTML Fontawesome` |
| `swift-intermediate-representation-primitives` | `Intermediate Representation` |

**Override is required when** mechanical derivation produces a name that
clashes with the canonical brand or designation, e.g.:

| package | mechanical | override (`socialPreview.displayName`) |
|---|---|---|
| `swift-postgresql-standard` | `Postgresql` | `PostgreSQL` |
| `swift-emailaddress-standard` | `Emailaddress` | `Email Address` |
| `swift-w3c-cssom` | `W3C Cssom` | `W3C CSSOM` |
| `swift-html-fontawesome` | `HTML Fontawesome` | `HTML\|Font Awesome` (2-line, brand) |

The `|` character in a `displayName` is a forced line-break for the auto-fit
logic — used when the natural single-line render would shrink unattractively
or when the brand has a canonical 2-line presentation.

**Forbidden**: enumerating the package's `Sources/` directory to detect the
primary module. The GitHub Contents API returns Sources entries in
non-deterministic order, leading to incorrect picks (e.g. picking
`Carrier Primitives Standard Library Integration` instead of
`Carrier Primitives`).

**Cross-references**: `feedback_namespace_implicit_prefix_removal`,
`API-NAME-001`.

---

### [SOC-005] Auto-Fit Layout Logic

**Statement**: `render.py` selects layout via per-glyph-class width
estimation, not character count. The chassis right-pane safe area is
**640 px wide** (x=580..1220), giving a symmetric 60 px gap on both
sides of the text (gradient ends at x=520; canvas right edge at x=1280).

**Width estimator** — em advances tuned empirically against Inter Heavy
800 with `letter-spacing="-2"`:

| Glyph class | Advance (em) |
|---|---|
| Uppercase / digit | 0.70 |
| Lowercase | 0.55 |
| Space | 0.30 |

A flat-average estimator (e.g. 0.55em across all glyphs) underestimates
all-caps strings — `W3C CSSOM` (8 caps + 1 space) measures ~5.96em, not
the ~4.95em a flat estimator predicts, and clips the right margin at
default size. The per-class estimator preserves the symmetric margin.

**Layout priority** (first matching mode wins):

1. **Full-size single line** (132 px) if width fits in 640 px.
2. **Shrunk single line** at the largest size that fits ≥ 84 px
   (the two-line full-size threshold).
3. **Full-size two-line** (84 px) if a split exists and the longer half fits.
4. **Shrunk two-line** at the largest size that fits ≥ 48 px (the
   thumbnail-legibility floor).

The priority deliberately prefers shrunk single-line over full-size
two-line *until* the shrunk size would drop below 84 px — at which
point a 2-line at 84 px preserves more visual weight per line than
a 1-line at, say, 75 px.

**Two-line split** (in `split_two_lines()`):

1. Explicit `|` separator (manual override from `displayName`) — split there.
2. Whitespace closest to the midpoint.
3. CamelCase boundary closest to the midpoint.

**Minimum font size**: 48 px floor on the 1280×640 canvas. Below this,
text becomes illegible at Twitter/X timeline thumbnail size (~504 px wide).

**Y-baseline policy**: content cluster anchored at canvas y≈350 (slightly
below mathematical center y=320) to balance against the pyramid glyph's
heavy base. Single-line: headline at y=350, subline at y=410, caption at
y=470. Two-line: lines at y=310 and y=310+font_size, subline and caption
follow at +60 / +113 px from the second line.

**Cross-references**: `Research/social-preview-cards-ecosystem-strategy.md` § Hard constraints.

---

### [SOC-006] No Committed PNG

**Statement**: The rendered PNG is derived state and MUST NOT be committed
to the target repo. The chassis + org metadata.yaml + package name are the
authoritative inputs; the PNG is reproducible from them on demand.

**Forbidden**:
- `.github/social-preview.png` committed to any repo
- A CI workflow that opens PRs to commit the PNG
- A workflow that hash-compares "PNG in repo" vs "PNG served by GitHub"

**Why**: matches ecosystem norm for derived artifacts (DocC HTML, SwiftPM
build outputs aren't tracked); avoids two-source-of-truth drift; obviates
the merge step that delays deployment.

**Drift detection** (if/when needed) compares rendered-fresh hash vs
GitHub-served `og:image` hash, NOT vs an in-repo PNG.

**Cross-references**: `Research/social-preview-cards-ecosystem-strategy.md`
§ Why local-only.

---

### [SOC-007] Vendored Uploader

**Statement**: The Playwright-based uploader at
`swift-institute/Scripts/social-preview-uploader/` is vendored from
[AnswerDotAI/gh-social-preview](https://github.com/AnswerDotAI/gh-social-preview)
(ISC license) with the README-screenshot logic stripped. It accepts a
pre-rendered PNG via `--image`, which the upstream tool does not.

**Critical implementation detail — `networkidle` wait**: After the upload
network response and image-id population, the script MUST wait for
`page.waitForLoadState("networkidle")` before closing the browser. Without
it, the `image-id` is set on the repo before the S3 PUT for the image bytes
completes, leaving a stale `og:image` URL that returns HTTP 403 AccessDenied
from the S3 CDN.

**Verification**: a successful upload MUST result in:
1. `og:image` meta on the public repo page pointing to
   `repository-images.githubusercontent.com/<repo-id>/<uuid>`
2. That URL serving HTTP 200 with PNG bytes matching the locally-rendered PNG
3. Settings → Social preview UI displaying the card (after page refresh)

If any of (1)–(3) fail, the upload was incomplete and must be re-run.

**Cross-references**: upstream commit at AnswerDotAI/gh-social-preview that
this is based on; vendor file: `Scripts/social-preview-uploader/upload.js`.

---

### [SOC-008] One-Time Auth, Persistent Session

**Statement**: The Playwright session is captured once via
`node upload.js init-auth` (interactive; opens browser, maintainer logs in
normally) and persisted at
`$XDG_STATE_HOME/gh-social-preview/auth/github.json` (fallback
`~/.local/state/gh-social-preview/auth/github.json`). Subsequent script
invocations reuse this session — no re-login per repo.

**Session lifetime**: matches GitHub's session cookie lifetime (typically
months unless explicitly logged out). Re-run `init-auth` only if the
session expires (the script will error with a clear message).

**Auth path co-residency**: matches the upstream tool's default path so
the two share state. If the upstream tool ever ships an `--image` flag, this
vendor can be retired and the upstream tool used directly without re-auth.

---

### [SOC-010] Per-Repo Display-Name Overrides

**Statement**: When mechanical derivation produces a display name that
clashes with the canonical brand, the package repo's `.github/metadata.yaml`
MUST add a `socialPreview.displayName` key. The override is the single point
of triage — there is no override at the org-defaults metadata.yaml.

**Schema**:

```yaml
# In <package>/.github/metadata.yaml (alongside description, topics, homepage)
socialPreview:
  displayName: "Email Address"   # plain string, or
  displayName: "HTML|Font Awesome"   # | forces 2-line break
```

**When to override**:

| Case | Mechanical | Override |
|---|---|---|
| Mixed-case brand (PostgreSQL, FontAwesome) | `Postgresql` | `PostgreSQL` |
| Multi-word that should display as words | `Emailaddress` | `Email Address` |
| Authority + acronym not in default list | `W3C Cssom` | `W3C CSSOM` |
| Brand wants forced 2-line presentation | `HTML Fontawesome` (single shrunk) | `HTML\|Font Awesome` |
| Authority code with multi-word body | `IETF Foo Bar` (mechanical OK) | (no override) |

**Cross-cutting fixes**: if many packages share the same fix (e.g. a
new common acronym that appears everywhere), prefer extending the
acronym list in `social-preview.sh`'s `awk` rule rather than adding
overrides in N packages. Overrides are for **package-specific brand
calls**, not for **systemic gaps in the derivation rules**.

**Override authoring requires the package repo to be cloned locally** at
`~/Developer/<owner>/<package>/`. The script reads
`<owner>/<package>/.github/metadata.yaml` directly from the working tree.
Commit + push the override before running `--backfill` so the rendered
card matches what's served.

---

### [SOC-009] Public-Repo Scope

**Statement**: Custom social previews are technically **gated by GitHub
to public repositories**. Private repos cannot receive custom cards
regardless of how the upload is invoked — the Settings → Social preview
UI element does not render on private repos, so the Playwright uploader's
`<h2>Social preview</h2>` locator times out (60s) and the script fails.
The `--backfill <org>` mode enumerates only public, non-archived repos
matching `swift-*` (excluding `*.org` website repos and the `.github`
infrastructure repo); this filter is **load-bearing**, not just a CI-policy
alignment.

**Per-repo invocation** (single target) does not enforce this filter at
the script level — a maintainer may pass any repo name — but a private-repo
target will fail at the upload step with the selector timeout above.
**Pre-publication card prep is not possible**: a repo must be public at
the moment of upload. The workflow is: (1) flip the repo public, (2) run
`Scripts/social-preview.sh <owner>/<repo>` immediately after.

**Forbidden anti-pattern**: do not flip a repo public for the sole purpose
of deploying its card. Wait until the repo is being published for its own
reasons (1.0 tag, blog launch, ecosystem announcement); the card is part
of the publication, not a precondition for it. Private repos stay private
and ship with GitHub's default `opengraph.githubassets.com` rendering
until they're independently ready for publication.

**Empirical verification**: 2026-05-12 — ran 28 sequential single-target
deploys covering 1 newly-public repo + 27 private repos. The newly-public
repo succeeded; all 27 private repos timed out on the same selector. No
exceptions observed across multiple repo shapes (different name patterns,
different sizes). The skill description prior to this date claimed
private-repo deploy "would technically work" — that claim was empirically
incorrect and has been removed.

---

## Operations

### One-time setup

```bash
cd ~/Developer/swift-institute/Scripts/social-preview-uploader
npm install                # installs Playwright + downloads Chromium (~150 MB)
node upload.js init-auth   # opens browser; log in to github.com; session saved
```

### Single repo (render + upload)

```bash
~/Developer/swift-institute/Scripts/social-preview.sh swift-primitives/swift-buffer-primitives
```

~7-10 sec total: render (50 ms) + Playwright launch (~5 sec) + upload + networkidle wait.

### Single repo (render only, manual upload via Settings UI)

```bash
~/Developer/swift-institute/Scripts/social-preview.sh --no-upload swift-primitives/swift-buffer-primitives
# Auto-opens Finder (with PNG selected) + Settings → Social preview tab.
# Drag PNG into upload area; click Save changes.
```

### Org-wide backfill

```bash
~/Developer/swift-institute/Scripts/social-preview.sh --backfill swift-primitives
```

Iterates every public swift-* repo in the org, render + upload each
serially. ~7-10 min for ~60 repos. Per-repo errors are reported but don't
halt the run.

### Adding a new org

1. Author `<new-org>/.github/metadata.yaml` with the `socialPreview` block.
2. Run `--backfill <new-org>`.

No swift-institute changes required. The chassis is already org-agnostic.

### Adding an org-of-orgs (umbrella + sub-orgs)

When an org is a notional umbrella for several sibling orgs (e.g.
swift-standards is the umbrella for swift-ietf / swift-iso / swift-ieee
/ swift-iec / swift-w3c / swift-whatwg / swift-ecma / swift-incits),
**each sub-org needs its own** `.github/metadata.yaml` with the
`socialPreview` block. There is no inheritance from the umbrella's
metadata. The umbrella org's metadata.yaml only governs repos that live
directly under the umbrella org's GitHub namespace.

For visual cohesion across a standards-body cohort, use the **same brand
declaration** (same accent + same caption) in every sub-org's metadata —
authority differentiation is in the per-package display name (e.g.
`RFC 8259`, `ISO 32000`, `W3C EPUB`), not in the brand. The standards
cohort all ship silver gradient + `STANDARDS` caption.

Backfill each sub-org separately:

```bash
for org in swift-standards swift-ietf swift-iso swift-ieee swift-iec \
           swift-w3c swift-whatwg swift-ecma swift-incits; do
  ~/Developer/swift-institute/Scripts/social-preview.sh --backfill "$org"
done
```

### Adding a per-repo display-name override

1. Clone the package locally if not already: `~/Developer/<owner>/<package>/`.
2. Add a `socialPreview.displayName` key in
   `<owner>/<package>/.github/metadata.yaml`.
3. Commit + push.
4. Re-render and re-upload that one repo:
   ```bash
   ~/Developer/swift-institute/Scripts/social-preview.sh <owner>/<package>
   ```

See [SOC-010] for the override decision rule (when to override vs. when
to extend the acronym list).

### Chassis change (visual update)

1. Edit `swift-institute/.github/social-preview/chassis.svg.tmpl` and/or
   `render.py`.
2. Commit + push to `swift-institute/.github`.
3. Run `--backfill <each-org>` to regenerate + redeploy across the
   ecosystem.

No PRs land in target repos. No merging. Single command per org.

---

## Verification

After upload, verify the card is live:

```bash
# Public og:image meta should point to repository-images.githubusercontent.com
curl -sL https://github.com/<owner>/<repo> | grep -oE 'meta property="og:image" content="[^"]*"'

# That URL must return HTTP 200 with PNG bytes
URL=$(curl -sL https://github.com/<owner>/<repo> | grep -oE 'repository-images\.githubusercontent\.com/[0-9]+/[a-f0-9-]+')
curl -sLI "https://$URL" | head -1
```

Expected:
- `og:image` host: `repository-images.githubusercontent.com` (custom upload)
- HTTP status: 200
- Content-type: `image/png`

If `og:image` host is `opengraph.githubassets.com`, no custom card is set
(upload didn't complete or was never attempted).

If status is 403 with body `<Error><Code>AccessDenied</Code>`, the upload
attached an image-id to the repo but the S3 PUT didn't complete — re-run
the upload (the `networkidle` fix in [SOC-007] should prevent this, but
network conditions may still race occasionally).

---

## File map

```
swift-institute/.github/
  social-preview/
    chassis.svg.tmpl              # parametric SVG; never per-org/per-repo
    render.py                     # auto-fit + substitute; called by social-preview.sh

swift-institute/Scripts/
  social-preview.sh               # render + upload wrapper
  social-preview-uploader/
    upload.js                     # vendored Playwright uploader
    package.json                  # playwright dep
    package-lock.json             # committed for reproducibility
    .gitignore                    # node_modules/

<each-org>/.github/
  metadata.yaml                   # org-level socialPreview block (brand defaults)

<each-package>/.github/
  metadata.yaml                   # optional: per-repo socialPreview.displayName override
```

---

## Open Questions

1. **Drift detection**: when chassis or brand changes, which repos still
   have the stale card live? A weekly script could fetch every repo's
   `og:image`, hash it, compare to a fresh local render, and surface stale
   ones. Not yet implemented; only matters once the ecosystem has more than
   ~5 chassis revisions.

2. **Selector brittleness**: the Playwright uploader depends on GitHub UI
   selectors (`#edit-social-preview-button`, `input#repo-image-file-input`,
   `input.js-repository-image-id`, `.js-repository-image-container`). If
   GitHub redesigns Settings, these may break. Recovery: inspect the new
   selectors; update `upload.js`. The upstream gh-social-preview tracks
   these too — watch its commit history for fixes.

3. **Public API**: GitHub may eventually ship a real REST/GraphQL endpoint
   for social preview. When that happens, the Playwright uploader becomes
   obsolete; replace with a fine-grained PAT + REST call. Watch
   [Community Discussion #172072](https://github.com/orgs/community/discussions/172072).

---

### [SOC-011] Post-Tuning Design-QA Gate via Multimodal Subordinate Agent

**Statement**: After ANY change to layout-affecting constants (advance estimator, pane width, auto-fit priority, glyph-class advance, displayName overrides), the writer MUST render the FULL cohort with `--no-upload` and run a multimodal subordinate-agent review for clipping / margin / cohesion BEFORE re-uploading. The render-without-upload pass is mechanical; the multimodal-agent QA pass catches clipping/cohesion defects that count-only metrics miss.

**Composite:** discipline rule (mechanical) + brief shape (semantic) + worked-example mapping (semantic).

**Procedure**:

```bash
# After tuning constants (e.g., pane width 0.70 → 0.74):
Scripts/social-preview.sh --backfill <org> --no-upload

# Then dispatch multimodal subordinate agent against the rendered cohort:
# Brief shape: "you are a senior visual designer obsessed with margin
#               cohesion. Strategic sampling across primitives/standards/
#               foundations + targeted outlier inspection (longest names,
#               narrowest avatars). Output: severity rubric (BLOCK / MAJOR
#               / MINOR / NIT) per item with concrete suggested fix."
```

The brief shape generalizes: "you are a senior {role} obsessed with {invariant}. Strategic sampling across {categories} + targeted outlier inspection. Output: severity rubric per item with concrete suggested fix." Useful any time bulk-generated visual or structured artifacts need cohort-level QA without per-item human review.

**Worked example (the origin incident)**:

The 2026-05-08 social-preview rollout went through 3 estimator iterations. Iteration 2 ("Build complete!" against the per-glyph-class advance estimator) reported zero error count. The multimodal subordinate-agent QA pass on the full cohort caught 5 BLOCK clippings on the longest-displayName tail (e.g., `swift-algebra-semilattice-primitives`); the constants got bumped from 0.70/0.55 → 0.74/0.57 in iteration 3 to address the clippings. Without the QA pass, iteration 2 would have shipped 5 BLOCK clipped cards.

**Rationale**: Cohort-bulk visual artifacts have a long-tail clipping/cohesion failure mode that count-only checks ("did N cards render?") cannot detect. A multimodal agent operating on a strict severity rubric provides cohort-scale QA at sub-second-per-card cost. The render-without-upload pass is the mechanical prerequisite — the agent reviews the rendered output, not the rendering pipeline.


**Cross-references**: [SOC-005] (Auto-Fit Layout Logic), [SOC-010] (Per-Repo Display-Name Overrides)

---

## References

- [Customizing your repository's social media preview — GitHub Docs](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/customizing-your-repositorys-social-media-preview)
- [GitHub Community Discussion #172072](https://github.com/orgs/community/discussions/172072)
- [AnswerDotAI/gh-social-preview](https://github.com/AnswerDotAI/gh-social-preview)
- Internal: `swift-institute/Research/social-preview-cards-ecosystem-strategy.md`
- Internal: `swift-institute/Skills/github-repository/SKILL.md`
- Internal: `swift-institute.org/avatars/avatar-{primitives,standards,foundations,institute}.svg`
