# Property Accessors and Static Method Architecture

Part of the **implementation** skill. Full text of the `Property` / `Property.View` accessor rules, the static method architecture for types with `~Copyable` generic parameters, and the scope-resolution rules for extension extraction. For the foundational axioms ([IMPL-INTENT], [IMPL-000], [IMPL-001], [IMPL-COMPILE]) and the rule index, see `SKILL.md`.

**Rules in this file**: [IMPL-020], [IMPL-021], [IMPL-022], [IMPL-023], [IMPL-024], [IMPL-025], [IMPL-026], [IMPL-079], [IMPL-081], [IMPL-082], [IMPL-100].

---

## Property Accessors

### [IMPL-020] Verb-as-Property with callAsFunction

**Statement**: When a type has a verb-like operation namespace, express it as a property returning `Property<Tag, Base>` with `callAsFunction` for the direct operation and named methods for qualified variants.

```swift
heap.initialize(to: element, at: slot)     // callAsFunction — direct
heap.initialize.next(to: element)          // named method — tracked
heap.move(at: slot)                        // callAsFunction — direct
heap.move.last()                           // named method — tracked
heap.deinitialize(at: slot)                // callAsFunction — direct
heap.deinitialize.all()                    // named method — tracked
```

Tag types are empty enums. Methods are extensions on `Property` constrained by `where Tag == ..., Base == ...`. See [INFRA-106].

**Cross-references**: [API-NAME-002], [INFRA-106]

---

### [IMPL-021] Property vs Property.View

**Statement**: Use `Property<Tag, Base>` for Copyable bases (owned access). Use `Property<Tag, Base>.View` for `~Copyable` bases (pointer-based mutable access). MUST NOT hand-roll accessor structs.

| Base type | Use | Accessor pattern |
|-----------|-----|------------------|
| Copyable (struct) | `Property<Tag, Base>` | `var x: Property<Tag, Self> { Property(self) }` |
| ~Copyable (struct) | `Property<Tag, Base>.View` | `var x: ... { mutating _read { yield unsafe ...View(&self) } }` |
| Class-backed | `Property<Tag, Base>` | `var x: Property<Tag, Self> { Property(self) }` — `.View` fails because classes forbid `mutating` accessors |

**Validated by**: `swift-property-primitives/Experiments/property-view-class-accessor/` (2026-07-05: path corrected — the prior citation omitted the package directory; disk-verified, the experiment exists and its `Package.swift` names the target `property-view-class-accessor`).

---

### [IMPL-022] _read + _modify for Mutating Property Accessors

**Statement**: When a `Property.View` extension includes **mutating** methods, the accessor property MUST provide both `_read` and `_modify` coroutines. Without `_modify`, the compiler treats the yield as read-only.

```swift
var remove: Property<Remove, Self>.View.Typed<Element> {
    mutating _read  { yield unsafe Property<Remove, Self>.View.Typed(&self) }
    mutating _modify { var view = unsafe Property<Remove, Self>.View.Typed<Element>(&self); yield &view }
}
```

If the extension only has non-mutating methods, `_read` alone is sufficient. The same applies to `.View.Typed.Valued` for value-generic types.

**Cross-references**: [IMPL-021], [API-NAME-002]

---

### [IMPL-026] Property.View Protocol Delegation

**Statement**: When a `~Copyable` protocol's conformers share Property.View operations with identical semantics, the accessors and Property.View methods MUST be provided as protocol defaults. Per-type accessors MUST NOT duplicate the default. Per-type extensions MAY add type-specific methods that coexist.

```swift
// Protocol provides defaults — all conformers get pop.first() automatically
extension MyProtocol where Self: ~Copyable {
    public var pop: Property<Pop, Self>.View {
        mutating _read { yield unsafe Property<Pop, Self>.View(&self) }
        mutating _modify { var view = unsafe Property<Pop, Self>.View(&self); yield &view }
    }
}
extension Property.View where Tag == Pop, Base: MyProtocol & ~Copyable {
    public func first() -> Index? { unsafe base.pointee.popFirst() }
}
```

**Compiler constraints**: (1) `where Self: ~Copyable` on protocol extensions — required. (2) `Base: Protocol & ~Copyable` on Property.View extensions — required for both Copyable and ~Copyable conformers. (3) Per-type overrides with identical body are redundant — remove them.

**Semantic boundary**: Applies when operations are expressible purely through protocol requirements with identical semantics. Does NOT apply when operations check type-specific state, return types differ, or require type-specific initializers.

**Compiler limitation**: Protocol type inference fails with `~Copyable Element` in `_read`/`_modify` coroutine accessors provided by protocol extensions. The protocol default compiles but conformers cannot resolve the Element type through the coroutine. Status: OPEN, present in Swift 6.3.

**Validated by**: `swift-institute/Experiments/property-view-pattern/`, `protocol-coroutine-accessor-limitation/`

**Cross-references**: [IMPL-020], [IMPL-021], [IMPL-022]

---

### [IMPL-079] Property.View Is the Terminal ~Escapable Layer

**Statement**: Property.View methods MUST return Copyable values or use closures for borrowed access. A Property.View method MUST NOT return another `~Escapable` value.

