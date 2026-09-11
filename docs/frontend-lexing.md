# Frontend Lexing

This document defines the current lexical contract for Adac source input. It
covers token boundaries, identifier spelling, and initial literal tokenization
without claiming support for Ada constructs that later parser and semantic
stages do not yet represent.

## Character Boundary

The scanner consumes the bounded `Character` stream defined by the frontend
source contract. The current identifier subset is ASCII-only. Unicode source
encoding, normalization, and identifier classification require a separate
contract before the accepted character set expands.

Characters outside a supported lexical form remain unknown input. They do not
become identifiers through locale-dependent classification. Scanner control
characters are named through `Ada.Characters.Latin_1`; the Annex J `Standard.ASCII`
package is outside the repository's Ada 2022 source subset.

## Identifiers

A valid identifier in the current frontend satisfies these rules:

- the first character is an ASCII letter;
- later characters may be ASCII letters, decimal digits, or underscores;
- two underscores may not be adjacent;
- the final character may not be an underscore.

The lexer consumes one maximal identifier-like sequence beginning with an ASCII
letter or underscore. A sequence that violates the spelling rules becomes one
`Tok_Invalid_Identifier` token rather than several misleading tokens. The
parser reports one ordinary `invalid identifier` diagnostic at the first
character and rejects the parse without publishing a root `Node_ID`.

A decimal digit does not begin an identifier.

## Decimal Literals

The current numeric-literal slices recognize decimal integer and real literals.
A numeral begins with an ASCII decimal digit. Single underscores may separate
digits, but an underscore may not lead, trail, or directly follow another
underscore.

A decimal real literal contains a point followed by another numeral. The
fractional numeral is required, so `123.` is malformed. The scanner preserves
the exact source spelling and does not convert a literal to a numeric value.

An exponent begins with `E` or `e`, may contain one `+` or `-` sign, and requires
another valid numeral. The scanner preserves the exact source spelling in the
token. The legality rule that forbids a negative exponent on an integer literal
belongs to later semantic work; this lexical slice does not evaluate values or
apply type rules.

A valid spelling without a point becomes `Tok_Decimal_Integer_Literal`; a valid
spelling with a point becomes `Tok_Decimal_Real_Literal`. A malformed numeral,
fraction, or exponent becomes one `Tok_Invalid_Numeric_Literal`. When an ASCII
identifier character immediately follows a decimal literal without a separator,
the scanner consumes the complete numeric-like sequence as one invalid token so
that `2main` and `1.0main` do not become misleading valid token sequences.

## Based Literals

A based literal begins with a decimal base numeral, followed by `#`, a based
numeral, an optional point and second based numeral, a closing `#`, and an
optional decimal exponent. Based numerals use ASCII decimal digits and letters
`A` through `F`, case-insensitively. Single underscores may separate extended
digits under the same placement rules used by decimal numerals.

A valid spelling without a point becomes `Tok_Based_Integer_Literal`; a valid
spelling with a point becomes `Tok_Based_Real_Literal`. After the opening `#`,
the scanner consumes one maximal based-literal-like sequence. A malformed based
numeral, fraction, delimiter, exponent, or adjacent identifier becomes one
`Tok_Invalid_Numeric_Literal` rather than several misleading tokens.

This lexical slice does not evaluate the base or extended-digit values. The
legality requirements that the base is in `2 .. 16` and each extended digit is
less than the base belong to later semantic analysis with numeric value
conversion. Lexically valid tokens may therefore remain semantically illegal.

The lexer preserves exact spelling and performs no numeric conversion. The
semantic scalar integration path now interprets represented integer literals only
when an enclosing supported assignment or local initializer supplies a concrete
expected `Integer` type; that conversion remains outside this lexical boundary.
The frontend may publish a `Numeric_Literal_Node` for any of the four valid
current token forms when an enclosing production path requests represented
primary syntax. The node stores only lexical form, spelling, and span. Ordinary
standalone literal expressions, including those encountered after `return`,
retain their precise unsupported-expression diagnostic until their enclosing
expression and statement forms are represented.

## Character Literals

The current character-literal slice recognizes one ASCII graphic character,
including space, between two apostrophes. A literal therefore occupies exactly
three source characters. The apostrophe character itself is written as three
consecutive apostrophes: `'''`.

