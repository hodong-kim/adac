# AST Model

This document defines Adac's abstract-syntax storage, identity, ownership, and
validation contracts.

## Ownership And Lifetime

Each `Adac.Compilation.Context` owns one append-only `Adac.AST.Store`. The store
owns every node created during that compilation attempt and releases all node
storage with the context. Compiler stages borrow the context and node
identifiers; they do not own or copy nodes.

`Adac.AST.Node_ID` is a private, stable reference to one node in one store. It
contains a deterministic one-based index and an opaque runtime owner marker.
`INVALID_NODE_ID` is the only public invalid value. Resolving an invalid,
foreign, or out-of-range ID is an internal compiler contract violation.

A `Node_ID` remains meaningful until its context is destroyed. It must not be
retained beyond that lifetime, serialized with its runtime owner marker, or
resolved through another context.

## Storage

The store is append-only. Appending a node does not invalidate earlier IDs, and
nodes are immutable after publication. Allocation order is deterministic parse
order within one context and is independent of addresses, other contexts, and
hash-table iteration.

`Node_List` is a temporary value used to collect child IDs before publishing a
parent. It does not own nodes. A production constructor validates each child ID
against the destination store before copying the list into the parent node.

`Program_Unit_Name` is a temporary ordered list of identifier components used
while constructing package syntax. Each component contains one context-owned
symbol and its exact identifier span. A package constructor validates every
component and copies the defining and optional closing lists directly into the
immutable package node. The temporary list owns no source text, symbol, or AST
node and is discarded after parent publication.

Parse failure does not roll back already appended nodes. Such unreachable nodes
remain private to the failed compilation and are reclaimed with the context.
This preserves stable IDs and simple failure cleanup. The context-owned AST
node budget defined in `resource-limits.md` bounds this storage.

## Construction

Production nodes are created through `Adac.Compilation.Syntax`. These
operations validate context initialization, symbol ownership, source ownership,
node ownership, node kind, and structural containment before publishing a node.
The context adapter delegates final store mutation to `Adac.AST.Construction`;
raw node-append operations are not part of the root `Adac.AST` visible surface.
The visible construction child forwards to one parent-private construction
implementation whose body is an implementation-only subunit of `Adac.AST`.
`Adac.AST` therefore remains the sole owner of the store representation, mutation
helpers, and structural invariants; the construction child introduces no second
AST model, arena, or validation authority.

The current node kinds are:

```text
Compilation_Unit_Node
Subunit_Node
Procedure_Body_Node
Function_Body_Node
With_Clause_Node
Use_Type_Clause_Node
Null_Statement_Node
Exit_Statement_Node
Return_Statement_Node
Extended_Return_Statement_Node
Raise_Statement_Node
Assignment_Statement_Node
Case_Alternative_Node
Case_Range_Choice_Node
Others_Case_Choice_Node
Case_Statement_Node
Block_Statement_Node
Loop_Statement_Node
Procedure_Call_Statement_Node
If_Statement_Node
Elsif_Part_Node
Others_Exception_Choice_Node
Exception_Handler_Node
Handled_Sequence_Node
Numeric_Literal_Node
Character_Literal_Node
String_Literal_Node
Null_Literal_Node
Record_Aggregate_Node
Array_Aggregate_Node
Bracket_Aggregate_Node
Qualified_Expression_Node
Allocator_Node
If_Expression_Node
Case_Expression_Alternative_Node
Case_Expression_Node
Raise_Expression_Node
Parenthesized_Expression_Node
Unary_Operator_Node
Binary_Exponentiating_Node
Binary_Multiplying_Node
Binary_Adding_Node
Relation_Node
Membership_Range_Choice_Node
Membership_Expression_Node
Short_Circuit_Expression_Node
Identifier_Name_Node
Selected_Name_Node
Explicit_Dereference_Name_Node
Selected_Component_Node
Parenthesized_Name_Node
Slice_Name_Node
Attribute_Name_Node
Aspect_Specification_Node
Parameter_Specification_Node
Object_Declaration_Node
Number_Declaration_Node
Exception_Declaration_Node
Procedure_Declaration_Node
Function_Declaration_Node
Private_Type_Declaration_Node
Derived_Type_Declaration_Node
Range_Constraint_Node
Subtype_Declaration_Node
Enumeration_Type_Declaration_Node
Discriminant_Specification_Node
Record_Component_Declaration_Node
Record_Variant_Node
Record_Variant_Part_Node
Record_Type_Declaration_Node
Access_Object_Type_Declaration_Node
Package_Renaming_Declaration_Node
Package_Instantiation_Node
Package_Declaration_Node
Package_Body_Stub_Node
Package_Body_Node
```

`Numeric_Literal_Node` represents the four numeric literal forms already
recognized by the lexer: decimal integer, decimal real, based integer, and based
real. It owns the lexical form, exact source spelling, and exact token span. The
node does not convert the spelling to a numeric value or assign a type; numeric
value interpretation, universal numeric types, and legality rules remain semantic
work. The current production path first publishes the decimal integer literal
`0` in the nested `report_exception` condition.

`Character_Literal_Node` represents one valid current ASCII character-literal
token. It owns the exact three-character source spelling and exact token span,
including the `'''` spelling for apostrophe. It does not decode a character
value, select a character type, or resolve the enumeration literal denoted by the
source. Expected-type and character-literal name resolution remain semantic work.

`Others_Exception_Choice_Node` represents the exact reserved-word choice
`others` in the current exception-handler subset. It owns only its exact token
span and creates no exception entity or matching semantics.

`Exception_Handler_Node` represents the current handler syntax. It owns an
optional choice-parameter defining symbol and exact defining-identifier span, a
nonempty ordered list of earlier exception choices, and a nonempty ordered list
of earlier represented body statements. A current exception choice is either an
`Others_Exception_Choice_Node` or an earlier represented identifier/selected
name that preserves an `exception_name` without resolving its exception
identity. Current structural handler statements are null, return, assignment,
procedure-call, raise, or one bounded `Block_Statement_Node`. A handler-owned
block is validated through the explicit compound worklist; any nested block with
handlers is rejected, and the owned block's own handlers are restricted to
noncompound current statements. This keeps block/handler ownership from forming
an unbounded source-controlled recursive validation chain. Direct `if` statements
are no longer part of the raw handler contract because the represented handler
parser does not publish them. The parser's ordinary represented handler subset
remains narrower, with one production-selected block-plus-bare-reraise form.
The nested production has no choice parameter and one `others` choice; the outer
production handlers use a choice parameter and selected-name or `others`
choices.
Exception matching, handler scope, occurrence identity, coverage legality, and
transfer of control remain later semantic work.

`Handled_Sequence_Node` represents `handled_sequence_of_statements`. It owns a
nonempty ordered list of earlier represented body statements and an ordered list
of earlier exception handlers. Current handled statements include the represented
simple/compound subset plus `Raise_Statement_Node`; construction and full
validation delegate raise children to the existing raise validator rather than
treating them specially in procedure bodies. The node's source span starts at the
first body statement and ends at the final body statement or final handler
statement; its owning procedure body retains the surrounding `begin` and `end`
boundaries.

`Elsif_Part_Node` represents one repeated AARM 5.3 `elsif condition then
sequence_of_statements` part. It owns one earlier represented condition expression,
a nonempty ordered list of earlier current branch statements, and the source span
from the `elsif` keyword through the final statement of that part. It is syntax
owned only by an enclosing `If_Statement_Node`; it is not itself a statement.

`If_Statement_Node` represents the current Ada `if_statement` subset with zero or
more ordered `Elsif_Part_Node` children. It owns an earlier represented opening
condition expression, a nonempty ordered then-statement list, the ordered earlier
`elsif` parts, an optional ordered else-statement list, and the complete span from
the opening `if` through the terminating semicolon. The current branch-child
subset includes null, return, assignment, procedure-call, bounded raise, another
`If_Statement_Node`, a handler-free `Block_Statement_Node`, and a current
`Loop_Statement_Node`; other compound children remain outside this slice.
Compound children are built bottom-up, so constructors accept already stable
earlier roots without recursively revalidating their subtrees. Raw-store and
context-aware full validation traverse the current if/elsif/handler-free-block/
loop/case/case-alternative graph through explicit pending-node worklists. This
keeps validation linear in represented syntax and independent of source-controlled
call-stack depth even for alternating `if -> loop -> case -> if` ownership. Boolean-condition typing,
branch reachability, control flow, and execution semantics remain later work. The
absence of else statements represents an absent `else` part because a valid Ada
`sequence_of_statements` is nonempty.

`Exit_Statement_Node` represents Ada 2022 AARM 5.7 exit-statement syntax. It
owns the complete span through the terminating semicolon, an optional loop-name
symbol/span pair, and an optional exact four-column `when` token span plus one
earlier represented condition expression. Presence of each optional pair must
agree and all present children are ordered and contained. The first parser slice
publishes unnamed `exit;` and `exit when represented_expression;`; named exit is
retained in the construction/validation contract but currently receives a
controlled frontend rejection. The node performs no loop-target lookup, Boolean
typing, transfer-of-control legality, or execution semantics.

