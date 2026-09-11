# Semantic Model

This document defines ownership, identity, construction, and validation for
Adac's semantic objects.

## Ownership And Identity

Each `Adac.Compilation.Context` owns one append-only `Adac.Semantics.Store`.
The store owns every semantic entity created during that compilation and
releases the storage with the context.

`Adac.Semantics.Entity_ID` is a private stable reference to one entity in one
store. It contains a deterministic one-based index and an opaque runtime owner
marker. `INVALID_ENTITY_ID` is the explicit invalid value. Invalid, foreign,
out-of-range, or expired IDs are internal compiler contract violations.

Compiler stages pass entity IDs and the owning context. They do not retain raw
entity pointers or copy mutable semantic records between stages.

## Current Entities

The current model defines two entity kinds:

```text
Object_Entity
Procedure_Body_Entity
```

Every entity records its canonical declaration `Node_ID`, declared `Symbol_ID`,
and source span. An `Object_Entity` additionally records its semantic `Type_ID`
and a disjoint initializer state. A supported explicit initializer is either one
checked integer value or one checked `Boolean_Value`; an uninitialized object has
neither kind, and validation rejects records carrying both or carrying stray
payload for an absent kind. The initializer's expected type is the object's own
`Type_ID` and is therefore not duplicated in a second semantic field. Supported
variable object entities currently use the predefined `Standard.Integer` or
`Standard.Boolean` type boundaries described by `type-model.md`.

A `Procedure_Body_Entity` owns the ordered entity IDs of its directly declared
local objects and one lexical scope for those direct declarations. The scope
retains one binding per local in declaration order, from the context-owned
`Symbol_ID` to the same one-based local ordinal used by checked statements. The
relationship is stored by the semantic store rather than reconstructed later
from spelling or AST order. It also owns an ordered checked statement sequence
for the executable subset. Every checked statement retains
its canonical statement `Node_ID`; a local integer assignment additionally
retains the bound one-based local ordinal, expected semantic `Type_ID`, and
evaluated static integer value. The ordinal identifies semantic source order
only and has no stack-offset or ABI meaning.

Local object entities are published before their procedure entity, and all IDs
remain immutable after publication. Empty-declarative procedures continue to
own an empty local list. Checked statement records are copied into context-owned
append-only storage only when the owning procedure entity is published.

The context-level production constructors derive symbol and span from the
context-owned AST so pipeline callers cannot provide conflicting copies. Object
construction also receives a validated context-owned type ID. The lower-level
store primitives enforce structural validity; context-aware AST, type, and
relationship validation remains in `Adac.Compilation.Semantics`.

The first lexical-scope representation is intentionally limited to one procedure
declarative region and its directly declared local objects, local subtype
declarations, statically initialized Integer/Boolean full constants, and supported
integer/real named numbers. `Adac.Semantics`
represents the scope as an ordered binding sequence plus a logarithmic lookup
index keyed by the owning symbol store's context-local symbol ordinal. Each
binding has an explicit kind. An object binding retains its source-order local
ordinal; a subtype binding retains the canonical `Subtype_Declaration_Node`,
resolved underlying `Type_ID`, and one fixed-size semantic subtype-constraint
value; a static Integer-constant binding retains the canonical full constant declaration,
shared Integer `Type_ID`, nominal constraint, and checked integer value; a static
Boolean-constant binding retains its canonical full constant declaration, shared
`Standard.Boolean` `Type_ID`, and fixed `Boolean_Value`; an integer named-number
binding retains the canonical `Number_Declaration_Node`, the
context-owned `universal_integer` `Type_ID`, and one private checked universal
integer value.
Bindings therefore retain stable identifiers without copying spellings into
semantic state. The source-order binding sequence is the authority for
deterministic traversal; the lookup index is an acceleration structure validated
against that sequence.

Semantic analysis builds this same scope representation while validating the
procedure. Duplicate declarations, object lookup, subtype-name lookup, static
constant lookup, and named-number lookup use it directly, so objects, subtypes,
supported constants, and integer named numbers participate in one direct-name
binding space and declaration order is preserved.
A rejected analysis discards that in-progress value and publishes no semantic
entity. On success, the validated in-progress scope is flattened into the semantic
store's append-only
binding vector and procedure-qualified lookup index; the procedure entity retains
that binding range alongside its ordered local object entities and checked
statements. There is no parent scope, package or use-clause visibility, overload
set, nested-scope graph, or general entity binding in this initial
representation.

