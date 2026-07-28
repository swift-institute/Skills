---
name: swift
description: How Swift is written across the Institute — namespaces and noun naming, one type per file, typed throws, intent-over-mechanism call sites, Byte-vs-UInt8 discipline, typed indices and conversions, data-structure selection, ownership and lifetime, unsafe containment, Span access, Sendable and isolation, and platform code placement. Apply whenever declaring a type, method, property, error, or file, writing implementation bodies, working at the byte or arithmetic boundary, converting between typed values, choosing a container, touching ~Copyable, ~Escapable, deinit, Span, raw pointers, @safe, Sendable, actors or Mutex, or placing platform code, conditionals, C imports, and package settings.
---

# Swift

This hub covers what any Swift file in the ecosystem needs. The specialized areas — bytes,
containers, ownership, unsafe memory, concurrency, platform code — are companions, listed at the
end.

## Namespaces and type names

All types use `Nest.Name`; compound type names are forbidden. `File.Directory.Walk`, not
`FileDirectoryWalk`. Each adjacent pair must read as "X is a kind of Y" or "X belongs to Y".

Depth is not a constraint in either direction: never flatten a semantically correct chain, and
never insert a filler level (`POSIX.Kernel.Types.IO.Read` — `Types` names no sub-domain). A
namespace containing exactly one type is a variant label, so nest it under its parent:
`Executor.Cooperative`; `Kernel.Thread.Executor.Polling`, not `Kernel.Thread.Polling.Executor`.

When a type sits at the intersection of two real domains and one is strictly larger, the larger
domain owns the namespace. The decision turns on whether the leading token is the **subject**
the operation processes ("parse the bytes" → `Byte.Parser`, `JSON.Coder`) or the **manner** in
which it behaves ("iterate borrowingly", "in chunks" → `Iterator.Borrow`, `Iterator.Chunk`).
Manner variants take the noun form, not the gerund.

Never reuse a subject's word as a manner word. The bulk iterator yields contiguous spans yet is
`Iterator.Chunk`, not `Iterator.Contiguous`, because `Contiguous` already names a memory subject
(`Storage.Contiguous`); `Borrow` is likewise reserved for the ownership tier. When a candidate
manner word could also name a subject (`Memory`, `Storage`, `Span`, `Contiguous`), pick a
different manner word rather than flipping to subject-first. Ownership direction confirms the
shape: role-owns depends *down* onto the mode, subject-first depends *up* onto the operation.

This is not "noun before verb" — `Parser.Builder` and `Buffer.Allocator` are correct. It fires
only when both tokens are domains in their own right.

Types implementing a specification mirror the spec's terminology under a spec namespace:
`RFC_4122.UUID`, `ISO_32000.Page` — never a bare `UUID` or `URL`. L2 Standards optimize for 1:1
spec encodings, so a deterministic transliteration of a spec-defined token is a spec-mirroring
name and the compound prohibitions do not apply; invented non-spec identifiers at L2 remain
non-conforming. When a domain-correct nested name shadows a stdlib type, keep the name and
disambiguate at the call site by module (`Base62_Primitives.String`).

Package and top-level namespace naming — the noun rule, the gerund typealias — belongs to the
`architecture` skill.

## Member names

Methods, properties, and enum cases must not be compound. Use nested accessors:
`dir.walk.files()`, `instance.open.write { }`. `fileprivate` / `private` declarations,
`is`-prefixed booleans, and spec-mirroring identifiers are exempt. Swift's ownership, effect,
and isolation keywords are never repurposed as identifiers. Two triggers deserve a re-check
before commit: an internal capital, and a name copied from the stdlib, an SE proposal, or
another language.

Choose between a nested accessor and a labeled method structurally. Two or more related
sub-operations under one root take a `Property.View` accessor (`remove.{first,last,all}`); one
operation disambiguated by labels takes a labeled method (`swap(at:with:)`). A `Property.View`
wrapper around a single method is ceremony. When a labeled method exists at the layer below,
match its name above.

A single-word removal op that can fail on empty returns `Optional` — `pop()`, not
`removeLast()`. Borrowing accessors are the carve-out: a `~Copyable` borrow of `Element?` is
structurally unavailable, so those keep crashing preconditions.

Drop a redundant prefix the namespace already supplies (`Manifest.Dependency.name`).
Phantom-type tags take the bare concept name — no `*Tag` suffix, no inner `.Tag`; the
surrounding namespace enum *is* the phantom. A phantom generic parameter — never stored, never
flowing through an operation — is bound `~Copyable & ~Escapable`. Widening is non-breaking;
relaxing a *stored* parameter is breaking, and the discriminator is whether any value of that
type is stored or passed through an operation. Relaxing a phantom forces companion edits:
conditional conformances restate the suppression, and a phantom associatedtype widens in step.

