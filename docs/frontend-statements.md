# Frontend Statements

This document defines the current frontend statement staging and representation
boundary. The deterministic bootstrap profile composes the represented statement
forms below across procedure/function bodies, explicit blocks, conditionals,
case statements, loops, and handled sequences. Representation remains syntax-only
unless `semantic-model.md` explicitly defines a later semantic boundary. Some
parser callers intentionally expose narrower statement subsets, so unsupported
diagnostics documented here are caller-specific rather than a claim that the
syntax is absent everywhere in the frontend.

## Bootstrap Coverage

Bootstrap-profile production sources are integration inputs, not parser control
data or a mutable source-line frontier. Every current bootstrap-profile member
parses and structurally validates through the frontend gate described by
`bootstrap-profile.md`. Production examples in this document illustrate syntax
shapes that drove representation work; historical source-line progression belongs
in Git history.

Ada 2022 AARM 6.4 defines a `procedure_call_statement` as either
`procedure_name;` or a procedure prefix followed by an actual-parameter part.
Current statement representation preserves the supported callable name and
ordered positional/named actual syntax without resolving whether the name denotes
a callable entity. Callable binding and execution remain semantic work.

## Current Grammar Boundary

The bootstrap-driven statement staging now includes:

```text
staged_current_if_statement ::=
  if staged_if_condition then staged_current_selected_sequence
    {elsif staged_if_condition then staged_current_selected_sequence}
    [else staged_current_selected_sequence]
  end if ;

staged_if_condition ::= expression

staged_current_selected_sequence ::=
  staged_current_selected_statement {staged_current_selected_statement}

staged_current_selected_statement ::=
    staged_current_procedure_call_statement
  | staged_current_if_statement
  | staged_current_block_statement
  | represented_iterator_loop
  | staged_current_raise_statement
  | return ;

staged_current_procedure_call_statement ::=
    staged_selected_callable_prefix ;
  | staged_selected_callable_prefix
      ( staged_parameter_association
        {, staged_parameter_association} ) ;

staged_parameter_association ::=
    staged_actual_expression
  | identifier => staged_actual_expression

staged_actual_expression ::= expression

staged_selected_callable_prefix ::= identifier {. identifier}
```

### Top-level statement-sequence recovery

The first statement-boundary recovery subset applies only to the top-level
procedure statement sequence owned directly by the compilation-unit parser. A
`use` token at that boundary cannot begin an Ada statement; current AARM 8.4 use
clauses belong to declarative parts. The parser therefore reports `declarative
item is not allowed in statement sequence` and synchronizes iteratively through
the next semicolon, or stops before caller-owned `end` or `exception`. A consumed
semicolon guarantees forward progress even when the misplaced `use` is already
adjacent to the synchronization delimiter.

This recovery is deliberately not delegated to the ordinary statement parser and
does not clear `self.failed`. Lexer/resource failures during synchronization and
EOF before a synchronization boundary remain terminal. After a recovered use
clause, later valid statements may still be parsed and represented so diagnostic
collection can continue, but the compilation-unit parser records the recovery and
marks the frontend result rejected after consuming the closing syntax. The
enclosing `Procedure_Body_Node` and compilation-unit root are therefore never
published from a recovered sequence. Nested arm/block/loop statement sequences
retain their existing fail-fast contracts until they receive their own bounded
recovery rule.

These productions are frontend staging forms, not replacements for the full Ada
`if_statement`, `sequence_of_statements`, or `procedure_call_statement` grammar.
A represented `if` arm owns one or more current selected statements, iterated in
source order. The current selected statement subset is a represented assignment,
procedure call, bounded raise-with-string-message statement, nested `if`,
handler-free explicit block, current represented iterator loop, or bare `return;`.
Other compound statements, labels,
and return expressions remain outside this arm-specific slice. Actual counts are
not hardcoded. Current named associations use an identifier selector and follow
Ada 2022 AARM 6.4 ordering: any positional associations precede all named
associations. Formal-parameter binding remains outside this frontend subset.

Parenthesized current calls reuse the expression parser owned by
`frontend-expressions.md`. Each actual expression returns structurally with
either a caller-owned comma or the closing `Tok_Right_Parenthesis` current. For
a named association the call parser first preserves the identifier selector,
consumes `=>`, and then parses the actual through the same expression path. The
call parser consumes delimiters iteratively and then the statement semicolon. A
no-actual-parameter-part call consumes its semicolon directly.

When call publication is requested, every association actual must return a
represented expression node and every named selector must return a represented
identifier-name node. A structurally valid actual that is outside the current
represented-expression subset is an ordinary source support boundary, not an
internal invariant failure: the call parser records `procedure call actual
expression is not supported` at that actual's first token and publishes no call
parent. A positional association after a named one is rejected before parent
publication. Earlier append-only name/expression children remain private to the
failed compilation. Staging-only call paths consume and enforce the same
association ordering without requiring call publication.

Every callable prefix reuses the iterative identifier-selected parser owned by
`frontend-names.md`. The represented nested calls and the selected outer
`Adac.Driver.run;` path publish their callable names and call nodes. Handler
call paths continue to disable publication until handler ownership is
represented. No parser path classifies the prefix semantically as a procedure,
resolves parameter modes, binds actuals to formals, or performs overload
resolution. The `if` parser owns every `elsif`, optional `else`, and the closing `end if;`
tokens. Each completed `elsif` part is published bottom-up before the enclosing
`If_Statement_Node`.

The `if` staging operation has an explicit completion policy. Ordinary statement
parsing continues to reject the current `if` without publishing child syntax.
The represented completion mode publishes the opening condition, every represented
statement in each selected arm, one `Elsif_Part_Node` for each completed `elsif`
arm, and the enclosing `If_Statement_Node`, then returns so its caller can expose
the next production source boundary. Current arm statements may themselves be
`if` statements, handler-free explicit blocks, current represented loops, or
represented `case` statements. Represented completion uses one explicit vector
of pending compound frames for `if`, block, loop, and case. Each completed inner
node is appended to its parent arm/body before that parent is closed, so
alternating `if -> loop -> case -> if` source does not grow the parser call
stack. The earlier structural-only completion mode is no longer
part of the current parser contract because its iterator-loop caller now owns
complete represented `if` syntax.
When a caller requests represented `if` syntax but the structurally valid
condition is outside the current represented-expression subset, staging rejects
with `if condition expressions are not supported` at the condition start instead
of treating the missing child as an internal invariant failure. Already-published
append-only name children remain private to the rejected compilation. Malformed
conditions retain expression-owned syntax diagnostics.

