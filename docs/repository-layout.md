# Repository Layout

This document defines the repository layout and Ada package placement rules for
`adac`. Logical stage responsibilities and dependency direction are defined by
`architecture.md`.

## Core Principles

The logical structure of `adac` is defined by the Ada package hierarchy and the
dependency rules in `architecture.md`.

Directories should reflect the major package hierarchy. However, not every
child package needs to be placed in its own directory immediately.

Ada source filenames should generally follow common Ada ecosystem naming
conventions. Directory names should prefer hyphen-separated names (`-`) when
practical.

These naming conventions are recommendations, not hard requirements.

Implementation-only Ada subunits that exist solely to split a large package
body shall remain beside their parent package and use a parent-prefixed filename
that names the separated subprogram or nested implementation package. A subunit
does not create a new logical package authority or a second state model; use it
when lexical access to the parent body's private implementation state is
intentionally required. A visible child package may therefore group an API while
a parent-private nested implementation subunit retains sole access to the
parent-owned representation and helpers.

## Goals

The repository layout aims to:

- keep package responsibilities clear;
- make file locations predictable;
- make the frontend/backend boundary visible;
- keep the custom IR as an independent central layer;
- maintain consistent file placement during AI-assisted development;
- start simple while preserving room for long-term growth.

## Repository Structure

The repository uses the following major structure. The package hierarchy is
authoritative; this listing intentionally omits individual subsystem files so
that routine package growth does not make the document stale.

```text
adac/
  README.md
  adac.adc
  adac_common.gpr
  adac.gpr
  docs/
    README.md
    STYLE-GUIDE.md
    architecture.md
    ast-model.md
    bootstrap-profile.md
    compiler-context.md
    compiler-identifiers.md
    compiler-symbols.md
    engineering-principles.md
    failure-model.md
    frontend-context-clauses.md
    frontend-declarations.md
    frontend-subprograms.md
    frontend-statements.md
    frontend-exception-handlers.md
    frontend-expressions.md
    frontend-lexing.md
    frontend-names.md
    ir-validation.md
    resource-limits.md
    repository-layout.md
    roadmaps/
      README.md
    semantic-model.md
    source-spans.md
    target-support.md
    test-orchestration.md
  src/
    adac.ads
    adac_main.adb
    adac/
      compilation/
      driver/
      frontend/
      ast/
      sema/
      semantics/
      ir/
      backend/
      wasm/
      diagnostics/
      source/
      symbols/
      support/
  tests-runner/   Adac-owned Clair.Test runner and fixture adapters
  tests-support/  shared Adac-owned test-only catalogs and protocols
  tests/          compiler process-level fixtures grouped by feature area
  tests-internal/ in-process compiler contract tests
```

## External Sibling Repositories

Repositories used by development or test orchestration are not part of the
`adac/` tree. When a sibling repository has a repository-level path contract,
document and resolve it relative to the Adac repository rather than embedding a
workstation-specific absolute path.

The current Clair test dependency is the sibling `clair` repository, resolved
as `../clair` from the Adac repository root. Build and test configuration shall
use that relative relationship as its source of truth.

## Build Project Boundaries

GPR project ownership follows executable responsibility rather than repository
directory breadth. `adac_common.gpr` is an abstract policy project only: it owns
the shared target/profile scenario values, Ada compiler switches, and the local
configuration-pragmas path, and owns no source directory, object directory, main
unit, or executable. `adac.adc` applies Ada 2022
`Restrictions (No_Obsolescent_Features)` to every Adac-owned project extending
that policy. Imported sibling projects retain their own compilation policy.

`adac.gpr` is the compiler project and defines only the production compiler
source closure rooted at `adac_main.adb`. Auxiliary Ada tools are not compiler
bootstrap members merely because they live in the same repository.

Test GPR projects extend the same abstract policy project for profile and compiler
switch consistency while retaining their own source membership, object
directories, mains, and external dependencies. Rake orchestrates these projects
but plain GPRbuild remains sufficient to build each project directly. Alire is
not required for any Adac project boundary.

## Package Hierarchy

The initial major package hierarchy is:

```text
Adac.Driver
Adac.Compilation
Adac.Frontend
Adac.AST
Adac.AST.Construction
Adac.AST.Validation
Adac.Sema
Adac.Semantics
Adac.IR
Adac.Backend
Adac.Wasm
Adac.Diagnostics
Adac.Source
Adac.Symbols
Adac.Support
Adac.Resources
```

Responsibilities:

```text
Adac.Driver
  Command-line handling, compilation pipeline execution, top-level control.

Adac.Compilation
  Per-compilation ownership, diagnostics, sources, options, and lifecycle.

Adac.Frontend
  Source input, lexer, parser, and frontend-level processing.

Adac.AST
  Context-owned syntax storage, stable node IDs, and structural validation.

Adac.Sema
  Semantic analysis, name checking, and basic validation.

Adac.Semantics
  Context-owned semantic entities, stable entity IDs, and validation.

Adac.Types
  Context-owned semantic types, stable type IDs, and type validation.

Adac.IR
  Custom IR definitions, IR construction, and IR validation.

Adac.Backend
  Backend interface, backend selection, and common backend flow.

Adac.Wasm
  Wasm backend implementation.

Adac.Diagnostics
  Errors, warnings, diagnostic state, and diagnostic rendering.

Adac.Source
  Source registry, source file identifiers, positions, and source spans.

Adac.Symbols
  Context-owned identifier interning and stable symbol identifiers.

Adac.Support
  Small shared utilities used across the project.

Adac.Resources
  Immutable compilation resource-limit policy and exhaustion signal.
```

## Child Packages And Directories

Child packages may be introduced whenever they are logically useful.

However, child directories should be introduced only when the package subtree is
large enough to benefit from a separate directory.

For example, the initial frontend files may live directly under
`src/adac/frontend/`.

```text
src/adac/frontend/
  adac-frontend.ads
  adac-frontend.adb
  adac-frontend-lexer.ads
  adac-frontend-lexer.adb
  adac-frontend-parser.ads
  adac-frontend-parser.adb
```

The packages may still be structured as:

```text
Adac.Frontend
Adac.Frontend.Lexer
Adac.Frontend.Parser
```

If lexer-related files grow large enough, they may later be promoted into a
dedicated directory.

```text
src/adac/frontend/lexer/
  adac-frontend-lexer.ads
  adac-frontend-lexer.adb
  adac-frontend-lexer-tokens.ads
  adac-frontend-lexer-source.ads
```

## When To Create A New Directory

Create a new directory when one or more of the following conditions apply:

* a directory has too many files to navigate comfortably;
* a child package group has an independent responsibility;
* a major boundary such as frontend, IR, or backend should be made clearer;
* tests, documentation, and implementation files become easier to understand
  when separated.

Do not create a new directory only because a single child package was added.

## File And Directory Naming

Ada package names follow Ada language rules and generally use the Clair coding
style conventions.

Ada source filenames generally follow common Ada ecosystem naming conventions.
In practice, child package separators are represented with hyphens (`-`), while
identifier-internal underscores (`_`) are preserved.

Example:

```text
Adac.Frontend.Lexer
  -> adac-frontend-lexer.ads
  -> adac-frontend-lexer.adb
```

Directory names should prefer hyphen-separated names (`-`) when practical,
because they are easier to type in shells.

Command names, executable names, Rake task names, and similar repository-level
identifiers should also prefer `kebab-case` unless a target language or
toolchain requires another form.

Example:

```text
src/adac-fmt/
adac-test-runner
target-config-test
```

This rule applies to repository paths, not Ada identifiers. Ada identifiers
continue to follow the Clair naming rules.

## Test Layout

Tests are organized by feature area and milestone. Tests under `tests/` execute
the compiler as an external program and verify user-visible behavior. Tests
under `tests-internal/` execute compiler APIs in one process and verify internal
ownership and isolation contracts.

`tests-runner/` owns deterministic fixture discovery, project-specific expected
results, output and publication checks, and the single Clair.Test runner.
`tests-support/` contains test-only units shared by more than one test executable
or project; it shall not become a production dependency. Rake builds the
required executables and invokes the runner, but it does not interpret fixture
results.

Test source directories contain only immutable inputs and expected results.
Generated actual output, assembly, executables, and temporary backend artifacts
belong under the target/profile-specific `build/tests/` work root. A test run
shall not create or update generated files beside `tests/` or `tests-internal/`
sources.

The initial minimal test uses:

```text
tests/
  pipeline/
    minimal/
      input.adb
      expected-result.txt
      expected-stdout.txt
```

The purpose of this test is to compile the following program and produce an
executable `main`.

```ada
procedure main is
begin
  null;
end main;
```

The internal test project builds a separate test executable. It shall not be a
main of the production `adac.gpr` project. Internal tests normally use public
compiler contracts. A test-only child package may access private representation
only to inject malformed state required to verify a production validator. Such
packages shall remain under `tests-internal/` and shall not be visible to the
production project.

`adac` and a future `adac-fmt` remain separate tools until a stable shared
subsystem justifies extraction. Do not couple tools merely to remove small
amounts of duplication. Source-style guidance itself is not an executable
repository tool or acceptance gate.

## Change Principles

The repository layout may change as the project grows.

Changes should satisfy the following principles:

* the relationship between package hierarchy and directory structure should
  become clearer;
* frontend/backend/IR boundaries must not become blurred;
* short-term convenience must not damage long-term structure;
* the reason for a layout change should be recorded in documentation or a
  commit message.
