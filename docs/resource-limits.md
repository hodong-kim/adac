# Resource Limits

This document defines compilation resource-limit ownership, enforcement, and
failure behavior.

## Ownership

Each `Adac.Compilation.Context` owns one immutable `Adac.Resources.Limits`
value. Limits are fixed when the context is created so that stage behavior
cannot change partway through one compilation attempt.

The default policy currently sets:

```text
maximum_source_characters_per_file = 16_777_216
maximum_expression_nesting = 32
maximum_profile_nesting = 32
maximum_universal_integer_decimal_digits = 1_024
maximum_universal_real_component_decimal_digits = 1_024
maximum_symbols = 1_000_000
maximum_ast_nodes = 1_000_000
```

Embedders and internal tests may supply a smaller or larger limit explicitly.
Zero is valid for every limit. It prevents the scanner from consuming a source
character, prevents entry into a recursive expression, prevents entry into an
access-to-subprogram profile, prevents any universal-integer value from entering
semantic state, prevents any universal-real rational component from entering
semantic state, prevents publication of a distinct symbol, or prevents publication
of any AST node, respectively.

`Source_Character_Limit` ends at `Positive'Last - 1`. This guarantees that the
one-based line or column immediately after every permitted character remains
representable. The subtype rejects an unrepresentable policy when the limits
value is constructed instead of allowing position arithmetic to overflow while
scanning.

## Source Character Budget

The source budget counts the normalized `Character` values that the lexer reads
from one source file. A line separator needed to reach a later line is exposed
as one normalized line-feed character and consumes one unit. The terminal text
file marker is not a lexical character and consumes no unit.

The counter is reset for each `parse_file` scan. The limit therefore applies to
one source-file scan rather than aggregating every file or repeated scan in a
compilation. A later multi-unit frontend may add an independent aggregate raw
byte budget after source encoding and source-manager ownership are defined.

The scanner reserves one unit before reading each character. It uses a bounded
two-character lookahead window and never reads or allocates an entire source
line.
Consequently, a single oversized line, comment, or identifier cannot bypass the
limit through `Get_Line` allocation. Token text remains bounded by the same
per-file budget.

Exhaustion stops tokenization immediately. The parser records exactly one
ordinary `source character limit exceeded` diagnostic and returns
`Parse_Rejected` without a root `Node_ID`. A registered source path, interned
symbols, or AST nodes published before exhaustion may remain in their
context-owned append-only stores; they remain private to the rejected
compilation and are reclaimed with its context.

## Symbol Budget

The symbol budget counts distinct canonical spellings published in the
context-owned symbol store. Re-interning a spelling already represented by the
store returns the existing `Symbol_ID` and consumes no additional budget. In
standard Ada mode this includes spellings that differ only by case.

The store validates initialization and nonempty spelling, performs canonical
lookup, and checks representable index capacity before applying the configured
budget. It checks the budget before appending either the spelling or map entry.
Consequently, exhaustion cannot hide a contract violation, reject a duplicate,
or publish a partial symbol.

Exhaustion raises `Adac.Resources.Limit_Exceeded`. The parser records exactly
one ordinary `symbol limit exceeded` diagnostic at the identifier that required
a new symbol and returns `Parse_Rejected` without a root `Node_ID`. Symbols
published before exhaustion remain in the context-owned append-only store and
are reclaimed with the rejected compilation.

## AST Node Budget

The AST budget counts every node appended to the context-owned AST store,
including nodes that become unreachable after parse rejection. A compilation
unit root consumes one node in addition to its statement nodes. Current name
components, object declarations, number declarations, parameter specifications,
and procedure declarations consume nodes independently. A represented formal
default expression consumes its ordinary expression/name nodes before the
parameter parent, so later parameter or subprogram-parent exhaustion may leave
those bounded children unreachable in a rejected compilation.

The budget is checked after context, symbol, source-span, child-node, and
structural preconditions have been validated, but before the append operation.
This ordering ensures that a contract violation is not hidden by an exhausted
budget. A rejected append does not change the AST node count or publish a
partial node.

A current if-expression parent follows the same budget-before-append rule after
its three child expressions have been published, and its parenthesized wrapper
follows only after the closing parenthesis is validated. A unary-operator parent
follows the same rule after its operand has been published. An if-statement
parent follows it after its condition
and every represented arm statement have been published. Case-alternative,
case-statement, block handled-sequence, block-statement, loop-statement,
package-body, and compilation-unit parents also follow that rule. Their temporary child
lists contain only stable `Node_ID` values for syntax already counted by this
budget; they do not duplicate node records or create a second source-controlled
storage pool.