`Return_Statement_Node` represents the current AARM 6.5 return-statement syntax
shape. It owns the complete statement span and an optional earlier represented
expression. `INVALID_NODE_ID` preserves the bare `return;` source form used by
current procedures; a present child preserves `return expression;` for current
function bodies. The node does not decide whether the enclosing callable permits
a return expression, resolve the expected result type, convert the expression, or
model transfer of control. Those are semantic responsibilities.

`Extended_Return_Statement_Node` represents the selected AARM 6.5 extended-return
`do` form. It owns one defining identifier symbol/span, one earlier simple return
subtype-mark name, one earlier handler-free `Handled_Sequence_Node`, and the
complete span through `end return;`. The current handled sequence is nonempty,
handler-free, and contains only null, assignment, or procedure-call statements.
Those children are stable leaf statement forms under handled-sequence ownership, so the
extended return introduces no source-controlled recursive ownership chain. The node
stores syntax only: return-object binding, subtype legality, initialization,
accessibility, and control transfer remain semantic work. `aliased`, `constant`,
initializer, access-definition, handler-bearing, no-`do`, and broader statement
forms remain outside this selected node contract.

`Raise_Statement_Node` represents two current AARM 11.3 source forms, selected
by `Raise_Statement_Form`: `Bare_Reraise_Form` for `raise;` and
`Named_With_Message_Raise_Form` for
`raise exception_name with string_expression;`. A bare re-raise owns no
exception-name or message child and only preserves the complete `raise;` span.
The named form owns one earlier identifier/selected exception-name node, one
later-but-still-earlier current represented message expression, and the complete
span through the terminating semicolon. Constructor and validator require the
child-presence pattern to agree with the form before publication. The AST does
not decide whether a bare re-raise is dynamically enclosed by an exception
handler, whether the message has type `String`, which exception occurrence is
raised, or how control propagates; those remain semantic responsibilities. The
intermediate `raise exception_name;` source form remains outside this selected
contract. Current semantic analysis reports a controlled unsupported diagnostic
if a raise statement reaches an analyzed procedure body.

`Assignment_Statement_Node` represents the current AARM 5.2 assignment subset.
It owns an earlier represented target name, an earlier represented RHS expression,
and the complete statement span through its terminating semicolon. The initial
target subset is an identifier-selected current name; the RHS may be any current
represented expression. The node preserves syntax only: variable-view legality,
name resolution, target/RHS type resolution, implicit conversion, controlled
assignment, and execution semantics remain later semantic work.

`Case_Alternative_Node` represents one current AARM 5.4 case alternative. It owns a nonempty ordered list of earlier represented current discrete-choice nodes and a nonempty ordered list of earlier represented current statements. The current choice subset is identifier/selected-name syntax, represented integer `Numeric_Literal_Node` choices, represented `Character_Literal_Node` choices, character-literal explicit ranges represented by `Case_Range_Choice_Node`, or one `Others_Case_Choice_Node`; multiple non-`others` choices are preserved in source order, while `others` must be the sole choice. Current statements include the bounded simple forms, including `Return_Statement_Node` with an optional represented expression, `Exit_Statement_Node`, plus represented `If_Statement_Node`, `Block_Statement_Node`, and `Case_Statement_Node` compound children; full validation follows those compound edges through the explicit mixed worklist rather than recursive subtree calls. Discrete subtype choices and broader range-bound expressions remain later extensions. The node span begins at `when` and ends at the final represented statement. It preserves syntax only and creates no choice coverage, matching, type, or control-flow state.

`Case_Range_Choice_Node` represents the current AARM 3.8.1 explicit-range `discrete_choice` used by a case alternative. The selected frontend subset owns two earlier `Character_Literal_Node` bounds, the exact `..` delimiter span, and the complete range span from the first position of the lower bound through the last position of the upper bound. The lower bound must precede the upper bound in both append order and source order. The node carries no expected-type, staticness, coverage, matching, or value semantics; those remain later legality and semantic work.

`Others_Case_Choice_Node` represents the AARM 5.4 reserved-word `others` when it is used as the sole current case-alternative choice. It stores only its exact source span and carries no matching, coverage, or type semantics. It is intentionally distinct from `Others_Exception_Choice_Node` so case and exception grammar ownership cannot be conflated by later stages.

`Case_Statement_Node` represents the current AARM 5.4 case-statement subset. It owns one earlier represented selecting expression and a nonempty ordered list of earlier `Case_Alternative_Node` values, plus the complete span from `case` through the terminating semicolon of `end case;`. The current production subset has two alternatives, but the node contract is list-based rather than fixed-count. Choice legality, selecting-expression typing, coverage, reachability, and execution remain semantic work.

`Block_Statement_Node` represents the current unlabeled AARM 5.6 block subset,
with either an explicit `declare` part or the implicit empty declarative part of
a block that begins directly with `begin`. It owns an ordered list of earlier
represented current declarations and one earlier `Handled_Sequence_Node`, plus
the complete span through the terminating semicolon of `end;`. The current
declaration subset is the represented object-declaration subset. A handler-free
current block owns a nonempty ordered list from the bounded block statement
subset: assignment, exit, case, procedure-call, simple return, or `if` statements.
A simple return may own its earlier represented expression; callable-result
legality remains outside block structural validation. An `if` branch may
in turn own a handler-free block. Construction treats already stable compound
children shallowly, while full raw/context validation uses an explicit mixed
`if`/block worklist; the two ownership edges therefore do not create mutual
source-controlled recursion or repeated subtree walks. The production `run` block
still uses exactly one call. A handler-bearing current block owns the same bounded
ordinary statement list as the handler-free form plus one or more earlier current
exception handlers. Direct nested block children of a handler-bearing block must
remain handler-free; compound ordinary children continue through the mixed
if/block/loop/case validation worklist, while handler nodes reuse the existing
exception-handler validator. This prevents handler-bearing block recursion from
becoming source-controlled call-stack depth while allowing production cleanup
blocks such as calls/assignment/if followed by `when others => ... raise;`.
Block scope, declaration elaboration, labels, exception propagation, and
execution remain later work.

`Loop_Statement_Node` represents four current unlabeled Ada 2022 loop source
forms under one discriminator: the ordinary loop-parameter range subset
`for defining_identifier in [reverse] lower .. upper loop ... end loop;`, the
range-attribute form `for defining_identifier in [reverse] name'Range loop ...
end loop;`, the generalized iterator subset `for defining_identifier of [reverse]
iterable_name loop ... end loop;`, the `while condition loop ... end loop;` form,
and the simple `loop ... end loop;` form with no iteration scheme. The ordinary
explicit range form owns the loop-parameter defining symbol/span, `reverse`
presence, and two earlier represented simple-expression bounds. The range-
attribute form owns the same defining syntax and reverse flag plus one earlier
represented `Attribute_Name_Node` whose parser source form is the reserved
`Range` designator. The generalized iterator form owns the same defining syntax
and reverse flag plus one earlier represented iterable name. A while form owns
one earlier current represented condition expression while all `for`-only fields
are absent. A simple loop owns neither condition nor `for` header state. These
header child sets are mutually exclusive. All forms own
a nonempty ordered list of earlier body statements and the complete loop span.
The current body subset accepts assignment, exit, procedure-call, case, `if`, and
handler-free block statements while a directly nested loop remains outside this
node contract. Full structural and context validation queues the complete mixed
compound graph explicitly rather than recursing through those ownership edges.
The node preserves syntax only; it creates no loop entity or scope, performs no
discrete-range or Boolean typing, does not classify an iterator container, and
assigns no iteration or execution semantics.

`Procedure_Call_Statement_Node` represents one current procedure-call statement.
It owns an earlier represented callable name, an ordered list of zero or more
earlier represented actual associations, and the complete statement span through
its terminating semicolon. A positional association owns one earlier represented
actual expression. A named association additionally owns one earlier
`Identifier_Name_Node` selector before its actual expression. Positional
associations may precede named associations, but no positional association may
follow a named one. The parser publication subset uses an identifier-selected
callable prefix and the current represented actual-expression subset, including
an empty actual list for the production `Adac.Driver.run;` statement.

The association shape preserves Ada 2022 AARM 6.4 source syntax without binding
selectors to formal parameters. Callable identity, duplicate-formal detection,
overload resolution, formal-parameter resolution, parameter modes, defaults, and
execution semantics remain later semantic work. Construction and validation
check child ownership, selector kind, source order, and the positional-before-
named structural rule before publishing the call parent.

`String_Literal_Node` represents one current valid string-literal token. It owns
the exact source spelling, including bracketing and doubled quotation marks, and
the exact token span. It does not decode a string value or assign an expected
string type. The current production path first publishes the literal `": "` in
the alternative nested `put_line` actual.

`Null_Literal_Node` represents the AARM 4.2 literal `null`. It owns only the
exact token span. The AST does not assign `universal_access`, select an expected
access type, apply a null exclusion, or create a null access value; those are
semantic/type-resolution responsibilities. This node is distinct from
`Null_Statement_Node`, which represents the statement syntax defined by AARM 5.1.

