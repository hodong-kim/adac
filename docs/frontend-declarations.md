# Frontend Declarations

This document defines the current parser-staging boundary for declarations and
declarative parts. It complements `frontend-subprograms.md` and
`frontend-expressions.md` without claiming declaration entities, scopes, types,
initialization semantics, or executable behavior that later compiler stages do
not yet represent.

## Object Declaration Selection

Object declaration staging is selected at caller-owned declarative-part
boundaries. One representative production shape is:

```ada
name : constant String := Ada.Exceptions.exception_name (error);
```

Ada 2022 AARM 3.3.1 defines an `object_declaration` with a
`defining_identifier_list`, optional `constant`, a subtype indication, and an
optional initialization expression. AARM 3.3.2 separately defines a
`number_declaration` whose prefix can be `defining_identifier : constant :=`.
The staging boundary therefore must not diagnose a missing subtype merely
because `:=` follows `constant`.

The production declaration needs one defining identifier, explicit `constant`,
an identifier-selected subtype mark, and a required initializer. This slice
stages only that prefix and delegates the initializer to the existing bounded
expression-staging parser.

## Current Grammar Boundary

The bootstrap-driven represented object declarations are:

```text
represented_variable_object_declaration ::=
  defining_identifier : represented_object_subtype_indication
    [:= represented_object_initializer] ;

represented_constant_object_declaration ::=
  defining_identifier : constant represented_object_subtype_indication
    [:= represented_object_initializer] ;

represented_object_initializer ::=
    represented_current_name
  | represented_numeric_literal
  | represented_unary_adding_expression
  | represented_relation_expression
  | represented_parenthesized_if_expression

represented_object_subtype_indication ::=
  represented_selected_subtype_mark [represented_index_constraint]

represented_selected_subtype_mark ::= identifier {. identifier}

represented_index_constraint ::=
  ( represented_simple_expression .. represented_simple_expression )

represented_number_declaration ::=
  defining_identifier : constant := represented_expression ;
```

`represented_current_name` is the caller-requested published-name subset owned
by `frontend-names.md`; represented numeric literals, unary adding expressions,
current relations, and the parenthesized-if subset are owned by
`frontend-expressions.md`. The declaration
parser does not
duplicate expression grammar, diagnostic precedence, name parsing, or nesting
accounting. The scalar integration caller requests numeric-literal publication
only for a variable initializer that begins with a numeric token. Broader
initializer expressions retain their existing expression-owned unsupported
diagnostics.

A represented object declaration becomes one `Object_Declaration_Node`. The
defining identifier is stored directly by that node, while the selected subtype
mark, optional single-range `Index_Constraint_Node`, and optional initializer are
owned child syntax. `Object_Declaration_Form`
preserves whether the source declared a variable or contained explicit
`constant`. A current variable may omit its initializer or own the selected
represented initializer subset. A current constant with an initializer is a full
constant declaration; a current constant without one is represented explicitly
as a deferred constant. Completion matching and the AARM 7.4 placement rules
remain semantic legality work.

The parser enters this declaration path when an identifier starts a declaration
at a caller-owned declarative-part boundary. The defining identifier is first
validated structurally without symbol publication and the colon is consumed. An
optional `constant` token selects the constant/number branches; otherwise an
identifier-starting selected subtype mark selects the current variable-object
branch. The defining symbol is interned only after one represented branch is
known. A variable declaration publishes its selected subtype mark, optionally
publishes one parenthesized explicit-range index constraint, then either consumes
the terminating semicolon or delegates a present `:=` initializer to the same
expression-staging path as a full constant. A full constant consumes `:=`
and an initializer. When its caller permits deferred constants, a constant whose
represented subtype is followed immediately by a semicolon publishes the same
object node with no initializer. That permission does not exclude variable or full
constant declarations at the same caller boundary.

