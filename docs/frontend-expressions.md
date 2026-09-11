# Frontend Expressions

This document defines the current expression-staging contract for the Adac
frontend. The staging parser recognizes a bounded subset of Ada operator,
membership, parenthesized, qualified-expression, parenthesized aggregate,
bracket-aggregate, and initial iterated-association structure so unsupported
expressions receive precise diagnostics. It now represents current binary
relations using Ada's six relational-operator spellings and the bounded
choice-expression-only `in`/`not in` membership subset in addition to
caller-requested current name and numeric primary syntax. Representation does not imply semantic expression analysis,
overload resolution, Boolean typing, or language support for evaluating
expressions.

## Current Grammar Boundary

The current staging subset follows these Ada 2022 precedence forms:

```text
expression ::= relation { and relation }
             | relation { and then relation }
             | relation { or relation }
             | relation { or else relation }
             | relation { xor relation }

relation ::= simple_expression [ relational_operator simple_expression ]
           | simple_expression [ not ] in membership_choice_list

membership_choice_list ::= membership_choice { | membership_choice }
membership_choice      ::= choice_expression
                         | simple_expression .. simple_expression

choice_expression ::= choice_relation { and choice_relation }
                    | choice_relation { and then choice_relation }
                    | choice_relation { or choice_relation }
                    | choice_relation { or else choice_relation }
                    | choice_relation { xor choice_relation }

choice_relation    ::= simple_expression
                       [ relational_operator simple_expression ]
simple_expression ::= [ unary_adding_operator ] term
                      { binary_adding_operator term }
term              ::= factor { multiplying_operator factor }
factor            ::= primary [ ** primary ] | abs primary | not primary

primary ::= numeric_literal
          | character_literal
          | string_literal
          | null
          | name
          | classic_aggregate
          | staged_delta_aggregate
          | staged_bracket_aggregate
          | qualified_expression
          | allocator
          | ( expression )

allocator ::= new qualified_expression

qualified_expression ::= subtype_mark ' ( expression )
                       | subtype_mark ' classic_aggregate
                       | subtype_mark ' staged_delta_aggregate
                       | subtype_mark ' staged_bracket_aggregate

classic_aggregate ::= record_aggregate | extension_aggregate | array_aggregate

staged_delta_aggregate ::=
  ( base_expression with delta staged_delta_association_list )

staged_bracket_aggregate ::=
    [ ]
  | [ expression {, expression} ]
  | [ expression {, expression}, others => staged_aggregate_value ]
  | [ staged_bracket_aggregate_association
      {, staged_bracket_aggregate_association} ]
  | [ others => staged_aggregate_value ]
  | [ base_expression with delta staged_delta_association_list ]

staged_aggregate_association ::=
    staged_choice_list => staged_aggregate_value
  | staged_iterated_association

staged_bracket_aggregate_association ::=
    staged_aggregate_association
  | staged_bracket_keyed_iterated_association

staged_bracket_keyed_iterated_association ::=
    for defining_identifier in [reverse] staged_in_iterator_domain
      [staged_iterator_filter] staged_iterator_key => expression
  | for defining_identifier : staged_loop_parameter_subtype_indication
      in [reverse] staged_iterator_name [staged_iterator_filter]
      staged_iterator_key => expression
  | for defining_identifier [: staged_loop_parameter_subtype_indication]
      of [reverse] staged_iterable_name [staged_iterator_filter]
      staged_iterator_key => expression

staged_iterated_association ::=
    for defining_identifier in staged_choice_list => expression
  | for defining_identifier in staged_in_iterator_domain
      staged_iterator_filter => expression
  | for defining_identifier in reverse staged_in_iterator_domain
      [staged_iterator_filter] => expression
  | for defining_identifier : staged_loop_parameter_subtype_indication
      in [reverse] staged_iterator_name [staged_iterator_filter] => expression
  | for defining_identifier [: staged_loop_parameter_subtype_indication]
      of [reverse] staged_iterable_name
      [staged_iterator_filter] => expression

staged_iterator_filter ::= when expression
staged_iterator_key ::= use expression
staged_loop_parameter_subtype_indication ::=
    [not null] name [staged_loop_parameter_constraint]
  | staged_access_definition
staged_function_result ::=
    [not null] name
  | staged_access_definition
staged_basic_formal_part ::=
  ( staged_basic_parameter_specification
    {; staged_basic_parameter_specification} )
staged_basic_parameter_specification ::=
    staged_formal_defining_identifier_list :
      staged_subtype_mark_parameter_definition [:= expression]
      [staged_parameter_aspect_specification]
  | staged_formal_defining_identifier_list :
      staged_access_definition [:= expression]
      [staged_parameter_aspect_specification]
staged_subtype_mark_parameter_definition ::=
  [aliased] staged_formal_parameter_mode [not null] name
staged_parameter_aspect_specification ::=
  with staged_parameter_aspect_mark
    [=> staged_parameter_aspect_definition]
    {, staged_parameter_aspect_mark
       [=> staged_parameter_aspect_definition]}
staged_parameter_aspect_mark ::= identifier ['Class]
staged_parameter_aspect_definition ::= expression
staged_access_definition ::=
    [not null] access [constant] name
  | [not null] access [protected] procedure [staged_basic_formal_part]
  | [not null] access [protected] function [staged_basic_formal_part]
      return staged_function_result
staged_formal_parameter_mode ::= [in] | in out | out
staged_formal_defining_identifier_list ::=
  defining_identifier {, defining_identifier}
staged_loop_parameter_constraint ::=
    staged_loop_parameter_scalar_constraint
  | staged_composite_constraint
staged_loop_parameter_scalar_constraint ::=
    range staged_range
  | digits expression [range staged_range]
staged_composite_constraint ::=
    staged_index_constraint
  | staged_discriminant_constraint
staged_index_constraint ::=
  ( staged_index_discrete_range {, staged_index_discrete_range} )
staged_index_discrete_range ::=
    subtype_mark [range staged_range]
  | staged_range
staged_discriminant_constraint ::=
  ( staged_discriminant_association
    {, staged_discriminant_association} )
staged_discriminant_association ::=
    expression
  | staged_discriminant_selector_list => expression
staged_discriminant_selector_list ::=
  selector_name { | selector_name }
staged_in_iterator_domain ::= name
                            | staged_discrete_subtype_choice
                            | simple_expression .. simple_expression
staged_iterator_name ::= name
staged_iterable_name ::= name

staged_aggregate_value ::= expression | <>
staged_choice_list ::= staged_choice { | staged_choice }
staged_choice ::= expression
                | staged_discrete_subtype_choice
                | simple_expression .. simple_expression

staged_discrete_subtype_choice ::= subtype_mark range staged_range
staged_range ::= range_attribute_reference
               | simple_expression .. simple_expression
```

The represented expression subset includes `Short_Circuit_Expression_Node` for
bounded top-level `and then` and `or else` chains whose operands are already
represented current expressions. The parser folds repeated operators
left-associatively, preserves the exact span of each reserved-word token, and
reuses the existing relation/simple-expression precedence path for every operand.
Ordinary `and`, `or`, and `xor`, mixed unparenthesized logical forms, and logical
operands outside the represented expression subset retain their existing staging
or support boundaries rather than manufacturing partial syntax.

A logical chain selects exactly one of `and`, `and then`, `or`, `or else`, or
`xor`. One unparenthesized chain may not mix these forms. Short-circuit control
words are consumed as two tokens so exact source spelling remains available.

