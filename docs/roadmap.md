# Development Roadmap

This document defines the development direction for `adac`, an Ada compiler
written in Ada. It describes milestone dependencies, completion criteria, and
the path from the current minimal compiler to a self-hosting, cross-platform
compiler.

The roadmap is capability-based rather than date-based. A milestone is complete
only when its exit criteria are satisfied. Calendar estimates and feature
counts shall not replace correctness, safety, or validation requirements.

## Scope

The primary language goal is a useful Ada 2022 subset with an architecture that
can expand without replacing the compiler pipeline.

The long-term project direction includes:

- a standalone compiler written in Ada;
- a separated frontend and backend architecture;
- a custom, target-independent IR;
- staged self-hosting;
- cross-platform compiler and program targets;
- a Wasm backend;
- an optional LLVM backend;
- structure suitable for later SPARK-related constraints;
- a Clair style checker and formatter.

Full Ada 2022 coverage, complete SPARK verification, advanced optimization,
tasking, protected objects, and specialized annex support are not prerequisites
for the initial useful compiler or the first self-hosting milestone.

## Current Baseline

The current compiler already connects the following stages:

```text
source
  -> lexer
  -> parser
  -> AST
  -> semantic analysis
  -> custom IR
  -> backend
  -> executable
```

The implemented language subset accepts a minimal procedure containing `null`
and `return` statements. The native backend emits GNU-style x86-64 assembly and
uses the system toolchain to assemble and link programs on supported Linux and
FreeBSD targets.

This connected pipeline is the foundation of the roadmap. New language
features shall extend it rather than bypass it.

## Development Rules

### Documentation First

Architecture, language-support boundaries, target requirements, and failure
behavior shall be documented before implementation depends on them.

When a change introduces a new subsystem contract or changes an existing one,
the applicable document shall be updated in the same change.

### Vertical Feature Slices

A language feature shall be implemented through every compiler stage that it
requires:

```text
source syntax
  -> tokens
  -> parser
  -> AST
  -> semantic model
  -> IR
  -> backend or runtime
  -> diagnostics and tests
```

Parser-only acceptance is not language support. A feature is not complete when
the compiler can parse it but cannot validate, lower, emit, execute, or reject
it correctly.

### Explicit Stage Boundaries

The frontend, AST, semantic analysis, IR, backend, diagnostics, source, and
support subsystems shall retain separate responsibilities.

Target-specific ABI and object-format behavior shall not leak into the parser,
AST, or target-independent semantic representation.

### Custom IR As The Center

Ada-level meaning shall be preserved until an explicit lowering step removes
it. LLVM may be supported as an optional backend, but LLVM IR shall not become
the compiler's primary semantic representation.

### Failure Containment

Expected input failures, external operational failures, and internal compiler
contract violations shall remain distinct as defined by `failure-model.md`.

Invalid input shall not crash the compiler. Internal invariant failures shall
not be converted into ordinary source diagnostics or successful fallback
behavior. Partial output shall not be published as a successful result.

### Determinism

Given identical source files, compiler version, language options, target, and
environmental inputs, the compiler should produce deterministic diagnostics,
metadata, IR dumps, and final output.

Iteration order over hash-based structures shall not determine externally
visible behavior.

## Support-State Model

Language and runtime features should be tracked using the following states:

```text
unsupported
parsed
semantically checked
lowered to IR
code generated
runtime supported
validated
```

The state applies to a documented feature boundary, not merely to one positive
example. `validated` requires positive tests, negative tests where applicable,
and execution or output validation for supported targets.

Target support should be tracked independently for:

```text
build host
compiler target
program target
```

The meaning of these roles and the current support matrix are defined in
`target-support.md`.

## Milestone 0: Baseline Stabilization

### Objective

Preserve the connected minimal compiler while making its existing contracts
explicit and dependable.

### Work

- keep the minimal procedure pipeline passing end-to-end tests;
- keep supported and unsupported targets explicit;
- ensure command-line and source inputs are treated as untrusted;
- keep temporary and final output handling failure-safe;
- document compiler-stage responsibilities and failure boundaries;
- maintain positive and negative regression tests for current behavior.

### Exit Criteria

- the minimal program compiles and executes on every supported native target;
- malformed source and invalid command lines fail with controlled diagnostics;
- unsupported targets are rejected before backend output is created;
- repository checks pass without relying on undocumented host assumptions.

## Milestone 1: Compiler Context And Core Infrastructure

### Objective

Replace process-global and ad-hoc state with explicit compilation ownership and
stable identifiers suitable for larger programs and parallel compilation.

### Work