The scanner uses bounded two-character lookahead to distinguish a character
literal from the single apostrophe delimiter without depending on parser
context. A valid spelling becomes `Tok_Character_Literal`. An apostrophe that
does not begin a valid current-subset literal becomes `Tok_Apostrophe` and
remains available for attribute and qualified-expression parsing.

Unicode and non-ASCII graphic characters require a source-encoding and
character-classification contract before this subset expands. When represented
primary syntax is requested, a valid current character literal may publish one
`Character_Literal_Node` containing its exact three-character source spelling and
span. The node does not decode a value or select a character type. A lone
apostrophe where a character literal is required retains the precise
`invalid character literal` diagnostic.

## String Literals

The current string-literal slice recognizes zero or more ASCII graphic
characters between quotation marks. A quotation mark inside the value is
written as two adjacent quotation marks. The scanner preserves the exact source
spelling, including doubled quotation marks, without decoding the value.

A valid spelling becomes `Tok_String_Literal`. A string that reaches a line
boundary or end of file without an unmatched closing quotation mark becomes one
`Tok_Invalid_String_Literal`. The scanner does not continue a string literal
across a line boundary. Non-ASCII and nongraphic characters are invalid in the
current subset and require the source-encoding contract to expand first.

`Tok_String_Literal` remains the lexical representation when a string literal
appears where an operator symbol may occur. The lexer does not create a second
operator-symbol token or decide whether the contained sequence names an Ada
operator. In a selected-component selector position, the parser accepts only
the spellings defined by the operator-token contract below. Other valid or
malformed string-literal spellings in that position are invalid operator
symbols.

The lexer itself does not publish expression syntax. When an expression caller
requests represented syntax, a valid current token may publish one
`String_Literal_Node` preserving its exact spelling and span without decoding a
value or assigning a type. A valid string literal encountered after `return`
still receives one precise unsupported-expression diagnostic. An invalid
spelling receives one `invalid string literal` diagnostic. Both paths reject the
parse
before statement or compilation-unit publication.

## Operator Tokens

Every spelling in the current Ada operator categories has one dedicated token
kind. Word operators are recognized case-insensitively while retaining exact
source spelling:

```text
and or xor mod rem abs not
```

The delimiter operators are:

```text
= /= < <= > >= + - & * / **
```

The lexer classifies spelling only. It does not decide whether `+` or `-` is
unary or binary, apply operator precedence, associate operands, or resolve an
overload. Membership and short-circuit grammar remains a parser responsibility.
The reserved words `in`, `then`, `elsif`, and `else` therefore have dedicated
tokens but are not added to the operator-symbol classifier.

String literals used as operator-symbol selectors remain
`Tok_String_Literal`; selector validation uses the same operator-spelling
classification as direct operator tokens rather than maintaining another list.

## Delimiters

A full stop that is not consumed inside a numeric literal becomes one `Tok_Dot`
token. The compound delimiter `..` becomes `Tok_Double_Dot`, and `=>` becomes
`Tok_Arrow`. Compound delimiters are recognized before their component
single-character delimiters. In particular, decimal tokenization leaves a full
stop for `Tok_Double_Dot` when the following character is another full stop, so
`1..10` becomes an integer literal, double dot, and integer literal rather than
a malformed real literal.

Left and right parentheses become `Tok_Left_Parenthesis` and
`Tok_Right_Parenthesis`; left and right square brackets become
`Tok_Left_Bracket` and `Tok_Right_Bracket`. A comma becomes `Tok_Comma`, and a
vertical bar becomes `Tok_Vertical_Bar`. A colon becomes `Tok_Colon`, and the
compound delimiter `:=` becomes `Tok_Assign`. The compound delimiter `<>`
becomes `Tok_Box`. The lexer preserves each delimiter independently and does not
combine a prefix with delimited text. Name structure, delimiter balance,
aggregate associations, and symbol ownership remain parser responsibilities.
This keeps one lexical representation available for selected names,
parenthesized name forms, and expression syntax. The operator delimiters listed
above have dedicated token kinds. Unsupported compound delimiters `<<` and `>>`
remain one `Tok_Unknown` lexical element rather than being split into
misleading component tokens. Other delimiters remain outside the current subset
unless already documented.

## Reserved Words