The full Ada grammar also permits a `subtype_mark` and a general `range` as a
membership choice. In the current staging subset, subtype-mark and range
attribute spellings are consumed through the existing name primary, while an
explicit range is recognized as `simple_expression .. simple_expression`.
Semantic classification of those alternatives is deferred to later stages.
A membership choice may contain a `choice_expression`, but another membership
test is not recursively accepted inside that choice expression.

The current represented membership subset is:

```text
represented_membership ::=
  represented_simple_expression [not] in
    represented_membership_choice
    { | represented_membership_choice }

represented_membership_choice ::= represented_simple_expression
                                | represented_membership_range

represented_membership_range ::= represented_simple_expression
                                 .. represented_simple_expression
```

The parser reuses the existing iterative membership-choice walk. Publication is
selected only when the tested expression and every choice have current represented
syntax. An explicit range publishes one `Membership_Range_Choice_Node` after both
bounds are stable, preserving the exact `..` span without making that node a
general expression. Relational/logical choice expressions and separately
classified subtype-mark choices remain staged-only. One `Membership_Expression_Node`
then preserves `in` versus `not in`, exact reserved-word token spans, and the
ordered heterogeneous choice nodes. No tested type, expected type for range bounds,
subtype-vs-value classification, equality operation, Boolean result semantics, or
range membership semantics is created by the frontend.

The current staged primary forms are numeric, character, string, and null
literals plus the name forms defined by `frontend-names.md`. When represented
syntax is requested, each valid current numeric token may publish one
`Numeric_Literal_Node` containing its lexical form, exact spelling, and span. A
valid current character token may publish one `Character_Literal_Node` containing
its exact three-character spelling and span, while a valid current string token
may publish one `String_Literal_Node` containing its exact source spelling and
span. The literal `null` may publish one `Null_Literal_Node` containing its exact
token span. An otherwise operator-free full expression containing exactly one
string-literal primary publishes that existing `String_Literal_Node` directly,
matching the current single numeric/null primary completion without adding String
typing. These syntax nodes assign no semantic value or expected type; in
particular, AARM 4.1/4.2 character-literal name resolution and expected character
type, string expected-type resolution, plus access-type resolution for `null`,
remain semantic work.

The current represented allocator subset is deliberately limited to Ada 2022
AARM 4.8 `new qualified_expression`. When syntax publication is requested, the
parser preserves the exact `new` token span and requires the allocated operand to
be one already represented current `Qualified_Expression_Node`. The allocator is
published as a distinct `Allocator_Node`; it is not folded into the qualified
expression or interpreted as an access value. The `new subtype_indication`
alternative, designated-access-type resolution, storage-pool selection,
accessibility, allocation, and initialization semantics remain later work. This
first slice is selected by the bootstrap `new String'("-o")` expression.

The current AARM 4.4 parenthesized-expression publication subset includes:

```text
represented_parenthesized_expression ::=
  ( represented_current_expression )
```

The wrapper is published only when the complete inner expression already has one
current represented expression node. Parentheses therefore preserve syntax for
current literals, names, unary `abs`/`not`, exponentiating factors,
binary-multiplying terms, binary-adding chains, relations, represented
membership/`and then`/`or else` expressions, and nested represented parentheses
without claiming support for structurally consumed ordinary logical expressions.
Nested relation/short-circuit
publication
uses isolated capture state so an inner parenthesized expression cannot overwrite
its enclosing relation or short-circuit candidate. Nested parentheses are bounded
by `maximum_expression_nesting`; AST/context validation uses explicit pending-node
worklists so raw trees do not consume call-stack depth proportional to parenthesis
nesting.

The current AARM 4.5.7 conditional-expression publication subset is:

```text
represented_parenthesized_if_expression ::=
  ( if represented_if_condition
    then represented_simple_expression
    else represented_simple_expression )

represented_if_condition ::= represented_simple_expression
                           | represented_relation
                           | represented_short_circuit_expression

represented_parenthesized_case_expression ::=
  ( case represented_simple_expression is
      represented_case_expression_alternative
      { , represented_case_expression_alternative } )

represented_case_expression_alternative ::=
  when represented_case_expression_choice
       { | represented_case_expression_choice }
  => represented_case_dependent_expression

represented_case_expression_choice ::= represented_simple_name | others

represented_case_dependent_expression ::= represented_simple_expression
                                        | represented_raise_expression

represented_raise_expression ::=
  raise represented_simple_name [with represented_string_simple_expression]

represented_string_simple_expression ::= represented_simple_expression
```

The parser publishes one `If_Expression_Node` after all three if-expression child
expressions exist. For the selected case-expression subset it publishes one
`Case_Expression_Alternative_Node` only after all of that alternative's choices
and dependent expression exist, then one `Case_Expression_Node` after the complete
ordered alternative list exists. Either conditional node is wrapped by one
`Parenthesized_Expression_Node` only after the closing parenthesis is validated.
`elsif` parts and a missing `else` remain outside the represented if subset. Case
choices are limited to represented identifier/selected simple names and `others`;
selecting expressions remain
limited to the current represented simple-expression subset. A dependent
expression may additionally be the bounded Ada 2022 AARM 11.3
`raise exception_name [with string_simple_expression]` form. The current exception
name is an identifier-selected simple name. A present message reuses the current
represented simple-expression syntax; its expected `String` type is semantic work.
The wrapper is required because AARM 4.5.7 permits a conditional expression
in an ordinary `expression` position only when immediately parenthesized. The if
condition may also reuse one already represented binary relation or short-circuit
expression, while the current dependent `then`/`else` expressions remain in the
simple-expression subset. This carries production forms such as `stack_size = 0`
and `not Ready and then (Left or else Right)` without changing the
dependent-expression contract. Membership conditions remain outside this selected
conditional-expression publication slice. No Boolean or
discrete typing, choice coverage/exhaustiveness checking, expected-type
propagation, branch selection, or common-type resolution is performed. In the
existing if-expression production, the three children occupy the syntax published
through node 369, the `If_Expression_Node` is node 370, and the
`Parenthesized_Expression_Node` wrapper is node 371. AST budgets 369 and 370
therefore reject those two parents independently without partial publication.
The enclosing `output_path` object declaration then publishes normally.

A factor of the exact current shape `not represented_primary` may publish one
`Unary_Operator_Node`. The node owns the earlier primary plus the exact `not`
spelling and token span. A simple expression beginning with AARM 4.5.4 unary
adding `+` or `-` may publish the same node kind around the earlier represented
term. Operator overload resolution, operand typing, arithmetic negation/absolute-value
semantics, Boolean typing, and result typing remain semantic work. An AARM 4.5.6
`abs represented_primary` factor may publish the same unary node kind around its
primary operand. The factor form `represented_primary ** represented_primary`
publishes a dedicated `Binary_Exponentiating_Node` owning both earlier primaries
and the exact `**` token span. The parser consumes only one exponentiating
operator at this factor boundary, preserving the grammar's non-chain structure;
repeated `**` without parentheses remains rejected.

A current term whose represented factors are joined by an Ada multiplying
operator (`*`, `/`, `mod`, or `rem`) may publish a left-associated
`Binary_Multiplying_Node` chain. Each node owns the earlier left term, the next
represented factor, exact source spelling/span of the operator, and its complete
span. This follows the AARM 4.4 `term ::= factor { multiplying_operator factor }`
precedence level without performing numeric/fixed-point typing, overload
selection, division/modulus/remainder semantics, overflow checking, or static
evaluation. The current factor publication subset includes represented primaries,
unary `abs`/`not`, and represented exponentiating factors. Unary adding belongs
to the surrounding simple-expression level and wraps the
represented term rather than changing factor precedence.

