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

Use `canon_apply_library()` for a STATIC, SHARED, MODULE, or INTERFACE library that should receive Canon's library policy:

```cmake
add_library(example SHARED example.cpp)
canon_apply_library(example)
```

Compiled libraries receive the common compiled-target policy and publish C++26 as a usage requirement. INTERFACE libraries publish the same C++26 usage requirement without compiled-target policy. Canon's current package-install integration still installs and exports managed libraries; package ownership is being simplified separately.

Export-header generation is explicit. Pass the library target, the include-relative header path, and the public export macro:

```cmake
canon_generate_export_header(example example/export.hpp EXAMPLE_API)
```

`canon_generate_export_header()` supports STATIC, SHARED, and MODULE libraries. It uses CMake's `GenerateExportHeader` module, writes the header below the target's `generated/` build directory, and publishes it through a public `HEADERS` file set named `canon_export_header`. The header path must be relative, and the macro must be an uppercase C identifier.

```cpp
#include <example/export.hpp>

EXAMPLE_API auto exampleAnswer() -> int;
```

The export-header path and macro are deliberately not inferred from `PROJECT_NAME`, the target name, or `EXPORT_NAME`. Public source layout and preprocessor identity belong to the project, and spelling them explicitly keeps Canon from maintaining a second naming policy.

## Package installation

The first managed library registers an installable CMake package for the current project. Architecture-independent packages install their CMake metadata beneath `${CMAKE_INSTALL_DATADIR}/cmake/${PROJECT_NAME}`. A package containing an installed compiled library or executable is architecture-specific and installs its metadata beneath `${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME}`. Imported targets use the `${PROJECT_NAME}::` namespace. `canon_apply_library()` creates the matching namespaced alias in the build tree. If a project sets CMake's native `EXPORT_NAME` target property, Canon uses that public name for the alias too. Project code and installed consumers can therefore use the same public target name.

`EXPORT_NAME` is an input to the current `canon_apply_library()` package integration and must be finalized before the call. Canon derives the build-tree alias when it applies the library policy. Changing `EXPORT_NAME` afterward is unsupported and can make the build-tree and installed identities disagree even when CMake accepts the change. Export-header identity is independent and comes only from `canon_generate_export_header()`.

A versioned project receives `<Project>Config.cmake`, `<Project>ConfigVersion.cmake`, and `<Project>Targets.cmake`. Before 1.0, compatible package versions must share the same minor version. Starting with 1.0, compatible versions must share the same major version. Header-only packages are architecture-independent. Package architecture only becomes more specific as managed targets are applied, so a later compiled library or executable moves the final package metadata to the architecture-specific location. Versionless projects omit `ConfigVersion.cmake`.

Executables installed with `canon_apply_executable()` are not exported as package targets and do not create a package configuration by themselves.

Each `canon_apply_*()` function is idempotent for a target. Reapplying the same function does not duplicate build policy or install rules. Applying `canon_apply_target()` first and later applying the matching executable or library function adds the higher-level policy without reapplying the compiled-target policy.

Use `canon_resolve_dependency()` when a project needs the same vendored-or-installed dependency lookup in its current build:

```cmake
canon_resolve_dependency(
    sdl
    PACKAGE SDL3
    VERSION "3.0...<4.0"
    TARGETS SDL3::SDL3
)
```

Canon first reuses the dependency when every required target already exists. Otherwise, if `${PROJECT_SOURCE_DIR}/external/sdl/CMakeLists.txt` exists, Canon adds that project beneath `${PROJECT_BINARY_DIR}/external/sdl` with `EXCLUDE_FROM_ALL`. If the vendored project is absent, Canon searches for the requested package and version in Config mode. The call fails if only some required targets already exist or if the selected provider does not supply every target. `TARGETS` may list more than one required target. Canon does not download dependencies.

The first successful resolution for a dependency name selects its provider for that project. Later calls with the same dependency name reuse that provider and require their requested targets to already be available; they do not fall through to another provider. The first argument names the directory beneath the project's `external/` tree. `PACKAGE` defaults to that name when the package name matches it. `VERSION` and `TARGETS` are required. `VERSION` constrains only the installed-package search performed during the first resolution when the required targets are absent and no vendored project is available. Existing targets are authoritative, and Canon does not infer or validate their version. A later call with a different `VERSION` therefore does not renegotiate an already-resolved dependency. Vendored dependency versions are likewise controlled by the selected source checkout rather than by `VERSION`.

This function only makes the dependency available to the current build. Installing selected runtime artifacts from a vendored dependency and recording dependencies of the installed CMake package are separate operations.

Use `canon_install_dependency()` when selected shared libraries from a vendored dependency belong in this project's installation:

```cmake
canon_install_dependency(
    sdl
    TARGETS SDL3::SDL3
)
```

