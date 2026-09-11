# Type Model

This document defines the first context-owned semantic type representation used
by Adac. It owns type identity and language-level scalar properties; target ABI,
register, stack-slot, and object-format choices remain backend responsibilities.

## Ownership And Identity

Each `Adac.Compilation.Context` owns one append-only `Adac.Types.Store`.
`Adac.Types.Type_ID` is a private context-owned reference to semantic type
identity, with the same owner and index safety rules as the other compiler
identifiers. A source subtype declaration does not allocate another `Type_ID`
merely because it introduces a new subtype name. `INVALID_TYPE_ID` is the
explicit invalid value. Foreign, invalid, out-of-range, or expired identifiers
are internal compiler contract violations.

`Adac.Compilation.Types` is the context-facing access boundary. Semantic analysis
and later stages borrow type IDs from the context; they do not copy mutable type
records or infer type identity from source spellings.

## Initial Predefined Types

The initial store contains six context-owned semantic type identities. The first
is the predefined signed integer type denoted by `Standard.Integer`. Adac defines
its supported initial range as the conventional 32-bit signed range -2**31
through 2**31-1. This satisfies the Ada 2022 requirement that `Integer` include
at least the required minimum range while giving scalar lowering a deterministic
implementation range. Its kind is `Signed_Integer_Type`, and the IR builder
explicitly lowers it to the current target-independent 32-bit signed integer IR
type.

The second identity is the language-defined universal type `universal_integer`,
represented by `Universal_Integer_Type`. It is distinct from `Standard.Integer`
and is compile-time-only: the signed-integer base-range accessors reject it and
the IR builder treats any attempt to lower it as an internal contract violation.
This follows the Ada 2022 model in which `universal_integer` represents the
integer class rather than one particular signed integer type. The type record
deliberately stores no native byte size, alignment, register class, stack offset,
ABI, or object-format information.

The third identity is the language-defined specific root type `root_integer`,
represented internally by `Root_Integer_Type`. It is distinct from both
`universal_integer` and `Standard.Integer` and is currently a compile-time
operator-resolution identity only. Adac does not expose a source spelling for it,
does not assign it the `Standard.Integer` i32 implementation range, and does not
lower it to runtime IR. This preserves the AARM distinction that universal
integer values may select predefined operators of the specific root type while
the result of such an operator is a `root_integer` value rather than another
`universal_integer` value.

The fourth identity is the language-defined universal type `universal_real`,
represented by `Universal_Real_Type`. It is distinct from all integer-class
identities and is compile-time-only. The IR builder rejects it as a runtime scalar,
and the signed-integer range accessors reject it.

The fifth identity is the language-defined specific root type `root_real`,
represented internally by `Root_Real_Type`. It is distinct from `universal_real`
and every integer-class identity and is currently a compile-time operator-
resolution identity only. Adac exposes no source spelling or runtime scalar
representation for it. This preserves the AARM rule that universal-only real
operands prefer predefined operators of `root_real`, whose result is a specific
root-real value rather than another implicitly convertible `universal_real` value.