The current AARM 5.6 block-statement staging path reuses the same operation for
identifier-starting block declarative items. Completed current declarations are
walked iteratively and left as append-only syntax until block ownership exists;
this does not create a block scope or declaration entity. The production first
block exercises that path with the full constant `analysis : constant
Adac.Sema.Analysis_Result := Adac.Sema.analyze (context, root);`. The
second explicit block reuses the same declaration operation for `result :
constant Adac.Backend.Emission_Result := Adac.Backend.emit (module,
output_path);`. The later `compile_file` inner block likewise represents
`result : constant Adac.Frontend.Parse_Result :=
Adac.Frontend.parse_file (context, input_path);`. The later `run` block likewise
represents `input_path : constant String :=
Ada.Strings.Unbounded.to_string (options.input_path);` through this same path.
Its following `output_path` declaration represents the AARM 4.5.7
parenthesized conditional initializer and publishes its complete object parent.
The production `context : Adac.Compilation.Context :=
Adac.Compilation.create (options.language_options);` variable reuses the same
represented initializer path, preserving its parenthesized current name and
complete object parent. These paths publish syntax only; object initialization
semantics and block scope remain later work. Exact resource-publication edges
are regression-test data rather than declaration-contract text.

The package-header staging boundary and the ordinary top-level procedure
declarative part also delegate represented number declarations to this operation.
The production `VERSION_MAJOR : constant := 0;` remains the bootstrap-selected
package-header boundary, while a procedure may now publish the same
`identifier : constant := expression;` syntax. The parser interns the one
defining identifier only after classifying the number-declaration prefix,
represents its initializer through the existing expression parser, and publishes
one `Number_Declaration_Node` after the terminating semicolon has been validated.
Frontend publication itself creates no semantic entity, scope, numeric type, or
named-number value; the procedure-local integer semantic subset is defined
separately by `semantic-model.md`.

Parameterless standalone procedure declarations selected by the child-package
bootstrap path are owned by `frontend-subprograms.md`. They participate in the
common declaration validation boundary as `Procedure_Declaration_Node` values;
this document does not duplicate their subprogram grammar or callable semantics.


## Object Renaming Representation

Ada 2022 AARM 8.5.1 defines an object-renaming declaration independently from
an object declaration. The current bootstrap-selected subset is deliberately
narrower than the full Ada 2022 syntax:

```text
represented_object_renaming_declaration ::=
  defining_identifier : represented_selected_subtype_mark
    renames represented_current_name ;
```

One `Object_Renaming_Declaration_Node` owns the defining symbol and exact
defining-identifier span, one earlier identifier/selected-name subtype mark, one
earlier current represented name for the renamed object, and the complete span
through the terminating semicolon. The two child names must be in source order
and precede the parent. The parser selects this branch after the shared
identifier/colon/subtype-mark prefix when `renames` follows the subtype mark, so
ordinary object declarations retain their existing assignment/deferred-constant
diagnostics. The defining symbol is syntax identity only.

The current subset does not represent the Ada 2022 omitted-subtype form, null
exclusion, `access_definition`, or aspect specification. It also does not resolve
the renamed name, enforce subtype matching, create a new object/entity, or model
the new view defined by renaming; those are semantic responsibilities. Current
explicit-block declarative ownership admits the stable renaming node alongside
ordinary object declarations without introducing a second scan or block-specific
renaming grammar.


## Deferred Constant Representation

Ada 2022 AARM 3.3.1 defines an object declaration containing `constant` but no
initialization expression as a deferred constant declaration; AARM 7.4 owns its
completion and placement legality rules.

The parser reuses `Object_Declaration_Node` with `Constant_Object_Form`, the
represented subtype mark, and `INVALID_NODE_ID` as the initializer. The
no-initializer form is enabled only at caller boundaries that explicitly permit
deferred-constant syntax; the permission is additive and does not force every
identifier-starting declaration to be deferred. The complete semicolon-terminated
declaration is required before its defining symbol and object parent are retained
by the owning declaration list.

This syntax ownership does not create the deferred constant object, link its later
full declaration, enforce package-visible placement, or establish type/visibility
semantics. Those are later semantic/completion responsibilities. Exact symbol and
AST publication edges for deferred constants are retained by regression tests.

## Enumeration-Type Declaration Representation

Ada 2022 AARM 3.2.1 classifies an enumeration definition as a full type
definition, and AARM 3.5.1 defines it as a parenthesized nonempty sequence of
enumeration literal specifications.

The current represented subset is:

```text
represented_identifier_enumeration_type_declaration ::=
  type defining_identifier is
    (defining_identifier {, defining_identifier}) ;
```

