# Skills

Canonical development conventions for the [Swift Institute](https://swift-institute.org) ecosystem — naming, errors, memory safety, testing, modularization, and more. Each skill is the canonical source for its area.

Skills are written to be loaded by AI agents as normative references during development; humans can read them directly as specifications.

This public repository contains reusable engineering and project conventions. Machine-specific
navigation wiring and fleet-wide repository mutation workflows are intentionally excluded from
the public corpus.

## Structure

Each subdirectory is one skill. Every skill has a `SKILL.md` file at its root that contains the requirement IDs and rules for its area. Some skills also include supporting examples and reference documents.

## Loading

Link or install the desired skill directory into the skill directory used by your agent. Keep
the directory intact so any companion references beside `SKILL.md` remain available. Swift
Institute maintainers load additional private operational skills from `Internal/Skills`.

## Companion repositories

| Repository | Contents |
|------------|----------|
| [swift-institute/swift-institute.org](https://github.com/swift-institute/swift-institute.org) | Website + DocC catalog |
| [swift-institute/Research](https://github.com/swift-institute/Research) | Design rationale and trade-off analysis |
| [swift-institute/Experiments](https://github.com/swift-institute/Experiments) | Standalone Swift packages backing technical claims |
| [swift-institute/Scripts](https://github.com/swift-institute/Scripts) | Workspace tooling |

## License

[Apache 2.0](LICENSE.md).
