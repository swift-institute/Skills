---
name: swift-linter
description: Create, validate, graduate, bundle, consume, and centrally enforce swift-linter rules. Apply when a convention is mechanically recognizable or lint configuration changes.
---

# Swift linter

Move deterministic enforcement out of prose. Skills explain why and guide
judgment; swift-linter recognizes source patterns, emits actionable diagnostics,
and prevents recurrence through centralized CI.

## Rules

### [LINT-OWNER] One mechanical owner

Every mechanically recognizable convention has one executable owner:

- swift-linter for Swift syntax and AST semantics;
- Workspace validators for checkout, package, and cross-package graph facts;
- repository-policy for GitHub repository files, settings, Actions, and
  cross-repository policy;
- centralized CI for execution and fleet rollout.

Do not restate an executable predicate as a second prose algorithm.

### [LINT-PREDICATE] Specify the predicate before implementing

Define:

- exact syntax or graph matched;
- semantic convention represented;
- known false-positive shapes;
- known false-negative shapes;
- diagnostic location and message;
- canonical fix or review action;
- allowed exemptions.

A partial detector names the slice it proves. It never claims full semantic
conformance.

### [LINT-FIXTURE] Fixtures are the rule contract

Ship positive, negative, and edge fixtures with every rule. Include legitimate
owner implementations, generated code, tests, platform branches, generic and
ownership variants, and any exemption shape the predicate can encounter.

### [LINT-EXEMPTION] Exemptions are typed and local

Design exclusions from **rule-exemptions** before broadening the predicate.
Suppress only the smallest finding with a reason that identifies the legitimate
shape. Never evade a detector through equivalent spelling.

### [LINT-SEVERITY] Severity follows measured evidence

Use warning while the predicate is incomplete or the ecosystem has legitimate
unresolved findings. Graduate canonically to error only after:

1. the predicate and fixtures cover the intended surface;
2. a fresh ecosystem run scans Sources and Tests across every applicable
   package root;
3. the rule's unsuppressed violation count is zero;
4. the same run and scope are reproducible in centralized CI.

Never create package-local severity overrides. Fix the predicate before
measuring its zero.

### [LINT-BUNDLE] Bundles define policy by layer

Activate one bundle matching the consumer layer. Bundles compose rule policy;
consumers do not enumerate bundled rules again. Per-rule exclusions exist only
for legitimate owner boundaries and require local rationale.

### [LINT-CONSUMER] Keep the consumer surface minimal

Use root `Lint.swift` for bundle activation, dependencies, parameters, and
exclusions. Use a nested `Lint/` Swift package only when the consumer defines
custom Swift rules or requires dependencies the single-file runner cannot
express. Keep all configuration in Swift.

### [LINT-CI] Central CI executes the canonical rule set

The universal reusable workflow runs swift-linter for every package; layer
wrappers add only layer-specific checks. A rule is not enforced ecosystem-wide
until its bundle membership, binary delivery, CI execution, and gating severity
are all canonical.

## Rule-authoring workflow

1. Cite the skill judgment or repeated defect that motivates mechanization.
2. Search existing rules and bundles; extend the existing owner when possible.
3. Write the predicate and exemption table before code.
4. Implement source rules in SwiftSyntax-backed swift-linter rule packages.
   Keep checkout/package graph checks in typed Workspace validation and GitHub
   repository/Actions checks in repository-policy.
5. Add positive, negative, edge, exemption, and self-firing fixtures.
6. Run focused rule tests.
7. Run a fresh ecosystem measurement over Sources and Tests with explicit
   package-root inventory and non-zero controls.
8. Fix the predicate, then fix real findings.
9. Set canonical severity using [LINT-SEVERITY].
10. Add the rule once to its layer bundle and verify consumer inheritance.
11. Verify centralized CI invokes the exact built rule set.
12. Remove the duplicated mechanical prose; retain only judgment and the link
    to the executable owner.

## Consumer shape

The default root file begins with:

```swift
// swift-linter-tools-version: 0.1

import Linter
import Linter_Institute_Rules

Lint.run(dependencies: [
    .package(
        path: "../swift-institute-linter-rules",
        products: ["Linter Institute Rules"]
    ),
]) {
    Lint.Rule.Bundle.institute
}
```

Select the layer bundle:

| Consumer | Bundle |
|---|---|
| L1 primitives | `Lint.Rule.Bundle.primitives` |
| L2 standards | `Lint.Rule.Bundle.standards` |
| L3 foundations | `Lint.Rule.Bundle.institute` |
| non-Institute/general | `Lint.Rule.Bundle.universal` |

Import a leaf rule module when `Lint.swift` names that rule directly. Use
`.excluding(rules:)` only for a legitimate brand-owner or equivalent typed
exemption; comment every exclusion.

## Verification record

Record:

- executable owner and rule ID;
- predicate and fixture matrix;
- rule package and bundle;
- applicable package roots;
- Sources and Tests counts;
- exemptions and reasons;
- canonical severity and graduation evidence;
- local rule tests;
- centralized CI invocation and outcome.

## Related skills

- **rule-exemptions** for predicate and suppression shapes.
- **ci-cd-workflows** for centralized execution.
- **github-repository** for repository-policy and bot convergence.
- **swift-package-build** for local lint invocation.
- **modularization** when a rule exposes an ownership or dependency defect.
- the motivating domain skill for the semantic judgment.
