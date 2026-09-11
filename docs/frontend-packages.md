# Frontend Packages

This document defines the current frontend representation boundary for package
library units. It complements `frontend-context-clauses.md` and
`frontend-declarations.md` while preserving package syntax ownership and
deferring scopes, visibility, elaboration, and semantic package entities.

## Ada 2022 Boundary

Ada 2022 AARM 7.1 defines a `package_declaration` as a
`package_specification` followed by a semicolon. A package specification begins
with the reserved word `package`, a defining program-unit name, optional
aspects, and `is`, followed by visible declarations, an optional private part,
and its closing `end` designator.

The current bootstrap source selected after `src/adac_main.adb` is
`src/adac.ads`. Package compilation-unit entry already recognizes the `package`
reserved word and stages its simple `package Adac is` header. The current
visible-part subset is:

```text
represented_package_library_item ::=
  package program_unit_name is
    {represented_package_declaration}
  end [program_unit_name] ; EOF

program_unit_name ::= identifier {. identifier}

represented_package_declaration ::=
  represented_number_declaration | represented_parameterless_procedure_declaration
```

The lexer classifies `package` case-insensitively as `Tok_Package`. After any
represented context clause, compilation-unit dispatch recognizes `Tok_Package`
and consumes it. Defining and closing program-unit names are first parsed
structurally into temporary spelling/span components; malformed dotted syntax
therefore fails before package-name symbol publication. Once a complete name
boundary is established, each component is interned and appended to one temporary
`Program_Unit_Name`. The package constructor copies those components into the
parent instead of manufacturing `Selected_Name_Node` use-name syntax for defining
occurrences.

The production declarations `VERSION_MAJOR`, `VERSION_MINOR`, and
`VERSION_PATCH` all have the represented `defining_identifier : constant :=
represented_expression;` shape. Each publishes its defining symbol,
numeric-literal child, and `Number_Declaration_Node` in source order. The parser
retains the ordered stable `Node_ID` values for those declarations until it can
publish one package parent; the package node then owns that visible declaration
list without copying child syntax objects.

After the consecutive current number-declaration sequence, the parser consumes
the common closing form `end [program_unit_name];` and requires end of file. A
present closing name is interned and preserved as ordered components. AARM 7.1
requires a present closing sequence to repeat the defining program-unit name, but
the constructor does not enforce that legality rule.

A structurally complete source publishes one `Package_Declaration_Node` owning
the ordered represented number declarations, then publishes the enclosing
`Compilation_Unit_Node` with that package as its library item. Package parsing
therefore succeeds through the frontend with no semantic entity. Semantic
analysis deliberately rejects the package library item with `package declarations
are not semantically supported` until package entities, scopes, visibility, and
elaboration exist.

A missing or malformed package defining identifier and a missing `is` retain the
ordinary expected-token or invalid-identifier diagnostics. A malformed current
number declaration retains its declaration or expression diagnostic before the
closing boundary is considered. A missing closing semicolon or trailing source
retains ordinary structural diagnostics before parent publication. An absent
closing designator and a distinct structurally valid closing identifier both
publish syntax successfully; designator legality is not a parser rule.
Package aspects, visible declarations outside the current number-declaration
subset, private declarative items, package semantics, and package bodies remain
outside this represented simple-package subset. An explicit empty private part is
structurally represented.

## Selected Child-Package Representation

Ada 2022 AARM 6.1 defines `defining_program_unit_name` as an optional
`parent_unit_name` followed by a defining identifier, and AARM 10.1.1 permits
that parent form for a library item. The next compiler-owned bootstrap source,
`src/adac/driver/adac-driver.ads`, begins with `package Adac.Driver is` and closes
with `end Adac.Driver;`.

The current represented child-package subset is:

```text
represented_selected_package ::=
  package program_unit_name is
    {represented_selected_visible_declaration}
  [private
    {represented_selected_private_declaration}]
  end [program_unit_name] ; EOF

program_unit_name ::= identifier {. identifier}

represented_selected_visible_declaration ::= represented_selected_declaration
represented_selected_private_declaration ::= represented_selected_declaration

represented_selected_declaration ::=
    represented_object_or_number_declaration
  | represented_private_or_enumeration_type_declaration
  | represented_record_type_declaration
  | represented_access_object_type_declaration
  | represented_procedure_declaration
  | represented_function_declaration
  | represented_nested_package_declaration
  | represented_generic_package_instantiation

represented_nested_package_declaration ::= represented_selected_package

represented_generic_package_instantiation ::=
  package program_unit_name is new selected_name
    [(named_generic_actual {, named_generic_actual})] ;

named_generic_actual ::=
  identifier => selected_name
```

The concrete declaration grammars are owned by `frontend-declarations.md` and
`frontend-subprograms.md`. The package layer dispatches by the current token and
does not encode production declaration counts or identifier spellings.

Defining and closing names are scanned iteratively into temporary spelling/span
components. Symbols are interned only after the complete structural name boundary
is known, so malformed dotted syntax fails before partial package-name
publication. `Package_Declaration_Node` copies the resulting ordered symbol/span
components directly; it does not reinterpret a defining occurrence as a
`Selected_Name_Node` selector use. An empty closing component list represents
`end;`. A present closing name is preserved structurally but is not compared with
the defining name in the parser or constructor; AARM 7.1 name repetition remains
a later semantic legality rule.

Represented visible declarations are collected iteratively as stable child
`Node_ID` values for the package parent. Repeated declarations of the same
represented grammar kind use the same parser operation regardless of their
position. A selected package may contain zero represented visible declarations.

The package layer also recognizes the optional AARM 7.1 `private` boundary. An
explicit `private` keyword is preserved with its exact source span and separates
the visible declaration list from a distinct private declaration list. Absence
of the keyword represents the implicit empty private part. The parser uses the same represented declaration dispatch in either declaration
part and appends each completed declaration only to the list for the part in
which it occurs. Package aspects and declarations outside the represented grammar
remain unsupported; malformed declarations retain their more precise
declaration-owned diagnostics.

The production `src/adac/driver/adac-driver.ads` therefore publishes three
distinct symbols (`Adac`, `Driver`, and `run`), one procedure declaration, one
package declaration, and one compilation-unit root. Frontend parsing succeeds
with zero semantic entities. Semantic analysis deliberately rejects the package
library item with `package declarations are not semantically supported`; package
identity, parent-unit resolution, closing-name equality, scopes, visibility,
elaboration, and callable semantics remain later work.


## Selected AST-Package Bootstrap Staging

The selected `src/adac/ast/adac-ast.ads` child-package path reuses the ordinary
dotted program-unit-name representation and then accumulates supported visible
declarations in source order. The package layer does not reimplement declaration
or subprogram grammar: private types, deferred constants, identifier-only
enumeration types, record types, access-to-object types, procedures, and
functions delegate to the authoritative operations in
`frontend-declarations.md` and `frontend-subprograms.md`.

Each completed visible declaration contributes one stable `Node_ID` to the
pending visible declaration list. If an explicit `private` boundary is present,
the parser records its exact span and switches to a distinct pending private
declaration list. Both lists are iterative and source ordered. A supported child
may publish its own symbols and syntax before its parent becomes stable, but the
package declaration and compilation-unit root are not published until the
complete selected package specification and closing syntax have been accepted.
Therefore an unsupported private item cannot be silently treated as visible and
cannot cause a partial package parent to appear.

