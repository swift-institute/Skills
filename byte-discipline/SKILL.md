---
name: byte-discipline
description: |
  UInt8/Byte discrimination — sibling types, no arithmetic on Byte, Binary.Serializable witnesses,
  rawValue:UInt8 domain disposition, UInt8 forwarder discipline.
  ALWAYS apply at the byte / arithmetic-domain boundary.

layer: implementation

requires:
  - swift-institute
  - code-surface

applies_to:
  - swift
  - swift6
  - primitives
  - standards
  - foundations

---

# Byte Discipline

UInt8/Byte are sibling types in the institute ecosystem, not refinement-related. `UInt8` is the stdlib arithmetic carrier (`AdditiveArithmetic`, `Numeric`, `BinaryInteger`, …); `Byte` is the institute byte-domain twin (equality, hash, comparison, bitwise, but NOT arithmetic). The two types answer different domain questions, and the discipline below maintains the separation through six mechanically-enforced rules.

The skill's load-bearing principle — the **byte-vs-arithmetic-domain axis** — is documented under [API-BYTE-004]. The other five rules are corollaries that encode specific consequences of the axis at code-surface locations the W2 cascade exposed.

---

## Q1 / Q3 anchors

The discipline derives from two prior research convergences:

- **Q1**: `byte-protocol-capability-marker.md` v1.1.0 RECOMMENDATION (2026-05-15) — UInt8 vs Byte sibling-form identity. UInt8 MUST NOT conform to `Byte.\`Protocol\``.
- **Q3**: `byte-arithmetic-conformance.md` v1.0.0 RECOMMENDATION ζ (2026-05-19) — Byte carries byte-domain identity, NOT arithmetic identity. Byte MUST NOT conform to stdlib arithmetic protocols.

The remaining four rules ([API-BYTE-003] through [API-BYTE-006]) encode the W2 cascade's discrimination criteria (`broader-l2-l3-byte-typing-gap-plan.md` § Wave 2).

---

### [API-BYTE-001] UInt8 MUST NOT conform to Byte.`Protocol`

**Statement**: `UInt8` MUST NOT conform to `Byte.\`Protocol\``. The stdlib raw arithmetic carrier (`UInt8`) and the institute byte-domain twin (`Byte`) are sibling-form per `byte-protocol-capability-marker.md` v1.1.0 RECOMMENDATION (2026-05-15), NOT refinement-form. Adding the conformance dissolves the separation, shadows operators (`<` / `==` / `hash`), broadens the API surface, and pollutes `Tagged<_, UInt8>` composition.

**Enforcement**: Mechanical — `Lint.Rule.Byte.UInt8ConformsToByteProtocol` in `swift-foundations/swift-institute-linter-rules`, target `Institute Linter Rule Byte` (pilot 1 of Post-W2 swift-linter arc 2026-05-19). Discipline: `Audits/PROMOTE-API-BYTE-001-2026-05-19.md`. [VERIFICATION: AST]

**Cross-references**: [API-NAME-001c] (capability-marker protocol recipe), [API-BYTE-002] (sibling Q3 rule), [API-BYTE-005] (W5 UInt8.ascii guard).

---

### [API-BYTE-002] Byte MUST NOT conform to stdlib arithmetic protocols

**Statement**: `Byte` MUST NOT conform to any stdlib arithmetic protocol: `AdditiveArithmetic`, `Numeric`, `SignedNumeric`, `BinaryInteger`, `FixedWidthInteger`, `SignedInteger`, `UnsignedInteger`, `Strideable`. The arithmetic surface lives on `UInt8` only. Per `byte-arithmetic-conformance.md` v1.0.0 RECOMMENDATION ζ (2026-05-19).

**Enforcement**: Mechanical — `Lint.Rule.Byte.ByteConformsToArithmetic` in `swift-foundations/swift-institute-linter-rules`, target `Institute Linter Rule Byte`. Discipline: `Audits/PROMOTE-API-BYTE-002-2026-05-19.md`. [VERIFICATION: AST]

**Allowed conformances on Byte** (non-arithmetic): `Equatable`, `Hashable`, `Comparable`, `Sendable`, `Codable`, `CustomStringConvertible`, `ExpressibleByIntegerLiteral`, bitwise operations via `Byte.\`Protocol\`+Bitwise`.