The parser first validates the complete type identifier, every enumeration
literal, closing parenthesis, and semicolon without publication. It then interns
the type and literal defining identifiers in source order and creates one
`Enumeration_Type_Declaration_Node` containing their exact spans. The literal
walk is iterative and has no production literal-count special case; source length
and the existing source-character and symbol budgets bound the work.
Character-literal enumeration literals, discriminants, aspects, and non-
enumeration full type definitions remain outside this selected representation
slice.

The selected AST-package continuation retains each completed declaration in
source order and delegates procedure/function specifications to
`frontend-subprograms.md`. Helper private types reuse the simple private-type
operation; identifier-only enumerations reuse one iterative enumeration
operation; and package-visible procedure/function declarations reuse shared
profile representation rather than source-line- or ordinal-specific paths. The
same enumeration operation may also publish an ordered local declarative child
inside the current nested-procedure subset; no procedure-specific enumeration
node or parser is introduced.

The represented formal-part machinery supports the current direct and selected
subtype marks plus the represented `Natural'Last` default expression. Parameter
children, result subtype syntax, and expression children are stable append-only
nodes before the enclosing declaration parent is published. Reusing a spelling
already interned by an earlier declaration does not consume another symbol, while
new defining names remain subject to the context symbol budget.

This document intentionally does not enumerate the cumulative symbol/AST count
after every bootstrap declaration. Those exact publication edges are regression
test data in `tests-internal/` and the independent compiler fixtures.
Repository-wide active work selection and any concrete unsupported boundary are
recorded once in `roadmaps/README.md`; `resource-limits.md` defines the durable
exhaustion contract.

A package-visible declaration that is not yet represented stops the selected
continuation before a package parent or compilation-unit root can be published.
Completed earlier declarations may remain append-only syntax in the rejected
compilation context. This preserves source order and prevents successful package
ownership from silently omitting a visible declaration.

## Exception Declaration Representation

Ada 2022 AARM 11.1 defines an exception declaration as a defining-identifier
list followed by `: exception;`. The current represented subset is deliberately
limited to one defining identifier:

```text
represented_exception_declaration ::=
  defining_identifier : exception ;
```

`Exception_Declaration_Node` owns the defining symbol, its exact identifier span,
and the complete declaration span through the semicolon. The defining symbol is
published only after the complete exception declaration shape has been selected,
and the parent node is appended only after the terminator is present. Multiple
defining identifiers remain an explicit unsupported declaration boundary in the
shared identifier-led declaration parser.

This syntax node creates no exception entity or occurrence identity and adds no
raising, propagation, handler matching, scope, or elaboration semantics. Those
behaviors remain semantic/runtime work.

## Subtype Declaration Representation

Ada 2022 AARM 3.2.2 defines a subtype declaration from a defining identifier and
a subtype indication. The current represented subset is:

```text
represented_subtype_declaration ::=
  subtype defining_identifier is selected_subtype_mark
    [range represented_expression .. represented_expression] ;
```

The subtype mark is the existing identifier/selected-name subset. The optional
constraint is an explicit scalar range whose lower and upper bounds are existing
represented expressions. `Range_Constraint_Node` owns those earlier bound nodes
in source order; `Subtype_Declaration_Node` owns the defining symbol/span, the
earlier subtype mark, the optional earlier range constraint, and the complete
declaration span through the semicolon.

The ordinary library-procedure declarative loop now dispatches `Tok_Subtype`
through this same staging path, so a represented subtype declaration and a
following object declaration retain their common source order in the procedure's
declarative list. This is parser/AST reuse rather than a second subtype grammar.

