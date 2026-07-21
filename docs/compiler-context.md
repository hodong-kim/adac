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

`Context` is a limited type. A context is not copied because future context
state will include owned stores and resources whose identity and cleanup must
remain unambiguous.

## Current Implementation

The context currently owns language options and diagnostic state.

```text
Compilation.Context
  language options
  diagnostic state
```

The driver creates one context for each compilation and keeps it alive while the
frontend, semantic analysis, IR, and backend stages execute. Stages that report
source errors borrow the context for the duration of the call.

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

The following state remains outside the context:

- source files and source text;
- AST and semantic storage;
- type information;
- IR storage;
- target configuration;
- cancellation state;
- resource limits.

These items shall be moved only when their own contracts and tests are added.
Unused placeholder fields shall not be added to the context.

## Responsibilities

The context owns state whose lifetime spans compiler stages or whose identity
must be isolated from other compilations.

Current context-owned state includes:

- diagnostic state;
- language options.

Planned context-owned state includes:

- source file registry;
- interned identifiers;
- AST storage;
- semantic entities and type information;
- IR storage;
- target options;
- cancellation state;
- resource accounting and limits.

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
created
  -> frontend
  -> semantic analysis
  -> IR construction
  -> backend emission
  -> completed
```

A compilation may instead enter a failed or cancelled terminal state from any
stage.

The first implementation does not store this state machine. A stored state shall
be introduced only with operations and validators that enforce its transitions.

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

Stable identifiers will be introduced incrementally. Planned identifier kinds
include:

```text
Source_File_ID
Node_ID
Symbol_ID
Entity_ID
Type_ID
```

Each identifier kind shall be a distinct type. Different identifier kinds shall
not be implicitly interchangeable.

An identifier shall have an explicit invalid state. Valid identifiers shall
refer only to storage owned by the context that created them.

Identifier allocation shall be deterministic for identical compiler inputs and
options. Allocation order shall not depend on hash iteration order or unrelated
parallel scheduling.

Identifier creation shall check overflow and resource limits. External callers
shall not be able to manufacture arbitrary valid identifiers when encapsulation
can prevent it.

`Source_File_ID` is the preferred first identifier. It will allow positions and
spans to reference a context-owned source registry instead of copying a file
path into every token or node.

## Result Types

Stage-specific result types will replace Boolean-only APIs incrementally.
Results shall distinguish ordinary unsuccessful compilation from payload values
that are valid for the next stage.

Detailed diagnostics remain in diagnostic state. A stage result indicates
whether the stage produced a usable output and, where appropriate, the failure
category.

Internal contract violations shall not be hidden in an ordinary failure result.
They may be intercepted only at the top-level failure boundary to clean up,
prevent output publication, and report an internal compiler error.

## Validators

Validators check internal stage contracts. They do not replace parser or
semantic checks for user input.

Planned validators include:

- context state validator;
- AST validator;
- IR validator.

A validator failure is an internal compiler contract violation. Validation must
occur before a malformed internal representation is passed to a later stage or
published as output.

Validation work shall be bounded or covered by resource accounting for large
inputs.

## Cancellation And Resource Limits

Cancellation and resource limits are not implemented by the initial context.
The context boundary is intended to provide their future owner.

Future limits may cover source bytes, token count, identifier count, AST nodes,
semantic entities, IR objects, diagnostics, nesting depth, and backend temporary
storage.

Cancellation shall be checked only at documented safe points. A cancelled
compilation shall release owned resources and shall not publish partial output.

## Migration Sequence

State shall move into the context in small, independently testable changes.
The minimal context and diagnostic-state migration are complete. The next
planned sequence is:

1. add a source registry and `Source_File_ID`;
2. introduce stage-specific result types;
3. add AST or IR validation;
4. expand in-process tests as additional context-owned state is introduced;
5. add cancellation and resource accounting when their contracts are defined.

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
