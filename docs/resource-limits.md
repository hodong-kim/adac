# Resource Limits

This document defines compilation resource-limit ownership, enforcement, and
failure behavior.

## Ownership

Each `Adac.Compilation.Context` owns one immutable `Adac.Resources.Limits`
value. Limits are fixed when the context is created so that stage behavior
cannot change partway through one compilation attempt.

The default policy currently sets:

```text
maximum_source_characters_per_file = 16_777_216
maximum_ast_nodes = 1_000_000
```

Embedders and internal tests may supply a smaller or larger limit explicitly.
Zero is valid for either limit. It prevents the scanner from consuming a source
character or prevents publication of any AST node, respectively.

`Source_Character_Limit` ends at `Positive'Last - 1`. This guarantees that the
one-based line or column immediately after every permitted character remains
representable. The subtype rejects an unrepresentable policy when the limits
value is constructed instead of allowing position arithmetic to overflow while
scanning.

## Source Character Budget

The source budget counts the normalized `Character` values that the lexer reads
from one source file. A line separator needed to reach a later line is exposed
as one normalized line-feed character and consumes one unit. The terminal text
file marker is not a lexical character and consumes no unit.

The counter is reset for each `parse_file` scan. The limit therefore applies to
one source-file scan rather than aggregating every file or repeated scan in a
compilation. A later multi-unit frontend may add an independent aggregate raw
byte budget after source encoding and source-manager ownership are defined.

The scanner reserves one unit before reading each character. It uses bounded
one-character lookahead and never reads or allocates an entire source line.
Consequently, a single oversized line, comment, or identifier cannot bypass the
limit through `Get_Line` allocation. Token text remains bounded by the same
per-file budget.

Exhaustion stops tokenization immediately. The parser records exactly one
ordinary `source character limit exceeded` diagnostic and returns
`Parse_Rejected` without a root `Node_ID`. A registered source path, interned
symbols, or AST nodes published before exhaustion may remain in their
context-owned append-only stores; they remain private to the rejected
compilation and are reclaimed with its context.

## AST Node Budget

The AST budget counts every node appended to the context-owned AST store,
including nodes that become unreachable after parse rejection. A compilation
unit root consumes one node in addition to its statement nodes.

The budget is checked after context, symbol, source-span, child-node, and
structural preconditions have been validated, but before the append operation.
This ordering ensures that a contract violation is not hidden by an exhausted
budget. A rejected append does not change the AST node count or publish a
partial node.

The check is constant-time and uses the AST store's node count as the single
source of truth. It does not maintain a duplicate mutable counter.

## Failure Contract

The lexer and `Adac.Compilation.Syntax` raise
`Adac.Resources.Limit_Exceeded` when valid work cannot proceed because the
applicable configured budget is exhausted. This exception is an internal stage
signal, not an allocator failure.

The parser converts the signal at the operation-specific boundary into one
ordinary source diagnostic and a `Parse_Rejected` result. It does not publish a
root `Node_ID`, continue parsing, or enter semantic analysis. Nodes appended
before exhaustion remain bounded by the configured limit and are reclaimed
with the context.

Actual memory exhaustion remains `Storage_Error` and follows the external
resource-failure contract in `failure-model.md`. Internal callers that use the
syntax-construction API directly must either propagate `Limit_Exceeded` to an
input-facing boundary or convert it to the result type defined by their stage.
They must not convert it to success or an internal compiler error.

## Concurrency

Operations on one compilation context remain sequential. A future parallel
frontend must make reservation and append one atomic context operation before
same-context parallel construction is supported.

## Future Limits

The current policy bounds normalized source characters per file and AST node
publication. Aggregate raw source bytes, token count, identifier count, nesting
depth, diagnostics, semantic objects, IR objects, backend storage, and
cancellation safe points require separate contracts and tests before they are
added.

## Tests

Deterministic tests shall cover:

- the default policy accepting the existing language subset;
- a zero-character budget rejecting a nonempty file before token publication;
- a small budget rejecting a long line without reading the complete line;
- exact-budget acceptance without charging the terminal text file marker;
- exactly one ordinary diagnostic per exhausted source file;
- no root or AST node publication when exhaustion precedes syntax;
- normal comment, token-position, and end-of-file behavior after streaming;
- a zero-node budget rejecting the first statement without appending a node;
- a one-node budget accepting a statement and rejecting the unit root;
- exactly one ordinary diagnostic per exhausted parse;
- no partial node publication after a rejected append;
- unchanged behavior for malformed source and internal contract violations;
- full repository regression checks.