This syntax representation itself does not resolve the subtype mark, create a
semantic subtype/type identity, evaluate bounds, establish staticness, or apply
constraint semantics. The current semantic layer described by `semantic-model.md`
accepts the narrow direct-identifier subtype-mark case rooted at the supported
`Standard.Integer`, `Standard.Natural`, and `Standard.Positive` integer subtypes,
or at an earlier supported local subtype. It also accepts the existing
selected-name syntax only for the exact two-component expanded names
`Standard.Integer`, `Standard.Natural`, and `Standard.Positive`; arbitrary
selected subtype marks remain semantic boundaries. It may evaluate an explicit range when
each represented bound is a selected static integer form: a literal, unary
`+`/`-` literal, a supported direct or exact `Standard.<subtype>`
`First`/`Last` attribute name, a parenthesized composition of current static
forms, a left-associated binary multiplying `*`/`/`/`rem`/`mod` term over those
forms, or a left-associated binary adding `+`/`-` chain whose terms are current
static forms. Concatenation, other names/attributes, and other represented expressions remain
valid frontend syntax but are later semantic static-expression boundaries. Other
subtype-indication constraint forms, null
exclusions, predicates, and aspects likewise remain later work. Binary `+`, `-`,
and `&` are represented uniformly as `Binary_Adding_Node`, which allows the
production upper bound `Positive'Last - 1` to retain its source syntax without
premature numeric or overload semantics in the frontend.

The subtype defining symbol is published before the subtype-mark name. Range
bounds and the range parent are published before the subtype parent. Configured
symbol or AST exhaustion may leave already completed child syntax private to the
rejected compilation context but shall never publish a partial range or subtype
parent.

## Record-Type Declaration Representation

Ada 2022 AARM 3.8 defines a record type definition as `record`, a component
list, and `end record`, with each ordinary component declaration containing one
or more defining identifiers, a component definition, an optional default
expression, optional aspects, and a terminating semicolon. The current represented
form is deliberately narrower:

```text
represented_record_type_declaration ::=
  type defining_identifier [represented_discriminant_part] is [limited] record
    {represented_record_component}
    [represented_record_variant_part]
  end record ;

represented_discriminant_part ::=
  (represented_discriminant_specification)

represented_discriminant_specification ::=
  defining_identifier : subtype_mark [:= represented_expression]

represented_record_component ::=
  defining_identifier : [aliased] subtype_mark [:= represented_expression] ;

represented_record_variant_part ::=
  case identifier is
    represented_record_variant {represented_record_variant}
  end case ;

represented_record_variant ::=
  when identifier {| identifier} =>
    (represented_record_component {represented_record_component} | null ;)
```

The initial subset accepts the untagged nonlimited or `limited` record source
form plus an optional single known discriminant specification with one defining
identifier, a represented identifier/selected-name subtype mark, and an optional
represented default expression. Ordinary components retain the
same one-identifier subtype/default subset and preserves the optional `aliased`
source modifier. The full AARM 3.7 syntax also permits multiple defining
identifiers, multiple discriminant specifications, null exclusions, access
definitions, and aspects; those forms remain explicit unsupported boundaries
here. Multiple component defining identifiers, access component definitions,
nested variant parts, nonidentifier discrete choices,
`others` choices, component aspects, tagged/extension forms, and null records also
remain outside this slice.

When a represented discriminant part is present, the type defining symbol is
published before discriminant staging so type/discriminant/name symbols retain
source publication order. A complete discriminant specification publishes one
`Discriminant_Specification_Node` before `is record`. Each complete ordinary
component publishes one `Record_Component_Declaration_Node`; the same component
parser is reused inside represented variants. A represented variant publishes one
`Record_Variant_Node` after its choice names and component list are complete, and
the enclosing `Record_Variant_Part_Node` is appended only after `end case;`. All
walks are iterative and the record parent is appended only after `end record;` is
complete. A failed later discriminant, variant, or component may therefore leave
earlier stable child syntax private to the rejected compilation context, but
never a partial variant-part or record parent.

`Record_Type_Declaration_Node` owns the type defining symbol/span, the source-form
Boolean recording whether `limited` appeared, an ordered possibly empty
discriminant list, an ordered possibly empty list of ordinary record-component
nodes, and an optional earlier record-variant-part node. Each
`Record_Component_Declaration_Node` preserves whether `aliased` appeared before
its subtype mark.
`Discriminant_Specification_Node` owns its defining
symbol/span, subtype-mark child, optional default-expression child, and exact
specification span. `Record_Variant_Part_Node` owns one earlier identifier name naming the governing
discriminant and a nonempty ordered list of earlier `Record_Variant_Node`
children. Each variant owns a nonempty ordered list of earlier identifier-name
choice nodes plus either a nonempty ordered list of ordinary component children or
the explicit `null;` component-list form. Choice coverage, staticness, overlap,
expected typing, and resolution of the governing discriminant are semantic work.