After a spelling is validated, the lexer compares it case-insensitively with the
reserved words supported by the current grammar. The explicit-dereference slice
adds `all` as `Tok_All`. Expression staging adds `in` as `Tok_In`, `then` as `Tok_Then`, and `else` as
`Tok_Else`. Represented conditional-statement staging adds `elsif` as `Tok_Elsif`;
initial statement staging adds `if` as `Tok_If`. Bounded raise-statement staging adds `raise` as `Tok_Raise`. Initial
exception-handler staging adds `exception` as `Tok_Exception`.
Classic aggregate staging adds `others` as `Tok_Others`, `with` as `Tok_With`,
and `record` as `Tok_Record`. Discrete subtype-choice staging adds `range` as
`Tok_Range`. Digits-constraint staging adds `digits` as `Tok_Digits`.
Parenthesized delta-aggregate staging adds `delta` as `Tok_Delta`. Initial
iterated-association staging adds `for` as `Tok_For`. Basic
iterator-specification staging adds `of` as `Tok_Of`. Statement iterator-loop
header staging adds `loop` as `Tok_Loop`. Reverse-`of` iterator staging adds
`reverse` as `Tok_Reverse`. Iterator-filter staging adds `when` as
`Tok_When`. Container iterated-key staging adds `use` as `Tok_Use`.
Access-to-object iterator subtype staging adds `access` as `Tok_Access` and
`constant` as `Tok_Constant`. Parameterless access-to-procedure staging adds
`protected` as `Tok_Protected`; `procedure` already uses `Tok_Procedure`.
Package compilation-unit staging adds `package` as `Tok_Package`. Generic package
instantiation staging adds the AARM 2.9 reserved word `new` as `Tok_New`; it is
never accepted as an identifier even when a surrounding generic form remains
unsupported. Package-body header staging adds `body` as `Tok_Body`; the spelling
is reserved independently of whether a complete package body is representable
yet. Subunit compilation-unit staging adds `separate` as `Tok_Separate`; its
parent-unit name remains ordinary identifier-selected program-unit-name syntax.
The selected AST-package
private-type staging adds `type` as `Tok_Type` and `private` as `Tok_Private`.
The selected limited-private continuation adds `limited` as `Tok_Limited`; all
three spellings remain reserved independently of semantic type support.
Initial block-statement
staging adds `declare` as `Tok_Declare`; it is reserved even while block ownership
and bodies remain unsupported. Initial case-statement staging adds `case` as
`Tok_Case`; its spelling is reserved before case-alternative ownership exists.
Parameterless access-to-function staging adds `function` as `Tok_Function`;
`return` already uses `Tok_Return`. Ada 2022 exit-statement staging adds `exit` as
`Tok_Exit`; it is reserved independently of whether a particular statement
context can resolve an enclosing loop. Selected extended-return staging adds `do` as
`Tok_Do`, reserved independently of whether broader extended-return forms are
represented. Formal-parameter staging adds `aliased` as
`Tok_Aliased` and `out` as `Tok_Out`; explicit `in` continues to use `Tok_In`.
Parameter-aspect staging and basic nonlimited with-clause staging reuse the
existing `Tok_With`. The production exception-handler boundary likewise reuses
existing `Tok_When`, `Tok_Others`, and `Tok_Arrow` tokens after the new keyword.
The `Class` spelling in an aspect mark is context-sensitive rather than
reserved: the lexer continues to return `Tok_Identifier` for any case variant
of `Class`, and the formal-parameter parser recognizes it only after an
aspect-mark apostrophe. Word operators are likewise reserved and receive their
dedicated operator token kinds. Exact source case remains in token text.
These reserved spellings cannot be interned or accepted where an identifier is
required. A valid spelling that is not a supported reserved word becomes
`Tok_Identifier`.

The symbol store owns identifier canonicalization after tokenization. Standard
Ada mode interns spellings case-insensitively, while the existing nonstandard
case-sensitive mode preserves exact matching. The interning contract remains in
`compiler-symbols.md`.

## Failure And Resource Contract

Source-character accounting applies before every character read, including
characters collected into an identifier, numeric literal, character literal,
or string literal. Budget exhaustion interrupts scanning before an incomplete
token is returned and follows `resource-limits.md`.