`Record_Aggregate_Node` represents the current unqualified named record-aggregate
subset. It owns a nonempty ordered list of component associations. Each
association stores one selector symbol and exact selector span plus one earlier
value `Node_ID`; associations are stored inline rather than as independently
addressable AST nodes. A direct value may be either a represented nonaggregate
simple expression or another earlier `Record_Aggregate_Node`. Unary and
binary-adding roots are therefore valid scalar association values, while nested
named record aggregates preserve composite component syntax directly. A
nonaggregate simple-expression subtree may not contain a record aggregate, array
aggregate, or `Qualified_Expression_Node`, so wrappers and operators cannot hide
aggregate syntax. Construction shallow-checks an already stable nested aggregate
root instead of revalidating its subtree. Full raw and context-aware aggregate
validation traverse nested record aggregates with explicit heap-backed worklists;
source nesting therefore does not create validator call-stack growth. The parser's
expression-nesting budget bounds recursive source parsing, and the AST-node budget
bounds the published aggregate graph and validation worklists. The aggregate owns
the complete span from `(` through `)`, validates association/value source order
and same-store ownership, and creates no record type, component identity, expected
type, layout, or aggregate value. Nested array aggregates, qualified aggregates,
wrapped nested aggregates, selector uniqueness, component lookup, `others`,
positional associations, multiple choices, and broader aggregate forms remain
outside this node contract.

`Array_Aggregate_Node` represents the bounded named array-aggregate syntax
selected by Ada 2022 AARM 4.3.3. It owns a nonempty ordered list of inline
component associations. Each association owns a nonempty ordered list of earlier
represented nonaggregate simple-expression choice nodes plus one later represented
nonaggregate simple-expression value node. The list shape mirrors
`discrete_choice_list => expression` without assigning an index type or deciding
choice coverage. Construction and validation preflight every choice and value with
the same explicit nonaggregate-expression worklist used by record aggregates,
validate same-store ownership, containment, and source order, and publish the
parent only after the complete association list is stable. The initial parser
slice publishes only a qualified parenthesized form with one association whose
one choice is a numeric literal, as required by `String'(1 => self.lookahead)`.
Multiple choices, multiple
associations, ranges, `others`, box values, iterated associations, positional and
bracket forms, multidimensional/subaggregate structure, array typing, bounds,
coverage, and evaluation remain later work.

`Bracket_Aggregate_Node` represents the first bounded Ada 2022 AARM 4.3.3
positional square-bracket aggregate subset selected from native-backend bootstrap
source requirements. It owns a nonempty ordered list of earlier `Allocator_Node`
expressions and the complete span from `[` through `]`. Construction validates
child ownership, source order, containment, and list nonemptiness before parent
publication; no child subtree is copied or semantically reinterpreted. Restricting
this first form to already stable allocator children keeps aggregate validation
linear and prevents source-controlled aggregate recursion while the syntax owner
is introduced. Expected array/container type, lower bound, index mapping,
component expected type, named/others associations, and aggregate evaluation
remain later work.

`Qualified_Expression_Node` represents the current bounded qualified-expression
subset. It owns one earlier identifier/selected subtype-mark name and one later-
but-still-earlier operand. The operand may be an unqualified named `Record_Aggregate_Node`, a bounded named
`Array_Aggregate_Node`, or one current direct expression from the selected
literal/name/parenthesized subset. Aggregate operands include their own closing
delimiter in the child span; direct operands end before the qualified expression's
closing parenthesis. A direct operand is preflighted with the same iterative
expression worklist used by aggregate values, rejecting any transitive record or
array aggregate or `Qualified_Expression_Node` before parent publication. This
keeps raw AST validation free of source-controlled qualification recursion through
parenthesized wrappers. Subtype resolution, type qualification, expected type,
component legality, and value semantics remain semantic work. Attribute-bearing
subtype marks, operators as the qualified root, and broader qualified operand forms
remain outside this represented node contract.

`Allocator_Node` represents the first bounded Ada 2022 AARM 4.8 allocator form
`new qualified_expression`. It owns the exact three-column `new` keyword span,
one earlier `Qualified_Expression_Node`, and the complete span from `new` through
that child. The node preserves allocator source identity separately from
qualification; it does not resolve an
access type, choose a storage pool, allocate storage, apply accessibility rules,
or determine the designated subtype. The alternative `new subtype_indication`
remains outside this first represented allocator subset.

`If_Expression_Node` represents the current AARM 4.5.7 conditional-expression
subset `if condition then dependent_expression else dependent_expression` with
no `elsif` parts. Its condition is one earlier current simple expression, relation,
or short-circuit expression, followed by two earlier represented current simple
dependent expressions in source order; the node spans from `if` through the final
dependent expression. It does
not type the condition, determine a common dependent-expression type, or select a
branch.

`Raise_Expression_Node` represents the bounded Ada 2022 AARM 11.3 expression
form `raise exception_name [with string_simple_expression]`. It owns one earlier
identifier-selected simple exception name and, when present, one later, earlier-published represented simple message expression. Its span begins at `raise` and ends at the
exception name or message. Exception resolution, the message expected `String`
type, propagation, and control transfer remain semantic/runtime work.

`Case_Expression_Alternative_Node` represents one bounded AARM 4.5.7
case-expression alternative. It owns a nonempty ordered list of earlier current
discrete-choice syntax nodes followed by one earlier represented simple dependent
expression or `Raise_Expression_Node`. The current choice subset is `Identifier_Name_Node`, `Selected_Name_Node`, and
`Others_Case_Choice_Node`; selected choices remain syntax-only names. Choice
typing, staticness, overlap, and `others` placement are semantic work. `Case_Expression_Node` owns one
earlier represented simple selecting expression plus a nonempty ordered list of
earlier `Case_Expression_Alternative_Node` children. It spans from `case` through
the last dependent expression and performs no expected-type propagation, coverage
check, or branch selection.

`Parenthesized_Expression_Node` represents a current AARM 4.4 parenthesized
primary. It owns one earlier current represented expression, or an existing
`If_Expression_Node` / `Case_Expression_Node` conditional-expression child, and
the complete span from the
opening through the closing parenthesis. This includes ordinary forms such as
`(Alpha)`, `(not Ready)`, represented binary relations, represented `and then` /
`or else` expressions, and nested represented parentheses. Construction checks
only the stable direct child and bracket span; full raw/context expression
validation follows nested parenthesized children through explicit pending-node
worklists rather than source-controlled recursive validation. Ordinary logical
forms outside the current represented subset remain outside this publication
boundary until their own expression publication paths are selected.

`Unary_Operator_Node` represents one current unary operation. The represented
spellings are AARM 4.5.4 unary adding `+`/`-` and AARM 4.5.6 `abs`/`not`. The
node owns one earlier represented operand, the exact operator spelling and token
span, and the complete expression span from the operator through the operand.
Unary adding owns the represented `term` required by the grammar, while `abs`
and `not` own their represented primary. It does not resolve an overload, enforce
operand typing, perform arithmetic/Boolean evaluation, or assign a result type.

`Binary_Exponentiating_Node` represents the AARM 4.4 factor form
`primary ** primary`. It owns two earlier represented primary/direct-expression
children, the exact two-character `**` spelling and token span, and the complete
source span from the left primary through the right primary. Construction and
validation preserve factor precedence and source order without assigning operand
or result types, selecting an overload, or performing exponentiation. The node is
not a multiplying-chain member; this keeps Ada's highest-precedence factor
boundary explicit and prevents accidental left-associative flattening.

`Binary_Multiplying_Node` represents one current AARM 4.4/4.5 term operation. It
owns an earlier left current term, an earlier right current factor, the exact
multiplying-operator spelling/span, and the complete source span. The represented
operator set is `*`, `/`, `mod`, and `rem`; word-operator spelling is preserved
while structural validation compares it case-insensitively. Repeated operators
form an append-only left-linked chain, matching Ada's textual left association.
Numeric/fixed-point typing, overload selection, division/modulus/remainder
semantics, overflow, and static evaluation remain semantic work. Represented
`abs`/`not` and exponentiation factors participate through the factor child
boundary rather than being flattened into this node.

`Binary_Adding_Node` represents one current binary-adding operation. It owns an
earlier left simple-expression node, an earlier right current term node, the
exact operator spelling and token span, and the complete operation span. The
parser publication subset uses all three Ada binary adding spellings `+`, `-`,
and `&`. Repeated operations form an append-only left-linked chain, preserving
Ada's textual left association without recursive construction. Numeric, array,
or component typing, overload resolution, and the result type remain semantic
work.

`Relation_Node` represents one current binary `relation` using any Ada
relational-operator spelling (`=`, `/=`, `<`, `<=`, `>`, or `>=`). It owns earlier
left and right expression operands, the exact operator spelling and operator-token
span, and the complete relation span. Publication preserves syntax without
resolving the operator, assigning operand types, selecting an overload, or
assigning the predefined `Boolean` result type. Current operands may be a
represented literal, current name, current exponentiating factor, current
binary-multiplying term, or current binary-adding chain. Broader represented
simple expressions extend that operand
boundary rather than changing relation ownership.

