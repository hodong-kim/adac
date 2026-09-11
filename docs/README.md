# Documentation Map

This directory contains the authoritative engineering contracts for `adac`.
Each contract has one primary document. Other documents may summarize it, but
shall link to the primary document instead of restating mutable details.

## Authority

| Document | Primary responsibility |
| --- | --- |
| `roadmaps/README.md` | Development roadmap, current work checkpoint, milestone order, and exit criteria |
| `architecture.md` | Logical compiler stages, dependency direction, and cross-stage structure |
| `engineering-principles.md` | Repository-wide design principles |
| `bootstrap-profile.md` | Bootstrap language and source profile |
| `compiler-context.md` | Per-compilation ownership and lifecycle |
| `compiler-identifiers.md` | Rules common to context-owned identifiers |
| `compiler-symbols.md` | Symbol interning and `Symbol_ID` |
| `frontend-context-clauses.md` | Context-clause staging boundary |
| `frontend-declarations.md` | Declarative-part staging boundary |
| `frontend-packages.md` | Package library-unit staging boundary |
| `frontend-subprograms.md` | Subprogram-header staging boundary |
| `frontend-statements.md` | Statement staging boundary |
| `frontend-exception-handlers.md` | Exception-handler staging boundary |
| `frontend-lexing.md` | Frontend token and literal spelling boundaries |
| `frontend-names.md` | Identifier name parsing and symbol ownership |
| `frontend-expressions.md` | Operator-expression staging boundaries |
| `source-spans.md` | Source positions, ranges, and span ownership |
| `ast-model.md` | AST storage, identity, ownership, and validation |
| `ir-validation.md` | IR invariants and validation boundaries |
| `failure-model.md` | Failure categories, propagation, and cleanup |
| `resource-limits.md` | Compilation budgets and exhaustion behavior |
| `semantic-model.md` | Semantic entities, identity, and validation |
| `type-model.md` | Semantic type identity, predefined types, and validation |
| `target-support.md` | Current and planned target support contracts |
| `test-orchestration.md` | Test discovery, execution, and result ownership |
| `repository-layout.md` | Package, source, and test placement |
| `STYLE-GUIDE.md` | Recommended source style and API documentation conventions |

Repository automation and autonomous-work rules are defined by `AGENTS.md` at
the repository root. User-facing build and usage information belongs in the
root `README.md`; it is not an architecture contract.

## Document Roles

Documentation is intentionally split by role so autonomous development can
resume reliably without turning contracts into an append-only work log.

- Contract documents under `docs/` describe the **current durable truth** for
  one subsystem or cross-cutting boundary. They do not preserve the sequence of
  commits that produced that truth.
- `roadmaps/README.md` describes the **current development position**, the next
  unmet work, long-term milestone ordering, and completion criteria.
- Tests and tracked expected fixtures are the authority for **exact regression
  evidence**, including item-specific symbol counts, AST counts, diagnostics,
  and resource-exhaustion edges.
- Git history is the authority for **historical development evidence**: old
  checkpoints, earlier frontier positions, per-commit validation totals, and
  the detailed path by which the current contract was reached.

A fact shall not be copied into several roles merely to make resumption easier.
The current checkpoint links the roles together instead.

## Document Creation Rules

Create a new document only when all of the following are true:

1. the work introduces a durable responsibility or contract boundary that does
   not already have a clear authoritative document;
2. combining that responsibility with an existing document would obscure
   ownership, lifetime, failure, stage, target, or package boundaries; and
3. the new document can be added to the authority map above with one primary
   responsibility that does not overlap another entry.

Do not create a document solely for a feature slice, roadmap item, temporary
checkpoint, validation run, implementation experiment, commit, or historical
progress record. Put those facts in the current roadmap checkpoint, tests, or
Git history according to their role.

When a new authoritative document is necessary, add it to this map in the same
change and replace duplicated descriptions elsewhere with links.

## Document Update Rules

Update existing documents by **replacing superseded state**, not by appending a
new chronological paragraph after every implementation slice.

Contract documents shall contain stable invariants, supported grammar or API
boundaries, ownership, failure behavior, and durable test obligations. They
shall not accumulate:

- commit identifiers or previous checkpoint states;
- ordinal work-item narratives such as first/second/thirty-ninth declaration;
- source-line frontiers whose only purpose is to say where development stopped;
- per-commit assertion totals; or
- exact item-specific symbol/AST counts already fixed by regression tests.

A numeric value belongs in a contract document when the number itself is a
public or architectural contract, such as a configurable limit or hard nesting
maximum. A number that only identifies one regression boundary belongs in the
corresponding test.

Roadmap updates shall rewrite the current position and remaining work in place.
Completed low-level items may be collapsed into a capability summary once their
successor is selected. Do not retain a chronological validation ledger or a
copy of every superseded resume checkpoint.

## Autonomous Development Checkpoint

`roadmaps/README.md` maintains exactly one compact current-work checkpoint for
resumption. It records only what a new development run needs to continue safely:

- active milestone or track;
- last completed work item and commit when applicable;
- current semantic, language, or other concrete next boundary;
- next selected work item and its success condition;
- latest relevant full validation result; and
- any material environment caveat or blocker.

Before a commit changes development position, update this checkpoint **in
place**. After the commit, its commit identifier may be recorded by the next
slice when that identifier is needed for resumption. Do not append a second
checkpoint or duplicate the same state in subsystem contracts.

Detailed in-progress reasoning does not belong in durable documentation. If a
slice is interrupted before a green commit, the working tree, tests, and diff
are the recovery evidence as defined by `AGENTS.md`.

## Maintenance And Cleanup Rules

- Update a contract before or with the implementation that depends on it.
- Put each mutable fact in exactly one authoritative place.
- Keep roadmap entries capability-oriented; subsystem representation belongs in
  the subsystem document.
- Keep summaries short and link to the authoritative contract.
- Remove or rewrite obsolete statements when behavior changes; do not preserve
  them as historical prose in the same contract.
- Remove obsolete contracts and compatibility descriptions when their paths are
  removed from the implementation.
- Reorganize or consolidate documents when boundaries create duplicate sources
  of truth or obscure ownership, lifetime, failure, or stage responsibilities.
- When the same implementation-specific status appears in two documents, treat
  that duplication as documentation debt and eliminate it in the next related
  documentation slice.
- Prefer deleting redundant prose over adding another cross-reference layer.

These rules are part of the autonomous development contract. Documentation must
remain sufficient for a fresh run to resume from the repository, but it is not
required to preserve information already recoverable from tests and Git history.
