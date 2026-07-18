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
