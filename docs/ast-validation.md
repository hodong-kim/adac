# AST Validation

This document defines the initial validation contract for Adac's abstract
syntax tree.

## Purpose

AST validation detects malformed internal syntax state before a later compiler
stage consumes it. It does not diagnose invalid Ada source and does not replace
parser or semantic analysis checks.

A validation failure is an internal compiler contract violation. It raises
`Program_Error` and shall not be converted into an ordinary source diagnostic
or a rejected semantic-analysis result.

## Initial Compilation Unit Invariants

The current minimal `Adac.AST.Compilation_Unit` is valid only when:

- `procedure_symbol` is a structurally valid `Symbol_ID`;
- `end_symbol` is a structurally valid `Symbol_ID`;
- `statements` contains at least one statement.
- the compilation-unit source span is structurally valid;
- every statement source span is structurally valid and contained by the unit
  span.

Every `Statement` contains an Ada enumeration value, so ordinary construction
already constrains its kind to the declared `Statement_Kind` values.

The validator does not require `procedure_symbol` and `end_symbol` to match.
Name matching is a language rule interpreted by the context-owned symbol store
and therefore remains the responsibility of semantic analysis.

Additional source-span, node-identity, ownership, declaration, expression, and
statement invariants shall be added with the corresponding AST structures. The
validator shall not contain speculative rules for representations that do not
yet exist.

## Validation Boundaries

`Adac.Frontend.Parser.parse_file` validates a successful parse before returning
its AST payload. This catches a parser defect at the stage that created the
malformed representation.

`Adac.Compilation.Syntax.validate` combines structural AST validation with
source-span and symbol ownership checks for one compilation context.

`Adac.Sema.analyze` runs context-aware validation before semantic checks. This
protects the semantic boundary when a caller supplies a compilation unit from
another internal producer.

`Adac.IR.Builder.build` repeats context-aware validation before lowering.

Validation does not transfer ownership and does not modify the compilation
unit. Validation is linear in the number of statements and allocates no
storage. Future checks shall remain deterministic and bounded by the size of
the validated representation or by documented compilation resource limits.

## Failure Contract

If validation fails, semantic analysis and IR construction do not run. No
ordinary source diagnostic is recorded for the malformed internal object, and
the internal failure propagates to the top-level compiler boundary.

## Tests

In-process tests shall cover:

- a valid minimal compilation unit;
- an invalid procedure symbol;
- an invalid end symbol;
- an empty statement list;
- invalid and non-containing source spans;
- a source span owned by another compilation context;
- a symbol owned by another compilation context;
- structurally valid but semantically mismatched names;
- deterministic rejection through `Program_Error`.

Existing end-to-end parser and semantic tests verify that malformed source is
still rejected through ordinary diagnostics.
