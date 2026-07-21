# Compiler Identifiers

This document defines the common contract for stable identifiers owned by an
Adac compilation context. The initial implementation covers `Source_File_ID`.
Later identifier types shall follow the same ownership and determinism rules
unless their subsystem documents a stricter contract.

## Purpose

Compiler objects should be owned once and referenced by small, typed
identifiers. This avoids repeated strings, ambiguous object ownership, and
long-lived access values between compiler stages.

Stable identifiers support:

- explicit ownership and lifetime boundaries;
- independent compilations in one process;
- deterministic allocation and diagnostics;
- compact positions, AST nodes, semantic objects, and IR references;
- validation before a later compiler stage consumes an object.

## Identifier Types

Each identifier category is a distinct Ada type. Values from different
categories shall not be implicitly interchangeable.

The planned categories are:

```text
Source_File_ID
Node_ID
Symbol_ID
Entity_ID
Type_ID
```

`Source_File_ID` is implemented first. The remaining types shall be introduced
with the stores and validators that own them.

## Context Ownership

An identifier belongs to exactly one store in exactly one compilation context.
It is meaningful only while that context and store remain alive.

Passing an identifier to a different context, retaining it beyond the owning
context's lifetime, or using it with the wrong identifier category is an
internal compiler contract violation.

A store shall validate ownership before resolving an identifier. The initial
source registry embeds an opaque runtime ownership marker in every
`Source_File_ID`. The marker allows cross-context use to be rejected even when
two contexts allocate the same numeric index.

The ownership marker is an implementation validation aid. It shall not be
serialized, rendered in diagnostics, hashed into persistent metadata, or used
to determine externally visible ordering.

## Invalid State

Every identifier type shall define an explicit invalid value.

```text
INVALID_SOURCE_FILE_ID
```

A default-initialized position may contain the invalid value until a lexer or
parser assigns a real source location. Resolving an invalid identifier is an
internal compiler contract violation.

Ordinary callers shall not be able to manufacture arbitrary valid identifiers
through numeric conversion or public record construction. Deliberate unchecked
operations are outside this contract.

## Deterministic Allocation

Valid identifiers are allocated in deterministic first-registration order
within their owning store. The first source file registered in a context gets
the first valid index, independently of files registered in another context.

Allocation order shall not depend on:

- hash-table iteration order;
- memory addresses;
- unrelated process-global counters;
- scheduling in another compilation context;
- target-specific backend behavior.

A runtime ownership marker may differ between process executions because it is
not part of the identifier's persistent or externally visible identity.

## Source File Registry

`Adac.Source.Registry` owns source path strings and assigns
`Source_File_ID` values. `Adac.Compilation.Context` owns one registry for the
entire compilation attempt.

The registry keeps two bounded-by-input structures:

- an ordered path-to-ID map for deterministic lookup;
- an index-to-path vector for constant-time ID resolution.

This stores at most two path copies per registered file and removes the previous
copy of the full path from every token position.

Registering the same exact path string more than once in one context returns the
existing ID and does not add another entry.

The registry records the path spelling supplied to the frontend. It does not
implicitly:

- resolve symbolic links;
- convert a relative path to an absolute path;
- normalize `.` or `..` components;
- apply file-system case folding;
- compare file identities through device and inode metadata.

Those operations depend on host policy and may fail independently. A later
source manager may add explicit canonicalization without changing the identifier
ownership contract.

A path may be registered before the frontend successfully opens it. The registry
therefore represents source paths requested during the compilation, not only
files that were read successfully.

## Source Positions

A source position contains:

```text
Source_File_ID
line
column
```

Line and column remain one-based positive values. A position does not own or
copy a source path.

Diagnostic rendering resolves the identifier through the compilation context's
source registry and produces the existing form:

```text
path:line:column
```

This resolution must occur while the owning context is alive. A diagnostic from
one context shall not resolve a position through another context.

## Failure Behavior

The following conditions are internal compiler contract violations:

- resolving `INVALID_SOURCE_FILE_ID`;
- resolving an identifier through a foreign registry;
- resolving an index outside the owning registry;
- using an identifier after its context has been destroyed.

They shall not be converted into ordinary source diagnostics.

Exhausting the representable source-file index space is a resource failure. The
registry shall reject the allocation rather than wrap, reuse a live identifier,
or return an invalid value.

If registration cannot update all required registry structures, it shall roll
back the partial update before propagating the failure.

## Concurrency

Different registries may be used independently by different compilation
contexts. Operations on the same registry are sequential unless a stronger
contract is introduced later.

No process-global mutable counter or registry is used for source identifiers.
Parallel scheduling in one compilation shall not determine externally visible
identifier allocation order.

## Serialization

Persistent metadata shall serialize a documented stable ordinal or another
schema-defined representation, never an address-derived ownership marker.

Serialized identifiers are meaningful only with the serialized store and schema
version that define them. Deserialization shall validate bounds, ownership
relationships, and format versions before creating internal references.

Persistent source metadata is not implemented by the initial registry.

## Completion Criteria

The initial source identifier work is complete when:

- `Source_File_ID` is a private, context-owned identifier type;
- an explicit invalid value exists;
- every context owns an independent source registry;
- exact duplicate paths return the same ID within one context;
- positions no longer copy source paths;
- path resolution rejects invalid and foreign IDs;
- diagnostic text remains unchanged;
- in-process tests verify allocation, lookup, deduplication, and isolation;
- repository checks pass.
