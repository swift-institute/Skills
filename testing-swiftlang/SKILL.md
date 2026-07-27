---
name: testing-swiftlang
description: Use Apple Swift Testing for suites, behavior names, async code, noncopyable values, macros, and model tests. Apply whenever tests import Testing.
---

# Swift Testing

Use **testing** for boundary and support-infrastructure decisions. This skill
owns the framework-facing choices. Load `catalogue.md` only when a task needs
the complete `[SWIFT-TEST-*]` patterns and examples.

## Core form

### [SWIFT-TEST-SUITE] Organize by behavior and scope

Nest suites only when the nesting communicates a real subject, state, or test
category. Avoid deep mechanical nesting: macro-generated symbol length and
diagnostics degrade before the organization earns its cost.

### [SWIFT-TEST-NAME] Write test names as behavior

An `@Test` name states the condition and expected behavior in readable words.
Do not repeat the suite or type name merely to imitate an XCTest method.

### [SWIFT-TEST-ASSERT] Keep observation at the failure site

Bind values explicitly when that makes ownership, async suspension, or failure
location clearer. Use `#expect` for ordinary predicates and `#require` when
later assertions require a value or condition.

### [SWIFT-TEST-NONCOPYABLE] Observe noncopyable values without forcing copies

Choose an observable property before consuming or borrowing a `~Copyable`
value. Helpers state their ownership convention and return copyable evidence
when the value itself cannot cross the assertion boundary safely.

Do not add copyability to production APIs solely to satisfy a test macro.

### [SWIFT-TEST-ASYNC] Make suspension and isolation visible

Await the operation under test directly and use deterministic coordination
instead of sleeps. Test cancellation, completion, and error paths separately.
Keep mutable shared state behind an actor or an existing test harness.

### [SWIFT-TEST-MODEL] Compare state machines with a simpler model

For collections, parsers, buffers, or stateful systems, drive both the subject
and a simple reference model through the same operation sequence. Compare
observable state after each transition so the first divergence is local.

### [SWIFT-TEST-MACRO] Keep macro helpers generic and framework-native

Reusable macro test helpers use Swift Testing and the existing macro support
product. Do not introduce XCTest or Foundation merely for fixture convenience.
When a macro emits a confusing lexical-context diagnostic, first type-check the
test body without the macro; see **issue-investigation**.

## Verification

Run the smallest useful filter while iterating, then the affected package
fresh when reporting completion:

```sh
workspace package test \
  --argument=--filter --argument "Behavior"
workspace package test --fresh
```