`Membership_Range_Choice_Node` represents one current explicit `range` used as
a membership choice. It owns an earlier represented lower simple expression, the
exact `..` delimiter span, an earlier represented upper simple expression, and
the complete range span. Both bounds must precede the range-choice node in the
append-only store and remain source ordered around the delimiter. The node is not
a general expression and is accepted only through membership-choice ownership.

`Membership_Expression_Node` represents the current Ada 2022 AARM 4.5.2
choice-expression and explicit-range membership subset. It owns one earlier
represented tested simple expression, an explicit `in`/`not in` operator kind,
the exact `in` token span plus an optional exact `not` token span, a nonempty
ordered list whose entries are earlier represented simple-expression choices or
`Membership_Range_Choice_Node` values, and the complete source span through the
last choice. Separately classified subtype-mark choices remain later work;
identifier names remain syntax-only choice expressions until semantic analysis
determines their tested type and interpretation. Construction and validation
require all children to precede the parent and preserve source order. Membership
result typing, expected types of range bounds, equality/subtype/range semantics,
and the complementary meaning of `not in` remain semantic work.

The current name representation preserves syntax without performing name
resolution. `Logical_Expression_Node` represents one current AARM 4.5.1 binary
`and`, `or`, or `xor` operation. It owns an earlier left expression, the logical
operator kind and exact operator-token span, an earlier right expression, and
the complete source span. Repeated same-precedence logical operators are folded
left-associatively, matching Ada source association. Construction rejects a
logical-expression right child so a represented chain is left-deep; raw and
context validation walk that left chain iteratively, keeping validator call-stack
depth independent of source-controlled chain length. Operand typing, overload
selection, Boolean/modular/array interpretation, and evaluation remain semantic
work.

`Short_Circuit_Expression_Node` represents one current binary `and then` or
`or else` operation. It owns an earlier left expression, the operator kind and
exact spans of both reserved-word tokens, and an earlier right expression. The
right child may not itself be a short-circuit node; repeated operators are stored
as a left-associated chain. Raw validation walks that left chain iteratively and
validates each non-chain right operand through the ordinary expression validator,
so chain length does not become validator call-stack depth. Each node span starts
at its left operand and ends at its right operand, with both operator-token spans
strictly source ordered between them. Boolean typing, legality of operand types,
short-circuit evaluation, and control-flow semantics remain later semantic work.
The expression parser publishes this representation for current top-level
`and then` and `or else` chains when every operand already belongs to the
represented expression subset. Publication folds repeated operators
left-associatively and preserves both reserved-word token spans. The node remains
syntax-only: Boolean typing, legality of operand types, short-circuit evaluation,
and control-flow semantics remain later semantic work.

`Identifier_Name_Node` stores one identifier symbol and its exact
source span. `Selected_Name_Node` stores an earlier identifier or selected-name
prefix, one selector symbol, the selector span, and the complete selected-name
span. Identifier selectors remain the ordinary simple-name subset. The selected
generic-actual path may additionally use a terminal valid operator symbol as the
selector; its symbol spelling retains the exact quoted source form such as `"="`,
and its selector span covers that complete token. This is syntax ownership only:
selector category, visibility, overload resolution, and callable semantics remain
later work. The parser does not use an operator-symbol selected name as the prefix
of another selected-name suffix in the current subset.
`Explicit_Dereference_Name_Node` represents AARM 4.1 `name.all` syntax. It owns
one earlier current-name prefix, the exact reserved-word `all` token span, and the
complete span from the prefix start through `all`. Construction and validation
require the prefix to be earlier, contained, and source ordered; they assign no
access type, designated object/subprogram, null check, or dereference semantics.
The node participates in the iterative current-name worklist and may be retained
as a parenthesized-name actual without classifying that enclosing syntax as a
call. `Selected_Component_Node` stores an earlier non-simple current-name prefix,
one identifier selector symbol/span, and the complete selected-component span.
The current selected-component prefix subset is a `Parenthesized_Name_Node`, an
`Explicit_Dereference_Name_Node`, or an earlier `Selected_Component_Node`, so forms
such as `A(B).C.D` and `Access_Value.all.Field` remain syntax-only.
`Parenthesized_Name_Node` stores an earlier prefix from the current parenthesized-
name prefix subset (identifier/selected name, `Explicit_Dereference_Name_Node`,
another `Parenthesized_Name_Node`, `Selected_Component_Node`, or
`Attribute_Name_Node`) plus a nonempty ordered list of actual items. Each item
preserves either positional source form or a named association whose selector is
an earlier `Identifier_Name_Node`; the actual remains an earlier current-name
item, represented `Numeric_Literal_Node`, `Character_Literal_Node`, selected
`Binary_Adding_Node` expression, or represented string-literal direct-expression
item. Named
associations may follow positional items, while a positional item after the first
named association is rejected. The node owns the
whole source span through the closing parenthesis. Repeated suffixes therefore
remain an append-only chain rather than being semantically classified.
A current name item may itself be a `Parenthesized_Name_Node` or an
`Attribute_Name_Node`. Character- and string-literal items remain syntax-only actual candidates and are
validated through the existing expression path; no call/index/conversion or
attribute-argument classification is assigned. The bounded binary-actual subset keeps its operands inside
a selected simple-expression shape. An iterative preflight may retain an
earlier `Parenthesized_Name_Node` operand when that nested name graph itself owns
only current-name or literal actuals; the preflight walks its prefix, selectors,
and actuals explicitly and rejects another expression actual below that nested
name. This admits production syntax such as `Positive (Natural
(local_objects.length) + 1)` while preventing source-controlled
name-to-expression-to-name-to-expression validation recursion. Existing forms
such as `OS.Write(File, Content(Content'First + Offset)'Address,
Content'Length - Offset)` remain within the same bounded ownership contract. `Slice_Name_Node` represents the
current AARM 4.1.2 explicit-range slice subset. It owns an earlier simple-name or
identifier-attribute prefix, an earlier represented lower simple expression, the
exact `..` delimiter span, an earlier represented upper simple expression, and
the complete span through the closing parenthesis. The parser currently publishes
a name-led lower bound and a name-or-numeric upper bound, with represented binary
adding chains on either side as encountered; broader discrete-range syntax stays
staged. The parenthesized-name parser preserves slice state per explicit nesting
frame, so a slice may itself be an actual of an outer parenthesized name. Both
bounds may own represented binary-adding chains, including the production form
`text(text'First + 1 .. text'Last - 1)`, without making nesting recursive. The
node records syntax only: array/index type, discrete-range legality, bound
evaluation, and slice semantics remain later work. `Attribute_Name_Node`
stores an earlier current-name prefix, one identifier attribute-designator symbol,
the exact designator span, and the complete span through that designator. This
allows an already represented parenthesized name to prefix an attribute such as
`Content(... )'Address` without deciding whether the parenthesized source form is
a call, indexed component, or conversion.

The parenthesized node is intentionally not classified as a function call,
indexed component, or type conversion. Ada resolves those syntactic
interpretations from the surrounding complete context, so that semantic
classification belongs to later name and overload resolution rather than the
parser's current syntax representation.

Every name child must already exist in the same append-only store before its
parent is published. The current parenthesized publication subset admits nested
current-name items and identifier selected-component suffixes whose prefixes are
validated iteratively through earlier nodes. The current attribute subset
contains one argument-free identifier designator and no following suffix; it
preserves syntax only and does not decide whether an attribute is defined for the
prefix. Broader name forms continue to use frontend staging until their AST
contracts are selected.

`Aspect_Specification_Node` represents the current bounded Ada 2022 aspect
syntax `with aspect_mark => aspect_definition` used by package function
declarations. It owns the identifier aspect-mark symbol and exact mark span, one
earlier represented expression for the aspect definition, and the complete span
from `with` through the definition. The node preserves syntax only: aspect-name
resolution, aspect legality, inheritance, assertion policy, contract evaluation,
and any effect on callable semantics remain later semantic work. The current
parser publishes at most one identifier-marked aspect with an explicit `=>`
definition; `aspect_mark'Class`, multiple comma-separated associations, and
omitted definitions remain outside this bounded subset.

`Parameter_Specification_Node` represents the current AARM 6.1
`defining_identifier_list` formal subset with an identifier-selected subtype
mark and an optional earlier represented default expression. It owns one
nonempty ordered defining-identifier list, one `Parameter_Mode_Kind`, the earlier
subtype-mark name node, and either `INVALID_NODE_ID` or one earlier current
represented-expression node for the default. The first defining symbol and exact
identifier span remain available through the compatibility `parameter_symbol`
and `parameter_defining_span` queries;
`parameter_defining_identifier_count`, `parameter_defining_symbol_at`, and
`parameter_defining_span_at` expose the complete source-ordered list.
`Parameter_Mode_Kind` distinguishes omitted/default `in`, explicit `in`,
explicit `in out`, and explicit `out`; the first two share the same later Ada
mode semantics but preserve different source forms. The node is syntax identity
only: parameter binding, default-expression expected typing, mode legality,
parameter passing, and scope membership remain semantic work. Its span begins at
the first defining identifier and ends at the default expression when one is
present, otherwise at the subtype mark. Any commas, explicit mode, and `:=`
tokens lie inside that span. `aliased`, null exclusions, access definitions, and
broader parameter forms remain outside this represented node subset. It creates
no parameter entities or binding/type state.

