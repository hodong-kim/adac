# adac

`adac` is an Ada compiler project written in Ada.

The goal is to build a standalone compiler for an Ada 2022 subset.
The compiler uses a separated frontend/backend architecture and a custom IR as
the central program representation.

`adac` defines lexer, parser, AST, semantic analysis, IR, diagnostics, backend,
and tests as separate connected subsystems.

Long-term goals include Wasm support, cross-platform support, an optional LLVM
backend, a structure intended to support SPARK-related constraints, a Clair
style checker, and a Clair formatter.

-----

## Build

The default build profile is `release`.

```text
$ rake info
$ rake build
$ rake build TARGET=x86_64-unknown-freebsd PROFILE=debug
```

Build outputs are separated by target and profile:

```text
build/obj/<target>/<profile>
build/bin/<target>/<profile>
```

For cross compilation, pass a toolchain target triple through `TARGET`:

```text
$ rake build TARGET=x86_64-unknown-freebsd
```

`TARGET` selects the platform where the `adac` executable itself will run.
Rake embeds that compiler target in a generated Ada package so runtime backend
selection cannot silently assume the build host.

The current native program backend supports x86-64 FreeBSD and x86-64 Linux.
Other compiler targets may be cross-built when a matching GNAT toolchain is
installed, but program emission is rejected until a backend for that target is
implemented. See `docs/target-support.md`.

`run`, `test`, `style`, and `style-test` execute the generated compiler or
style checker, so they are available only when the selected target is compatible
with the host architecture, OS, and ABI.

-----

## Development Approach

This project is developed with active AI assistance.

AI is used for design review, implementation support, test generation, code
review, and documentation. Implementation work is expected to follow the
compiler pipeline and the repository architecture defined by the project.

Features are implemented through the compiler pipeline: lexer, parser, AST,
semantic analysis, IR, and backend.

Subsystem responsibilities and compiler-stage boundaries are documented in the
repository.

-----

## Long-Term Goals

The long-term goals of `adac` are:

- Ada 2022 subset compiler written in Ada
- standalone compiler architecture with a path toward self-hosting
- separated frontend/backend architecture
- custom IR design
- Wasm support
- cross-platform support
- optional LLVM backend support
- structure intended to support SPARK-related constraints
- Clair style checker
- Clair formatter

-----

## Language Options

`adac` follows Ada syntax and semantic rules by default.

Some options may be provided experimentally for specific development workflows
or repository policies.

For example, a case-sensitive mode may be supported as an optional mode for
codebases where case distinction is required by repository policy or selected
workflows.

-----

## Minimum Goal

The minimum goal is to compile the following Ada program and produce an
executable binary.

```ada
procedure main is
begin
  null;
end main;
```

Expected usage:

```text
$ adac main.adb -o main
$ ./main
```

Repository checks:

`text
$ rake test
$ rake style
$ rake check
`

The initial feature set is limited, and the implementation follows the compiler
pipeline from the beginning.

```text
source
  -> lexer
  -> parser
  -> AST
  -> semantic analysis
  -> IR
  -> backend
  -> executable
```

This minimum goal has already shaped the current implementation: `adac` can
parse the minimal program, build a small AST, run semantic checks, build a
minimal IR module, emit native assembly for the null program, and produce an
executable through the system toolchain.

---

## Design Principles

* Write the Ada compiler in Ada.
* Implement features inside the compiler pipeline.
* Maintain frontend/backend boundaries from the beginning.
* Use the custom IR as the central compiler representation.
* Keep LLVM as an optional backend target, not as the design center.
* Preserve Ada-level meaning in the IR before lowering to backend-specific
  forms.
* Use AI assistance while preserving structural consistency and long-term
  maintainability.
* Prefer architecture that can grow toward self-hosting.
* Prefer extensible structure over short-lived implementation paths.

---

## Coding Style

All project code must follow the Clair Coding Style.

The style rules are defined by `STYLE-GUIDE.md` in the repository root.

AI-generated code must follow the same style rules. Code review should also
check whether the generated or edited code follows the Clair style.

The Clair Coding Style is not only a formatting convention. It defines project
expectations for readability, API design, naming, and structural consistency.

Long-term tooling goals include:

* a style checker that verifies the Clair Coding Style;
* a formatter that applies the Clair Coding Style.

The style checker and formatter are currently planned as separate tools rather
than integrated `adac` subcommands. This structure may change later.

---

## Current Implementation

The current implementation contains:

* command-line driver
* lexer
* pull-based token stream
* parser for the minimal procedure form
* AST representation for the minimal compilation unit
* semantic check for procedure/end name consistency
* diagnostic subsystem
* source position tracking
* custom IR skeleton
* dump backend
* native assembly backend for the null program
* regression test infrastructure
* positive and negative tests
* `-o` output path support

The current native backend is limited to the null program. It emits assembly for
the null program and relies on the system toolchain to link the resulting
executable.

---

## Non-Goals For The Initial Stage

The initial stage does not include:

* full Ada 2022 implementation
* complete SPARK verifier
* advanced optimization
* complete runtime system
* full tasking support
* full protected object support
* full generic support
* full formatter implementation

---

## Roadmap

The project starts with a limited compiler pipeline that connects the major
compiler stages, then expands the supported Ada 2022 subset incrementally.

The major development directions are:

1. minimal compiler pipeline
2. frontend expansion
3. semantic analysis expansion
4. custom IR stabilization
5. backend expansion
6. Wasm support
7. optional LLVM backend support
8. self-hosting-oriented structure
9. structure intended to support SPARK-related constraints
10. Clair style checker
11. Clair formatter

---

## License

`adac` is distributed under the 0BSD license.

See `LICENSE` for details.

---

## Status

`adac` is in an early implementation stage.

The current compiler pipeline connects lexer, parser, AST, semantic analysis,
IR, diagnostics, backend, and regression tests. The current backend emits
native assembly for the minimal null program, and the test suite verifies
executable generation.
