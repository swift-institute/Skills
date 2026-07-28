---
name: documentation
description: Everything written for humans — inline DocC comments, .docc catalogues and tutorials, READMEs, blog posts and launch articles, and generated HTML/PDF documents. Apply when writing or reviewing documentation comments, a .docc article or tutorial, a README, a public post, or when building or verifying a rendered document or a deployed docs site.
---

# Docs

One skill for prose aimed at humans. Code conventions live elsewhere.

## Audience layers

A feature's documentation lives in four layers, each reaching a different reader in a
different context. They do not substitute for each other.

| Layer | Where | Reader | Optimize for |
|---|---|---|---|
| Inline `///` | `.swift` source | someone using the API right now | the autocomplete/quick-help popup at the call site: one-line summary plus canonical usage snippet |
| Per-symbol article | `.docc/{Symbol}.md` | someone who clicked through to the type | overview, example, rationale, member Topics groupings |
| Topical article | `.docc/{Topic}.md` | someone learning a concept spanning symbols | task-oriented prose, decision matrices |
| Tutorial | `.docc/{Name}.tutorial` | a first-time reader | learning by doing |

Author each fact in one layer and reference it from the others. API contract belongs inline;
decision matrices belong in topical articles; historical rationale, research summaries, and
experiment links belong in `.docc` articles and never in inline `///`. Duplication is a smell
unless it is a deliberate mirror of a contract the reader needs in-context.

Never invent a rationale. Where one is unrecorded, say so, and say that none should be
inferred — a plausible reconstruction is indistinguishable from a recorded one once it is on
the page, and the next reader has no way to tell.

## Generated documents

`import PDF` pulls the whole stack and is the default. Narrower imports exist only to avoid
that: `import HTML` for HTML pages and Markdown-to-HTML rendering; `import PDF_Rendering` for
direct low-level PDF composition with `PDF.View` / `@PDF.Builder` and no HTML involved.

Configuration entry points: `PDF.HTML.Configuration` for the HTML-to-PDF path (paper size,
margins, default font and size, line height, table styling, outline depth), `PDF.Configuration`
for direct rendering, and `Markdown.Configuration` / `Markdown.Rendering` for markdown — slug
generation and directives are configuration, per-element HTML is rendering.

Fonts are the PDF Standard 14, which is what `PDF.Font` models: Helvetica, Times, and Courier
across the regular/bold × normal/italic-or-oblique grid, plus Symbol and ZapfDingbats. The
family enum also carries a `custom` case for an embedded TrueType/OpenType face; treat that as
available but unproven here — nothing in this corpus exercises the embedding path end to end,
so verify it against the renderer before relying on it.

Headers and footers require two-pass rendering — pass one counts pages, pass two renders —
which is what makes "Page X of Y" correct. Declare `header:`/`footer:` heights in the
configuration and pass `header:`/`footer:` closures to `PDF.HTML.pages(...)`; each closure
receives a `Page.Info` carrying `pageNumber`, `totalPages`, `sectionTitle`, `documentTitle`,
and `date`.

When layout matters, render the artifact and look at it. Test escaping, Unicode, empty
content, and pagination — none of which a passing render asserts anything about.

## Public writing

Write from one reader problem to one durable insight, and explain the problem and its
constraints before naming the Institute abstraction that solves it. Every code sample compiles
against the version the piece presents.

Link a receipt per claim, not one blanket "see the experiments" link at the bottom. Per-claim
links cost more to write and dramatically less to verify; that asymmetry is the point. When a
claim is empirically true but resists minimal reproduction, link the production artifact as the
receipt, link whatever experiment demonstrates the adjacent mechanism, and say plainly that the
minimal reproduction does not exist.

No whimsy. No internal rule IDs and no skill names in public prose — restate the principle in
general terms, which is also what makes it legible to a reader outside the Institute. Cut
content that documents internal editorial or organizational decisions: why the launch was
structured this way, which package graduated out of which, post-meta ledes, and links that
ground nothing load-bearing.

Ownership and reference primitives are escape hatches for what the language cannot express —
the preferred approach is always `borrowing`, `consuming`, `~Copyable`, `~Escapable`. They may
ship, but they are never the flagship, the lead blog topic, or the featured example. Their
absence from most code is the point being made.

## Elsewhere

- `.docc` catalogues, the symbol-graph trap, tutorials, deployed-site verification —
  [docc.md](docc.md).
- README families, structure, badges, org profiles — [readmes.md](readmes.md).
