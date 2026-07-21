# AGENTS.md

## Documentation First

Before reviewing, modifying, or generating source code, read and understand all
documents under `docs/`. Source-code work must not begin until the applicable
documentation constraints have been incorporated into the implementation plan.

Re-read the roadmap and the documents relevant to the selected work before each
development cycle. If documentation is missing, incorrect, ambiguous, or
inconsistent with the implementation, investigate and resolve the discrepancy
explicitly. Do not silently ignore documentation defects.

Create or update documentation before implementation depends on a new or
changed subsystem, public API, ownership, lifetime, failure, target, or package
boundary contract. Documentation-only corrections may be completed as an
independent development slice.

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
5. Create or update the required documentation, then implement the code and
   tests as one vertical slice.
6. Run focused tests followed by `rake check`.
7. Review the complete diff, run `git diff --check`, and verify the working-tree
   scope.
8. Commit only the related green change.
9. Reassess the roadmap and implementation state, then select the next work
   item.

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
4. obsolete-path removal and documentation completion.

Every intermediate commit must build and pass its applicable tests. Do not mix
unrelated cleanup, renaming, formatting churn, or speculative abstractions into
the refactoring. Public API or persistent-format changes require an explicit
migration or compatibility decision.

## Roadmap Maintenance

Update roadmap status, ordering, prerequisites, and completion criteria when
implementation and test evidence show that they have changed. Preserve the
long-term goals and do not expand or reduce supported scope without evidence.

Keep contract documentation in the same commit as the implementation that
depends on it. Update architecture and repository-layout documents when a
refactoring changes their boundaries. After completing a milestone, verify its
exit criteria before proceeding to the next milestone.

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
