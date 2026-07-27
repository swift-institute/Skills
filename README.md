# Skills

Canonical development conventions for the [Swift Institute](https://swift-institute.org) ecosystem — naming, errors, memory safety, testing, modularization, and more. Each skill is the canonical source for its area.

Skills are written to be loaded by AI agents as normative references during development; humans can read them directly as specifications.

This public repository contains reusable engineering and project conventions. Machine-specific
navigation wiring and fleet-wide repository mutation workflows are intentionally excluded from
the public corpus.

## Structure

Each subdirectory is one skill. Its `SKILL.md` is a compact routing and workflow
hub; detailed requirement IDs, examples, and edge cases may live in directly
linked companion documents.

## Loading

`swift-institute/Workspace` owns installation for the shared checkout:

```sh
workspace context install
workspace context check
```

The installer validates each canonical `SKILL.md` and projects whole skill
directories into the common Claude/Codex entry point, preserving companion
references. Skills use only `name` and `description` frontmatter; the
description is the routing interface, and detailed material is loaded
progressively from the body or an explicitly linked companion. The Swift
validator rejects hubs over 500 lines so context-budget discipline is
mechanical rather than advisory.

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
