# Platform — Compilation Mechanics & C Shims

C shim layer structure, SwiftPM platform conditions, source-level `#if os()` vs `#if canImport()`, module-name normalization, and C-library linker flags, plus two non-rule subsections: Namespace Collision Handling and Conditional Compilation Foresight.

**Rules in this file**: [PATTERN-001], [PATTERN-004], [PATTERN-004a], [PATTERN-004b], [PATTERN-004c]

Full rationale, provenance, and extended worked examples for every rule: `swift-institute/Research/platform-skill-rationale.md` (the rationale archive).

---

### [PATTERN-001] C Shim Layer Structure

**Statement**: Where platform-specific functionality is required, packages MUST use minimal C shim targets isolated from Swift code.

```text
swift-numeric-primitives/
├── _Shims/                           # C target
│   └── include/
│       └── shims.h                   # C declarations
└── Sources/
    └── Real Primitives/
        └── Numeric.Math.swift        # Swift wrapper
```

The C shim layer isolates platform-specific inline assembly, provides unified interface across Darwin (libm), Glibc, Musl, and remains internal.

**Semantic boundary**: Each platform's shim MUST be independent — even when wrapping identical C functions — to maintain independent compilability.

```c
// CORRECT — Separate files per platform
// CDarwinKernelShim/uuid_shim.h
#include <uuid/uuid.h>
static inline int swift_uuid_parse(const char* str, unsigned char* out) {
    return uuid_parse(str, out);
}

// CLinuxKernelShim/uuid_shim.h (SEPARATE FILE - independent)
#include <uuid/uuid.h>
static inline int swift_uuid_parse(const char* str, unsigned char* out) {
    return uuid_parse(str, out);
}

// INCORRECT — Shared header with conditionals
#if defined(__APPLE__)
#include <uuid/uuid.h>
#elif defined(__linux__)
...
#endif
```

Duplication is intentional: packages compile independently, no conditional compilation, platform-specific semantics stay isolated (e.g., Windows `UuidFromStringA` produces mixed-endian bytes).

**Lint enforcement**: Workflow `validate-package-shape.yml` flags any C header under `Sources/` containing BOTH `__APPLE__` and `__linux__` preprocessor checks; single-platform headers with one check are not flagged. [VERIFICATION: WF validate-package-shape.py (PATTERN-001)]

**Cross-references**: [PLAT-ARCH-002], [PATTERN-004c]

---

### [PATTERN-004] SwiftPM Platform Conditions

**Statement**: Platform-specific dependencies MUST use SwiftPM condition directives.

```swift
.product(
    name: "ARM Standard",
    package: "swift-arm-standard",
    condition: .when(platforms: [.macOS, .iOS, .tvOS, .watchOS, .linux])
)
```

**Lint enforcement**: Workflow `validate-package-shape.yml` flags platform-package `.product` references lacking `condition: .when(platforms:` (platform-specific packages exempt — their deps are inherently single-platform). Detail: rationale archive §[PATTERN-004]. [VERIFICATION: WF validate-package-shape.py (PATTERN-004)]

**Cross-references**: [PATTERN-004a]

---

### [PATTERN-004a] Source-Level Platform Conditionals

**Statement**: For platform identity checks, `#if os()` MUST be used instead of `#if canImport()`. `canImport` is appropriate only for optional module availability, not platform identity.

```swift
// CORRECT — Platform identity
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
import Darwin_Kernel_Standard
#elseif os(Linux)
import Linux_Kernel_Standard
#elseif os(Windows)
import Windows_Kernel_Standard
#endif

// INCORRECT — canImport for platform identity
#if canImport(Darwin_Kernel_Standard)
import Darwin_Kernel_Standard
#endif
```

| Check | Evaluated Against | Determinism |
|-------|-------------------|-------------|
| `os()` | Target triple | Always deterministic |
| `canImport()` | Module resolution | Varies by build system |

Use `canImport` for optional features (e.g., `#if canImport(SwiftUI)`). Use `os()` for platform identity.

**Lint enforcement**: `Lint.Rule.Platform.PlatformConditional` flags `canImport(<platform-module>)` conditions (optional-feature modules like `SwiftUI` not flagged). [VERIFICATION: AST Lint.Rule.Platform.PlatformConditional]

**Cross-references**: [PATTERN-004], [PLAT-ARCH-006]

---

### [PATTERN-004b] Module Name Normalization

**Statement**: Swift normalizes Package.swift target names by replacing spaces with underscores. Import statements MUST use the normalized form.

| Package.swift Target | Import Identifier |
|---------------------|-------------------|
| `"Darwin Kernel Standard"` | `Darwin_Kernel_Standard` |
| `"Real Primitives"` | `Real_Primitives` |
| `"IO Primitives"` | `IO_Primitives` |

**Lint enforcement**: Workflow `validate-package-shape.yml` flags target/product name strings mixing BOTH spaces AND underscores (pure spaced and pure spec-namespace-underscored forms are not flagged). [VERIFICATION: WF validate-package-shape.py (PATTERN-004b)]

**Cross-references**: [API-NAME-001], [PATTERN-004a]

---

### [PATTERN-004c] C Library Linker Flags

**Statement**: When a platform requires linking against a C library not automatically provided, linker settings MUST declare the dependency with platform conditions.

```swift
linkerSettings: [
    .linkedLibrary("uuid", .when(platforms: [.linux]))
]
```

| Platform | Library | Linked By Default |
|----------|---------|-------------------|
| Darwin | libc (uuid_parse) | Yes |
| Linux | libuuid | No — requires `-luuid` |
| Windows | Rpcrt4.lib | Yes |

Documentation MUST note external library prerequisites (e.g., `libuuid-dev`).

**Lint enforcement**: Workflow `validate-package-shape.yml` flags `.linkedLibrary(...)` declarations lacking `.when(platforms:`. [VERIFICATION: WF validate-package-shape.py (PATTERN-004c)]

**Cross-references**: [PATTERN-004], [PATTERN-001]

---

### Namespace Collision Handling

When a Swift type name collides with a system module (e.g., `Darwin` type vs Apple's `Darwin` module), usage sites MUST use fully-qualified paths.

```swift
// CORRECT
let uuid = Darwin_Standard_Core.Darwin.Identity.UUID.parse(string)

// INCORRECT — Ambiguous
let uuid = Darwin.Identity.UUID.parse(string)
```

| Type Name | Collides With | Resolution |
|-----------|---------------|------------|
| `Darwin` | Apple's Darwin C module | `Darwin_Standard_Core.Darwin` |
| `Foundation` | Apple's Foundation | Avoid; primitives don't use Foundation |
| `System` | Apple's System module | `System_Primitives.System` |

**Cross-references**: [PATTERN-004b], [API-NAME-001], [PLAT-ARCH-004]

---

### Conditional Compilation Foresight

Packages SHOULD include conditional compilation guards for known future features (Embedded Swift, WebAssembly) proactively.

```swift
#if !hasFeature(Embedded)
extension Tagged: Codable where RawValue: Codable { ... }
#endif
```

| Feature | Embedded | WebAssembly |
|---------|----------|-------------|
| `Codable` | Unavailable | Usually available |
| Existentials (`any`) | Unavailable | Available |
| Runtime reflection | Unavailable | Limited |
| Foundation types | Unavailable | Platform-dependent |

Foresight guards cost nothing when unused and save hours when needed.

**Cross-references**: [PATTERN-004]

---