The sixth identity is the predefined enumeration type `Standard.Boolean`,
represented by `Boolean_Type`. It is distinct from every numeric identity and is
appended after them so existing numeric `Type_ID` indices remain stable. This first
Boolean boundary owns type identity, source-name resolution, and the two
language-defined literal values. `Boolean_Value` stores `False` at position zero
and `True` at position one, matching declaration order. A non-mutating predefined
literal resolver maps already-owned `False`/`True` symbols to `Standard.Boolean`
plus that fixed-size value and preserves the symbol store's identifier case policy.
Procedure Sema consumes those values through one typed static-Boolean boundary
for compile-time full constants: a direct `Boolean` or exact `Standard.Boolean`
constant may be initialized by an unshadowed direct `False` or `True`, by an
earlier Boolean full constant in the same lexical region, or by parenthesized,
unary-`not`, ordinary `and`/`or`/`xor`, and short-circuit `and then`/`or else`
compositions of those atoms. All six predefined Boolean relations over supported
static-Boolean operands are also admitted and return `Standard.Boolean`.
Equality/inequality compare the two Boolean values directly; ordering follows the
language-defined enumeration position order `False < True`. The static evaluator
retains `Standard.Boolean` identity and fixed values throughout. Short-circuit
evaluation is left-first; a right relation whose value cannot affect the result is
checked only for the currently supported static-Boolean shape and is not evaluated.
Procedure-local mutable objects may now use direct `Boolean` or exact
`Standard.Boolean`; they retain the same semantic identity and may omit
initialization or use one supported static Boolean initializer. Target-independent
IR has a distinct Boolean scalar/constant representation, while its native width
and truth coding remain backend-owned. Static-expression assignment, direct
local-to-local Boolean copy, unary runtime `not`, ordinary runtime
`and`/`or`/`xor`, equality/inequality, and all four ordering relations preserve
the same `Standard.Boolean` identity. Mixed and nested eager assignments may
combine supported static Boolean subtrees with initialized or earlier-defined
mutable-local reads; static subtrees fold without changing the runtime type.
Direct-local `and then` and `or else` assignments also preserve this type while
retaining their lazy evaluation identity through semantic and IR lowering. Copy
lowers as a local load/store, eager operators use target-independent Boolean
operator values, and short-circuit forms use distinct lazy Boolean value kinds.
Runtime ordering uses the language enumeration position order `False < True`;
native coding remains outside the semantic type contract. Nested or mixed runtime
short-circuit forms, conditions, addressable/runtime constant-object state, and
broader runtime Boolean operators remain unsupported. Signed-integer range
accessors and numeric operator resolvers continue to reject Boolean.

`Universal_Real_Value` is a private exact rational carrier backed by the Ada 2022
`Big_Real` facility. Construction from a quotient validates canonical decimal
integer text for the numerator and a strictly positive denominator, preflights both
components against the caller's resource limit, reduces the rational value, and
retains reduced numerator/denominator magnitude digit counts. A second internal
constructor accepts already-bounded universal-integer numerator/denominator
carriers so Sema can normalize source literals without exposing the private
big-integer representation. Equivalent quotients therefore compare as the same
exact value; no host `Float` or `Long_Float` approximation participates. The
default and maximum supported component size are 1024 decimal digits. This is a
compile-time resource envelope rather than the semantic range of `universal_real`.

The exact real carrier also owns bounded sign inspection, unary negation,
addition, subtraction, multiplication, nonzero division, and integer
exponentiation. Every arithmetic entry validates both reduced input components
against the supplied component limit. Additive operations first factor the
denominator gcd and multiplication/division cross-cancel numerator/denominator
factors before any potentially growing product. The remaining products and sums
reuse the bounded universal-integer primitives, so an intermediate component that
cannot fit the configured envelope is rejected before unbounded rational work
occurs. Integer exponentiation preserves exact rational values, accepts negative
exponents by taking the reciprocal of a nonzero base, handles zero and unit bases
without exponent-sized work, and uses logarithmic exponentiation by squaring for
all remaining cases. A nontrivial exponent whose magnitude exceeds the bounded
work envelope derived from the component limit is rejected before the loop. The
final quotient is reduced again and its numerator/denominator metadata is
revalidated. Division by zero and zero raised to a negative exponent are low-level
carrier precondition violations; a source-facing evaluator must recognize them
before calling the primitive and issue its own source diagnostic.

The type layer owns a minimal homogeneous predefined-integer operator resolver.
For unary homogeneous integer arithmetic, a `universal_integer` operand selects
the `root_integer` operator, while an already supported specific operand retains
its own type. For binary homogeneous arithmetic (`+`, `-`, `*`, `/`, `rem`, and
`mod` at the current boundary), two universal operands select `root_integer`; a
universal operand paired with one supported specific operand selects that
specific operand type; equal specific operands retain that type; incompatible
specific operands do not resolve. This boundary does not yet model exponentiation
(the right operand has the distinct expected subtype `Natural`), relational
results, general overload sets, or user-defined operators.

