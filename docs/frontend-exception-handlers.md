# Frontend Exception Handlers

This document defines the current frontend representation and staging boundary
for Ada exception-handler syntax. The represented subset includes the handler
forms required by the deterministic bootstrap profile, including optional choice
parameters, selected exception-name choices, `others`, and supported statement
sequences. It complements `frontend-statements.md` and
`frontend-subprograms.md` without claiming exception entities, handler legality,
propagation behavior, or executable exception semantics.

## Bootstrap Coverage

Bootstrap-profile production sources are integration inputs rather than a mutable
handler frontier. Every current profile member parses and structurally validates;
production examples below document the represented shapes that exercise this
contract. Historical progression from an individual handler to complete handled
sequences belongs in Git history.

Ada 2022 AARM 11.2 defines an `exception_handler` as `when`, an optional
`choice_parameter_specification`, a nonempty `|`-separated `exception_choice`
list, `=>`, and a nonempty `sequence_of_statements`. A choice parameter is a
defining identifier; an exception choice is an exception name or `others`. The
rule that `others` is the sole choice of the final handler is legality rather
than syntax and remains semantic work.

## Current Grammar Boundary

The bootstrap-driven staging subset is:

```text
staged_current_exception_handlers ::=
  exception staged_current_exception_handler
    {staged_current_exception_handler}

staged_current_exception_handler ::=
    when others => staged_current_handler_statement
  | staged_current_named_choice_handler
  | staged_current_choice_parameter_handler

staged_current_named_choice_handler ::=
  when staged_selected_exception_name
    {| staged_current_exception_choice} => staged_current_named_choice_handler_body

staged_current_named_choice_handler_body ::=
  staged_current_named_choice_statement
    {staged_current_named_choice_statement}

staged_current_named_choice_statement ::=
    staged_current_identifier_statement
  | null ;
  | return [represented_expression] ;

staged_current_identifier_statement ::=
    staged_current_procedure_call_statement
  | staged_current_assignment_statement

staged_current_choice_parameter_handler ::=
  staged_current_choice_parameter_handler_header
    staged_current_choice_parameter_handler_body

staged_current_choice_parameter_handler_header ::=
  when defining_identifier : staged_current_exception_choice
    {| staged_current_exception_choice} =>

staged_current_exception_choice ::=
    staged_selected_exception_name
  | others

staged_current_choice_parameter_handler_body ::=
    staged_current_handler_statement
  | staged_current_handler_call_sequence
  | return represented_expression ;

staged_current_handler_call_sequence ::=
  staged_current_procedure_call_statement
    {staged_current_procedure_call_statement}

staged_current_others_handler_body ::=
    null ;
  | bare_reraise
  | staged_current_handler_call_sequence bare_reraise
  | represented_current_bare_block_statement bare_reraise

bare_reraise ::= raise ;

staged_selected_exception_name ::= identifier {. identifier}

staged_current_handler_statement ::= null ;
```

These are frontend staging productions rather than replacements for the full Ada
11.2 grammar. The existing `when others => null;` form remains structurally
complete. The selected parameterless `others` path also owns bare re-raise, a
call sequence followed by bare re-raise, and the production cleanup shape of one
represented bare `begin ... exception ... end;` block followed by bare re-raise.
That block is published through the shared compound-frame parser and its inner
handler remains subject to the bounded nonrecursive handler/block contract in
`ast-model.md`. A choice-parameter handler may use selected exception-name
choices or `others`, and may retain the current `null;` body or consume
consecutive current identifier-leading assignments/calls. A handler may also omit
the choice parameter and begin directly with a selected exception name, as
permitted by AARM 11.2. Its ordinary body subset is a nonempty iterative sequence
of represented identifier-leading assignments/calls, `null;`, return statements
with or without a represented expression, and bare re-raise statements. The
identifier-leading path reuses the statement layer's assignment/call
discriminator rather than maintaining handler-specific assignment syntax. The
production `compile_file` handler uses two calls followed by `return;`. The call,
assignment, and block staging contracts are owned by `frontend-statements.md`;
this boundary does not duplicate their parsing.

The handler list is consumed iteratively. `Tok_When` is owned by this boundary
while another current handler follows. The caller-owned terminator remains
unconsumed after the final handler. Current callers use `Tok_End`, so subprogram
parsing retains ownership of the closing form.

Exception-handler staging has an explicit publication and completion policy.
Ordinary procedure parsing validates the complete current handler list and then
rejects at its opening `exception`; that ordinary path intentionally disables
handler AST publication. The nested and outer bootstrap paths request handler
publication and return at `Tok_End`. Their enclosing subprogram parsers retain
ownership of the closing forms.

