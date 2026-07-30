# Verdict rubric

Use this rubric to challenge a proposed review verdict without expanding the
review into a general audit.

| Dimension | Question |
| --- | --- |
| Object | Is every claim bound to the live exact head and owning Issue? |
| Scope | Does each finding arise from the changed surface or a required gate? |
| Evidence | Are checked, task-attributed, and inferred claims distinguishable? |
| Independence | Did the reviewer form its own judgment without mechanically repeating sufficient evidence? |
| Actionability | Does a blocker name the smallest fix another owner can execute? |
| Stop | After the verdict became fixed, did unrelated verification and CI enumeration stop? |
| Landing | If clean, were all relevant gates and exact-state guards satisfied immediately before mutation? |
| Exposure | Is the public payload free of private or machine-specific material? |
| Handoff | Is the next owner explicit, with no reviewer/fixer overlap? |

Conflicting evidence is itself a finding. Resolve only the conflict that can
change the verdict.
