# adac

`adac` is an Ada compiler written in Ada. It currently compiles a minimal Ada
2022 procedure subset through a separated frontend, AST, semantic analysis,
custom IR, and native backend pipeline.

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

```text
$ rake test
$ rake style
$ rake style-test
$ rake check
```

Tasks that execute a built program require a target compatible with the build
host. `rake check` runs target-model checks, compiler tests, internal contract
tests, source-style checks, and style-checker regression tests.

## Language Options

Ada identifiers are case-insensitive by default. The nonstandard
`--case-sensitive-identifiers` option requires exact case matching.

```text
$ adac main.adb -o main --case-sensitive-identifiers
```

## Documentation

- `docs/README.md`: documentation authority map
- `docs/roadmap.md`: development milestones and completion criteria
- `docs/target-support.md`: target terminology and support matrix
- `docs/repository-layout.md`: package and file placement
- `docs/STYLE-GUIDE.md`: Clair Coding Style

## License

`adac` is distributed under the 0BSD license. See `LICENSE`.
