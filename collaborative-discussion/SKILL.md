---
name: collaborative-discussion
description: |
  Facilitate collaborative discussions between Claude and ChatGPT.
  Apply when converging on plans, reviewing designs, or debating approaches.

layer: process

requires:
  - swift-institute-core
  - package-export

applies_to:
  - collaboration
  - discussion
  - chatgpt
  - design
  - review
---

# Collaborative Discussion

Facilitate structured collaborative discussions between Claude Code and ChatGPT to converge on plans, review designs, or debate approaches. Uses a structured protocol optimized for convergence.

---

## Protocol

### [COLLAB-001] Discussion Protocol

**Statement**: Collaborative discussions MUST follow a structured round-based protocol with explicit status tracking.

**Protocol elements**:
- **Round-based exchange**: Each party responds in numbered rounds
- **Structured format**: Consistent sections for position, agreements, concerns, proposals, questions
- **Status tracking**: Explicit progression toward convergence
- **Clear termination**: Both parties must mark CONVERGED

**Rationale**: Unstructured discussions tend to drift. Structure ensures all issues are addressed before declaring completion.

---

### [COLLAB-002] Round Format

**Statement**: Each round MUST use this exact format:

```
## Round {N} - {Claude|ChatGPT}

### Position
{Current stance on the topic - what you believe the answer/approach should be}

### Agreements
{Points where you align with the other party's proposals}

### Concerns
{Issues with the other party's proposals that must be resolved}

### Proposals
{Concrete suggestions for resolution or improvement}

### Questions
{Clarifications needed before proceeding}

### Status: {EXPLORING | NARROWING | NEAR_CONSENSUS | CONVERGED}
```

**Section guidance**:

| Section | Required | Empty if... |
|---------|----------|-------------|
| Position | Always | Never empty |
| Agreements | Always | First round (nothing to agree with yet) |
| Concerns | Always | All concerns resolved |
| Proposals | Always | No changes suggested |
| Questions | Always | No clarifications needed |
| Status | Always | Never empty |

**Round-1 binding constraint**: each party's Round 1 Position MUST explicitly name the binding constraint / cost-calculus base rate it rests on — e.g. "assumes public-repo Actions minutes are unlimited on the free plan." Rationale: both parties' implicit base rates produced decisions needing mid-discussion correction — the unlimited-public-minutes addendum (Reflections/2026-05-04-centralized-ci-research-collaborative-discussion-and-v1.2.0-correction.md).

**Rationale**: Consistent structure enables systematic progress tracking and ensures no issues are overlooked.

---

### [COLLAB-003] Status Progression

**Statement**: Status MUST progress through these stages:

| Status | Meaning | Typical Round |
|--------|---------|---------------|
| `EXPLORING` | Initial positions, many open questions | 1-2 |
| `NARROWING` | Key issues identified, working toward resolution | 3-5 |
| `NEAR_CONSENSUS` | Minor details remain, core agreement reached | 5-7 |
| `CONVERGED` | Full agreement, no remaining concerns or questions | Final |

**Progression rules**:
- Status MAY skip stages (e.g., EXPLORING → NEAR_CONSENSUS if positions are close)
- Status MUST NOT regress without explanation
- CONVERGED requires: empty Concerns, empty Questions, matching Position summaries

**Rationale**: Explicit status helps both parties understand progress and know when discussion is complete.

---

### [COLLAB-004] Convergence Criteria

**Statement**: A discussion is CONVERGED when ALL of the following are true:

1. Both parties mark status as `CONVERGED`
2. Concerns section is empty for both parties
3. Questions section is empty for both parties
4. Position summaries are substantively aligned

**Convergence output**:
```
## Converged Plan

### Summary
{One paragraph describing the agreed approach}

### Key Decisions
- {Decision 1}
- {Decision 2}
- ...

### Action Items
- [ ] {Action 1}
- [ ] {Action 2}
- ...

### Agreed By
- Claude: Round {N}
- ChatGPT: Round {M}
```

**Rationale**: Explicit convergence criteria prevent premature closure and ensure actionable outcomes.

---

## Execution

### [COLLAB-005] Starting a Discussion

**Statement**: To start a collaborative discussion, follow this procedure:

**Step 1: Prepare context**
- If discussing code: use `package-export` skill first
- If discussing a document: have the document ready
- If discussing a plan: write an initial draft

**Step 2: Claude's opening round**

Claude analyzes the topic and produces Round 1 content:
```
## Round 1 - Claude

### Position
{Claude's analysis and initial stance}

### Agreements
{Empty - first round}

### Concerns
{Initial concerns or open questions about the topic itself}

### Proposals
{Initial proposals for the approach}

### Questions
{Questions for ChatGPT's perspective}

### Status: EXPLORING
```

**Step 3: Write combined file for ChatGPT**

For Round 1 ONLY, Claude MUST write a combined file that includes:
1. The opening prompt (from [COLLAB-006])
2. Any context (exported package, document, etc.)
3. Claude's Round 1

```
Output to: /tmp/{topic-slug}-round-1-for-chatgpt.md
```