The selected represented `if`/case paths also admit `Tok_Raise` and delegate to one
bounded raise publisher. It now preserves either bare `raise;` as
`Bare_Reraise_Form` or the existing identifier/selected exception name plus
`with` message as `Named_With_Message_Raise_Form`, always including the terminating
semicolon before creating `Raise_Statement_Node`. This follows AARM 11.3 syntax
without performing handler-context legality, exception identity, propagation, or
String typing/conversion in the frontend. The intermediate
`raise exception_name;` form remains an ordinary frontend support boundary.
Ordinary top-level statement parsing is not widened merely because the syntax
node exists.

Statement parsing also has an explicit publication policy. Ordinary statement
sequences publish their represented statement nodes to their caller-owned list.
The outer bootstrap path requests one represented call node but does not attach
it to a handled sequence yet; its caller retains the stable node ID for the
future outer-body ownership slice. The current exception-handler staging path
may reuse the same statement parser with publication disabled, so its `null;`
syntax
is validated without attaching a statement node to the wrong owner.

## Return Statement Representation

The general statement publisher preserves simple and extended returns as distinct
syntax forms:

```text
represented_return_statement ::= return [represented_expression] ;

represented_extended_return_statement ::=
  return defining_identifier : represented_simple_subtype_mark
    do represented_extended_return_body_statement+ end return ;

represented_extended_return_body_statement ::=
    represented_null_statement
  | represented_assignment_statement
  | represented_procedure_call_statement
```

`Return_Statement_Node` owns the complete simple-return span and optionally an
earlier represented expression. A bare return stores `INVALID_NODE_ID`; an
expression return stores the represented child and can be queried through
`return_has_expression` and `return_expression`. Expression publication uses the
existing bounded expression parser and caller-owned semicolon boundary. A
structurally valid but currently unrepresented simple-return expression is an
ordinary frontend support rejection, not an internal invariant failure.

`Extended_Return_Statement_Node` is the selected AARM 6.5 compound form needed by
bootstrap. It owns the defining identifier symbol/span, one earlier simple subtype
mark, and one earlier handler-free `Handled_Sequence_Node`. The current `do` body
is a nonempty iterative sequence of represented null, assignment, and
procedure-call statements; no fixed statement count is encoded. All three statement forms are already stable leaves under handled-sequence
validation, so this widening adds no recursive extended-return graph. `aliased`, `constant`, an initializer, an access-definition
result subtype, an absent `do` part, other statement kinds, and exception handlers
remain explicit later boundaries. Return-object binding, subtype compatibility,
initialization semantics, accessibility, and transfer of control remain semantic.

The represented `if`-arm grammar accepts bare `return;` and, when syntax
publication is requested, a simple return whose expression already belongs to the
represented expression subset. Staging-only callers keep the earlier bare-return
boundary, and extended returns in an `if` arm remain outside this slice. Current
procedure semantic analysis still rejects an expression return instead of
silently treating it as a procedure return. The root-neutral compound-frame case
alternative path follows the same publication rule: when represented syntax is
requested, a simple `return represented_expression;` is retained as one
`Return_Statement_Node`; staging-only callers keep the earlier unsupported-expression
boundary, and an extended return is not accepted as a case simple statement. This
keeps nested loop/block/case ownership grammar-equivalent to the direct case path
without adding result typing or control-flow semantics. Result-type resolution,
legality of returning from the enclosing callable, conversion, and control-flow
semantics remain later work.

## Exit Statement Representation

The current frontend preserves the Ada 2022 AARM 5.7 exit-statement syntax with
one dedicated node:

```text
represented_exit_statement ::= exit [when represented_expression] ;
```

`Exit_Statement_Node` owns the complete statement span, no loop-name syntax in
the first parser subset, and either no condition or the exact `when` token span
plus one earlier represented condition expression. The AST construction API also
models the optional Ada loop name as a symbol/span pair so later support can add
`exit loop_name [when condition];` without changing node identity. The current
parser deliberately rejects a present loop name with `named exit statements are
not supported` rather than dropping it.

The same exit publisher is available to represented loop bodies and compound
if/block/case children. This is a syntax decision only: whether an exit is legally
nested in and names an enclosing loop, whether its condition is Boolean, and what
control transfer occurs remain semantic responsibilities. Expression parsing
reuses the existing bounded publisher and the caller-owned terminating semicolon.

## Loop Representation

The current frontend represents four unlabeled Ada 2022 loop source forms
selected by AARM 5.5/5.5.2: the ordinary `for ... in` loop-parameter form with an
explicit range, the generalized `for ... of` iterator form, the `while` form, and
the simple form whose optional iteration scheme is absent. All publish the same
`Loop_Statement_Node` with an explicit source-form discriminator.

```text
represented_discrete_range_loop ::=
  for defining_identifier in [reverse]
    represented_simple_expression .. represented_simple_expression loop
      represented_loop_statement {represented_loop_statement}
  end loop ;

represented_iterator_loop ::=
  for defining_identifier of [reverse] represented_iterable_name loop
    represented_loop_statement {represented_loop_statement}
  end loop ;

represented_while_loop ::=
  while represented_expression loop
    represented_loop_statement {represented_loop_statement}
  end loop ;

represented_simple_loop ::=
  loop represented_loop_statement {represented_loop_statement} end loop ;

represented_iterable_name ::= identifier {. identifier}

represented_loop_statement ::=
    represented_assignment_statement
  | represented_exit_statement
  | represented_procedure_call_statement
  | represented_if_statement
  | represented_case_statement
  | represented_block_statement
```

The ordinary explicit range form owns the defining identifier as syntax identity,
optional `reverse`, and two earlier represented simple-expression bounds in
source order. The range-attribute form owns the same defining syntax and
`reverse` flag plus one earlier represented `name'Range` attribute node. The
generalized iterator form owns the same defining syntax and `reverse` flag plus
an earlier iterable simple name. The while form owns an
earlier represented condition expression and no iterator-only header fields.
The simple form owns no iteration-scheme fields. These header representations
are mutually exclusive and all forms require a nonempty ordered body. No range
subtype, loop-parameter entity, iterable classification, Boolean typing, or
overload resolution is created at syntax time.

One root-neutral compound-frame vector handles represented if/block/range-loop/
generalized-iterator/while/simple-loop/case nesting. `for` consumes the shared
defining identifier and then dispatches by the grammar token: `in` selects the
ordinary AARM 5.5 loop-parameter form. Its discrete subtype definition may be the
current explicit two-simple-expression range around `..` or a represented
`name'Range` attribute reference; `of` selects the current AARM 5.5.2 iterable-
name form. `while` is
classified case-insensitively as `Tok_While`, its condition is parsed by the
existing expression parser through the required `loop` delimiter, and bare
`Tok_Loop` selects the same frame with no iteration scheme. Closing syntax reuses
the exact `end loop;` operation. Completed body statements are retained in source
order and the parent is published only after closing syntax succeeds. A directly
nested loop remains outside the current loop-body contract; other represented
compound children are validated through the mixed explicit worklist rather than
recursive subtree validation.

