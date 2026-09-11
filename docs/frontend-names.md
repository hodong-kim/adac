# Frontend Names

This document defines the initial name-parsing contract for the Adac frontend.
It covers identifier direct names, selected components with the current
selector-name forms, explicit dereferences, parenthesized name suffixes, the
current explicit-range slice subset, and identifier/`Range`/`Delta` attribute
designators. It does not claim semantic name resolution or slice evaluation.

## Supported Grammar

The current subset uses this staging grammar:

```text
parsed_name ::= identifier { name_suffix }

name_suffix ::= . selector_name
              | . all
              | ' attribute_designator
              | ( parenthesized_content )

attribute_designator ::= identifier | Range | Delta
selector_name        ::= identifier | character_literal | operator_symbol
```

`parenthesized_content` is a frontend staging form rather than an Ada grammar
production. It recognizes a nonempty, balanced sequence built from the current
valid name and literal tokens, nested parentheses, comma separators, double-dot
delimiters, and arrows. A double dot or arrow requires a completed staged item on its left and another
staged item on its right. Outside the selected explicit-range slice below, the
parser does not distinguish an indexed component, function call, type conversion,
range, or named association because those classifications depend on expression
parsing and semantic information. Binary adding tokens inside the selected slice
bounds are retained only when they form represented current simple expressions.

When a caller explicitly requests current name syntax, the parser can publish a
narrower AST subset while consuming this same grammar:

```text
published_name ::= published_simple_name
                   [ { published_parenthesized_suffix
                       { published_selected_component_suffix } }
                     | published_identifier_attribute_suffix ]

published_simple_name ::= identifier {. identifier}

published_explicit_dereference_suffix ::= . all

published_parenthesized_suffix ::=
  ( published_parenthesized_item {, published_parenthesized_item} )

published_parenthesized_item ::= published_name_item
                               | numeric_literal
                               | character_literal
                               | published_named_actual

published_named_actual ::= identifier => published_name_item

published_selected_component_suffix ::= . identifier

published_identifier_attribute_suffix ::= ' identifier

published_name_item ::= published_simple_name
                        [ published_explicit_dereference_suffix ]
                        [ published_identifier_attribute_suffix ]
                      | published_parenthesized_suffix
                        { published_selected_component_suffix }
```

The first parser publication path for an explicit-dereference suffix is a
`published_name_item` inside a represented parenthesized name. It publishes one
`Explicit_Dereference_Name_Node` owning the earlier current-name prefix, exact
`all` token span, and whole `name.all` span. This preserves production forms such
as `OS.Spawn(compiler_path.all, arguments)` while deferring the AARM 4.1 access-
type expectation, designated-entity lookup, null check, evaluation semantics, and
classification of the enclosing parenthesized name. Standalone/top-level `.all`
forms retain the existing controlled unsupported diagnostic for this slice even
though the raw/context AST construction API can represent an explicit dereference
from an earlier current-name prefix.

The parenthesized node preserves the syntactic ambiguity of forms such as
`Ada.Exceptions.exception_name(error)`. It does not claim a function call,
indexed component, or type conversion. A current named actual association stores
its selector as an owned identifier-name child and its actual through the same
bounded item path as positional source. Positional actuals may precede named
associations, but once a named association is published a later positional item
is rejected; formal/actual binding and overload resolution remain semantic work.
The identifier-attribute node preserves
forms such as `message'length` as prefix syntax plus the exact designator symbol
and span; it does not decide whether that attribute is defined for the prefix.
The semantic range-bound evaluator may interpret a direct supported integer
subtype prefix or the exact expanded `Standard.Integer`/`Natural`/`Positive`
forms with the identifier designator `First` or `Last`; this is a narrow consumer
of the unchanged syntax node, not general attribute semantics.
A published parenthesized name may be followed by one or more identifier
selectors, and either the parenthesized name itself or the resulting selected-
component chain may in turn be the prefix of another parenthesized suffix. Each
such suffix publishes another `Parenthesized_Name_Node`, preserving recursive
Ada 2022 AARM 4.1 `name`/`prefix` syntax without choosing indexed-component,
function-call, or type-conversion semantics. The first identifier selector is
represented as a selected-component node whose prefix is the earlier
parenthesized name; further identifier selectors may use the preceding selected-
component node as their prefix. The semantic subtype layer may interpret exactly the two-component selected names
`Standard.Integer`, `Standard.Natural`, and `Standard.Positive` as expanded names
for the current predefined integer subtypes. That consumer requires a direct
identifier prefix naming package `Standard` and does not generalize selected-name
syntax into package visibility or arbitrary selector resolution.