The check is constant-time and uses the AST store's node count as the single
source of truth. It does not maintain a duplicate mutable counter.

## Expression Nesting Budget

The expression nesting budget bounds the number of simultaneously active
recursive expression entries introduced by general parenthesized primaries,
parenthesized or bracket aggregate primaries, or qualified operands. It also
bounds the explicit parser frames needed to publish *additional nested*
parenthesized-name suffixes. The outermost parenthesized-name suffix remains an
iterative name operation and consumes no frame; each suffix nested inside an
item consumes one level until that child closes.

`Expression_Nesting_Limit` accepts values from zero through
`MAXIMUM_SUPPORTED_EXPRESSION_NESTING`, currently 64. The default is 32. The
hard upper bound is part of the stack-safety contract: a caller cannot configure
an arbitrarily deep recursive expression parse without changing the supported
limit type and revalidating the parser design.

Before consuming a left parenthesis or left bracket that begins a recursive
expression or aggregate primary, the parser checks the current active depth
against the compilation context's immutable limit. Nested component expressions
recurse only after that check succeeds. Exceeding the budget records exactly one
`expression nesting limit exceeded` diagnostic at the rejected opening
delimiter and returns `Parse_Rejected` without publishing an AST root.

A zero limit therefore rejects the first recursive delimited primary or
qualified operand and also rejects the first parenthesized-name suffix nested
inside another suffix. A limit of one accepts one such additional active name
frame or one active recursive expression level but rejects a deeper entry before
its opening delimiter is consumed. Aggregate
association counts are iterative and consume no additional nesting depth. Direct
record-aggregate association values may themselves be represented record
aggregates; each nested parenthesized aggregate consumes one expression-nesting
level while its source is parsed. Construction shallow-checks each already stable
nested aggregate root, while full raw and context-aware record-aggregate
validation use explicit heap-backed worklists instead of recursive validator
calls. The AST-node budget bounds both the published aggregate graph and those
worklists. The counter is parser-local and is decremented on both successful
closure and failed nested parsing.

## Profile Nesting Budget

The profile nesting budget bounds simultaneously active access-to-subprogram
profiles. Every staged access-to-procedure or access-to-function definition
consumes one level, including a parameterless profile and a function profile
reached recursively through its result `access_definition`.

`Profile_Nesting_Limit` accepts values from zero through
`MAXIMUM_SUPPORTED_PROFILE_NESTING`, currently 64. The default is 32. The hard
upper bound is part of the parser stack-safety contract and prevents callers
from configuring arbitrary recursive profile depth without revalidating the
parser implementation.

Before consuming the `procedure` or `function` keyword of a staged
access-to-subprogram definition, the parser checks the active profile depth
against the compilation context's immutable limit. Exceeding the budget records
exactly one `profile nesting limit exceeded` diagnostic at that rejected keyword
and returns `Parse_Rejected` without publishing an AST root.

A zero limit therefore rejects the first access-to-subprogram profile, including
a parameterless one. A limit of one accepts one active profile but rejects a
recursively nested profile before its subprogram keyword is consumed. The
counter is parser-local and is decremented after both successful and ordinarily
failed nested parsing.

Expression and profile nesting can interleave. Their independent hard maxima
bound the recursive contribution of these two syntax families by the sum of
their configured limits, each itself capped by a hard maximum. Neither family
can therefore request unbounded parser recursion.

Nested package declarations do not add parser or validation recursion. Package
staging uses an explicit vector of pending package frames and iteratively closes
the innermost frame before appending its stable `Node_ID` to its parent. Raw AST
and context-aware package validation likewise use explicit pending-node lists; a
parent constructor does not recursively revalidate an already stable nested
package subtree. Deep package nesting therefore remains linear in represented
source/AST size rather than becoming call-stack growth or repeated quadratic
subtree validation. Each live parser frame requires source characters for a
distinct `package ... is` prefix, so frame count is bounded by the per-file
source-character budget. Published child lists contain only stable AST
identifiers and remain bounded by the AST-node budget. A separate package-nesting
budget is therefore not introduced by the current representation.

