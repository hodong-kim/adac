# Development Roadmap

This is the sole active Adac development roadmap. It owns repository-wide
milestone ordering, the current resumption checkpoint, support-state progression,
and milestone exit criteria. Durable subsystem contracts are indexed by
`../README.md`; exact regression evidence belongs in tests, and historical
progress belongs in Git history.

The roadmap is capability-based rather than date-based. A milestone is complete
only when its exit criteria are satisfied. Calendar estimates and feature counts
shall not replace correctness, safety, or validation requirements.

## Roadmap Ownership

No specialized roadmap is currently active. Create one only when an active,
bounded track needs enough independent sequencing to justify a separate document.
A specialized roadmap shall refine this roadmap without duplicating its mutable
checkpoint or changing repository-wide milestone order.

When a specialized roadmap completes, move any durable ownership, failure,
resource, build, or test contract into its authoritative subsystem document and
remove the completed roadmap once Git history is sufficient to preserve its
development sequence. Do not retain completed roadmaps as permanent progress
logs.

The long-term objectives and final project direction below are user-owned.
Implementation work may revise intermediate ordering, prerequisites, and exit
criteria when evidence requires it, but shall not remove, narrow, replace, or
redefine those final goals without an explicit user request.

## Scope And Long-Term Direction

The primary language goal is a useful Ada 2022 subset with an architecture that
can expand without replacing the compiler pipeline.

The long-term project direction remains:

- a standalone compiler written in Ada;
- a separated frontend and backend architecture;
- a custom, target-independent IR;
- staged self-hosting;
- cross-platform compiler and program targets;
- a Wasm backend;
- an optional LLVM backend;
- structure suitable for later SPARK-related constraints; and
- optional Clair formatter tooling that does not define repository acceptance
  criteria.

Full Ada 2022 coverage, complete SPARK verification, advanced optimization,
tasking, protected objects, and specialized annex support are not prerequisites
for the initial useful compiler or the first self-hosting milestone.

## Architectural Invariants

The connected compiler pipeline remains:

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

Language work proceeds as vertical slices through every stage required by the
feature. Parser-only acceptance is not compiler support. Target-specific ABI or
object-format behavior shall not leak into the frontend, AST, semantic model, or
target-independent IR. `../architecture.md`, `../failure-model.md`,
`../resource-limits.md`, and `../engineering-principles.md` own the durable
architecture, failure, bounded-resource, and engineering contracts.

The custom IR remains the semantic center between analysis and backends. LLVM may
be added as an optional backend later, but LLVM IR shall not replace Adac's own
target-independent representation.

Milestone ordering below is **exit ordering**, not a ban on prerequisite slices
from later subsystems. For example, Milestone 3 control-flow work may add the IR
basic blocks and native branches required to validate that feature end to end.
Those enabling slices do not make Milestone 4 or 5 complete; those milestones
stabilize and close the representations introduced incrementally.

## Support-State Model

Track language and runtime capabilities using these states:

```text
unsupported
parsed
semantically checked
lowered to IR
code generated
runtime supported
validated
```

A state applies to a documented feature boundary, not one positive example.
`validated` requires the applicable positive, negative, IR, backend, execution,
failure, resource, and target tests. Bootstrap-profile sources use the same model
as defined by `../bootstrap-profile.md`.

Track target support independently for build host, compiler target, and program
target according to `../target-support.md`.

## Current Baseline

Milestones 0, 1, and 2 are complete. The deterministic bootstrap profile parses
completely into structurally validated ASTs; there is no remaining bootstrap
frontend frontier. Frontend syntax coverage is therefore substantially broader
than the subset currently accepted by semantic analysis and native execution.

The current semantic/native subset is intentionally narrower and centered on a
context-free procedure body:

- procedure-local `Integer`, `Natural`, `Positive`, local Integer subtypes,
  compile-time Integer constants and named numbers, and exact static numeric
  evaluation;
- mutable Integer locals with checked static initialization/assignment and direct
  initialized/defined local-to-local copies;
