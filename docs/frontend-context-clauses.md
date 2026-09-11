# Frontend Context Clauses

This document defines the current represented frontend boundary for Ada context
clauses. It complements `frontend-lexing.md`, `frontend-names.md`, and
`ast-model.md` without claiming dependency, visibility, or library-unit semantics
that the semantic model does not yet implement.

## Bootstrap Selection

The bootstrap profile uses the production entry source `src/adac_main.adb`, whose
first constructs are ordinary nonlimited, nonprivate `with` clauses. Earlier
work staged those clauses only far enough to diagnose them precisely. After the
production body can be staged through end of file, these context items are the
earliest unrepresented source syntax preventing a complete compilation-unit AST.

Ada 2022 AARM 10.1.1 defines a `compilation_unit` as a `context_clause` followed
by a library item or subunit. AARM 10.1.2 defines a context clause as context
items and defines the current production form as a nonlimited `with_clause`. The
AST therefore separates the compilation-unit root from its grammar-level unit
item rather than attaching context syntax directly to a procedure body or subunit.

## Current Grammar Boundary

The bootstrap-driven represented subset is:

```text
represented_compilation_unit ::=
  represented_context_clause (represented_library_item | represented_subunit)

represented_context_clause ::= {represented_plain_with_clause}

represented_subunit ::=
  separate (program_unit_name) represented_proper_body

represented_proper_body ::= current_package_body

represented_plain_with_clause ::=
  with represented_library_unit_name {, represented_library_unit_name};

represented_library_unit_name ::= identifier {. identifier}
```

The parser consumes consecutive `Tok_With` clauses before dispatching the current
unit item. The selected unit-boundary recovery rule recognizes exactly the empty
form `with ;` before library-unit-name parsing. It reports `with clause requires a
library unit name` at the semicolon, records a sticky recovered-context state,
consumes that semicolon for guaranteed progress, and continues with a following
`with` item or the library unit. Two independent empty with clauses may therefore
produce two ordered diagnostics while a later valid unit is still parsed. If EOF
follows the recovered context items, parsing terminates without manufacturing an
unrelated unit-starter diagnostic. Nonempty malformed with clauses continue through
the existing fail-fast name/comma/semicolon paths; recovery does not clear their
`self.failed` state.

`Tok_Separate` selects a subunit, whose parent unit name reuses the
iterative program-unit-name parser before the current proper package body. A
library-unit name contains one or more identifier components;
one clause may contain multiple comma-separated names. The current subset is
plain, nonlimited, and nonprivate. It deliberately does not widen the accepted
name grammar beyond the identifier-selected production requirement.

## AST And Symbol Ownership

Each plain clause publishes one `With_Clause_Node`. The node owns a nonempty
ordered list of current identifier or selected-name nodes, one for each
library-unit name, and a span from `with` through the terminating semicolon.
Each identifier component is interned through the compilation context, using the
existing case policy and symbol budget. No aggregate symbol is created for a
complete selected library-unit name.

`Compilation_Unit_Node` owns an ordered, possibly empty context-item list and one
unit item. A direct library item remains one of the currently represented
procedure/package forms. A `Subunit_Node` instead owns a nonempty ordered parent-
unit-name component list plus one earlier proper body; the current parser subset
uses `Package_Body_Node` as that proper body. The compilation-unit span starts at
the first context item when one is present and otherwise at the unit item, and
the unit-item span always closes it. `unit_item` preserves this grammar choice;
`library_item` deliberately rejects a subunit instead of flattening the proper
body into an ordinary library item.

The AST remains append-only. Name nodes precede their `With_Clause_Node`; parent-
unit-name symbols and the proper body precede their `Subunit_Node`; every context
item and the final unit item precede the `Compilation_Unit_Node`. An empty recovered
with clause publishes no symbol, name node, or context-item node. Its sticky
recovery state is checked by `parse_file` after the unit syntax closes and before
root construction, so no `Compilation_Unit_Node` can be published for a recovered
unit. Valid child syntax parsed after recovery may remain unreachable and private
to the rejected compilation context. Parse rejection does not roll such nodes
back.

## Semantic Support Boundary

Representing a context clause is not dependency support. A successfully parsed
unit containing one or more current `With_Clause_Node` items is rejected by
semantic analysis with one ordinary source diagnostic before a procedure entity
is published:

```text
context clauses are not semantically supported
```

The diagnostic is anchored at the first represented context item. This prevents
the backend from accepting a program whose context dependencies, visibility, or
elaboration requirements were ignored. Context rejection precedes unit-item
inspection. For a context-free unit, a `Subunit_Node` is rejected with `subunits
are not semantically supported`; its proper body is never flattened into an
ordinary library item. Context-free minimal procedures continue through semantic
analysis and IR lowering unchanged apart from the explicit procedure-body child
node.

The current slice does not support or represent:

- `limited with` clauses;
- `private with` clauses;
- `use_clause` context items;
- dependency edges or library-unit lookup;
- context-driven visibility or elaboration behavior; or
- semantic entities for context items.

Malformed current syntax is rejected by the parser before semantic analysis. The
empty `with ;` form uses the bounded unit-boundary recovery rule above. Every
nonempty missing library-unit identifier, selector component, comma item, or
semicolon keeps the existing fail-fast syntax-diagnostic precedence.

## Failure And Resource Contract

Clause, name, component, and comma loops are iterative. The parser allocates one
AST node per represented clause and the existing bounded name nodes for each
library-unit name. Context-item lists are bounded by the AST-node and source-
character budgets; no source-controlled recursive parser stack, scanner rewind,
or token buffer is introduced.

AST-node exhaustion is reported as the existing `AST node limit exceeded` source
failure before a parent node is published. Symbol-budget exhaustion retains the
existing `symbol limit exceeded` diagnostic. Earlier append-only nodes may remain
unreachable after either rejection and are reclaimed with the context. Source-
character exhaustion keeps the existing controlled failure path. Internal
ownership or ordering violations remain `Program_Error`.

## Test Contract

Tests for this boundary shall cover:

- a context-free minimal compilation unit using a separate procedure-body child;
- one and multiple consecutive plain `with` clauses;
- a comma-separated clause containing selected library-unit names;
- exact context-item order, spans, and unit-item ownership in the root;
- subunit parent-unit-name order, proper-body ownership, and the non-flattening
  `library_item` boundary;
- component-wise symbol interning without an aggregate library-unit symbol;
- context-aware validation of represented with-clause names;
- semantic rejection before procedure-entity publication when context items are
  present;
- unchanged semantic and executable behavior for a context-free minimal unit;
- controlled AST-node and symbol-budget exhaustion without partial parent
  publication;
- two independent empty `with ;` context items followed by a valid unit, with
  ordered diagnostics and no compilation-unit root publication;
- empty-with recovery followed directly by EOF without an unrelated unit diagnostic;
- a missing library-unit name after a comma;
- a missing selected-name component after a dot; and
- a missing terminating semicolon.

The production bootstrap source now composes its five represented plain `with`
clauses with the represented outer `adac_main` procedure body under one
`Compilation_Unit_Node`. Root publication itself creates no semantic entity.
Semantic analysis then rejects at the first context item with the documented
`context clauses are not semantically supported` diagnostic, preserving the
separation between frontend representation and dependency/visibility semantics.
The production bootstrap source remains the authority for selecting the next
prerequisite after this root boundary is validated.
