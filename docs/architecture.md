# Compiler Architecture

This document defines Adac's repository-wide logical compiler architecture and
dependency direction. Subsystem documents remain authoritative for their own
representation, ownership, failure, resource, and language-support contracts.
`repository-layout.md` owns physical file placement rather than logical stage
semantics.

## Pipeline

The compiler is organized as a one-way pipeline:

```text
Driver
  -> Frontend
  -> AST
  -> Semantic analysis / semantic model / types
  -> IR construction / IR
  -> Backend
```

`Adac.Driver` orchestrates stages and process-facing behavior. It shall not own
syntax, semantic, IR, or backend representation.

`Adac.Frontend` owns source-to-syntax processing. It may depend on source,
symbol, diagnostic, resource, AST-construction, and compilation-context APIs,
but shall not depend on semantic analysis, IR construction, or backend code.

`Adac.AST` owns target-independent syntax representation and structural
validation. AST storage shall not depend on `Adac.Compilation`; the compilation
context composes the AST store instead.

`Adac.Sema` consumes validated syntax and publishes semantic state through the
context-owned stores defined by `Adac.Semantics` and `Adac.Types`. Semantic
analysis shall not depend on IR or backend representation.

`Adac.IR.Builder` consumes semantic state and produces target-independent IR.
`Adac.IR` shall not depend on a backend.

`Adac.Backend` consumes validated IR. Target-specific ABI, assembly, object,
toolchain, and output-publication behavior belongs at or below this boundary and
shall not flow back into frontend, AST, semantic, or target-independent IR
packages.

## Foundational State And Context Adapters

`Adac.Source`, `Adac.Symbols`, `Adac.Diagnostics`, `Adac.Resources`, and
`Adac.Language` define foundational state or policy. They shall remain usable
without depending on later compiler stages.

`Adac.Compilation.Context` is the owner that composes per-compilation stores and
policy. `Adac.Compilation.*` child packages provide context-aware access to those
stores. They may validate context ownership and convert between context-facing
and store-facing APIs, but shall not become alternate implementations of AST,
symbol, source, semantic, or type storage.

There shall be one source of truth for each store invariant. A context adapter
may strengthen ownership checks but shall not duplicate mutable representation
or maintain a second independent model of the same compiler object.

## Frontend Structure

Frontend control flow is grammar-driven. Production bootstrap source selects
which language capabilities need implementation; it shall not become parser
control data.

In particular, parser behavior shall not depend on:

- a declaration's ordinal position in a production file;
- a source line number;
- a production-file-specific sequence count;
- a particular production identifier spelling when the grammar does not require
  that spelling; or
- a chain of helpers whose only purpose is to advance a bootstrap frontier one
  source item at a time.

Once a declaration or construct belongs to a represented grammar subset, the
same parser operation shall accept repeated occurrences until a genuinely
unrepresented grammar form is reached. The roadmap records that observed
frontier; the parser does not encode it.

Large frontend implementation units may be split by coherent grammar ownership
such as names, expressions, declarations, statements, and compilation units.
Such a split shall preserve one parser state model, deterministic token
ownership, bounded recursion/resource accounting, and precise diagnostic
precedence. File splitting alone is not an architectural goal.

## AST And Context-Facing Syntax APIs

Adac retains one context-owned append-only AST store and one stable `Node_ID`
identity model. Syntax-family growth shall not create independent AST arenas or
copy subtrees between syntax packages.

`Adac.AST` is the structural storage authority. Raw store mutation and
Store-aware structural validation are grouped by `Adac.AST.Construction` and
`Adac.AST.Validation`, with parent-private implementation subunits retaining the
single store and invariant authority. `Adac.Compilation.Syntax` is the unified
context-facing syntax facade. Its consumers commonly combine construction,
queries, and validation in one parser or semantic operation, so it shall not
mirror the low-level AST child split unless caller responsibilities become
separable enough to reduce actual dependency coupling.

New node kinds continue to require construction invariants, queries, validation,
resource behavior, and tests in the same vertical change. A physical source-file
boundary shall not create a second validation contract.

## Bootstrap And Production Sources

Bootstrap tests use authoritative production sources in place as defined by
`bootstrap-profile.md`. Production files are integration inputs, not parser
specifications.

A production-source failure is useful evidence for selecting the next language
prerequisite. It is not justification for adding source-order-specific parser
branches or permanently retaining every intermediate frontier as code or test
structure.

## Physical Modularity

The Ada package hierarchy is the primary module boundary. A large source file is
not automatically defective, but it should be split when it contains several
independently named responsibilities whose contracts can be enforced without
creating cycles or duplicate state.

Prefer a child package when it gives one responsibility a stable dependency
boundary, reduces repeated cross-family changes, or materially improves testing
and review. Do not create child packages merely to satisfy a line-count target.

Architecture changes shall keep the dependency graph acyclic and preserve the
ownership, failure, resource, and determinism contracts defined by the
authoritative subsystem documents.