- introduce a compiler or compilation-session context;
- assign stable source-file, node, entity, symbol, and type identifiers;
- attach source spans to syntax and semantic objects;
- intern identifiers and other frequently repeated immutable strings;
- define stage-specific result types rather than returning only a Boolean;
- define ownership and lifetime rules for AST, semantic, and IR objects;
- introduce validators for stage inputs and outputs;
- make diagnostic state owned by a compilation context;
- prepare cancellation and resource-limit boundaries.

Arena-backed storage with identifier references is preferred where it improves
ownership clarity, locality, validation, and deterministic serialization.

### Exit Criteria

- two independent compilation contexts can exist in one process;
- diagnostics and identifiers do not leak between compilations;
- malformed internal AST or IR objects are detected as contract violations;
- large invalid inputs do not leave published partial output.

## Milestone 2: Frontend Coverage

### Objective

Represent the Ada syntax needed by later milestones while maintaining bounded,
recoverable parsing behavior.

### Work

- complete token coverage for the selected Ada 2022 subset;
- support numeric, character, and string literals;
- implement names, selected names, attributes, and expressions;
- implement declarations and declarative parts;
- implement control-flow statements;
- implement subprogram specifications and bodies;
- implement package specifications and bodies;
- parse context clauses and compilation units;
- create syntax nodes for planned but not yet supported constructs when useful;
- add parser recovery at declaration, statement, and unit boundaries;
- reject excessive nesting or resource consumption predictably.

Unsupported syntax that can be parsed safely should produce a precise
unsupported-feature diagnostic rather than an unrelated parser failure.

### Exit Criteria

- all source files in the bootstrap profile can be parsed into an AST;
- the parser reports multiple independent errors when recovery is safe;
- every produced node has a valid source span;
- deep or adversarial nesting is bounded without process-stack exhaustion.

## Milestone 3: Semantic Core And Scalar Execution

### Objective

Compile useful scalar programs with declarations, expressions, control flow,
and subprogram calls.

### Work

- define entities, lexical scopes, and visibility;
- implement case-insensitive Ada identifier resolution by default;
- preserve the optional case-sensitive extension as a separate language mode;
- implement types, subtypes, base types, and constraints;
- implement expected-type propagation and implicit conversions;
- implement universal integer and universal real handling as required;
- implement static-expression evaluation;
- implement overload-set construction and resolution;
- implement variables, constants, and assignment;
- implement integer, Boolean, and enumeration types;
- implement arithmetic, comparison, and logical operators;
- implement `if`, `case`, basic loops, and loop exits;
- implement procedures, functions, parameter modes, and return values;
- implement nested subprograms to the extent required by the bootstrap profile.

### Exit Criteria

- scalar declarations and expressions are type-checked before IR lowering;
- ambiguous and illegal programs are rejected with source-level diagnostics;
- variables, branches, loops, procedures, and functions execute correctly;
- negative tests cover visibility, type, overload, and control-flow errors.

## Milestone 4: Typed IR And Control-Flow Stabilization

### Objective

Replace the minimal flat instruction sequence with validated representations
that preserve Ada semantics and support multiple backends.

### Work

- define a typed high-level IR that preserves relevant Ada meaning;
- define a lower control-flow IR with functions and basic blocks;
- represent values, memory operations, calls, branches, and returns explicitly;
- represent runtime checks explicitly;
- represent exceptional or failing operations without hidden backend behavior;
- define target-independent data-layout requirements;
- provide deterministic textual dumps;
- validate dominance, block termination, types, references, and ownership;
- keep backend-specific registers, calling conventions, and object formats out
  of the target-independent IR.

An additional machine-level IR may be introduced when native code generation
requires it. It is not required before the typed and control-flow IR contracts
are stable.

### Exit Criteria

- every supported scalar program lowers through validated IR;
- invalid IR is rejected before backend emission;
- IR dumps are deterministic and covered by regression tests;
- the dump and native backends consume the same validated module contract.

## Milestone 5: Native Backend And Minimal Runtime

### Objective

Make the existing x86-64 Linux and FreeBSD path a dependable native execution
platform for the scalar language subset.

### Work

- implement stack frames and local storage;
- implement integer and Boolean operations;
- implement comparison and conditional branches;
- implement function calls, arguments, and return values;
- implement global and read-only data;
- define alignment and target data layout;
- define the supported System V ABI boundary;
- add runtime checks for ranges, overflow, division, and null access as needed;
- add program initialization, elaboration entry, and termination support;
- write output through temporary files and publish it atomically when practical;
- distinguish toolchain unavailability from malformed compiler output.

Direct ELF object generation is not required at this milestone. Assembly plus a
documented system assembler and linker driver remains an acceptable backend.

