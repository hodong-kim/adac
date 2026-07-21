# AST Model

This document defines Adac's abstract-syntax storage, identity, ownership, and
validation contracts.

## Ownership And Lifetime

Each `Adac.Compilation.Context` owns one append-only `Adac.AST.Store`. The store
owns every node created during that compilation attempt and releases all node
storage with the context. Compiler stages borrow the context and node
identifiers; they do not own or copy nodes.

`Adac.AST.Node_ID` is a private, stable reference to one node in one store. It
contains a deterministic one-based index and an opaque runtime owner marker.
`INVALID_NODE_ID` is the only public invalid value. Resolving an invalid,
foreign, or out-of-range ID is an internal compiler contract violation.

A `Node_ID` remains meaningful until its context is destroyed. It must not be
retained beyond that lifetime, serialized with its runtime owner marker, or
resolved through another context.

## Storage

The store is append-only. Appending a node does not invalidate earlier IDs, and
nodes are immutable after publication. Allocation order is deterministic parse
order within one context and is independent of addresses, other contexts, and
hash-table iteration.

`Node_List` is a temporary value used to collect child IDs before publishing a
parent. It does not own nodes. A production constructor validates each child ID
against the destination store before copying the list into the parent node.

Parse failure does not roll back already appended nodes. Such unreachable nodes
remain private to the failed compilation and are reclaimed with the context.
This preserves stable IDs and simple failure cleanup. The context-owned AST
node budget defined in `resource-limits.md` bounds this storage.

## Construction

Production nodes are created through `Adac.Compilation.Syntax`. These
operations validate context initialization, symbol ownership, source ownership,
node ownership, node kind, and structural containment before publishing a node.

The current node kinds are:

```text
Compilation_Unit_Node
Null_Statement_Node
Return_Statement_Node
```

A compilation unit is published only when:

- its procedure and end symbols are valid and owned by the context;
- it contains at least one statement;
- every child ID names a statement in the same AST store;
- its source span is valid and owned by the context;
- every statement span is valid, context-owned, and contained by the unit span.

The constructor does not require the procedure and end symbols to match. Name
matching is a language rule and remains the responsibility of semantic
analysis.

Production APIs do not expose mutable node records or unchecked constructors.
Malformed representations needed by validator tests are created only through
test-only child packages that can see the private store representation.

## Queries

Queries require the owning context and a valid `Node_ID`. They return immutable
node properties such as kind, span, symbols, statement count, and child IDs.
Kind-specific queries reject a node of the wrong kind.

No query returns a raw node pointer or mutable node reference. Semantic analysis
and IR construction resolve IDs through `Adac.Compilation.Syntax`, preserving
the context ownership boundary.

## Stage Boundaries

`Adac.Frontend.Parse_Result` is discriminated by parse status. A rejected parse
has no AST payload. A successful parse contains the root `Node_ID`, which
borrows the AST store in the context supplied to `parse_file`.

The parser validates the completed root before returning success. Semantic
analysis repeats context-aware validation before consuming the tree and
publishes a semantic entity on success. IR construction reaches the declaration
through that validated entity. Validation does not transfer ownership or modify
the store.

`Adac.Compilation.Syntax.validate` checks:

- root validity, ownership, range, and compilation-unit kind;
- symbol structure and context ownership;
- nonempty statement structure and child kinds;
- span structure, context ownership, and containment.

A validation failure raises `Program_Error`. It is not an ordinary Ada source
diagnostic and must not be converted to a rejected parse or semantic result.

## Complexity And Failure

Appending and resolving one node are constant-time apart from copying a direct
child list. Root validation is linear in the number of direct nodes currently
represented and allocates no storage. Future recursive syntax shall retain
work proportional to reachable nodes and shall be covered by resource limits.

Configured node-budget exhaustion raises `Adac.Resources.Limit_Exceeded` before
an append and leaves the node count unchanged. Representable node-index or
allocator exhaustion raises `Storage_Error` before an ID wraps or a live ID is
reused. A failure may leave earlier nodes in the append-only store, but it must
not publish a partially initialized node.

Operations on one context are sequential until a stronger concurrency contract
is introduced. Independent contexts share no AST store or mutable node state.

## Extension Rules

New node kinds shall add their structural invariants, context-owned references,
queries, validator coverage, and parser boundary tests in the same change.
Semantic facts belong in semantic storage rather than mutable AST fields.

Persistent formats shall serialize schema-defined node ordinals and the owned
store, never runtime ownership markers or memory addresses.

## Tests

In-process tests shall cover:

- deterministic construction and queries for a valid minimal unit;
- invalid and foreign `Node_ID` values;
- invalid and foreign symbols and source spans;
- an empty statement list and a child outside its parent span;
- parser root publication and exact node spans;
- semantic and IR rejection of malformed internal trees;
- isolation between two compilation contexts;
- deterministic `Program_Error` for contract violations.

End-to-end parser and semantic tests verify that malformed source continues to
use ordinary diagnostics rather than internal contract failures.