**Why**: `_read` coroutine scoping prevents `~Escapable` values from crossing View boundaries. A `~Escapable` value produced inside an inner `_read` has its lifetime tied to that inner scope; an outer `_read` cannot yield the inner value because the inner scope ends first.

**Validated by**: `swift-institute/Experiments/tagged-escapable-accessor/`, `escapable-accessor-patterns/`

**Cross-references**: [IMPL-021], [IMPL-065], [MEM-LIFE-005], [MEM-COPY-013]

---

### [IMPL-081] Null-Termination Awareness for Sub-View APIs

**Statement**: When designing sub-view APIs on types derived from C strings, the return type MUST reflect whether null-termination is preserved.

| Operation | Null-terminated? | Safe return type |
|-----------|-----------------|-----------------|
| Suffix to end (`lastComponent`) | Yes — shares original `\0` | `Path.View` or typed view |
| Prefix (`parent`) | No — separator at boundary | `Span<Char>` or byte count |
| Arbitrary sub-range | No | `Span<Char>` |

**General principle**: When a type carries a hidden invariant (null-termination, alignment, capacity), sub-slicing operations must make explicit which invariants survive. Different return types for different guarantee levels.

**Cross-references**: [MEM-SPAN-001], [IMPL-065]

---

## Static Method Architecture

### [IMPL-023] Core Logic in Static Methods

**Statement**: Types with `~Copyable` generic parameters needing both `~Copyable` and `Copyable` overloads MUST place core logic in static methods. Instance methods delegate to statics. This eliminates Swift's overload recursion problem.

**The problem**: Two extensions with same method name, different constraints — the more-constrained overload calling `self.method()` resolves to itself, producing infinite recursion.

**The solution**: Statics are called on the type, not `self`, so overload resolution cannot recurse. See [INFRA-110].

**Static signature pattern**: Statics take decomposed state as parameters (e.g., `state: inout State`, `storage: Storage`). Methods that replace `self` as a whole (growth, CoW) remain as instance methods.

**Validated by**: `swift-buffer-primitives/Experiments/static-property-view-pattern/`

**Cross-references**: [IMPL-020], [IMPL-024], [IMPL-025], [API-NAME-002]

---

### [IMPL-024] Compound Identifiers in the Static Layer

**Statement**: Static methods (implementation layer) MAY use compound names. The public API layer MUST NOT — it uses Property.View nested accessors per [API-NAME-002].

| Layer | Audience | Naming | Example |
|-------|----------|--------|---------|
| Static | Package author | Compound allowed | `MyType.insertFront(_:state:storage:)` |
| Property.View | Consumer | Nested required | `instance.insert.front(element)` |

**Cross-references**: [API-NAME-002], [IMPL-023], [INFRA-110], [INFRA-106]

---

### [IMPL-025] Two-Tier Overload Resolution

**Statement**: Types supporting both `~Copyable` and `Copyable` elements MUST provide two tiers of public methods. Both delegate to the same static. The `Copyable` tier adds preparation logic (e.g., CoW uniqueness checks). Neither tier calls `self.method()`. See [INFRA-110].

**Cross-references**: [IMPL-023], [MEM-COPY-006]

---

## Extension Extraction

### [IMPL-082] Scope Resolution on Extension Extraction

**Statement**: When extracting methods from a nested extension body (`extension Outer { struct Inner { } }`) to an explicit extension (`extension Outer.Inner { }`), sibling types declared in `Outer` lose implicit scope resolution. All references to sibling types MUST be fully qualified after extraction.

**Root cause**: `extension Outer { struct Inner {} }` places methods at nesting depth 2 (Outer scope visible). `extension Outer.Inner {}` places methods at depth 1 (only Inner's own scope). The fully-qualified type path is the same, but lexical nesting differs.

**Validated by**: `swift-institute/Experiments/extension-extraction-scope-resolution/`

**Cross-references**: [API-IMPL-005], [API-IMPL-008]

---

### [IMPL-100] Coroutine `_read`/`_modify` over `with*` Closure APIs

**Statement**: For borrowed access to `~Copyable` resources stored in classes or actor state, coroutine property accessors (`_read`, `_modify`) are PREFERRED over `with*` closure-taking APIs. The accessor shape reads as an ordinary property at call sites; the closure shape forces the caller into a nested-scope pattern that does not compose with the ownership primitives.

**Correct**:

```swift
public var event: Executor.Wait.Event.Source {
    _read { yield _storage.event }
}
// Call site:
for await e in executor.event { ... }
```

**Incorrect (with*)**:

```swift
public func withEvent<R>(_ body: (borrowing Executor.Wait.Event.Source) -> R) -> R {
    body(_storage.event)
}
// Call site:
executor.withEvent { event in
    for await e in event { ... }
}
```

**Rationale**: The closure form dictates a stack-shape the caller cannot escape, breaking composition with `for await`, `defer`, and sibling coroutine APIs. The coroutine accessor preserves ownership discipline (the yielded value is borrowed for the caller's scope) while presenting an ordinary property shape that composes freely.


**Cross-references**: [IMPL-021], [IMPL-071]