### Exit Criteria

- scalar programs execute correctly on supported Linux and FreeBSD targets;
- ABI behavior is documented and tested;
- backend failures produce controlled operational or internal diagnostics;
- range and arithmetic checks have positive and negative runtime tests.

## Milestone 6: Packages And Separate Compilation

### Objective

Support multi-unit Ada programs with explicit dependencies, interfaces, and
elaboration order.

### Work

- implement package specifications and bodies;
- implement context clauses, `with`, and `use` semantics;
- implement public and private declarations;
- implement child units when the base package model is stable;
- build and validate the compilation-unit dependency graph;
- diagnose missing, duplicated, and circular dependencies;
- define specification and body matching;
- define library metadata and interface hashes;
- record compiler, language-mode, target, ABI, and IR-schema versions;
- implement incremental rebuild and cache invalidation rules;
- define deterministic elaboration ordering and generated metadata.

The metadata format shall be an Adac-owned interface. Compatibility with a
different compiler's private metadata format is not a requirement.

### Exit Criteria

- a program containing multiple package specifications and bodies builds;
- interface changes invalidate dependent units correctly;
- dependency and elaboration diagnostics are deterministic;
- stale or incompatible metadata is rejected safely.

## Milestone 7: Composite Types And Storage Model

### Objective

Support the data types needed by practical Ada programs and the compiler's own
bootstrap profile.

### Work

- implement arrays and strings;
- implement records and aggregates;
- implement constrained and unconstrained subtypes;
- implement commonly required attributes;
- implement access types and allocators;
- define array bounds and descriptor representations;
- define fat pointers or equivalent descriptors where required;
- implement discriminated and variant records in staged subsets;
- implement derived types;
- define temporary-object storage and lifetime handling;
- implement controlled types and finalization after ownership rules are stable;
- implement accessibility checks required by the selected subset.

### Exit Criteria

- arrays, strings, records, and access values execute correctly;
- constrained and unconstrained representations are documented;
- bounds, discriminants, and accessibility failures are tested;
- object lifetime and cleanup behavior are explicit at exceptional exits.

## Milestone 8: Exceptions, Generics, And Tagged Types

### Objective

Add the major language mechanisms required by reusable libraries and a broader
self-hosting compiler implementation.

### Exceptions

- exception declarations and `raise`;
- handlers and propagation;
- cleanup and finalization during propagation;
- controlled unhandled-exception termination;
- optional traceback support behind a stable runtime interface.

### Generics

- generic formal objects, types, and subprograms;
- generic packages and subprograms;
- instantiation environments and legality checking;
- recursive and cyclic instantiation detection;
- documented code-sharing or specialization policy.

### Tagged Types

- tagged records and type extension;
- primitive operations and overriding;
- class-wide types;
- dispatch tables and dynamic dispatch;
- interfaces after the base dispatch model is validated.

### Exit Criteria

- exceptions propagate across supported calls without leaking owned resources;
- selected generic containers or compiler-specific generic utilities work;
- tagged dispatch works for the documented subset;
- negative tests cover illegal instantiation, overriding, and handler cases.

## Milestone 9: Staged Self-Hosting

### Objective

Build `adac` with `adac` without making full Ada support a prerequisite.

### Bootstrap Profile

The bootstrap profile is the documented Ada subset used by the compiler
implementation itself. The profile should minimize unnecessary dependency on
large runtime or generic-library surfaces until those surfaces are validated.

Compiler-specific arena, vector, string, or table utilities may be used when
they reduce bootstrap complexity and remain maintainable. Depending on another
compiler's private runtime ABI is not a self-hosting requirement.

### Stages

```text
S0  A seed compiler builds adac-stage1.
S1  adac-stage1 parses all bootstrap-profile sources.
S2  adac-stage1 semantically checks all bootstrap-profile sources.
S3  adac-stage1 builds adac-stage2.
S4  adac-stage2 builds adac-stage3.
S5  stage2 and stage3 pass semantic and executable comparison gates.
S6  normalized or reproducible bootstrap output is achieved.
```

Byte-for-byte equality may exclude documented nondeterministic fields until
those fields are removed or normalized. Functional equality alone is not the
final reproducibility goal.

### Exit Criteria

- the bootstrap profile is documented and automatically checked;
- stage2 and stage3 pass the same compiler regression suite;
- stage differences are explainable and eventually reproducible;
- the seed compiler is required only to start a clean bootstrap chain.

## Milestone 10: Cross-Platform Expansion

### Objective

Extend both compiler targets and program targets without weakening frontend,
IR, ABI, or validation boundaries.