- procedure-local `Boolean`/`Standard.Boolean`, compile-time Boolean constants,
  mutable Boolean locals, and static Boolean expressions;
- eager runtime Boolean expression trees containing mutable-local reads, static
  subtrees, parentheses, `not`, `and`, `or`, `xor`, and all six Boolean relations;
- direct mutable-local `and then`/`or else` assignments with genuine lazy native
  evaluation of the right operand; and
- target-independent scalar IR plus native GNU-style x86-64 assembly, assembly/
  linking through the system toolchain, and executable validation on supported
  FreeBSD and Linux program targets.

General runtime Integer arithmetic/comparison trees, mixed or nested runtime
short-circuit operands, statement conditions, branches, loops, callable
subprogram semantics, context clauses, packages, and separate compilation remain
outside the current semantic execution boundary. `../semantic-model.md`,
`../type-model.md`, and `../ir-validation.md` are authoritative for exact current
representation and validation details.

## Current Work Checkpoint

This is the repository's single durable resumption checkpoint. Rewrite it in
place before a commit changes development position.

| Field | Current value |
| --- | --- |
| Active milestone | Milestone 3A: Runtime Scalar Expressions |
| Last completed work | Direct mutable-Boolean `and then` and `or else` assignments lower through semantic provenance, target-independent lazy Boolean IR values, validated x86-64 branching, and executable tests. The right local load is skipped when the left operand determines the result. |
| Current semantic boundary | Mixed/nested eager Boolean runtime trees are supported; runtime short-circuit operands are still limited to a direct initialized/defined mutable local on each side. Integer runtime state supports static initialization/assignment and direct initialized/defined local copies, but not general runtime arithmetic or Integer relations. Statement conditions and control flow are not yet semantically lowered. |
| Next active work | Generalize runtime `and then`/`or else` assignment operands to bounded mixed/nested Boolean expression trees while preserving left-first evaluation, conditional right-subtree evaluation, per-runtime-leaf definition provenance, maximal safe static folding, deterministic construction, and bounded validation. Statement conditions remain outside this slice. |
| Next language prerequisite | Apply Ada 2022 AARM 4.5.1 and 5.2 rules for Boolean short-circuit assignment expressions: both operands use the expected Boolean type, the left is evaluated first, and the right is evaluated only when required. Static folding must never convert a potentially skipped runtime subtree into eager evaluation. |
| Critical path after the next slice | Runtime Integer expressions and comparisons -> Boolean statement conditions and `if` -> `case`/loops/`exit` -> procedure/function calls and returns -> remaining scalar semantic closure. |
| Latest validation | `rake check` passes 2/2 suites, 12 cases, and 681/681 assertions on x86-64 FreeBSD. The bootstrap-profile frontend gate parses every derived production member. |
| Environment caveat | No current validation blocker. Project-controlled temporary work belongs under `build/tmp/` as required by `AGENTS.md`. |

A resumed run shall inspect Git state and the authoritative subsystem contracts
before trusting this checkpoint.

## Completed Foundations

| Milestone | Durable result |
| --- | --- |
| 0: Baseline Stabilization | Connected source-to-executable pipeline, controlled CLI/source failures, explicit target rejection, and failure-safe output behavior are established. |
| 1: Compiler Context And Core Infrastructure | Per-compilation ownership, stable context-owned identities/stores, source spans, diagnostics, validators, and bounded resource contracts are established. Concrete `Type_ID` support was introduced later when scalar semantics required it rather than as speculative placeholder state. |
| 2: Frontend Coverage | Every tracked bootstrap-profile compiler source parses and structurally validates through the deterministic frontend gate. Parsing remains bounded and syntax support is explicitly distinct from semantic/runtime support. |

Completed source-structure, build-layout, and test-framework modernization is now
part of the durable contracts in `../architecture.md`, `../repository-layout.md`,
and `../test-orchestration.md` rather than separate roadmaps.

## Milestone 3: Semantic Core And Scalar Execution

### Objective

Compile useful scalar Ada programs with declarations, runtime expressions,
control flow, and subprogram calls. Milestone 3 is divided into ordered phases so
implementation reaches useful executable algorithms instead of over-expanding one
expression family before control flow exists.

