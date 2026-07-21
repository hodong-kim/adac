# Compiler Context

This document defines the ownership and lifecycle contract for one Adac
compilation. It establishes the foundation for Milestone 1 without changing the
supported Ada subset or compiler pipeline.

## Purpose

A compilation context represents state that belongs to exactly one compilation.
It provides an explicit owner for cross-cutting state that would otherwise be
process-global, passed independently through unrelated APIs, or attached to the
wrong compiler stage.

The context exists to support:

- independent compilations in one process;
- deterministic ownership and cleanup;
- diagnostics and identifiers that cannot leak between compilations;
- bounded resource use and cancellation in later changes;
- explicit stage contracts without merging stage responsibilities.

The context is not a replacement for the compiler pipeline. The frontend, AST,
semantic analysis, custom IR, and backend remain separate subsystems.

## Package And Type

The context is defined by `Adac.Compilation.Context`.

`Adac.Compilation` owns compilation-wide state and lifecycle contracts. It does
not perform lexing, parsing, semantic analysis, IR construction, or backend
emission.

`Context` is a limited type. A context is not copied because its owned stores
and resources have identities and cleanup whose ownership must remain
unambiguous.

## Current Implementation

The context currently owns language options, immutable resource limits,
diagnostic state, a source file registry, an interned symbol store, and an
append-only AST store.

```text
Compilation.Context
  language options
  resource limits
  diagnostic state
  source file registry
  symbol store
  AST store
```

The driver creates one context for each compilation and keeps it alive while the
frontend, semantic analysis, IR, and backend stages execute. Stages that report
source errors borrow the context for the duration of the call.

`Adac.Compilation.create` is the only operation that constructs a valid
context. Ada permits a caller to default-initialize the limited private type,
but that object remains uninitialized and shall not be passed to a context
operation. Every public context operation validates this state and raises
`Program_Error` before reading or modifying owned state when the object was not
created.

`Adac.Diagnostics.State` defines the diagnostic state representation.
`Adac.Compilation` composes that state into `Context`, while
`Adac.Compilation.Diagnostics` provides context-scoped diagnostic operations.
This dependency direction keeps diagnostic representation independent of the
compilation package and avoids package-level mutable state.

A newly created context starts with zero diagnostics. A context is not reset for
reuse, and diagnostic state from one context is not visible through another
context.

Diagnostic rendering still writes immediately to standard output. Independent
error counts therefore do not yet make concurrent output rendering atomic or
ordered across threads.

`Adac.Source.Registry` registers each exact source path once and assigns a
context-local `Source_File_ID`. Positions contain the identifier rather than a
copy of the path. The registry validates that an identifier belongs to the
context before resolving it. The detailed identifier contract is defined in
`compiler-identifiers.md`.

The registry does not own open file handles or source text. The frontend lexer
continues to own and close its input file while parsing.

The following state remains outside the context:

- source text and open source file handles;
- semantic storage;
- type information;
- IR storage;
- target configuration;
- cancellation state;
- resource counters other than AST node count.

These items shall be moved only when their own contracts and tests are added.
Unused placeholder fields shall not be added to the context.

## Responsibilities

The context owns state whose lifetime spans compiler stages or whose identity
must be isolated from other compilations.

Current context-owned state includes:

- diagnostic state;
- language options;
- immutable resource limits;
- source file registry and source file identifiers;
- interned identifier spellings and symbol identifiers;
- append-only AST storage and node identifiers.

Planned context-owned state includes:

- semantic entities and type information;
- IR storage;
- target options;
- cancellation state;
- additional resource accounting and limits.

Each owned subsystem may define its own state or storage type. The context
composes those types. Subsystems shall not depend on `Adac.Compilation` merely
to recover their own representation.

## Non-Responsibilities

The context does not own process-wide command-line behavior or operating-system
exit status. Those remain driver responsibilities.

The context does not define source syntax, AST node kinds, semantic rules, IR
instructions, ABI behavior, or output formats. Those remain in their existing
subsystems.

The context does not convert failures between categories. Expected input
failures, external operational failures, and internal contract violations
remain distinct as defined by `failure-model.md`.

## Lifecycle