## Semantic Analysis Boundary

`Adac.Sema.Analysis_Result` is discriminated by status. A rejected analysis has
no entity payload and means ordinary source diagnostics were recorded. A
successful analysis contains the `Entity_ID` for the analyzed procedure.

The context-owned type layer retains distinct compile-time `universal_integer` and
`root_integer` identities plus the private checked universal value carrier.
Procedure analysis uses `universal_integer` for integer named-number bindings and
uses `root_integer` as the selected result type of the corresponding predefined
operators. The exact integer evaluator carries `Type_ID` and arbitrary-precision
value together, applies the AARM root preference for universal-only homogeneous
operators, and propagates a specific expected type into operands when one exists.
All currently supported procedure-local Integer static-expression consumers use
this exact path: number declarations, subtype range bounds, mutable/full-constant
object initializers, and static assignment RHS expressions. A specific consumer
checks its completed exact value against the `Standard.Integer` base range and any
retained nominal subtype constraint only at that consumer boundary. Neither
`universal_integer` nor `root_integer` is lowered to runtime IR. The context-owned
type layer also has distinct compile-time `universal_real` and `root_real`
identities plus an exact bounded rational value carrier. A minimal
homogeneous predefined-real operator resolver gives universal-only real operands
the required root-real preference without creating runtime real state. A separate
mixed multiplying resolver represents the AARM 4.5.5 root-real/root-integer
signatures and their asymmetric division. Procedure semantic analysis carries
these identities through an iterative exact numeric stack for real named-number
declarations; completed real values are published back as compile-time-only
`universal_real` bindings.

The same context-owned type store retains the predefined `Standard.Boolean` type
as a distinct `Boolean_Type` identity. The Boolean semantic boundary owns type
identity plus non-mutating direct/`Standard.Boolean` type-name resolution and
direct `False`/`True` literal classification. The typed static-Boolean evaluator
accepts an unshadowed direct predefined literal or an earlier Boolean full
constant, parenthesized compositions, unary `not`, ordinary homogeneous
`and`/`or`/`xor`, short-circuit `and then`/`or else`, and all six predefined
Boolean relations. It uses explicit frames and values rather than recursive source
traversal, and every supported operand/result remains `Standard.Boolean`. Boolean
relations and ordinary logical operators evaluate both supported static operands;
ordering uses the enumeration declaration order `False < True`. Short-circuit
forms evaluate the left relation first and, when that value determines the result,
validate only the supported static-Boolean shape of the right relation without
evaluating it. A full local Boolean constant retains the shared type and fixed
value as compile-time lexical state only. A mutable direct `Boolean` or exact
`Standard.Boolean` object instead publishes an `Object_Entity` and runtime local;
it may omit initialization or retain one checked static Boolean initializer.
Assignment to a mutable Boolean local supports static Boolean expressions, direct
mutable-local copy, and eager runtime Boolean expression trees composed from
initialized/defined mutable Boolean locals, supported static Boolean atoms,
parentheses, unary `not`, ordinary `and`/`or`/`xor`, and all six Boolean relations.
Wholly static assignments still fold through the static evaluator. Within a mixed
runtime tree, maximal static subtrees collapse to one semantic Boolean constant while
mutable-local leaves retain definition provenance and remain runtime reads. The
semantic tree is stored in postorder with fixed-size value records and lowers directly
to the target-independent Boolean value graph. Direct `Left and then Right` and
`Left or else Right` assignments are additionally supported when both operands are
direct initialized/defined mutable Boolean locals. Their semantic statement retains
left/right definition provenance independently and distinguishes the two lazy forms;
IR/backend lowering conditionally skips the right runtime load. Nested or mixed
runtime short-circuit operands, statement conditions, and general control flow remain
unsupported. Numeric evaluators reject the Boolean kind explicitly so this boundary
cannot alter arithmetic behavior.