The type layer also owns the matching minimal homogeneous predefined-real operator
resolver. A unary `universal_real` operand selects `root_real`; an already
supported specific root-real operand remains `root_real`. For homogeneous binary
real arithmetic, two universal operands select `root_real`, a universal operand
paired with `root_real` adapts to `root_real`, and two root-real operands remain
root-real. Integer-class types and incompatible type pairs do not resolve through
this homogeneous real boundary. The additional AARM 4.5.5 multiplying forms that
combine root numeric classes use a separate mixed resolver rather than pretending
the operands share one homogeneous type. Its operation kind is explicit: mixed
multiplication accepts `root_real * root_integer` and
`root_integer * root_real`, while mixed division accepts only
`root_real / root_integer`; every accepted form returns `root_real`. A
`universal_real` operand may adapt only to the root-real position and a
`universal_integer` operand only to the root-integer position. `Standard.Integer`,
reverse integer/real division, homogeneous pairs, and unrelated type pairs do not
resolve through this boundary. The exact real named-number evaluator consumes this
mixed resolver only at multiplying nodes. Direct integer literals and earlier
integer named numbers retain their integer carrier and type identity until a mixed
signature is selected; only then are they converted to an exact rational with
denominator 1 for the bounded real carrier operation. Integer atoms in unary,
additive, homogeneous-real, or reverse-division positions remain unsupported.

Real exponentiation uses its own AARM 4.5.6 resolver because the operand types are
not homogeneous. The left operand must be `universal_real` or `root_real`; the
right operand must already have the context-owned `Standard.Integer` identity,
which represents the predefined `Integer'Base` parameter of the operator. Either
supported real left type selects `root_real` as the result. A universal/root
integer right type is not silently accepted by this resolver: Sema supplies the
`Standard.Integer` expected type while evaluating the exponent and owns the final
base-range check before operator selection. Integer-class left operands and all
other signatures remain unresolved so integer exponentiation can follow its own
`Natural` overload path.

`Universal_Integer_Value` is a private checked arbitrary-precision carrier backed
by the Ada 2022 big-integer facility. Construction from canonical decimal text
preflights the magnitude digit count before allocating the big integer and rejects
values beyond the caller-supplied per-value decimal-digit limit with the compiler
resource-limit failure category. The default context limit is 1024 magnitude
digits and the hard supported configuration ceiling is 1024 digits. The
carrier retains its validated magnitude digit count, exposes only bounded
inspection/conversion operations, and rejects an invalid default value.

This is an implementation resource boundary, not a semantic range for Ada
`universal_integer`. The carrier itself can therefore represent values well beyond
`Long_Long_Integer`, while conversion to `Long_Long_Integer` is an explicit
checked operation used only when a supported specific-Integer boundary requires a
host-sized value. The current Sema exact integer evaluator carries this
representation together with a selected context-owned `Type_ID` through its
postorder value stack, so named-number intermediates do not narrow merely because
the eventual use may be a specific Integer context. Keeping the big representation
private prevents semantic bindings from depending on GNAT storage details and
permits later arithmetic/resource refinements without changing binding identity.

Carrier arithmetic is exact inside the admitted digit envelope. The type layer
provides sign/zero inspection plus bounded unary negation, absolute value,
addition, subtraction, multiplication, integer division, remainder, modulus, and
nonnegative exponentiation. Every operation validates both operands against the
requested per-value decimal-digit limit. Addition/subtraction may form at most one
extra decimal digit before the exact result is checked; multiplication rejects a
result whose minimum possible magnitude already exceeds the limit before the big
product is formed. Division, remainder, and modulus reject a zero divisor as an
internal precondition violation and cannot increase operand magnitude. Power uses
constant-time special cases for bases 0, 1, and -1, bounds any remaining exponent
by the configured result envelope, and performs logarithmic exponentiation by
squaring through the same bounded multiplication primitive. Source diagnostics
for zero divisors or negative exponents remain the caller's responsibility.

Creating predefined types does not intern the source spellings `Integer`,
`Natural`, `Positive`, or `Boolean` in the symbol store. Frontend symbol counts
remain a property of source syntax. `Adac.Compilation.Types` classifies an
already context-owned source `Symbol_ID` by non-mutating existing-symbol lookup as
one of the supported predefined integer subtypes, and a separate Boolean lookup
resolves direct `Boolean` or the exact expanded `Standard.Boolean` form. The
integer boundary likewise accepts `Standard.Integer`, `Standard.Natural`, and
`Standard.Positive`; no other package prefix is interpreted by these narrow
paths. The three integer subtype names resolve to the same context-owned Integer
`Type_ID`; `Natural` and `Positive` additionally carry fixed semantic constraints
`0 .. Integer'Last` and `1 .. Integer'Last`. `Boolean` resolves to its distinct
context-owned `Boolean_Type` identity. The symbol store remains the single owner
of identifier case policy: standard Ada mode accepts canonical-equivalent casing,
while the nonstandard case-sensitive mode requires the exact Standard spelling.
Lookup creates no symbol, type, semantic entity, visibility edge, overload
candidate, or runtime slot.
The predefined Boolean literal resolver follows the same non-mutating rule for
`False` and `True`. An unresolved symbol returns an explicit not-found status and
an invalid type identity rather than using `False` as a sentinel; a resolved
literal always carries the context-owned `Standard.Boolean` `Type_ID`.