A simple expression whose currently represented terms are joined by an Ada
binary adding operator (`+`, `-`, or `&`) may publish a left-associated
`Binary_Adding_Node` chain. Every node owns the earlier left expression, the next
represented term, the exact operator spelling and token span, and its complete
source span. The representation preserves source association without resolving
numeric, array, or component types or selecting an overloaded operator. A leading
unary `+` or `-` is represented separately as `Unary_Operator_Node`; that unary
node may also become the left operand of a following represented binary-adding
chain, preserving the AARM simple-expression source order without flattening the
unary term.

When one current relation consists of two represented simple expressions
separated by a relational operator (`=`, `/=`, `<`, `<=`, `>`, or `>=`), the
frontend may publish one `Relation_Node` owning those earlier operands, the
exact operator spelling and token span, and the complete relation span. Callers
that explicitly select represented relation completion may return that stable
node immediately instead of falling through the legacy unsupported-operator
boundary; current object initializers use this opt-in path. Other expression
callers retain their existing completion policy, so a represented relation prefix
does not by itself widen broader unsupported operator forms. Publication
preserves syntax only; name resolution, operand compatibility, overload
selection, and the predefined `Boolean` result remain semantic work.

Parenthesized expressions outside the represented simple-expression and
conditional-expression subsets remain staged as primaries. Parentheses may change
the grouping required by the Ada precedence grammar, including forms such as
`(Cold and Sunny) or Warm` and `A ** (B ** C)`; those broader operator trees remain
explicitly unrepresented until their nested-expression paths are selected.

The staging subset recognizes both qualified-expression alternatives. The
subtype mark is consumed through the existing name parser. The frontend does not
claim that the name actually denotes a subtype because type identity and name
resolution belong to later semantic work. An attribute may be part of the
staged subtype mark, as in `Types.Index'Base'(Value)`.

`classic_aggregate` is a frontend staging name for the record, extension, and
array aggregate alternatives that use the currently available expression, name,
and explicit-range forms. It is not an Ada grammar production. The parser uses
delimiters that disambiguate these forms from a parenthesized expression: a
comma, `=>`, `|`, `..`, `with`, `null record`, or `others`. It recognizes
positional and named associations, `others =>`, box (`<>`) values, and extension
aggregates without claiming which composite type an aggregate has. A single
positional item remains a parenthesized expression, matching the Ada rule that a
one-association record aggregate must be named. Positional associations may
precede named associations; `others` must be last.

Within that broader staging grammar, the current represented record-aggregate
subset is deliberately narrower:

```text
represented_record_aggregate ::=
  ( represented_record_association
    {, represented_record_association} )

represented_record_association ::=
  identifier => represented_record_value

represented_record_value ::=
    represented_nonaggregate_simple_expression
  | represented_record_aggregate

represented_nonaggregate_simple_expression ::=
  represented_simple_expression whose transitive expression subtree contains
  no represented record aggregate, array aggregate, or qualified expression

represented_qualified_expression ::=
    represented_simple_subtype_mark ' represented_record_aggregate
  | represented_simple_subtype_mark ' represented_array_aggregate
  | represented_simple_subtype_mark ' ( represented_qualified_direct_operand )

represented_array_aggregate ::=
  ( represented_array_association )

represented_array_association ::=
  represented_numeric_literal
    => represented_nonaggregate_simple_expression

represented_qualified_direct_operand ::= current direct literal/name expression
  with no transitive record aggregate, array aggregate, or qualified expression

represented_simple_subtype_mark ::= identifier {. identifier}
```

A syntax-owning caller may publish the unqualified parenthesized form as one
`Record_Aggregate_Node`. Each association preserves the selector symbol/span and
one earlier value child in source order. A direct value may be either an already
represented nonaggregate simple expression, including unary and binary-adding
roots, or another represented named `Record_Aggregate_Node`. The aggregate-value
boundary still walks nonaggregate expression graphs iteratively and rejects any
transitive `Record_Aggregate_Node`, `Array_Aggregate_Node`, or
`Qualified_Expression_Node`, so parentheses and operators cannot hide nested
aggregate syntax. Direct nested record aggregates are shallow-checked during
parent construction and traversed by explicit worklists during full raw and
context-aware validation rather than recursively revalidating stable children.
Each nested parenthesized aggregate consumes the existing expression-nesting
budget while parsing. Nested array aggregates, qualified aggregates, and wrapped
nested record aggregates remain outside this represented subset. When the same
named aggregate follows an identifier/selected subtype mark and apostrophe, the
parser preserves the earlier qualifier node and the unqualified aggregate
separately, then publishes one
`Qualified_Expression_Node` spanning both. The same node now also owns selected
direct operands such as `String'("-o")`; the inner expression is preserved as
its own earlier child while the qualified wrapper owns the apostrophe/parentheses
through its complete span. Construction and validation preflight direct operands
iteratively and reject transitive aggregate or qualification syntax, so nesting a
qualified expression under a parenthesized operand cannot create validation
recursion. The selected qualified named-array path is intentionally narrower than the
staging grammar: it publishes one association whose single choice is a numeric
literal and whose value is a represented nonaggregate simple expression,
preserving both children in source order under `Array_Aggregate_Node` before
wrapping it in
`Qualified_Expression_Node`. This covers `String'(1 => self.lookahead)` without
classifying an unqualified named aggregate as record versus array syntax.
Positional associations, `others`, multiple choices separated by `|`, multiple
array associations, range choices, box values, iterated associations, extension
aggregates, operator-root qualified operands, bracket/delta qualified forms, and
attribute-bearing qualified subtype marks continue to use staging only. The parser does not resolve
the expected type, look up components, or type qualified operands; those are
semantic responsibilities.

Named array choices now stage the discrete-subtype form whose subtype indication
is a subtype mark optionally constrained by the current scalar range syntax. A
bare subtype mark remains syntactically indistinguishable from a name
choice-expression until semantic analysis; a following `range` token selects the
staged constrained-subtype form. The range is either a `Range` attribute
reference or two simple-expression bounds separated by `..`. The parser does
not claim that the subtype mark denotes a discrete subtype.

Other subtype constraints require their own lexical and grammar prerequisites.

The staging subset recognizes the parenthesized syntax shared by Ada 2022 record
and array delta aggregates. The expression before `with delta` is parsed through
the existing expression grammar. Every following association must be named and
uses the current aggregate-choice staging. `others` choices and box (`<>`)
component values are rejected. The frontend does not decide whether the operand
has a record or array type; that distinction requires semantic type information.

Square-bracket aggregate syntax is staged without deciding whether the expected
type is an array or a user-defined container. The current represented subset
publishes one nonempty positional form whose elements are already represented
`Allocator_Node` expressions; this is the production shape used by the native
backend argument list. The `Bracket_Aggregate_Node` owns those elements in source
order and the exact `[`/`]` whole span without assigning expected type, bounds,
or index positions. Other bracket forms remain staging-only. The broader staging
subset accepts null, positional, and non-iterated named bracket forms plus the
bracketed array-delta spelling. A positional bracket form may end with `others =>`; otherwise a
bracket aggregate is either positional or named rather than mixing the two
forms. Named choices reuse the current expression, explicit-range, and staged
discrete-subtype choice grammar. A box (`<>`) value is retained where a bracket
array or indexed
container can use it; semantic legality remains deferred until expected-type
information exists.

The staging subset recognizes basic iterated aggregate associations in both
the existing `in` form and the iterator-specification `of` form. An `in` form
without a filter continues to stage a choice list without deciding whether an
array or container aggregate is expected.