**Corollary — protocols requiring arithmetic**: Types that conform to protocols requiring `FixedWidthInteger` / `BinaryInteger` (e.g., `OptionSet`'s `RawValue: FixedWidthInteger` requirement) CANNOT switch their storage from `UInt8` to `Byte`, because `Byte` does not satisfy the protocol's arithmetic requirements. Such `rawValue: UInt8` stays UInt8 regardless of byte-domain semantics; the witness signature still retypes per [API-BYTE-003]. (Arc B 2026-05-20 refinement.)

**Cross-references**: [API-BYTE-001] (sibling Q1 rule), [API-BYTE-004] (rawValue:UInt8 disposition that this rule's "stays UInt8" branch flows from).

---

### [API-BYTE-003] Binary.Serializable witnesses MUST use Buffer.Element == Byte

**Statement**: `Binary.Serializable` / `Binary.Parseable` witness implementations (`serialize(_:into:)`, `parse(_:)`, init) MUST use `Buffer.Element == Byte` (or `Source.Element == Byte`, `Bytes.Element == Byte`), NOT `== UInt8`. The protocol surface was retyped to `Byte` at `swift-binary-primitives@b121c0e` (Wave 2). The Statement covers BOTH witness shapes:

- **Conformer-extension shape**: `extension Foo: Binary.Serializable { static func serialize<Buffer: ...>(into: inout Buffer) where Buffer.Element == Byte ... }`. Witness for the named conformer `Foo`.
- **Default-impl-extension shape**: `extension Binary.Serializable { func serialize<Buffer: ...>(into: inout Buffer) where Buffer.Element == Byte ... }` (and the conditional form `extension Binary.Serializable where Self: ... { ... }`). Witness for any conformer without an override. The Binary.Parseable analog is identical.

Stdlib-interop forwarders carrying `@_disfavoredOverload` are exempt across both shapes; the 6-forwarder allowlist documented in `broader-l2-l3-byte-typing-gap-plan.md` § "Forwarder scope on Binary.Serializable" enumerates them:

1. `serialize(into:) where Buffer.Element == UInt8`
2. `Array.init<S: Binary.Serializable>(_:) where Element == UInt8`
3. `ContiguousArray.init<S: Binary.Serializable>(_:) where Element == UInt8`
4. `RangeReplaceableCollection<UInt8>.append<S: Binary.Serializable>(_:)`
5. `withSerializedBytes(_:(borrowing Span<UInt8>) throws -> R)`
6. `var bytes: [UInt8]` default convenience

All six live in `swift-binary-primitives` and carry `@_disfavoredOverload`. The rule's exemption is mechanical (attribute presence), not file-path-based.

**Enforcement**: Mechanical — `Lint.Rule.Byte.BinarySerializableUInt8Witness` in `swift-foundations/swift-institute-linter-rules`, target `Institute Linter Rule Byte`. Detection covers both shapes: the gate fires when EITHER (a) the extension's inheritance clause names `Binary.Serializable` / `Binary.Parseable` (conformer-extension), OR (b) the extended type IS the protocol (default-impl-extension). Default-impl-extension coverage landed 2026-05-20 (Arc G Phase 7 addendum). Discipline: `Audits/PROMOTE-API-BYTE-003-2026-05-19.md`. [VERIFICATION: AST]

**Cross-references**: [API-BYTE-004] (rawValue:UInt8 conformer companion), [API-BYTE-006] (@_disfavoredOverload forwarder rule).

---

### [API-BYTE-004] rawValue: UInt8 on Binary.Serializable conformers — domain disposition

**Statement**: Conformers to `Binary.Serializable` / `Binary.Parseable` with `rawValue: UInt8` storage MUST be classified per the W2 discrimination rubric below. The rule fires at every such site; per-site disposition is the writer's.

**Enforcement**: Mechanical — `Lint.Rule.Byte.BinarySerializableRawValueUInt8` in `swift-foundations/swift-institute-linter-rules`, target `Institute Linter Rule Byte`. Discipline: `Audits/PROMOTE-API-BYTE-004-2026-05-19.md`. [VERIFICATION: AST]

#### W2 discrimination rubric — the load-bearing principle

The **byte-vs-arithmetic-domain axis** determines storage substrate. This is the principle from which the other five rules are corollaries:

| Pattern in rawValue's usage | Domain | Disposition |
|-----------------------------|--------|-------------|
| `rawValue: UInt8` participating in **arithmetic** — `- 1` (decrement), `+ 1` (increment), `* 4` (multiplier), `% n` (modular roll-over), `< n` (magnitude comparison) | arithmetic-domain | **STAYS UInt8** — Byte has no arithmetic by design. Bridge via `.underlying` at the conformance boundary. The witness signature still retypes to `Buffer.Element == Byte`. |
| `rawValue: UInt8` purely **bit-field / kind-tag / opaque-byte** — no arithmetic, only bitwise (`& 0b...`, `\| 0b...`), equality, hash | byte-domain | **RETYPE storage to `Byte`** |
| `rawValue: UInt8` on a type conforming to **`OptionSet`** (or any protocol requiring `RawValue: FixedWidthInteger`) | protocol-required | **STAYS UInt8** per [API-BYTE-002] corollary. Byte ≢ FixedWidthInteger. Witness signature retypes; storage doesn't. (Arc B 2026-05-20 refinement.) |
| `rawValue: UInt16` / `UInt32` participating in **arithmetic** — checksum sum, length math, range checks | arithmetic-domain (wider) | **STAYS UInt16/UInt32**. Same rationale as UInt8 arithmetic. Serialize via `bytes(endianness:)` for typed byte output. (Arc B 2026-05-20 refinement.) |
| **Opaque byte-domain payload** publicly exposed (`payload: [UInt8]`, `signature: [UInt8]` on JWT-shaped types) | byte-domain (public) | **`[Byte]` primary + `[UInt8]` `@_disfavoredOverload` forwarder** for callers holding stdlib `[UInt8]` (e.g., from network frames). (Arc B 2026-05-20 refinement; matches W2 Q3 disposition for rfc-7519.) |
| **Stdlib-shaped API** in witness body (`String(decoding:as:UTF8.self)`, `MaskingKey.apply(_:UInt8)` from RFC 6455) | stdlib-idiom | Bridge via `.underlying` at the call site rather than retyping the stdlib-shaped API. The stdlib signature stays; the byte-domain context wraps. (Arc B 2026-05-20 refinement.) |
| **Per-direction asymmetric substrate** — codec family (rfc-4648 Base16/32/64): encode `[Byte] → [ASCII.Code]`; decode `[ASCII.Code] → [Byte]` | bidirectional codec | Per-direction signature: each function uses the substrate appropriate to its direction. Internal alphabet table = `[ASCII.Code]`; internal decode lookup = `[UInt8?]` Optional (see below). Third reference exemplar after rfc-791 TTL witness-only retype and rfc-7519 JWT opaque payload. (Arc C-continuation 2026-05-20 refinement.) |
| **Codec lookup table** — sparse 256-entry index mapping ASCII char → value (Base16/32/64 decode tables) | arithmetic-domain (sparse) | `[UInt8?]` Optional. Types validity at the type-system level rather than via magic sentinel (`UInt8` value 255). Per-codec: index by ASCII byte; `nil` = not-in-alphabet; non-nil = the sextet/digit value. Replaces sentinel pattern; principal-confirmed mid-Arc-C-continuation. (Arc C-continuation 2026-05-20 refinement.) |

**Why mechanical fire (not AST arithmetic classification)**: AST cannot reliably distinguish arithmetic-domain vs byte-domain usage without cross-function-body analysis (arithmetic happens in `decrement()`, `init(bytes:)`, etc., not in the storage declaration itself). The rule's value is surfacing the question uniformly; the answer is per-type judgment.

#### Grounding — the `bytes(endianness:)` / `init(bytes:endianness:)` codec

The `bytes(endianness:)` selector cited in the rubric (and its reciprocal reader) is the **already-shipped** bidirectional integer↔bytes codec in `swift-binary-primitives`, target *Binary Primitives Standard Library Integration*, file `Sources/Binary Primitives Standard Library Integration/FixedWidthInteger+Binary.swift`. It is declared once on the generic `extension FixedWidthInteger`, so it covers **every** width, signed and unsigned (`UInt8`…`UInt64`, `Int8`…`Int64`), with no per-type boilerplate. The selector set:

| Direction | Signature | Note |
|-----------|-----------|------|
| write → array | `func bytes(endianness: Binary.Endianness = .little) -> [Byte]` (:62) | fresh `[Byte]` |
| write → sink | `func bytes<Sink: RangeReplaceableCollection>(into: inout Sink, endianness:) where Sink.Element == Byte` (:121) | alloc-free; preferred on hot paths and for `[Byte]` buffers |
| read (collection) | `init?(bytes: some Collection<Byte>, endianness:)` (:87) | requires `bytes.count == size`, else `nil` |
| read (span) | `init?(_ bytes: borrowing Span<Byte>, endianness:)` (:105) | zero-copy |

It returns/consumes `[Byte]` (not `[UInt8]`). Import note: a consuming file imports `Binary_Primitives_Standard_Library_Integration` for the codec **and** must also `import Binary_Endianness_Primitives` directly — under `MemberImportVisibility` the SLI's `public import` re-export surfaces the `Binary.Endianness` *type* but not its `.big` / `.little` *cases*, so a bare codec call fails to compile without the second import (no package-manifest change needed — the module is already reachable via the SLI dep). Two adoption invariants: (1) the default is `.little` — pass `.big` / `.network` **explicitly** at big-endian sites or the value silently corrupts; (2) `init?(bytes:)` traps on a short slice *before* the optional is evaluated, so a force-unwrap needs a proven upstream length guard. Signed reads decode directly — `Int16(bytes: slice, endianness: .big)!` replaces the `Int16(bitPattern: UInt16(...))` dance. Do **not** mint a parallel selector; adopt this one. Reference consumers (2026-06-25): the swift-pdf chain — `swift-iso-14496-22`, `swift-w3c-png`, `swift-rfc-1950`, `swift-rfc-1951`, `swift-iso-32000`.

#### Per-RFC analysis exemplar (RFC 791)

| Type | rawValue | Arithmetic? | Disposition |
|---|---|---|---|
| Flags | UInt8 (bit field) | bitwise only | retype to Byte ✓ (landed `cde98cb`) |
| HeaderChecksum | UInt16 | arithmetic (sum) | UInt16 stays; serialize via `bytes(endianness:)` |
| IHL | UInt8 (count) | `* 4` (header-length multiplier) | **STAYS UInt8** |
| IPv4.Address | UInt32 | bitwise | UInt32 stays |
| Identification | UInt16 | none (opaque ID) | UInt16 stays |
| FragmentOffset | UInt16 (13-bit) | shift / mask | UInt16 stays |
| Precedence | UInt8 (3-bit) | bitwise only | retype to Byte |
| Protocol | UInt8 (catalog) | none (lookup) | retype to Byte |
| TTL | UInt8 (count) | `- 1` (decrement) | **STAYS UInt8** ✓ (landed `cde98cb`) |
| TotalLength | UInt16 | arithmetic (sum/check) | UInt16 stays |
| TypeOfService | UInt8 (bit field) | bitwise | retype to Byte |
| Version | UInt8 (literal) | none | retype to Byte |

Per-RFC the analysis differs; the rule's mechanical fire surfaces the question for each `rawValue: UInt8` + Binary.{Serializable,Parseable} pair so the writer applies the rubric site-by-site.

#### Enum raw-value catalog convention (Arc B 2026-05-20 refinement)

Types whose `rawValue: UInt8` is a **catalog of enumerated constants** (e.g., `MessageType`, `ContentType`, `Kind` — large mechanical case lists per a spec) MAY keep the catalog in a separate `.swift` file from the type's `Binary.Serializable` conformance. The witness boundary applies `Byte(value.rawValue)` once at the conformance site; the catalog file stays per-case mechanical without per-case bridging.

This is purely a code-organization preference (one bridge call vs N case-level bridges); the discrimination rule above still applies — catalog values participate in lookup/equality only (byte-domain) so the storage retypes to Byte per the rubric.

#### Test sweep convention (Arc B 2026-05-20 refinement)

Test bodies that materialized `[UInt8]` arrays as test fixtures (`for byte in 0..<255 as ClosedRange<UInt8>`) MUST migrate to `[Byte]` with the literal-inference convention per W1's test-syntax rules. Where the loop variable was UInt8 (e.g., `for value in 0..<255`), wrap as `Byte(value)` at usage — `Byte` is NOT `Strideable` per Q3, so range-iteration stays on UInt8 with per-iteration bridge.

#### Wrapper-extension split by direction (Arc C-continuation 2026-05-20 refinement)

For codec or codec-shaped types operating bidirectionally (encode + decode), a single type MAY host BOTH directions via where-clause-partitioned extensions rather than splitting into two sibling types. Pattern from rfc-4648:

```swift
extension Codec where Direction == .encode { /* [Byte] in, [ASCII.Code] out */ }
extension Codec where Direction == .decode { /* [ASCII.Code] in, [Byte] out */ }
```

The where-clause partition gives the type system per-direction substrate without forcing API consumers to choose between two types. Composes with the per-direction asymmetric substrate row above.

#### Iterator-boundary arithmetic bridge (Arc C-continuation 2026-05-20 refinement)

When a codec / parser unpacks a buffer of `Byte` into the integer-arithmetic domain (e.g., LEB128, Base64 sextet packing), the `Byte → UInt8` bridge happens ONCE at the unpacking iterator boundary, scoped tight. Pattern shape:

```swift
for byte in input {              // input: some Sequence<Byte>
    let v = byte.underlying      // ONE bridge, scoped to this iteration's accumulation
    accumulator = (accumulator << 6) | UInt32(v & 0x3F)
}
```

The bridge is acceptable per the rubric because it's contained to arithmetic-domain accumulation (NOT scattered across consumer sites). Composes with the arithmetic-domain row of the main rubric.

**Cross-references**: [API-BYTE-002] (Q3 — Byte has no arithmetic; this rule's "stays UInt8" disposition flows from Q3), [API-BYTE-003] (witness signature retype, co-fires on every conformer), [API-BYTE-006] (forwarder discipline that the arithmetic-domain bridge uses).

---

### [API-BYTE-008] Byte is canonical in the L1 byte-domain — minimize UInt8, no ergonomic forwarders, promote accumulators at construction

**Statement**: `Byte` is the canonical substrate across the L1 byte-domain ecosystem. `UInt8` is permitted ONLY where it is **necessary** (compiler- or protocol-required) or **semantically appropriate** (the domain genuinely is arithmetic). New byte-domain APIs MUST take `[Byte]` / `Span<Byte>` / `Byte` only; they MUST NOT add ergonomic `@_disfavoredOverload [UInt8]` forwarders as a convenience for callers that happen to hold `[UInt8]` — those callers bridge explicitly (`.map(Byte.init)`) at their own site. This narrows [API-BYTE-006]: its intent is "if a `UInt8` forwarder exists, mark it `@_disfavoredOverload` and (per [API-BYTE-007]) locate it in an SLI module," NOT "always provide a forwarder." Pre-existing forwarders are left alone unless cleanup is requested; the rule governs whether a *new* one should exist (default: no).

#### Accumulator / aggregate promotion at the construction boundary

When the destination element type is `Byte` (`var out: [Byte] = []`, `extension Array where Element == Byte`, a `Byte.Input` sink, …), local byte-accumulator variables MUST also be `Byte` from their construction — NOT `UInt8` carried through the body and bridged to `Byte` at the append/store boundary. Promote at construction, not at the destination.

**Correct**:
```swift
// Byte accumulator throughout — one construction-boundary promotion
var byte = Byte(UInt8(v & 0x7F))
byte |= 0x80
out.append(byte)
```

**Incorrect**:
```swift
var byte = UInt8(v & 0x7F)      // ❌ carries UInt8 through a byte-domain body
byte |= 0x80
out.append(Byte(byte))          // ❌ Byte() bridge deferred to the append boundary
```

`Byte`'s `Byte.\`Protocol\`+Bitwise` conformance supports the same bitwise operators (`&`, `|=`, equality against integer literals) that encoders such as LEB128 use, so the body translates 1:1 with no arithmetic loss.

#### Parameter lift over in-body bridge

When a `UInt8`-typed parameter or argument cannot pass to a `Byte`-typed slot, **lift the parameter type** to `[Byte]` / `Byte` — do NOT bridge inside the body via `Array<Byte>(uint8sParam)`. This is the parameter-side companion to accumulator promotion (promote at the boundary, not inside the body). A `UInt8`-forwarder file that exists ONLY to bridge to a `[Byte]` primary already declared in a sibling file is migration debt: delete the forwarder and let consumers bridge (`Array<Byte>(uint8s)`) at their own call site.

**Correct**:
```swift
public init?(bytes: [Byte], endianness: Binary.Endianness = .little) { … }  // ✅ lift the parameter
```

**Incorrect**:
```swift
guard let raw = RawValue(bytes: Array<Byte>(bytes), …) else { … }  // ❌ in-body bridge keeps UInt8 in the API
```

Distinct from [API-BYTE-006] / [API-BYTE-007], which govern forwarders that legitimately exist for stdlib-interop ergonomics; this covers the forwarder that is purely a migration-debt bridge to a sibling `[Byte]` primary.

#### Where UInt8 IS appropriate (permitted)

- **Carrier axis**: `Byte.underlying: UInt8`, `Byte.init(_:UInt8)` — by design.
- **Arithmetic domain**: shift counts (`Byte.\`Protocol\` << UInt8`), `UInt8.coder()`, `Pattern8 = Pattern<UInt8>`, LEB128 local accumulators, bit-field constants — per [API-BYTE-004]'s arithmetic-domain row.
- **Stdlib protocol requirements**: `RawRepresentable.RawValue == UInt8`, `OptionSet.RawValue: FixedWidthInteger` — per [API-BYTE-002].
- **Bit-cast bridges**: `Int8.init(bitPattern: UInt8)`.
- **Stdlib boundary types**: `StaticString.utf8Start: UnsafePointer<UInt8>`, `String.UTF8View.Element == UInt8`.

#### Where UInt8 is NOT appropriate (retype to Byte — or to ASCII.Code)

- An **"ergonomic" forwarder** for callers holding `[UInt8]` arrays — the caller bridges at its own site.
- **Buffer / Input / Output substrate** for byte-domain APIs — use `[Byte]` / `Byte.Input`.
- **Public byte-content parameters** where `Byte`'s identity is load-bearing.

#### ASCII-strict carve-out

`Byte` is the canonical *byte-domain* substrate, but it is NOT the right substrate everywhere `UInt8` currently lives. In ASCII packages (`swift-ascii-primitives`, `swift-foundations/swift-ascii`, `INCITS_4_1986`, …), prefer `ASCII.Code` over `Byte` where the content is semantically ASCII-strict (decoded as US-ASCII, 0x00–0x7F). Byte-domain content (UTF-8 bytes, raw binary, possibly 0x80+) is `Byte`; codec input/output splits per-direction per the [API-BYTE-004] rubric. Example: `String.init?(ascii bytes: [UInt8])` migrates to `init?(ascii bytes: [ASCII.Code])` (NOT `[Byte]`) because the parameter is ASCII-strict and `ASCII.Code` carries its own 0x7F-bounded invariant; by contrast `Text.Line.Map.init(scanning content: [UInt8])` migrates to `[Byte]` because UTF-8 source may contain non-ASCII bytes. See [API-BYTE-005] (`ASCII.Code` is the canonical typed ASCII substrate).

#### Cohort-migration precondition — classify each site by domain first

Before assigning a substrate in a `UInt8 → typed` cohort migration, classify EACH site by domain — ASCII-strict → `ASCII.Code`, byte-domain → `Byte`, codec → per-direction split (per the [API-BYTE-004] rubric) — do NOT blanket-assign `→ Byte`. A parent arc's framing of a site as "deliberate UInt8 / stdlib-interop namespace" may be factually wrong (e.g., a to-be-deleted `UInt8.ascii.X` wrapper); verify against the existing canonical pattern for the spec (e.g. `ASCII.Code+INCITS_4_1986.swift` is the canonical INCITS / US-ASCII substrate) before assuming. Apply the classification at both handoff-write time and cohort-execution time.

**Enforcement**: Discipline rule — the *absence* of an ergonomic forwarder is not mechanically detectable, so this rule has no standalone AST gate. Its mechanical complements are [API-BYTE-006] (`@_disfavoredOverload` required WHEN a `UInt8` forwarder exists) and [API-BYTE-007] (such forwarders live in `* Standard Library Integration` modules). This rule governs the prior decision — whether the forwarder should exist at all, and whether the accumulator should have been `Byte` from construction. [VERIFICATION: manual]


**Cross-references**: [API-BYTE-004] (byte-vs-arithmetic-domain axis this rule is a corollary of; per-direction codec table), [API-BYTE-006] (forwarder-marking discipline this rule narrows), [API-BYTE-007] (SLI module location for forwarders that do exist), [API-BYTE-005] (`ASCII.Code` substrate), [API-BYTE-002] (stdlib-protocol UInt8 retention).

---

### [API-BYTE-005] extension UInt8 MUST NOT declare ASCII-namespace members

**Statement**: `extension UInt8` MUST NOT declare members under the `.ascii` namespace (`static var ascii`, `static func ascii`, nested `enum ASCII`, nested `struct ASCII`). `extension UInt8.ASCII { ... }` (directly extending the ASCII subspace on UInt8) is equivalently forbidden. The canonical typed substrate for ASCII operations is `ASCII.Code`.

**Migration**:

| Before | After |
|--------|-------|
| `UInt8.ascii.lf` | `ASCII.Code.lf` |
| `byte.ascii.X` (on UInt8 var) | `ASCII.Code(byte).X` |
| `extension UInt8 { static var ascii }` | `extension ASCII.Code { ... }` |
| `[UInt8](ascii: ...)` | `[ASCII.Code](...)` or BSLI bridge |

**Enforcement**: Mechanical — `Lint.Rule.Byte.UInt8AsciiExtension` in `swift-foundations/swift-institute-linter-rules`, target `Institute Linter Rule Byte`. Discipline: `Audits/PROMOTE-API-BYTE-005-2026-05-19.md`. [VERIFICATION: AST]

**Cross-references**: [API-BYTE-001] (sibling Q1 rule — UInt8/Byte sibling-form identity); `byte-protocol-capability-marker.md` v1.1.0; `byte-arithmetic-conformance.md` v1.0.0.

---

### [API-BYTE-006] UInt8 forwarders in byte-domain extensions MUST carry @_disfavoredOverload

**Statement**: In byte-domain extensions (`extension [Byte]`, `extension Array<Byte>`, `extension Array where Element == Byte`, `extension ContiguousArray where Element == Byte`, `extension ArraySlice where Element == Byte`, `extension RangeReplaceableCollection where Element == Byte`, and similar stdlib-collection extensions parameterized on `Byte`), any function or initializer that takes a `UInt8` parameter (or returns `[UInt8]` / `Array<UInt8>` / `ContiguousArray<UInt8>` / a type-tree containing `UInt8`) MUST carry the `@_disfavoredOverload` attribute.

**Worked example**:

```swift
// Primary (byte-domain, no @_disfavoredOverload):
extension Array where Element == Byte {
    public init<S: Binary.Serializable>(_ s: S) { ... }
}

// Forwarder (stdlib-interop, MUST carry @_disfavoredOverload):
extension Array where Element == UInt8 {
    @_disfavoredOverload
    public init<S: Binary.Serializable>(_ s: S) {
        let typed: [Byte] = Array(s)
        self = typed.underlying
    }
}
```

Without `@_disfavoredOverload` on the second extension, an unannotated `Array(s)` call site cannot decide between `[Byte](s)` and `[UInt8](s)` and Swift will sometimes prefer the UInt8 form, breaking the Byte-typing the W2 cascade established.

**Enforcement**: Mechanical — `Lint.Rule.Byte.UInt8ForwarderMissingDisfavored` in `swift-foundations/swift-institute-linter-rules`, target `Institute Linter Rule Byte`. Discipline: `Audits/PROMOTE-API-BYTE-006-2026-05-19.md`. [VERIFICATION: AST]

**Cross-references**: [API-BYTE-003] (witness `where`-clause rule with the same `@_disfavoredOverload` exemption shape), [API-BYTE-004] (rawValue domain disposition; the arithmetic-domain bridge often produces UInt8 forwarders that need this attribute).

---

### [API-BYTE-007] Stdlib-interop UInt8 forwarders MUST live in `* Standard Library Integration` modules

**Statement**: `@_disfavoredOverload` UInt8 forwarders DECLARED AS extensions ON stdlib types (`Array`, `ContiguousArray`, `ArraySlice`, `RangeReplaceableCollection`, `Span`, `UnsafeBufferPointer`, …) that bridge between stdlib and byte-domain types MUST live in `* Standard Library Integration` modules (per-package SLI target), NOT in byte-domain primary modules. The rule's subject is the EXTENSION TYPE: extensions on stdlib types carrying stdlib forwarders live in SLI; extensions on INSTITUTE types (`Byte.Input`, `RFC_4122.UUID`, …) with `@_disfavoredOverload` UInt8-accepting inits or methods are LEGITIMATE PRIMARY-MODULE CONVENIENCES and DO NOT belong in SLI — those are bridges that the INSTITUTE type owns. Refines [API-BYTE-003]'s attribute-presence allowlist to a module-location rule, scoped by extension subject.

**Subject scope**: SLI's purpose is to provide overloads ON stdlib types that ACCEPT institute types. The reverse direction (overloads on institute types that accept stdlib types) lives in primary alongside the institute type's other API. Examples:

| Shape | Location |
|---|---|
| `extension Array where Element == UInt8 { @_disfavoredOverload init<S: Binary.Serializable>(_:) }` | SLI |
| `extension ContiguousArray where Element == UInt8 { @_disfavoredOverload init<S: ...>(_:) }` | SLI |
| `extension RangeReplaceableCollection where Element == UInt8 { @_disfavoredOverload mutating func append<S: ...>(_:) }` | SLI |
| `extension Span where Element == UInt8 { ... }` (or `Swift.Array<UInt8>` explicit) | SLI |
| `extension Byte.Input { @_disfavoredOverload init<Bytes: Swift.Collection>(_:) where Bytes.Element == UInt8 }` | **PRIMARY** (extension on institute type) |
| `extension RFC_4122.UUID { @_disfavoredOverload init(_:[UInt8]) }` | **PRIMARY** |

**Enforcement**: Mechanical — `Lint.Rule.Byte.StdlibForwarderOutsideSLI` in `swift-foundations/swift-institute-linter-rules`, target `Institute Linter Rule Byte` (pilot of Post-W2 Arc F SLI consolidation 2026-05-20; narrowed 2026-05-21 to fire only on stdlib-type extension subjects after binary-input-view arc surfaced false positives on `extension Byte.Input` UInt8-convenience inits). The detector walks parent nodes from each `@_disfavoredOverload` function/init up to the enclosing `ExtensionDeclSyntax` and checks the extended type's leaf-name against a curated stdlib-type allowlist (or explicit `Swift.<X>` qualifier). Discipline: `Audits/PROMOTE-API-BYTE-007-2026-05-20.md`. [VERIFICATION: AST]

**Cross-references**: [API-BYTE-003] (witness-signature rule — Binary.Serializable forwarders relocated to `Binary Primitives Standard Library Integration` per this rule), [API-BYTE-006] (`@_disfavoredOverload` attribute requirement — this rule constrains the host module), [API-BYTE-004] (arithmetic-domain exception preserves UInt8-stays-UInt8 storage in primary modules), [API-BYTE-002] (stdlib-protocol corollary preserves `OptionSet.RawValue: UInt8` in primary modules). Nested-type lookup at SLI extension boundary requires fully-qualified parameter / throws types (rfc-8446 + rfc-768 class-c reveal).

---

## Infrastructure notes

**Package.swift Byte dep gap** (Arc B 2026-05-20 observation): `Standard_Library_Extensions` does NOT re-export `Byte_Primitives`. Consumer packages that newly reference `Byte` via the W2 cascade may need to add a direct `swift-byte-primitives` dep to their Package.swift. Surfaced concretely during iso-21320 migration. Future re-export decision is its own design question (whether `Standard_Library_Extensions` SHOULD re-export Byte to spare every consumer the explicit dep); for now, the explicit dep is the working pattern.

## Cross-references

- **byte-protocol-capability-marker.md** v1.1.0 — Q1 anchor (UInt8/Byte sibling-form identity)
- **byte-arithmetic-conformance.md** v1.0.0 — Q3 anchor (Byte has no arithmetic)
- **byte-primitive-extraction-and-domain-naming.md** v1.0.1 — Byte type identity vs UInt8
- **broader-l2-l3-byte-typing-gap-plan.md** § Wave 2 — discrimination rubric
- **broader-l2-l3-byte-typing-gap-plan.md** § "Post-W2 swift-linter byte-discipline arc (parallel arc A)" — arc closeout, ground-truth probe baseline
- **broader-l2-l3-byte-typing-gap-plan.md** § "Post-W2 consumer cascade sweep (parallel arc B)" — arc closeout, 5 discrimination refinements + 1 infrastructure observation (this section captures them)
- **code-surface** skill — [API-NAME-001c] capability-marker protocol recipe; [API-IMPL-020] leaf-body typealias (sibling Conformance-pack rule using the same protocol-family detection pattern)
