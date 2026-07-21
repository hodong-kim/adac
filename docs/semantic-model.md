# Semantic Model

This document defines ownership, identity, construction, and validation for
Adac's semantic objects.

## Ownership And Identity

Each `Adac.Compilation.Context` owns one append-only `Adac.Semantics.Store`.
The store owns every semantic entity created during that compilation and
releases the storage with the context.

`Adac.Semantics.Entity_ID` is a private stable reference to one entity in one
store. It contains a deterministic one-based index and an opaque runtime owner
marker. `INVALID_ENTITY_ID` is the explicit invalid value. Invalid, foreign,
out-of-range, or expired IDs are internal compiler contract violations.

Compiler stages pass entity IDs and the owning context. They do not retain raw
entity pointers or copy mutable semantic records between stages.

## Current Entity

The current model defines one entity kind:

```text
Procedure_Body_Entity
```

The entity records:

```text
declaration  Node_ID of the compilation-unit procedure body
symbol       Symbol_ID of the declared procedure
span         closed source span of the declaration
```

These references are immutable after publication. The context-level production
constructor accepts only the declaration `Node_ID`; it derives symbol and span
from the context-owned AST so pipeline callers cannot provide conflicting
copies of those properties. The lower-level store append primitive accepts the
normalized fields and enforces their structural validity; context-aware
ownership and canonical-relationship validation remain in
`Adac.Compilation.Semantics`.

Type information, lexical scopes, visibility, overload sets, and declaration
relationships are not represented yet. `Type_ID` shall be introduced only with
real type objects and type-checking behavior.

## Semantic Analysis Boundary

`Adac.Sema.Analysis_Result` is discriminated by status. A rejected analysis has
no entity payload and means ordinary source diagnostics were recorded. A
successful analysis contains the `Entity_ID` for the analyzed procedure.

Semantic analysis validates the AST and all language rules implemented for the
current subset before publishing the entity. A rejected analysis does not
append a semantic entity.

`Adac.IR.Builder.build` accepts the successful entity ID rather than a raw AST
root. It validates the entity through the compilation context, resolves the
entity's declaration node, and lowers that declaration. This makes semantic
success an explicit prerequisite for IR construction.

## Validation

`Adac.Compilation.Semantics.validate` verifies:

- entity ID validity, store ownership, and range;
- entity kind and structurally valid stored references;
- declaration node ownership and compilation-unit kind;
- symbol and source-span ownership;
- equality between the stored symbol/span and the canonical AST declaration
  properties.

Validation is deterministic, does not modify the store, and allocates no
storage. A validation failure raises `Program_Error` and is not converted to an
ordinary source diagnostic or backend operational failure.

Production APIs expose no unchecked constructor. Validator tests use test-only
child packages under `tests-internal/` to inject malformed entities without
weakening the production contract.

## Allocation And Failure

Entities are appended in deterministic semantic-analysis order. Appending does
not invalidate earlier IDs. Representable index or allocator exhaustion raises
`Storage_Error` before an ID wraps or a live ID is reused.

The current language subset creates at most one procedure entity per normal
compilation pipeline execution. A semantic-entity resource limit shall be
introduced when frontend coverage permits an input-controlled number of
entities.

Operations on one context remain sequential. Independent contexts share no
semantic store or entity state.

## Tests

In-process tests shall cover:

- successful procedure analysis publishing one entity;
- rejected analysis publishing no entity;
- canonical declaration, symbol, and span queries;
- invalid and foreign `Entity_ID` values;
- malformed declaration, symbol, and span references;
- IR construction rejecting malformed or foreign entities;
- isolation between compilation contexts;
- existing end-to-end compiler behavior.