A filter-bearing `in` form is delimiter-sensitive. In a parenthesized aggregate,
the domain before `when` must be a single staged name, matching the generalized
iterator form available to an array aggregate. In a bracket aggregate, the same
name form is accepted, and the current constrained-subtype and explicit-range
staging is also accepted to cover a container loop-parameter specification. A
bare bracket name is not classified as an iterator name or a discrete subtype.
A vertical-bar choice list is not filterable. A parenthesized constrained
subtype or explicit range is likewise not filterable.

The `in reverse` form uses the same delimiter-sensitive domain boundary and may
also have an optional `when expression` filter. A vertical-bar choice list is
not accepted after `reverse`.

The `of` form accepts an optional `when expression` iterator filter after the
staged iterable name, with or without `reverse`. The iterable name uses the
existing name parser without claiming that it denotes an array or iterable
container. Every staged iterator filter uses the existing expression parser
without claiming that the condition has a Boolean type.

The current iterator-specification staging accepts a subtype-mark name with an
optional null exclusion `not null` and optional staged constraint, the
access-to-object `access_definition` alternative
`[not null] access [constant] subtype_mark`, an access-to-procedure
definition, or an access-to-function definition whose result uses a subtype
mark or the currently staged `access_definition` alternatives. The subprogram
forms may be parameterless or contain one staged basic formal part before the
procedure boundary or function `return`. A colon after the defining identifier
selects this iterator-specification path for both `in` and `of`.
The subtype mark uses the existing name parser without claiming that the name
denotes a subtype. `not null` is retained as structural syntax without claiming
that the subtype is an access subtype or that the null exclusion is semantically
legal. A staged scalar constraint is either the existing `range` form or a
`digits` constraint with an optional range. A range remains a `Range` attribute
reference or two simple-expression bounds.

The current composite-constraint slice stages the index-constraint and
discriminant-constraint structures needed at this boundary. An index constraint
contains one or more discrete ranges. A staged discrete range may be a subtype-
mark name, that name followed by a `range` constraint, a `Range` attribute, or
two simple-expression bounds. A discriminant constraint contains positional
expressions or named associations whose `selector_name` list is followed by
`=>` and an expression. Positional associations must precede named associations.
In a `subtype_indication`, the subtype-mark name parser stops before the left
parenthesis so the constraint parser owns the delimiter.

A bare subtype-mark name or bare `Range` attribute remains syntactically
ambiguous between an index discrete range and a positional discriminant
expression until type and name resolution are available. An explicit range or a
subtype-mark name followed by `range staged_range` selects index-constraint
syntax. A general expression that cannot be a staged subtype mark or bare
`Range` attribute, and every named association, selects discriminant-constraint
syntax. Once an exclusive form selects one structure, a later exclusive item
from the other structure is rejected as malformed composite-constraint syntax.

Staging does not claim that the outer subtype mark denotes an unconstrained
array or discriminated subtype, that an inner subtype mark denotes a discrete
subtype, or that a range has the required index type. It also does not validate
array dimensionality, index compatibility, discriminant count, selector
resolution, selector type agreement, or whether each discriminant is constrained
exactly once.

The `digits` operand uses the current expression precedence parser with
membership disabled only at its top-level boundary. This preserves the following
iterator `in` token as the outer delimiter without scanner rewind or token
buffering; nested delimited expressions retain their existing parsing rules. The
frontend does not claim that the operand is static, positive, or integer typed,
or that the subtype mark denotes a decimal fixed point subtype. Those are
semantic and legality rules for later milestones.

The access-to-object form consumes its subtype mark through the existing name
parser. `access` and `constant` are structural syntax only; staging does not
create an anonymous access type or validate designated-type, null-exclusion, or
constant-view semantics. Access-to-procedure and access-to-function forms may
omit their formal part or use one staged basic formal part, such as
`(Item : Item_Type)`, `(Item : not null Item_Type)`,
`(Left, Right : Item_Type)`, or
`(Item : Item_Type; Other, Extra : Other_Type)`. The basic form stages one or
more `parameter_specification` forms separated by semicolons. Each specification
has a nonempty `defining_identifier_list` and selects either a subtype-mark
parameter definition or a staged `access_definition`. The subtype-mark form
supports optional `aliased`, all staged modes, and optional `not null`,
and one subtype-mark name. The access definition stages the access-to-object,
access-to-procedure, and access-to-function alternatives, including optional
nested basic formal parts and recursive function-result access definitions.
Both parameter-definition forms may have an optional default expression
introduced by `:=` and an optional parameter aspect specification after the
default. A staged parameter aspect specification consumes one or more
comma-separated aspect marks after `with`. Each aspect mark is an identifier
with an optional case-insensitive `'Class` designator and may have an explicit
definition after `=>`. Explicit definitions reuse the current expression parser,
including names and aggregates already accepted by expression staging. Ada
2022's specialized `global_aspect_definition` is not staged at this formal-
parameter boundary. Adac does not assign aspect semantics here and does not
define a custom non-expression aspect-definition syntax in this slice.
Every formal defining identifier is validated without creating a binding, while
subtype marks and default expressions reuse the existing name and expression
parsers. Aspect-mark identifiers and the optional `Class` designator are
validated structurally without symbol publication. Names in explicit aspect
definitions retain the existing expression-parser symbol-publication rules.
Structural staging creates no explicitly-aliased, parameter-mode, default-value,
aspect, anonymous-access-type, designated-type, constant-view, or accessibility
state. The separate package-subprogram representation path may request syntax
publication for a selected formal default. Its first bootstrap use is the
current represented name `Natural'Last`; that expression is returned as existing
identifier-attribute syntax and becomes an optional parameter child. This does
not change the broader access-profile staging path or assign default semantics.
Nested access-to-subprogram profiles are syntax only and do not create a
designated profile or calling-convention state. The parser also defers
null-exclusion, default-expression, aspect-recognition, duplicate-aspect, and
aspect-definition legality. This staging supplies the parameter
`aspect_specification` shell while aspect recognition and semantics remain
outside this slice. Specialized non-expression definitions also remain outside.
The function result may
be a subtype mark or any currently staged `access_definition`, including another
access-to-function result.
Staging does not create an anonymous access-to-subprogram type, formal parameter
entity or scope, designated profile, result subtype, or calling-convention
state. `protected`, `function`, `return`, and the basic formal-part delimiters
are structural syntax only in this boundary.
For `in`, the domain after an explicit subtype indication must be a staged
iterator name in both delimiter forms; a bracket aggregate does not reinterpret
an explicit-range domain as a container loop-parameter specification once the
colon has selected `iterator_specification` syntax. `reverse` and an iterator
filter remain available after the corresponding iterator name.

The obsolescent `delta_constraint` is intentionally outside Adac's default
language subset. Recursive access-to-subprogram profiles, including
access-to-function results, are staged under the explicit profile-nesting
contract in `resource-limits.md`.

A bracket iterated association may also stage Ada 2022's optional
`use key_expression` after an eligible loop-parameter specification or iterator
specification, including after an iterator filter. The key expression uses the
existing bounded expression parser without claiming a key type. A bracket `in`
form is eligible only when its single domain can be staged as a discrete subtype
definition; a choice list or general choice expression is not reinterpreted as a
container loop parameter merely because `use` follows. Parenthesized aggregates
do not accept an iterator key.

The iterator defining identifier and staged formal defining identifiers are
validated but are not interned because expression staging creates no binding,
scope, or entity. Ordinary names in an iteration subtype mark, formal parameter
subtype mark, default expression or aspect definition, access subtype mark,
function result subtype mark, function result access subtype mark, domain,
filter condition, key expression, and value keep the existing name-parser
symbol-publication rules. Formal aspect-mark identifiers do not publish symbols.
The colon, `aliased`, parameter-mode tokens, `not null`, `:=`, `with`, aspect
arrows and marks, `access`, `constant`, `protected`, `procedure`, `function`,
`return`, formal-part delimiters, `use`, either staged `reverse` modifier, and
the `when` token change only structure and do not create iterator or aspect
state.

