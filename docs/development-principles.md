# Development Principles

This document records lightweight development principles for `adac`.

## Compiler Pipeline

Features should be implemented through the compiler pipeline:

```text
lexer -> parser -> AST -> semantic analysis -> IR -> backend
```

## Tool Boundaries

`adac`, `adac-style`, and `adac-fmt` start as separate tools.

They do not need to share code at first. Shared components may be extracted
later when repeated routines become stable.

## AI Assistance

AI may be used for design review, implementation support, tests, code review,
and documentation.

AI-generated code must follow the repository structure and Clair Coding Style.

## Visibility

Development workflows should keep generated artifacts and repository state
visible unless there is a specific reason to hide them.
