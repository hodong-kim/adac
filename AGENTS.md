# AGENTS.md

## Documentation First

Before reviewing, modifying, or generating source code, read and understand all
documents under `docs/`. Source-code work must not begin until the applicable
documentation constraints have been incorporated into the implementation plan.

Roadmap discovery starts at `docs/roadmaps/README.md`. Read that index and every
roadmap it marks applicable to the selected work. `docs/roadmaps/README.md`
owns repository-wide milestone ordering and completion criteria; additional
roadmaps may refine a bounded area without duplicating that authority.

Documentation maintenance follows `docs/README.md`. Contract documents describe
current durable truth and are not append-only development logs. The roadmap
keeps one current resumption checkpoint in place; exact item-specific regression
evidence belongs in tests, and historical checkpoints belong in Git history.

Re-read the roadmap and the documents relevant to the selected work before each
development cycle. If documentation is missing, incorrect, ambiguous, or
inconsistent with the implementation, investigate and resolve the discrepancy
explicitly. Do not silently ignore documentation defects.

Create or update documentation before implementation depends on a new or
changed subsystem, public API, ownership, lifetime, failure, target, or package
boundary contract. Documentation-only corrections may be completed as an
independent development slice.

## Ada Language Reference

For work that reviews, designs, implements, tests, or documents Ada language
behavior, consult the Ada 2022 Annotated Ada Reference Manual (AARM) before
relying on memory, compiler behavior, or secondary summaries. Use the table of
contents and index to locate the relevant clauses, then read the applicable
normative text, annotations, and cross-references.

Use these AARM entry points:

- AdaIC Ada 2022 AARM table of contents:
  https://www.adaic.org/resources/add_content/standards/22aarm/html/AA-TOC.html
- AdaIC Ada 2022 AARM index:
  https://www.adaic.org/resources/add_content/standards/22aarm/html/AA-0-4.html
- Ada-Auth Ada 2022 AARM with Amendment 1 table of contents:
  http://www.ada-auth.org/standards/22aarm_w_amd1/html/AA-TOC.html
- Ada-Auth Ada 2022 AARM with Amendment 1 index:
  http://www.ada-auth.org/standards/22aarm_w_amd1/html/AA-0-4.html

Treat the AdaIC Ada 2022 AARM as the baseline for Ada 2022 language rules. Use
the Amendment 1 edition when the work targets Amendment 1 or when checking
post-Ada-2022 corrections and changes. Determine the intended language revision
before adopting differing wording; do not silently mix rules from different
revisions.

Distinguish normative Reference Manual text embedded in the AARM from AARM
annotations. Annotations provide rationale and implementation guidance but do
not override normative wording. When a relevant annotation identifies an Ada
Issue or a rule remains materially ambiguous, inspect the corresponding Ada
Issue before choosing compiler behavior.

## Ada 2022 Obsolescent Features Policy

Adac targets Ada 2022 language behavior. Do not implement any feature defined
by Ada 2022 RM/AARM Annex J, "Obsolescent Features". Treat Annex J as outside
Adac's supported language subset, consistently with the Ada 2022
`No_Obsolescent_Features` restriction.

Before selecting a language work item, determine whether Ada 2022 Annex J
classifies it as an Obsolescent Feature. If it does, skip it and continue with
the earliest non-obsolescent roadmap prerequisite. Do not add an Annex J feature
as a roadmap prerequisite merely because it remains in the grammar, appears in
an index, has an existing lexer token, or is accepted by another compiler.

Existing implemented behavior is not removed solely by this rule. Removal of
existing Annex J support requires a separate compatibility decision and its own
documented, tested change.

## Repository Temporary Files

Project-controlled temporary files and directories shall use `build/tmp/`
instead of the system `/tmp`. Create `build/tmp/` when needed and direct
tools that honor a temporary-directory override (for example `TMPDIR`) to
that location. Do not depend on free space, cleanup policy, or retained
state in the system `/tmp`. An external tool that unavoidably hardcodes the
system temporary directory is an exception only when no supported override
exists.

## Autonomous Development Loop

An implementation request, including a general instruction such as "start
work", starts the autonomous development loop. A read-only investigation, code
review, question, or planning request does not start implementation.

Continue the following loop until a documented stop condition applies:

1. Inspect the working tree, recent commits, roadmap, and applicable documents.
2. Run `rake check` before the first change to establish the baseline.
3. Select the smallest complete work item from the earliest unmet roadmap
   prerequisite.
4. Define its contracts, success criteria, affected boundaries, and any required
   refactoring.
5. Create or update required contract documentation, then implement the code and
   tests as one vertical slice.
6. Run focused tests followed by `rake check`.
7. Update the applicable roadmap checkpoint from the validated implementation
   state.
8. Review the complete diff, run `git diff --check`, and verify the working-tree
   scope.
9. Commit only the related green change.
10. Reassess the roadmap and implementation state, then select the next work
    item.

Required per-slice order: 구현 → 테스트/검증 → 로드맵 갱신 → diff 검토 → 커밋 순서.

Do not stop after producing a plan when implementation is authorized and no
stop condition applies. A milestone is complete only when its contracts,
implementation paths, validators, positive and negative tests, and applicable
target validation satisfy its documented exit criteria.

## Work Selection And Engineering Quality

