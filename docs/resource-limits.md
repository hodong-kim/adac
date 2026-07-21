# Resource Limits

This document defines compilation resource-limit ownership, enforcement, and
failure behavior.

## Ownership

Each `Adac.Compilation.Context` owns one immutable `Adac.Resources.Limits`
value. Limits are fixed when the context is created so that stage behavior
cannot change partway through one compilation attempt.

The default policy currently sets:

```text
maximum_ast_nodes = 1_000_000
```

Embedders and internal tests may supply a smaller or larger limit explicitly.
Zero is valid and prevents publication of any AST node.

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

`Adac.Compilation.Syntax` raises `Adac.Resources.Limit_Exceeded` when a valid
node cannot be appended because the configured budget is exhausted. This
exception is an internal stage signal, not an allocator failure.

The parser converts that signal into one ordinary source diagnostic and a
`Parse_Rejected` result. It does not publish a root `Node_ID`, continue parsing,
or enter semantic analysis. Nodes appended before exhaustion remain bounded by
the configured limit and are reclaimed with the context.

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

The current policy bounds only AST node publication. Source bytes, token count,
identifier count, nesting depth, diagnostics, semantic objects, IR objects,
backend storage, and cancellation safe points require separate contracts and
tests before they are added.

## Tests

Deterministic tests shall cover:

- the default policy accepting the existing language subset;
- a zero-node budget rejecting the first statement without appending a node;
- a one-node budget accepting a statement and rejecting the unit root;
- exactly one ordinary diagnostic per exhausted parse;
- no partial node publication after a rejected append;
- unchanged behavior for malformed source and internal contract violations;
- full repository regression checks.