The syntax layer creates no record/discriminant/component entity, limited-type
semantics, constraint, layout, variant selection, expected-type resolution,
default value semantics,
visibility, or elaboration state. Counts are bounded by source length, symbol
publication, and the configured AST-node budget; no recursion or production-name/
count special case is introduced.

## Access-To-Object Type Declaration Representation

Ada 2022 AARM 3.10 defines a named access-to-object type with an optional null
exclusion followed by `access`, an optional general access modifier (`all` or
`constant`), and a subtype indication. The current represented subset is:

```text
represented_access_object_type_declaration ::=
  type defining_identifier is
    access [all | constant] subtype_mark ;
```

The initial subset has no `not null` exclusion, constraint, or aspect
specification. The designated subtype is the existing represented identifier or
selected-name subtype mark. The syntax node preserves whether the general access
modifier is absent, `all`, or `constant`; it does not assign accessibility,
storage-pool, allocation, dereference, mutability, or designated-type semantics.

The type defining symbol is published before the designated subtype name so
append-only symbol and syntax order follows source order. The designated subtype
name must be an earlier node in the same store and lie after the defining name
inside the complete declaration span. The parent is published only after the
terminating semicolon, and configured symbol or AST exhaustion cannot publish a
partial access-type parent.

## Derived-Type Declaration Representation

Ada 2022 AARM 3.4 defines derived types from a parent subtype indication. The
current represented subset is deliberately limited to the unconstrained form
needed by the production bootstrap source:

```text
represented_derived_type_declaration ::=
  type defining_identifier is new selected_subtype_mark ;
```

`selected_subtype_mark` is the existing identifier/selected-name subtype-mark
subset. The parser validates the complete declaration shape before publishing the
`Derived_Type_Declaration_Node`. The defining symbol is published before the
parent subtype-mark child so source publication order remains deterministic; the
parent node is appended only after the terminating semicolon is validated.

This syntax representation does not resolve the parent type, create a derived
type entity, inherit operations, determine primitive operations, process a parent
constraint, or establish representation/elaboration semantics. Discriminants,
constraints, `abstract`/`limited`, interface lists, record extensions, and aspects
remain explicit unsupported boundaries.

Configured symbol and AST exhaustion follows the common append-only declaration
contract: already published defining/name syntax may remain private to a rejected
compilation context, while a partial derived-type parent is never published.

## Private-Type Declaration Staging

Ada 2022 AARM 7.3 defines private-type declarations and their partial views.
The current represented subset is deliberately narrower than full private-type
syntax:

```text
represented_private_type_declaration ::=
  type defining_identifier [represented_discriminant_part]
    is [limited] private ;

represented_discriminant_part ::=
  ( defining_identifier : represented_subtype_mark
      [:= represented_expression] )
```

Ada 2022 AARM 7.3 places optional `limited` immediately before `private` in
this untagged subset and permits a discriminant part on the partial view. `type`,
`limited`, and `private` are therefore reserved tokens. The current bounded
discriminant form reuses the same single defining-identifier, simple subtype-mark,
and optional represented-default ownership already used by record types. The
defining type identifier is validated without duplicate publication; when a
discriminant part is present its type symbol is interned before the child syntax,
and the completed `Private_Type_Declaration_Node` owns the ordered discriminant
list, exact type identifier span, limited-form Boolean, and complete declaration
span. Multiple discriminant specifications, multiple defining identifiers,
access/null-exclusion discriminants, `abstract`/`tagged`, aspects, private
extensions, and other full type declarations remain outside the selected subset.
Completion matching, partial/full-view conformance, discriminant legality,
partial-view semantics, and semantic limitedness remain later work.

The private-type node preserves syntax ownership only. Exact publication counts
and the current production continuation belong to regression tests and the main
roadmap rather than this contract.

## End-To-End Local Integer Integration

The active scalar integration track reuses the existing variable-object syntax
for ordinary context-free top-level procedure bodies. After `procedure ... is`,
the parser iterates consecutive current object declarations before `begin` and
attaches the represented nodes directly to that `Procedure_Body_Node`; it does
not add a second declaration representation or a production-source special case.

