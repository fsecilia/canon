# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

if (NOT DEFINED CANON_GCOVR_EXECUTABLE OR "${CANON_GCOVR_EXECUTABLE}" STREQUAL "")
    message(FATAL_ERROR "CANON_GCOVR_EXECUTABLE is required")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/preset-common.cmake")

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
