---
name: skill-lifecycle
description: Create, edit, validate, and retire Swift Institute skills. Apply whenever a skill is added, changed, split, renamed, or removed.
---

# skill-lifecycle

How to work on the skill corpus. The former apparatus — provenance mandates,
`last_reviewed` drift gates, additive/breaking classification, review cadences,
staged deprecation with retention windows — is gone (solo-dev ceremony cut,
2026-07-18). Git history is the record; the corpus is small enough to read.

## Editing a skill

- Edit reusable public skills under `swift-institute/Skills/<name>/`, private operational
  skills under `swift-institute/Internal/Skills/<name>/`, and legal skills under
  `rule-institute/Skills/<name>/`. Local harness entries are symlinks to those sources.
- Keep each skill focused and **prune rather than accrete** — a skill that only grows is
  the ceremony problem. Cut a stale rule when you see it; don't annotate it with dated
  history in the body (that's what git log is for).
- Keep `SKILL.md` at or below 500 lines. The Workspace context validator
  enforces this ceiling. Put optional, task-specific detail in a
  one-level `references/` directory and link each reference directly from the
  hub with an explicit loading condition.
- Keep frontmatter to `name` and `description`. Make the description state both
  the capability and its triggers; it is the routing surface.
- Requirement IDs are `[PREFIX-NNN]` or a stable semantic axiom such as
  `[MOD-OWNER]`. Before assigning one, grep the corpus to confirm it is free.

## Creating a skill

1. Write `<name>/SKILL.md` with `name` and `description` frontmatter. Keep the
   body procedural and omit knowledge a capable model already has.
2. Add a public skill to `swift-institute-core/SKILL.md`; add a private operational skill to
   `Internal/Skills/README.md` instead.
3. Run `workspace context install` from the Workspace package to project the
   canonical skill roots into the entry-point harness.
4. Run `workspace context check`; it parses every canonical skill through the
   Swift `Skill Validation` product before accepting the projection. Run any
   domain-owner tests affected by changed requirement IDs or enforcement.

Machine-specific configuration, private control-plane paths, credentials operations, and
fleet-wide mutation workflows belong in `Internal/Skills`; reusable engineering conventions
belong here.

## Retiring a skill

Delete the directory and remove it from the `swift-institute-core` index. Clean
all name and requirement-ID references, then run `workspace context install` to
reconcile generated links. Git history preserves it.
