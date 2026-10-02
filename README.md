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

Adjust the vendored path to match the project layout.

Canon's installed Config package uses the same compatibility policy as other Canon-managed packages: versions before 1.0 are compatible within the same minor version, while versions starting at 1.0 are compatible within the same major version.

## Tool versions

Canon requires CMake 3.31.6 or newer. Its test matrix uses GNU GCC 14 and LLVM Clang 19 through Clang's GNU-compatible frontend.

Canon does not reject other compilers by version or identity. They must support C++26. Vendor Clang builds may carry warning groups from newer LLVM releases, so Canon probes the small set of warning suppressions known to vary across supported Clang distributions. Developer features that require compiler-specific support fail with a clear diagnostic when Canon has no implementation for the active compiler or frontend.

## Compiled targets

`canon_apply_target()` supports executables, object libraries, and STATIC, SHARED, and MODULE libraries. Use it for compiled targets that need Canon's build policy without Canon-managed installation:

```cmake
add_executable(example main.cpp)
canon_apply_target(example)
```

For each managed target, Canon currently:

* requires C++26;
* disables C++ module dependency scanning;
* enables position-independent code;
* hides symbols by default;
* enables interprocedural optimization for Release executables, shared libraries, and module libraries when supported; and
* applies compiler-specific build options when Canon has policy for the toolchain.

Canon intentionally leaves Release static and object libraries without IPO. Those artifacts remain ordinary object code that can be consumed across compatible compiler toolchains, at the cost of excluding their compiled object code from later whole-program IPO. Header-defined code compiled directly into an IPO-enabled final target remains eligible for that target's optimization.

Canon requires the C++26 language level but does not set `CXX_EXTENSIONS`. The caller owns whether the compiler uses GNU-style extensions or a strict ISO dialect.

Use `canon_apply_executable()` for a normal executable that should also be installed:

```cmake
add_executable(example main.cpp)
canon_apply_executable(example)
```

`canon_apply_executable()` applies the compiled-target policy and installs the executable through CMake's conventional runtime install directory. `MACOSX_BUNDLE` executables are not supported.

## Libraries and export headers

Use `canon_apply_library()` for a STATIC, SHARED, MODULE, or INTERFACE library that should be installed and exported as part of the project's CMake package:

```cmake
add_library(example SHARED example.cpp)
target_sources(
    example
    PUBLIC
        FILE_SET public_headers
        TYPE HEADERS
        BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/src"
        FILES src/example/example.hpp
)
canon_apply_library(example)
```

Declare the library's public `HEADERS` file sets before calling `canon_apply_library()`. Canon discovers their names, installs them beneath CMake's conventional include directory, and preserves each file's path relative to its file-set base directory.

Compiled libraries receive the common compiled-target policy and publish C++26 as a usage requirement. Canon also uses CMake's `GenerateExportHeader` module to publish an export header through a public `HEADERS` file set named `canon_export_header`. Generated headers live below `generated/` in the build tree and install below the matching public include path.

The header path and `_API` macro follow the package's public target identity. Canon derives each identity component mechanically from common PascalCase boundaries. It lowercases the result for header paths and uppercases it for preprocessor macros. If the public library name matches the project name, Canon uses the shorter primary-library form. For example, `Example::Example` uses `example/export.hpp` and `EXAMPLE_API`. A secondary target such as `Example::Core` uses `example/core/export.hpp` and `EXAMPLE_CORE_API`.

The mechanical rule is deterministic, not semantic, so unusual acronym spelling may need an override. Set the `CANON_EXPORT_IDENTITY` target property before `canon_apply_library()` to replace the derived public-library identity used by both the header path and generated macro family. The value is an uppercase C identifier. For example, `IPv6Address` derives `I_PV6_ADDRESS`, which produces `i_pv6_address/export.hpp` and `I_PV6_ADDRESS_API`. Set `CANON_EXPORT_IDENTITY` to `IPV6_ADDRESS` to use `ipv6_address/export.hpp` and `IPV6_ADDRESS_API` instead.

```cpp
#include <example/export.hpp>

EXAMPLE_API auto exampleAnswer() -> int;
```

INTERFACE libraries publish the same C++26 usage requirement but have no compiled-target policy or generated export header. Canon installs and exports them together with their public header file sets. `FRAMEWORK` libraries are not supported.

## Package installation

The first managed library registers an installable CMake package for the current project. Architecture-independent packages install their CMake metadata beneath `share/cmake/${PROJECT_NAME}`. A package containing an installed compiled library or executable is architecture-specific and installs its metadata beneath `${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}`. Imported targets use the `${PROJECT_NAME}::` namespace. `canon_apply_library()` creates the matching namespaced alias in the build tree. If a project sets CMake's native `EXPORT_NAME` target property, Canon uses that public name for the alias too. Project code and installed consumers can therefore use the same public target name.

