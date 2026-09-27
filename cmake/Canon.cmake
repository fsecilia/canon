# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

option(CANON_ENABLE_WARNINGS "Enable Canon's strict compiler warnings." OFF)
option(CANON_ENABLE_TIDY "Run clang-tidy as part of compiling Canon-managed targets." OFF)
option(CANON_ENABLE_DOCUMENTATION "Enable the project documentation target." OFF)

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
            -Wdouble-promotion
            -Wfloat-conversion
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

# Adds Canon's compiled-target policy and a generated public export header to a library.
function(canon_apply_library TARGET)
    if (NOT TARGET "${TARGET}")
        message(FATAL_ERROR "canon_apply_library(): target '${TARGET}' does not exist")
    endif()

    get_target_property(_type "${TARGET}" TYPE)
    if (NOT _type STREQUAL "STATIC_LIBRARY"
        AND NOT _type STREQUAL "SHARED_LIBRARY"
        AND NOT _type STREQUAL "MODULE_LIBRARY")
        message(FATAL_ERROR
            "canon_apply_library(): target '${TARGET}' must be a STATIC, SHARED, or MODULE library")
    endif()

    canon_apply_target("${TARGET}")

    string(MAKE_C_IDENTIFIER "${TARGET}" _api_name)
    string(TOLOWER "${_api_name}" _api_name)

    include(GenerateExportHeader)
    get_target_property(_target_binary_dir "${TARGET}" BINARY_DIR)
    set(_include_dir "${_target_binary_dir}/canon/include")
    set(_header "${_include_dir}/${TARGET}/export.hpp")
    file(MAKE_DIRECTORY "${_include_dir}/${TARGET}")

    generate_export_header(
        "${TARGET}"
        EXPORT_FILE_NAME "${_header}"
        EXPORT_MACRO_NAME "${_api_name}_api"
    )
    target_sources(
        "${TARGET}"
        PUBLIC
            FILE_SET canon_export_header
            TYPE HEADERS
            BASE_DIRS "${_include_dir}"
            FILES "${_header}"
    )
endfunction()

# Adds a conventional Doxygen target using CMake's native FindDoxygen integration.
function(canon_add_documentation)
    find_package(Doxygen 1.9 REQUIRED OPTIONAL_COMPONENTS dot)

    set(_readme "${PROJECT_SOURCE_DIR}/README.md")
    if (EXISTS "${_readme}")
        set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "${_readme}")
    endif()

    set(DOXYGEN_OUTPUT_DIRECTORY "${PROJECT_BINARY_DIR}/doxygen")
    set(DOXYGEN_EXCLUDE
        "${PROJECT_BINARY_DIR}"
        "${PROJECT_SOURCE_DIR}/build"
        "${PROJECT_SOURCE_DIR}/external"
        "${PROJECT_SOURCE_DIR}/standards"
        "${PROJECT_SOURCE_DIR}/test"
    )
    set(DOXYGEN_EXCLUDE_PATTERNS "*_test.cpp")
    set(DOXYGEN_STRIP_FROM_PATH "${PROJECT_SOURCE_DIR}")
    set(DOXYGEN_QUIET YES)
    set(DOXYGEN_WARN_AS_ERROR FAIL_ON_WARNINGS)
    set(DOXYGEN_WARN_LOGFILE "${PROJECT_BINARY_DIR}/doxygen-warnings.log")
    set(DOXYGEN_JAVADOC_AUTOBRIEF YES)
    set(DOXYGEN_QT_AUTOBRIEF YES)
    set(DOXYGEN_ENABLE_PREPROCESSING YES)
    set(DOXYGEN_EXTRACT_ALL NO)
    set(DOXYGEN_EXCLUDE_SYMBOLS "*::detail*")

    doxygen_add_docs(
        doc
        "${PROJECT_SOURCE_DIR}"
        WORKING_DIRECTORY "${PROJECT_SOURCE_DIR}"
        COMMENT "Generating API documentation"
    )

    add_custom_target(
        doc-clean
        COMMAND "${CMAKE_COMMAND}" -E rm -rf "${DOXYGEN_OUTPUT_DIRECTORY}"
        COMMAND "${CMAKE_COMMAND}" -E rm -f "${DOXYGEN_WARN_LOGFILE}"
        COMMENT "Cleaning generated API documentation"
        VERBATIM
    )
endfunction()