`Object_Declaration_Node` represents the current one-defining-identifier,
identifier-selected-subtype subset with no `aliased`, access definition, anonymous
type, or aspect specification. `Object_Declaration_Form` distinguishes a variable
object from an explicit `constant` object. The node owns the defining symbol and
exact defining-identifier span, the earlier subtype-mark node, an optional earlier
`Index_Constraint_Node`, an optional earlier represented-expression initializer,
and the complete declaration span. A missing constraint or initializer is
represented explicitly. For `Variable_Object_Form` it
represents the current uninitialized variable subset; for
`Constant_Object_Form` it represents an AARM 3.3.1/7.4 deferred constant. A
present initializer on `Constant_Object_Form` remains a full constant
declaration. The form plus initializer-presence pair therefore preserves these
source distinctions without adding a second constant-object node kind.

The subtype mark, any present index constraint, and any present initializer must
already exist in the same store. The subtype mark is an identifier or selected
name; the current index constraint contains one explicit discrete range; a present
initializer is any current represented expression. The declaration span begins at
the defining identifier and ends at the terminating semicolon, contains its
present children, and preserves subtype-mark -> constraint -> initializer source
order. The form enum preserves whether the `constant`
token was present even though reserved words and punctuation are not stored as
separate child nodes. Variable/constant semantics, subtype legality,
initialization, binding, visibility, and elaboration remain later semantic work.

`Object_Renaming_Declaration_Node` represents the current explicit-subtype Ada
2022 AARM 8.5.1 object-renaming subset. It owns one defining symbol and exact
defining span, one earlier identifier/selected-name subtype mark, one earlier
current represented name denoting the renamed object, and the complete declaration
span through the semicolon. The subtype mark precedes the renamed-object name,
both children precede the parent, and all three spans are contained and source
ordered. The node is distinct from `Object_Declaration_Node`: renaming does not
create an initialized/uninitialized object declaration and later semantic analysis
must preserve Ada's view semantics rather than treating it as a copy. Omitted
subtype marks, null exclusions, access definitions, aspects, name resolution,
subtype matching, and renamed-view semantics remain outside the current node
contract.

`Number_Declaration_Node` represents the current bootstrap named-number subset
with one defining identifier, the required `constant :=` syntax, one earlier
represented initializer expression, and no aspect specification. It owns the
defining symbol and exact defining-identifier span plus the initializer node ID.
The initializer must already exist in the same store, precede its parent, and be
a current represented expression. The declaration span begins at the defining
identifier and ends at the terminating semicolon and contains the initializer in
source order. The node preserves syntax only: staticness, expected numeric type,
universal numeric type, named-number value, visibility, and declaration identity
remain semantic work. The current node invariant implies that `constant :=` was
present even though those tokens are not stored as child nodes.

`Procedure_Declaration_Node` represents the current procedure-declaration
subset with an identifier defining name and an optional current formal part. It
owns the defining symbol and exact defining-identifier span, an ordered list of
earlier `Parameter_Specification_Node` children, and the complete declaration
span from `procedure` through the terminating semicolon. An empty parameter list
means the formal part is absent. Every present parameter must lie after the
defining name and before the semicolon in source order. The node preserves syntax
identity only and creates no callable entity, overload set, scope, completion
link, profile semantics, visibility, elaboration state, or executable behavior;
aspects, overriding indicators, renamings, null or abstract completions, and
bodies remain outside this node.

`Function_Declaration_Node` represents the current AARM 6.1 function-declaration
subset and the bounded AARM 6.8 parenthesized expression-function form. It owns
an identifier defining designator, the shared optional current formal part,
`return subtype_mark`, an optional earlier represented expression-function
expression, and an optional bounded aspect specification. The defining
symbol/span, ordered earlier `Parameter_Specification_Node` children, and result
subtype remain common to both forms. `function_declaration_has_expression` and
`function_declaration_expression` distinguish the expression-function source
form without creating a separate callable entity. Any present expression follows
the result subtype in source order, and any present aspect follows the result or
expression. Operator-symbol defining designators, null exclusions, access
results, aggregate expression-function bodies, multiple or class-wide aspects,
overriding indicators, renamings, ordinary bodies, and callable or contract
semantics remain outside this node.

`Discriminant_Specification_Node` represents the current AARM 3.7 known
discriminant subset with exactly one defining identifier, one earlier represented
identifier/selected-name subtype mark, and an optional earlier represented default
expression. It owns the defining symbol/span and the exact specification span; it
does not create a discriminant entity, resolve the discriminant subtype, apply
expected typing to the default, or enforce the semantic all-or-none default rule
across a discriminant part. Null exclusions, access definitions, multiple
defining identifiers/specifications, and discriminant aspects remain outside the
current syntax subset.

`Exception_Declaration_Node` represents the current AARM 11.1 single-identifier
exception declaration subset. It owns the defining symbol, exact identifier span,
and complete declaration span through `exception;`. It creates no exception
entity or occurrence identity and carries no raising, propagation, matching, or
elaboration semantics.

`Record_Component_Declaration_Node` represents one current AARM 3.8 ordinary
record component declaration with exactly one defining identifier. It owns the
component defining symbol and exact span, a Boolean preserving whether `aliased`
appeared, one earlier represented subtype-mark name, an optional earlier
represented default expression, and the complete component span through its
semicolon. The node is a record child rather than a package/procedure declarative
item and creates no component entity, aliasing semantics, or layout.

`Record_Variant_Node` represents one current AARM 3.8.1 variant. It owns a
nonempty ordered list of earlier identifier-name discrete choices and either a
nonempty ordered list of earlier ordinary `Record_Component_Declaration_Node`
children or an explicit Boolean recording the source `null;` component list. The
current syntax subset does not represent ranges, `others`, non-name choice
expressions, aspect clauses, or nested variant parts. It does not check staticness,
choice overlap, coverage, or expected discriminant typing.

`Record_Variant_Part_Node` represents `case discriminant_direct_name is ... end
case;`. It owns one earlier `Identifier_Name_Node` for the direct discriminant
name, a nonempty ordered list of earlier `Record_Variant_Node` children, and the
complete variant-part span. Structural validation preserves source order and
containment but does not resolve the direct name to a discriminant or choose a
variant.

`Record_Type_Declaration_Node` represents the current untagged record-type
subset with optional `limited` source form and an optional represented known
discriminant part. It owns the type defining symbol/span, a Boolean preserving
whether `limited` appeared, an ordered possibly empty list of earlier
`Discriminant_Specification_Node` children, an ordered possibly empty list of
earlier ordinary `Record_Component_Declaration_Node` children, an optional earlier
`Record_Variant_Part_Node`, and the complete type declaration span from `type`
through `end record;`. Discriminants precede ordinary components, which precede
the optional variant part; all children must be contained by the record span,
precede the record parent, and appear in source order. At least one ordinary
component or a variant part must be present in the current non-null-record subset.
The node creates no type/first-subtype/discriminant or component entity,
limited-type semantics, record layout, component offsets, discriminant constraint
or variant-selection state,
default initialization semantics, or elaboration state.

`Access_Object_Type_Declaration_Node` represents the current named
access-to-object subset `type T is access [all | constant] subtype_mark;`. It
owns the type defining symbol/span, one `General_Access_Modifier_Kind` preserving
modifier absence, `all`, or `constant`, one earlier represented simple-name node
for the designated subtype mark, and the complete declaration span. The node is
syntax only: access-type identity, accessibility, storage pools, allocation,
dereference, designated-type legality, null exclusion, and mutability semantics
remain later semantic work.

`Private_Type_Declaration_Node` represents the current AARM 7.3 untagged
private-type subset `type defining_identifier [discriminant_part] is [limited]
private;`. It owns the defining symbol, its exact identifier span, an optional
ordered list of earlier current `Discriminant_Specification_Node` children, the
source-form Boolean recording whether `limited` appeared, and the complete
declaration span from `type` through the terminating semicolon. The current
frontend publishes at most one discriminant specification, while the raw node
contract keeps the list ordered and bounded by the common resource limits. The
node has no `abstract`/`tagged` modifier, aspect specification, private extension,
or full-view syntax. It preserves the partial-view declaration as syntax only and
creates no type entity, first subtype, completion link, visibility state,
discriminant semantics, limitedness semantics, or elaboration semantics.

`Enumeration_Type_Declaration_Node` represents the current AARM 3.2.1/3.5.1
identifier-only enumeration subset. It owns the type defining symbol/span, a
nonempty ordered list of enumeration literal defining symbol/span pairs, and the
complete declaration span from `type` through the terminating semicolon. Literal
defining names are stored inline rather than as one AST node per literal, so a
large enumeration does not consume AST-node budget proportional to its literal
count. The source-character and distinct-symbol budgets still bound parsing and
publication. Defining-character-literal syntax remains outside this initial
subset. Literal distinctness, overload semantics, position numbers, predefined
operators, first-subtype creation, and elaboration are semantic work.

