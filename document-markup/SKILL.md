---
name: document-markup
description: Select and compose the Institute HTML, Markdown, PDF, and rendering packages. Apply when creating markup, rendering documents, generating PDFs, or choosing a document pipeline.
---

# Document markup

Compose the narrowest existing document capabilities. Keep document semantics,
serialization, rendering, and transport as separate owners.

## Workflow

1. Identify the source model, target format, rendering requirement, and output
   boundary.
2. Search the ecosystem for the existing markup, encoder, renderer, and file
   capabilities.
3. Choose semantic types before string concatenation or ad-hoc templates.
4. Keep HTML, Markdown, PDF structure, rasterization, and persistence in their
   owning packages.
5. Add integration only at the lowest owner that may depend on both sides.
6. Verify semantic output and, when layout matters, render and inspect the
   artifact.
7. Test escaping, Unicode, empty content, pagination, and failure paths relevant
   to the selected pipeline.

## Detailed rules

Load [`catalogue.md`](catalogue.md) for exact `[DOC-MARKUP-*]` requirements,
package selection, typed HTML patterns, PDF composition, Markdown rendering,
and artifact-verification procedures.

## Related skills

- **reuse-first** and **ecosystem-data-structures** for owner selection.
- **documentation** for DocC rather than generated documents.
- **modularization** for renderer or encoder boundaries.