Nested procedure bodies use the same stable-child principle. A
`Function_Body_Node` may own an earlier `Procedure_Body_Node` in its declarative
part; construction checks that compound child shallowly instead of traversing its
subtree again. Full raw/context validation delegates the child to the existing
explicit procedure-body worklist, whose pending IDs are bounded by the AST-node
budget. Function-to-procedure declarative ownership therefore adds no source-controlled
validator recursion or independent nesting resource. When a procedure
declarative part itself contains procedure bodies, parsing uses an explicit vector
of procedure frames rather than recursive parser calls. Each live frame requires
a distinct source profile/body prefix and retains only bounded lists of stable AST
IDs; source characters, symbols, and AST publication therefore bound this state.
The same procedure-body validation worklist checks the resulting tree. A function
body owned by a procedure may itself own a current local procedure body, but that
local procedure is a bounded leaf with respect to subprogram bodies: its direct
declarative list may not contain a `Procedure_Body_Node` or `Function_Body_Node`.
The parser disables further subprogram-body descent at that entry, and both raw
and context-aware procedure validation preflight the same restriction. Therefore
the added procedure-to-function-to-procedure ownership has fixed alternation depth
and does not create source-controlled call-stack recursion.

Represented `elsif` parts are append-only children of an `If_Statement_Node`.
Each part owns one represented condition and one nonempty direct statement list,
and the enclosing `if` owns only the resulting stable part IDs. Construction
therefore performs work proportional to the direct part, while full validation
visits each part once as part of the same pending compound traversal. Repeated
`elsif` syntax is bounded by source characters and AST-node publication without a
separate alternative-count resource.

Mutually nested represented compound statements follow the same nonrecursive
ownership model. One root-neutral explicit compound-frame vector covers if,
handler-free block, generalized iterator-loop, while-loop, simple-loop, and
current case syntax whether any of those forms is the entry root. This is
necessary because the represented grammar can form chains such as
`if -> loop -> block -> block -> if`. Repeated alternating nesting remains in
the vector rather than adding parser calls. The mixed full-validation graph
covers `if`, `elsif`, handler-free block, every represented loop form, case
statement, and case alternative nodes. Constructors and handled-sequence
builders perform only direct checks on already stable compound roots rather than
recursively revalidating their subtrees. Full raw and context-aware validation
uses heap-backed pending-node worklists and therefore remains linear in
represented source/AST size without source-controlled process-stack growth.
Every represented compound parent consumes an AST-node slot, so the existing
source-character and AST-node budgets bound the structure without a separate
statement-nesting limit.

Iterator-loop body collection remains one forward source-order pass. Each
supported assignment/call/case/`if`/handler-free-block child is parsed once,
retained as one stable `Node_ID`, and copied once into the loop parent's bounded
list. Compound child roots are shallow-checked during parent construction and are
traversed only by full validation, preventing quadratic re-walks as nesting grows.

Parenthesized represented-expression publication uses the existing
`maximum_expression_nesting` parser budget for source nesting. The AST node itself
stores one earlier child only. Raw and context-aware full expression validation
queue parenthesized children explicitly, so deeply nested represented parentheses
consume heap-backed bounded AST storage rather than proportional process-stack
depth. Construction remains O(1) for each wrapper and does not revalidate the
entire already-stable child subtree.

## Failure Contract

The lexer, `Adac.Symbols`, and `Adac.Compilation.Syntax` raise
`Adac.Resources.Limit_Exceeded` when valid work cannot proceed because an
applicable configured budget is exhausted. This exception is an internal stage
signal, not an allocator failure.

The parser converts the signal at the operation-specific boundary into one
ordinary source diagnostic and a `Parse_Rejected` result. It does not publish a
root `Node_ID`, continue parsing, or enter semantic analysis. Nodes appended
before exhaustion remain bounded by the configured limit and are reclaimed
with the context.

Actual memory exhaustion remains `Storage_Error` and follows the external
resource-failure contract in `failure-model.md`. Internal callers that use the
syntax-construction API directly must either propagate `Limit_Exceeded` to an
input-facing boundary or convert it to the result type defined by their stage.
They must not convert it to success or an internal compiler error.

## Concurrency

Operations on one compilation context remain sequential. A future parallel
frontend must make reservation and append one atomic context operation before
same-context parallel construction is supported.

## Future Limits