The obsolescent `delta_constraint` and specialized
`global_aspect_definition` syntax remain outside this slice. The latter belongs
to later general declaration-aspect staging. Allocators, `case` expressions, quantified expressions, and broader
conditional-expression forms likewise remain outside the current subset.
Parenthesized suffixes that are already part of the name-staging contract remain
usable inside an ordinary name primary; the loop-parameter subtype-mark boundary
may stop before a left parenthesis so composite-constraint staging can own it.

## Name Reuse And Symbol Ownership

The expression parser does not duplicate name parsing. A name primary is
consumed through the name parser defined by `frontend-names.md`, including its
selector, attribute, explicit-dereference, parenthesized-suffix, validation, and
symbol-publication rules.

A caller may request represented expression syntax. Current name primaries reuse
the published-name subset from `frontend-names.md`; numeric and string primaries
may publish their literal nodes; and current represented binary-adding simple
expressions may publish a `Binary_Adding_Node` chain. When the complete expression
is exactly one published name primary and the caller requests ordinary completion,
expression staging returns its AST node without consuming the caller-owned
terminator or publishing an unsupported-expression diagnostic. The production
constant-object declaration uses this result mode.

A structural-completion caller may request represented syntax while the
enclosing statement remains unrepresented. Publishable names and literals are
appended as bounded AST subtrees. Current parenthesized if expressions publish an `If_Expression_Node` plus its
`Parenthesized_Expression_Node` wrapper. Current `not` factors publish
`Unary_Operator_Node` values, represented multiplying terms publish left-associated
`Binary_Multiplying_Node` values, represented binary-adding chains publish
left-associated `Binary_Adding_Node` values, and a current represented binary
relation publishes a `Relation_Node` after both operands exist. The nested production `if`
condition
uses this mode for `message'length = 0`; its two branch calls use the same mode
for `prefix & name` and `prefix & name & ": " & message` before call statements
themselves are represented.

Expression staging also accepts a caller-owned terminator and a structural-
completion mode. The parser consumes only expression tokens and requires the
selected terminator to be current when the expression is complete; it never
consumes that outer token. Return expressions retain `Tok_Semicolon` and their
existing unsupported-expression behavior. Object initializers also retain the
semicolon boundary; the bounded scalar-integration declaration caller allows a
complete numeric literal to return represented syntax for later semantic
expected-type checking. The bounded scalar-assignment caller likewise allows a
complete numeric literal, identifier-starting represented current name, exact
represented unary-`not` factor, exact represented `Relation_Node`, complete
represented `Binary_Multiplying_Node` term, or complete represented
`Binary_Adding_Node` root to return syntax. The unary and relation paths are
caller-opted: they preserve only the existing `Unary_Operator_Node` for Ada 2022
AARM 4.4 `not primary` and an already represented exact relation, without
widening `abs`, unary adding, logical-expression roots, or other caller
completion. The multiplying path preserves left-associated `*`, `/`, `mod`, and
`rem`; the binary-adding path preserves the existing left-associated `+`, `-`,
and `&` source shape. Numeric/Boolean typing, relational overload resolution,
fixed-point rules, array concatenation legality, and overload selection remain
semantic work. Semantic
analysis narrows the direct-name form to a supported
local read; other broader initializer and assignment expressions retain their
existing support boundaries. The current `if` statement condition uses
`Tok_Then`.

A procedure-call actual expression may additionally return with `Tok_Comma`
current while its required terminator remains `Tok_Right_Parenthesis`. This
comma-before-terminator mode is used only by the call parser's iterative
association list; for a named association the call parser consumes the selector
and `=>` before entering this expression path. Nested commas continue to be owned
by the expression forms that contain them. Structural completion may return a
represented current expression node, and the caller owns both the comma and
right-parenthesis delimiters.

The current parenthesized-name source-form publisher also retains a bounded
multi-actual shape without classifying the prefix as a call, indexed component,
or type conversion. Each item owns independent publication state. A current name
item remains accepted as before; a direct numeric literal or string literal and
a selected binary-adding item may additionally be retained as one actual, and an
already completed parenthesized name may prefix an attribute reference. This
keeps production `Character'Val (16#27#)` as syntax-only attribute-prefix plus
based-integer actual ownership rather than evaluating `Val`. Nested parenthesized
suffix frames save and restore the
pending binary state, so an inner actual such as `Content'First + Offset` cannot
leak into a following outer actual such as `Content'Length - Offset`. The
production `OS.Write(File, Content(Content'First + Offset)'Address,
Content'Length - Offset)` therefore preserves three ordered actuals as syntax.
The selected binary-actual subset may retain one earlier represented
`Parenthesized_Name_Node` operand when that nested name graph itself owns only
current-name or literal actuals. Construction preflight walks that nested prefix,
selectors, and actuals iteratively and rejects an expression actual below the
nested name, so the type-level name/expression ownership cycle cannot become
source-controlled validator recursion. This carries production syntax such as
`Positive (Natural (local_objects.length) + 1)` without classifying either
parenthesized suffix as a call or conversion. Attribute meaning, call resolution,
indexing, conversion, and expected-type semantics remain later work.

Structural completion is not expression-language support. It may publish only
caller-requested represented syntax. The current enclosing expression forms are
limited to the selected parenthesized if expression, represented `not` factors,
represented binary-multiplying terms, represented binary-adding chains, and
current represented binary relations; other staged operator shapes remain
unrepresented. Malformed expression syntax
retains the same expression-owned diagnostics, and a missing non-semicolon
terminator uses the ordinary expected-token diagnostic at that boundary. The
statement parser does not duplicate precedence, name parsing, operator parsing,
nesting accounting, or diagnostic
precedence. Procedure-call staging likewise delegates each actual expression
to this boundary instead of treating operator-bearing actual text as a generic
parenthesized name.

A represented concatenation or binary relation still receives the existing
unsupported operator-expression diagnostic when the caller requests rejection
rather than structural completion. Independent name operands retain independent
publication state: a parenthesized or attributed name in one relation operand does
not disable the same bounded name form in a later short-circuit operand. This is
required by production conditions that repeat `self.nodes (...).kind` and then
use that selected component inside another parenthesized name. AST publication
therefore does not widen the accepted language subset or bypass an owning
declaration or statement boundary.

When a name is the only primary, the existing name-specific unsupported
diagnostic remains authoritative. A name followed by the qualified-expression
apostrophe boundary remains interned component by component before its operand
is parsed. The parser retains that node across the apostrophe only for syntax
publication; an identifier/selected qualifier plus the represented named record
aggregate or selected direct operand returns `Qualified_Expression_Node`. Other
qualified forms retain the qualified-expression or qualified-aggregate support
diagnostic. A malformed name
still fails at the name parser boundary before an expression diagnostic can be
published.

The current conditional-expression boundary distinguishes structurally valid but
unrepresented forms from malformed syntax. An `elsif` continuation, an omitted
`else`, or an unrepresented current child reports an ordinary support diagnostic
before either conditional parent is published:

```text
conditional expression with elsif is not supported
conditional expression without else is not supported
conditional expression then expression is not supported
```

Malformed delimiters or missing required current-subset tokens retain the normal
expected-token diagnostics. Child nodes already appended before rejection remain
private to the rejected compilation context.

## Diagnostics And Stage Boundary

A structurally valid staged operator, membership, or short-circuit expression
receives one diagnostic at its first token when its caller requires unsupported
expression rejection. This includes a represented binary relation:

```text
operator expressions are not supported: Item not in 1 .. 10 | Other
operator expressions are not supported: Ready and then Valid
```

Diagnostic text preserves source token spelling and case but normalizes spacing
around staged operators, control words, range delimiters, and membership-choice
separators. Source whitespace is not retained.

A single staged primary keeps its existing unsupported literal or name diagnostic
unless it belongs to a represented publication subset. A standalone represented
numeric primary returns its existing `Numeric_Literal_Node`, and a standalone
`null` primary returns its `Null_Literal_Node`, when syntax publication is
requested. Staging-only callers may still consume those tokens and retain their
caller-owned unsupported-expression behavior; representation does not widen those
ownership boundaries or claim semantic typing.

A structurally valid parenthesized simple expression such as `(Alpha)` is now
represented. A parenthesized form whose complete inner expression is still
outside the represented subset retains the corresponding operator/expression
support diagnostic rather than publishing a partial wrapper.

If an operator occurs inside or outside the parentheses, the operator-expression
diagnostic remains authoritative for the complete staged expression.

A structurally valid qualified expression containing no operator receives:

```text
qualified expressions are not supported: Types.Index'Base'(Value)
```

The operator-expression diagnostic remains authoritative when an operator occurs
inside the qualified operand or elsewhere in the complete staged expression.
The qualified-expression diagnostic otherwise takes precedence over a
parenthesized or name-specific diagnostic when qualification occurs inside a
larger parenthesized primary.

Classic aggregates outside the represented named-record subset retain the
existing unsupported forms:

```text
aggregate expressions are not supported: (Left => Alpha, others => <>)
qualified aggregate expressions are not supported: Types.Vector'(Alpha, Beta)
```

An unqualified aggregate made only of represented `identifier => value`
associations returns `Record_Aggregate_Node` instead of this diagnostic when the
caller requests syntax publication. The same aggregate preceded by an
identifier/selected subtype mark and apostrophe returns `Qualified_Expression_Node`;
for example `Pair'(Left => Alpha, Right => Beta)` owns `Pair` and the aggregate as
distinct earlier children. Positional qualified aggregates such as the example
above remain unsupported.

Operator-expression diagnostics retain priority when an aggregate component
contains an operator. Outside the represented qualified-record subset, a
qualified-aggregate diagnostic has priority over the ordinary aggregate and
qualified-expression diagnostics.

Structurally valid staged delta aggregates receive one of these forms:

```text
delta aggregate expressions are not supported: (Old with delta X => New_X)
qualified delta aggregate expressions are not supported: T'(A with delta X => Y)
```

Operator-expression diagnostics retain priority over delta-aggregate diagnostics
when the base expression, a choice, or a component value contains an operator.

Structurally valid bracket aggregates receive one of these forms:

```text
bracket aggregate expressions are not supported: [Alpha, Beta]
qualified bracket aggregate expressions are not supported: T'[Alpha, Beta]
bracket delta aggregate expressions are not supported: [Old with delta 1 => New]
qualified bracket delta aggregate expressions are not supported: T'[...]
```

The bracket diagnostics intentionally do not classify an ordinary bracket form
as an array or container aggregate. Operator-expression diagnostics retain the
same highest priority when an operator occurs anywhere in a bracket aggregate.

Malformed expression structure is an ordinary syntax error, not an unsupported
feature. A `not` following a completed simple expression requires `in`. Once an
`and then` or `or else` chain is selected, later connectors in that chain must
keep the same form. A missing membership choice after `in` or `|`, or an empty
parenthesized expression, an empty qualified operand, or a missing aggregate
component value reports the existing `expected expression primary` diagnostic.
A missing closing parenthesis for a general expression, aggregate, or qualified
operand uses the existing `expected TOK_RIGHT_PARENTHESIS` diagnostic. A
positional association after a named association is rejected as malformed
aggregate structure, and an `others` association must be last. A `range`
constraint in an aggregate choice requires a staged subtype-mark name on its
left. A constrained choice without `..` or a `Range` attribute reports the
missing range delimiter as syntax. A staged delta association must include a
choice list and `=>`; positional associations are rejected. `others` choices and
box component values are rejected before unsupported-feature publication. A
bracket aggregate rejects a named association following a positional one, and a
`with` in a bracket primary requires `delta`. `others` remains final. An
iterated association requires an identifier after `for`, then either `in` with
a nonempty staged choice list, a filter-bearing `in` with one staged domain
appropriate to the delimiter, `in reverse` with a delimiter-appropriate staged
domain, or `of` with an optional `reverse` followed by a staged iterable name.
The `in reverse`
and `of` forms may have an optional `when` filter. The association then requires
`=>` and an expression value. A parenthesized filter-bearing `in` accepts only a
staged name, while a bracket form also accepts the current constrained-subtype
and explicit-range staging. A vertical-bar choice list cannot be followed by a
filter, and a parenthesized constrained subtype or explicit range cannot be
filtered. In those cases `when` remains at the normal expected-arrow boundary.
A colon after the defining identifier requires a staged loop-parameter subtype
indication and selects iterator-specification syntax. The current indication is
an optional `not null` followed by a subtype-mark name and optional `range`
constraint; `access` with optional `constant` and an access subtype-mark name;
`access` with optional `protected` and `procedure`; or `access` with optional
`protected` and `function`, followed by `return` and a staged result. Each
staged subprogram kind may be parameterless or have one basic formal part using
the `staged_formal_parameter_mode` form defined above. A function result may be
a subtype mark or any staged `access_definition`, including a recursively
staged access-to-function result. `not` without the required `null`,
a null exclusion without a following subtype or access definition, `access`
with no subtype mark in its object form, or `access protected` without
`procedure` or `function` is a
syntax error. A function form requires `return` and a staged result. An
access-to-object result requires its access subtype mark. A result
`access protected` requires `procedure` or `function`. A staged basic formal
part requires one or more semicolon-separated parameter specifications. Each
specification requires a nonempty comma-separated defining-identifier list, a
colon, and either a subtype-mark or staged access parameter definition. The
subtype-mark alternative accepts optional `aliased`, one staged parameter mode,
an optional `not null`, and one subtype-mark name. The staged access alternative
accepts object, procedure, and function access definitions;
including recursively staged basic formal parts and function results. `aliased`
and explicit mode tokens are not part of an access definition. All current forms
may be followed by `:=` and one expression, then by one optional parameter
aspect specification. An aspect specification requires `with` and one or more
comma-separated aspect marks. Each mark requires an identifier, optionally
followed by the exact case-insensitive designator `'Class`; an optional `=>`
requires a following staged expression. Specialized `global_aspect_definition`
syntax and implementation-defined non-expression definitions remain outside
this formal-parameter boundary. Aspect identifiers are structural and are not
reinterpreted as ordinary names. An
initial `not null` selects an access alternative when followed by `access`;
otherwise it remains the implicit-`in` subtype-mark form. A syntactic default is
staged independently of later legality checks. A missing identifier after a
comma, parameter specification after a semicolon, `null` after parameter `not`,
subtype mark after access-object `access` or `constant`, or expression after
`:=` is syntax. A missing aspect mark after `with` or an aspect comma, a
non-`Class` designator after an aspect-mark apostrophe, or a missing aspect
definition after `=>` is syntax. `access protected` requires `procedure` or
`function` at this formal boundary. An explicit mode before `access` remains
syntax.
A `digits` constraint requires an expression
and may be followed by the staged `range` form. At this
iterator-specification boundary, top-level membership is not consumed as part of
the digits operand, so `in` remains available as the iterator delimiter. A
composite constraint requires one or more comma-separated items belonging to a
single syntactic constraint structure. A staged index item is a subtype-mark
name with an optional `range` constraint, a bare `Range` attribute, or an
explicit range. A discriminant item is a positional expression or a named
association. Bare subtype-mark and `Range`-attribute items remain ambiguous
until semantic resolution. An explicit range or constrained subtype-mark item
selects index syntax; a non-subtype general expression or named
association selects discriminant syntax. Mixing exclusive forms from the two
structures is syntax.
Within discriminant syntax, once a named association is seen, a later positional
association is syntax. A selector candidate followed by `|` or `=>` must be a
single `selector_name`; a selected component, attribute, parenthesized name, or
operator expression is not reinterpreted as a selector. Selector identifiers
retain ordinary symbol publication, while character-literal and operator-symbol
selectors do not create identifier symbols. An empty constraint, trailing comma,
missing selector after `|`, missing `=>` after a selector list, or missing named
association expression is syntax. A `range` following a non-subtype expression
reports that a range constraint requires a subtype mark. A consumed staged range
must contain a valid range; an explicit lower bound without `..` reports the
missing range delimiter as syntax. A range
constraint is not accepted after an access definition. The token following the
completed subtype indication must be `in` or `of`. After a function `return`,
all staged access definitions are accepted recursively under the profile-
nesting budget. An explicit subtype indication on an `in` form requires an
iterator name even in a bracket
aggregate, so an explicit range domain there is rejected as malformed
iterator-specification structure rather than being accepted as a container
loop-parameter specification. The obsolescent `delta_constraint` and specialized
`global_aspect_definition` syntax remain outside this staging subset.
In a bracket aggregate, `use key_expression` is accepted only after an eligible
single loop-parameter specification or iterator specification and any iterator
filter. A missing key expression is syntax. `use` after a parenthesized
iterator, a choice list, or a general choice-expression `in` domain remains at
the normal
expected-arrow boundary rather than changing the selected grammar form.
A missing reversed domain and a missing name after `of reverse` are syntax. Any
consumed filter with no condition before `=>` is also syntax. A box value is
rejected, and an iterated association cannot follow a positional association.
An apostrophe followed by an identifier, `Range`, `Digits`, or `Delta` remains
an attribute suffix rather than a qualification boundary. Extra tokens
that cannot belong to the selected grammar form use the existing expression-end
boundary.