### Milestone 3A: Runtime Scalar Expressions

Complete the runtime expression substrate needed by branches and loops.

Work:

- generalize lazy Boolean `and then`/`or else` from direct-local pairs to mixed
  and nested runtime/static Boolean expression operands;
- preserve left-to-right evaluation, skipped-right-subtree behavior, local
  definition provenance, maximal safe static folding, and bounded deterministic
  value-graph construction;
- add runtime Integer expression values for local reads and the selected unary,
  arithmetic, multiplying, and relational operators required by useful scalar
  programs;
- lower Integer comparisons to Boolean values suitable for later statement
  conditions;
- define and validate runtime range, overflow, division-by-zero, and other checks
  as each operation makes them observable; and
- retain exact static evaluation instead of replacing it with host-width runtime
  arithmetic during constant folding.

Exit criteria:

- mixed/nested lazy Boolean assignments execute with observably correct skipped
  evaluation;
- representative runtime Integer arithmetic and comparison expressions involving
  mutable locals lower through validated IR and execute correctly;
- invalid or undefined local reads and arithmetic failures use the documented
  source/runtime failure boundary; and
- expression construction/validation remains deterministic and bounded for large
  supported trees.

### Milestone 3B: Scalar Control Flow

Use the scalar expression substrate to execute real algorithms.

Work:

- accept semantically checked Boolean expressions as `if`/`elsif` conditions;
- lower `if`/`elsif`/`else` with explicit target-independent control flow;
- add the selected scalar `case` forms;
- add `while`, simple loop, and selected `for` loop execution;
- implement `exit` and conditional `exit when` with validated loop ownership;
- introduce or extend IR basic-block, branch, merge, and loop representations only
  as required by these vertical slices; and
- keep CFG construction, label allocation, and validation deterministic and
  bounded for large statement graphs.

Exit criteria:

- a program can compute mutable Integer/Boolean values through runtime branches
  and loops and produce the expected executable behavior;
- nested supported control flow validates without source-controlled host-stack
  growth;
- illegal conditions, case choices, and loop exits fail with source-level
  diagnostics; and
- IR rejects malformed branch targets, unterminated blocks, and invalid ownership
  before backend emission.

### Milestone 3C: Subprogram Execution

Add callable scalar program structure after expression and control-flow semantics
are stable.

Work:

- define callable procedure/function entities and lexical parent relationships;
- extend scopes and visibility beyond one direct procedure declarative region;
- implement procedure/function profiles, parameter modes needed by the selected
  scalar subset, calls, returns, and function result values;
- implement nested subprograms to the extent required by the bootstrap profile;
- represent calls and returns explicitly in target-independent IR; and
- implement the corresponding native stack-frame and System V call boundary
  without leaking ABI choices into semantic state.

Exit criteria:

- supported procedures and functions can call one another with checked arguments
  and return values;
- nested supported subprogram references resolve through explicit lexical scope;
- parameter/return type and mode errors produce deterministic source diagnostics;
  and
- recursive or deeply nested supported call structures do not corrupt compiler
  ownership or validation state.

### Milestone 3D: Scalar Semantic Closure

Close the remaining semantic requirements of the original scalar milestone.

Work:

- implement enumeration type semantics needed by the supported scalar subset;
- complete expected-type propagation and implicit conversions required by the
  selected operators and calls;
- construct and resolve overload sets where the supported language surface needs
  them;
- complete direct-name, scope, and visibility rules required by supported scalar
  declarations and subprograms;
- retain universal integer and universal real compile-time behavior required by
  the supported static expression surface; and
- close positive/negative coverage for visibility, type, overload, declaration,
  expression, and control-flow legality.

Milestone 3 exit criteria:

- supported scalar declarations and expressions are type-checked before IR
  lowering;
- ambiguous and illegal supported programs are rejected with source-level
  diagnostics;
- variables, branches, loops, procedures, and functions execute correctly on the
  supported scalar subset; and
