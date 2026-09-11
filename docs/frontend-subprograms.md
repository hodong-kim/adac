# Frontend Subprograms

This document defines the current frontend representation and staging boundary
for subprogram syntax outside access definitions. The production nested
`report_exception` body and enclosing `adac_main` body are now represented as
`Procedure_Body_Node` values. It complements `frontend-declarations.md` and
`frontend-expressions.md` without claiming scopes, callable entities,
elaboration, or executable subprogram semantics.

## Bootstrap Selection

The production `src/adac_main.adb` path represents every current child of the
nested `report_exception` body: its two parameters, two constant object
declarations, and its handled sequence containing the `if` plus
`when others => null;`. Ada 2022 AARM 6.3 defines a subprogram body as a
subprogram specification followed by `is`, a `declarative_part`, `begin`, one
`handled_sequence_of_statements`, and `end [designator];`. The nested procedure
is therefore represented by one `Procedure_Body_Node` that coherently owns
those children.

That `Procedure_Body_Node` for `report_exception` owns the represented parameter
list, ordered declarative-part list, and one `Handled_Sequence_Node`.
The node owns the represented parameter list, ordered declarative-part list, and
one `Handled_Sequence_Node`. The nested defining identifier is now interned and
stored by the body. A present closing designator is preserved; an absent one is
represented explicitly without inventing a designator. AARM 6.3(3) name
equality,
parameter binding, declaration elaboration, scopes, callable identity, and body
execution remain semantic work.

The same normalized body ownership applies to ordinary library procedures. A
handler-free body owns a `Handled_Sequence_Node` with an empty handler list, so
procedure bodies do not retain a second duplicate statement vector. Existing
statement queries are compatibility views over the owned handled sequence. The
ordinary library-procedure declarative loop admits the existing represented
`Subtype_Declaration_Node` alongside identifier-led object declarations; it
reuses `parse_subtype_declaration_staging` and preserves the shared declarative
source order rather than introducing procedure-specific subtype syntax.

Nested procedure declarative parts also reuse the shared AARM 8.4 use-clause
staging path. Current `use type` and package-use clauses retain the existing
`Use_Type_Clause_Node` / `Use_Package_Clause_Node` ownership and remain syntax
only; name resolution, visibility, and overload effects are deferred.

Grouped AARM 6.1 parameter specifications are parsed as one syntax node, not as
several overlapping parameter nodes. A source form such as `left, right : T`
retains both defining identifiers in order and shares one mode, subtype mark, and
optional default expression. The parser remains iterative and bounded; parameter
entity creation, binding, mode legality, and subtype resolution remain semantic.

## Current Grammar Boundary

The current bootstrap-driven staging grammar composes the previously selected
boundaries and now owns the nested body closing syntax:

```text
staged_current_nested_procedure_body ::=
  staged_nested_procedure_body_header
  staged_current_nested_declarative_part
  begin staged_current_nested_statement_sequence
  [staged_current_exception_handlers]
  end [identifier] ;

staged_current_nested_statement_sequence ::=
    staged_current_identifier_or_case_statement
      {staged_current_mixed_statement}
  | represented_current_if_statement {represented_current_if_statement}
  | represented_current_block_statement

staged_current_identifier_or_case_statement ::=
    staged_current_identifier_statement
  | represented_current_case_statement

staged_current_mixed_statement ::=
    staged_current_identifier_statement
  | represented_current_case_statement
  | represented_current_if_statement

staged_nested_procedure_body_header ::=
  procedure defining_identifier
    [staged_nested_procedure_formal_part] is

staged_nested_procedure_formal_part ::=
  ( represented_nested_parameter_specification
    {; represented_nested_parameter_specification} )

represented_nested_parameter_specification ::=
  defining_identifier {, defining_identifier} :
    [represented_parameter_mode] represented_selected_subtype_mark

represented_parameter_mode ::= in | in out | out

represented_selected_subtype_mark ::=
  identifier {. identifier}
```

Each source parameter specification becomes one `Parameter_Specification_Node`;
its ordered defining-identifier list is retained without expanding one source
specification into overlapping nodes, and its subtype mark reuses
`Identifier_Name_Node` and `Selected_Name_Node`. The node preserves whether `in`
was omitted, written explicitly, combined as `in out`, or written as `out`. The
parser accepts these mode forms only in the current grouped-identifier,
simple-subtype nested-body subset; semantic directionality and parameter-passing
rules remain deferred. The completed nested body is published after its delegated
declarative part, statement, handler, and closing form have all been represented.
Those constituent grammars remain owned
by their authoritative frontend contracts rather than duplicated here. This
composed frontend grammar is not a replacement definition of the Ada
productions.

The parser enters this path only after the outer procedure's `is` when the next
token is `Tok_Procedure`. It now returns the represented nested body node after
consuming the selected body through its terminating semicolon. The opening
defining identifier is interned as syntax identity. A present closing identifier
is likewise interned and retained; absence is preserved explicitly. A mismatched
but structurally valid designator remains a represented syntax form for later
semantic legality checking rather than a parser error.

## Procedure Body Stubs

At the immediate declarative level of a represented package body, the shared
procedure-profile parser accepts both existing AARM 6.1 procedure declarations
and the bounded AARM 10.1.3 form
`procedure defining_identifier [formal_part] is separate;`. A semicolon directly
after the profile publishes `Procedure_Declaration_Node`; `is separate;`
publishes a distinct `Procedure_Body_Stub_Node`. Separate parser flags enable
these completions only for the caller that owns the relevant package-body
declarative item; function/procedure declarative nesting and subunit proper-body
parsing retain their narrower policies. Both forms retain profile syntax and
source ownership only. Completion matching, corresponding subunit lookup, full
conformance, visibility, overload binding, elaboration, and executable behavior
remain deferred.