Semantic analysis validates the compilation-unit AST and all language rules
implemented for the current subset before publishing the entity. The current
semantic subset requires an empty context clause; a represented `With_Clause_Node`
therefore produces an ordinary `context clauses are not semantically supported`
diagnostic and no entity. Context rejection precedes inspection of the unit
item so the production bootstrap source stops at its earliest unsupported
semantic prerequisite.

For a context-free unit, analysis first selects the grammar-level unit item. A
`Subunit_Node` produces `subunits are not semantically supported` at the subunit
span and no entity; its proper body is not flattened into a library item. For a
direct library item, analysis then applies the existing library-item boundary.
A represented `Package_Declaration_Node` produces an ordinary `package
declarations are not
semantically supported` diagnostic at the package span and no entity. A
represented `Package_Body_Node` likewise produces `package bodies are not
semantically supported` at the package-body span and no entity. This explicit
boundary prevents frontend-complete package syntax from becoming an internal
kind error. For a `Procedure_Body_Node`, the integrated declarative subset is an ordered
sequence of variable `Object_Declaration_Node` values and
`Subtype_Declaration_Node` values. A subtype declaration currently requires one
direct identifier subtype mark resolving to `Standard.Integer`,
`Standard.Natural`, `Standard.Positive`, or an earlier supported local subtype,
or the exact two-component expanded name `Standard.Integer`, `Standard.Natural`,
or `Standard.Positive`. The expanded-name path recognizes only package
`Standard`; it is not general package visibility or selected-name resolution.
The three predefined names share the Integer `Type_ID`; `Natural` contributes the
fixed constraint `0 .. Integer'Last`, `Positive` contributes
`1 .. Integer'Last`, and `Integer` has no narrower constraint. An unconstrained
local declaration inherits the parent's semantic constraint. A constrained
declaration accepts one represented range
whose lower and upper bounds are selected static integer expressions: direct
integer literals, unary `+`/`-` over any already supported static term or grouped
expression, `abs` over an already supported static primary, direct supported
subtype `S'First`/`S'Last` attribute names,
including the exact supported `Standard.<subtype>'First`/`'Last` expanded
forms, parenthesized compositions of current static expressions, represented
`static_primary ** static_primary` exponentiation, left-associated binary
multiplying `*`/`/`/`rem`/`mod` terms, and left-associated binary adding `+`/`-`
chains. The exponent primary is evaluated through the same bounded postorder machinery and
must finish in the predefined `Natural` range. Direct literals, grouped static
expressions, static constants/named numbers in a specific context, and supported
subtype `First`/`Last` attributes reuse that path; a negative final exponent is an
invalid static expression, while a nonstatic name remains unsupported.
Exponentiation uses bounded exponentiation-by-squaring. Attribute prefixes resolve
only through the current predefined/local subtype boundary. Each range bound is
evaluated exactly under the underlying Integer expected type, checked against the
base range only when the completed bound is consumed, and, for a constrained
parent subtype, must then be contained by the parent range. The
defining symbol remains bound to the
same underlying `Type_ID`; the explicit range is retained separately as one
`Subtype_Constraint`, so a subtype never manufactures a new base-type identity.

A procedure-local full constant whose nominal subtype resolves through the current
Integer subtype boundary may also enter this lexical scope when its initializer is
a supported static integer expression. The initializer is evaluated before the
binding is inserted, so self-reference and use-before-declaration remain
unavailable. The binding is immutable compile-time state: it creates no
`Object_Entity`, runtime local ordinal, stack slot, or new `Type_ID`. Its checked
value may be used by later supported static expressions, including subtype range
bounds, object initializers, and assignment RHS expressions. A constant binding
shadows predefined direct subtype/package spellings just like the other direct
bindings, and an assignment whose target resolves to the constant is rejected.
Deferred constants and addressable/runtime constant-object semantics remain outside
the current subset.