Local bindings use the type's own name or a domain word — `impl`, `obj`, `inst`, `instance` are
forbidden.

An `OptionSet` type is not named `Flags`, which is C-speak; a linter rule fires on that suffix
and only on that suffix. `Options` is the default choice and the one to reach for absent a
reason, but a domain word that names what the set *is* rather than that it is a bag of options
is in good standing and the corpus uses several — `Memory.Map.Access`,
`Terminal.Input.Key.Modifiers`, `Kernel.Event.Interest`. Nothing checks that half.

Typealiases must not be unification bridges — after unifying, call sites use the canonical type.
Generic-instantiation typealiases are sanctioned, and so is namespace adoption where the
adopting layer builds substantial domain behavior on the adopted concept; a typealias that
merely shortens a name is the forbidden form. Extensions resolve *through* typealiases, so "we
can't nest under X because it's a typealias" is false — write it and let the compiler answer.

## Files and type bodies

One type declaration per file; extensions do not count. The file name is the type's full nested
path with dots: `Array.Dynamic.Iterator.swift`. Extension-only files carry a `+` conformance
suffix (`Array.Dynamic+Sequence.swift`) or a where-clause discriminator matching the extension.
Tests, experiments, and examples are out of scope.

Type bodies hold only stored properties, the canonical initializer, and `deinit`; everything
else lives in extensions. `~Copyable` generic types may keep nested storage types in the body to
avoid constraint poisoning, and conditional conformances still go in the same file.
Result-builder enums, `Protocol`-sentinel hosts, and SwiftSyntax visitor subclasses satisfy the
rule as written.

Moving witnesses to extensions while leaving conformances on the struct declaration creates an
associatedtype inference cycle (`unsupported recursion for reference to type alias`) — put the
conformance on the extension and fully qualify storage types, keeping marker-only conformances
on the declaration. Inside `extension T: P` where `P` declares `associatedtype X`, a bare `X`
resolves to the conformer's binding, not to a same-named namespace elsewhere; fully
module-qualify any type whose name could collide (`Serializer`, `Parser`, `Coder`, `Body`,
`Output`, `Failure`).

When a protocol must appear as `Outer.Inner.Protocol` on a generic type, hoist it to module
scope and nest a `typealias Protocol`. Self-conformance must use the hoisted name — the
canonical path self-references and the compiler reports `circular reference`. Sibling conformers
and constraint sites use the canonical path. The hoist idiom is sanctioned for struct carriers
too.

`@retroactive` is scoped to the Swift *package*, not the module — a same-package conformance is
rejected with `'retroactive' attribute does not apply`, even across targets. An in-package
protocol refining an external one needs both clauses: `extension Int: X, @retroactive Y`.

Generic leaf conformers to `Parser.Protocol` / `Serializer.Protocol` / `Coder.Protocol` with no
delegating `body` must declare `public typealias Body = Never` explicitly, or witness-table
emission fails at link time with `Undefined symbols … protocol witness for body.getter`.

Element-vending and forwarding property and subscript surfaces use the `_read` / `_modify`
coroutine pair, never plain `get` / `set`, wherever the value may be `~Copyable` or a copy is
avoidable; properties returning `~Escapable` values use `borrowing get` plus `@_lifetime`.
Protocol *requirements* stay `{ get set }` and conformers witness them with coroutines. Do not
adopt the experimental unprefixed `read` / `modify` spelling.

Public stored value types in the storage tower are `@frozen` from birth; views, iterators, and
snapshots stay unfrozen until cross-module partial consumption is demonstrated.

A capability seam — a protocol minted so generic algorithms can range over a family — is a
deletable convenience. Canonical spellings stay concrete; existentials of the seam (`any X`) are
forbidden; the seam never becomes a product's public spelling. When minting one, mint the
canonical triple described in `architecture`, homed on the agent noun and never on the deverbal
noun.

## Errors

Every throwing function uses typed throws. `throws`, `throws(any Error)`, and `Self.Error` in a
`throws(...)` clause outside a protocol are forbidden. When a stored closure can throw
user-domain errors, make the containing type generic over the error type. Error types nest as
`Domain.Error` and conform to the explicitly qualified `Swift.Error`. Cases describe the failure
condition (`invalidHeader(expected:found:)`), never the recovery action.

Calling a stdlib `rethrows` function from a `throws(E)` context requires an explicit `throws(E)`
annotation on the closure — without it Swift infers `any Error`, and the diagnostic you get is
"thrown expression type 'any Error' cannot be converted to error type 'E'".

