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
`roadmap.md`.

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