The loop node preserves syntax only. Loop-parameter scope/binding, discrete-range
typing and null-range behavior, iterable classification, Boolean condition typing,
iteration order, control transfer, and execution remain semantic work.

### Owned explicit block in current statement sequences

The same explicit-block parser is selected by current iterator-loop bodies and by
the general represented function-body statement dispatcher. The current production
loop contains an explicit `declare` block with a complete independent ownership
boundary:

```text
represented_iterator_block ::=
  declare {represented_current_identifier_declaration}
  begin represented_iterator_block_statement
        {represented_iterator_block_statement}
  end ;

represented_iterator_block_statement ::=
    represented_current_identifier_statement
  | represented_current_return_statement
  | represented_current_if_statement
  | represented_current_case_statement
  | represented_current_iterator_loop_statement
  | represented_current_block_statement
```

The declaration walk retains every complete current object declaration in source
order. The identifier-statement dispatcher publishes either the existing
assignment or procedure-call statement according to its grammar continuation,
and the `if` path uses represented completion. Every completed body statement is retained as a stable earlier node ID. Compound
`if`, block, iterator-loop, and case syntax is driven by one explicit frame vector,
so nested block/loop combinations do not recurse through the parser call stack.
The frame/list state is bounded by the same source and AST resource controls. The
block requires at least one represented body statement. The shared compound
frame may now also be rooted directly at `Tok_Begin`; that form publishes the
same `Block_Statement_Node` with an empty declaration list rather than inventing
a declarative part. The nested-procedure handler-free statement dispatcher routes
both `Tok_Declare` and `Tok_Begin` through this same block publisher, including a
bare block that follows earlier represented statements or is the first statement
after a represented declarative part. A represented block body uses the same
rule for a nested `Tok_Begin` child, pushing another block frame exactly as it
does for `Tok_Declare`. Represented `if` arms apply the same composition rule,
so a bare block is retained as one ordered arm statement rather than requiring
an explicit `declare`. The production exception-handler cleanup block uses this
bare-root entry and may own its own bounded handler list.

Only after the exact unlabeled `end;` closing syntax is accepted does the parser
publish one `Handled_Sequence_Node` spanning the first body statement through the
last ordinary statement or final exception handler, followed by one
`Block_Statement_Node` owning the retained declaration list and that handled
sequence. A block frame that encounters `exception` after a nonempty ordinary
body delegates the handler list to `parse_exception_handlers_staging`, which
returns at the block's `end`. The production-selected handler form therefore
owns `when others => free_arguments (arguments); raise;` without assigning
exception semantics. The common block parser/publisher is shared with the
function-body dispatcher and the already represented package-body block paths,
so source-order, span, resource, and validation behavior are not reimplemented
for each caller. A function body appends the completed block to its ordinary
statement list only after exact `end;` validation; the block remains syntax-only
and creates no scope or elaboration state. The current block-specific validator
admits assignment, nested handler-free block, case, `exit`, procedure call,
iterator-loop, simple return, and `if` statements. Construction preflight, raw
full validation, and compilation-context validation apply the same statement-kind
bound so parser publication cannot expose a later validator-only rejection. When
represented syntax is requested, a
simple return may retain an already represented expression through the ordinary
return publisher. Staging-only callers preserve the earlier bare-`return;`
boundary and publish no return node, while extended returns remain outside the
block-body subset. Compound full validation uses the mixed worklist, and a
handler-bearing block cannot directly own another handler-bearing block, keeping
source-controlled nesting off the validator call stack.

## Block-Statement Header Staging

Ada 2022 AARM 5.6 defines an unlabeled block statement as an optional `declare`
plus `declarative_part`, followed by `begin`, a handled sequence, and `end`. The
current bootstrap source reaches an explicit block immediately after the
represented first `compile_parsed_unit` body call.

The current staging boundary is deliberately smaller than block ownership:

```text
staged_block_prefix ::=
  [declare {represented_current_object_declaration}] begin
```

`declare` is classified case-insensitively as `Tok_Declare` and consumed without
publishing a symbol or AST node. When it is present, consecutive
identifier-starting declarations are delegated iteratively to the current
declaration parser and their completed AST nodes remain append-only syntax; no
block parent or declaration scope is created. When `declare` is absent, the
block has the AARM 5.6 implicit empty declarative part and staging begins directly
at `begin`. In either form, `begin` is consumed before the caller selects the
block body representation. A different explicit declarative item retains `block
statement declarative parts are not supported`, while malformed current
declarations keep their own more precise declaration diagnostics. If the first
body token is outside the caller-selected current subset, staging stops there
with `block statement bodies are not supported`.

The production `src/adac/driver/adac-driver.adb` represents the block-local full
constant `analysis : constant Adac.Sema.Analysis_Result := Adac.Sema.analyze
(context, root);` before entering its first explicit block body. The declaration
adds three distinct symbols and ten AST nodes, producing 34 symbols and 115 AST
nodes before the case header. After `compile_parsed_unit` is fully owned,
package-body traversal enters `compile_file`, represents its first logging call,
and reaches line 101's bare `begin` at 48 symbols and 231 AST nodes. Staging that
header consumes no symbol or AST budget and exposes line 102's inner `declare`
at the same counts without publishing the outer block parent. The inner explicit
block then reuses the same prefix helper and current full-constant declaration
path for `result : constant Adac.Frontend.Parse_Result :=
Adac.Frontend.parse_file (context, input_path);`. Its `begin` is consumed only
after that declaration is represented; production reaches line 106
`case result.status is` at 50 symbols, 241 AST nodes, and zero semantic entities.
A 240-node budget preserves the declaration children and rejects before the
`result` object parent. The inner block parent remains unpublished until its body
is stable.

The `run` procedure reuses this same block-prefix operation after its two current
`if` guards. Its line 147 `declare` introduces no block node, and the first
`input_path` full constant is already within the current declaration/name subset.
The following `output_path` initializer uses the represented AARM 4.5.7
parenthesized conditional expression owned by `frontend-expressions.md`, so the
complete full constant is now retained by the block prefix. The next `context`
declaration uses the same current initializer path for
`Adac.Compilation.create (options.language_options)` and can therefore publish
its complete variable object parent. The prefix consumes the block `begin` but
does not publish a `Block_Statement_Node`; it stops with the first body call
`compile_file (context, input_path, output_path);` current at line 157.
Production reaches 68 symbols, 382 AST nodes, and zero semantic entities. A
381-node budget rejects the `context` object parent atomically. AST budgets 369
and 370 still protect the conditional parents, and 357 protects the earlier
`input_path` object parent.

