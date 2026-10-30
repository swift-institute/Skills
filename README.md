# Skills

How the [Swift Institute](https://swift-institute.org) ecosystem is built. The corpus is one
skill, [`institute`](institute/SKILL.md): the architecture (layers, organizations, dependency
direction, Foundation-freedom, package naming) and the local workflow and evidence standard.

A rule a machine can check (CI, a linter, a compiler setting) is not written here; it lives in
that check. How to write Swift is not written here either. The skill holds only what remains:
the architecture and the judgment a check cannot express.

This public repository contains reusable engineering and project conventions. Machine-specific
wiring and fleet-wide repository mutation workflows are intentionally excluded.

## Loading

On Coen's machine, the dotfiles bootstrap links each skill directory into
`~/.claude/skills`. Skills use only
`name` and `description` frontmatter. The description is the routing interface: it
is loaded whether or not the skill is used, which is what makes it worth writing
carefully and worth keeping the body out of.

Two gates run against this corpus, and neither has an opinion about the writing:

- **Publication hygiene, in CI.** Frontmatter parses; `name` and `description`
  are present and `name` matches its directory; every relative link resolves; no
  machine-local path and no internal rule ID reaches a public file; an empty
  corpus fails closed rather than reading as a clean scan.
- **Loadability, in the Institute installer.** The frontmatter parses under the
  installer's own stricter reader, and the document is small enough for it to
  accept.

Swift Institute maintainers also project private operational skills from
`Internal/Skills` through the same owner.

## Companion repositories

| Repository | Contents |
|------------|----------|
| [swift-institute/swift-institute.org](https://github.com/swift-institute/swift-institute.org) | Website + DocC catalog |
| [swift-institute/Research](https://github.com/swift-institute/Research) | Design rationale and trade-off analysis |
| [swift-institute/Experiments](https://github.com/swift-institute/Experiments) | Standalone Swift packages backing technical claims |
| [swift-institute/institute](https://github.com/swift-institute/institute) | The `institute` command: the central CI planner and organization policy |

## License

[Apache 2.0](LICENSE.md).
