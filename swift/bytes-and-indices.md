# Byte discipline, typed indices, and conversions

Companion to the `swift` skill. Read this when working at the byte or arithmetic
boundary, or converting between typed values.

## `UInt8` and `Byte` are siblings

They are not refinement-related. `UInt8` is the stdlib arithmetic carrier; `Byte`
is the institute byte-domain twin, carrying equality, hash, comparison, and
bitwise operations — but no arithmetic. `UInt8` must not conform to
`Byte.Protocol`, and `Byte` must not conform to any stdlib arithmetic protocol.
`Binary.Serializable` / `Binary.Parseable` witnesses use `Buffer.Element ==
Byte`; stdlib-interop forwarders carrying `@_disfavoredOverload` are the only
exemption.

For a conformer with `rawValue: UInt8` storage, classify by domain:

- participates in arithmetic (`- 1`, `* 4`, `% n`, magnitude `<`) → stays
  `UInt8`; bridge via `.underlying` at the conformance boundary, but the witness
  signature still retypes to `Byte`;
- purely bit-field, kind-tag, or opaque byte → retype the storage to `Byte`;
- `OptionSet`, or anything requiring `RawValue: FixedWidthInteger` → stays
  `UInt8`;
- wider arithmetic raw values stay `UInt16` / `UInt32`.

A publicly exposed opaque byte payload is `[Byte]` primary with a `[UInt8]`
`@_disfavoredOverload` forwarder. A codec's alphabet table is `[ASCII.Code]`; its
sparse 256-entry decode lookup is `[UInt8?]`, typing validity instead of a magic
sentinel.

No AST rule can make this call, and none tries: arithmetic happens in method
bodies, not at the storage declaration, so the classification is yours.

## `Byte` is canonical across the L1 byte domain

`UInt8` is permitted only where necessary — compiler- or protocol-required, the
carrier axis `Byte.underlying`, shift counts, bit-cast bridges, stdlib boundary
types — or where the domain genuinely is arithmetic.

New byte-domain APIs take `[Byte]` / `Span<Byte>` / `Byte` only and must **not**
add ergonomic `[UInt8]` forwarders; callers bridge with `.map(Byte.init)`. A
genuine stdlib-interop forwarder carries `@_disfavoredOverload`. Without it, an
unannotated `Array(s)` call site cannot choose between the `[Byte]` and `[UInt8]`
forms, and Swift will sometimes prefer the `UInt8` one — silently unwinding the
byte typing at exactly the sites you were trying to type.

Forwarders declared as extensions **on stdlib types** live in the package's
`* Standard Library Integration` target; forwarders on institute types stay put.

Promote at the boundary, not at the destination: a byte-domain body declares its
accumulator as `Byte` from construction, and a parameter's type is lifted rather
than bridged inside the body. A forwarder file existing only to bridge to a
`[Byte]` primary in a sibling file is migration debt. The one sanctioned bridge
is at an unpacking iterator boundary where bytes enter integer accumulation.

`extension UInt8` must not declare `.ascii`-namespace members — `ASCII.Code` is
the canonical typed ASCII substrate. In ASCII-strict contexts (0x00–0x7F) prefer
`ASCII.Code`; UTF-8 or raw binary that may exceed 0x7F is `Byte`. In a cohort
migration, classify each site by domain first — never blanket-assign to `Byte`.

## The integer↔bytes codec

The shipped codec is `bytes(endianness:)` / `init?(bytes:endianness:)` on
`FixedWidthInteger`. Adopt it; do not mint a parallel selector.

Two traps:

- The default is `.little`, so a big-endian site that omits `.big` **silently
  corrupts**.
- `init?(bytes:)` guards its own length correctly — `guard bytes.count ==
  MemoryLayout<Self>.size else { return nil }` is the first statement. The hazard
  is one layer out, in the slice expression: `buf[i..<i+n]` traps before the
  initializer is ever entered. Guard the buffer, not the optional.

Under `MemberImportVisibility` the Standard Library Integration target re-exports
`Binary.Endianness` with a plain `public import`, which surfaces the type but not
its `.big` / `.little` cases — a consuming file must import
`Binary_Endianness_Primitives` directly as well. Separately,
`Standard_Library_Extensions` re-exports nothing at all, so it does not give you
`Byte_Primitives`.

## Typed indices

`Index<Element>` is `Tagged<Element, Ordinal>` with a phantom `Element` bound
`~Copyable & ~Escapable`. `Index<T>.Offset` wraps a signed displacement,
`Index<T>.Count` an unsigned count.

Tagged is a functor, and the conversion preference is strict — attempt each tier
before descending:

1. `retag` — same raw value, different domain (`bitOffset.retag(Byte.self)`).
   Zero-cost.
2. `map` — same tag, transformed raw value.
3. Typed arithmetic for composed operations — `.zero + count`, `index + .one`,
   `end - start`.
4. Typed initializer at a system boundary — `try Index(int)`, `Ordinal(uint)`.
5. `rawValue` / `__unchecked` — last resort, same-package internals only,
   requires justification.

`retag` does not apply across different scales. For a known ratio use the count
chain — `.zero + Index<A>.Count(sourceIndex) * .ratio` — entirely non-throwing.
You cannot scale a point in affine geometry, only a magnitude, which is why the
`Count(index)` step is type-theoretically necessary even though numerically it is
a no-op. When a signed displacement is also involved, add it to the chain and
propagate failure with typed throws rather than an internal `try!`.

`.rawValue` and `.position` access is confined to extension initializers and
same-package implementations. `Int(bitPattern: index.position.rawValue)` — the
multi-level reach-through — is always wrong, as is `Int(x.underlying.rawValue)`
inside a typed-seam body. When a raw loop genuinely needs an `Int` seed, derive
the bound through the typed API and descend once via `Int(clamping:)`. Compare at
the semantic type level (`#expect(index == 3)`).

Arithmetic uses the typed operators. `Int(bitPattern:)` is valid only for C APIs,
stdlib APIs requiring `Int`, and debug output. `Count - Count` has no `-` by
design — use `.subtract.saturating(_:)`. Bounds-check with `index < count`;
iterate with `(.zero..<count)`. When wrapping a stdlib collection, store the typed
`Index<Element>` as the primary position and derive the raw index only at the
subscript boundary. A compile-time-constant index is a bare integer literal
(`slab[0] = x`) via the tagged-primitives integration carve-out; a runtime int
keeps explicit construction.

Different phantom types exist precisely so `Index<Bit>` and `Index<Byte>` cannot
be compared or mixed — that is the feature, not friction to route around. Values
entering from stdlib `Int`-returning properties (`bitWidth`,
`MemoryLayout<T>.stride`) are legitimate boundary conversions.