A procedure-local full Boolean constant follows the same immutable lexical-scope
ownership model but has a deliberately narrower initializer boundary. Its subtype
mark is direct `Boolean` or exact `Standard.Boolean`; its required initializer is
a supported static Boolean expression. Direct-name atoms first check an earlier
static Boolean constant and reuse its retained `Standard.Boolean` type/value. If
no such binding exists, any other lexical binding with the same symbol blocks
predefined fallback; only then may direct `False` or `True` resolve through the
context-owned predefined literal boundary. Parentheses preserve the expected
type, unary `not` evaluates the same Boolean type with conventional negation, and
ordinary `and`/`or`/`xor` propagate `Standard.Boolean` to both operands and compute
the conventional result. Boolean relations likewise evaluate two `Standard.Boolean` operands and produce
the predefined Boolean result; `<`, `<=`, `>`, and `>=` compare declaration-order
positions, with `False` preceding `True`.
Short-circuit `and then`/`or else` also propagate `Standard.Boolean`, but evaluate
the left relation first. If the left value
determines the result, the right relation must still be a supported static Boolean
expression but remains statically unevaluated; otherwise the right relation is
evaluated normally. An explicit evaluation-frame/value stack makes all supported
evaluation iterative, and a separate explicit shape worklist validates a skipped
right relation without performing its evaluation-time checks. This preserves
declaration order and the symbol store's case policy without spelling comparisons.
On success the new binding retains the canonical declaration, `Standard.Boolean`
`Type_ID`, and `Boolean_Value`, with no object entity or runtime state. Duplicate
names, use-before-declaration, wrong-kind shadowing, unsupported operands, and
assignment to the constant remain ordinary source failures that publish no
semantic entity. Mutable Boolean objects reuse this same static evaluator for an
optional declaration initializer and for static-expression assignment RHS values.
A direct mutable Boolean local may additionally be copied by assignment when an
initializer or earlier supported Boolean assignment establishes its value. The
existing direct-local unary and binary assignment forms remain compact semantic
records. Mixed and nested eager expressions use a separate postorder semantic value
tree. A local leaf retains its local ordinal, source-definition statement, and known
Boolean value; a static subtree becomes one constant leaf; unary and binary values
reference earlier tree values. Parentheses add no semantic value. Each value also
retains its subtree size, allowing validation to prove a complete non-shared tree in
linear time without recursion or an auxiliary consumer table. Sema computes known
values only for cross-validation; mutable runtime reads are never replaced by those
known values. Direct-local runtime `and then`/`or else` assignments use separate
checked statement kinds rather than the eager expression tree. Both source locals
are required to have supported definitions for semantic provenance, but native
evaluation loads the left first and branches around the right load when the left
determines the result. Nested/mixed runtime short-circuit forms and conditions remain
later slices.

A procedure-local AARM 3.3.2 number declaration may enter the same lexical scope
when its initializer is an integer static expression supported by the exact
evaluator. The current subset accepts decimal and based integer literals, earlier
integer named numbers, earlier typed static Integer constants, supported scalar
subtype `First`/`Last` attributes, and their represented parenthesized, unary,
adding, multiplying, remainder/modulus/division, and exponentiating compositions.
The exact integer branch uses a `(Type_ID, Universal_Integer_Value)` value stack:
literals and earlier named numbers enter an unconstrained numeric context as
`universal_integer`, while unary and homogeneous binary operator applications use
the predefined-integer resolver and retain the selected `root_integer` or specific
result type. Parenthesized expressions preserve the enclosing expected type.
Arithmetic remains exact and bounded by the same carrier contract and never routes
intermediates through `Long_Long_Integer` merely for type selection. Integer
exponentiation propagates its selected result type to the left operand and the
predefined `Natural` context to the right operand. The right expression may contain
arbitrarily large supported static intermediates, but its final exact value must be
nonnegative and no greater than `Integer'Last` before exponentiation is applied.

