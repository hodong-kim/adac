# Target Support

This document defines the target terminology and the current native backend
support boundary for `adac`.

## Target Roles

`adac` distinguishes the following roles.

```text
build host
  The machine that executes Rake and GPRbuild.

compiler target
  The platform where the resulting adac executable runs.

program target
  The platform for code emitted by adac.
```

The current compiler is native-only. Its program target is therefore the same
as its compiler target. A later cross-compiler interface may separate these
roles without changing the build-host and compiler-target model.

## Cross-Build System

The Rake build accepts a compiler target triple through `TARGET` or
`ADAC_TARGET`. For a non-native compiler target, the triple is passed to
GPRbuild through `--target`.

Build products are isolated by compiler target and profile.

```text
build/obj/<compiler-target>/<profile>
build/bin/<compiler-target>/<profile>
build/generated/<compiler-target>/<profile>
```

Rake generates `Adac.Build_Config` in the target-specific generated source
directory. The package records the compiler target triple, architecture,
operating system, and whether the current native backend supports that target.
The generated file is rewritten only when its contents change.

## Native Backend Matrix

The current native backend emits GNU-style x86-64 assembly and invokes a C
compiler driver to assemble and link it.

Supported compiler targets:

```text
x86_64-*-freebsd*
x86_64-*-linux*
```

Unsupported combinations are rejected before backend output files are created.
This prevents a successfully cross-built compiler from silently emitting code
for the wrong architecture or object format.

Darwin, Windows, Android, AArch64, and other targets require target-specific
assembly, object-format, ABI, and toolchain handling before they may be enabled.

## Initial Local Stack Storage

The first end-to-end local scalar slice lowers each current 32-bit signed integer
IR local to one native stack slot. When a module has no locals, native assembly
remains byte-for-byte compatible with the existing minimal path. When locals are
present, the x86-64 backend emits a conventional frame-pointer prologue, reserves
a frame size rounded up to a 16-byte boundary, and emits the matching epilogue on
every generated return path.

The IR contains no native offsets. The backend derives layout deterministically
from ordered local metadata, checks frame-size arithmetic before emission, and
does not initialize an Ada scalar object that has no explicit initialization
expression.

The current scalar store path lowers a signed 32-bit integer constant plus
`Store_Local_Instruction` to one `movl` immediate store at the derived x86-64
stack slot. The same target-independent operation is used for an explicit local
integer initializer and a later static-expression assignment after semantic
folding has reduced either expression to one checked integer constant. Initializer
stores are emitted in local declaration order before body instructions.

Procedure-local static integer constants are compile-time lexical bindings in the
current subset. Their initializer is folded before semantic publication and they
allocate no IR local, stack slot, load, or initialization instruction. Later
supported static expressions may consume their checked value and lower the final
result through the same integer-constant path.

Procedure-local integer named numbers are likewise compile-time-only. Their
lexical binding retains `universal_integer` type identity and a checked universal
value, but no IR local or instruction. The context also owns the specific
`root_integer` identity used by the predefined-operator resolution boundary; it
has no runtime scalar representation. When a named number is consumed in a
supported Integer context, Sema first checks compatibility and folds the result to
the existing target-independent Integer constant path. The backend rejects
`universal_integer`, `root_integer`, `universal_real`, or `root_real` if any
compile-time-only numeric identity leaks to runtime lowering. `universal_real`
appears in compile-time-only procedure-local bindings for direct decimal and based
real number literals. Those bindings retain exact rational values but still create
no runtime floating-point type, ABI, stack slot, instruction, or native lowering.
`root_real` is currently used only by predefined operator resolution and likewise
has no runtime representation.