## Support Boundary

A syntactically valid staged header whose next token does not enter the current
declaration path retains the precise `nested procedure bodies are not supported`
diagnostic at the nested `procedure` token. A current declarative-part walk may retain identifier-led object/object-renaming
declarations, represented AARM 8.4 `use`/`use type` clauses, procedure declarations,
and stable nested procedure bodies in source order before consuming the following
`begin`. The use-clause syntax is parsed by the same caller-neutral helper used by
compilation-unit context items; visibility and use-visibility remain semantic work. A procedure profile is parsed once:
a following semicolon publishes the existing `Procedure_Declaration_Node`, while
`is` keeps the same frame as a body. Nested procedure bodies reached from that
declarative walk use an explicit `Procedure_Frame_Vectors` stack: each frame
retains its profile, declarations, statements, and handlers; closing a child
publishes one stable `Procedure_Body_Node` and appends only that ID to its parent.
No recursive nested-procedure parser call is used for this path. Whether the body enters directly at `begin`, first enters through a represented
`if`, or follows a represented declarative part, current pre-handler statements
reuse one bounded dispatcher. Identifier-leading statements share the common
assignment-or-call publisher; `if`, `case`, explicit `declare` blocks, represented
`for`/`while`/simple loops, and bounded raises reuse their existing caller-neutral
publishers. Every stable child is appended to one handled-statement list in source
order, and iteration resumes at the next represented statement or closing
boundary. No first-statement special path duplicates that continuation grammar.
A following `Tok_Exception` is delegated to `frontend-exception-handlers.md` by
one common procedure-body completion path, rather than only by the older
`if`-first special case.

After the current handler returns at `Tok_End`, nested-subprogram parsing builds
one `Handled_Sequence_Node` spanning the first represented body statement through
the final handler, consumes `end`, the optional identifier designator, and the
terminating semicolon, then publishes the body from its already represented
children. A handler-free body uses the same path with an empty handler list. The
node is returned to the enclosing parser, which appends it as the first outer
declarative item before constructing the enclosing procedure body.

The represented enclosing procedure owns the nested body as its first declarative
item. After `begin`, it
publishes the parameterless `Adac.Driver.run;` call, delegates the complete
current handler list to `frontend-exception-handlers.md`, and publishes one
outer `Handled_Sequence_Node` containing that statement and both handlers. It
then consumes `end [identifier];`, preserves the optional closing designator,
and publishes the outer `Procedure_Body_Node`.

The completed outer body remains syntax-only and creates no procedure entity,
scope, declaration elaboration, or executable handler semantics. After the body
is validated, the parser retains its stable node ID for `parse_file`, which
publishes the enclosing `Compilation_Unit_Node` rather than reconstructing or
copying the body.

Nested/subunit procedure formal parts reuse the shared current parameter parser
with represented default expressions enabled. Each selected default remains one
existing represented name expression or string-literal expression owned by its
`Parameter_Specification_Node`;
the parser does not evaluate the default or apply it to a call. The Ada 2022
legality rule restricting defaults to `in` parameters remains semantic work.

The nested-procedure declarative walks also admit one bounded `Tok_Function`
child through the existing function-body parser. This procedure-owned nested
function may use the current represented profile, ordinary represented statement
loop, nested expression-return discovery, exception-handler subsets, ordered
current object declarations, and current local procedure bodies. A local procedure
owned by this function reuses `Procedure_Body_Node` and the existing bounded
procedure statement machinery, but its own declarative part may not contain a
procedure or function body. Procedure-body construction/validation independently
preflights every declaration owned by the procedure-owned function and accepts
only `Object_Declaration_Node` or this bounded `Procedure_Body_Node` form. This
permits the production `append_handled_sequence` helper without allowing
procedure/function alternation to become source-controlled parser or validator
recursion. Extended returns and other declarative-subprogram forms remain
excluded. The stricter function-owned nested-function mode remains limited to its
earlier direct-return and declaration-free subset.

Other continuations reject before ordinary successful body parsing. If the
first outer statement does not start with an identifier token eligible for the
current-call subset, the existing diagnostic remains anchored at the outer
`begin`:

```text
nested subprograms are not supported in procedure declarative parts
```

A token outside the selected shared handler-free statement sequence retains
`nested procedure body continuation is not supported`. Other unrepresented
initial nested statement
starts retain `nested procedure statements are not supported`, and a declarative
item outside the current identifier/procedure/function subset retains `nested
procedure declarative parts are not supported`.

Malformed closing syntax is diagnosed before the enclosing unsupported boundary.
A missing terminating semicolon therefore uses the ordinary expected-token
diagnostic. Omitting the optional closing designator is structurally valid.
Name equality is a legality rule for later semantic analysis once the nested
subprogram has a represented declaration and binding.

The current slice does not stage or claim support for:

- function bodies or further procedure bodies inside a procedure body owned by
  the bounded procedure-owned function;
- declarative subprogram forms other than that bounded local procedure body below
  the procedure-owned function;
- multiple defining identifiers in one parameter specification;
- `aliased`, null exclusions, multiple defining identifiers, access definitions,
  or parameter defaults outside the current represented name-expression subset;