Implement language features through every compiler stage they require. Do not
treat parser-only support, disconnected placeholders, or unused state as a
completed feature. Preserve the frontend, AST, semantic analysis, custom IR,
backend, diagnostics, source, and support boundaries.

Preserve explicit ownership, failure categories, deterministic behavior,
bounded resource use, and failure-safe output publication. Do not replace an
internal contract violation with an ordinary source diagnostic or successful
fallback behavior.

Prefer the smallest complete change, but do not use temporary workarounds,
duplicate sources of truth, indefinitely retained compatibility wrappers, or
defensive code that only hides the underlying defect.

## Refactoring

Perform the necessary amount of refactoring when the existing structure cannot
correctly support the roadmap, violates an ownership, lifetime, failure, or
stage-boundary contract, prevents meaningful validation, or cannot meet
large-input and long-term maintenance requirements.

The required scope is determined by the architectural contract, not by a
preference for a small diff. Perform a full subsystem or repository-structure
refactoring when that is necessary for the correct long-term design. Do not
preserve an unsound structure merely to reduce the immediate change size.

Document the purpose and invariants before implementation when refactoring
changes an architectural contract. When practical, divide substantial work
into independently green changes in this order:

1. behavior-preserving structure and tests;
2. new contract or API and tests;
3. caller migration;
4. superseded-path removal and documentation completion.

Every intermediate commit must build and pass its applicable tests. Do not mix
unrelated cleanup, renaming, formatting churn, or speculative abstractions into
the refactoring. Public API or persistent-format changes require an explicit
migration or compatibility decision.

## Roadmap Maintenance

Update roadmap status, ordering, prerequisites, and completion criteria when
implementation and test evidence show that they have changed. Preserve the
long-term goals and do not expand or reduce supported scope without evidence.
The roadmap's long-term objectives and final project direction are user-owned:
automated work shall not remove, replace, narrow, or redefine them unless the
user explicitly requests that roadmap-goal change.

Before every commit that changes development position, update the single current
work checkpoint in the applicable roadmap with the durable current position,
last completed work, remaining work, latest relevant validation, and next work
item. Rewrite that checkpoint in place; do not append a per-commit progress log,
validation ledger, or duplicate checkpoint. Exact item-specific symbol/AST
counts, diagnostic edges, and similar regression evidence belong in tests unless
the number itself is an architectural contract. This update is part of the
commit, not a later follow-up. Keep contract documentation in the same commit as
the implementation that depends on it. Update architecture and repository-layout
documents when a refactoring changes their boundaries. After completing a
milestone, verify its exit criteria before proceeding to the next milestone.

## Working Tree And Commits

Record the initial working-tree and index state. Preserve all user changes.
Ignore unrelated dirty files and never include them in an automated commit. If
an existing change overlaps the selected files, or the index already contains
user-staged changes, stop and report the conflict instead of modifying or
committing over it.

Create one commit for each green vertical slice. Include only files belonging
to that slice and follow the repository's established treatment of tracked
expected and actual test fixtures. Use commit subjects in the form
`<area>: <imperative summary>`.

Do not push, create branches, amend commits, rebase, or rewrite history unless
the user explicitly requests that specific operation.

## Interruption And Resumption

An execution limit, credit exhaustion, process termination, context reset, or
other interruption does not make incomplete work complete and does not
authorize discarding it. `AGENTS.md` cannot bypass platform limits or restart
an agent automatically. A later invocation shall recover from repository state
before continuing.

At the start of every resumed run, before selecting new work:

1. Re-read `AGENTS.md`, the roadmap, and documents relevant to the apparent
   in-progress work.
2. Inspect `git status --short`, unstaged and staged diffs, the diff summary,
   and recent commits.
3. Compare the working tree with the latest green commit and the earliest unmet
   roadmap prerequisite.
4. If the tree is clean, resume from the next unmet work item. If it is dirty,
   determine and finish the coherent in-progress slice before starting another
   slice.
5. Preserve unrelated user changes. If ownership or intent of overlapping
   changes cannot be established safely, stop and report the ambiguity.

Never create an incomplete or failing checkpoint commit merely to record
progress. Commit only a coherent slice whose applicable checks pass. If an
interruption occurs before that point, leave the working tree intact; on
resumption, inspect and continue those changes rather than resetting,
duplicating, or silently replacing them.

Before a planned stop, report the current slice, completed commits, remaining
work, validation already run, and any command still in progress. Update the
roadmap only for durable changes in implementation status, not as a temporary
session log. Replace superseded checkpoint text instead of retaining multiple
historical resume states.

## Stop Conditions

Stop the autonomous loop only when one of the following conditions applies:

- the user pauses, stops, or redirects the work;
- a material product or architecture decision cannot be derived from the
  repository contracts;
- a destructive operation, elevated permission, external credential, or new
  dependency requires approval;
- user changes cannot be separated safely from the selected work;
- a reproducible environment problem prevents validation and no independent
  roadmap work can proceed;
- documentation and implementation contradict each other so that no safe next
  work item can be selected.

If the current environment cannot validate a supported target, do not claim
that target or milestone is complete. Record the outstanding validation and
continue with other independent work when possible.

## Progress Reporting

During work, report the selected slice, relevant contracts, refactoring reason,
and validation status concisely. After each commit, report its identifier,
summary, and checks, then continue the loop.

When a stop condition ends the loop, report completed commits, the current
roadmap position, validation results, the exact blocker, and the next work item.
