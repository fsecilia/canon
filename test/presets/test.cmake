# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/support/CanonTest.cmake")

canon_test_require_variables(
    CANON_SOURCE_DIR
    CANON_TEST_BINARY_DIR
    CANON_CXX_COMPILER
    CANON_TEST_CASE
)

set(_test_cases debug release asan coverage tidy)
list(FIND _test_cases "${CANON_TEST_CASE}" _test_case_index)
if ("${_test_case_index}" EQUAL -1)
    message(FATAL_ERROR "unknown preset test case '${CANON_TEST_CASE}'")
endif()

if ("${CANON_TEST_CASE}" STREQUAL "coverage")
    canon_test_require_variables(CANON_GCOVR_EXECUTABLE)
elseif ("${CANON_TEST_CASE}" STREQUAL "tidy")
    canon_test_require_variables(CANON_CLANG_TIDY_EXECUTABLE)
endif()

# Recreate the consumer with Canon vendored at the same path used by the preset include.
file(REMOVE_RECURSE "${CANON_TEST_BINARY_DIR}")
set(_source_dir "${CANON_TEST_BINARY_DIR}/source")
file(COPY "${CANON_SOURCE_DIR}/test/presets/" DESTINATION "${_source_dir}")
file(MAKE_DIRECTORY "${_source_dir}/external/canon")
file(COPY "${CANON_SOURCE_DIR}/CMakeLists.txt" DESTINATION "${_source_dir}/external/canon")
file(COPY "${CANON_SOURCE_DIR}/cmake" DESTINATION "${_source_dir}/external/canon")
file(WRITE "${_source_dir}/CMakePresets.json"
    "{\n"
    "  \"version\": 10,\n"
    "  \"cmakeMinimumRequired\": {\"major\": 3, \"minor\": 31, \"patch\": 6},\n"
    "  \"include\": [\"external/canon/cmake/CanonPresets.json\"]\n"
    "}\n")

set(_environment_command "${CMAKE_COMMAND}" -E env "CXX=${CANON_CXX_COMPILER}")
if (DEFINED CANON_TOOLCHAIN_FILE AND NOT "${CANON_TOOLCHAIN_FILE}" STREQUAL "")
    list(APPEND _environment_command "CMAKE_TOOLCHAIN_FILE=${CANON_TOOLCHAIN_FILE}")
endif()

function(_run DESCRIPTION)
    canon_test_run(
        DESCRIPTION "${DESCRIPTION}"
        COMMAND
            "${CMAKE_COMMAND}"
            -E chdir
            "${_source_dir}"
            ${_environment_command}
            ${ARGN}
    )
endfunction()

function(_expect_cache_value PRESET VARIABLE TYPE EXPECTED_VALUE DESCRIPTION)
    set(_cache "${_source_dir}/build/${PRESET}/CMakeCache.txt")
    if (NOT EXISTS "${_cache}")
        message(FATAL_ERROR "${DESCRIPTION} did not create '${_cache}'")
    endif()

    file(STRINGS "${_cache}" _cache_line REGEX "^${VARIABLE}:${TYPE}=")
    if (NOT "${_cache_line}" STREQUAL "${VARIABLE}:${TYPE}=${EXPECTED_VALUE}")
        message(FATAL_ERROR
            "${DESCRIPTION} configured the wrong ${VARIABLE}: '${_cache_line}'")
    endif()
endfunction()

function(_run_workflow PRESET BUILD_TYPE)
    _run("${PRESET} workflow" "${CMAKE_COMMAND}" --workflow --preset "${PRESET}")
    _expect_cache_value(
        "${PRESET}"
        CMAKE_BUILD_TYPE
        STRING
        "${BUILD_TYPE}"
        "${PRESET} workflow"
    )
    _expect_cache_value(
        "${PRESET}"
        CANON_ENABLE_WARNINGS
        BOOL
        TRUE
        "${PRESET} workflow"
    )
endfunction()

if ("${CANON_TEST_CASE}" STREQUAL "debug")
    _run_workflow(debug Debug)
elseif ("${CANON_TEST_CASE}" STREQUAL "release")
    _run_workflow(release Release)
elseif ("${CANON_TEST_CASE}" STREQUAL "asan")
    _run_workflow(asan Debug)
    _expect_cache_value(
        asan
        CANON_ENABLE_ASAN
        BOOL
        TRUE
        "asan workflow"
    )
elseif ("${CANON_TEST_CASE}" STREQUAL "coverage")
    # Pass through reporting-tool overrides supplied to the outer project.
    set(_coverage_configure_command
        "${CMAKE_COMMAND}"
        --preset coverage
        "-DCANON_GCOVR_EXECUTABLE=${CANON_GCOVR_EXECUTABLE}"
    )
    if (DEFINED CANON_GCOV_EXECUTABLE AND NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL "")
        list(APPEND _coverage_configure_command
            "-DCANON_GCOV_EXECUTABLE=${CANON_GCOV_EXECUTABLE}")
    endif()
    if (DEFINED CANON_LLVM_COV_EXECUTABLE AND NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
        list(APPEND _coverage_configure_command
            "-DCANON_LLVM_COV_EXECUTABLE=${CANON_LLVM_COV_EXECUTABLE}")
    endif()
    _run("coverage configure" ${_coverage_configure_command})

    _run_workflow(coverage Debug)
    _expect_cache_value(
        coverage
        CANON_GCOVR_EXECUTABLE
        FILEPATH
        "${CANON_GCOVR_EXECUTABLE}"
        "coverage workflow"
    )
    _expect_cache_value(
        coverage
        CANON_ENABLE_COVERAGE
        BOOL
        TRUE
        "coverage workflow"
    )
    if (DEFINED CANON_GCOV_EXECUTABLE AND NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL "")
        _expect_cache_value(
            coverage
            CANON_GCOV_EXECUTABLE
            FILEPATH
            "${CANON_GCOV_EXECUTABLE}"
            "coverage workflow"
        )
    endif()
    if (DEFINED CANON_LLVM_COV_EXECUTABLE AND NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
        _expect_cache_value(
            coverage
            CANON_LLVM_COV_EXECUTABLE
            FILEPATH
            "${CANON_LLVM_COV_EXECUTABLE}"
            "coverage workflow"
        )
    endif()

    set(_index "${_source_dir}/build/coverage/coverage/index.html")
    if (NOT EXISTS "${_index}")
        message(FATAL_ERROR "coverage workflow did not generate '${_index}'")
    endif()
elseif ("${CANON_TEST_CASE}" STREQUAL "tidy")
    # Seed the tidy build tree with the exact executable validated by the outer project.
    _run(
        "tidy configure"
        "${CMAKE_COMMAND}"
        --preset tidy
        "-DCANON_CLANG_TIDY_EXECUTABLE=${CANON_CLANG_TIDY_EXECUTABLE}"
    )
    file(COPY "${CANON_SOURCE_DIR}/.clang-tidy" DESTINATION "${_source_dir}")

    _run_workflow(tidy Debug)
    _expect_cache_value(
        tidy
        CANON_CLANG_TIDY_EXECUTABLE
        FILEPATH
        "${CANON_CLANG_TIDY_EXECUTABLE}"
        "tidy workflow"
    )
    _expect_cache_value(
        tidy
        CANON_ENABLE_TIDY
        BOOL
        TRUE
        "tidy workflow"
    )
endif()
