---
name: rule-exemptions
description: Select and implement legitimate exemption shapes for swift-linter rules. Apply when a mechanical rule intersects an intentional Institute, generated, test, platform, or standard-library pattern.
---

# Rule exemptions

An exemption narrows a detector around a lawful shape. It is not a way to keep
the prohibited behavior under different spelling.

## Workflow

1. Reproduce the finding on the smallest source fixture.
2. Decide whether the source is actually lawful under the motivating semantic
   rule.
3. Identify the narrowest stable property that distinguishes the lawful shape.
4. Search the existing exemption catalogue and rule implementation before
   inventing another mechanism.
5. Encode the exemption in the rule’s Swift predicate, not in ad-hoc consumer
   configuration.
6. Add a positive violation fixture, an exempt fixture, and a near-miss fixture
   that must still fire.
7. Keep diagnostic scope and any source suppression as local as possible.
8. Rerun the focused rule tests and a representative ecosystem measurement.

## Detailed shapes

Load [`catalogue.md`](catalogue.md) to select an exact `[RULE-EXEMPT-*]` shape
or when changing an existing exemption’s firing boundary.

## Related skills

- **swift-linter** owns predicate, fixture, bundle, and severity policy.
- The motivating domain skill decides whether the source is semantically
  lawful.