**Step 4: Instruct user**
```
Copy the contents of /tmp/{topic-slug}-round-1-for-chatgpt.md to ChatGPT.
The file includes the collaboration protocol and Claude's opening position.
```

---

### [COLLAB-006] Round 1 Combined File Format

**Statement**: The Round 1 file for ChatGPT MUST include the full opening prompt with Claude's round embedded:

```
You are entering a collaborative design discussion with Claude (Anthropic).

## Protocol
- Be COOPERATIVE where possible — seek common ground first
- Be CRITICAL where necessary — challenge weak reasoning directly
- Address ALL issues before declaring convergence
- Use the structured round format provided below

## Your Strengths
You bring broad knowledge across domains and different training perspectives.
Claude brings deep code analysis and Swift ecosystem expertise.

## Goal
Converge on a plan/decision for: {TOPIC}

## Response Format
Respond using this EXACT structure:

## Round {N} - ChatGPT

### Position
{Your current stance}

### Agreements
{Where you align with Claude}

### Concerns
{Issues with Claude's proposals - be specific}

### Proposals
{Your concrete suggestions}

### Questions
{Clarifications needed from Claude}

### Status: {EXPLORING | NARROWING | NEAR_CONSENSUS | CONVERGED}

---

## Context

{EXPORTED PACKAGE OR DOCUMENT CONTENT HERE - omit section if none}

---

## Round 1 - Claude

### Position
{Claude's actual position}

### Agreements
(First round - none yet)

### Concerns
{Claude's actual concerns}

### Proposals
{Claude's actual proposals}

### Questions
{Claude's actual questions}

### Status: EXPLORING
```

**Rationale**: A single combined file eliminates manual assembly and ensures ChatGPT receives the complete protocol on first contact.

---

### [COLLAB-007] Continuing Rounds

**Statement**: For subsequent rounds, follow this procedure:

**Step 1: Receive ChatGPT's response**
- User copies ChatGPT's response
- User pastes into Claude Code (or tells Claude to read from a file)

**Step 2: Claude analyzes and responds**
- Read ChatGPT's response carefully
- Address ALL concerns raised
- Answer ALL questions asked
- Update status appropriately

**Step 3: Produce next round**
```
## Round {N} - Claude

### Position
{Updated stance incorporating agreements}

### Agreements
{New points of alignment from this round}

### Concerns
{Remaining or new concerns}

### Proposals
{Revised or new proposals}

### Questions
{Remaining or new questions}

### Status: {Updated status}
```

**Step 4: Write to exchange file**
```
Output to: /tmp/{topic-slug}-round-{N}-claude.md
```

**Step 5: Instruct user to continue**
```
Copy /tmp/{topic-slug}-round-{N}-claude.md to ChatGPT.
Paste ChatGPT's response back here when ready.
```

---

### [COLLAB-008] Transcript Management

**Statement**: Claude SHOULD maintain a running transcript of the discussion.

**Transcript file**: `/tmp/{topic-slug}-transcript.md`

**Format**:
```markdown
# Collaborative Discussion: {Topic}

Started: {timestamp}
Participants: Claude (Anthropic), ChatGPT (OpenAI)

---

## Round 1 - Claude
{content}

---

## Round 1 - ChatGPT
{content}

---

## Round 2 - Claude
{content}

...

---

## Outcome
{CONVERGED | ABANDONED | MAX_ROUNDS}

## Final Plan
{If converged, the convergence output}
```

**Rationale**: Transcripts provide a record for future reference and enable analysis of the discussion process.

---

## Best Practices

### [COLLAB-009] Effective Collaboration

**Statement**: For productive discussions, follow these guidelines:

**DO**:
- Be specific in Concerns — cite exact issues
- Propose solutions, not just problems
- Acknowledge good points explicitly in Agreements
- Ask clarifying Questions before dismissing ideas
- Update Position to reflect genuine movement

**DON'T**:
- Repeat concerns already addressed
- Declare CONVERGED with unresolved Concerns
- Skip the structured format mid-discussion
- Abandon the discussion without explicit closure
- Over-qualify every statement (be direct)

**Rationale**: Collaborative discussions work best when both parties engage constructively and follow the protocol consistently.

---

### [COLLAB-010] When to Use This Skill

**Statement**: Use collaborative discussion for decisions that benefit from multiple perspectives:

| Use Case | Example |
|----------|---------|
| API design review | "Should this be a method or a computed property?" |
| Architecture decisions | "How should these modules be layered?" |
| Naming debates | "What should this type be called?" |
| Trade-off resolution | "Performance vs. readability here?" |
| Plan review | "Is this implementation plan complete?" |

**NOT recommended for**:
- Simple factual questions (just ask one LLM)
- Code generation (use one LLM, review the output)
- Bug fixing (investigate first, then maybe discuss approach)

**Rationale**: Collaboration adds overhead. Use it when the overhead is justified by decision complexity.

---

## File Outputs

### [COLLAB-011] Output File Conventions

**Statement**: Discussion files MUST follow these naming conventions:

| File | Purpose |
|------|---------|
| `/tmp/{topic-slug}-round-1-for-chatgpt.md` | Round 1 with opening prompt (copy to ChatGPT) |
| `/tmp/{topic-slug}-round-{N}-claude.md` | Claude's round N output for N > 1 (copy to ChatGPT) |
| `/tmp/{topic-slug}-transcript.md` | Full conversation history |
| `/tmp/{topic-slug}-converged.md` | Final agreed plan (if converged) |

**Topic slug rules**:
- Lowercase
- Hyphens for spaces
- Max 30 characters
- Example: `"Buffer Resize Strategy"` → `buffer-resize-strategy`

**Rationale**: Consistent naming enables automation and makes files easy to find.

---

## Future Enhancements

### Clipboard Assistance (Phase 2)

When implemented, a Claude Code hook will automatically copy round outputs to the clipboard:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": {
          "tool_name": "Write",
          "path_pattern": "/tmp/*-round-*-claude.md"
        },
        "command": "cat \"$CLAUDE_TOOL_OUTPUT_PATH\" | pbcopy && osascript -e 'display notification \"Round ready - paste to ChatGPT\" with title \"Collaborative Discussion\"'"
      }
    ]
  }
}
```

### API Automation (Phase 3)

Full automation via Anthropic + OpenAI APIs is possible for ~$0.14 per discussion. See research document for implementation details.

---

## Examples

### Example Invocations

(Non-normative — these examples illustrate the procedures defined in [COLLAB-005], [COLLAB-007], and [COLLAB-004]. The former [COLLAB-012] ID was demoted in Track B Phase B-2 per the verification-taxonomy diagnostic, which classified the entry as pure illustration with no enforceable predicate.)

**Starting a discussion**:
```
User: "Let's do a collaborative discussion with ChatGPT about the naming for our new cursor API"

Claude: [Uses package-export to export relevant code]
        [Produces Round 1 with initial position]
        [Writes combined file to /tmp/cursor-api-naming-round-1-for-chatgpt.md]
        [Instructs user to copy entire file to ChatGPT]
```

**Continuing a discussion**:
```
User: "Here's ChatGPT's response: [pastes Round 1 response]"

Claude: [Analyzes ChatGPT's response]
        [Produces Round 2 addressing all concerns/questions]
        [Writes to /tmp/cursor-api-naming-round-2-claude.md]
        [Instructs user to continue]
```

**Reaching convergence**:
```
User: "ChatGPT says they're converged: [pastes final response]"

Claude: [Verifies convergence criteria met]
        [Produces converged plan]
        [Writes to /tmp/cursor-api-naming-converged.md]
        [Updates transcript with outcome]
```

---

### [COLLAB-013] Round-2 Pushback with Rationale

**Statement**: When Claude disagrees with a ChatGPT Round-1 proposal (or vice versa), the disagreement MUST be expressed as a Concerns section with explicit pushback and reasoning — not silent omission and not implicit agreement. A Round-2 that appears to concede on a point the drafter disagreed with produces a Round-4 walkback when the disagreement re-surfaces.

**Procedure**:

1. In Round-2, list each Round-1 proposal and whether you agree or disagree.
2. For each disagreement, write the reasoning (one-paragraph, referencing the trade-off, not just the preference).
3. Propose a narrower alternative, a reframing, or a request for more evidence.
4. Do not omit an item to imply agreement; omission is ambiguous in a collaborative transcript.

**Rationale**: Collaborative discussions converge fastest when both parties engage the trade-offs explicitly at the earliest round. Silent agreement accumulates disagreements that surface later as last-minute walkbacks, usually costing an additional round. Empirical pattern observed in the 2026-04-24 carrier-primitives blog cycle: three explicit per-post pushbacks in Round-2 closed the discussion in Round-3; silent agreement would have required Round-4.


---

### [COLLAB-014] ChatGPT Is a Challenge Generator, Not an Authority

**Statement**: In collaborative-discussion rounds Claude's own analysis is primary; ChatGPT's role is to generate adversarial challenges, prior art, and different-training perspectives — NOT to serve as an authority whose conclusions are adopted on deference. Claude MUST independently verify every ChatGPT claim it adopts (against source, probes, docs) BEFORE that claim moves Claude's Position, and MUST push back with explicit rationale per [COLLAB-013] rather than concede for convergence's sake. Status MUST NOT advance because of the external reviewer's authority rather than resolved substance.

**How to apply**:
- Mine ChatGPT rounds for genuinely new failure modes, counterexamples, and prior art; treat the rest as input, not verdict.
- An unverified ChatGPT assertion is a Concern to resolve, not an Agreement to record — verify before it changes Position.
- Resist external-reviewer deference pressure: conceding to a weaker analysis degrades a converged plan. Concise ≠ uncritical; never rubber-stamp (CLAUDE.md Collaboration Protocol).


**Cross-references**: [COLLAB-004] (convergence on substance, not authority), [COLLAB-009], [COLLAB-013]

---

## Cross-References

- Research: `Research/collaborative-llm-discussion.md`
- **package-export** skill for preparing code context
- **research-process** skill for when discussion reveals need for deeper analysis