The same bounded form may appear as one item of
an enclosing parenthesized name, so
`Check (self.nodes (Index).kind)` preserves the inner selected component rather
than disabling publication for the outer name. A simple-name item may also carry
one current argument-free identifier attribute suffix, preserving forms such as
`Count_Type (Positive'Last)` as one parenthesized name with an
`Attribute_Name_Node` item. Nested parenthesized suffixes still enter the existing expression-nesting
budget. Repeated outer suffixes are sequential and therefore require no extra
simultaneously active nesting frame. A current identifier `Attribute_Name_Node`
may prefix a following parenthesized suffix, preserving forms such as
`T'Image(value)` as two ordered syntax nodes without deciding whether the
parentheses belong to an attribute-designator argument or a call/index/conversion-
shaped continuation. Attribute suffixes after that parenthesized form and
reserved or otherwise unrepresented attribute designators retain their existing
staging-only boundaries. This remains distinct from the identifier-only selected-
name chain used where a simple name is required.

A valid numeric literal in an ordinary parenthesized item position may publish the
existing `Numeric_Literal_Node`. This preserves production syntax such as
`Character'Val (16#27#)` as an attribute-name prefix followed by one ambiguous
`Parenthesized_Name_Node` containing the exact based-integer literal. The parser
does not evaluate the attribute, assign an expected integer type, or decide
whether the parenthesized suffix belongs to the attribute designator or another
name interpretation.

A valid character literal in an ordinary parenthesized item position may publish
the existing `Character_Literal_Node`. This preserves attribute-reference forms
such as `Character'Pos ('0')` as an attribute-name prefix followed by one ambiguous
`Parenthesized_Name_Node` containing the exact character literal. The parser does
not evaluate the attribute, assign an expected character type, or classify the
parenthesized suffix as an attribute argument, call, indexed component, or
conversion.

A valid string literal in an ordinary parenthesized item position may publish the
existing `String_Literal_Node`. This preserves forms such as
`Ada.Environment_Variables.Exists ("ADAC_CC")` as an ambiguous
`Parenthesized_Name_Node` with one literal item. Operator-symbol syntax after a
dot retains its existing staged-only path, and the frontend still does not decide
whether the parenthesized suffix denotes a call, indexed component, or conversion.
A string literal may also participate as a leaf of the current parenthesized
binary-adding item, preserving production syntax such as
`Text.Make ("I/O failure: " & output_path)` as one `Binary_Adding_Node` actual.
This remains syntax-only; concatenation typing and callable interpretation are
not assigned here. A parenthesized-name binary item may also use an earlier
`Parenthesized_Name_Node` as an operand when that nested name owns only current
names or literal actuals. The parser and AST keep this as ambiguous name syntax;
an iterative preflight rejects another expression actual beneath the nested name,
so alternating parenthesized-name/expression nesting cannot create validator stack
depth from source input. This covers shapes such as `Positive (Natural
(local_objects.length) + 1)` without classifying either suffix as a call or
conversion.

The current explicit-range slice publication subset is:

```text
represented_slice_name ::= represented_slice_prefix
  ( represented_name_led_bound .. represented_slice_upper_bound )

represented_slice_prefix ::= published_simple_name
                           | published_identifier_attribute_name
represented_name_led_bound ::= published_current_name
  { binary_adding_operator represented_slice_bound_term }
represented_slice_upper_bound ::= represented_slice_bound_term
  { binary_adding_operator represented_slice_bound_term }
represented_slice_bound_term ::= published_current_name | numeric_literal
```

