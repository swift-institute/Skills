---
name: swift-forums-review
description: Pressure-test a Swift package or proposal against recurring Swift Forums critique patterns. Apply before a Forums announcement, public pitch, or major package launch.
---

# Swift Forums review

Use the corpus to expose likely objections, not to impersonate specific people
or replace real community review.

## Workflow

1. Define the artifact, intended venue, maturity, audience, and claims.
2. Characterize its ownership, API surface, dependencies, portability,
   performance posture, documentation, and migration cost from live source.
3. Select the critique angles most relevant to those facts.
4. Write the strongest technically grounded objection for each angle.
5. Classify each objection independently as load-bearing or
   archetype-shaped, and as verified, uncertain, or false-premise.
6. Verify factual premises against source, manifests, tests, benchmarks, and
   published documentation.
7. Turn verified load-bearing objections into fixes or explicit launch risks.
8. Keep predicted reception separate from correctness.

## Detailed corpus guidance

Load [`catalogue.md`](catalogue.md) for `[FREVIEW-*]` archetypes, angle
frequencies, venue and era adjustments, scoring, output formats, and corpus
methodology. Historical non-Swift corpus-maintenance commands are not the
current automation boundary.

## Related skills

- **release-readiness** for launch gates.
- **research-process** for verifying objections.
- **blog-process** and **swift-evolution** for the target communication.