Every rejection occurs before publishing a return-statement node,
compilation-unit root, semantic entity, IR object, or backend output.

## Resource And Complexity Contract

The staging parser retains the fixed precedence call structure for each active
expression. Source-controlled operator, short-circuit, and membership-choice
chains are consumed by loops. A membership choice may enter one fixed
`choice_expression` level whose relation does not accept another membership
test.

A parenthesized expression, parenthesized or bracket aggregate, or qualified
operand enters the same expression parser only after reserving one level from
the compilation context's expression-nesting budget. The default limit is 32
and the supported policy type has a hard upper bound of 64. The parser checks
the budget before consuming the opening delimiter or making a recursive
component parse, so adversarial nesting cannot grow the process stack beyond
the documented bound. Aggregate association counts are consumed by loops; only
nested expression primaries consume nesting depth. The resource contract is
defined in `resource-limits.md`.

Parsing work is linear in the number of consumed tokens. Diagnostic text is
bounded by the existing per-file source-character budget. Name symbol
publication remains bounded by the context-owned symbol budget. The staging
parser allocates no operator stack, expression tree, aggregate association list,
membership-choice list, iterated-association list, or unbounded auxiliary index.
The defining identifier of a staged iterated association is retained only in the
bounded diagnostic text and does not consume the symbol budget. An iterator
filter or container key expression invokes one existing bounded expression
parse. A loop-parameter range constraint reuses the existing staged-range parser
and its bounded simple-expression calls. A digits constraint reuses the existing
expression precedence calls with top-level membership disabled and optionally
reuses the staged-range parser. It adds no scanner rewind, token buffer, or
backtracking state. A staged composite constraint consumes its nonempty
association sequence iteratively. Each item starts with one bounded simple-
expression parse. An explicit `..` range or a bare subtype-mark followed by
`range` reuses the staged-range parser and selects index syntax. A non-subtype
general expression selects discriminant syntax. When `|` or `=>` follows a
single selector-name primary, the parser continues as a named discriminant
association. Selector lists are also consumed iteratively, and the associated
value reuses one bounded expression parse. Two parser-local enum values retain
only the current item's syntactic form and the selected composite structure; one
Boolean enforces positional-before-named ordering within discriminant syntax. A
direct-name counter and existing primary counters distinguish ambiguous bare
forms without scanner rewind or backtracking. The association and selector loops
allocate no constraint list, add no recursive nesting, and perform no semantic
constraint classification. Their counts remain bounded by the source-character
budget. An access-to-object loop-parameter
definition reuses one existing name parse. Access-to-subprogram definitions
reuse one bounded profile parser for both procedure and function profiles. A
staged basic formal part consumes its nonempty parameter-specification sequence
iteratively. Each specification validates a nonempty defining-identifier list
and selects one of two bounded paths. The subtype-mark path consumes at most one
`aliased` token, two parameter-mode tokens, one fixed two-token null exclusion,
and one name. The access-definition path consumes one staged object or
access-to-subprogram definition. An optional default reuses one existing bounded
expression parse.
The identifier and specification loops allocate no parameter or identifier
list; their counts remain bounded by the source-character budget. Nested default
expressions use the existing context-owned expression-nesting budget.
A parameter aspect specification consumes its nonempty aspect-mark sequence
iteratively without allocating an aspect list. Each staged explicit aspect
definition reuses one existing bounded expression parse. Aspect-mark count is
bounded by the source-character budget, while nested aspect-definition
expressions use the
existing expression-nesting budget. No aspect state or auxiliary aspect stack is
allocated.

Every staged access-to-subprogram profile enters through the context-owned
profile-nesting budget before its `procedure` or `function` keyword is consumed.
Parameterless profiles consume one level, so an access-to-function result cannot
bypass the bound by omitting a formal part. The profile counter is parser-local
and is released after both successful and ordinarily rejected nested parsing.
Expression and profile nesting can interleave, but each has an independent hard
supported maximum, so their simultaneous recursive contribution is bounded by
the sum of those hard limits. No form allocates an auxiliary profile stack.

## Tests

Tests shall cover:

- a valid staged expression spanning unary, exponentiation, multiplying,
  adding, relational, logical, `abs`, and `not` operators;
- represented binary relations for all six Ada relational-operator spellings,
  preserving the exact spelling while leaving typing and overload resolution
  to semantic analysis;
- the production-shaped parenthesized `if ... then ... else ...` expression,
  preserving condition/dependent-expression order and both parenthesis boundaries;
- rejection of `elsif`, missing-else, and unrepresented dependent-expression
  forms without publishing a partial conditional or wrapper parent;
- represented `not` over a current name primary, preserving exact operator
  spelling/span and returning the unary node to a represented-expression caller;
- represented unary adding over a current term, including composition with a
  following binary-adding chain, represented `abs`/`not` over a current primary,
  and represented `primary ** primary` factor syntax;
- `in` and `not in` membership tests;
- an explicit-range membership choice preserving both character-literal bounds
  and the exact `..` delimiter, including composition under `or else`, plus
  multiple `|` membership choices;
- case-insensitive `and then` and `or else` with exact spelling preservation;
- a repeated short-circuit chain using one consistent control form, including
  independent repeated parenthesized-name operands and a nested selected-component
  parenthesized item without cross-name publication-state leakage;