The first semantically supported declarative form is deliberately narrower than
the represented frontend form:

```text
integrated_local_integer_object ::=
  defining_identifier : supported_direct_integer_subtype
    [:= integer_literal] ;

supported_direct_integer_subtype ::=
  Integer | Natural | Positive
  | Standard.Integer | Standard.Natural | Standard.Positive
  | earlier_supported_local_subtype
```

The names above describe semantic classes rather than case-sensitive lexer
spellings; identifier resolution follows the compilation's symbol policy. A
present initializer is semantically supported only when its complete expression
is a represented decimal or based integer literal compatible with the shared
`Standard.Integer` base type and the selected nominal subtype constraint. A real
literal reaches semantic analysis and is rejected as a type mismatch; other
represented initializer forms remain unsupported. The
frontend may still represent current constants and selected subtype marks where
its existing grammar allows them. Consecutive object declarations are parsed
iteratively; there is no one-declaration or one-initializer count special case.

This integration preserves the earlier bootstrap-specific declaration paths. It
does not change package ownership, nested-procedure syntax, or the stored AST
shape of already represented object declarations.

## Support Boundary

This frontend slice represents current object-declaration syntax without
assigning semantic meaning itself. The scalar integration path now semantically
supports top-level local variables whose direct nominal subtype is `Integer`,
`Natural`, `Positive`, or an earlier supported local integer subtype, with no
initializer or one complete integer-literal initializer. The production
declarations for `name` and `message`
each still publish a validated `Object_Declaration_Node`; their initializer
parenthesized names remain syntactically ambiguous and are not classified as
function calls, indexed components, or type conversions.

The nested-subprogram parser consumes consecutive declarations in this current
subset. Once they are represented, it advances through the production `begin`
and delegates the first statement to `frontend-statements.md`. No declaration
entity, scope, type, initialization semantics, or executable behavior is
claimed by this transition.

Malformed syntax inside the selected prefix retains ordinary syntax
diagnostics. A missing colon, malformed selected subtype mark, or missing
initializer expression therefore fails before an unsupported declaration or
expression claim can hide the source error.

Valid declaration forms outside the selected prefix receive a declaration-
specific unsupported diagnostic instead of a false syntax failure. These
unsupported forms are rejected before defining-identifier symbol publication.
In particular:

- a variable or constant object initializer outside the selected represented
  expression subset retains an expression-owned unsupported diagnostic;
- `defining_identifier : constant := ...` receives
  `number declarations are not supported`; and
- a comma after the first defining identifier receives
  `declarations with multiple defining identifiers are not supported`.

The current slice does not stage or claim support for:

- `aliased` object declarations;
- multiple defining identifiers;
- number declarations with multiple defining identifiers or initializer
  expressions outside the current represented expression subset;
- null exclusions, access definitions, and constrained subtype indications beyond
  the selected one-dimensional explicit-range index constraint;
- anonymous array, task, or protected object definitions;
- deferred constants outside caller-selected declaration paths;
- object-declaration aspect specifications;
- general declaration entities, lexical scopes, or visibility; or
- object, subtype, constantness, or initialization semantics beyond the bounded
  top-level local `Integer` integration contract in `semantic-model.md`.

Those forms remain outside the represented declaration subset and shall be
selected when an active semantic or bootstrap prerequisite requires them rather
than added speculatively.

## Symbol And AST Ownership

The object defining identifier is interned only after the parser has established
that the declaration belongs to the represented variable- or full-constant-object
subset, and is stored directly by `Object_Declaration_Node`. A present selected
index constraint is published after its simple-expression bounds and before the
object parent, without creating a subtype or array-index entity. Unsupported object
or multiple-defining-identifier forms do not leave a defining symbol behind. The current represented number-declaration path interns its one defining
identifier as syntax identity and stores it directly in `Number_Declaration_Node`;
frontend ownership alone is not a declaration entity or scope binding. Procedure
semantic analysis may later retain that symbol as the integer named-number
binding described by `semantic-model.md`. Identifier components in the selected
subtype mark and initializer continue to use the same
context-owned symbol store; no aggregate name or declaration symbol is created.

