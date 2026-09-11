# adac

`adac` is an Ada compiler written in Ada. It currently compiles a bounded scalar
Ada 2022 procedure subset through a separated frontend, AST, semantic analysis,
custom IR, and native backend pipeline. Current native execution covers
procedure-local Integer/Boolean storage, exact static scalar evaluation, runtime
Boolean expression trees, and direct-local lazy Boolean short-circuit
assignments. The frontend parses the complete Adac bootstrap profile, but parsed
syntax is intentionally broader than the current semantic/runtime subset.

The native backend currently supports x86-64 FreeBSD and x86-64 Linux. Other
compiler targets may be cross-built with a matching GNAT toolchain, but program
emission remains disabled until the corresponding backend contract is
implemented.

## Build

The default build profile is `release`.

```text
$ rake info
$ rake build
$ rake build TARGET=x86_64-unknown-freebsd PROFILE=debug
```

Build products are isolated by target and profile under:

```text
build/obj/<target>/<profile>
build/bin/<target>/<profile>
build/generated/<target>/<profile>
```

`TARGET` selects the platform where the `adac` executable runs. The current
compiler is native-only, so its program target is the same platform.

## Checks

The compiler build itself does not require Clair. `rake test` and `rake check`
use the public [Clair](https://github.com/hodong-kim/clair) test support and expect
that repository to be checked out as the sibling directory `../clair`.

```text
$ rake test
$ rake check
```

Tasks that execute a built program require a target compatible with the build
host. `rake test` builds the sibling Clair dependency, then runs compiler fixtures
and internal contract tests through one Clair.Test runner. `rake check` adds
repository target and project-boundary checks. Source-style conventions remain
documented guidance rather than a build or test gate.

## Language Options

Ada identifiers are case-insensitive by default. The nonstandard
`--case-sensitive-identifiers` option requires exact case matching.

```text
$ adac main.adb -o main --case-sensitive-identifiers
```

## Documentation

- `docs/README.md`: documentation authority map
- `docs/architecture.md`: logical compiler stages and dependency direction
- `docs/roadmaps/README.md`: development roadmap and current work checkpoint
- `docs/target-support.md`: target terminology and support matrix
- `docs/repository-layout.md`: package and file placement
- `docs/test-orchestration.md`: test discovery and result ownership
- `docs/STYLE-GUIDE.md`: recommended source style and API documentation conventions

## License

`adac` is distributed under the 0BSD license. See `LICENSE`.