A versioned project receives `<Project>Config.cmake`, `<Project>ConfigVersion.cmake`, and `<Project>Targets.cmake`. Before 1.0, compatible package versions must share the same minor version. Starting with 1.0, compatible versions must share the same major version. Header-only packages are architecture-independent. Package architecture only becomes more specific as managed targets are applied, so a later compiled library or executable moves the final package metadata to the architecture-specific location. Versionless projects omit `ConfigVersion.cmake`.

Executables installed with `canon_apply_executable()` are not exported as package targets and do not create a package configuration by themselves.

Use `canon_apply_dependency()` when an installed package must recover another package before importing its targets:

```cmake
find_package(fmt 11 CONFIG REQUIRED)
canon_apply_dependency(fmt 11 CONFIG)

target_link_libraries(example PUBLIC fmt::fmt)
```

`canon_apply_dependency()` does not locate, vendor, or link the dependency. In this example, Canon records `find_dependency(fmt 11 CONFIG)` in the installed package configuration. Use it also when a dependency comes from the source tree during the build but downstream consumers must find that dependency as a package. Do not pass `REQUIRED` or `QUIET`; `find_dependency()` inherits those requirements from the outer `find_package()` call.

## Developer controls

Canon's shared development presets are the normal entry points for developer policy. Every shared development preset enables strict warnings. The `asan`, `tidy`, and `coverage` presets also enable their matching features. Projects that do not use Canon's presets, or that need a different combination, may set the same options directly or from their own presets:

* `CANON_ENABLE_WARNINGS` enables Canon's strict compiler warning policy;
* `CANON_ENABLE_ASAN` enables AddressSanitizer instrumentation;
* `CANON_ENABLE_TIDY` enables clang-tidy during compilation; and
* `CANON_ENABLE_COVERAGE` enables coverage instrumentation and reporting support.

These controls are build-wide. When enabled, they apply to every Canon-managed target in the build, including Canon-managed targets from vendored subprojects. Canon does not isolate them per project.

## Warnings

Warnings are controlled by `CANON_ENABLE_WARNINGS`. It is off by default. Canon's shared development presets turn it on.

This keeps the distinction explicit. Family development builds use strict warnings. A project configured normally does not inherit warnings-as-errors merely because it uses Canon.

With warnings enabled, GCC uses Canon's warning set and treats warnings as errors. Clang's GNU-compatible frontend uses `-Weverything`, treats warnings as errors, and applies Canon's deliberate suppressions. Canon capability-probes the few suppressions whose availability differs between supported Clang distributions and omits only those unavailable groups. Other compilers may still use Canon, but this option fails if Canon has no warning policy for them.

## AddressSanitizer

AddressSanitizer instrumentation is controlled by `CANON_ENABLE_ASAN`. It is off by default. Canon's shared `asan` development preset enables it in a dedicated Debug build tree.

When enabled, Canon adds AddressSanitizer compile instrumentation to managed targets and preserves frame pointers for useful diagnostics. Compile instrumentation remains private to each managed target. Static and object libraries publish the sanitizer runtime link requirement to consumers, while shared libraries both use and publish it. This allows an unmanaged executable to consume an instrumented library without instrumenting the executable's own translation units.

MODULE libraries cannot propagate an AddressSanitizer runtime requirement to the process that loads them dynamically. The host process must arrange for the sanitizer runtime separately.

Canon does not set `ASAN_OPTIONS` or otherwise control the sanitizer runtime. Projects and users keep ownership of runtime settings for their environment and tests.

## Coverage

Coverage instrumentation is controlled by `CANON_ENABLE_COVERAGE`. It is off by default. When enabled, Canon adds gcov-compatible compile instrumentation to managed targets. GCC also receives `-fprofile-abs-path` so profile data records stable source paths. Compile instrumentation remains private. Static and object libraries publish the coverage runtime link requirement to consumers, while targets with their own link step satisfy that requirement directly.

Canon adds build-wide coverage helpers when the first managed target receives coverage, even when that target belongs to a nested project. `coverage-clean` removes stale `.gcda` files from the build tree. Canon asks the active compiler driver for its coverage companion. It checks the reported tool's compiler family and major version before adding `coverage-report`. GCC uses the compiler-reported `gcov`; Clang uses the compiler-reported `llvm-cov gcov`.

If automatic discovery fails validation, Canon warns and leaves coverage reporting disabled. It does not search for alternate tool names. `CANON_GCOV_EXECUTABLE` and `CANON_LLVM_COV_EXECUTABLE` are explicit overrides for unusual installations. Automatic discovery never populates them, and an invalid override is a configuration error.

`coverage-report` runs gcovr from the project source root and writes detailed HTML beneath `coverage/`. It excludes project `external/` directories and `*_test.cpp`, prints a summary, and removes generated `.gcda` data after reporting. The report fails if filtering leaves no project source files.

Canon's shared `coverage` workflow uses a dedicated Debug build tree and sequences configure, cleanup, build, CTest, and report generation. Run the complete workflow with:

```text
cmake --workflow --preset coverage
```