### Direction

The current expansion direction is:

1. stabilize x86-64 Linux and FreeBSD;
2. add Wasm module generation;
3. add AArch64 Linux;
4. add x86-64 Windows;
5. add Darwin targets;
6. add an optional LLVM backend.

The ordering may change when prerequisites or project needs change. A target is
not supported merely because the compiler executable can be cross-built for
it. Program emission requires a matching backend, ABI, data layout, output
format, toolchain contract, and end-to-end tests.

### Required Target Work

- target-triple parsing and normalization;
- compiler-target and program-target separation;
- ABI and calling-convention definitions;
- object or module format integration;
- assembler and linker selection where applicable;
- runtime porting;
- target-specific diagnostics;
- native, emulated, or externally verified execution tests;
- explicit unsupported-combination rejection.

### Exit Criteria

- each advertised target has a documented support level;
- frontend behavior does not depend on the build host;
- unsupported target combinations fail before publishing output;
- cross-target output is covered by deterministic backend tests;
- supported targets have end-to-end validation appropriate to the platform.

## Milestone 11: Tasking And Specialized Annexes

### Objective

Add concurrency and specialized facilities only after the sequential language,
runtime, exceptions, storage, and target contracts are stable.

### Work

- task types and task objects;
- entries, `accept`, and rendezvous;
- protected objects and protected operations;
- selective waits, requeue, delay, and abort in staged subsets;
- scheduler and synchronization runtime interfaces;
- exception and finalization behavior across task boundaries;
- atomic and volatile semantics;
- selected real-time or systems-programming facilities;
- Ravenscar or other restricted profiles when their runtime contracts are
  sufficiently defined.

Tasking is a runtime and memory-model project, not only a parser feature.

### Exit Criteria

- the sequential and tasking runtimes can be configured explicitly;
- supported synchronization behavior is documented and stress-tested;
- failures and exceptions across task boundaries preserve compiler guarantees;
- unsupported annex features are rejected clearly.

## Milestone 12: Analysis, Optimization, And Developer Tools

### Objective

Build advanced capabilities on the stable semantic model and IR rather than
embedding them into early frontend code.

### Work

- basic IR simplification and dead-code elimination;
- optional higher optimization levels with separate correctness tests;
- debug-information support;
- structure for SPARK-related legality and analysis constraints;
- Clair style checker expansion;
- Clair formatter;
- optional language-server or incremental-analysis interfaces;
- optional LLVM backend maturation;
- direct object writers when they provide clear portability or control gains.

### Exit Criteria

- optimization preserves observable behavior across the regression suite;
- analysis and style tools reuse stable compiler representations where useful;
- optional backends cannot silently change language semantics;
- tooling failures cannot corrupt normal compiler output.

## Validation Strategy

Every language feature should add the applicable tests from this list:

- lexer tests;
- parser positive tests;
- parser negative and recovery tests;
- semantic positive tests;
- semantic negative tests;
- IR dump tests;
- IR validator tests;
- backend output tests;
- executable behavior tests;
- runtime-failure tests;
- unsupported-feature tests;
- target-matrix tests.

### Differential Validation

Where language behavior is defined and comparable, test programs may be
compiled with another Ada implementation and compared for:

- acceptance or rejection;
- execution results;
- exception behavior;
- static-expression results;
- representation details only when the language or documented ABI defines them.

Implementation-defined behavior shall be separated from language-conformance
comparisons.

### Conformance Suites

Applicable Ada conformance tests should be introduced incrementally as the
supported subset grows. Each imported test shall be classified as passing,
failing, unsupported, or not applicable, with unsupported classifications tied
to documented feature boundaries.

### Fuzzing And Adversarial Inputs

Fuzzing targets should include:

- source decoding;
- lexer and token streams;
- parser and recovery;
- diagnostic rendering;
- metadata readers;
- IR readers or deserializers if introduced;
- command-line handling;
- target-triple handling.

Resource tests should cover very large token counts, long identifiers, deep
nesting, large overload sets, large dependency graphs, repeated error recovery,
storage exhaustion, interrupted output, and cancellation.

## Completion Definition

A milestone is complete only when:

- its public and internal contracts are documented;
- required implementation paths are connected;
- validators enforce the new invariants;
- positive and negative regression tests pass;
- supported target tests pass;
- failure paths do not publish invalid output;
- deterministic behavior is maintained or documented;
- the next milestone does not require bypassing the established architecture.

The roadmap may be revised as the implementation exposes new constraints. Such
revisions should preserve explicit support boundaries, vertical feature slices,
custom IR independence, failure containment, and the path toward self-hosting
and cross-platform support.
