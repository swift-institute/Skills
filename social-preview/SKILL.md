---
name: social-preview
description: Design, render, verify, and publish GitHub social preview cards from canonical repository metadata. Apply when adding a preview, changing the shared chassis, or defining an organization brand variant.
---

# Social preview

The repository metadata owns brand inputs; one shared renderer owns visual
mechanics. Do not fork a card template or encode organization branding in a
package repository.

## Workflow

1. Resolve repository visibility and read the canonical metadata.
2. Confirm the organization brand variant, title treatment, maturity, and
   output dimensions.
3. Reuse the shared chassis and renderer; add a brand variant centrally when
   the metadata cannot express it.
4. Render deterministically and inspect the actual image for clipping,
   contrast, glyph substitution, and small-size legibility.
5. Verify the output maps byte-for-byte to the current metadata inputs.
6. Treat GitHub upload as an external mutation requiring explicit scope and
   post-write verification.

All maintained rendering, validation, and upload automation must be Swift-owned.
Do not add or revive shell, Python, or Node orchestration.

## Detailed design rules

Load [`catalogue.md`](catalogue.md) for `[SOC-*]` chassis, typography, layout,
brand metadata, visual QA, and historical migration context. Commands for
retired non-Swift helpers in that catalogue are not current procedure.

## Related skills

- **github-repository** for visibility and metadata.
- **ci-cd-workflows** for centralized deterministic rendering.
- **document-markup** for typed rendering composition.
