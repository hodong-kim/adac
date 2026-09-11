# Compiler Symbols

This document defines context-owned identifier interning for Adac.

## Purpose

`Adac.Symbols.Store` owns identifier spellings and assigns stable `Symbol_ID`
values. AST and later compiler stages store IDs instead of repeated strings.

The store provides:

- one owned copy of each identifier under the active language policy;
- deterministic first-interning order;
- context ownership validation;
- constant-size identifier values in syntax objects;
- a single case-comparison policy for parsing and semantic analysis;
- non-mutating lookup of an already interned canonical spelling.

## Case Policy

The symbol store receives `case_sensitive_identifiers` when its compilation
context is created. The policy never changes during that compilation.

In standard Ada mode, interning uses a lowercase canonical key. `Main` and
`main` therefore return the same `Symbol_ID`. The store preserves the spelling
from the first interning operation for diagnostics, dumps, and backend names.

In the optional case-sensitive mode, the exact spelling is the canonical key,
so `Main` and `main` receive distinct IDs.

The frontend validates the ASCII identifier spelling defined in
`frontend-lexing.md` before interning. Initial canonicalization uses the
compiler's character-level lowercase operation. Unicode and source-encoding
policy must be defined before the identifier character set expands.

## Ownership And Lifetime

One `Adac.Compilation.Context` owns one symbol store. A `Symbol_ID` borrows that
store and is meaningful only while the context remains alive.

`INVALID_SYMBOL_ID` is the explicit invalid sentinel. Resolving an invalid,
foreign, or out-of-range ID is an internal compiler contract violation.

The parser interns procedure and end names through the compilation context.
Context-aware AST validation runs before semantic analysis and IR lowering.
The IR builder resolves the procedure symbol's first spelling when constructing
the target-independent module entry name.

A parser may intern a name before a later token rejects the compilation unit.
Those symbols remain owned by the same compilation context until that attempt
ends; parse rejection does not transactionally roll back the shared store.

## Determinism And Complexity

IDs use deterministic one-based first-interning order within one store. Runtime
ownership markers are not persistent identity and shall not affect output.

The store uses an ordered canonical-key map and an index-to-spelling vector.
Lookup and insertion are logarithmic in the number of distinct symbols;
resolution is constant time. `find` applies the same canonical case policy as
`intern`, returns the existing `Symbol_ID` or `INVALID_SYMBOL_ID`, and never
inserts a spelling or consumes symbol budget. Storage is bounded by the
configured distinct symbol budget and by the source-character budget that
bounds spelling lengths.

The store also exposes the validated one-based ordinal of a `Symbol_ID` for
context-owned compiler structures that need a fixed-size ordered lookup key. The
ordinal is exactly the symbol's deterministic position in this store, so two
canonical-equivalent spellings share it and a foreign symbol is rejected before
the ordinal is returned. It is an internal context-local ordering/key, not a
portable or persistent identity; serialization continues to require an explicit
schema and owning store.

## Failure Contract

Empty spellings and malformed IDs are internal compiler contract violations and
raise `Program_Error`.

The compilation context supplies an immutable maximum number of distinct
symbols. Re-interning a canonical spelling already present in the store is
allowed when the budget is full because it publishes no new symbol. Attempting
to insert a new spelling at the configured limit raises
`Adac.Resources.Limit_Exceeded` before either store structure changes. The
parser converts that signal into one ordinary source diagnostic and rejects the
parse without publishing a root node.

Representable index exhaustion raises `Storage_Error` before an ID can wrap or
be reused. If map insertion fails after vector insertion, the vector update is
rolled back before the failure propagates. The complete budget contract is
defined in `resource-limits.md`.

## Extension Rules

`Symbol_ID` identifies an interned name, not a declaration, AST node, semantic
entity, or type. `Node_ID`, `Entity_ID`, and `Type_ID` are distinct implemented
identities. The context-owned type store does not reuse symbol identity as type
or object identity.

Persistent formats shall serialize schema-defined symbol ordinals and owned
spellings, never runtime ownership markers.
