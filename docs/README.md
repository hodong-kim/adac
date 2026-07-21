# Documentation Map

This directory contains the authoritative engineering contracts for `adac`.
Each contract has one primary document. Other documents may summarize it, but
shall link to the primary document instead of restating mutable details.

## Authority

| Document | Primary responsibility |
| --- | --- |
| `roadmap.md` | Product direction, milestone order, and exit criteria |
| `compiler-context.md` | Per-compilation ownership and lifecycle |
| `compiler-identifiers.md` | Rules common to context-owned identifiers |
| `compiler-symbols.md` | Symbol interning and `Symbol_ID` |
| `source-spans.md` | Source positions, ranges, and span ownership |
| `ast-validation.md` | AST invariants and validation boundaries |
| `ir-validation.md` | IR invariants and validation boundaries |
| `failure-model.md` | Failure categories, propagation, and cleanup |
| `target-support.md` | Current and planned target support contracts |
| `repository-layout.md` | Package, source, and test placement |
| `STYLE-GUIDE.md` | Source style and API documentation conventions |

Repository automation and autonomous-work rules are defined by `AGENTS.md` at
the repository root. User-facing build and usage information belongs in the
root `README.md`; it is not an architecture contract.

## Maintenance Rules

- Update a contract before or with the implementation that depends on it.
- Put mutable implementation status in exactly one authoritative document.
- Keep roadmap entries capability-oriented; subsystem representation belongs
  in the subsystem document.
- Keep summaries short and link to the authoritative contract.
- Remove obsolete contracts and compatibility descriptions when their paths
  are removed from the implementation.
- Reorganize documents when their current boundaries create duplicate sources
  of truth or obscure ownership, lifetime, failure, or stage responsibilities.
