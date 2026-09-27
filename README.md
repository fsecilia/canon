## Canon

Canon is an opinionated CMake policy layer for C++ projects. It adds shared project policy where that saves real repetition.

## Using Canon

A project may use Canon that was already loaded by a parent, vendor Canon in its source tree, or find an installed Canon package. Use the public command as the load sentinel, prefer the vendored copy when it exists, and otherwise use normal CMake package discovery:

```cmake
if (NOT COMMAND canon_apply_target)
    if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/canon/CMakeLists.txt")
        add_subdirectory(external/canon EXCLUDE_FROM_ALL)
    else()
        find_package(Canon 0.1 CONFIG REQUIRED)
    endif()
endif()
```

Adjust the vendored path to match the project layout. Canon's installed Config package uses normal CMake version matching within the same major version.

Apply Canon to an existing compiled target:

```cmake
add_executable(example main.cpp)
canon_apply_target(example)
```

## Compiled targets

`canon_apply_target()` supports executables, object libraries, and STATIC, SHARED, and MODULE libraries.

For each managed target, Canon currently:

* requires C++26;
* disables C++ module dependency scanning;
* enables position-independent code;
* hides symbols by default;
* enables interprocedural optimization for Release builds; and
* applies the supported compiler-specific build options.

## Libraries and export headers

Use `canon_apply_library()` when a STATIC, SHARED, or MODULE library needs Canon's generated public export header:

```cmake
add_library(example SHARED example.cpp)
canon_apply_library(example)
```

`canon_apply_library()` first calls `canon_apply_target()`, so the library receives the common compiled-target policy. It then uses CMake's `GenerateExportHeader` module to create `<target>/export.hpp`. Canon publishes that file through a public `HEADERS` file set named `canon_export_header`.

The primary export annotation uses the target name normalized as a lowercase C identifier plus `_api`. For a target named `example`, a public declaration can use the generated header like this:

```cpp
#include "example/export.hpp"

example_api auto exampleAnswer() -> int;
```

Canon does not install or export the library. Projects use normal CMake install, export, and package commands. They may install `canon_export_header` with the library's other file sets. INTERFACE libraries have no compiled-library policy; manage their headers and usage requirements with ordinary CMake.

## Warnings

Warnings are controlled by `CANON_ENABLE_WARNINGS`. It is off by default. Canon's shared development presets turn it on.

This keeps the distinction explicit. Family development builds use strict warnings. A project configured normally doesnot inherit warnings-as-errors merely because it uses Canon.

With warnings enabled, GCC uses the warning set maintained by Canon and treats warnings as errors. Clang uses `-Weverything`, treats warnings as errors, and suppresses only the intentional C++98 compatibility diagnostic.

## clang-tidy

Running clang-tidy is enabled by `CANON_ENABLE_TIDY`. It is off by default. Canon's shared development presets turn it on.

When enabled, Canon locates clang-tidy and attaches it to managed targets through CMake's native `CXX_CLANG_TIDY` target property. CMake then supplies the real compiler invocation for each translation unit.

The checked-in `.clang-tidy` file comes from `standards/`. Editors, CI, and direct tool invocations can use the same configuration without going through Canon.

## Shared presets

Canon ships `cmake/CanonPresets.json` for projects that want to share its ordinary development configurations. A project can include the fragment from its checked-in `CMakePresets.json`:

```json
{
  "version": 10,
  "cmakeMinimumRequired": {
    "major": 3,
    "minor": 31,
    "patch": 6
  },
  "include": [
    "external/canon/cmake/CanonPresets.json"
  ]
}
```

The shared fragment provides separate `debug`, `release`, and `tidy` configure trees beneath `build/`. All three development configurations enable Canon's strict warnings, while `tidy` also enables clang-tidy. Matching build and test presets use the same configured tree, and each workflow preset performs configure, build, and CTest in sequence.

Machine-specific compiler, toolchain, SDK, and local path choices belong in ignored `CMakeUserPresets.json` files. Local presets can inherit the checked-in shared presets normally.

The shared build-tree layout is a development convenience, not a requirement imposed by Canon. Projects may configure Canon-managed targets manually or use their own preset layout.

## Development

Canon follows the repository standards in `standards/`. Its root `CMakePresets.json` is for Canon's own integration suite rather than for consuming projects. Configure, build, and run that suite with:

```text
cmake --workflow --preset debug
```