- access definitions or parameter aspects;
- a subprogram-body `aspect_specification`;
- the nested body's general declarative part beyond the current object,
  object-renaming, procedure-declaration, identifier-enumeration-type,
  represented-record-type, generic-package-instantiation, and
  nested-subprogram-body subset, and statement
  forms outside the documented represented subset; or
- declaration, scope, visibility, callable-entity, or elaboration semantics.

Those boundaries remain outside the represented subprogram subset and shall be
selected when an active semantic or bootstrap prerequisite requires them rather
than added speculatively.

## Package Procedure Declaration Staging

Ada 2022 AARM 6.1 defines a `subprogram_declaration` from a subprogram
specification, optional aspects, and a terminating semicolon. Its
`procedure_specification` consists of `procedure`, a defining program-unit name,
and a parameter profile. The current child-package bootstrap source
`src/adac/driver/adac-driver.ads` contains the minimal parameterless declaration
`procedure run;`.

Within a staged selected child package, the current subset represents both a
parameterless `procedure identifier;` and a procedure whose optional formal part
contains the already represented single-defining-identifier parameter subset.
Each formal parameter owns its defining symbol/span, explicit or default mode,
and represented identifier or selected-name subtype mark. The procedure
`Procedure_Declaration_Node` owns those `Parameter_Specification_Node` children
in source order; an absent formal part is represented by an empty parameter list.
The parser validates and publishes the formal parameters through the same bounded
operation used by current procedure bodies, then publishes the procedure parent
only after the terminating semicolon is stable. Consecutive declarations remain
iterative so source length does not become host call-stack depth. Multiple
defining identifiers, access definitions, null exclusions, defaults, parameter
aspects, procedure aspects, overriding indicators, functions, null or abstract
procedures, renamings, subprogram bodies, declaration completion, and callable
semantics remain outside this boundary.

The selected package path uses this same declaration operation for both the
parameterless `procedure run;` form and parameterized helper procedures in the
bootstrap AST package. Repeated declarations and overload spellings do not
create item-specific parser paths. Parameter children are retained before the
procedure parent, and no callable entity, overload set, scope, or package
semantics is created by frontend representation.

## Package Function Declaration Representation

Ada 2022 AARM 6.1 defines a function specification as `function` plus a defining
designator and a parameter-and-result profile. The selected package subset is
narrower:

```text
represented_package_function_declaration ::=
  function identifier [represented_formal_part]
    return represented_selected_subtype_mark
    [represented_function_aspect] ;

represented_function_aspect ::=
  with identifier => represented_expression
```

`represented_formal_part` reuses the same ordered parameter operation as current
procedure declarations. The result subtype is represented by the existing direct
or selected-name syntax. The parser validates the complete profile and
terminating semicolon before publishing the function defining symbol and
`Function_Declaration_Node`; parameter, optional default-expression, and result
subtype children remain append-only syntax owned by the rejected context if a
later publication fails.

The bootstrap AST package also exercises the represented
`maximum_nodes : Natural := Natural'Last` default, while production token
construction exercises an empty string-literal default. A present default is owned by
its `Parameter_Specification_Node` and extends that parameter's source span. The
frontend preserves the represented expression syntax only; default typing,
omission at calls, and Ada legality rules remain semantic work.

The function-body staging path also recognizes the bounded AARM 6.8 form
`function ... return ... is (expression);`. It reuses the represented function
profile and publishes a `Function_Declaration_Node` whose optional expression
child owns the complete parenthesized return expression. This path is available
for ordinary and procedure-owned local functions, while the existing
function-owned nesting restriction remains unchanged. Expression expected
typing, profile conformance, completion rules, elaboration, and execution remain
semantic work; aggregate expression functions and trailing aspects are not yet
part of this bounded path.

The current package-function path also admits at most one identifier-marked
aspect with an explicit `=>` definition. It publishes one
`Aspect_Specification_Node` after the result subtype and before the function
parent. The production `failure_message` declaration uses
`with pre => result.status = Emission_Operational_Failure`; the relation remains
ordinary represented expression syntax owned by the aspect node. The frontend
does not resolve `pre`, evaluate a contract, apply assertion policy, or decide
aspect legality. Class-wide marks, multiple comma-separated aspects, and omitted
definitions remain outside this bounded subset.

Consecutive package functions use one generic/default-profile path regardless of
function name, overload spelling, parameter count within the represented subset,
or whether subtype marks reuse previously interned symbols. There is no ordinal
or source-line-specific function parser contract. Repository-wide active work
selection belongs in `roadmaps/README.md`, while exact symbol/AST publication
edges belong in regression tests.

Operator-symbol designators, null exclusions, access results, unsupported default
expressions, broader aspect forms, overriding indicators, renamings, ordinary
bodies, and function semantics remain outside this package-declaration subset.
Configured resource exhaustion follows `resource-limits.md`: stable child syntax
may remain append-only, but no partial parameter, function, package, or
compilation-unit parent is published.

## Current Function-Body Representation

Package-body traversal now represents the current function-body subset needed by
the production AST construction wrappers:

```text
represented_function_body ::=
  function defining_identifier [formal_part]
    return selected_subtype_mark is
  {current_function_declarative_item}
  begin
    represented_function_statement+
  [exception represented_function_exception_handler+]
  end [defining_identifier] ;

current_function_declarative_item ::=
    current_identifier_led_declaration
  | represented_nested_procedure_body
  | represented_nested_function_body

represented_nested_function_body ::=
  function defining_identifier return selected_subtype_mark is
  begin
    return represented_expression ;
  end [defining_identifier] ;

represented_function_statement ::=
    represented_procedure_call_statement
  | represented_assignment_statement
  | represented_if_statement
  | represented_case_statement
  | represented_iterator_loop
  | null ;
  | return represented_expression ;
  | represented_extended_return_statement
```

The selected function-handler subset reuses `frontend-exception-handlers.md`.
Each current function handler owns one represented return statement with an
expression; the current production expressions are record aggregates. The
ordinary function statement list must still satisfy the existing expression-
return requirement before handler staging is entered. The final handled-sequence
span extends through the final handler, while result typing, conversions,
exception matching, choice-parameter scope, and control transfer remain semantic
work.

The formal part reuses the function-declaration profile parser and therefore
preserves current default expressions such as `Natural'Last`. The result subtype
reuses the identifier/selected-name representation. Before `begin`, the function
declarative walk dispatches each current item by its grammar-leading token.
Identifier-led declarations reuse the same bounded declaration parser used by
other declarative regions. `Tok_Procedure` parses one shared procedure profile
and then distinguishes its continuation: a semicolon publishes the existing
`Procedure_Declaration_Node`, while `is` continues through the nested-procedure
body path. `Tok_Function` admits one production-driven nested-function body only:
it has no formal part, no declarative items, no exception handlers, and exactly
one ordinary represented return expression. The nested parser call disables any
further nested-function child before descending, so parser call-stack depth is
bounded independently of source nesting. Broader nested-function profiles, local
declarative items, extended returns, handlers, and nested-nested function bodies
retain explicit diagnostics. Every completed child is retained in source order
as one stable declaration ID. This follows AARM 3.11, where a declarative item may
be a basic declaration or a body, and AARM 6.1/6.3 for subprogram declarations
and bodies. Function declarations, body stubs, package bodies, and other
unrepresented declarative items retain the function declarative-part support
boundary.
After `begin`, the parser owns one ordered statement list. Identifier-starting syntax parses its selected leading
name once and dispatches by grammar:
`:=` selects the assignment tail, while every other continuation remains on the
existing procedure-call path so malformed calls keep their established token
diagnostics. `null;` uses the general simple-statement publisher. A current `if`
reuses the existing represented-if staging path; its selected branch subset uses
the shared identifier assignment/call discriminator and includes the bounded
raise-with-string-message statement required by the construction implementation.
The same direct handler-free nested-procedure statement walk now accepts a
current `raise selected_name with represented_expression;` after an initial
represented `if` or other supported statement, delegating to the common raise
publisher rather than maintaining a procedure-specific raise grammar. A direct
`case` token delegates to the same caller-neutral bounded case parser used
inside current iterator loops, retaining the resulting stable `Case_Statement_Node`
in the function's ordered statement list. An explicit `declare` block delegates to
the same bottom-up block parser used inside current iterator loops; completed declarations,
body statements, handler-free handled sequence, and `Block_Statement_Node` are
retained as one ordinary function-body statement. When the next token is `for`, function-body staging delegates the current
`for defining_identifier of [reverse] selected_name loop` form to the represented
iterator-loop path; `while` delegates the represented condition form, and a bare
`loop` selects the simple form with no iteration scheme. All three forms use one
source-order body dispatcher that reuses the current identifier assignment/call
path, represented `if`, the caller-neutral current `case` parser, and the already
owned explicit block publisher. The iterator form additionally interns its
defining identifier as syntax identity and publishes its iterable simple name. A
represented case body preserves ordered name choices or a sole `others` choice
and the current call/raise/simple alternative statements before publishing its
case parent. After exact `end loop;` validation the selected loop publishes one
`Loop_Statement_Node` and returns that stable node to the ordinary function
statement list. The loop parent and its children remain syntax-only; no iterator
scope, condition typing, or execution semantics are created. The represented
function sequence must contain at least one represented function return. A direct
`return represented_expression;` or the selected assignment-body extended return
documented in `frontend-statements.md` satisfies that condition immediately. For
returns owned by current compound statements, the function parser walks already
published `if`, `case`, explicit-block, and loop statement children with an
explicit worklist until it finds an expression-bearing return. This is a bounded
frontend-coverage condition, not a control-flow proof: it does not establish
reachability, termination, or all-path return behavior. A direct top-level return
remains terminal in the current subset, while a compound-owned return does not by
itself forbid following outer statements. A simple return expression delegates to the
general expression publisher, so a call-like expression such as
`Implementation.append_numeric_literal (self, form, ...)` is retained as the
existing `Parenthesized_Name_Node` hierarchy rather than being re-parsed by a
function-specific expression grammar. Extended-return disambiguation uses one
bounded token of lookahead after `return`, preserving existing identifier-starting
simple-return expressions without scanner rewind or backtracking. All completed
statements are wrapped in one handler-free `Handled_Sequence_Node`, then owned by
`Function_Body_Node`.

