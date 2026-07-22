---
name: skill-lifecycle
description: |
  Create, edit, and retire skills.
  Apply when adding a new skill, changing an existing one, or removing one.

layer: process
requires:
  - swift-institute-core
applies_to:
  - skills
  - documentation
  - swift-institute
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
- Requirement IDs are `[PREFIX-NNN]`. Before assigning a new one, grep the skill to
  confirm the number is free.

## Creating a skill

1. Write `<name>/SKILL.md` with frontmatter (`name`, `description`, `layer`, `requires`).
   The `description` is what the harness shows each session — keep it one or two lines.
2. Add a public skill to `swift-institute-core/SKILL.md`; add a private operational skill to
   `Internal/Skills/README.md` instead.
3. Link the complete skill directory into the local harness's skill directory.

Machine-specific configuration, private control-plane paths, credentials operations, and
fleet-wide mutation workflows belong in `Internal/Skills`; reusable engineering conventions
belong here.

## Retiring a skill

Delete the directory and its symlink, and remove it from the `swift-institute-core`
index. If other skills referenced it, grep for the name and clean the references.
Git history preserves it.