The handler statement in the standalone `others` form reuses the ordinary
statement parser rather than maintaining a second `null;` grammar. That call
uses an explicit return-only statement-publication mode. The nested publication
path creates a `Null_Statement_Node` without appending it to the
compilation-unit
statement list; staging-only callers still consume the same syntax without
publishing a node.

For a represented choice-parameter handler, the defining identifier is interned
and retained as syntax identity together with its exact source span only after a
following colon has structurally selected the parameter form. Without that
colon, the first identifier begins an exception name instead. This does not
create a handler scope, object entity, or `Exception_Occurrence` semantics. Each
selected exception name is published as identifier-selected name syntax and is
stored directly in the ordered choice list.
It remains a name rather than a resolved exception identity. `others` continues
to use `Others_Exception_Choice_Node` and publishes no symbol. Staging-only
callers preserve the existing no-publication behavior.

## Support Boundary

A complete current-shaped exception-handler part encountered in an ordinary
procedure receives exactly one diagnostic at its opening keyword:

```text
exception handlers are not supported
```

The production nested procedure uses structural completion. After
`when others => null;` is staged, this boundary returns with the following
`Tok_End` current and records no unsupported-handler diagnostic.
`frontend-subprograms.md` then owns `end [designator];` and the enclosing
procedure's subsequent staging boundary.

A valid identifier-starting handler without a choice parameter stages its
selected-name choice list directly. In the `compile_file` production this
preserves all six `Ada.IO_Exceptions.*` choices, then represents
`Adac.Compilation.Diagnostics.error
(context, "unable to read input file: " & input_path);`,
`finish_with_failure (context);`, and `return;` in source order. The completed
`Exception_Handler_Node` owns the six choices and three statements, then parsing
returns at the enclosing block's line 125 `end`. Production reaches 58 symbols
and 295 AST nodes with zero semantic entities; a 294-node budget preserves all
children and rejects before the handler parent.

A missing `when`, missing choice after `:` or `|`, missing arrow, or missing
handler statement is a syntax failure and retains a syntax diagnostic before an
unsupported-feature diagnostic can hide it. An invalid identifier retains the
existing invalid-identifier diagnostic.

The production outer handler list is structurally complete after the second
handler's two procedure calls. The selected production path publishes both
handlers and returns with the outer `Tok_End` current. The enclosing parser must
still reject there because the represented nested body, outer call, and handlers
are not yet owned by one outer procedure body. That enclosing diagnostic is
owned by `frontend-subprograms.md` rather than this handler boundary.

A non-call statement after a choice-parameter header and a second statement
after the current `null;` retain `exception handler statement sequences are not
supported`.

A parameterless current handler may also retain bare `raise;` after earlier
current calls. The resulting `Raise_Statement_Node` uses `Bare_Reraise_Form`;
syntax publication does not itself prove that re-raise is legal or attach an
exception occurrence. This path exists so production cleanup handlers can own
their source before exception propagation is implemented.

This slice does not stage or claim support for:

- choice-parameter bindings or handler scopes;
- exception-name resolution or exception identity;
- parameterless named-choice handler statements beyond current identifier-led
  assignments/calls, `null;`, simple `return;`, and bare `raise;`;
- semantic legality, duplicate coverage, `others` placement, or handler
  ordering;
- general handler statement sequences beyond the current `null;` form and the
  production identifier-starting assignment/call sequence;
- exception declarations or named raise statements;
- exception propagation or occurrence semantics; or
- exception-handler recovery.

The handler parser stages current syntax without deciding AARM legality that
requires a represented handler list or resolved exception identities. In
particular, structural recognition of `others` does not itself claim that its
placement or combination with another choice is legal.

Those forms remain later production-driven work. Structural staging does not
make exception handling a supported executable feature.

## Symbol, AST, And Stage Ownership

`exception`, `when`, `others`, `:`, `|`, and `=>` introduce no identifier
symbol. A represented choice-parameter defining occurrence is interned as syntax
identity; in the production source the spelling `error` reuses the symbol
already published by the nested procedure parameter.

The nested `when others => null;` representation remains four AST nodes: one
`Others_Exception_Choice_Node`, one return-only `Null_Statement_Node`, one
`Exception_Handler_Node`, and one `Handled_Sequence_Node`.

Before the outer handlers, the production path has twenty-eight final distinct
symbols available across the complete staged path and sixty-seven AST nodes. The
first outer handler publishes six three-node selected exception names, four
nodes for its `report_exception` call, seven nodes for its `set_exit_status`
call, and
one handler parent. It therefore adds thirty nodes and reaches ninety-seven. The
second handler adds one `Others_Exception_Choice_Node`, the same four- and
seven-node call shapes, and one handler parent, adding thirteen more nodes. The
complete production path therefore reaches one hundred ten AST nodes while
remaining at twenty-eight distinct symbols and zero semantic entities.

