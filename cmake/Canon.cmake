# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

# Applies the compiler-specific build policy shared by Canon-managed compiled targets.
function(_canon_apply_compiler_policy TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_compile_options("${TARGET}" PRIVATE
            $<$<COMPILE_LANGUAGE:CXX>:-fdiagnostics-color=always>
            $<$<COMPILE_LANGUAGE:CXX>:-fstrict-aliasing>
            $<$<COMPILE_LANGUAGE:CXX>:-fsized-deallocation>
            $<$<COMPILE_LANGUAGE:CXX>:-ftemplate-backtrace-limit=1>
        )
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        target_compile_options("${TARGET}" PRIVATE
            $<$<COMPILE_LANGUAGE:CXX>:-fcolor-diagnostics>
            $<$<COMPILE_LANGUAGE:CXX>:-fstrict-aliasing>
            $<$<COMPILE_LANGUAGE:CXX>:-fsized-deallocation>
        )
    else()
        message(FATAL_ERROR
            "Canon does not provide compiler policy for '${CMAKE_CXX_COMPILER_ID}'")
    endif()
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
endfunction()