The package staging layer is deliberately independent of how many production
items precede a selected declaration boundary or whether the defining name is simple or
selected. Visible and private traversal dispatch by the same represented
declaration grammar. Repeated procedures, functions, private types, enumeration types, record types,
access-to-object types, object/number declarations, nested packages, and
represented formal
defaults therefore use shared machinery rather than ordinal, source-line,
production-identifier, or package-name-shape branches. Nested package
declarations use explicit parser frames rather than recursive parser calls; an
inner package parent is published before its stable `Node_ID` is appended to the
correct outer declaration list. The first token that cannot enter a represented
declaration grammar is the package support boundary. Repository-wide active work
selection and the next language prerequisite belong only in
`roadmaps/README.md`.

Configured symbol and AST exhaustion preserves the same append-only ownership
rule: already completed child syntax may remain private to the rejected
compilation context, while the rejected declaration or package parent is never
partially published. Exact item-specific budget edges are regression-test data;
`resource-limits.md` defines the durable exhaustion contract.

Package identity, parent-unit resolution, closing-name equality, scopes,
visibility, elaboration, and callable semantics remain later semantic work unless
a separate authoritative contract explicitly states otherwise.

## Package Renaming Representation

Ada 2022 AARM 8.5.3 defines package renaming declarations. The current represented
subset is:

```text
represented_package_renaming ::=
  package program_unit_name renames selected_name ;
```

`renames` is a reserved token. The defining package name reuses the ordered
program-unit-name symbol/span representation, while the renamed package is an
earlier represented identifier or selected-name node. The parser selects this
form immediately after the defining name and before ordinary `is`-based package
declaration or instantiation parsing, so it cannot fall back to object or unrelated
package syntax. The same operation is usable as a library item or as a represented
declarative item inside a package body.

`Package_Renaming_Declaration_Node` is syntax ownership only. It does not resolve
the renamed package, establish a package entity/view, apply visibility, link a
completion, or perform elaboration. Configured symbol or AST exhaustion may leave
completed defining/name syntax private to the rejected context, but a partial
renaming parent is never published.

## Generic Package Instantiation Representation

Ada 2022 AARM 12.3 defines a package generic instantiation as `package`
`defining_program_unit_name` `is new` `generic_package_name`, followed by an
optional generic actual part and a semicolon. The current represented subset is narrower than the complete
`generic_association` grammar:

```text
represented_generic_package_instantiation ::=
  package program_unit_name is new selected_name
    [(represented_generic_actual {, represented_generic_actual})] ;

represented_generic_actual ::= represented_generic_actual_value
                             | generic_formal_selector => represented_generic_actual_value

represented_generic_actual_value ::= selected_name
                                   | selected_operator_name
                                   | string_literal
selected_operator_name ::= selected_name . operator_symbol
generic_formal_selector ::= identifier | operator_symbol
```

The defining package name uses the same ordered symbol/span component model as
ordinary package declarations. The generic package name is an earlier represented
identifier or selected-name node. Each actual association records an explicit
`Generic_Actual_Association_Form`: positional actuals own one earlier represented
selected-name, terminal selected-operator name, or string-literal actual; named
actuals additionally own the formal selector symbol and exact selector span. A
selected-operator actual reuses `Selected_Name_Node` with the exact quoted
operator-symbol spelling/span and an earlier identifier-only selected-name prefix.
Associations remain ordered by source position and are parsed
iteratively. One bounded token of lookahead distinguishes an identifier-starting
positional actual from `identifier => actual`; no scanner rewind or backtracking is
introduced. The package-declaration and current nested-procedure declarative paths
share this same instantiation-tail publisher after owning the `package` defining
name and `is` prefix, so the AARM 12.3 subset has one parser contract rather than
duplicated package-context grammars.

Expression actuals outside the current selected-name/terminal-selected-operator/
string-literal subset, box/default actual syntax, and generic procedure/function
instantiations remain outside this subset. Valid operator-symbol formal selectors
and terminal selected-operator actual names are represented, while operator and
expanded-name resolution remain semantic work. Those forms receive explicit unsupported diagnostics after
the surrounding instantiation shape has been recognized; they do not fall back to
object or ordinary package-declaration parsing.