`Standard.Boolean` has a context-owned semantic identity and a distinct target-
independent `Boolean_Type` IR scalar kind. The IR kind deliberately carries no
native width or truth coding. The x86-64 native backend currently gives every
scalar local a four-byte stack slot and lowers Boolean constants as 32-bit `0` for
`False` and `1` for `True`; Boolean local loads/stores copy the full four-byte
value. This coding is a backend representation choice and does not define Ada
Boolean ordering, which remains a semantic property of `False` before `True`.
Procedure-local full Boolean constants remain compile-time lexical bindings and
therefore create no IR local, value, stack slot, or instruction. Mutable direct
`Boolean` and exact `Standard.Boolean` local objects are now admitted as runtime
locals. An omitted initializer emits no write; a supported static initializer
lowers to one target-independent Boolean constant and local store in declaration
elaboration order. Assignment from a supported static Boolean expression lowers
to the same Boolean constant/local-store path. Direct Boolean local-to-local
assignment lowers to a four-byte local load/store after semantic
definition-provenance validation. Unary `not` of one initialized/defined mutable
Boolean local lowers through the same four-byte load, logical negation of the
backend's canonical 0/1 representation, and store. Ordinary `and`/`or`/`xor` over
two direct mutable Boolean locals lower through two four-byte loads and the
corresponding native bitwise operation; the canonical 0/1 representation makes
those operations coincide with the required Boolean truth tables.
Equality/inequality and ordering over two direct Boolean locals lower through the
same loads plus an integer compare and canonical Boolean result. The native
backend uses unsigned compare result instructions for ordering because its current
canonical coding is `False = 0`, `True = 1`; the semantic rule remains Boolean
position order and does not expose that coding. The target-independent IR can represent nested ordinary runtime Boolean operator
values by referencing earlier Boolean values. The native backend lowers such a
validated tree iteratively with a balanced scratch stack rather than recursive
compiler calls; direct-local forms retain their current compact load/operator
sequences. Shared computed subexpressions are intentionally not yet part of the IR
contract, preventing repeated code expansion from a compact DAG. Source Sema emits
that graph for eager mixed/nested Boolean assignment expressions, folding static
subtrees while preserving each mutable-local runtime read. Direct-local runtime
`and then` and `or else` assignments lower to distinct lazy IR values. The x86-64
backend loads the left operand first, emits a conditional branch keyed to the lazy
value ID, evaluates the right load only on the required path, and joins with `%eax`
holding the Boolean result before the target store. This branch/label structure is a
backend realization of language evaluation order, not target-independent control-flow
identity. Nested/mixed runtime short-circuit forms and statement conditions remain
unsupported at the language boundary.

For a direct local RHS, the store consumes a `Local_Load_Value`. The x86-64
backend derives both stack offsets from their one-based local ordinals, emits
`movl` from the source slot into `%eax`, then emits `movl` from `%eax` into the
target slot. `%eax` is a backend-owned scratch choice and is not represented in
semantic state or IR. The currently supported static arithmetic is folded before
IR construction; runtime arithmetic, nonstatic initialization expressions,
compound reads, and broader value forms remain separate vertical slices. Modules without
locals retain the byte-for-byte minimal assembly path, and local-only modules
without a store retain the existing uninitialized-frame behavior.

## Cross-Platform Direction

Cross-platform support is a long-term project requirement. It includes both the
platform where the compiler executable runs and the platform for which the
compiler emits programs. These capabilities may advance independently once the
compiler-target and program-target interfaces are separated.

Target-specific behavior shall remain behind explicit target and backend
boundaries. The frontend, semantic model, and target-independent IR shall not
infer an ABI, object format, or operating system from the build host.

A new compiler or program target shall not be marked supported until the
following work is complete for its declared support level:

- target-triple recognition and configuration;
- data-layout and ABI definitions;
- backend or code-generation availability;
- assembler, linker, or object-emission integration;
- controlled rejection of unsupported combinations;
- target-specific regression tests;
- at least one end-to-end executable or module-generation test.

The planned expansion direction is:

1. stabilize the existing x86-64 Linux and FreeBSD native backend;
2. add a Wasm backend using the target-independent IR;
3. add AArch64 Linux native support;
4. add x86-64 Windows compiler and program target support;
5. add Darwin targets;
6. add an optional LLVM backend as an alternate code-generation path.

This ordering records the current engineering direction rather than a permanent
compatibility promise. A target may move earlier when its prerequisites are
ready, but support boundaries shall remain explicit and tested.

The complete development sequence and milestone exit criteria are defined in
`roadmaps/README.md`.

## Toolchain Selection

At runtime, the native backend uses `ADAC_CC` as the assembler and linker driver
when the variable is set. Otherwise it searches for `cc` in `PATH`.

The selected command runs on the compiler target. Cross-building the `adac`
executable does not by itself install or select the toolchain that will later be
available when that executable runs.

## Validation

`rake target-config-test` verifies the native backend support matrix without
requiring cross toolchains. Native end-to-end compiler tests continue to run
through `rake test`, and `rake check` includes both sets of checks.
