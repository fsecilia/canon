# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include_guard(GLOBAL)

option(CANON_ENABLE_ASAN "Enable AddressSanitizer on Canon-managed targets." OFF)
option(CANON_ENABLE_COVERAGE "Enable coverage instrumentation on Canon-managed targets." OFF)
option(CANON_ENABLE_TIDY "Run clang-tidy as part of compiling Canon-managed targets." OFF)
option(CANON_ENABLE_WARNINGS "Enable Canon's strict compiler warnings." OFF)

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
    elseif (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        set(_build_options
            -fcolor-diagnostics
            -fstrict-aliasing
            -fsized-deallocation
        )
    else()
        message(FATAL_ERROR
            "Canon does not provide compiler policy for '${CMAKE_CXX_COMPILER_ID}'")
    endif()

    foreach(_option IN LISTS _build_options)
        _canon_apply_cxx_option("${TARGET}" "${_option}")
    endforeach()
endfunction()

# Enables Release IPO when the active C++ toolchain supports it.
function(_canon_apply_ipo_if_supported TARGET)
    get_property(_ipo_supported GLOBAL PROPERTY _CANON_IPO_SUPPORTED)
    if ("${_ipo_supported}" STREQUAL "")
        include(CheckIPOSupported)
        check_ipo_supported(
            RESULT _ipo_supported
            OUTPUT _ipo_output
            LANGUAGES CXX
        )
        set_property(GLOBAL PROPERTY _CANON_IPO_SUPPORTED "${_ipo_supported}")

        if (NOT _ipo_supported)
            message(STATUS "Canon: IPO is unavailable; Release builds will continue without it")
            message(VERBOSE "Canon IPO probe failed:\n${_ipo_output}")
        endif()
    endif()

    if (_ipo_supported)
        set_property(
            TARGET "${TARGET}"
            PROPERTY INTERPROCEDURAL_OPTIMIZATION_RELEASE TRUE
        )
    endif()
endfunction()

# Applies Canon's strict compiler-specific warning policy.
function(_canon_apply_warnings TARGET)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
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
            "Canon does not provide warning policy for '${CMAKE_CXX_COMPILER_ID}'")
    endif()

    foreach(_option IN LISTS _warning_options _warning_suppressions)
        _canon_apply_cxx_option("${TARGET}" "${_option}")
    endforeach()
endfunction()

# Adds AddressSanitizer instrumentation to managed C++ compilation and linking.
function(_canon_apply_asan TARGET)
    _canon_apply_cxx_option("${TARGET}" "-fsanitize=address")
    _canon_apply_cxx_option("${TARGET}" "-fno-omit-frame-pointer")
    target_link_options("${TARGET}" PRIVATE -fsanitize=address)
endfunction()

# Selects the compiler-matched gcov backend used by gcovr.
function(_canon_find_coverage_backend OUT_COMMAND)
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        if (NOT CANON_GCOV_EXECUTABLE)
            execute_process(
                COMMAND "${CMAKE_CXX_COMPILER}" -print-prog-name=gcov
                OUTPUT_VARIABLE _gcov_candidate
                OUTPUT_STRIP_TRAILING_WHITESPACE
                COMMAND_ERROR_IS_FATAL ANY
            )
            if (IS_ABSOLUTE "${_gcov_candidate}" AND EXISTS "${_gcov_candidate}")
                set(
                    CANON_GCOV_EXECUTABLE
                    "${_gcov_candidate}"
                    CACHE FILEPATH "gcov executable used by Canon coverage"
                )
            else()
                find_program(
                    CANON_GCOV_EXECUTABLE
                    NAMES "${_gcov_candidate}" gcov
                    REQUIRED
                    DOC "gcov executable used by Canon coverage"
                )
            endif()
        endif()
        set(${OUT_COMMAND} "${CANON_GCOV_EXECUTABLE}" PARENT_SCOPE)
        return()
    endif()

    if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        get_filename_component(_compiler_dir "${CMAKE_CXX_COMPILER}" DIRECTORY)
        find_program(
            CANON_LLVM_COV_EXECUTABLE
            NAMES llvm-cov
            HINTS "${_compiler_dir}"
            REQUIRED
            DOC "llvm-cov executable used by Canon coverage"
        )
        set(${OUT_COMMAND} "${CANON_LLVM_COV_EXECUTABLE} gcov" PARENT_SCOPE)
        return()
    endif()

    message(FATAL_ERROR
        "Canon coverage does not support compiler '${CMAKE_CXX_COMPILER_ID}'")
endfunction()