`With_Clause_Node` represents one current plain nonlimited, nonprivate `with`
clause. It owns a nonempty ordered list of earlier identifier or selected-name
nodes, one for each library-unit name in the clause. Its span starts at `with`
and ends at the terminating semicolon. The node records syntax only; it does not
resolve a library unit or create dependency, visibility, or elaboration state.

`Derived_Type_Declaration_Node` represents the current unconstrained derived-type
declaration subset `type defining_identifier is new subtype_mark;`. It owns the
defining symbol/span, one earlier represented identifier or selected-name parent
subtype mark, and the complete declaration span. The node does not create a type,
resolve the parent type, inherit operations, establish primitive operations,
process constraints, or apply representation/elaboration semantics.

The parent subtype-mark node must precede the derived-type parent, lie inside the
declaration span after the defining identifier, and pass current simple-name
validation. Discriminants, subtype constraints, interface lists, record
extensions, abstract/limited modifiers, and aspects remain outside this syntax
subset.

`Range_Constraint_Node` represents one current explicit scalar range constraint.
It owns two earlier represented expression nodes for the lower and upper bounds
and the complete span beginning at `range` and ending at the upper bound. The
bounds remain syntax only; value evaluation, staticness, expected-type
propagation, and range legality are semantic work.

`Index_Constraint_Node` represents the current Ada 2022 single-range index-
constraint subset `(lower .. upper)`. It owns two earlier represented simple-
expression bounds, the exact `..` token span, and the complete span including the
opening and closing parentheses. Additional dimensions, subtype-mark discrete
ranges, range-attribute discrete ranges inside index constraints, index subtype
resolution, staticness, and array constraint semantics remain later work.

`Subtype_Declaration_Node` represents the current AARM 3.2.2 subset `subtype S is
subtype_mark [range lower .. upper];`. It owns the defining symbol/span, one
earlier identifier/selected-name subtype mark, an optional earlier
`Range_Constraint_Node`, and the complete declaration span. It creates no subtype
entity, first subtype, constraint semantics, predicate state, or elaboration
state.

`Package_Renaming_Declaration_Node` represents the current AARM 8.5.3 package
renaming subset `package defining_program_unit_name renames selected_name;`. It
owns a nonempty ordered defining program-unit-name component list, one earlier
identifier/selected-name node for the renamed package, and the complete source
span through the terminating semicolon. The node preserves syntax only: it does
not resolve the renamed package, establish a new package view/entity, create a
scope, or apply visibility/elaboration semantics.

The renamed package child must precede the renaming parent, lie after the complete
defining name in source order, and remain inside the declaration span. Defining
components use the same symbol/span representation as other package declarations.

`Package_Instantiation_Node` represents the current AARM 12.3 generic package
instantiation subset. It owns a nonempty ordered defining program-unit-name
component list, one earlier represented identifier/selected-name node naming the
generic package, an ordered possibly empty list of positional or named generic
actual associations, and the complete source span through the terminating
semicolon. `Generic_Actual_Association_Form` distinguishes a positional association,
which owns only one earlier represented identifier/selected-name or string-literal
actual, from a named association, which also owns one formal selector symbol/span. Identifier
selectors and valid operator-symbol selectors such as `"="` use the same source-
spelling identity; the latter retains its quoted operator-symbol spelling.
Selector queries are invalid for positional associations rather than
manufacturing a sentinel selector. The node does not resolve the generic unit,
match formals and
actuals, apply defaults, copy template declarations, create an instance
entity/scope, or perform elaboration.

The defining components, generic package name, named selectors, and actual children
must all lie inside the instantiation span and appear in source order. Every actual
child must precede the instantiation parent and satisfy the current generic-actual
validation contract: represented name validation for name actuals or string-literal
validation for `String_Literal_Node` actuals.
Duplicate selectors, positional-to-formal mapping, and formal-name legality are
semantic rules and
are not checked by the structural constructor.

`Package_Declaration_Node` represents the current package-specification subset
with either a simple or identifier-selected defining program-unit name. It owns a
nonempty ordered defining-name component list, an ordered possibly empty visible
declaration list, an optional explicit `private` keyword span, a distinct ordered
possibly empty private declaration list, an optional ordered closing-name
component list, and the complete source span from `package` through the
terminating semicolon. Current structurally representable package declarations
are object, object-renaming, number, exception, procedure, function, private-type, derived-type,
subtype, enumeration-type, record-type, access-object-type, package-renaming,
package-instantiation, or nested package-declaration nodes. An invalid
private-part span
denotes the
implicit empty
private part; a valid span denotes an explicit private boundary. A nonempty
private declaration list requires that explicit boundary. An empty closing-name
list represents an absent closing designator. A present closing list is preserved
but is not required by the constructor to equal the defining list; AARM 7.1 name
repetition remains a semantic legality rule. The node creates no package entity,
scope, visibility, elaboration state, private-view semantics, named-number
semantics, or callable semantics.

Every defining or closing component owns one symbol and exact identifier span.
Components must be contained by the package span and appear in source order.
Every represented visible declaration must already exist in the same append-only
store, precede the package parent, be contained by the package span, and appear
after the complete defining name. A nested package child recursively satisfies
this same structural contract while retaining its own defining/closing names and
declaration lists. An explicit private keyword follows all visible declarations;
every represented private declaration follows that keyword and the preceding
private item. Closing components follow the final visible declaration
when no explicit private part exists, or the private keyword/final private item
when it does. Aspect specifications and private-part semantic visibility rules
remain outside this structural node contract.

`Use_Type_Clause_Node` represents the selected AARM 8.4 basic declarative item
`use type subtype_mark {, subtype_mark};`. It owns a nonempty ordered list of
earlier represented identifier/selected-name subtype marks plus the complete
source span from `use` through the terminating semicolon. Every subtype-mark child
must precede the clause parent, lie within that span, and appear in source order.
The node preserves syntax only: it performs no subtype resolution, primitive
operator discovery, direct-visibility update, overload-set mutation, or
elaboration.

`Use_Package_Clause_Node` represents the selected AARM 8.4 package-use basic
declarative item `use package_name {, package_name};`. It owns a nonempty ordered
list of earlier represented identifier/selected package names plus the complete
source span through the terminating semicolon. Every package-name child must
precede the clause parent, lie within that span, and appear in source order. The
node is syntax only: package resolution, direct visibility, overload visibility,
and scope effects remain semantic work.

`Procedure_Body_Stub_Node` represents the selected AARM 10.1.3
`procedure defining_identifier [formal_part] is separate;` subset of a
subprogram body stub. It owns the defining symbol/span, ordered earlier current
`Parameter_Specification_Node` children, and the complete source span through the
terminating semicolon. The parser only selects this node for a procedure item
immediately inside a package-body declarative part; other nested-procedure
contexts do not widen. Overriding indicators, function stubs, aspect
specifications, completion matching, corresponding-subunit lookup, profile
conformance, and elaboration remain outside this syntax-only node.

`Package_Body_Stub_Node` represents the selected Ada 2022 AARM 10.1.3
`package body defining_identifier is separate;` body stub. It owns the defining
identifier symbol and exact identifier span plus the complete source span from
`package` through the terminating semicolon. The defining identifier is not a
program-unit-name component list because AARM 10.1.3 permits only one defining
identifier in this form. The node preserves syntax only: completion matching,
corresponding subunit lookup, same-kind checks, distinct-stub legality, and the
post-compilation requirement for a corresponding subunit remain later work.

`Package_Body_Node` represents the current AARM 7.2 package-body subset with a
selected defining program-unit name, an ordered possibly empty list of earlier
represented declarative items, an optional ordered closing-name component list,
and the complete source span from `package` through the closing semicolon. Current
declarative children may be `Procedure_Body_Node` or `Function_Body_Node` values,
`Procedure_Body_Stub_Node` and `Package_Body_Stub_Node` body stubs,
`Use_Type_Clause_Node` and
`Use_Package_Clause_Node` basic declarative items, or any normal declaration kind
accepted by current declaration validation,
including package renamings and nested package declarations. Defining and closing
names use the same exact
symbol/span component representation as package declarations. An empty closing-
name list preserves an absent designator; a present list is not required by the
constructor to equal the defining list because AARM 7.2 name repetition remains a
semantic legality rule. The current node has no package-body `begin` part or
exception handlers; sources using package initialization remain outside the
selected frontend subset.

Every declarative child must already exist in the same append-only store, precede
the package-body parent, lie inside the package-body span, and follow the complete
defining name in source order. Closing components follow the final owned item. The
node creates no package entity, completion link, scope, visibility, elaboration
state, package initialization semantics, or executable behavior.