The shared workflow is not required. A project may enable coverage in another build tree and invoke the helper targets around its own build and test steps.

## clang-tidy

Running clang-tidy is enabled by `CANON_ENABLE_TIDY`. It is off by default. Canon's shared development presets turn it on.

Canon requires clang-tidy 21.1.6 or newer. When enabled, Canon locates clang-tidy, verifies its version, and attaches it to managed targets through CMake's native `CXX_CLANG_TIDY` target property. CMake then supplies the real compiler invocation for each translation unit.

The checked-in `.clang-tidy` file comes from `standards/`. Editors, CI, and direct tool invocations can use the same configuration without going through Canon.

## Documentation

Call `canon_add_documentation()` with the files or directories that belong to the project's Doxygen input. Relative paths are resolved from the project source directory:

```cmake
canon_add_documentation(
    include
    src
)
```

At least one input path is required. Explicit inputs keep nested project trees out of an outer project's documentation unless the caller deliberately includes them.

Each project receives `${PROJECT_NAME}-doc` and `${PROJECT_NAME}-doc-clean` targets for its own documentation. The top-level project also receives `doc` and `doc-clean` convenience targets. A nested project can generate and clean its documentation on its own. Its documentation is not added to the outer project's `Documentation` install component.

Canon looks for Doxygen 1.9 or newer during configuration. A missing Doxygen installation does not make configuration or ordinary builds fail. If Doxygen was not found, building the project's documentation target fails with a diagnostic that asks the user to install Doxygen and reconfigure. Its cleanup target remains available either way.

Canon uses CMake's native `FindDoxygen` module and `doxygen_add_docs()`. When Doxygen is available, generated HTML is written beneath `${PROJECT_BINARY_DIR}/doxygen/html`, and Doxygen warnings fail the project's documentation target. The warning log is kept at `${PROJECT_BINARY_DIR}/doxygen-warnings.log`. These output and warning settings are Canon invariants because the documentation targets and install contract depend on them. Canon also owns the documentation input and working directory.

Projects may customize Doxygen through the native `DOXYGEN_*` variables before calling `canon_add_documentation()`. The function arguments own `DOXYGEN_INPUT`. Canon adds its required input exclusions to caller-provided `DOXYGEN_EXCLUDE`, `DOXYGEN_EXCLUDE_PATTERNS`, and `DOXYGEN_EXCLUDE_SYMBOLS` values. Ordinary settings such as `DOXYGEN_QUIET`, `DOXYGEN_JAVADOC_AUTOBRIEF`, `DOXYGEN_QT_AUTOBRIEF`, `DOXYGEN_ENABLE_PREPROCESSING`, `DOXYGEN_EXTRACT_ALL`, and `DOXYGEN_STRIP_FROM_PATH` keep an explicit caller value. Other unrelated `DOXYGEN_*` settings pass through to CMake's Doxygen integration.

When `DOXYGEN_USE_MDFILE_AS_MAINPAGE` is not set, Canon uses the project `README.md` as the default main page if that file exists. Documentation input excludes the active project binary tree, the conventional source-side `build/` tree, `external/`, `standards/`, `test/`, and files matching `*_test.cpp`. Canon excludes symbols named `detail` so top-level and nested implementation-detail namespaces are omitted. Doxygen's `EXCLUDE_SYMBOLS` cannot distinguish symbol kinds, so public non-namespace symbols named `detail` are also excluded. The naming rules in `standards/` avoid that collision. Graphviz support is used when CMake's Doxygen finder discovers `dot`; it is not required.

Canon does not generate documentation during ordinary builds or installation. Generated HTML is registered as the `Documentation` install component and remains excluded from a normal installation. Build `doc` first, then install the component explicitly:

```text
cmake --build build --target doc
cmake --install build --component Documentation
```

Requesting the `Documentation` component before the generated HTML exists fails instead of omitting it. Canon installs the HTML through CMake's `DOC` install type, so `CMAKE_INSTALL_DOCDIR` controls its destination.

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

The shared fragment provides separate `debug`, `release`, `asan`, `tidy`, and `coverage` configure trees beneath `build/`. These development configurations enable Canon's strict warnings. The specialized configurations use Debug: `asan` enables AddressSanitizer, `tidy` enables clang-tidy, and `coverage` enables gcov-compatible instrumentation.

Debug, Release, ASan, and tidy workflows perform configure, build, and CTest in sequence. The coverage workflow adds cleanup before the build and report generation after CTest while keeping those stages as separate native preset steps.

Machine-specific compiler, toolchain, SDK, and local path choices belong in ignored `CMakeUserPresets.json` files. Local presets can inherit the checked-in shared presets normally.

The shared build-tree layout is a development convenience, not a requirement imposed by Canon. Projects may configure Canon-managed targets manually or use their own preset layout.

## Development

Canon follows the repository standards in `standards/`. Its root `CMakePresets.json` is for Canon's own integration suite rather than for consuming projects. Configure, build, and run that suite with:

```text
cmake --workflow --preset debug
```