The selected AARM 5.6 ownership slice permits this production block body to
contain exactly one current represented procedure-call statement and no exception
handlers. After `compile_file (context, input_path, output_path);` is represented,
the parser validates `end;`, publishes a handler-free `Handled_Sequence_Node`,
and then publishes the enclosing `Block_Statement_Node` owning all three current
declarations. The call adds five AST nodes without a new distinct symbol; the
handled sequence and block parent add two more. Production therefore reaches 68
symbols, 389 AST nodes, and zero semantic entities before stopping at line 159
`end run;`. Budgets 386, 387, and 388 reject respectively before the call,
handled-sequence, and block parents without partial parent publication. This does
not create a block scope, bind the call, or publish the surrounding `run`
procedure body.

## Case-Statement Header Staging

Ada 2022 AARM 5.4 defines a `case_statement` as `case`, a selecting expression,
`is`, one or more alternatives, and `end case;`. The current staging subset is:

```text
staged_case_header ::= case represented_current_expression is
```

`case` is classified case-insensitively as `Tok_Case`. The selecting expression
is delegated to the existing bounded expression parser with syntax publication
enabled. The production `analysis.status` becomes one identifier-name node plus
one selected-name node; no case-statement parent, alternative list, choice, or
control-flow state is published by the header itself. The selected first-
alternative path begins after `is`.

The header alone reaches line 57 `when Adac.Sema.Analysis_Rejected =>` with
35 distinct symbols, 117 AST nodes, and zero semantic entities. The later
`compile_file` inner block reuses the same header staging for
`case result.status is`; because `result` and `status` are already interned, it
adds only the two name AST nodes and reaches line 107's first `when` at 50
symbols, 243 AST nodes, and zero semantic entities. A 242-node budget preserves
the identifier child and rejects before the selected-name parent. A malformed
selecting expression or missing `is` keeps the expression/expected-token
diagnostic.

The selected `compile_file` first-alternative slice reuses the current
identifier-selected choice, procedure-call sequence, and `Case_Alternative_Node`
ownership contracts for
`when Adac.Frontend.Parse_Rejected => finish_with_failure (context);`. It
publishes the complete alternative only after its choice and nonempty statement
list are stable, then stops at the following `when`. The case statement and both
inner/outer block parents remain unpublished; choice resolution, coverage, and
control-flow semantics remain later work. The production state after this append-only slice is 51 symbols and 250 AST
nodes, with a 249-node budget rejecting before the alternative parent.

The selected second-alternative/inner-block ownership slice then preserves
`when Adac.Frontend.Parse_Succeeded =>` and the current three-actual
`compile_parsed_unit (context, result.root, output_path);` call. After validating
exact `end case; end;` closing syntax it publishes the second alternative, case
statement, inner block handled sequence, and inner `Block_Statement_Node`
bottom-up. The enclosing bare block remains unpublished and parsing stops at its
line 114 `exception` boundary. Production reaches 52 symbols and 263 AST nodes at line 114 `exception`.
Budgets 259 through 262 reject, respectively, before the second-alternative,
case, handled-sequence, and inner-block parents without partial publication.

After the parameterless named-choice exception handler is represented, the
enclosing bare block owns the completed inner block as its one body statement and
the represented exception handler as its one handler. Publication appends one
`Handled_Sequence_Node` spanning those children and one outer
`Block_Statement_Node` spanning line 101 `begin` through line 125 `end;`. The
block has an empty declarative part. Production then reaches line 126
`end compile_file;` at 58 symbols, 297 AST nodes, and zero semantic entities.
Budgets 295 and 296 reject before the outer handled-sequence and block parents,
respectively, without partial parent publication.
The current handled-block AST contract deliberately permits this one nesting
shape only: a handled outer block may own one earlier handler-free case block,
while exception-handler bodies exclude block/case nodes. This keeps validation
depth structurally bounded until broader nested block sequences receive an
iterative validator rather than source-controlled recursion.

The selected case-alternative staging subset consumes one `when`, one or more
represented identifier/selected-name, integer-literal, character-literal, or bounded
character-literal explicit-range discrete choices, and `=>`. It reuses the current procedure-
call and simple `return;` statement syntax iteratively until the following
`when`. The production `Adac.Sema.Analysis_Rejected` choice is preserved as
current name syntax; `finish_with_failure (context);` and `return;` remain stable
statement nodes. No case-alternative or case-statement parent is published yet.
The first alternative advances production to the second `when` with 36 distinct
symbols, 124 AST nodes, and zero semantic entities. A 123-node budget preserves
the choice and call syntax and rejects before the `return;` statement parent.

`others` is represented only as a sole choice. The selected second-alternative
staging path consumes one further `when`, one represented choice, and `=>`, then
preserves exactly one current procedure
call before returning at the following statement. In production this represents
`Adac.Sema.Analysis_Succeeded` and `Ada.Text_IO.put_line ("adac: sema ok");`, then
exposes `module := Adac.IR.Builder.build (context, analysis.entity);` as the next
statement frontier. Production reaches that assignment with 37
symbols, 132 AST nodes, and zero semantic entities; a 131-node budget rejects
before partial second-alternative call-parent publication.

## Assignment-Statement Representation

Ada 2022 AARM 5.2 defines `assignment_statement` as `variable_name := expression;`.
The current represented subset is:

```text
represented_assignment_statement ::=
  represented_selected_target := represented_expression ;
```

The target is parsed through the current identifier-selected name path and the
RHS is delegated to the existing bounded expression parser. A complete current `Binary_Multiplying_Node` or `Binary_Adding_Node` root is
accepted here alongside the previously represented name/literal/expression forms.
The multiplying subset preserves `*`, `/`, `mod`, and `rem` term syntax while
`abs`, exponentiation, unary adding, and broader unrepresented operator shapes
retain their expression-owned diagnostics. Publication creates one
`Assignment_Statement_Node` only after the target, RHS, and terminating semicolon
are structurally complete. The node owns those earlier children and the complete
statement span. It does not decide whether the target denotes a variable or whether
the RHS has the target type.

The production target `module` is a direct identifier. Its RHS
`Adac.IR.Builder.build (context, analysis.entity)` is already within the current
parenthesized-name expression subset. The represented statement advances to line
64 `end case;` with 39 distinct symbols, 142 AST nodes, and zero semantic
entities without creating case/block ownership. A 141-node budget preserves all
earlier target/RHS children and rejects before the assignment parent with one
ordinary limit diagnostic and no partial node.

Broader target-name forms remain owned by `frontend-names.md`; unsupported RHS
forms retain expression diagnostics. Case alternatives and case/block parents
remain frontend-only where their semantic support has not been defined.

