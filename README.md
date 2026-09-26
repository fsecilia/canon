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

## Development

Canon follows the repository standards in `standards/`. Configure, build, and run the current integration suite with:

```text
cmake --workflow --preset debug
```
