---
name: documentation
description: Everything written for humans — inline DocC comments, .docc catalogues and tutorials, READMEs, blog posts and launch articles, and generated HTML/PDF documents. Apply when writing or reviewing documentation comments, a .docc article or tutorial, a README, a public post, or when building or verifying a rendered document or a deployed docs site.
---

# Docs

One skill for prose aimed at humans. Code conventions live elsewhere.

## Audience layers

A feature's documentation lives in four layers, each reaching a different reader in a different context. They do not substitute for each other.

| Layer | Where | Reader | Optimize for |
|---|---|---|---|
| Inline `///` | `.swift` source | someone using the API right now | the autocomplete/quick-help popup at the call site: one-line summary plus canonical usage snippet |
| Per-symbol article | `.docc/{Symbol}.md` | someone who clicked through to the type | overview, example, rationale, member Topics groupings |
| Topical article | `.docc/{Topic}.md` | someone learning a concept spanning symbols | task-oriented prose, decision matrices |
| Tutorial | `.docc/{Name}.tutorial` | a first-time reader | learning by doing |

Author each fact in exactly one layer and reference it from the others. API contract belongs inline; decision matrices belong in topical articles; historical rationale, research summaries, and experiment links belong in `.docc` articles and must never appear in inline `///`. Duplication is a smell unless it is a deliberate mirror of a contract the reader needs in-context.

## .docc catalogues

A `.docc/` directory must be named for its module — DocC associates catalogues by matching directory name to module name.

Exception, umbrella consolidation: in a package with a multi-target + umbrella + `@_exported public import` shape, put every per-symbol article, topical article, tutorial, and the landing page under the umbrella's single catalogue, and omit `.docc/` from the variant modules entirely. `@_exported` re-exports symbols into the umbrella's API surface but strips their doc comments during symbol-graph extraction, so without consolidation the umbrella archive shows signature-only pages while the real docs sit in sidebar archives nobody reads.

In a consolidated catalogue, each per-symbol article's `#` heading must address the symbol through the umbrella module, not its declaring module — `# ``Property_Primitives/Property/Typed``, not `# ``Property_Typed_Primitives/Property/Typed``. DocC attaches the article as an extension of the symbol as seen through the catalogue's primary module, and the umbrella is that module.

### The symbol-graph trap

`docc convert` and `docc preview` must receive **only** the isolated umbrella symbol graph via `--additional-symbol-graph-dir`. Passing the whole pool of per-module graphs makes DocC see the same precise identifier under both its declaring module and the umbrella; every in-catalogue cross-reference becomes ambiguous and every `` `Symbol` `` link silently fails to resolve. Symptom: "Failed to resolve reference" warnings for every symbol referenced in articles. Fix: write the patched umbrella graph into a dedicated directory and pass that directory alone.

```bash
xcrun docc convert "Sources/<Umbrella>/<Umbrella>.docc" \
    --additional-symbol-graph-dir "${DOCS_WORK}/umbrella-symbol-graph" \
    --fallback-display-name "<Umbrella>" \
    --fallback-bundle-identifier "<package>.<Umbrella-kebab>" \
    --output-path "${DOCS_WORK}/archives/<Umbrella>.doccarchive"
```

Symbol-graph emission, umbrella isolation, patching, and conversion are one Swift-owned operation; CI only schedules it. Reproduce locally through `workspace package build`, never raw `swift build`.

### Tutorials

A catalogue containing any `@Tutorial` file must also contain a `@Tutorials` table-of-contents file. Without it DocC emits one warning and then **silently omits the tutorial from the rendered archive** — the build still succeeds.

Do not add a host target for tutorial code. DocC treats step files as text to render, never as Swift to compile: invalid Swift in a step file builds the archive successfully with no warning. Step sources live in `.docc/Resources/` and are referenced by filename from `@Code(name:file:)`. Because DocC will never catch the rot, any package shipping tutorials in a long-lived release needs a separate verification mechanism — a test target mirroring the final step, or a CI step running `swiftc` over `Resources/*.swift`. Pick one; "we'll remember" is not one.

Start with a single tutorial with a 5–15 minute scope. Add more only after the first proves insufficient.

Keep page design (`@PageColor`, `@PageImage`, landing layout) consistent across every catalogue in a package. A variant catalogue may omit `@PageColor` to inherit the umbrella's, but must not declare a different one.

### Toolchain version labels

Any toolchain or snapshot version written into a doc, README, research note, comment, or commit must be the verbatim output of `swift --version` with that toolchain selected (`TOOLCHAINS=<bundle-id> swift --version`). Never infer it from the bundle-ID prefix, the install-directory name, the snapshot date, or memory — none of them map reliably to the reported version. Run the command, cite what it printed.

## Verifying deployed docs

A DocC site is a client-side-hydrated single-page app. `WebFetch` and `curl` see the same empty shell HTML for every page; "looks empty / minimal content" is evidence the page is DocC, not evidence the page is broken. Content verification requires a real browser that runs the JS.

Verify three independent layers and do not conflate them:

- HTTP availability — `curl -sLI` the URL. DocC's hosting 301-redirects `path` to `path/`; that normalization is expected, not a bug. Pass `-L` or you will read the 301 as breakage.
- Build status — the docs workflow run on the owning repo.
- Rendered content — a browser load, visually checked.

## READMEs

Every README belongs to exactly one family, and the family fixes the audience, the voice, and the required structure. Resolve a repository's family from `readme.family` in its canonical repository metadata rather than by guessing from the path; the centralized Swift repository-policy validator reads the same field.

