# DocC catalogues, tutorials, and deployed docs

Companion to the `documentation` skill. Read this when writing a `.docc` article
or tutorial, building a documentation archive, or checking a deployed docs site.

## No manifest restatement

A `.docc` article must not restate facts derivable from the package manifest —
target lists, dependency versions, platform floors, product enumeration. The
manifest and the evaluated-manifest command are the projection; an article
carries judgment, rationale, and usage the manifest cannot express. (Added per
https://github.com/swift-institute/.github/issues/126, 2026-07-30.)

## Catalogue naming

A `.docc/` directory must be named for its module. DocC associates catalogues by
matching directory name to module name, so a mismatch is not a style issue —
the catalogue simply does not attach.

### Umbrella consolidation

In a package with a multi-target + umbrella + `@_exported public import` shape,
put every per-symbol article, topical article, tutorial, and the landing page
under the umbrella's single catalogue, and omit `.docc/` from the variant modules
entirely.

The reason is mechanical: `@_exported` re-exports symbols into the umbrella's API
surface but strips their doc comments during symbol-graph extraction. Without
consolidation the umbrella archive shows signature-only pages while the real docs
sit in sidebar archives nobody reads — and both archives build successfully, so
nothing tells you.

In a consolidated catalogue, each per-symbol article's `#` heading addresses the
symbol through the umbrella module, not its declaring module — `#
``Property_Primitives/Property/Typed`` `, not `#
``Property_Typed_Primitives/Property/Typed`` `. DocC attaches the article as an
extension of the symbol as seen through the catalogue's primary module, and the
umbrella is that module.

### The symbol-graph trap

`docc convert` and `docc preview` must receive **only** the isolated umbrella
symbol graph via `--additional-symbol-graph-dir`. Pass the whole pool of
per-module graphs and DocC sees the same precise identifier under both its
declaring module and the umbrella; every in-catalogue cross-reference becomes
ambiguous, and every `` `Symbol` `` link silently fails to resolve.

Symptom: "Failed to resolve reference" warnings for every symbol referenced in
articles. Fix: write the patched umbrella graph into a dedicated directory and
pass that directory alone.

```bash
xcrun docc convert "Sources/<Umbrella>/<Umbrella>.docc" \
    --additional-symbol-graph-dir "${DOCS_WORK}/umbrella-symbol-graph" \
    --fallback-display-name "<Umbrella>" \
    --fallback-bundle-identifier "<package>.<Umbrella-kebab>" \
    --output-path "${DOCS_WORK}/archives/<Umbrella>.doccarchive"
```

Symbol-graph emission, umbrella isolation, patching, and conversion are one
Swift-owned operation; CI only schedules it.

## Tutorials

A catalogue containing any `@Tutorial` file must also contain a `@Tutorials`
table-of-contents file. Without it DocC emits one warning and then **silently
omits the tutorial from the rendered archive** — and the build still succeeds.

Do not add a host target for tutorial code. DocC treats step files as text to
render, never as Swift to compile: invalid Swift in a step file builds the
archive successfully with no warning. Step sources live in `.docc/Resources/` and
are referenced by filename from `@Code(name:file:)`.

Because DocC will never catch the rot, a package shipping tutorials in a
long-lived release needs a verification mechanism of its own — a test target
mirroring the final step, or a CI step running `swiftc` over `Resources/*.swift`.
Either works. "We'll remember" is not a mechanism, and the failure mode is a
tutorial that has silently stopped compiling against the API it teaches.

Start with one tutorial, scoped to a single sitting, and add more only once the
first proves insufficient.

Keep page design (`@PageColor`, `@PageImage`, landing layout) consistent across
every catalogue in a package. A variant catalogue may omit `@PageColor` to
inherit the umbrella's, but must not declare a different one.

## Toolchain version labels

Any toolchain or snapshot version written into a doc, README, research note,
comment, or commit is the verbatim output of `swift --version` with that
toolchain selected:

```bash
TOOLCHAINS=<bundle-id> swift --version
```

Never infer it from the bundle-ID prefix, the install-directory name, the
snapshot date, or memory — none of them maps reliably to the reported version.
Run the command, cite what it printed.

## Verifying deployed docs

A DocC site is a client-side-hydrated single-page app. `WebFetch` and `curl` see
the same empty shell HTML for every page, so "looks empty / minimal content" is
evidence that the page is DocC, not evidence that the page is broken. Content
verification needs a real browser that runs the JS.

Three layers, independently verified, not conflated:

- **HTTP availability** — `curl -sLI` the URL. DocC's hosting 301-redirects
  `path` to `path/`; that normalization is expected. Pass `-L`, or you will read
  the 301 as breakage.
- **Build status** — the docs workflow run on the owning repo.
- **Rendered content** — a browser load, visually checked.