The selected subtype mark is published as identifier and selected-name syntax.
Initializer names follow `frontend-names.md` through the existing expression
parser. For each production declaration the initializer publishes identifier and
selected components for its `Ada.Exceptions` prefix, the exception-query
selector, the inner `error` item, and one parenthesized-name node.

The object declaration owns its subtype and optional represented-expression
initializer syntax through stable `Node_ID` values. A variable without an
initializer owns only its subtype child. Parser publication remains narrower than
the AST ownership API: current variables and full constants accept the
represented-name subset or the selected parenthesized conditional expression.
No semantic entity, type, scope, visibility state, or elaboration state is
published. A later source failure may leave completed declarations in the
append-only AST store; they remain private to the rejected compilation context.

## Failure And Resource Contract

The selected-subtype-mark loop is iterative and allocates no declaration list,
identifier list, or auxiliary nesting stack. Its work is bounded by the source-
character budget and distinct-symbol budget. The declaration prefix itself does
not consume expression- or profile-nesting budget.

Initializer parsing delegates to the existing expression staging path and
therefore inherits its expression-nesting limit, source-character limit,
symbol-publication policy, AST-node budget, and controlled diagnostics. The
subtype mark or number initializer and completed declaration are validated at
their stage boundaries. AST-node exhaustion before a declaration parent append
leaves only its already-published child syntax and reports a controlled source
failure; a partial declaration node is never published. Exact exhaustion edges
remain regression-test data. The declaration parser adds no scanner rewind, token
buffering, or second expression parser.

Internal impossible-entry conditions remain `Program_Error` contract failures.
Invalid or unsupported source remains an expected input failure as defined by
`failure-model.md`.

## Test Contract

Tests for this boundary shall cover:

- the production-shaped full constant object declaration;
- a variable object declaration without an initializer and one with a current
  represented initializer;
- source-form queries distinguishing variable from constant objects and present
  from absent initializers;
- delegation of its initializer to existing expression staging;
- publication and validation of its subtype-mark and initializer expression
  subtrees;
- symbol publication for the object defining identifier, subtype mark, and every
  published initializer identifier;
- a validated `Object_Declaration_Node` owning those child nodes;
- two consecutive current declarations before the nested body statement part;
- delegation of the production block-local `analysis` full constant through the
  same declaration representation path;
- controlled AST-node-budget exhaustion before an object-declaration append;
- no declaration semantic entity on parser rejection;
- a missing colon before `constant`;
- a missing selected-name component in the subtype mark;
- a missing initializer expression after `:=`;
- a variable object initializer outside the represented-expression subset
  retaining a precise expression-owned unsupported diagnostic;
- a constant without an initializer retaining the deferred-constant unsupported
  diagnostic; and
- the first production number declaration publishing its defining symbol,
  numeric-literal child, complete declaration span, and `Number_Declaration_Node`;
- controlled AST-node-budget exhaustion before the number-declaration parent
  append without partial parent publication; and
- broader number-declaration forms retaining precise unsupported or syntax
  diagnostics;
- case-insensitive representation of `type identifier is private;` with exact
  defining symbol/span, nonlimited source form, and complete declaration span;
- case-insensitive `type identifier is limited private;` preserving the limited
  source-form Boolean while creating no semantic type state;
- a `limited` modifier without following `private` retaining the expected-token
  syntax diagnostic before private-type publication;
- a private-type discriminant part preserving its defining symbol, subtype mark,
  optional default expression, source order, and parent ownership;
- selected package-visible deferred-constant representation with explicit
  constant form, absent initializer, and retained subtype child;
- the existing nonselected nested-declaration path still rejecting deferred
  constants; and
- controlled AST-node exhaustion before the production deferred-constant parent
  while its defining symbol and subtype child remain append-only;
- mixed-case identifier-only enumeration representation with more than two
  literals, exact type/literal spans, and source-order ownership; and
- defining-character-literal enumeration syntax retaining the explicit current
  unsupported boundary; and
- direct parameter-node construction with absent and represented default
  expressions, including source-order and foreign-child validation.

Both current declarations are now retained as ordered declarative-part children
of the nested `Procedure_Body_Node`. Their declaration semantics remain
deferred;
the body merely preserves source ownership so later scope and elaboration work
can consume the list without reconstructing it. The production bootstrap source
remains the authority for selecting broader declaration forms.
