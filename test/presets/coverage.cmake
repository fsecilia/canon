# SPDX-License-Identifier: MIT
# Copyright (c) 2026 Frank Secilia

include("${CANON_SOURCE_DIR}/test/presets/common.cmake")

canon_test_require_variables(CANON_GCOVR_EXECUTABLE)

set(_preset "${CANON_PRESET_PROFILE}-coverage")
# Pass through reporting-tool overrides supplied to the outer project.
set(_coverage_configure_command
    "${CMAKE_COMMAND}"
    --preset "${_preset}"
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
_run("${_preset} configure" ${_coverage_configure_command})

_run_workflow("${_preset}" Debug)
_expect_cache_value(
    "${_preset}"
    CANON_GCOVR_EXECUTABLE
    FILEPATH
    "${CANON_GCOVR_EXECUTABLE}"
    "${_preset} workflow"
)
_expect_cache_value(
    "${_preset}"
    CANON_ENABLE_COVERAGE
    BOOL
    TRUE
    "${_preset} workflow"
)
if (DEFINED CANON_GCOV_EXECUTABLE AND NOT "${CANON_GCOV_EXECUTABLE}" STREQUAL "")
    _expect_cache_value(
        "${_preset}"
        CANON_GCOV_EXECUTABLE
        FILEPATH
        "${CANON_GCOV_EXECUTABLE}"
        "${_preset} workflow"
    )
endif()
if (DEFINED CANON_LLVM_COV_EXECUTABLE AND NOT "${CANON_LLVM_COV_EXECUTABLE}" STREQUAL "")
    _expect_cache_value(
        "${_preset}"
        CANON_LLVM_COV_EXECUTABLE
        FILEPATH
        "${CANON_LLVM_COV_EXECUTABLE}"
        "${_preset} workflow"
    )
endif()

set(_index "${_source_dir}/build/${_preset}/coverage/index.html")
if (NOT EXISTS "${_index}")
    message(FATAL_ERROR "${_preset} workflow did not generate '${_index}'")
endif()
