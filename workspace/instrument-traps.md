# Instrument traps

Companion to the `workspace` skill. Read this before any large sweep, census, or
claim that something is absent.

Every trap here fails into a clean, confident negative — a zero that looks
exactly like success. None is a logic error.

These are recorded failures, not a checklist to satisfy. The transferable part is
the shape: an instrument that can only fail toward silence needs something that
proves it can speak.

## Do not hand-roll a probe a tool already answers

Ask in this order. Only the third step is allowed to be a `grep`.

1. **Does the question have a lint rule? Run the linter.** A hand-rolled `grep`
   is triage, never evidence. The rules are hardened against shapes a regex does
   not survive: the Foundation-import rule has named cases for
   `public import Foundation`, `import FoundationNetworking`,
   `@_exported import FoundationNetworking`, and `import FoundationXML`. A
   pattern like `@[a-zA-Z]+` **cannot match `@_exported`** — the underscore is
   outside the class — so it returns a clean zero over a file full of imports.
2. **Does Workspace own the fact?** `workspace doctor` for repository state,
   `workspace package dump-package --package-path <p>` for one package's
   evaluated manifest.
3. **Only then inspect source directly.** Bound the population, run a
   known-positive and a known-negative through the same path, state roots and
   exclusions, and label the result triage. Do not claim source inspection is
   equivalent to a controlled instrument.

This ordering is a deletion, not an addition: it subsumes every path-safety,
attribute-class, and word-splitting pitfall below, because in each case a tool
that already handled them existed and was not run.

## Why a zero is the dangerous result

A probe that fails toward "found something" gets investigated — that noise is
self-correcting. A probe that fails toward zero looks exactly like success and
terminates the investigation.

**The prohibition is not what saves you; the control is.** "A zero from a failed
probe is not evidence of absence" has been loaded in context during failures of
exactly this kind and did not fire. What caught them was running a control.

A right answer for the wrong reason is a fail-open. One probe reported a package
Foundation-free; the package *is* Foundation-free, but every import lived in an
umbrella `exports.swift` the pattern could not see. Had one been
`import Foundation`, it would have certified clean — on the exact rule being
ratcheted to `.error`.

So control it, at both ends and at the degenerate case:

- **Pick controls that cannot legitimately be zero** — a known-positive that must
  fire and a known-negative that must not. "Run a positive control" is not
  enough: a control can return zero too and confirm a wrong conclusion twice
  over. Switching to a token that must be non-zero (`struct`, dozens of files) is
  what localises the fault. An expected zero is the least-audited number in any
  census, and a probe that under-reports looks exactly like a clean ecosystem.
- **Match the control to the degenerate case under test.** For a
  visibility-gated resource the control must itself be visibility-gated — GitHub
  returns 404, not 403, for a private repository the caller cannot read.
- **State the population a probe covered**, not merely that it worked. A working
  instrument pointed at the wrong search space yields the same confident zero,
  and two probes of the same design share the blind spot. Treat every automated
  count as a floor and hand-read the residue.

## Shell and tool traps