Only some stdlib `rethrows` functions preserve typed throws even then. On the toolchain in hand
at the time of writing, `map`, `filter`, `withUnsafeBytes(of:)`,
`withUnsafeMutableBytes(of:)`, and `Mutex.withLock` do; `compactMap`, `flatMap`, `forEach`,
`reduce`, `contains(where:)`, `allSatisfy`, `first(where:)`, `sorted(by:)`, `min(by:)`,
`max(by:)`, `drop(while:)`, and `prefix(while:)` do not. This membership changes as the stdlib
adopts typed throws, so treat the list as a starting point and settle a specific case with a
one-file `swiftc -typecheck` probe rather than from memory. Do not add `@_disfavoredOverload`
twins for the ones that work; for the rest, materialize a `Result<T, E>` inside the closure and
`try result.get()` outside.

**Untyped-callee boundary.** When the callee's error is untyped — a cross-module API such as
`FileManager.removeItem(at:)` or `try await task.value` — every form violates something: `try?`
fires the try-optional rule, a bare `do` / `catch` fires the typed-catch rule, `do throws(any
Error)` fires the existential rule, and `do throws(E)` does not compile. Keep the `try?` and add
`// swift-linter:disable:next try optional` with a `// REASON:` naming the untyped callee. No
lint rule can decide this; that is why the suppression exists rather than an exemption. When the
callee *is* typed, `do throws(E) { … } catch { }` is correct and `try?` is not.

Public `throws(...)` clauses name the public API path with explicit generic parameters, never a
`__`-prefixed hoisted internal. A shared lifecycle-error typealias is adopted only when every
case of the shared type is actually produced. Under typed throws, catch with the implicit
binding: `catch where error.isInterrupted`; writing `catch let error where …` erases to `any
Error`.

An error enum nested in a generic type whose parameter it never uses is accidentally generic:
the `@error` SIL result carries a type parameter and trips `FunctionSignatureOpts` under `-O
-enable-default-cmo`, aborting the release build of the package and of every consumer. Hoist the
enum to non-generic module scope and keep `typealias Error` on the generic type. The shape is
necessary but not sufficient — the crash also needs an eliminable argument, a SIL-level property
no syntactic check sees — so treat a finding as a candidate and confirm with a release build.

## Intent over mechanism

Every line reads as *what* is accomplished, never *how*. Intent is the domain operation —
initialize, move, insert, compare, iterate. Mechanism is offset computation, pointer arithmetic,
rawValue extraction, bitPattern conversion, manual index construction, and it belongs inside
operators, overloads, accessors, and boundary methods. When mechanism leaks into a call site,
the infrastructure is incomplete — improve the infrastructure.

Write the ideal expression first. If it does not compile, ask whether the absence is
*principled*. It is principled when the operation would violate a mathematical property: `count
- count` (subtraction on naturals is not total — `count.subtract.saturating(other)`), `index *
2` (scaling a position is meaningless), `bounded + .one` returning `Bounded<N>` (use
`successor()`). It is a gap when the operation preserves the types' properties: `count + .one`,
`slot < capacity`, a missing `Int` bridge on a valid pointer operation.

Express every invariant the type system can carry at compile time. Prefer single expressions to
intermediate bindings; extract named functions, not locals. Keep the execution model uniform at
a given structural level — never mix immediate and deferred. Iteration climbs the ladder: bulk
operation, then iteration infrastructure, then a typed `while`, never a raw counter loop. Push
`Int` to the edge.

Reach for ecosystem dependencies before ad-hoc implementations, and ask whether the component
needs to exist at all — the `composition` skill is the fuller version of that question.

When converting a protocol to a witness struct with stored closures, call sites lose argument
labels (`set(attribute:)` degrades to `setAttribute`) — add `@inlinable` labeled convenience
methods forwarding to the stored closures.

## Elsewhere

- `UInt8` vs `Byte`, the integer↔bytes codec, typed indices and conversions —
  [bytes-and-indices.md](bytes-and-indices.md).
- Container families, variant axes, the four-layer tower —
  [data-structures.md](data-structures.md).
- `~Copyable`, `~Escapable`, `deinit`, `consuming`, CoW construction —
  [ownership.md](ownership.md).
- `@safe` / `@unsafe`, raw pointers, the Span family — [unsafe-and-span.md](unsafe-and-span.md).
- `Sendable`, `@unchecked`, actors, `Mutex` — [concurrency.md](concurrency.md).
- Platform stack, kernel vocabulary, conditionals, platform C — [platform.md](platform.md).
- Tools-version pins, upcoming features, products, linking —
  [package-settings.md](package-settings.md).