`Procedure_Body_Node` represents the current procedure-body subset in the same
ownership shape as Ada 2022 AARM 6.3. It owns the defining procedure symbol, an
ordered possibly empty parameter list, an ordered possibly empty
declarative-part
list, one earlier `Handled_Sequence_Node`, and an optional closing-designator
symbol. Current parameters must be earlier `Parameter_Specification_Node`
values.
Current declarative items are earlier `Object_Declaration_Node`,
`Object_Renaming_Declaration_Node`, `Procedure_Declaration_Node`,
`Enumeration_Type_Declaration_Node`, `Record_Type_Declaration_Node`,
`Package_Instantiation_Node`, `Use_Type_Clause_Node`, `Use_Package_Clause_Node`,
or `Procedure_Body_Node` values in source order. A procedure declaration preserves
its profile/semicolon syntax without creating a completion link. A nested
procedure body is owned
by the enclosing procedure declarative part as one stable child ID; no subtree
is copied into its parent, and construction checks that stable compound child
shallowly rather than revalidating its complete subtree. The handled sequence is mandatory
and contains the executable statement syntax and optional exception handlers; a
procedure body no longer duplicates those statements in a second vector.

The span starts at `procedure` and ends at the body semicolon. An absent closing
designator is represented by `INVALID_SYMBOL_ID`; when a designator is present,
its symbol is preserved. The constructor does not require a present closing
designator to equal the defining symbol because AARM 6.3(3) makes that a
language
legality rule for semantic analysis. `statement_count` and `statement_at` remain
compatibility queries that read the ordinary statement list of the owned handled
sequence rather than storing a duplicate list.

`Function_Body_Node` represents the current AARM 6.3 function-body subset. It
owns the defining function symbol, an ordered possibly empty parameter list, one
earlier result-subtype name, an ordered possibly empty declarative-part list, one
earlier `Handled_Sequence_Node`, and an optional closing-designator symbol.
Current parameters reuse `Parameter_Specification_Node`, including represented
default expressions. Current declarative items are ordinary declaration nodes accepted by declaration
validation or stable earlier `Procedure_Body_Node` / `Function_Body_Node` values.
The parser can select nested procedure bodies and one bounded production-shaped
nested function body from function declarative syntax while retaining current
identifier-led declarations in source order. A function body that is itself owned
by a procedure may additionally own current local `Procedure_Body_Node` children;
those procedure children shall not themselves own a procedure or function body.
The enclosing procedure-body construction/validation boundary preflights this
restricted shape before accepting the function child. Construction treats already
stable nested subprogram bodies as shallow compound children. Full raw/context
function-body validation traverses nested function bodies through explicit
function worklists, and nested procedures retain their existing explicit
procedure-body worklist, so validation stack usage does not grow with nested
function AST depth. The handled sequence contains the
ordered current represented prefix statements followed by the required
`return expression;` statement and no exception handlers.
The current prefix subset includes call, assignment, `if`, iterator-loop, and
`null;` syntax; each compound child retains its own bounded nonrecursive contract.

The function-body parent is appended only after its profile, result subtype,
declarative children, complete ordered statement syntax, return-expression subtree,
handled sequence, and closing syntax are stable. All children must precede the body
parent and remain in source order inside the complete span. Additional declarative
forms, broader body statements, and function exception handlers remain explicit
frontend boundaries until a production prerequisite selects them. The node creates
no callable entity, scope, overload, return-type semantics, elaboration state, or
execution behavior.

`Subunit_Node` represents the current Ada subunit syntax `separate
(parent_unit_name) proper_body`. It owns the nonempty ordered parent-unit-name
component list and one earlier proper-body node. The raw AST contract admits
current procedure, function, and package bodies as proper bodies; the parser
subset selected by the bootstrap profile publishes package-body and current
procedure-body subunits. Procedure proper bodies reuse the ordinary represented
procedure-body ownership path and remain syntax-only. Function, task, and
protected proper bodies remain parser boundaries. The subunit span begins at
`separate` and ends with the proper body,
and every parent-name component precedes that body in source order. The node
preserves syntax identity only: it creates no parent/body completion link,
separate-subunit entity, library dependency, visibility, or elaboration state.

`Compilation_Unit_Node` is the syntax root. It owns an ordered, possibly empty
list of earlier context-item nodes and one earlier unit-item node. A unit item is
either a current library item or `Subunit_Node`; current library-item kinds are
`Procedure_Body_Node`, `Package_Renaming_Declaration_Node`,
`Package_Instantiation_Node`, `Package_Declaration_Node`, and `Package_Body_Node`.
The root span starts at the first context item when one is present, otherwise at
the unit item, and always ends with the unit item. Every child span must be
contained by the unit span and context items must precede the unit item in source
order. `unit_item` exposes this grammar-level choice. The compatibility
`library_item` query succeeds only when the unit item is actually a library item
and rejects a subunit rather than erasing its distinct AARM 10.1.1 ownership.

Production APIs do not expose mutable node records or unchecked constructors.
Malformed representations needed by validator tests are created only through
test-only child packages that can see the private store representation.

## Structural Validation

`Adac.AST.validate (node)` remains the root identity check for an opaque
`Node_ID`; it rejects the public invalid value and does not traverse a store.
Store-aware subtree and compilation-unit validation is exposed through
`Adac.AST.Validation`. The validation child forwards to one parent-private
validation implementation subunit that has lexical access to the same AST store
and invariant helpers used by construction. It owns no mutable state and creates
no second validation model.

`Adac.Compilation.Syntax` performs context/source/symbol ownership checks around
that structural validation surface. This keeps context-aware validation and raw
store invariants distinct while preserving one structural validation authority.

## Queries

Queries require the owning context and a valid `Node_ID`. They return immutable
node properties such as kind, span, handled statements and handlers, handler
choices and body statements, `if` condition and branch statements, callable name
and ordered call actuals, literal spelling, binary-adding or relation operator
spelling and span, expression operands, symbols, statement count, and child IDs.
Kind-specific queries reject a node of the wrong kind.

No query returns a raw node pointer or mutable node reference. Semantic analysis
and IR construction resolve IDs through `Adac.Compilation.Syntax`, preserving
the context ownership boundary.

## Stage Boundaries

`Adac.Frontend.Parse_Result` is discriminated by parse status. A rejected parse
has no AST payload. A successful parse contains the root `Node_ID`, which
borrows the AST store in the context supplied to `parse_file`.

The parser validates the completed root before returning success. Semantic
analysis repeats context-aware validation before consuming the tree and
publishes a semantic entity on success. IR construction reaches the declaration
through that validated entity. Validation does not transfer ownership or modify
the store.

`Adac.Compilation.Syntax.validate` checks:

- root validity, ownership, range, and compilation-unit kind;
- ordered context-item ownership and the current `With_Clause_Node` kind;
- each with-clause name list, current simple-name shape, and symbol ownership;
- the current procedure-body or package-declaration library-item kind and its
  kind-specific symbols, represented children, and source-order invariants;
- child ordering plus source-span structure, context ownership, and containment.

`Adac.Compilation.Syntax.validate_handled_sequence` validates the current
handled
sequence, including a nonempty statement list, ordered earlier handler nodes,
source containment, and source order. `validate_exception_handler` validates an
optional choice-parameter symbol/span pair, a nonempty ordered choice list, and
a nonempty body statement list. Current choices are
`Others_Exception_Choice_Node`
values or represented identifier/selected names; name validation remains purely
syntactic and does not resolve exception identity.

`Adac.Compilation.Syntax.validate_if_statement` validates the current `if` node,
including condition ownership, a nonempty ordered then list, optional ordered
else list, earlier-node requirements, branch source order, and containment within
the complete statement span. The condition reuses expression validation and
branch children reuse current statement validation without assigning Boolean or
control-flow semantics.

`Adac.Compilation.Syntax.validate_case_alternative` validates a nonempty ordered
choice list and nonempty ordered statement list, earlier-node requirements,
source order, and containment. Current choices are identifier or selected names;
current alternative statements remain the represented simple statement subset.

`Adac.Compilation.Syntax.validate_case_statement` validates the selecting
expression, a nonempty ordered alternative list, earlier-node requirements,
source order, and complete `case ... end case;` containment without performing
coverage or choice legality.

`Adac.Compilation.Syntax.validate_block_statement` validates ordered current
object declarations, the earlier block `Handled_Sequence_Node`, source order, and
the complete explicit `declare ... end;` span. It creates no block scope or
elaboration state.

`Adac.Compilation.Syntax.validate_loop_statement` validates the loop-parameter
symbol/span, iterable simple-name subtree, nonempty ordered bounded body list,
earlier-node requirements, source order, and complete `for ... end loop;` span.
It does not create a loop-parameter binding or resolve iterable semantics.

`Adac.Compilation.Syntax.validate_procedure_call` validates a current procedure
call, including callable-name ownership, ordered positional/named actual
associations, identifier selectors on named associations, positional-before-named
ordering, earlier-node requirements, statement containment, and the terminating-
statement span boundary. Actual expressions reuse expression validation and
remain semantically unbound.