- a production-shaped multi-actual parenthesized name with a nested
  parenthesized-name attribute prefix and independent binary-adding actuals, plus
  construction-time rejection of a binary actual that would reintroduce recursive
  parenthesized-name ownership;
- standalone and deeply nested represented parenthesized expressions, including
  unary `not`, relation, and represented short-circuit children, with nested
  relation/short-circuit capture state isolated and no validator call-stack growth;
- broader nested parenthesized operators that remain outside the represented
  inner-expression subset;
- parenthesized grouping of a logical chain and exponentiation;
- rejection of an empty or unterminated parenthesized expression;
- controlled rejection before exceeding the expression-nesting budget;
- a qualified expression with a selected and attributed subtype-mark spelling;
- operator-expression priority when an operator occurs in a qualified operand;
- rejection of an empty or unterminated qualified-expression operand;
- qualified-expression participation in the expression-nesting budget;
- unchanged attribute parsing when an apostrophe is followed by an identifier;
- positional, named, `others`, box, `null record`, and extension aggregate
  forms;
- qualified classic aggregates with exact subtype-mark spelling preservation;
- named array choices using a subtype-mark range constraint with explicit bounds
  and a `Range` attribute reference;
- rejection of a range constraint whose left side is not a staged subtype mark;
- rejection of a constrained subtype choice missing its range delimiter;
- rejection of a missing aggregate value, positional-after-named structure,
  and a nonfinal `others` association;
- parenthesized record-or-array delta aggregate staging and qualification;
- rejection of positional, `others`, and box forms in a staged delta aggregate;
- null, positional, named, `others`, and box bracket aggregate forms without a
  premature array-or-container type classification;
- bracketed array-delta staging and qualification;
- rejection of named-after-positional bracket structure and non-delta `with`;
- basic `in` iterated associations in parenthesized and bracket aggregate
  lists;
- basic `of` iterator-specification associations in parenthesized and bracket
  aggregate lists;
- `of reverse` iterator specifications with exact modifier spelling;
- `of` iterator filters in parenthesized and bracket aggregates, including a
  `reverse` form;
- rejection of a missing `of` filter condition and operator-expression priority
  inside an `of` filter;
- `in` iterator filters after a parenthesized name and a bracket discrete range,
  including a `reverse` form and operator-expression diagnostic priority;
- `in reverse` iterator-name staging in parenthesized and bracket aggregates;
- bracket `in reverse` discrete-range staging without a semantic subtype claim;
- choice-list iteration domains and operator-expression diagnostic priority;
- rejection of an `in` filter after a choice list or parenthesized range, and of
  a missing `in` filter condition;
- bare, null-excluding, range-constrained, access-to-object, and parameterless
  access-to-procedure and access-to-function loop-parameter subtype indications
  on both `in` and `of` iterator specifications;
- composition of an access-to-object indication with `not null` or `constant`,
  and access-to-procedure and access-to-function indications with `not null`,
  `protected`, subtype-mark and access-to-object results, and
  access-to-procedure and access-to-function results;
- one or multiple basic parameter specifications using the current subtype-mark
  form or a staged access definition, including optional `aliased`, all current
  modes, null exclusion, `constant`, and `protected` where their respective
  grammar alternatives permit them;
- recursive access-to-procedure and access-to-function formal parameters,
  including a nested basic formal part and an access-to-function result;
- controlled rejection before exceeding the profile-nesting budget, including
  parameterless profiles and recursive function results;
- default expressions on all current parameter-definition forms, including
  termination at both a semicolon and the formal-part right parenthesis;
- no symbol publication for staged formal defining identifiers while subtype-
  mark and default-expression names retain ordinary name publication;
- parameter aspect specifications on subtype-mark and access parameter forms,
  including a default, multiple marks, a bare mark, and mixed-case `'Class`;
- no symbol publication for aspect-mark identifiers or the `Class` designator,
  while names in explicit aspect definitions retain ordinary publication;
- rejection of a non-`Class` aspect designator, a missing aspect definition,
  and an unstaged specialized global aspect definition;
- composition of an explicit subtype indication with `reverse` and an iterator
  filter, while preserving operator-expression diagnostic priority;
- operator-expression diagnostic priority when an operator occurs in a staged
  loop-parameter range constraint;
- digits constraints with and without an optional range on iterator
  specifications, including preservation of the following `in` delimiter;
- operator-expression diagnostic priority inside a staged digits operand;
- rejection of a missing digits operand and a malformed optional digits range;
- single and comma-separated explicit ranges, constrained discrete subtype
  indications, and ambiguous bare subtype-mark items in index constraints;
- single and multiple-selector named discriminant associations, including a
  positional association followed by a named association;
- ordinary name symbol publication across composite-constraint items, range
  bounds, constrained discrete subtype marks, and identifier discriminant
  selectors, with unchanged parenthesized-name parsing outside the subtype-
  indication boundary;
- rejection of syntactically exclusive index items mixed with discriminant
  associations in either order;
- rejection of an empty composite constraint, a trailing comma, a missing
  explicit-range or constrained-subtype range bound, a positional discriminant
  association after a named association, a range constraint after a non-subtype
  expression, and a non-selector expression before a named-association arrow;
- rejection of a missing selector in a named selector list, a missing named
  arrow, and a missing named-association expression;
- rejection of a missing `null` after a subtype-indication `not`, a missing
  subtype mark after `not null` or `access constant`, `access protected` without
  a subprogram kind, a missing function `return`, result subtype mark, or
  access-result subtype mark, result `access protected` without a subprogram
  kind, malformed basic formal parts including a missing defining identifier
  comma, a missing parameter specification after a semicolon, or a missing
  `null` after parameter `not`, a missing subtype mark after `aliased`, any
  explicit parameter mode, `access`, or `constant`, an explicit mode before an
  access parameter definition, `access protected` without a subprogram kind at
  the formal boundary, a missing function `return`, or a missing default
  expression after `:=`, a range constraint after an access definition, a
  missing range delimiter in a
  range delimiter in a
  loop-parameter range constraint, and an explicit-range `in` domain after a
  subtype indication;
- bracket container `use key_expression` staging after eligible `in` and `of`
  forms, including composition with `reverse` and an iterator filter;
- operator-expression diagnostic priority and ordinary name publication inside
  a staged key expression;
- rejection of a missing key expression, parenthesized iterator keys, and keys
  following a choice list or general choice-expression `in` domain;
- rejection of a parenthesized non-name `in reverse` domain and of a choice list
  following `in reverse`;
- rejection of malformed iterated identifiers, domains, iterable names, arrows,
  box values, and iterated associations following positional associations;
- rejection of missing domains after `in reverse` and `of reverse`;
- no symbol publication for the defining identifier of an iterated association,
  while names in an iterator filter or key expression retain ordinary symbol
  publication;
- operator-expression priority inside classic, delta, and bracket aggregates;
- parenthesized and bracket aggregate nesting through the expression-nesting
  budget;
- rejection of a `not` membership prefix without a following `in`;
- rejection of a mixed short-circuit and ordinary logical chain;
- rejection of a missing membership choice as syntax;
- exact staged-token spelling and normalized diagnostic spacing;
- reuse of name symbol publication inside staged expressions;
- rejection of a missing operand as syntax rather than unsupported syntax;
- rejection of repeated exponentiation without parentheses;
- rejection of multiple relational operators without parentheses;
- rejection of mixed unparenthesized logical operator kinds;
- publication and validation of standalone numeric and `null` literals with
  preserved numeric form/spelling or exact null span and no semantic typing;
- no AST or semantic publication after expression rejection;
- unchanged diagnostics for staging-only single literals and names.