`Package_Instantiation_Node` is syntax ownership only. It does not resolve the
generic unit, bind actuals to formals, apply generic defaults, check generic
legality, copy a template, create an instance entity or scope, or perform
elaboration. Those AARM 12.3 semantics remain later semantic work.

Configured source, symbol, and AST limits preserve append-only publication:
completed defining-name components, selected-name children, and named actual
children may remain private to a rejected compilation context, but the package
instantiation parent is appended only after its complete terminating semicolon.

## Package-Body Stub Representation

Ada 2022 AARM 3.11 permits a `body_stub` as a `declarative_item`, and AARM
10.1.3 defines the selected package form as:

```text
represented_package_body_stub ::= package body defining_identifier is separate ;
```

Package-body declarative traversal distinguishes this form from an ordinary
package declaration after the shared `package` token. It consumes `body`, one
defining identifier, `is separate`, and the terminating semicolon before
publishing `Package_Body_Stub_Node`. The node owns only the defining symbol/span
and complete stub span. A selected program-unit name is deliberately not
accepted because the AARM grammar uses `defining_identifier`, not
`defining_program_unit_name`.

The package-body parent may retain the completed stub in its ordered
declarative-item list. Package specifications do not admit body stubs through
their `basic_declarative_item` lists, so the package-declaration parser continues
to reject `package body` there. Proper nested package bodies are a distinct
`proper_body` form and remain outside this selected slice. Correspondence with a
subunit, completion legality, defining-identifier distinctness, and
post-compilation requirements remain semantic or environment work. Publication
is append-only: the parent stub is created only after all stub tokens are valid.

## Package-Body Header Staging

Ada 2022 AARM 7.2 defines a `package_body` beginning with `package body`, a
`defining_program_unit_name`, and `is`, followed by a declarative part, an
optional handled sequence, and the closing designator. Reassessing the bootstrap
build closure after `adac-driver.ads` selects `src/adac/driver/adac-driver.adb`,
whose first program-unit tokens are `package body Adac.Driver is`.

The current staging subset is:

```text
staged_package_body_header ::= package body program_unit_name is
program_unit_name ::= identifier {. identifier}
```

The lexer classifies `body` case-insensitively as `Tok_Body`. After consuming
`package body`, the parser reuses the iterative structural program-unit-name
scanner used by package declarations, but it does not publish those components.
A complete header consumes `is`. The declarative part is then walked iteratively
through grammar-driven dispatch rather than a procedure-only loop. Current
`procedure` and current `function` bodies reuse their subprogram-body parsers;
`package` delegates to the shared package operation (including package renaming);
current `type`, `subtype`, and identifier-led declaration forms reuse their
existing declaration parsers. AARM 8.4 `use type` clauses are represented as
basic declarative items rather than declarations:

```text
represented_use_type_clause ::=
  use type represented_subtype_mark {, represented_subtype_mark} ;
represented_subtype_mark ::= identifier {. identifier}
```

Each clause publishes one `Use_Type_Clause_Node` owning a nonempty ordered list of
earlier represented identifier/selected-name subtype marks and the complete span
through its semicolon. The same package-body dispatch also represents the bounded
AARM 8.4 package-use form:

```text
represented_use_package_clause ::=
  use represented_package_name {, represented_package_name} ;
represented_package_name ::= identifier {. identifier}
```

A package-use clause publishes one distinct `Use_Package_Clause_Node` so package
use and `use type` source forms remain structurally distinguishable. The parser
does not create package, type, or primitive-operator visibility; those AARM 8.4
effects remain semantic work. `use all type` and broader name/subtype-mark forms
remain outside this selected subset.

Each completed stable declarative-item `Node_ID` is appended to one ordered
temporary package-body list. An empty declarative part is valid in this subset.
Current function bodies may retain consecutive identifier-led declarations before
`begin` and one represented expression return as `Function_Body_Node` values.
Other function declarative forms or statement sequences remain explicit boundaries
and are not misclassified as ordinary function declarations.

