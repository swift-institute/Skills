# Memory Safety — Reference Primitives

Part of the **memory-safety** skill. See `SKILL.md` for the navigation hub, frontmatter, and rule index.

**Rules in this file**: [MEM-REF-001], [MEM-REF-002], [MEM-REF-003], [MEM-REF-004], [MEM-REF-005].

---

## Reference Primitives

### [MEM-REF-001] Reference Primitive Selection

| Type | Ownership | Mutability | Sendable |
|------|-----------|------------|----------|
| `Reference.Box` | Strong | Immutable | When `Value: Sendable` |
| `Reference.Indirect` | Strong | Mutable | Not Sendable (use `.Unchecked`) |
| `Reference.Weak` | Weak | N/A | When `Object: Sendable` |
| `Reference.Unowned` | Unowned | N/A | Not Sendable |
| `Reference.Slot` | Strong | Move semantics | `@unchecked` (atomic) |
| `Reference.Transfer` | One-shot | Move-only | Tokens are Sendable |
| `Reference.Sendability.Unchecked` | N/A | Immutable | `@unchecked` (assertion) |

---

### [MEM-REF-002] Reference.Box

**Statement**: Use `Reference.Box` for immutable heap allocation of `~Copyable` values.

---

### [MEM-REF-003] Reference.Indirect

**Statement**: Use `Reference.Indirect` for mutable heap-allocated values. NOT Sendable by design. Use `.Unchecked` for explicit cross-isolation transfer.

---

### [MEM-REF-004] Reference.Transfer

**Statement**: Use `Reference.Transfer` for moving `~Copyable` values across `@Sendable` boundaries with exactly-once semantics.

| Type | Use Case | Allocation |
|------|----------|------------|
| `Cell<T>` | Pass existing value through escaping boundary | One (box) |
| `Storage<T>` | Create inside closure, retrieve after | One (box) |
| `Retained<T>` | Zero-allocation class transfer | Zero |

All invariant violations trap deterministically (not undefined behavior).

---

### [MEM-REF-005] Reference.Slot

**Statement**: Use `Reference.Slot` for atomic, reusable store/take operations on `~Copyable` values.

Key difference from Transfer: Transfer is one-shot; Slot is reusable (empty <-> filled, cycles indefinitely).

---