The first argument names a dependency previously passed to `canon_resolve_dependency()` or otherwise resolved by Canon. If that dependency was provided by its vendored source tree, Canon installs the listed source-built shared-library targets using the normal runtime and library destinations. Canon adds an explicit parent build dependency for each selected target so its artifact exists when the project is installed; the target and the rest of the vendored subtree remain excluded from the vendor's own default build. If an already-provided or installed package won instead, the call adds no install rules. This keeps installed packages external while allowing vendored runtime artifacts to accompany the project that built them.

`TARGETS` is explicit because CMake 3.31 does not expose a portable target-graph operation that identifies the transitive shared-library runtime closure on every target platform. List every vendored shared-library target that the installation requires, including private runtime support libraries. Canon accepts aliases to targets created by the winning vendored project. Imported targets, frameworks, and target kinds other than `SHARED_LIBRARY` are rejected rather than staged heuristically. The vendored project's own install rules remain excluded.

GoogleTest has a dedicated policy because it is shared by essentially every C++ project in the Canon ecosystem:

```cmake
canon_require_googletest()
```

The call requires both `GTest::gmock_main` and `GTest::gtest_main`. If those targets already exist, Canon reuses them. Otherwise a source checkout of Canon uses its pinned `external/googletest` submodule when populated. Populate only that submodule with:

```sh
git submodule update --init external/googletest
```

If Canon's vendored GoogleTest source is unavailable, including when Canon is consumed as an installed package, Canon searches for an installed GTest package in the range `1.18.0...<2.0.0`. Canon does not install GoogleTest with itself and does not search for or add GoogleTest merely because Canon was loaded. Projects that never call `canon_require_googletest()` pay no GoogleTest configuration or build cost.

Use `canon_package_dependency()` when an installed package must recover another package before importing its targets:

```cmake
find_package(fmt 11 CONFIG REQUIRED)
canon_package_dependency(fmt 11 CONFIG)

target_link_libraries(example PUBLIC fmt::fmt)
```

`canon_package_dependency()` does not locate, vendor, or link the dependency. In this example, Canon records a call equivalent to `find_dependency(fmt 11 CONFIG)` in the installed package configuration. Use it also when a dependency comes from the source tree during the build but downstream consumers must find that dependency as a package. Do not pass `REQUIRED` or `QUIET`; `find_dependency()` inherits those requirements from the outer `find_package()` call.

Dependency arguments use normal CMake evaluation. Canon captures the values produced at the `canon_package_dependency()` call site and serializes those values safely into the generated package configuration. The generated package then forwards those values through CMake's `find_dependency()` macro. Values containing CMake variable, escape, or list syntax may therefore be interpreted again when the installed package is loaded. Normal `find_dependency()` and `find_package()` parsing, expansion, and list semantics apply; do not rely on the generated source preserving the original spelling or argument boundaries from the call site.

## Developer controls

Canon's shared development presets are the normal entry points for developer policy. Every shared development preset enables strict warnings. Presets with the `asan`, `tidy`, and `coverage` intents also enable their matching features. Projects that do not use Canon's presets, or that need a different combination, may set the same options directly or from their own presets:

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

AddressSanitizer instrumentation is controlled by `CANON_ENABLE_ASAN`. It is off by default. Canon's shared `gcc-asan` and `clang-asan` development presets enable it in dedicated Debug build trees.

When enabled, Canon adds AddressSanitizer compile instrumentation to managed targets and preserves frame pointers for useful diagnostics. Compile instrumentation remains private to each managed target. Static and object libraries publish the sanitizer runtime link requirement to consumers, while shared libraries both use and publish it. This allows an unmanaged executable to consume an instrumented library without instrumenting the executable's own translation units.

MODULE libraries cannot propagate an AddressSanitizer runtime requirement to the process that loads them dynamically. The host process must arrange for the sanitizer runtime separately.

Canon does not set `ASAN_OPTIONS` or otherwise control the sanitizer runtime. Projects and users keep ownership of runtime settings for their environment and tests.

## Coverage

Coverage instrumentation is controlled by `CANON_ENABLE_COVERAGE`. It is off by default. When enabled, Canon adds gcov-compatible compile instrumentation to managed targets. GCC also receives `-fprofile-abs-path` so profile data records stable source paths. Compile instrumentation remains private. Static and object libraries publish the coverage runtime link requirement to consumers, while targets with their own link step satisfy that requirement directly.

Canon adds build-wide coverage helpers when the first managed target receives coverage, even when that target belongs to a nested project. `coverage-clean` removes stale `.gcda` files from the build tree. Canon asks the active compiler driver for its coverage companion. It checks the reported tool's compiler family and major version before adding `coverage-report`. GCC uses the compiler-reported `gcov`; Clang uses the compiler-reported `llvm-cov gcov`.