| Trap | Correct form |
|---|---|
| Bare `grep` here is a shell function wrapping `ugrep --ignore-files --hidden -I` — it honours `.gitignore`, skips binaries, and silently under-reports. The same recursive search has returned 62, then 0, then 0 | `/usr/bin/grep`; likewise `/usr/bin/log` |
| `xargs -a <file>` is GNU-only; BSD xargs exits 1, and piped, the pipeline reports only the last stage's status | `find … -print0 \| xargs -0 …` — also survives spaces in paths, which plain `xargs` word-splits |
| `/usr/bin/ps` does not exist on macOS | `/bin/ps` |
| **`/bin` and `/usr/bin` are strictly disjoint** — a few dozen entries against several hundred, intersection empty. `/bin` only: `cat ps ls cp mv rm date echo`. `/usr/bin` only: `sed grep awk find wc head sort cut xargs stat`. Either directory preference is wrong for most of the other list, and a wrong guess is exit 127 leaving an empty artifact | An absolute path to a coreutil is a per-tool fact, not a directory preference — there is no rule to remember. Know the tool's path, or use the bare name and let PATH resolve it |
| **A failed generator still leaves a valid, empty artifact.** `/bin/sed … > out.sh` → exit 127, `out.sh` created, size 0 — the shell creates the redirect target *before* running the command. `bash out.sh` then exits 0, so a test shelling out to the generated script reports success while testing nothing. `set -o pipefail` does not help; the redirect already happened | Assert the artifact is non-empty and differs from baseline before drawing any conclusion, or check the generator's own exit status |
| **A linter can fall back to a zero-rules configuration** when its manifest path is unset — the engine runs, exits 0, and reports a clean-looking zero having loaded no rules at all | Accept a zero only when the run demonstrably loaded rules: assert `N active rules` with N>0 and files>0, else record UNMEASURED, not clean. An engine's exit status attests that it ran, never that it was configured |
| `timeout(1)` does not exist on macOS — exits 127 without running | None; restructure the probe |
| `script(1)` exits 1 and yields zero bytes whenever its own stdout is a file — indistinguishable from "the program printed nothing", and it fools you even when the program did print | A controlled pty harness, never `script -q /dev/null > file` |
| `swift-format`'s `BeginDocumentationCommentWithOneLineSummary` is platform-dependent — the same version reports findings on Linux and nothing on macOS | Verify that gate in the Linux container, never locally |
| `${PIPESTATUS[0]}` is empty in zsh | `$pipestatus[1]`, or a bare `$?` |
| **`find $ROOTS …` scans nothing under zsh when `$ROOTS` holds several paths** — zsh does not word-split unquoted parameter expansions, so `find` receives one argument (the space-joined string), which is not a path; a trailing `2>/dev/null` swallows the error and the probe returns 0 across every candidate. Localised stage by stage: single root 6612 ✅ · single root + `! -path` 68 ✅ · three roots via `$VAR` 0 ❌ · three roots literal 2343 ✅ | Use an array (`find "${roots[@]}"`), literal paths, or one root per invocation — and never pair a multi-root `find` with `2>/dev/null` |
| **In zsh a variable named `path` IS `$PATH`** (they are tied). A helper doing `path="$2"` silently replaces PATH with a directory; every subsequent command 127s and the sweep reports 0 findings across every package — a perfect false clean | Never name a local `path` (use `pkg_dir`), and run the positive control through the same function as the measurement — a top-level preflight passes because it executes before the clobber |
| `\b` is unsupported by Apple git's `grep -E` — silent zero | Test the regex against a known match first |
| **BSD `grep` has no `-P`** — it exits 2 and prints nothing, which reads exactly like "no matches in the population". Caught mid-flight reporting *none* in scope where the truth was 7 of 8 | `awk` with a field-exact match, or `/usr/bin/grep -E`, paired with a positive control — the failure is a confident empty, not an error |
| **BSD `sed` does not support `\b` either — it matches nothing and reports success.** In a four-family rename it silently left one family unrepaired while the other three succeeded: a partial success that looks complete | Use `[^A-Za-z0-9_]` anchors or `perl -pe`, then re-count the stale references and require 0 — the edit is proven by re-measuring, never by `sed`'s exit status |
| `git log --since=<bare ISO date>` returns zero for that day | `--since='<date> 00:00'` |
| **`gh run view --log-failed` is run-scoped, not job-scoped** — it returns the failed-step logs of every failing job in the run. With 5–16 failing jobs, sampling them and labelling the result with one platform's name manufactures a dominant cause that does not exist in that job | Always pass `--job <id>`; verify by grepping the suspected signature inside the target job and expecting zero in the others |
| **Windows CI logs are CRLF** — a `[^\r]` or `.` capture truncates mid-message (`error: 'semapho`) and then merges unrelated failures under a shared prefix | Strip `\r` before matching, or anchor on the full message; treat any truncated-looking diagnostic as un-parsed rather than as data |
| **`find`'s `-o` binds looser than the implicit AND, so an exclusion after an alternation covers only the last branch.** `find … -name '*.c' -o -name '*.h' -not -path '*/.build*'` parses as `-name '*.c'` OR `(-name '*.h' AND -not -path …)`, so every `.build/` `.c` file is counted. This reported 170 of 268 packages as shipping C sources; parenthesised, the truth is 11 — inflated ~15×. **This trap widens silently instead of failing**, so it is caught by implausible magnitude rather than by an error | Parenthesise every alternation — `find … \( -name '*.c' -o -name '*.h' \) -not -path '*/.build*'` — and sanity-check the magnitude: a figure that would be surprising if true is the tell |
| `head`/`tail` truncate the *evidence*, not just the display, and a pipeline's exit status becomes the pager's | Count first, then page; or redirect to a file and set `-o pipefail` |

