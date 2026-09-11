# Failure Model

Adac distinguishes expected input failures, internal compiler contract
violations, and external system failures.

## Expected Input Failures

Source text, command-line arguments, target descriptions, object files, and
other user-controlled inputs shall be treated as untrusted input.

Invalid source code, invalid command-line usage, unsupported language features,
and other documented input errors are expected compilation failures. They shall
be reported through normal diagnostics and shall result in an unsuccessful exit
status.

Expected input failures are not internal contract violations and shall not be
reported as internal compiler errors.

Parser recovery is opt-in at explicitly documented grammar boundaries. A
recoverable source error may be diagnosed and scanning may continue only when the
synchronization rule guarantees token-stream progress and cannot publish the
failed enclosing construct as a successful stage result. Recovery scanning remains
subject to the ordinary source/resource budgets. If synchronization encounters a
resource-limit failure, external failure, or internal contract violation, recovery
stops immediately and the terminal failure is preserved. A compilation that used
parser recovery remains unsuccessful even when later syntax is consumed
successfully.

Exceeding an explicitly configured compiler budget because of input size is an
expected compilation failure. The input-facing stage shall report a controlled
diagnostic and stop before publishing a partial stage result. This is distinct
from allocator or operating-system resource exhaustion.

Public and input-facing operations shall validate untrusted input before passing
it to operations whose preconditions assume validated internal data.

## Internal Compiler Contract Violations

A call to an internal operation implies that its documented preconditions have
already been satisfied by the caller.

Examples of internal contract violations include:

- a required access value being null;
- an invalid enumeration value, index, length, or range;
- a malformed or inconsistent AST or IR object;
- an object being passed to the wrong compiler stage;
- an impossible compiler state;
- a violation of resource ownership or lifetime rules.

Internal contract violations shall not be silently converted into successful
control flow, ordinary source diagnostics, unsupported-feature diagnostics, or
fallback behavior.

An internal contract violation may be intercepted at the top-level compiler
boundary only to release resources, prevent invalid output from being
published, and report an internal compiler error.

Compilation shall not continue after an internal contract violation when doing
so could produce misleading diagnostics, corrupt compiler state, or emit
invalid output.

## External System Failures

External system failures occur when a valid compiler operation cannot complete
because of the execution environment.

Examples include:

- source or output file access failure;
- permission failure;
- storage exhaustion or file-system failure;
- operating system resource failure;
- failure to create an external process;
- an unavailable or failed assembler, linker, or optional backend;
- backend communication failure;
- allocation or resource exhaustion;
- interruption or cancellation;
- external protocol failure.

External failures may require controlled diagnostics, state invalidation,
resource teardown, retry behavior, temporary-file removal, or another
documented recovery action.

The origin of an error does not by itself determine its category. In
particular, rejection by an external assembler or linker is an internal
compiler failure when the rejection was caused by malformed output generated
by Adac.

Likewise, an allocation-related exception caused by environmental exhaustion
is an external failure, while one caused by an internal unbounded computation
or invalid compiler state is an internal compiler failure.

## Resource Cleanup

Resource cleanup operations may accept an empty, closed, or null resource as an
idempotent no-op only when that behavior is explicitly part of their documented
contract.

All resources owned by an operation shall be released on both normal and
exceptional exits.

Cleanup failure shall not silently replace or hide the primary failure.
Relevant secondary cleanup failures may be attached to the primary diagnostic.

Partially generated compiler output shall not be published as a successful
result. Output should be written to temporary files and committed atomically
when practical.

## Failure Reporting

Expected input failures shall produce ordinary diagnostics and an unsuccessful
exit status.

External system failures shall produce controlled operational diagnostics and
an unsuccessful exit status.

Internal compiler failures shall produce an internal compiler error diagnostic
and an unsuccessful exit status. The diagnostic should include enough stage and
location information to identify the violated invariant without exposing
irrelevant implementation details to ordinary users.

A successful exit status shall be produced only after every required compiler
stage has completed successfully and the final output has been published.
