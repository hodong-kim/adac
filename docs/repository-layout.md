# Repository Layout

This document defines the repository layout and Ada package placement rules for
`adac`.

## Core Principles

The logical structure of `adac` is defined by the Ada package hierarchy.

Directories should reflect the major package hierarchy. However, not every
child package needs to be placed in its own directory immediately.

Ada source filenames should generally follow common Ada ecosystem naming
conventions. Directory names should prefer hyphen-separated names (`-`) when
practical.

These naming conventions are recommendations, not hard requirements.

## Goals

The repository layout aims to:

- keep package responsibilities clear;
- make file locations predictable;
- make the frontend/backend boundary visible;
- keep the custom IR as an independent central layer;
- maintain consistent file placement during AI-assisted development;
- start simple while preserving room for long-term growth.

## Initial Directory Layout

The initial repository layout follows this structure.

```text
adac/
  README.md
  docs/
    STYLE-GUIDE.md
    compiler-context.md
    failure-model.md
    repository-layout.md
    roadmap.md
    target-support.md
  src/
    adac/
      driver/
      frontend/
      ast/
      sema/
      ir/
      backend/
      wasm/
      diagnostics/
      source/
      support/
  tests/
    minimal/
  tests-internal/
    adac_internal_tests.gpr
    adac_internal_tests.adb
    expected.txt
```

## Package Hierarchy

The initial major package hierarchy is:

```text
Adac.Driver
Adac.Compilation
Adac.Frontend
Adac.AST
Adac.Sema
Adac.IR
Adac.Backend
Adac.Wasm
Adac.Diagnostics
Adac.Source
Adac.Support
```

Responsibilities:

```text
Adac.Driver
  Command-line handling, compilation pipeline execution, top-level control.

Adac.Compilation
  Per-compilation ownership, diagnostics, options, and lifecycle state.

Adac.Frontend
  Source input, lexer, parser, and frontend-level processing.

Adac.AST
  Abstract syntax tree definitions and related utilities.

Adac.Sema
  Semantic analysis, name checking, and basic validation.

Adac.IR
  Custom IR definitions, IR construction, and IR validation.

Adac.Backend
  Backend interface, backend selection, and common backend flow.

Adac.Wasm
  Wasm backend implementation.

Adac.Diagnostics
  Errors, warnings, diagnostic state, and diagnostic rendering.

Adac.Source
  Source files, source positions, and source spans.

Adac.Support
  Small shared utilities used across the project.
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

Ada package names follow Ada rules and the Clair coding style.

Ada source filenames generally follow common Ada ecosystem naming conventions.
In practice, child package separators are represented with hyphens (`-`), while
identifier-internal underscores (`_`) are preserved.

Example:

```text
Adac.Frontend.Lexer
  -> adac-frontend-lexer.ads
  -> adac-frontend-lexer.adb

Guiyom.Widget.List_View
  -> guiyom-widget-list_view.ads
  -> guiyom-widget-list_view.adb
```

Directory names should prefer hyphen-separated names (`-`) when practical,
because they are easier to type in shells.

Example:

```text
src/adac-style/
src/adac-fmt/
```

This rule applies to repository paths, not Ada identifiers. Ada identifiers
continue to follow the Clair naming rules.

## Test Layout

Tests are organized by feature area and milestone. Tests under `tests/` execute
the compiler as an external program and verify user-visible behavior. Tests
under `tests-internal/` execute compiler APIs in one process and verify internal
ownership and isolation contracts.

The initial minimal test uses:

```text
tests/
  minimal/
    input.adb
    expected.txt
    expected-status.txt
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
main of the production `adac.gpr` project. Internal tests may inspect public
compiler contracts but should not depend on private representation details.

## Change Principles

The repository layout may change as the project grows.

Changes should satisfy the following principles:

* the relationship between package hierarchy and directory structure should
  become clearer;
* frontend/backend/IR boundaries must not become blurred;
* short-term convenience must not damage long-term structure;
* the reason for a layout change should be recorded in documentation or a
  commit message.
