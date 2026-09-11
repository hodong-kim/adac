# Bootstrap Profile

This document defines Adac's bootstrap profile: the Ada language and runtime
surface that the compiler implementation may rely on for staged self-hosting,
and the tracked Adac source files that are required to stay within that
surface.

`roadmaps/README.md` owns milestone ordering, required support states,
and self-hosting stages. This document owns bootstrap-profile scope,
membership, and progression rules. Test execution mechanics remain owned by
`test-orchestration.md` when profile validation is automated.

## Goals

The bootstrap profile exists to:

- validate compiler development against actual Adac source instead of relying
  only on isolated synthetic fixtures;
- keep the self-hosting language and runtime surface no larger than required;
- make bootstrap dependencies and support-state progression explicit;
- prevent bootstrap success from depending on simplified copies of production
  source; and
- provide a stable path from frontend parsing to reproducible self-hosting.

Profile membership or success at an early support state is not by itself a
self-hosting claim. Self-hosting requires the staged gates defined by the
roadmap.

## Language And Runtime Boundary

The language portion of the profile is the documented Ada subset used by the
compiler implementation itself. Retain every language and runtime capability
required by bootstrap sources and their documented prerequisites, but do not
widen the profile solely because an unrelated or hypothetical source might use
another feature.

When a compiler source relies on a capability outside the current profile,
decide whether to expand the profile or revise the source using
`engineering-principles.md`. Do not automatically expand the language boundary
to preserve an accidental implementation choice, and do not simplify the
source when doing so would violate the minimum sufficient design.

The Ada subset policy in `AGENTS.md` continues to apply. Obsolescent or
obsolete features are not admitted merely to ease bootstrap. The profile should
also avoid unnecessary dependence on large runtime or generic-library surfaces
until those surfaces are validated.

Compiler-specific arena, vector, string, or table utilities may be used when
they reduce bootstrap complexity and remain maintainable. Depending on a seed
compiler's private runtime ABI is not a self-hosting requirement.

## Source Membership

The source portion of the profile is the explicit, reviewable set of tracked
`.ads` and `.adb` files required to build the Adac compiler bootstrap target.
Unrelated Ada tools in the repository are not implicitly bootstrap members.

Membership is determined by the bootstrap target, not by current Adac compiler
capabilities or test outcomes. If a tracked Ada source becomes required by that
target, the profile shall be updated as part of the same architectural change;
it shall not wait until Adac can successfully process the file.

The production compiler GPR project is the build-system boundary for that target.
Auxiliary tool projects may share explicitly factored support or build policy,
but their mains and tool-only implementation units are not compiler bootstrap
members. An abstract common GPR project may share scenario and compiler-switch
policy only; it shall not broaden compiler source membership.

Each member shall refer to the authoritative production source in place. Do not
create a simplified, rewritten, or copied bootstrap-only variant solely to
avoid syntax, semantic, lowering, or code-generation work required by that
source.

Membership shall not change implicitly because directory contents, compiler
capabilities, or test outcomes change. A missing or renamed member is a profile
mismatch until the profile is deliberately updated. A member shall not be
silently skipped because the current compiler cannot satisfy the support state
required by the roadmap.

The concrete representation of membership is an implementation mechanism. This
contract does not require a particular manifest format, file name, or runner
integration before automation work establishes those constraints.

## Support-State Progression

Bootstrap-source requirements use the support-state model defined by
`roadmaps/README.md`. The roadmap determines which state the complete
profile must reach at each milestone or self-hosting stage.

Every profile member is subject to the state required by the applicable roadmap
gate. A later gate may raise that state, but an individual source shall not be
downgraded or converted into an expected failure merely to keep profile
validation green.

Success at one state does not imply success at a later state. In particular,
successful parsing does not imply semantic validity, successful lowering, code
generation, runtime support, or validated self-hosting.

Synthetic positive and negative fixtures remain necessary for local language,
diagnostic, resource, and failure-boundary coverage. Bootstrap-source checks
complement those fixtures by validating feature composition in real compiler
source; they do not replace them.

## Automated Enforcement

When profile validation is automated, it shall be deterministic and shall fail
when a member does not reach the support state required by the roadmap. It
shall not convert unsupported members into skips or expected-success
exceptions.

Membership shall have one authoritative representation. The test runner, build
scripts, and documentation shall not maintain independent membership copies
that can drift. Required support states remain authoritative in
`roadmaps/README.md`.

For the compiler bootstrap target, automated source membership is derived after a
successful production build from the main closure reported by the GPR project
tool for `adac.gpr`, intersected with Git-tracked `.ads` and `.adb` files. The
intersection excludes generated project sources while retaining specifications,
bodies, and subunits that are actual tracked compiler dependencies. The derived
paths are sorted and written only to the unique test work root for that run; the
derived manifest is not checked in and is not a second membership authority.

The Milestone 2 internal frontend profile gate is now in its all-members-parse
state. It walks the complete deterministic manifest in order, requires every
member to parse without diagnostics, and structurally validates every resulting
root. Any unsupported or regressed member is therefore a gate failure; there is no
longer an expected frontend frontier or an early-exit exception for later profile
members.
