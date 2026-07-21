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

- `procedure_name` is not empty;
- `end_name` is not empty;
- `statements` contains at least one statement.

Every `Statement` contains an Ada enumeration value, so ordinary construction
already constrains its kind to the declared `Statement_Kind` values.

The validator does not require `procedure_name` and `end_name` to match. Name
matching is a language rule interpreted using compilation language options and
therefore remains the responsibility of semantic analysis.

Additional source-span, node-identity, ownership, declaration, expression, and
statement invariants shall be added with the corresponding AST structures. The
validator shall not contain speculative rules for representations that do not
yet exist.

## Validation Boundaries

`Adac.Frontend.Parser.parse_file` validates a successful parse before returning
its AST payload. This catches a parser defect at the stage that created the
malformed representation.

`Adac.Sema.analyze` validates its borrowed compilation unit before performing
semantic checks. This protects the semantic boundary when a caller supplies a
compilation unit from another internal producer.

Validation does not transfer ownership and does not modify the compilation
unit. The initial checks are constant time. Future checks that traverse the AST
shall remain deterministic and bounded by the size of the validated
representation or by documented compilation resource limits.

## Failure Contract

If validation fails, semantic analysis and IR construction do not run. No
ordinary source diagnostic is recorded for the malformed internal object, and
the internal failure propagates to the top-level compiler boundary.

## Tests

In-process tests shall cover:

- a valid minimal compilation unit;
- an empty procedure name;
- an empty end name;
- an empty statement list;
- structurally valid but semantically mismatched names;
- deterministic rejection through `Program_Error`.

Existing end-to-end parser and semantic tests verify that malformed source is
still rejected through ordinary diagnostics.
