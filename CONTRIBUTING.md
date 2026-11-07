# Contributing

## Pull Requests

Pull requests should target dev. The main branch is updated periodically from dev with fast-forward-only merges and is not used as the normal pull-request target.

## Standards

This project follows the shared engineering standards in [`standards/`](standards/).

The applicable standards are:

- [`standards/repository.md`](standards/repository.md)
- [`standards/cmake/code.md`](standards/cmake/code.md)
- [`standards/cmake/testing.md`](standards/cmake/testing.md)
- [`standards/cpp/design.md`](standards/cpp/design.md)
- [`standards/cpp/structure.md`](standards/cpp/structure.md)
- [`standards/cpp/style.md`](standards/cpp/style.md)

Project-specific additions or exceptions are documented below.

### Integration tests

Every test is declared once in `test/CMakeLists.txt` with `_canon_add_test()`, next to its expectations and the optional tools it requires. Registration writes a spec file per test into the build tree, and the test runs that spec with `cmake -P`. To rerun one test by hand, run its spec from `test/specs/` in the build tree.

Prefer the cheapest form that expresses the contract:

- A configure-time behavior or diagnostic with one or two Canon calls is a `CASE`: inline CMake code that runs in `test/support/case`, or in a named `FIXTURE` such as `test/dependency` when it needs more files on disk.
- A fixture that only needs to configure, build, install, and match an install manifest uses the generic driver. Give it `BUILD`, `INSTALL`, or `INSTALL_TARGET` and record expected paths with `canon_fixture_expect_installed()`.
- A lifecycle that runs executables, crosses several configure trees, or inspects generated output gets its own driver script built on `test/support/CanonTest.cmake`.

Give every fixture source a name that no assertion pattern for a neighboring file could also match.
