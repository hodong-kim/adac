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
Compilation_Unit_Node
  first: first context item when present, otherwise library-item first position
  last:  library-item terminating semicolon

Package_Declaration_Node
  first: package keyword
  last:  package-declaration terminating semicolon
  children: every defining-name component span, represented visible declaration,
            and optional closing-name component span is contained in source order

Package_Body_Node
  first: package keyword
  last:  package-body terminating semicolon
  children: every defining-name component span, represented procedure body, and
            optional closing-name component span is contained in source order

Procedure_Body_Node
  first: procedure keyword
  last:  procedure-body terminating semicolon
  children: parameters, declarative items, and the handled sequence are
            contained
            and ordered by their source spans; an optional end designator is
            represented by symbol presence rather than a separate child span

Function_Body_Node
  first: function keyword
  last:  function-body terminating semicolon
  children: parameters, result subtype, declarative items including any stable
            nested procedure bodies, and the handled sequence are contained and
            ordered by their source spans; an optional end designator is
            represented by symbol presence rather than a separate child span

With_Clause_Node
  first: with keyword
  last:  with-clause terminating semicolon

Null_Statement_Node or Return_Statement_Node
  first: null or return keyword
  last:  statement terminating semicolon

Assignment_Statement_Node
  first: first position of the target name
  last:  statement terminating semicolon
  children: target and RHS expression spans are contained in source order

Case_Alternative_Node
  first: first position of the `when` keyword
  last:  terminating semicolon of the final represented statement
  children: choices precede statements and all are contained in source order

Case_Range_Choice_Node
  first: first position of the lower character-literal bound
  last:  last position of the upper character-literal bound
  children: lower bound, exact `..` delimiter span, and upper bound are contained
            in source order

Raise_Expression_Node
  first: first position of the `raise` keyword
  last:  last position of the exception name or present message expression
  children: exception name precedes an optional message and all are contained

Case_Statement_Node
  first: first position of the `case` keyword
  last:  statement terminating semicolon after `end case`
  children: selecting expression precedes every alternative

Block_Statement_Node
  first: first position of explicit `declare`, otherwise the opening `begin`
  last:  statement terminating semicolon after `end`
  children: declarations precede the handled sequence and all are contained
            in source order

Loop_Statement_Node
  first: first position of the opening `for`
  last:  statement terminating semicolon after `end loop`
  children: loop-parameter defining span, iterable name, and body statements are
            contained in source order

Procedure_Call_Statement_Node
  first: first position of the callable name
  last:  statement terminating semicolon

If_Statement_Node
  first: first position of the opening if keyword
  last:  statement terminating semicolon after end if

Others_Exception_Choice_Node
  first/last: exact others token

Exception_Handler_Node
  first: first position of the when keyword
  last:  terminating semicolon of the final handler-body statement
  children: an optional choice-parameter defining span, every represented
            exception-name or others choice, and every body statement are
            contained in source order

Handled_Sequence_Node
  first: first position of the first handled statement
  last:  last position of the final handler or handled statement

Numeric_Literal_Node or String_Literal_Node
  first/last: exact literal token

If_Expression_Node
  first: first position of the `if` keyword
  last:  last position of the else-dependent expression

Parenthesized_Expression_Node
  first: opening left parenthesis
  last:  closing right parenthesis

Unary_Operator_Node
  first: first position of the unary operator
  last:  last position of the operand

Binary_Adding_Node
  first: first position of the left operand
  last:  last position of the right operand

Relation_Node
  first: first position of the left operand
  last:  last position of the right operand

Identifier_Name_Node
  first/last: exact identifier token

Selected_Name_Node
  first: first position of its prefix
  last:  last position of its selector

Parenthesized_Name_Node
  first: first position of its prefix
  last:  closing right parenthesis

Attribute_Name_Node
  first: first position of its prefix
  last:  last position of its identifier attribute designator

Parameter_Specification_Node
  first: defining identifier
  last:  last position of a present default expression, otherwise subtype mark
  note:  explicit mode and `:=` tokens lie inside this span

Object_Declaration_Node
  first: defining identifier
  last:  declaration terminating semicolon
  child: initializer span is present only when the declaration has one

Number_Declaration_Node
  first: defining identifier
  last:  declaration terminating semicolon

