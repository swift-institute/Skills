---
name: readme/user-profile
description: |
  Family A rules — GitHub user profile README content. Apply when authoring or
  reviewing the README at <user>/<user>/README.md (the special same-name repo
  that GitHub renders at github.com/<user>). First-person mission-anchored
  voice with marketing-with-substance permitted, distinct from the third-person
  evaluator register of sub-package READMEs the same user owns.

layer: implementation

requires:
  - readme

applies_to:
  - coenttb
---

# User Profile README

Family A rules. Authoring contract for the README that GitHub renders at `github.com/<user>` — the user account's special same-name repo at `<user>/<user>/README.md`. The reader is a recruiter, prospective collaborator, ecosystem visitor, or talent scout evaluating who the user is and whether to work with, hire, or follow them.

Loaded on demand from the **readme** skill hub (`SKILL.md`). The two universal meta-rules — [README-023] Evaluator's Lens and [README-026] No Internal Rule-ID Citations — apply to this family and live in the hub.

**Scope**: All `<user>/<user>/README.md` files for user accounts in the ecosystem. Today the only such file is `coenttb/coenttb/README.md`. The rules generalize to any user account; they do not apply to repo-level READMEs the user owns (those follow Family E or Family F depending on the package's state).

The user profile is forced by GitHub: user accounts use the special same-name repo for the profile README; there is no `.github/profile/README.md` equivalent for user accounts.

Full evicted rationale and extra example variants for this family: the rationale archive (`Readme Skill Rationale Archive`), referenced below.

---

## Voice

User profile READMEs operate in a first-person, mission-anchored register — the only family in which first-person voice is permitted. Every paragraph answers "Who is this person and should I work with / hire / follow them?" — see [README-023] Evaluator's Lens in the hub.

| Element | Convention |
|---|---|
| Person | First-person ("I see a future …", "I build tools that …") for mission, philosophy, and closing call-to-action. Third-person for project descriptions ("swift-html: type-safe HTML & CSS DSL …"). The mix is intentional — the user is the agent of the mission and philosophy; the projects exist as artifacts independent of the narrator. |
| Mission framing | Required and load-bearing. Without a mission paragraph the README reduces to a portfolio; with one it reads as a person's body of work in pursuit of a goal. |
| Marketing-with-substance | Permitted and encouraged when the substance is real. "*The fastest HTML to PDF library for Swift.* 1,939 PDFs/second with 35MB memory." earns its place because the metric is verifiable and reproducible. "Best library you'll ever use!" does not — there is no substance. |
| Stars and metrics | Permitted as adoption signals but discouraged for hardcoded star counts since 2026-07-02 (stale-prone; pins render live counts — see [README-122]). Verifiable performance metrics remain welcome. |
| Future commitments | Permitted only when explicitly status-marked ("*Currently in private alpha (v0.1.0)*", "*Coming soon*"). Never promise specific dates. |
| Internal rule-IDs in prose | Forbidden per [README-026] — the reader has no access to skill files. |
| Length | 100–200 lines is the target range, derived from the canonical Family A instance (`coenttb/coenttb/README.md`, 145 lines). Sample size of 1; the range is a recommendation, not an observed norm. Beyond ~250 lines the README begins to read as a CV rather than a navigation aid. |

**The voice contrast** with Family E (sub-package): a coenttb/coenttb/README.md is a person's introduction; coenttb/swift-html/README.md is a package's evaluator-shaped README. The first allows "I see a future where …"; the second prohibits any first-person voice. Both are correct for their family.

---

## Structure

### [README-120] Identity Line

**Statement**: Family A READMEs MUST open with an H1 (the person's full name) followed immediately by a bold one-line tagline naming the person's professional roles, separated by bullet markers.

**Correct**:

```markdown
# Coen ten Thije Boonkkamp

**Lawyer • Swift Developer • Founder**
```

**Constraints**:

- H1 is the person's full name as they wish to be addressed (not a username, not a handle).
- The tagline is bold (`**...**`) and occupies a single line.
- Roles are separated by `•` (Unicode bullet, U+2022) with single spaces. Other separators (`|`, `/`, `-`) are visually weaker and SHOULD NOT be used.
- 2–4 roles is the typical range. A single role is sometimes the right call (a focused practitioner). Five or more roles dilutes the signal.

**Incorrect**:

```markdown
# coenttb  <!-- ❌ Username instead of full name -->
```

**Decision test**: Could a recruiter scanning the page in 2 seconds answer "what does this person do, broadly?" The tagline must do that.

**Rationale**: Recruiters and ecosystem visitors scan the top of the page first; the full-name H1 + bullet-separated roles tagline is the densest form of identity disclosure (full text + extra variants: rationale archive §[README-120]).

---

### [README-121] Mission Paragraph

**Statement**: Family A READMEs SHOULD include a mission paragraph (1–3 paragraphs) immediately after the identity line. The mission states the future the user is building toward and connects it to their body of work. Without a mission paragraph the README reduces to a portfolio; with one it reads as deliberate contribution toward a goal.

**Correct**:

```markdown
I see a future where no person again faces the unjust reality that economic differences significantly dictate legal outcomes. To reach that future, we need technology that makes legal services accessible and affordable.

Another reality is that the infrastructure to reach this, just isn't there yet.

That's why I build type-safe Swift web infrastructure—from PostgreSQL queries to HTML rendering, from payments infrastructure to email. 90+ open source packages working together in production. Pioneering server-side Swift through real-world systems that prove the language's potential beyond iOS.

And I plan to take all my learnings back to legal. But first:
```

**Pattern**: the mission has three load-bearing parts:

1. **The future** — what the user is building toward. The framing is normative and sometimes personal ("I see a future where …").
2. **The gap** — why the future doesn't exist yet (the infrastructure is missing, the tool is missing, the practice doesn't exist).
3. **The current focus** — what the user does today that bridges the gap. This connects to the projects section that follows.

**Optional**: a closing line that points forward to the projects section ("And I plan to take all my learnings back to legal. But first:" — observed in coenttb/coenttb).

**Incorrect**:

```markdown
I am passionate about Swift and law. I love coding.  <!-- ❌ Generic enthusiasm without a mission -->
```

**Decision test**: After reading the mission paragraph, can a reader explain in one sentence what the user is trying to change about the world? If the mission could be anyone's, it doesn't earn its place.

**Rationale**: A mission paragraph is the load-bearing differentiator between a portfolio README and a personal README — readers choose to engage based on alignment with the stated mission, and the mission frames the projects that follow (full text + extra variants: rationale archive §[README-121]).

**Cross-references**: [README-122] (the projects section the mission frames).

---

### [README-122] Flagship Projects Format

**Statement**: Family A READMEs SHOULD include a curated showcase of the user's most significant work. The preferred shape (as of 2026-07-02) is a **compact table** — one row per project, linked name + one-line role — because GitHub renders pinned-repository cards directly below the profile README, and a full per-entry anatomy duplicates that surface at three times the length. The classic per-entry anatomy (bold name + link + adoption signal + 1-line tagline + 2–5 bulleted highlights) remains permitted when pins are absent or a project genuinely needs per-entry depth.

**Section heading**: `## Selected work` or `## My contributions to <ecosystem>` or similar — the heading frames the projects as contributions rather than as advertisements.

**Correct (compact table — preferred; reference implementation coenttb/coenttb as of 2026-07-02)**:

```markdown
## Selected work

| Project | What it is |
|---|---|
| [swift-pdf](https://github.com/swift-foundations/swift-pdf) | PDF generation from HTML views and Markdown |
| [swift-io](https://github.com/swift-foundations/swift-io) | Async I/O executor isolating blocking syscalls |
| ... 3–6 more rows spanning distinct capability dimensions ... | ... |
```

Constraints for the table form: 5–8 rows spanning distinct capability dimensions; one line per role; no star counts; secondary/legacy work folds into a single prose sentence after the table rather than a second list.

**Correct (single flagship entry — classic anatomy, permitted)**:

```markdown
**[swift-html-to-pdf](https://github.com/coenttb/swift-html-to-pdf)** (54 stars)
*The fastest HTML to PDF library for Swift.* 1,939 PDFs/second with 35MB memory.
- Concurrent rendering with WebView pooling
- Swift 6 strict concurrency
- Type-safe HTML integration
```

**Anatomy** (per entry):

| Element | Form | Purpose |
|---|---|---|
| Project name | `**[name](url)**` (bold link) | Identifies the project |
| Adoption signal | `(N stars)` after the bold link, space-separated | Quantified third-party signal |
| Tagline | One italicized line `*The X for Y.*` followed by quantified-claim sentence | The motivated claim and its substance |
| Highlights | 2–5 bullet points of capabilities | Per-project feature signals |

**Subsection grouping**: when the user has many flagship entries, group by category (`### Flagship Projects`, `### Production-Ready SDKs`, `### Core Infrastructure`, `### Developer Tools`). Within each subsection, entries follow the per-entry shape above. Smaller categories MAY use a tighter form (single-line entries) when the projects are similar in role.

**Tighter form (for grouped infrastructure / tools where each line carries less weight)**:

```markdown
### Developer Tools

- [**swift-resource-pool**](https://github.com/coenttb/swift-resource-pool) (2 stars) - Production-ready resource pooling with FIFO fairness
- [**swift-throttling**](https://github.com/coenttb/swift-throttling) - Security-first rate limiting with exponential backoff
```

**Constraints**:

- The italicized tagline MUST be followed by a quantified-substance claim per [README-123] when used in marketing form ("*The fastest …*"). A bare italicized claim without substance is forbidden.
- Bullets MUST describe distinct capabilities, not synonyms. "Fast" + "Performant" + "Optimized" is one bullet's worth.
- Star counts are OPTIONAL and discouraged as of 2026-07-02: hardcoded counts go stale daily and read as score-keeping, and the pinned-repository cards below the README already render live counts. Where cited anyway, they MUST be kept reasonably current — an order-of-magnitude-stale count erodes trust (mirrors [README-021] in `sub-package.md`).

**Incorrect**:

```markdown
**[swift-foo](url)** (1000 stars) - The best HTML library ever  <!-- ❌ Marketing without substance -->
```

**Decision test**: Reading only the flagship entry, would a developer evaluating the project know whether to investigate further? If the tagline + bullets don't differentiate the project from competitors, it doesn't earn its place.

**Rationale**: The flagship-entry shape is the densest form of project signaling — star count as adoption proxy, italicized tagline as frame, quantified claim as substance, bullets as capabilities (full text + extra incorrect variants: rationale archive §[README-122]).

**Cross-references**: [README-123] (quantified-claim convention); [README-021] in `sub-package.md` (maintenance currency).

---

### [README-123] Quantified-Claim Convention

**Statement**: Marketing-shaped claims in user profile READMEs MUST be paired with quantified substance. The italicized form (`*Claim.*`) is permitted only when the next sentence supplies a verifiable metric, benchmark, or behavioral guarantee.

**Correct**:

```markdown
*The fastest HTML to PDF library for Swift.* 1,939 PDFs/second with 35MB memory.
```

The substance can be quantitative (throughput, latency, memory) or qualitative-but-verifiable (technology choice claim like "100% Swift"; feature-coverage claim like "48 modules covering entire Stripe API").

**Incorrect**:

```markdown
*Lightning fast performance.* Built for speed.  <!-- ❌ Substance is a synonym, not a measurement -->
```

**Decision test**: Could the substance sentence be falsified by a measurement? If yes, the claim earns its place. If the substance is restating the marketing claim in different words, it does not.

**Rationale**: The italicized form is a marketing convention, and marketing without substance is forbidden by the universal evaluator's lens ([README-023]); the quantified-substance pairing preserves the convention's signaling value while preventing hype (full text + extra variants: rationale archive §[README-123]).

**Cross-references**: [README-006] in `sub-package.md`; [README-016] in `sub-package.md` (marketing language without substance).

---

### [README-124] Professional Work Section

**Statement**: Family A READMEs SHOULD include a `## Professional Work` section when the user does professional work outside the open-source ecosystem (consulting, employment, advisory roles). Each entry uses a consistent shape: bold role + dash + 1-line scope, followed by bulleted client/engagement links.

**Correct**:

```markdown
## Professional Work

**Legal Advisor** - Bridging law and code for groundbreaking life sciences:
- [100+ Study](https://100plus.nl) - Amsterdam UMC's pioneering longevity research
- [Alzheimer Genetics Hub](https://alzheimergenetics.org) - Global genetics collaboration platform
- [DEMENTREE Biobank](https://www.alzheimercentrum.nl/wetenschap/lopend-onderzoek/biobank-dementree/) - Advanced dementia research infrastructure
```

**Constraints**:

- The role is the user's title in the engagement (Legal Advisor, Technical Consultant, etc.).
- The scope is what the user contributes, framed in a way that connects to the mission ([README-121]).
- Each engagement is a public link the reader can follow; private engagements are NOT listed (no "confidential client" entries).
- Engagements MUST be active or recent. Past engagements (> 2 years inactive) belong on a separate CV, not the user profile README.

**Decision test**: Could a recruiter or prospective collaborator click through to verify the engagement is real? If no, the entry doesn't earn its place.

**Rationale**: Professional engagements signal domain credibility outside the open-source body of work and connect the mission to outcomes; the bulleted-link form makes verification trivial (full text: rationale archive §[README-124]).

**Cross-references**: [README-121] (mission paragraph the professional work supports).

---

### [README-125] Philosophy Section

**Statement**: Family A READMEs MAY include a `## Philosophy` section stating the user's beliefs grounded in their body of work. The section opens with a paragraph framing the philosophy, followed by a bold "Core beliefs:" header and 3–5 bulleted convictions.

**Correct**:

```markdown
## Philosophy

I build tools that make wrong things impossible. Every abstraction removes entire classes of errors. My frameworks don't just work - they teach you how to build better systems.

**Core beliefs:**
- Type safety is a feature, not overhead
- Swift's future extends far beyond Apple platforms
- The best code is code that guides its users
- Building in public accelerates everyone's learning
```

**Constraints**:

- Beliefs MUST be evidenced in the user's body of work elsewhere in the README (the "type safety is a feature" belief is corroborated by the type-safe HTML, queries, environment variables projects).
- Beliefs MUST be the user's own — not generic industry truisms ("good code is readable code").
- Beliefs MUST NOT be applied prescriptively to readers ("you should use Swift").
- 3–5 bullets is the range. Fewer dilutes the signal; more starts to read as a manifesto.

**Incorrect**:

```markdown
**Core beliefs:**
- Code should be clean
- Tests are important
- DRY principle  <!-- ❌ Generic truisms with no connection to the user's work -->
```

**Decision test**: For each belief, can you point to a project or piece of work in the README that demonstrates the belief in practice? If no, the belief is decorative.

**Rationale**: A philosophy section without grounding is hot air; with grounding it tells the reader how the user reasons — sometimes the load-bearing fit signal for prospective collaborators (full text + extra variants: rationale archive §[README-125]).

---

### [README-126] Recent Writing Section

**Statement**: Family A READMEs MAY include a `## Recent Writing` section listing 3–5 of the user's most relevant published pieces, ordered most-relevant-first (often most-recent-first when relevance correlates with recency). Each entry is a link + 1-line description.

**Correct**:

```markdown
## Recent Writing

- [From Broke to Building in Public](https://www.coenttb.com/blog/1-from-broke-to-building-in-public-open-sourcing-coenttb-com) - Why I open-sourced my business
- [A Journey Building HTML Documents in Swift](https://www.coenttb.com/blog/2-a-journey-building-html-documents-in-swift) - Evolution of type-safe HTML
- [A Tour of PointFreeHTML](https://www.coenttb.com/blog/3-a-tour-of-pointfreehtml) - Deep dive into HTML DSLs
- [Modern Swift Library Architecture](https://www.coenttb.com/blog/4-modern-swift-library-architecture-1-the-swift-package) - Building modular systems
```

**Constraints**:

- 3–5 entries. Fewer feels thin; more starts to read as a publication list.
- Each entry MUST link to a publicly accessible piece (no private-link "ask me for the article" entries).
- The 1-line description states what the piece is about, not promotional language ("read this!").
- Pieces older than ~2 years SHOULD be replaced with newer work as it accumulates.

**Decision test**: Reading the descriptions, would a reader interested in the user's mission ([README-121]) want to click through? If no, the writing list isn't relevant — either replace with more relevant pieces or omit the section.

**Rationale**: Writing signals how the user thinks beyond what the projects show; 3–5 pieces demonstrates range without consuming the page (full text: rationale archive §[README-126]).

---

### [README-127] Connect Block

**Statement**: Family A READMEs SHOULD include a `## Let's Connect` section listing the user's canonical communication channels with one entry per channel. Channels: website, social platforms, professional/legal practice, contact form. Each entry is `**Channel:**` followed by a link.

**Correct**:

```markdown
## Let's Connect

- **Website:** [coenttb.com](https://coenttb.com)
- **Twitter/X:** [@coenttb](https://x.com/coenttb)
- **LinkedIn:** [Coen ten Thije Boonkkamp](https://www.linkedin.com/in/tenthijeboonkkamp)
- **Legal Practice:** [Ten Thije Boonkkamp](https://tenthijeboonkkamp.nl)
```

**Constraints**:

- Channel name is bold and ends with a colon.
- Each channel is a single link (the user's primary presence on that channel, not multiple alts).
- 3–5 channels typical. Listing every social network the user has accounts on dilutes the signal.
- If the user has different presences for different domains (technical vs legal vs personal), include them as separate channels with descriptive names ("Legal Practice", "Twitter/X").

**Decision test**: For a reader who wants to reach the user, does each channel resolve to an actually-used presence? Dormant accounts and abandoned pages should be removed.

**Rationale**: The connect block is the call-to-action affordance — readers who decided to engage need a clear path, and channel diversity lets them choose the one that fits their context (full text: rationale archive §[README-127]).

---

### [README-128] Closing Call-to-Action

**Statement**: Family A READMEs MAY end with an italicized one-sentence opt-in call-to-action stating what the user is currently open to and how to initiate. Single sentence, italicized to signal it's metadata about availability rather than continued profile content.

**Correct**:

```markdown
---

*Currently accepting select consulting engagements in Swift, breakthrough life science projects, or legal tech. Have an interesting challenge? [Let's talk](https://coenttb.com/contact).*
```

**Constraints**:

- A horizontal rule (`---`) separates the call-to-action from the connect block.
- The sentence is italicized and includes the word "Currently" or equivalent (signals freshness / opt-in).
- The link MUST be a contact form, calendar booking, or canonical opener — not a generic "DM me on Twitter" (which would belong in [README-127]).
- Update or remove the closing call-to-action when the user is no longer open to new engagements.

**Decision test**: Does the call-to-action reflect what the user is *currently* open to? Stale opt-ins (the user is fully booked but the README still says "accepting engagements") erode trust.

**Rationale**: The closing call-to-action converts readers who reached the bottom into action-takers; the italics + "Currently" framing signal live availability, and removal-when-closed prevents false signals (full text: rationale archive §[README-128]).

---

### [README-129] (reserved)

---

## Cross-References

- **readme** skill hub (`SKILL.md`) — Family routing matrix, universal meta-rules ([README-023], [README-026]).
- **readme/sub-package** sibling — Family E rules; the third-person evaluator register that the same user's package READMEs follow. The voice contrast is intentional.
- **readme/org-profile** sibling — Family G rules; the institutional counterpart for organization accounts. User profiles are first-person; org profiles are third-person plural.
- Provenance: `coenttb/coenttb/README.md` (145 lines, 2026-05-01) is the canonical instance of a correctly-formed Family A README. Rules derived from observation of that file plus the universal evaluator-lens discipline.