Check the status of the stage you care about, not the pipeline's — most of the
above become invisible the moment they are piped. A shell chain joined on `&&`
reports "did not run" and "ran, found nothing" identically: split the chain, or
check exit status per stage.

## Two house conventions manufacture these hazards

Both are deliberate, which is why they are not perceived as hazards:

- **Target directories are space-separated** (`Sources/Products Live/`). Any
  pattern assuming a path has no spaces — `[^ ]+`, an unquoted expansion, a
  `sed` pattern — silently drops exactly those paths.
- **Umbrella `exports.swift` files carry the imports**, often as
  `@_exported public import`. A per-file scan of ordinary sources finds none.

So the test is never *which tool am I using* but **would this still match
`Sources/Products Live/exports.swift` and the `@_exported` line inside it?**
Prove it against a known-matching case before trusting any count over the tree.

These also defeat magnitude sanity-checks. One figure was inflated by rule-tag
double-counting and its correction deflated by word-splitting — two errors in
opposite directions on one number (80, then 47; true value 59), each making the
other look plausible.

## Reading results

- Use absolute paths or `git -C`; the shell working directory changes between
  commands.
- Search for the file as it is actually spelled — glob the stem, then narrow.
- Exclude every `.build*` directory, including nested ones under `Tests/`. Parse
  manifests with an authoritative probe, never a comment-blind single-line grep.
- A compiler error list is a lower bound. Enumerate the affected token family and
  re-run after each fix.
- **Attribute imports to a target, never to a directory.** SwiftPM compiles
  targets; a `Sources/` directory no target claims is dead source that compiles
  nowhere, and counting it manufactures dependency edges ecosystem-wide.
- **`@_exported` re-exports let a consumer bind a package's types without naming
  it in any manifest.** Every manifest-derived in-degree therefore under-reports,
  and "zero consumers" is an upper bound on consumption rather than a measurement
  of it. Chase the re-export chains before retiring anything.
- **Macro expansions reach modules named in no import statement**, as
  `@testable` reaches internal surface. A source-import derivation misses both.
- **Four states, four probes:** *absent* (`ls`) · *untracked* (`git ls-files`) ·
  *ignored* (`git check-ignore`) · *published* (`git grep <remote-ref>`).
  `rev-parse --show-toplevel` answers only which repository owns a path and is
  evidence of none of them. Audit exposure against the pushed ref, never the
  working tree.
- **A configured remote URL is not remote identity** — `git remote get-url`
  returns what `.git/config` says, not what it resolves to today. Resolve with
  `gh repo view`, and resolve `isArchived` alongside visibility.
- **A name is not a capability.** Verify the dependency class of the thing you
  would consume, not merely that the symbol resolves.
- **A census of a live workspace is a measurement with a timestamp, not a fact.**
  Date every figure and expect drift rather than reading a mismatch as a defect.
- **"X cannot be done" is a claim about the world, not about your toolbox.** Probe
  the environment that would provide the capability before declaring it absent.
- **A directory holding several checkouts is not itself a git root.** Sibling
  repositories are separate roots, so probing the parent gives a false "commit
  not found". Derive a package's location from the Workspace inventory, never
  from the tree.
- **Verify a push against the real remote** (`git ls-remote`), never a cached
  tracking ref. Local HEAD equal to `ls-remote` after your own push does not
  prove your push landed — verify content-level against the pushed tree.

## Long-running work

- **Monitors and background watches do not survive compaction** — the task list
  returns empty and nothing surfaces an error, while the watched work keeps
  running unobserved. Re-arm every watch after a compaction, and verify a monitor
  by observing its first event, never by its arming.
- **A persistent watch pipeline must end in a line-buffered stage.** `cut` and
  `head` block-buffer on pipes and can deliver nothing for hours; end with
  `grep --line-buffered`, or `awk` with `fflush`.