For the bounded scalar integration path, an ordinary context-free top-level
procedure admits assignment syntax in its statement sequence. Semantic support
is intentionally narrower than frontend representation: the target must be a
direct identifier denoting a supported local variable, and the complete RHS is
either a represented integer literal or a direct identifier denoting another
supported local `Integer`. The target type supplies the RHS expected type as
required by AARM 5.2. A local RHS must resolve through the same compilation-case
policy, have the same semantic `Type_ID` as the target, and already have a
supported defined value from its explicit initializer or an earlier checked
assignment. Reading an uninitialized local remains an unsupported source path.

The assignment parser therefore permits a complete identifier-starting current
name RHS to reach semantic analysis in addition to a numeric literal. Selected
or otherwise compound names are still represented only as syntax and are
rejected by the current semantic boundary. Real literals produce a type-mismatch
diagnostic; undeclared target/source names, unsupported name shapes, undefined
local reads, and other expressions are rejected before any semantic entity is
published. Arithmetic, calls, branches, broader assignment targets, and compound
reads remain outside this executable slice.

Function-body statement staging reuses the same assignment and procedure-call
tails behind one identifier-starting dispatcher. It parses the selected leading
name exactly once; `Tok_Assign` selects assignment construction, while any other
continuation is delegated to the existing call tail. The call tail therefore
remains responsible for actual-part and semicolon diagnostics, preserving
malformed-call diagnostic precedence instead of inventing a function-body-specific
lookahead or token rewind. This dispatcher is syntax-only and performs no callable
or variable classification.

## Case And Block Ownership

After the production assignment and exact `end case;` / unlabeled block `end;`
closing forms are structurally complete, the selected ownership slice publishes
the already represented syntax bottom-up. It does not reparse or copy child
syntax:

```text
represented_case_choice ::=
    represented_selected_choice
  | represented_integer_literal
  | represented_character_literal
  | represented_character_literal .. represented_character_literal
  | others

represented_case_choice_list ::=
  represented_case_choice { | represented_case_choice }

represented_case_alternative ::=
  when represented_case_choice_list => represented_statement+

represented_case_statement ::=
  case represented_expression is represented_case_alternative+ end case ;

represented_block_statement ::=
  declare represented_object_declaration* begin represented_handled_sequence end ;
```

Each `Case_Alternative_Node` owns a nonempty ordered choice list and a nonempty
ordered statement list. Current non-`others` choice syntax permits identifier/
selected-name, integer-literal, character-literal, and character-literal explicit
range choices separated by `|`; `others` remains a sole choice represented as
`Others_Case_Choice_Node`. A `Case_Range_Choice_Node` owns the two earlier
character-literal bounds and exact `..` span without performing staticness, type,
coverage, or matching checks.
current alternative bodies may own the already represented call, return,
assignment, `if`, explicit block, loop, nested `case`, null, and bounded raise
statements. Nested cases and loops reuse the root-neutral compound frame vector,
so deeper compound nesting does not create parser-stack recursion. In the
current represented-statement subset, a return may retain its already represented
expression child through the common return publisher; callers that intentionally
disable return-expression syntax keep their existing rejection boundary. An explicit
block delegates to the same caller-neutral `declare ... begin ... end;` parser
used by ordinary function and loop statement sequences; the case parser retains
only the resulting stable `Block_Statement_Node`. No coverage, matching, or
choice typing is created.

`Case_Statement_Node` owns the earlier selecting expression and the ordered
alternative nodes. Its complete span begins at `case` and ends at the semicolon
of `end case;`. One caller-neutral case-statement parser owns the header,
choice-list, alternative statement-sequence, closing, and bottom-up publication
primitives. Existing nested-procedure case/block paths reuse those primitives
through narrow wrappers, while iterator-loop and ordinary function-body statement
dispatch select the same case parser on `Tok_Case`; no caller maintains a second
case grammar. The parser
remains list-based rather than depending on any production-specific alternative
count.

The block body reuses `Handled_Sequence_Node`, but the current block-specific
validator narrows that sequence to a nonempty list of represented case statements
with no handlers. This prevents the ownership API from creating recursively
nested block bodies before an iterative nesting contract exists. The production
sequence contains exactly the represented case statement. `Block_Statement_Node`
then owns the earlier block-local declarations and that handled sequence. Its
complete span begins at the explicit `declare` and ends at the semicolon of the
unlabeled `end;`. The block declaration list is retained while declarations are
parsed instead of reconstructing it from the AST store later.

Publication order is alternative parents, case parent, block handled-sequence
parent, then block parent. Each append is independently subject to the AST-node
budget and occurs only after all of its children and the complete closing syntax
are valid. Exhaustion may leave earlier append-only children in a rejected
compilation but never a partial parent. No scanner rewind, recursive case walk,
or second statement parser is introduced.

The production path therefore adds exactly five parents after its 142-node
assignment state and reaches line 67 `Ada.Text_IO.put_line ("adac: ir ok");` with
39 distinct symbols, 147 AST nodes, and zero semantic entities. Budgets 142
through 146 reject, respectively, the first alternative, second alternative,
case statement, block handled sequence, and block statement parent without
partial publication.

Once the block parent exists, the enclosing procedure's temporary handled-
statement list retains that stable node before later outer statements are
considered. The following production statement remains the next frontend
prerequisite; this slice does not silently skip the represented block or publish
the enclosing procedure body prematurely.

## Post-Block Procedure-Call Continuation

Ada 2022 AARM 6.4 permits the already represented current procedure-call
statement form used by the production line 67 call. After a completed block has
been appended to the enclosing procedure's temporary handled-statement list, the
current continuation reuses the existing procedure-call parser for exactly one
following identifier-starting call. It does not rebuild, replace, or flatten the
preceding block.

The production `Ada.Text_IO.put_line ("adac: ir ok");` reuses already interned
symbols and adds its fresh name/expression/call syntax after the block. It advances
to line 69 `declare` with 39 distinct symbols, 152 AST nodes, and zero semantic
entities. A 151-node budget preserves the callable-name and actual-expression
children and rejects before partial call-parent publication.

This continuation stops at the second explicit block. The selected next slice
reuses the existing AARM 5.6 block-prefix and declaration contracts rather than
treating `declare` as an unknown continuation.

## Second Block Prefix Staging

The second production block begins at line 69 and has the current prefix:

```text
declare
  {represented_current_object_declaration}
begin
```

The parser consumes `declare`, iteratively delegates identifier-starting
declarations to the existing declaration parser, and consumes `begin`. It does
not publish a `Block_Statement_Node` until the block body and closing syntax are
represented. The production declaration `result : constant
Adac.Backend.Emission_Result := Adac.Backend.emit (module, output_path);` is a
current full-constant object declaration and therefore reuses the existing
`Object_Declaration_Node` path. Successful prefix staging stops at line 73 with
the first body `case result.status is` token current, at 42 distinct symbols,
162 AST nodes, and zero semantic entities. A 161-node budget preserves the
subtype and initializer children and rejects before partial `result` object-parent
publication.