`Adac.Compilation.Syntax.validate_expression` validates a current represented
expression subtree that may have been published before an enclosing unsupported
construct rejects parsing. Direct represented literals and names are validated
without semantic interpretation. A unary operator validates its earlier primary,
operator spelling/span, and source ordering. A binary-multiplying chain is
validated iteratively through left-linked terms while each right operand remains
a current factor. A binary-adding chain is likewise validated iteratively through
its left links while each right operand remains a current term. A relation
validates its represented simple-expression operands, earlier-node ownership,
operator spelling/span, and ordered containment.

`Adac.Compilation.Syntax.validate_name` separately validates a current name
subtree that may have been published before an enclosing unsupported construct
rejects parsing. It verifies AST-store ownership and ordering, current name
kinds, symbol ownership, source ownership, and child-span containment. Selected
prefix chains, parenthesized item lists, the current simple-prefix attribute node,
and slice range bounds are validated without source-controlled recursive
traversal. Slice bounds enter the existing expression worklist while the current
slice prefix is deliberately limited to non-slice simple/attribute syntax.

`Adac.Compilation.Syntax.validate_parameter` validates a current parameter
specification before its enclosing owner is represented. It verifies the
defining symbol and span, simple subtype-mark subtree, optional current
represented default expression, child ordering and containment, and
compilation-context ownership.

`Adac.Compilation.Syntax.validate_declaration` validates a current object,
number, or parameterless procedure declaration before the parser advances past
that declaration boundary. For an object declaration it verifies the defining
symbol and span, current subtype-mark and initializer subtrees, child ordering
and containment, and compilation-context ownership. For a number declaration it
verifies the defining symbol and span, represented initializer expression,
earlier-child ordering, containment, and compilation-context ownership. For a
procedure declaration it verifies the defining symbol/span and complete
`procedure ...;` source boundary without inventing a profile or semantic callable
identity. It does not validate staticness, numeric typing, overload resolution,
or subprogram completion.

`Adac.Compilation.Syntax.validate_package_declaration` validates one current
package subtree, including all defining-name components, optional closing-name
components, ordered earlier number/procedure-declaration children, containment,
source order, and compilation-context ownership. It does not enforce closing-name
equality or create semantic package state.

A validation failure raises `Program_Error`. It is not an ordinary Ada source
diagnostic and must not be converted to a rejected parse or semantic result.

## Complexity And Failure

Appending a handled sequence or exception handler is linear in its direct child
count. Each owned list is copied once into context-owned immutable syntax
storage. Appending case alternatives, a case statement, or a block statement is
likewise linear in direct child count and copies each direct `Node_ID` list once.
Appending a current iterator loop is linear in its direct body-statement count;
stable case/if/block children are checked shallowly during construction. Full
validation visits loop/case/if/handler-free-block compound descendants through one
explicit mixed worklist, so alternating compound ownership does not become call-
stack recursion or repeated subtree validation. The current case-alternative
compound-child subset includes `if`, block, loop, and nested case statements;
all are queued on the same mixed worklist, so nested case/block/loop depth does
not create source-controlled recursive validation. Appending an `if` statement
is linear in
its direct branch-statement count plus
validation of its condition and current child statements. Each branch list is
copied once into context-owned immutable syntax storage. Appending a
procedure-call statement is linear in its actual-association count plus
validation of the callable name, named selectors, and represented actual
expressions. The association list is copied once into context-owned immutable
syntax storage.
Appending a literal, current if expression, parenthesized conditional wrapper,
or one unary, binary-multiplying, binary-adding, or relation node performs bounded
direct-child checks and is constant-time. Full validation of left-associated
binary-multiplying and binary-adding chains is linear in node count and uses
constant auxiliary space. Appending an identifier, selected name, current
identifier-attribute name, or
current explicit-range slice performs bounded direct-child checks and is
constant-time apart from context validation of represented slice bounds. Full
slice validation queues lower/upper expressions on the existing iterative
expression worklist. Appending a parenthesized name is linear in its direct item
count because the child list is validated and copied once at each ownership
layer.
Appending a current parameter specification, object declaration, number
declaration, or parameterless procedure declaration performs bounded direct-
child identity, kind, span, and source-order checks. A function-body constructor
likewise checks a stable nested procedure declarative child shallowly rather than
re-walking that child subtree; full function-body validation delegates nested
procedure subtrees to the explicit procedure-body worklist, so validation remains
linear without source-controlled call-stack growth. Context-aware number-
declaration construction additionally validates the initializer expression, so
its work is proportional to that represented expression subtree; the current
production numeric-literal initializer is constant-time.
Appending a with clause is linear in its direct name count. Appending a package
declaration is linear in its defining components, direct visible declarations,
and closing components. Appending a procedure body is linear in its direct
parameter and statement counts. Appending
the compilation-unit root is linear in its context-item count plus validation of
its unit item. Full
name or declaration validation is linear in the reachable current-name nodes and
allocates no traversal stack. Root validation is linear in the reachable current
context names and direct procedure statements. Future recursive syntax shall
retain work proportional to reachable nodes and shall be covered by resource
limits.

Configured node-budget exhaustion raises `Adac.Resources.Limit_Exceeded` before
an append and leaves the node count unchanged. Representable node-index or
allocator exhaustion raises `Storage_Error` before an ID wraps or a live ID is
reused. A failure may leave earlier nodes in the append-only store, but it must
not publish a partially initialized node.

Operations on one context are sequential until a stronger concurrency contract
is introduced. Independent contexts share no AST store or mutable node state.

## Extension Rules

New node kinds shall add their structural invariants, context-owned references,
queries, validator coverage, and parser boundary tests in the same change.
Semantic facts belong in semantic storage rather than mutable AST fields.

Persistent formats shall serialize schema-defined node ordinals and the owned
store, never runtime ownership markers or memory addresses.

## Tests

In-process tests shall cover:

- deterministic construction and queries for a valid minimal unit with a
  separate procedure-body child;
- deterministic plain-with construction, multiple names, context-item ordering,
  and compilation-unit containment;
- invalid and foreign `Node_ID` values;
- invalid and foreign symbols and source spans;
- an empty statement list and a child outside its parent span;
- parser root publication and exact node spans;
- deterministic construction, queries, and validation for `others`, named
  exception choices, optional choice parameters, current exception handlers, and
  handled sequences;
- rejection of empty handler choice/body lists and foreign, later, malformed, or
  out-of-order handled-sequence and handler children;
- deterministic construction, queries, and validation for the current `if`
  statement with and without an `else` part;
- rejection of empty then lists and foreign, later, malformed, or out-of-order
  `if` condition and branch children;
- deterministic construction, queries, and validation for parameterless,
  positional, and mixed positional/named procedure-call statements;
- rejection of foreign, later, malformed, or out-of-order callable names, named
  selectors, and actual expressions, including a positional actual after a named
  association;
- deterministic construction, queries, and validation for the current
  parenthesized `if ... then ... else ...` expression, including foreign,
  malformed, and out-of-order children;
- deterministic construction, queries, and validation for the current `not`
  unary operator, including malformed operator/operand/span rejection;
- deterministic construction, queries, and validation for the current
  left-associated multiplying chain across `/`, `mod`, and `rem`, with `*` also
  covered through frontend assignment publication;
- rejection of invalid multiplying-operator spelling and foreign/malformed child
  structure through the ordinary expression validators;
- deterministic construction, queries, and validation for current string
  literals and left-associated concatenation chains;
- rejection of malformed string-literal shape and foreign, malformed, or out-of-
  order binary-adding operands and operator spans;
- iterative validation of a long left-associated concatenation chain without
  recursion proportional to source length;
- deterministic construction, queries, and validation for a current equality
  relation with ordered represented operands;
- rejection of foreign, malformed, or out-of-order relation operands and
  operator spans;
- deterministic construction, queries, and validation for current name nodes,
  including an identifier attribute reference;
- rejection of a current name through a foreign compilation context;
- controlled AST-node-budget exhaustion before attribute-parent publication;
- deterministic construction, queries, and validation for current parameter
  specifications with absent and present represented default expressions;
- rejection of a current parameter through a foreign compilation context and of
  malformed, foreign, later, or out-of-order default-expression children;
- deterministic construction, queries, and validation for the current object
  declaration node;
- deterministic construction, queries, and validation for the current number
  declaration node;
- deterministic construction, queries, and validation for current generic
  package instantiations whose actuals include selected names and exact string
  literals in positional or named associations;
- deterministic construction, queries, and validation for a character-literal
  case range choice, including both bound children, exact `..` span, source order,
  and rejection of malformed or non-character bound ownership;
- deterministic construction, queries, and validation for the current package
  declaration node, including empty and multi-declaration visible parts;
- rejection of a current package through a foreign compilation context and of
  malformed package declaration children;
- rejection of a current declaration through a foreign compilation context;
- rejection of a malformed object declaration with a non-name subtype child;
- rejection of a malformed number declaration with a non-expression initializer;
- controlled AST-node-budget exhaustion before partial parent publication;
- semantic and IR rejection of malformed internal trees;
- isolation between two compilation contexts;
- deterministic `Program_Error` for contract violations.

End-to-end parser and semantic tests verify that malformed source continues to
use ordinary diagnostics rather than internal contract failures.