A procedure-local full Boolean constant uses one typed atom resolver over that
predefined boundary and the procedure lexical scope. Its nominal subtype must be
direct `Boolean` or the exact expanded `Standard.Boolean`. Its initializer may be
an unshadowed direct predefined Boolean literal, an earlier static Boolean
constant name, parenthesized/unary-`not` compositions, ordinary homogeneous
`and`/`or`/`xor`, or short-circuit `and then`/`or else` combinations of those
forms. Lexical lookup precedes predefined fallback: an earlier Boolean constant
supplies its retained value, while any other binding with that name blocks the
fallback. The Boolean evaluator uses explicit frames rather than source recursion
and preserves the same `Standard.Boolean` expected/result type across all current
operators. All six predefined Boolean relations evaluate both operands under that
same Boolean type and return the predefined Boolean result; ordering uses
`False_Boolean_Value` before `True_Boolean_Value`, matching `Standard.Boolean`
declaration order. For a short-circuit form it evaluates the left relation first and does not evaluate a right relation whose
value is statically irrelevant, while still requiring that right relation to have
a supported static-Boolean shape. The
semantic binding retains the shared `Type_ID` and fixed `Boolean_Value`; it does
not allocate another type, runtime local, object entity, stack slot, or IR
instruction. This is intentionally narrower than general Boolean expression
support.

A local subtype declaration binds its new name to the same underlying `Type_ID`
as its resolved subtype mark. The declaration itself and that type association
are retained by the procedure lexical scope, so source-level subtype identity is
not inferred from spelling or collapsed out of semantic validation. Ada subtype
declarations do not declare new types: the current direct integer range form,
for example `subtype Small is Integer range 1 .. 10;`, is retained separately as
one fixed-size semantic `Subtype_Constraint` containing its checked lower and
upper integer bounds. An unconstrained child inherits its parent's constraint;
a new explicit range must fit the constrained parent. No constrained subtype
allocates a distinct base `Type_ID` or runtime object slot.

## Current Support Boundary

The current scalar integration accepts direct `Integer`, `Natural`, and `Positive`
subtype marks, their explicit `Standard.Integer`, `Standard.Natural`, and
`Standard.Positive` expanded-name forms, plus earlier supported local subtype
names, for local variable
object declarations in a context-free top-level procedure. All currently
supported integer subtypes use the same context-owned Integer `Type_ID`; nominal
subtype constraints remain separate semantic metadata. Assignment uses that base
`Type_ID` as the expected type of a direct local assignment expression and the
object's retained constraint as the narrower range check, following the AARM 5.2
assignment context.
An integer literal can therefore satisfy a `Standard.Integer` target through its
universal integer interpretation; a real literal does not satisfy the current
integer target. A direct local RHS instead resolves to the source object's stored
`Type_ID` and is accepted only when that type equals the current target type. The
context owns distinct `universal_integer` and `root_integer` `Type_ID` values.
Procedure-local integer named numbers retain the universal identity and a private
arbitrary-precision universal value. During their initializer evaluation, literal
and named-number atoms begin as `universal_integer` when no specific expected type
exists; unary and homogeneous binary predefined operators select and retain the
`root_integer` result identity through the exact postorder stack. In the number declaration's any-numeric context, an earlier typed static Integer
constant or supported scalar subtype `First`/`Last` attribute retains its specific
Integer `Type_ID`; a universal literal or earlier integer named number retains
`universal_integer`. Homogeneous predefined operator resolution combines those
identities without relabeling the typed atom. At the number declaration boundary,
any supported completed integer static result is converted back to the named
number's `universal_integer` identity without changing its exact value. For
integer exponentiation the left operand follows the selected result type while the
right operand is resolved in the predefined `Natural` context, represented by the
shared `Standard.Integer` `Type_ID` plus a final `0 .. Integer'Last` check. Large
static intermediates inside that exponent expression remain exact; only the final
exponent value must satisfy `Natural`. Mutable/full-constant object initializers, static assignment RHS expressions, and
local subtype range bounds pass their expected Integer `Type_ID` into this exact
path and perform base/subtype or parent-range checks only on completed values. Full
constants and subtype declarations retain no additional runtime type identity or
slot. This does
not change runtime scalar identity or lowering.


