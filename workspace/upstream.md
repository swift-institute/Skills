# Upstream Swift

Companion to the `workspace` skill. Read this before opening a pull request
against `swiftlang/swift`, drafting a Swift Evolution pitch, or preparing a
public launch for Forums review.

## Pull requests to swiftlang/swift

Fork and push to the fork. Direct push needs commit access, which is granted
after several accepted non-trivial PRs.

```bash
gh repo fork swiftlang/swift --clone=false
git remote add myfork https://github.com/{username}/swift.git
```

Target `main`; release branches need branch-manager approval.

Commit subjects carry a component tag — `[SILOptimizer]`, `[Sema]`, `[SILGen]`,
`[IRGen]`, `[AST]`, `[SIL]`, `[stdlib]`, `[test]`, `[Embedded]`, or the colon
form (`IRGen:`) — and `NFC:` for no-functional-change work.

New source files carry the Apache 2.0 + Runtime Library Exception header; test
files under `test/` do not. No CLA or DCO is required.

Reference issues by GitHub URL, never `rdar://`, which is Apple-internal and
resolves for nobody reviewing. Never use `Resolves` on an upstream PR. Disclose
AI assistance in the PR body when any part of the change was AI-assisted, and
replace the default HTML comment template rather than leaving it in place.

### Every bug fix ships a test

At the abstraction level nearest the change: `.sil` tests under
`test/SILOptimizer/` via `sil-opt` + FileCheck, `test/SILGen/` via
`-emit-silgen`, `test/Sema/` via `-typecheck`, `test/IRGen/` via `-emit-ir`,
`test/Interpreter/` for end-to-end behavior.

Gate with `// REQUIRES: swift_in_compiler` and `// REQUIRES: swift_feature_X`.
Use `-enable-experimental-feature Lifetimes` for `~Escapable` types,
`-disable-availability-checking` when the test uses features gated on newer
deployment targets — without it `llvm-lit` fails against an older macOS target —
and `-sil-print-types` to make types visible to FileCheck.

Run tests through llvm-lit before pushing, since it honors `REQUIRES:` and a
direct invocation does not:

```bash
llvm-lit -sv test/SILOptimizer/your_test.sil
llvm-lit -sv test/SILOptimizer/lifetime_dependence/
```

### Review

CODEOWNERS auto-assigns reviewers on non-draft PRs. CI runs from a PR comment
(`@swift-ci Please smoke test`, `@swift-ci Please test`, `@swift-ci Please
benchmark`); contributors without commit access cannot trigger it and must ask a
reviewer to.

Address feedback with follow-up commits — never force-push, which discards the
review context reviewers are reading against. If asked to split a PR, close it
with an explanatory comment and open focused replacements rather than rewriting
history.

## Swift Evolution pitches

- https://github.com/swiftlang/swift-evolution/blob/main/process.md
- https://github.com/swiftlang/swift-evolution/blob/main/commonly_proposed.md
- https://forums.swift.org/c/evolution/pitches/18

Check `commonly_proposed.md` before drafting. Those ideas have been extensively
debated, and revisiting one requires substantial new evidence rather than a fresh
argument.

A pitch gives the problem and a general solution direction. A proposal gives a
complete specification with detailed design and full compatibility analysis, and
a language change needs an implementation. Do not write proposal-weight content
for a pitch — it invites review of a design that has not yet earned the
discussion.

## Pre-launch Forums review

Before a Forums announcement or public launch, pressure-test the artifact against
the recurring critique patterns in the Forums corpus. Verify each objection's
factual premises against source, manifests, tests, and benchmarks, and turn the
verified load-bearing ones into fixes or explicit launch risks.

Keep predicted reception separate from correctness. They answer different
questions and mixing them lets a popular objection outrank a true one.

Simulated threads are INTERNAL artifacts. Never suggest posting simulated content
to forums.swift.org, Bluesky, Discord, or anywhere else — treat simulated posts
as draft-only, and give handles in simulated threads a non-identifying form such
as `@reviewer-<cluster-id>`.