A failure inside any current declarative item retains that item's precise
structural or support diagnostic; the package-body layer does not replace it with
a generic continuation error. The first bounded recovery subset is narrower than
that general failure path: a stray simple-statement starter `null` or `return` at
the package-body declarative-item boundary is known not to begin a declaration.
The parser reports `statement is not allowed in package body declarative part`,
then advances iteratively through the next semicolon, or stops before `end` if no
semicolon occurs first. Consuming a semicolon guarantees progress for an offending
token already adjacent to the synchronization boundary. `end` remains owned by the
package closing parser. EOF, resource-limit failures encountered while advancing,
and every other unsupported/failed declarative form remain fail-fast. Multiple
such stray simple statements may therefore produce ordered independent
diagnostics in one compilation. The parser still consumes the package closing
syntax when possible, but any recovered declarative error suppresses publication
of the `Package_Body_Node` and compilation-unit root, so recovery cannot turn a
partial package into a successful frontend result.

When `end` follows the represented declarative part, the parser reuses the
iterative package-closing operation through optional dotted closing name,
terminating semicolon, and EOF. Closing staging itself publishes no
defining or closing-name symbols and no AST node, and it deliberately defers the
AARM 7.2 closing-name repetition legality rule. Only after that complete
structural boundary succeeds does package-body ownership publish the defining and
closing name components, the `Package_Body_Node`, and finally the compilation-unit
root. The temporary list may contain earlier `Procedure_Body_Node`,
`Function_Body_Node`, `Package_Body_Stub_Node`, `Use_Type_Clause_Node`,
`Use_Package_Clause_Node`, and normal represented declaration nodes in source
order; it creates no semantic completion, package scope,
visibility, or elaboration state. Ordinary
package-body compilation units attach this node directly as the unit item. When
the same parser is entered after `separate (parent_unit_name)`, the completed
package body instead becomes the proper-body child of a `Subunit_Node`, preserving
the compilation-unit distinction without duplicating package-body parsing. The
same subunit dispatch also admits the current represented procedure-body path;
package parsing remains unchanged and does not absorb subprogram proper bodies.