One context represents one compilation attempt.

The conceptual lifecycle is:

```text
uninitialized
  -> created
created
  -> frontend
  -> semantic analysis
  -> IR construction
  -> backend emission
  -> completed
```

A compilation may instead enter a failed or cancelled terminal state from any
stage.

The initial stored state distinguishes only `uninitialized` from `created` and
enforces construction through `Adac.Compilation.create`. It does not yet record
pipeline stages, completion, failure, or cancellation. Those transitions shall
be introduced only with operations and validators that enforce them.

A context shall not be reset and reused for an unrelated compilation. A new
compilation receives a new context with clean owned state.

Objects owned by one context shall not be referenced through another context.
A later identifier or validator API shall treat such a reference as an internal
compiler contract violation.

## Ownership And Lifetime

The driver creates the context before entering the compiler pipeline. The
context remains alive until the compilation succeeds or fails and all owned
resources have been released.

The long-term ownership model is:

```text
Driver
  owns Compilation.Context

Compilation.Context
  owns compilation-wide stores and state

Compiler stages
  borrow the context or specific owned state for the duration of a call
```

A stage shall not retain a borrowed reference beyond the documented lifetime of
the context or the referenced store.

Values may be copied between stages only when the copy is intentional and its
cost is bounded. Large source text, repeated file paths, AST nodes, semantic
entities, and IR objects should normally be owned once and referenced by stable
identifiers.

Normal and exceptional exits shall release all resources owned by the
compilation. Cleanup shall not hide the primary failure. Failed compilation
output shall not be published as a successful result.

## Stage Boundaries

The context may be passed through stage APIs, but doing so does not transfer the
stage's responsibility to `Adac.Compilation`.

The intended dependency direction is:

```text
Adac.Compilation
  owns state types defined by source, diagnostics, AST, semantic, and IR layers

Frontend, semantic analysis, IR construction, and backend
  operate on the context or on explicitly borrowed state
```

Circular dependencies between a stage package and `Adac.Compilation` shall be
avoided. Storage and state representations may need to be separated from stage
algorithms before they are added to the context.

Target-specific ABI, object format, and toolchain behavior shall not enter the
frontend, AST, semantic model, or target-independent IR through the context.

## Thread Safety And Parallel Compilation

Different contexts must be usable independently in the same process. State
owned by one context shall not be visible through another context.

The existence of independent contexts does not make every shared process
facility automatically thread-safe. Diagnostic rendering, standard output,
external tool invocation, caches, and final output publication require explicit
synchronization or isolation contracts before concurrent use is supported.

No package-level mutable state may be introduced as a shortcut for context
access.

Operations on the same context are sequential unless an operation explicitly
documents a stronger concurrency contract. Future parallel work inside one
compilation must preserve deterministic externally visible ordering.

## Stable Identifiers

`Source_File_ID`, `Symbol_ID`, and `Node_ID` are the stable identifiers currently
implemented by the compiler. Each identifier belongs to one context-owned store
and contains a deterministic one-based index plus a runtime ownership marker.
The marker detects cross-context use but is not part of serialized or
externally visible identity.

The source registry preserves the exact path spelling supplied to the frontend.
Registering the same exact path again in one context returns the existing ID.
Path canonicalization, symlink resolution, and file-system case folding are not
performed implicitly.

Positions now store `Source_File_ID`, line, and column. Diagnostic rendering
resolves the path through the owning context. Passing an invalid, out-of-range,
or foreign identifier to a registry is an internal compiler contract violation.

AST nodes are immutable after publication in the context-owned append-only
store. Compiler stages pass private `Node_ID` values rather than copying node
records or retaining raw pointers. Structural AST validation checks node shape
and span containment, while context-aware validation rejects foreign node,
symbol, and source identifiers. The detailed contracts are defined in
`ast-model.md` and `source-spans.md`.

Planned identifier kinds include:

```text
Entity_ID
Type_ID
```

The common identifier rules, ownership checks, determinism requirements, and
serialization boundary are defined in `compiler-identifiers.md`.

## Result Types

Stage-specific result types will replace Boolean-only APIs incrementally.
Results shall distinguish ordinary unsuccessful compilation from payload values
that are valid for the next stage.