This operation is grammar driven. On `src/adac/ast/adac-ast-construction.adb` it
automatically traverses the wrapper functions, including the overloaded wrapper
whose declarative part contains `private_declarations : Node_List;`; no wrapper
name, declaration ordinal, source line, or fixed declaration count participates in
parser control. That complete source now frontend-parses successfully. In the
first construction implementation functions the same sequence automatically
represents calls, assignments, a qualified aggregate actual, and the current
`if`/raise statement, then represents generalized iterator, while, and simple
loops through the shared loop node. Iterator loops own defining syntax and
iterable selected names; while loops own a represented condition expression;
simple loops own no iteration-scheme fields. All retain source-ordered supported
bodies including calls, guards, assignments, and explicit blocks. The parser
validates `end loop;` before publishing that parent and then resumes ordinary
function-body statement parsing at the following token. No production identifier,
line, or fixed body count selects this path. Other
function
declarative forms, compound statements outside the selected `if`/`case`/
explicit-block subset, exception handlers, aspects, null exclusions, and access
results remain explicit boundaries.

`Function_Body_Node` preserves syntax identity only: defining/closing symbols,
ordered parameter children, result subtype, ordered declaration children, handled
sequence, and complete span.
It does not create a function entity, bind the closing designator, resolve the
result type or return expression, select overloads, establish a scope, or perform
elaboration. AST exhaustion may leave completed profile, declaration, statement, or expression
children private to the rejected context, but neither the handled-sequence parent
nor function-body parent is partially published. Stable nested procedure/function
children are checked shallowly during function-body construction. Raw and
context-aware function validation traverse nested function children through
explicit worklists, while nested procedures retain their existing explicit
procedure-body worklist, so validation stack usage is independent of nested-function
AST depth.

## Handler-Free Procedure-Call Bodies

Ada 2022 AARM 6.3 permits an empty `declarative_part` before `begin`, and the
handled sequence remains nonempty. The first package-body declarative item in
`src/adac/driver/adac-driver.adb`, `procedure print_usage is`, uses that shape and
contains one procedure call whose positional actual is the already represented
string-concatenation expression.

The current handler-free subset is:

```text
current_handler_free_procedure_body ::=
  procedure identifier [current_formal_part] is
  begin
    current_handler_free_statement
    {current_handler_free_statement}
  end [identifier] ;

current_handler_free_statement ::=
    current_identifier_statement
  | represented_if_statement
  | represented_case_statement
  | represented_explicit_block_statement
  | represented_for_loop
  | represented_while_loop
  | represented_simple_loop
  | represented_raise_statement

current_identifier_statement ::=
    represented_assignment_statement
  | current_procedure_call_statement
```

The parser reuses the existing nested-procedure header and formal-part staging.
When `begin` follows `is` directly, identifier-leading statements delegate to the
common assignment-or-call publisher; represented `if`, `case`, explicit `declare`
blocks, all three current loop forms, and bounded raise statements reuse their
existing caller-neutral publishers. Procedure-call actual associations retain
represented current expressions, including AARM 4.5.1 `and`, `or`, and `xor`
logical expressions. Those logical chains are represented left-associatively and
validated iteratively. Parenthesized-name actuals may also retain an AARM 4.1.2
slice whose lower and upper bounds each use represented binary adding syntax;
the parser stores slice state in the existing explicit parenthesized frame so
nesting does not consume call-stack depth. Call binding, formal matching, modes,
overload resolution, and evaluation remain deferred. Each stable statement node
is appended in source order. After the bounded statement sequence, the common
completion path
publishes one `Handled_Sequence_Node`, optionally after delegating a following
`Tok_Exception` to the current handler parser, then publishes the closing form and
existing `Procedure_Body_Node`. A declaration-free nested body beginning with
`null;`, for example, still retains `nested procedure statements are not
supported`. Existing `report_exception` parsing now shares this same completion
path instead of retaining a separate handler-specific body publisher.

For the production `print_usage` body, the already represented context clause
state is seventeen symbols and forty-six AST nodes. The procedure defining name
and `put_line` selector add two distinct symbols. Callable-name syntax, two string
literals, their binary concatenation, the call statement, handled sequence, and
procedure body add nine AST nodes, so successful first-body publication reaches
nineteen symbols and fifty-five AST nodes with zero semantic entities. Package-
body staging then stops at the next declarative item, `procedure
finish_with_failure ...`, rather than discarding or pre-parsing that declaration.

Package-body ownership, declaration completion, callable binding, and execution
semantics remain outside this procedure-body representation slice.

A nonempty current declarative part uses production-selected statement
continuations without publishing a handled-sequence or procedure-body parent
until the complete body boundary is known. `compile_parsed_unit` first
preserves the represented `Ada.Text_IO.put_line ("adac: parse ok");` call and
delegates its
following block structure to the current block path. `run` preserves consecutive
current represented `if` statements iteratively in the same ordered
`handled_statements` list. After the first two guards, the `run` continuation
may delegate a following `declare` token to the existing block-prefix staging
operation. Completed block declarations remain append-only syntax until block
ownership exists; the block itself is not appended to `handled_statements` in
this prefix slice. The first expression or declaration outside the current block
prefix remains the owning frontend boundary.