The fourteen represented context clauses account for seventeen distinct symbols
and forty-six AST nodes before the package body. The iterative walk represents
both `print_usage` and `finish_with_failure`, then enters `compile_parsed_unit`.
Its profile represents the explicit `in out` first parameter plus the two
omitted/default-`in` parameters. The current declaration subset then represents
`module : Adac.IR.Module;` as a variable object without an initializer. The
current statement continuation then represents the first body call,
`Ada.Text_IO.put_line ("adac: parse ok");`. Initial block staging classifies and
consumes the following line 52 `declare` token without publication, then reuses
the current declaration parser for the block-local full constant `analysis`.
The block body then consumes `begin`, stages the current `case analysis.status
is` header, and preserves the first `when Adac.Sema.Analysis_Rejected =>`
alternative through `finish_with_failure (context); return;`. Production stops at
the second `when` on line 61 with 36 distinct symbols, 124 AST nodes, and zero
semantic entities. The second alternative then preserves
`Adac.Sema.Analysis_Succeeded` and `Ada.Text_IO.put_line ("adac: sema ok");`,
reaching the assignment `module := Adac.IR.Builder.build (context,
analysis.entity);` on line 63 with 37 distinct symbols, 132 AST nodes, and zero
semantic entities. The assignment itself is represented with current target/RHS
syntax, advancing to line 64 `end case;` with 39 distinct symbols, 142 AST nodes,
and zero semantic entities. After validating `end case;` and the unlabeled block
`end;`, the parser publishes both case alternatives, the case parent, one block
handled sequence, and the block parent bottom-up. The following outer
`Ada.Text_IO.put_line ("adac: ir ok");` is then represented with current call
syntax, advancing production to line 69 `declare` with 39 distinct symbols, 152
AST nodes, and zero semantic entities. The selected continuation reuses the
current block-prefix and full-constant declaration paths for the second explicit
block, reaching line 73 `case result.status is` with 42 distinct symbols, 162
AST nodes, and zero semantic entities without publishing a second block parent.
The common case-header parser then represents `result.status` and stops at line 74
first `when` with 42 distinct symbols, 164 AST nodes, and zero semantic entities
without publishing a case parent. A 163-node budget rejects the selected-name
parent without partial publication; a 161-node budget rejects the earlier
`result` object parent. The first second-case choice and its diagnostics-call,
failure-call, and return sequence are then represented and one alternative parent
is published at line 80, reaching 45 distinct symbols, 183 AST nodes, and zero
semantic entities. A 182-node budget rejects before that alternative parent. The
remaining `Emission_Succeeded => null;` alternative and exact case/block closing
syntax then permit the second alternative, case, handled-sequence, and block
parents to be published bottom-up; the complete second block is retained by the
enclosing procedure statement list before later outer statements are considered.
Production reaches line 85 at 46 distinct symbols, 191 AST nodes, and zero
semantic entities. Budgets 187 through 190 reject each successive second-case/
block ownership parent without partial publication. The selected continuation
then walks the two identifier-starting `put_line` calls after the second block
iteratively and retains both in the enclosing procedure statement list, reaching
line 91 `end compile_parsed_unit;` at 46 distinct symbols, 214 AST nodes, and
zero semantic entities. Budgets 195 and 213 reject before the respective call
parents without partial publication. The complete statement list can then be
wrapped in the existing handler-free handled-sequence representation and owned
by one `Procedure_Body_Node`. Budgets 214 and 215 reject the handled-sequence and
body parents respectively. Iterative package-body traversal then resumes at the
following `compile_file` procedure, represents its current profile and first
logging call, and reaches line 101's bare `begin` at 48 distinct symbols, 231
AST nodes, and zero semantic entities. The AARM 5.6 bare-block header consumes
that `begin` as a block with an implicit empty declarative part and exposes line
102's inner `declare` at the same symbol/AST/semantic counts. The nested explicit
block then represents `result : constant Adac.Frontend.Parse_Result :=
Adac.Frontend.parse_file (context, input_path);`, consumes line 105 `begin`, and
reaches line 106 `case result.status is` at 50 distinct symbols, 241 AST nodes,
and zero semantic entities. The existing AARM 5.4 case-header staging then
represents `result.status` and advances to line 107's first `when` at 50 symbols,
243 AST nodes, and zero semantic entities. A 242-node budget rejects before the
selected-name parent; the earlier 240-node budget still rejects before the
`result` object parent.
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
`return;` in one ordered statement list. The procedure-body continuation then
reuses the represented-if path for `not options.has_input`, retaining both guard
statements in source order. The following line 147 block prefix then represents
its current `input_path` full constant and represented parenthesized
conditional `output_path` initializer, publishing the complete second object
parent. It next represents the `context` variable declaration through its current
parenthesized-name initializer and complete object parent. The block prefix then
consumes `begin` and stops at the line 157 `compile_file` call because block-body
ownership is still pending. Production has 68 symbols, 382 AST nodes, and zero
semantic entities. A 381-node budget rejects the `context` object parent after
all children exist; budgets 369/370 protect the conditional parents, while the
earlier 357-node `input_path` and 348-node second-if boundaries remain green.

