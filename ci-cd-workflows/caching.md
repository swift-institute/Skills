# CI caching and generated state

Load this reference when changing SwiftPM caches, tool distribution,
`Package.resolved`, `.gitignore`, or package-local formatter/linter settings.

### [CI-040] Do not cache ordinary SwiftPM build state

Ordinary package jobs must not cache `.build`. Institute packages follow branch
dependencies and do not commit `Package.resolved`, so an apparently plausible
cache key cannot prove it represents the resolved graph.

An explicitly owned specialized job may earn a narrow carve-out only when it
defines an exact complete key, has no partial fallback, and carries fixtures
that prove stale state cannot be selected. The existing L1 Embedded job is the
only such carve-out.

### [CI-041] Treat `Package.resolved` as generated state

Library repositories ignore `Package.resolved`. Workflows must not commit,
edit, copy, inspect individual pins as policy, or delete it to force movement.
Change `Package.swift` and resolve through the Swift-owned package interface.

The repository-policy Swift product owns the repository-level generated-state
predicate; package-analysis owners handle manifest semantics. Central CI
invokes them rather than propagating files.

### [CI-042] Cache keys do not fall back by prefix

`restore-keys` is forbidden for every `actions/cache` use. A cache either
matches the complete key or misses. Partial matches make provenance ambiguous.

### [CI-043] Central policy validates; the bot converges typed changes

Repository-policy owns required structural `.gitignore` entries. Package
repositories may add their own ignores. Do not synchronize whole files from a
template. When a deterministic repair is safe and authorized,
`swift-institute-bot` applies the minimal typed change through the repository's
normal review/commit path and records the receipt.

### [CI-044] Immutable tool binaries may use exact caches

A released tool binary may be cached by an exact key containing its immutable
version and platform. The install path must still verify the downloaded digest.
Main-tracking tools do not qualify: their inputs move without a version change.

### [CI-116] Main-tracking linter binaries are built once

The swift-linter owner publishes CI binaries and a digest manifest from the
same Swift/container contract used by consumers. Central CI downloads and
verifies those artifacts. It must not compile or cache a separate linter in
every consumer repository.

A missing or invalid artifact may fall back to the same Swift source owner, but
never to a different predicate. The manifest records engine and rule-pack
revisions so a result is attributable.

### [CI-057] Formatter and linter configuration remains package-local

`.swift-format` and `.swiftlint.yml` are package-owned configuration. Different
domains may choose different stylistic settings and exemptions.

This autonomy does not extend to Institute semantic rules. swift-linter bundles
and centralized CI decide those mechanically; a package-local configuration
may select an approved bundle or documented exemption, not redefine the
predicate.

## Review checklist

- no ordinary `.build` cache;
- no `restore-keys`;
- every binary download is digest-verified;
- immutable version/platform is part of a permitted cache key;
- no tracked `Package.resolved`;
- no template propagation or repository-sweep script;
- package-local style does not disable centralized semantic rules.