The initializer is evaluated before insertion, so self-reference and
use-before-declaration remain unavailable. A direct literal or earlier named number
can enter as `universal_integer`; an earlier static full constant or supported
subtype attribute enters with its specific Integer `Type_ID`. Homogeneous operator
resolution can therefore adapt universal operands to that specific type, while a
universal-only predefined operation selects `root_integer`. The number declaration
converts any supported completed integer static result to `universal_integer` when
the binding is published, retaining the exact `Universal_Integer_Value`; it creates no
`Object_Entity`, runtime local ordinal, stack slot, or initialization IR. `maximum_universal_integer_decimal_digits` bounds every admitted universal
value and intermediate. An expression whose literal or operator result exceeds
that resource envelope records one declaration-local resource diagnostic and
rejects analysis before procedure publication. Zero divisors and negative
exponents remain ordinary source-invalid/unsupported diagnostics rather than
low-level arithmetic contract failures. A later supported mutable-object initializer or static assignment expression may
consume the named number while remaining in exact carrier space; the value is
checked against the expected signed base range and target nominal constraint and
converted only at that final consumer boundary. A named number is not an assignment target and
shadows predefined direct names in the same way as the other direct lexical
bindings. A real number declaration follows the same declaration-order, duplicate-
name, shadowing, and immutable named-number rules and is retained as a
`Local_Real_Number_Binding` with `universal_real` identity and an exact
`Universal_Real_Value`. Its iterative postorder evaluator accepts direct
decimal/based real literals, earlier real named numbers, parentheses, unary
`+`/`-`/`abs`, additive `+`/`-`, homogeneous real `*`/`/`, the three AARM
4.5.5 mixed root-real/root-integer multiplying signatures, and AARM 4.5.6 real
exponentiation. Direct integer literals and earlier integer named numbers enter
the temporary numeric stack with their integer carrier and `universal_integer`
identity; they are converted to an exact denominator-1 rational only after a mixed
multiplying signature is selected. Real exponentiation instead requires a
real/root-real left operand and evaluates the right operand through the exact
integer path with `Standard.Integer` as the expected `Integer'Base` type. The
exponent may be negative, but its final exact value must fit that base range; wide
intermediates may cancel before the final check. Zero raised to a negative exponent
is diagnosed before the carrier precondition, while admitted powers use the
bounded exact rational primitive. Operator results carry `root_real` internally
and the number-declaration boundary converts the completed static result back to
`universal_real`. Reverse integer/real division and mixed additive/unary uses
remain unsupported. Division recognizes a zero divisor before the low-level
rational primitive, and resource exhaustion becomes a declaration-local source
diagnostic. The binding has no object entity, runtime local ordinal, stack slot,
or initialization IR. Literal source spelling is normalized into exact bounded
carriers, never a host floating-point approximation. A real named number blocks
predefined subtype fallback when it shadows `Integer` or `Standard`, cannot be an
assignment target, and is rejected as the source of the current Integer-only
assignment form. Addressability and general real overload resolution remain
outside this subset.

A following variable object may use one of the supported predefined Integer-family
direct names, its explicit `Standard.<subtype>` expanded form, an earlier supported
local Integer subtype name, direct `Boolean`, or exact `Standard.Boolean`. Integer
objects retain the shared underlying Integer `Type_ID` plus their nominal subtype
constraint. Their optional static initializer is evaluated through the exact typed
path, so arbitrarily large admitted intermediates remain available until the final
object-type and nominal-subtype checks. A Boolean object carries the distinct
`Standard.Boolean` `Type_ID`, has no numeric subtype constraint, and may omit its
initializer or retain one result from the supported static-Boolean evaluator. Full
Integer and Boolean constants remain compile-time-only lexical bindings with no
runtime entity or slot. Each accepted runtime initializer is retained as one final
scalar value, so lowering emits a scalar constant/store rather than an arithmetic
expression tree for these compile-time forms.
Semantic analysis performs name lookup through
context-owned symbol/type or lexical-scope boundaries; Sema does not compare or
canonicalize identifier spelling itself. Selected subtype marks outside the exact `Standard.<supported subtype>` boundary,
subtype use before declaration, concatenation operators, nonstatic exponent names,
range-bound names or attributes beyond supported-subtype `First`/`Last`, other
constraint forms, and a subtype declaration of a different
underlying type remain outside the current subset. Duplicate direct object,
subtype, and static-constant names are rejected before publication.

Supported body statements are `null;`, bare `return;`, and the bounded local
integer assignment described in `frontend-statements.md`. For an assignment,
analysis resolves the direct target through the in-progress lexical scope and
applies the target object's `Type_ID` as the RHS expected type. Any expression
already accepted by the bounded static integer evaluator is folded to one checked
integer value within the base type and then checked against the target object's
nominal subtype constraint. A direct identifier RHS is resolved through the same
deterministic lexical scope. A mutable local must have the same semantic type and
a supported statically known
integer value from an explicit initializer or an earlier checked assignment; a
static-constant binding contributes its already checked immutable value. Either
value must satisfy the target object's nominal subtype constraint.
A real literal is a type mismatch for the current integer target; nonstatic names
and expression forms outside the evaluator remain unsupported.

