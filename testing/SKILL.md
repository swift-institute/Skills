---
name: testing
description: Route Swift Institute test design, organization, support infrastructure, and verification. Always apply when writing, restructuring, or reviewing tests.
---

# Testing

Start with the behavior that must be observed, then choose the smallest test
boundary that can observe it without recreating production logic.

## Route

| Active work | Load |
| --- | --- |
| Swift Testing suites, names, async, model tests, noncopyable values | **testing-swiftlang** |
| snapshot tests or isolated test-only dependencies | **testing-institute** |
| performance measurement | **benchmark** |
| compiler or toolchain failure | **issue-investigation** |
| package/product/target decomposition | **modularization** |
| detailed support-target and fixture catalogue | `catalogue.md` |

Load `catalogue.md` only when the task needs one of its specific rules. It owns
the full `[TEST-*]` catalogue, including test-support layering, target
declarations, fixture factories, concurrency gates, and special test forms.

## Decision order

### [TEST-INTENT] Test the public behavior

Name the invariant, input space, observable result, and failure signal before
choosing a fixture. Test through the narrowest public or package interface that
expresses the behavior. Do not couple a test to incidental implementation
steps unless those steps are the contract.

### [TEST-LAW] Prefer laws and models over repeated examples

For a family of operations, encode the shared law once and vary data,
strategies, or implementations. Keep at least one non-default state that can
expose addressing, ordering, ownership, and constraint bugs.

### [TEST-BOUNDARY] Match the production boundary

A same-file or same-target test cannot prove a cross-module claim. Add the
module, package, optimization, platform, or process boundary on which the
behavior depends. Conversely, do not create a nested package when an ordinary
test target owns the dependency graph cleanly.

### [TEST-SUPPORT] Reuse test infrastructure by semantic owner

Search existing test-support products before adding literals, factories,
temporary-resource helpers, dependency overrides, or concurrency harnesses.
Reusable helpers live with the lowest layer that can own them; package-specific
fixtures stay local.

Test support may depend on production products. Production products never
depend on test support.

### [TEST-FRESH] Evidence is freshly compiled

Use `workspace package test --fresh` for a reported correctness, migration,
release, or audit claim. Add meaningful forwarded arguments explicitly:

```sh
workspace package test --fresh \
  --argument=--filter --argument "Suite or test"
```

A filtered run proves only that filter. A cached green is not evidence for a
fresh-build claim.

### [TEST-MECHANICAL] Let tooling own deterministic conventions

File naming, forbidden imports, target dependency direction, and other
source/manifest predicates belong in swift-linter or the package-analysis
owner with fixtures. This skill retains the design reason and exemption
judgment, not a copy of the implementation.

## Review checklist

- Does the test name state behavior and conditions?
- Does at least one case exercise a state that can falsify the implementation?
- Does the test boundary match the claim?
- Is support infrastructure reused from its semantic owner?
- Are concurrency, ownership, and resource lifetime explicit?
- Does the verification command measure the scope being reported?
