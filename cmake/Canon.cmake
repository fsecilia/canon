# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

option(CANON_ENABLE_WARNINGS "Enable Canon's strict compiler warnings." OFF)
option(CANON_ENABLE_TIDY "Run clang-tidy as part of compiling Canon-managed targets." OFF)

function(_canon_apply_cxx_option TARGET OPTION)
    target_compile_options("${TARGET}" PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:${OPTION}>")
endfunction()

# Applies the compiler-specific build policy shared by Canon-managed compiled targets.
function(_canon_apply_compiler_policy TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        set(_build_options
            -fdiagnostics-color=always
            -fstrict-aliasing
            -fsized-deallocation
            -ftemplate-backtrace-limit=1
        )
        set(_warning_options
            -Wall
            -Wextra
            -Wpedantic
            -Werror
            -Wstrict-aliasing=2
            -Wswitch
            -Wdouble-promotion
            -Wfloat-conversion
            -Wchanges-meaning
            -Wshadow
        )
        set(_warning_suppressions)
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        set(_build_options
            -fcolor-diagnostics
            -fstrict-aliasing
            -fsized-deallocation
        )
        set(_warning_options
            -Weverything
            -Werror
            -Wswitch
            -Wdouble-promotion
            -Wfloat-conversion
            -Wshadow-all
        )
        set(_warning_suppressions
            -Wno-c++98-compat
        )
    else()
        message(FATAL_ERROR
            "Canon does not provide compiler policy for '${CMAKE_CXX_COMPILER_ID}'")
    endif()

    foreach(_option IN LISTS _build_options)
        _canon_apply_cxx_option("${TARGET}" "${_option}")
    endforeach()

    if (CANON_ENABLE_WARNINGS)
        foreach(_option IN LISTS _warning_options _warning_suppressions)
            _canon_apply_cxx_option("${TARGET}" "${_option}")
        endforeach()
    endif()
endfunction()

# Lets CMake drive clang-tidy with the real compile command for each source file.
function(_canon_apply_tidy TARGET)
    if (NOT CANON_ENABLE_TIDY)
        return()
    endif()

    find_program(
        CANON_CLANG_TIDY_EXECUTABLE
        NAMES clang-tidy
        REQUIRED
        DOC "clang-tidy executable used by Canon"
    )
    set_property(TARGET "${TARGET}" PROPERTY CXX_CLANG_TIDY "${CANON_CLANG_TIDY_EXECUTABLE}")
endfunction()

# Applies Canon's private build policy to a target that compiles C++ sources.
function(canon_apply_target TARGET)
    if (NOT TARGET "${TARGET}")
        message(FATAL_ERROR "canon_apply_target(): target '${TARGET}' does not exist")
    endif()

    get_target_property(_type "${TARGET}" TYPE)
    if (NOT _type STREQUAL "EXECUTABLE"
        AND NOT _type STREQUAL "STATIC_LIBRARY"
        AND NOT _type STREQUAL "SHARED_LIBRARY"
        AND NOT _type STREQUAL "MODULE_LIBRARY"
        AND NOT _type STREQUAL "OBJECT_LIBRARY")
        message(FATAL_ERROR
            "canon_apply_target(): target '${TARGET}' has type '${_type}', which has no compiled-target Canon policy")
    endif()

    set_target_properties("${TARGET}" PROPERTIES
        CXX_SCAN_FOR_MODULES FALSE
        CXX_STANDARD 26
        CXX_STANDARD_REQUIRED TRUE
        INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE
        POSITION_INDEPENDENT_CODE TRUE
        VISIBILITY_INLINES_HIDDEN TRUE
        CXX_VISIBILITY_PRESET hidden
    )

    _canon_apply_compiler_policy("${TARGET}")
    _canon_apply_tidy("${TARGET}")
endfunction()