- negative tests cover visibility, type, overload, and control-flow errors.

## Milestone 4: Typed IR And Control-Flow Stabilization

### Objective

Stabilize the typed value and control-flow representations introduced
incrementally by Milestone 3 into a backend-independent contract suitable for
multiple backends.

### Work

- define the durable typed high-level IR that preserves relevant Ada meaning;
- define a lower control-flow IR with functions and basic blocks where a separate
  level is justified;
- represent values, memory operations, calls, branches, and returns explicitly;
- represent runtime checks explicitly;
- represent exceptional or failing operations without hidden backend behavior;
- define target-independent data-layout requirements;
- provide deterministic textual dumps;
- validate dominance, block termination, types, references, and ownership; and
- keep backend-specific registers, calling conventions, and object formats out of
  target-independent IR.

An additional machine-level IR may be introduced when native code generation
requires it. It is not required before the typed and control-flow IR contracts
are stable.

### Exit Criteria

- every supported scalar program lowers through validated IR;
- invalid IR is rejected before backend emission;
- IR dumps are deterministic and covered by regression tests; and
- dump and native backends consume the same validated module contract.

## Milestone 5: Native Backend And Minimal Runtime

### Objective

Stabilize the existing x86-64 Linux and FreeBSD path as a dependable native
execution platform for the scalar language subset.

### Work

- complete stack frames and local storage;
- complete Integer and Boolean operations;
- complete comparisons and conditional branches;
- complete function calls, arguments, and return values;
- implement global and read-only data;
- define alignment and target data layout;
- define the supported System V ABI boundary;
- add runtime checks for ranges, overflow, division, and null access as needed;
- add program initialization, elaboration entry, and termination support;
- write output through temporary files and publish it atomically when practical;
  and
- distinguish toolchain unavailability from malformed compiler output.

Direct ELF object generation is not required at this milestone. Assembly plus a
documented system assembler and linker driver remains an acceptable backend.

### Exit Criteria

- scalar programs execute correctly on supported Linux and FreeBSD targets;
- ABI behavior is documented and tested;
- backend failures produce controlled operational or internal diagnostics; and
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
- implement incremental rebuild and cache invalidation rules; and
- define deterministic elaboration ordering and generated metadata.

The metadata format shall be an Adac-owned interface. Compatibility with another
compiler's private metadata format is not a requirement.

### Exit Criteria

- a program containing multiple package specifications and bodies builds;
- interface changes invalidate dependent units correctly;
- dependency and elaboration diagnostics are deterministic; and
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
  and
- implement accessibility checks required by the selected subset.

### Exit Criteria

- arrays, strings, records, and access values execute correctly;
- constrained and unconstrained representations are documented;
- bounds, discriminants, and accessibility failures are tested; and
- object lifetime and cleanup behavior are explicit at exceptional exits.

## Milestone 8: Exceptions, Generics, And Tagged Types

### Objective

Add the major language mechanisms required by reusable libraries and a broader
self-hosting compiler implementation.

### Exceptions

- exception declarations and `raise`;
- handlers and propagation;
- cleanup and finalization during propagation;
- controlled unhandled-exception termination; and
- optional traceback support behind a stable runtime interface.

### Generics

- generic formal objects, types, and subprograms;
- generic packages and subprograms;
- instantiation environments and legality checking;
- recursive and cyclic instantiation detection; and
- documented code-sharing or specialization policy.

### Tagged Types

- tagged records and type extension;
- primitive operations and overriding;
- class-wide types;
- dispatch tables and dynamic dispatch; and
- interfaces after the base dispatch model is validated.

### Exit Criteria

- exceptions propagate across supported calls without leaking owned resources;
- selected generic containers or compiler-specific generic utilities work;
- tagged dispatch works for the documented subset; and
- negative tests cover illegal instantiation, overriding, and handler cases.

## Milestone 9: Staged Self-Hosting

### Objective

Build `adac` with `adac` without making full Ada support a prerequisite.

### Bootstrap Profile

