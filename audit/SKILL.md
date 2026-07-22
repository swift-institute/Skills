---
name: audit
description: |
  Check code against skill requirement IDs and record findings.
  Apply when auditing convention compliance or when the user invokes /audit.

layer: process
requires:
  - swift-institute
applies_to:
  - swift-primitives
  - swift-standards
  - swift-foundations
---

# audit

Check a target's code against the relevant skill rules and write down what's wrong.
The former status taxonomy, index files, staleness flags, one-commit-per-finding
rhythm, and consolidate-on-contact protocol are gone (solo-dev ceremony cut,
2026-07-18) — keep it a plain findings list you can re-run.

## Procedure

1. Pick the target (a package, or the whole layer) and the skills that apply to it
   (see the skill-routing map in `CLAUDE.md`).
2. Read the code against each skill's rules. For mechanical rules, grep; for shape
   rules, read. Positive-control every probe — a zero from a broken probe is not a
   clean result.
3. Write findings to `Audits/audit.md` (gitignored; one file, most-severe first).
   Each finding: the rule ID, the file:line, and what's wrong. That's enough.
4. Fixing is separate from auditing — record first, fix in a normal edit pass. Re-run
   the audit to confirm a finding is closed; delete closed rows or strike them, your call.

There is no required table schema, no `_index.json`, no staleness cadence. If the
audit is stale, re-run it.