Malformed current declarations retain their declaration/expression diagnostics;
a noncurrent declarative item retains the block-declarative support boundary.
AST-node exhaustion before the `result` object parent may leave its already
published subtype and initializer children in the rejected compilation, but it
shall not publish a partial object parent. No block scope, handled sequence, or
block parent is created by this prefix slice.

Broader second-block body traversal, enclosing procedure completion, and
package-body ownership remain later work.

## Second Case Header Staging

The second block begins with the same AARM 5.4 case-statement header shape as the
first block. The parser therefore reuses one common header operation for
`case represented_current_expression is`. The production selector
`result.status` is represented through the existing identifier-selected name
path; no case alternative or case parent is published by this header slice.
Successful staging returns at line 74 with the first `when` token current. The
production selector adds two AST nodes and no new symbols, reaching 42 distinct
symbols, 164 AST nodes, and zero semantic entities. A 163-node budget preserves
the direct-name child and rejects before partial selected-name parent publication.
Malformed selectors and a missing `is` retain the existing expression or
expected-token diagnostics.

The common helper preserves the first block's publication contract: its caller
retains the represented selecting-expression node and remains responsible for
alternatives, closing syntax, and any eventual `Case_Statement_Node`. The second
block likewise keeps only append-only selector syntax until its own alternatives
are stable.

## Second Case First Alternative

The first second-block alternative has one selected-name choice and the current
call/simple-statement sequence:

```text
when Adac.Backend.Emission_Operational_Failure =>
  Adac.Compilation.Diagnostics.error
    (context, Adac.Backend.failure_message (result));
  finish_with_failure (context);
  return;
```

The choice reuses the current selected-name parser. The first call reuses the
existing positional-actual expression path, including the nested parenthesized
name `Adac.Backend.failure_message (result)`. The following call and simple
return use the current statement representations. When the following `when` is
reached, the choice and nonempty ordered statement list have a complete source
boundary and publish one `Case_Alternative_Node`. Production reaches line 80
with 45 distinct symbols, 183 AST nodes, and zero semantic entities. A 182-node
budget preserves the complete choice and statement children and rejects before
partial alternative-parent publication. No case or block parent is published yet.

The shared alternative-header helper accepts only one current selected-name
choice; vertical-bar choices and `others` remain outside this parser subset. The
shared call/simple-statement sequence is iterative and stops at its caller-owned
`when` terminator. Malformed calls and returns retain their existing diagnostics,
and AST exhaustion before any statement or alternative parent remains a
controlled input failure without partial parent publication.

## Second Case And Block Ownership Completion

The remaining second-block alternative is the current one-choice/one-statement
shape `when Adac.Backend.Emission_Succeeded => null;`. Its selected-name choice,
`Null_Statement_Node`, and `Case_Alternative_Node` are published before the
closing syntax is consumed. After exact validation of `end case;` and the
unlabeled block `end;`, the parser publishes the enclosing `Case_Statement_Node`,
a handler-free `Handled_Sequence_Node`, and the `Block_Statement_Node` bottom-up.
The complete block is then appended to the enclosing procedure's ordered handled-
statement list before any later outer statement is considered. Production reaches
line 85 `Ada.Text_IO.put_line ("adac: backend ok");` with 46 distinct symbols,
191 AST nodes, and zero semantic entities. Budgets 187 through 190 reject,
respectively, the second alternative, case, block handled-sequence, and block
parents without partial publication.

This completion reuses the same AARM 5.4/AARM 5.6 ownership contracts as the
first explicit block. No second implementation of case or block AST structure is
introduced. Parent publication occurs only after every owned child and closing
delimiter is structurally complete. AST-budget exhaustion may leave earlier
append-only children in a rejected compilation, but each unavailable parent is
rejected before partial publication. No case coverage, selecting-expression
typing, block scope, exception handler, or execution semantics are created.

## Calls After The Second Block

After the complete second block, the production procedure has two consecutive
AARM 6.4 procedure-call statements before its closing `end`:

```text
Ada.Text_IO.put_line ("adac: backend ok");
Ada.Text_IO.put_line
  ("adac: diagnostics " &
   Adac.Support.image
     (Adac.Compilation.Diagnostics.error_count (context)) &
   " error(s)");
```

The parser walks consecutive identifier-starting current calls iteratively and
appends each represented `Procedure_Call_Statement_Node` to the enclosing
procedure's ordered handled-statement list. The first call uses the existing
string-literal actual. The second reuses the represented ampersand expression
chain and nested parenthesized-name syntax already required by earlier bootstrap
procedures. The walk stops before the caller-owned `end` token; it does not
publish the enclosing handled sequence or procedure body in this slice.
Production reaches line 91 `end compile_parsed_unit;` with 46 distinct symbols,
214 AST nodes, and zero semantic entities. A 195-node budget rejects before the
first trailing call parent, while a 213-node budget rejects before the second
call parent without partial publication.

No fixed call count is encoded. Malformed call syntax and unsupported actual
expressions retain the existing call/expression diagnostics, while AST exhaustion
before either call parent leaves only already-published child syntax.

Block scopes, case coverage and choice legality, selecting-expression typing,
control flow, execution, labels, block exception handlers, and broader compound
child forms remain later work. Represented case alternatives may own nested case
and explicit-block children through the shared iterative compound machinery.

## Support Boundary

A complete current-shaped `if` encountered by ordinary statement parsing still
receives exactly one diagnostic at its opening `if` token and publishes no `if`
syntax:

```text
if statements are not supported
```

If a selected sequence begins with a statement outside the current call,
bare-return, bounded-raise, or nested-`if` subset, or if an unsupported statement
appears before `else` or `end`,
the selected-sequence boundary remains authoritative:

```text
if statement sequences are not supported
```

The production nested procedure uses represented completion. After each current
arm sequence and closing `end if;` are consumed, the caller retains the stable
`If_Statement_Node` and resumes at the following token. A `Tok_Exception`
continuation is delegated to
`frontend-exception-handlers.md`. Any other continuation retains the nested-body
diagnostic:

```text
nested procedure body continuation is not supported
```

Statement staging does not consume or classify exception-handler syntax. This
keeps the statement and handled-sequence ownership boundaries separate.

Malformed condition and call syntax fails before these unsupported boundaries.
The existing expression, name, and call diagnostics remain authoritative. Once
`Tok_End` begins the closing form, a missing closing `if` or final semicolon
uses the ordinary expected-token diagnostic. A missing semicolon after a
no-actual-parameter-part current call likewise uses the expected-token
diagnostic before an enclosing unsupported boundary can hide the syntax error.
Other unrepresented sequence structure retains the selected-sequence unsupported
boundary.