`Slice_Name_Node` owns the prefix, lower bound, exact `..` span, upper bound, and
whole closing-parenthesis span. The first parser slice intentionally requires a
name-led lower bound; numeric-only lower bounds and broader discrete ranges remain
staging-only until their parser contract is selected. Prefix publication is
limited to simple names and identifier attributes, preventing slice/prefix nesting
from creating source-controlled validator recursion. All bounds remain syntax-
only represented expressions.

A one-component `parsed_name` has the direct-name form. Each `. selector_name`
suffix forms another selected component. Character-literal and operator-symbol
selectors retain their exact token spelling. Each `. all` suffix forms an
explicit dereference, and each `' identifier` suffix forms an attribute
reference in the current subset. A parenthesized suffix may be followed by
another supported name suffix. An identifier attribute suffix may likewise be
followed by one current parenthesized suffix. The parser consumes every suffix and nested
parenthesis iteratively, so source-controlled depth does not create recursive
parser-stack growth.

An operator-symbol selector uses the existing `Tok_String_Literal` token. Its
contained sequence must correspond, case-insensitively for word operators, to
one of the operator symbols defined by the current Ada operator categories.
Validation shares the operator-spelling classifier used for direct operator
tokens. A different valid string literal or a malformed string literal in
selector position receives an `invalid operator symbol` diagnostic. General
current-name publication still stops at character-literal or operator-symbol
selectors. The generic-actual parser has one narrower publication path for an
operator symbol that is the terminal selector of an identifier-only selected-name
prefix, preserving forms such as `Ada.Strings.Unbounded."="` as a
`Selected_Name_Node`. Only that path interns the exact quoted operator spelling as
the selector symbol; it does not permit a following selected-name suffix or make
any expanded-name or overload-resolution claim.

The lexer classifies `all` case-insensitively as the reserved-word token
`Tok_All`. In suffix position, `. all` is an explicit dereference rather than a
selected component. When current syntax publication is enabled and the prefix is
represented, the parser publishes `Explicit_Dereference_Name_Node`; diagnostic-
only staging still preserves the source spelling. Neither path resolves whether
the prefix has an access type.

The attribute subset recognizes identifier designators and the reserved `Range`
and `Delta` designators. These reserved designators are not interned as
identifiers. Optional static-expression attribute arguments and the reserved
`Access`, `Digits`, and `Mod` designators remain outside explicit attribute
classification. When a complete staged name is followed by an apostrophe and a
left parenthesis or left bracket, the name parser preserves the apostrophe and
returns that boundary to the expression parser instead of treating it as an
attribute designator. This stages the `subtype_mark'(expression)` and current
`subtype_mark'aggregate` qualified-expression forms defined by
`frontend-expressions.md`. The name parser does not distinguish the operand form
or make a semantic subtype claim.

For the staged loop-parameter `subtype_indication`, the expression parser may
request a subtype-mark boundary that stops before a following left parenthesis.
That parenthesis is then owned by composite-constraint staging rather than by
the generic parenthesized-name-suffix parser. Ordinary name expressions continue
to consume parenthesized suffixes unchanged. This boundary does not make a
semantic subtype, callable-name, index-constraint, or discriminant-constraint
classification.

## Symbol Ownership

Each identifier component outside parenthesized staging content, including an
identifier attribute designator, is validated by the lexer and interned
separately in the symbol store owned by the active
`Adac.Compilation.Context`. The parser does not intern a second spelling for the
complete name. Standard Ada mode therefore applies the existing
case-insensitive canonicalization independently to each component, while the
optional case-sensitive mode preserves its current policy.

Character-literal selectors and diagnostic-only operator-symbol selectors are not
identifiers and are not interned in the symbol store. The narrow terminal
selected-operator generic-actual path is the exception: it interns the exact
quoted operator spelling because `Selected_Name_Node` stores a selector symbol.
The reserved words `all`, `Range`, `Digits`, and `Delta` used in their specialized
name positions are likewise not interned.
Identifiers inside parenthesized content are interned only when that content is
part of the published-name subset requested by the caller. Identifiers in the
broader diagnostic-only parenthesized staging grammar remain validated without
symbol publication. No aggregate symbol is created for a complete name.

