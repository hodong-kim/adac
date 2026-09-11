# Engineering Principles

This document defines repository-wide principles for engineering and design
decisions in Adac. Subsystem documents remain authoritative for their concrete
contracts, invariants, and implementation boundaries.

## Minimum Sufficient Design

A minimum sufficient design is the smallest design that fully satisfies the
defined goal and the engineering properties required to make that goal sound.
It is not the design with the fewest components, abstractions, checks, or lines
of code.

The defined goal includes its documented contracts, acceptance criteria, and
known prerequisites. It does not implicitly expand to unrelated or hypothetical
future goals.

For a goal A, retain every structure, invariant, boundary, or capability needed
to achieve A with the required correctness, performance, safety, reliability,
maintainability, and testability under the intended operating conditions. If
removing an element makes A brittle, weakens those properties, creates a known
architectural dead end, or forces avoidable redesign of a boundary already
known to be required to complete, operate, or safely evolve A, that removal is
underdesign rather than simplification.

Do not add generality solely for hypothetical future goals B or C. Extensibility
is part of maintainability when it is necessary to complete, operate, or safely
evolve A without violating A's contracts or invariants. Speculative extension
points, generic frameworks, and abstractions without such a requirement shall
be deferred until a demonstrated need exists.

Distinguish required structure from a particular implementation mechanism.
Required ownership, lifecycle, concurrency, failure, persistence, isolation,
or extension boundaries may need to be established up front, while the
concrete mechanism should remain undecided until constraints, evidence, or
implementation work justify choosing it.

When deciding whether an element belongs in the design, ask whether omitting it
would compromise correctness, performance, safety, reliability,
maintainability, testability, or the ability to evolve A in a way already
required by A's documented constraints. If so, retain it. If its only
justification is an uncertain future requirement unrelated to completing,
operating, or safely evolving A, defer it.