For a current procedure body that already owns one or more represented
declarations, a sequence that begins with an identifier statement or represented
`case` now walks following identifier assignment/call, caller-neutral represented
`case`, and represented `if` statements in source order. Every statement is
published independently and retained as one stable child before the next token is
selected. The walk stops at the first token outside that bounded subset, preserving
`nested procedure body continuation is not supported` until another represented
statement form is selected. This follows AARM 5.1 sequence ownership without
assuming a fixed statement count.

After the represented nested subprogram returns to its enclosing procedure, the
production-specific boundary consumes the outer `begin` and publishes one
identifier-starting current call. If the following token is `Tok_Exception`,
control is delegated to `frontend-exception-handlers.md` so the production
handler header can be staged. The published call remains append-only pending
syntax because the outer handled sequence is not represented yet. Any other
continuation retains:

```text
procedure body continuation after staged declarative part is not supported
```

If that outer body does not begin with an identifier token eligible for the
current-call staging path, the existing `nested subprograms are not supported in
procedure declarative parts` boundary remains authoritative at the outer
`begin`. This preserves the rule that an unrepresented declarative item cannot
disappear from a successful AST.

This slice does not stage or claim support for:

- selected-arm statement kinds other than current procedure calls, bounded
  raise-with-string-message statements, nested `if`, handler-free explicit
  blocks, and current simple returns;
- labels, assignments, other compound statements, or extended returns in the
  selected-arm subset;
- named actual parameters;
- general identifier-starting statements outside the caller-selected current
  call paths;
- exception-handler syntax owned by `frontend-exception-handlers.md`;
- conditional expressions beginning with `if`;
- expression, call, Boolean, overload-resolution, or control-flow semantics; or
- statement recovery.

`elsif` is now a dedicated case-insensitive reserved token. Its branch conditions
and statement sequences use the same represented expression and current branch-
statement boundaries as the opening `if` arm. `elsif` does not become a nested
`else if` tree, so source ordering and resource publication remain explicit.

## Symbol, AST, And Stage Ownership

`if`, `then`, `else`, `end`, delimiters, and punctuation consume no symbol
budget. Before the first branch call, the production condition has published
eleven distinct symbols. That call adds `Text_IO`, `put_line`, and `prefix`,
bringing the fixture to fourteen symbols.

The alternative call reuses `Ada`, `Text_IO`, `put_line`, `prefix`, `name`, and
`message`. Its string literal publishes no identifier symbol, so completing the
production `if` leaves the distinct-symbol count at fourteen.

Before the condition, represented nested parameters and declarations contribute
twenty AST nodes. The production `message'length` operand publishes its
identifier prefix and one `Attribute_Name_Node`, and the right operand `0`
publishes one `Numeric_Literal_Node`. The enclosing equality publishes one
`Relation_Node`, bringing the nested path to twenty-four AST nodes.

The first branch call publishes three callable-name nodes for
`Ada.Text_IO.put_line`, two actual identifier-name nodes, one
`Binary_Adding_Node`, and one `Procedure_Call_Statement_Node`. It therefore adds
seven nodes after the condition. The alternative publishes another three
callable-name nodes, three actual identifier-name nodes, one
`String_Literal_Node`, three left-associated `Binary_Adding_Node` values, and one
call node. It adds eleven more nodes. The two calls therefore leave forty-two
AST nodes before their enclosing statement is published. The
`If_Statement_Node` adds one node, so completing the nested `if` leaves
forty-three AST nodes.

After the complete nested body and represented context clauses, the production
path has sixty-three AST nodes. Publishing `Adac.Driver.run;` adds one
identifier node, two selected-name nodes, and one call node, bringing the path
to sixty-seven AST nodes. Its `Adac`, `Driver`, and `run` spellings bring the
symbol count to seventeen at that source point. Publishing the four outer
handler calls adds twenty-two callable-name, actual-expression, and call-parent
nodes. Together with the handler choices and parents owned by
`frontend-exception-handlers.md`, the complete production path reaches
twenty-eight distinct symbols and one hundred ten AST nodes.

The condition owns its represented equality relation and primary subtrees, and
the nested branch calls own their callable names and represented concatenation
actuals. The enclosing `If_Statement_Node` owns those existing children. The
outer call owns its selected callable name but remains unattached to a
represented outer handled sequence. The selected outer-handler path publishes
its current procedure calls into pending handler nodes; staging-only callers
retain no-publication behavior. No semantic entity, scope, callable identity,
control-flow state, IR object, or
output is published by these paths.

## Failure And Resource Contract

The selected callable-prefix loops are iterative and perform work proportional
to their components. They reuse the existing symbol budget and allocate no
auxiliary name list or nesting stack. Parenthesized call actuals delegate to the
existing expression parser and inherit its source-character, symbol, and
expression-nesting failure behavior from `frontend-expressions.md` and
`resource-limits.md`. The no-actual-parameter-part alternative performs no
expression parse and introduces no new nesting or resource counter.

The nested production `if` requests bounded publication for its condition and
branch calls. The condition consumes four AST-node budget slots. The two calls
together consume six callable-name nodes, ten actual-expression nodes, and two
call-statement nodes. The enclosing `if` consumes one additional slot after all
children and the closing semicolon have been validated. Call and branch-list
construction each copy their direct child list once. During represented if
parsing, nested if/block/loop/case syntax is held in one explicit parser vector.
Every frame corresponds to a distinct source compound prefix, so live frame count
is bounded by the per-file source-character budget and completed parents by the
AST-node budget. Standalone loop/case parsers may enter this frame machine once
when they first encounter a represented `if`; further alternating compound
nesting stays in the vector, so wrapper call depth is constant rather than
source-controlled. No separate statement-nesting counter is introduced. Completed
inner compound nodes are stable AST children, and outer construction does not
recursively revalidate them. Full raw/context validation uses explicit mixed
pending-node worklists.

The outer parameterless call consumes four AST-node slots in source order: the
identifier name, two selected-name parents, and the call parent. Capacity is
checked before every append, so exhaustion leaves only earlier append-only nodes
and never a partial call parent. It performs no expression recursion and
allocates only an empty temporary actual list. Handler calls use the same
bounded name, expression, and call-parent publication when their owning handler
is being
represented. A caller that disables statement publication returns after syntax
has been consumed and before statement-node construction. The statement wrapper adds constant work around delegated parsers and introduces
no scanner rewind, auxiliary recursion, or resource counter. Extended-return
disambiguation uses one bounded parser token of lookahead after `return` only; the
lookahead is consumed monotonically and is never used for backtracking.

Unsupported statement structure is an expected input failure. Malformed source
retains ordinary syntax diagnostics. Calling an internal staging operation at an
unrelated token or allowing a structurally staged but unrepresented `if` to pass
an ordinary statement boundary is an internal compiler contract violation.