The selected exception-name choices in the current production handler also
reuse identifier-selected name parsing with AST publication disabled. Their
components are reference names and are interned normally. The preceding choice
parameter is a defining identifier owned by the exception-handler boundary and
is deliberately not interned until handler scope and binding are represented.

A parse may intern one or more outer components before a later component or
delimiter rejects the source. The append-only symbol store does not roll those
entries back. They remain private to the rejected compilation and are reclaimed
with its context.

## Current Stage Boundary

General expression AST nodes and semantic name resolution are not implemented
yet. The current declaration parser publishes identifier-selected subtype marks
through the same identifier and selected-name node contracts used by expression
names. Its initializer may request the current published-name subset from
expression staging. The nested production `if` condition also requests name
publication so the first `message'length` operand is retained as an
`Attribute_Name_Node` while the surrounding comparison remains staged. None of
these paths assigns subtype, call, index, conversion, attribute, or binding
semantics. Other expression callers retain diagnostic-only name staging.

The current statement path reuses the identifier-selected parser for both
production occurrences of `Ada.Text_IO.put_line`, the outer `Adac.Driver.run`,
the handler-local `report_exception`, and
`Ada.Command_Line.set_exit_status` call prefixes. The two nested `put_line`
calls and the selected outer `Adac.Driver.run;` call request name publication,
so each
callable becomes an identifier-plus-selected-component chain owned by its
procedure-call statement. The selected outer-handler slice also publishes
handler callable names and the six `Ada.IO_Exceptions.*` exception-name choices
as ordinary identifier/selected-name trees. Staging-only handler paths retain
no-publication behavior. None of these paths resolves callable or exception
identity semantically.

When a name participates in a staged operator expression,
`frontend-expressions.md` owns the final unsupported-feature diagnostic while
this contract continues to own name validation and symbol publication. A
complete identifier name used by itself as a return expression receives one
diagnostic in this form:

```text
name expressions are not supported: Alpha.Beta
```

A name containing a parenthesized suffix receives this form:

```text
parenthesized name forms are not supported: Factory(Outer(Inner),Index).Field
```

The diagnostic preserves token spellings and delimiter order. Inter-token
whitespace is not retained in the staged spelling.

A name containing an explicit dereference but no parenthesized suffix receives
this form, even when another name suffix follows it:

```text
explicit dereferences are not supported: Access_Value.ALL.Field
```

A name containing an attribute suffix but neither of the preceding forms
receives this form:

```text
attribute references are not supported: Alpha.Beta'First
```

Diagnostics from diagnostic-only name staging are anchored at the first
component. A caller-requested published name can remain as an unreachable AST
subtree when an enclosing unsupported construct later rejects parsing. The
parse still publishes no successful compilation-unit root, semantic entity, IR,
or backend output.

An empty parenthesized suffix or a misplaced comma, double dot, or arrow
receives an `expected parenthesized name item` diagnostic.
A double dot or arrow without a following item receives the same diagnostic at
the token that violates the item requirement.
Adjacent items without a delimiter receive an `expected parenthesized name
delimiter` diagnostic. A statement terminator or end of file
before the balancing right parenthesis uses the existing
`expected TOK_RIGHT_PARENTHESIS` diagnostic. Invalid identifier, numeric, and
string tokens retain their existing lexical diagnostics.

An invalid identifier component uses the existing `invalid identifier`
diagnostic. A full stop not followed by a valid current selector form uses an
`expected selector name` diagnostic at the offending token. A valid or malformed
string literal that does not form an operator symbol uses `invalid operator
symbol`. A reserved `all` token after a full stop is consumed only as an
explicit dereference. An apostrophe followed by a left parenthesis or left
bracket after a complete staged name is returned to expression staging as a
qualified-expression boundary. When syntax publication is requested, an
apostrophe followed by `Tok_Range` publishes the existing `Attribute_Name_Node`
with the exact reserved-designator span; this supports range-attribute discrete
ranges without adding a second attribute syntax node. `Tok_Digits` and `Tok_Delta`
remain consumed staged-only reserved attribute designators. Other apostrophes not
followed by a current attribute designator keep the
existing `expected TOK_IDENTIFIER` diagnostic.
Symbol-budget exhaustion and source-character exhaustion retain their existing
controlled failure behavior.

