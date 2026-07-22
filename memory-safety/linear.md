# Memory Safety — Linear and Affine Types

Part of the **memory-safety** skill. See `SKILL.md` for the navigation hub, frontmatter, and rule index.

**Rules in this file**: [MEM-LINEAR-001], [MEM-LINEAR-002], [MEM-LINEAR-003].

---

## Linear and Affine Types

### [MEM-LINEAR-001] Exactly-Once Types

**Statement**: Linear types MUST be `~Copyable` with a `consuming func` for the use operation and a `deinit` that traps if not consumed.

---

### [MEM-LINEAR-002] At-Most-Once Types

**Statement**: Affine types MUST be `~Copyable` with a `consuming func` and a silent `deinit` (no trap).

| Semantics | `deinit` Behavior |
|-----------|-------------------|
| Exactly-once (linear) | `preconditionFailure` |
| At-most-once (affine) | Silent — unused is valid |

---

### [MEM-LINEAR-003] Proof Categories

| Invariant | Ownership Encoding | Compiler Enforcement |
|-----------|-------------------|---------------------|
| Exactly-once use | `~Copyable` + `consuming func` + `deinit` trap | Double-use at compile time; dropped-without-use at runtime |
| At-most-once use | `~Copyable` + `consuming func` + silent `deinit` | Double-use at compile time |
| Transfer semantics | `consuming` parameter | Caller cannot use value after transfer |
| Borrow semantics | `borrowing` parameter | Callee cannot consume or store |

---