`Adac.Frontend.Parse_Result` is a discriminated result. `Parse_Rejected` has no
AST payload, while `Parse_Succeeded` contains the root `Node_ID` in the AST
store owned by the supplied context. A rejection means that ordinary source
diagnostics were recorded. External input failures and internal contract
violations continue to propagate as exceptions.

`Adac.Sema.Analysis_Result` distinguishes `Analysis_Rejected` from
`Analysis_Succeeded`. A rejection means that the semantic stage recorded
ordinary source diagnostics and did not produce permission to enter IR
lowering. Internal compiler contract violations continue to propagate as
exceptions. Semantic analysis borrows the context and root node identifier and
does not transfer their ownership.

`Adac.Backend.Emission_Result` distinguishes published output from an external
operational failure. The failure variant owns a diagnostic message for the
driver. Backend implementation contract violations continue to propagate as
exceptions and are not converted into operational failures.

Detailed diagnostics remain in diagnostic state. A stage result indicates
whether the stage produced a usable output and, where appropriate, the failure
category.

Internal contract violations shall not be hidden in an ordinary failure result.
They may be intercepted only at the top-level failure boundary to clean up,
prevent output publication, and report an internal compiler error.

## Validators

Validators check internal stage contracts. They do not replace parser or
semantic checks for user input.

The initial AST validator rejects missing procedure names, missing end names,
and empty statement lists before a successful parse returns or semantic
analysis begins. It leaves name matching to semantic analysis because that rule
depends on language options. Its contract and extension rules are defined in
`ast-model.md`.

The initial IR validator rejects a missing entry name and an empty instruction
list before a module leaves the builder or enters the backend. Its contract and
extension rules are defined in `ir-validation.md`.

Planned validators include:

- additional context state validators as lifecycle transitions are stored;
- additional AST validators as syntax representations grow;
- additional IR validators as typed and control-flow representations grow.

A validator failure is an internal compiler contract violation. Validation must
occur before a malformed internal representation is passed to a later stage or
published as output.

Validation work shall be bounded or covered by resource accounting for large
inputs.

## Cancellation And Resource Limits

Each context owns an immutable resource-limit policy. The current
implementation enforces an AST node budget before node publication and converts
parser exhaustion into a controlled source diagnostic. The detailed contract
is defined in `resource-limits.md`.

Future limits may cover source bytes, token count, identifier count, semantic
entities, IR objects, diagnostics, nesting depth, and backend temporary storage.
Cancellation is not implemented yet.

Cancellation shall be checked only at documented safe points. A cancelled
compilation shall release owned resources and shall not publish partial output.

## Migration Sequence

State shall move into the context in small, independently testable changes.
The minimal context, diagnostic-state migration, source registry, initial stage
result types, interned symbols, context-owned AST arena and `Node_ID`, initial
AST source spans, initial AST and IR validators, and the AST node budget are
complete. The next planned sequence is:

1. extend AST and IR validation with each new representation;
2. expand in-process tests as additional context-owned state is introduced;
3. add cancellation and additional resource accounting when their contracts
   are defined.

The sequence may change when implementation constraints require it, but each
change shall preserve existing frontend, AST, semantic, IR, backend, failure,
and target boundaries.

## Diagnostic Migration Completion Criteria

The diagnostic migration is complete when:

- every compilation context owns independent diagnostic state;
- a new context starts with zero errors without a reset operation;
- parser, semantic, driver, and backend-boundary diagnostics use that context;
- diagnostics from one context do not change another context's error count;
- existing compiler diagnostic text and exit behavior remain unchanged;
- no package-level mutable diagnostic state remains;
- repository checks pass.

## Source Registry Completion Criteria

The source registry migration is complete when:

- every compilation context owns an independent source registry;
- every registered path receives a context-local `Source_File_ID`;
- re-registering the same exact path returns the existing identifier;
- positions store source file identifiers instead of copied paths;
- diagnostics resolve positions through the owning context;
- invalid and cross-context identifiers are rejected as contract violations;
- existing compiler diagnostic text and exit behavior remain unchanged;
- in-process tests verify source registry isolation;
- repository checks pass.
