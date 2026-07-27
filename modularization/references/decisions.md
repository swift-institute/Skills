# Boundary decisions

Use this reference for architecture changes. Work from the semantic owner
outward; do not begin from the desired number of modules.

## Package

Create or retain a package when it has a coherent ecosystem identity and at
least one package-level reason:

- independent dependency closure;
- independent release or versioning boundary;
- distinct repository, authority, or standards ownership;
- reuse without importing an unrelated package surface;
- cycle-breaking placement at a lower lawful owner.

Keep capabilities in one package when they share ownership, release, and
dependency closure. A second related capability does not automatically require
a second package. Conversely, a single capability may require its own package
when its dependency or ownership boundary is independent.

Reject package changes justified only by file count, target count, current
consumer count, aesthetic symmetry, or a noun that can be coined.

## Product

Publish a product only when it represents a supported consumer choice. A
product may expose one target or a deliberate composition of targets.

Use:

- a narrow product when consumers should opt into a capability independently;
- an umbrella product when “the complete supported surface” is itself a stable
  consumer choice;
- no product for implementation-only, namespace-root, macro-support, or other
  internal targets.

Do not publish every target automatically. Product count expresses supported
adoption paths, not implementation structure.

## Target

Create a target when a compile-time or dependency boundary is valuable:

- consumers can avoid a dependency or platform requirement;
- an optional capability or conformance can be selected independently;
- incompatible generic, ownership, or platform constraints must be isolated;
- parallel compilation or incremental invalidation materially improves;
- a lower-level capability needs an importable owner.

Keep declarations together when they require the same dependency closure,
cannot form useful independent imports, or need package-internal implementation
access that a split would merely route through SPI.

Neither “one target per type” nor “few targets” is a goal. A namespace often
suggests a capability boundary, but spelling alone is not evidence.

## File

Use a file as the smallest review and declaration unit. Prefer one primary
type, conformance, or tightly coupled extension concern per file. Split a file
for navigability and ownership clarity without inventing a target.

A file boundary has no dependency semantics. Do not turn a file split into a
target split unless the target criteria independently hold.

## Integration ownership

For a capability involving owners `A` and `B`:

1. If one owner may lawfully depend on the other, put the extension or
   conformance in that owner or an optional target it owns.
2. If the language can express conditional integration through an existing
   trait without a reverse dependency, use that composition.
3. If neither owner may depend on the other, place integration at the lowest
   layer or package that may depend on both.
4. Create a separate integration package only when it is an independently
   consumable dependency boundary, not as an automatic response to two owners.

Never duplicate either owner's vocabulary in the integration site.

For repository/CI integration, the Institute control plane is an owner:
repository-policy defines admissible structure, centralized workflows own
shared execution, and `swift-institute-bot` owns fleet convergence. A
package-local workflow/action boundary requires an explicit typed whitelist
grant in addition to the target/product criteria above.

## Layer placement

Place a capability at the lowest layer that both owns its semantic axis and can
enforce its invariants:

- L1 primitives: layer-agnostic vocabulary and lawful operations;
- L2 standards: specification-defined vocabulary and behavior;
- L3 foundations: composition across primitives and standards.

Decompose a multi-axis bundle before placement. Do not push a concern below the
layer able to enforce it, and do not leave a layer-agnostic capability stranded
above its owner.

## Decision comparison

For each proposed shape, compare:

| Question | Evidence |
|---|---|
| Who owns the law? | Definitions, invariants, specification or domain |
| What can consumers choose? | Actual supported import and product paths |
| What dependencies disappear? | Before/after package and target graph |
| What must compile together? | Imports, constraints, package access, macros |
| What releases together? | Repository and versioning policy |
| Where does integration belong? | Lowest legal common owner |
| What becomes mechanically enforceable? | Linter, validator, compiler, CI |

Choose the smallest graph that preserves every real boundary, not the graph
with the fewest or most nodes.