Checked assignment metadata distinguishes static-expression assignment from
direct local copy assignment. Both forms retain the statically known integer value used for
subtype-range validation. A checked local copy additionally records the source
local ordinal plus its current definition provenance. Definition statement zero
means the source was explicitly initialized; a positive value names an earlier
checked assignment statement whose target is that source local. After either
supported assignment kind is checked, its target becomes a supported definition
for later statements.
This compact provenance lets semantic validation re-establish the no-uninitialized-
read contract without an auxiliary source-sized validation table.

Boolean assignments use distinct statement kinds parallel to the Integer model. A
Boolean-static assignment retains target local, expected `Standard.Boolean`, and
folded `Boolean_Value`, then lowers to a Boolean constant plus store. Direct copy,
unary-not, and binary-local statements retain their compact source provenance. A
general eager Boolean expression assignment instead owns one contiguous postorder
value-tree slice. Its value kinds are static constant, mutable-local read, unary
`not`, and binary Boolean operator. Local reads retain definition statement zero for
an explicit initializer or a positive earlier Boolean-assignment statement. Operator
values reference only earlier values in the same slice and retain a subtree-size
proof; the final value spans the whole slice and is the assignment root. Boolean
ordering follows language position order, `False < True`. Known values are
cross-validation metadata only. IR lowering maps the semantic slice in order to
Boolean constants, local loads, not values, and binary values, then stores the root.
Integer and Boolean provenance are disjoint: a Boolean assignment can never satisfy
an Integer-copy definition and vice versa. Assignment to a full constant or named
number remains rejected.

Only after all declarations and statements pass does analysis publish the
ordered object entities, including any checked initializer values, and then the
owning procedure entity with its lexical scope and checked statement sequence. A rejected analysis
does not append any semantic entity. Ordered procedure-local ownership therefore
also defines declaration elaboration order for lowering: explicit initializer
actions occur in local source order before body statements. Nested procedures
and all other declarative forms continue to produce a precise unsupported
semantic diagnostic at the first unsupported declaration.

`Adac.IR.Builder.build` accepts the successful entity ID rather than a raw AST
root. It validates the entity through the compilation context and lowers stored
semantic locals and checked statements. It does not redo source-name lookup or
numeric-literal parsing from the AST. This makes semantic success and binding an
explicit prerequisite for IR construction.

## Validation

`Adac.Compilation.Semantics.validate` verifies:

- entity ID validity, store ownership, and range;
- entity kind and structurally valid stored references;
- declaration node ownership and the AST kind required by the entity kind;
- symbol and source-span ownership;
- object type-ID ownership, canonical object declaration relationship, and
  initializer-presence agreement with the AST;
- initialized-object literal form and checked value containment in both the
  underlying signed-integer type and nominal subtype constraint;
- procedure local-object entity ownership, ordering, and `Object_Entity` kind;
- lexical-scope binding count, source order, symbol ownership, binding kind,
  static-constant declaration/type/constraint/value metadata, named-number
  declaration/universal-type/value metadata, and
  lookup-index consistency;
- object-binding local ordinals and equality with the corresponding local
  entities;
- subtype-binding declaration ownership, defining symbol, underlying `Type_ID`,
  inherited or explicit signed-integer range constraint, parent-range
  containment, and resolution through an earlier subtype binding or the
  predefined-type boundary;
- checked statement count, source order, and canonical statement `Node_ID`;
- assignment target-local ownership and expected-type consistency;
- checked Integer-assignment value containment in the expected signed-integer
  type and target object's nominal subtype constraint;
- checked Boolean-static assignment target/type agreement, Boolean-only payload,
  and supported static-Boolean expression shape;
- Boolean copy/not/binary target/type agreement, source ownership, canonical
  source-name agreement with the AST, exact runtime operator shape, and independent
  provenance for both binary operands;