A procedure-local number declaration may retain an exact real static expression as
a `universal_real` binding. Real atoms are direct decimal/based real literals or
earlier real named numbers. Parentheses preserve the atom/operator type; unary
`+`, `-`, and `abs`, additive `+`/`-`, and homogeneous real `*`/`/` select
`root_real` through the predefined-real resolver while exact values remain in the
bounded rational carrier. At the number-declaration boundary the completed result
is published with `universal_real` identity, without changing its exact value.
Decimal literal normalization removes the radix point and applies the decimal
exponent as a power of ten; based real normalization applies the exponent as a
power of the literal's specified base. Trailing fractional zero digits are
discarded before forming the scale so they do not consume artificial resource
headroom. This is a compile-time-only path: it declares no runtime real scalar
type and does not make a real value compatible with the current Integer target.

The literal evaluator accepts complete represented decimal and based integer
literals on the RHS of a supported local `Integer` assignment, as an explicit
initializer of a supported local `Integer` variable, or as an atom in the current
range-bound static evaluator. Range-bound evaluation additionally accepts unary
`+`/`-` over an integer literal, direct supported integer subtype `S'First` and
`S'Last` attribute atoms, parenthesized compositions of current static forms,
left-associated binary multiplying `*`/`/`/`rem`/`mod` terms, and left-associated
binary adding `+`/`-` chains. Attribute prefixes are direct supported subtype names or the exact expanded
`Standard.Integer`/`Natural`/`Positive` forms resolved through the same subtype
boundary; unconstrained `Integer` aliases use the
base type bounds and constrained predefined/local subtypes use their retained
nominal bounds. The static integer evaluator uses explicit evaluation-frame and value vectors rather
than source-controlled recursion, so parenthesized grouping and operator
application are processed iteratively. It retains bounded arbitrary-precision
intermediates together with their selected `Type_ID`; a specific consumer supplies
its expected operator type, while base-range and nominal/parent subtype checks are
applied only to the completed value at that boundary. The evaluator rejects zero
divisors before division/remainder/modulus and preserves Ada `rem` sign-of-left and
`mod` sign-of-right semantics. Large exponents cannot cause unbounded repeated work: for a nonzero value,
an exponent beyond the useful i32 range is rejected before exponentiation; zero
remains zero after a syntactically valid exponent.

A direct local `Integer` read is now supported only as the complete RHS of the
bounded local assignment form and only after the source has an explicit
initializer or earlier supported assignment. The semantic layer retains that
known integer value so a copy into a narrower constrained subtype can be checked
before publication. Concatenation, range-bound names or
attributes beyond the supported-subtype `First`/`Last` atoms, expanded
subtype names outside package `Standard`, conversions, compound reads, general
initialization expressions,
user-defined types, integer atoms outside the three supported mixed
real/integer multiplying signatures, universal expressions outside the current
procedure-local static-number boundary,
overload sets, and predefined subtypes beyond
`Natural` and `Positive` remain unsupported
until their own vertical slices are defined. Static full Integer constants are
handled as compile-time lexical bindings as described by `semantic-model.md`. An
unsupported subtype,
assignment expression, initializer expression, or undefined local read is an
ordinary source diagnostic produced before any semantic entity is published. A
malformed or foreign `Type_ID` is instead an internal contract violation.

## Allocation And Validation

Type IDs are stable for the lifetime of their owning context. Appending future
types shall not invalidate earlier IDs or reuse a live index. Representable index
or allocator exhaustion raises `Storage_Error`; an identifier shall never wrap.

Validation is deterministic and side-effect free. In-process tests cover all
six predefined type identities, the Integer bounds, integer universal/root-kind
separation, the compile-time-only universal/root-real identities, homogeneous predefined-
integer and real operator selection, rejection of signed-range queries for every non-signed
identity, invalid and foreign `Type_ID` values, invalid universal value carriers,
exact rational reduction, component resource limits, and independent compilation
contexts.
