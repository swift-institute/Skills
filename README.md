# Skills

Development conventions for the [Swift Institute](https://swift-institute.org) ecosystem — naming, errors, memory safety, testing, modularization, and more. Each skill is the one place its area is written down.

Skills are lightweight guides, not a register of every known practice. They are written to be loaded by an agent when the work calls for them, and they carry judgment where judgment is what the situation needs; humans can read them directly.

This public repository contains reusable engineering and project conventions. Machine-specific
navigation wiring and fleet-wide repository mutation workflows are intentionally excluded from
the public corpus.

## Structure

Each subdirectory is one skill. Its `SKILL.md` is the hub: what you need to route
correctly, decide, and know that a hazard exists. Material that only some readers
need on only some tasks lives in a companion document the hub links, so it loads
when it is wanted and costs nothing when it is not.

Companions carry prose, not a rule register. Naming a behaviour is what makes a
skill usable by a reader who has never seen the internal numbering; internal rule
IDs are not published here, and CI rejects them.

### Where enforcement stops

Some of what these skills ask for is checked by a machine and some is not, and the
two read identically on the page unless a skill says which is which. Where a rule
divides that way, the skill says so: what a predicate settles, and what is left to
the person writing the code. An unenforced rule is still the rule — saying it is
unenforced is a statement about who decides, not a softening of the guidance.

## Loading

`swift-institute/Workspace` owns installation for the shared checkout:

```sh
workspace context install
workspace context check
```

The installer parses each canonical `SKILL.md` and projects whole skill
directories into the common Claude/Codex entry point, so linked companions ride
along with their hub. Skills use only `name` and `description` frontmatter — the
installer rejects any other field. The description is the routing interface: it
is loaded whether or not the skill is used, which is what makes it worth writing
carefully and worth keeping the body out of.

Two gates run against this corpus, and neither has an opinion about the writing:

- **Publication hygiene, in CI.** Frontmatter parses; `name` and `description`
  are present and `name` matches its directory; every relative link resolves; no
  machine-local path and no internal rule ID reaches a public file; an empty
  corpus fails closed rather than reading as a clean scan.
- **Loadability, in the Workspace installer.** The frontmatter parses under the
  installer's own stricter reader, and the document is small enough for it to
  accept. Companions are projected but not parsed, so a hub that has grown past
  the installer is a hub with a companion waiting to be split out of it.

Swift Institute maintainers also project private operational skills from
`Internal/Skills` through the same owner.

## Companion repositories

| Repository | Contents |
|------------|----------|
| [swift-institute/swift-institute.org](https://github.com/swift-institute/swift-institute.org) | Website + DocC catalog |
| [swift-institute/Research](https://github.com/swift-institute/Research) | Design rationale and trade-off analysis |
| [swift-institute/Experiments](https://github.com/swift-institute/Experiments) | Standalone Swift packages backing technical claims |
| [swift-institute/Workspace](https://github.com/swift-institute/Workspace) | Inventory, context installation, and Swift-owned workspace tooling |

## License

[Apache 2.0](LICENSE.md).
