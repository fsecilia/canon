## Canon

Canon is an opinionated CMake policy layer for C++ projects. It adds shared project policy where that saves real repetition.

## Using Canon

Keep Canon in the project tree, normally as `external/canon`.

If more than one project in the source tree may load Canon, guard the include so it is loaded only once:

```cmake
if (NOT COMMAND canon_apply_target)
    include(external/canon/cmake/Canon.cmake)
endif()
```

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