The next production procedure, `finish_with_failure`, uses the same formal-part
and handler-free body shape. Its simple formal parameter and current calls are
representable, including the nested parenthesized-name actual
`Adac.Support.image (Adac.Compilation.Diagnostics.error_count (context))`. Nested
parenthesized items are published bottom-up and validated iteratively. Package-
body declarative traversal now retains both `print_usage` and
`finish_with_failure` as consecutive `Procedure_Body_Node` values. It then enters
the next production procedure, `compile_parsed_unit`, represents its `in out`
`context` parameter and two omitted/default-`in` parameters, and represents the
variable declaration `module : Adac.IR.Module;`. The earlier two bodies, all three
new parameter nodes,
and the variable declaration remain stable append-only syntax; no package-body
parent or semantic completion is published. The following `declare` token is recognized as a block-statement header. The
block-local full constant `analysis` is represented through the existing current
declaration path without publishing a block parent. The block `begin` is then
consumed and the current `case analysis.status is` header is staged. The first
`when Adac.Sema.Analysis_Rejected =>` alternative preserves its selected-name
choice, `finish_with_failure (context);` call, and `return;` statement. The
second alternative preserves its selected-name choice and initial `put_line`
call. The following assignment is represented as `Assignment_Statement_Node`.
After the exact `end case;` and unlabeled block `end;` forms validate, both case
alternatives, the case statement, the block handled sequence, and the block
statement are published bottom-up. The completed block is retained in the
procedure's temporary handled-statement list before line 67 is exposed. The
following `Ada.Text_IO.put_line ("adac: ir ok");` is then represented with the
existing procedure-call syntax and appended after the block. Production reaches
line 69 `declare` at 39 symbols, 152 AST nodes, and zero semantic entities without
publishing the enclosing procedure body. A 151-node budget rejects before the
post-block call parent without losing the owned block or call children. The
selected next slice consumes the second block prefix, represents its `result`
full constant through the existing object-declaration path, and stops at line 73
`case result.status is` with 42 symbols, 162 AST nodes, and zero semantic
entities while the enclosing procedure body remains unpublished. A 161-node
budget rejects before partial `result` object-parent publication. The existing
case-header expression path then represents `result.status` and stops at line 74
first `when` with 42 symbols, 164 AST nodes, and zero semantic entities. A
163-node budget rejects before partial selected-name parent publication, and no
second case/block parent is published. The first second-case alternative choice
plus its two calls and `return;` are then represented and the complete alternative
parent is published at line 80, reaching 45 symbols, 183 AST nodes, and zero
semantic entities. A 182-node budget rejects before partial alternative-parent
publication. The remaining `Emission_Succeeded => null;` alternative and exact
`end case; end;` closing forms then complete the second case and block ownership
bottom-up, after which the block is appended to the procedure's ordered handled-
statement list. Production reaches line 85 at 46 symbols, 191 AST nodes, and zero
semantic entities; budgets 187 through 190 reject each successive ownership
parent without partial publication. The following two production `put_line`
calls are then traversed iteratively through the existing call/expression path
and retained as later statements of the same procedure, reaching line 91 closing
`end` at 46 symbols, 214 AST nodes, and zero semantic entities. Budgets 195 and
213 reject before the respective call parents without partial publication.

## `compile_parsed_unit` Body Ownership

At the line 91 closing `end`, the `compile_parsed_unit` profile, `module`
declaration, and complete ordered statement list are all represented. The parser
therefore reuses the existing handler-free body ownership contract: it publishes
one `Handled_Sequence_Node` over the complete statement list, consumes
`end [designator];`, and then publishes one `Procedure_Body_Node` owning the
profile, declaration, handled sequence, and complete source span. The optional
closing designator is preserved as syntax identity but name equality remains a
later legality rule.

The handled-sequence and procedure-body parents are appended only after all child
syntax is stable. AST budgets 214 and 215 reject before those two parents,
respectively, leaving the earlier children valid without partial publication.
The completed body brings the path to 216 AST nodes while retaining 46 distinct
symbols and zero semantic entities. Once the body is complete, the package-body
declarative-item loop resumes at the next `procedure` instead of requiring a
special transition for `compile_parsed_unit`. It enters `compile_file`,
represents its three current parameters and first logging call, and reaches line
101's bare `begin` at 48 distinct symbols, 231 AST nodes, and zero semantic
entities. The AARM 5.6 bare-block header then consumes that `begin` as a block
with an implicit empty declarative part and exposes line 102's inner `declare`
without additional symbol, AST, or semantic publication. The nested explicit
block then represents its current `result` full constant and consumes its
`begin`, exposing line 106 `case result.status is` at 50 distinct symbols, 241
AST nodes, and zero semantic entities while outer/inner block ownership remains
unpublished. The existing AARM 5.4 case-header path then represents
`result.status` and reaches line 107's first `when` at 50 symbols, 243 AST nodes,
and zero semantic entities. A 242-node budget rejects before the selected-name
parent; the earlier 240-node budget rejects before the `result` object parent.
The next selected slice preserves the first parse-result case alternative
through its `Adac.Frontend.Parse_Rejected` choice and
`finish_with_failure (context);` call, publishing only the alternative parent and
stopping at the second `when`; case and block ownership remain deferred.
The following ownership slice is selected to represent the
`Adac.Frontend.Parse_Succeeded` alternative, validate `end case; end;`, and
publish the completed inner case/block bottom-up while leaving the enclosing
bare block pending at its `exception` part.
The parameterless six-choice exception handler owns its two current calls and
simple `return;` in one `Exception_Handler_Node`. The enclosing bare block then
owns the completed inner block and that handler through a handled sequence plus
`Block_Statement_Node`, reaching line 126 `end compile_file;` at 58 symbols,
297 AST nodes, and zero semantic entities. The selected AARM 6.3 ownership slice
wraps the initial logging call plus that block in one handler-free
`Handled_Sequence_Node` and then publishes the `compile_file`
`Procedure_Body_Node`. Those two parents consume AST slots 298 and 299; package-
body traversal then continues immediately into the following `run` procedure.
The current declaration path represents `options : constant
Adac.Support.CLI.Options := Adac.Support.CLI.parse;`, and the represented-if
caller publishes `not options.valid` plus the first guard's three calls and bare
`return;` in one ordered statement list. The complete `If_Statement_Node` is
then published. The procedure-body continuation reuses that same represented-if
boundary for the second guard `not options.has_input`, retaining both complete
`If_Statement_Node` values in source order before stopping at line 147
`declare`. The second guard introduces only the new `has_input` symbol and adds
fourteen AST nodes. The continuation then delegates the line 147 block prefix,
which publishes the current `input_path` full constant, the parenthesized
conditional `output_path` initializer, and the complete `output_path` object
parent. It then represents the following `context` variable's selected subtype and current parenthesized-name
initializer, allowing the complete declaration parent to be published. The
block prefix then consumes `begin` and exposes the line 157 `compile_file` call
without publishing a block parent. Production reaches 68 symbols, 382 AST nodes,
and zero semantic entities. A 381-node budget protects the `context` object
parent; budgets 369/370 protect the two conditional parents, and the earlier
357-node `input_path` and 348-node second-if boundaries remain green.