| Family | Path | Reader |
|---|---|---|
| User profile | `<user>/<user>/README.md` | visitors to a person's GitHub page |
| Process / workflow repo | `<repo>/README.md` | maintainers running the workflow |
| Sub-package library | `<repo>/README.md` | evaluators deciding whether to adopt |
| Placeholder / scaffold | `<repo>/README.md` | anyone landing on a stub |
| Org profile | `<org>/.github/profile/README.md` | visitors to the organization page |

Every paragraph must answer the family's evaluation question. Ecosystem-positioning ("this is Layer 1 of…"), extraction backstory, design reflections, and pre-tag process residue are author-oriented; they belong in `Research/`, DocC, or a post. Conversely, presence is mandatory even where depth varies: name every user-facing entry point — each CLI subcommand, each top-level product — at least once with its purpose. A reader must not have to read the source or `--help` to discover a capability exists. Apply the same coverage question to `CLAUDE.md` / `AGENTS.md` (check whether they are symlinked before counting them as two surfaces).

A public README is a public contract. Never put a maintainer's home-directory path or a hand-maintained clone layout in one — expose an explicit option and document its default instead. Never cite internal rule IDs; name the behaviour.

Sub-package structure scales with maturity, and a validator checks it:

- Minimum, always: title, development-status badge, one-liner, `## Installation`, `## License`.
- Standard, once there is a public API: plus Key Features, Quick Start, Architecture, Platform Support.
- Complete, at v1.0 or with external users: plus Error Handling, Related Packages.

The development-status badge must be the first badge line directly after the H1 and must use the standard status vocabulary (`status-active--development-blue`, not an improvised `status-beta-yellow`). Platform Support cells use only `Full support`, `Supported`, `Planned`, `Possible`, `Not supported`. Placeholder READMEs carry a title, a one-line scope, and a status from exactly `Pre-implementation`, `Namespace-reservation`, `Unnecessary`, `Archived`; the validator rejects any other value and rejects any `##` section other than `## License`.

The `## Installation` block must carry both a dependency clause and a target clause, and the pin form must match reality: a branch pin before the package has any tag, a `from:` tag pin only once that tag exists. A pre-tag README pinning `from: "0.1.0"` fails resolution for every reader who copies it.

Org profiles carry no installation block. Above roughly 20 repos, an org profile must not enumerate packages — a names-only link-wall is strictly less informative than GitHub's Repositories tab and goes stale on every rename. Route into the native tab with one filter link per domain, `https://github.com/orgs/<org>/repositories?q=<term>`, above a curated "Start here" table of 5–8 packages spanning the org's capability dimensions.

### Where the check and the text disagree

The shipped README validator is not a faithful implementation of the prose, and the gaps run in both directions. Most consequential: a process/workflow repo that also ships an executable is permitted by the text to document its command surface, but the check unconditionally flags a literal `## Installation` heading, any badge line, a `## Quick Start` heading, and any README over 80 lines. Expect the finding; do not delete correct content to silence it, and do not treat a clean validator run as proof the prose rules hold. Where a check's condition is narrower than the rule it is named for, a finding asserts only the narrow condition.

## Generated documents

`import PDF` pulls the whole stack and is the default. Narrower imports exist only to avoid that: `import HTML` for HTML pages and Markdown-to-HTML rendering; `import PDF_Rendering` for direct low-level PDF composition with `PDF.View` / `@PDF.Builder` and no HTML involved.

Configuration entry points: `PDF.HTML.Configuration` for the HTML-to-PDF path (paper size, margins, default font and size, line height, table styling, outline depth), `PDF.Configuration` for direct rendering, and `Markdown.Configuration` / `Markdown.Rendering` for markdown (slug generation and directives are configuration; per-element HTML is rendering).

Fonts are the PDF Standard 14 and nothing else: `.times`, `.helvetica`, `.courier`, each with `Bold`, and `Italic` for Times or `Oblique` for the other two, plus the four `BoldItalic` / `BoldOblique` combinations.

Headers and footers require two-pass rendering — pass one counts pages, pass two renders — which is what makes "Page X of Y" correct. Declare `header:`/`footer:` heights in the configuration and pass `header:`/`footer:` closures to `PDF.HTML.pages(...)`; each closure receives a `Page.Info` carrying `pageNumber`, `totalPages`, `sectionTitle`, `documentTitle`, `date`.

When layout matters, render the artifact and inspect it. Test escaping, Unicode, empty content, and pagination.

## Public writing

Write from one reader problem to one durable insight, and explain the problem and its constraints before naming the Institute abstraction that solves it. Every code sample must compile against the version the piece presents.

Link a receipt per claim, not one blanket "see the experiments" link at the bottom. Per-claim links cost more to write and dramatically less to verify; that asymmetry is the point. When a claim is empirically true but resists minimal reproduction, link the production artifact as the receipt, link whatever experiment demonstrates the adjacent mechanism, and say plainly that the minimal reproduction does not exist.

No whimsy. No internal rule IDs or skill names in public prose — restate the principle in general terms. Cut content that documents internal editorial or organizational decisions: why the launch was structured this way, which package graduated out of which, post-meta ledes, and links that ground nothing load-bearing.

Ownership and reference primitives are escape hatches for what the language cannot express — the preferred approach is always `borrowing`, `consuming`, `~Copyable`, `~Escapable`. They may ship, but they must never be the flagship, the lead blog topic, or the featured example; their absence from most code is the point.

Publishing and deploying are separately authorized actions.