- direct-local assignment source ownership, source/target type agreement, and
  canonical source-name agreement with the AST;
- type-specific direct-local definition provenance naming an explicit source
  initializer or an earlier checked assignment of the same scalar family that
  targets the same source local and retains the same known value;
- equality between stored symbol/span data and canonical AST properties.

Validation is deterministic, does not modify the store, and allocates no
storage. A validation failure raises `Program_Error` and is not converted to an
ordinary source diagnostic or backend operational failure.

Production APIs expose no unchecked constructor. Validator tests use test-only
child packages under `tests-internal/` to inject malformed entities without
weakening the production contract.

## Allocation And Failure

Entities are appended in deterministic semantic-analysis order. Appending does
not invalidate earlier IDs. Representable index or allocator exhaustion raises
`Storage_Error` before an ID wraps or a live ID is reused.

The integrated scalar subset can create an input-controlled number of object
entities plus one procedure entity and one lexical binding per represented direct
declaration. Static Integer and Boolean constants add only a bounded lexical binding and no
object entity or runtime local. Boolean adds one fixed-size value field and no
source-sized auxiliary structure. The subset otherwise retains
and one checked-statement record per supported represented statement. Each scope
binding uses fixed-size symbol/local metadata plus one ordered-map entry; it does
not retain another identifier spelling. Semantic publication remains append-only
and deterministic; the existing AST limit bounds declarations, bindings, and
statements, so checked semantic state cannot grow independently of frontend
publication. A
dedicated semantic limit remains a later resource-policy slice and shall be added
before semantic state can grow independently of those bounds.

Operations on one context remain sequential. Independent contexts share no
semantic store or entity state.

## Tests

In-process tests shall cover:

- successful empty procedure analysis publishing one procedure entity;
- successful local-Integer analysis publishing ordered object entities, ordered
  lexical bindings, and one owning procedure entity, with and without explicit
  integer initializers and compile-time-only Integer/Boolean static constants;
- successful predefined `Integer`/`Natural`/`Positive` lookup with one shared
  Integer `Type_ID`, exact Standard constraints, case-policy preservation, and no
  symbol/type/entity/runtime allocation side effects;
- successful explicit `Standard.Integer`/`Natural`/`Positive` expanded subtype
  marks, plus rejection of other package prefixes and local `Standard` shadowing,
  without adding general package visibility state;
- successful unconstrained subtype chains and selected static integer range
  expressions using literal, unary `+`/`-`, binary multiplying
  `*`/`/`/`rem`/`mod`, parenthesized grouping, and binary adding `+`/`-` forms
  with Ada precedence and left association, retaining
  declaration bindings, the shared underlying type, and
  inherited/explicit constraint metadata without extra runtime slots;
- rejection of subtype use before declaration, unsupported static-expression
  forms, arithmetic results outside the underlying type, child ranges outside a
  constrained parent, and duplicate object/subtype names without semantic
  publication;
- rejection of constrained-object initializers such as `Positive := 0`,
  static-expression assignments, and known local-copy values outside the target
  subtype range;
- declaration-order preservation for multiple initialized locals before checked
  body statements are lowered;
- duplicate or unsupported local declarations publishing no semantic entity;
- rejected analysis publishing no entity;
- canonical declaration, symbol, span, type, and local-entity queries;
- checked statement queries including assignment target binding, expected type,
  integer-literal value, direct source binding, and definition provenance;
- direct local copies after an initializer and after an earlier assignment,
  including case-insensitive scope lookup;
- lexical-scope source-order queries, static-constant type/constraint/value and
  named-number universal-value retention, duplicate insertion without mutation,
  absent lookup, and rejection of foreign symbols;
- rejection of undeclared/unsupported assignment targets or sources,
  uninitialized local reads, mismatched assignment or initializer literal types,
  unsupported/nonstatic initializers, static-constant or named-number assignment
  targets and use-before-declaration, real/out-of-envelope named numbers,
  zero-divisor static expressions, and
  out-of-range integer expressions without semantic
  publication;
- invalid and foreign `Entity_ID` values;
- malformed declaration, symbol, and span references;
- IR construction rejecting malformed or foreign entities;
- isolation between compilation contexts;
- existing end-to-end compiler behavior.
