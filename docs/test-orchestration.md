# Test Orchestration

This document defines Adac-owned test discovery, fixture interpretation, process
execution, result aggregation, and failure preservation.

## Ownership

`adac-test-runner` is the only test-result authority invoked by `rake test`.
It owns one `Clair.Test.Reporter.Context` and reports two suites:

```text
compiler fixtures
internal compiler tests
```

The runner uses `Clair.Process.Execution` for every tested executable. Clair
owns bounded process execution, timeout and process-tree termination, retained
output, and result aggregation. Adac owns fixture discovery and all
project-specific success rules.

Rake builds the production tools and the Adac-owned internal test executable.
Before it builds the test runner directly with GPRbuild, it invokes `rake build`
in the sibling Clair repository with the resolved target, target OS, and build
profile. The sibling repository is resolved as `../clair` from the Adac
repository root; orchestration documentation and configuration shall not depend
on a workstation-specific absolute project path. Clair remains the sole owner
of its generated probes, generated source, library artifacts, transactions, and
locks. Adac does not synthesize Clair artifacts or assume that an earlier Clair
build populated them.

After preparing Clair, Rake builds the test runner, passes absolute executable
and repository paths to it, invokes the runner once, and does not interpret test
results.

## Deterministic Discovery

Compiler fixtures are descendant directories of `tests/` that contain
`input.adb` or `input-path.txt`. Non-fixture directories group tests by durable
feature area; discovery descends through them with a bounded depth and does not
descend below a fixture directory. The runner sorts full compiler-fixture paths
before execution so file-system enumeration order cannot affect result or
diagnostic order.

A missing fixture root, empty fixture set, ambiguous compiler input, missing
required file, invalid expected result, malformed argument file, or compiler
fixture nesting beyond the configured discovery bound is a test infrastructure
failure. It is not silently skipped.

A compiler fixture's identity is its path relative to `tests/`, not its final
directory basename. That relative path is used consistently for process labels,
source paths passed to the compiler, fixture-visible output paths, and the
mirrored directory below the run-owned compiler work root. Two nested fixtures
therefore cannot collide merely because their leaf directory names match.

## Compiler Fixture Contract

Compiler fixtures use this vocabulary:

```text
input.adb
input-path.txt
arguments.txt
omit-output-option.txt
output-is-directory.txt
missing-toolchain.txt
preserve-output.txt
expected-result.txt
expected-stdout.txt
expected-diagnostics.txt
expected-stderr.txt
expected-assembly.txt
expected-assembly-patterns.txt
```

`expected-result.txt` contains the result category `success` or `failure`. It
does not encode a numeric process exit status. No current compiler fixture makes
a numeric exit code part of the contract; a future fixture that needs one shall
introduce an explicit exact-exit-code expectation rather than overloading the
category file.

Every compiler fixture contains exactly one stdout oracle:

- `expected-stdout.txt` compares the complete normalized stdout byte-for-byte.
  Use it only when the complete CLI presentation or successful pipeline dump is
  intentionally part of the regression contract.
- `expected-diagnostics.txt` compares, in order and byte-for-byte, only stdout
  lines beginning with `adac: error:`. Use it for ordinary rejected-source
  fixtures so progress messages such as parsing or stage-completion notices do
  not become unrelated golden contracts.

`expected-stderr.txt` is optional. When it is absent, stderr must be empty. When
present, stderr is compared byte-for-byte. stdout and stderr are therefore
independent test channels rather than one successful stdout snapshot plus
unexamined stderr.

The adapter:

- rejects fixtures containing both input forms or neither input form;
- parses `arguments.txt` using shell-word quoting and escaping;
- checks the expected success or failure result category;
- rejects a missing or ambiguous stdout oracle;
- retains stdout and stderr separately under the configured `build/tests/` work
  root;
- compares either complete stdout or only exact `adac: error:` diagnostic lines
  according to the selected oracle;
- requires empty stderr unless an explicit stderr oracle exists;
- compares generated assembly byte-for-byte when `expected-assembly.txt` exists;
- otherwise, when `expected-assembly-patterns.txt` exists, applies ordered
  semantic assembly patterns;
- requires successful fixtures to publish assembly and an executable;
- executes each successfully published program;
- verifies failed fixtures do not publish an executable;
- verifies `preserve-output.txt` fixtures retain the previous output;
- rejects stale or remaining temporary and backup work files; and
- removes an output directory fixture after the primary result is recorded.

Cleanup failure is secondary to an earlier process, assertion, or adapter
failure. It is reported separately and never changes an earlier failure into
success.

### Assembly Oracles

A fixture may contain at most one assembly oracle. `expected-assembly.txt` is an
exact whole-file snapshot and is reserved for a deliberately selected canonical
or ABI baseline. Most backend-semantic fixtures should instead use
`expected-assembly-patterns.txt`. Successful compiler fixtures without either
assembly oracle still require assembly and executable publication and execute the
resulting program. A failed compiler fixture requires assembly publication only
when it selects an assembly oracle.

