# IR Validation

This document defines the initial validation contract for Adac's
target-independent intermediate representation.

## Purpose

IR validation detects malformed internal compiler state before a later stage
consumes or publishes it. It does not diagnose invalid Ada source and does not
replace parser or semantic analysis checks.

A validation failure is an internal compiler contract violation. It raises
`Program_Error` and shall not be converted into an ordinary source diagnostic,
an operational backend failure, or successful fallback behavior.

## Initial Module Invariants

The current minimal `Adac.IR.Module` is valid only when:

- `entry_name` is not empty;
- `instructions` contains at least one instruction.

Every `Instruction` contains an Ada enumeration value, so ordinary construction
already constrains its kind to the declared `Instruction_Kind` values.

The initial validator does not require an explicit terminal instruction. The
current native backend provides the documented process return sequence when a
valid instruction list has no explicit `Return_Instruction`.

Additional type, reference, ownership, block, and termination invariants shall
be added with the corresponding typed and control-flow IR structures. The
validator shall not contain speculative rules for representations that do not
yet exist.

## Validation Boundaries

`Adac.IR.Builder.build` validates a module before returning it. This catches a
builder defect at the stage that created the malformed representation.

`Adac.Backend.emit` validates its borrowed module before producing an IR dump,
temporary file, assembly file, executable, or other published output. This
protects the backend boundary when a caller supplies a module from another
internal producer.

Validation does not transfer ownership and does not modify the module. The
initial checks are constant time. Future checks that traverse IR shall remain
deterministic and bounded by the size of the validated representation or by
documented compilation resource limits.

## Failure And Output Contract

Validation completes before any backend-visible output is emitted. If
validation fails:

- no IR dump is written;
- no backend temporary file is created;
- no final output is published;
- the internal failure propagates to the top-level compiler boundary.

Operational failures that occur after successful validation remain governed by
`failure-model.md` and the backend emission-result contract.

## Tests

In-process tests shall cover:

- a valid minimal module;
- an empty entry name;
- an empty instruction list;
- deterministic rejection through `Program_Error`.

Existing end-to-end compiler tests verify that valid frontend and semantic
output continues through IR construction and backend publication.
