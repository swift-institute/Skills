# GitHub Actions authoring constraints

Load this reference for workflow syntax, expressions, composite actions, or
parse/startup failures. These rules describe GitHub Actions interfaces; custom
Institute predicates still belong in Swift.

Before authoring YAML, confirm that repository-policy admits the exact local
file class, triggers, and direct `uses:` references. GitHub accepting a
workflow is not Institute permission to host it.

### [CI-ACTIONS-AUTHOR] Author only admitted local surfaces

Package repositories normally author one thin caller. Tool repositories may
author only the reusable workflows or actions explicitly granted to that tool
owner. Shared jobs, schedules, fleet checks, and cross-repository mutations
belong in central workflows and `swift-institute-bot`.

When a new local shape is legitimate, change the typed whitelist and its
positive/negative/exemption fixtures before or with the YAML. Do not add a
filename exception to a validator after the fact.

### [CI-070] Composite actions run as top-level steps

A composite action is invoked from `steps`, never from inside shell iteration.
If work varies per item, use a matrix or give the Swift executable a typed list.
Do not replace the composite with a sourced shell helper.

### [CI-102] Description fields are plain text

Composite-action `description` fields at the action, input, and output levels
must not contain expression syntax. GitHub parses these as metadata, not runtime
templates.

### [CI-103] `env` is unavailable in early job fields

Do not reference `env.*` from `runs-on` or `container`. Those fields are
resolved before job environment bindings. Use a literal, matrix value, input,
or repository variable supported by that evaluation phase.

### [CI-105] Reusable-call jobs cannot be advisory directly

A job using another workflow with job-level `uses:` cannot also carry
`continue-on-error`. Model advisory posture as a typed input interpreted inside
the called workflow or place it on a normal job.

### [CI-106] Permissions can only narrow down the call chain

Every reusable-workflow hop must receive enough permission for its callees.
Declare the least privilege at the job that performs the operation and verify
the complete caller → wrapper → universal chain. A downstream declaration
cannot restore permission removed upstream.

### [CI-110] Mixed-trigger inputs are nullable

In a workflow supporting both `workflow_call` and event triggers, normalize
typed inputs explicitly before forwarding them. An event without the input is
not equivalent to an asserted Boolean value.

Prefer a planning job that converts event context into closed outputs consumed
by later jobs. Repository-policy separately verifies that every declared
trigger is admitted for that repository class.

### [CI-104] Exercise scheduled workflows through dispatch

A schedule-only path needs a manual dispatch/canary surface with the same Swift
executable, inputs, permissions, and aggregation. A YAML parse check does not
prove the scheduled execution path.

### [CI-100] Do not enable style rules that oppose canonical expression style

The canonical configuration excludes SwiftLint rules that rewrite preferred
Institute expression forms merely for stylistic taste. A package-local style
choice must not contradict swift-linter semantic rules.

### [CI-101] Fix predicates; do not evade regexes

When a custom rule fires on valid code, improve its owning Swift predicate or
add a narrow documented exemption with fixtures. Do not reformat source to
escape a regex, weaken the workflow check, or add an unexplained disable.

## Failure triage

1. A workflow rejected before jobs appear is usually schema, expression-phase,
   permission-chain, or reusable-call shape.
2. A job that starts and fails is an execution or tool problem.
3. A job that skips unexpectedly is planning, `if`, visibility, or input
   normalization.
4. Reproduce the exact evaluator; do not infer correctness from YAML text
   alone.