The selected run-block ownership slice then represents the line 157
`compile_file` call, validates `end;`, and publishes the block handled sequence
and `Block_Statement_Node` bottom-up. It adds seven AST nodes and no new distinct
symbol, so production reaches line 159 `end run;` at 68 symbols, 389 AST nodes,
and zero semantic entities. Budgets 386 through 388 protect the call parent,
handled-sequence parent, and block parent in order. Package-body traversal remains
inside `run`; the procedure body is not published by this block slice. The
following AARM 6.3 slice publishes the completed `run` handled sequence and body,
so package-body traversal retains five current procedure bodies and reaches line
161 `end Adac.Driver;` at 68 symbols, 391 AST nodes, and zero semantic entities.
Closing staging adds no publication. Final package-body ownership then interns
the previously unpublished `Driver` defining-name component, publishes the
package-body parent and compilation-unit root, and reaches 69 symbols, 393 AST
nodes, and zero semantic entities at the frontend boundary.
A 99-node budget preserves the complete
subtype-name children and rejects before partial object-parent publication; a 104-node budget preserves
the call name and actual expression but rejects before partial call-parent
publication; a 114-node budget rejects the block-local `analysis` object parent;
a 116-node budget rejects the `analysis.status` selected-name parent; a 123-node
budget rejects the first-alternative `return;` parent; a 131-node budget rejects
the second-alternative call parent; a 141-node budget rejects the assignment
parent; budgets 142 through 146 reject each successive case/block ownership
parent; and a 151-node budget rejects the following call parent without partial
publication. The
spelling `context` and subtype component `Context` share one symbol under the
default case-insensitive identifier policy; `module` and subtype selector `Module`
likewise share one symbol.

Malformed defining names and a missing `is` retain ordinary expected-token or
invalid-identifier diagnostics. Package-body AST ownership, completion of the
corresponding package declaration, broader declarative items, optional package
statements, closing-name ownership, semantic completion rules, elaboration, and
lowering remain outside this slice.

## Failure And Resource Contract

The package header, visible-declaration walk, and closing-name walk are iterative.
Temporary parsed name components contain bounded source spellings/spans only until
a complete dotted name is known; publication then interns each component once.
Each complete parameterless procedure declaration publishes one defining symbol
and one AST node. No source-controlled recursion is introduced, and temporary
name/declaration state remains bounded by source length plus the symbol and AST
budgets. The parser accumulates only the ordered stable `Node_ID` values needed by a
represented package parent; this temporary list is bounded by the AST-node budget
and does not duplicate syntax objects. Each number-declaration expression inherits
the existing bounded expression and AST-node budgets. The package parent
and compilation-unit root are appended only after their children and complete
source boundaries are valid. Exhaustion before either parent append leaves
earlier append-only children but never a partial package or root. The existing
source-character and symbol budgets remain authoritative.

## Test Contract

Tests for this boundary shall cover:

- lowercase and mixed-case `package` classification through the shared keyword
  matcher;
- simple and selected package defining names publishing only after a complete
  structurally valid header;
- a missing defining identifier and missing `is` retaining structural
  diagnostics;
- the production `src/adac.ads` source publishing all three consecutive current
  version number declarations, one package parent, and one compilation-unit root;
- a multi-number fixture proving visible-part traversal is iterative rather than
  a fixed number of declaration special cases;
- absent and distinct simple closing designators parsing successfully without
  premature legality checking;
- a malformed closing semicolon and trailing source retaining syntax diagnostics;
- exact package defining/closing symbols, visible-declaration order, complete
  package/root spans, and AST-budget behavior at package and root parents;
- semantic rejection of a represented package without entity publication;
- the production `src/adac/driver/adac-driver.ads` publishing `Adac.Driver`, the
  represented `procedure run;`, one package parent, and one compilation-unit root
  with three distinct symbols, three AST nodes, and zero semantic entities;
- iterative multi-component selected defining/closing names and repeated
  parameterless procedure-declaration staging;
- absent or distinct structurally valid closing designators deferring name
  legality, while malformed dotted closing syntax and trailing source retain
  structural diagnostics;
- broader procedure profile/aspect continuations rejecting distinctly from
  malformed simple declarations;
- an independent selected-package fixture traversing the second procedure and
  third function before rejecting at the following declaration, plus production
  73-symbol/53-node third-function resource boundaries;
- a second selected-package fixture traversing the fourth function's selected
  result subtype plus production 74-symbol/61-node resource boundaries;