The next current statement is the explicit `declare` block itself. Its body call
and `end;` are owned by `frontend-statements.md`; the completed block is retained
as the third ordered handled statement after the two guards. Production now stops
at line 159 `end run;` with 68 symbols, 389 AST nodes, and zero semantic entities.
This slice deliberately stops before publishing the procedure handled sequence or
`Procedure_Body_Node`, keeping block ownership and subprogram ownership as
separate resource boundaries.

The selected AARM 6.3 ownership slice reuses the existing handler-free
procedure-body publisher after the complete block is stable. It wraps the two
represented guards plus the block in one ordered `Handled_Sequence_Node`,
validates `end [designator];`, preserves the present `run` closing designator,
and publishes the `Procedure_Body_Node` only after all children and closing
syntax are complete. The two parents advance production from 389 to 391 AST
nodes while retaining 68 symbols and zero semantic entities. Budgets 389 and 390
reject respectively before the handled-sequence and procedure-body parents.
Package-body traversal then reaches line 161 `end Adac.Driver;`; package-body
ownership remains a later boundary.

## Symbol And AST Ownership

The nested procedure defining identifier is now interned and stored directly by
`Procedure_Body_Node`. This is syntax identity rather than a callable entity or
lexical-scope binding. A present closing identifier is stored separately;
absence
is represented by `INVALID_SYMBOL_ID`. The production spelling
`report_exception` is already referenced later by outer staging, so publishing
the defining occurrence does not increase the final production distinct-symbol
count. The standalone nested fixture does gain that previously unpublished
symbol.

The represented parameter nodes remain ordered profile children. The two current
`Object_Declaration_Node` values are accumulated in source order as the nested
body's declarative part. The already represented `Handled_Sequence_Node` becomes
the body statement/handler child. The procedure body parent therefore adds one
AST node to the nested path without copying any child subtree or statement list.

For the current nested fixture, publication advances from fourteen symbols and
forty-seven AST nodes to fifteen symbols and forty-eight AST nodes. At nested-body
publication the production path reaches sixty-three AST nodes; the represented
outer call, handlers, handled sequence, and procedure body then advance the full
production path to one hundred twelve AST nodes while retaining twenty-eight
distinct symbols and zero semantic entities.

Ordinary handler-free library procedures use the same normalized structure:
their
parsed statement list is wrapped once in a handler-free `Handled_Sequence_Node`
before the procedure body is created. `statement_count` and `statement_at` read
that owned sequence for downstream compatibility; they are not separate storage.

## Failure And Resource Contract

Formal-parameter, declarative-item, and selected-subtype-mark loops remain
iterative. The nested body retains temporary `Node_List` values containing only
already-published parameter and declaration IDs; their lengths are bounded by
the existing AST-node and source-character budgets. The handled sequence is one
stable node identifier rather than a copied statement tree.

Publishing the nested defining identifier uses the existing distinct-symbol
budget. The procedure-body parent consumes one AST-node budget slot after every
child has been validated; exhaustion therefore leaves the earlier append-only
children valid and publishes no partial body. A handler-free ordinary body first
consumes one handled-sequence slot and then one body slot under the same failure
policy. Closing `end [designator];` parsing is constant work aside from optional
symbol interning and introduces no recursive traversal or auxiliary nesting
stack. Internal impossible-entry conditions remain `Program_Error` contract
failures rather than ordinary source diagnostics.

## Procedure Bodies As Subunit Proper Bodies

The compilation-unit parser may reuse the current represented procedure-body
staging path after Ada 2022 AARM 10.1.3 `separate (parent_unit_name)` syntax.
The resulting `Procedure_Body_Node` is preserved as the earlier proper-body
child of `Subunit_Node`; it is not exposed as an ordinary library item. This is
a syntax-ownership reuse only. The procedure parser retains its existing bounded
declaration and handler-free statement subset, and the subunit layer requires
EOF after the complete body before publishing the parent node.

This selected proper-body slice does not implement function, task, or protected
subunit bodies, body-stub/proper-body conformance, parent-body lookup, visibility,
elaboration, or post-compilation rules. Those remain distinct semantic or later
frontend work.

## Enclosing Procedure Closing Form

After the complete current outer exception-handler list returns with `Tok_End`
current, the bootstrap-production staging path owns the enclosing procedure
closing form:

```text
staged_current_enclosing_procedure_closing ::=
  end [identifier] ;
```