# Creates cleanup and report targets for the top-level project that owns the coverage build.
function(_canon_add_coverage_targets)
    find_program(
        CANON_GCOVR_EXECUTABLE
        NAMES gcovr
        REQUIRED
        DOC "gcovr executable used by Canon coverage"
    )
    _canon_find_coverage_backend(_gcov_command)

    add_custom_target(
        coverage-clean
        COMMAND
            "${CMAKE_COMMAND}"
            "-DCANON_COVERAGE_BINARY_DIR=${CMAKE_BINARY_DIR}"
            -P "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/CanonCoverageClean.cmake"
        COMMENT "Cleaning coverage data"
        VERBATIM
    )

    set(_output_dir "${CMAKE_BINARY_DIR}/coverage")
    add_custom_target(
        coverage-report
        COMMAND "${CMAKE_COMMAND}" -E make_directory "${_output_dir}"
        COMMAND
            "${CANON_GCOVR_EXECUTABLE}"
            --root "${CMAKE_SOURCE_DIR}"
            "${CMAKE_BINARY_DIR}"
            --gcov-executable "${_gcov_command}"
            --exclude ".*_test\\.cpp$"
            --exclude ".*/external/.*"
            --html-details "${_output_dir}/index.html"
            --delete
            --print-summary
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
        COMMENT "Generating coverage report"
        USES_TERMINAL
        VERBATIM
    )
endfunction()

# Adds gcov-compatible instrumentation and top-level reporting helpers.
function(_canon_apply_coverage TARGET)
    _canon_apply_cxx_option("${TARGET}" "--coverage")
    if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        _canon_apply_cxx_option("${TARGET}" "-fprofile-abs-path")
    endif()
    target_link_options("${TARGET}" PRIVATE --coverage)

    if (PROJECT_IS_TOP_LEVEL)
        get_property(_targets_added GLOBAL PROPERTY _CANON_COVERAGE_TARGETS_ADDED)
        if (NOT _targets_added)
            _canon_add_coverage_targets()
            set_property(GLOBAL PROPERTY _CANON_COVERAGE_TARGETS_ADDED TRUE)
        endif()
    endif()
endfunction()

# Lets CMake drive clang-tidy with the real compile command for each source file.
function(_canon_apply_tidy TARGET)
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
        POSITION_INDEPENDENT_CODE TRUE
        VISIBILITY_INLINES_HIDDEN TRUE
        CXX_VISIBILITY_PRESET hidden
    )

    _canon_apply_compiler_policy("${TARGET}")
    _canon_apply_ipo_if_supported("${TARGET}")
    if (CANON_ENABLE_WARNINGS)
        _canon_apply_warnings("${TARGET}")
    endif()
    if (CANON_ENABLE_ASAN)
        _canon_apply_asan("${TARGET}")
    endif()
    if (CANON_ENABLE_COVERAGE)
        _canon_apply_coverage("${TARGET}")
    endif()
    if (CANON_ENABLE_TIDY)
        _canon_apply_tidy("${TARGET}")
    endif()
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

# Adds conventional documentation targets using CMake's native FindDoxygen integration.
function(canon_add_documentation)
    find_package(Doxygen 1.9 QUIET OPTIONAL_COMPONENTS dot)

    set(_output_directory "${PROJECT_BINARY_DIR}/doxygen")
    set(_warning_log "${PROJECT_BINARY_DIR}/doxygen-warnings.log")

    add_custom_target(
        doc-clean
        COMMAND "${CMAKE_COMMAND}" -E rm -rf "${_output_directory}"
        COMMAND "${CMAKE_COMMAND}" -E rm -f "${_warning_log}"
        COMMENT "Cleaning generated API documentation"
        VERBATIM
    )

    if (NOT Doxygen_FOUND)
        add_custom_target(
            doc
            COMMAND
                "${CMAKE_COMMAND}" -E echo
                "Doxygen 1.9 or newer was not found when this build tree was configured."
            COMMAND
                "${CMAKE_COMMAND}" -E echo
                "Install Doxygen 1.9 or newer and reconfigure before building the doc target."
            COMMAND "${CMAKE_COMMAND}" -E false
            COMMENT "Unable to generate API documentation"
            VERBATIM
        )
        return()
    endif()

    set(_readme "${PROJECT_SOURCE_DIR}/README.md")
    if (EXISTS "${_readme}")
        set(DOXYGEN_USE_MDFILE_AS_MAINPAGE "${_readme}")
    endif()

    set(DOXYGEN_OUTPUT_DIRECTORY "${_output_directory}")
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
    set(DOXYGEN_WARN_LOGFILE "${_warning_log}")
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
endfunction()