- a fifth-function fixture covering selected `Span` results plus production
  75-symbol/69-node resource boundaries;
- a parameterized third-procedure fixture plus the production 80-node procedure
  parent boundary with no new distinct symbol;
- a one-parameter sixth-function fixture plus production 76-symbol/84-node
  resource boundaries;
- a selected-result seventh-function fixture plus production 77-symbol/92-node
  resource boundaries;
- a selected-`Span` eighth-function fixture plus production 78-symbol/100-node
  resource boundaries;
- mixed-case limited-private syntax, missing-`private` rejection, and production
  79-symbol/101-node resource boundaries while preserving the same private-type
  node kind;
- the parameterless ninth-function fixture and production 80/103 resource
  boundaries;
- an `append_numeric_literal`-shaped package function retaining the represented
  `Natural'Last` formal default without publishing package semantics;
- generic package instantiations retaining ordered positional and named actuals
  whose current value subset is a selected name or exact string literal, including
  the production-shaped `"=" => "="` operator-symbol association;
- a positional string-literal generic actual retaining its source form, plus a
  non-operator string selector rejecting with the operator-symbol diagnostic; and
- unchanged procedure compilation-unit behavior;
- case-insensitive `body` classification and selected package-body header staging;
- package-body declarative traversal owning an AARM 10.1.3
  `package body defining_identifier is separate;` stub after its matching package
  declaration, while a proper nested package body retains a controlled unsupported
  boundary and package specifications continue to reject package-body syntax;
- the production `src/adac/driver/adac-driver.adb` retaining `print_usage` and
  `finish_with_failure`, representing the `compile_parsed_unit` profile,
  `module : Adac.IR.Module;`, the first body call, and block-local `analysis`
  declaration before reaching line 55 at 34 symbols, 115 AST nodes, and zero
  semantic entities;
- AST-node exhaustion before the production variable-object, first-call, or
  block-local object parent without partial parent publication;
- a multi-procedure package-body fixture proving declaration traversal is
  iterative and preserves source order;
- AST-node exhaustion at both the first and second production procedure-body
  parents without partial parent publication; and
- malformed package-body defining names and missing `is` preserving structural
  diagnostics;
- package-body closing with absent or structurally distinct dotted designators
  reaching the ownership boundary without premature name-legality checking; and
- missing package-body closing semicolons or trailing source retaining the shared
  expected-token diagnostics before the ownership boundary;
- direct construction and validation of package-body defining/closing names,
  ordered procedure-body children, exact span, and foreign-context rejection;
- production package-body and compilation-unit-root publication only after all
  five procedure bodies and closing syntax are complete;
- controlled AST-node exhaustion before package-body and root parents without
  partial publication; and
- explicit semantic rejection of a context-free `Package_Body_Node` without
  entity publication.

The production package body retains all five current procedure bodies and reaches
its line 161 closing form at 68 symbols, 391 AST nodes, and zero semantic
entities. Closing staging is publication-free, so those counts remain unchanged
through `end Adac.Driver;` and EOF. Ownership then publishes the defining and
closing program-unit names only after the complete closing form is structurally
valid. The defining name adds one previously absent distinct symbol, `Driver`.
One `Package_Body_Node` owns the five stable procedure-body children in source
order, and the enclosing `Compilation_Unit_Node` owns that package body as its
library item. Successful frontend publication therefore reaches 69 symbols, 393
AST nodes, and zero semantic entities. A 391-node budget rejects before the
package-body parent, while a 392-node budget retains that parent and rejects
before the compilation-unit root; neither boundary publishes a partial parent.

The node does not represent an optional package initialization part, perform
defining/closing-name equality checking, link the corresponding package
declaration, or create semantic package state. Context-free semantic analysis
rejects a represented package body explicitly with `package bodies are not
semantically supported` and no entity. Production instead has fourteen context
clauses, so semantic analysis rejects its first context item at line 7 before
inspecting the package-body library item.