This is the current production subset of Ada 2022 AARM 6.3
`end [designator];`. The production source uses `end adac_main;`.

The parser consumes `end`, interns an optional identifier designator as syntax
identity, consumes the terminating semicolon, and requires `Tok_EOF` afterward.
An absent designator is represented by `INVALID_SYMBOL_ID`. The closing
identifier is not compared with the opening procedure symbol at this syntax
boundary. AARM 6.3 requires a present closing designator to repeat the defining
designator, but that remains a semantic legality rule.

Successful structural completion publishes the outer handled sequence and outer
procedure body and returns the represented body to the compilation-unit
publication boundary. `parse_file` then owns root construction. A missing
semicolon, invalid present identifier, or trailing source retains the ordinary
syntax diagnostic before root publication. A distinct valid closing identifier
is preserved rather than rejected prematurely; in the production source,
`adac_main` reuses the existing opening symbol and therefore does not increase
the distinct-symbol count.

Before root publication, the full production path retains twenty-eight distinct
symbols, reaches one hundred twelve AST nodes, and retains zero semantic
entities. The outer handled sequence contributes one node and the outer
procedure body contributes one node after all children have been validated. The
compilation-unit root then consumes one additional AST-node slot. Exhaustion at
any of these parent boundaries leaves earlier append-only children intact and
publishes no partial parent.

This slice does not:

- perform closing-designator legality checking or declaration elaboration;
- make procedure bodies, exception handlers, or calls executable semantics; or
- claim context dependency, visibility, or elaboration semantics merely because
  the frontend can publish the complete compilation root.

The outer handler structure is now represented. The selected ownership slice
creates one outer `Handled_Sequence_Node` for `Adac.Driver.run;` plus both outer
handlers, then creates the outer `Procedure_Body_Node` with the represented
`report_exception` body as its declarative item. This remains syntax-only: no
procedure entity, nested scope, declaration elaboration, or executable handler
semantics is published. The enclosing compilation-unit root owns that body as
its library item; context-clause semantics remain a later boundary.

Allowing a `Procedure_Body_Node` in another procedure body's declarative list
makes procedure-body AST structure recursively nestable. Both structural and
context-aware validators therefore traverse nested procedure bodies with an
explicit bounded work list rather than recursive procedure-body calls. Work is
linear in reachable represented syntax, auxiliary `Node_ID` storage is bounded
by the AST-node budget, and malformed, foreign, out-of-order, or exhausted
construction still publishes no partial parent node.

## Test Contract

Tests for this boundary shall cover:

- a production-shaped nested procedure with two represented parameters and two
  ordered object declarations;
- publication of the nested defining symbol without creating a semantic entity;
- one `Procedure_Body_Node` owning its parameters, declarative items, and
  existing
  `Handled_Sequence_Node`;
- procedure-body compatibility statement queries delegating to the handled
  sequence rather than duplicated storage;
- exact body span from `procedure` through the terminating semicolon;
- preservation of a present `end report_exception` designator;
- preservation of the AARM 6.3 `end;` form as an absent designator rather than
  an
  invented symbol;
- mismatch of a present designator remaining semantic legality rather than a
  parser syntax error;
- malformed, foreign-context, out-of-order, and missing handled-sequence
  children
  rejecting without partial parent publication;
- controlled AST-node-budget exhaustion immediately before the nested body
  parent
  is appended;
- production package-function reuse through line 96
  `program_unit_name_component_count`, including its default-`in` parameter,
  direct result subtype, delayed defining symbol, and 73/53 resource boundaries;
- production line 101 `program_unit_name_component_symbol` reuse with two
  default-`in` parameters, selected result subtype, and 74/61 resource
  boundaries;
- production line 107 `program_unit_name_component_span` reuse with selected
  `Adac.Source.Span` result and 75/69 resource boundaries;
- production line 113 `Enumeration_Literal_List` `append` reuse with no new
  symbol and an 80-node procedure-parent boundary;
- production line 119 `enumeration_literal_list_count` reuse with 76/84
  symbol/parent resource boundaries;
- production line 124 `enumeration_literal_list_symbol` reuse with selected
  result subtype and 77/92 resource boundaries;
- production line 130 `enumeration_literal_list_span` reuse with selected
  `Adac.Source.Span` result and 78/100 resource boundaries;
- production `append_numeric_literal` owning its `Natural'Last` formal default
  as current attribute-name syntax, including default-child query and resource
  boundaries without evaluating the default;
- the nested fixture reaching fifteen symbols and forty-eight AST nodes;
- the full production path reaching twenty-eight symbols, one hundred thirteen
  AST nodes, and zero semantic entities after compilation-unit-root publication;
- handler-free ordinary procedures using the same handled-sequence ownership
  while retaining existing semantic and IR statement behavior;
- the outer handled sequence owning the represented `Adac.Driver.run;` call and
  both represented outer exception handlers;
- the outer procedure body owning the nested `report_exception` body as its
  declarative item and preserving its optional closing designator;
- controlled AST-node-budget exhaustion before the outer handled-sequence and
  outer procedure-body parents are appended;
- the production `run` body owning its two guards plus completed block in one
  handler-free handled sequence before the package-body closing boundary;
- production budgets 389 and 390 rejecting before the `run` handled-sequence
  and procedure-body parents without partial publication;
- the represented outer body becoming the library item of one validated
  compilation-unit root without publishing a semantic entity; and
- malformed outer closing syntax retaining its earlier syntax diagnostics.
