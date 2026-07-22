---
name: reflect-session
description: |
  Lightweight end-of-session note capture.
  Apply at the end of a non-trivial session, or mid-session on a significant learning.

layer: process
requires:
  - swift-institute
applies_to:
  - reflection
  - session
  - learning
---

# reflect-session

Jot what you learned. That's the whole discipline — the elaborate template, tagging,
indexing, and triage pipeline this skill used to mandate are gone (solo-dev ceremony cut,
2026-07-18).

## What to do

- Write a short dated note in `Research/Reflections/` (or the relevant repo's own
  `Reflections/` — legal work goes to `rule-law/Research/`, Dutch legislature to
  `swift-nl-wetgever/Research/`). A few sentences is fine. No fixed structure, no cap.
- If the learning is a **convention**, fix it in its owning skill directly (see the
  skill-routing map in the workspace instructions). If it is **deferred work**, record it
  in the project's tracked backlog. Swift Institute maintainers use
  `Internal/BACKLOG.md`; quick corrections go to `Internal/inbox.md`.

## Two habits worth keeping (they catch real bugs)

- **Re-grep after you edit.** After changing a file, confirm the change landed
  (`grep` the new text). An edit you didn't verify is a claim, not a fact.
- **Re-derive state claims from disk.** Before asserting "X references Y" or "N call
  sites", run the probe and read the output — don't report from memory or from a prior
  turn's number. A zero from a probe that errored or was mis-scoped is not a finding.