The current policy bounds normalized source characters per file, expression
nesting, profile nesting, distinct symbols, and AST node publication. Local
mutable-object semantic/IR records are one-for-one descendants of represented
mutable object declarations. The procedure lexical scope retains exactly one bounded binding record plus one
ordered lookup entry per supported direct object, subtype, static Integer/Boolean
constant, or named-number declaration and does not copy identifier spellings. A
subtype binding reuses its resolved underlying `Type_ID` and stores at most one
fixed-size signed-integer range constraint (kind plus two checked bounds). A static
constant binding reuses the same type/constraint representation and adds one
fixed-size checked integer value plus its declaration ID; it creates no semantic
object entity, runtime local, stack slot, or initializer IR instruction. These
bindings therefore add no input-proportional type-store record. Bindings are
flattened into one append-only
semantic-store vector, while one ordered lookup index is keyed by procedure entity
plus symbol ordinal; each procedure entity retains only its binding range
metadata. Checked initializer
metadata and initializer IR value/store pairs are
at most one per represented initialized object. Checked semantic body statements,
assignment IR values, local-load metadata, and stores are likewise at most one
bounded record/value pair per represented assignment statement. Direct-local
definition provenance is one scalar statement index, and the current statically
known assignment value is one fixed-size integer, not a source-sized side table.
These counts therefore remain indirectly bounded by the existing AST node
limit and cannot grow independently of frontend publication. A dedicated
semantic or IR count limit is not introduced by these scalar integration slices.
The predefined `Standard.Boolean` identity adds exactly one fixed type-store record.
The target-independent IR Boolean scalar and Boolean constant value are likewise
fixed-size records and introduce no separately growing resource pool. The native
backend reuses the existing fixed four-byte-per-local frame accounting for Boolean
locals, so the current local-count frame-size bound remains unchanged. Its
`False`/`True` semantic values use one fixed-size enumeration value with no
allocation;
literal resolution performs only bounded existing-symbol lookup. A supported local
Boolean full constant contributes one ordinary lexical binding containing that
fixed value and declaration/type IDs, but no object entity, runtime local, stack
slot, or IR instruction. A mutable Boolean declaration contributes the same fixed
object/local records as an Integer variable; when initialized it adds at most one
fixed `Boolean_Value`, one Boolean IR constant, and one store. These counts are bounded by represented declarations and the existing local/AST
publication bounds. Each checked static Boolean assignment adds at most one fixed-size statement
record, one Boolean IR constant, and one store. Each direct Boolean copy likewise
adds one fixed-size statement record, one local-load value, and one store. Unary
runtime Boolean `not` adds one fixed-size statement record, one local-load value,
one Boolean-not value, and one store. An ordinary runtime Boolean binary logical
assignment adds one fixed-size statement record, two local-load values, one binary
Boolean value, and one store. Left/right source definition provenance uses two
local ordinals and two statement indices plus one fixed Boolean result rather than
an auxiliary history table. A mixed/nested eager Boolean assignment adds at most one
fixed-size semantic expression value per represented runtime leaf/operator plus one
constant value per maximal folded static subtree. The values form one contiguous
postorder tree slice; each record carries a subtree count, so semantic validation is
linear and allocation-free. Sema construction uses explicit frame/value vectors whose
peak size is linear in represented expression size. The resulting IR adds one value
per semantic tree value and one store. These counts remain bounded by AST publication
and expression nesting limits and introduce no independently growing resource pool.
Nested target-independent Boolean operator values are ordered by `Value_ID` and
may reference only earlier Boolean values. Computed not/binary/short-circuit values
have at most one consumer in the current IR contract, making each runtime operator
graph a forest. A direct-local short-circuit assignment adds two fixed local-load
value descriptions, one fixed lazy Boolean value, and one store; it adds no persistent
CFG or label table. Validation uses one fixed-size consumer-count entry per IR value.
The native backend derives one deterministic join label from the lazy value ID while
emitting the expression, so label storage does not grow independently of represented
IR. Native
code generation walks each consumed Boolean tree with an explicit compiler-owned
frame vector and emits one balanced machine-stack save/restore per pending binary
left operand. It does not recurse on source- or IR-controlled depth, and the
single-consumer invariant bounds emitted operator work linearly by represented IR
values rather than by a potentially exponentially expanded shared DAG. Source
expression nesting remains independently bounded by `maximum_expression_nesting`.
The supported static Boolean evaluator uses one explicit evaluation-frame vector
and one fixed-size Boolean-value vector. Each represented identifier,
parenthesized expression, unary `not`, Boolean relation, ordinary logical node,
or short-circuit node contributes only a bounded number of entries, so temporary
work/memory are
linear in and already bounded by AST publication. A statically skipped
short-circuit right relation is traversed by a separate explicit shape-check
worklist, also bounded linearly by the represented subtree; it is not evaluated
and allocates no value-stack entries. Boolean parenthesis/operator nesting
therefore does not recurse on the process call stack and introduces no independent
source-controlled budget.
The type store owns two additional fixed compile-time numeric identities beyond
`Standard.Integer`: `universal_integer` and `root_integer`. The root identity adds
only one fixed type-store record and no value allocation or runtime state. The
private universal value carrier uses the Ada 2022 arbitrary-precision integer
facility and retains a validated decimal magnitude digit count. Each construction
from canonical decimal text must preflight that count before big-integer
allocation. `maximum_universal_integer_decimal_digits` is the per-value context
limit: it defaults to 1024 digits and is configuration-bounded by a hard
1024-digit ceiling. Exceeding it raises the compiler resource-limit failure
category rather than attempting the oversized allocation. The 1024-digit hard
ceiling also leaves deliberate implementation headroom below the Ada 2022
Big_Integer runtime used by the current toolchain, including one-digit transient
growth during checked arithmetic, so an Adac resource rejection occurs before a
runtime bignum capacity failure. That implementation headroom is not an Ada
language range restriction.