Assembly-pattern files use a small Adac-owned line format. Empty lines and lines
beginning with `#` are ignored. A line beginning with `+ ` requires the remaining
literal text to occur on an assembly line after the line matched by the previous
`+` pattern. A line beginning with `! ` forbids the remaining literal text on any
assembly line. Required matches may have unrelated lines before, between, or
after them. Pattern text is literal rather than regular-expression syntax, so
matching work is deterministic and bounded by the generated assembly and pattern
file sizes. A selected pattern file must contain at least one `+` or `!`
directive. Malformed directives, empty operands, and directive-free files are
test infrastructure failures.

Use patterns to pin semantic backend properties such as frame allocation, local
slot selection, store/load order, and required return structure without making
every emitted line a contract. Exact snapshots shall not be copied across
fixtures merely because current assembly happens to be identical.

## Fixture Corpus Growth

Production-frontier coverage shall not preserve one copied source prefix for each
historical development step. `package-bootstrap-frontier-current` points to the
authoritative production `src/adac/ast/adac-ast.ads` through `input-path.txt` and
owns only the current external compiler-stage diagnostic. That source now parses
completely in the frontend; the fixture may therefore exercise a later stage and
shall not be interpreted as the bootstrap-profile syntax frontier. Historical
frontier positions remain in Git history.

Focused syntax, ownership, resource-exhaustion, and failure regressions remain
separate tests. A new fixture family whose members repeat an ever-growing common
input must be redesigned when one mutable frontier plus focused invariant tests
can provide the same coverage. Corpus growth should be proportional to distinct
capabilities or regressions, not to the number of sequential roadmap steps.

## Internal Test Contract

`adac-internal-tests` owns in-process compiler contract tests that require direct
access to Adac APIs or test-only child packages. The shared
`Adac_Internal_Test_Catalog` defines a bounded set of named subsystem scenarios.
The internal executable accepts exactly one catalog scenario per invocation; the
Adac test runner iterates the same catalog and executes every scenario as an
independent `Clair.Test` process case.

Each scenario is process-isolated from the others. A contract failure therefore
identifies the scenario in the runner result and does not prevent later scenarios
from running. Scenario output is not a correctness oracle. Internal assertions
verify ownership, counts, identities, stage results, and resource invariants
directly; exact user-visible diagnostic wording remains the responsibility of
focused compiler fixtures. No repository-wide internal stdout golden transcript
is maintained.

The shared catalog is Adac-owned test support and has no production dependency.
The internal executable may place each catalog scenario body in an
implementation-only nested-procedure subunit. Those subunits share only the
parent executable's test helpers and do not create a second scenario registry,
runner, or correctness authority. This structure uses Clair's existing public
process-case interface; a required Clair change still needs explicit user
approval.

The `bootstrap-profile-frontend` scenario receives a run-owned manifest derived by
Rake from the production `adac.gpr` main closure intersected with Git-tracked Ada
sources. It walks every relative path in deterministic order with a fresh
compilation context per member, requires each member to parse without diagnostics,
and
structurally validates every resulting AST. Any unsupported or regressed member
fails the scenario. The manifest is a generated test artifact below the unique
work root and is preserved with that root on failure.

## Repository Checks

`rake check` combines target-configuration checks, project-boundary checks, and
the unified compiler/internal test runner. Source-style conventions are documented
in `STYLE-GUIDE.md` for contributor guidance and are not an executable test suite
or acceptance gate.

## Failure And Resource Contract

Each child process receives:

```text
stdout capture limit: 1 MiB
stderr capture limit: 1 MiB
timeout:              120 seconds
termination scope:    process tree
```

An unexpected normal exit is an assertion failure. A signal, timeout, launch
failure, process infrastructure failure, output truncation, or cleanup failure
is a diagnostic failure with its category retained in the message. An expected
compiler rejection remains a passing fixture when its exact result and output
contract match.

## Test Work Artifacts

Rake owns a target/profile-specific parent directory at
`build/tests/<target>/<profile>/`. Each test invocation atomically creates one
unique `run-*` child below that parent and passes only that child to the Adac test
runner. Compiler fixtures retain stdout and stderr separately there and retain a
filtered `diagnostics.txt` when a diagnostic-only oracle is selected. Their
feature-relative path below `tests/` is mirrored below the run-owned `compiler/`
work directory. Compiler fixtures also place generated assembly, executables, and
backend temporary/backup files there.
Internal scenarios do not persist successful stdout. Source fixture directories
are immutable test inputs during a run.

When compiler output contains the generated output path, the adapter normalizes
only that known per-run path back to the fixture-visible `tests/.../main` path
before comparing user-visible output. Source locations, diagnostics, and all
other text remain exact. This compatibility normalization avoids rewriting
diagnostic golden files solely because artifacts live outside the source tree.

Independent runner invocations therefore never share generated fixture paths,
even for the same target and profile. A successful Rake test invocation removes
only its own run directory. A failed or interrupted invocation retains its own
run directory for inspection and reports that path when Rake observes the
failure. `rake clean` removes the complete target/profile parent, including any
retained failed runs. Future fixture sharding shall preserve one owned work root per
runner invocation rather than introducing shared generated files or source-tree
locks.
