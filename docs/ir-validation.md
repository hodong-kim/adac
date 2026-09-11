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

The current `Adac.IR.Module` is valid only when:

- `entry_name` is not empty;
- every local has a nonempty deterministic source name;
- every local has a supported target-independent scalar type;
- every integer constant has the signed-32 integer scalar type, fits that type,
  and carries no Boolean or local-load payload;
- every Boolean constant has the Boolean scalar type, carries exactly one Boolean
  value, and carries no integer or local-load payload;
- every local-load value references an existing local whose scalar type matches
  the value type and carries no constant/operator payload;
- every Boolean-not value has Boolean type, references one earlier Boolean value,
  and carries no constant/local or right-operand payload;
- every Boolean binary value has Boolean type, an explicit
  `and`/`or`/`xor`/`=`/`/=`/`<`/`<=`/`>`/`>=` operator, references two earlier
  Boolean values, and carries no constant/local payload;
- every Boolean `and then`/`or else` value has Boolean type, references two earlier
  Boolean values, and carries no constant/local/eager-operator payload; its value
  kind itself identifies the short-circuit form;
- every computed Boolean-not/binary/short-circuit value has at most one
  computed-value or store
  consumer, so the current runtime Boolean graph is a forest rather than a shared
  expression DAG;
- null/return instructions carry no local-store operands;
- every local-store instruction references an existing local and existing value,
  and the stored value type matches the target local type; and
- `instructions` contains at least one instruction.

The target-independent scalar kinds currently include signed 32-bit integer and
Boolean. `Signed_Integer_32_Type` is the explicit IR lowering of semantic
`Standard.Integer`. `Boolean_Type` is the explicit IR lowering of semantic
`Standard.Boolean` and carries only language-level Boolean identity; it does not
specify a native stack width, register class, truth coding, or ABI type. Locals are ordered by semantic
declaration order and are addressed by their one-based module-local position.
Module-owned values are addressed by stable one-based `Value_ID` values.
`Integer_Constant_Value` stores a signed-32 target-independent integer constant.
`Boolean_Constant_Value` stores one target-independent Boolean constant as a host
compiler `Boolean`; its target coding is chosen only by the backend.
`Local_Load_Value` stores one source local ordinal and represents reading that
local when a consuming instruction evaluates the value. `Store_Local_Instruction`
references one target local position and one value ID; neither value nor
instruction encodes a native offset, register, or machine instruction.

An uninitialized local declaration alone still implies no write. A supported
explicit local `Integer` initializer lowers to an integer constant plus local
store; a supported mutable Boolean initializer analogously lowers to a Boolean
constant plus local store. A checked static Boolean assignment in the procedure body lowers through that
same Boolean-constant/store representation. A checked direct Boolean local copy lowers
to a Boolean `Local_Load_Value` plus store, using the same local ordinals and scalar
type validation as the existing Integer copy path. Unary runtime Boolean `not`
lowers to a Boolean local load followed by one `Boolean_Not_Value` that references
that earlier load; the store consumes the not result. Ordinary runtime Boolean
`and`/`or`/`xor`, equality `=`/`/=`, and ordering `<`/`<=`/`>`/`>=` lower to
two Boolean local loads followed by one `Boolean_Binary_Value` that references
both loads and retains the language-level operator. Runtime Boolean operator values may reference any earlier Boolean constant, local
load, not, or binary value. Earlier-value ordering prevents cycles and forward
references. The current single-consumer rule for computed Boolean values keeps
each executable expression graph tree-shaped, so iterative backend expansion is
linear in represented values and cannot duplicate a shared subgraph
exponentially. Sema emits these tree-shaped graphs for supported mixed/nested eager
Boolean assignment expressions, preserving mutable-local loads and folding maximal
static subtrees to Boolean constants. A direct-local runtime short-circuit
assignment lowers two local-load value descriptions followed by one distinct
`Boolean_And_Then_Value` or `Boolean_Or_Else_Value`. Earlier placement of the
right-load description does not mean eager execution: values are evaluated only
when a consuming instruction walks the graph. Short-circuit evaluation therefore
visits the left value first and conditionally bypasses the right value. Initializer
stores appear in semantic local declaration order before instructions lowered
from the procedure body,
preserving the current declaration elaboration order without introducing a
backend-specific initialization opcode. A supported direct local RHS lowers to
one `Local_Load_Value` consumed by the following local store. Store consumption
therefore fixes the read point in instruction order while keeping machine scratch
registers out of IR. Arithmetic, implicit default initialization, compound reads,
and control-flow value merging remain later IR slices. The validator checks both load-source and store-target type agreement across the
current integer and Boolean scalar kinds, so a value cannot be copied or stored
through a differently typed local.

Every instruction, value, and local type contains an Ada enumeration value, so
ordinary construction constrains its kind to the declared values.

The initial validator does not require an explicit terminal instruction. The
current native backend provides the documented process return sequence when a
valid instruction list has no explicit `Return_Instruction`.

Additional arithmetic values, broader object accesses, block structure, and
termination invariants shall be added with the corresponding language and
control-flow IR structures. The validator shall not contain speculative rules
for representations that do not yet exist.

## Validation Boundaries

`Adac.IR.Builder.build` first validates its semantic entity input through the
compilation context, then validates the constructed module before returning it.
This catches malformed stage input and builder defects at their boundary.

`Adac.Backend.emit` validates its borrowed module before producing an IR dump,
temporary file, assembly file, executable, or other published output. This
protects the backend boundary when a caller supplies a module from another
internal producer.

Validation does not transfer ownership and does not modify the module. Validation
is linear in the represented locals, values, instructions, and Boolean value
edges; the computed-value single-consumer check uses one temporary `Natural`
counter per IR value. Future checks that traverse IR shall remain deterministic
and bounded by the size of the validated representation or by documented
compilation resource limits.

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
- a valid local integer constant/store module, including initializer stores
  before body stores;
- a valid direct local-load/store module for both integer and Boolean locals;
- a valid Boolean local-load/not/store module and nested Boolean-not value graph;
- valid Boolean binary/store modules for `and`, `or`, `xor`, `=`, `/=`, `<`,
  `<=`, `>`, and `>=`, including operands that are earlier Boolean operator
  values;
- valid Boolean `and then`/`or else` value/store modules whose left and right
  operands are earlier Boolean values;
- a valid Boolean constant/store module for both `False` and `True`;
- rejection of integer constants tagged as Boolean and Boolean constants tagged
  as integer;
- an empty entry name;
- an empty instruction list;
- an invalid store local or value reference;
- an invalid local-load source reference or payload;
- invalid Boolean-not type, operand reference/order/type, payload, and repeated
  consumption of one computed operand;
- invalid Boolean-binary operator, type, left/right reference/order/type, payload,
  and repeated consumption of one computed operand;
- invalid Boolean short-circuit type, left/right reference/order/type, eager
  operator payload, and repeated consumption;
- an out-of-range signed 32-bit constant;
- unexpected store operands on null/return instructions; and
- deterministic rejection through `Program_Error`.

Existing end-to-end compiler tests verify that valid frontend and semantic
output continues through IR construction and backend publication.