## Tests

Tests for this boundary shall cover:

- case-insensitive `if` tokenization with exact spelling preservation;
- rejection of `if` as a procedure defining identifier;
- an ordinary procedure retaining the unsupported sequence diagnostic for a
  non-call first statement;
- the production condition `message'length = 0` through `then`;
- a represented-if caller accepting the current represented `not` condition;
- represented `if` arms owning multiple current calls plus bare `return;` in
  source order, including the first production guard clause in `run`;
- represented `if`/`elsif` arms selecting assignment versus procedure-call
  syntax through the shared identifier-statement dispatcher while ordinary
  unsupported-`if` staging retains its established call-only rejection behavior;
- zero, one, and multiple case-insensitive `elsif` parts preserving ordered
  conditions and branch statements as `Elsif_Part_Node` children;
- mutually nested represented `if`/handler-free-block statements built bottom-up
  through explicit parser and validator worklists, including deep nesting without
  call-stack growth;
- represented iterator loops inside if/elsif/else arms, including an alternating
  `if -> loop -> case -> if -> loop` parser fixture proving the compound frame
  machine does not recurse with source nesting;
- an empty condition retaining the expression-primary syntax diagnostic;
- a missing `then` retaining the ordinary expected-token diagnostic;
- the production selected callable prefix and operator-expression actuals in
  both branches;
- represented completion with and without the optional `else`, including the
  production `else` and closing `end if;`;
- an ordinary complete current-shaped `if` still rejecting at its opening
  keyword without publishing an AST node;
- an empty alternative-call actual retaining the expression-primary syntax
  diagnostic;
- malformed closing syntax retaining the expected-token diagnostic;
- the production path returning at `Tok_Exception` for delegation to the
  exception-handler boundary;
- production symbol publication remaining fourteen after the alternative call;
- forty-three-node AST publication including represented parameters, the
  condition relation, both branch calls, and the enclosing `If_Statement_Node`;
- exact condition, then/else statement order, and complete `end if;` span;
- an `if` without `else` retaining an empty else list;
- controlled AST-node-budget exhaustion before the `if` parent is published;
- exception-handler reuse of `null;` parsing without statement-node publication;
- the outer parameterless selected call `Adac.Driver.run;` after the staged
  nested declarative item;
- a missing semicolon after that call retaining the expected-token diagnostic;
- the outer call bringing symbol publication to seventeen at that source point
  while production AST publication advances from sixty-three to sixty-seven
  nodes;
- delegation of the following outer `Tok_Exception` to the exception-handler
  boundary without allowing a successful root to omit the nested subprogram;
- a nonempty positional actual list with more than two actuals using the same
  iterative staging path rather than a two-actual special case;
- mixed positional/named call associations preserving identifier selectors and
  actual order, with a positional association after a named one rejected before
  call-parent publication;
- a trailing comma retaining the existing expression-primary diagnostic;
- the production two-actual `report_exception` call and following one-actual
  `Ada.Command_Line.set_exit_status` call;
- production handler-call staging bringing the symbol count to twenty-eight
  while AST publication remains sixty-seven nodes in this slice;
- the generic nested-subprogram fixture retaining its outer-`begin` unsupported
  boundary when the body does not start with the current call; and
- exact callable-name, positional-actual order, statement span, and context
  ownership for represented nested calls;
- parameterless procedure-call node construction with an empty actual list;
- controlled production AST-node-budget exhaustion before each outer callable-
  name node and the call parent are published;
- controlled AST-node-budget exhaustion before a call parent is published;
- case-insensitive `declare` tokenization on the current block header;
- a mixed-case bare `begin` block header staging an implicit empty declarative
  part without symbol, AST, or semantic publication;
- current block declarative items traversed iteratively without block
  publication, including a two-declaration fixture;
- an empty block declarative part reaching its first unsupported body statement;
- case-insensitive `case` tokenization with exact spelling preservation;
- publication of the production `analysis.status` selecting-name syntax before
  the first alternative boundary;
- a missing case-header `is` retaining the expected-token diagnostic;
- controlled AST-node-budget exhaustion before the production selecting-name
  parent without partial parent publication;
- the first production case alternative preserving its selected-name choice,
  procedure call, and simple return before the second `when` boundary;
- controlled AST-node-budget exhaustion before the first-alternative return
  statement parent;
- the production second alternative preserving its selected-name choice and first
  procedure call before the assignment frontier;
- controlled AST-node-budget exhaustion before that second-alternative call
  parent;
- direct construction and validation of an assignment statement with target/RHS
  ownership and complete span;
- production assignment publication through `end case;` staging;
- controlled AST-node-budget exhaustion before the assignment parent;
- exact `end case;` and unlabeled block `end;` validation before parent
  publication;
- malformed case/block closing forms retaining expected-token diagnostics and
  preventing case/block parent publication;
- direct construction and validation of case alternatives, including ordered
  multiple name choices, a character-literal explicit range with exact `..` span,
  a sole `others` choice, bounded raise bodies, case statements, and
  block statements, including a handler-free procedure-call block, a mixed
  call/`if`/assignment block, and malformed child-list rejection without mutation;
- iterator explicit-block publication after its declaration and mixed body are
  complete and retained as one loop-body child;
- direct loop construction/query/validation for defining symbol/span, `reverse`
  source form, iterable name, ordered call/`if`/block body, and complete span;
- parser publication of the complete current `of [reverse] selected_name` loop
  without creating semantic state;
- source-ordered iterator bodies containing call, `if`, assignment, and later
  call syntax through the shared identifier-statement dispatcher;
- caller-neutral case parsing inside an iterator body, preserving two ordered
  name choices, a sole `others` alternative, call/raise bodies, and one stable
  `Case_Statement_Node` child without duplicating nested-procedure case grammar;
- controlled iterator-block AST-node-budget exhaustion immediately before the
  handled-sequence and block-parent appends without partial parent publication;
- controlled loop-parent AST-node-budget exhaustion after every header/body
  child is stable without partial loop publication;
- the production `run` block owning its single `compile_file` call before the
  surrounding procedure-body closing boundary;
- controlled AST-node-budget exhaustion at the production `run` block call,
  handled-sequence, and block-parent boundaries;
- controlled AST-node-budget exhaustion before each of the five production
  case/block ownership parents; and
- no assignment, `if`, call, block, or case semantic entity after rejection.

The complete bootstrap-profile frontend gate is the integration check for these
composed statement forms. `frontend-expressions.md`,
`frontend-exception-handlers.md`, and `frontend-subprograms.md` own their
respective child syntax contracts; this document does not retain a mutable
production source-line frontier. Repository-wide next work belongs in
`roadmaps/README.md`.
