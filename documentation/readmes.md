# READMEs

Companion to the `documentation` skill. Read this when writing or reviewing a
README.

## Family first

Every README belongs to exactly one family, and the family fixes the audience,
the voice, and the required structure. Resolve a repository's family from
`readme.family` in its canonical repository metadata rather than guessing from
the path — the centralized Swift repository-policy validator reads the same
field, so guessing puts you and the check on different rules.

| Family | Path | Reader |
|---|---|---|
| User profile | `<user>/<user>/README.md` | visitors to a person's GitHub page |
| Process / workflow repo | `<repo>/README.md` | maintainers running the workflow |
| Sub-package library | `<repo>/README.md` | evaluators deciding whether to adopt |
| Placeholder / scaffold | `<repo>/README.md` | anyone landing on a stub |
| Org profile | `<org>/.github/profile/README.md` | visitors to the organization page |

Every paragraph answers the family's evaluation question. Ecosystem-positioning
("this is Layer 1 of…"), extraction backstory, design reflections, and pre-tag
process residue are author-oriented — they belong in `Research/`, DocC, or a
post.

Coverage runs the other way, though, and is not optional: name every user-facing
entry point — each CLI subcommand, each top-level product — at least once, with
its purpose. Depth may vary; presence may not. A reader must not have to read
the source or run `--help` to discover that a capability exists. Ask the same
coverage question of `CLAUDE.md` / `AGENTS.md`, checking whether they are
symlinked before counting them as two surfaces.

A public README is a public contract. Never put a maintainer's home-directory
path or a hand-maintained clone layout in one — expose an explicit option and
document its default instead.

## Sub-package structure scales with maturity

- **Minimum, always** — title, one-liner, `## Installation`, `## License`.
- **Standard, once there is a public API** — plus Key Features, Quick Start,
  Architecture.
- **Complete, at v1.0 or with external users** — plus Error Handling, Related
  Packages.

Placeholder READMEs carry a title, a one-line scope, and a status from exactly
`Pre-implementation`, `Namespace-reservation`, `Unnecessary`, `Archived`. The
validator rejects any other status value, and rejects any `##` section other than
`## License`.

The `## Installation` block carries both a dependency clause and a target clause,
and the pin form matches reality: a branch pin before the package has any tag, a
`from:` tag pin only once that tag exists. A pre-tag README pinning `from:
"0.1.0"` fails resolution for every reader who copies it — which is every reader
the block exists for.

## Org profiles

No installation block. Past the point where a link-wall stops being readable, an
org profile must not enumerate packages: a names-only list is strictly less
informative than GitHub's Repositories tab and goes stale on every rename. Route
into the native tab with one filter link per domain,
`https://github.com/orgs/<org>/repositories?q=<term>`, above a short curated
"Start here" table spanning the org's capability dimensions.

## Where the check and the text disagree

The general form is worth carrying: where a check's condition is narrower than
the rule it is named for, a finding asserts only the narrow condition. Read what
fired, not what it was named after.
