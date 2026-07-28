# Ownership, deinit, and lifetime views

Companion to the `swift` skill. Read this when touching `~Copyable`,
`~Escapable`, `deinit`, or `consuming`.

## Ownership belongs on the type

Types representing a resource with a lifecycle — descriptors, handles,
allocations, locks — are natively `~Copyable`, with the ownership on the type
itself. Wrapper adapters (`Owned<Tag>`) are only for types from modules you
cannot change. Prefer `~Copyable` for new types; `Copyable` is the choice that
needs a reason.

Annotate `consuming` / `borrowing` / `inout` explicitly wherever ownership is not
obvious. Ownership is not an overload axis — do not ship `borrowing` and
`consuming` twins of the same operation.

Never degrade a `~Copyable` value to its raw representation to avoid the cascade.
If a `~Copyable` value appears in an enum case, a stored field, or a generic
argument, make the container `~Copyable` too. Extracting `_raw` / `_rawValue` on
one side of a call, layer, or closure boundary and reconstructing on the other
voids the close-on-drop guarantee; any `_raw` / `init(_rawValue:)` outside the
wrapper's own file is a review finding.

`Swift.Error` requires `Copyable`, so move-only values never go in error payloads
— return a non-throwing outcome enum instead. For recursive value-type
indirection use `Reference<T>` / `Owned<T>`, never an ad-hoc `_Box` class.

## Suppression does not propagate

Every extension, protocol refinement, and conformance re-imposes `Copyable` on
any suppressed parameter it fails to restate. Three sharp edges:

- a bare conformance to a marker protocol with zero requirements still
  Copyable-pins the capability;
- conditional `Copyable` / `Sendable` conformances must key on the parameter
  itself (`where S: Copyable`), never on a projection — which is rejected for
  suppressible protocols but legal on plain extensions, so the mistake compiles
  in the neighbouring case;
- Copyable-element tests mask the defect entirely, so a suite over a
  `~Copyable`-generic API that never instantiates a move-only element is not
  testing the suppression at all.

Other walls: conformances split across files need to move into the type's file;
compound constraints plus a separate file plus the Lifetimes flag can fail at
module emission; and `Sequence` / `Collection` requirements have no `~Copyable`
workaround — vend a borrowing `forEach`.

## `deinit` and `consuming`

`deinit` on a `~Copyable` struct grants *immutable* access to `self`, like
`borrowing`; `consuming func` grants mutable access. So `Optional.take()` works
in `consuming` and fails in `deinit`. The canonical deinit idiom for an
`Optional<~Copyable>` field is `guard case .some = _field else { return }` — read
the discriminator, never the payload.

A `consuming func` that does not `discard self` still runs `deinit` on the
remaining stored properties. When a consuming operation has already extracted the
resource, track that (`Atomic<Bool>`, or an Optional field niled in the consuming
op) and guard `deinit` on it. `discard self` requires trivially-destroyed stored
properties, so a closure-bearing `~Copyable` type uses the Optional-field +
guarded-deinit shape.

A value type with a user `deinit` cannot conform to `Copyable`, even
conditionally, and a conditional `deinit` is not expressible. A generic struct
wanting (a) a generic substrate field, (b) conditional Copyability, and (c)
automatic cleanup gets any two. The escape is to relocate (a) + (c) into a
private `final class Box`. Keep exactly one cleanup-truth-holder per discipline —
the deinit lives on the Box *or* on a self-cleaning concrete substrate, never
both. For an inline `@_rawLayout` substrate a class Box is wrong, since it
reintroduces the heap the layout existed to avoid; put the occupancy oracle and
deinit in the move-only leaf.

Linear types (exactly-once) are `~Copyable` + `consuming func` + a trapping
`deinit`; affine types (at-most-once) are the same with a silent `deinit`. A
refcounted box wrapping move-only storage must drain elements in its own class
`deinit` through public mutating API and close with `_fixLifetime(self)`.

**The optimizer can delete your deinit.** Under `-O`, once
`isKnownUniquelyReferenced` has been applied, the optimizer devirtualizes the
final release and omits the user deinit of a generic-namespace-nested
`~Copyable` struct while still destroying its fields — elements leak while their
bytes are freed. An empty `deinit {}` does not restore it, and neither does a
non-trivial `AnyObject?` field.

The cross-package `@_rawLayout` deinit-skip needs a `_deinitWorkaround:
AnyObject?` marker, placed by shape: at the substrate leaf when the
`@_rawLayout` leaf lives in another module, on the type itself for same-module
direct `@_rawLayout`. Never add a buffer-level workaround over a nested
`@_rawLayout` substrate — that SIGSEGV-miscompiles. The naked skip is debug-only,
since release specializes past it, but debug leaks are still leaks, so the
workaround stays.

Never replace `@_rawLayout` storage with `InlineArray<n, Optional<Element>>`.
Optional requires `Element: Copyable` and adds a per-element tag, destroying both
properties `@_rawLayout` was chosen for.

## CoW strategy is captured at construction

Clone strategy and drain are captured where `Element: Copyable` is statically
visible, and cannot be recovered downstream. Split constructors and every generic
construction helper on element copyability.

A single `~Copyable`-generic form statically selects the strategy-less overload
even when the caller's element is concretely Copyable, producing a box that works
while unique and traps on the first post-fork mutation. The same split is
mandatory for any overload that *replaces* a shared box.

A `where S == Wrapper<E, Concrete<E>>` same-type method pin only derives
conditional conformances conditional on suppressions; a conformance conditional
on a protocol bound does not derive through such a pin. So a type consumed
through method pins carries its protocol obligations in the declaration's generic
bounds.

## Lifetime views

`~Escapable` views are the ecosystem infrastructure and supersede new `with*`
closure APIs for borrowed access to a `~Copyable` resource. Add a `with*` overload
only as a verified compiler-limitation fallback with a TRACKING comment.

`~Escapable` values cannot be stored in class stored properties or captured in
`@escaping` closures. When a view must live behind a class property, use
`~Copyable` alone — the `_read` coroutine scope prevents escape and `~Copyable`
prevents aliasing. They *can* be async function parameters and survive `await`.

A `~Escapable` value produced inside an inner `_read` coroutine cannot be yielded
from an outer one — return a Copyable projection, or use closure-based access.

When an annotation such as `~Escapable` is semantically redundant and triggers a
known optimizer crash, omit it until the compiler is fixed. `@_lifetime` is
version-skewed: 6.2.x requires it on mutating methods with `~Escapable` self,
while 6.4-dev rejects it when the return type is Escapable — so this is one to
check against the toolchain in hand rather than to remember.