## Resource And Complexity Contract

Parsing work is linear in the number of consumed tokens. Parenthesis balance is
tracked by one bounded counter and does not allocate a nesting stack. Name text
retained for the unsupported-feature diagnostic is bounded by the per-file
source-character budget. Distinct identifier publication is bounded by the
context-owned symbol budget.

When AST publication is requested, each identifier, simple selected-name
component, or represented selected component after a parenthesized suffix adds
one bounded AST node, and a parenthesized, current identifier-attribute, or
explicit-range slice suffix adds one node after its prefix and direct children are
validated. A nested
parenthesized item is built bottom-up from earlier child nodes. The outer suffix
needs no nesting frame; each additional simultaneously active nested suffix uses
one explicit parser frame and is bounded by `maximum_expression_nesting`, whose
hard maximum is 64. Construction is linear in published components; selected-
prefix construction does not revalidate the entire prefix chain. Both AST and
context-aware `validate_name` use explicit iterative work queues for nested name
items. AST-node budget exhaustion is a controlled source failure and cannot
publish a partial parent node. No source-controlled recursive name traversal is
introduced.

## Tests

Tests shall cover:

- one identifier direct name;
- a selected-component chain containing multiple identifiers;
- an identifier attribute suffix following a selected prefix;
- case-preserving reserved attribute suffixes, with `Range` published through the
  existing attribute-name symbol path while `Digits` and `Delta` remain staged-only;
- an explicit dereference followed by another selected component;
- case-insensitive recognition and exact spelling of reserved `all`;
- a character-literal selector;
- delimiter and case-insensitive word operator-symbol selectors;
- publication of nested parenthesized current-name items, identifier-attribute
  items, numeric-literal items, character-literal items, string-literal items, a
  bounded nested-parenthesized binary operand, and multiple items;
- controlled rejection when a parenthesized-name binary operand itself owns an
  expression actual, preventing source-controlled alternating name/expression
  validation depth;
- a double-dot range spelling and named-association arrow inside a parenthesized
  suffix without claiming semantic classification;
- unchanged ordinary parenthesized-name staging when subtype-indication parsing
  uses the stop-before-parenthesis boundary;
- publication of a selected-component node following a parenthesized suffix,
  including its prefix, selector symbol/span, full span, and chained-selector
  validation without reclassifying the parenthesized prefix;
- publication of that selected-component form as an item of an enclosing
  parenthesized name, including repeated independent parenthesized names in one
  short-circuit expression without leaking per-name suffix state;
- rejection of an empty parenthesized suffix;
- rejection of a double dot without a following staged item;
- rejection of a missing balancing right parenthesis;
- exact preservation of component, selector, attribute, and staged token
  spelling;
- rejection of a full stop without a following selector name;
- rejection of a valid string literal that is not an operator symbol;
- rejection of a malformed string literal in operator-symbol context;
- rejection of an apostrophe without a following attribute designator;
- qualification-boundary preservation before a left parenthesis or left bracket;
- individual outer-component interning without an aggregate-name symbol;
- no symbol interning for character-literal or diagnostic-only operator-symbol
  selectors, with exact quoted interning only for the represented terminal
  selected-operator generic-actual path;
- no symbol interning for reserved `all` or diagnostic-only parenthesized
  staging content;
- selected callable-prefix identifiers interning with publication only when the
  owning nested procedure-call statement is represented;
- publication of identifier and selected-name nodes for the current declaration
  subtype mark;
- publication of identifier, selected, and parenthesized name nodes for the
  production initializer, including its inner identifier item;
- publication of the production `message'length` operand as an identifier prefix
  plus one identifier-attribute node while the enclosing comparison remains
  staged;
- exact spans, symbols, prefixes, designator span, item order, and context
  ownership for published names;
- controlled AST-node-budget exhaustion before a parenthesized or attribute node
  is published;
- controlled nested parenthesized-name depth exhaustion before another parser
  frame is entered;
- rejection of reserved `all` where an identifier is required;
- no semantic publication after name-form or enclosing declaration rejection;
- unchanged minimal-procedure compilation.