When coverage is enabled, a usable compiler-matched reporting backend is required. If automatic discovery fails validation, configuration fails with a diagnostic naming the applicable override. Canon does not search for alternate tool names. `CANON_GCOV_EXECUTABLE` and `CANON_LLVM_COV_EXECUTABLE` are explicit overrides for unusual installations. Automatic discovery never populates them, and an invalid override is a configuration error.

`coverage-report` runs gcovr from the project source root and writes detailed HTML beneath `coverage/`. It excludes the active project's `external/` directory and `*_test.cpp`, prints a summary, and removes generated `.gcda` data after reporting. The report fails if filtering leaves no project source files.

Canon's shared coverage workflows use dedicated Debug build trees and sequence configure, cleanup, build, CTest, and report generation. Select the native compiler profile in the preset name, for example:

```text
cmake --workflow --preset gcc-coverage
cmake --workflow --preset clang-coverage
```

The shared workflow is not required. A project may enable coverage in another build tree and invoke the helper targets around its own build and test steps.

## clang-tidy

Running clang-tidy is enabled by `CANON_ENABLE_TIDY`. It is off by default. Canon's shared `gcc-tidy` and `clang-tidy` development presets turn it on.

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

When `DOXYGEN_USE_MDFILE_AS_MAINPAGE` is not set, Canon uses the project `README.md` as the default main page if that file exists. Documentation input excludes the active project binary tree when it is strictly below a requested input directory, plus `external/`, `standards/`, `test/`, and files matching `*_test.cpp`. If a requested input is the active binary directory itself, Canon fails during configuration because it cannot exclude an in-source build tree without also excluding the requested documentation input. In-source builds may use narrower documentation inputs such as `include/` and `src/`. Canon does not assume that a source-side `build/` directory or any other local build-tree name is generated output. Projects that document a broad source root may add other build directories to `DOXYGEN_EXCLUDE`; Canon preserves those entries when it appends its own exclusions. Canon excludes symbols named `detail` so top-level and nested implementation-detail namespaces are omitted. Doxygen's `EXCLUDE_SYMBOLS` cannot distinguish symbol kinds, so public non-namespace symbols named `detail` are also excluded. The naming rules in `standards/` avoid that collision. Graphviz support is used when CMake's Doxygen finder discovers `dot`; it is not required.

Canon does not generate documentation during ordinary builds or installation. Generated HTML is registered as the `Documentation` install component and remains excluded from a normal installation. Build `doc` first, then install the component explicitly:

```text
cmake --build build --target doc
cmake --install build --component Documentation
```

Requesting the `Documentation` component before the generated HTML exists fails instead of omitting it. Canon installs the HTML through CMake's `DOC` install type, so `CMAKE_INSTALL_DOCDIR` controls its destination.

## Shared presets

Canon ships `cmake/CanonPresets.json` for projects that want to share its ordinary native development configurations. A project can include the fragment from its checked-in `CMakePresets.json`:

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

The shared fragment combines a native compiler profile with a build intent. GCC profiles use `gcc` and `g++`; Clang profiles use `clang` and `clang++`. These executable names are resolved through the normal process `PATH`.

| Compiler profile | Build intents |
| --- | --- |
| `gcc` | `debug`, `release`, `asan`, `tidy`, `coverage` |
| `clang` | `debug`, `release`, `asan`, `tidy`, `coverage` |

Preset names use `<compiler>-<intent>`, such as `gcc-debug`, `clang-release`, or `clang-asan`. The same logical name is available as a configure, build, test, and workflow preset, so ordinary use does not require learning separate names for each preset kind:

```text
cmake --workflow --preset gcc-debug
cmake --workflow --preset clang-asan
```

All shared development configurations enable Canon's strict warnings. The specialized intents use Debug: `asan` enables AddressSanitizer, `tidy` enables clang-tidy, and `coverage` enables gcov-compatible instrumentation. Debug, Release, ASan, and tidy workflows perform configure, build, and CTest in sequence. Coverage workflows add cleanup before the build and report generation after CTest while keeping those stages as separate native preset steps.

The compiler profiles deliberately name ordinary compiler executables rather than machine-specific paths. Selecting another native installation is therefore a machine environment concern, normally handled by `PATH`. Canon also exposes hidden `canon-base` and `canon-<intent>` configure presets as composition points. Projects that need a fundamentally different toolchain or execution environment can inherit those fragments instead of duplicating Canon's build-intent policy.

The shared build-tree layout is a development convenience, not a requirement imposed by Canon. Projects may configure Canon-managed targets manually or use their own preset layout.

## Development

Canon follows the repository standards in `standards/`. Its root `CMakePresets.json` is for Canon's own integration suite rather than for consuming projects. Configure, build, and run that suite with:

```text
cmake --workflow --preset debug
```