Both outer `Exception_Handler_Node` values retain the `error` choice-parameter
symbol and exact defining span. The first owns six ordered selected-name
choices; the second owns one exact `others` choice. Each owns its two ordered
procedure-
call statements. The nodes create no exception entity, handler scope, occurrence
object, coverage result, control-flow state, semantic entity, IR object, or
backend output.

## Failure And Resource Contract

Handler-list, vertical-bar choice-list, selected-name, call-sequence, and
positional-actual parsing remain iterative and introduce no scanner rewind,
token buffer, recursive handler traversal, or new resource counter. Publication
uses temporary `Node_List` values containing stable node identifiers; every list
is bounded by source length and the existing AST-node budget.

The nested `others` path retains its four-node resource contract. Outer selected
exception choices reuse bounded iterative name publication. Each handler call
uses the existing call/expression resource contracts, and each handler parent is
appended only after all of its choices and statements have been validated. AST
exhaustion can therefore leave earlier append-only children but never a partial
name parent, call parent, or handler parent. Regression tests cover exhaustion
at the first named choice, first handler call, first handler parent, second
`others`
choice, and second handler parent.

Choice-parameter and selected-name identifiers use the existing distinct-symbol
budget. A represented choice parameter is interned after its colon confirms the
parameter form and before its choices; a parameterless first identifier is
interned as the first exception-name component instead. `others` consumes no
symbol budget. Symbol or AST exhaustion is converted to one controlled source
diagnostic at the operation that required publication.

The caller-owned terminator is validated after the complete current handler list
and before structural completion can return or publish its unsupported
diagnostic. Calling the internal staging operation at a token other than
`Tok_Exception` is an internal compiler contract violation and raises
`Program_Error`. Unsupported handler structure is an expected input failure;
source-character exhaustion and existing statement resource failures continue to
follow `resource-limits.md` and `failure-model.md`.

## Tests

Tests for this boundary shall cover:

- case-insensitive `exception` tokenization with exact spelling preservation;
- rejection of `exception` as a procedure defining identifier;
- the complete current `exception when others => null;` shape;
- ordinary procedure parsing retaining the unsupported-handler diagnostic at
  the opening `exception` after full structural validation;
- the production nested procedure staging the handler and returning its
  subprogram-closing `Tok_End` to `frontend-subprograms.md`;
- a missing `when`, missing exception choice, and missing `=>` retaining syntax
  diagnostics;
- a valid selected exception choice without a choice parameter staging as a
  named choice rather than being misclassified as a missing parameter colon;
- the production six-choice parameterless handler header and its two-call-plus-
  return body publishing one handler parent;
- controlled AST exhaustion before both the final selected-name choice parent and
  the completed parameterless handler parent;
- a choice parameter followed by `others` using the same represented defining-
  identifier policy as a selected-name choice;
- a missing arrow after a choice-parameter `others` choice retaining the
  ordinary expected-token diagnostic;
- a missing choice after a vertical bar and a missing `=>` retaining syntax
  diagnostics;
- the production six-name choice list consuming through `=>`;
- the production two-actual `report_exception` call and following one-actual
  `Ada.Command_Line.set_exit_status` call consuming through their semicolons;
- iterative publication of the following second handler and its current call
  body;
- a three-handler current fixture proving the handler loop is not a two-handler
  special case;
- the complete production handler list returning with outer `Tok_End` current;
- represented choice-parameter symbol/span queries without a semantic binding;
- selected exception-name component publication bringing the production count
  from seventeen to twenty-four;
- the complete outer handlers bringing the production path to twenty-eight
  symbols, one hundred ten AST nodes, and zero semantic entities;
- a second handler statement receiving the handler-sequence unsupported
  diagnostic;
- statement-parser reuse with return-only `null;` publication that does not
  append to the compilation-unit statement list;
- unchanged earlier AST-node-limit rejection before the nested handler part;
- exact choice-parameter, selected-name/`others`, handler, and handled-sequence
  source spans and ownership;
- malformed and foreign-context handler structures rejecting without mutation;
- controlled AST-node-budget exhaustion across nested handler publication and
  the selected outer choice/call/handler parent boundaries;
- no exception semantic entity after rejection.

The complete bootstrap-profile frontend gate is the integration authority for
handler composition. Repository-wide semantic and language work selection
belongs in `roadmaps/README.md`; this document does not retain a mutable
production frontier.