Malformed identifier or numeric-literal spelling is an expected source failure.
An apostrophe used where a character literal is expected is also an expected
source failure. A malformed string literal is an expected source failure.
Unsupported numeric, character, and string literal expressions are expected
source failures. None of these paths appends an AST node, enters semantic
analysis, or publishes backend output. Internal scanner-state violations remain
`Program_Error`.

## Tests

Tests shall cover:

- a valid identifier containing separated underscores and a decimal digit;
- rejection of a leading underscore;
- rejection of adjacent underscores;
- rejection of a trailing underscore;
- no symbol or AST publication after identifier-spelling rejection;
- unchanged case-insensitive reserved-word and symbol behavior;
- case-insensitive `all` tokenization with exact spelling preservation;
- rejection of reserved `all` where an identifier is required;
- a decimal integer literal containing separated underscores and an exponent;
- rejection of adjacent or trailing underscores in a numeral;
- rejection of a missing separator before an adjacent identifier;
- one unsupported-expression diagnostic for a valid decimal integer literal;
- no successful statement, root, semantic, IR, or backend publication after
  numeric-literal rejection;
- a decimal real literal containing separated underscores and an exponent;
- rejection of a decimal point without a fractional numeral;
- rejection of malformed underscores in a fractional numeral;
- rejection of a missing separator after a decimal real literal;
- a based integer literal with extended digits and an exponent;
- a based real literal with a fraction and an exponent;
- rejection of a leading underscore in a based numeral;
- rejection of a character outside `A` through `F` in a based numeral;
- rejection of a missing closing based-literal delimiter;
- rejection of a missing separator after a based literal;
- ordinary ASCII and space character literals;
- the apostrophe character literal;
- preservation of a standalone apostrophe delimiter and following identifier;
- rejection of empty and multi-character literal spellings;
- represented character-literal spelling/span ownership and expression use;
- no AST or semantic publication after character-literal rejection;
- ordinary and empty ASCII string literals;
- preservation of doubled quotation marks in a string literal;
- rejection of a string literal terminated by a line boundary or end of file;
- one unsupported-expression diagnostic for a valid string literal;
- no AST or semantic publication after string-literal rejection;
- character-literal and operator-symbol tokens in selector position;
- case-insensitive recognition of a word operator symbol;
- rejection of a nonoperator string literal in selector position;
- dedicated tokens for every current Ada operator spelling;
- case-insensitive word-operator tokenization with exact spelling retention;
- shared operator-spelling classification for direct tokens and selectors;
- case-insensitive `in`, `then`, `elsif`, `else`, `if`, `raise`, and `exception`
  tokens with exact spelling retention;
- case-insensitive `declare` classification as `Tok_Declare` while retaining exact
  token spelling;
- case-insensitive `case` classification as `Tok_Case` while retaining exact token
  spelling;
- rejection of expression, statement, and exception-handler reserved words
  where an identifier is required;
- single-minus tokenization without regressing `--` comment recognition;
- preservation of `<<` and `>>` as one unknown token each;
- preservation of `<>` as one `Tok_Box` compound delimiter;
- case-insensitive `others`, `with`, and `record` tokens with exact spelling;
- case-insensitive `range` tokenization with exact spelling preservation;
- case-insensitive `digits` tokenization with exact spelling preservation;
- case-insensitive `delta` tokenization with exact spelling preservation;
- case-insensitive `for`, `of`, `loop`, `reverse`, `when`, `use`, `access`,
  `constant`, `protected`, `function`, `aliased`, `out`, `type`, and `private`
  tokenization with exact spelling;
- rejection of aggregate, range, digits, delta, `for`, `of`, `loop`, `reverse`,
  `when`, `use`, `access`, `constant`, `protected`, `function`, `aliased`, `out`,
  `type`, and `private` reserved words where an identifier is required;
- rejection of a word operator where an identifier is required;
- preservation of a full stop as a standalone `Tok_Dot` delimiter;
- preservation of `..` as one `Tok_Double_Dot`, including after an integer
  without whitespace;
- preservation of `=>` as one `Tok_Arrow`;
- preservation of `|` as one `Tok_Vertical_Bar`;
- preservation of `:` as one `Tok_Colon` and `:=` as one `Tok_Assign`
  compound delimiter;
- preservation of left and right parentheses, left and right square brackets,
  and comma as standalone tokens;
- unchanged end-to-end compilation for the existing minimal subset.
