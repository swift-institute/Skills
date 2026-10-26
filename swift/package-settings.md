# Package settings

Companion to the `swift` skill. Read this when writing or changing a
`Package.swift`.

## Pins and language mode

`InternalImportsByDefault` makes import visibility a module contract: a type
named in an `@inlinable` declaration must be imported with `public import`,
consistently across the module's files. `MemberImportVisibility` extends the same
logic to members, which is why a re-export can surface a type without surfacing
its cases.

## Products and targets

Expose several small `.library` products rather than one aggregate — a consumer
that wants one capability should not compile the rest.

Keep implementation-root targets — those holding only the namespace enum —
internal and unpublished; variant targets carry the namespace outward with
`@_exported public import`.

SwiftPM normalizes spaces in target names to underscores, so `"Darwin Kernel
Standard"` imports as `Darwin_Kernel_Standard`. Never mix spaces and underscores
in one name; pick the spaced form and let the normalization do the rest.

## Linking and platform conditions

Declare libraries the platform does not link automatically, always conditioned:

```swift
.linkedLibrary("uuid", .when(platforms: [.linux]))
```

Linux needs `-luuid`; Darwin and Windows link theirs by default.
Platform-specific `.product` dependencies carry `condition: .when(platforms:)`.

Guard known-absent features proactively with `#if !hasFeature(Embedded)` around
`Codable`, existentials, and reflection-dependent code — an L1 package that
compiles for Embedded is one that was written for it, not one that happened to
avoid the features.