The bootstrap language boundary, source membership, progression, and enforcement
rules are defined in `../bootstrap-profile.md`. This milestone completes their
automated use through the staged self-hosting chain.

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

Byte-for-byte equality may exclude documented nondeterministic fields until those
fields are removed or normalized. Functional equality alone is not the final
reproducibility goal.

### Exit Criteria

- the bootstrap profile is documented and automatically checked;
- stage2 and stage3 pass the same compiler regression suite;
- stage differences are explainable and eventually reproducible; and
- the seed compiler is required only to start a clean bootstrap chain.

## Milestone 10: Cross-Platform Expansion

### Objective

Extend both compiler targets and program targets without weakening frontend, IR,
ABI, or validation boundaries.

### Direction

The current expansion direction remains:

1. stabilize x86-64 Linux and FreeBSD;
2. add Wasm module generation;
3. add AArch64 Linux;
4. add x86-64 Windows;
5. add Darwin targets; and
6. add an optional LLVM backend.

Ordering may change when prerequisites or project needs change. A target is not
supported merely because the compiler executable can be cross-built for it.
Program emission requires a matching backend, ABI, data layout, output format,
toolchain contract, and end-to-end tests.

### Required Target Work

- target-triple parsing and normalization;
- compiler-target and program-target separation;
- ABI and calling-convention definitions;
- object or module format integration;
- assembler and linker selection where applicable;
- runtime porting;
- target-specific diagnostics;
- native, emulated, or externally verified execution tests; and
- explicit unsupported-combination rejection.

### Exit Criteria

- each advertised target has a documented support level;
- frontend behavior does not depend on the build host;
- unsupported target combinations fail before publishing output;
- cross-target output is covered by deterministic backend tests; and
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
- selected real-time or systems-programming facilities; and
- Ravenscar or other restricted profiles when their runtime contracts are
  sufficiently defined.

Tasking is a runtime and memory-model project, not only a parser feature.

### Exit Criteria

- the sequential and tasking runtimes can be configured explicitly;
- supported synchronization behavior is documented and stress-tested;
- failures and exceptions across task boundaries preserve compiler guarantees;
  and
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
- optional Clair formatter;
- optional language-server or incremental-analysis interfaces;
- optional LLVM backend maturation; and
- direct object writers when they provide clear portability or control gains.

### Exit Criteria

- optimization preserves observable behavior across the regression suite;
- analysis and formatter tools reuse stable compiler representations where useful;
- optional backends cannot silently change language semantics; and
- tooling failures cannot corrupt normal compiler output.

## Validation Strategy

Every language feature adds the applicable tests from this set:

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
- unsupported-feature tests; and
- target-matrix tests.

### Differential Validation

Where language behavior is defined and comparable, test programs may be compiled
with another Ada implementation and compared for acceptance/rejection, execution
results, exception behavior, static-expression results, and representation details
only when the language or documented ABI defines them. Keep implementation-defined
behavior separate from language-conformance comparisons.

### Conformance Suites

Introduce applicable Ada conformance tests incrementally as the supported subset
grows. Classify each imported test as passing, failing, unsupported, or not
applicable, with unsupported classifications tied to documented feature
boundaries.

### Fuzzing And Adversarial Inputs

Fuzzing targets include source decoding, lexer/token streams, parser/recovery,
diagnostic rendering, metadata readers, IR readers/deserializers when introduced,
command-line handling, and target-triple handling.

Resource tests cover very large token counts, long identifiers, deep nesting,
large overload sets, large dependency graphs, repeated error recovery, storage
exhaustion, interrupted output, and cancellation.

## Completion Definition

A milestone is complete only when:

- its public and internal contracts are documented;
- required implementation paths are connected;
- validators enforce the new invariants;
- positive and negative regression tests pass;
- supported target tests pass;
- failure paths do not publish invalid output;
- deterministic behavior is maintained or documented; and
- the next milestone does not require bypassing the established architecture.

The roadmap may be revised as implementation exposes new constraints. Such
revisions shall preserve explicit support boundaries, vertical feature slices,
custom IR independence, failure containment, and the path toward self-hosting and
cross-platform support.