The type store also owns two fixed compile-time real-class identities,
`universal_real` and `root_real`. The root identity adds only one fixed type-store
record and no value allocation or runtime state. The private universal-real value
carrier uses the Ada 2022 exact `Big_Real` facility rather than a host binary
floating-point type. Values are stored as reduced rational numbers;
construction accepts canonical decimal numerator and positive denominator text,
preflights both input components, and records the reduced numerator and denominator
magnitude digit counts. `maximum_universal_real_component_decimal_digits` bounds
each input and reduced component, defaults to 1024 digits, and has the same hard
1024-digit configuration ceiling. A zero or negative denominator is an internal
constructor contract violation. Exceeding the component budget raises
`Adac.Resources.Limit_Exceeded` before an oversized input integer is allocated.
The bound is an implementation resource envelope, not a semantic range for Ada
`universal_real`.

Exact real carrier arithmetic applies the same component ceiling to admitted
operands and every potentially expanding integer component used to form a result.
Addition and subtraction compute a denominator gcd before cross-products;
multiplication and division cross-cancel numerator/denominator factors before
multiplication. Remaining integer products use the universal-integer multiplication
preflight, and sums use its bounded one-extra-digit path. The reduced rational
result is validated against the real component ceiling before publication. This
allows cancellation such as `(999/1000) * (1000/999)` under a four-digit limit
without first allocating six-digit products, while a genuinely oversized product
is rejected by `Adac.Resources.Limit_Exceeded`. No real arithmetic operation
allocates a table proportional to a numeric value.

Direct real-literal named-number normalization uses the same bounded universal-
integer primitives for its significand and radix-power scale. Fractional trailing
zeros are removed before the scale exponent is chosen. Nontrivial powers use the
existing logarithmic exponentiation-by-squaring path; no exponent-sized table or
linear exponent loop is introduced. Any significand, scale, numerator, denominator,
or reduced rational component that would exceed the configured 1024-digit envelope
is rejected as `Adac.Resources.Limit_Exceeded` before semantic publication. The
resulting real lexical binding contributes one fixed-size semantic binding record
plus the bounded exact rational carrier and creates no runtime object/entity/IR
state.

Compound real named-number evaluation uses an explicit postorder frame vector and
a separate numeric value vector containing one `Type_ID` plus bounded integer and
real carrier slots; it does not recurse on source nesting. An integer slot remains
exact until a selected mixed root-real/root-integer multiplying operator requires
denominator-1 rational conversion. Each represented static AST node contributes
only a bounded number of frames and values, so temporary stack counts are linear
in and bounded by the existing AST budget. Every carrier operation receives the
context's component limit. Zero divisors are rejected by Sema before rational
division and resource exhaustion aborts the declaration before semantic
publication.

Exact real exponentiation reuses the same component envelope. Bases `0`, `1`, and
`-1` are resolved without exponent-sized work when the mathematical result is
defined. Every other exponent must have a host-representable absolute magnitude no
greater than `4 * maximum_universal_real_component_decimal_digits + 4`; larger
magnitudes raise `Adac.Resources.Limit_Exceeded` before repeated arithmetic. The
remaining work is exponentiation by squaring, so carrier multiplications are
logarithmic in the admitted exponent magnitude and each intermediate rational is
rechecked against the component envelope. Negative exponents invert a nonzero base
once before the same bounded loop. No exponent-sized allocation or linear
exponent loop is permitted.

