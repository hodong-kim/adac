# Source Spans

This document defines source-range semantics for Adac syntax objects.

## Representation

`Adac.Source.Span` is a closed source range with a first and last position. Both
endpoints are included in the represented source text.

A valid span satisfies all of the following invariants:

- both endpoints contain a valid `Source_File_ID`;
- both endpoints identify the same source file;
- the first endpoint does not follow the last endpoint;
- endpoint line and column values remain one-based.

The default value is `INVALID_SPAN`. It is suitable only for an object under
construction and is rejected at a stage boundary.

`Adac.Source.make_span` validates structural ordering before constructing a
span. Registry-aware validation additionally verifies that the source-file
identifier belongs to the expected compilation context and is still in range.

## Current AST Coverage

The current parser attaches spans to every produced AST node:

```text
Compilation_Unit
  first: procedure keyword
  last:  compilation-unit terminating semicolon

Statement
  first: null or return keyword
  last:  statement terminating semicolon
```

A compilation-unit span shall contain every statement span in its statement
list. The current grammar does not yet produce separate name or declaration
nodes, so those source ranges are not represented independently.

## Ownership And Validation

A span borrows its source-file identity from one `Adac.Source.Registry`. It
does not own source text, a path string, or the registry.

`Adac.AST.validate` checks structural span validity and node containment.
`Adac.Sema.analyze` additionally validates every span through the source
registry owned by its `Adac.Compilation.Context`. Passing a structurally valid
span from another context is an internal compiler contract violation.
`Adac.IR.Builder.build` repeats structural validation before lowering but does
not replace semantic-boundary ownership validation.

Validation is linear in the number of AST nodes and allocates no storage.
Future parser resource accounting shall bound the number of nodes before this
walk becomes unbounded.

## Failure Contract

Malformed, invalid, foreign, or out-of-range spans are internal compiler
contract violations and raise `Program_Error`. They are not ordinary source
errors and shall not be converted into semantic rejection.

Source text that cannot be parsed never publishes an AST payload, so partially
constructed spans remain private to the failed parser operation.

## Extension Rules

New syntax and semantic objects shall receive a source span when they are
introduced. A composite node span shall contain the spans of child nodes that
represent source text within that construct.

Generated objects with no direct source text require an explicit provenance
contract before they may use an invalid or synthetic span. No synthetic-span
policy is defined by the initial implementation.