Procedure_Declaration_Node
  first: procedure keyword
  last:  declaration terminating semicolon
  child: defining-identifier span is contained between those endpoints

Private_Type_Declaration_Node
  first: type keyword
  last:  private-type declaration terminating semicolon
  child: defining-identifier span is contained between those endpoints
  note:  an optional `limited` token lies inside the span but has no child span

Enumeration_Type_Declaration_Node
  first: type keyword
  last:  enumeration-type declaration terminating semicolon
  children: type defining-identifier span followed by every literal defining-
            identifier span, all contained in source order
```

An exception-handler span shall contain its optional choice-parameter defining
span, every choice, and every body-statement span in source order, including the
`when`/`:`/`|`/`=>` source intervals around those children. A handled-sequence
span shall contain every handled statement and handler span in source order. Its
handlers, when present, follow all ordinary statements.

An `if` statement span shall contain its condition and every then/else statement
span in source order. Its first endpoint precedes the condition and its last
endpoint follows the final branch statement through the terminating semicolon.

A procedure-call statement span shall contain its callable-name span and every
positional-actual span in source order, and shall extend past the final child to
the terminating semicolon.

An if-expression span shall contain its condition, then-dependent expression,
and else-dependent expression in source order, starting at `if` and ending at
the else-dependent expression. Its parenthesized-expression parent shall contain
that complete child and both required parentheses. A unary-operator span shall
contain its operator-token and operand spans in source order, starting at the
operator and ending at the operand. A binary-adding
or relation span shall contain both operand spans and the operator-token span in
source order. Its first endpoint equals the left
operand's first endpoint and its last endpoint equals the right operand's last
endpoint.

A compilation-unit span shall contain every context-item span and its unit-item
span. A subunit span shall begin at `separate`, contain every parent-unit-name
component in source order, and end with its proper-body span. A package-declaration
span shall contain every defining-name component,
represented visible declaration, and present closing-name component span in
source order. A procedure-body
span shall contain every represented parameter,
declarative-item, and handled-sequence span in source order. A function-body span
shall additionally contain its result-subtype span before every represented
declarative item, including any nested procedure body. A with-clause span
shall contain every represented library-unit name in source order. A selected,
parenthesized, or attribute name contains all represented child spans. A current
parameter specification contains its defining-identifier span, subtype-mark
name, and optional represented default expression in source order.
A current object declaration contains its defining-identifier span, subtype-mark
name, and initializer name in source order. A current number declaration
contains its defining-identifier span and initializer expression in source order.
A current procedure declaration contains its defining-identifier span and every
represented parameter span in source order between the opening `procedure`
keyword and terminating semicolon. A parameterless declaration has no parameter
child spans. A current function declaration additionally contains its result
subtype-mark span after every parameter and before the terminating semicolon.
Punctuation and reserved words do not receive separate spans in the current AST
representation.

## Ownership And Validation

A span borrows its source-file identity from one `Adac.Source.Registry`. It
does not own source text, a path string, or the registry.

`Adac.AST.validate` checks structural span validity and node containment.
`Adac.Compilation.Syntax.validate` additionally validates every span through
the source registry owned by its `Adac.Compilation.Context`. Semantic analysis
and IR lowering both use this context-aware boundary. Passing a structurally
valid span from another context is an internal compiler contract violation.

Validation is linear in the number of reachable AST nodes. Nested procedure-body
validation uses an explicit work list of stable `Node_ID` values rather than
recursive procedure-body calls, so source nesting does not create unbounded host
call-stack growth. The represented AST and its temporary traversal state remain
bounded by the compilation resource contracts in `resource-limits.md`.

## Failure Contract

Malformed, invalid, foreign, or out-of-range spans are internal compiler
contract violations and raise `Program_Error`. They are not ordinary source
errors and shall not be converted into semantic rejection.

Source text that cannot be parsed never publishes a root `Node_ID`. Nodes and
spans appended before rejection remain private to the context-owned AST store
and are reclaimed with that compilation context.

## Extension Rules

New syntax and semantic objects shall receive a source span when they are
introduced. A composite node span shall contain the spans of child nodes that
represent source text within that construct.

Generated objects with no direct source text require an explicit provenance
contract before they may use an invalid or synthetic span. No synthetic-span
policy is defined by the initial implementation.