At the source semantic boundary, a real exponent expression is evaluated by the
iterative exact integer evaluator under the `Standard.Integer` expected type. Its
intermediates remain subject to the universal-integer digit envelope and may
exceed the specific base range temporarily, but the final exponent must fit
`Integer'Base` before the real carrier is called. This prevents a huge exponent
from reaching rational exponentiation merely because the real base is a carrier
fast path. Zero raised to a negative exponent is rejected before the low-level
precondition.

Procedure-local integer named numbers retain one carrier value inside each
lexical binding. Their count remains bounded by frontend AST publication, and
they allocate no runtime local, object entity, stack slot, or IR initialization.
The carrier can represent values beyond `Long_Long_Integer`, and the Sema universal
integer evaluator keeps its value stack in that carrier rather than narrowing
intermediates to a host integer. Literal construction and every carrier operation
receive the context's same per-value digit limit. Addition/subtraction can
transiently require only one extra decimal digit; multiplication rejects any
product whose minimum possible digit count already exceeds the configured limit
before allocating that product.
Division/remainder/modulus cannot grow beyond admitted operand magnitude. Power
handles 0/1/-1 without exponent-sized work, rejects a nontrivial exponent that is
too large for any result inside the configured envelope, and otherwise uses
logarithmic exponentiation by squaring through bounded multiplication. No
operation allocates an exponent-sized table or loops linearly in the exponent.

The semantic layer now has one iterative postorder static-integer evaluation path.
Number declarations, subtype range bounds, mutable/full-constant Integer object
initializers, and static assignment RHS expressions store a context-owned `Type_ID`
together with each bounded `Universal_Integer_Value`; frames also retain the
expected type required by the enclosing operator context. The obsolete host-sized
signed evaluator and its dedicated literal/arithmetic helpers are removed. Each represented AST node contributes only a
bounded number of frames and values, so frame/value counts remain linear in and
bounded by the AST node budget. Each exact carrier is independently bounded by
`maximum_universal_integer_decimal_digits`, making worst-case temporary exact-value
storage bounded by the product of those two configured limits rather than by
source-controlled recursion.

Exact static arithmetic deliberately does not narrow every intermediate to
`Standard.Integer`: Ada static evaluation can require values outside a specific
base range while they are part of a larger static expression. Mutable object
initializers and static assignments therefore retain exact values throughout the
expression; their final consumer boundary owns the `Standard.Integer` base-range
and nominal-subtype checks before host conversion. Integer
exponentiation is a separate operator boundary: the right operand is evaluated
with the predefined `Natural` expectation, retains exact intermediates, and must
finish in `0 .. Integer'Last` before the bounded power primitive is called. Power
itself still uses logarithmic exponentiation by squaring, allocates no
exponent-sized table, and every arbitrary-precision arithmetic result remains
subject to the per-value decimal-digit limit. Parenthesized nesting cannot consume the process call stack during static
integer evaluation.

Aggregate raw source bytes, token count, additional grammar-specific nesting,
diagnostics, semantic/IR state that can grow independently of AST publication,
backend storage, and cancellation safe points require separate contracts and
tests before they are added.

## Tests

Deterministic tests shall cover every configured budget at three levels:

- acceptance at a representative nonexhausted boundary;
- rejection at or immediately before the next publication/recursion operation;
- preservation of ownership invariants after rejection.

The regression suite shall verify, as applicable:

- zero and exact source-character limits, including streaming of long lines and
  exclusion of the terminal text-file marker;
- expression- and profile-nesting limits, including rejection before entering
  unsupported recursive depth and restoration of parser-local counters;
- symbol exhaustion before insertion of a new canonical spelling while existing
  spellings remain reusable;
- AST exhaustion before parent append after all prerequisite child syntax and
  defining symbols have been validated or published;
- exactly one ordinary diagnostic for each input-facing limit exhaustion;
- no root publication for a rejected compilation and no partial node or symbol
  publication for the rejected operation;
- preservation of completed append-only child syntax only within the rejected
  compilation context; and
- unchanged behavior for malformed source and internal contract violations.

Production bootstrap fixtures may pin exact symbol counts, AST counts,
diagnostic locations, or constructor-specific exhaustion edges when those values
are useful regressions. Those numbers belong in the tests and tracked expected
fixtures rather than in this contract document unless a number itself is part of
the configured resource policy.

Every new independently growing compiler resource requires an ownership,
configuration, exhaustion, diagnostic, and validation contract before it is
introduced. A test-only boundary count is not itself a new architectural limit.
